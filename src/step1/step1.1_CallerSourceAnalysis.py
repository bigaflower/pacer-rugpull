import os
import sys
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Set, Optional, Any, Tuple
import copy
from dataclasses import dataclass

from slither import Slither
from slither.core.cfg.node import NodeType
from slither.core.expressions import (
    CallExpression,
    Identifier,
    MemberAccess,
    AssignmentOperation
)
from slither.core.variables.local_variable import LocalVariable
from slither.core.variables.state_variable import StateVariable
from slither.core.declarations import Function, Contract, SolidityVariableComposed
from slither.slithir.operations import Assignment, InternalCall, Operation
from slither.analyses.data_dependency.data_dependency import is_dependent


try:
    PROJECT_ROOT = Path(__file__).resolve().parents[2]
except NameError:
    PROJECT_ROOT = Path.cwd()


sys.path.insert(0, str(PROJECT_ROOT / 'src'))


from utils.version_manager import init_slither as init_slither_with_version
from utils.caller_map_utils import format_function_key
from utils.path_manager import get_output_dir


OUTPUT_ROOT = get_output_dir()


@dataclass
class TaintEvent:
    """Represents a taint state change event at a specific line."""
    line: int
    tainted_vars_before: List[str]
    tainted_vars_after: List[str]
    action: str

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            'line': self.line,
            'tainted_vars_before': sorted(self.tainted_vars_before),
            'tainted_vars_after': sorted(self.tainted_vars_after),
            'action': self.action
        }


def _extract_contract_like_names(contract_path: str) -> List[str]:
    try:
        content = Path(contract_path).read_text(encoding="utf-8")
    except OSError:
        return []

    pattern = re.compile(
        r'^\s*(?:abstract\s+)?(?:contract|library|interface)\s+([A-Za-z_][A-Za-z0-9_]*)',
        re.MULTILINE,
    )
    return pattern.findall(content)


def _build_fallback_result(contract_path: str, reason: str) -> Dict[str, Any]:
    contract_names = _extract_contract_like_names(contract_path)
    if not contract_names:
        contract_names = [Path(contract_path).stem]

    caller_template = {
        "msg.sender": {"source": "msg.sender", "scope": "always"},
        "_msgSender": {"source": "msg.sender", "scope": "always"},
        "tx.origin": {"source": "tx.origin", "scope": "always"},
    }

    fallback = {}
    trimmed_reason = reason.strip().splitlines()[0][:200]
    for name in contract_names:
        fallback[name] = {
            "persistent_roles": [],
            "transient_caller_analysis": {
                "caller_map": copy.deepcopy(caller_template),
                "taint_events": {},
                "tainted_parameters": {},
                "analysis_notes": f"fallback_mode: {trimmed_reason}",
            },
            "analysis_status": "fallback",
        }

    print("⚠️  Slither analysis failed; emitting fallback caller map with default sources.")
    return fallback


class PersistentRoleAnalyzer:

    def __init__(self, slither: Slither, global_propagators: Dict[str, Dict[str, str]]):
        self.slither = slither
        self.global_propagators = global_propagators
        self.taint_sources: Set[Any] = set()

    def _global_propagator_source(self, function: Function) -> Optional[str]:
        contract_name = function.contract.name if function.contract else None
        if not contract_name:
            return None
        entries = self.global_propagators.get(function.name, {})
        return entries.get(contract_name)

    def identify_taint_sources(self, contract: Contract) -> Set[Any]:
        """Identify msg.sender and tx.origin objects."""
        sources = set()

        for function in contract.functions:
            if not function.is_implemented:
                continue

            for node in function.nodes:
                for var in node.variables_read + node.variables_written:
                    if isinstance(var, SolidityVariableComposed):
                        if var.name in ['msg.sender', 'tx.origin']:
                            sources.add(var)

        self.taint_sources = sources
        return sources

    def analyze_constructor(self, contract: Contract) -> Set[str]:
        persistent_roles = set()


        constructor = None
        for function in contract.functions:
            if function.is_constructor:
                constructor = function
                break

        if not constructor or not constructor.is_implemented:
            return persistent_roles


        self.identify_taint_sources(contract)


        functions_to_analyze = {constructor}
        analyzed = set()


        while functions_to_analyze:
            func = functions_to_analyze.pop()
            if func in analyzed:
                continue
            analyzed.add(func)

            for node in func.nodes:
                if hasattr(node, 'irs'):
                    for ir in node.irs:

                        if isinstance(ir, Assignment):
                            lvalue = ir.lvalue
                            rvalue = ir.rvalue

                            if isinstance(lvalue, StateVariable):
                                if self._is_tainted_by_source(rvalue, contract):
                                    if lvalue.name not in persistent_roles:
                                        persistent_roles.add(lvalue.name)
                                        print(f"      ✓ Persistent Role: {lvalue.name}")


                        elif isinstance(ir, InternalCall):
                            if ir.function and ir.function.is_implemented:
                                functions_to_analyze.add(ir.function)
                            else:
                                propagator_source = (
                                    self._global_propagator_source(ir.function)
                                    if ir.function else None
                                )
                                if propagator_source and ir.lvalue and isinstance(ir.lvalue, StateVariable):
                                    if ir.lvalue.name not in persistent_roles:
                                        persistent_roles.add(ir.lvalue.name)
                                        print(f"      ✓ Persistent Role: {ir.lvalue.name} (from global propagator)")

        return persistent_roles

    def _is_tainted_by_source(self, value: Any, contract: Contract) -> bool:
        """Check if value is tainted by msg.sender/tx.origin."""
        if value in self.taint_sources:
            return True

        if isinstance(value, SolidityVariableComposed):
            if value.name in ['msg.sender', 'tx.origin']:
                return True

        for source in self.taint_sources:
            if is_dependent(value, source, contract):
                return True

        return False


