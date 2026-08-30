import Foundation
import AVFoundation

/// 单词朗读(系统 TTS,离线可用)
final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    private init() {}

    static var autoSpeakEnabled: Bool {
        UserDefaults.standard.object(forKey: "autoSpeak") as? Bool ?? true
    }

    /// 连续朗读 times 遍,遍与遍之间留短暂停顿
    func speak(_ text: String, times: Int = 3) {
        guard !text.isEmpty else { return }
        stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for _ in 0..<times {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.45
            utterance.postUtteranceDelay = 0.25
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
