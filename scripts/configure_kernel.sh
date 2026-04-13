#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

version="${1:?kernel version required}"
src_dir="$(kernel_src_dir "${version}")"
build_dir="$(kernel_build_dir "${version}")"

[[ -d "${src_dir}" ]] || die "kernel source not found: ${src_dir}"
mkdir -p "${build_dir}"

msg "generating defconfig"
make -C "${src_dir}" O="${build_dir}" defconfig

config_tool="${src_dir}/scripts/config"
[[ -x "${config_tool}" ]] || die "missing config tool: ${config_tool}"

msg "enabling debug and initramfs-friendly options"
"${config_tool}" --file "${build_dir}/.config"   --enable BLK_DEV_INITRD   --enable DEVTMPFS   --enable DEVTMPFS_MOUNT   --enable TMPFS   --enable TMPFS_POSIX_ACL   --enable PROC_FS   --enable SYSFS   --enable UNIX   --enable INET   --enable KALLSYMS   --enable KALLSYMS_ALL   --enable DEBUG_INFO   --enable FRAME_POINTER   --enable DEBUG_FS   --enable GDB_SCRIPTS   --enable IKCONFIG   --enable IKCONFIG_PROC   --enable KCOV   --enable KCOV_ENABLE_COMPARISONS   --enable KASAN   --enable KASAN_GENERIC   --enable SLUB_DEBUG   --enable SLUB_DEBUG_ON   --enable PROC_KCORE   --enable BUG_ON_DATA_CORRUPTION   --disable RANDOMIZE_BASE

msg "running olddefconfig"
make -C "${src_dir}" O="${build_dir}" olddefconfig

msg "kernel config ready: ${build_dir}/.config"
