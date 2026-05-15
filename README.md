# PACER Dataset

Permission-level Attack and Control Escalation Recognition (PACER) dataset for detecting rugpull vulnerabilities in Ethereum smart contracts.

## Overview

- **Total contracts**: 4,557
- **Analyzed**: 4,529 (99.4%)
- **Positive (rugpull)**: 2,388
- **Negative (normal)**: 2,141 analyzed / 2,169 total
- **Total size**: ~3.1 GB

## Detection Metrics (Main Experiment)

| Metric | Value |
|--------|-------|
| True Positives (TP) | 1,933 |
| False Positives (FP) | 507 |
| True Negatives (TN) | 1,634 |
| False Negatives (FN) | 455 |
| **Precision** | 0.7921 |
| **Recall** | 0.8095 |
| **F1 Score** | 0.8004 |

## Directory Structure

```
PACER_DATASET_UPLOAD/
├── README.md                     # This file
├── dataset_summary.json          # Dataset metadata and statistics
├── P/                            # 2,388 rugpull contracts (ground truth positives)
│   └── <address>/
│       ├── code/                 # Solidity source, compile info, detection result
│       └── result/               # PACER analysis results (step1 + step2)
└── N/
    ├── benign/                   # 234 confirmed benign contracts (TN)
    │   └── <address>/            # (same structure as P/)
    ├── no_path/                  # 1,400 contracts, zero escalation paths found (TN)
    │   └── <address>/            # (same structure as P/)
    ├── F_positive/               # 507 false positives — flagged but manually benign
    │   └── <address>/            # (same structure as P/)
    └── others/                   # 28 contracts, pipeline failure (Slither init error)
        └── <address>/
            └── code/             # Source code only, no analysis results
```

## Per-Contract Files

### `code/` (all contracts)
- `*.sol` — Solidity source code
- `compile.json` — Compilation metadata (contract name, version, file name)
- `metadata.json` — Contract metadata (name, compiler version, ABI)
- `detect_result.json` — Detection result (primarily in P/ contracts). Contains:
  - `DPW` / `IDPW` — Direct/Indirect Permission Write patterns
  - `DT` / `IDT` — Direct/Indirect Trapdoors
  - `FLAG` — Overall detection result (true = vulnerable detected)

### `result/step1/` (all except N/others)
- `step1.1_caller_source.json` — Caller source identification
- `step1.2_permission_profile.json` — Permission profile extraction
- `step1.3_PLCG.json` — Permission-Level Call Graph
- `step1.4_paths.json` — Extracted permission escalation paths

### `result/step2/` (all except N/others)
- `step2.1_formatted_paths.json` — Formatted paths for semantic analysis
- `step2.2_semantic_analysis.json` — Semantic analysis results (MINT / LIMIT / LEAK detection)

## Category Definitions

| Category | Count | Meaning | Detection |
|----------|-------|---------|-----------|
| P/ | 2,388 | Confirmed rugpull | Ground truth positive |
| N/benign/ | 234 | Confirmed benign | True Negative (TN) |
| N/no_path/ | 1,400 | No escalation paths | True Negative (TN) |
| N/F_positive/ | 507 | Flagged but benign | False Positive (FP) |
| N/others/ | 28 | Pipeline failure | Excluded from metrics |

## Notes

- **N/no_path**: These contracts have complete source code and PACER ran successfully, but found zero permission escalation paths (i.e., no state variables are writable through permission-gated call chains). The `step1.4_paths.json` contains empty path arrays.
- **N/others**: These 28 contracts failed at Slither initialization (typically due to unresolved OpenZeppelin dependency chains). They have source code but no analysis results.
- **Fallback files**: Some contracts used the `__rq2_raw` variant as fallback when the default result file was missing (primarily `step2.1_formatted_paths.json` in ~1,051 N/ contracts).

## Usage

Each contract is identified by its Ethereum address (directory name). The `code/` directory contains the Solidity source files. The `result/` directory contains the PACER detection pipeline outputs.

To load detection results for a contract:
```python
import json
with open("<address>/code/detect_result.json") as f:
    result = json.load(f)
print(f"Flagged: {result.get('FLAG', False)}")
```

## License

This dataset is provided for academic research purposes. Individual contract source code retains its original license.

## Citation

If you use this dataset in your research, please cite the corresponding paper.
