# check=skip=InvalidDefaultArgInFrom
# Builds the Linux program and packages it as .deb and AppImage, so that the
# host needs only Docker: see scripts/linux.sh. Debian 12 (glibc 2.36), so that
# the program also runs on older systems than the ones of the tests (Ubuntu
# 24.04, Fedora 42). GO_VERSION is the go line of go.mod.
ARG GO_VERSION
FROM golang:${GO_VERSION}-bookworm
# Gio's build dependencies (gioui.org/doc/install/linux), dpkg-shlibdeps for
# the dependencies of the .deb, and file for appimagetool.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		gcc pkg-config dpkg-dev file \
		libwayland-dev libx11-dev libx11-xcb-dev libxkbcommon-x11-dev \
		libgles2-mesa-dev libegl1-mesa-dev libffi-dev libxcursor-dev libvulkan-dev \
	&& rm -rf /var/lib/apt/lists/*
