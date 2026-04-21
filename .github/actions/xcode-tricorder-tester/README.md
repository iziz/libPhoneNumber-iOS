# Xcode Test The Tricorders

Local composite action for running `xcodebuild test` across simulator destinations selected by `simctl-tricorder-selector`.

## Inputs

- `scheme`
  - Xcode scheme to test
- `xcode_container`
  - Path to the Xcode project or workspace
  - The action infers the type from the file extension
  - Supported values end in `.xcodeproj` or `.xcworkspace`
- `destination_ids`
  - Newline-separated simulator UDIDs from `simctl-tricorder-selector`
- `simulator_jsons`
  - JSON array from `simctl-tricorder-selector`
- `result_bundle_directory`
  - Directory where `.xcresult` bundles should be created
  - Default: `TestResults`
- `destination_arch`
  - Architecture used in each `xcodebuild -destination`
  - Default: `arm64`
- `xcodebuild_extra_args`
  - Optional extra `xcodebuild` arguments

This action always runs with `-enableCodeCoverage YES` and `CODE_SIGNING_ALLOWED=NO`.

## Outputs

- `result_bundle_directory`
- `result_bundle_paths`

## Example

```yaml
- name: Pick simulator
  id: simulator
  uses: ./.github/actions/simctl-tricorder-selector
  with:
    device_types: iphone
    iphoneos_version: latest
    selection_mode: random-compatible

- name: Run unit tests
  id: tests
  uses: ./.github/actions/xcode-tricorder-tester
  with:
    scheme: libPhoneNumber
    xcode_container: libPhoneNumber.xcodeproj
    destination_ids: ${{ steps.simulator.outputs.destination_ids }}
    simulator_jsons: ${{ steps.simulator.outputs.simulator_jsons }}

- name: Upload unit test results
  uses: actions/upload-artifact@v7
  with:
    name: project-unit-tests-libPhoneNumber
    path: ${{ steps.tests.outputs.result_bundle_directory }}
```
