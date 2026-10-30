//
//  DaoHuiAI.swift
//  DaoHui
//
//  AI correction of the composition: Ctrl+R (lua/asus_fix.lua of the
//  input-method data). Lua puts a ready chat-completions request in the
//  session property asus_fix_request; SquirrelInputController hands it here,
//  and the answer goes back through asus_fix_result and the key F23.
//
//  The model runs on this Mac only: llama.cpp's llama-server (listening on
//  127.0.0.1) with Qwen3.5-4B, both downloaded by the input menu item
//  「下載 AI 修正模型…」 into ~/Library/DaoHui/ai and checked against the
//  SHA-256 below. The server starts at the first Ctrl+R and stops after
//  IDLE_SECONDS without one, giving the memory back.
//

import AppKit
import CryptoKit
import Foundation

final class DaoHuiAI {
  static let shared = DaoHuiAI()

  struct Download {
    let url: URL
    let sha256: String
    let size: Int64
  }

  // llama.cpp b11559 (MIT), as on Windows (tools/fetch_assist.py).
  #if arch(arm64)
  static let server = Download(
    url: URL(string: "https://github.com/ggml-org/llama.cpp/releases/download/b11559/llama-b11559-bin-macos-arm64.tar.gz")!,
    sha256: "c6cfeaa709b8d2e47e8a50f6833d22071f7ee7079b0b1a6d704e482afe6ee2c6", size: 12_105_699)
  #else
  static let server = Download(
    url: URL(string: "https://github.com/ggml-org/llama.cpp/releases/download/b11559/llama-b11559-bin-macos-x64.tar.gz")!,
    sha256: "630d5ab669876748b4f715def6b1cbbc2a8cf836ca8310cb9e4585d5f61fe8d4", size: 11_597_115)
  #endif
  // Qwen3.5-4B (Apache-2.0), 4-bit GGUF converted by unsloth; the model
  // tools/eval_fix.py measured (held-out: 544 -> 583 of 720 sentences right).
  static let model = Download(
    url: URL(string: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/e87f176479d0855a907a41277aca2f8ee7a09523/Qwen3.5-4B-Q4_K_M.gguf")!,
    sha256: "00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4", size: 2_740_937_888)
  static let serverFolder = "llama-b11559"  // the archive's top folder
  static let port = 8739
  static let idleSeconds: TimeInterval = 600

  var dir: URL { SquirrelApp.userDir.appending(component: "ai", directoryHint: .isDirectory) }
  var modelURL: URL { dir.appending(component: "Qwen3.5-4B-Q4_K_M.gguf") }
  var serverURL: URL { dir.appending(components: Self.serverFolder, "llama-server") }
  var ready: Bool {
    FileManager.default.isExecutableFile(atPath: serverURL.path) && FileManager.default.fileExists(atPath: modelURL.path)
  }
  private(set) var downloading = false

  private var process: Process?
  private var serverUp = false
  private var waiting: [(Bool) -> Void] = []
  private var idleTimer: Timer?

  // MARK: asking

  /// The model's answer to a chat-completions body, or "!<message>" for the
  /// bubble. completion runs on the main queue.
  func ask(body: Data, completion: @escaping (String) -> Void) {
    if downloading {
      completion("!AI 修正模型下載中，完成後就能用")
      return
    }
    guard ready else {
      completion("!需要先下載 AI 修正模型：島輝選單 → 下載 AI 修正模型…")
      return
    }
    startServer { [weak self] ok in
      guard let self else { return }
      guard ok else {
        completion("!AI 修正模型無法啟動")
        return
      }
      var request = URLRequest(url: URL(string: "http://127.0.0.1:\(Self.port)/v1/chat/completions")!)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = body
      request.timeoutInterval = 60
      URLSession.shared.dataTask(with: request) { data, _, _ in
        var answer = "!AI 沒有回應"
        if let data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = object["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
          answer = content
        }
        DispatchQueue.main.async {
          self.keepAlive()
          completion(answer)
        }
      }.resume()
    }
  }

  // MARK: the server

  private func startServer(_ done: @escaping (Bool) -> Void) {
    if let process, process.isRunning, serverUp {
      done(true)
      return
    }
    waiting.append(done)
    if waiting.count > 1 { return }  // already starting
    let process = Process()
    process.executableURL = serverURL
    process.currentDirectoryURL = serverURL.deletingLastPathComponent()
    process.arguments = ["-m", modelURL.path, "--host", "127.0.0.1", "--port", String(Self.port),
                         "-ngl", "all", "-c", "4096", "-np", "1", "--reasoning", "off", "--no-webui"]
    let log = SquirrelApp.logDir.appending(component: "llama-server.log")
    try? FileManager.default.createDirectory(at: SquirrelApp.logDir, withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: log.path, contents: nil)
    if let handle = try? FileHandle(forWritingTo: log) {
      process.standardOutput = handle
      process.standardError = handle
    }
    process.terminationHandler = { [weak self] _ in
      DispatchQueue.main.async {
        self?.serverUp = false
        self?.process = nil
      }
    }
    do {
      try process.run()
    } catch {
      print("llama-server did not start: \(error)")
      finishStarting(false)
      return
    }
    self.process = process
    pollHealth(deadline: Date().addingTimeInterval(180))
  }

  private func pollHealth(deadline: Date) {
    let url = URL(string: "http://127.0.0.1:\(Self.port)/health")!
    URLSession.shared.dataTask(with: url) { [weak self] _, response, _ in
      DispatchQueue.main.async {
        guard let self else { return }
        if (response as? HTTPURLResponse)?.statusCode == 200 {
          self.serverUp = true
          self.finishStarting(true)
        } else if self.process?.isRunning != true || Date() > deadline {
          self.stop()
          self.finishStarting(false)
        } else {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.pollHealth(deadline: deadline) }
        }
      }
    }.resume()
  }

