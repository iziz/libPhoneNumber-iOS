#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#  generate_coverage_summary.py
#  xccov-warp-bubble
#
#  Created by Kodex on 4/17/26.
#
# This script reads downloaded xcresult bundles, calculates per-scope coverage,
# optionally calculates combined coverage across multiple scopes, prints the
# results to the GitHub Actions log, and writes a markdown coverage summary file.

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass


SCRIPT_VERSION: str = "0.1.0"
"""The current version of the script"""


XCRESULT_SUFFIX: str = ".xcresult"
"""The filesystem suffix used for Xcode result bundles"""


DEFAULT_SCOPE_PREFIXES_TO_TRIM: tuple[str, ...] = ("project-unit-tests-",)
"""Common artifact name prefixes that should be trimmed from scope labels"""


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


def validateScriptArguments(scriptArgs: argparse.Namespace) -> tuple[float, float]:
    """
    Validates the parsed script arguments

    Parameters
    ----------
    scriptArgs
        The parsed script arguments

    Returns
    -------
    tuple[float, float]
        The parsed failing and passing coverage thresholds
    """

    if len(scriptArgs.xcresultsDirectory.strip()) <= 0:
        raise ValueError("An xcresults directory must be provided")

    if len(scriptArgs.summaryFile.strip()) <= 0:
        raise ValueError("A summary file path must be provided")

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

    return (failingCoverageThreshold, passingCoverageThreshold)


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


