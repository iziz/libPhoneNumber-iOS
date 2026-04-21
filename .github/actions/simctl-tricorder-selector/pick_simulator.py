#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#  pick_simulator.py
#  simctl-tricorder-selector
#
#  Created by Kodex on 4/17/26.
#
# This script inspects the locally installed Xcode simulator inventory and chooses one
# compatible destination per requested device type for downstream use in GitHub Actions
# or local automation.

import argparse
import json
import os
import random
import re
import subprocess
import sys
from dataclasses import dataclass
from typing import Optional


SCRIPT_VERSION: str = "0.3.0"
"""The current version of the script"""


SUPPORTED_DEVICE_TYPES: tuple[str, ...] = ("iphone", "ipad", "macos", "watch", "vision")
"""Supported Apple simulator device types"""


SUPPORTED_SELECTION_MODES: tuple[str, ...] = (
    "random-compatible",
    "random-latest-compatible",
    "model-type",
    "latest-model",
)
"""Supported simulator selection modes"""


RUNTIME_FAMILY_MAP: dict[str, tuple[str, ...]] = {
    "iOS": ("iphone", "ipad"),
    "macOS": ("macos",),
    "watchOS": ("watch",),
    "visionOS": ("vision",),
    "xrOS": ("vision",),
}
"""Maps simctl runtime families to the supported device types"""


VARIANT_SCORES: tuple[tuple[str, int], ...] = (
    ("ultra", 80),
    ("pro max", 70),
    ("max", 60),
    ("plus", 50),
    ("pro", 40),
    ("air", 30),
    ("mini", 20),
    ("se", 10),
)
"""Relative ranking for Apple simulator model variants"""


OUTPUT_MARKER: str = "__SIMCTL_PICK_A_TRICORDER__"
"""The multiline GitHub Actions output marker"""


@dataclass(frozen=True)
class Candidate:
    """Represents a single compatible simulator candidate"""

    deviceType: str
    """The normalized device type"""

    name: str
    """The simulator display name"""

    udid: str
    """The simulator UDID"""

    runtimeIdentifier: str
    """The CoreSimulator runtime identifier"""

    runtimeFamily: str
    """The runtime family, such as iOS or watchOS"""

    osVersion: tuple[int, ...]
    """The parsed OS version tuple"""


def setupArgumentParser() -> argparse.ArgumentParser:
    """
    Sets up the Arugment Parser

    Returns
    -------
    ArgumentParser
        The created argument parser for this script
    """

    parser: argparse.ArgumentParser = argparse.ArgumentParser(description="""
                This script inspects the available Xcode simulators and selects one
                compatible Apple simulator destination per requested device type.""")

    parser.add_argument("--version", "-v", action="version",
                        version="%(prog)s " + SCRIPT_VERSION)
    parser.add_argument("-?", action="help",
                        help="show this help message and exit")
    parser.add_argument("--device-types", metavar="iphone,ipad", required=True,
                        help="Ordered, comma-separated list of device types to consider - iphone, ipad, macos, watch, vision",
                        dest='deviceTypes')
    parser.add_argument("--selection-mode", metavar="random-compatible",
                        help="How to choose the simulator(s) - random-compatible, random-latest-compatible, model-type, latest-model",
                        dest='selectionMode', default="random-compatible",
                        choices=SUPPORTED_SELECTION_MODES)
    parser.add_argument("--model-preferences", metavar="iphone=Pro Max;ipad=Pro",
                        help="Semicolon-separated model keywords per device type",
                        dest='modelPreferences', default="")
    parser.add_argument("--iphoneos-version", metavar="latest",
                        help="Specific iOS version for iPhone simulators, or latest",
                        dest='iphoneosVersion', default="latest")
    parser.add_argument("--ipados-version", metavar="latest",
                        help="Specific iOS version for iPad simulators, or latest",
                        dest='ipadosVersion', default="latest")
    parser.add_argument("--macos-version", metavar="latest",
                        help="Specific macOS version for macOS simulators, or latest",
                        dest='macosVersion', default="latest")
    parser.add_argument("--watchos-version", metavar="latest",
                        help="Specific watchOS version for watch simulators, or latest",
                        dest='watchosVersion', default="latest")
    parser.add_argument("--visionos-version", metavar="latest",
                        help="Specific visionOS version for Vision simulators, or latest",
                        dest='visionosVersion', default="latest")
    parser.add_argument("--devices-json-file", metavar="devices.json",
                        help="Optional path to a simctl devices JSON file for local testing",
                        dest='devicesJsonFile', default=None)

    return parser