class TransactionScopedTaintAnalyzer:

    def __init__(self,
                 slither: Slither,
                 persistent_roles: Set[str],
                 global_propagators: Dict[str, Dict[str, str]]):
        self.slither = slither
        self.persistent_roles = persistent_roles
        self.global_propagators = global_propagators
        self.taint_sources: Set[Any] = set()
        self.propagator_functions: Dict[str, str] = {}


        self.tainted_parameters: Dict[str, Dict[int, Dict[str, Any]]] = {}

    @staticmethod
    def _format_function_key(function: Function, fallback_contract: Optional[Contract] = None) -> str:
        contract_name = None
        if function.contract:
            contract_name = function.contract.name
        elif fallback_contract:
            contract_name = fallback_contract.name
        return format_function_key(contract_name, function.full_name)

    @staticmethod
    def _contract_lineage(contract: Contract) -> List[str]:
        lineage = [contract.name]
        for parent in getattr(contract, 'inheritance', []):
            if hasattr(parent, 'name'):
                lineage.append(parent.name)
        return lineage

    def _resolve_global_propagator(self, func_name: str, contract: Contract) -> Optional[str]:
        entries = self.global_propagators.get(func_name, {})
        if not entries:
            return None
        for ancestor in self._contract_lineage(contract):
            if ancestor in entries:
                return entries[ancestor]
        return None

    def identify_taint_sources(self, contract: Contract) -> Set[Any]:
        """Identify msg.sender and tx.origin objects."""
        sources = set()

        for function in contract.functions:
            if not function.is_implemented:
                continue

            for node in function.nodes:
                for var in node.variables_read + node.variables_written:
                    if isinstance(var, SolidityVariableComposed):
                        if var.name in ['msg.sender', 'tx.origin']:
                            sources.add(var)

        self.taint_sources = sources
        return sources

    def identify_propagators(self, contract: Contract) -> Dict[str, str]:
        propagators = {}


        accessible_function_names = {f.name for f in contract.functions}


        for func_name in accessible_function_names:
            source = self._resolve_global_propagator(func_name, contract)
            if source:
                propagators[func_name] = source


        for function in contract.functions:
            if not function.is_implemented or function.is_constructor:
                continue

            func_name = function.name
            if func_name in propagators:
                continue

            for node in function.nodes:
                if node.type.name != 'RETURN':
                    continue

                for source in self.taint_sources:
                    if node.expression and is_dependent(node, source, contract):
                        propagators[func_name] = source.name
                        break

        self.propagator_functions = propagators
        return propagators

    def scan_parameter_taint_propagation(self,
                                         contract: Contract,
                                         functions_subset: Optional[Set[Function]] = None):
        print(f"   🔍 Scanning parameter-level taint propagation...")

        if functions_subset is None:
            target_functions = {f for f in contract.functions if f.is_implemented and not f.is_constructor}
        else:
            target_functions = {
                f for f in functions_subset
                if f.is_implemented and not f.is_constructor
            }


        for caller_func in target_functions:
            if not caller_func.is_implemented or caller_func.is_constructor:
                continue


            local_tainted: Set[str] = set()

            for node in caller_func.nodes:
                if not hasattr(node, 'irs'):
                    continue

                for ir in node.irs:

                    if isinstance(ir, Assignment):
                        lvalue = ir.lvalue
                        rvalue = ir.rvalue

                        if isinstance(lvalue, LocalVariable):
                            var_name = lvalue.name
                            if self._is_transient_taint(rvalue, local_tainted, contract):
                                local_tainted.add(var_name)
                            else:
                                local_tainted.discard(var_name)

                    elif isinstance(ir, InternalCall):

                        if ir.function and ir.function.name in self.propagator_functions:
                            if ir.lvalue:
                                var_name = str(ir.lvalue)
                                local_tainted.add(var_name)


                        if ir.function and ir.function.is_implemented and (
                            ir.function in target_functions
                        ):
                            callee_key = self._format_function_key(ir.function, contract)


                            if hasattr(ir, 'arguments') and ir.arguments:
                                for param_idx, arg in enumerate(ir.arguments):
                                    arg_str = str(arg)


                                    is_tainted = False
                                    taint_source = None

                                    if isinstance(arg, LocalVariable) and arg.name in local_tainted:
                                        is_tainted = True
                                        taint_source = 'msg.sender'
                                    elif arg_str in local_tainted:
                                        is_tainted = True
                                        taint_source = 'msg.sender'
                                    elif self._is_transient_taint(arg, local_tainted, contract):
                                        is_tainted = True
                                        taint_source = 'msg.sender'

                                    if is_tainted and callee_key:

                                        if callee_key not in self.tainted_parameters:
                                            self.tainted_parameters[callee_key] = {}

                                        if param_idx not in self.tainted_parameters[callee_key]:
                                            self.tainted_parameters[callee_key][param_idx] = {
                                                'source': taint_source,
                                                'call_sites': []
                                            }


                                        caller_key = self._format_function_key(caller_func, contract)
                                        call_site = f"{caller_key} line {self._get_line_number(node) or 'unknown'}"
                                        call_sites = self.tainted_parameters[callee_key][param_idx]['call_sites']
                                        if call_site not in call_sites:
                                            call_sites.append(call_site)


        if self.tainted_parameters:
            print(f"   ✓ Found {sum(len(params) for params in self.tainted_parameters.values())} tainted parameter(s):")
            for func_name, params in self.tainted_parameters.items():
                for param_idx, info in params.items():
                    print(f"      • {func_name}(param#{param_idx}) ← {info['source']} from {len(info['call_sites'])} call site(s)")
        else:
            print(f"   ℹ️  No parameter-level taint propagation detected")

    def determine_function_scope(self, contract: Contract) -> Tuple[List[Function], Set[Function]]:
        entry_functions = [
            f for f in contract.functions
            if f.is_implemented
            and not f.is_constructor
            and f.visibility in ('public', 'external')
        ]

        if not entry_functions:

            entry_functions = [
                f for f in contract.functions
                if f.is_implemented and not f.is_constructor
            ]

        reachable: Set[Function] = set()
        queue: List[Function] = list(entry_functions)

        while queue:
            func = queue.pop()
            if func in reachable:
                continue
            reachable.add(func)

            for node in func.nodes:
                if not hasattr(node, 'internal_calls'):
                    continue

                for call in node.internal_calls:
                    callee = getattr(call, 'function', None)
                    if (callee
                        and hasattr(callee, 'is_implemented')
                        and callee.is_implemented
                        and not callee.is_constructor):
                        queue.append(callee)

        return entry_functions, reachable

    def analyze_function(self, function: Function, contract: Contract) -> Dict[str, Any]:
        if not function.is_implemented or function.is_constructor:
            return {'caller_map': {}, 'taint_events': [], 'variable_scopes': {}}

        caller_map = {}
        taint_events = []
        tainted_vars: Set[str] = set()


        variable_scopes = {}


        func_key = self._format_function_key(function, contract)
        if func_key in self.tainted_parameters:
            for param_idx, param_info in self.tainted_parameters[func_key].items():
                if param_idx < len(function.parameters):
                    param = function.parameters[param_idx]
                    param_name = param.name
                    tainted_vars.add(param_name)
                    caller_map[param_name] = param_info['source']
                    print(f"      ✓ Parameter '{param_name}' (#{param_idx}) is tainted by {param_info['source']}")


        for node in function.nodes:
            line_number = self._get_line_number(node)
            if line_number is None:
                continue

            vars_before = tainted_vars.copy()


            if hasattr(node, 'irs'):
                for ir in node.irs:
                    self._process_ir_operation(ir, tainted_vars, caller_map, contract)

            vars_after = tainted_vars.copy()


            if node.type.name not in ['ENDIF', 'ENDLOOP', 'STARTLOOP', 'IFLOOP']:
                for var in vars_after:
                    if not var.startswith('TMP_'):
                        self._update_variable_scope(var, node, variable_scopes)


            newly_tainted = {v for v in (vars_after - vars_before) if not v.startswith('TMP_')}
            newly_cleansed = {v for v in (vars_before - vars_after) if not v.startswith('TMP_')}

            if newly_tainted or newly_cleansed:

                vars_before_filtered = [v for v in vars_before if not v.startswith('TMP_')]
                vars_after_filtered = [v for v in vars_after if not v.startswith('TMP_')]

                action = self._describe_change(
                    ir if 'ir' in locals() else None,
                    newly_tainted,
                    newly_cleansed
                )

                taint_events.append(TaintEvent(
                    line=line_number,
                    tainted_vars_before=vars_before_filtered,
                    tainted_vars_after=vars_after_filtered,
                    action=action
                ))


        filtered_caller_map = {k: v for k, v in caller_map.items() if not k.startswith('TMP_')}
        filtered_variable_scopes = {k: v for k, v in variable_scopes.items() if not k.startswith('TMP_')}

        return {
            'caller_map': filtered_caller_map,
            'taint_events': [event.to_dict() for event in taint_events],
            'variable_scopes': filtered_variable_scopes
        }

    def _process_ir_operation(self,
                              ir: Operation,
                              tainted_vars: Set[str],
                              caller_map: Dict[str, str],
                              contract: Contract):
        if isinstance(ir, Assignment):
            lvalue = ir.lvalue
            rvalue = ir.rvalue


            if isinstance(lvalue, LocalVariable):
                var_name = lvalue.name


                if self._is_transient_taint(rvalue, tainted_vars, contract):
                    tainted_vars.add(var_name)


                    if str(rvalue) in caller_map:
                        caller_map[var_name] = caller_map[str(rvalue)]
                    else:
                        source = self._get_taint_source(rvalue, tainted_vars)
                        if source:
                            caller_map[var_name] = source
                else:

                    tainted_vars.discard(var_name)
                    caller_map.pop(var_name, None)

        elif isinstance(ir, InternalCall):

            if ir.function and ir.function.name in self.propagator_functions:
                if ir.lvalue:


                    var_name = str(ir.lvalue)
                    tainted_vars.add(var_name)
                    caller_map[var_name] = self.propagator_functions[ir.function.name]

    def _is_transient_taint(self,
                           value: Any,
                           tainted_vars: Set[str],
                           contract: Contract) -> bool:

        if value in self.taint_sources:
            return True

        if isinstance(value, SolidityVariableComposed):
            if value.name in ['msg.sender', 'tx.origin']:
                return True


        if isinstance(value, StateVariable):
            return False


        if isinstance(value, LocalVariable):
            return value.name in tainted_vars


        if str(value) in tainted_vars:
            return True


        for source in self.taint_sources:
            if is_dependent(value, source, contract):


                return True

        return False

    def _get_taint_source(self,
                         value: Any,
                         tainted_vars: Set[str]) -> Optional[str]:
        """Get the ultimate taint source name."""
        if isinstance(value, SolidityVariableComposed):
            if value.name in ['msg.sender', 'tx.origin']:
                return value.name

        if isinstance(value, LocalVariable):
            if value.name in tainted_vars:
                return 'msg.sender'

        return 'msg.sender'

    def _get_line_number(self, node) -> Optional[int]:
        """Extract line number from node source mapping."""
        if hasattr(node, 'source_mapping') and node.source_mapping:
            if hasattr(node.source_mapping, 'lines'):
                lines = node.source_mapping.lines
            elif isinstance(node.source_mapping, dict):
                lines = node.source_mapping.get('lines', [])
            else:
                return None

            if lines and len(lines) > 0:
                return lines[0]

        return None

    def _get_source_location(self, node) -> Optional[Dict[str, Any]]:
        if not hasattr(node, 'source_mapping') or not node.source_mapping:
            return None

        mapping = node.source_mapping
        location = {}


        if hasattr(mapping, 'lines') and mapping.lines:
            location['line'] = mapping.lines[0]
        elif isinstance(mapping, dict) and 'lines' in mapping:
            lines = mapping.get('lines', [])
            if lines:
                location['line'] = lines[0]


        if hasattr(mapping, 'start'):
            location['start'] = mapping.start
        if hasattr(mapping, 'length'):
            location['length'] = mapping.length


        if hasattr(node, 'expression') and node.expression:
            stmt = str(node.expression)

            location['statement'] = stmt[:80] + '...' if len(stmt) > 80 else stmt

        return location if location else None

    def _update_variable_scope(self, var_name: str, node, variable_scopes: Dict):
        location = self._get_source_location(node)
        if not location:
            return

        if var_name not in variable_scopes:

            variable_scopes[var_name] = {
                'first_location': location.copy(),
                'last_location': location.copy()
            }
        else:

            scope = variable_scopes[var_name]


            if 'start' in location and 'start' in scope['last_location']:

                if location['start'] > scope['last_location']['start']:
                    scope['last_location'] = location.copy()
            elif 'line' in location and 'line' in scope['last_location']:

                if location['line'] > scope['last_location']['line']:
                    scope['last_location'] = location.copy()

    def _format_scope_string(self, scope_info: Dict) -> str:
        first = scope_info['first_location']
        last = scope_info['last_location']

        first_line = first.get('line')
        last_line = last.get('line')
        first_start = first.get('start')
        last_end = last.get('start', 0) + last.get('length', 0)


        if first_start is not None and last_end is not None:
            if first_line == last_line:

                result = f"L{first_line}[{first_start}-{last_end}]"
            else:

                result = f"L{first_line}-L{last_line}[{first_start}-{last_end}]"


        elif first_line is not None and last_line is not None:
            if first_line == last_line:
                result = f"L{first_line}"
            else:
                result = f"L{first_line}-L{last_line}"
        else:
            result = "unknown"


        if 'statement' in first and first['statement']:
            result += f" | START: {first['statement']}"


        if 'statement' in last and last['statement']:
            if first != last:
                result += f" | END: {last['statement']}"

        return result

    def _describe_change(self,
                        ir: Optional[Operation],
                        newly_tainted: Set[str],
                        newly_cleansed: Set[str]) -> str:
        """Generate human-readable description of taint change."""
        if newly_tainted:
            vars_str = "', '".join(newly_tainted)
            if ir and isinstance(ir, InternalCall):
                func_name = ir.function.name if ir.function else "unknown"
                return f"TAINTED: Variable(s) '{vars_str}' are Transient Callers, assigned from propagator '{func_name}'."
            return f"TAINTED: Variable(s) '{vars_str}' are Transient Callers, assigned from msg.sender."

        if newly_cleansed:
            vars_str = "', '".join(newly_cleansed)
            return f"CLEANSED: Variable(s) '{vars_str}' reassigned with non-transient value."

        return "State changed."


