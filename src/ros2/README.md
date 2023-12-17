
# ROS2 (ros2)

Installs ROS2.

## Example Usage

```json
"features": {
    "ghcr.io/ar90n/devcontainer-features/ros2:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| distro | Select or enter a ROS2 distro to install | string | humble |
| package | Select or enter a ROS2 package to install | string | desktop |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ar90n/devcontainer-features/blob/main/src/ros2/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
