import importlib.util
import sys
from pathlib import Path

import pytest


def determine_repo_root() -> Path:
    current_path = Path(__file__).resolve()
    for candidate in current_path.parents:
        if (candidate / ".git").exists():
            return candidate

    raise RuntimeError("Unable to determine repository root for Python action tests")


REPO_ROOT = determine_repo_root()


@pytest.fixture(scope="session")
def repo_root() -> Path:
    return REPO_ROOT


@pytest.fixture(scope="session")
def python_executable() -> str:
    return sys.executable


def load_module(module_name: str, relative_path: str):
    module_path = REPO_ROOT / relative_path
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module: {module_path}")

    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture(scope="session")
def pick_simulator_module():
    return load_module(
        "test_pick_simulator_module",
        ".github/actions/simctl-tricorder-selector/pick_simulator.py",
    )


@pytest.fixture(scope="session")
def run_xcode_tests_module():
    return load_module(
        "test_run_xcode_tests_module",
        ".github/actions/xcode-tricorder-tester/run_xcode_tests.py",
    )


@pytest.fixture(scope="session")
def coverage_summary_module():
    return load_module(
        "test_generate_coverage_summary_module",
        ".github/actions/xccov-warp-bubble/generate_coverage_summary.py",
    )


@pytest.fixture()
def sample_devices_payload():
    return {
        "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [
                {"name": "iPhone 16", "udid": "IPHONE16", "isAvailable": True},
                {"name": "iPhone 16 Pro Max", "udid": "IPHONE16PM", "isAvailable": True},
                {"name": "iPad Pro 13-inch (M4)", "udid": "IPADPRO", "isAvailable": True},
                {"name": "iPhone 14", "udid": "IPHONE14", "isAvailable": False},
            ],
            "com.apple.CoreSimulator.SimRuntime.iOS-17-5": [
                {"name": "iPhone SE (3rd generation)", "udid": "IPHONESE", "isAvailable": True},
            ],
            "com.apple.CoreSimulator.SimRuntime.macOS-15-0": [
                {"name": "My Mac", "udid": "MYMAC", "isAvailable": True},
            ],
            "com.apple.CoreSimulator.SimRuntime.watchOS-11-0": [
                {"name": "Apple Watch Series 10 (42mm)", "udid": "WATCH10", "isAvailable": True},
            ],
            "com.apple.CoreSimulator.SimRuntime.visionOS-2-0": [
                {"name": "Apple Vision Pro", "udid": "VISIONPRO", "isAvailable": True},
            ],
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-0": [
                {"name": "Apple TV", "udid": "TV", "isAvailable": True},
            ],
        }
    }
