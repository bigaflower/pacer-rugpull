from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import shutil
from typing import Any, Dict, Iterable, List, Optional, Tuple

import openpyxl


try:
    PROJECT_ROOT = Path(__file__).resolve().parents[2]
except ValueError:
    PROJECT_ROOT = Path.cwd()

OUTPUT_DIR = PROJECT_ROOT / "output"
GROUND_TRUTH_PATH = PROJECT_ROOT / "groundTruth.xlsx"
RESULTS_JSON_PATH = PROJECT_ROOT / "results.json"
ANALYSIS_FILENAME = "step2.2_semantic_analysis.json"
CATEGORIES: Tuple[str, ...] = ("MINT", "LIMIT", "LEAK", "EMPTY", "ERROR")
GT_ORDER: Tuple[str, ...] = ("MINT", "LEAK", "LIMIT")


@dataclass
class ContractSummary:
    counts: Dict[str, int]
    total: int
    direct: int = 0
    indirect: int = 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Summarize contract categories and compare with ground-truth labels."
    )
    parser.add_argument(
        "--contracts",
        nargs="+",
        help="Specific contract folders to include (default: all with Step2 outputs).",
    )
    parser.add_argument(
        "--output-dir",
        default=str(OUTPUT_DIR),
        help="Root directory containing per-contract output folders (default: ./output).",
    )
    parser.add_argument(
        "--ground-truth",
        default=str(GROUND_TRUTH_PATH),
        help="Path to groundTruth.xlsx for label comparison (default: ./groundTruth.xlsx).",
    )
    parser.add_argument(
        "--no-export",
        action="store_true",
        help="Disable exporting timestamped folders (default exports reports/UTC_TIMESTAMP).",
    )
    parser.add_argument(
        "--export-root",
        default=None,
        help="Base directory for exported reports (default: output/reports).",
    )
    parser.add_argument(
        "--results-json",
        default=str(RESULTS_JSON_PATH),
        help="Path to legacy results.json for pattern-based comparison.",
    )
    return parser.parse_args()


def discover_analysis_files(root: Path, contracts: Iterable[str] | None) -> List[Path]:
    root = root.resolve()
    if not root.exists():
        return []

    targets = []
    if contracts:
        for contract in contracts:
            path = root / contract / "step2" / ANALYSIS_FILENAME
            if path.exists():
                targets.append(path)
    else:
        for contract_dir in root.iterdir():
            if not contract_dir.is_dir():
                continue
            candidate = contract_dir / "step2" / ANALYSIS_FILENAME
            if candidate.exists():
                targets.append(candidate)

    return sorted(targets)


def _count_from_paths(data: Dict[str, Any]) -> Tuple[Dict[str, int], int, int]:
    counts = {category: 0 for category in CATEGORIES}
    direct = 0
    indirect = 0
    paths = data.get("paths", []) or []
    for entry in paths:
        path_type = (entry.get("path_type") or "").upper()
        if path_type == "DIRECT":
            direct += 1
        elif path_type == "INDIRECT":
            indirect += 1
        label = (entry.get("category") or "").upper()
        if label in {"MINT", "LIMIT", "LEAK"}:
            counts[label] += 1
        else:
            llm_category = (
                ((entry.get("llm_result") or {}).get("category") or "").upper()
            )
            if llm_category == "ERROR":
                counts["ERROR"] += 1
            else:
                counts["EMPTY"] += 1
    return counts, direct, indirect


def load_summary(file_path: Path) -> Tuple[Dict[str, int], int, int, int]:
    data = json.loads(file_path.read_text(encoding="utf-8"))
    path_counts, direct, indirect = _count_from_paths(data)
    total_paths = len(data.get("paths", []) or [])


    if total_paths == 0:
        summary = data.get("summary", {})
        path_counts = {category: int(summary.get(category, 0)) for category in CATEGORIES}
        total_paths = sum(path_counts.values())

    return path_counts, total_paths, direct, indirect


