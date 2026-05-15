import json
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional, Set, Tuple
from dataclasses import dataclass


try:
    PROJECT_ROOT = Path(__file__).resolve().parents[2]
except NameError:
    PROJECT_ROOT = Path.cwd()

sys.path.insert(0, str(PROJECT_ROOT / 'src'))

from slither.slither import Slither
from slither.core.cfg.node import Node, NodeType
from slither.core.declarations import (
    Modifier, Function, Contract,
    SolidityVariableComposed, SolidityFunction
)
from slither.core.variables.state_variable import StateVariable
from slither.core.variables.local_variable import LocalVariable
from slither.core.expressions import (
    CallExpression, MemberAccess, Identifier,
    BinaryOperation, UnaryOperation, IndexAccess
)
from slither.slithir.operations import (
    Operation, Assignment, Binary, Unary,
    InternalCall, HighLevelCall, LibraryCall,
    Index, Member, SolidityCall
)
from slither.slithir.variables import ReferenceVariable
from slither.analyses.data_dependency.data_dependency import is_dependent
from slither.exceptions import SlitherError


from utils.version_manager import init_slither
from utils.caller_map_utils import build_caller_context, format_function_key
from utils.path_manager import get_output_dir


def setup_project_paths() -> Tuple[Optional[Path], Optional[Path], Optional[Path]]:
    try:

        project_root = Path(__file__).resolve().parents[2]

        contracts_dir = project_root / "contracts"
        output_dir = get_output_dir()

        if not contracts_dir.exists():
            print(f"❌ Error: 'contracts' directory not found in {project_root}.")
            return None, None, None

        output_dir.mkdir(parents=True, exist_ok=True)
        return project_root, contracts_dir, output_dir
    except IndexError:
        print("❌ Error: Cannot determine project root. Ensure script is in 'src/step1/' directory.")
        return None, None, None


