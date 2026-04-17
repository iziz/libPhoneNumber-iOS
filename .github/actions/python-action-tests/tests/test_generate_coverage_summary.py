import argparse
import json
import os
import subprocess
import textwrap

import pytest


def build_script_args(tmp_path, **overrides):
    values = {
        "xcresultsDirectory": str(tmp_path / "CoverageResults" / "xcresults"),
        "summaryFile": str(tmp_path / "CoverageResults" / "summary.md"),
        "summaryJsonFile": str(tmp_path / "CoverageResults" / "summary.json"),
        "failingCoverageThreshold": 60.0,
        "passingCoverageThreshold": 75.0,
    }
    values.update(overrides)
    return argparse.Namespace(**values)


def test_setup_argument_parser_parses_valid_values(coverage_summary_module):
    parser = coverage_summary_module.setupArgumentParser()
    script_args = parser.parse_args([
        "--xcresults-directory", "CoverageResults/xcresults",
        "--summary-file", "CoverageResults/summary.md",
        "--summary-json-file", "CoverageResults/summary.json",
        "--failing-coverage-threshold", "60",
        "--passing-coverage-threshold", "75",
    ])

    assert script_args.xcresultsDirectory == "CoverageResults/xcresults"
    assert script_args.failingCoverageThreshold == 60.0
    assert script_args.passingCoverageThreshold == 75.0


def test_argument_parsing_helpers(coverage_summary_module):
    assert coverage_summary_module.parseNonEmptyArgument(" summary.md ") == "summary.md"
    assert coverage_summary_module.parseThreshold("75", "passing coverage threshold") == 75.0
    assert coverage_summary_module.parseCoverageThresholdArgument("60") == 60.0

    with pytest.raises(ValueError):
        coverage_summary_module.parseNonEmptyArgument("   ")

    with pytest.raises(ValueError):
        coverage_summary_module.parseThreshold("abc", "coverage threshold")

    with pytest.raises(ValueError):
        coverage_summary_module.parseThreshold("120", "coverage threshold")


def test_validate_script_arguments_rejects_invalid_threshold_order(coverage_summary_module, tmp_path):
    script_args = build_script_args(tmp_path, failingCoverageThreshold=80.0, passingCoverageThreshold=75.0)

    with pytest.raises(ValueError):
        coverage_summary_module.validateScriptArguments(script_args)


def test_normalize_scope_name_and_find_result_bundles(coverage_summary_module, tmp_path):
    assert coverage_summary_module.normalizeScopeName("project-unit-tests-libPhoneNumber") == "libPhoneNumber"
    assert coverage_summary_module.normalizeScopeName("libPhoneNumber.xcresult") == "libPhoneNumber"

    root = tmp_path / "xcresults"
    nested_bundle = root / "project-unit-tests-libPhoneNumber" / "libPhoneNumber-iPhone-16.xcresult"
    nested_bundle.mkdir(parents=True)

    bundles = coverage_summary_module.findResultBundles(str(root))
    assert bundles == [str(nested_bundle)]


def test_discover_coverage_scopes_prefers_scope_directories(coverage_summary_module, tmp_path, capsys):
    root = tmp_path / "xcresults"
    (root / "project-unit-tests-libPhoneNumber" / "libPhoneNumber-iPhone-16.xcresult").mkdir(parents=True)
    (root / "project-unit-tests-libPhoneNumberGeocoding" / "libPhoneNumberGeocoding-iPhone-16.xcresult").mkdir(parents=True)
    (root / "empty-scope").mkdir(parents=True)

    scopes = coverage_summary_module.discoverCoverageScopes(str(root))
    assert sorted(scopes.keys()) == ["libPhoneNumber", "libPhoneNumberGeocoding"]

    error_output = capsys.readouterr().err
    assert "empty-scope: no downloaded .xcresult bundles found" in error_output


def test_discover_coverage_scopes_falls_back_to_root_bundles(coverage_summary_module, tmp_path):
    root = tmp_path / "xcresults"
    bundle = root / "libPhoneNumber-iPhone-16.xcresult"
    bundle.mkdir(parents=True)

    scopes = coverage_summary_module.discoverCoverageScopes(str(root))
    assert scopes == {"xcresults": [str(bundle)]}


