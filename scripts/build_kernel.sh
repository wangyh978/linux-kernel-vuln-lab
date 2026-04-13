#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

version="${1:?kernel version required}"
src_dir="$(kernel_src_dir "${version}")"
build_dir="$(kernel_build_dir "${version}")"
jobs="${JOBS:-$(nproc_safe)}"

[[ -d "${src_dir}" ]] || die "kernel source not found: ${src_dir}"
[[ -f "${build_dir}/.config" ]] || die "kernel config missing: ${build_dir}/.config"

msg "building kernel ${version} with ${jobs} jobs"
make -C "${src_dir}" O="${build_dir}" -j"${jobs}" bzImage vmlinux

[[ -f "$(kernel_image "${version}")" ]] || die "bzImage build failed"
[[ -f "$(kernel_vmlinux "${version}")" ]] || die "vmlinux build failed"
msg "kernel build complete"
