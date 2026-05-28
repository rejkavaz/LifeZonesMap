import UIKit
import AVFoundation
import OSLog

private let mediaLog = Logger(subsystem: "com.rejkavaz.LifeZonesMap", category: "Media")

// MARK: - Photo helpers

enum PhotoStore {
    /// Resize the longest edge to 1024px and re-encode as JPEG quality 0.8.
    /// Keeps SwiftData store under ~150 KB per check-in image.
    static func compressed(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        let size = image.size
        guard size.width > 0 && size.height > 0 else { return nil }
        let scale: CGFloat
        if size.width > size.height {
            scale = min(1, maxDimension / size.width)
        } else {
            scale = min(1, maxDimension / size.height)
        }
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target, format: .init(for: .init(displayScale: 1)))
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Audio recorder

/// Lightweight wrapper around AVAudioRecorder for a single-take voice note.
/// Records to a temp file, then call `finishedData()` to read it back and
/// hand to SwiftData.
@MainActor
final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var meterLevel: Float = 0   // 0...1 normalized

    private var recorder: AVAudioRecorder?
    private var displayLink: CADisplayLink?
    private var startTime: Date?
    private var tempURL: URL?

    /// Maximum length we allow — 90 seconds is plenty for a weekly thought.
    var maxDuration: TimeInterval = 90

    // MARK: - Permission

    /// Request mic permission via the iOS 17+ API.
    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Start / stop

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("life-zones-rec-\(UUID().uuidString).m4a")
        tempURL = url

        let settings: [String: Any] = [
            AVFormatIDKey:            kAudioFormatMPEG4AAC,
            AVSampleRateKey:          44_100,
            AVNumberOfChannelsKey:    1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.record(forDuration: maxDuration)
        startTime = Date()
        isRecording = true

        // Tick a display link to update duration + level for the UI
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() -> (data: Data?, duration: TimeInterval) {
        recorder?.stop()
        displayLink?.invalidate()
        displayLink = nil
        isRecording = false

        let dur = startTime.map { Date().timeIntervalSince($0) } ?? 0
        startTime = nil

        guard let url = tempURL,
              let data = try? Data(contentsOf: url) else {
            mediaLog.error("Failed to read recording data")
            return (nil, dur)
        }
        try? FileManager.default.removeItem(at: url)
        return (data, dur)
    }

    func cancel() {
        recorder?.stop()
        recorder?.deleteRecording()
        displayLink?.invalidate()
        displayLink = nil
        isRecording = false
        duration = 0
        meterLevel = 0
        startTime = nil
        if let url = tempURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Tick

    @objc private func tick() {
        guard let recorder, isRecording else { return }
        recorder.updateMeters()
        let raw = recorder.averagePower(forChannel: 0)            // dBFS, typ. -160...0
        let clamped = max(-50, min(0, raw))
        meterLevel = Float((clamped + 50) / 50)                   // 0...1
        if let start = startTime {
            duration = Date().timeIntervalSince(start)
        }
    }

    // MARK: - Delegate

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.displayLink?.invalidate()
            self.displayLink = nil
            self.isRecording = false
        }
    }
}

// MARK: - Audio player

@MainActor
final class VoicePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0

    private var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?

    func play(_ data: Data) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.play()
        isPlaying = true
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        player?.stop()
        isPlaying = false
        progress = 0
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        guard let player else { return }
        progress = player.duration > 0 ? player.currentTime / player.duration : 0
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.progress = 0
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }
}

// MARK: - Format

enum AudioFormat {
    static func mmss(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
