from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


try:
 PROJECT_ROOT = Path(__file__).resolve.parents[2]
except ValueError:
 PROJECT_ROOT = Path.cwd

sys.path.insert(0, str(PROJECT_ROOT / "src"))
from utils.path_manager import get_output_dir

OUTPUT_DIR = get_output_dir


CALLER_ASSIGNMENT_PATTERN = re.compile(
 r"^\s*(?:address\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:_msgSender\(\)|msg\.sender)\s*;?"
)

REASONING_STEPS = [
 "1. Read nodes in order: when encountering [PERM] nodes, record who can trigger them and what state they depend on; when encountering [ASSET] nodes, record how balances/variables change.",
 "2. Focus on asset sources: pay attention to whether from/payer in [ASSET] nodes is provided by parameters or arbitrary addresses rather than the caller; also check if trading switches/blacklist variables are modified.",
 "3. Link permissions to assets: explain how privileged identities manipulate these asset changes, whether affected addresses are fixed (e.g. owner), arbitrary input, or limited to caller.",
 "4. Rugpull : Hidden Mint=, Limiting Sell=, Leaking Token=; no \"\". . ",
]

RUGPULL_DEFINITION = [
 "Mint（）: （onlyOwner, _taxWallet ）, yes; , no. ",
 "Limit（）: （, /, ）,  transfer/yesno, , no. ",
 "Leak（）: ——A) : /yes, ; B) : /no, . yes,  Leak. ",
 ":  [PERM] [ASSET] , yesno Mint/Limit/Leak , . ",
]

FINAL_INSTRUCTION = (
 ", yesno Hidden Mint / Limiting Sell / Leaking Token / no（\"\"）. "
 " JSON: {\"category\":\"...\",\"confidence\":0.0-1.0,\"reasoning\":[...],\"key_nodes\":[...]}"
)


def _load_json(path: Path) -> Optional[Dict[str, Any]]:
 if not path.exists:
 return None
 try:
 return json.loads(path.read_text(encoding="utf-8"))
 except json.JSONDecodeError:
 return None


def _discover_contracts -> List[str]:
 if not OUTPUT_DIR.exists:
 return []
 return sorted(
 [
 p.name
 for p in OUTPUT_DIR.iterdir
 if p.is_dir and (p / "step1" / "step1.4_paths.json").exists
 ]
 )


def _now_iso -> str:
 return datetime.now(timezone.utc).isoformat


