from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Tuple

import openpyxl


PROJECT_ROOT = Path(__file__).resolve.parents[2]
GROUND_TRUTH_DEFAULT = PROJECT_ROOT / "groundTruth.xlsx"
RESULTS_JSON_DEFAULT = PROJECT_ROOT / "results.json"

CATEGORIES: Tuple[str, ...] = ("MINT", "LEAK", "LIMIT")


def parse_args -> argparse.Namespace:
 parser = argparse.ArgumentParser(
 description="Compare CRP (results.json) predictions with groundTruth.xlsx."
 )
 parser.add_argument(
 "--results",
 default=str(RESULTS_JSON_DEFAULT),
 help="Path to results.json (default: %(default)s)",
 )
 parser.add_argument(
 "--ground-truth",
 default=str(GROUND_TRUTH_DEFAULT),
 help="Path to groundTruth.xlsx (default: %(default)s)",
 )
 return parser.parse_args


def normalize_label(value: Any) -> int:
 """Standardize ground truth labels in Excel (0 1)"""
 if value is None:
 return 0
 if isinstance(value, bool):
 return int(value)
 if isinstance(value, (int, float)):
 return int(value)
 text = str(value).strip
 if not text:
 return 0
 lowered = text.lower
 if lowered in {"1", "true", "yes", "y"} or text in {"yes", "yes"}:
 return 1
 if lowered in {"0", "false", "no", "n"} or text in {"no", "no"}:
 return 0
 try:
 return int(float(text))
 except ValueError:
 print(f"[WARN] Unrecognized label '{value}', defaulting to 0.")
 return 0


def load_ground_truth(path: Path) -> Dict[str, Dict[str, int]]:
 """ Ground Truth Excel """
 if not path.exists:
 raise FileNotFoundError(f"groundTruth not found: {path}")

 workbook = openpyxl.load_workbook(path, read_only=True, data_only=True)
 sheet = workbook.active
 labels: Dict[str, Dict[str, int]] = {}


 column_index = {"MINT": 1, "LEAK": 2, "LIMIT": 3}

 for row in sheet.iter_rows(min_row=2, values_only=True):
 contract = row[0]
 if not contract:
 continue
 address = str(contract).strip
 normalized = address.lower

 row_labels = {}
 for kind in CATEGORIES:
 idx = column_index.get(kind, 0)
 val = row[idx] if idx < len(row) else 0
 row_labels[kind] = normalize_label(val)

 labels[normalized] = row_labels

 workbook.close
 return labels


def load_crp_predictions(path: Path) -> Dict[str, Dict[str, int]]:
 """ CRP results.json """
 if not path.exists:
 raise FileNotFoundError(f"results.json not found: {path}")

 predictions: Dict[str, Dict[str, int]] = {}

 try:
 payload = json.loads(path.read_text(encoding="utf-8"))
 except json.JSONDecodeError as e:
 raise ValueError(f"Failed to parse JSON content: {e}")

 for entry in payload:

 if not isinstance(entry, list) or len(entry) < 2:
 continue

 raw_name = str(entry[0] or "")
 tags = entry[1] if isinstance(entry[1], list) else []

 if not raw_name:
 continue


 address = raw_name.split(".", 1)[0].strip
 if not address:
 continue
 normalized = address.lower

 flags = {kind: 0 for kind in CATEGORIES}


 for tag in tags:

 token = str(tag or "").strip.lower


 if token == "mint_0106":
 flags["MINT"] = 1
 elif token == "leak_0104":
 flags["LEAK"] = 1
 elif token == "limit_0102":
 flags["LIMIT"] = 1


 predictions[normalized] = flags

 return predictions


def evaluate(predictions: Dict[str, Dict[str, int]], ground_truth: Dict[str, Dict[str, int]]) -> Tuple[List[List[str]], Dict[str, Dict[str, int]], List[str]]:
 """,  TP/FP/FN"""
 header = ["Contract"] + [f"GT_{k}" for k in CATEGORIES] + [f"CRP_{k}" for k in CATEGORIES]
 rows: List[List[str]] = [header]
 metrics = {kind: {"TP": 0, "FP": 0, "FN": 0} for kind in CATEGORIES}
 skipped: List[str] = []


 for contract, gt_labels in sorted(ground_truth.items):
 pred = predictions.get(contract)


 if pred is None:
 skipped.append(contract)
 continue

 row = [contract]
 for kind in CATEGORIES:
 gt_val = int(gt_labels.get(kind, 0))
 det_val = int(pred.get(kind, 0))

 row.append(str(gt_val))
 row.append(str(det_val))

 if det_val == 1 and gt_val == 1:
 metrics[kind]["TP"] += 1
 elif det_val == 1 and gt_val == 0:
 metrics[kind]["FP"] += 1
 elif det_val == 0 and gt_val == 1:
 metrics[kind]["FN"] += 1

 rows.append(row)

 return rows, metrics, skipped


def build_metrics_table(metrics: Dict[str, Dict[str, int]]) -> List[List[str]]:
 """ Precision, Recall, F1"""
 header = ["Category", "TP", "FP", "FN", "Precision", "Recall", "F1"]
 rows: List[List[str]] = [header]
 totals = {"TP": 0, "FP": 0, "FN": 0}

 def safe_div(num: int, denom: int) -> float:
 return num / denom if denom else 0.0


 for kind in CATEGORIES:
 stats = metrics[kind]
 tp, fp, fn = stats["TP"], stats["FP"], stats["FN"]
 totals["TP"] += tp
 totals["FP"] += fp
 totals["FN"] += fn

 precision = safe_div(tp, tp + fp)
 recall = safe_div(tp, tp + fn)
 f1 = safe_div(2 * precision * recall, precision + recall) if (precision + recall) else 0.0

 rows.append([kind, str(tp), str(fp), str(fn), f"{precision:.3f}", f"{recall:.3f}", f"{f1:.3f}"])


 overall_precision = safe_div(totals["TP"], totals["TP"] + totals["FP"])
 overall_recall = safe_div(totals["TP"], totals["TP"] + totals["FN"])
 overall_f1 = safe_div(2 * overall_precision * overall_recall, overall_precision + overall_recall) if (overall_precision + overall_recall) else 0.0

 rows.append(["OVERALL", str(totals["TP"]), str(totals["FP"]), str(totals["FN"]), f"{overall_precision:.3f}", f"{overall_recall:.3f}", f"{overall_f1:.3f}"])
 return rows


def format_table(rows: List[List[str]]) -> str:
 """"""
 if not rows:
 return ""
 widths = [max(len(row[i]) for row in rows) for i in range(len(rows[0]))]

 def fmt(row: List[str]) -> str:
 return " ".join(cell.ljust(width) for cell, width in zip(row, widths))

 lines = [fmt(rows[0]), fmt(["-" * w for w in widths])]
 lines.extend(fmt(row) for row in rows[1:])
 return "\n".join(lines)


def main -> None:
 args = parse_args

 try:
 ground_truth = load_ground_truth(Path(args.ground_truth))
 predictions = load_crp_predictions(Path(args.results))
 except Exception as e:
 print(f"[ERROR] {e}")
 return

 comparison_rows, metrics, skipped = evaluate(predictions, ground_truth)
 print("CRP vs GroundTruth (Details):")
 print(format_table(comparison_rows))

 if skipped:
 print
 print(f"[INFO] Skipped {len(skipped)} contract(s) found in GroundTruth but missing in results.json.")


 print
 print("Precision / Recall / F1 Summary:")
 print(format_table(build_metrics_table(metrics)))


if __name__ == "__main__":
 main
