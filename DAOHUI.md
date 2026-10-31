# 島輝 DaoHui for macOS: fork notes

DaoHui (島輝) for macOS is a renamed, independent fork of
[Squirrel 鼠鬚管](https://github.com/rime/squirrel) 1.1.2 (tag `1.1.2`, commit
`876adeb`, 2026-01-13, the latest release; the `latest` tag is the nightly) by the
RIME team, licensed under GPLv3 like the original. It is the macOS sibling of the
Windows fork of Weasel (`D:\src\daohui`, see its `DAOHUI.md`); both follow the same
pattern. Branch `daohui` of this repository holds:

1. Upstream fixes from after 1.1.2, cherry-picked with `-x`: `0cd71a6` (install path
   in `SquirrelApp.appDir`: 1.1.2 has the typo `/Library/Input Library/…`), `841fb47`
   (BSD `basename` in `add_data_files`), `041e921` + `9b012e8` (productbuild
   `Distribution`, localized installer conclusion page), `2158538`
   (`hostArchitectures`, so the installer does not ask for Rosetta). The `Main.swift`
   part of `7b4a314` (`deliverImmediately` for `--reload`/`--sync`) is ported by hand.
2. `.gitattributes`: LF line endings in every checkout (the Windows machine has
   `core.autocrlf=true`).