def test_merge_coverage_report_and_scope_calculation(coverage_summary_module, tmp_path, monkeypatch):
    scope_a_bundle = tmp_path / "scope-a.xcresult"
    scope_b_bundle = tmp_path / "scope-b.xcresult"
    scope_a_bundle.mkdir()
    scope_b_bundle.mkdir()

    reports = {
        str(scope_a_bundle): {
            "/tmp/FileA.swift": [
                {"line": 1, "isExecutable": True, "executionCount": 1},
                {"line": 2, "isExecutable": True, "executionCount": 0},
                {"line": 3, "isExecutable": False, "executionCount": 0},
            ],
        },
        str(scope_b_bundle): {
            "/tmp/FileA.swift": [
                {"line": 2, "isExecutable": True, "executionCount": 1},
            ],
            "/tmp/FileB.swift": [
                {"line": 10, "isExecutable": True, "executionCount": 1},
            ],
        },
    }

    def fake_check_output(command, text):
        assert text is True
        bundle_path = command[-1]
        return json.dumps(reports[bundle_path])

    monkeypatch.setattr(coverage_summary_module.subprocess, "check_output", fake_check_output)

    merged = {}
    coverage_summary_module.mergeCoverageReport(merged, str(scope_a_bundle))
    assert merged["/tmp/FileA.swift"] == {1: True, 2: False}

    scope_coverages, overall_coverage = coverage_summary_module.calculateScopeCoverages(
        {
            "ScopeA": [str(scope_a_bundle)],
            "ScopeB": [str(scope_b_bundle)],
        }
    )

    assert [(scope.name, round(scope.coveragePercent, 2)) for scope in scope_coverages] == [
        ("ScopeA", 50.0),
        ("ScopeB", 100.0),
    ]
    assert overall_coverage is not None
    assert overall_coverage.name == "Combined"
    assert round(overall_coverage.coveragePercent, 2) == 100.0


def test_rendering_and_serialization_helpers(coverage_summary_module, capsys):
    thresholds = coverage_summary_module.CoverageThresholds(failing=60.0, passing=75.0)
    scope_a = coverage_summary_module.ScopeCoverage(
        name="ScopeA",
        coveredLines=3,
        executableLines=5,
        coveragePercent=60.0,
    )
    scope_b = coverage_summary_module.ScopeCoverage(
        name="ScopeB",
        coveredLines=5,
        executableLines=5,
        coveragePercent=100.0,
    )
    combined = coverage_summary_module.ScopeCoverage(
        name="Combined",
        coveredLines=8,
        executableLines=10,
        coveragePercent=80.0,
    )

    assert coverage_summary_module.determineCoverageStatus(50.0, thresholds) == "fail"
    assert coverage_summary_module.determineCoverageStatus(65.0, thresholds) == "warn"
    assert coverage_summary_module.determineCoverageStatus(80.0, thresholds) == "pass"
    assert coverage_summary_module.determineStatusEmoji("pass") == "✅"
    assert coverage_summary_module.serializeScope(scope_a, thresholds)["status"] == "warn"
    assert coverage_summary_module.determineOverallCoveragePercent([scope_a], None) == "60.00"
    assert coverage_summary_module.determineOverallCoveragePercent([scope_a, scope_b], combined) == "80.00"

    coverage_summary_module.printCoverageSummary([scope_a, scope_b], combined, thresholds)
    output = capsys.readouterr().out
    assert "ScopeA - 60.00% ⚠️" in output
    assert "Combined - 80.00% ✅" in output

    markdown = coverage_summary_module.renderMarkdownSummary([scope_a, scope_b], combined, thresholds)
    assert "| ScopeA | 60.00% | ⚠️ |" in markdown
    assert "**Combined**" in markdown

    json_payload = coverage_summary_module.renderJsonSummary([scope_a, scope_b], combined, thresholds)
    assert json_payload["scope_count"] == 2
    assert json_payload["combined"]["status"] == "pass"


