#!/usr/bin/env bash
# The playground as a real Flatpak, to test the file dialog in the sandbox.
#
#   scripts/flatpak.sh        build in Docker, install for this user and run it
#   scripts/flatpak.sh build  only build build/gioplayground.flatpak
#
# The build needs Docker (--privileged, for the sandbox of flatpak-builder). The
# bundle is for the architecture of the Docker host. Running it needs flatpak
# on the host: the dialog comes from the desktop, not from a container.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
app=org.example.gioplayground
image=gioplayground-flatpak
mode=${1:-run}

case $mode in
build | run) ;;
*)
	echo "usage: $0 [build]" >&2
	exit 2
	;;
esac
if [ "$mode" = run ] && ! command -v flatpak >/dev/null; then
	echo "flatpak is missing: sudo apt install flatpak" >&2
	exit 1
fi

mkdir -p "$root/build"
docker build -t "$image" "$root/flatpak"
# The volumes keep the SDK and the build's cache for the next run.
docker run --rm --privileged \
	-v "$root:/src:ro" -v "$root/build:/out" \
	-v "$image-data:/root/.local/share/flatpak" -v "$image-work:/work" \
	-e OWNER="$(id -u):$(id -g)" \
	"$image" build-bundle
echo "built $root/build/gioplayground.flatpak"
[ "$mode" = build ] && exit 0

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Installing the same version again is an error. The app's data stays.
flatpak uninstall --user --assumeyes "$app" 2>/dev/null || true
flatpak install --user --assumeyes --bundle "$root/build/gioplayground.flatpak"
flatpak run "$app" 2>&1 | tee -a "$root/build/flatpak-test.log"
