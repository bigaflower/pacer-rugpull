from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


CallerContext = Dict[str, Any]


def format_function_key(contract_name: Optional[str], function_full_name: str) -> str:
    """Return a normalized Contract.function signature string."""
    contract_segment = contract_name or "UnknownContract"
    return f"{contract_segment}.{function_full_name}"


def _normalize_scope_entries(scope_value: Any) -> List[str]:
    if isinstance(scope_value, list):
        return [entry for entry in scope_value if isinstance(entry, str) and entry]
    if isinstance(scope_value, str) and scope_value:
        return [scope_value]
    return []


def _extract_function_from_scope(scope_entry: str) -> Optional[str]:
    if not scope_entry:
        return None
    if ":" not in scope_entry:
        return scope_entry.strip()
    return scope_entry.split(":", 1)[0].strip()


def build_caller_context(step11_payload: Dict[str, Any]) -> CallerContext:
    global_symbols: Dict[str, Dict[str, Any]] = {}
    function_symbols: Dict[str, Dict[str, Dict[str, Any]]] = defaultdict(dict)
    wrapper_functions: set[str] = set()
    tainted_parameters: Dict[str, Any] = {}

    def _ingest_entry(contract_name: str, symbol_name: str, info: Any):
        entry = info if isinstance(info, dict) else {"source": info, "scope": "always"}
        normalized_name = symbol_name.lower()
        scope_value = entry.get("scope", "always")

        if scope_value == "always":
            global_symbols[normalized_name] = {
                "name": symbol_name,
                "source": entry.get("source", "msg.sender"),
            }
            if normalized_name not in {"msg.sender", "tx.origin"}:
                wrapper_functions.add(normalized_name)
            return

        for scope_entry in _normalize_scope_entries(scope_value):
            func_sig = _extract_function_from_scope(scope_entry)
            if not func_sig:
                continue
            function_symbols[func_sig][normalized_name] = {
                "name": symbol_name,
                "source": entry.get("source", "msg.sender"),
                "scope": scope_entry,
            }

    for bundle in step11_payload.values():
        if not isinstance(bundle, dict):
            continue
        for contract_name, analysis in bundle.items():
            if not isinstance(analysis, dict):
                continue

            transient = analysis.get("transient_caller_analysis", {})
            raw_map = transient.get("caller_map", {})
            for symbol_name, info in raw_map.items():
                _ingest_entry(contract_name, symbol_name, info)

            raw_tainted = transient.get("tainted_parameters", {})
            for func_key, param_data in raw_tainted.items():
                qualified_key = (
                    func_key
                    if "." in func_key
                    else format_function_key(contract_name, func_key)
                )
                tainted_parameters[qualified_key] = param_data

    symbol_count = len(global_symbols) + sum(
        len(symbols) for symbols in function_symbols.values()
    )

    return {
        "global_symbols": global_symbols,
        "function_symbols": dict(function_symbols),
        "wrapper_functions": wrapper_functions,
        "tainted_parameters": tainted_parameters,
        "symbol_count": symbol_count,
    }


def load_caller_context(step11_file: Path) -> CallerContext:
    """Load and parse caller context from a step1.1 output file."""
    if not step11_file.exists():
        return {
            "global_symbols": {},
            "function_symbols": {},
            "wrapper_functions": set(),
            "tainted_parameters": {},
            "symbol_count": 0,
        }

    with step11_file.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)

    return build_caller_context(payload)
