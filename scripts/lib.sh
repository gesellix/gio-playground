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
fork | upstream) ;;
*)
	echo "GIO is fork or upstream, not $GIO" >&2
	exit 2
	;;
esac

# The module of the build: fork (with the patches) or upstream.
moddir=$root/$GIO
mkdir -p "$root/build"

# gogio runs as a tool of the module, so each build gets its own gogio:
# the fork's with -plist, -manifest and -privacymanifest, or upstream's.
gogio() { (cd "$moddir" && go tool gogio "$@"); }

# ldflags passes the gogio flags of the build (a comma separated list) and
# the URL scheme to the program, which shows them.
ldflags() {
	local p=github.com/gesellix/gio-playground
	echo "-X $p.buildFlags=$1 -X $p.urlScheme=$URL_SCHEME"
}
