#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

version="${1:?kernel version required}"
need_cmd tar
need_cmd xz

series="$(kernel_series_dir "${version}")"
archive="linux-${version}.tar.xz"
url="https://cdn.kernel.org/pub/linux/kernel/${series}/${archive}"
archive_path="${SRC_DIR}/${archive}"
src_dir="$(kernel_src_dir "${version}")"

if [[ -d "${src_dir}" ]]; then
  msg "kernel source already exists: ${src_dir}"
  exit 0
fi

if [[ ! -f "${archive_path}" ]]; then
  msg "downloading kernel ${version}"
  download_file "${url}" "${archive_path}"
else
  msg "using cached archive ${archive_path}"
fi

msg "extracting ${archive}"
tar -C "${SRC_DIR}" -xf "${archive_path}"
[[ -d "${src_dir}" ]] || die "kernel extraction failed: ${src_dir} not found"
msg "kernel source ready: ${src_dir}"
