from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from collections import defaultdict, deque


try:
    project_root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(project_root / 'src'))
except IndexError:
    pass

from utils.caller_map_utils import build_caller_context
from utils.path_manager import get_output_dir


@dataclass
class PathNode:
    """Path node with semantic context"""
    node_id: str
    node_type: str
    function: str
    call_depth: int = 0
    code_blocks: List[Dict[str, Any]] = field(default_factory=list)
    condition: Optional[str] = None
    branch: Optional[str] = None
    data_io_profile: Dict[str, Any] = field(default_factory=dict)
    permission_checks: List[Dict[str, Any]] = field(default_factory=list)
    active_constraints: List[str] = field(default_factory=list)
    call_out: List[Dict[str, Any]] = field(default_factory=list)
    asset_annotations: List[Dict[str, Any]] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to JSON-serializable dict"""
        result = {
            'node_id': self.node_id,
            'node_type': self.node_type,
            'function': self.function,
            'call_depth': self.call_depth
        }
        if self.code_blocks:
            result['code_blocks'] = self.code_blocks
        if self.condition:
            result['condition'] = self.condition
            result['branch'] = self.branch
        if self.data_io_profile:
            result['data_io_profile'] = self.data_io_profile
        if self.permission_checks:
            result['permission_checks'] = self.permission_checks
        if self.active_constraints:
            result['active_constraints'] = self.active_constraints
        if self.call_out:
            result['call_out'] = self.call_out
        if self.asset_annotations:
            result['asset_annotations'] = self.asset_annotations
        return result


@dataclass
class PathEdge:
    """Edge in execution path"""
    source_node_id: str
    target_node_id: str
    edge_type: str


    condition: Optional[str] = None
    branch: Optional[str] = None


    call_expression: Optional[str] = None
    target_function: Optional[str] = None
    parameters: List[str] = field(default_factory=list)
    parameter_mapping: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to JSON-serializable dict"""
        result = {
            'source_node_id': self.source_node_id,
            'target_node_id': self.target_node_id,
            'edge_type': self.edge_type
        }
        if self.condition:
            result['condition'] = self.condition
            result['branch'] = self.branch
        if self.call_expression:
            result['call_expression'] = self.call_expression
            result['target_function'] = self.target_function
            result['parameters'] = self.parameters
        if self.parameter_mapping:
            result['parameter_mapping'] = self.parameter_mapping
        return result


@dataclass
class DirectPath:
    """Direct path with function call expansion"""
    path_id: str
    function_signature: str
    entry_node_id: str
    nodes: List[PathNode]
    edges: List[PathEdge]
    asset_observations: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to JSON-serializable dict"""
        return {
            'path_id': self.path_id,
            'path_type': 'DIRECT',
            'function_signature': self.function_signature,
            'entry_node_id': self.entry_node_id,
            'nodes': [n.to_dict() for n in self.nodes],
            'edges': [e.to_dict() for e in self.edges],
            'asset_observations': self.asset_observations,
            'metadata': self.metadata
        }


@dataclass
class IndirectPath:
    """Indirect path representing state variable control chain"""
    path_id: str
    control_source: Dict[str, Any]
    control_variable: Dict[str, Any]
    affected_targets: List[Dict[str, Any]]
    control_chain: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to JSON-serializable dict"""
        payload = {
            'path_id': self.path_id,
            'path_type': 'INDIRECT',
            'control_source': self.control_source,
            'control_variable': self.control_variable,
            'affected_targets': self.affected_targets,
        }
        if self.control_chain:
            payload['control_chain'] = self.control_chain
        if self.metadata:
            payload['metadata'] = self.metadata
        return payload


def _extract_contract_name(signature: Optional[str]) -> Optional[str]:
    if not signature:
        return None
    if '.' in signature:
        return signature.split('.', 1)[0]
    if '(' in signature:
        return signature.split('(', 1)[0]
    return signature


def _collect_direct_contracts(nodes: List[PathNode]) -> List[str]:
    contracts = set()
    for node in nodes:
        contract = _extract_contract_name(node.function)
        if contract:
            contracts.add(contract)
    return sorted(contracts)


def _collect_indirect_contracts(
    control_source: Dict[str, Any],
    control_chain: List[Dict[str, Any]],
    targets: List[Dict[str, Any]],
) -> List[str]:
    contracts = set()

    def add(func: Optional[str]) -> None:
        name = _extract_contract_name(func)
        if name:
            contracts.add(name)

    add(control_source.get('function'))
    for hop in control_chain or []:
        add(hop.get('function'))
    for target in targets or []:
        add(target.get('function'))

    return sorted(contracts)


class CallerAwareParameterMapper:
    """Build parameter mappings with is_caller annotation using step1.1 caller_map"""

    def __init__(self, caller_context: Dict[str, Any]):
        self.global_symbols = caller_context.get('global_symbols', {}) or {}
        self.function_symbols = caller_context.get('function_symbols', {}) or {}
        self.wrapper_functions = set(caller_context.get('wrapper_functions', set()) or set())

    def build_parameter_mapping(
        self,
        source_function: str,
        target_function: str,
        call_arguments: List[str],
        target_parameters: List[Dict[str, Any]],
        data_io_profile: Dict[str, Any]
    ) -> Dict[str, Dict[str, Any]]:
        mapping = {}

        for i, param in enumerate(target_parameters):
            param_name = param['name']


            if i < len(call_arguments):
                arg_expr = call_arguments[i]
            else:
                arg_expr = None


            source_info = self._analyze_argument_source(arg_expr, data_io_profile)


            is_caller, evidence = self._is_caller_parameter(arg_expr, source_info, source_function)

            mapping[param_name] = {
                'call_argument': arg_expr,
                'source': source_info,
                'is_caller': is_caller
            }

            if evidence:
                mapping[param_name]['caller_evidence'] = evidence

        return mapping

    def _analyze_argument_source(
        self,
        arg_expr: Optional[str],
        data_io_profile: Dict[str, Any]
    ) -> Dict[str, Any]:
        if not arg_expr:
            return {'type': 'UNKNOWN', 'value': None}

        arg_lower = arg_expr.lower()


        if 'msg.sender' in arg_lower or 'tx.origin' in arg_lower:
            return {'type': 'GLOBAL', 'value': arg_expr}


        if '(' in arg_expr and ')' in arg_expr:
            func_name = arg_expr.split('(')[0].strip().lower()
            if func_name in self.wrapper_functions:
                trace = (self.global_symbols.get(func_name) or {}).get('source', 'msg.sender')
                return {'type': 'CALLER_FUNCTION', 'value': arg_expr, 'trace': trace}
            return {'type': 'FUNCTION_CALL', 'value': arg_expr}


        param_reads = data_io_profile.get('parameter_reads', [])
        if arg_expr in param_reads:

            return {'type': 'PARAMETER', 'value': arg_expr}


        state_reads = data_io_profile.get('state_reads', [])
        if arg_expr in state_reads:
            return {'type': 'STATE', 'value': arg_expr}


        local_reads = data_io_profile.get('local_reads', [])
        if arg_expr in local_reads:

            return {'type': 'LOCAL', 'value': arg_expr}


        return {'type': 'CONSTANT', 'value': arg_expr}

    def _is_caller_parameter(
        self,
        arg_expr: Optional[str],
        source_info: Dict[str, Any],
        source_function: str
    ) -> Tuple[bool, Optional[Dict[str, Any]]]:
        if not arg_expr:
            return False, None

        source_type = source_info.get('type')


        if source_type == 'GLOBAL':
            return True, {'source': 'msg.sender', 'scope': 'global'}


        if source_type == 'CALLER_FUNCTION':
            return True, {
                'source': source_info.get('trace', 'msg.sender'),
                'trace': source_info.get('value', source_info.get('trace')),
                'scope': 'function_wrapper'
            }

        arg_lower = arg_expr.lower()
        function_callers = self.function_symbols.get(source_function, {})
        if arg_lower in function_callers:
            entry = function_callers[arg_lower]
            return True, {
                'source': arg_expr,
                'mapping': entry.get('source', 'msg.sender'),
                'scope': 'mapped'
            }

        return False, None


