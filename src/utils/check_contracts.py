import sys
import argparse
import subprocess
from pathlib import Path
from io import StringIO
from contextlib import redirect_stdout, redirect_stderr


try:
    PROJECT_ROOT = Path(__file__).resolve().parents[2]
except:
    PROJECT_ROOT = Path.cwd()

sys.path.insert(0, str(PROJECT_ROOT / 'src'))

from utils.version_manager import init_slither, SolidityVersionManager


def check_contract(contract_path: Path) -> dict:
    """Check if a contract can be compiled."""
    version = SolidityVersionManager.detect_version(str(contract_path))


    with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
        slither = init_slither(str(contract_path))

    if slither is not None:
        return {
            'name': contract_path.name,
            'version': version or 'N/A',
            'status': 'SUCCESS',
            'error': '',
            'contracts': len(slither.contracts)
        }


    try:
        proc = subprocess.run(
            ['solc', '--optimize', str(contract_path)],
            capture_output=True, text=True, timeout=5
        )
        error = proc.stderr.strip()


        if '@openzeppelin' in error or 'not found' in error.lower():
            error_type = 'Missing dependencies'
        elif 'immutable' in error.lower():
            error_type = 'Immutable variable error'
        elif 'override' in error.lower():
            error_type = 'Missing override specifier'
        elif 'visibility' in error.lower():
            error_type = 'Visibility mismatch'
        elif 'calldata' in error.lower():
            error_type = 'Calldata not supported'
        elif 'SPDX' in error:
            error_type = 'SPDX/Import issues'
        else:
            error_type = 'Compilation error'
    except:
        error_type = 'Unknown error'

    return {
        'name': contract_path.name,
        'version': version or 'N/A',
        'status': 'FAILED',
        'error': error_type,
        'contracts': 0
    }


def main():
    parser = argparse.ArgumentParser(description='Check contract compilation status')
    parser.add_argument('contract', nargs='?', help='Specific contract to check')
    parser.add_argument('--failed', action='store_true', help='Show only failed contracts')
    parser.add_argument('--success', action='store_true', help='Show only successful contracts')
    parser.add_argument('--quiet', '-q', action='store_true', help='Minimal output')
    args = parser.parse_args()

    contracts_dir = PROJECT_ROOT / 'contracts'


    if args.contract:
        contract_path = contracts_dir / args.contract
        if not contract_path.exists():

            contract_path = contracts_dir / f"{args.contract}.sol"

        if not contract_path.exists():
            print(f"❌ Contract not found: {args.contract}")
            return 1

        result = check_contract(contract_path)
        if result['status'] == 'SUCCESS':
            print(f"✅ {result['name']} (v{result['version']}) - {result['contracts']} contracts")
        else:
            print(f"❌ {result['name']} (v{result['version']}) - {result['error']}")
        return 0 if result['status'] == 'SUCCESS' else 1


    contracts = sorted(contracts_dir.glob('*.sol'))

    if not contracts:
        print("❌ No contracts found in contracts/ directory")
        return 1

    results = []
    total = len(contracts)

    if not args.quiet:
        print(f"\n{'='*60}")
        print(f"  Contract Compilation Checker")
        print(f"{'='*60}\n")

    for i, contract_path in enumerate(contracts, 1):
        if not args.quiet:
            print(f"\r  Checking {i}/{total}...", end='', flush=True)
        results.append(check_contract(contract_path))

    if not args.quiet:
        print("\r" + " " * 30 + "\r", end='')


    if args.failed:
        results = [r for r in results if r['status'] == 'FAILED']
    elif args.success:
        results = [r for r in results if r['status'] == 'SUCCESS']


    success_count = sum(1 for r in results if r['status'] == 'SUCCESS')
    fail_count = sum(1 for r in results if r['status'] == 'FAILED')

    if not args.quiet:
        print(f"{'='*60}\n")


    if not args.failed:
        success_results = [r for r in results if r['status'] == 'SUCCESS']
        if success_results:
            print(f"✅ Successfully Compiled ({len(success_results)})")
            print(f"{'-'*60}")
            for r in success_results:
                print(f"  {r['name']:<50} v{r['version']}")
            print()

    if not args.success:
        failed_results = [r for r in results if r['status'] == 'FAILED']
        if failed_results:
            print(f"❌ Failed ({len(failed_results)})")
            print(f"{'-'*60}")
            for r in failed_results:
                print(f"  {r['name']:<50} {r['error']}")
            print()


    if not args.quiet and not args.failed and not args.success:
        total_checked = success_count + fail_count
        print(f"{'='*60}")
        print(f"  Summary: {success_count}/{total_checked} successful ({success_count/total_checked*100:.1f}%)")
        print(f"{'='*60}\n")

    return 0 if fail_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
