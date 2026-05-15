import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional, Any
from dataclasses import dataclass, field, asdict
from collections import defaultdict
from slither.slither import Slither
from slither.core.cfg.node import Node as SlitherNode, NodeType
from slither.core.declarations import Function, Contract
from slither.core.declarations.structure import Structure
from slither.core.solidity_types.mapping_type import MappingType
from slither.core.solidity_types.array_type import ArrayType
from slither.core.solidity_types.elementary_type import ElementaryType
from slither.core.solidity_types.user_defined_type import UserDefinedType
from slither.core.variables.state_variable import StateVariable


try:
 PROJECT_ROOT = Path(__file__).resolve.parents[2]
except NameError:
 PROJECT_ROOT = Path.cwd


sys.path.insert(0, str(PROJECT_ROOT / 'src'))


from utils.version_manager import init_slither as init_slither_with_version
from utils.caller_map_utils import load_caller_context, format_function_key
from utils.path_manager import get_output_dir

CONTRACTS_DIR = PROJECT_ROOT / "contracts"
OUTPUT_BASE = get_output_dir


@dataclass
class EntryNode:
 """: """
 node_id: str
 visibility: str
 modifiers: List[str] = field(default_factory=list)
 modifier_details: List[Dict[str, Any]] = field(default_factory=list)
 parameters: List[Dict[str, Any]] = field(default_factory=list)
 source_mapping: Dict[str, Any] = field(default_factory=dict)
 permission_checks: Dict[str, Any] = field(default_factory=dict)

 def to_dict(self):
 return asdict(self)


@dataclass
class BaseNode:
 """"""
 node_id: str
 node_type: str
 code_blocks: List[Dict[str, Any]] = field(default_factory=list)
 line_range: Tuple[int, int] = field(default=(0, 0))
 state_reads: List[str] = field(default_factory=list)
 state_writes: List[str] = field(default_factory=list)
 state_variable_types: Dict[str, str] = field(default_factory=dict)
 parameter_reads: List[str] = field(default_factory=list)
 local_reads: List[str] = field(default_factory=list)
 local_writes: List[str] = field(default_factory=list)
 global_reads: List[str] = field(default_factory=list)
 variable_initializations: Dict[str, str] = field(default_factory=dict)
 external_calls: List[str] = field(default_factory=list)
 call_details: List[Dict[str, Any]] = field(default_factory=list)
 permission_checks: List[Dict[str, Any]] = field(default_factory=list)
 asset_variable_tags: List[Dict[str, Any]] = field(default_factory=list)

 def to_dict(self):
 return asdict(self)


@dataclass
class ModifierNode(BaseNode):
 """"""
 modifier_name: str = ""


@dataclass
class DivisionNode(BaseNode):
 """: （ + ）"""
 pass


@dataclass
class IFNode:
 """"""
 node_id: str
 condition: str
 line: int


 permission_info: Optional[Dict[str, Any]] = None


 condition_analysis: Dict[str, Any] = field(default_factory=dict)

 def to_dict(self):
 return asdict(self)


@dataclass
class FinishNode:
 """"""
 node_id: str

 def to_dict(self):
 return asdict(self)


@dataclass
class Edge:
 """"""
 source_id: str
 target_id: str
 edge_type: str


 condition: Optional[str] = None
 branch: Optional[str] = None
 is_permission_check: Optional[bool] = None


 call_expression: Optional[str] = None
 target_function_signature: Optional[str] = None


 metadata: Optional[dict] = None

 def to_dict(self):
 return asdict(self)


