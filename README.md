# Linux Kernel Vuln Lab Minimal BusyBox

Reusable Linux kernel vulnerability emulation framework.

This edition keeps the previous fixes and also changes BusyBox to a **minimal non-interactive configuration**.

Included fixes:

- standalone workspace output
- resilient downloads with wget resume support
- visible download progress
- fixed kernel configure bug
- fixed BusyBox `olddefconfig` bug
- replaced BusyBox `defconfig` with `allnoconfig + minimal applets`
- disabled console/keyboard applets that pull `linux/kd.h`

## Quick start

```bash
sudo apt update
sudo apt install -y   build-essential bc bison flex libelf-dev libssl-dev dwarves pahole   cpio rsync curl xz-utils tar gzip bzip2 file   qemu-system-x86 qemu-utils gdb python3 wget
```

Optional for static BusyBox:

```bash
sudo apt install -y musl-tools
```

## Usage

```bash
./scripts/repair_permissions.sh
./lab.sh up 6.6.30
```
