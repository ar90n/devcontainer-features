
# pico-sdk (pico-sdk)

Installs pico-sdk.

## Example Usage

```json
"features": {
    "ghcr.io/ar90n/devcontainer-features/pico-sdk:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a pico-sdk version to install | string | latest |
| installExamples | Additionally install Examples | boolean | false |
| installExtras | Additionally install Extras | boolean | false |
| installPlayground | Additionally install Playground | boolean | false |
| installPicoprobe | Additionally install Picoprobe | boolean | false |
| installPicotool | Additionally install Picotool | boolean | false |
| installOpenOCD | Additionally install OpenOCD | boolean | false |
| installDebugprobe | Additionally install Debugprobe | boolean | false |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ar90n/devcontainer-features/blob/main/src/pico-sdk/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
