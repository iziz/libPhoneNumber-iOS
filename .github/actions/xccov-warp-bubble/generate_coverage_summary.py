#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#  generate_coverage_summary.py
#  xccov-warp-bubble
#
#  Created by Kodex on 4/17/26.
#
# This script reads downloaded xcresult bundles, calculates per-scope coverage,
# optionally calculates combined coverage across multiple scopes, prints the
# results to the GitHub Actions log, and writes markdown and JSON summary files.

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass


SCRIPT_VERSION: str = "0.3.1"
"""The current version of the script"""


XCRESULT_SUFFIX: str = ".xcresult"
"""The filesystem suffix used for Xcode result bundles"""


DEFAULT_SCOPE_PREFIXES_TO_TRIM: tuple[str, ...] = ("project-unit-tests-",)
"""Common artifact name prefixes that should be trimmed from scope labels"""


@dataclass(frozen=True)
class CoverageThresholds:
    """Represents the configured coverage thresholds"""

    failing: float
    """Coverage percent below which the status is considered failing"""

    passing: float
    """Coverage percent at or above which the status is considered passing"""


@dataclass(frozen=True)
class ScopeCoverage:
    """Represents coverage summary details for a single scope"""

    name: str
    """The display name of the scope"""

    coveredLines: int
    """The number of covered executable lines"""

    executableLines: int
    """The total number of executable lines"""

    coveragePercent: float
    """The coverage percent for this scope"""


def setupArgumentParser() -> argparse.ArgumentParser:
    """
    Sets up the argument parser

    Returns
    -------
    ArgumentParser
        The created argument parser for this script
    """

    parser: argparse.ArgumentParser = argparse.ArgumentParser(description="""
                This script generates a code coverage summary from downloaded
                xcresult bundles.""")

    parser.add_argument("--version", "-v", action="version",
                        version="%(prog)s " + SCRIPT_VERSION)
    parser.add_argument("-?", action="help",
                        help="show this help message and exit")
    parser.add_argument("--xcresults-directory", metavar="CoverageResults/xcresults",
                        help="The root directory containing downloaded xcresult artifacts",
                        dest='xcresultsDirectory', required=True,
                        type=parseNonEmptyArgument)
    parser.add_argument("--summary-file", metavar="CoverageResults/code-coverage-summary.md",
                        help="The markdown file path where the coverage summary should be written",
                        dest='summaryFile', required=True,
                        type=parseNonEmptyArgument)
    parser.add_argument("--summary-json-file", metavar="CoverageResults/code-coverage-summary.json",
                        help="The JSON file path where the coverage summary should be written",
                        dest='summaryJsonFile', required=True,
                        type=parseNonEmptyArgument)
    parser.add_argument("--failing-coverage-threshold", metavar="60",
                        help="Coverage percent below which the status is marked as failing",
                        dest='failingCoverageThreshold', required=True,
                        type=parseCoverageThresholdArgument)
    parser.add_argument("--passing-coverage-threshold", metavar="75",
                        help="Coverage percent at or above which the status is marked as passing",
                        dest='passingCoverageThreshold', required=True,
                        type=parseCoverageThresholdArgument)

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


def parseThreshold(value: str, label: str) -> float:
    """
    Parses a coverage threshold value

    Parameters
    ----------
    value
        The raw threshold string
    label
        The threshold label for error reporting

    Returns
    -------
    float
        The parsed threshold value
    """

    try:
        threshold = float(value.strip())
    except ValueError as error:
        raise ValueError(f"Unsupported {label} value specified: {value}") from error

    if threshold < 0.0 or threshold > 100.0:
        raise ValueError(f"{label} must be between 0 and 100: {value}")

    return threshold


def parseCoverageThresholdArgument(value: str) -> float:
    """
    Parses and validates a coverage threshold argument

    Parameters
    ----------
    value
        The raw threshold argument value

    Returns
    -------
    float
        The parsed threshold value
    """

    return parseThreshold(value, "coverage threshold")


