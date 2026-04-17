# Xcode Test The Tricorders

Local composite action for running `xcodebuild test` across simulator destinations selected by `simctl-pick-a-tricorder`.

## Inputs

- `scheme`
  - Xcode scheme to test
- `xcode_container`
  - Path to the Xcode project or workspace
  - The action infers the type from the file extension
  - Supported values end in `.xcodeproj` or `.xcworkspace`
- `destination_ids`
  - Newline-separated simulator UDIDs from `simctl-pick-a-tricorder`
- `simulator_jsons`
  - JSON array from `simctl-pick-a-tricorder`
- `result_bundle_directory`
  - Directory where `.xcresult` bundles should be created
  - Default: `TestResults`
- `destination_arch`
  - Architecture used in each `xcodebuild -destination`
  - Default: `arm64`
- `enable_code_coverage`
  - Value passed to `-enableCodeCoverage`
  - Default: `YES`
- `code_signing_allowed`
  - Value passed through `CODE_SIGNING_ALLOWED`
  - Default: `NO`
- `xcodebuild_extra_args`
  - Optional extra `xcodebuild` arguments

## Outputs

- `result_bundle_directory`
- `result_bundle_paths`

## Example

```yaml
- name: Pick simulator
  id: simulator
  uses: ./.github/actions/simctl-pick-a-tricorder
  with:
    device_types: iphone
    iphoneos_version: latest
    selection_mode: random-compatible

- name: Run unit tests
  id: tests
  uses: ./.github/actions/xcode-test-the-tricorders
  with:
    scheme: libPhoneNumber
    xcode_container: libPhoneNumber.xcodeproj
    destination_ids: ${{ steps.simulator.outputs.destination_ids }}
    simulator_jsons: ${{ steps.simulator.outputs.simulator_jsons }}

- name: Upload unit test results
  uses: actions/upload-artifact@v6
  with:
    name: project-unit-tests-libPhoneNumber
    path: ${{ steps.tests.outputs.result_bundle_directory }}
```