def load_caller_analysis(contract_name: str, output_dir: Path) -> Tuple[Dict[str, Any], Set[str]]:
    source_file = output_dir / contract_name / "step1" / "step1.1_caller_source.json"

    if not source_file.exists():
        print(f"  ⚠️  Warning: step1.1 output not found: {source_file.name}")
        return {}, set()

    try:
        with open(source_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError:
        print(f"  ⚠️  Warning: Cannot parse {source_file.name}")
        return {}, set()


    contract_data = data.get(contract_name, {})

    caller_context: Dict[str, Any] = {}
    persistent_roles = set()

    for sub_contract_name, analysis in contract_data.items():
        if not isinstance(analysis, dict):
            continue


        roles = analysis.get('persistent_roles', [])
        if isinstance(roles, list):
            persistent_roles.update(roles)


        pass

    if contract_data:
        caller_context = build_caller_context({contract_name: contract_data})
    else:
        caller_context = {
            'global_symbols': {},
            'function_symbols': {},
            'wrapper_functions': set(),
            'tainted_parameters': {},
            'symbol_count': 0,
        }

    return caller_context, persistent_roles


@dataclass
class ConditionExpression:
    """Represents a single condition expression extracted from code"""
    node: Node
    expression: Any
    source_code: str
    line: int
    node_type: str


    depends_on_caller: bool = False
    depends_on_state: bool = False
    state_variables: List[str] = None
    is_state_lock: bool = False
    is_permission: bool = False

    def __post_init__(self):
        if self.state_variables is None:
            self.state_variables = []


class GuardStatementScanner:

    def __init__(self, contract: Contract, sol_path: Path):
        self.contract = contract
        self.sol_path = sol_path

    def scan_function(self, function: Function, include_modifiers: bool = True) -> List[ConditionExpression]:
        conditions = []
        visited = set()


        conditions.extend(self._scan_unit(function, visited))


        if include_modifiers:
            for modifier in function.modifiers:
                conditions.extend(self._scan_unit(modifier, visited))

        return conditions

    def _scan_unit(self, unit: Function | Modifier, visited: Set[str]) -> List[ConditionExpression]:
        """Recursively scan a function or modifier for conditions"""
        unit_id = f"{unit.contract.name if hasattr(unit, 'contract') and unit.contract else 'Unknown'}.{unit.name}"

        if unit_id in visited:
            return []
        visited.add(unit_id)

        conditions = []
        processed_lines = set()

        for node in unit.nodes:

            if not self._is_guard_node(node):
                continue


            line = self._get_line_number(node)
            if line in processed_lines:
                continue


            condition = self._extract_condition(node)
            if condition:
                conditions.append(condition)
                processed_lines.add(line)


        for call in unit.internal_calls:
            if (hasattr(call, 'function') and call.function and
                hasattr(call.function, 'is_implemented') and call.function.is_implemented):
                conditions.extend(self._scan_unit(call.function, visited))

        return conditions

    def _is_guard_node(self, node: Node) -> bool:
        """Check if node represents a guard statement"""
        node_type_str = str(node.type).upper()


        if 'END' in node_type_str:
            return False


        if 'EXPRESSION' in node_type_str:
            if node.expression:
                expr_str = str(node.expression).lower()
                if any(kw in expr_str for kw in ['require', 'assert', 'revert']):
                    return True


        if 'IF' in node_type_str:
            return True

        return False

    def _extract_condition(self, node: Node) -> Optional[ConditionExpression]:
        source_code = self._get_source_code(node)
        line = self._get_line_number(node)

        if not source_code:
            return None


        actual_condition, actual_source = self._analyze_guard_control_flow(node, source_code)

        return ConditionExpression(
            node=node,
            expression=actual_condition,
            source_code=actual_source[:250],
            line=line,
            node_type=str(node.type)
        )

    def _get_source_code(self, node: Node) -> str:
        """Get source code for a node"""
        if node.expression:
            return str(node.expression)

        if node.source_mapping and node.source_mapping.lines:
            lines = node.source_mapping.lines
            if lines:
                try:
                    with open(self.sol_path, 'r', encoding='utf-8') as f:
                        file_lines = f.readlines()
                        code_lines = file_lines[min(lines)-1 : max(lines)]
                        return ''.join(code_lines).strip()
                except (IOError, IndexError):
                    pass

        return ""

    def _analyze_guard_control_flow(self, node: Node, source_code: str) -> tuple[Any, str]:
        node_type_str = str(node.type).upper()


        if 'EXPRESSION' in node_type_str:
            expr_str = str(node.expression).lower() if node.expression else ''
            if 'require' in expr_str or 'assert' in expr_str:


                return (node.expression, source_code)


        if 'IF' in node_type_str:

            true_leads_to_revert = self._branch_leads_to_revert(node, branch='true')
            false_leads_to_revert = self._branch_leads_to_revert(node, branch='false')

            if true_leads_to_revert and not false_leads_to_revert:


                negated_source = self._negate_condition_str(source_code)
                return (node.expression, negated_source)
            elif false_leads_to_revert and not true_leads_to_revert:


                return (node.expression, source_code)


        return (node.expression, source_code)

    def _branch_leads_to_revert(self, if_node: Node, branch: str) -> bool:
        if not hasattr(if_node, 'sons') or not if_node.sons:
            return False


        if len(if_node.sons) < 2:
            return False

        target_node = if_node.sons[0] if branch == 'true' else if_node.sons[1] if len(if_node.sons) > 1 else None

        if not target_node:
            return False


        return self._node_leads_to_revert(target_node, visited=set(), depth=0, max_depth=10)

    def _node_leads_to_revert(self, node: Node, visited: set, depth: int, max_depth: int) -> bool:
        if depth > max_depth:
            return False

        node_id = id(node)
        if node_id in visited:
            return False
        visited.add(node_id)


        node_type_str = str(node.type).upper()
        if 'THROW' in node_type_str:
            return True


        if node.expression:
            expr_str = str(node.expression).lower()
            if 'revert' in expr_str:
                return True


        if hasattr(node, 'sons'):
            for son in node.sons:
                if self._node_leads_to_revert(son, visited, depth + 1, max_depth):
                    return True

        return False

    def _negate_condition_str(self, condition_str: str) -> str:
        condition_str = condition_str.strip()


        if condition_str.startswith('!'):

            return condition_str[1:].strip()


        if ' ' in condition_str and not condition_str.startswith('('):
            return f"({condition_str})"
        else:
            return f"!{condition_str}"

    def _get_line_number(self, node: Node) -> int:
        """Get line number for a node"""
        if node.source_mapping and node.source_mapping.lines:
            return node.source_mapping.lines[0]
        return -1


class PermissionHeuristicFilter:

    def __init__(self,
                 contract: Contract,
                 caller_context: Dict[str, Any],
                 persistent_roles: Set[str]):
        self.contract = contract
        self.caller_context = caller_context or {}
        self.persistent_roles = persistent_roles
        self.global_symbols = set(
            (self.caller_context.get('global_symbols') or {}).keys()
        )
        self.function_symbols: Dict[str, Dict[str, Any]] = (
            self.caller_context.get('function_symbols') or {}
        )

    def _function_key(self, function: Optional[Function]) -> Optional[str]:
        if not function:
            return None
        contract_name = function.contract.name if function.contract else self.contract.name
        return format_function_key(contract_name, function.full_name)

    def _get_function_caller_symbols(self, function: Optional[Function]) -> Set[str]:
        symbols = set(self.global_symbols)
        func_key = self._function_key(function)
        if func_key and func_key in self.function_symbols:
            symbols.update(self.function_symbols[func_key].keys())
        return symbols

    def filter_conditions(self, conditions: List[ConditionExpression]) -> List[ConditionExpression]:
        for condition in conditions:
            condition.depends_on_caller = self._depends_on_caller(condition)
            condition.depends_on_state, condition.state_variables = self._depends_on_state(condition)
            condition.is_state_lock = self._is_state_lock_condition(condition)
            condition.is_permission = self._is_permission_condition(condition)

        return conditions

    def _depends_on_caller(self, condition: ConditionExpression) -> bool:

        source_lower = condition.source_code.lower()
        function = getattr(condition.node, 'function', None)
        caller_symbols = self._get_function_caller_symbols(function)

        for symbol in caller_symbols:
            if symbol in source_lower:
                return True
            symbol_base = symbol.replace('()', '').replace('(', '').replace(')', '')
            if symbol_base in source_lower:
                return True

        if condition.node and condition.node.variables_read:
            for var in condition.node.variables_read:
                var_name = str(var.name).lower() if hasattr(var, 'name') else str(var).lower()
                if var_name in caller_symbols:
                    return True


                if isinstance(var, SolidityVariableComposed):
                    if var.name in ['msg.sender', 'tx.origin']:
                        return True

        return False

    def _depends_on_state(self, condition: ConditionExpression) -> Tuple[bool, List[str]]:
        state_vars = []

        if not condition.node:
            return False, state_vars


        for var in condition.node.variables_read:
            if isinstance(var, StateVariable):
                state_vars.append(var.name)


        if hasattr(condition.node, 'irs'):
            for ir in condition.node.irs:
                state_vars.extend(self._extract_state_from_ir(ir))


        state_vars.extend(self._extract_state_from_function_calls(condition))


        state_vars = list(set(state_vars))


        if state_vars:
            filtered_vars = self._apply_mapping_filter(condition, state_vars)
            return len(filtered_vars) > 0, filtered_vars

        return False, []

    def _extract_state_from_ir(self, ir: Operation) -> List[str]:
        """Extract state variables from SlithIR operation"""
        state_vars = []


        if hasattr(ir, 'read'):
            for var in ir.read:
                if isinstance(var, StateVariable):
                    state_vars.append(var.name)


        if isinstance(ir, Index):
            if isinstance(ir.variable_left, StateVariable):
                state_vars.append(ir.variable_left.name)


        if isinstance(ir, Member):
            if isinstance(ir.variable_left, StateVariable):
                state_vars.append(ir.variable_left.name)

        return state_vars

    def _apply_mapping_filter(self, condition: ConditionExpression, state_vars: List[str]) -> List[str]:
        filtered = []

        for var_name in state_vars:

            state_var = self._find_state_variable(var_name)
            if not state_var:

                filtered.append(var_name)
                continue


            var_type_str = str(state_var.type).lower()

            if 'mapping' in var_type_str:


                if 'bool' in var_type_str:

                    filtered.append(var_name)
                else:

                    if not self._is_used_in_math(condition, var_name):
                        filtered.append(var_name)

            else:

                filtered.append(var_name)

        return filtered

    def _find_state_variable(self, var_name: str) -> Optional[StateVariable]:
        """Find state variable by name in contract"""
        for var in self.contract.state_variables:
            if var.name == var_name:
                return var


        for parent in self.contract.inheritance:
            for var in parent.state_variables:
                if var.name == var_name:
                    return var

        return None

    def _is_used_in_math(self, condition: ConditionExpression, var_name: str) -> bool:
        if not condition.node or not hasattr(condition.node, 'irs'):
            return False


        for ir in condition.node.irs:
            if isinstance(ir, Binary):

                op_str = str(ir.type).lower()
                math_ops = ['add', 'sub', 'mul', 'div', 'mod', 'greater', 'less', 'geq', 'leq']

                if any(math_op in op_str for math_op in math_ops):

                    if hasattr(ir, 'variable_left'):
                        left_str = str(ir.variable_left).lower()
                        if var_name.lower() in left_str:
                            return True
                    if hasattr(ir, 'variable_right'):
                        right_str = str(ir.variable_right).lower()
                        if var_name.lower() in right_str:
                            return True

        return False

    def _extract_state_from_function_calls(self, condition: ConditionExpression) -> List[str]:
        state_vars = []

        if not condition.node:
            return state_vars


        for call in condition.node.internal_calls:
            if hasattr(call, 'function') and call.function:

                state_vars.extend(self._analyze_function_return_state(call.function))


        if hasattr(condition.node, 'irs'):
            for ir in condition.node.irs:
                if isinstance(ir, InternalCall):
                    if ir.function and hasattr(ir.function, 'is_implemented'):
                        if ir.function.is_implemented:
                            state_vars.extend(self._analyze_function_return_state(ir.function))

        return list(set(state_vars))

    def _analyze_function_return_state(self, function: Function) -> List[str]:
        state_vars = []

        if not function or not hasattr(function, 'is_implemented'):
            return state_vars

        if not function.is_implemented:
            return state_vars


        func_name_lower = function.name.lower()


        for state_var in self.contract.state_variables:
            var_name_lower = state_var.name.lower()


            if func_name_lower == var_name_lower:
                state_vars.append(state_var.name)
                continue


            if func_name_lower == var_name_lower.lstrip('_'):
                state_vars.append(state_var.name)
                continue


            if f"_{func_name_lower}" == var_name_lower:
                state_vars.append(state_var.name)
                continue


        for node in function.nodes:
            node_type_str = str(node.type).upper()

            if 'RETURN' in node_type_str:

                for var in node.variables_read:
                    if isinstance(var, StateVariable):
                        state_vars.append(var.name)


                if hasattr(node, 'irs'):
                    for ir in node.irs:
                        if hasattr(ir, 'values'):

                            for val in ir.values:
                                if isinstance(val, StateVariable):
                                    state_vars.append(val.name)

        return list(set(state_vars))

    def _is_permission_condition(self, condition: ConditionExpression) -> bool:
        """Final permission decision with minimal heuristics."""
        if self._is_zero_address_check(condition):
            return False

        if condition.depends_on_caller and condition.depends_on_state:
            return True

        if condition.depends_on_caller and self._is_self_authorization_check(condition):
            return True

        return False

    def _is_state_lock_condition(self, condition: ConditionExpression) -> bool:
        """Detect paused/tradingEnabled style state locks."""
        keywords = ['pause', 'paused', 'trade', 'trading', 'swap', 'enable', 'lock']
        writer_keywords = ['limit']
        all_keywords = keywords + writer_keywords

        for var_name in condition.state_variables:
            state_var = self._find_state_variable(var_name)
            if not state_var:
                continue
            var_type = str(state_var.type).lower()
            if 'bool' in var_type:
                if any(kw in var_name.lower() for kw in all_keywords):
                    return True

        lower_source = (condition.source_code or '').lower()
        return any(kw in lower_source for kw in all_keywords)

        return False

    def _is_self_authorization_check(self, condition: ConditionExpression) -> bool:
        if not condition.node:
            return False


        source_lower = condition.source_code.lower()
        if '==' not in source_lower and '!=' not in source_lower:
            return False


        has_caller = any(symbol in source_lower for symbol in self._get_function_caller_symbols(
            getattr(condition.node, 'function', None)
        ))

        if not has_caller:
            return False


        if not hasattr(condition.node, 'function') or not condition.node.function:
            return False

        function = condition.node.function
        if not hasattr(function, 'parameters'):
            return False


        for param in function.parameters:
            param_name = param.name.lower()
            if param_name in source_lower:


                return True

        return False

    def _is_zero_address_check(self, condition: ConditionExpression) -> bool:
        if not condition.source_code:
            return False

        source_lower = condition.source_code.lower()


        zero_address_patterns = [
            'address(0)',
            'address(0x0)',
            '0x0000000000000000000000000000000000000000'
        ]

        has_zero_address = any(pattern in source_lower for pattern in zero_address_patterns)

        if not has_zero_address:
            return False


        if '==' not in source_lower and '!=' not in source_lower:
            return False


        param_names = [
            'from', 'to', 'owner', 'spender', 'account',
            'recipient', 'sender', 'address', 'newowner',
            'target', 'destination', 'source'
        ]


        if any(param in source_lower for param in param_names):
            return True

        return False


class PermissionSummaryBuilder:
    """Builds compact permission summaries for each condition."""

    def __init__(self, function: Function):
        self.function = function

    def summarize(self, conditions: List[ConditionExpression]) -> List[Dict[str, Any]]:
        summaries: List[Dict[str, Any]] = []
        for condition in conditions:
            entry: Dict[str, Any] = {
                "source": self._get_condition_source(condition),
                "line": condition.line,
                "summary": (condition.source_code or "")[:200].strip(),
                "has_permission": bool(condition.is_permission),
                "depends_on_caller": bool(condition.depends_on_caller),
                "depends_on_state": bool(condition.depends_on_state)
            }
            if condition.state_variables:
                entry["state_variables"] = condition.state_variables
            if condition.is_state_lock:
                entry["is_state_lock"] = True
            summaries.append(entry)
        return summaries

    def _get_condition_source(self, condition: ConditionExpression) -> str:
        """Identify whether condition comes from modifier or function body."""
        if not self.function:
            return "unknown"

        cond_line = condition.line
        if not cond_line:
            return "unknown"


        for modifier in self.function.modifiers:
            if modifier.source_mapping and modifier.source_mapping.lines:
                if cond_line in modifier.source_mapping.lines:
                    return f"modifier:{modifier.name}"


        if self.function.source_mapping and self.function.source_mapping.lines:
            if cond_line in self.function.source_mapping.lines:
                return "function_body"

        return "unknown"


class PermissionProfileGenerator:

    def __init__(self, contract: Contract, sol_path: Path, caller_context: Dict, persistent_roles: Set):
        self.contract = contract
        self.sol_path = sol_path
        self.caller_context = caller_context
        self.persistent_roles = persistent_roles


        self.stage1 = GuardStatementScanner(contract, sol_path)
        self.stage2 = PermissionHeuristicFilter(contract, caller_context, persistent_roles)


    def generate_profile(self, function: Function) -> Dict[str, Any]:

        all_conditions = self.stage1.scan_function(function, include_modifiers=True)

        raw_count = len(all_conditions)

        if not all_conditions:
            return {
                "function": function.full_name,
                "visibility": function.visibility,
                "modifiers": [m.name for m in function.modifiers],
                "metadata": {
                    "contract": function.contract.name if function.contract else "Unknown",
                    "start_line": function.source_mapping.lines[0] if function.source_mapping and function.source_mapping.lines else None
                },
                "permission_checks": None,
                "raw_condition_count": 0,
                "permission_condition_count": 0
            }


        filtered_conditions = self.stage2.filter_conditions(all_conditions)


        summary_builder = PermissionSummaryBuilder(function)
        permission_checks = summary_builder.summarize(filtered_conditions) or None

        function_key = format_function_key(
            function.contract.name if function.contract else self.contract.name,
            function.full_name
        )

        return {
            "function": function_key,
            "visibility": function.visibility,
            "modifiers": [m.name for m in function.modifiers],
            "metadata": {
                "contract": function.contract.name if function.contract else "Unknown",
                "start_line": function.source_mapping.lines[0] if function.source_mapping and function.source_mapping.lines else None
            },
            "permission_checks": permission_checks,
            "raw_condition_count": raw_count,
            "permission_condition_count": sum(
                1 for entry in (permission_checks or []) if entry.get("has_permission")
            )
        }


def analyze_contract(sol_path: Path, output_dir: Path, contract_address: Optional[str] = None) -> Optional[Dict[str, Any]]:

    if contract_address:
        contract_name = contract_address
        actual_contract_name = sol_path.stem
        print(f"\n{'='*80}")
        print(f"📄 Analyzing: {actual_contract_name} (Output: {contract_address})")
        print(f"{'='*80}")
    else:
        contract_name = sol_path.stem
        actual_contract_name = contract_name
        print(f"\n{'='*80}")
        print(f"📄 Analyzing: {contract_name}")
        print(f"{'='*80}")


    print("📥 Loading step1.1 caller analysis...")
    caller_context, persistent_roles = load_caller_analysis(contract_name, output_dir)

    symbol_count = caller_context.get('symbol_count', 0)
    if symbol_count == 0:
        print("  ⚠️  No caller map found. Some analysis may be limited.")
    else:
        print(f"  ✓ Loaded {symbol_count} caller symbols")

    if persistent_roles:
        print(f"  ✓ Identified {len(persistent_roles)} persistent roles: {persistent_roles}")


    print("\n📦 Initializing Slither...")
    slither = init_slither(str(sol_path))
    if slither is None:
        print(f"  ❌ Slither initialization failed")
        return None

    results = {
        "contract_name": actual_contract_name,
        "contract_path": str(sol_path),
        "functions": {}
    }


    for contract in slither.contracts:
        if contract.is_interface:
            continue

        print(f"\n🔍 Analyzing contract: {contract.name}")


        generator = PermissionProfileGenerator(
            contract, sol_path, caller_context, persistent_roles
        )


        func_count = 0
        for function in contract.functions:
            if function.is_constructor or function.is_fallback or function.is_receive:
                continue

            profile = generator.generate_profile(function)


            if profile['permission_checks']:
                func_key = profile["function"]
                results["functions"][func_key] = profile
                func_count += 1

        print(f"  ✓ Generated profiles for {func_count} functions")


    if results["functions"]:
        contract_output_dir = output_dir / contract_name / "step1"
        contract_output_dir.mkdir(parents=True, exist_ok=True)
        outfile = contract_output_dir / "step1.2_permission_profile.json"

        with open(outfile, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)

        print(f"\n💾 Results saved to: {outfile.relative_to(output_dir)}")


        total_permission_funcs = sum(
            1 for f in results["functions"].values()
            if f["permission_checks"]
        )

        print(f"\n📊 Summary:")
        print(f"  • Functions with permission checks: {total_permission_funcs}")
    else:
        print("\n  ℹ️  No permission-controlled functions found")

    return results


def main():
    """Script main entry point"""
    print("\n" + "="*80)
    print("🚀 High-Precision Permission Analysis Engine")
    print("   Simplified Version: Permission Checks Only")
    print("="*80)

    project_root, contracts_dir, output_dir = setup_project_paths()
    if not project_root:
        return

    print(f"\nProject root: {project_root}")
    print(f"Contracts directory: {contracts_dir}")
    print(f"Output directory: {output_dir}")

    sol_files = list(contracts_dir.glob("*.sol"))
    if not sol_files:
        print("\n❌ No .sol files found in 'contracts' directory.")
        return

    print(f"\n📋 Found {len(sol_files)} contract(s) to analyze")

    all_results = []
    for sol_file in sol_files:
        result = analyze_contract(sol_file, output_dir)
        if result:
            all_results.append(result)


    print("\n" + "="*80)
    print("📊 Final Summary")
    print("="*80)
    total_contracts = len(all_results)
    total_functions = sum(len(r['functions']) for r in all_results)

    print(f"Contracts analyzed: {total_contracts}")
    print(f"Permission-controlled functions: {total_functions}")
    print("\n✅ Permission analysis complete!")


if __name__ == "__main__":
    main()