3. The rename, so DaoHui installs **side by side** with a stock Squirrel.
4. DaoHui's icons, Rime data and look (`daohui-data/`, `data/squirrel.yaml`).
5. CI: `.github/workflows/daohui-macos.yml` (Squirrel's own workflows are removed).

The run-time names live in [`sources/DaoHuiBrand.swift`](sources/DaoHuiBrand.swift)
(the counterpart of `include/DaoHuiBrand.h`). Names that Swift cannot provide are in
`resources/Info.plist`, `resources/InfoPlist.xcstrings`, the project file and the
package scripts; the tables below list each place.

## Renamed identifiers

### Bundle, input source, package

| What | Stock Squirrel | DaoHui | Where |
|---|---|---|---|
| Bundle identifier | `im.rime.inputmethod.Squirrel` | `io.github.timlin-1231.inputmethod.DaoHui` | `PRODUCT_BUNDLE_IDENTIFIER` (pbxproj, Debug + Release) |
| Input source id (`TISInputSourceID`) | `im.rime.inputmethod.Squirrel` | `io.github.timlin-1231.inputmethod.DaoHui` | Info.plist, InfoPlist.xcstrings |
| Input modes | `….Squirrel.Hans` (zh-Hans, primary), `….Squirrel.Hant` (zh-Hant) | one mode, `io.github.timlin-1231.inputmethod.DaoHui.Hant` (zh-Hant, primary) | Info.plist `ComponentInputModeDict`, InfoPlist.xcstrings, `InputSource.swift` (`InputMode`, raw value) |
| `InputMethodConnectionName` | `Squirrel_Connection` | `DaoHui_Connection` | Info.plist |
| Controller / delegate class | `Squirrel.SquirrelInputController` | `$(PRODUCT_MODULE_NAME).SquirrelInputController` = `DaoHui.SquirrelInputController` (the Swift module follows `PRODUCT_NAME`) | Info.plist |
| Product, `CFBundleName`, `CFBundleExecutable` | `Squirrel.app`, `Squirrel` | `DaoHui.app`, `DaoHui` | `PRODUCT_NAME`, Info.plist, scheme `BuildableName` |
| Install location | `/Library/Input Methods/Squirrel.app` | `~/Library/Input Methods/DaoHui.app` of the login user since 1.1.2.21 (the package still installs into `/Library/Input Methods`, and `scripts/postinstall` moves it; see "Automatic updates"); `SquirrelApp.appDir` (`--register-input-source`, `--update-input-source`) is wherever the app runs from | `scripts/postinstall`, `Main.swift`; the package's `/Library/Input Methods`: Makefile `SQUIRREL_APP_ROOT`, `package/make_package`, `package/Squirrel-component.plist`, `package/sign_app` |
| Package identifier (receipt) | `im.rime.inputmethod.Squirrel` | `io.github.timlin-1231.inputmethod.DaoHui` | `package/make_package`, `package/Distribution` (pkg-ref and choice ids) |
| Package files | `Squirrel.pkg`, `Squirrel-component.pkg`, `Squirrel-<ver>.pkg` | `DaoHui.pkg`, `DaoHui-component.pkg`, `DaoHui-<ver>.pkg` | Makefile `PACKAGE`, `make_package`, `make_archive`, `.gitignore` |
| Installer title | `Squirrel-<ver>` | `島輝 DaoHui <ver>` | `package/Distribution` |
| `postinstall` | `killall Squirrel`; `Squirrel --register-input-source` as root, `--build` in SharedSupport, `--enable-input-source` / `--select-input-source` via `sudo -u` | `killall DaoHui`; moves `DaoHui.app` to the login user's `~/Library/Input Methods` (`ditto`, `chown`; left in place if that fails or nobody is logged in); `DaoHui --update-input-source` (register, disable + enable, select) via `launchctl asuser <uid> sudo -u <user>` in the login user's session; no `--build` (the shared data is prebuilt by `package/prebuild_shared`, so the bundle stays sealed). A stock Squirrel is not touched. See "Updates and the input source list" | `scripts/postinstall`, `sources/InputSource.swift` |
| Version | `CURRENT_PROJECT_VERSION` 1.1.2 | `DAOHUI_VERSION` (CI: `1.1.2.<commits since 876adeb>`, as the Windows `0.17.4.<n>`) sets `CURRENT_PROJECT_VERSION` → `CFBundleVersion`/`CFBundleShortVersionString` and the package version; default 1.1.2 | Makefile, `make_package`, `make_archive` |

### Run-time names

| What | Stock Squirrel | DaoHui | Where |
|---|---|---|---|
| Distributed notifications (`--reload`, `--sync`) | `SquirrelReloadNotification`, `SquirrelSyncNotification` | `DaoHuiReloadNotification`, `DaoHuiSyncNotification` | `DaoHuiBrand`; `Main.swift`, `SquirrelApplicationDelegate.swift` |
| User notification request ids | `SquirrelUpdateNotification`, `SquirrelNotification` | `DaoHuiUpdateNotification`, `DaoHuiNotification` | same |
| Crash-loop launch record | `$TMPDIR/squirrel_launch.json` | `$TMPDIR/daohui_launch.json` | same |
| librime `distribution_code_name` / `distribution_name` | `Squirrel` / `鼠鬚管` | `DaoHui` / `島輝` | `DaoHuiBrand.codeName`, `.distributionName` |
| librime `app_name` (glog prefix) | `rime.squirrel`, `rime.squirrel-builder` (`--build`) | `rime.daohui`, `rime.daohui-builder` | `DaoHuiBrand.logAppName`, `.builderAppName` |

1.1.2 has no `--ascii`/`--nascii`/`--getascii` notifications (they came later upstream).

### Folders

| What | Stock Squirrel | DaoHui |
|---|---|---|
| User data folder | `~/Library/Rime` | `~/Library/DaoHui` (`DaoHuiBrand.userDirName`) |
| Shared data | `Squirrel.app/Contents/SharedSupport` | `DaoHui.app/Contents/SharedSupport` (plus `lua/`, `opencc/asus_*`) |
| Logs | `$TMPDIR/rime.squirrel/` | `$TMPDIR/rime.daohui/` (`DaoHuiBrand.logAppName`) |

The separate user folder means a stock Squirrel and DaoHui never share
`default.custom.yaml`, userdb locks or `build/`. Rime documentation that says
`~/Library/Rime` means `~/Library/DaoHui` here; the menu item 用戶設定 opens it.

### Updates (Sparkle 2.6.2)

| What | Stock Squirrel | DaoHui |
|---|---|---|
| `SUFeedURL` | `https://rime.github.io/release/squirrel/appcast.xml` | `https://raw.githubusercontent.com/TimLin-1231/rime-asus-zhuyin/main/update/appcast-macos-app.xml` (the `.zip`; 1.1.2.20 and older read `appcast-macos.xml`, the `.pkg`) |
| Automatic updates | asks before installing | `SUEnableAutomaticChecks`, `SUAutomaticallyUpdate`, `SUScheduledCheckInterval` 21600 (6 h); installed without asking (below) |
| `SUPublicEDKey` | Squirrel's EdDSA key | placeholder `DAOHUI_SPARKLE_PUBLIC_KEY` |
| Appcasts written by `make_archive` | `appcast.xml`, `testing-appcast.xml`, `debug-appcast.xml` | `appcast-macos-app.xml` (`DaoHui-<ver>.zip`), `appcast-macos.xml` (`DaoHui-<ver>.pkg`; the testing channel uses the same feeds, as on Windows), `debug-appcast.xml` |
| Download URL in the appcast | `github.com/rime/squirrel/releases/download/<ver>/Squirrel-<ver>.pkg` | `github.com/<GITHUB_REPOSITORY>/releases/download/<tag>/DaoHui-<ver>.zip` / `.pkg` (default repo `TimLin-1231/daohui-squirrel`, tag `v<ver>`) |

`SUFeedURL` is the single constant: `make_archive` reads it from `resources/Info.plist`
with PlistBuddy, and writes the package feed `appcast-macos.xml` next to it.

**The Sparkle key placeholder.** `resources/Info.plist` carries
`<string>DAOHUI_SPARKLE_PUBLIC_KEY</string>` as `SUPublicEDKey`. While the built app still
has the placeholder, `SquirrelApplicationDelegate` does not start the updater
(`DaoHuiBrand.sparkleConfigured`; a started Sparkle refuses an undecodable key and shows
an error at every launch) and 檢查新版本 does nothing. The release step replaces it:

1. Once, on a Mac: `./download/bin/generate_keys` (in the Sparkle 2.6.2 archive that
   `action-install.sh` downloads) prints the public key and stores the private key in the
   login keychain; `generate_keys -x sparkle_private_key.txt` exports the private key.
2. Repository secrets: `SPARKLE_PUBLIC_ED_KEY` (the base64 public key) and
   `SPARKLE_PRIVATE_ED_KEY` (the exported private key).
3. The workflow then runs `PlistBuddy -c "Set :SUPublicEDKey …" resources/Info.plist`
   before building, and on `v*` tags signs the package and the zipped app with
   `sign_update --ed-key-file` and attaches both appcasts to the release.
   Locally: set the key the same way before `make`, or keep the placeholder (no updates).
4. Publish `appcast-macos-app.xml` at the `SUFeedURL` and `appcast-macos.xml` next to it
   (`update/` of rime-asus-zhuyin). Never change the key after shipping: installed copies
   only accept updates signed with it.

**Updates and the input source list.** Sparkle installs the `.pkg` silently with
`installer` as root, so the Distribution's `onConclusion="RequireLogout"` never asks for a
logout. Installing replaces the whole bundle; on 1.1.2.14 (stock postinstall) this left
島輝 greyed out in the input menu: it was gone from the user's `TISCreateInputSourceList`
and from `AppleEnabledInputSources`, while the postinstall had printed "already
registered/enabled" and "Selection succeeds" because `sudo -u` from the installer keeps
the installer's bootstrap and its input source calls never reach the user's text input
server. Running `--register-input-source` and `--select-input-source` by hand in the
user's Terminal registered and selected it, but the enabled state was saved only by
logging out and in. Since 1.1.2.18 the postinstall runs `DaoHui --update-input-source`
through `launchctl asuser` in the login user's session: it registers unconditionally,
turns the mode off and on (enabling is what gets saved) and selects it.

**Automatic updates (since 1.1.2.21).** Sparkle installs an update without asking only
when it needs no administrator password, and a `.pkg`, or any bundle in
`/Library/Input Methods`, always needs one (`SPUUsesSystemDomainForBundlePath`: the
automatic driver then stops with `SUInstallationAuthorizeLaterError` and shows its
window). So the package moves the app into the login user's `~/Library/Input Methods`
(input methods load from either folder; the package itself still installs into
`/Library/Input Methods`, since installing runs as root), and the app reads
`appcast-macos-app.xml`, whose enclosure is the app zipped with
`ditto -c -k --sequesterRsrc --keepParent` (installation type "application"). Sparkle
accepts the ad-hoc signed update: its EdDSA signature is valid and the new app's own
signature is intact (the workflow unzips it and runs `codesign --verify --deep --strict`);
the designated requirements of two ad-hoc builds never match, which `SUUpdateValidator`
allows once the EdDSA check passes. Every 6 hours Sparkle checks, downloads in the
background and calls `updater(_:willInstallUpdateOnQuit:immediateInstallationBlock:)`:
an input method never quits, so `SquirrelApplicationDelegate` runs the block once no key
has reached DaoHui for 60 s and nothing is being composed
(`SquirrelInputController.lastKeyTime`, `.composing`, checked every 30 s). Sparkle
replaces the bundle and relaunches it; `updater(_:willInstallUpdate:)` has noted whether
DaoHui was the input source in use, and the new version's first launch
(`refreshInputSourceAfterUpdate`, version kept in the `DaoHuiLaunchedVersion` default)
runs `DaoHui --update-input-source [--no-select]` in a process of its own, as the
postinstall does after a package. Copies in `/Library/Input Methods` (1.1.2.20 and older,
or where the move failed) read `appcast-macos.xml` (1.1.2.20 and older) and get the
package, with the password, once more.

### User-visible names

| Where | Stock Squirrel | DaoHui |
|---|---|---|
| `CFBundleName`, `CFBundleDisplayName` (InfoPlist.xcstrings), input source and mode names | `Squirrel` / `鼠鬚管` / `鼠须管`, `Squirrel - Simplified/Traditional` | `DaoHui` (en), `島輝` (zh-Hant and zh-Hans) |
| `INFOPLIST_KEY_CFBundleDisplayName` | `Squirrel Input Method` | `DaoHui` |
| `NSHumanReadableCopyright` | `Copyleft, RIME Developers` / `式恕堂 版權所無` | `Based on Squirrel (鼠鬚管) by the RIME team. GPLv3 \| Copyleft RIME Developers and DaoHui contributors` (zh: 基於 RIME 團隊的鼠鬚管…與島輝貢獻者) |
| Menu / notification title (Localizable `"Squirrel"`) | `鼠鬚管` | key `"DaoHui"`: `島輝` |
| `deploy_success` (en) | `Squirrel is ready.` | `DaoHui is ready.` |
| `--help`, log messages | Squirrel | DaoHui |
| `README.md` (also in the app's Resources) | 鼠鬚管 | 島輝, with the Squirrel credits kept |

The brand stays 島輝 in zh-Hans too, as on Windows.

### Icons

| File | Used for | Source (branding set F, `D:\Document\輸入法\branding`, read only) |
|---|---|---|
| `Assets.xcassets/DaoHui.appiconset/` (`ASSETCATALOG_COMPILER_APPICON_NAME = DaoHui`; actool makes `DaoHui.icns`, `CFBundleIconFile = DaoHui`) | App icon (installer, Finder, notifications, Sparkle) | byte-identical copies: `out/F/app-512.png`, `app-256.png`, `tauri/icons/128x128.png`, `32x32.png`, the 64 px and 1024 px entries of `tauri/icons/icon.icns`; the 16 px image is the 16 px frame of `out/F/weasel.ico` (hinted Microsoft JhengHei Bold, as on Windows) |
| `resources/daohui.pdf` | Menu-bar and input-source icon (`tsInputMode*IconFileKey`), a **template image** (`TISIconIsTemplate`, top level and in the mode) | 16×16 pt vector: rounded badge with the brush 島 of `concepts/F.svg` (Yuji Syuku, SIL OFL 1.1) knocked out, even-odd, the negative look of F |

Removed: `Rime.icon` (Icon Composer, RIME logo) and `resources/rime.pdf`.
`tools/make_daohui_icons.py <branding dir> [--preview out.png]` regenerates both from the
branding folder (sources used: `concepts/F.svg` SHA-256 `dcda5409…58da`,
`tauri/icons/icon.icns` `bb5166f7…1756`, `weasel.ico` `1e5338b3…40b8`). With the classic
app icon set, macOS 26 shows the tile inside its standard squircle; an Icon Composer
`DaoHui.icon` (needs Xcode 26) is a possible later improvement.

## Kept on purpose (still named Squirrel)

- `Squirrel.xcodeproj`, target, scheme (`-scheme Squirrel`), Swift type names
  (`SquirrelApp`, `SquirrelInputController`, …), source file names,
  `Squirrel-Bridging-Header.h`, `resources/Squirrel.entitlements`,
  `package/Squirrel-component.plist`: internal, so upstream changes still merge.
- Rime config id **`squirrel`** (`squirrel.yaml`, `squirrel.custom.yaml`): the frontend
  settings file keeps its name, as Windows keeps `weasel.yaml`. Squirrel users can copy
  their `squirrel.custom.yaml`.
- `tsInputModeCharacterRepertoireKey` `Hant, Hans`; `TICapsLockLanguageSwitchCapable`.
- The 在線文檔 menu item (`https://github.com/rime/home/wiki`): same engine and settings.
- `INSTALL.md`, `CHANGELOG.md`, `.github/ISSUE_TEMPLATE/` (upstream documents).

## Data

- **`daohui-data/`** is a copy of the Windows fork's `output/data_daohui/` (built by
  `tools/package_daohui_data.py`; no private data, licences in
  `DAOHUI_DATA_LICENSES.txt`; see `D:\src\daohui\DATA.md`). Text files are stored with
  LF. Do not edit it here; regenerate and copy (`daohui-data/README.md`).
- **How it gets into the app.** `package/copy_daohui_data <SharedSupport>` copies every
  file of `FILES.txt` except `weasel.yaml` (lua/ and opencc/ included) and fails if
  `FILES.txt` and the folder disagree. It is the last build phase of the target,
  "Copy DaoHui data" (a Run Script phase; `ENABLE_USER_SCRIPT_SANDBOXING = NO` on the
  target because it writes outside declared outputs). Before `xcodebuild`, the Makefile
  runs `copy_daohui_data --override-plum data/plum`, which puts DaoHui's `default.yaml`
  over plum's, so the stock "Copy Shared Support Files" phase copies DaoHui's too and
  the order of the phases does not matter. Code signing happens after all phases.
- **Default schema.** `daohui-data/default.yaml` (stock + root `__patch`) makes
  `asus_zhuyin` the only schema, `page_size` 9, Shift/Ctrl taps `noop`, Caps Lock
  `commit_text`, then applies `default.custom:/patch?`. The stock Squirrel schemas stay
  in SharedSupport (unused); the schema needs `bopomofo_tw`, `terra_pinyin.dict`,
  `essay.txt`, prelude, opencc `t2s`/`t2tw` from plum's `:preset`.
- **No octagram data** from plum (`SQUIRREL_BUNDLED_RECIPES=''`). The language model
  `wanxiang-lts-zh-hant.gram` (410 MB) is **not shipped**; `grammar.yaml` names it and
  octagram looks in the user folder first, so it goes into `~/Library/DaoHui/` (nothing on
  macOS downloads it yet; without it DaoHui types but is less accurate, DATA.md).
- **The look, `data/squirrel.yaml`**: stock file + root `__patch` (then
  `squirrel.custom:/patch?`), the port of `rime/weasel.custom.yaml`:

| Weasel (`weasel.custom.yaml`) | Squirrel (`data/squirrel.yaml` patch) |
|---|---|
| `show_notifications: true`, `show_notifications_time` | `show_notifications_when: appropriate` (no duration setting) |
| — | `keyboard_layout: default` (ABC key positions for the Dachen layout) |
| `style/color_scheme` / `color_scheme_dark` | same keys |
| `font_face` etc. Microsoft JhengHei UI 13 / 10 / 12 pt | `PingFang TC` 17 / 13 / 16 pt (same size: Windows pt × 96/72) |
| `horizontal: false` | `candidate_list_layout: stacked` (Squirrel sets librime's `_linear` from it before every key; `asus_keys.lua` expects `_linear` off) |
| `inline_preedit: true`, `preedit_type: preview` | `inline_preedit: true`, `inline_candidate: true` |
| `label_format: "%s"` | `candidate_format: "[label] [candidate] [comment]"` |
| `layout/corner_radius 7`, `round_corner 5` | `corner_radius: 7`, `hilited_corner_radius: 5` |
| `layout/spacing 6`, `candidate_spacing 8` | `spacing: 6`, `line_spacing: 8` |
| `layout/margin_x/y 3`, `border_width 0`, `hilite_padding_*`, `min_width/height` | stock `border_width/height: -2` (Squirrel adds `corner_radius` to the border; tune on a Mac) |
| `layout/shadow_*`, `shadow_color` | not ported (`shadow_size` is a highlight shadow in Squirrel: 0) |
| `color_format: argb`, colours `0xAARRGGBB` | `0xAABBGGRR` (red/blue swapped; checked mechanically against `weasel.custom.yaml`), `color_space: srgb` |
| `hilited_label_color` = highlight colour (hides "1") | `hilited_candidate_label_color` = `hilited_candidate_back_color` |
| `hilited_mark_color`, `display_tray_icon`, `ascii_tip_follow_cursor`, `hover_type` | no Squirrel equivalent |
| `app_options/<exe>` (terminals `asus_en_direct`, editors `asus_en_noauto`) | `app_options/<bundle id>`: `com.apple.Terminal`, `com.googlecode.iterm2` (both keep stock `no_inline`), `dev.warp.Warp-Stable`, `net.kovidgoyal.kitty`, `org.alacritty`, `com.github.wez.wezterm`, `co.zeit.hyper` → `asus_en_direct`; `com.microsoft.VSCode`, `com.todesktop.230313mzl4w4u92` (Cursor), `com.apple.dt.Xcode`, `com.jetbrains.pycharm(.ce)`, `com.jetbrains.intellij(.ce)`, `com.sublimetext.4` → `asus_en_noauto` |

  The terminal and editor entries replace the stock ones, which started those programs in
  English (`ascii_mode: true`), as the Windows patch does for `cmd.exe`. The other stock
  `app_options` (Spotlight, Alfred, MacVim, Emacs, Chrome/Edge/Telegram `inline`, …)
  stay.

## What still differs on macOS (Lua and schema)

The Lua is shared with Windows (`daohui-data/lua`, from the input-method repository);
`docs/macos.md` §1 lists the Windows-only parts. State in this fork:

| Item | macOS |
|---|---|
| Timing (`os.clock()`) | Handled by `asus_clock.lua`: librime-lua of librime 1.16.0 should have `rime_api.get_time_ms` (inferred from dates, not verified; on a Mac, `asus_clock.source()` or the absence of the `no millisecond clock` warning in `$TMPDIR/rime.daohui/` tells) |
| Named pipe `\\.\pipe\asus_zhuyin_assist_*` | Off (only opened when `asus_clock.windows`) |
| Writing helper (pause-to-continue, Ctrl+Alt+W, `assist/`) | Not available: it needs the named pipes, **F24** sent by SendInput (Mac keyboards stop at F20) and Windows APIs. A macOS version would need a channel in the Swift frontend (e.g. a Unix socket) that hands F24 to librime itself, plus Accessibility permission |
| Ctrl+Space (`asus_keys.lua` toggles English) | macOS uses Ctrl+Space for "Select the previous input source" and takes it first. Turn that shortcut off in System Settings › Keyboard › Keyboard Shortcuts › Input Sources, or use double Shift |
| `app_options` | Keyed by **bundle id** instead of `.exe` name (table above). The mechanism is the same: Squirrel sets each listed option on the session, Lua reads it with `get_option` |
| Caps Lock | macOS's "Use Caps Lock to switch to and from ABC" switches the input source instead of sending Caps Lock to Rime |
| Shift+Del / Ctrl+Del (forget a learnt word, `asus_learn.lua`) | No Delete key on Mac keyboards: fn+Delete is Delete, so Shift+fn+Delete |
| Keep the inline text when focus leaves (Windows `keep-composition` TSF patch) | Since 1.1.2.20, `commitComposition` (called by the app, and by `deactivateServer`) commits the text shown inline (`commit_text_preview`, `shownText()`); stock Squirrel committed the **raw input** (`get_input`, e.g. `ji3rup wu0 cp3`). Web pages and Electron apps call it while BackSpace edits a long composition, so the keys typed replaced the whole sentence. Upstream `52d3bc3` (after 1.1.2) still commits the raw input |
| Ctrl+punctuation (`asus_symbols.lua` assumes Weasel's key translation: Ctrl cleared, Shift kept) | Squirrel's translation of Ctrl+Shift+; etc. is unverified |
| Tools (`rime_harness.py`, `backup_learn.py`, settings app) | Windows-only (winreg, rime.dll, WeaselServer, `HKCU\Software\DaoHui`); the settings app's LM download has no macOS counterpart yet |
| AI correction, Ctrl+R (`asus_fix.lua`) | macOS since 1.1.2.22, Windows since 0.17.4.9; each front end asks the model itself. See below |

### AI correction (Ctrl+R)

While composing, Ctrl+R asks a local language model to correct the sentence (wrong
homophones, characters spoiled by a slipped key, 的/得/地, 在/再); the correction is shown
as the whole composition, Enter commits it, Esc goes back. The work is split:

- `asus_fix.lua` (input-method repository, shared with Windows) builds the
  chat-completions request, puts `<id>\t<JSON>` in the session property
  `asus_fix_request`, and on the key **F23** (`0xFFD4`) reads `<id>\t<answer>` from
  `asus_fix_result`, tidies it and keeps it only if it still reads as the keys typed
  (`ReverseLookup` of `terra_pinyin.asus`, `asus_fix_data.lua`), keeps English words and
  numbers, never swaps 他/她 or 你/您, and has no simplified characters (`s2tw.json`).
  Lua only asks when the front end set the option `_asus_fix`.
- `SquirrelInputController` sets `_asus_fix` on every session, and after each key
  (`takeFixRequest`) empties a waiting request and hands it to `DaoHuiAI`; the answer
  (or `!message` for the bubble) comes back on the main queue, is put in
  `asus_fix_result` and F23 is processed for that session. Then it looks for a request
  again: when an answer changed nothing, Lua asks once more while handling F23 (any
  tone, held to each syllable's characters by a grammar: 一血 → 一些; since 1.1.2.24).
- `DaoHuiAI.swift` runs llama.cpp's `llama-server` (b11559, `127.0.0.1:8739`, Metal,
  `--reasoning off`) on Qwen3.5-4B Q4_K_M, started at the first Ctrl+R (up to 180 s for
  the first load) and stopped after 10 minutes unused or when DaoHui quits. Both come
  from the input menu item 「下載 AI 修正模型（約 2.8 GB）…」 into `~/Library/DaoHui/ai/`
  (pinned URLs, SHA-256 checked, the archive unpacked with `tar`, quarantine removed).
  The server's output goes to `$TMPDIR/rime.daohui/llama-server.log`.
  `NSAllowsLocalNetworking` in Info.plist lets URLSession reach `http://127.0.0.1`.

Measured in the input-method repository (`tools/eval_fix.py --ime-rescore --two-pass`,
both requests through the Lua as shipped, Qwen3.5-4B): held-out, 576 → 644 of 820
sentences right (72 fixed, 4 broken), tone slips 32 → 62 of 100; median 209 ms on a
Windows PC for both requests.
Not verified on a Mac: model load time and answer time with Metal, memory use.

## Building

### CI (GitHub Actions)

`.github/workflows/daohui-macos.yml` runs on pushes to `daohui`, on `v*` tags and by
hand, on the GitHub-hosted **`macos-15`** runner (Apple silicon; Squirrel 1.1.2's own
workflows used `macos-latest`, which was macos-15 then; upstream master later moved to
`macos-26` for macOS 26 APIs that 1.1.2 does not use; `macos-14` was retired in July 2026).
It uses the image's default Xcode and prints its version.

1. Checkout with full history (build number) and the submodules (librime headers, plum,
   Sparkle).
2. SwiftLint (advisory, does not fail the build).
3. Optional: Sparkle public key into Info.plist; Developer ID certificates into a
   temporary keychain plus a notarytool profile.
4. `./action-build.sh package` with `ARCHS="arm64 x86_64"`: `action-install.sh`
   downloads librime 1.16.0 `a251145` (`rime-a251145-macOS-universal.tar.bz2` +
   `rime-deps-…`, built by librime's CI with lua, octagram and predict as separate
   dylibs, copied to `Contents/Frameworks/rime-plugins/`), Sparkle 2.6.2 and plum's
   `:preset`; `make package` → `xcodebuild` universal Release →
   `package/prebuild_shared` (the app's `rime_deployer --build` into
   `SharedSupport/build`, then an ad hoc re-seal of the app) → `DaoHui.pkg`
   (signed, notarized and stapled only with the signing secrets).
5. `package/check_daohui_bundle`: identity, both architectures, plugins, data, the
   prebuilt data, an intact signature (`codesign --verify --deep --strict`), the pkg
   payload and the postinstall script.
6. Artifact **`DaoHui-<version>-macOS`**: `DaoHui-<version>.pkg` and `SHA256SUMS.txt`
   (30 days).
7. `package/smoke_daohui_rime deploy`: `rime_deployer --build` of `asus_zhuyin` with
   the app's librime and an empty user folder (fails the job if the schema does not
   compile). Then `… keys` (informational): `tools/rime_keys.c`, a small client of
   librime's C API built against the app's `librime.1.dylib`, types `su3cl3` (你好) and
   `hello` so the Lua scripts run on macOS's librime-lua, and prints the candidates and
   librime's errors.
8. On `v*` tags: `appcast-macos.xml` (with `SPARKLE_PRIVATE_ED_KEY`) and a GitHub
   release with the `.pkg` via `gh` and `GITHUB_TOKEN` (prerelease while unsigned).

Secrets (all optional; unset = unsigned build):

| Secret | Use |
|---|---|
| `MACOS_CERTIFICATE_P12` (base64), `MACOS_CERTIFICATE_PASSWORD` | `.p12` with the "Developer ID Application" and "Developer ID Installer" identities |
| `MACOS_DEV_ID` | `Name (TEAMID)` as in the identity names (Makefile `DEV_ID`) |
| `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD` | notarytool (app-specific password) |
| `SPARKLE_PUBLIC_ED_KEY`, `SPARKLE_PRIVATE_ED_KEY` | Sparkle (above) |

Signing runs only when all six signing secrets exist (the Makefile notarizes whenever
`DEV_ID` is set; `NOTARY_KEYCHAIN` points notarytool at the temporary keychain).

### Push only DaoHui's refs

Push the `daohui` branch (full history, so the build number can count from Squirrel
1.1.2) and `v*` tags. Do not push upstream's `master` or its tags: their commits carry
Squirrel's own workflows (`release-ci.yml` runs on every tag and on `master`). Make
`daohui` the default branch.

### On a Mac

Requirements: Xcode (full, for `xcodebuild` and `actool`). Then:

```sh
git clone --recursive <this repository> daohui-mac && cd daohui-mac
git checkout daohui
ARCHS='arm64 x86_64' ./action-build.sh package      # → package/DaoHui.pkg
sudo installer -pkg package/DaoHui.pkg -target /
```

Log out and in, then System Settings › Keyboard › Input Sources › Edit › + › Chinese,
Traditional › 島輝. Put the language model, `terra_pinyin.personal.dict.yaml`,
`shortcuts.txt` and `*.custom.yaml` into `~/Library/DaoHui/` and choose 重新部署.
Avoid `make install-release` (it changes the owner of `/Library/Input Methods`).

## Not verified (nothing was built here)

Everything was prepared on Windows, where macOS code cannot be built. Checked here:
the project file parses as an OpenStep plist with every object reference resolving
(it keeps upstream's two duplicate object ids from `add_data_files`); the plists, the
xcstrings and the asset catalog JSON parse; `bash -n` passes for every shell script and
every `run:` block of the workflow; `copy_daohui_data` was dry-run (42 files, stale
files removed, `FILES.txt` mismatch detected); the colour conversion was checked against
`weasel.custom.yaml`; `tools/rime_keys.c` parses with clang (clang-tidy) against
librime's `rime_api.h`. Not verified until the first CI run or a Mac:

- The Swift compiles (small, reviewed changes: `DaoHuiBrand.swift`, the single input
  mode, the Sparkle start switch).
- The Run Script phase runs after the stock copy phases (the Makefile pre-copy makes the
  only overlapping file, `default.yaml`, independent of that order).
- `actool` output names (`DaoHui.icns`, `Assets.car`) and that the template PDF is drawn
  as a template in the menu bar; the icon sizes on macOS 26.
- `macos-15`'s default Xcode (16.x or 26.x) builds 1.1.2 without `Rime.icon`; Sparkle's
  `bin/sign_update` path in the 2.6.2 archive; `pkgutil --expand-full`.
- librime-lua's `get_time_ms`, the Lua scripts on macOS, the style numbers (spacing,
  font sizes), Ctrl+punctuation, the unsigned `.pkg` through Gatekeeper, Sparkle with a
  real key.

Upstream fixes after 1.1.2 that were not taken (candidates for a later merge):
`52d3bc3` (finalize stranded composition), `c2280ad` (Caps Lock state on activation),
`151a43c` (ghost "a" from remote-desktop modifier events), `8ce1020`/`1dde022` (direct
commits in marked-text clients, Alacritty), `8418c95`, `769ae42`, `325b614`,
librime 1.17.0.
