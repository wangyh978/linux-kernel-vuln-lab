#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

version="${1:?kernel version required}"
case_name="${2:-${DEFAULT_CASE}}"
overlay_dir="$(case_overlay_dir "${case_name}")"
dest_root="$(rootfs_case_dir "${version}" "${case_name}")"
busybox_install="$(busybox_install_dir)"
busybox_bin="$(busybox_binary)"

[[ -d "${overlay_dir}" ]] || die "case overlay not found: ${overlay_dir}"
[[ -f "${busybox_bin}" ]] || die "busybox binary not found: ${busybox_bin}"

msg "creating rootfs for ${version}/${case_name}"
rm -rf "${dest_root}"
mkdir -p "${dest_root}"

mkdir -p "${dest_root}/proc" "${dest_root}/sys" "${dest_root}/dev" "${dest_root}/dev/pts" "${dest_root}/tmp" "${dest_root}/run" "${dest_root}/root" "${dest_root}/etc"

rsync -a "${busybox_install}/" "${dest_root}/"

cat > "${dest_root}/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

cat > "${dest_root}/etc/group" <<'EOF'
root:x:0:
EOF

cat > "${dest_root}/etc/hostname" <<'EOF'
kernel-lab
EOF

copy_binary_deps "${busybox_bin}" "${dest_root}"
copy_overlay "${overlay_dir}" "${dest_root}"

chmod +x "${dest_root}/init"
[[ -f "${dest_root}/root/repro.sh" ]] && chmod +x "${dest_root}/root/repro.sh"

msg "rootfs ready: ${dest_root}"
