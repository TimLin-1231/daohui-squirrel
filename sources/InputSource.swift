//
//  InputSource.swift
//  Squirrel
//
//  Created by Leo Liu on 5/10/24.
//

import Foundation
import InputMethodKit

final class SquirrelInstaller {
  // DaoHui registers one Traditional Chinese mode (stock Squirrel: .Hans and
  // .Hant). Keep the id in step with resources/Info.plist and InfoPlist.xcstrings.
  enum InputMode: String, CaseIterable {
    static let primary = Self.hant
    case hant = "io.github.timlin-1231.inputmethod.DaoHui.Hant"
  }
  private lazy var inputSources: [String: TISInputSource] = Self.listInputSources()

  // DaoHui: a function (stock: the lazy initializer) so refresh() can read the
  // list again after registering.
  private static func listInputSources() -> [String: TISInputSource] {
    var inputSources = [String: TISInputSource]()
    let sourceList = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
    for inputSource in sourceList {
      let sourceIDRef = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
      guard let sourceID = unsafeBitCast(sourceIDRef, to: CFString?.self) as String? else { continue }
      // print("[DEBUG] Examining input source: \(sourceID)")
      inputSources[sourceID] = inputSource
    }
    return inputSources
  }

  func enabledModes() -> [InputMode] {
    var enabledModes = Set<InputMode>()
    for (mode, inputSource) in getInputSource(modes: InputMode.allCases) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), enabled {
        enabledModes.insert(mode)
      }
      if enabledModes.count == InputMode.allCases.count {
        break
      }
    }
    return Array(enabledModes)
  }

  func register() {
    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty {
      print("User already registered DaoHui method(s): \(enabledInputModes.map { $0.rawValue })")
      // Already registered.
      return
    }
    TISRegisterInputSource(SquirrelApp.appDir as CFURL)
    print("Registered input source from \(SquirrelApp.appDir)")
  }

  func enable(modes: [InputMode] = []) {
    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty && modes.isEmpty {
      print("User already enabled DaoHui method(s): \(enabledInputModes.map { $0.rawValue })")
      // keep user's manually enabled input modes.
      return
    }
    let modesToEnable = modes.isEmpty ? [.primary] : modes
    for (mode, inputSource) in getInputSource(modes: modesToEnable) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), !enabled {
        let error = TISEnableInputSource(inputSource)
        print("Enable \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
      }
    }
  }

  func select(mode: InputMode? = nil) {
    let enabledInputModes = enabledModes()
    let modeToSelect = mode ?? .primary
    if !enabledInputModes.contains(modeToSelect) {
      if mode != nil {
        enable(modes: [modeToSelect])
      } else {
        print("Default method not enabled yet: \(modeToSelect.rawValue)")
        return
      }
    }
    for (mode, inputSource) in getInputSource(modes: [modeToSelect]) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled),
         let selectable = getBool(for: inputSource, key: kTISPropertyInputSourceIsSelectCapable),
         let selected = getBool(for: inputSource, key: kTISPropertyInputSourceIsSelected),
         enabled && selectable && !selected {
        let error = TISSelectInputSource(inputSource)
        print("Selection \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
      } else {
        print("Failed to select \(mode.rawValue)")
      }
    }
  }

  // DaoHui: scripts/postinstall runs this in the login user's session after
  // every install or update. Replacing the bundle leaves a stale entry in the
  // user's input sources: greyed out in the menu, possibly still reported as
  // enabled but missing from AppleEnabledInputSources, so register() and
  // enable() return early and the input method stays unusable until the next
  // login. Register unconditionally, read the list again, turn the primary
  // mode off and on (enabling is what the text input server saves) and select it.
  func refresh() {
    TISRegisterInputSource(SquirrelApp.appDir as CFURL)
    print("Registered input source from \(SquirrelApp.appDir)")
    let mode = InputMode.primary
    var found: TISInputSource?
    for attempt in 1...10 {
      inputSources = Self.listInputSources()
      found = inputSources[mode.rawValue]
      if found != nil || attempt == 10 { break }
      Thread.sleep(forTimeInterval: 0.2)
    }
    guard let inputSource = found else {
      print("Input source not found after registering: \(mode.rawValue)")
      return
    }
    if getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled) == true {
      let error = TISDisableInputSource(inputSource)
      print("Disable \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
    }
    var error = TISEnableInputSource(inputSource)
    print("Enable \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
    error = TISSelectInputSource(inputSource)
    print("Selection \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
  }

  func disable(modes: [InputMode] = []) {
    let modesToDisable = modes.isEmpty ? InputMode.allCases : modes
    for (mode, inputSource) in getInputSource(modes: modesToDisable) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), enabled {
        let error = TISDisableInputSource(inputSource)
        print("Disable \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
      }
    }
  }

  private func getInputSource(modes: [InputMode]) -> [InputMode: TISInputSource] {
    var matchingSources = [InputMode: TISInputSource]()
    for mode in modes {
      if let inputSource = inputSources[mode.rawValue] {
        matchingSources[mode] = inputSource
      }
    }
    return matchingSources
  }

  private func getBool(for inputSource: TISInputSource, key: CFString!) -> Bool? {
    let enabledRef = TISGetInputSourceProperty(inputSource, key)
    guard let enabled = unsafeBitCast(enabledRef, to: CFBoolean?.self) else { return nil }
    return CFBooleanGetValue(enabled)
  }
}