def printScriptStart():
    """Prints the info for the start of the script"""

    print(f"Starting {os.path.basename(__file__)} v{SCRIPT_VERSION}", file=sys.stderr)


def parseCommaSeparatedList(value: str) -> list[str]:
    """
    Parses a comma-separated string into a normalized list of values

    Parameters
    ----------
    value
        The comma-separated string to parse

    Returns
    -------
    list[str]
        The normalized list of values
    """

    return [part.strip().lower() for part in value.split(",") if len(part.strip()) > 0]


def parseRequestedVersion(value: str) -> Optional[tuple[int, ...]]:
    """
    Parses the requested OS version string

    Parameters
    ----------
    value
        The requested version string

    Returns
    -------
    tuple[int, ...] | None
        The parsed version tuple, or None when the latest available version should be used
    """

    normalized = value.strip().lower()
    if normalized == "latest":
        return None

    if not re.fullmatch(r"\d+(?:\.\d+)*", normalized):
        raise ValueError(f"Unsupported version value specified: {value}")

    return tuple(int(part) for part in normalized.split("."))


def parseModelPreferences(value: str) -> dict[str, list[str]]:
    """
    Parses the model preference string into a dictionary keyed by device type

    Parameters
    ----------
    value
        The raw model preference string

    Returns
    -------
    dict[str, list[str]]
        The parsed model preferences by device type
    """

    preferences: dict[str, list[str]] = {}
    if value is None or len(value.strip()) <= 0:
        return preferences

    for segment in value.split(";"):
        trimmedSegment = segment.strip()
        if len(trimmedSegment) <= 0:
            continue

        if "=" not in trimmedSegment:
            raise ValueError(
                "Model preferences must use the format "
                '"device=keyword1,keyword2;other-device=keyword"'
            )

        deviceType, keywordsString = trimmedSegment.split("=", 1)
        normalizedDeviceType = deviceType.strip().lower()

        if normalizedDeviceType not in SUPPORTED_DEVICE_TYPES:
            raise ValueError(f"Unsupported device type in model preferences: {deviceType}")

        preferences[normalizedDeviceType] = [
            keyword.strip().lower() for keyword in keywordsString.split(",") if len(keyword.strip()) > 0
        ]

    return preferences


def readDevicesJson(devicesJsonFile: Optional[str]=None) -> dict[str, object]:
    """
    Reads the simulator device inventory as JSON

    Parameters
    ----------
    devicesJsonFile
        Optional path to a pre-generated simctl devices JSON file

    Returns
    -------
    dict[str, object]
        The simctl device inventory payload
    """

    if devicesJsonFile is not None and len(devicesJsonFile.strip()) > 0:
        with open(devicesJsonFile, "r", encoding="utf-8") as file:
            return json.load(file)

    result = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "--json"],
        text=True,
    )

    return json.loads(result)


def parseRuntimeIdentifier(runtimeIdentifier: str) -> Optional[tuple[str, tuple[int, ...]]]:
    """
    Parses a CoreSimulator runtime identifier

    Parameters
    ----------
    runtimeIdentifier
        The CoreSimulator runtime identifier

    Returns
    -------
    tuple[str, tuple[int, ...]] | None
        The runtime family and parsed version tuple, or None if unsupported
    """

    runtimeMatch = re.match(
        r"^com\.apple\.CoreSimulator\.SimRuntime\.([A-Za-z]+)-(\d+(?:-\d+)*)$",
        runtimeIdentifier,
    )
    if runtimeMatch is None:
        return None

    runtimeFamily = runtimeMatch.group(1)
    if runtimeFamily not in RUNTIME_FAMILY_MAP:
        return None

    runtimeVersion = tuple(int(part) for part in runtimeMatch.group(2).split("-"))
    return (runtimeFamily, runtimeVersion)


