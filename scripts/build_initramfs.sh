#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

version="${1:?kernel version required}"
case_name="${2:-${DEFAULT_CASE}}"
root_dir="$(rootfs_case_dir "${version}" "${case_name}")"
output="$(initramfs_path "${version}" "${case_name}")"

[[ -d "${root_dir}" ]] || die "rootfs not found: ${root_dir}"

msg "packing initramfs"
(
  cd "${root_dir}"
  find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "${output}"
)

[[ -f "${output}" ]] || die "initramfs generation failed"
msg "initramfs ready: ${output}"
