// Toca o som de tecla com baixa latência. O zsh escreve 1 letra no FIFO por tecla:
// k = tecla comum, s = espaço, e = enter, b = apagar
import AVFoundation
import Foundation

let soundsDir = CommandLine.arguments[1]
let fifoPath = CommandLine.arguments[2]
let volume = Float(CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "0.5") ?? 0.5

func pool(_ name: String, _ count: Int = 6) -> [AVAudioPlayer] {
    let url = URL(fileURLWithPath: soundsDir).appendingPathComponent(name)
    return (0..<count).compactMap { _ in
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.prepareToPlay()
        return p
    }
}

let keyFiles = ((try? FileManager.default.contentsOfDirectory(atPath: soundsDir)) ?? [])
    .filter { $0.hasPrefix("key") }.sorted()
let keys = keyFiles.map { pool($0) }
let sounds: [UInt8: [[AVAudioPlayer]]] = [
    UInt8(ascii: "k"): keys,
    UInt8(ascii: "s"): [pool("space.wav")],
    UInt8(ascii: "e"): [pool("enter.wav")],
    UInt8(ascii: "b"): [pool("back.wav")],
]

func play(_ code: UInt8) {
    guard let variants = sounds[code], let players = variants.randomElement(), !players.isEmpty else { return }
    let player = players.first { !$0.isPlaying } ?? players.max { $0.currentTime < $1.currentTime }!
    player.volume = volume * Float.random(in: 0.8...1.0)
    player.currentTime = 0
    player.play()
}

// O_RDWR mantém o FIFO aberto mesmo sem shells conectados
let fd = open(fifoPath, O_RDWR)
guard fd >= 0 else { exit(1) }

Thread.detachNewThread {
    var buf = [UInt8](repeating: 0, count: 64)
    while true {
        let n = read(fd, &buf, buf.count)
        if n <= 0 { continue }
        let codes = Array(buf[0..<n])
        DispatchQueue.main.async { codes.forEach(play) }
    }
}
dispatchMain()