def parseThresholds(scriptArgs: argparse.Namespace) -> CoverageThresholds:
    """
    Parses and validates the configured coverage thresholds

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    CoverageThresholds
        The parsed coverage thresholds
    """

    thresholds = CoverageThresholds(
        failing=float(scriptArgs.failingCoverageThreshold),
        passing=float(scriptArgs.passingCoverageThreshold),
    )
    if thresholds.failing >= thresholds.passing:
        raise ValueError(
            "The failing coverage threshold must be less than the passing coverage threshold"
        )

    return thresholds


def validateScriptArguments(scriptArgs: argparse.Namespace) -> CoverageThresholds:
    """
    Validates the parsed script arguments

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    CoverageThresholds
        The parsed coverage thresholds
    """

    return parseThresholds(scriptArgs)


def normalizeScopeName(scopeName: str) -> str:
    """
    Normalizes a downloaded artifact directory name into a scope label

    Parameters
    ----------
    scopeName
        The raw artifact directory name

    Returns
    -------
    str
        The normalized scope label
    """

    normalizedScopeName = scopeName.strip()

    for prefix in DEFAULT_SCOPE_PREFIXES_TO_TRIM:
        if normalizedScopeName.startswith(prefix):
            normalizedScopeName = normalizedScopeName[len(prefix):]
            break

    if normalizedScopeName.endswith(XCRESULT_SUFFIX):
        normalizedScopeName = normalizedScopeName[:-len(XCRESULT_SUFFIX)]

    return normalizedScopeName or scopeName


def findResultBundles(searchRoot: str) -> list[str]:
    """
    Finds all xcresult bundles under the specified directory

    Parameters
    ----------
    searchRoot
        The directory to search for xcresult bundles

    Returns
    -------
    list[str]
        The discovered xcresult bundle paths
    """

    resultBundles: list[str] = []
    if not os.path.isdir(searchRoot):
        return resultBundles

    for root, dirnames, _filenames in os.walk(searchRoot):
        remainingDirnames: list[str] = []
        for dirname in dirnames:
            fullPath = os.path.join(root, dirname)
            if dirname.endswith(XCRESULT_SUFFIX):
                resultBundles.append(fullPath)
            else:
                remainingDirnames.append(dirname)
        dirnames[:] = remainingDirnames

    return sorted(resultBundles)


def discoverCoverageScopes(searchRoot: str) -> dict[str, list[str]]:
    """
    Discovers the downloaded coverage scopes and their xcresult bundles

    Parameters
    ----------
    searchRoot
        The root directory containing downloaded coverage artifacts

    Returns
    -------
    dict[str, list[str]]
        The discovered coverage scopes and their xcresult bundle paths
    """

    if not os.path.isdir(searchRoot):
        return {}

    scopeBundles: dict[str, list[str]] = {}
    for entryName in sorted(os.listdir(searchRoot)):
        entryPath = os.path.join(searchRoot, entryName)
        if not os.path.isdir(entryPath):
            continue

        resultBundles = findResultBundles(entryPath)
        if len(resultBundles) <= 0:
            print(f"{entryName}: no downloaded .xcresult bundles found", file=sys.stderr)
            continue

        scopeBundles[normalizeScopeName(entryName)] = resultBundles

    if len(scopeBundles) > 0:
        return scopeBundles

    rootResultBundles = findResultBundles(searchRoot)
    if len(rootResultBundles) <= 0:
        return {}

    fallbackScopeName = os.path.basename(os.path.normpath(searchRoot)) or "Coverage"
    return {normalizeScopeName(fallbackScopeName): rootResultBundles}


def mergeCoverageReport(target: dict[str, dict[int, bool]], resultBundlePath: str):
    """
    Merges an xcresult coverage report into an aggregated line coverage map

    Parameters
    ----------
    target
        The target aggregated line coverage map
    resultBundlePath
        The xcresult bundle path to process
    """

    report = json.loads(
        subprocess.check_output(
            ["xcrun", "xccov", "view", "--archive", "--json", resultBundlePath],
            text=True,
        )
    )

    for filePath, entries in report.items():
        if not isinstance(entries, list):
            continue

        combinedLines = target.setdefault(filePath, {})
        for entry in entries:
            if not isinstance(entry, dict):
                continue

            lineNumber = entry.get("line")
            if lineNumber is None or not entry.get("isExecutable"):
                continue

            isCovered = int(entry.get("executionCount", 0) or 0) > 0
            combinedLines[int(lineNumber)] = combinedLines.get(int(lineNumber), False) or isCovered