class DirectPathSearcher:
    """Search direct paths with function call expansion"""

    def __init__(
        self,
        plcg: Dict[str, Any],
        permission_profile: Dict[str, Any],
        caller_mapper: CallerAwareParameterMapper,
        target_contracts: Set[str]
    ):
        self.plcg = plcg
        self.permission_profile = permission_profile
        self.caller_mapper = caller_mapper
        self.path_counter = 0
        self.target_contracts = target_contracts or set()

    def search_all_direct_paths(self) -> List[DirectPath]:
        """Search all direct paths across all functions"""
        all_paths = []

        for func_key, func_data in self.plcg.items():
            if not self._should_analyze_entry(func_key, func_data):
                continue

            if not self._has_any_permission_check(func_key, func_data):
                continue


            paths = self._search_function_paths(func_key, func_data)
            all_paths.extend(paths)


        all_paths = self._deduplicate_direct_paths(all_paths)

        return all_paths

    def _should_analyze_entry(self, func_key: str, func_data: Dict[str, Any]) -> bool:
        if not func_data:
            return False

        contract_name = func_key.split('.', 1)[0]
        if self.target_contracts and contract_name not in self.target_contracts:
            return False

        nodes = func_data.get('nodes', {})
        entry_node = nodes.get('E1')
        if not entry_node:
            return False

        visibility = (entry_node.get('visibility') or '').lower()
        if visibility not in ('public', 'external'):
            return False

        return True

    def _is_subsequence(self, subseq: tuple, seq: tuple) -> bool:
        if len(subseq) > len(seq):
            return False


        for i in range(len(seq) - len(subseq) + 1):
            if seq[i:i+len(subseq)] == subseq:
                return True

        return False

    def _deduplicate_direct_paths(self, paths: List[DirectPath]) -> List[DirectPath]:
        if not paths:
            return paths


        path_signatures = []
        for path in paths:

            signature = tuple(
                (node.function, node.node_id, node.call_depth)
                for node in path.nodes
            )
            path_signatures.append((path, signature))


        kept_paths = []
        for i, (path_i, sig_i) in enumerate(path_signatures):
            is_contained = False


            for j, (path_j, sig_j) in enumerate(path_signatures):
                if i == j:
                    continue


                if self._is_subsequence(sig_i, sig_j):
                    is_contained = True
                    break


            if not is_contained:
                kept_paths.append(path_i)

        return kept_paths

    def _has_any_permission_check(
        self,
        func_key: str,
        func_data: Dict[str, Any],
        visited: Optional[Set[str]] = None
    ) -> bool:
        if visited is None:
            visited = set()


        if func_key in visited:
            return False
        visited = visited | {func_key}


        if func_key in self.permission_profile.get('functions', {}):
            if self.permission_profile['functions'][func_key].get('permission_checks'):
                return True


        nodes = func_data.get('nodes', {})
        for node_data in nodes.values():
            if node_data.get('permission_checks'):
                return True


        for node_data in nodes.values():
            for call in node_data.get('call_details', []):
                target_func = call.get('target_function_signature')
                if not target_func:
                    target_contract = call.get('contract_name')
                    func_signature = call.get('function_signature')
                    if target_contract and func_signature:
                        target_func = f"{target_contract}.{func_signature}"

                if not target_func:
                    continue


                target_name = target_func.split('.')[-1].split('(')[0].lower()
                if target_name in self.caller_mapper.wrapper_functions:
                    continue


                if target_func in self.plcg:
                    if self._has_any_permission_check(
                        target_func,
                        self.plcg[target_func],
                        visited
                    ):
                        return True

        return False

    def _search_function_paths(self, func_key: str, func_data: Dict[str, Any]) -> List[DirectPath]:
        """Search all paths within a function"""
        paths = []
        nodes = func_data.get('nodes', {})
        edges = func_data.get('edges', [])


        entry_id = None
        for node_id, node_data in nodes.items():
            if node_data.get('node_id') == node_id and node_id.startswith('E'):
                entry_id = node_id
                break

        if not entry_id:
            return paths


        visited_paths = self._dfs_enumerate_paths(
            func_key=func_key,
            current_id=entry_id,
            current_path=[],
            call_depth=0,
            nodes=nodes,
            edges=edges,
            visited_functions={func_key},
            active_constraints=[],
            parameter_bindings=None
        )


        for path_nodes in visited_paths:

            has_permission = self._path_has_permission(path_nodes)
            state_reads = []
            state_writes = []
            metadata_contracts = []

            if not has_permission:
                continue

            for node in path_nodes:
                if node.data_io_profile:
                    state_reads.extend(node.data_io_profile.get('state_reads') or [])
                    state_writes.extend(node.data_io_profile.get('state_writes') or [])
            metadata_contracts = _collect_direct_contracts(path_nodes)

            if not state_reads and not state_writes:
                has_call_out = any(getattr(node, 'call_out', None) for node in path_nodes)
                if not has_call_out:
                    continue


            path_edges = self._reconstruct_edges(path_nodes)
            self._attach_call_context(path_nodes, path_edges)
            asset_observations = self._extract_asset_observations(path_nodes)
            if not asset_observations:

                continue
            contracts_in_path = _collect_direct_contracts(path_nodes)

            path = DirectPath(
                path_id=f"path_{self.path_counter}",
                function_signature=func_key,
                entry_node_id=entry_id,
                nodes=path_nodes,
                edges=path_edges,
                asset_observations=asset_observations,
                metadata={
                    'has_function_calls': any(n.call_depth > 0 for n in path_nodes),
                    'max_call_depth': max((n.call_depth for n in path_nodes), default=0),
                    'contracts_in_path': contracts_in_path,
                    'state_reads': sorted(set(state_reads)),
                    'state_writes': sorted(set(state_writes)),
                }
            )
            paths.append(path)
            self.path_counter += 1

        return paths

    def _reconstruct_edges(self, nodes: List[PathNode]) -> List[PathEdge]:
        edges = []

        for i in range(len(nodes) - 1):
            curr = nodes[i]
            next_node = nodes[i + 1]


            if curr.node_type == 'FINISH':
                continue


            if next_node.call_depth > curr.call_depth:

                edge = PathEdge(
                    source_node_id=curr.node_id,
                    target_node_id=next_node.node_id,
                    edge_type='call',
                    target_function=next_node.function
                )

                param_mapping = next_node.data_io_profile.get('parameter_mapping')
                if param_mapping:
                    edge.parameter_mapping = param_mapping
                edges.append(edge)

            elif next_node.call_depth < curr.call_depth:


                continue

            else:

                if curr.node_type == 'IF':
                    branch_label = curr.branch if curr.branch else 'unknown'
                    if next_node.active_constraints:
                        added = [
                            constraint for constraint in next_node.active_constraints
                            if constraint not in curr.active_constraints
                        ]
                        if added:
                            last = added[-1]
                            if '[' in last and ']' in last:
                                branch_label = last.split('[', 1)[1].split(']', 1)[0]

                    edge = PathEdge(
                        source_node_id=curr.node_id,
                        target_node_id=next_node.node_id,
                        edge_type='conditional',
                        condition=curr.condition,
                        branch=branch_label or 'unknown'
                    )
                else:

                    edge = PathEdge(
                        source_node_id=curr.node_id,
                        target_node_id=next_node.node_id,
                        edge_type='sequential'
                    )
                edges.append(edge)

        return edges

    def _attach_call_context(self, path_nodes: List[PathNode], path_edges: List[PathEdge]):
        """Attach call target + parameter mapping info to nodes for inline context."""
        lookup = {node.node_id: node for node in path_nodes}

        for edge in path_edges:
            if edge.edge_type != 'call':
                continue
            node = lookup.get(edge.source_node_id)
            if not node:
                continue
            call_info = {
                'callee': edge.target_function,
                'target_node': edge.target_node_id,
                'parameter_mapping': edge.parameter_mapping
            }
            node.call_out.append(call_info)

    def _extract_asset_observations(self, path_nodes: List[PathNode]) -> List[Dict[str, Any]]:
        """Summarize asset-related operations for later prompt generation."""
        observations: List[Dict[str, Any]] = []

        for node in path_nodes:
            if not node.asset_annotations:
                continue

            code_snippets = [block.get('expression', block.get('code', '')) for block in node.code_blocks]

            for annotation in node.asset_annotations:
                observations.append({
                    'node': node.node_id,
                    'function': node.function,
                    'variable': annotation.get('variable'),
                    'classification': annotation.get('classification'),
                    'access': annotation.get('access', []),
                    'expressions': code_snippets,
                    'active_constraints': list(node.active_constraints),
                    'permission_checks': node.permission_checks,
                    'call_depth': node.call_depth
                })

        return observations

    def _dfs_enumerate_paths(
        self,
        func_key: str,
        current_id: str,
        current_path: List[PathNode],
        call_depth: int,
        nodes: Dict[str, Any],
        edges: List[Dict[str, Any]],
        visited_functions: Optional[Set[str]] = None,
        active_constraints: Optional[List[str]] = None,
        parameter_bindings: Optional[List[Dict[str, Any]]] = None
    ) -> List[List[PathNode]]:
        if visited_functions is None:
            visited_functions = set()

        completed_paths = []
        current_constraints = list(active_constraints or [])


        current_node = nodes.get(current_id)
        if not current_node:
            return completed_paths
        current_binding = None
        if parameter_bindings:
            current_binding = parameter_bindings[-1]

        path_node = self._create_path_node(
            func_key,
            current_id,
            current_node,
            call_depth,
            current_constraints,
            current_binding
        )
        new_path = current_path + [path_node]


        if current_id.startswith('F'):
            return [new_path]


        outgoing = [e for e in edges if e['source_id'] == current_id]

        if not outgoing:

            return []


        call_edges = [e for e in outgoing if e.get('edge_type') == 'call']
        control_edges = [e for e in outgoing if e.get('edge_type') in ['sequential', 'conditional']]


        current_paths = [new_path]

        for call_edge in call_edges:

            next_paths = []
            for path in current_paths:
                expanded_paths = self._expand_function_call(
                    edge=call_edge,
                    current_path=path,
                    call_depth=call_depth + 1,
                    caller_function=func_key,
                    caller_node=current_node,
                    visited_functions=visited_functions,
                    active_constraints=current_constraints,
                    parameter_bindings=parameter_bindings
                )
                next_paths.extend(expanded_paths)
            current_paths = next_paths


        if not control_edges:
            return current_paths


        for control_edge in control_edges:
            target_id = control_edge.get('target_id')


            for path in current_paths:
                sub_paths = self._dfs_enumerate_paths(
                    func_key=func_key,
                    current_id=target_id,
                    current_path=path,
                    call_depth=call_depth,
                    nodes=nodes,
                    edges=edges,
                    visited_functions=visited_functions,
                    active_constraints=self._next_constraints(control_edge, current_constraints),
                    parameter_bindings=parameter_bindings
                )
                completed_paths.extend(sub_paths)

        return completed_paths

    def _expand_function_call(
        self,
        edge: Dict[str, Any],
        current_path: List[PathNode],
        call_depth: int,
        caller_function: str,
        caller_node: Dict[str, Any],
        visited_functions: Set[str],
        active_constraints: List[str],
        parameter_bindings: Optional[List[Dict[str, Any]]] = None
    ) -> List[List[PathNode]]:
        target_func_key = edge.get('target_function_signature')
        if not target_func_key or target_func_key not in self.plcg:

            return [current_path]


        target_func_name = target_func_key.split('.')[-1].split('(')[0].lower()
        if target_func_name in self.caller_mapper.wrapper_functions:

            return [current_path]


        if target_func_key in visited_functions:

            return [current_path]


        callee_data = self.plcg[target_func_key]
        callee_nodes = callee_data.get('nodes', {})
        callee_edges = callee_data.get('edges', [])


        callee_entry_id = None
        for node_id, node_data in callee_nodes.items():
            if node_id.startswith('E'):
                callee_entry_id = node_id
                break

        if not callee_entry_id:
            return [current_path]


        call_args = edge.get('parameters', [])
        callee_entry = callee_nodes[callee_entry_id]
        callee_params = callee_entry.get('parameters', [])


        caller_data_io = {
            'state_reads': caller_node.get('state_reads', []),
            'state_writes': caller_node.get('state_writes', []),
            'parameter_reads': caller_node.get('parameter_reads', []),
            'local_reads': caller_node.get('local_reads', []),
            'local_writes': caller_node.get('local_writes', [])
        }

        param_mapping = self.caller_mapper.build_parameter_mapping(
            source_function=caller_function,
            target_function=target_func_key,
            call_arguments=call_args,
            target_parameters=callee_params,
            data_io_profile=caller_data_io
        )


        new_visited = visited_functions | {target_func_key}


        new_bindings = list(parameter_bindings or [])
        new_bindings.append(param_mapping)

        callee_paths = self._dfs_enumerate_paths(
            func_key=target_func_key,
            current_id=callee_entry_id,
            current_path=current_path,
            call_depth=call_depth,
            nodes=callee_nodes,
            edges=callee_edges,
            visited_functions=new_visited,
            active_constraints=active_constraints,
            parameter_bindings=new_bindings
        )

        if not callee_paths:
            return [current_path]

        return callee_paths

    def _create_path_node(
        self,
        func_key: str,
        node_id: str,
        node_data: Dict[str, Any],
        call_depth: int,
        active_constraints: List[str],
        parameter_binding: Optional[Dict[str, Any]]
    ) -> PathNode:
        """Create PathNode from PLCG node data"""

        if node_id.startswith('E'):
            node_type = 'ENTRY'
        elif node_id.startswith('D'):
            node_type = 'DIVISION'
        elif node_id.startswith('IF'):
            node_type = 'IF'
        elif node_id.startswith('F'):
            node_type = 'FINISH'
        else:
            node_type = 'UNKNOWN'

        path_node = PathNode(
            node_id=node_id,
            node_type=node_type,
            function=func_key,
            call_depth=call_depth
        )
        path_node.active_constraints = list(active_constraints)


        if node_type == 'ENTRY':
            path_node.data_io_profile = {
                'parameters': node_data.get('parameters', []),
                'modifiers': node_data.get('modifiers', [])
            }
            if parameter_binding:
                path_node.data_io_profile['parameter_binding'] = parameter_binding

                path_node.data_io_profile.setdefault('parameter_mapping', parameter_binding)

            path_node.permission_checks = node_data.get('permission_checks', [])
            asset_tags = node_data.get('asset_variable_tags', [])
            if asset_tags:
                path_node.asset_annotations = asset_tags

        elif node_type == 'DIVISION':
            path_node.code_blocks = node_data.get('code_blocks', [])
            division_profile = {
                'state_reads': node_data.get('state_reads', []),
                'state_writes': node_data.get('state_writes', []),
                'parameter_reads': node_data.get('parameter_reads', []),
                'local_reads': node_data.get('local_reads', []),
                'local_writes': node_data.get('local_writes', [])
            }
            state_variable_types = node_data.get('state_variable_types')
            if state_variable_types:
                division_profile['state_variable_types'] = state_variable_types
            variable_initializations = node_data.get('variable_initializations')
            if variable_initializations:
                division_profile['variable_initializations'] = variable_initializations
            if parameter_binding:
                division_profile['parameter_binding'] = parameter_binding
            path_node.data_io_profile = division_profile
            path_node.permission_checks = node_data.get('permission_checks', [])
            asset_tags = node_data.get('asset_variable_tags', [])
            if asset_tags:
                path_node.asset_annotations = asset_tags

        elif node_type == 'IF':
            path_node.condition = node_data.get('condition')
            path_node.data_io_profile = {
                'condition_analysis': node_data.get('condition_analysis', {})
            }
            if parameter_binding:
                path_node.data_io_profile['parameter_binding'] = parameter_binding

            permission_info = node_data.get('permission_info')
            if permission_info:
                path_node.permission_checks = [permission_info]
            asset_tags = node_data.get('asset_variable_tags', [])
            if asset_tags:
                path_node.asset_annotations = asset_tags

        return path_node

    def _next_constraints(self, edge: Dict[str, Any], current_constraints: List[str]) -> List[str]:
        """Return updated constraint list when traversing an edge."""
        if edge.get('edge_type') != 'conditional':
            return list(current_constraints)

        condition = edge.get('condition', 'unknown')
        branch = edge.get('branch', 'unknown')
        source = edge.get('source_id', '')
        label = f"{source or 'IF'}: {condition} [{branch}]"
        return list(current_constraints) + [label]

    def _path_has_permission(self, path_nodes: List[PathNode]) -> bool:
        """Check if path contains at least one meaningful permission check"""
        for node in path_nodes:
            if self._node_has_permission(node):
                return True
        return False

    @staticmethod
    def _node_has_permission(node: PathNode) -> bool:
        """Return True if node's permission_checks indicate real privilege control."""
        checks = node.permission_checks or []
        for check in checks:
            if check.get('has_permission'):
                return True
            if check.get('is_state_lock'):
                return True
            if check.get('depends_on_caller') and check.get('depends_on_state'):
                return True
        return False


