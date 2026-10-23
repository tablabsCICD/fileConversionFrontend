# file_convertor

Convert, share and secure files — a Flutter app for iOS, Android, web and desktop.

## Running

```sh
flutter pub get
flutter run                 # the app
flutter test                # unit, widget and accessibility tests
```

## Widgetbook (component workbench)

[Widgetbook](https://docs.widgetbook.io) is the Flutter equivalent of Storybook.
Every reusable widget, design token and conversion state is catalogued there.

```sh
flutter run -t widgetbook/main.dart -d chrome          # live, with hot reload
flutter build web -t widgetbook/main.dart -o build/widgetbook   # static build
```

| Folder | Contents |
| --- | --- |
| Design System | Colours (with live contrast ratios), file families, typography, spacing & radii, motion, iconography |
| Components | Button, text field, format badge, file glyph, file tile, drop zone, progress track, notice, segmented toggle, section header, empty state |
| Layout | Navigation bar, brand mark |
| File Converter | Every conversion state, an interactive converter with a mock engine, tool cards, upload card, storage overview |
| Screens | App shell, Home, Convert, Share, Profile, Vault |

Addons: light/dark theme, device viewports (iPhone SE → MacBook), text scale up to
200%, an accessibility checker (tap targets, labels, overflow), inspector, 8pt grid, zoom.
Widgetbook has no Actions panel, so story callbacks report themselves in a snack bar
and the debug console.

Stories live in `widgetbook/` and only depend on `widgetbook` / `accessibility_tools`
as dev dependencies, so nothing ships in the app.

## Design system

| Where | What |
| --- | --- |
| `lib/app/theme/app_palette.dart` | Colour tokens (`context.palette`) — light "paper" and dark "ink" |
| `lib/app/theme/app_typography.dart` | Instrument Serif (display), platform sans (UI), IBM Plex Mono (data) |
| `lib/app/theme/app_tokens.dart` | Spacing, radii, breakpoints, sizes, motion, shadows |
| `lib/core/widgets/` | Shared components |

Fonts are bundled in `assets/fonts` under the SIL Open Font License.

## Features

### On-device conversion
`LocalFileConverter` runs conversions in a background isolate with pure-Dart
libraries (`image`, `pdf`, `archive`, `csv`, `xml`, `markdown`, `excel`) and saves
results to *Documents/Converted* (visible in the iOS Files app). Supported tools are
listed in `OnDeviceTools` (`conversion_engine.dart`): image formats, images → PDF,
TXT/Markdown → PDF, TXT ↔ DOCX, DOCX → HTML, CSV/JSON/XML/XLSX, Markdown → HTML,
TAR → ZIP and ZIP compression. Tools that need a server or native codecs
(PDF → Office, video, audio, HEIC, RAR/7Z) are tagged **Soon** and cannot be started.
To add a remote engine, implement `FileConverter` and override `fileConverterProvider`.

### Storage
`DeviceStorageService` reads real figures over the `file_convertor/storage` channel
(`MainActivity.kt`, `AppDelegate.swift`): total/free capacity on both platforms and,
on Android with media permission, image/video/audio usage from MediaStore. iOS does
not expose other apps' files, so it shows device totals plus this app's folders.

### Private Vault
Users choose PIN, password, fingerprint/face, or biometrics + PIN/password. Passcodes
are stored only as salted PBKDF2-HMAC-SHA256 hashes in the Keychain / Android Keystore,
with escalating lockouts after 5 failures. Files are encrypted with AES-256-GCM using a
random key held in secure storage, live in Application Support, and the vault locks
whenever the app is backgrounded.

### History, sharing, profile
Conversions, transfers and vault imports are logged locally (History). Sending shows a
QR code any phone camera can open to download the file; receiving shows progress and
saves to *Documents/Received*. The profile (name/email) and theme are stored on device.
