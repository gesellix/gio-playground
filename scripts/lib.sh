# Shared by the scripts (sourced, not run): loads .env and picks the build.
#
# Variables from the environment win over .env, so a single run can change
# one, for example: GIO=upstream scripts/ios.sh

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# .env has KEY=VALUE lines; # starts a comment line, empty values are
# skipped, a leading ~ is the home directory.
if [ -f "$root/.env" ]; then
	while IFS= read -r line || [ -n "$line" ]; do
		case $line in '' | '#'*) continue ;; esac
		key=${line%%=*}
		val=${line#*=}
		val=${val%\"}
		val=${val#\"}
		val=${val/#\~/$HOME}
		if [ -n "$val" ] && [ -z "${!key+x}" ]; then
			export "$key=$val"
		fi
	done <"$root/.env"
fi

: "${GIO:=fork}"
: "${APP_ID:=org.example.gioplayground}"
: "${APP_NAME:=GioPlayground}"
: "${URL_SCHEME:=gioplayground}"

case $GIO in
fork | upstream | platformdir) ;;
*)
	echo "GIO is fork, upstream or platformdir, not $GIO" >&2
	exit 2
	;;
esac

# The module of the build: fork (with the patches), upstream, or
# platformdir (the fork's Gio, with the gogio of -platformdir).
moddir=$root/$GIO
mkdir -p "$root/build"

# gogio runs as a tool of the module, so each build gets its own gogio:
# the fork's with -plist, -manifest and -privacymanifest, upstream's, or
# the one with -platformdir.
gogio() { (cd "$moddir" && go tool gogio "$@"); }

# platformdir writes the complete platform files of platform/<target>/ to
# build/platform/<target>/, with the values of .env, and prints the
# directory to pass to gogio -platformdir.
platformdir() {
	local target=$1 dir=$root/build/platform
	rm -rf "${dir:?}/$target"
	mkdir -p "$dir/$target"
	local f
	for f in "$root/platform/$target"/*; do
		sed -e "s|@APP_ID@|$APP_ID|g" -e "s|@APP_NAME@|$APP_NAME|g" -e "s|@URL_SCHEME@|$URL_SCHEME|g" "$f" >"$dir/$target/$(basename "$f")"
	done
	echo "$dir"
}

# ldflags passes the gogio flags of the build (a comma separated list) and
# the URL scheme to the program, which shows them.
ldflags() {
	local p=github.com/gesellix/gio-playground
	echo "-X $p.buildFlags=$1 -X $p.urlScheme=$URL_SCHEME"
}
