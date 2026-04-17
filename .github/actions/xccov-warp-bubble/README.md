# Xccov Warp Bubble

Local composite action for generating a code coverage summary from downloaded `.xcresult` bundles.

## Inputs

- `xcresults_directory`
  - Root directory containing downloaded artifact folders with `.xcresult` bundles
  - Default: `CoverageResults/xcresults`
- `summary_file`
  - Markdown file path where the coverage summary should be written
  - Default: `CoverageResults/code-coverage-summary.md`
- `summary_json_file`
  - JSON file path where the coverage summary should be written
  - Default: `CoverageResults/code-coverage-summary.json`
- `failing_coverage_threshold`
  - Coverage percent below which the status is marked with a red X
  - Default: `60`
- `passing_coverage_threshold`
  - Coverage percent at or above which the status is marked with a green checkmark
  - Default: `75`

If only one coverage scope is found, the action reports coverage for that scope only. If multiple scopes are found, the action also computes and reports combined coverage across all scopes.

## Outputs

- `coverage_percent`
- `summary_file`
- `summary_json_file`
- `scope_count`

## Example

```yaml
- name: Download unit test results
  uses: actions/download-artifact@v7
  with:
    pattern: project-unit-tests-*
    path: CoverageResults/xcresults

- name: Generate code coverage summary
  id: coverage
  uses: ./.github/actions/xccov-warp-bubble
  with:
    xcresults_directory: CoverageResults/xcresults
    summary_file: CoverageResults/code-coverage-summary.md
    summary_json_file: CoverageResults/code-coverage-summary.json

- name: Publish coverage comment to pull request
  uses: marocchino/sticky-pull-request-comment@v2
  with:
    header: combined-code-coverage
    path: ${{ steps.coverage.outputs.summary_file }}
```
