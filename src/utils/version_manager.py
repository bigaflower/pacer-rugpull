import os
import re
import subprocess
from pathlib import Path
from typing import Optional, Tuple

from slither import Slither

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOLC_SELECT_STORAGE = PROJECT_ROOT / ".solc-select"
SOLC_SELECT_STORAGE.mkdir(parents=True, exist_ok=True)


PREFERRED_PATCH_BY_MAJOR_MINOR = {
    "0.4": "0.4.26",
    "0.5": "0.5.17",
    "0.6": "0.6.12",
    "0.7": "0.7.6",
    "0.8": "0.8.26",
    "0.9": "0.9.9",
}


class SolidityVersionManager:
    """Lightweight version manager for multi-version contract analysis."""

    @staticmethod
    def _highest_patch(version: str) -> str:
        try:
            major, minor, _ = version.split(".")
        except ValueError:
            return version
        key = f"{major}.{minor}"
        return PREFERRED_PATCH_BY_MAJOR_MINOR.get(key, version)

    @staticmethod
    def _version_tuple(version: str) -> Tuple[int, int, int]:
        try:
            return tuple(map(int, version.split(".")))
        except Exception:
            return (0, 0, 0)

    @staticmethod
    def detect_version(file_path: str) -> Optional[str]:
        try:
            content = Path(file_path).read_text(encoding='utf-8')

            content = re.sub(r'/\*.*?\*/', ' ', content, flags=re.DOTALL)
            content = re.sub(r'//.*', ' ', content)


            matches = re.findall(r'pragma\s+solidity\s+([^;]+);', content, re.IGNORECASE)
            if not matches:

                contract_match = re.search(r'\bcontract\s+([A-Za-z_]\w*)', content)
                old_ctor = None
                if contract_match:
                    cname = contract_match.group(1)
                    if re.search(rf'\bfunction\s+{re.escape(cname)}\s*\(', content):
                        old_ctor = True
                if old_ctor or re.search(r'\bfunction\s*\(\)\s*(public|external)?\s*(payable)?', content):
                    return PREFERRED_PATCH_BY_MAJOR_MINOR.get("0.4")
                return None


            exact_versions = []
            range_versions = []

            for version_spec in matches:
                version_spec = version_spec.strip()


                exact_with_equals = re.search(r'^=\s*(\d+\.\d+\.\d+)', version_spec)
                if exact_with_equals:
                    exact_versions.append(exact_with_equals.group(1))
                    continue


                exact_match = re.search(r'^(\d+\.\d+\.\d+)$', version_spec)
                if exact_match:

                    exact_versions.append(exact_match.group(1))
                    continue


                caret_match = re.search(r'\^(\d+\.\d+\.\d+)', version_spec)
                if caret_match:
                    range_versions.append(SolidityVersionManager._highest_patch(caret_match.group(1)))
                    continue


                caret_short = re.search(r'\^(\d+\.\d+)(?!\.\d)', version_spec)
                if caret_short:
                    range_versions.append(
                        SolidityVersionManager._highest_patch(f"{caret_short.group(1)}.0")
                    )
                    continue


                gte_match = re.search(r'>=\s*(\d+\.\d+\.\d+)', version_spec)
                if gte_match:
                    range_versions.append(SolidityVersionManager._highest_patch(gte_match.group(1)))
                    continue


                gt_match = re.search(r'>\s*(\d+)\.(\d+)\.(\d+)', version_spec)
                if gt_match:
                    major, minor, patch = int(gt_match.group(1)), int(gt_match.group(2)), int(gt_match.group(3))
                    bumped = f"{major}.{minor}.{patch + 1}"
                    range_versions.append(SolidityVersionManager._highest_patch(bumped))
                    continue


            if exact_versions:
                selected = max(exact_versions, key=SolidityVersionManager._version_tuple)
                if len(exact_versions) > 1:
                    print(f"   [*] Multiple exact versions found: {exact_versions}, using highest: {selected}")
                return selected


            if range_versions:
                selected = max(range_versions, key=SolidityVersionManager._version_tuple)
                if len(range_versions) > 1:
                    print(f"   [*] Multiple range versions found: {range_versions}, using highest: {selected}")
                return selected

            print(f"   [!] Could not parse any version from pragmas: {matches}")
            return None

        except Exception as e:
            print(f"   [!] Version detection failed: {e}")
            return None

    @staticmethod
    def switch_version(version: str) -> bool:
        env = os.environ.copy()
        env.setdefault("VIRTUAL_ENV", str(SOLC_SELECT_STORAGE))

        def _run(args, **kwargs):
            kwargs.setdefault("env", env)
            return subprocess.run(args, **kwargs)

        solc_path = SOLC_SELECT_STORAGE / "artifacts" / f"solc-{version}" / f"solc-{version}"
        if solc_path.exists():
            print(f"   [*] Using cached solc {version} at {solc_path}")
            return True


        try:
            _run(['solc-select', 'versions'], capture_output=True, check=True, timeout=10)
        except subprocess.TimeoutExpired:
            print("   [!] solc-select timeout when checking versions")
            return False
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("   [!] solc-select not installed. Install: pip install solc-select")
            return False

        try:
            print(f"   [*] Installing solc {version}...")
            install_result = _run(
                ['solc-select', 'install', version],
                capture_output=True, text=True, timeout=180
            )

            if install_result.returncode != 0:
                print(f"   [!] Installation failed: {install_result.stderr}")
                return False

            if solc_path.exists():
                print(f"   [*] Installed solc {version}")
                return True

            print("   [!] solc installation reported success but binary not found")
            return False

        except subprocess.TimeoutExpired:
            print(f"   [!] Timeout installing solc {version}")
            return False
        except Exception as e:
            print(f"   [!] Version switch failed: {e}")
            return False

    @staticmethod
    def init_slither(contract_path: str, **kwargs) -> Optional[Slither]:

        version = SolidityVersionManager.detect_version(contract_path)

        if version:
            print(f"   [*] Detected: solidity {version}")
            if not SolidityVersionManager.switch_version(version):
                print("   [!] Falling back to system solc due to version switch failure")
            else:
                solc_path = (
                    SOLC_SELECT_STORAGE
                    / "artifacts"
                    / f"solc-{version}"
                    / f"solc-{version}"
                )
                if solc_path.exists():
                    kwargs.setdefault("solc", str(solc_path))
        else:
            print("   [*] Using default compiler")


        contract_dir = Path(contract_path).parent
        kwargs.setdefault("solc_working_dir", str(contract_dir))


        try:
            return Slither(contract_path, **kwargs)
        except Exception as e:
            print(f"   [!] Slither initialization failed: {e}")
            return None


def init_slither(contract_path: str, **kwargs) -> Optional[Slither]:
    return SolidityVersionManager.init_slither(contract_path, **kwargs)