def summarizeLineCoverage(lineCoverageMap: dict[str, dict[int, bool]]) -> ScopeCoverage:
    """
    Summarizes an aggregated line coverage map

    Parameters
    ----------
    lineCoverageMap
        The aggregated line coverage map

    Returns
    -------
    ScopeCoverage
        The summarized coverage details
    """

    executableLines = sum(len(lines) for lines in lineCoverageMap.values())
    coveredLines = sum(
        1 for lines in lineCoverageMap.values() for isCovered in lines.values() if isCovered
    )
    coveragePercent = (
        coveredLines / executableLines * 100.0
        if executableLines > 0
        else 0.0
    )

    return ScopeCoverage(
        name="",
        coveredLines=coveredLines,
        executableLines=executableLines,
        coveragePercent=coveragePercent,
    )


def withName(scopeCoverage: ScopeCoverage, name: str) -> ScopeCoverage:
    """
    Applies a display name to a scope coverage summary

    Parameters
    ----------
    scopeCoverage
        The coverage summary to rename
    name
        The scope name to apply

    Returns
    -------
    ScopeCoverage
        The renamed coverage summary
    """

    return ScopeCoverage(
        name=name,
        coveredLines=scopeCoverage.coveredLines,
        executableLines=scopeCoverage.executableLines,
        coveragePercent=scopeCoverage.coveragePercent,
    )


def calculateScopeCoverages(discoveredScopes: dict[str, list[str]]) -> tuple[list[ScopeCoverage], ScopeCoverage | None]:
    """
    Calculates coverage summaries for each discovered scope

    Parameters
    ----------
    discoveredScopes
        The discovered scopes and their xcresult bundle paths

    Returns
    -------
    tuple[list[ScopeCoverage], ScopeCoverage | None]
        The per-scope summaries and optional combined summary
    """

    combinedCoverageMap: dict[str, dict[int, bool]] = {}
    scopeCoverages: list[ScopeCoverage] = []

    for scopeName, resultBundles in sorted(discoveredScopes.items()):
        scopeCoverageMap: dict[str, dict[int, bool]] = {}
        for resultBundle in resultBundles:
            print(f"Processing result bundle for {scopeName}: {resultBundle}")
            mergeCoverageReport(scopeCoverageMap, resultBundle)
            mergeCoverageReport(combinedCoverageMap, resultBundle)

        scopeCoverages.append(withName(summarizeLineCoverage(scopeCoverageMap), scopeName))

    if len(scopeCoverages) <= 1:
        return (scopeCoverages, None)

    return (scopeCoverages, withName(summarizeLineCoverage(combinedCoverageMap), "Combined"))


def determineCoverageStatus(coveragePercent: float, thresholds: CoverageThresholds) -> str:
    """
    Determines the coverage status label for a coverage percent

    Parameters
    ----------
    coveragePercent
        The coverage percent to evaluate
    thresholds
        The configured coverage thresholds

    Returns
    -------
    str
        The coverage status label
    """

    if coveragePercent < thresholds.failing:
        return "fail"
    if coveragePercent < thresholds.passing:
        return "warn"

    return "pass"


def determineStatusEmoji(status: str) -> str:
    """
    Determines the emoji for a coverage status label

    Parameters
    ----------
    status
        The coverage status label

    Returns
    -------
    str
        The corresponding emoji
    """

    return {"fail": "❌", "warn": "⚠️", "pass": "✅"}[status]


