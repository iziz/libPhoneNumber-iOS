import argparse
import json
import os
import subprocess
import textwrap

import pytest


def build_script_args(tmp_path, **overrides):
    values = {
        "scheme": "libPhoneNumber",
        "xcodeContainer": "libPhoneNumber.xcodeproj",
        "destinationIds": "SIM-001\nSIM-002\n",
        "simulatorJsons": json.dumps([
            {"name": "iPhone 16", "os": "18.0", "safe_name": "iPhone-16-18.0"},
            {"name": "iPhone 16 Pro Max", "os": "18.0", "safe_name": "iPhone-16-Pro-Max-18.0"},
        ]),
        "resultBundleDirectory": str(tmp_path / "TestResults"),
        "destinationArch": "arm64",
        "enableCodeCoverage": "YES",
        "codeSigningAllowed": "NO",
        "xcodebuildExtraArgs": "--test-iterations 2",
    }
    values.update(overrides)
    return argparse.Namespace(**values)


def test_setup_argument_parser_parses_valid_values(run_xcode_tests_module):
    parser = run_xcode_tests_module.setupArgumentParser()
    script_args = parser.parse_args([
        "--scheme", "libPhoneNumber",
        "--xcode-container", "libPhoneNumber.xcodeproj",
        "--destination-ids", "SIM-001",
        "--simulator-jsons", '[{"name":"iPhone 16","os":"18.0","safe_name":"iphone-16"}]',
        "--destination-arch", "arm64",
        "--enable-code-coverage", "YES",
        "--code-signing-allowed", "NO",
    ])

    assert script_args.scheme == "libPhoneNumber"
    assert script_args.enableCodeCoverage == "YES"
    assert script_args.codeSigningAllowed == "NO"


def test_argument_parsing_helpers(run_xcode_tests_module):
    assert run_xcode_tests_module.parseNonEmptyArgument(" libPhoneNumber ") == "libPhoneNumber"
    assert run_xcode_tests_module.parseYesNoArgument("yes") == "YES"
    assert run_xcode_tests_module.parseDestinationIds("A\nB\n\n") == ["A", "B"]

    with pytest.raises(ValueError):
        run_xcode_tests_module.parseNonEmptyArgument("   ")

    with pytest.raises(ValueError):
        run_xcode_tests_module.parseYesNoArgument("maybe")


def test_determine_xcode_container_type(run_xcode_tests_module):
    assert run_xcode_tests_module.determineXcodeContainerType("App.xcodeproj") == "project"
    assert run_xcode_tests_module.determineXcodeContainerType("App.xcworkspace") == "workspace"

    with pytest.raises(ValueError):
        run_xcode_tests_module.determineXcodeContainerType("App.swift")


def test_parse_simulator_jsons_validation(run_xcode_tests_module):
    simulators = run_xcode_tests_module.parseSimulatorJsons(
        '[{"name":"iPhone 16","os":"18.0","safe_name":"iphone-16"}]'
    )
    assert simulators == [{"name": "iPhone 16", "os": "18.0", "safe_name": "iphone-16"}]

    with pytest.raises(ValueError):
        run_xcode_tests_module.parseSimulatorJsons('{"name":"iPhone 16"}')

    with pytest.raises(ValueError):
        run_xcode_tests_module.parseSimulatorJsons('[{"name":"iPhone 16","os":"18.0"}]')


def test_validate_script_arguments(run_xcode_tests_module, tmp_path):
    script_args = build_script_args(tmp_path)
    destination_ids, simulators = run_xcode_tests_module.validateScriptArguments(script_args)

    assert destination_ids == ["SIM-001", "SIM-002"]
    assert len(simulators) == 2

    with pytest.raises(ValueError):
        run_xcode_tests_module.validateScriptArguments(
            build_script_args(tmp_path, destinationIds="SIM-001")
        )


def test_write_github_outputs(run_xcode_tests_module, tmp_path, monkeypatch):
    output_file = tmp_path / "github-output.txt"
    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))

    run_xcode_tests_module.writeGithubOutput("result_bundle_directory", "TestResults")
    run_xcode_tests_module.writeGithubMultilineOutput("result_bundle_paths", ["A.xcresult", "B.xcresult"])

    contents = output_file.read_text(encoding="utf-8")
    assert "result_bundle_directory=TestResults" in contents
    assert "result_bundle_paths<<__XCODE_TEST_THE_TRICORDERS__" in contents
    assert "A.xcresult" in contents
    assert "B.xcresult" in contents


