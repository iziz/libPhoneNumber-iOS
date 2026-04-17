import argparse
import json
import os
import subprocess
import textwrap

import pytest


def make_candidate(module, *, device_type: str, name: str, udid: str, runtime: str, family: str, version: tuple[int, ...]):
    return module.Candidate(
        deviceType=device_type,
        name=name,
        udid=udid,
        runtimeIdentifier=runtime,
        runtimeFamily=family,
        osVersion=version,
    )


def test_setup_argument_parser_parses_valid_values(pick_simulator_module):
    parser = pick_simulator_module.setupArgumentParser()
    script_args = parser.parse_args([
        "--device-types", "iphone,ipad",
        "--selection-mode", "latest-model",
        "--iphoneos-version", "18.0",
    ])

    assert script_args.deviceTypes == "iphone,ipad"
    assert script_args.selectionMode == "latest-model"
    assert script_args.iphoneosVersion == "18.0"


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("iphone, ipad", ["iphone", "ipad"]),
        (" iphone ", ["iphone"]),
        ("iphone,,watch", ["iphone", "watch"]),
    ],
)
def test_parse_comma_separated_list(pick_simulator_module, value, expected):
    assert pick_simulator_module.parseCommaSeparatedList(value) == expected


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("latest", None),
        ("18", (18,)),
        ("18.2", (18, 2)),
    ],
)
def test_parse_requested_version_valid_values(pick_simulator_module, value, expected):
    assert pick_simulator_module.parseRequestedVersion(value) == expected


def test_parse_requested_version_invalid_value_raises(pick_simulator_module):
    with pytest.raises(ValueError):
        pick_simulator_module.parseRequestedVersion("18.x")


def test_parse_model_preferences_parses_expected_values(pick_simulator_module):
    preferences = pick_simulator_module.parseModelPreferences("iphone=Pro Max,Plus;ipad=Pro")
    assert preferences == {"iphone": ["pro max", "plus"], "ipad": ["pro"]}


def test_parse_model_preferences_rejects_invalid_segment(pick_simulator_module):
    with pytest.raises(ValueError):
        pick_simulator_module.parseModelPreferences("iphone")


def test_read_devices_json_reads_from_file(pick_simulator_module, tmp_path, sample_devices_payload):
    json_file = tmp_path / "devices.json"
    json_file.write_text(json.dumps(sample_devices_payload), encoding="utf-8")

    loaded_payload = pick_simulator_module.readDevicesJson(str(json_file))
    assert loaded_payload == sample_devices_payload


def test_parse_runtime_identifier_and_classification_helpers(pick_simulator_module):
    assert pick_simulator_module.parseRuntimeIdentifier(
        "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
    ) == ("iOS", (18, 2))
    assert pick_simulator_module.parseRuntimeIdentifier("com.apple.CoreSimulator.SimRuntime.tvOS-18-0") is None
    assert pick_simulator_module.classifyDeviceType("iPhone 16 Pro") == "iphone"
    assert pick_simulator_module.classifyDeviceType("iPad Air 13-inch") == "ipad"
    assert pick_simulator_module.classifyDeviceType("Apple Watch Ultra 2") == "watch"
    assert pick_simulator_module.classifyDeviceType("Apple Vision Pro") == "vision"
    assert pick_simulator_module.classifyDeviceType("My Mac") == "macos"
    assert pick_simulator_module.versionToString((18, 2, 1)) == "18.2.1"


def test_variant_and_model_helpers(pick_simulator_module):
    pro_max = make_candidate(
        pick_simulator_module,
        device_type="iphone",
        name="iPhone 16 Pro Max",
        udid="A",
        runtime="com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        family="iOS",
        version=(18, 0),
    )
    base = make_candidate(
        pick_simulator_module,
        device_type="iphone",
        name="iPhone 16",
        udid="B",
        runtime="com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        family="iOS",
        version=(18, 0),
    )

    assert pick_simulator_module.determineVariantDetails(pro_max.name) == ("pro max", 70)
    assert pick_simulator_module.determineModelType(pro_max.name) == "Pro Max"
    assert pick_simulator_module.determineModelType(base.name) == ""
    assert pick_simulator_module.createSafeName("iPhone 16 Pro Max", "18.0") == "iPhone-16-Pro-Max-18.0"
    assert pick_simulator_module.filterToLatestModel([base, pro_max]) == [pro_max]


def test_filter_to_model_preferences(pick_simulator_module):
    pro = make_candidate(
        pick_simulator_module,
        device_type="iphone",
        name="iPhone 16 Pro",
        udid="PRO",
        runtime="com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        family="iOS",
        version=(18, 0),
    )
    plus = make_candidate(
        pick_simulator_module,
        device_type="iphone",
        name="iPhone 16 Plus",
        udid="PLUS",
        runtime="com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        family="iOS",
        version=(18, 0),
    )

    filtered = pick_simulator_module.filterToModelPreferences(
        [pro, plus],
        {"iphone": ["plus"]},
    )
    assert filtered == [plus]