def determineScopeBundles(searchRoot: str) -> dict[str, list[str]]:
    """
    Determines the downloaded coverage scopes and their xcresult bundles

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
        scopeBundles[normalizeScopeName(os.path.basename(os.path.normpath(searchRoot)) or "Coverage")] = rootResultBundles

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


def determineStatusEmoji(coveragePercent: float,
                         failingCoverageThreshold: float,
                         passingCoverageThreshold: float) -> str:
    """
    Determines the coverage status emoji for a coverage percent

    Parameters
    ----------
    coveragePercent
        The coverage percent to evaluate
    failingCoverageThreshold
        The failing coverage threshold
    passingCoverageThreshold
        The passing coverage threshold

    Returns
    -------
    str
        The status emoji
    """

    if coveragePercent < failingCoverageThreshold:
        return "❌"
    if coveragePercent < passingCoverageThreshold:
        return "⚠️"
    return "✅"


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


def publishOutputs(summaryFile: str, coveragePercent: str, scopeCount: int):
    """
    Publishes the generated coverage summary outputs for GitHub Actions

    Parameters
    ----------
    summaryFile
        The markdown summary file path
    coveragePercent
        The overall coverage percent string
    scopeCount
        The number of summarized scopes
    """

    writeGithubOutput("summary_file", summaryFile)
    writeGithubOutput("coverage_percent", coveragePercent)
    writeGithubOutput("scope_count", str(scopeCount))


def writeUnavailableSummary(summaryFile: str, message: str):
    """
    Writes a markdown summary file for an unavailable coverage result

    Parameters
    ----------
    summaryFile
        The markdown summary file path
    message
        The message to write
    """

    summaryDirectory = os.path.dirname(summaryFile)
    if len(summaryDirectory) > 0:
        os.makedirs(summaryDirectory, exist_ok=True)

    with open(summaryFile, "w", encoding="utf-8") as file:
        print("### Code Coverage", file=file)
        print(file=file)
        print(message, file=file)


def writeSummaryFile(summaryFile: str,
                     scopeCoverageSummaries: list[ScopeCoverage],
                     overallCoverage: ScopeCoverage | None,
                     failingCoverageThreshold: float,
                     passingCoverageThreshold: float):
    """
    Writes the markdown coverage summary file

    Parameters
    ----------
    summaryFile
        The markdown summary file path
    scopeCoverageSummaries
        The per-scope coverage summaries
    overallCoverage
        The optional combined coverage summary
    failingCoverageThreshold
        The failing coverage threshold
    passingCoverageThreshold
        The passing coverage threshold
    """

    summaryDirectory = os.path.dirname(summaryFile)
    if len(summaryDirectory) > 0:
        os.makedirs(summaryDirectory, exist_ok=True)

    with open(summaryFile, "w", encoding="utf-8") as file:
        print("### Code Coverage", file=file)
        print(file=file)
        print("| Scope | Coverage | Status |", file=file)
        print("| --- | :---: | :---: |", file=file)

        for scopeCoverage in scopeCoverageSummaries:
            emoji = determineStatusEmoji(
                coveragePercent=scopeCoverage.coveragePercent,
                failingCoverageThreshold=failingCoverageThreshold,
                passingCoverageThreshold=passingCoverageThreshold,
            )
            print(
                f"| {scopeCoverage.name} | {scopeCoverage.coveragePercent:.2f}% | {emoji} |",
                file=file,
            )

        if overallCoverage is not None:
            combinedEmoji = determineStatusEmoji(
                coveragePercent=overallCoverage.coveragePercent,
                failingCoverageThreshold=failingCoverageThreshold,
                passingCoverageThreshold=passingCoverageThreshold,
            )
            indent = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
            print(
                f"| {indent} **Combined** | **{overallCoverage.coveragePercent:.2f}%** | **{combinedEmoji}** |",
                file=file,
            )


def main():
    """Runs the coverage summary generation script"""

    parser = setupArgumentParser()
    scriptArgs = parser.parse_args()

    printScriptStart()

    failingCoverageThreshold, passingCoverageThreshold = validateScriptArguments(scriptArgs)
    scopeBundles = determineScopeBundles(scriptArgs.xcresultsDirectory)

    if len(scopeBundles) <= 0:
        writeUnavailableSummary(
            scriptArgs.summaryFile,
            "Code coverage unavailable because no unit test result bundles were downloaded.",
        )
        publishOutputs(
            summaryFile=scriptArgs.summaryFile,
            coveragePercent="",
            scopeCount=0,
        )
        return

    combinedCoverageMap: dict[str, dict[int, bool]] = {}
    scopeCoverageSummaries: list[ScopeCoverage] = []

    for scopeName, resultBundles in sorted(scopeBundles.items()):
        scopeCoverageMap: dict[str, dict[int, bool]] = {}

        for resultBundle in resultBundles:
            print(f"Processing result bundle for {scopeName}: {resultBundle}")
            report = readCoverageReport(resultBundle)
            mergeCoverageReport(scopeCoverageMap, report)
            mergeCoverageReport(combinedCoverageMap, report)

        coveredLines, executableLines, coveragePercent = summarizeLineCoverage(scopeCoverageMap)
        scopeCoverage = ScopeCoverage(
            name=scopeName,
            coveredLines=coveredLines,
            executableLines=executableLines,
            coveragePercent=coveragePercent,
        )
        scopeCoverageSummaries.append(scopeCoverage)
        print(
            f"{scopeCoverage.name} - {scopeCoverage.coveragePercent:.2f}% "
            f"{determineStatusEmoji(scopeCoverage.coveragePercent, failingCoverageThreshold, passingCoverageThreshold)}"
        )

    overallCoverage: ScopeCoverage | None = None
    overallCoveragePercent = ""

    if len(scopeCoverageSummaries) == 1:
        overallCoveragePercent = f"{scopeCoverageSummaries[0].coveragePercent:.2f}"
    else:
        coveredLines, executableLines, coveragePercent = summarizeLineCoverage(combinedCoverageMap)
        overallCoverage = ScopeCoverage(
            name="Combined",
            coveredLines=coveredLines,
            executableLines=executableLines,
            coveragePercent=coveragePercent,
        )
        overallCoveragePercent = f"{overallCoverage.coveragePercent:.2f}"
        print(
            f"Combined - {overallCoverage.coveragePercent:.2f}% "
            f"{determineStatusEmoji(overallCoverage.coveragePercent, failingCoverageThreshold, passingCoverageThreshold)}"
        )

    writeSummaryFile(
        summaryFile=scriptArgs.summaryFile,
        scopeCoverageSummaries=scopeCoverageSummaries,
        overallCoverage=overallCoverage,
        failingCoverageThreshold=failingCoverageThreshold,
        passingCoverageThreshold=passingCoverageThreshold,
    )
    publishOutputs(
        summaryFile=scriptArgs.summaryFile,
        coveragePercent=overallCoveragePercent,
        scopeCount=len(scopeCoverageSummaries),
    )


if __name__ == "__main__":
    main()
