# The .rpm of the Linux program: scripts/rpm.sh passes the version, the app
# id and the directory with the files (srcdir), which go in as they are.
Name:           gioplayground
Version:        %{pkgversion}
Release:        1
Summary:        Tries out patches to Gio, gio-x and gogio
License:        MIT
URL:            https://github.com/gesellix/gio-playground
# rpmbuild adds a Requires for each shared library the program links (by
# soname). Gio loads OpenGL ES and Vulkan with dlopen, which rpmbuild does not
# see: OpenGL ES (libGLESv2.so.2) is what Gio draws with when Vulkan is not
# there, so it is required, and Vulkan (libvulkan.so.1) is recommended.
Requires:       libglvnd-gles%{?_isa}
Recommends:     vulkan-loader%{?_isa}

# A Go program, built outside of rpmbuild: no debuginfo package.
%global debug_package %{nil}
%global _build_id_links none

%description
A small Gio program to try out patches to Gio, gio-x and gogio, and to show
what they change. An event log records what the program receives.

%install
install -D -m 755 %{srcdir}/gioplayground %{buildroot}%{_bindir}/gioplayground
install -D -m 644 %{srcdir}/%{appid}.desktop %{buildroot}%{_datadir}/applications/%{appid}.desktop
install -D -m 644 %{srcdir}/%{appid}.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/%{appid}.png

%files
%{_bindir}/gioplayground
%{_datadir}/applications/%{appid}.desktop
%{_datadir}/icons/hicolor/256x256/apps/%{appid}.png

%changelog
* Sat Nov 07 2026 Tobias Gesellchen <tobias@gesellix.de> - 2.0.0-1
- The playground as an .rpm.
