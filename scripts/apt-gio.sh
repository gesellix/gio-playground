#!/usr/bin/env bash
# Installs Gio's build packages on Debian or Ubuntu (the CI runner), plus
# the packages given as arguments: scripts/apt-gio.sh [PACKAGE...]
# https://gioui.org/doc/install/linux
set -euo pipefail

sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends gcc pkg-config \
	libwayland-dev libx11-dev libx11-xcb-dev libxkbcommon-x11-dev \
	libgles2-mesa-dev libegl1-mesa-dev libffi-dev libxcursor-dev libvulkan-dev \
	"$@"
