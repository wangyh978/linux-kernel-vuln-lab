#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

version="${1:?kernel version required}"
case_name="${2:-${DEFAULT_CASE}}"

image="$(kernel_image "${version}")"
vmlinux="$(kernel_vmlinux "${version}")"
initramfs="$(initramfs_path "${version}" "${case_name}")"
rootfs_src="$(rootfs_case_dir "${version}" "${case_name}")"
ws_dir="$(workspace_dir "${version}" "${case_name}")"

[[ -f "${image}" ]] || die "kernel image not found: ${image}"
[[ -f "${vmlinux}" ]] || die "vmlinux not found: ${vmlinux}"
[[ -f "${initramfs}" ]] || die "initramfs not found: ${initramfs}"
[[ -d "${rootfs_src}" ]] || die "rootfs not found: ${rootfs_src}"

rm -rf "${ws_dir}"
mkdir -p "${ws_dir}/logs"

cp -f "${image}" "${ws_dir}/bzImage"
cp -f "${vmlinux}" "${ws_dir}/vmlinux"
cp -f "${initramfs}" "${ws_dir}/initramfs.cpio.gz"
rsync -a "${rootfs_src}/" "${ws_dir}/rootfs/"

cat > "${ws_dir}/meta.env" <<EOF
QEMU_MEMORY=${QEMU_MEMORY}
QEMU_SMP=${QEMU_SMP}
QEMU_NET=${QEMU_NET}
QEMU_EXTRA_ARGS=${QEMU_EXTRA_ARGS}
KERNEL_CMDLINE=${KERNEL_CMDLINE}
KERNEL_VERSION=${version}
CASE_NAME=${case_name}
EOF

cat > "${ws_dir}/README.txt" <<'EOF'
Standalone runtime directory.

Run:
  ./start.sh

For debug:
  ./start-wait-gdb.sh
  ./gdb.sh
EOF

cat > "${ws_dir}/start.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "${DIR}/meta.env"

qemu_args=(
  -kernel "${DIR}/bzImage"
  -initrd "${DIR}/initramfs.cpio.gz"
  -append "${KERNEL_CMDLINE}"
  -nographic
  -m "${QEMU_MEMORY}"
  -smp "${QEMU_SMP}"
  -monitor none
  -no-reboot
)

if [[ "${QEMU_NET}" == "none" ]]; then
  qemu_args+=(-net none)
else
  qemu_args+=(-net nic -net "${QEMU_NET}")
fi

if [[ -n "${QEMU_EXTRA_ARGS}" ]]; then
  extra_args=( ${QEMU_EXTRA_ARGS} )
  qemu_args+=("${extra_args[@]}")
fi

exec qemu-system-x86_64 "${qemu_args[@]}"
EOF

cat > "${ws_dir}/start-wait-gdb.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "${DIR}/meta.env"

qemu_args=(
  -kernel "${DIR}/bzImage"
  -initrd "${DIR}/initramfs.cpio.gz"
  -append "${KERNEL_CMDLINE}"
  -nographic
  -m "${QEMU_MEMORY}"
  -smp "${QEMU_SMP}"
  -monitor none
  -no-reboot
  -s
  -S
)

if [[ "${QEMU_NET}" == "none" ]]; then
  qemu_args+=(-net none)
else
  qemu_args+=(-net nic -net "${QEMU_NET}")
fi

if [[ -n "${QEMU_EXTRA_ARGS}" ]]; then
  extra_args=( ${QEMU_EXTRA_ARGS} )
  qemu_args+=("${extra_args[@]}")
fi

exec qemu-system-x86_64 "${qemu_args[@]}"
EOF

cat > "${ws_dir}/gdb.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec gdb -ex "file ${DIR}/vmlinux" -ex "target remote :1234" -ex "lx-symbols" -ex "set pagination off"
EOF

chmod +x "${ws_dir}/start.sh" "${ws_dir}/start-wait-gdb.sh" "${ws_dir}/gdb.sh"
msg "standalone workspace ready: ${ws_dir}"