def serializeScope(scopeCoverage: ScopeCoverage, thresholds: CoverageThresholds) -> dict[str, object]:
    """
    Serializes a scope coverage summary for JSON output

    Parameters
    ----------
    scopeCoverage
        The scope coverage summary
    thresholds
        The configured coverage thresholds

    Returns
    -------
    dict[str, object]
        The serialized scope coverage payload
    """

    status = determineCoverageStatus(scopeCoverage.coveragePercent, thresholds)
    return {
        "name": scopeCoverage.name,
        "covered_lines": scopeCoverage.coveredLines,
        "executable_lines": scopeCoverage.executableLines,
        "coverage_percent": round(scopeCoverage.coveragePercent, 2),
        "status": status,
        "status_emoji": determineStatusEmoji(status),
    }


def printCoverageSummary(scopeCoverages: list[ScopeCoverage],
                         overallCoverage: ScopeCoverage | None,
                         thresholds: CoverageThresholds):
    """
    Prints a concise coverage summary to the GitHub Actions log

    Parameters
    ----------
    scopeCoverages
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary
    thresholds
        The configured coverage thresholds
    """

    for scopeCoverage in scopeCoverages:
        status = determineCoverageStatus(scopeCoverage.coveragePercent, thresholds)
        print(f"{scopeCoverage.name} - {scopeCoverage.coveragePercent:.2f}% {determineStatusEmoji(status)}")

    if overallCoverage is not None:
        status = determineCoverageStatus(overallCoverage.coveragePercent, thresholds)
        print(f"Combined - {overallCoverage.coveragePercent:.2f}% {determineStatusEmoji(status)}")


def renderMarkdownSummary(scopeCoverages: list[ScopeCoverage],
                          overallCoverage: ScopeCoverage | None,
                          thresholds: CoverageThresholds) -> str:
    """
    Renders the markdown coverage summary

    Parameters
    ----------
    scopeCoverages
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary
    thresholds
        The configured coverage thresholds

    Returns
    -------
    str
        The markdown summary contents
    """

    lines = [
        "### Code Coverage",
        "",
        "| Scope | Coverage | Status |",
        "| --- | :---: | :---: |",
    ]

    for scopeCoverage in scopeCoverages:
        status = determineCoverageStatus(scopeCoverage.coveragePercent, thresholds)
        lines.append(f"| {scopeCoverage.name} | {scopeCoverage.coveragePercent:.2f}% | {determineStatusEmoji(status)} |")

    if overallCoverage is not None:
        status = determineCoverageStatus(overallCoverage.coveragePercent, thresholds)
        indent = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
        lines.append(f"| {indent} **Combined** | **{overallCoverage.coveragePercent:.2f}%** | **{determineStatusEmoji(status)}** |")

    return "\n".join(lines) + "\n"


def renderJsonSummary(scopeCoverages: list[ScopeCoverage],
                      overallCoverage: ScopeCoverage | None,
                      thresholds: CoverageThresholds) -> dict[str, object]:
    """
    Renders the JSON coverage summary payload

    Parameters
    ----------
    scopeCoverages
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary
    thresholds
        The configured coverage thresholds

    Returns
    -------
    dict[str, object]
        The JSON coverage summary payload
    """

    payload: dict[str, object] = {
        "scope_count": len(scopeCoverages),
        "thresholds": {
            "failing_coverage_threshold": thresholds.failing,
            "passing_coverage_threshold": thresholds.passing,
        },
        "scopes": [serializeScope(scopeCoverage, thresholds) for scopeCoverage in scopeCoverages],
        "overall_coverage_percent": "",
    }

    if overallCoverage is not None:
        payload["combined"] = serializeScope(overallCoverage, thresholds)
        payload["overall_coverage_percent"] = round(overallCoverage.coveragePercent, 2)
    elif len(scopeCoverages) == 1:
        payload["overall_coverage_percent"] = round(scopeCoverages[0].coveragePercent, 2)

    return payload


def ensureParentDirectory(filePath: str):
    """
    Ensures the parent directory for a file path exists

    Parameters
    ----------
    filePath
        The file path whose parent directory should be created
    """

    parentDirectory = os.path.dirname(filePath)
    if len(parentDirectory) > 0:
        os.makedirs(parentDirectory, exist_ok=True)


