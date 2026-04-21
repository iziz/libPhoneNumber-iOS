#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#  run_xcode_tests.py
#  xcode-tricorder-tester
#
#  Created by Kodex on 4/17/26.
#
# This script runs xcodebuild tests against one or more simulator destinations
# selected upstream and publishes the generated xcresult bundle paths for
# downstream GitHub Actions steps.

import argparse
import json
import os
import shlex
import subprocess
import sys


SCRIPT_VERSION: str = "0.2.2"
"""The current version of the script"""


SUPPORTED_XCODE_CONTAINERS: dict[str, str] = {
    ".xcodeproj": "project",
    ".xcworkspace": "workspace",
}
"""Supported Xcode container extensions mapped to xcodebuild argument types"""


OUTPUT_MARKER: str = "__XCODE_TEST_THE_TRICORDERS__"
"""The multiline GitHub Actions output marker"""


def setupArgumentParser() -> argparse.ArgumentParser:
    """
    Sets up the argument parser

    Returns
    -------
    ArgumentParser
        The created argument parser for this script
    """

    parser: argparse.ArgumentParser = argparse.ArgumentParser(description="""
                This script runs xcodebuild tests against simulator destinations
                selected by an upstream simulator-selection step.""")

    parser.add_argument("--version", "-v", action="version",
                        version="%(prog)s " + SCRIPT_VERSION)
    parser.add_argument("-?", action="help",
                        help="show this help message and exit")
    parser.add_argument("--scheme", metavar="SchemeName", required=True,
                        help="The Xcode scheme to run tests for",
                        dest='scheme', type=parseNonEmptyArgument)
    parser.add_argument("--xcode-container", metavar="Project.xcodeproj", required=True,
                        help="The path to the Xcode project or workspace",
                        dest='xcodeContainer', type=parseNonEmptyArgument)
    parser.add_argument("--destination-ids", metavar="DESTINATION_IDS", required=True,
                        help="Newline-separated simulator destination UDIDs",
                        dest='destinationIds', type=parseNonEmptyArgument)
    parser.add_argument("--simulator-jsons", metavar="SIMULATOR_JSONS", required=True,
                        help="JSON array of simulator objects from the picker action",
                        dest='simulatorJsons', type=parseNonEmptyArgument)
    parser.add_argument("--result-bundle-directory", metavar="TestResults",
                        help="The directory where xcresult bundles should be written",
                        dest='resultBundleDirectory', default="TestResults",
                        type=parseNonEmptyArgument)
    parser.add_argument("--destination-arch", metavar="arm64", required=True,
                        help="The destination architecture to use with xcodebuild",
                        dest='destinationArch', type=parseNonEmptyArgument)
    parser.add_argument("--xcodebuild-extra-args", metavar="--test-iterations 2",
                        help="Optional extra xcodebuild arguments",
                        dest='xcodebuildExtraArgs', default="")

    return parser


def printScriptStart():
    """Prints the info for the start of the script"""

    print(f"Starting {os.path.basename(__file__)} v{SCRIPT_VERSION}", file=sys.stderr)


def parseNonEmptyArgument(value: str) -> str:
    """
    Parses and validates a non-empty string argument

    Parameters
    ----------
    value
        The raw argument value

    Returns
    -------
    str
        The normalized non-empty argument value
    """

    normalizedValue = value.strip()
    if len(normalizedValue) <= 0:
        raise ValueError("Argument value must not be empty")

    return normalizedValue


def determineXcodeContainerType(xcodeContainer: str) -> str:
    """
    Determines the Xcode container type from the specified path

    Parameters
    ----------
    xcodeContainer
        The path to the Xcode project or workspace

    Returns
    -------
    str
        The Xcode container type to pass to xcodebuild
    """

    _root, extension = os.path.splitext(xcodeContainer.strip())
    containerType = SUPPORTED_XCODE_CONTAINERS.get(extension.lower())
    if containerType is None:
        raise ValueError(
            f"Unsupported Xcode container specified: {xcodeContainer}. "
            f"Expected a path ending in {', '.join(SUPPORTED_XCODE_CONTAINERS.keys())}"
        )

    return containerType


def parseDestinationIds(value: str) -> list[str]:
    """
    Parses the destination ID input into a list of UDIDs

    Parameters
    ----------
    value
        The raw newline-separated destination ID string

    Returns
    -------
    list[str]
        The parsed destination IDs
    """

    return [part.strip() for part in value.splitlines() if len(part.strip()) > 0]