def test_file_output_helpers(coverage_summary_module, tmp_path, monkeypatch):
    thresholds = coverage_summary_module.CoverageThresholds(failing=60.0, passing=75.0)
    summary_file = tmp_path / "results" / "summary.md"
    summary_json_file = tmp_path / "results" / "summary.json"
    output_file = tmp_path / "github-output.txt"

    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))

    coverage_summary_module.writeTextFile(str(summary_file), "hello\n")
    coverage_summary_module.writeJsonFile(str(summary_json_file), {"ok": True})
    coverage_summary_module.publishOutputs(str(summary_file), str(summary_json_file), "88.00", 2)

    assert summary_file.read_text(encoding="utf-8") == "hello\n"
    assert json.loads(summary_json_file.read_text(encoding="utf-8")) == {"ok": True}

    output_contents = output_file.read_text(encoding="utf-8")
    assert f"summary_file={summary_file}" in output_contents
    assert "coverage_percent=88.00" in output_contents
    assert "scope_count=2" in output_contents

    coverage_summary_module.writeUnavailableSummaries(
        str(summary_file),
        str(summary_json_file),
        "No coverage available.",
        thresholds,
    )
    assert "No coverage available." in summary_file.read_text(encoding="utf-8")
    assert json.loads(summary_json_file.read_text(encoding="utf-8"))["scope_count"] == 0


def test_main_writes_unavailable_summaries(coverage_summary_module, tmp_path, monkeypatch):
    script_args = build_script_args(tmp_path)
    output_file = tmp_path / "github-output.txt"

    class FakeParser:
        def parse_args(self):
            return script_args

    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))
    monkeypatch.setattr(coverage_summary_module, "setupArgumentParser", lambda: FakeParser())

    coverage_summary_module.main()

    summary_contents = (tmp_path / "CoverageResults" / "summary.md").read_text(encoding="utf-8")
    json_payload = json.loads((tmp_path / "CoverageResults" / "summary.json").read_text(encoding="utf-8"))
    output_contents = output_file.read_text(encoding="utf-8")

    assert "Code coverage unavailable because no unit test result bundles were downloaded." in summary_contents
    assert json_payload["scope_count"] == 0
    assert "coverage_percent=" in output_contents


def test_main_writes_summary_for_downloaded_results(coverage_summary_module, tmp_path, monkeypatch):
    xcresults_root = tmp_path / "CoverageResults" / "xcresults"
    bundle = xcresults_root / "project-unit-tests-libPhoneNumber" / "libPhoneNumber-iPhone-16.xcresult"
    bundle.mkdir(parents=True)

    script_args = build_script_args(tmp_path)
    output_file = tmp_path / "github-output.txt"

    class FakeParser:
        def parse_args(self):
            return script_args

    def fake_check_output(command, text):
        assert command[-1] == str(bundle)
        return json.dumps(
            {
                "/tmp/FileA.swift": [
                    {"line": 1, "isExecutable": True, "executionCount": 1},
                    {"line": 2, "isExecutable": True, "executionCount": 0},
                ],
            }
        )

    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))
    monkeypatch.setattr(coverage_summary_module, "setupArgumentParser", lambda: FakeParser())
    monkeypatch.setattr(coverage_summary_module.subprocess, "check_output", fake_check_output)

    coverage_summary_module.main()

    summary_contents = (tmp_path / "CoverageResults" / "summary.md").read_text(encoding="utf-8")
    json_payload = json.loads((tmp_path / "CoverageResults" / "summary.json").read_text(encoding="utf-8"))
    output_contents = output_file.read_text(encoding="utf-8")

    assert "| libPhoneNumber | 50.00% | ❌ |" in summary_contents
    assert json_payload["overall_coverage_percent"] == 50.0
    assert "coverage_percent=50.00" in output_contents


