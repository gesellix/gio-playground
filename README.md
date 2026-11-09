# gio-playground

A small [Gio](https://gioui.org) program to try out patches to Gio, gio-x
and gogio on real devices, and to show what they change. The same program
is built with the patches (`fork/`) and with upstream as it is
(`upstream/`, which by now has some of them).

Each page of the app exercises one patch. An event log that all pages
share records what the program receives (configuration changes, URLs,
scene notifications, file results), so a test can be shown or copied
afterwards ("Event log", "Copy the log").

## Pages

| Page                                         | Patch                                                            | What to check                                                                                                                                                                                                                                                                                                                                                                             |
|----------------------------------------------|------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Clipboard: sensitive content                 | Gio: `clipboard.WriteCmd.Sensitive`                              | Android 13+: the preview shows dots. iOS: no Universal Clipboard. Windows: not in Win+V. KDE: no Klipper entry. macOS: skipped by nspasteboard.org clipboard managers.                                                                                                                                                                                                                    |
| Background: BackgroundEvent, ForegroundEvent | Gio: `app.BackgroundEvent`, `app.ForegroundEvent` (Android, iOS) | Home, app switcher, screen off: `BackgroundEvent`, then `ForegroundEvent` on return. Android document picker: `BackgroundEvent`. Notification shade, Control Center: only `Focused` changes. Android dark mode switch: no event. Android "Open a second activity" (an activity of the app without Gio): no event while it is in front, `BackgroundEvent` when the app is left from there. |
| URLs and iOS scenes                          | Gio: UIScene life cycle; gogio manifest                          | Open `gioplayground://hello` while running and after closing the app (cold start): a `URLEvent` each time. "Disconnect the scene", then reopen the app.                                                                                                                                                                                                                                   |
| Title bar colors                             | Gio: `app.DecorationColors`                                      | Where Gio draws its own title bar (Wayland under GNOME), the colors change.                                                                                                                                                                                                                                                                                                               |
| Editor.Wipe                                  | Gio: `widget.Editor.Wipe`                                        | The editor is empty and stays usable.                                                                                                                                                                                                                                                                                                                                                     |
| Files: export and save                       | gio-x: explorer                                                  | Android: export with an unknown extension works; the log shows the URI and name of the file. Desktop: `SaveFilePath`.                                                                                                                                                                                                                                                                     |
| Event log                                    |                                                                  | Everything above, newest first.                                                                                                                                                                                                                                                                                                                                                           |

The gogio patches show at build time: on iOS the log starts with whether
the Info.plist has the scene manifest, its MinimumOSVersion and whether
the app has its privacy manifest. Upstream's gogio writes the scene
manifest itself and builds for 13 without `-minsdk`; the fork's builds
take all three from the complete platform files (see [Running](#running)).
Not covered: the js build tags fix.

Where the patches are:

- Gio: [gesellix/gio-forked](https://github.com/gesellix/gio-forked),
  sent as [gio-patches 72110](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72110)
  and, after the review, as v2
  ([gio-patches 72119](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72119)).
  Upstream applied iOS 13 as the minimum, the UIScene life cycle and
  `clipboard.WriteCmd.Sensitive` (20998f2d, 2026-10-25), and the patch
  that posts the macOS/iOS wakeup to the main queue (24f37972, 2026-11-01). Config.Hidden
  (v2 2/4) is not applied: Elias preferred to report the background through
  `app.Events`, and upstream merged `app.BackgroundEvent` and
  `app.ForegroundEvent` (ff63fbb7, 2026-11-01). The X11 clipboard
  refusal ([gio-patches 72360](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72360))
  is upstream too (327752e9, 2026-11-09). DecorationColors, which Elias
  turned down in favour of no decorations of Gio's own, and Editor.Wipe
  stay in the fork. The fork's branch pwdmgr-327752e9 is upstream main
  (327752e9, 2026-11-09) plus these two.
- gio-x: [gesellix/gio-x](https://github.com/gesellix/gio-x), sent as
  [gio-patches 72104](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72104).
  The two Android patches are upstream (`ad1ee9c`, `77d3e1d`); `explorer.SaveFilePath`
  stays in the fork, on branch `explorer-save-path-rebased`.
- gogio: [gesellix/gio-cmd](https://github.com/gesellix/gio-cmd), sent as
  [gio-patches 72106](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72106)
  (`-plist`, `-privacymanifest`, `-manifest`; turned down for complete
  platform files, no longer used here). The scene manifest and iOS 13 as
  the default `-minsdk` are upstream (c57ee40, 2026-10-25). `-platformdir`
  (branch platform-dir-v4, which the fork's builds use) replaces the
  generated files with complete ones, named after their target as Elias
  suggested (Info_ios.plist, with Info.plist as the fallback), and on
  Windows with a ready resource object (rsrc_windows_<arch>.syso). It was
  sent with the lookup in the main package as the default and the flag
  optional (branch platform-dir-v5).

## Flatpak test

Does `SaveFilePath` plus a temporary file and rename work for a real Flatpak
app going through the dialog? The manifest `flatpak/` gives the app no access
to your files, so it only reaches what the dialog grants.

`scripts/flatpak.sh` builds the fork's program in Docker, installs the bundle
for this user and runs it, with the log on the terminal and in
`build/flatpak-test.log`. The host needs Docker and flatpak, not flatpak-builder
or the SDK. On the
page "Files: export and save": `SaveFilePath` for a new name and to replace a
file, cancel, "List the folder of the remembered path". Then close the app,
run `flatpak run org.example.gioplayground 2>&1 | tee -a build/flatpak-test.log`,
and "Save again to the remembered path". Remove it with `flatpak uninstall --user org.example.gioplayground`, and the
build's image and volumes with `docker rmi gioplayground-flatpak` and
`docker volume rm gioplayground-flatpak-data gioplayground-flatpak-work`.

## Linux packages

The fork's program as .deb, .rpm and AppImage, built with only bash and
Docker, for the architecture of the Docker host (amd64 or arm64):

```sh
scripts/linux.sh       # build/gioplayground-linux-<arch>
scripts/deb.sh         # build/gioplayground_2.0.0_<arch>.deb
scripts/rpm.sh         # build/gioplayground-2.0.0-1.<arch>.rpm
scripts/appimage.sh    # build/gioplayground-2.0.0-<arch>.AppImage
scripts/linux-package-test.sh deb    # or rpm, appimage, flatpak
```

The program is built on Debian 12, so it runs on Ubuntu 24.04 and Fedora 42
(it needs glibc 2.34 or later; the .deb also needs the library versions of
Debian 12, `dpkg-shlibdeps` says which). The packages build the
program first if `build/` does not have it. The test installs a package in a
clean container (`ubuntu:24.04`, for rpm `fedora:42`, for flatpak `ubuntu:24.04`
with `--privileged`), starts the program under Xvfb with `PLAYGROUND_LOG` and
passes when the log has a `FrameEvent` and the program still runs after it;
it prints what the package brought along and which graphics libraries the
program loaded.

The dependencies come from the program itself: `dpkg-shlibdeps` for the .deb
and rpmbuild (sonames) for the .rpm. Gio loads OpenGL ES (`libGLESv2.so.2`)
and Vulkan (`libvulkan.so.1`) with dlopen, which neither tool sees. Without
OpenGL ES the window ends right after its first frame ("gl: no OpenGL
implementation could be loaded"), so it is a dependency (`libgles2`,
`libglvnd-gles`); Vulkan is recommended (`libvulkan1`, `vulkan-loader`). The
AppImage bundles no libraries and relies on the system's, as a desktop has
them: `scripts/appimage.sh` says why. appimagetool and the AppImage runtime
are pinned releases, checked by sha256.

## Layout

- The root package (`playground`) is the program. It builds against
  upstream Gio and gio-x, so it cannot use an API of the patches by
  accident; the fork passes those APIs in as `playground.Features`.
- `fork/` and `upstream/` are the two programs, each a module of its own
  with its versions of Gio, gio-x and gogio (`go tool gogio`). `diag/` is
  the fork's program with a trace of the iOS driver.
- `platform/` holds the complete platform files of the fork's builds
  (`fork/` and `diag/`) as templates (`AndroidManifest.xml`, `Info_ios.plist`,
  `PrivacyInfo_ios.xcprivacy`, `Info_macos.plist`, `winres.json`): the
  scripts fill in `APP_ID`, `APP_NAME` and `URL_SCHEME` and write them to
  `build/platform/`, where gogio picks the files of its target by name.
  For Windows, `scripts/windows.sh` first makes `rsrc_windows_<arch>.syso`
  from `winres.json` with go-winres (a tool of the `fork` and `diag`
  modules).
- `packaging/linux/` has what the Linux packages need: the build image
  (`Dockerfile`, Debian 12 with Gio's build dependencies), the image of the
  .rpm (`rpm.Dockerfile`) and its spec, the desktop file and the icon, and
  `xvfb-test.sh`, which runs in the test containers.
- `scripts/` builds, installs and starts the app, and holds the checks
  (see [Checks without a person](#checks-without-a-person-ci)); the Linux
  package scripts share `scripts/linux-lib.sh`.
- `.github/workflows/ci.yml` runs the checks.

## Setup

- Go 1.27.3 or later (the go line of the go.mod files).
- Android: the Android SDK with the NDK (`ANDROID_HOME`) and `adb`.
- iOS: a Mac with Xcode and an Apple account (see [iOS setup](#ios-setup)).

```sh
cp .env-example .env   # then fill in .env, it stays out of git
```

## Running

```sh
scripts/desktop.sh                 # this computer, without an app bundle
scripts/macos.sh                   # macOS: build the .app and open it
scripts/android.sh                 # build, install (keeps data), start
scripts/android.sh log             # the app's log
scripts/ios.sh                     # build, install, start
scripts/windows.sh                 # build the .exe (copy it to Windows)
scripts/flatpak.sh                 # Linux: build and install as a Flatpak, then run it
scripts/deb.sh                     # Linux packages, built in Docker (see Linux packages)
GIO=upstream scripts/android.sh    # the same with upstream as it is
GIO=diag scripts/ios.sh            # a trace of the iOS driver, driven by URLs
scripts/ios-background-test.sh     # runs the background tests with that build
```

With `GIO=fork` (the default) and `GIO=diag` gogio gets `-platformdir`
instead of `-schemes` and `-minsdk` (on Windows it keeps `-schemes`, as
Gio registers the scheme at run time); the files in
`platform/` set the version (2.0.0, 7), the URL scheme and the minimum
version. To see that they are used as they are: on iOS the event log
shows the `CFBundleExecutable` (`<APP_NAME>Exe`), the version and the key
`PlaygroundPlatformFile`; on Android `adb shell dumpsys package <APP_ID>`
shows versionName 2.0.0, minSdk 24 and no `ALLOW_BACKUP`; on macOS the
bundle's executable is `<APP_NAME>Exe`; on Windows the properties of the
.exe (Details) show version 2.0.0.7 and the comment
`PlaygroundPlatformFile`, both from `winres.json`. gogio looks for the
files only with `-platformdir` (an opt-in while the change is tried
out).

Each script lists its commands at the top (`build`, `run`, `uninstall`,
...). Variables from the environment win over `.env`. Both builds use the
same app id, so installing one replaces the other.

URLs need an app that registers the scheme: on the desktop that is only
the macOS bundle of `scripts/macos.sh` (`open gioplayground://hello`),
not `scripts/desktop.sh`.

## Checks without a person (CI)

`.github/workflows/ci.yml` runs on every push to main and every pull
request, for each of `fork`, `diag` and `upstream` (the Linux packages for
`fork`). Each check is a script
that also runs locally:

| Check | Script | What it shows |
|---|---|---|
| Format, vet, tests, tidy, shellcheck, actionlint | (in the workflow) | |
| The platform files in the package | `scripts/check-build.sh FILE GIO` | `.apk`, `.exe`, macOS and iOS `.app`: version 2.0.0, `PlaygroundPlatformFile`, backup, second activity, privacy manifest, MinimumOSVersion (fork and diag) or gogio's own (upstream) |
| Android in the emulator | `scripts/android.sh smoke` | start up to a frame, a URL, the backup flag (`dumpsys package`) |
| Windows | `scripts/windows.sh smoke` (on Windows, Git Bash) | start up to a frame, a URL that a second process hands to the window |
| macOS | `scripts/macos.sh smoke` | the bundle, start up to a frame, a URL |
| iOS simulator | `scripts/ios.sh simulator` | an unsigned simulator build (x86_64, so an Intel runner): the Info.plist lines of the log (scene manifest, MinimumOSVersion, privacy manifest), the scene connecting; no URL, as iOS asks before it opens one from `simctl openurl` |
| X11 clipboard | `scripts/x11-clipboard-check.sh` | under Xvfb with xclip: TARGETS, the text, the hint on a sensitive copy only, and a type that is not offered: refused at once |
| Wayland | `scripts/wayland-check.sh` | under Mutter, GNOME's compositor, headless: Wayland view, configuration, frame |
| Linux packages | `scripts/deb.sh`, `rpm.sh`, `appimage.sh`, `flatpak.sh build`, then `scripts/linux-package-test.sh KIND` | each installed alone in a clean container (Ubuntu 24.04, Fedora 42), started under Xvfb up to a frame (see [Linux packages](#linux-packages)) |

The program helps with two variables of the environment (see `Run` in
`run.go`): `PLAYGROUND_LOG` writes the event log to a file (`1`:
`Documents/playground.log`, the app's own on iOS), and `PLAYGROUND_COPY`
(`sensitive` or `plain`) copies with the first frame. `scripts/check-log.sh`
waits for the lines a check expects. The two Linux checks run themselves in
Docker on a host that is not Linux (`rerun_in_docker` in `scripts/lib.sh`).

## iOS setup

Xcode has to be installed: gogio takes the iOS SDK, clang, `actool` and
`lipo` from it, and the scripts install and start the app with
`devicectl`. Its user interface is needed only for a few steps, marked
"(Xcode UI)" below.

### 1. Xcode

1. Install Xcode from the App Store or from
   [developer.apple.com/download](https://developer.apple.com/download/applications/).
2. Select it, if the Command Line Tools are selected so far
   (`xcode-select -p` does not print a path inside `Xcode.app`):
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Accept the license and install the extra packages:
   `sudo xcodebuild -license accept`, then `xcodebuild -runFirstLaunch`.
4. Download the iOS platform, which Xcode no longer ships with:
   `xcodebuild -downloadPlatform iOS`.
5. Check: `xcrun --sdk iphoneos --show-sdk-path` prints the path of the SDK.

### 2. Apple account

Pick one of the two. Either way `APP_ID` has to be a bundle id of your
own (the one in `.env-example` is only an example); it cannot be changed
for an existing profile.

#### 2a. Free Apple account (Personal Team)

Xcode, Settings, Accounts, "+", Apple Account (Xcode UI). The team shows
up as "Your Name (Personal Team)". Its limits: profiles last 7 days, at
most 3 devices, explicit app ids only (no wildcards), and only a few new
app ids per week.

#### 2b. Apple Developer Program (paid)

Profiles and certificates last a year, and you can make them without
Xcode (step 4b). You need:

- The team id: [developer.apple.com/account](https://developer.apple.com/account),
  Membership details.
- Optional, for creating profiles from the command line: an App Store
  Connect API key. [appstoreconnect.apple.com](https://appstoreconnect.apple.com),
  Users and Access, Integrations, App Store Connect API, Team Keys
  (the first time, the Account Holder has to request access there).
  "Generate API Key" with:
  - a name, e.g. "gio-playground signing",
  - access "Admin": the lower roles may not create certificates and
    profiles.

  Then note the Key ID (in the list of keys) and the Issuer ID (above
  the list), and download the key, `AuthKey_<KEY_ID>.p8`. It can be
  downloaded only once; keep it outside the repository, e.g. in
  `~/.appstoreconnect/private_keys/`. No script uses the key yet; see
  step 4b for what it can do.

Instead of the key you can also add the account in Xcode as in 2a and
make the profile as in 4a; it then lasts a year as well.

### 3. iPhone

1. Connect the iPhone by cable, unlock it and confirm "Trust This
   Computer" with the passcode.
2. `scripts/ios.sh devices` (`xcrun devicectl list devices`) lists it;
   its identifier goes into `IOS_DEVICE`. If it is not paired yet:
   `xcrun devicectl manage pair --device <identifier>`.
3. Turn on Developer Mode: on the iPhone, Settings, Privacy & Security,
   Developer Mode; the iPhone restarts and asks once more. iOS shows this
   switch only after the iPhone was connected to a Mac with Xcode. If it
   is missing, open Window, Devices and Simulators in Xcode once while
   the iPhone is connected (Xcode UI).
4. Only for 2b with a profile made by hand: register the device at
   [developer.apple.com/account/resources/devices](https://developer.apple.com/account/resources/devices/list)
   with its UDID, which `xcrun devicectl device info details --device <identifier>`
   prints.

### 4. Certificate and provisioning profile

#### 4a. With Xcode (2a, or 2b with the account in Xcode)

1. Create an empty iOS app project in Xcode with the bundle id of
   `APP_ID` (Build Settings, Product Bundle Identifier), set up the
   signing with your team ("Set Up Signing…" in Xcode 27.1) and run it
   once on the iPhone (Xcode UI). That creates the development
   certificate and the provisioning profile.
2. `scripts/ios.sh profiles` lists the profiles with their app ids; put
   the path of the one for `APP_ID` into `IOS_SIGNKEY`.

With a Personal Team, repeat this every 7 days (running the project once
more renews the profile).

#### 4b. In the developer portal (2b)

At [developer.apple.com/account/resources](https://developer.apple.com/account/resources/):

1. Identifiers, "+", App IDs, App: an explicit bundle id, the value of
   `APP_ID`. No capabilities are needed.
2. Certificates, "+", Apple Development. The portal asks for a
   certificate signing request: in Keychain Access, Certificate
   Assistant, "Request a Certificate From a Certificate Authority",
   saved to disk. Download the certificate and open it; it lands in the
   login keychain next to its private key.
   `security find-identity -v -p codesigning` then lists an "Apple
   Development: ..." identity. If it is listed as not trusted, the Apple
   intermediate certificate is missing
   ([apple.com/certificateauthority](https://www.apple.com/certificateauthority/),
   "Worldwide Developer Relations").
3. Profiles, "+", iOS App Development: the app id, the certificate and
   the devices. Download the `.mobileprovision` and put its path into
   `IOS_SIGNKEY`.

A new device: register it (step 3.4), add it to the profile (Profiles,
Edit) and download the profile again.

With the API key, `xcodebuild` does all three steps for any Xcode project
with automatic signing, e.g. the empty one of 4a:

```sh
xcodebuild -project Empty.xcodeproj -destination id=<identifier> \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 \
  -authenticationKeyID <KEY_ID> -authenticationKeyIssuerID <ISSUER_ID> \
  DEVELOPMENT_TEAM=<TEAM_ID> PRODUCT_BUNDLE_IDENTIFIER=<APP_ID> build
```

The profile then shows up in `scripts/ios.sh profiles`.

### 5. Build and run

1. In `.env`: `APP_ID`, `IOS_SIGNKEY` and `IOS_DEVICE`.
2. `scripts/ios.sh`. With a Personal Team iOS asks once to trust the
   developer: on the iPhone, Settings, General, VPN & Device Management.

### Notes

About gogio on current Xcode versions, handled by the scripts:

- Newer Xcode versions keep the profiles in
  `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`, while
  gogio only searches `~/Library/MobileDevice/Provisioning Profiles/`
  without `-signkey`. The scripts always pass `-signkey`.

Without `-minsdk`, gogio builds for iOS 13; the scripts pass `-minsdk`
only when `IOS_MINSDK` is set. Before c57ee40, upstream gogio built for
iOS 10, which the current SDKs can no longer link (no libarclite), and
without the scene manifest an app built with the iOS 27 SDK closed right
after launch (TN3187); both are fixed upstream now.
