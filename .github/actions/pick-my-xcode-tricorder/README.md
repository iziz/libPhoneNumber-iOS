# Pick My Xcode Tricorder

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
  uses: ./.github/actions/pick-my-xcode-tricorder
  with:
    device_types: iphone,ipad
    iphoneos_version: latest
    ipados_version: latest
    selection_mode: random-latest-compatible

- name: Run tests
  env:
    DESTINATION_IDS: ${{ steps.simulator.outputs.destination_ids }}
    SIMULATOR_JSONS: ${{ steps.simulator.outputs.simulator_jsons }}
  run: |
    python3 -c '
    import json
    import os

    destination_ids = [
      value.strip()
      for value in os.environ["DESTINATION_IDS"].splitlines()
      if value.strip()
    ]
    simulators = json.loads(os.environ["SIMULATOR_JSONS"])

    for index, destination_id in enumerate(destination_ids):
      simulator = simulators[index]
      destination = f"id={destination_id},arch=arm64"
      safe_name = simulator["safe_name"]
      print(f"Run against {simulator['name']} ({simulator['os']})")
      print(f"Use safe result-bundle name: {safe_name}")
      print(f"xcodebuild -destination {destination} test")
    '
```