def test_generate_coverage_summary_script_runs_as_black_box(repo_root, python_executable, tmp_path):
    script_path = repo_root / ".github/actions/xccov-warp-bubble/generate_coverage_summary.py"
    output_file = tmp_path / "github-output.txt"
    fake_bin_dir = tmp_path / "bin"
    fake_bin_dir.mkdir()
    fake_xcrun_path = fake_bin_dir / "xcrun"
    report_mapping = {
        "libPhoneNumber-iPhone-16.xcresult": {
            "/tmp/FileA.swift": [
                {"line": 1, "isExecutable": True, "executionCount": 1},
                {"line": 2, "isExecutable": True, "executionCount": 0},
            ]
        },
        "libPhoneNumberGeocoding-iPhone-16.xcresult": {
            "/tmp/FileA.swift": [
                {"line": 2, "isExecutable": True, "executionCount": 1},
            ],
            "/tmp/FileB.swift": [
                {"line": 10, "isExecutable": True, "executionCount": 1},
            ],
        },
    }
    mapping_file = tmp_path / "xccov-reports.json"
    mapping_file.write_text(json.dumps(report_mapping), encoding="utf-8")

    fake_xcrun_path.write_text(
        textwrap.dedent(
            """\
            #!/usr/bin/env python3
            import json
            import os
            import sys
            from pathlib import Path

            args = sys.argv[1:]
            with open(os.environ["XCRUN_LOG_FILE"], "a", encoding="utf-8") as handle:
                handle.write(" ".join(args) + "\\n")

            if args[:3] != ["xccov", "view", "--archive"] or args[3] != "--json":
                raise SystemExit(f"Unexpected xcrun arguments: {args}")

            report_key = Path(args[4]).name
            with open(os.environ["XCCOV_REPORTS_FILE"], "r", encoding="utf-8") as handle:
                reports = json.load(handle)

            sys.stdout.write(json.dumps(reports[report_key]))
            raise SystemExit(0)
            """
        ),
        encoding="utf-8",
    )
    fake_xcrun_path.chmod(0o755)

    xcresults_root = tmp_path / "CoverageResults" / "xcresults"
    (xcresults_root / "project-unit-tests-libPhoneNumber" / "libPhoneNumber-iPhone-16.xcresult").mkdir(parents=True)
    (xcresults_root / "project-unit-tests-libPhoneNumberGeocoding" / "libPhoneNumberGeocoding-iPhone-16.xcresult").mkdir(parents=True)
    summary_file = tmp_path / "CoverageResults" / "summary.md"
    summary_json_file = tmp_path / "CoverageResults" / "summary.json"

    command = [
        python_executable,
        str(script_path),
        "--xcresults-directory", str(xcresults_root),
        "--summary-file", str(summary_file),
        "--summary-json-file", str(summary_json_file),
        "--failing-coverage-threshold", "60",
        "--passing-coverage-threshold", "75",
    ]
    environment = os.environ.copy()
    environment["GITHUB_OUTPUT"] = str(output_file)
    environment["XCCOV_REPORTS_FILE"] = str(mapping_file)
    environment["XCRUN_LOG_FILE"] = str(tmp_path / "xcrun.log")
    environment["PATH"] = str(fake_bin_dir) + os.pathsep + environment["PATH"]

    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        env=environment,
    )

    summary_contents = summary_file.read_text(encoding="utf-8")
    summary_json = json.loads(summary_json_file.read_text(encoding="utf-8"))
    output_contents = output_file.read_text(encoding="utf-8")
    xcrun_log_lines = (tmp_path / "xcrun.log").read_text(encoding="utf-8").splitlines()

    assert "| libPhoneNumber | 50.00% | ❌ |" in summary_contents
    assert "| libPhoneNumberGeocoding | 100.00% | ✅ |" in summary_contents
    assert "**Combined**" in summary_contents
    assert summary_json["combined"]["coverage_percent"] == 100.0
    assert "coverage_percent=100.00" in output_contents
    assert "scope_count=2" in output_contents
    assert "Processing result bundle for libPhoneNumber:" in result.stdout
    assert "Combined - 100.00% ✅" in result.stdout
    assert len(xcrun_log_lines) == 4
    assert sum("libPhoneNumber-iPhone-16.xcresult" in line for line in xcrun_log_lines) == 2
    assert sum("libPhoneNumberGeocoding-iPhone-16.xcresult" in line for line in xcrun_log_lines) == 2