def normalize(name):
    """Normalize name to lowercase."""
    return str(name).lower().replace("()", "").replace(" ", "").strip()


def build_legacy_caller_map(contract: Contract) -> Dict[str, str]:
    known_callers = {}


    for function in contract.functions:
        if not hasattr(function, 'nodes'):
            continue

        for node in function.nodes:
            if not hasattr(node, 'expression') or node.expression is None:
                continue

            expr_str = str(node.expression).lower()
            if "msg.sender" in expr_str:
                known_callers["msg.sender"] = "msg.sender"
            if "tx.origin" in expr_str:
                known_callers["tx.origin"] = "tx.origin"


    for function in contract.functions:
        if function.is_constructor or not function.is_implemented:
            continue

        func_name = normalize(function.name)
        if func_name in known_callers:
            continue

        for node in function.nodes:
            if node.type != NodeType.RETURN or not node.expression:
                continue

            expr_str = str(node.expression).lower()
            if "msg.sender" in expr_str:
                known_callers[func_name] = "msg.sender"
                break
            if "tx.origin" in expr_str:
                known_callers[func_name] = "tx.origin"
                break

    return known_callers


class GlobalTaintPropagatorDiscovery:

    def __init__(self, slither: Slither):
        self.slither = slither
        self.taint_sources: Set[Any] = set()
        self.global_propagators: Dict[str, Dict[str, str]] = defaultdict(dict)

    def identify_global_taint_sources(self) -> Set[Any]:
        sources = set()

        for contract in self.slither.contracts:
            for function in contract.functions:
                if not function.is_implemented:
                    continue

                for node in function.nodes:
                    for var in node.variables_read + node.variables_written:
                        if isinstance(var, SolidityVariableComposed):
                            if var.name in ['msg.sender', 'tx.origin']:
                                sources.add(var)

        self.taint_sources = sources
        return sources

    def discover_global_propagators(self) -> Dict[str, Dict[str, str]]:
        print(f"\n{'='*60}")
        print(f"🌍 Stage 0: Global Taint Propagator Discovery")
        print(f"{'='*60}")


        self.identify_global_taint_sources()
        print(f"   ✓ Identified {len(self.taint_sources)} global taint source(s)")


        iteration = 0
        previous_count = 0

        while True:
            iteration += 1
            print(f"\n   🔄 Iteration {iteration}: Scanning all contracts...")


            for contract in self.slither.contracts:
                self._scan_contract_for_propagators(contract)

            current_count = self._count_propagators()

            if current_count == previous_count:

                print(f"   ✓ Fixed point reached after {iteration} iteration(s)")
                break

            print(f"   ℹ️  Found {current_count - previous_count} new propagator(s)")
            previous_count = current_count

            if iteration > 10:
                print(f"   ⚠️  Iteration limit reached")
                break

        print(f"\n   ✅ Global Propagator Discovery Complete")
        print(f"   📊 Total: {self._count_propagators()} propagator definition(s)")

        if self.global_propagators:
            print(f"\n   Global Propagators:")
            for func_name, entries in sorted(self.global_propagators.items()):
                for contract_name, source in sorted(entries.items()):
                    print(f"      • {contract_name}.{func_name} → {source}")

        return self.global_propagators

    def _count_propagators(self) -> int:
        return sum(len(entries) for entries in self.global_propagators.values())

    def _scan_contract_for_propagators(self, contract: Contract):
        for function in contract.functions:
            if not function.is_implemented or function.is_constructor:
                continue

            func_name = function.name


            existing_entries = self.global_propagators.get(func_name, {})
            if contract.name in existing_entries:
                continue


            for node in function.nodes:
                if node.type != NodeType.RETURN or not node.expression:
                    continue

                expr_str = str(node.expression).lower()


                if "msg.sender" in expr_str:
                    self.global_propagators[func_name][contract.name] = "msg.sender"
                    break
                elif "tx.origin" in expr_str:
                    self.global_propagators[func_name][contract.name] = "tx.origin"
                    break


                for source in self.taint_sources:
                    try:
                        if is_dependent(node, source, contract):
                            self.global_propagators[func_name][contract.name] = source.name
                            break
                    except:
                        pass


                if contract.name not in self.global_propagators.get(func_name, {}):
                    for known_func, known_sources in self.global_propagators.items():
                        if known_func.lower() in expr_str:
                            inherited_source = next(iter(known_sources.values()))
                            self.global_propagators[func_name][contract.name] = inherited_source
                            break


