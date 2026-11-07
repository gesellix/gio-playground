# Builds the .rpm of the Linux program: see scripts/rpm.sh. rpmbuild of
# Fedora finds the shared libraries that the program needs (their sonames)
# and declares them as Requires.
FROM fedora:42
RUN dnf install -y rpm-build && dnf clean all