def classifyDeviceType(name: str) -> Optional[str]:
    """
    Determines the normalized device type from the simulator display name

    Parameters
    ----------
    name
        The simulator display name

    Returns
    -------
    str | None
        The normalized device type, or None if unsupported
    """

    normalizedName = name.strip()

    if normalizedName.startswith("iPhone"):
        return "iphone"
    if normalizedName.startswith("iPad"):
        return "ipad"
    if normalizedName.startswith("Apple Watch"):
        return "watch"
    if "Vision" in normalizedName:
        return "vision"
    if normalizedName.startswith("Mac") or normalizedName == "My Mac":
        return "macos"

    return None


def versionToString(version: tuple[int, ...]) -> str:
    """
    Converts a version tuple into a human-readable string

    Parameters
    ----------
    version
        The version tuple to convert

    Returns
    -------
    str
        The version string
    """

    return ".".join(str(part) for part in version)


def matchesRequestedVersion(candidateVersion: tuple[int, ...], requestedVersion: Optional[tuple[int, ...]]) -> bool:
    """
    Determines whether a simulator OS version matches the requested version

    Parameters
    ----------
    candidateVersion
        The simulator candidate OS version
    requestedVersion
        The requested OS version, or None when any/latest version is acceptable

    Returns
    -------
    bool
        Whether the candidate version matches the requested version
    """

    if requestedVersion is None:
        return True

    return candidateVersion[:len(requestedVersion)] == requestedVersion


def determineVariantDetails(name: str) -> tuple[str, int] | None:
    """
    Determines the detected model variant keyword and score

    Parameters
    ----------
    name
        The simulator display name

    Returns
    -------
    tuple[str, int] | None
        The detected variant keyword and score, or None if no variant matched
    """

    normalizedName = name.lower()

    for keyword, score in VARIANT_SCORES:
        if keyword in normalizedName:
            return (keyword, score)

    return None


def determineModelType(name: str) -> str:
    """
    Determines the simulator model type from the simulator display name

    Parameters
    ----------
    name
        The simulator display name

    Returns
    -------
    str
        The detected model type, or an empty string if none is present
    """

    variantDetails = determineVariantDetails(name)
    return variantDetails[0].title() if variantDetails is not None else ""


def createSafeName(name: str, osVersion: str) -> str:
    """
    Creates a filesystem-safe simulator identifier string

    Parameters
    ----------
    name
        The simulator display name
    osVersion
        The simulator OS version string

    Returns
    -------
    str
        The filesystem-safe simulator identifier
    """

    return re.sub(r"[^A-Za-z0-9._-]+", "-", f"{name}-{osVersion}").strip("-")


def determineModelRank(candidate: Candidate) -> tuple[tuple[int, ...], int, tuple[int, ...], str]:
    """
    Determines the rank tuple for a simulator candidate

    Parameters
    ----------
    candidate
        The simulator candidate to rank

    Returns
    -------
    tuple[tuple[int, ...], int, tuple[int, ...], str]
        The rank tuple used for deterministic sorting and comparisons
    """

    variantDetails = determineVariantDetails(candidate.name)
    numericParts = tuple(int(part) for part in re.findall(r"\d+", candidate.name))
    return (
        candidate.osVersion,
        variantDetails[1] if variantDetails is not None else 25,
        numericParts,
        candidate.name,
    )


