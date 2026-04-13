#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

need_cmd tar
need_cmd bzip2

archive="busybox-${DEFAULT_BUSYBOX_VERSION}.tar.bz2"
url="https://busybox.net/downloads/${archive}"
archive_path="${SRC_DIR}/${archive}"
src_dir="$(busybox_src_dir)"

if [[ -d "${src_dir}" ]]; then
  msg "busybox source already exists: ${src_dir}"
  exit 0
fi

if [[ ! -f "${archive_path}" ]]; then
  msg "downloading busybox ${DEFAULT_BUSYBOX_VERSION}"
  download_file "${url}" "${archive_path}"
else
  msg "using cached archive ${archive_path}"
fi

msg "extracting ${archive}"
tar -C "${SRC_DIR}" -xf "${archive_path}"
[[ -d "${src_dir}" ]] || die "busybox extraction failed: ${src_dir} not found"
msg "busybox source ready: ${src_dir}"
