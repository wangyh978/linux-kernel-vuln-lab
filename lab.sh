#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
command="${1:-help}"
version="${2:-}"
case_name="${3:-default}"

usage() {
  cat <<'EOF'
Usage:
  ./lab.sh check
  ./lab.sh fetch <kernel-version>
  ./lab.sh config <kernel-version>
  ./lab.sh kernel <kernel-version>
  ./lab.sh busybox
  ./lab.sh rootfs <kernel-version> [case]
  ./lab.sh initramfs <kernel-version> [case]
  ./lab.sh workspace <kernel-version> [case]
  ./lab.sh run <kernel-version> [case]
  ./lab.sh up <kernel-version> [case]
  ./lab.sh case <case-name>
  ./lab.sh clean <kernel-version>
EOF
}

require_version() {
  if [[ -z "${version}" ]]; then
    echo "[!] kernel version is required"
    usage
    exit 1
  fi
}

build_all() {
  echo "[+] step: check host"
  "${ROOT_DIR}/scripts/check_host.sh"
  echo "[+] step: fetch kernel"
  "${ROOT_DIR}/scripts/fetch_kernel.sh" "${version}"
  echo "[+] step: configure kernel"
  "${ROOT_DIR}/scripts/configure_kernel.sh" "${version}"
  echo "[+] step: build kernel"
  "${ROOT_DIR}/scripts/build_kernel.sh" "${version}"
  echo "[+] step: fetch busybox"
  "${ROOT_DIR}/scripts/fetch_busybox.sh"
  echo "[+] step: build busybox"
  "${ROOT_DIR}/scripts/build_busybox.sh"
  echo "[+] step: build rootfs"
  "${ROOT_DIR}/scripts/build_rootfs.sh" "${version}" "${case_name}"
  echo "[+] step: build initramfs"
  "${ROOT_DIR}/scripts/build_initramfs.sh" "${version}" "${case_name}"
}

case "${command}" in
  help|-h|--help) usage ;;
  check) "${ROOT_DIR}/scripts/check_host.sh" ;;
  fetch) require_version; "${ROOT_DIR}/scripts/fetch_kernel.sh" "${version}" ;;
  config) require_version; "${ROOT_DIR}/scripts/fetch_kernel.sh" "${version}"; "${ROOT_DIR}/scripts/configure_kernel.sh" "${version}" ;;
  kernel) require_version; "${ROOT_DIR}/scripts/fetch_kernel.sh" "${version}"; "${ROOT_DIR}/scripts/configure_kernel.sh" "${version}"; "${ROOT_DIR}/scripts/build_kernel.sh" "${version}" ;;
  busybox) "${ROOT_DIR}/scripts/fetch_busybox.sh"; "${ROOT_DIR}/scripts/build_busybox.sh" ;;
  rootfs) require_version; "${ROOT_DIR}/scripts/fetch_busybox.sh"; "${ROOT_DIR}/scripts/build_busybox.sh"; "${ROOT_DIR}/scripts/build_rootfs.sh" "${version}" "${case_name}" ;;
  initramfs) require_version; "${ROOT_DIR}/scripts/fetch_busybox.sh"; "${ROOT_DIR}/scripts/build_busybox.sh"; "${ROOT_DIR}/scripts/build_rootfs.sh" "${version}" "${case_name}"; "${ROOT_DIR}/scripts/build_initramfs.sh" "${version}" "${case_name}" ;;
  workspace) require_version; build_all; echo "[+] step: create workspace"; "${ROOT_DIR}/scripts/create_workspace.sh" "${version}" "${case_name}" ;;
  run) require_version; build_all; echo "[+] step: create workspace"; "${ROOT_DIR}/scripts/create_workspace.sh" "${version}" "${case_name}"; exec "${ROOT_DIR}/instances/linux-${version}-${case_name}/start.sh" ;;
  up) require_version; build_all; echo "[+] step: create workspace"; "${ROOT_DIR}/scripts/create_workspace.sh" "${version}" "${case_name}"; exec "${ROOT_DIR}/instances/linux-${version}-${case_name}/start.sh" ;;
  case) new_case="${2:-}"; [[ -n "${new_case}" ]] || { echo "[!] case name is required"; usage; exit 1; }; "${ROOT_DIR}/scripts/create_case.sh" "${new_case}" ;;
  clean) require_version; rm -rf "${ROOT_DIR}/work/build/linux-${version}" "${ROOT_DIR}/work/rootfs/linux-${version}" "${ROOT_DIR}/work/out/initramfs-${version}-"*.cpio.gz "${ROOT_DIR}/instances/linux-${version}-"* "${ROOT_DIR}/work/build/busybox-install"; echo "[+] cleaned build outputs for ${version}" ;;
  *) echo "[!] unknown command: ${command}"; usage; exit 1 ;;
esac