def filterToLatestModel(candidates: list[Candidate]) -> list[Candidate]:
    """
    Filters the candidate list down to the highest-ranked model(s)

    Parameters
    ----------
    candidates
        The candidate simulators to filter

    Returns
    -------
    list[Candidate]
        The highest-ranked simulator candidate(s)
    """

    if len(candidates) <= 0:
        return []

    bestRank = max(determineModelRank(candidate) for candidate in candidates)
    return [candidate for candidate in candidates if determineModelRank(candidate) == bestRank]


def filterToModelPreferences(candidates: list[Candidate], modelPreferences: dict[str, list[str]]) -> list[Candidate]:
    """
    Filters the candidate list using the requested model preference keywords

    Parameters
    ----------
    candidates
        The candidate simulators to filter
    modelPreferences
        The requested model preferences by device type

    Returns
    -------
    list[Candidate]
        The filtered candidate list
    """

    if len(candidates) <= 0:
        return []

    keywords = modelPreferences.get(candidates[0].deviceType, [])
    if len(keywords) <= 0:
        return candidates

    return [
        candidate
        for candidate in candidates
        if all(keyword in candidate.name.lower() for keyword in keywords)
    ]


def enumerateCandidates(devicePayload: dict[str, object], requestedDeviceTypes: list[str]) -> dict[str, list[Candidate]]:
    """
    Enumerates all compatible simulator candidates from the simctl payload

    Parameters
    ----------
    devicePayload
        The simctl device payload
    requestedDeviceTypes
        The normalized device types to consider

    Returns
    -------
    dict[str, list[Candidate]]
        The compatible candidates grouped by device type
    """

    requestedDeviceTypesSet = set(requestedDeviceTypes)
    candidatesByType: dict[str, list[Candidate]] = {
        deviceType: [] for deviceType in requestedDeviceTypes
    }

    devicesByRuntime = devicePayload.get("devices", {})
    if not isinstance(devicesByRuntime, dict):
        raise ValueError("Unexpected simctl JSON format: missing devices map")

    for runtimeIdentifier, entries in devicesByRuntime.items():
        parsedRuntime = parseRuntimeIdentifier(runtimeIdentifier)
        if parsedRuntime is None:
            continue

        runtimeFamily, runtimeVersion = parsedRuntime
        if not isinstance(entries, list):
            continue

        print(f"Runtime: {runtimeIdentifier} ({len(entries)} devices)", file=sys.stderr)

        for entry in entries:
            if not isinstance(entry, dict):
                continue

            name = str(entry.get("name") or "").strip()
            udid = str(entry.get("udid") or "").strip()
            isAvailable = bool(entry.get("isAvailable"))

            if not isAvailable or len(name) <= 0 or len(udid) <= 0:
                continue

            deviceType = classifyDeviceType(name)
            if deviceType is None:
                continue
            if deviceType not in requestedDeviceTypesSet:
                continue
            if deviceType not in RUNTIME_FAMILY_MAP.get(runtimeFamily, ()):
                continue

            candidate = Candidate(
                deviceType=deviceType,
                name=name,
                udid=udid,
                runtimeIdentifier=runtimeIdentifier,
                runtimeFamily=runtimeFamily,
                osVersion=runtimeVersion,
            )

            candidatesByType[deviceType].append(candidate)
            print(
                f"  {name} ({runtimeFamily} {versionToString(runtimeVersion)}) [{udid}]",
                file=sys.stderr,
            )

    return candidatesByType


def filterCandidatesForRequestedOs(candidates: list[Candidate], requestedVersion: Optional[tuple[int, ...]], deviceType: str) -> list[Candidate]:
    """
    Filters candidates to the requested OS version, or the latest available version when unspecified

    Parameters
    ----------
    candidates
        The candidate simulators to filter
    requestedVersion
        The requested OS version, or None for latest
    deviceType
        The device type being filtered

    Returns
    -------
    list[Candidate]
        The filtered candidates for the requested or latest OS version
    """

    matchingCandidates = [candidate for candidate in candidates if matchesRequestedVersion(candidate.osVersion, requestedVersion)]

    if requestedVersion is not None:
        print(
            f"{deviceType}: requested OS {versionToString(requestedVersion)}",
            file=sys.stderr,
        )
        return matchingCandidates

    if len(matchingCandidates) <= 0:
        return matchingCandidates

    latestVersion = max(candidate.osVersion for candidate in matchingCandidates)
    print(f"{deviceType}: using latest OS {versionToString(latestVersion)}", file=sys.stderr)

    return [
        candidate for candidate in matchingCandidates if candidate.osVersion == latestVersion
    ]


