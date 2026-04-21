# Simctl Pick A Tricorder

Local composite action for choosing an installed simulator device from `xcrun simctl list devices --json`.

## Inputs

- `device_types`
  - Ordered, comma-separated list of device types to return simulators for.
  - Supported values: `iphone`, `ipad`, `macos`, `watch`, `vision`
- `selection_mode`
  - `random-compatible`
  - `random-latest-compatible`
  - `model-type`
  - `latest-model`
- `model_preferences`
  - Semicolon-separated mappings such as `iphone=Pro Max;ipad=Pro;watch=Ultra`
- `iphoneos_version`, `ipados_version`, `macos_version`, `watchos_version`, `visionos_version`
  - A specific version like `18`, `18.2`, `15.0`
  - Or `latest`

`device_types` is required. The action returns exactly one simulator destination per requested device type, in the same order the device types were specified. If any requested device type cannot be satisfied, the action fails.

## Outputs

- `simulator_jsons`
- `destination_ids`

`simulator_jsons` returns one object per found simulator with:
- `udid`
- `name`
- `os`
- `modelType`
- `safe_name`

## Example

```yaml
- name: Pick simulator
  id: simulator
  uses: ./.github/actions/simctl-tricorder-selector
  with:
    device_types: iphone,ipad
    iphoneos_version: latest
    ipados_version: latest
    selection_mode: random-latest-compatible

- name: Run tests
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