  private func finishStarting(_ ok: Bool) {
    let callbacks = waiting
    waiting = []
    callbacks.forEach { $0(ok) }
    if ok { keepAlive() }
  }

  private func keepAlive() {
    idleTimer?.invalidate()
    idleTimer = Timer.scheduledTimer(withTimeInterval: Self.idleSeconds, repeats: false) { [weak self] _ in
      self?.stop()
    }
  }

  func stop() {
    idleTimer?.invalidate()
    idleTimer = nil
    process?.terminate()
    process = nil
    serverUp = false
  }

  // MARK: downloading

  /// Fetches the server and the model (about 2.8 GB) into ~/Library/DaoHui/ai,
  /// each checked against its SHA-256; tells the user when done.
  func download() {
    guard !downloading else { return }
    if ready {
      SquirrelApplicationDelegate.showMessage(msgText: "AI 修正模型已經下載好了：打字時按 Ctrl+R")
      return
    }
    downloading = true
    SquirrelApplicationDelegate.showMessage(msgText: "開始下載 AI 修正模型（約 2.8 GB），完成後會通知你")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    fetch(Self.server) { [weak self] archive in
      guard let self else { return }
      guard let archive, self.unpack(archive) else { return self.failed("AI 修正程式下載失敗") }
      self.fetch(Self.model) { model in
        guard let model else { return self.failed("AI 修正模型下載失敗") }
        do {
          try? FileManager.default.removeItem(at: self.modelURL)
          try FileManager.default.moveItem(at: model, to: self.modelURL)
        } catch {
          return self.failed("AI 修正模型無法存檔")
        }
        self.downloading = false
        SquirrelApplicationDelegate.showMessage(msgText: "AI 修正模型下載好了：打字時按 Ctrl+R")
      }
    }
  }

  private func failed(_ message: String) {
    downloading = false
    SquirrelApplicationDelegate.showMessage(msgText: message)
  }

  /// Downloads item to a file in dir, or nil if it fails or its hash differs.
  private func fetch(_ item: Download, completion: @escaping (URL?) -> Void) {
    let target = dir.appending(component: item.url.lastPathComponent + ".part")
    URLSession.shared.downloadTask(with: item.url) { temp, response, error in
      var result: URL?
      if let temp, error == nil, (response as? HTTPURLResponse)?.statusCode == 200 {
        try? FileManager.default.removeItem(at: target)
        if (try? FileManager.default.moveItem(at: temp, to: target)) != nil,
           Self.sha256(of: target) == item.sha256 {
          result = target
        } else {
          try? FileManager.default.removeItem(at: target)
        }
      }
      DispatchQueue.main.async { completion(result) }
    }.resume()
  }

  private static func sha256(of url: URL) -> String? {
    guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
    defer { try? handle.close() }
    var hasher = SHA256()
    while let chunk = try? handle.read(upToCount: 4 << 20), !chunk.isEmpty {
      hasher.update(data: chunk)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }

  private func unpack(_ archive: URL) -> Bool {
    defer { try? FileManager.default.removeItem(at: archive) }
    try? FileManager.default.removeItem(at: dir.appending(component: Self.serverFolder))
    guard Self.run("/usr/bin/tar", ["-xzf", archive.path, "-C", dir.path]) else { return false }
    _ = Self.run("/usr/bin/xattr", ["-dr", "com.apple.quarantine", dir.appending(component: Self.serverFolder).path])
    return FileManager.default.isExecutableFile(atPath: serverURL.path)
  }

  private static func run(_ tool: String, _ arguments: [String]) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: tool)
    process.arguments = arguments
    do {
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus == 0
    } catch {
      return false
    }
  }
}
