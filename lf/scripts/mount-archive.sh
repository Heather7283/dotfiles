#!/usr/bin/env bash

export _script_name="mount-archive"

# shellcheck source=/home/heather/.config/lf/scripts/common-defs.sh
source ~/.config/lf/scripts/common-defs.sh

archive="$(realpath "$f")"
if [ -z "$archive" ]; then die "no filename provided"; fi
if [ -d "$archive" ]; then die "not mounting directory"; fi

if [[ "$archive" = $_lf_client_data_dir* ]]; then
  die "nested mounts are not supported";
fi

archive_dirname="$(dirname "$archive")"

mountpoint="$(mktmpdir)"
mountpoint="${mountpoint//\/\//\/}" # replace // with /
if [ -z "$mountpoint" ]; then die "couldn't create mountpoint"; fi

mountpoint_dirname="${mountpoint%/*}"

if [ ! -d ~/.cache/ratarmount/ ]; then
  mkdir -p ~/.cache/ratarmount/ || die "couldn't create cache dir";
fi

# NOTE: read-only mount
# surely recursive mount won't cause problems :clueless:
stderr_wrapper ratarmount \
  --recursive \
  --lazy \
  --parallelization "$(( $(nproc) / 2))" \
  --index-folders ~/.cache/ratarmount/ \
  -o 'ro' \
  "$archive" \
  "$mountpoint" || die "unable to mount archive"

lf -remote "send $id cd $mountpoint"

# check if after cd we are not under mountpoint anymore
# if so, unmount archive, remove mountpoint and delete hook
on_cd_hook="$(
cat <<EOF
if [[ ! "\${PWD}" =~ ^${mountpoint} ]]; then \
    if [ "\${PWD}" = "${mountpoint_dirname}" ]; then \
        lf -remote "send \${id} select ${archive}"; \
    fi; \
    umount "${mountpoint}" && rmdir "${mountpoint}"; \
    lf -remote "send \${id} cmd on-cd"; \
fi
EOF
)"

lf -remote "send ${id} cmd on-cd &${on_cd_hook}"