def analyze_contract_file(contract_path: str) -> Dict[str, Any]:
    print(f"\n{'#'*60}")
    print(f"📄 Analyzing: {os.path.basename(contract_path)}")
    print(f"{'#'*60}")


    print(f"\n{'='*60}")
    print(f"📦 Initializing Slither with Version Management")
    print(f"{'='*60}")

    slither = init_slither_with_version(contract_path)
    if slither is None:
        print(f"❌ Failed to initialize Slither for {contract_path}")
        return _build_fallback_result(contract_path, "Slither initialization failed")


    global_discovery = GlobalTaintPropagatorDiscovery(slither)
    global_propagators = global_discovery.discover_global_propagators()

    all_results = {}

    for contract in slither.contracts:


        if contract.is_interface:
            print(f"\n⏭️  Skipping interface: {contract.name}")
            continue

        print(f"\n{'='*60}")
        print(f"🔍 Analyzing Contract: {contract.name}")
        print(f"{'='*60}")


        print(f"\n📌 Stage 1: Persistent Role Identification")
        print(f"   Analyzing constructor for deployment-time roles...")

        phase1_analyzer = PersistentRoleAnalyzer(slither, global_propagators)
        persistent_roles = phase1_analyzer.analyze_constructor(contract)

        if persistent_roles:
            print(f"   ✓ Found {len(persistent_roles)} persistent role(s)")
        else:
            print(f"   ℹ️  No persistent roles found")


        print(f"\n📌 Stage 2: Transaction-Scoped Taint Analysis (Inheritance-Aware)")
        print(f"   Each function simulates an isolated transaction...")
        total_global = sum(len(entries) for entries in global_propagators.values())
        print(f"   Using {total_global} global propagator definition(s) for inheritance awareness")

        phase2_analyzer = TransactionScopedTaintAnalyzer(slither, persistent_roles, global_propagators)
        phase2_analyzer.identify_taint_sources(contract)
        propagators = phase2_analyzer.identify_propagators(contract)

        if propagators:
            print(f"   ✓ Available propagators (global + local): {len(propagators)}")

        entry_functions, reachable_functions = phase2_analyzer.determine_function_scope(contract)
        if entry_functions:
            print(f"   ✓ Entry points detected: {len(entry_functions)}")
        if reachable_functions:
            print(f"   ✓ Reachable functions to analyze: {len(reachable_functions)}")


        phase2_analyzer.scan_parameter_taint_propagation(contract, reachable_functions)


        base_caller_map = {}


        for source in phase2_analyzer.taint_sources:
            if hasattr(source, 'name'):
                base_caller_map[source.name] = source.name


        base_caller_map.update(propagators)


        transient_analysis = {
            'caller_map': base_caller_map.copy(),
            'taint_events': {}
        }

        function_count = 0
        taint_event_count = 0


        all_variable_scopes = {}

        for function in contract.functions:
            if function.is_constructor or not function.is_implemented:
                continue

            if function not in reachable_functions:
                continue

            result = phase2_analyzer.analyze_function(function, contract)


            for var_name, source in result['caller_map'].items():
                if var_name not in transient_analysis['caller_map']:
                    transient_analysis['caller_map'][var_name] = source


            func_sig = format_function_key(contract.name, function.full_name)
            for var_name, scope_info in result['variable_scopes'].items():
                if var_name not in all_variable_scopes:
                    all_variable_scopes[var_name] = {}
                all_variable_scopes[var_name][func_sig] = scope_info


            if result['taint_events']:
                func_sig_full = f"{contract.name}.{function.full_name}"
                transient_analysis['taint_events'][func_sig_full] = result['taint_events']
                function_count += 1
                taint_event_count += len(result['taint_events'])

        print(f"   ✓ Analyzed {len(reachable_functions)} function(s)")
        print(f"   ✓ Found {taint_event_count} taint event(s) in {function_count} function(s)")


        structured_caller_map = {}
        for var_name, source in transient_analysis['caller_map'].items():
            if var_name in all_variable_scopes:

                scopes = []
                for func_name, scope_info in all_variable_scopes[var_name].items():

                    scope_str = phase2_analyzer._format_scope_string(scope_info)
                    scopes.append(f"{func_name}:{scope_str}")
                structured_caller_map[var_name] = {
                    'source': source,
                    'scope': scopes if len(scopes) > 1 else scopes[0]
                }
            else:

                structured_caller_map[var_name] = {
                    'source': source,
                    'scope': 'always'
                }


        transient_analysis['caller_map'] = structured_caller_map


        if phase2_analyzer.tainted_parameters:
            transient_analysis['tainted_parameters'] = phase2_analyzer.tainted_parameters


        all_results[contract.name] = {
            'persistent_roles': sorted(list(persistent_roles)),
            'transient_caller_analysis': transient_analysis
        }

    return all_results


