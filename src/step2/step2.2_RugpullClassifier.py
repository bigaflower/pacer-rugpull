from __future__ import annotations

import argparse
import json
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

import openai


try:
 PROJECT_ROOT = Path(__file__).resolve.parents[2]
except ValueError:
 PROJECT_ROOT = Path.cwd


env_output = os.environ.get("PADG_OUTPUT_DIR")
if env_output:
 OUTPUT_DIR = Path(env_output).resolve
else:
 OUTPUT_DIR = PROJECT_ROOT / "issta25_sok_results"


HARDCODED_API_KEY = "sk-vl5kT785gkMkJ9NwClrryg5J2JHAWmQnN0XaCcZR2bvzRfF3"

HARDCODED_BASE_URL = "https://api.yunwu.ai/v1"
HARDCODED_MODEL = "gpt-4o-mini"
SKIP_REASON_NO_ASSET = "Skipped before LLM: no asset-related activity detected"


CATEGORY_GUIDANCE = """
Classification criteria (three categories only, leave empty for others). Judgment conditions must be directly related to asset changes: if there is no read/write of asset variables or trading logic in the path, no category should be assigned.
1. MINT（）: ,  += , , . yes“”,  MINT. 
2. LIMIT（）: High-privilege entity can toggle trading, black/whitelist, lock positions, etc., causing normal users' transfers to be blocked or passively charged. Merely restricting admin function access (e.g. onlyOwner checks) does NOT count as LIMIT, unless the function directly controls transfer behavior.
3. LEAK（）: High-privilege entity can reduce or transfer others' balances. Includes:
 - Direct leak/malicious burn: privileged user can arbitrarily specify non-caller accounts, reducing, zeroing, or deducting their balances without equivalent compensation, even if deducted tokens are not credited to other accounts.
 - / : , from amount,  to amount, . “”. 
yes,  Leak. 
, category "". 
Analyze each execution path carefully and classify whether it implements one
of the following rugpull behaviors (MINT, LIMIT, LEAK) none.

[EXAMPLE 1 - MINT]
Code: `_balances[user] += 1000;`
Simulation: start=100 → end=1100 (Increase)
Category: MINT

[EXAMPLE 2 - NOT MINT]
Code: `_balances[user] *= 0;` `_balances[user] = 0;`
Simulation: start=100 → end=0 (Decrease/Reset)
Category: "" LEAK（ NEVER MINT）

[EXAMPLE 3 - LIMIT]
Code:
 `require(allowTransfer, "transfer disabled");`
 `function setAllowTransfer(bool status) onlyOwner {{ allowTransfer = status; }}`
Explanation: transfer, yesno → LIMIT

[EXAMPLE 3 - LEAK ]
Code:
 `fee_amount = amount * fee/100;`
 `balances[from] -= amount;`
 `balances[to] += (amount - fee_amount);`
 `balances[owner] += fee_amount;`
Simulation: from=100 → 100-amount; to=100 → 100+(amount - fee); owner=100 → 100+fee; owner → LEAK

[EXAMPLE 4 - LEAK ( vs )]
:
 `function drain(address victim, uint amount) onlyOwner {{`
 ` balances[victim] -= amount;`
 ` balances[owner] += amount;`
 `}}`
Simulation: victim=100 → 100-amount; owner=100 → 100+amount → LEAK（ victim yes caller）
: , yes（ caller ）,  → Leak

[NORMAL EXAMPLE]
Code:
 `balances[from] -= amount;`
 `balances[to] += amount;`
Simulation: from=100 → 100-amount; to=100 → 100+amount; yes → 

[FEASIBILITY RULES]
1. [BIND] `param ← /` , . yesno. 
2. `_balances[...]`, `balanceOf(...)`, `_totalSupply`, `allowance` `uint256` ≥0; ,  `0 > balance`, `newBalance(=0) > currentBalance(>=0)` yes. 
3. （/）, ,  `category=""`. 

{CATEGORY_GUIDANCE}

 JSON: 
{{
 "category": "MINT|LIMIT|LEAK|\"\"",
 "confidence": 0.0-1.0,
 "reasoning": ["step-by-step evidence ..."],
 "key_nodes": ["NodeID1", "NodeID2", ...]
}}
Only include keys shown above. `reasoning` （）, . 

 def build_direct_prompt(self, path: Dict[str, Any]) -> str:
 sections: List[str] = []
 overview = path.get("overview", {})

 sections.append("### Path Overview")
 sections.append(f"Path ID: {overview.get('path_id')}")
 sections.append(f"Entry Function: {overview.get('function_signature')}")
 sections.append(f"Trace: {overview.get('trace')}")
 if overview.get("summary"):
 sections.append(f"Summary: {overview.get('summary')}")
 sections.append("")

 sections.append("### Node Blocks")
 for block in path.get("node_blocks", []):
 header = block.get("header")
 if header:
 sections.append(header)
 code = block.get("code_block")
 if code:
 sections.append(code)
 notes = block.get("notes") or []
 for note in notes:
 sections.append(f"- {note}")
 sections.append("")

 focus = path.get("focus_hints") or {}
 sections.append("### Focus Hints")
 sections.append(f"Permission nodes: {', '.join(focus.get('permission_nodes') or []) or 'None'}")
 sections.append(f"Asset nodes: {', '.join(focus.get('asset_nodes') or []) or 'None'}")
 sections.append("")

 asset_nodes = focus.get("asset_nodes") or []

 sections.append("### Reasoning Steps")
 for step in path.get("reasoning_steps") or []:
 sections.append(f"- {step}")
 sections.append("")

 sections.append("### Balance Change Checklist")
 sections.append(" [ASSET] : ")
 sections.append("1. yes？, yes. ")
 sections.append("2. /（, , ）, yesno. ")
 sections.append("3. yes“”“”“”yes“”. yes, no. ,  MINT. ")
 sections.append("4. yesno？, . ")
 sections.append("")

 sections.append("### Simulation Protocol (Required Step)")
 sections.append(",  [ASSET] : ")
 sections.append("1. 100. ")
 sections.append("2. :  `_balances[x] *= 0` → 100 0; `_balances[x] = 1000` → 100 1000. ")
 sections.append("3. 100:  100 ⇒ Mint;  100/ 0 ⇒ Leak;  100 ⇒ no; no. ")
 sections.append("4. “ A B”,  A B . ")
 sections.append("")
 sections.append("### Feasibility Checks")
 sections.append("1. `[BIND] param = ` `param←`, ;  IF /, yesno. ")
 sections.append("2. , , allowance `uint256` ≥ 0.  `0 > balance` , , . ")
 sections.append("3. （ newBalance=0 newBalance>currentBalance）, yes `_mint`/`_burn` ,  rugpull,  `category:\"\"` . ")
 sections.append("")

 sections.append("### Rugpull Definition")
 for item in path.get("rugpull_definition") or []:
 sections.append(f"- {item}")
 sections.append("")

 sections.append("### Instructions")
 instruction = path.get("instruction") or (
 " Simulation , yesno Hidden Mint / Limiting Sell / Leaking Token / \"\", "
 " JSON: {\"category\":\"...\",\"confidence\":0.0-1.0,\"reasoning\":[\"Simulation: 100 -> 0, ...\",...],\"key_nodes\":[...]}. "
 )
 sections.append(instruction)
 if not asset_nodes:
 sections.append(":  [ASSET] , ,  category=\"\". ")

 return "\n".join(sections)

 def build_indirect_prompt(self, path: Dict[str, Any]) -> str:
 sections: List[str] = []
 overview = path.get("overview", {})
 details = path.get("details", {})

 sections.append("### Indirect Path Overview")
 sections.append(f"Path ID: {path.get('path_id')}")
 sections.append(f"Control Source: {overview.get('source')}")
 sections.append(f"Control Variable: {overview.get('control_variable')}")
 sections.append(f"Affected Targets: {', '.join(overview.get('targets') or [])}")
 sections.append("")

 sections.append("### Control Details")
 sections.append(json.dumps(details.get("control_source", {}), indent=2, ensure_ascii=False))
 sections.append("")
 sections.append("Control Chain:")
 chain = details.get("control_chain") or []
 if chain:
 for hop in chain:
 sections.append(json.dumps(hop, indent=2, ensure_ascii=False))
 else:
 sections.append("[]")
 sections.append("")
 sections.append("Affected Targets:")
 for target in details.get("affected_targets") or []:
 sections.append(json.dumps(target, indent=2, ensure_ascii=False))
 sections.append("")

 sections.append("### Reasoning Steps")
 for step in path.get("reasoning_steps") or []:
 sections.append(f"- {step}")
 sections.append("")

 sections.append("### Rugpull Definition")
 for item in path.get("rugpull_definition") or []:
 sections.append(f"- {item}")
 sections.append("")

 sections.append("### Instructions")
 instruction = path.get("instruction") or (
 "yesno Hidden Mint / Limiting Sell / Leaking Token / \"\", "
 " JSON: {\"category\":\"...\",\"confidence\":0.0-1.0,\"reasoning\":[...],\"key_nodes\":[...]}. "
 )
 sections.append(instruction)
 targets = overview.get("targets") or []
 if not targets:
 sections.append(": , no,  category=\"\". ")

 return "\n".join(sections)


def path_has_asset_activity(path: Dict[str, Any]) -> bool:

 return True


def build_skip_result -> Dict[str, Any]:
 return {
 "category": "",
 "confidence": 0.0,
 "reasoning": [SKIP_REASON_NO_ASSET],
 "key_nodes": [],
 }


class LLMAnalyzer:
 def __init__(self, model: Optional[str], api_key: Optional[str], base_url: Optional[str], timeout: int = 120):
 effective_model = model or HARDCODED_MODEL
 effective_key = api_key or HARDCODED_API_KEY
 effective_url = base_url or HARDCODED_BASE_URL
 self.client = openai.OpenAI(api_key=effective_key, base_url=effective_url, timeout=timeout)
 self.model = effective_model

 def analyze(self, prompt: str) -> Dict[str, Any]:
 response = self.client.chat.completions.create(
 model=self.model,
 messages=[
 {"role": "system", "content": SYSTEM_PROMPT.strip},
 {"role": "user", "content": prompt},
 ],
 temperature=0.1,
 )
 content = response.choices[0].message.content.strip
 if content.startswith("```"):
 content = self._extract_json(content)


 result = self._safe_json_loads(content)


 if result is None:
 result = self._extract_embedded_json(content)


 if result is None:
 result = {"category": "ERROR", "confidence": 0.0, "reasoning": [content], "key_nodes": []}

 return result

 @staticmethod
 def _extract_json(blob: str) -> str:
 lines = blob.splitlines
 without_fence = [line for line in lines if not line.strip.startswith("```")]
 return "\n".join(without_fence).strip

 @staticmethod
 def _safe_json_loads(text: str) -> Optional[Dict[str, Any]]:
 try:
 data = json.loads(text)
 if "category" not in data:
 return None
 if "reasoning" not in data:
 data["reasoning"] = []
 if "key_nodes" not in data:
 data["key_nodes"] = []
 return data
 except json.JSONDecodeError:
 return None

 @staticmethod
 def _extract_embedded_json(text: str) -> Optional[Dict[str, Any]]:

 json_candidates = []
 brace_count = 0
 start_pos = -1

 for i, char in enumerate(text):
 if char == '{':
 if brace_count == 0:
 start_pos = i
 brace_count += 1
 elif char == '}':
 brace_count -= 1
 if brace_count == 0 and start_pos >= 0:

 json_str = text[start_pos:i+1]
 json_candidates.append(json_str)
 start_pos = -1


 for candidate in json_candidates:
 try:
 data = json.loads(candidate)

 if isinstance(data, dict) and "category" in data:

 if "reasoning" not in data:
 data["reasoning"] = []
 if "key_nodes" not in data:
 data["key_nodes"] = []
 if "confidence" not in data:
 data["confidence"] = 0.0


 category = data.get("category", "")
 if category in {"MINT", "LIMIT", "LEAK", "ERROR", ""}:
 return data
 except (json.JSONDecodeError, ValueError):
 continue

 return None


def load_formatted_paths(contract: str) -> Optional[Dict[str, Any]]:
 """ Step 2.1 """
 path = OUTPUT_DIR / contract / "step2" / "step2.1_formatted_paths.json"
 if not path.exists:
 return None
 try:
 return json.loads(path.read_text(encoding="utf-8"))
 except json.JSONDecodeError:
 return None


def save_results(contract: str, results: Dict[str, Any]) -> None:
 """ Step 2.2 """
 out_dir = OUTPUT_DIR / contract / "step2"
 out_dir.mkdir(parents=True, exist_ok=True)
 out_file = out_dir / "step2.2_semantic_analysis.json"
 out_file.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
 print(f"[OK] Saved to: {out_file}")


def analyze_contract(
 contract: str,
 analyzer: LLMAnalyzer,
 builder: PromptBuilder,
 max_direct: Optional[int],
 include_indirect: bool,
) -> Dict[str, Any]:
 formatted = load_formatted_paths(contract)
 if not formatted:
 raise FileNotFoundError(f"Missing formatted paths for {contract}")

 results: Dict[str, Any] = {
 "contract_name": contract,
 "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime),
 "model": analyzer.model,
 "paths": [],
 "summary": {"MINT": 0, "LIMIT": 0, "LEAK": 0, "EMPTY": 0, "ERROR": 0},
 }

 direct_paths = formatted.get("direct_paths", [])
 if max_direct is not None:
 direct_paths = direct_paths[:max_direct]

 total_direct = len(direct_paths)
 if total_direct:
 print(f"[{contract}] Direct paths: {total_direct} total", flush=True)

 for idx, path in enumerate(direct_paths, start=1):
 print(
 f"[{contract}] Direct path {idx}/{total_direct}: {path.get('path_id')}",
 flush=True,
 )
 if not path_has_asset_activity(path):
 print(f" ↳ skipped (no asset activity)", flush=True)
 results["summary"]["EMPTY"] += 1
 results["paths"].append(
 {
 "path_id": path["path_id"],
 "path_type": "DIRECT",
 "category": "",
 "llm_result": build_skip_result,
 "overview": path.get("overview", {}),
 }
 )
 continue
 prompt = builder.build_direct_prompt(path)
 result = analyzer.analyze(prompt)
 category = result.get("category", "")
 if category not in {"MINT", "LIMIT", "LEAK"}:
 if category == "ERROR":
 results["summary"]["ERROR"] += 1
 else:
 results["summary"]["EMPTY"] += 1
 category = ""
 else:
 results["summary"][category] += 1

 results["paths"].append(
 {
 "path_id": path["path_id"],
 "path_type": "DIRECT",
 "category": category,
 "llm_result": result,
 "overview": path.get("overview", {}),
 }
 )

 if include_indirect:
 indirect_paths = formatted.get("indirect_paths", [])
 total_indirect = len(indirect_paths)
 if total_indirect:
 print(f"[{contract}] Indirect paths: {total_indirect} total", flush=True)
 for idx, path in enumerate(indirect_paths, start=1):
 print(
 f"[{contract}] Indirect path {idx}/{total_indirect}: {path.get('path_id')}",
 flush=True,
 )
 if not path_has_asset_activity(path):
 print(f" ↳ skipped (no asset activity)", flush=True)
 results["summary"]["EMPTY"] += 1
 results["paths"].append(
 {
 "path_id": path["path_id"],
 "path_type": "INDIRECT",
 "category": "",
 "llm_result": build_skip_result,
 "overview": path.get("overview", {}),
 }
 )
 continue
 prompt = builder.build_indirect_prompt(path)
 result = analyzer.analyze(prompt)
 category = result.get("category", "")
 if category not in {"MINT", "LIMIT", "LEAK"}:
 if category == "ERROR":
 results["summary"]["ERROR"] += 1
 else:
 results["summary"]["EMPTY"] += 1
 category = ""
 else:
 results["summary"][category] += 1

 results["paths"].append(
 {
 "path_id": path["path_id"],
 "path_type": "INDIRECT",
 "category": category,
 "llm_result": result,
 "overview": path.get("overview", {}),
 }
 )

 return results


def parse_args -> argparse.Namespace:
 parser = argparse.ArgumentParser(description="Step 2 semantic tagger (LLM-based).")
 parser.add_argument("--contracts", nargs="+", help="Contract names (default: all with formatted paths).")
 parser.add_argument("--max-direct", type=int, default=None, help="Limit number of direct paths per contract.")
 parser.add_argument("--skip-indirect", action="store_true", help="Skip indirect paths.")
 parser.add_argument("--model", default=HARDCODED_MODEL, help="LLM model name.")
 parser.add_argument("--base-url", default=HARDCODED_BASE_URL, help="Optional OpenAI proxy base URL.")

 parser.add_argument("--overwrite", action="store_true", help="Overwrite existing results instead of skipping.")
 return parser.parse_args


def discover_contracts -> List[str]:
 """Auto-discover contracts that have Step 2.1 outputs"""
 contracts = []
 if not OUTPUT_DIR.exists:
 return []

 for contract_dir in OUTPUT_DIR.iterdir:
 if not contract_dir.is_dir:
 continue

 formatted = contract_dir / "step2" / "step2.1_formatted_paths.json"
 if formatted.exists:
 contracts.append(contract_dir.name)

 return sorted(contracts)


def main -> None:
 args = parse_args


 if not OUTPUT_DIR.exists:
 print(f"[ERROR] Data directory not found: {OUTPUT_DIR}")
 print("Please check if 'issta25_sok_results' exists in the project root.")
 return

 contracts = args.contracts or discover_contracts
 if not contracts:
 print(f"[INFO] No contracts found in {OUTPUT_DIR} with 'step2/step2.1_formatted_paths.json'")
 return

 api_key = os.environ.get("OPENAI_API_KEY") or HARDCODED_API_KEY

 analyzer = LLMAnalyzer(model=args.model, api_key=api_key, base_url=args.base_url)
 builder = PromptBuilder

 print(f"Starting Analysis...")
 print(f"Data Directory: {OUTPUT_DIR}")
 print(f"Contracts to process: {len(contracts)}")
 print(f"Model: {analyzer.model}")
 print(f"Overwrite Mode: {args.overwrite}")
 print("-" * 50)

 ok_count = 0
 skipped_count = 0

 for idx, contract in enumerate(contracts, start=1):


 output_file = OUTPUT_DIR / contract / "step2" / "step2.2_semantic_analysis.json"

 if output_file.exists and not args.overwrite:
 try:

 with open(output_file, "r", encoding="utf-8") as f:
 json.load(f)

 print(f"[{idx}/{len(contracts)}] [SKIP] {contract}: Output file exists and is valid.")
 skipped_count += 1
 ok_count += 1
 continue
 except json.JSONDecodeError:
 print(f"[{idx}/{len(contracts)}] [WARN] {contract}: Output file corrupted. Re-processing...")
 except Exception as e:
 print(f"[{idx}/{len(contracts)}] [WARN] {contract}: Error checking output file: {e}. Re-processing...")


 try:
 print(f"\n=== Processing {contract} ({idx}/{len(contracts)}) ===", flush=True)
 results = analyze_contract(
 contract=contract,
 analyzer=analyzer,
 builder=builder,
 max_direct=args.max_direct,
 include_indirect=not args.skip_indirect,
 )
 save_results(contract, results)
 ok_count += 1
 except FileNotFoundError as e:
 print(f"[WARN] {e}")
 except Exception as exc:
 import traceback
 traceback.print_exc
 print(f"[ERROR] Failed to analyze {contract}: {exc}")

 print(f"\n[Summary] Total: {len(contracts)} | Processed/Available: {ok_count} | Skipped: {skipped_count}")


if __name__ == "__main__":
 main
