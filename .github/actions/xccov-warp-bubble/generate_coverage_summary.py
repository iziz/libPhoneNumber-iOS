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


SCRIPT_VERSION: str = "0.2.0"
"""The current version of the script"""


XCRESULT_SUFFIX: str = ".xcresult"
"""The filesystem suffix used for Xcode result bundles"""


DEFAULT_SCOPE_PREFIXES_TO_TRIM: tuple[str, ...] = ("project-unit-tests-",)
"""Common artifact name prefixes that should be trimmed from scope labels"""


@dataclass(frozen=True)
class CoverageThresholds:
    """Represents the configured coverage thresholds"""

    failingCoverageThreshold: float
    """Coverage percent below which the status is considered failing"""

    passingCoverageThreshold: float
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
    Sets up the Arugment Parser

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
                        dest='xcresultsDirectory', required=True)
    parser.add_argument("--summary-file", metavar="CoverageResults/code-coverage-summary.md",
                        help="The markdown file path where the coverage summary should be written",
                        dest='summaryFile', required=True)
    parser.add_argument("--summary-json-file", metavar="CoverageResults/code-coverage-summary.json",
                        help="The JSON file path where the coverage summary should be written",
                        dest='summaryJsonFile', required=True)
    parser.add_argument("--failing-coverage-threshold", metavar="60",
                        help="Coverage percent below which the status is marked as failing",
                        dest='failingCoverageThreshold', required=True)
    parser.add_argument("--passing-coverage-threshold", metavar="75",
                        help="Coverage percent at or above which the status is marked as passing",
                        dest='passingCoverageThreshold', required=True)

    return parser


def printScriptStart():
    """Prints the info for the start of the script"""

    print(f"Starting {os.path.basename(__file__)} v{SCRIPT_VERSION}", file=sys.stderr)


def parseCoverageThreshold(value: str, label: str) -> float:
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

    if len(scriptArgs.xcresultsDirectory.strip()) <= 0:
        raise ValueError("An xcresults directory must be provided")

    if len(scriptArgs.summaryFile.strip()) <= 0:
        raise ValueError("A summary file path must be provided")

    if len(scriptArgs.summaryJsonFile.strip()) <= 0:
        raise ValueError("A summary JSON file path must be provided")

    failingCoverageThreshold = parseCoverageThreshold(
        scriptArgs.failingCoverageThreshold,
        "failing coverage threshold",
    )
    passingCoverageThreshold = parseCoverageThreshold(
        scriptArgs.passingCoverageThreshold,
        "passing coverage threshold",
    )

    if failingCoverageThreshold >= passingCoverageThreshold:
        raise ValueError(
            "The failing coverage threshold must be less than the passing coverage threshold"
        )

    return CoverageThresholds(
        failingCoverageThreshold=failingCoverageThreshold,
        passingCoverageThreshold=passingCoverageThreshold,
    )


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

    scopeBundles: dict[str, list[str]] = {}

    if not os.path.isdir(searchRoot):
        return scopeBundles

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
    if len(rootResultBundles) > 0:
        fallbackScopeName = os.path.basename(os.path.normpath(searchRoot)) or "Coverage"
        scopeBundles[normalizeScopeName(fallbackScopeName)] = rootResultBundles

    return scopeBundles


def readCoverageReport(resultBundlePath: str) -> dict[str, object]:
    """
    Reads the xccov JSON coverage report for an xcresult bundle

    Parameters
    ----------
    resultBundlePath
        The xcresult bundle path

    Returns
    -------
    dict[str, object]
        The parsed xccov JSON report
    """

    report = subprocess.check_output(
        ["xcrun", "xccov", "view", "--archive", "--json", resultBundlePath],
        text=True,
    )

    return json.loads(report)