class PLCGBuilder:

 def __init__(self,
 contract_address: str,
 sol_path: Optional[Path] = None,
 output_base: Path = OUTPUT_BASE):
 self.contract_address = contract_address
 self.output_base = output_base
 self.contract_dir = output_base / contract_address / "step1"


 if sol_path is None:
 contract_path = CONTRACTS_DIR / f"{contract_address}.sol"
 else:
 contract_path = Path(sol_path)

 print(f"\n📄 Loading contract: {contract_path}")
 self.slither = init_slither_with_version(str(contract_path))
 if self.slither is None:
 raise RuntimeError(f"Failed to initialize Slither for {contract_path}")


 self.global_initializations = {}
 self.asset_variables: Dict[str, Dict[str, Any]] = {}

 self.cfg_node_mapping: Dict[Any, str] = {}


 self.permission_data = self._load_permission_data


 self.caller_context = self._load_caller_map


 self.plcg = {}

 def _load_caller_map(self) -> Dict[str, Any]:
 caller_file = self.contract_dir / "step1.1_caller_source.json"

 if not caller_file.exists:
 print(f" ⚠️ Warning: step1.1 caller source not found: {caller_file}")
 return {}

 try:
 caller_context = load_caller_context(caller_file)
 symbol_count = caller_context.get('symbol_count', 0)
 print(f" ✓ Loaded {symbol_count} caller symbols from step1.1")
 return caller_context

 except Exception as e:
 print(f" ⚠️ Error loading caller map: {e}")
 return {
 'global_symbols': {},
 'function_symbols': {},
 'wrapper_functions': set,
 'tainted_parameters': {},
 'symbol_count': 0,
 }

 def _load_permission_data(self) -> Dict:
 permission_file = self.contract_dir / "step1.2_permission_profile.json"

 if not permission_file.exists:
 print(f" ⚠️ Warning: step1.2 permission profile not found: {permission_file}")
 print(f" ℹ️ Will build PLCG without permission annotations")
 return {}

 try:
 with open(permission_file, 'r', encoding='utf-8') as f:
 data = json.load(f)
 print(f" ✓ Loaded permission data from step1.2")
 return data
 except Exception as e:
 print(f" ⚠️ Error loading permission data: {e}")
 return {}

 def build(self) -> Dict:
 print(f"\n🔨 Building PLCG for contract: {self.contract_address}")


 self._collect_global_initializations
 self._identify_asset_variables


 functions_to_analyze = self._select_all_implemented_functions
 print(f" ✓ Selected {len(functions_to_analyze)} functions to analyze")


 for func_info in functions_to_analyze:
 func_sig = func_info['signature']
 print(f"\n 📊 Analyzing function: {func_sig}")
 try:
 self._build_function_graph(func_info)
 except Exception as e:
 print(f" ⚠️ Error analyzing {func_sig}: {e}")
 import traceback
 traceback.print_exc
 continue


 print(f"\n 🔗 Creating call edges...")
 self._create_call_edges

 return {
 'functions': self.plcg,
 'metadata': {
 'global_variable_initializations': self.global_initializations,
 'asset_variables': self.asset_variables,
 'total_functions': len(self.plcg)
 }
 }

 def _collect_global_initializations(self):
 print("\n📊 Collecting global variable initializations...")

 for contract in self.slither.contracts:

 if contract.is_interface:
 continue


 for var in contract.state_variables:
 var_name = var.name


 if var.expression:
 init_value = str(var.expression)
 self.global_initializations[var_name] = {
 'value': init_value,
 'source': 'DECLARATION',
 'type': str(var.type),
 'contract': contract.name,
 'is_constant': var.is_constant,
 'is_immutable': var.is_immutable
 }
 print(f" ✓ {var_name} = {init_value} (declaration)")
 else:

 default_value = self._get_type_default_value(var.type)
 self.global_initializations[var_name] = {
 'value': default_value,
 'source': 'DEFAULT',
 'type': str(var.type),
 'contract': contract.name
 }


 if contract.constructor:
 self._extract_constructor_initializations(contract.constructor, contract.name)

 def _identify_asset_variables(self):
 asset_vars: Dict[str, Dict[str, Any]] = {}

 print("\n🔎 Scanning state variables for asset-like patterns...")
 for contract in self.slither.contracts:
 if contract.is_interface:
 continue

 for var in contract.state_variables:
 metadata = self._analyze_asset_candidate(var, contract.name)
 if metadata:
 asset_vars[var.name] = metadata

 self.asset_variables = asset_vars

 if asset_vars:
 print(f"📌 Identified {len(asset_vars)} asset-like variable(s)")
 for name, info in asset_vars.items:
 evidence = ", ".join(info.get('evidence', [])) or "structure match"
 print(f" • {info['contract']}.{name} -> {info.get('classification')} ({evidence})")
 else:
 print("ℹ️ No asset-like variables detected")

 def _analyze_asset_candidate(self, state_var: StateVariable, contract_name: str) -> Optional[Dict[str, Any]]:
 var_type = getattr(state_var, 'type', None)
 if not var_type:
 return None

 mapping_signature = self._extract_mapping_signature(var_type)
 if not mapping_signature:
 return None

 metadata = {
 'variable': state_var.name,
 'contract': contract_name,
 'type': str(var_type),
 'classification': mapping_signature.get('classification', 'mapping_balance_like'),
 'key_types': mapping_signature.get('key_types', []),
 'leaf_type': mapping_signature.get('leaf_type'),
 'nested_mapping_depth': mapping_signature.get('depth', 1),
 'structure_path': mapping_signature.get('structure_path', []),
 'evidence': mapping_signature.get('evidence', [])
 }
 return metadata

 def _extract_mapping_signature(self, sol_type) -> Optional[Dict[str, Any]]:
 if not isinstance(sol_type, MappingType):
 return None

 key_type = getattr(sol_type, 'type_from', None)
 value_type = getattr(sol_type, 'type_to', None)
 if not self._is_address_like(key_type):
 return None

 leaf_info = self._resolve_mapping_leaf(value_type, depth=1)
 if not leaf_info:
 return None

 evidence = [f"key:{str(key_type)}"] + leaf_info.get('evidence', [])

 return {
 'classification': 'mapping_balance_like',
 'key_types': [str(key_type)] + leaf_info.get('additional_keys', []),
 'leaf_type': leaf_info.get('leaf_type'),
 'depth': leaf_info.get('depth', 1),
 'structure_path': leaf_info.get('structure_path', []),
 'evidence': evidence
 }

 def _resolve_mapping_leaf(self, value_type, depth: int) -> Optional[Dict[str, Any]]:
 if isinstance(value_type, MappingType):
 nested_key = getattr(value_type, 'type_from', None)
 nested_value = getattr(value_type, 'type_to', None)
 if not self._is_address_like(nested_key):
 return None
 child = self._resolve_mapping_leaf(nested_value, depth + 1)
 if not child:
 return None
 child['additional_keys'].insert(0, str(nested_key))
 child['depth'] = child.get('depth', depth) + 1
 child.setdefault('structure_path', []).insert(0, str(nested_value))
 child.setdefault('evidence', []).append(f"nested_key:{str(nested_key)}")
 return child

 if isinstance(value_type, ArrayType):
 base = value_type.type
 if self._is_numeric_type(base):
 return {
 'leaf_type': f"{str(base)}[]",
 'additional_keys': [],
 'structure_path': [str(value_type)],
 'depth': depth,
 'evidence': [f"numeric_array:{str(base)}"]
 }

 return None

 if self._is_numeric_type(value_type):
 return {
 'leaf_type': str(value_type),
 'additional_keys': [],
 'structure_path': [str(value_type)],
 'depth': depth,
 'evidence': [f"numeric_leaf:{str(value_type)}"]
 }

 if isinstance(value_type, UserDefinedType):
 user_type = value_type.type
 if isinstance(user_type, Structure):
 numeric_fields = self._structure_numeric_fields(user_type)
 if numeric_fields:
 pretty_name = f"struct {user_type.name}"
 return {
 'leaf_type': pretty_name,
 'additional_keys': [],
 'structure_path': [pretty_name],
 'depth': depth,
 'evidence': [f"struct_field:{field}" for field in numeric_fields]
 }

 return None

 def _structure_numeric_fields(self, struct: Structure) -> List[str]:
 """yesno. """
 numeric_fields = []
 for elem in getattr(struct, 'elems', []):
 elem_type = getattr(elem, 'type', None)
 elem_name = getattr(elem, 'name', 'field')
 if self._is_numeric_type(elem_type):
 numeric_fields.append(elem_name)
 return numeric_fields

 @staticmethod
 def _is_address_like(sol_type) -> bool:
 """yesno address/address payable. """
 if isinstance(sol_type, ElementaryType):
 name = (sol_type.name or '').lower
 return 'address' in name
 return 'address' in str(sol_type).lower

 @staticmethod
 def _is_numeric_type(sol_type) -> bool:
 """yesno/. """
 if sol_type is None:
 return False
 if isinstance(sol_type, ElementaryType):
 name = (sol_type.name or '').lower
 return any(token in name for token in ['uint', 'int', 'fixed'])
 return any(token in str(sol_type).lower for token in ['uint', 'int', 'fixed'])

 def _get_type_default_value(self, var_type) -> str:
 """ Solidity """
 type_str = str(var_type)


 if 'mapping' in type_str:
 return '0'
 elif '[]' in type_str:
 return '[]'
 elif 'bool' in type_str:
 return 'false'
 elif 'uint' in type_str or 'int' in type_str:
 return '0'
 elif 'address' in type_str:
 return 'address(0)'
 else:
 return f'<zero-value of {type_str}>'

 def _extract_constructor_initializations(self, constructor: Function, contract_name: str):
 """"""
 for node in constructor.nodes:
 if node.type != NodeType.EXPRESSION:
 continue

 if not node.expression:
 continue

 expr_str = str(node.expression)


 if '=' in expr_str and not any(op in expr_str for op in ['==', '!=', '<=', '>=']):
 parts = expr_str.split('=', 1)
 if len(parts) == 2:
 left = parts[0].strip
 right = parts[1].strip


 var_name = left.split('.')[-1].strip


 if var_name in self.global_initializations:
 old_value = self.global_initializations[var_name]['value']
 self.global_initializations[var_name].update({
 'value': right,
 'source': 'CONSTRUCTOR',
 'overrides': old_value
 })


 if 'msg.sender' in right or 'tx.origin' in right:
 self.global_initializations[var_name]['is_caller_initialized'] = True
 self.global_initializations[var_name]['likely_permission_variable'] = True

 print(f" ✓ {var_name} = {right} (constructor)")

 def _select_all_implemented_functions(self) -> List[Dict]:
 selected = []

 for contract in self.slither.contracts:

 if contract.is_interface:
 print(f" ⏭️ Skipping interface: {contract.name}")
 continue

 for func in contract.functions:

 if not func.is_implemented:
 continue


 if func.is_constructor or func.is_fallback or func.is_receive:
 continue


 if func.name.startswith('slitherConstructor'):
 continue


 func_key = f"{contract.name}.{func.full_name}"

 selected.append({
 'signature': func_key,
 'contract': contract.name,
 'function': func,
 'visibility': func.visibility
 })

 return selected

 def _build_function_graph(self, func_info: Dict):
 func = func_info['function']
 func_sig = func_info['signature']
 contract_name = func_info['contract']


 graph = {
 'nodes': {},
 'edges': []
 }


 modifiers, modifier_details = self._extract_modifier_info(func)


 func_permissions = self._get_function_permissions(func)


 modifier_permissions = self._extract_modifier_permissions(func_permissions)


 self.modifier_counter = 0


 entry_id = "E1"
 entry_node = EntryNode(
 node_id=entry_id,
 visibility=func.visibility,
 modifiers=modifiers,
 modifier_details=modifier_details,
 parameters=self._extract_parameters(func),
 source_mapping=self._extract_source_mapping(func) if func.source_mapping else {},
 permission_checks=modifier_permissions
 )
 graph['nodes'][entry_id] = entry_node.to_dict


 finish_id = "F1"
 finish_node = FinishNode(node_id=finish_id)
 graph['nodes'][finish_id] = finish_node.to_dict


 modifier_nodes = self._build_modifier_nodes(func, func_permissions)
 previous_node = entry_id
 for modifier_node in modifier_nodes:
 node_id = modifier_node['node_id']
 graph['nodes'][node_id] = modifier_node
 graph['edges'].append(Edge(
 source_id=previous_node,
 target_id=node_id,
 edge_type="sequential"
 ).to_dict)
 previous_node = node_id


 if func.entry_point:
 self._build_cfg_graph(func, graph, previous_node, finish_id)
 else:

 graph['edges'].append(Edge(
 source_id=previous_node,
 target_id=finish_id,
 edge_type="sequential"
 ).to_dict)


 self.plcg[func_sig] = graph

 def _extract_modifier_info(self, func: Function) -> Tuple[List[str], List[Dict]]:
 modifier_names = [mod.name for mod in func.modifiers if hasattr(mod, 'name')]
 modifier_details = []


 func_permissions = self._get_function_permissions(func)
 permission_checks_data = func_permissions.get('permission_checks')


 for mod_name in modifier_names:
 has_perm = self._is_permission_modifier(mod_name, permission_checks_data)

 detail = {
 'name': mod_name,
 'has_permission_check': has_perm,
 'has_state_check': False
 }
 modifier_details.append(detail)

 return modifier_names, modifier_details

 def _is_permission_modifier(self, modifier_name: str, permission_checks) -> bool:
 if not permission_checks:
 return False


 if isinstance(permission_checks, list):
 conditions = permission_checks
 elif isinstance(permission_checks, dict):

 conditions = permission_checks.get('conditions', [])
 else:
 return False


 for cond in conditions:
 source = cond.get('source', '')

 if source == f'modifier:{modifier_name}':
 return True

 return False

 def _extract_modifier_permissions(self, func_permissions: Dict) -> List[Dict]:
 if not func_permissions:
 return []

 perm_checks_obj = func_permissions.get('permission_checks')
 if not perm_checks_obj:
 return []


 if isinstance(perm_checks_obj, list):
 conditions = perm_checks_obj
 elif isinstance(perm_checks_obj, dict):

 conditions = perm_checks_obj.get('conditions', [])
 else:
 return []


 modifier_perms = []
 for cond in conditions:
 source = cond.get('source', '')
 if source.startswith('modifier:'):
 modifier_perms.append(cond)

 return modifier_perms

 def _extract_parameters(self, func: Function) -> List[Dict]:
 return [
 {
 'name': param.name,
 'type': str(param.type),
 'index': idx
 }
 for idx, param in enumerate(func.parameters)
 ]

 def _is_pure_control_flow(self, code: str) -> bool:
 """yesnoyes（）"""
 stripped = code.strip.rstrip(';').strip

 if stripped in ['{', '}', '}{']:
 return True

 if stripped.startswith('function '):
 return True
 return False

 def _is_modifier_call(self, expression: str, modifier_names: Set[str]) -> bool:
 if not modifier_names or not expression:
 return False

 expr_stripped = expression.strip.rstrip(';').strip


 for mod_name in modifier_names:

 if expr_stripped == mod_name or expr_stripped == f"{mod_name}":
 return True

 return False

 def _reconstruct_statement(self, expression: str, node_type: NodeType) -> str:
 expr = expression.strip

 if node_type == NodeType.RETURN:
 return f"return {expr}"
 elif node_type == NodeType.IF:
 return f"if ({expr})"
 elif node_type == NodeType.IFLOOP:
 return f"while ({expr})"
 elif node_type == NodeType.VARIABLE:
 return expr
 elif node_type == NodeType.EXPRESSION:
 return expr
 elif node_type in [NodeType.THROW, NodeType.PLACEHOLDER]:
 return expr
 else:
 return expr

 def _build_cfg_graph(self, func: Function, graph: Dict, start_parent_id: str, finish_id: str):

 self.division_counter = 0
 self.if_counter = 0


 visited = set


 if func.entry_point:
 self._traverse_cfg(
 cfg_node=func.entry_point,
 func=func,
 graph=graph,
 parent_node_id=start_parent_id,
 finish_id=finish_id,
 visited=visited,
 depth=0
 )
 else:
 graph['edges'].append(Edge(
 source_id=start_parent_id,
 target_id=finish_id,
 edge_type="sequential"
 ).to_dict)

 def _build_modifier_nodes(self, func: Function, func_permissions: Dict) -> List[Dict[str, Any]]:
 """"""
 modifier_nodes: List[Dict[str, Any]] = []
 if not func.modifiers:
 return modifier_nodes

 modifier_names = {mod.name for mod in func.modifiers if hasattr(mod, 'name')}

 for modifier in func.modifiers:
 if not hasattr(modifier, 'nodes'):
 continue

 self.modifier_counter += 1
 node_id = f"M{self.modifier_counter}"
 modifier_param_names = {p.name for p in getattr(modifier, 'parameters', [])}

 code_blocks = []
 state_reads: Set[str] = set
 state_writes: Set[str] = set
 parameter_reads: Set[str] = set
 local_reads: Set[str] = set
 local_writes: Set[str] = set
 global_reads: Set[str] = set
 external_calls: Set[str] = set
 call_details: List[Dict[str, Any]] = []
 variable_inits: Dict[str, str] = {}
 state_variable_types: Dict[str, str] = {}
 permission_checks: List[Dict[str, Any]] = []

 for node in modifier.nodes:
 line = node.source_mapping.lines[0] if node.source_mapping and node.source_mapping.lines else None
 expr = str(node.expression) if node.expression else None

 if expr and not self._is_pure_control_flow(expr):
 code_blocks.append({
 'expression': self._reconstruct_statement(expr, node.type),
 'line': line,
 'node_type': str(node.type)
 })


 if line:
 perm_check = self._find_permission_check_by_line(func_permissions, line)
 if perm_check:
 permission_checks.append(perm_check)

 for var in node.state_variables_read:
 state_reads.add(var.name)
 for var in node.state_variables_written:
 state_writes.add(var.name)
 for var in node.local_variables_read:
 if var.name in modifier_param_names:
 parameter_reads.add(var.name)
 else:
 local_reads.add(var.name)
 for var in node.local_variables_written:
 local_writes.add(var.name)
 if hasattr(node, 'solidity_variables_read'):
 for var in node.solidity_variables_read:
 global_reads.add(str(var))


 for call in node.internal_calls:
 callee = getattr(call, 'function', None)
 if callee and hasattr(callee, 'name'):
 func_sig = getattr(callee, 'full_name', callee.name)
 if callee.name not in modifier_names:
 params = self._extract_call_parameters(
 str(node.expression) if node.expression else "",
 func_sig
 )
 callee_contract = getattr(callee, 'contract', None)
 target_contract = callee_contract.name if callee_contract else func.contract.name
 call_details.append({
 'function_signature': func_sig,
 'contract_name': target_contract,
 'call_expression': str(node.expression) if node.expression else "",
 'parameters': params,
 'line': line
 })

 for call in getattr(node, 'external_calls_as_expressions', []):
 external_calls.add(str(call))

 all_state_vars = state_reads | state_writes
 for var_name in all_state_vars:
 if var_name in self.global_initializations:
 variable_inits[var_name] = self.global_initializations[var_name]['value']
 state_variable_types[var_name] = self.global_initializations[var_name]['type']

 asset_tags = []
 for var_name in sorted(all_state_vars):
 if var_name in self.asset_variables:
 info = self.asset_variables[var_name].copy
 access = []
 if var_name in state_reads:
 access.append('read')
 if var_name in state_writes:
 access.append('write')
 info.update({'variable': var_name, 'access': access or ['unknown']})
 asset_tags.append(info)

 min_line = min((b['line'] for b in code_blocks if b.get('line')), default=0)
 max_line = max((b['line'] for b in code_blocks if b.get('line')), default=0)

 modifier_node = ModifierNode(
 node_id=node_id,
 node_type="MODIFIER",
 modifier_name=modifier.name if hasattr(modifier, 'name') else '',
 code_blocks=code_blocks,
 line_range=(min_line, max_line),
 state_reads=sorted(state_reads),
 state_writes=sorted(state_writes),
 state_variable_types=state_variable_types,
 parameter_reads=sorted(parameter_reads),
 local_reads=sorted(local_reads),
 local_writes=sorted(local_writes),
 global_reads=sorted(global_reads),
 variable_initializations=variable_inits,
 external_calls=sorted(external_calls),
 call_details=call_details,
 permission_checks=permission_checks,
 asset_variable_tags=asset_tags
 )

 modifier_nodes.append(modifier_node.to_dict)

 return modifier_nodes

 def _traverse_cfg(self, cfg_node: SlitherNode, func: Function, graph: Dict,
 parent_node_id: str, finish_id: str, visited: Set[SlitherNode],
 parent_edge_info: Optional[Dict[str, Any]] = None, depth: int = 0):

 MAX_RECURSION_DEPTH = 500
 if depth > MAX_RECURSION_DEPTH:
 print(f" ⚠️ Maximum recursion depth ({MAX_RECURSION_DEPTH}) reached in {func.name}, stopping traversal")

 if parent_node_id:
 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=finish_id,
 edge_type="sequential",
 metadata={"truncated": "max_depth_reached"}
 ).to_dict)
 return
 if cfg_node in visited:
 existing_node_id = self.cfg_node_mapping.get(cfg_node)
 if existing_node_id and parent_node_id:
 edge_kwargs = parent_edge_info.copy if parent_edge_info else {'edge_type': 'sequential'}
 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=existing_node_id,
 **edge_kwargs
 ).to_dict)
 return

 if cfg_node.type == NodeType.ENTRYPOINT:

 visited.add(cfg_node)
 for son in cfg_node.sons:
 self._traverse_cfg(son, func, graph, parent_node_id, finish_id, visited, depth=depth+1)
 return


 if cfg_node.type == NodeType.IF:
 self._handle_if_node(cfg_node, func, graph, parent_node_id, finish_id, visited, parent_edge_info, depth)
 return


 code_blocks, data_profile, next_node = self._collect_code_blocks(cfg_node, func, visited)

 if code_blocks:

 division_id = f"D{self.division_counter}"
 self.division_counter += 1


 call_details = data_profile.pop('call_details', [])

 division_node = DivisionNode(
 node_id=division_id,
 node_type="DIVISION",
 code_blocks=code_blocks,
 line_range=(
 min((b['line'] for b in code_blocks if b['line']), default=0),
 max((b['line'] for b in code_blocks if b['line']), default=0)
 ) if code_blocks else (0, 0),
 **data_profile
 )


 division_dict = division_node.to_dict
 division_dict['call_details'] = call_details

 graph['nodes'][division_id] = division_dict
 self.cfg_node_mapping[cfg_node] = division_id


 if parent_edge_info:

 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=division_id,
 **parent_edge_info
 ).to_dict)
 else:

 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=division_id,
 edge_type="sequential"
 ).to_dict)


 if next_node:

 self._traverse_cfg(next_node, func, graph, division_id, finish_id, visited, depth=depth+1)
 else:

 graph['edges'].append(Edge(
 source_id=division_id,
 target_id=finish_id,
 edge_type="sequential"
 ).to_dict)
 else:

 if next_node:
 self._traverse_cfg(next_node, func, graph, parent_node_id, finish_id, visited, parent_edge_info, depth+1)
 else:

 if parent_edge_info:
 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=finish_id,
 **parent_edge_info
 ).to_dict)
 else:
 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=finish_id,
 edge_type="sequential"
 ).to_dict)

 def _handle_if_node(self, if_node: SlitherNode, func: Function, graph: Dict,
 parent_node_id: str, finish_id: str, visited: Set[SlitherNode],
 parent_edge_info: Optional[Dict[str, Any]] = None, depth: int = 0):
 visited.add(if_node)


 condition = str(if_node.expression) if if_node.expression else "unknown"
 line = if_node.source_mapping.lines[0] if if_node.source_mapping and if_node.source_mapping.lines else None


 permission_info = None
 if line:
 func_permissions = self._get_function_permissions(func)
 perm_check = self._find_permission_check_by_line(func_permissions, line)
 if perm_check:
 permission_info = perm_check


 condition_analysis = self._analyze_condition_dependencies(condition, if_node, func)


 if_id = f"IF{self.if_counter}"
 self.if_counter += 1

 if_node_obj = IFNode(
 node_id=if_id,
 condition=condition,
 line=line if line else 0,
 permission_info=permission_info,
 condition_analysis=condition_analysis
 )

 graph['nodes'][if_id] = if_node_obj.to_dict
 self.cfg_node_mapping[if_node] = if_id


 if parent_edge_info:
 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=if_id,
 **parent_edge_info
 ).to_dict)
 else:
 graph['edges'].append(Edge(
 source_id=parent_node_id,
 target_id=if_id,
 edge_type="sequential"
 ).to_dict)


 if len(if_node.sons) > 0:
 true_branch = if_node.sons[0]

 true_edge_info = {
 'edge_type': 'conditional',
 'condition': condition,
 'branch': 'true'
 }
 self._traverse_cfg(true_branch, func, graph, if_id, finish_id, visited, true_edge_info, depth+1)


 if len(if_node.sons) > 1:
 false_branch = if_node.sons[1]
 if false_branch.type != NodeType.ENDIF:

 false_edge_info = {
 'edge_type': 'conditional',
 'condition': f"!({condition})",
 'branch': 'false'
 }
 self._traverse_cfg(false_branch, func, graph, if_id, finish_id, visited, false_edge_info, depth+1)

 def _collect_code_blocks(self, start_node: SlitherNode, func: Function, visited: Set[SlitherNode]) -> Tuple[List[Dict], Dict, Optional[SlitherNode]]:
 code_blocks = []
 state_reads = set
 state_writes = set
 parameter_reads = set
 local_reads = set
 local_writes = set
 global_reads = set
 internal_calls = set
 external_calls = set


 call_details = []


 permission_checks = []
 has_permission_check = False
 state_checks = []
 has_state_check = False

 param_names = {param.name for param in func.parameters}


 func_permissions = self._get_function_permissions(func)


 try:
 modifier_names = {mod.name for mod in func.modifiers if hasattr(mod, 'name')}
 except RecursionError:
 print(f" ⚠️ RecursionError when accessing modifiers for {func.name}, using empty set")
 modifier_names = set

 current = start_node
 next_node = None

 while current:
 if current in visited:
 candidate = current
 while candidate and self.cfg_node_mapping.get(candidate) is None:
 if candidate.sons:
 candidate = candidate.sons[0]
 else:
 candidate = None
 break
 next_node = candidate
 break

 if current.type in [NodeType.IF, NodeType.IFLOOP]:
 next_node = current
 break


 if current.type == NodeType.ENDIF:
 visited.add(current)
 if current.sons:
 next_node = current.sons[0]
 else:
 next_node = None
 break

 visited.add(current)


 if current.source_mapping and current.source_mapping.lines:
 node_line = current.source_mapping.lines[0]


 perm_check = self._find_permission_check_by_line(func_permissions, node_line)
 if perm_check:
 has_permission_check = True
 permission_checks.append(perm_check)


 state_check = self._find_state_check_by_line(func_permissions, node_line)
 if state_check:
 has_state_check = True
 state_checks.append(state_check)


 if current.expression:
 code = str(current.expression)
 if code and code.strip and not self._is_pure_control_flow(code):

 complete_statement = self._reconstruct_statement(code, current.type)


 if not self._is_modifier_call(complete_statement, modifier_names):
 code_blocks.append({
 'expression': complete_statement,
 'line': current.source_mapping.lines[0] if current.source_mapping and current.source_mapping.lines else None,
 'node_type': str(current.type)
 })


 for var in current.state_variables_read:
 state_reads.add(var.name)
 for var in current.state_variables_written:
 state_writes.add(var.name)
 for var in current.local_variables_read:
 if var.name in param_names:
 parameter_reads.add(var.name)
 else:
 local_reads.add(var.name)
 for var in current.local_variables_written:
 local_writes.add(var.name)
 if hasattr(current, 'solidity_variables_read'):
 for var in current.solidity_variables_read:
 global_reads.add(str(var))


 for call in current.internal_calls:
 if hasattr(call, 'function'):
 f = call.function
 func_sig = None
 if hasattr(f, 'full_name'):
 func_sig = f.full_name
 elif hasattr(f, 'name'):
 func_sig = f.name


 func_name = func_sig.rstrip('') if func_sig else None
 if func_sig and func_name not in modifier_names:

 internal_calls.add(func_sig)


 if current.expression:
 call_expr = str(current.expression)
 line = current.source_mapping.lines[0] if current.source_mapping and current.source_mapping.lines else None


 params = self._extract_call_parameters(call_expr, func_sig)


 target_contract_name = f.contract.name if hasattr(f, 'contract') and f.contract else 'Unknown'

 call_details.append({
 'function_signature': func_sig,
 'contract_name': target_contract_name,
 'call_expression': call_expr,
 'parameters': params,
 'line': line
 })

 for call in current.external_calls_as_expressions:
 external_calls.add(str(call))


 if len(current.sons) == 1:
 next_candidate = current.sons[0]

 if next_candidate.type in [NodeType.IF, NodeType.IFLOOP]:
 next_node = next_candidate
 break
 current = next_candidate
 else:
 break


 variable_inits = {}
 all_state_vars = state_reads | state_writes
 for var_name in all_state_vars:
 if var_name in self.global_initializations:
 variable_inits[var_name] = self.global_initializations[var_name]['value']


 state_variable_types = {}
 for var_name in all_state_vars:
 if var_name in self.global_initializations:
 state_variable_types[var_name] = self.global_initializations[var_name]['type']

 data_profile = {
 'state_reads': sorted(list(state_reads)),
 'state_writes': sorted(list(state_writes)),
 'state_variable_types': state_variable_types,
 'parameter_reads': sorted(list(parameter_reads)),
 'local_reads': sorted(list(local_reads)),
 'local_writes': sorted(list(local_writes)),
 'global_reads': sorted(list(global_reads)),
 'variable_initializations': variable_inits,

 'external_calls': sorted(list(external_calls)),
 'call_details': call_details,

 'permission_checks': permission_checks,


 }


 asset_tags = []
 for var_name in sorted(all_state_vars):
 if var_name in self.asset_variables:
 info = self.asset_variables[var_name].copy
 access = []
 if var_name in state_reads:
 access.append('read')
 if var_name in state_writes:
 access.append('write')
 info.update({
 'variable': var_name,
 'access': access or ['unknown']
 })
 asset_tags.append(info)
 if asset_tags:
 data_profile['asset_variable_tags'] = asset_tags

 return code_blocks, data_profile, next_node

 def _extract_call_parameters(self, call_expr: str, func_name: str) -> List[str]:
 import re


 simple_name = func_name.split('(')[0]


 func_start = call_expr.find(simple_name + '(')
 if func_start == -1:
 return []


 paren_start = func_start + len(simple_name)
 paren_depth = 0
 paren_end = -1

 for i in range(paren_start, len(call_expr)):
 if call_expr[i] == '(':
 paren_depth += 1
 elif call_expr[i] == ')':
 paren_depth -= 1
 if paren_depth == 0:
 paren_end = i
 break

 if paren_end == -1:
 return []


 params_str = call_expr[paren_start+1:paren_end].strip
 if not params_str:
 return []


 params = []
 current_param = ""
 paren_depth = 0

 for char in params_str:
 if char == '(':
 paren_depth += 1
 current_param += char
 elif char == ')':
 paren_depth -= 1
 current_param += char
 elif char == ',' and paren_depth == 0:

 params.append(current_param.strip)
 current_param = ""
 else:
 current_param += char


 if current_param.strip:
 params.append(current_param.strip)

 return params

 def _get_function_permissions(self, func: Function) -> Dict:
 if not self.permission_data or 'functions' not in self.permission_data:
 return {}

 functions_dict = self.permission_data.get('functions', {})

 contract_name = func.contract.name if func.contract else None
 func_key = format_function_key(contract_name, func.full_name)


 func_data = (
 functions_dict.get(func_key)
 or functions_dict.get(func.full_name)
 or functions_dict.get(func.name)
 or {}
 )

 return func_data

 def _find_permission_check_by_line(self, func_permissions: Dict, line: int) -> Optional[Dict]:
 if not func_permissions:
 return None

 perm_checks_obj = func_permissions.get('permission_checks')
 if not perm_checks_obj:
 return None


 if isinstance(perm_checks_obj, list):
 conditions = perm_checks_obj
 elif isinstance(perm_checks_obj, dict):

 conditions = perm_checks_obj.get('conditions', [])
 else:
 return None


 for cond in conditions:
 if cond.get('line') == line:
 return cond

 return None

 def _find_state_check_by_line(self, func_permissions: Dict, line: int) -> Optional[Dict]:

 return None

 def _create_call_edges(self):
 call_edge_count = 0

 for func_sig, func_graph in self.plcg.items:
 nodes = func_graph['nodes']
 edges = func_graph['edges']


 for node_id, node in nodes.items:
 if not node_id.startswith('D'):
 continue


 call_details = node.get('call_details', [])
 if call_details:
 for call_info in call_details:

 contract_name = call_info.get('contract_name', 'Unknown')
 func_signature = call_info['function_signature']
 target_func_key = f"{contract_name}.{func_signature}"


 if target_func_key in self.plcg:

 target_entry_id = self.plcg[target_func_key]['nodes']['E1']['node_id']


 call_edge = Edge(
 source_id=node_id,
 target_id=f"{target_func_key}::{target_entry_id}",
 edge_type="call",
 call_expression=call_info['call_expression'],
 target_function_signature=target_func_key
 )


 edge_dict = call_edge.to_dict
 edge_dict['parameters'] = call_info['parameters']
 edge_dict['line'] = call_info['line']

 edges.append(edge_dict)
 call_edge_count += 1

 else:

 internal_calls = node.get('internal_calls', [])
 for call_sig in internal_calls:


 found = False
 for plcg_key in self.plcg.keys:
 if plcg_key.endswith(f".{call_sig}"):
 target_entry_id = self.plcg[plcg_key]['nodes']['E1']['node_id']

 call_edge = Edge(
 source_id=node_id,
 target_id=f"{plcg_key}::{target_entry_id}",
 edge_type="call",
 call_expression=call_sig,
 target_function_signature=plcg_key
 )

 edges.append(call_edge.to_dict)
 call_edge_count += 1
 found = True
 break

 print(f" ✓ Created {call_edge_count} call edges")

 def _extract_source_mapping(self, func: Function) -> Dict:
 """"""
 if not func.source_mapping or not func.source_mapping.lines:
 return {}

 lines = func.source_mapping.lines
 return {
 'start_line': lines[0],
 'end_line': lines[-1]
 }

 def _analyze_condition_dependencies(self, condition: str, cfg_node: SlitherNode, func: Function) -> Dict:

 state_reads = list(self._extract_state_reads_from_expression(condition, func))


 depends_on_caller = False
 caller_reads = []

 condition_lower = condition.lower
 caller_symbols = self._get_caller_symbols_for_function(func)
 for caller_var in caller_symbols:
 caller_var_lower = caller_var.lower
 caller_base = caller_var_lower.replace('', '').replace('(', '').replace(')', '')
 if caller_var_lower in condition_lower or caller_base in condition_lower:
 depends_on_caller = True
 caller_reads.append(caller_var)


 depends_on_state = len(state_reads) > 0

 return {
 'depends_on_caller': depends_on_caller,
 'depends_on_state': depends_on_state,
 'state_reads': state_reads,
 'caller_reads': caller_reads
 }

 def _get_caller_symbols_for_function(self, func: Optional[Function]) -> Set[str]:
 symbols = set((self.caller_context.get('global_symbols') or {}).keys)
 if not func:
 return symbols

 contract_name = func.contract.name if func.contract else self.contract_address
 func_key = format_function_key(contract_name, func.full_name)
 function_map = (self.caller_context.get('function_symbols') or {}).get(func_key, {})
 symbols.update(function_map.keys)
 return symbols

 def _extract_state_reads_from_expression(self, expression: str, func: Function) -> Set[str]:
 import re

 state_reads = set


 state_var_names = {var.name for var in func.contract.state_variables}


 for var_name in state_var_names:


 pattern = r'\b' + re.escape(var_name) + r'\b'

 if re.search(pattern, expression):


 state_reads.add(var_name)

 return state_reads

 def save(self, output_path: Optional[Path] = None):
 """ PLCG """
 if output_path is None:
 output_path = self.contract_dir / "step1.3_PLCG.json"

 output_path.parent.mkdir(parents=True, exist_ok=True)

 output_data = {
 'functions': self.plcg,
 'metadata': {
 'global_variable_initializations': self.global_initializations,
 'asset_variables': self.asset_variables,
 'total_functions': len(self.plcg)
 }
 }

 with open(output_path, 'w', encoding='utf-8') as f:
 json.dump(output_data, f, indent=2, ensure_ascii=False)

 print(f"\n💾 PLCG saved to: {output_path}")