def format_table(rows: List[List[str]]) -> str:
    widths = [max(len(row[i]) for row in rows) for i in range(len(rows[0]))]

    def fmt(row: List[str]) -> str:
        return "  ".join(cell.ljust(width) for cell, width in zip(row, widths))

    lines = [fmt(rows[0]), fmt(["-" * w for w in widths])]
    lines.extend(fmt(row) for row in rows[1:])
    return "\n".join(lines)


def gather_contract_data(files: List[Path]) -> Dict[str, ContractSummary]:
    contract_data: Dict[str, ContractSummary] = {}
    for path in files:
        contract = path.parent.parent.name
        counts, contract_total, direct, indirect = load_summary(path)
        contract_data[contract] = ContractSummary(
            counts=counts,
            total=contract_total,
            direct=direct,
            indirect=indirect,
        )
    return contract_data


def build_summary_table(contract_data: Dict[str, ContractSummary]) -> List[List[str]]:
    totals = {category: 0 for category in CATEGORIES}
    total_paths = 0
    total_direct = 0
    total_indirect = 0
    rows: List[List[str]] = [
        [
            "Contract",
            "Total",
            "Direct",
            "Indirect",
            "Suspicious",
            "MINT",
            "LIMIT",
            "LEAK",
        ]
    ]

    for contract in sorted(contract_data):
        summary = contract_data[contract]
        counts = summary.counts
        contract_total = summary.total
        total_direct += summary.direct
        total_indirect += summary.indirect
        for category, value in counts.items():
            totals[category] += value
        total_paths += contract_total
        suspicious = counts["MINT"] + counts["LIMIT"] + counts["LEAK"]
        rows.append(
            [
                contract,
                str(contract_total),
                str(summary.direct),
                str(summary.indirect),
                str(suspicious),
                str(counts["MINT"]),
                str(counts["LIMIT"]),
                str(counts["LEAK"]),
            ]
        )

    rows.append(
        [
            "TOTAL",
            str(total_paths),
            str(total_direct),
            str(total_indirect),
            str(totals["MINT"] + totals["LIMIT"] + totals["LEAK"]),
            str(totals["MINT"]),
            str(totals["LIMIT"]),
            str(totals["LEAK"]),
        ]
    )
    return rows


def normalize_label(value: Any) -> int:
    if value is None:
        return 0
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, (int, float)):
        return int(value)
    text = str(value).strip()
    if not text:
        return 0
    lowered = text.lower()
    if lowered in {"1", "true", "yes", "y"} or text in {"yes", "yes"}:
        return 1
    if lowered in {"0", "false", "no", "n"} or text in {"no", "no"}:
        return 0
    try:
        return int(float(text))
    except ValueError:
        print(f"[WARN] Unrecognized label '{value}', defaulting to 0.")
        return 0


def load_ground_truth(path: Path) -> Dict[str, Dict[str, Any]]:
    if not path.exists():
        return {}
    workbook = openpyxl.load_workbook(path, read_only=True, data_only=True)
    sheet = workbook.active
    column_index = {"MINT": 1, "LEAK": 2, "LIMIT": 3}

    labels: Dict[str, Dict[str, Any]] = {}
    for row in sheet.iter_rows(min_row=2, values_only=True):
        contract = row[0]
        if not contract:
            continue
        contract_name = str(contract).strip()
        normalized_name = contract_name.lower()
        label_values = {}
        for kind in GT_ORDER:
            col_idx = column_index.get(kind, 0)
            value = row[col_idx] if col_idx < len(row) else 0
            label_values[kind] = normalize_label(value)
        labels[normalized_name] = {
            "address": contract_name,
            "labels": label_values,
        }
    workbook.close()
    return labels