def find_all_contracts(base_dir="../../contracts"):
    """Auto-discover all .sol files in contracts directory."""
    script_dir = Path(__file__).parent.absolute()
    contracts_dir = (script_dir / base_dir).resolve()

    if not contracts_dir.exists():
        print(f"❌ Contracts directory not found: {contracts_dir}")
        return []

    sol_files = list(contracts_dir.glob("**/*.sol"))
    return [str(f) for f in sol_files]


def analyze_all_contracts(output_dir=None):
    """Auto-scan and analyze all contracts."""
    sol_files = find_all_contracts()

    if not sol_files:
        print("❌ No Solidity contracts found in contracts/ directory")
        return {}

    print(f"\n{'='*60}")
    print(f"🔍 Found {len(sol_files)} Solidity file(s)")
    print(f"{'='*60}")
    for i, f in enumerate(sol_files, 1):
        print(f"   {i}. {os.path.basename(f)}")

    if output_dir:
        base_output_path = Path(output_dir).resolve()
    else:
        base_output_path = OUTPUT_ROOT

    all_results = {}
    saved_files = []
    success_contracts = []
    fallback_contracts = []
    failed_contracts = []

    for sol_file in sol_files:
        contract_name = os.path.basename(sol_file).replace('.sol', '')
        file_results = analyze_contract_file(sol_file)

        if file_results:

            is_fallback = any(
                contract_data.get('analysis_status') == 'fallback'
                for contract_data in file_results.values()
                if isinstance(contract_data, dict)
            )

            if is_fallback:
                fallback_contracts.append(contract_name)
            else:
                success_contracts.append(contract_name)


            contract_output_dir = base_output_path / contract_name / "step1"
            contract_output_dir.mkdir(parents=True, exist_ok=True)

            output_file = contract_output_dir / "step1.1_caller_source.json"

            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump({contract_name: file_results}, f, indent=2, ensure_ascii=False)

            saved_files.append(str(output_file))
            print(f"💾 Saved: {output_file.relative_to(PROJECT_ROOT)}")
        else:
            failed_contracts.append(contract_name)

    print(f"\n{'='*60}")
    print(f"✅ Analysis Complete!")
    print(f"{'='*60}")
    print(f"📊 Statistics:")
    print(f"   • Total contracts: {len(sol_files)}")
    print(f"   • ✅ Successful: {len(success_contracts)} ({len(success_contracts)/len(sol_files)*100:.1f}%)")
    print(f"   • ⚠️  Fallback mode: {len(fallback_contracts)} ({len(fallback_contracts)/len(sol_files)*100:.1f}%)")
    print(f"   • ❌ Failed: {len(failed_contracts)} ({len(failed_contracts)/len(sol_files)*100:.1f}%)")
    print(f"📁 Output directory: {base_output_path}")
    print(f"📄 Generated {len(saved_files)} file(s)")

    if fallback_contracts:
        print(f"\n⚠️  Contracts in fallback mode (compilation issues):")
        for name in fallback_contracts:
            print(f"   • {name}")

    if failed_contracts:
        print(f"\n❌ Failed contracts (no output generated):")
        for name in failed_contracts:
            print(f"   • {name}")

    print(f"{'='*60}")

    return all_results