class PathFormatter:
 """Formatter for Step 1.4 paths."""

 def __init__(self, contract_name: str, raw_paths: Dict[str, Any]):
 self.contract_name = contract_name
 self.raw_paths = raw_paths


 def format_paths(self) -> Dict[str, Any]:
 """Return formatted representation for all direct/indirect paths."""
 formatted: Dict[str, Any] = {
 "contract_name": self.contract_name,
 "generated_at": _now_iso,
 "direct_paths": [],
 "indirect_paths": [],
 }

 for path in self.raw_paths.get("direct_paths", []):
 formatted["direct_paths"].append(self._format_direct_path(path))

 for path in self.raw_paths.get("indirect_paths", []):
 formatted["indirect_paths"].append(self._format_indirect_path(path))

 summary = self.raw_paths.get("summary", {})
 formatted["summary"] = {
 "direct_paths": len(formatted["direct_paths"]),
 "indirect_paths": len(formatted["indirect_paths"]),
 "original_summary": summary,
 }
 return formatted


 def _format_direct_path(self, path: Dict[str, Any]) -> Dict[str, Any]:
 nodes: List[Dict[str, Any]] = path.get("nodes", [])
 overview = self._build_overview(path, nodes)
 node_blocks = [self._build_node_block(node) for node in nodes]
 focus = {
 "permission_nodes": [ block["node_id"] for block in node_blocks if "PERMISSION" in block["attention"]],
 "asset_nodes": [ block["node_id"] for block in node_blocks if "ASSET" in block["attention"]],
 }

 return {
 "path_id": path["path_id"],
 "path_type": path.get("path_type", "DIRECT"),
 "overview": overview,
 "node_blocks": node_blocks,
 "focus_hints": focus,
 "reasoning_steps": REASONING_STEPS,
 "rugpull_definition": RUGPULL_DEFINITION,
 "instruction": FINAL_INSTRUCTION,
 }

 def _build_overview(self, path: Dict[str, Any], nodes: List[Dict[str, Any]]) -> Dict[str, Any]:
 trace_tokens: List[str] = []
 permission_nodes: List[str] = []
 asset_nodes: List[str] = []

 for node in nodes:
 label = node.get("node_id", "")
 if self._node_has_permission(node):
 label += "[PERM]"
 permission_nodes.append(node.get("node_id", ""))
 elif node.get("asset_annotations"):
 label += "[ASSET]"
 asset_nodes.append(node.get("node_id", ""))
 trace_tokens.append(label)

 summary_parts = [
 f" {path.get('function_signature')}",
 ]
 if permission_nodes:
 summary_parts.append(f": {', '.join(permission_nodes)}")
 if asset_nodes:
 summary_parts.append(f": {', '.join(asset_nodes)}")

 return {
 "path_id": path.get("path_id"),
 "function_signature": path.get("function_signature"),
 "trace": " -> ".join(trace_tokens),
 "summary": "; ".join(summary_parts),
 }

 def _build_node_block(self, node: Dict[str, Any]) -> Dict[str, Any]:
 node_id = node.get("node_id")
 node_type = node.get("node_type")
 call_depth = node.get("call_depth", 0)
 function_name = node.get("function")

 attention: List[str] = []
 if self._node_has_permission(node):
 attention.append("PERMISSION")
 if node.get("asset_annotations"):
 attention.append("ASSET")

 code_lines = self._extract_code_snippet(node)
 notes = self._build_node_notes(node)

 header = f"[Node {node_id} | depth={call_depth} | {function_name}]"
 if attention:
 header += f" | ATTENTION: {', '.join(attention)}"

 return {
 "node_id": node_id,
 "header": header,
 "attention": attention,
 "code_block": "\n".join(code_lines) if code_lines else "",
 "notes": notes,
 }

 @staticmethod
 def _node_has_permission(node: Dict[str, Any]) -> bool:
 checks = node.get("permission_checks") or []
 for check in checks:
 if check.get("has_permission"):
 return True
 if check.get("is_state_lock"):
 return True
 if check.get("depends_on_caller") and check.get("depends_on_state"):
 return True
 return False

 def _extract_code_snippet(self, node: Dict[str, Any]) -> List[str]:
 relevant_lines: List[str] = []
 caller_aliases = self._collect_caller_aliases(node)
 data_profile = node.get("data_io_profile") or {}
 init_values = data_profile.get("variable_initializations") or {}
 state_types = data_profile.get("state_variable_types") or {}
 parameter_binding = data_profile.get("parameter_binding") or {}
 permission_lines = {
 check.get("line")
 for check in node.get("permission_checks") or []
 if check.get("line") is not None
 }
 asset_vars = [ann.get("variable") for ann in node.get("asset_annotations") or [] if ann.get("variable")]

 for block in node.get("code_blocks") or []:
 expression = block.get("expression") or ""
 inline_hints: List[str] = []
 if init_values:
 for var, value in init_values.items:
 if not var or value is None:
 continue
 type_str = (state_types.get(var) or "").lower
 if "mapping" in type_str:
 continue
 pattern = r"\b" + re.escape(var) + r"\b"
 if re.search(pattern, expression):
 val_str = str(value).strip
 if val_str:
 inline_hints.append(f"{var}={val_str}")
 if inline_hints:
 expression = f"{expression} /* {'; '.join(inline_hints)} */"
 line_no = block.get("line")
 tags: List[str] = []


 param_hints: List[str] = []
 if parameter_binding:
 for param_name, binding in parameter_binding.items:
 if not param_name or not binding:
 continue
 pattern = r"\b" + re.escape(param_name) + r"\b"
 if re.search(pattern, expression):
 hint = self._describe_parameter_binding(binding)
 if hint:
 param_hints.append(f"{param_name}←{hint}")
 if param_hints:
 suffix = " ; ".join(param_hints)
 expression = f"{expression} /* {suffix} */" if "/*" not in expression else f"{expression} ; {suffix}"

 if line_no in permission_lines:
 tags.append("PERM")
 if any(alias and alias in expression for alias in caller_aliases):
 tags.append("CALLER")
 if any(var and var in expression for var in asset_vars):
 tags.append("ASSET")

 if tags:
 prefix = f"L{line_no}: " if line_no is not None else ""
 relevant_lines.append(f"{prefix}{expression} // [{', '.join(tags)}]")

 if not relevant_lines and node.get("condition"):
 relevant_lines.append(node.get("condition"))

 return relevant_lines

 @staticmethod
 def _collect_caller_aliases(node: Dict[str, Any]) -> List[str]:
 aliases: List[str] = []
 data_profile = node.get("data_io_profile") or {}
 for param, mapping in (data_profile.get("parameter_mapping") or {}).items:
 if mapping.get("is_caller"):
 aliases.append(param)

 for block in node.get("code_blocks") or []:
 expr = block.get("expression") or ""
 match = CALLER_ASSIGNMENT_PATTERN.match(expr)
 if match:
 aliases.append(match.group(1))
 return aliases

 def _build_node_notes(self, node: Dict[str, Any]) -> List[str]:
 notes: List[str] = []
 data_profile = node.get("data_io_profile") or {}
 parameter_binding = data_profile.get("parameter_binding") or {}
 for param_name, binding in (parameter_binding or {}).items:
 hint = self._describe_parameter_binding(binding)
 if hint:
 notes.append(f"[BIND] {param_name} = {hint}")
 for check in node.get("permission_checks") or []:
 if any([check.get("has_permission"), check.get("is_state_lock"), (check.get("depends_on_caller") and check.get("depends_on_state"))]):
 line = check.get("line")
 summary = check.get("summary") or ""
 prefix = "L{}".format(line) if line is not None else ""
 if prefix:
 notes.append(f"[PERM] {prefix} {summary}")
 else:
 notes.append(f"[PERM] {summary}")

 for ann in node.get("asset_annotations") or []:
 var = ann.get("variable")
 access = ann.get("access") or []
 if var:
 access_str = "/".join(access) if access else ""
 if access_str:
 notes.append(f"[ASSET] {var} ({access_str})")
 else:
 notes.append(f"[ASSET] {var}")
 notes.extend(self._collect_initialization_notes(node))
 return notes

 def _describe_parameter_binding(self, binding: Dict[str, Any]) -> str:
 """Render a concise description of how a parameter value was sourced."""
 if not binding:
 return ""
 source = binding.get("source") or {}
 call_arg = binding.get("call_argument")

 if source.get("type") == "CONSTANT":
 return str(source.get("value") or call_arg or "0")
 if binding.get("is_caller"):
 evidence = binding.get("caller_evidence") or {}
 return evidence.get("source") or "caller"
 if source.get("type") == "GLOBAL":
 return source.get("value") or call_arg or "global"
 if source.get("type") == "PARAMETER":
 val = source.get("value") or call_arg
 return f"param:{val}" if val else "param"
 if source.get("type") == "LOCAL":
 val = source.get("value") or call_arg
 return f"local:{val}" if val else "local"
 if call_arg:
 return str(call_arg)
 return str(source.get("value") or "")

 def _collect_initialization_notes(self, node: Dict[str, Any]) -> List[str]:
 data_profile = node.get("data_io_profile") or {}
 init_map = data_profile.get("variable_initializations")
 if not isinstance(init_map, dict) or not init_map:
 return []

 state_types = (data_profile.get("state_variable_types") or {})
 expressions = " ".join(
 block.get("expression") or "" for block in node.get("code_blocks") or []
 )
 referenced = [var for var in init_map if var and var in expressions]
 if not referenced:
 referenced = [var for var in init_map if var]

 notes: List[str] = []
 for var in referenced:
 var_type = (state_types.get(var) or "").lower
 if "mapping" in var_type:
 continue
 value = init_map.get(var)
 if value is None:
 continue
 value_str = str(value).strip
 if not value_str:
 continue
 notes.append(f"[INIT] {var} = {value_str}")
 return notes


 @staticmethod
 def _format_indirect_path(path: Dict[str, Any]) -> Dict[str, Any]:
 control_source = path.get("control_source", {})
 control_var = path.get("control_variable", {})
 affected_targets = path.get("affected_targets", [])
 control_chain = path.get("control_chain") or []

 return {
 "path_id": path.get("path_id"),
 "overview": {
 "source": control_source.get("function"),
 "control_variable": control_var.get("name"),
 "targets": [t.get("function") for t in affected_targets],
 },
 "details": {
 "control_source": control_source,
 "control_variable": control_var,
 "control_chain": control_chain,
 "affected_targets": affected_targets,
 },
 "reasoning_steps": REASONING_STEPS,
 "rugpull_definition": RUGPULL_DEFINITION,
 "instruction": FINAL_INSTRUCTION,
 }