def load_results_predictions(path: Path) -> Dict[str, Dict[str, int]]:
    if not path.exists():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        print(f"[WARN] Unable to parse {path}; skipping results.json comparison.")
        return {}
    predictions: Dict[str, Dict[str, int]] = {}
    for entry in payload:
        if not isinstance(entry, list) or len(entry) < 2:
            continue
        raw_name = str(entry[0])
        tags = entry[1] if isinstance(entry[1], list) else []
        if not raw_name:
            continue
        address = raw_name.split(".", 1)[0].strip()
        if not address:
            continue
        normalized = address.lower()
        flags = {kind: 0 for kind in GT_ORDER}
        for tag in tags:
            token = str(tag).strip().lower()
            if not token:
                continue
            if token.startswith("mint"):
                flags["MINT"] = 1
            elif token.startswith("leak"):
                flags["LEAK"] = 1
            elif token.startswith("limit"):
                flags["LIMIT"] = 1
        predictions[normalized] = flags
    return predictions


def _build_step2_detector(contract_data: Dict[str, ContractSummary]):
    lookup = {name.lower(): summary for name, summary in contract_data.items()}

    def detector(contract: str) -> Optional[Dict[str, int]]:
        original = contract_data.get(contract)
        summary = original or lookup.get(contract.lower())
        if not summary:
            return None
        counts = summary.counts
        return {kind: int(counts.get(kind, 0) > 0) for kind in GT_ORDER}

    return detector


def evaluate_results_vs_ground_truth(
    ground_truth: Dict[str, Dict[str, Any]],
    detector,
) -> Tuple[List[List[str]], Dict[str, Dict[str, int]], List[str]]:
    table, metrics, skipped, _ = evaluate_predictions_against_ground_truth(
        ground_truth, detector
    )
    return table, metrics, skipped


def evaluate_predictions_against_ground_truth(
    ground_truth: Dict[str, Dict[str, Any]],
    detector,
) -> Tuple[List[List[str]], Dict[str, Dict[str, int]], List[str], List[Dict[str, Any]]]:
    header = [
        "Contract",
        "GT_MINT",
        "DET_MINT",
        "GT_LEAK",
        "DET_LEAK",
        "GT_LIMIT",
        "DET_LIMIT",
    ]
    rows: List[List[str]] = [header]
    gt_totals = {kind: 0 for kind in GT_ORDER}
    det_totals = {kind: 0 for kind in GT_ORDER}
    metrics: Dict[str, Dict[str, int]] = {
        kind: {"TP": 0, "FP": 0, "FN": 0} for kind in GT_ORDER
    }
    skipped: List[str] = []
    mismatches: List[Dict[str, Any]] = []

    for entry in sorted(ground_truth.values(), key=lambda item: item["address"].lower()):
        contract = entry["address"]
        gt = entry["labels"]
        detected = detector(contract)
        if detected is None:
            skipped.append(contract)
            continue
        mismatch_categories: List[str] = []
        for kind in GT_ORDER:
            gt_totals[kind] += int(gt.get(kind, 0))
            det_val = detected[kind]
            det_totals[kind] += det_val
            gt_val = int(gt.get(kind, 0))
            if det_val and gt_val:
                metrics[kind]["TP"] += 1
            elif det_val and not gt_val:
                metrics[kind]["FP"] += 1
            elif not det_val and gt_val:
                metrics[kind]["FN"] += 1
            if det_val != gt_val:
                mismatch_categories.append(kind)

        if mismatch_categories:
            mismatches.append(
                {
                    "contract": contract,
                    "gt": {kind: int(gt.get(kind, 0)) for kind in GT_ORDER},
                    "detected": {kind: detected.get(kind, 0) for kind in GT_ORDER},
                    "mismatch_categories": mismatch_categories,
                }
            )

        rows.append(
            [
                contract,
                str(gt.get("MINT", 0)),
                str(detected["MINT"]),
                str(gt.get("LEAK", 0)),
                str(detected["LEAK"]),
                str(gt.get("LIMIT", 0)),
                str(detected["LIMIT"]),
            ]
        )

    rows.append(
        [
            "TOTAL",
            str(gt_totals["MINT"]),
            str(det_totals["MINT"]),
            str(gt_totals["LEAK"]),
            str(det_totals["LEAK"]),
            str(gt_totals["LIMIT"]),
            str(det_totals["LIMIT"]),
        ]
    )
    return rows, metrics, skipped, mismatches


