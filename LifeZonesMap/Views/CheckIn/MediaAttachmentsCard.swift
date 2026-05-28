import SwiftUI
import PhotosUI

/// Compact card on the CheckInView that lets the user attach one photo and
/// record one voice note for the week. Both optional. Lives between the
/// zone cards and the save CTA.
struct MediaAttachmentsCard: View {
    @Binding var photoData: Data?
    @Binding var audioData: Data?
    @Binding var audioDuration: Double

    @State private var photoItem: PhotosPickerItem?
    @State private var showingRecorder = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Memory hooks").uppercaseCaption()
                Spacer()
                Text("Optional")
                    .uppercaseCaption(color: LZ.inkMute, size: 9.5, tracking: 1.6)
            }
            HStack(spacing: 10) {
                photoTile
                audioTile
            }
        }
        .padding(14)
        .background(LZ.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onChange(of: photoItem) { _, newValue in
            Task {
                if let newValue,
                   let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let compressed = PhotoStore.compressed(image) {
                    photoData = compressed
                }
            }
        }
        .sheet(isPresented: $showingRecorder) {
            VoiceNoteRecorderSheet { data, duration in
                audioData = data
                audioDuration = duration
                showingRecorder = false
            }
        }
    }

    // MARK: - Tiles

    @ViewBuilder
    private var photoTile: some View {
        if let photoData, let image = UIImage(data: photoData) {
            // Filled state — preview + remove
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button {
                    self.photoData = nil
                    photoItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .black.opacity(0.5))
                }
                .padding(6)
            }
        } else {
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(LZ.inkSoft)
                    Text("Photo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LZ.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .background(LZ.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var audioTile: some View {
        if let audioData {
            VoiceNotePlaybackTile(data: audioData, duration: audioDuration) {
                self.audioData = nil
                self.audioDuration = 0
            }
        } else {
            Button { showingRecorder = true } label: {
                VStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(LZ.inkSoft)
                    Text("Voice note")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LZ.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .background(LZ.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Playback tile

struct VoiceNotePlaybackTile: View {
    let data: Data
    let duration: Double
    var onRemove: () -> Void

    @StateObject private var player = VoicePlayer()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Button {
                    if player.isPlaying { player.stop() } else { try? player.play(data) }
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(LZ.tealDeep)
                }
                .buttonStyle(.plain)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(LZ.tealDeep.opacity(0.15)).frame(height: 3)
                        Capsule().fill(LZ.tealDeep)
                            .frame(width: geo.size.width * CGFloat(player.progress), height: 3)
                    }
                }
                .frame(height: 3)

                Text(AudioFormat.mmss(duration))
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(LZ.inkSoft)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(LZ.tealDeep.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(LZ.tealDeep.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                player.stop()
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(LZ.inkSoft, LZ.cream)
            }
            .padding(6)
        }
    }
}

// MARK: - Recorder sheet

struct VoiceNoteRecorderSheet: View {
    var onSave: (Data, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder()
    @State private var permissionDenied = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 24) {
                Spacer()

                if permissionDenied {
                    permissionDeniedState
                } else {
                    waveformOrIdle
                    Text(AudioFormat.mmss(recorder.duration))
                        .font(.system(size: 40, weight: .light).monospacedDigit())
                        .tracking(-1)
                        .foregroundStyle(LZ.ink)
                    Text(recorder.isRecording ? "Recording…" : "Up to 90 seconds.")
                        .font(LZType.serifItalic(13.5))
                        .foregroundStyle(LZ.inkSoft)
                }

                Spacer()

                if recorder.isRecording {
                    Button(action: stopAndSave) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(LZ.zVitality)
                    }
                    .accessibilityLabel("Stop and save")
                } else if !permissionDenied {
                    Button(action: startRecording) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 72))
                            .foregroundStyle(LZ.tealDeep)
                    }
                    .accessibilityLabel("Start recording")
                }

                if let error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(LZ.zVitality)
                }

                Spacer().frame(height: 24)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(LZ.paper.ignoresSafeArea())
            .navigationTitle("Voice note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.cancel()
                        dismiss()
                    }
                    .foregroundStyle(LZ.inkSoft)
                }
            }
        }
    }

    private var waveformOrIdle: some View {
        Canvas { ctx, size in
            let bars = 28
            let w = size.width
            let h = size.height
            let center = h / 2
            let barW = w / CGFloat(bars) * 0.5
            let spacing = w / CGFloat(bars)
            for i in 0..<bars {
                let phase = CGFloat(i) / CGFloat(bars)
                let baseHeight = recorder.isRecording ? CGFloat(recorder.meterLevel) * h * 0.8 : 4
                // Slight per-bar variation so it doesn't look like one block
                let mod = sin(phase * .pi * 4 + CGFloat(recorder.duration) * 2) * 0.3 + 1
                let barH = max(2, baseHeight * mod)
                let x = CGFloat(i) * spacing + spacing / 4
                let rect = CGRect(x: x, y: center - barH / 2, width: barW, height: barH)
                ctx.fill(
                    Path(roundedRect: rect, cornerRadius: barW / 2),
                    with: .color(recorder.isRecording ? LZ.tealDeep : LZ.inkMute.opacity(0.4))
                )
            }
        }
        .frame(height: 64)
        .padding(.horizontal, 20)
    }

    private var permissionDeniedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.system(size: 32))
                .foregroundStyle(LZ.inkSoft)
            Text("Microphone access denied.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LZ.ink)
            Text("Enable it in Settings → Life Zones → Microphone.")
                .font(LZType.serifItalic(13))
                .foregroundStyle(LZ.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            let granted = await recorder.requestPermission()
            if !granted {
                permissionDenied = true
                return
            }
            do {
                try recorder.start()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func stopAndSave() {
        let (data, duration) = recorder.stop()
        if let data, duration > 0 {
            onSave(data, duration)
        } else {
            dismiss()
        }
    }
}