def mergeCoverageReport(target: dict[str, dict[int, bool]], report: dict[str, object]):
    """
    Merges an xccov JSON report into an aggregated line coverage map

    Parameters
    ----------
    target
        The target aggregated line coverage map
    report
        The xccov JSON report to merge
    """

    for filePath, entries in report.items():
        if not isinstance(entries, list):
            continue

        combinedLines = target.setdefault(filePath, {})
        for entry in entries:
            if not isinstance(entry, dict):
                continue

            lineNumber = entry.get("line")
            isExecutable = bool(entry.get("isExecutable"))
            if lineNumber is None or not isExecutable:
                continue

            isCovered = int(entry.get("executionCount", 0) or 0) > 0
            combinedLines[int(lineNumber)] = combinedLines.get(int(lineNumber), False) or isCovered


def summarizeLineCoverage(lineCoverageMap: dict[str, dict[int, bool]]) -> tuple[int, int, float]:
    """
    Summarizes an aggregated line coverage map

    Parameters
    ----------
    lineCoverageMap
        The aggregated line coverage map

    Returns
    -------
    tuple[int, int, float]
        The covered line count, executable line count, and coverage percent
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

    return (coveredLines, executableLines, coveragePercent)


def createScopeCoverage(name: str,
                        lineCoverageMap: dict[str, dict[int, bool]]) -> ScopeCoverage:
    """
    Creates a scope coverage summary from an aggregated line coverage map

    Parameters
    ----------
    name
        The scope display name
    lineCoverageMap
        The aggregated line coverage map

    Returns
    -------
    ScopeCoverage
        The created scope coverage summary
    """

    coveredLines, executableLines, coveragePercent = summarizeLineCoverage(lineCoverageMap)
    return ScopeCoverage(
        name=name,
        coveredLines=coveredLines,
        executableLines=executableLines,
        coveragePercent=coveragePercent,
    )


def calculateScopeCoverages(discoveredScopes: dict[str, list[str]]) -> tuple[list[ScopeCoverage], dict[str, dict[int, bool]]]:
    """
    Calculates per-scope coverages and the aggregated combined line coverage map

    Parameters
    ----------
    discoveredScopes
        The discovered scopes and their xcresult bundle paths

    Returns
    -------
    tuple[list[ScopeCoverage], dict[str, dict[int, bool]]]
        The per-scope coverage summaries and the combined line coverage map
    """

    combinedCoverageMap: dict[str, dict[int, bool]] = {}
    scopeCoverageSummaries: list[ScopeCoverage] = []

    for scopeName, resultBundles in sorted(discoveredScopes.items()):
        scopeCoverageMap: dict[str, dict[int, bool]] = {}

        for resultBundle in resultBundles:
            print(f"Processing result bundle for {scopeName}: {resultBundle}")
            report = readCoverageReport(resultBundle)
            mergeCoverageReport(scopeCoverageMap, report)
            mergeCoverageReport(combinedCoverageMap, report)

        scopeCoverageSummaries.append(
            createScopeCoverage(
                name=scopeName,
                lineCoverageMap=scopeCoverageMap,
            )
        )

    return (scopeCoverageSummaries, combinedCoverageMap)


def calculateOverallCoverage(scopeCoverageSummaries: list[ScopeCoverage],
                             combinedCoverageMap: dict[str, dict[int, bool]]) -> ScopeCoverage | None:
    """
    Calculates the overall combined coverage when multiple scopes are present

    Parameters
    ----------
    scopeCoverageSummaries
        The per-scope coverage summaries
    combinedCoverageMap
        The combined line coverage map

    Returns
    -------
    ScopeCoverage | None
        The combined coverage summary, or None when only one scope is present
    """

    if len(scopeCoverageSummaries) <= 1:
        return None

    return createScopeCoverage(
        name="Combined",
        lineCoverageMap=combinedCoverageMap,
    )


def determineCoverageStatus(coveragePercent: float,
                            thresholds: CoverageThresholds) -> str:
    """
    Determines the normalized status for a coverage percent

    Parameters
    ----------
    coveragePercent
        The coverage percent to evaluate
    thresholds
        The configured coverage thresholds

    Returns
    -------
    str
        The normalized coverage status
    """

    if coveragePercent < thresholds.failingCoverageThreshold:
        return "fail"
    if coveragePercent < thresholds.passingCoverageThreshold:
        return "warn"
    return "pass"


def determineStatusEmoji(status: str) -> str:
    """
    Determines the coverage status emoji for a normalized status

    Parameters
    ----------
    status
        The normalized coverage status

    Returns
    -------
    str
        The status emoji
    """

    if status == "fail":
        return "❌"
    if status == "warn":
        return "⚠️"
    return "✅"


def printCoverageSummary(scopeCoverageSummaries: list[ScopeCoverage],
                         overallCoverage: ScopeCoverage | None,
                         thresholds: CoverageThresholds):
    """
    Prints the coverage summary details to the GitHub Actions log

    Parameters
    ----------
    scopeCoverageSummaries
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary
    thresholds
        The configured coverage thresholds
    """

    for scopeCoverage in scopeCoverageSummaries:
        status = determineCoverageStatus(scopeCoverage.coveragePercent, thresholds)
        emoji = determineStatusEmoji(status)
        print(f"{scopeCoverage.name} - {scopeCoverage.coveragePercent:.2f}% {emoji}")

    if overallCoverage is not None:
        status = determineCoverageStatus(overallCoverage.coveragePercent, thresholds)
        emoji = determineStatusEmoji(status)
        print(f"Combined - {overallCoverage.coveragePercent:.2f}% {emoji}")


def ensureParentDirectory(filePath: str):
    """
    Ensures that the parent directory exists for a file path

    Parameters
    ----------
    filePath
        The file path whose parent directory should exist
    """

    parentDirectory = os.path.dirname(filePath)
    if len(parentDirectory) > 0:
        os.makedirs(parentDirectory, exist_ok=True)


def renderMarkdownSummary(scopeCoverageSummaries: list[ScopeCoverage],
                          overallCoverage: ScopeCoverage | None,
                          thresholds: CoverageThresholds) -> str:
    """
    Renders the markdown coverage summary text

    Parameters
    ----------
    scopeCoverageSummaries
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary
    thresholds
        The configured coverage thresholds

    Returns
    -------
    str
        The rendered markdown summary
    """

    lines: list[str] = [
        "### Code Coverage",
        "",
        "| Scope | Coverage | Status |",
        "| --- | :---: | :---: |",
    ]

    for scopeCoverage in scopeCoverageSummaries:
        status = determineCoverageStatus(scopeCoverage.coveragePercent, thresholds)
        emoji = determineStatusEmoji(status)
        lines.append(f"| {scopeCoverage.name} | {scopeCoverage.coveragePercent:.2f}% | {emoji} |")

    if overallCoverage is not None:
        status = determineCoverageStatus(overallCoverage.coveragePercent, thresholds)
        emoji = determineStatusEmoji(status)
        indent = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
        lines.append(
            f"| {indent} **Combined** | **{overallCoverage.coveragePercent:.2f}%** | **{emoji}** |"
        )

    return "\n".join(lines) + "\n"


def renderJsonSummary(scopeCoverageSummaries: list[ScopeCoverage],
                      overallCoverage: ScopeCoverage | None,
                      thresholds: CoverageThresholds) -> dict[str, object]:
    """
    Renders the JSON coverage summary payload

    Parameters
    ----------
    scopeCoverageSummaries
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

    def serializeScope(scopeCoverage: ScopeCoverage) -> dict[str, object]:
        status = determineCoverageStatus(scopeCoverage.coveragePercent, thresholds)
        return {
            "name": scopeCoverage.name,
            "covered_lines": scopeCoverage.coveredLines,
            "executable_lines": scopeCoverage.executableLines,
            "coverage_percent": round(scopeCoverage.coveragePercent, 2),
            "status": status,
            "status_emoji": determineStatusEmoji(status),
        }

    payload: dict[str, object] = {
        "scope_count": len(scopeCoverageSummaries),
        "thresholds": {
            "failing_coverage_threshold": thresholds.failingCoverageThreshold,
            "passing_coverage_threshold": thresholds.passingCoverageThreshold,
        },
        "scopes": [serializeScope(scopeCoverage) for scopeCoverage in scopeCoverageSummaries],
        "overall_coverage_percent": "",
    }

    if len(scopeCoverageSummaries) == 1:
        payload["overall_coverage_percent"] = round(scopeCoverageSummaries[0].coveragePercent, 2)

    if overallCoverage is not None:
        payload["combined"] = serializeScope(overallCoverage)
        payload["overall_coverage_percent"] = round(overallCoverage.coveragePercent, 2)

    return payload


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