def parseSimulatorJsons(value: str) -> list[dict[str, str]]:
    """
    Parses the simulator JSON payload

    Parameters
    ----------
    value
        The raw simulator JSON string

    Returns
    -------
    list[dict[str, str]]
        The parsed simulator objects
    """

    simulators = json.loads(value)
    if not isinstance(simulators, list):
        raise ValueError("Simulator JSON payload must be a list")

    normalizedSimulators: list[dict[str, str]] = []
    for simulator in simulators:
        if not isinstance(simulator, dict):
            raise ValueError("Simulator JSON payload entries must be objects")

        safeName = str(simulator.get("safe_name") or "").strip()
        if len(safeName) <= 0:
            raise ValueError("Simulator output is missing a safe_name value")

        normalizedSimulators.append({
            "name": str(simulator.get("name") or "").strip(),
            "os": str(simulator.get("os") or "").strip(),
            "safe_name": safeName,
        })

    return normalizedSimulators


def validateScriptArguments(scriptArgs: argparse.Namespace) -> tuple[list[str], list[dict[str, str]]]:
    """
    Validates the parsed script arguments

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    tuple[list[str], list[dict[str, str]]]
        The parsed destination IDs and simulator objects
    """

    determineXcodeContainerType(scriptArgs.xcodeContainer)

    destinationIds = parseDestinationIds(scriptArgs.destinationIds)
    simulators = parseSimulatorJsons(scriptArgs.simulatorJsons)
    if len(destinationIds) != len(simulators):
        raise ValueError("Destination ID and simulator output counts do not match")

    return (destinationIds, simulators)


def writeGithubOutput(name: str, value: str):
    """
    Writes a single GitHub Actions output value

    Parameters
    ----------
    name
        The output name
    value
        The output value
    """

    outputFile = os.environ.get("GITHUB_OUTPUT")
    if outputFile is None or len(outputFile.strip()) <= 0:
        return

    with open(outputFile, "a", encoding="utf-8") as file:
        print(f"{name}={value}", file=file)


def writeGithubMultilineOutput(name: str, values: list[str]):
    """
    Writes a multiline GitHub Actions output value

    Parameters
    ----------
    name
        The output name
    values
        The list of values to write
    """

    outputFile = os.environ.get("GITHUB_OUTPUT")
    if outputFile is None or len(outputFile.strip()) <= 0:
        return

    with open(outputFile, "a", encoding="utf-8") as file:
        print(f"{name}<<{OUTPUT_MARKER}", file=file)
        for value in values:
            print(value, file=file)
        print(OUTPUT_MARKER, file=file)


def runTests(scriptArgs: argparse.Namespace,
             destinationIds: list[str],
             simulators: list[dict[str, str]]) -> tuple[str, list[str]]:
    """
    Runs xcodebuild tests for all selected simulator destinations

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    tuple[str, list[str]]
        The result bundle directory and generated xcresult bundle paths
    """

    xcodeContainerType = determineXcodeContainerType(scriptArgs.xcodeContainer)
    extraArgs = shlex.split(scriptArgs.xcodebuildExtraArgs)

    os.makedirs(scriptArgs.resultBundleDirectory, exist_ok=True)

    resultBundlePaths: list[str] = []
    for destinationId, simulator in zip(destinationIds, simulators):
        resultBundlePath = os.path.join(
            scriptArgs.resultBundleDirectory,
            f"{scriptArgs.scheme}-{simulator['safe_name']}.xcresult",
        )
        destination = f"id={destinationId},arch={scriptArgs.destinationArch}"

        print(
            f"Running {scriptArgs.scheme} on {simulator['name']} ({simulator['os']}) -> {resultBundlePath}",
            file=sys.stderr,
        )

        subprocess.check_call(
            [
                "xcodebuild",
                f"-{xcodeContainerType}",
                scriptArgs.xcodeContainer,
                "-scheme",
                scriptArgs.scheme,
                "-destination",
                destination,
                "-resultBundlePath",
                resultBundlePath,
                "-enableCodeCoverage",
                "YES",
                "CODE_SIGNING_ALLOWED=NO",
                *extraArgs,
                "test",
            ]
        )
        resultBundlePaths.append(resultBundlePath)

    return (scriptArgs.resultBundleDirectory, resultBundlePaths)


def main():
    """Runs the Xcode test execution script"""

    parser = setupArgumentParser()
    scriptArgs = parser.parse_args()

    printScriptStart()

    destinationIds, simulators = validateScriptArguments(scriptArgs)
    resultBundleDirectory, resultBundlePaths = runTests(
        scriptArgs=scriptArgs,
        destinationIds=destinationIds,
        simulators=simulators,
    )
    writeGithubOutput("result_bundle_directory", resultBundleDirectory)
    writeGithubMultilineOutput("result_bundle_paths", resultBundlePaths)


if __name__ == "__main__":
    main()
