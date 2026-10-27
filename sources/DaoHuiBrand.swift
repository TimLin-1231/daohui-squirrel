//
//  DaoHuiBrand.swift
//  DaoHui
//
//  DaoHui (島輝) is a renamed fork of Squirrel (鼠鬚管) by the RIME team.
//  Every run-time name that would collide with a stock Squirrel installed on
//  the same Mac is defined here, so both can be installed side by side.
//  DAOHUI.md lists every identifier and its stock Squirrel value.
//
//  Defined elsewhere because they cannot refer to Swift code:
//    - bundle identifier: PRODUCT_BUNDLE_IDENTIFIER in Squirrel.xcodeproj
//    - input source / mode ids, connection name, SUFeedURL, SUPublicEDKey:
//      resources/Info.plist (and the ids again in resources/InfoPlist.xcstrings
//      and as enum raw values in sources/InputSource.swift)
//    - package id and install path: package/make_package, package/Distribution
//

import Foundation

enum DaoHuiBrand {
  /// Executable name, librime `distribution_code_name` (stock: Squirrel).
  static let codeName = "DaoHui"
  /// librime `distribution_name` (stock: 鼠鬚管).
  static let distributionName = "島輝"
  /// User data folder `~/Library/DaoHui` (stock: `~/Library/Rime`).
  static let userDirName = "DaoHui"
  /// Install location (stock: `/Library/Input Methods/Squirrel.app`).
  static let appPath = "/Library/Input Methods/DaoHui.app"
  /// Log folder `$TMPDIR/rime.daohui` and glog file prefix (stock: `rime.squirrel`).
  static let logAppName = "rime.daohui"
  /// glog name of `DaoHui --build` (stock: `rime.squirrel-builder`).
  static let builderAppName = "rime.daohui-builder"
  /// Distributed notifications sent by `DaoHui --reload` / `--sync`
  /// (stock: `SquirrelReloadNotification`, `SquirrelSyncNotification`).
  static let reloadNotification = "DaoHuiReloadNotification"
  static let syncNotification = "DaoHuiSyncNotification"
  /// User notification request ids (stock: `SquirrelUpdateNotification`, `SquirrelNotification`).
  static let updateNotificationIdentifier = "DaoHuiUpdateNotification"
  static let notificationIdentifier = "DaoHuiNotification"
  /// Launch record in `$TMPDIR` for crash-loop detection (stock: `squirrel_launch.json`).
  static let launchRecordFile = "daohui_launch.json"
  /// `SUPublicEDKey` in Info.plist until the release build puts the real key there.
  /// While it is still the placeholder, Sparkle is not started (see DAOHUI.md).
  static let sparkleKeyPlaceholder = "DAOHUI_SPARKLE_PUBLIC_KEY"

  /// True when Info.plist carries a real Sparkle EdDSA public key.
  static var sparkleConfigured: Bool {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else { return false }
    return !key.isEmpty && key != sparkleKeyPlaceholder
  }
}