class IndirectPathSearcher:
    """Search indirect paths via state variable control chains"""

    def __init__(self,
                 plcg: Dict[str, Any],
                 permission_profile: Dict[str, Any],
                 caller_context: Dict[str, Any],
                 plcg_metadata: Dict[str, Any],
                 target_contracts: Set[str]):
        self.plcg = plcg
        self.permission_profile = permission_profile
        self.wrapper_functions = set(caller_context.get('wrapper_functions', set()) or set())
        asset_meta = (plcg_metadata or {}).get('asset_variables') or {}
        self.asset_variables = asset_meta
        self.asset_variable_names = set(asset_meta.keys())
        self.path_counter = 0
        self.target_contracts = target_contracts or set()
        self.functions_by_signature = self._index_functions_by_signature()


        self.control_graph = self._build_control_graph()

    def _index_functions_by_signature(self) -> Dict[str, List[str]]:
        """Build helper map for resolving call signatures across inheritance."""
        signature_map: Dict[str, List[str]] = defaultdict(list)
        for func_key in self.plcg.keys():
            if '.' in func_key:
                _, signature = func_key.split('.', 1)
            else:
                signature = func_key
            signature_map[signature].append(func_key)
        return signature_map

    def _has_any_permission_check(
        self,
        func_key: str,
        func_data: Dict[str, Any],
        visited: Optional[Set[str]] = None
    ) -> bool:
        if visited is None:
            visited = set()


        if func_key in visited:
            return False
        visited = visited | {func_key}


        if func_key in self.permission_profile.get('functions', {}):
            if self.permission_profile['functions'][func_key].get('permission_checks'):
                return True


        nodes = func_data.get('nodes', {})
        for node_data in nodes.values():
            if node_data.get('permission_checks'):
                return True


        for node_data in nodes.values():
            for call in node_data.get('call_details', []):
                target_func = call.get('target_function_signature')
                if not target_func:
                    target_contract = call.get('contract_name')
                    func_signature = call.get('function_signature')
                    if target_contract and func_signature:
                        target_func = f"{target_contract}.{func_signature}"

                if not target_func:
                    continue


                target_name = target_func.split('.')[-1].split('(')[0].lower()
                if target_name in self.wrapper_functions:
                    continue


                if target_func in self.plcg:
                    if self._has_any_permission_check(
                        target_func,
                        self.plcg[target_func],
                        visited
                    ):
                        return True

        return False

    def _build_control_graph(self) -> Dict[str, Any]:
        modify_edges = []
        depend_edges = []
        function_nodes = {}
        variable_nodes = defaultdict(lambda: {'writers': set(), 'readers': set()})
        adjacency = defaultdict(set)
        external_entry_candidates: Set[str] = set()

        for func_key, func_data in self.plcg.items():
            nodes = func_data.get('nodes', {})
            has_permission = self._has_any_permission_check(func_key, func_data)
            self_permission = self._function_has_direct_permission(func_key, func_data)

            function_nodes[func_key] = {
                'has_permission': has_permission,
                'self_permission': self_permission,
                'modifies': set(),
                'depends': set(),
                'visibility': None,
                'externally_reachable': False
            }

            for node_id, node_data in nodes.items():
                if node_id.startswith('E'):
                    visibility = (node_data.get('visibility') or '').lower()
                    function_nodes[func_key]['visibility'] = visibility
                    if visibility in ('public', 'external'):
                        external_entry_candidates.add(func_key)

                for call in node_data.get('call_details', []):
                    target_func = call.get('target_function_signature')
                    if not target_func:
                        target_contract = call.get('contract_name')
                        func_signature = call.get('function_signature')
                        if target_contract and func_signature:
                            target_func = f"{target_contract}.{func_signature}"
                    if target_func and target_func in self.plcg:
                        adjacency[func_key].add(target_func)

                state_writes = node_data.get('state_writes', [])
                for var in state_writes:
                    if self._is_pseudo_transient_variable(var):
                        continue
                    modify_edges.append((func_key, var))
                    function_nodes[func_key]['modifies'].add(var)
                    variable_nodes[var]['writers'].add(func_key)

                if node_data.get('permission_checks'):
                    for check in node_data.get('permission_checks') or []:
                        for var in check.get('state_variables') or []:
                            if self._is_pseudo_transient_variable(var):
                                continue
                            depend_edges.append((func_key, var))
                            function_nodes[func_key]['depends'].add(var)
                            variable_nodes[var]['readers'].add(func_key)

                if node_id.startswith('IF'):
                    condition_analysis = node_data.get('condition_analysis', {})
                    state_reads_from_condition = condition_analysis.get('state_reads', [])
                    for var in state_reads_from_condition:
                        if self._is_pseudo_transient_variable(var):
                            continue
                        depend_edges.append((func_key, var))
                        function_nodes[func_key]['depends'].add(var)
                        variable_nodes[var]['readers'].add(func_key)

                if self._node_contains_guard(node_data):
                    state_reads = node_data.get('state_reads', [])
                    for var in state_reads:
                        if self._is_pseudo_transient_variable(var):
                            continue
                        depend_edges.append((func_key, var))
                        function_nodes[func_key]['depends'].add(var)
                        variable_nodes[var]['readers'].add(func_key)

        externally_reachable = self._compute_externally_reachable(adjacency, external_entry_candidates)
        for func in externally_reachable:
            if func in function_nodes:
                function_nodes[func]['externally_reachable'] = True

        return {
            'modify_edges': modify_edges,
            'depend_edges': depend_edges,
            'function_nodes': function_nodes,
            'variable_nodes': dict(variable_nodes)
        }

    def _compute_externally_reachable(
        self,
        adjacency: Dict[str, Set[str]],
        entry_candidates: Set[str]
    ) -> Set[str]:
        """BFS over call graph starting from public/external entries."""
        reachable: Set[str] = set()
        queue: deque[str] = deque(entry_candidates)
        while queue:
            func = queue.popleft()
            if func in reachable:
                continue
            reachable.add(func)
            for target in adjacency.get(func, set()):
                if target not in reachable:
                    queue.append(target)
        return reachable

    def _function_has_direct_permission(self, func_key: str, func_data: Dict[str, Any]) -> bool:
        """Return True if this function itself carries a permission check."""
        perm_profile = (self.permission_profile.get('functions') or {}).get(func_key)
        if perm_profile and perm_profile.get('permission_checks'):
            return True

        nodes = func_data.get('nodes', {})
        for node in nodes.values():
            if node.get('permission_checks'):
                return True
        return False

    @staticmethod
    def _node_contains_guard(node_data: Dict[str, Any]) -> bool:
        """Heuristic: does this node contain require/assert style guard?"""
        for block in node_data.get('code_blocks') or []:
            expr = (block.get('expression') or '').lower()
            if 'require(' in expr or 'assert(' in expr or 'revert' in expr:
                return True
        return False

    def search_all_indirect_paths(self, timeout: Optional[float] = None) -> List[IndirectPath]:
        all_paths = []

        function_nodes = self.control_graph['function_nodes']
        variable_nodes = self.control_graph['variable_nodes']


        control_sources = [
            func_key for func_key, data in function_nodes.items()
            if data.get('self_permission') and data.get('externally_reachable')
        ]
        total_sources = len(control_sources)
        discovered = 0
        stats = {"expansions": 0}
        max_expansions = 50000
        max_paths = 100
        deadline = time.monotonic() + timeout if timeout else None

        for idx, source_func in enumerate(control_sources, 1):
            print(f"  [INDIRECT] Scanning source {idx}/{total_sources}: {source_func}")
            if not self._is_valid_control_source(source_func):
                continue
            if deadline and time.monotonic() > deadline:
                print("  [INDIRECT] Timeout reached, stopping search.")
                break

            modified_vars = function_nodes[source_func]['modifies']

            for var in modified_vars:

                if self._is_business_variable(var):
                    continue


                paths = self._search_control_chains(
                    source_function=source_func,
                    control_variable=var,
                    chain_depth=0,
                    max_depth=10,
                    stats=stats,
                    max_expansions=max_expansions,
                    deadline=deadline
                )
                if not paths:
                    continue
                for path in paths:
                    has_asset_target = any(
                        self._affected_target_has_asset_operation(target)
                        for target in (path.affected_targets or [])
                    )
                    if has_asset_target:
                        all_paths.append(path)
                        discovered += 1
                        if discovered % 10 == 0:
                            print(f"    [INDIRECT] Found {discovered} path(s) so far...")
                        if len(all_paths) >= max_paths:
                            print(f"    [INDIRECT] Reached max path cap ({max_paths}), stopping early.")
                            break
                        if stats["expansions"] >= max_expansions:
                            print("    [INDIRECT] Expansion cap reached for this source, stopping further chains.")
                            break
                if len(all_paths) >= max_paths:
                    break
                if stats["expansions"] >= max_expansions:
                    break
            if stats["expansions"] >= max_expansions:
                print(f"  [INDIRECT] Expansion cap hit at {stats['expansions']} steps; stopping search early.")
                break
            if len(all_paths) >= max_paths:
                print(f"  [INDIRECT] Path cap hit at {len(all_paths)} paths; stopping search early.")
                break
            if deadline and time.monotonic() > deadline:
                print("  [INDIRECT] Timeout reached, stopping search.")
                break


        all_paths = self._deduplicate_indirect_paths(all_paths)
        print(f"  [INDIRECT] Total paths before dedup: {discovered}, after dedup: {len(all_paths)}")

        return all_paths

    def _deduplicate_indirect_paths(self, paths: List[IndirectPath]) -> List[IndirectPath]:
        if not paths:
            return paths


        grouped = {}

        for path in paths:
            source_func = path.control_source['function']
            var_name = path.control_variable['name']


            for target in path.affected_targets:
                target_func = target['function']
                target_node = target.get('node_id', '')

                unique_key = (source_func, var_name, target_func, target_node)


                if unique_key not in grouped:

                    metadata = {
                        'contracts_in_path': _collect_indirect_contracts(
                            path.control_source,
                            path.control_chain,
                            [target],
                        )
                    }
                    new_path = IndirectPath(
                        path_id=path.path_id,
                        control_source=path.control_source,
                        control_variable=path.control_variable,
                        affected_targets=[target],
                        control_chain=path.control_chain if path.control_chain else [],
                        metadata=metadata,
                    )
                    grouped[unique_key] = new_path
                else:

                    existing = grouped[unique_key]
                    existing_len = len(existing.control_chain) if existing.control_chain else 0
                    current_len = len(path.control_chain) if path.control_chain else 0


                    if current_len < existing_len:
                        metadata = {
                            'contracts_in_path': _collect_indirect_contracts(
                                path.control_source,
                                path.control_chain,
                                [target],
                            )
                        }
                        new_path = IndirectPath(
                            path_id=path.path_id,
                            control_source=path.control_source,
                            control_variable=path.control_variable,
                            affected_targets=[target],
                            control_chain=path.control_chain if path.control_chain else [],
                            metadata=metadata,
                        )
                        grouped[unique_key] = new_path

        return list(grouped.values())

    def _is_business_variable(self, var_name: str) -> bool:
        """Filter variables that should not seed indirect control chains."""
        if not var_name:
            return True

        base_name = var_name.split('.', 1)[-1]
        lowered = base_name.lower()


        if var_name in self.asset_variable_names:
            return True
        if base_name in self.asset_variable_names:
            return True

        supply_keywords = {
            "totalsupply",
            "_totalsupply",
            "total_supply",
            "totalissuance",
            "total_issuance",
            "maxsupply",
            "_maxsupply",
            "max_supply",
            "supplycap",
            "supply_cap",
            "capsupply",
        }
        if any(keyword in lowered for keyword in supply_keywords):
            return True

        if lowered.endswith("supply") or lowered.startswith("supply"):
            return True
        return False

    @staticmethod
    def _is_pseudo_transient_variable(var_name: str) -> bool:
        if not var_name:
            return False
        lowered = var_name.lower()
        pseudo = {
            "msgsend",
            "msgreceive",
            "msgsender",
            "msgreceiver",
            "msgorigin",
            "calleraddress",
        }
        return lowered in pseudo

    def _search_control_chains(
        self,
        source_function: str,
        control_variable: str,
        chain_depth: int,
        max_depth: int,
        visited_vars: Optional[Set[str]] = None,
        stats: Optional[Dict[str, int]] = None,
        max_expansions: int = 0,
        deadline: Optional[float] = None
    ) -> List[IndirectPath]:
        if visited_vars is None:
            visited_vars = set()

        if chain_depth > max_depth or control_variable in visited_vars:
            return []

        visited_vars = visited_vars | {control_variable}
        paths = []
        control_source_info = self._extract_control_source_info(source_function)

        variable_nodes = self.control_graph['variable_nodes']
        function_nodes = self.control_graph['function_nodes']


        readers = variable_nodes.get(control_variable, {}).get('readers', set())

        for reader_func in readers:

            if reader_func == source_function:
                continue

            if stats is not None:
                stats["expansions"] += 1
                if stats["expansions"] % 2000 == 0:
                    print(f"    [INDIRECT] expansions={stats['expansions']}")
                if max_expansions and stats["expansions"] >= max_expansions:
                    return []
            if deadline and time.monotonic() > deadline:
                return []


            affected_target = self._extract_affected_target(reader_func, control_variable)

            if affected_target and self._affected_target_has_asset_operation(affected_target):

                metadata = {
                    'contracts_in_path': _collect_indirect_contracts(
                        control_source_info,
                        [],
                        [affected_target],
                    )
                }
                path = IndirectPath(
                    path_id=f"indirect_{self.path_counter}",
                    control_source=control_source_info,
                    control_variable=self._extract_variable_info(control_variable),
                    affected_targets=[affected_target],
                    control_chain=[],
                    metadata=metadata,
                )
                paths.append(path)
                self.path_counter += 1


            reader_modifies = function_nodes.get(reader_func, {}).get('modifies', set())

            for next_var in reader_modifies:
                if next_var in visited_vars:
                    continue


                if self._is_business_variable(next_var):
                    continue


                nested_paths = self._search_control_chains(
                    source_function=source_function,
                    control_variable=next_var,
                    chain_depth=chain_depth + 1,
                    max_depth=max_depth,
                    visited_vars=visited_vars,
                    stats=stats,
                    max_expansions=max_expansions,
                    deadline=deadline
                )


                for nested_path in nested_paths:

                    current_layer = {
                        'function': reader_func,
                        'variable': next_var,
                        'depth': chain_depth + 1
                    }
                    nested_path.control_chain.insert(0, current_layer)
                    if nested_path.metadata is None:
                        nested_path.metadata = {}
                    nested_path.metadata['contracts_in_path'] = _collect_indirect_contracts(
                        control_source_info,
                        nested_path.control_chain,
                        nested_path.affected_targets,
                    )

                paths.extend(nested_paths)

        return paths

    def _is_valid_control_source(self, func_key: str) -> bool:
        contract_name = func_key.split('.', 1)[0]
        if self.target_contracts and contract_name not in self.target_contracts:
            return False
        data = self.control_graph['function_nodes'].get(func_key, {})
        if not data.get('self_permission'):
            return False
        if not data.get('externally_reachable'):
            return False
        return True

    def _affected_target_has_asset_operation(self, target: Dict[str, Any]) -> bool:
        if not target:
            return False


        for var in target.get('writes') or []:
            if var in self.asset_variable_names:
                return True


        func_key = target.get('function')
        if func_key and self._function_has_asset_operation(func_key):
            return True

        return False

    def _function_has_asset_operation(self, func_key: str) -> bool:
        return self._function_has_asset_operation_recursive(func_key, set())

    def _function_has_asset_operation_recursive(self, func_key: str, visited: Set[str]) -> bool:
        if func_key in visited:
            return False
        visited.add(func_key)

        func_data = self.plcg.get(func_key, {})
        nodes = func_data.get('nodes', {})

        for node in nodes.values():

            for ann in node.get('asset_variable_tags') or []:
                var = ann.get('variable')
                if var and var in self.asset_variable_names:
                    return True

            for var in node.get('state_writes') or []:
                if var in self.asset_variable_names:
                    return True

            for call in node.get('call_details', []):
                target_func = call.get('target_function_signature')
                if not target_func:
                    target_contract = call.get('contract_name')
                    func_signature = call.get('function_signature')
                    if target_contract and func_signature:
                        target_func = f"{target_contract}.{func_signature}"
                candidates: Set[str] = set()
                if target_func:
                    candidates.add(target_func)
                func_signature = call.get('function_signature')
                if func_signature:
                    candidates.update(self.functions_by_signature.get(func_signature, []))

                if not candidates:
                    continue

                for candidate in candidates:
                    target_name = candidate.split('.')[-1].split('(')[0].lower()
                    if target_name in self.wrapper_functions:
                        continue
                    if self._function_has_asset_operation_recursive(candidate, visited):
                        return True

        return False

    def _extract_control_source_info(self, func_key: str) -> Dict[str, Any]:
        """Extract control source function info"""
        func_data = self.plcg.get(func_key, {})
        nodes = func_data.get('nodes', {})


        for node_id, node_data in nodes.items():
            if node_id.startswith('E'):
                return {
                    'function': func_key,
                    'node_id': node_id,
                    'modifiers': node_data.get('modifiers', []),
                    'visibility': node_data.get('visibility')
                }

        return {'function': func_key}

    def _extract_variable_info(self, var_name: str) -> Dict[str, Any]:
        """Extract variable info"""
        variable_node = self.control_graph['variable_nodes'].get(var_name, {})

        return {
            'name': var_name,
            'writers': list(variable_node.get('writers', [])),
            'readers': list(variable_node.get('readers', []))
        }

    def _extract_affected_target(self, func_key: str, var_name: str) -> Optional[Dict[str, Any]]:
        func_data = self.plcg.get(func_key, {})
        nodes = func_data.get('nodes', {})

        for node_id, node_data in nodes.items():

            if node_id.startswith('IF'):
                condition_analysis = node_data.get('condition_analysis', {})
                state_reads = condition_analysis.get('state_reads', [])

                if var_name in state_reads:
                    return {
                        'function': func_key,
                        'node_id': node_id,
                        'usage_type': 'CONDITIONAL_CHECK',
                        'condition': node_data.get('condition')
                    }


            if node_id.startswith('D'):
                state_reads = node_data.get('state_reads', [])

                if var_name in state_reads:

                    if node_data.get('state_writes'):
                        return {
                            'function': func_key,
                            'node_id': node_id,
                            'usage_type': 'STATE_MODIFICATION',
                            'writes': node_data.get('state_writes', [])
                        }
                    if self._node_contains_guard(node_data):
                        return {
                            'function': func_key,
                            'node_id': node_id,
                            'usage_type': 'CONDITIONAL_CHECK',
                            'condition': '; '.join(
                                block.get('expression', '')
                                for block in node_data.get('code_blocks', [])
                                if 'require' in (block.get('expression') or '').lower()
                                or 'revert' in (block.get('expression') or '').lower()
                            )
                        }

        return None