def build_metrics_table(metrics: Dict[str, Dict[str, int]]) -> List[List[str]]:
    header = ["Category", "TP", "FP", "FN", "Precision", "Recall", "F1"]
    rows: List[List[str]] = [header]
    totals = {"TP": 0, "FP": 0, "FN": 0}

    def safe_div(num: int, denom: int) -> float:
        return num / denom if denom else 0.0

    for kind in GT_ORDER:
        stats = metrics.get(kind, {"TP": 0, "FP": 0, "FN": 0})
        tp = stats["TP"]
        fp = stats["FP"]
        fn = stats["FN"]
        totals["TP"] += tp
        totals["FP"] += fp
        totals["FN"] += fn
        precision = safe_div(tp, tp + fp)
        recall = safe_div(tp, tp + fn)
        f1 = safe_div(2 * precision * recall, precision + recall) if (precision + recall) else 0.0
        rows.append(
            [
                kind,
                str(tp),
                str(fp),
                str(fn),
                f"{precision:.3f}",
                f"{recall:.3f}",
                f"{f1:.3f}",
            ]
        )

    total_precision = safe_div(totals["TP"], totals["TP"] + totals["FP"])
    total_recall = safe_div(totals["TP"], totals["TP"] + totals["FN"])
    total_f1 = (
        safe_div(2 * total_precision * total_recall, total_precision + total_recall)
        if (total_precision + total_recall)
        else 0.0
    )
    rows.append(
        [
            "OVERALL",
            str(totals["TP"]),
            str(totals["FP"]),
            str(totals["FN"]),
            f"{total_precision:.3f}",
            f"{total_recall:.3f}",
            f"{total_f1:.3f}",
        ]
    )
    return rows