def main:
 """"""
 print("="*80)
 print("🚀 PLCG Builder v2.0")
 print("="*80)

 parser = argparse.ArgumentParser(
 description="Build PLCG artifacts for one or more contracts."
 )
 parser.add_argument(
 "--sol-path",
 help="Optional path to the Solidity source when analyzing a single contract "
 "(useful when the file is outside contracts/)."
 )
 parser.add_argument(
 "contracts",
 nargs="*",
 help="Contract addresses (default: every *.sol file under contracts/)."
 )
 args = parser.parse_args

 if args.sol_path and len(args.contracts) != 1:
 parser.error("--sol-path can only be used when exactly one contract address is provided.")

 if args.contracts:
 contract_addresses = args.contracts
 print(f"\n📋 Analyzing {len(contract_addresses)} specified contract(s)...")
 else:
 print("\n📋 No contract specified, analyzing all contracts in contracts/ directory...")
 sol_files = list(CONTRACTS_DIR.glob("*.sol"))

 if not sol_files:
 print(f"\n❌ No .sol files found in {CONTRACTS_DIR}")
 sys.exit(1)

 contract_addresses = [f.stem for f in sol_files]
 print(f" Found {len(contract_addresses)} contract(s) to analyze")


 total_functions = 0
 total_variables = 0
 success_count = 0
 failed_contracts = []


 for i, contract_address in enumerate(contract_addresses, 1):
 print(f"\n{'='*80}")
 print(f"[{i}/{len(contract_addresses)}] Processing: {contract_address}")
 print(f"{'='*80}")

 try:
 override_path = Path(args.sol_path).resolve if args.sol_path else None
 builder = PLCGBuilder(contract_address, override_path)
 result = builder.build
 builder.save


 total_functions += len(result['functions'])
 total_variables += len(result['metadata']['global_variable_initializations'])
 success_count += 1

 print("\n✅ Build complete!")
 print(f" • Functions analyzed: {len(result['functions'])}")
 print(f" • Global variables: {len(result['metadata']['global_variable_initializations'])}")

 except Exception as e:
 print(f"\n❌ Error processing {contract_address}: {e}")
 failed_contracts.append(contract_address)
 import traceback
 traceback.print_exc
 continue


 print("\n" + "="*80)
 print("📊 Final Summary")
 print("="*80)
 print(f"✅ Successfully analyzed: {success_count}/{len(contract_addresses)} contracts")
 print(f" • Total functions: {total_functions}")
 print(f" • Total global variables: {total_variables}")

 if failed_contracts:
 print(f"\n❌ Failed contracts ({len(failed_contracts)}):")
 for contract in failed_contracts:
 print(f" - {contract}")
 sys.exit(1)
 else:
 print("\n🎉 All contracts processed successfully!")


if __name__ == "__main__":
 main
