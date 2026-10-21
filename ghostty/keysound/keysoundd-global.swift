// Som de teclado mecânico para o Ghostty.
// Escuta as teclas do sistema (só leitura) e toca um som sempre que o Ghostty recebe a tecla —
// no prompt, no claude, no vim, em qualquer programa dentro do terminal.
import AppKit
import AVFoundation

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : NSString(string: "~/.config/ghostty/keysound").expandingTildeInPath)
let soundsDir = dir.appendingPathComponent("sounds")
let offFile = dir.appendingPathComponent("off").path
let volumeFile = dir.appendingPathComponent("volume").path
let ghosttyID = "com.mitchellh.ghostty"

func pool(_ name: String, _ count: Int = 6) -> [AVAudioPlayer] {
    (0..<count).compactMap { _ in
        let p = try? AVAudioPlayer(contentsOf: soundsDir.appendingPathComponent(name))
        p?.prepareToPlay()
        return p
    }
}

let keyFiles = ((try? FileManager.default.contentsOfDirectory(atPath: soundsDir.path)) ?? [])
    .filter { $0.hasPrefix("key") }.sorted()
let keys = keyFiles.map { pool($0) }
let space = [pool("space.wav")], enter = [pool("enter.wav")], back = [pool("back.wav")]

var volume: Float = 0.5, muted = false, lastSettingsCheck = Date.distantPast
func refreshSettings() {
    guard Date().timeIntervalSince(lastSettingsCheck) > 1 else { return }
    lastSettingsCheck = Date()
    muted = FileManager.default.fileExists(atPath: offFile)
    if let s = try? String(contentsOfFile: volumeFile, encoding: .utf8), let v = Float(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
        volume = v
    }
}

func play(_ variants: [[AVAudioPlayer]]) {
    guard let players = variants.randomElement(), !players.isEmpty else { return }
    // pega um player livre; se todos estiverem tocando, reaproveita o que começou há mais tempo
    let player = players.first { !$0.isPlaying } ?? players.max { $0.currentTime < $1.currentTime }!
    player.volume = volume * Float.random(in: 0.8...1.0)
    player.currentTime = 0
    player.play()
}

func ghosttyIsFrontmost() -> Bool {
    NSWorkspace.shared.frontmostApplication?.bundleIdentifier == ghosttyID
}

var tap: CFMachPort?
let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    refreshSettings()
    guard type == .keyDown, !muted, ghosttyIsFrontmost(),
          event.getIntegerValueField(.keyboardEventAutorepeat) == 0 else {
        return Unmanaged.passUnretained(event)
    }
    switch event.getIntegerValueField(.keyboardEventKeycode) {
    case 49: play(space)                 // espaço
    case 36, 76: play(enter)             // enter / enter do teclado numérico
    case 51, 117: play(back)             // delete / forward delete
    default: play(keys)
    }
    return Unmanaged.passUnretained(event)
}

// Precisa da permissão "Monitoramento de Entrada" (só leitura das teclas)
if !CGPreflightListenEventAccess() {
    CGRequestListenEventAccess()
}
while true {
    tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
                            callback: callback, userInfo: nil)
    if tap != nil { break }
    Thread.sleep(forTimeInterval: 3) // aguardando a permissão ser liberada
}
let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
CGEvent.tapEnable(tap: tap!, enable: true)
NSApplication.shared.setActivationPolicy(.prohibited)
NSApplication.shared.run()
