# gio-playground

A small [Gio](https://gioui.org) program to try out patches to Gio, gio-x
and gogio on real devices, and to show what they change. The same program
is built with the patches (`fork/`) and without them (`upstream/`), and a
third time with the gogio prototype of `-platformdir` (`platformdir/`).

Each page of the app exercises one patch. An event log that all pages
share records what the program receives (configuration changes, URLs,
scene notifications, file results), so a test can be shown or copied
afterwards ("Event log", "Copy the log").

## Pages

| Page                         | Patch                                   | What to check                                                                                                                                                          |
|------------------------------|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Clipboard: sensitive content | Gio: `clipboard.WriteCmd.Sensitive`     | Android 13+: the preview shows dots. iOS: no Universal Clipboard. Windows: not in Win+V. KDE: no Klipper entry. macOS: skipped by nspasteboard.org clipboard managers. |
| Background: Config.Hidden    | Gio: `app.Config.Hidden` (Android, iOS) | Home, app switcher, screen off: `Hidden=true`, then `false` on return. Notification shade, Control Center: only `Focused` changes.                                     |
| URLs and iOS scenes          | Gio: UIScene life cycle; gogio manifest | Open `gioplayground://hello` while running and after closing the app (cold start): a `URLEvent` each time. "Disconnect the scene", then reopen the app.                |
| Title bar colors             | Gio: `app.DecorationColors`             | Where Gio draws its own title bar (Wayland under GNOME), the colors change.                                                                                            |
| Editor.Wipe                  | Gio: `widget.Editor.Wipe`               | The editor is empty and stays usable.                                                                                                                                  |
| Files: export and save       | gio-x: explorer                         | Android: export with an unknown extension works; the log shows the URI and name of the file. Desktop: `SaveFilePath`.                                                  |
| Event log                    |                                         | Everything above, newest first.                                                                                                                                        |

The gogio patches show at build time: on iOS the log starts with whether
the Info.plist has the scene manifest (gogio writes it), its
MinimumOSVersion (13 without `-minsdk`) and whether the app has its
privacy manifest (`-privacymanifest`); on Android `-manifest` turns
off the app's backup (`adb shell dumpsys package <APP_ID>`: no
`ALLOW_BACKUP` among the flags). Not covered: the js build tags fix.

Where the patches are:

- Gio: [gesellix/gio-forked](https://github.com/gesellix/gio-forked),
  sent as [gio-patches 72110](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72110)
  (branch upstream-series); v2 (branch upstream-series-v2) makes iOS 13
  the minimum and the UIScene life cycle unconditional. Editor.Wipe is
  not sent yet.
- gio-x: [gesellix/gio-x](https://github.com/gesellix/gio-x), sent as
  [gio-patches 72104](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72104).
- gogio: [gesellix/gio-cmd](https://github.com/gesellix/gio-cmd), sent as
  [gio-patches 72106](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72106);
  the scene manifest and iOS 13 as the default `-minsdk` go with Gio v2
  (branch ios-scenes). `-platformdir` (branch platform-dir-v2, not sent:
  a proposal to Elias) replaces the generated AndroidManifest.xml and
  Info.plist with complete files.

## Layout

- The root package (`playground`) is the program. It builds against
  upstream Gio and gio-x, so it cannot use an API of the patches by
  accident; the fork passes those APIs in as `playground.Features`.
- `fork/` and `upstream/` are the two programs, each a module of its own
  with its versions of Gio, gio-x and gogio (`go tool gogio`).
- `ios/` and `android/` hold the files for gogio's `-privacymanifest`
  and `-manifest`.
- `platformdir/` is a third program, the fork's with the gogio of
  `-platformdir`, and `platform/` holds its complete platform files per
  target, as templates: the scripts fill in `APP_ID`, `APP_NAME` and
  `URL_SCHEME` and write them to `build/platform/`.
- `scripts/` builds, installs and starts the app.

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
GIO=upstream scripts/android.sh    # the same without the patches
GIO=platformdir scripts/ios.sh     # with complete platform files
```

With `GIO=platformdir` gogio gets `-platformdir` instead of `-schemes`,
`-manifest`, `-plist`, `-privacymanifest` and `-minsdk`; the files in
`platform/` set the version (2.0.0, 7), the URL scheme and the minimum
version. To see that they are used as they are: on iOS the event log
shows the `CFBundleExecutable` (`<APP_NAME>Exe`), the version and the key
`PlaygroundPlatformFile`; on Android `adb shell dumpsys package <APP_ID>`
shows versionName 2.0.0, minSdk 24 and no `ALLOW_BACKUP`; on macOS the
bundle's executable is `<APP_NAME>Exe`.

Each script lists its commands at the top (`build`, `run`, `uninstall`,
...). Variables from the environment win over `.env`. Both builds use the
same app id, so installing one replaces the other.

URLs need an app that registers the scheme: on the desktop that is only
the macOS bundle of `scripts/macos.sh` (`open gioplayground://hello`),
not `scripts/desktop.sh`.

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

Two things about gogio on current Xcode versions, both handled by the
scripts:

- Without `-minsdk`, upstream gogio builds for iOS 10, which the current
  SDKs can no longer link (no libarclite). For upstream the scripts pass
  `IOS_MINSDK` (default 15); the fork's gogio builds for iOS 13 and gets
  `-minsdk` only when `IOS_MINSDK` is set.
- Newer Xcode versions keep the profiles in
  `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`, while
  gogio only searches `~/Library/MobileDevice/Provisioning Profiles/`
  without `-signkey`. The scripts always pass `-signkey`.

With the iOS 27 SDK, `GIO=upstream scripts/ios.sh` builds an app that
closes right after launch: upstream Gio has no UIScene support and
upstream gogio cannot add the scene manifest (TN3187).