def buildCandidatePool(deviceType: str,
                       candidates: list[Candidate],
                       requestedVersion: Optional[tuple[int, ...]],
                       selectionMode: str,
                       modelPreferences: dict[str, list[str]]) -> list[Candidate]:
    """
    Builds the final candidate pool for the specified device type and selection mode

    Parameters
    ----------
    deviceType
        The device type being evaluated
    candidates
        The compatible candidates for this device type
    requestedVersion
        The requested OS version, or None for latest
    selectionMode
        The simulator selection mode
    modelPreferences
        The requested model preferences by device type

    Returns
    -------
    list[Candidate]
        The narrowed candidate pool for final selection
    """

    versionFilteredCandidates = filterCandidatesForRequestedOs(
        candidates=candidates,
        requestedVersion=requestedVersion,
        deviceType=deviceType,
    )

    if selectionMode == "random-compatible":
        return versionFilteredCandidates

    if selectionMode == "model-type":
        versionFilteredCandidates = filterToModelPreferences(
            versionFilteredCandidates,
            modelPreferences,
        )

    if selectionMode in {"random-latest-compatible", "model-type", "latest-model"}:
        return filterToLatestModel(versionFilteredCandidates)

    raise ValueError(f"Unsupported selection mode: {selectionMode}")


def selectDestinationFromPool(candidates: list[Candidate],
                              selectionMode: str) -> Optional[Candidate]:
    """
    Selects a single destination from a prepared candidate pool

    Parameters
    ----------
    candidates
        The candidate pool to select from
    selectionMode
        The simulator selection mode

    Returns
    -------
    Candidate | None
        The selected candidate destination
    """

    if len(candidates) <= 0:
        return None

    if selectionMode.startswith("random-"):
        return random.choice(candidates)

    rankedCandidates = sorted(candidates, key=determineModelRank, reverse=True)
    return rankedCandidates[0]


def determineRequestedVersions(scriptArgs: argparse.Namespace) -> dict[str, Optional[tuple[int, ...]]]:
    """
    Determines the requested OS versions for all supported device types

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    dict[str, tuple[int, ...] | None]
        The requested OS versions by device type
    """

    return {
        "iphone": parseRequestedVersion(scriptArgs.iphoneosVersion),
        "ipad": parseRequestedVersion(scriptArgs.ipadosVersion),
        "macos": parseRequestedVersion(scriptArgs.macosVersion),
        "watch": parseRequestedVersion(scriptArgs.watchosVersion),
        "vision": parseRequestedVersion(scriptArgs.visionosVersion),
    }


def validateScriptArguments(scriptArgs: argparse.Namespace) -> list[str]:
    """
    Validates the parsed script arguments

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    list[str]
        The normalized requested device types
    """

    requestedDeviceTypes = parseCommaSeparatedList(scriptArgs.deviceTypes)
    if len(requestedDeviceTypes) <= 0:
        raise ValueError("At least one device type must be provided")

    unsupportedDeviceTypes = [
        deviceType for deviceType in requestedDeviceTypes
        if deviceType not in SUPPORTED_DEVICE_TYPES
    ]
    if unsupportedDeviceTypes:
        raise ValueError(
            f"Unsupported device type specified: {', '.join(unsupportedDeviceTypes)}"
        )

    return requestedDeviceTypes