def publishOutputs(summaryFile: str,
                   summaryJsonFile: str,
                   coveragePercent: str,
                   scopeCount: int):
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

    markdownSummary = "\n".join([
        "### Code Coverage",
        "",
        message,
        "",
    ])
    jsonSummary = {
        "message": message,
        "overall_coverage_percent": "",
        "scope_count": 0,
        "scopes": [],
        "thresholds": {
            "failing_coverage_threshold": thresholds.failingCoverageThreshold,
            "passing_coverage_threshold": thresholds.passingCoverageThreshold,
        },
    }

    writeTextFile(summaryFile, markdownSummary)
    writeJsonFile(summaryJsonFile, jsonSummary)


def determineOverallCoveragePercent(scopeCoverageSummaries: list[ScopeCoverage],
                                    overallCoverage: ScopeCoverage | None) -> str:
    """
    Determines the overall coverage percent string for action outputs

    Parameters
    ----------
    scopeCoverageSummaries
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

    if len(scopeCoverageSummaries) == 1:
        return f"{scopeCoverageSummaries[0].coveragePercent:.2f}"

    return ""


def main():
    """Runs the coverage summary generation script"""

    parser = setupArgumentParser()
    scriptArgs = parser.parse_args()

    printScriptStart()

    thresholds = validateScriptArguments(scriptArgs)
    discoveredScopes = discoverCoverageScopes(scriptArgs.xcresultsDirectory)

    if len(discoveredScopes) <= 0:
        writeUnavailableSummaries(
            summaryFile=scriptArgs.summaryFile,
            summaryJsonFile=scriptArgs.summaryJsonFile,
            message="Code coverage unavailable because no unit test result bundles were downloaded.",
            thresholds=thresholds,
        )
        publishOutputs(
            summaryFile=scriptArgs.summaryFile,
            summaryJsonFile=scriptArgs.summaryJsonFile,
            coveragePercent="",
            scopeCount=0,
        )
        return

    scopeCoverageSummaries, combinedCoverageMap = calculateScopeCoverages(discoveredScopes)
    overallCoverage = calculateOverallCoverage(
        scopeCoverageSummaries=scopeCoverageSummaries,
        combinedCoverageMap=combinedCoverageMap,
    )

    printCoverageSummary(
        scopeCoverageSummaries=scopeCoverageSummaries,
        overallCoverage=overallCoverage,
        thresholds=thresholds,
    )

    markdownSummary = renderMarkdownSummary(
        scopeCoverageSummaries=scopeCoverageSummaries,
        overallCoverage=overallCoverage,
        thresholds=thresholds,
    )
    jsonSummary = renderJsonSummary(
        scopeCoverageSummaries=scopeCoverageSummaries,
        overallCoverage=overallCoverage,
        thresholds=thresholds,
    )

    writeTextFile(scriptArgs.summaryFile, markdownSummary)
    writeJsonFile(scriptArgs.summaryJsonFile, jsonSummary)

    publishOutputs(
        summaryFile=scriptArgs.summaryFile,
        summaryJsonFile=scriptArgs.summaryJsonFile,
        coveragePercent=determineOverallCoveragePercent(scopeCoverageSummaries, overallCoverage),
        scopeCount=len(scopeCoverageSummaries),
    )


if __name__ == "__main__":
    main()