def test_enumerate_candidates_groups_by_device_type(pick_simulator_module, sample_devices_payload, capsys):
    candidates_by_type = pick_simulator_module.enumerateCandidates(
        sample_devices_payload,
        ["iphone", "ipad", "macos", "watch", "vision"],
    )

    assert [candidate.name for candidate in candidates_by_type["iphone"]] == [
        "iPhone 16",
        "iPhone 16 Pro Max",
        "iPhone SE (3rd generation)",
    ]
    assert [candidate.name for candidate in candidates_by_type["ipad"]] == ["iPad Pro 13-inch (M4)"]
    assert [candidate.name for candidate in candidates_by_type["macos"]] == ["My Mac"]
    assert [candidate.name for candidate in candidates_by_type["watch"]] == ["Apple Watch Series 10 (42mm)"]
    assert [candidate.name for candidate in candidates_by_type["vision"]] == ["Apple Vision Pro"]

    error_output = capsys.readouterr().err
    assert "Runtime: com.apple.CoreSimulator.SimRuntime.iOS-18-0" in error_output
    assert "Apple TV" not in error_output


def test_enumerate_candidates_rejects_invalid_devices_map(pick_simulator_module):
    with pytest.raises(ValueError):
        pick_simulator_module.enumerateCandidates({"devices": []}, ["iphone"])


def test_filter_candidates_for_requested_os_and_candidate_pool(pick_simulator_module, sample_devices_payload, capsys):
    candidates = pick_simulator_module.enumerateCandidates(sample_devices_payload, ["iphone"])["iphone"]

    latest_candidates = pick_simulator_module.filterCandidatesForRequestedOs(
        candidates,
        None,
        "iphone",
    )
    assert [candidate.name for candidate in latest_candidates] == ["iPhone 16", "iPhone 16 Pro Max"]

    specific_candidates = pick_simulator_module.filterCandidatesForRequestedOs(
        candidates,
        (17, 5),
        "iphone",
    )
    assert [candidate.name for candidate in specific_candidates] == ["iPhone SE (3rd generation)"]

    pool = pick_simulator_module.buildCandidatePool(
        deviceType="iphone",
        candidates=candidates,
        requestedVersion=None,
        selectionMode="latest-model",
        modelPreferences={},
    )
    assert [candidate.name for candidate in pool] == ["iPhone 16 Pro Max"]

    error_output = capsys.readouterr().err
    assert "iphone: using latest OS 18.0" in error_output
    assert "iphone: requested OS 17.5" in error_output


def test_select_destination_from_pool_and_requested_versions(pick_simulator_module, monkeypatch):
    first = make_candidate(
        pick_simulator_module,
        device_type="iphone",
        name="iPhone 16",
        udid="FIRST",
        runtime="com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        family="iOS",
        version=(18, 0),
    )
    second = make_candidate(
        pick_simulator_module,
        device_type="iphone",
        name="iPhone 16 Pro Max",
        udid="SECOND",
        runtime="com.apple.CoreSimulator.SimRuntime.iOS-18-0",
        family="iOS",
        version=(18, 0),
    )

    monkeypatch.setattr(pick_simulator_module.random, "choice", lambda values: values[0])
    assert pick_simulator_module.selectDestinationFromPool([first, second], "random-compatible") == first
    assert pick_simulator_module.selectDestinationFromPool([first, second], "latest-model") == second
    assert pick_simulator_module.selectDestinationFromPool([], "latest-model") is None

    script_args = argparse.Namespace(
        iphoneosVersion="18.0",
        ipadosVersion="latest",
        macosVersion="15.0",
        watchosVersion="latest",
        visionosVersion="2.0",
    )
    assert pick_simulator_module.determineRequestedVersions(script_args) == {
        "iphone": (18, 0),
        "ipad": None,
        "macos": (15, 0),
        "watch": None,
        "vision": (2, 0),
    }


def test_validate_script_arguments_and_selection_failures(pick_simulator_module):
    valid_args = argparse.Namespace(deviceTypes="iphone,watch", selectionMode="latest-model")
    assert pick_simulator_module.validateScriptArguments(valid_args) == ["iphone", "watch"]

    with pytest.raises(ValueError):
        pick_simulator_module.validateScriptArguments(
            argparse.Namespace(deviceTypes="iphone,tvos", selectionMode="latest-model")
        )

    with pytest.raises(SystemExit):
        pick_simulator_module.determineSelectedDestinations(
            requestedDeviceTypes=["iphone"],
            candidatesByType={"iphone": []},
            requestedVersions={"iphone": None},
            selectionMode="latest-model",
            modelPreferences={},
        )


def test_determine_selected_destinations_success_and_publish_outputs(
    pick_simulator_module,
    tmp_path,
    sample_devices_payload,
    monkeypatch,
):
    candidates_by_type = pick_simulator_module.enumerateCandidates(sample_devices_payload, ["iphone", "watch"])
    monkeypatch.setattr(pick_simulator_module.random, "choice", lambda values: values[0])

    selected_candidates = pick_simulator_module.determineSelectedDestinations(
        requestedDeviceTypes=["iphone", "watch"],
        candidatesByType=candidates_by_type,
        requestedVersions={"iphone": None, "watch": None},
        selectionMode="random-compatible",
        modelPreferences={},
    )

    assert [candidate.udid for candidate in selected_candidates] == ["IPHONE16", "WATCH10"]

    output_file = tmp_path / "github-output.txt"
    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))
    pick_simulator_module.publishOutputs(selected_candidates)

    output_contents = output_file.read_text(encoding="utf-8")
    assert "simulator_jsons=" in output_contents
    assert "destination_ids<<__SIMCTL_PICK_A_TRICORDER__" in output_contents
    assert "IPHONE16" in output_contents
    assert "WATCH10" in output_contents