def load_step1_outputs(contract_name: str, output_dir: Path) -> Tuple[Dict, Dict, Dict, Dict]:
    """Load step1.1, step1.2, step1.3 outputs"""
    step1_dir = output_dir / contract_name / "step1"


    caller_context: Dict[str, Any] = {}
    step11_file = step1_dir / "step1.1_caller_source.json"
    if step11_file.exists():
        with open(step11_file, 'r', encoding='utf-8') as f:
            step11_data = json.load(f)
            caller_context = build_caller_context(step11_data)


    permission_profile = {}
    step12_file = step1_dir / "step1.2_permission_profile.json"
    if step12_file.exists():
        with open(step12_file, 'r', encoding='utf-8') as f:
            permission_profile = json.load(f)
    else:
        legacy_file = step1_dir / "step1.2_permission_profile_v2.json"
        if legacy_file.exists():
            print(f"  ⚠️  Ignoring legacy file {legacy_file.name}; expected canonical step1.2 output.")


    plcg = {}
    plcg_metadata = {}
    step13_file = step1_dir / "step1.3_PLCG.json"
    if step13_file.exists():
        with open(step13_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            plcg = data.get('functions', {})
            plcg_metadata = data.get('metadata', {})

    return caller_context, permission_profile, plcg, plcg_metadata


def analyze_contract(
    contract_name: str,
    output_dir: Path,
    skip_indirect: bool = False,
    indirect_timeout: Optional[float] = None,
) -> Optional[Dict[str, Any]]:
    """Run path search for a contract"""
    print(f"\n{'='*80}\n📄 Analyzing: {contract_name}\n{'='*80}")


    caller_context, permission_profile, plcg, plcg_metadata = load_step1_outputs(contract_name, output_dir)

    if not plcg:
        print(f"  ❌ Failed to load PLCG for {contract_name}")
        return None

    print(f"  ✓ Loaded PLCG: {len(plcg)} functions")
    print(f"  ✓ Loaded caller_map: {caller_context.get('symbol_count', 0)} symbols")


    caller_mapper = CallerAwareParameterMapper(caller_context)
    permission_contracts = {
        func_key.split('.', 1)[0]
        for func_key, func_data in (permission_profile.get('functions') or {}).items()
        if func_data.get('permission_checks')
    }
    asset_contracts = {
        info.get('contract')
        for info in (plcg_metadata.get('asset_variables') or {}).values()
        if info.get('contract')
    }
    all_contracts = {
        func_key.split('.', 1)[0]
        for func_key in plcg.keys()
    }
    target_contracts = permission_contracts or asset_contracts or all_contracts

    direct_searcher = DirectPathSearcher(plcg, permission_profile, caller_mapper, target_contracts)
    indirect_searcher = IndirectPathSearcher(plcg, permission_profile, caller_context, plcg_metadata, target_contracts)


    print(f"\n🔍 Searching direct paths...")
    direct_paths = direct_searcher.search_all_direct_paths()
    print(f"  • Found {len(direct_paths)} direct paths")


    if skip_indirect:
        print("\n🔍 Skipping indirect path search (per flag)")
        indirect_paths = []
    else:
        print(f"\n🔍 Searching indirect paths...")
        indirect_paths = indirect_searcher.search_all_indirect_paths(timeout=indirect_timeout)
        print(f"  • Found {len(indirect_paths)} indirect paths")


    results = {
        'contract_name': contract_name,
        'analysis_timestamp': '2025-11-20',
        'direct_paths': [p.to_dict() for p in direct_paths],
        'indirect_paths': [p.to_dict() for p in indirect_paths],
        'summary': {
            'total_direct_paths': len(direct_paths),
            'total_indirect_paths': len(indirect_paths)
        }
    }


    out_dir = output_dir / contract_name / "step1"
    out_dir.mkdir(parents=True, exist_ok=True)
    outfile = out_dir / "step1.4_paths.json"

    with outfile.open('w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\n💾 Saved results to {outfile.relative_to(output_dir)}")

    return results


def main() -> None:
    print("\n" + "=" * 80)
    print("🚀 Step 1.4 Path Search")
    print("   Direct Paths: Function call expansion + Parameter mapping")
    print("   Indirect Paths: Nested state variable control chains")
    print("=" * 80)

    parser = argparse.ArgumentParser(description="Step 1.4 path search")
    parser.add_argument("contracts", nargs="*", help="Contract names to analyze")
    parser.add_argument(
        "--skip-indirect",
        action="store_true",
        help="Skip indirect path search (only run direct paths).",
    )
    parser.add_argument(
        "--indirect-timeout",
        type=int,
        default=0,
        help="Timeout in seconds for indirect search; 0 = no timeout.",
    )
    parser.add_argument(
        "--results-dir",
        help="Override the directory containing step1.x outputs (default: PADG_OUTPUT_DIR or repo output).",
    )
    args = parser.parse_args()

    base_root = 'project_root' in globals() and project_root or Path.cwd()

    if args.results_dir:
        output_dir = Path(args.results_dir).expanduser()
        if not output_dir.is_absolute():
            output_dir = base_root / output_dir
    else:
        output_dir = get_output_dir()

    if not output_dir.exists():
        print("❌ Error: output directory not found")
        return

    indirect_timeout = args.indirect_timeout if args.indirect_timeout > 0 else None


    if args.contracts:

        contracts = args.contracts
        print(f"\n📋 Processing {len(contracts)} specified contract(s):")
        for c in contracts:
            print(f"   • {c}")
    else:

        contracts = []
        for contract_dir in output_dir.iterdir():
            if contract_dir.is_dir():
                step13_file = contract_dir / "step1" / "step1.3_PLCG.json"
                if step13_file.exists():
                    contracts.append(contract_dir.name)

        if not contracts:
            print("❌ No contracts with step1.3 output found")
            return

        print(f"\n📋 Found {len(contracts)} contracts with PLCG data")


    successful = 0
    failed = []
    skipped = []


    for contract_name in contracts:
        try:
            result = analyze_contract(
                contract_name,
                output_dir,
                skip_indirect=args.skip_indirect,
                indirect_timeout=indirect_timeout,
            )

            if result is None:
                skipped.append((contract_name, "No PLCG data"))
            elif result.get('summary', {}).get('total_direct_paths', 0) == 0 and \
                 result.get('summary', {}).get('total_indirect_paths', 0) == 0:

                print(f"  ⚠️  No paths found for {contract_name} (empty result saved)")
                successful += 1
            else:
                successful += 1

        except Exception as e:
            print(f"  ❌ Error analyzing {contract_name}: {str(e)}")
            import traceback
            traceback.print_exc()
            failed.append((contract_name, str(e)))
            continue


    print("\n" + "=" * 80)
    print("📊 Final Summary")
    print("=" * 80)
    print(f"Total contracts: {len(contracts)}")
    print(f"✅ Successfully analyzed: {successful}")

    if skipped:
        print(f"⚠️  Skipped (no data): {len(skipped)}")
        for contract, reason in skipped:
            print(f"   - {contract}: {reason}")

    if failed:
        print(f"❌ Failed: {len(failed)}")
        for contract, error in failed:
            print(f"   - {contract}: {error}")

    print("\n✅ Path search complete")


if __name__ == "__main__":
    main()
