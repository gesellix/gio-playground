# gio-playground

A small [Gio](https://gioui.org) program to try out patches to Gio, gio-x
and gogio on real devices, and to show what they change. The same program
is built twice: with the patches (`fork/`) and without them (`upstream/`).

Each page of the app exercises one patch. An event log that all pages
share records what the program receives (configuration changes, URLs,
scene notifications, file results), so a test can be shown or copied
afterwards ("Event log", "Copy the log").

## Pages

| Page                         | Patch                                   | What to check                                                                                                                                                          |
|------------------------------|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Clipboard: sensitive content | Gio: `clipboard.WriteCmd.Sensitive`     | Android 13+: the preview shows dots. iOS: no Universal Clipboard. Windows: not in Win+V. KDE: no Klipper entry. macOS: skipped by nspasteboard.org clipboard managers. |
| Background: Config.Hidden    | Gio: `app.Config.Hidden` (Android, iOS) | Home, app switcher, screen off: `Hidden=true`, then `false` on return. Notification shade, Control Center: only `Focused` changes.                                     |
| iOS: scenes and URLs         | Gio: UIScene life cycle; gogio `-plist` | Open `gioplayground://hello` while running and after closing the app (cold start): a `URLEvent` each time. "Disconnect the scene", then reopen the app.                |
| Title bar colors             | Gio: `app.DecorationColors`             | Where Gio draws its own title bar (Wayland under GNOME), the colors change.                                                                                            |
| Editor.Wipe                  | Gio: `widget.Editor.Wipe`               | The editor is empty and stays usable.                                                                                                                                  |
| Files: export and save       | gio-x: explorer                         | Android: export with an unknown extension works; the log shows the URI and name of the file. Desktop: `SaveFilePath`.                                                  |
| Event log                    |                                         | Everything above, newest first.                                                                                                                                        |

The gogio patches show at build time: on iOS the log starts with whether
the Info.plist has the scene manifest (`-plist`) and whether the app has
its privacy manifest (`-privacymanifest`); on Android `-manifest` turns
off the app's backup (`adb shell dumpsys package <APP_ID>`: no
`ALLOW_BACKUP` among the flags). Not covered: the js build tags fix.

Where the patches are:

- Gio: [gesellix/gio-forked](https://github.com/gesellix/gio-forked),
  not sent yet.
- gio-x: [gesellix/gio-x](https://github.com/gesellix/gio-x), sent as
  [gio-patches 72104](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72104).
- gogio: [gesellix/gio-cmd](https://github.com/gesellix/gio-cmd), sent as
  [gio-patches 72106](https://lists.sr.ht/~eliasnaur/gio-patches/patches/72106).

## Layout

- The root package (`playground`) is the program. It builds against
  upstream Gio and gio-x, so it cannot use an API of the patches by
  accident; the fork passes those APIs in as `playground.Features`.
- `fork/` and `upstream/` are the two programs, each a module of its own
  with its versions of Gio, gio-x and gogio (`go tool gogio`).
- `ios/` and `android/` hold the files for gogio's `-plist`,
  `-privacymanifest` and `-manifest`.
- `scripts/` builds, installs and starts the app.

## Setup

- Go 1.27.3 or later (the go line of the go.mod files).
- Android: the Android SDK with the NDK (`ANDROID_HOME`) and `adb`.
- iOS: a Mac with Xcode (see below for the signing).

```sh
cp .env-example .env   # then fill in .env, it stays out of git
```

## Running

```sh
scripts/desktop.sh                 # this computer
scripts/android.sh                 # build, install (keeps data), start
scripts/android.sh log             # the app's log
scripts/ios.sh                     # build, install, start
GIO=upstream scripts/android.sh    # the same without the patches
```

Each script lists its commands at the top (`build`, `run`, `uninstall`,
...). Variables from the environment win over `.env`. Both builds use the
same app id, so installing one replaces the other.

## iOS signing

A free Apple account (Personal Team) is enough for a device of your own;
such a profile lasts 7 days.

1. Xcode, Settings, Accounts: add the account. Connect the iPhone and turn
   on Developer Mode on it (Settings, Privacy & Security).
2. Create an empty iOS app project in Xcode with the bundle id of
   `APP_ID` (Build Settings, Product Bundle Identifier), set up the
   signing with your team ("Set Up Signing…" in Xcode 27.1) and run it
   once on the iPhone. That
   creates the development certificate and the provisioning profile.
3. `scripts/ios.sh profiles` lists the profiles with their app ids; put
   the path of the one for `APP_ID` into `IOS_SIGNKEY`.
   `scripts/ios.sh devices` lists the devices for `IOS_DEVICE`.
4. `scripts/ios.sh`. If iOS asks, trust the developer on the iPhone
   (Settings, General, VPN & Device Management).

Two things about gogio on current Xcode versions, both handled by the
scripts:

- Without `-minsdk`, gogio builds for iOS 10, which the current SDKs can
  no longer link (no libarclite). The scripts pass `IOS_MINSDK`
  (default 15).
- Newer Xcode versions keep the profiles in
  `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`, while
  gogio only searches `~/Library/MobileDevice/Provisioning Profiles/`
  without `-signkey`. The scripts always pass `-signkey`.

With the iOS 27 SDK, `GIO=upstream scripts/ios.sh` builds an app that
closes right after launch: upstream Gio has no UIScene support and
upstream gogio cannot add the scene manifest (TN3187).
