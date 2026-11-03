#!/usr/bin/env bash
# Runs in the container of flatpak/Dockerfile: the source is /src (read only),
# the bundle goes to /out, owned by the user $OWNER (uid:gid).
set -euo pipefail

app=org.example.gioplayground
flatpak-builder --user --force-clean --disable-rofiles-fuse --assumeyes \
	--install-deps-from=flathub \
	--state-dir=/work/state --repo=/work/repo \
	/work/app "/src/flatpak/$app.yml"
flatpak build-bundle --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
	/work/repo /out/gioplayground.flatpak "$app"
chown "$OWNER" /out/gioplayground.flatpak
