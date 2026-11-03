# Builds the Flatpak bundle, so that the host needs neither flatpak-builder nor
# the SDK: see scripts/flatpak.sh.
FROM ubuntu:24.04
RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates elfutils flatpak flatpak-builder \
	&& rm -rf /var/lib/apt/lists/*
RUN flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
COPY build-bundle.sh /usr/local/bin/build-bundle