def main() -> None:
    args = parse_args()
    output_dir = Path(args.output_dir)
    files = discover_analysis_files(output_dir, args.contracts)
    if not files:
        print("No Step2 semantic analysis files found.")
        return

    contract_data = gather_contract_data(files)
    summary_table = build_summary_table(contract_data)
    summary_text = format_table(summary_table)
    print(summary_text)

    ground_truth_path = Path(args.ground_truth)
    ground_truth = load_ground_truth(ground_truth_path)
    gt_text = ""
    metrics_text = ""
    step2_skipped: List[str] = []
    step2_mismatches: List[Dict[str, Any]] = []
    results_table_text = ""
    results_metrics_text = ""
    results_skipped: List[str] = []
    if ground_truth:
        print()
        print(f"Ground-truth comparison for Step2 ({ground_truth_path}):")
        detector = _build_step2_detector(contract_data)
        gt_table, metrics, skipped, mismatches = evaluate_predictions_against_ground_truth(ground_truth, detector)
        gt_text = format_table(gt_table)
        print(gt_text)
        if skipped:
            step2_skipped = skipped
            print()
            print(f"[INFO] Skipped {len(skipped)} contract(s) without Step2 outputs: {', '.join(skipped)}")
        if mismatches:
            step2_mismatches = mismatches
            print()
            print("Contracts with mismatched Step2 labels (GT vs DET):")
            for item in mismatches:
                contract = item["contract"]
                gt_vals = ", ".join(f"{kind}:{item['gt'][kind]}" for kind in GT_ORDER)
                det_vals = ", ".join(f"{kind}:{item['detected'][kind]}" for kind in GT_ORDER)
                mismatch_kinds = ", ".join(item["mismatch_categories"])
                print(f"  - {contract} | GT[{gt_vals}] vs Step2[{det_vals}] (diff: {mismatch_kinds})")
        print()
        print("Step2 Precision / Recall / F1:")
        metrics_table = build_metrics_table(metrics)
        metrics_text = format_table(metrics_table)
        print(metrics_text)

        results_path = Path(args.results_json)
        if results_path.exists():
            predictions = load_results_predictions(results_path)
            if predictions:
                def _results_detector(contract: str) -> Optional[Dict[str, int]]:
                    return predictions.get(contract.lower())

                print()
                print(f"results.json comparison ({results_path}):")
                res_table, res_metrics, res_skipped = evaluate_results_vs_ground_truth(
                    ground_truth, _results_detector
                )
                results_table_text = format_table(res_table)
                print(results_table_text)
                if res_skipped:
                    results_skipped = res_skipped
                    print()
                    print(f"[INFO] results.json missing {len(res_skipped)} contract(s): {', '.join(res_skipped)}")
                print()
                print("results.json Precision / Recall / F1:")
                res_metrics_table = build_metrics_table(res_metrics)
                results_metrics_text = format_table(res_metrics_table)
                print(results_metrics_text)
            else:
                print()
                print(f"[WARN] No recognizable entries in {results_path}")
        else:
            print()
            print(f"[WARN] results.json not found at {results_path}")
    else:
        print()
        print(f"[WARN] Ground-truth file not found at {ground_truth_path}")

    if not args.no_export:
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        export_base = Path(args.export_root) if args.export_root else Path("reports")
        export_dir = export_base / timestamp
        export_dir.mkdir(parents=True, exist_ok=True)

        stats_file = export_dir / "statistics.txt"
        with stats_file.open("w", encoding="utf-8") as handle:
            handle.write("Step2 Semantic Summary\n")
            handle.write(summary_text + "\n\n")
            if gt_text:
                handle.write(f"Ground-truth comparison for Step2 ({ground_truth_path}):\n")
                handle.write(gt_text + "\n\n")
            if step2_skipped:
                handle.write(f"Skipped contracts without Step2 outputs: {', '.join(step2_skipped)}\n\n")
            if step2_mismatches:
                handle.write("Contracts with mismatched Step2 labels:\n")
                for item in step2_mismatches:
                    contract = item["contract"]
                    gt_vals = ", ".join(f"{kind}:{item['gt'][kind]}" for kind in GT_ORDER)
                    det_vals = ", ".join(f"{kind}:{item['detected'][kind]}" for kind in GT_ORDER)
                    mismatch_kinds = ", ".join(item["mismatch_categories"])
                    handle.write(f"  - {contract} | GT[{gt_vals}] vs Step2[{det_vals}] (diff: {mismatch_kinds})\n")
                handle.write("\n")
            if metrics_text:
                handle.write("Step2 Precision / Recall / F1:\n")
                handle.write(metrics_text + "\n")
            if results_table_text:
                handle.write("\nresults.json comparison:\n")
                handle.write(results_table_text + "\n\n")
            if results_skipped:
                handle.write(f"results.json missing contracts: {', '.join(results_skipped)}\n\n")
            if results_metrics_text:
                handle.write("results.json Precision / Recall / F1:\n")
                handle.write(results_metrics_text + "\n")

        exported_contracts = set()
        for file_path in files:
            contract_root = file_path.parent.parent
            contract_name = contract_root.name
            if contract_name in exported_contracts:
                continue
            exported_contracts.add(contract_name)

            target_dir = export_dir / contract_name
            target_dir.mkdir(parents=True, exist_ok=True)

            for stage in ("step1", "step2"):
                stage_src = contract_root / stage
                if stage_src.exists():
                    shutil.copytree(stage_src, target_dir / stage, dirs_exist_ok=True)


if __name__ == "__main__":
    main()
