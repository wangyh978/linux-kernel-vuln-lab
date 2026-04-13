#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/config/default.env"

WORK_DIR="${ROOT_DIR}/work"
SRC_DIR="${WORK_DIR}/src"
BUILD_DIR="${WORK_DIR}/build"
ROOTFS_DIR="${WORK_DIR}/rootfs"
OUT_DIR="${WORK_DIR}/out"
INSTANCES_DIR="${ROOT_DIR}/instances"
CASES_DIR="${ROOT_DIR}/cases"

mkdir -p "${SRC_DIR}" "${BUILD_DIR}" "${ROOTFS_DIR}" "${OUT_DIR}" "${INSTANCES_DIR}"

msg() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die() { echo "[x] $*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

nproc_safe() {
  if command -v nproc >/dev/null 2>&1; then nproc; else getconf _NPROCESSORS_ONLN; fi
}

kernel_series_dir() {
  local version="$1"
  case "${version}" in
    6.*) echo "v6.x" ;;
    5.*) echo "v5.x" ;;
    4.*) echo "v4.x" ;;
    3.*) echo "v3.x" ;;
    2.6.*) echo "v2.6" ;;
    *) die "unsupported kernel version series: ${version}" ;;
  esac
}

kernel_src_dir() { echo "${SRC_DIR}/linux-$1"; }
kernel_build_dir() { echo "${BUILD_DIR}/linux-$1"; }
kernel_image() { echo "$(kernel_build_dir "$1")/arch/x86/boot/bzImage"; }
kernel_vmlinux() { echo "$(kernel_build_dir "$1")/vmlinux"; }
busybox_src_dir() { echo "${SRC_DIR}/busybox-${DEFAULT_BUSYBOX_VERSION}"; }
busybox_install_dir() { echo "${BUILD_DIR}/busybox-install"; }
busybox_binary() { echo "$(busybox_install_dir)/bin/busybox"; }
case_overlay_dir() { echo "${CASES_DIR}/$1/overlay"; }
rootfs_case_dir() { echo "${ROOTFS_DIR}/linux-$1/$2"; }
initramfs_path() { echo "${OUT_DIR}/initramfs-$1-$2.cpio.gz"; }
workspace_dir() { echo "${INSTANCES_DIR}/linux-$1-$2"; }

copy_binary_deps() {
  local binary="$1"
  local dest_root="$2"
  local dep
  if ! ldd "${binary}" >/dev/null 2>&1; then return 0; fi
  while IFS= read -r dep; do
    [[ -z "${dep}" ]] && continue
    mkdir -p "${dest_root}$(dirname "${dep}")"
    cp -Lf "${dep}" "${dest_root}${dep}"
  done < <(ldd "${binary}" | awk '/=> \/.* / {print $3} /^\/.* / {print $1}')
}

copy_overlay() {
  local src="$1"
  local dest="$2"
  [[ -d "${src}" ]] && rsync -a "${src}/" "${dest}/"
}

download_file() {
  local url="$1"
  local dest="$2"
  local tmp="${dest}.part"
  mkdir -p "$(dirname "${dest}")"
  echo "[+] downloading: ${url}"
  if command -v wget >/dev/null 2>&1; then
    wget --continue --tries=20 --waitretry=3 --timeout=30 --progress=bar:force:noscroll --show-progress -O "${tmp}" "${url}" || die "wget download failed: ${url}"
    mv -f "${tmp}" "${dest}"
    echo "[+] download complete: ${dest}"
    return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -L --retry 20 --retry-delay 3 --retry-all-errors --connect-timeout 30 -C - --progress-bar -o "${tmp}" "${url}" || die "curl download failed: ${url}"
    mv -f "${tmp}" "${dest}"
    echo "[+] download complete: ${dest}"
    return 0
  fi
  die "no downloader found: install wget or curl"
}
