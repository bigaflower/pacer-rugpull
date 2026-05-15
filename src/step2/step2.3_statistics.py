import json
import os
import csv
from pathlib import Path


try:
 PROJECT_ROOT = Path(__file__).resolve.parents[2]
except ValueError:
 PROJECT_ROOT = Path.cwd

env_output = os.environ.get("PADG_OUTPUT_DIR")
if env_output:
 OUTPUT_DIR = Path(env_output).resolve
else:
 OUTPUT_DIR = PROJECT_ROOT / "issta25_sok_results"

def main:
 if not OUTPUT_DIR.exists:
 print(f"[ERROR] Cannot find results directory: {OUTPUT_DIR}")
 return

 print(f"Scanning directory: {OUTPUT_DIR} ...")


 total_processed = 0


 stats_multilabel = {
 "MINT": 0,
 "LIMIT": 0,
 "LEAK": 0
 }


 stats_binary = {
 "VULNERABLE": 0,
 "SAFE": 0
 }


 csv_rows = []


 contract_dirs = sorted([d for d in OUTPUT_DIR.iterdir if d.is_dir])

 for contract_dir in contract_dirs:
 contract_name = contract_dir.name
 result_file = contract_dir / "step2" / "step2.2_semantic_analysis.json"

 if not result_file.exists:
 continue

 try:
 with open(result_file, "r", encoding="utf-8") as f:
 data = json.load(f)

 total_processed += 1
 summary = data.get("summary", {})


 n_mint = summary.get("MINT", 0)
 n_limit = summary.get("LIMIT", 0)
 n_leak = summary.get("LEAK", 0)


 has_mint = 1 if n_mint > 0 else 0
 has_limit = 1 if n_limit > 0 else 0
 has_leak = 1 if n_leak > 0 else 0


 if has_mint: stats_multilabel["MINT"] += 1
 if has_limit: stats_multilabel["LIMIT"] += 1
 if has_leak: stats_multilabel["LEAK"] += 1


 is_vulnerable = 1 if (has_mint or has_limit or has_leak) else 0

 if is_vulnerable:
 stats_binary["VULNERABLE"] += 1
 else:
 stats_binary["SAFE"] += 1


 csv_rows.append({
 "contract": contract_name,
 "is_vulnerable": is_vulnerable,
 "mint": has_mint,
 "limit": has_limit,
 "leak": has_leak
 })

 except json.JSONDecodeError:
 print(f"[WARN] JSON : {contract_name}")
 except Exception as e:
 print(f"[ERROR] {contract_name}: {e}")


 print("\n" + "="*60)
 print(" STATISTICAL REPORT (CONTRACT LEVEL) ")
 print("="*60)

 print(f"yes: {total_processed}")

 print(f"\n[ 1: ]")
 print(f": yes . ")
 print("-" * 40)
 print(f"🔴 MINT : {stats_multilabel['MINT']}")
 print(f"🟡 LIMIT : {stats_multilabel['LIMIT']}")
 print(f"🟠 LEAK : {stats_multilabel['LEAK']}")

 print(f"\n[ 2: 0/1 ]")
 print(f": 1 (Vulnerable), no 0 (Safe). ")
 print("-" * 40)
 print(f"❌ yes (1): {stats_binary['VULNERABLE']} (: {stats_binary['VULNERABLE']/total_processed*100:.1f}%)" if total_processed else "0")
 print(f"✅ no (0): {stats_binary['SAFE']}")
 print("-" * 40)


 csv_file = OUTPUT_DIR / "statistics_summary.csv"
 try:
 with open(csv_file, "w", newline="", encoding="utf-8") as f:
 fieldnames = ["contract", "is_vulnerable", "mint", "limit", "leak"]
 writer = csv.DictWriter(f, fieldnames=fieldnames)

 writer.writeheader
 for row in csv_rows:
 writer.writerow(row)

 print(f"\n[] (CSV) : {csv_file}")
 print(f"CSV : is_vulnerable (0/1), mint (0/1), limit (0/1), leak (0/1)")
 except Exception as e:
 print(f"[] CSV : {e}")

if __name__ == "__main__":
 main