def main():
    print("\n" + "="*60)
    print("🚀 High-Precision Transient Caller Analysis Engine")
    print("   (Inheritance-Aware Architecture)")
    print("="*60)
    print("Multi-Stage Analysis Strategy:")
    print("  Stage 0: Global Taint Propagator Discovery (NEW!)")
    print("           → Handles inheritance chains globally")
    print("  Stage 1: Persistent Role Identification (Constructor)")
    print("  Stage 2: Transaction-Scoped Taint Analysis")
    print()
    print("Transaction Scope Principle:")
    print("  • Each function simulates an ISOLATED transaction")
    print("  • State variables are CLEAN (do not propagate taint)")
    print("  • Only msg.sender/tx.origin derivatives are tainted")
    print()
    print("Inheritance Awareness:")
    print("  • Global discovery BEFORE contract analysis")
    print("  • Handles BaseContract._msgSender() -> msg.sender")
    print("  • ChildContract calls are correctly tainted")
    print("="*60)

    if len(sys.argv) > 1:
        path = sys.argv[1]

        contract_address = sys.argv[2] if len(sys.argv) > 2 else None

        if os.path.isfile(path):
            result = analyze_contract_file(path)

            base_output_path = OUTPUT_ROOT


            if contract_address:
                contract_name = contract_address
                print(f"ℹ️  Using contract address for output: {contract_address}")
            else:
                contract_name = os.path.basename(path).replace('.sol', '')
                print(f"ℹ️  Using filename for output: {contract_name}")

            contract_output_dir = base_output_path / contract_name / "step1"
            contract_output_dir.mkdir(parents=True, exist_ok=True)

            output_file = contract_output_dir / "step1.1_caller_source.json"


            actual_contract_name = os.path.basename(path).replace('.sol', '')
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump({actual_contract_name: result}, f, indent=2, ensure_ascii=False)

            print(f"✅ Results saved to: {output_file.relative_to(PROJECT_ROOT)}")

        elif os.path.isdir(path):
            print(f"📁 Scanning directory: {path}")
            find_all_contracts.__defaults__ = (str(Path(path).resolve()),)
            analyze_all_contracts()
        else:
            print(f"❌ Invalid path: {path}")
            sys.exit(1)
    else:
        print("ℹ️  Auto mode: Scanning contracts/ directory...")
        analyze_all_contracts()


if __name__ == "__main__":
    main()