def test_main_runs_end_to_end(pick_simulator_module, tmp_path, sample_devices_payload, monkeypatch, capsys):
    class FakeParser:
        def parse_args(self):
            return argparse.Namespace(
                deviceTypes="iphone,watch",
                selectionMode="random-compatible",
                modelPreferences="",
                iphoneosVersion="latest",
                ipadosVersion="latest",
                macosVersion="latest",
                watchosVersion="latest",
                visionosVersion="latest",
                devicesJsonFile=None,
            )

    output_file = tmp_path / "github-output.txt"
    monkeypatch.setenv("GITHUB_OUTPUT", str(output_file))
    monkeypatch.setattr(pick_simulator_module, "setupArgumentParser", lambda: FakeParser())
    monkeypatch.setattr(pick_simulator_module, "readDevicesJson", lambda *_args, **_kwargs: sample_devices_payload)
    monkeypatch.setattr(pick_simulator_module.random, "choice", lambda values: values[0])

    pick_simulator_module.main()

    output_contents = output_file.read_text(encoding="utf-8")
    assert "simulator_jsons=" in output_contents
    assert "IPHONE16" in output_contents
    assert "WATCH10" in output_contents

    error_output = capsys.readouterr().err
    assert "Selected Simulators:" in error_output


def test_pick_simulator_script_runs_as_black_box(repo_root, python_executable, tmp_path, sample_devices_payload):
    script_path = repo_root / ".github/actions/simctl-pick-a-tricorder/pick_simulator.py"
    output_file = tmp_path / "github-output.txt"
    fake_bin_dir = tmp_path / "bin"
    fake_bin_dir.mkdir()
    fake_xcrun_path = fake_bin_dir / "xcrun"
    devices_json_path = tmp_path / "devices.json"
    devices_json_path.write_text(json.dumps(sample_devices_payload), encoding="utf-8")

    fake_xcrun_path.write_text(
        textwrap.dedent(
            """\
            #!/usr/bin/env python3
            import os
            import sys

            with open(os.environ["SIMCTL_LOG_FILE"], "a", encoding="utf-8") as handle:
                handle.write(" ".join(sys.argv[1:]) + "\\n")

            if sys.argv[1:] == ["simctl", "list", "devices", "--json"]:
                with open(os.environ["SIMCTL_DEVICES_JSON_FILE"], "r", encoding="utf-8") as handle:
                    sys.stdout.write(handle.read())
                raise SystemExit(0)

            raise SystemExit(f"Unexpected xcrun arguments: {sys.argv[1:]}")
            """
        ),
        encoding="utf-8",
    )
    fake_xcrun_path.chmod(0o755)

    command = [
        python_executable,
        str(script_path),
        "--device-types", "iphone,watch",
        "--selection-mode", "latest-model",
        "--iphoneos-version", "latest",
        "--watchos-version", "latest",
    ]
    environment = os.environ.copy()
    environment["GITHUB_OUTPUT"] = str(output_file)
    environment["SIMCTL_DEVICES_JSON_FILE"] = str(devices_json_path)
    environment["SIMCTL_LOG_FILE"] = str(tmp_path / "xcrun.log")
    environment["PATH"] = str(fake_bin_dir) + os.pathsep + environment["PATH"]

    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        env=environment,
    )

    output_contents = output_file.read_text(encoding="utf-8")
    assert "simulator_jsons=" in output_contents
    assert "destination_ids<<__SIMCTL_PICK_A_TRICORDER__" in output_contents
    assert "IPHONE16PM" in output_contents
    assert "WATCH10" in output_contents

    simulator_payload = json.loads(output_contents.split("simulator_jsons=", 1)[1].splitlines()[0])
    assert simulator_payload[0] == {
        "udid": "IPHONE16PM",
        "name": "iPhone 16 Pro Max",
        "os": "18.0",
        "modelType": "Pro Max",
        "safe_name": "iPhone-16-Pro-Max-18.0",
    }
    assert simulator_payload[1]["udid"] == "WATCH10"
    assert simulator_payload[1]["name"] == "Apple Watch Series 10 (42mm)"
    assert simulator_payload[1]["os"] == "11.0"
    assert simulator_payload[1]["safe_name"].startswith("Apple-Watch-Series-10-42mm")

    assert "Selected Simulators:" in result.stderr
    assert "iPhone 16 Pro Max" in result.stderr
    assert "Apple Watch Series 10 (42mm)" in result.stderr
    assert (tmp_path / "xcrun.log").read_text(encoding="utf-8").strip() == "simctl list devices --json"
