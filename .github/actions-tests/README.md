# Actions Tests

This folder contains the Python unit-test harness for the reusable GitHub Actions under `.github/actions`.
The subfolder layout mirrors the action names so each action's tests live beside the corresponding action name under `.github/actions-tests`.

## Local setup

1. Run the setup script:

   ```bash
   ./.github/actions-tests/setup_tests.sh
   ```

2. Run the tests and generate coverage artifacts:

   ```bash
   ./.github/actions-tests/run_tests.sh
   ```

If `.github/actions-tests/.venv` exists, the test runner will automatically use it.

To use a specific Python interpreter during setup, set `PYTHON_ACTION_TEST_SETUP_PYTHON_BIN`:

```bash
PYTHON_ACTION_TEST_SETUP_PYTHON_BIN=python3.13 ./.github/actions-tests/setup_tests.sh
```

## Generated artifacts

By default, test artifacts are written under `.github/actions-tests/build/python-action-test-results/`:

- `junit.xml`
- `coverage.xml`
- `htmlcov/`

## Optional coverage threshold

To fail the test run if total coverage drops below a minimum percentage:

```bash
PYTHON_ACTION_TEST_COVERAGE_FAIL_UNDER=90 ./.github/actions-tests/run_tests.sh
```