def process_contract(contract_name: str) -> None:
 step1_dir = OUTPUT_DIR / contract_name / "step1"
 step2_dir = OUTPUT_DIR / contract_name / "step2"
 step2_dir.mkdir(parents=True, exist_ok=True)

 path_file = step1_dir / "step1.4_paths.json"
 raw_paths = _load_json(path_file)
 if not raw_paths:
 print(f"[WARN] Missing or invalid path file for {contract_name}: {path_file}")
 return

 formatter = PathFormatter(contract_name, raw_paths)
 formatted = formatter.format_paths

 output_file = step2_dir / "step2.1_formatted_paths.json"
 output_file.write_text(json.dumps(formatted, indent=2), encoding="utf-8")
 print(f"[OK] Formatted paths saved to {output_file.relative_to(PROJECT_ROOT)}")


def main -> None:
 parser = argparse.ArgumentParser(description="Format Step 1.4 paths for Step 2 LLM input.")
 parser.add_argument(
 "--contracts",
 nargs="+",
 help="Specific contract names (default: all contracts with step1.4 output).",
 )
 args = parser.parse_args

 contracts = args.contracts or _discover_contracts
 if not contracts:
 print("[WARN] No contracts found to process.")
 return

 for contract in contracts:
 process_contract(contract)


if __name__ == "__main__":
 main
