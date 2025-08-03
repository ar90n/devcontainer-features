
# xPack Dev Tools (xpack-dev-tools)

Installs xPack development tools including compilers, build tools, and debugging utilities.

## Example Usage

```json
"features": {
    "ghcr.io/ar90n/devcontainer-features/xpack-dev-tools:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installPath | Base installation path for xPack tools | string | /opt/xpack |
| armNoneEabiGcc | ARM Cortex-M & Cortex-R GCC toolchain version. Empty string skips installation. | string | - |
| aarch64NoneElfGcc | ARM AArch64 bare-metal GCC toolchain version. Empty string skips installation. | string | - |
| riscvNoneElfGcc | RISC-V bare-metal GCC toolchain version. Empty string skips installation. | string | - |
| gcc | Native GCC compiler version. Empty string skips installation. | string | - |
| clang | LLVM clang/clang++ compiler version. Empty string skips installation. | string | - |
| cmake | CMake build system version. Empty string skips installation. | string | - |
| mesonBuild | Meson build system version. Empty string skips installation. | string | - |
| ninjaBuild | Ninja build tool version. Empty string skips installation. | string | - |
| pkgConfig | pkg-config tool version. Empty string skips installation. | string | - |
| openocd | OpenOCD debugging tool version. Empty string skips installation. | string | - |
| qemuArm | QEMU ARM emulator version. Empty string skips installation. | string | - |
| qemuRiscv | QEMU RISC-V emulator version. Empty string skips installation. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ar90n/devcontainer-features/blob/main/src/xpack-dev-tools/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