def test_run_tests_executes_xcodebuild_for_each_destination(run_xcode_tests_module, tmp_path, monkeypatch):
    script_args = build_script_args(tmp_path)
    destination_ids = ["SIM-001", "SIM-002"]
    simulators = run_xcode_tests_module.parseSimulatorJsons(script_args.simulatorJsons)
    recorded_commands = []

    def fake_check_call(command):
        recorded_commands.append(command)

    monkeypatch.setattr(run_xcode_tests_module.subprocess, "check_call", fake_check_call)

    result_bundle_directory, result_bundle_paths = run_xcode_tests_module.runTests(
        scriptArgs=script_args,
        destinationIds=destination_ids,
        simulators=simulators,
    )

    assert result_bundle_directory == script_args.resultBundleDirectory
    assert result_bundle_paths == [
        str(tmp_path / "TestResults" / "libPhoneNumber-iPhone-16-18.0.xcresult"),
        str(tmp_path / "TestResults" / "libPhoneNumber-iPhone-16-Pro-Max-18.0.xcresult"),
    ]
    assert len(recorded_commands) == 2
    assert recorded_commands[0][:4] == ["xcodebuild", "-project", "libPhoneNumber.xcodeproj", "-scheme"]
    assert "--test-iterations" in recorded_commands[0]
    assert "2" in recorded_commands[0]
    assert "CODE_SIGNING_ALLOWED=NO" in recorded_commands[0]
    assert recorded_commands[0][-1] == "test"


def test_main_runs_end_to_end(run_xcode_tests_module, tmp_path, monkeypatch):
    script_args = build_script_args(tmp_path)
    output_file = tmp_path / "github-output.txt"
    recorded_commands = []

    class FakeParser:
        def parse_args(self):
            return script_args

    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))
    monkeypatch.setattr(run_xcode_tests_module, "setupArgumentParser", lambda: FakeParser())
    monkeypatch.setattr(run_xcode_tests_module.subprocess, "check_call", lambda command: recorded_commands.append(command))

    run_xcode_tests_module.main()

    contents = output_file.read_text(encoding="utf-8")
    assert "result_bundle_directory=" in contents
    assert "result_bundle_paths<<__XCODE_TEST_THE_TRICORDERS__" in contents
    assert len(recorded_commands) == 2


def test_run_xcode_tests_script_runs_as_black_box(repo_root, python_executable, tmp_path):
    script_path = repo_root / ".github/actions/xcode-test-the-tricorders/run_xcode_tests.py"
    output_file = tmp_path / "github-output.txt"
    fake_bin_dir = tmp_path / "bin"
    fake_bin_dir.mkdir()
    fake_xcodebuild_path = fake_bin_dir / "xcodebuild"
    fake_xcodebuild_path.write_text(
        textwrap.dedent(
            """\
            #!/usr/bin/env python3
            import json
            import os
            import sys
            from pathlib import Path

            args = sys.argv[1:]
            with open(os.environ["XCODEBUILD_LOG_FILE"], "a", encoding="utf-8") as handle:
                handle.write(json.dumps(args) + "\\n")

            if "-resultBundlePath" in args:
                result_bundle_path = args[args.index("-resultBundlePath") + 1]
                Path(result_bundle_path).mkdir(parents=True, exist_ok=True)

            raise SystemExit(0)
            """
        ),
        encoding="utf-8",
    )
    fake_xcodebuild_path.chmod(0o755)

    result_bundle_directory = tmp_path / "TestResults"
    command = [
        python_executable,
        str(script_path),
        "--scheme", "libPhoneNumber",
        "--xcode-container", "libPhoneNumber.xcodeproj",
        "--destination-ids", "SIM-001\nSIM-002",
        "--simulator-jsons", json.dumps([
            {"name": "iPhone 16", "os": "18.0", "safe_name": "iPhone-16-18.0"},
            {"name": "iPhone 16 Pro Max", "os": "18.0", "safe_name": "iPhone-16-Pro-Max-18.0"},
        ]),
        "--result-bundle-directory", str(result_bundle_directory),
        "--destination-arch", "arm64",
        "--enable-code-coverage", "YES",
        "--code-signing-allowed", "NO",
        "--xcodebuild-extra-args", "--test-iterations 2",
    ]
    environment = os.environ.copy()
    environment["GITHUB_OUTPUT"] = str(output_file)
    environment["XCODEBUILD_LOG_FILE"] = str(tmp_path / "xcodebuild.log")
    environment["PATH"] = str(fake_bin_dir) + os.pathsep + environment["PATH"]

    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        env=environment,
    )

    output_contents = output_file.read_text(encoding="utf-8")
    assert f"result_bundle_directory={result_bundle_directory}" in output_contents
    assert "result_bundle_paths<<__XCODE_TEST_THE_TRICORDERS__" in output_contents
    assert "libPhoneNumber-iPhone-16-18.0.xcresult" in output_contents
    assert "libPhoneNumber-iPhone-16-Pro-Max-18.0.xcresult" in output_contents

    logged_commands = [
        json.loads(line)
        for line in (tmp_path / "xcodebuild.log").read_text(encoding="utf-8").splitlines()
    ]
    assert len(logged_commands) == 2
    assert logged_commands[0][:4] == ["-project", "libPhoneNumber.xcodeproj", "-scheme", "libPhoneNumber"]
    assert "--test-iterations" in logged_commands[0]
    assert "2" in logged_commands[0]
    assert any(
        path.name == "libPhoneNumber-iPhone-16-18.0.xcresult"
        for path in result_bundle_directory.iterdir()
    )
    assert any(
        path.name == "libPhoneNumber-iPhone-16-Pro-Max-18.0.xcresult"
        for path in result_bundle_directory.iterdir()
    )
    assert "Running libPhoneNumber on iPhone 16 (18.0)" in result.stderr
