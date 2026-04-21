#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

results_dir="${PYTHON_ACTION_TEST_RESULTS_DIR:-$script_dir/build/python-action-test-results}"
coverage_fail_under="${PYTHON_ACTION_TEST_COVERAGE_FAIL_UNDER:-}"
python_bin="${PYTHON_ACTION_TEST_PYTHON_BIN:-}"

if [[ -z "$python_bin" && -x "$script_dir/.venv/bin/python" ]]; then
  python_bin="$script_dir/.venv/bin/python"
fi

if [[ -z "$python_bin" ]]; then
  python_bin="python3"
fi

mkdir -p "$results_dir"
cd "$repo_root"
export COVERAGE_FILE="$script_dir/.coverage"
rm -f "$script_dir"/.coverage "$script_dir"/.coverage.*

cleanup_python_caches() {
  find "$repo_root" -type d \( -name "__pycache__" -o -name ".pytest_cache" \) -prune -exec rm -rf {} +
}

trap cleanup_python_caches EXIT

pytest_args=(
  "-c" "$script_dir/pyproject.toml"
  "$script_dir/simctl-tricorder-selector"
  "$script_dir/xcode-tricorder-tester"
  "$script_dir/xccov-warp-bubble"
  "--junitxml=$results_dir/junit.xml"
  "--cov=.github/actions/simctl-tricorder-selector"
  "--cov=.github/actions/xcode-tricorder-tester"
  "--cov=.github/actions/xccov-warp-bubble"
  "--cov-branch"
  "--cov-report="
)

if [[ -n "$coverage_fail_under" ]]; then
  pytest_args+=("--cov-fail-under=$coverage_fail_under")
fi

set +e
"$python_bin" -m pytest "${pytest_args[@]}"
pytest_exit_code=$?
set -e

shopt -s nullglob
coverage_shards=( "$script_dir"/.coverage.* )
shopt -u nullglob

if [[ ${#coverage_shards[@]} -gt 0 ]]; then
  "$python_bin" -m coverage combine "$script_dir"
fi

"$python_bin" -m coverage report --skip-covered --show-missing
"$python_bin" -m coverage xml -o "$results_dir/coverage.xml"
"$python_bin" -m coverage html -d "$results_dir/htmlcov"

exit "$pytest_exit_code"