def writeTextFile(filePath: str, contents: str):
    """
    Writes text contents to a file path

    Parameters
    ----------
    filePath
        The file path to write
    contents
        The text contents to write
    """

    ensureParentDirectory(filePath)
    with open(filePath, "w", encoding="utf-8") as file:
        file.write(contents)


def writeJsonFile(filePath: str, payload: dict[str, object]):
    """
    Writes a JSON payload to a file path

    Parameters
    ----------
    filePath
        The file path to write
    payload
        The JSON payload to write
    """

    ensureParentDirectory(filePath)
    with open(filePath, "w", encoding="utf-8") as file:
        json.dump(payload, file, indent=2, sort_keys=True)
        file.write("\n")


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


def publishOutputs(summaryFile: str, summaryJsonFile: str, coveragePercent: str, scopeCount: int):
    """
    Publishes the generated coverage summary outputs for GitHub Actions

    Parameters
    ----------
    summaryFile
        The markdown summary file path
    summaryJsonFile
        The JSON summary file path
    coveragePercent
        The overall coverage percent string
    scopeCount
        The number of summarized scopes
    """

    writeGithubOutput("summary_file", summaryFile)
    writeGithubOutput("summary_json_file", summaryJsonFile)
    writeGithubOutput("coverage_percent", coveragePercent)
    writeGithubOutput("scope_count", str(scopeCount))


def writeUnavailableSummaries(summaryFile: str,
                              summaryJsonFile: str,
                              message: str,
                              thresholds: CoverageThresholds):
    """
    Writes markdown and JSON summary files for an unavailable coverage result

    Parameters
    ----------
    summaryFile
        The markdown summary file path
    summaryJsonFile
        The JSON summary file path
    message
        The message to write
    thresholds
        The configured coverage thresholds
    """

    writeTextFile(summaryFile, f"### Code Coverage\n\n{message}\n")
    writeJsonFile(
        summaryJsonFile,
        {
            "message": message,
            "overall_coverage_percent": "",
            "scope_count": 0,
            "scopes": [],
            "thresholds": {
                "failing_coverage_threshold": thresholds.failing,
                "passing_coverage_threshold": thresholds.passing,
            },
        },
    )


def determineOverallCoveragePercent(scopeCoverages: list[ScopeCoverage], overallCoverage: ScopeCoverage | None) -> str:
    """
    Determines the overall coverage percent string for action outputs

    Parameters
    ----------
    scopeCoverages
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary

    Returns
    -------
    str
        The overall coverage percent string
    """

    if overallCoverage is not None:
        return f"{overallCoverage.coveragePercent:.2f}"
    if len(scopeCoverages) == 1:
        return f"{scopeCoverages[0].coveragePercent:.2f}"

    return ""


def main():
    """Runs the coverage summary generation script"""

    parser = setupArgumentParser()
    scriptArgs = parser.parse_args()

    printScriptStart()

    thresholds = validateScriptArguments(scriptArgs)
    discoveredScopes = discoverCoverageScopes(scriptArgs.xcresultsDirectory)

    if len(discoveredScopes) <= 0:
        message = "Code coverage unavailable because no unit test result bundles were downloaded."
        writeUnavailableSummaries(scriptArgs.summaryFile, scriptArgs.summaryJsonFile, message, thresholds)
        publishOutputs(scriptArgs.summaryFile, scriptArgs.summaryJsonFile, "", 0)
        return

    scopeCoverages, overallCoverage = calculateScopeCoverages(discoveredScopes)
    printCoverageSummary(scopeCoverages, overallCoverage, thresholds)

    writeTextFile(
        scriptArgs.summaryFile,
        renderMarkdownSummary(scopeCoverages, overallCoverage, thresholds),
    )
    writeJsonFile(
        scriptArgs.summaryJsonFile,
        renderJsonSummary(scopeCoverages, overallCoverage, thresholds),
    )

    publishOutputs(
        scriptArgs.summaryFile,
        scriptArgs.summaryJsonFile,
        determineOverallCoveragePercent(scopeCoverages, overallCoverage),
        len(scopeCoverages),
    )


if __name__ == "__main__":
    main()
