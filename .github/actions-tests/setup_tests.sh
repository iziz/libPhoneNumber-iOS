#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python_bin="${PYTHON_ACTION_TEST_SETUP_PYTHON_BIN:-python3}"
venv_dir="${PYTHON_ACTION_TEST_VENV_DIR:-$script_dir/.venv}"
venv_python="$venv_dir/bin/python"

if [[ ! -d "$venv_dir" ]]; then
  "$python_bin" -m venv "$venv_dir"
fi

"$venv_python" -m pip install -r "$script_dir/requirements.txt"

echo "Python action test environment is ready: $venv_dir"