def determineSelectedDestinations(requestedDeviceTypes: list[str],
                                  candidatesByType: dict[str, list[Candidate]],
                                  requestedVersions: dict[str, Optional[tuple[int, ...]]],
                                  selectionMode: str,
                                  modelPreferences: dict[str, list[str]]) -> list[Candidate]:
    """
    Determines the final selected destinations across the requested device types

    Parameters
    ----------
    requestedDeviceTypes
        The ordered requested device types
    candidatesByType
        The compatible candidates grouped by device type
    requestedVersions
        The requested OS versions by device type
    selectionMode
        The simulator selection mode
    modelPreferences
        The requested model preferences by device type

    Returns
    -------
    list[Candidate]
        The selected destinations
    """

    selectedCandidates: list[Candidate] = []
    missingDeviceTypes: list[str] = []

    for deviceType in requestedDeviceTypes:
        compatibleCandidates = candidatesByType.get(deviceType, [])
        if len(compatibleCandidates) <= 0:
            print(f"{deviceType}: no compatible devices found", file=sys.stderr)
            missingDeviceTypes.append(deviceType)
            continue

        candidatePool = buildCandidatePool(
            deviceType=deviceType,
            candidates=compatibleCandidates,
            requestedVersion=requestedVersions[deviceType],
            selectionMode=selectionMode,
            modelPreferences=modelPreferences,
        )

        if len(candidatePool) <= 0:
            print(f"{deviceType}: no devices matched the requested filters", file=sys.stderr)
            missingDeviceTypes.append(deviceType)
            continue

        selectedCandidate = selectDestinationFromPool(
            candidates=candidatePool,
            selectionMode=selectionMode,
        )
        if selectedCandidate is None:
            missingDeviceTypes.append(deviceType)
            continue

        selectedCandidates.append(selectedCandidate)

    if len(missingDeviceTypes) > 0:
        missingDeviceTypesLabel = ", ".join(missingDeviceTypes)
        raise SystemExit(
            f"Unable to determine simulator destinations for the requested device types: "
            f"{missingDeviceTypesLabel}"
        )

    return selectedCandidates


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


def publishOutputs(selectedCandidates: list[Candidate]):
    """
    Publishes the selected simulator outputs for GitHub Actions

    Parameters
    ----------
    selectedCandidates
        The selected simulator candidates
    """

    if len(selectedCandidates) <= 0:
        return

    destinationIds = [candidate.udid for candidate in selectedCandidates]
    simulators = [
        {
            "udid": candidate.udid,
            "name": candidate.name,
            "os": versionToString(candidate.osVersion),
            "modelType": determineModelType(candidate.name),
            "safe_name": createSafeName(candidate.name, versionToString(candidate.osVersion)),
        }
        for candidate in selectedCandidates
    ]

    writeGithubOutput("simulator_jsons", json.dumps(simulators))
    writeGithubMultilineOutput("destination_ids", destinationIds)


def main():
    """Runs the simulator picker script"""

    parser = setupArgumentParser()
    scriptArgs = parser.parse_args()

    printScriptStart()

    requestedDeviceTypes = validateScriptArguments(scriptArgs)
    requestedVersions = determineRequestedVersions(scriptArgs)
    modelPreferences = parseModelPreferences(scriptArgs.modelPreferences)
    devicePayload = readDevicesJson(scriptArgs.devicesJsonFile)
    candidatesByType = enumerateCandidates(devicePayload, requestedDeviceTypes)

    selectedCandidates = determineSelectedDestinations(
        requestedDeviceTypes=requestedDeviceTypes,
        candidatesByType=candidatesByType,
        requestedVersions=requestedVersions,
        selectionMode=scriptArgs.selectionMode,
        modelPreferences=modelPreferences,
    )

    print("Selected Simulators:", file=sys.stderr)
    for candidate in selectedCandidates:
        print(
            f"  {candidate.name} ({candidate.runtimeFamily} {versionToString(candidate.osVersion)}) "
            f"[{candidate.udid}]",
            file=sys.stderr,
        )

    publishOutputs(selectedCandidates)


if __name__ == "__main__":
    main()
