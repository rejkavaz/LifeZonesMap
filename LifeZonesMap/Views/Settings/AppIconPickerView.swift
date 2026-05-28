import SwiftUI

struct AppIconPickerView: View {
    @State private var current: AppIconVariant = .default
    @State private var pending: AppIconVariant?
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pick an app icon")
                    .uppercaseCaption()
                Text("Four variants — your home screen, your weather.")
                    .font(LZType.serifItalic(13.5))
                    .foregroundStyle(LZ.inkSoft)
                    .padding(.bottom, 4)

                if !AlternateIconService.isSupported {
                    Label("Your iOS version doesn't support alternate icons.",
                          systemImage: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundStyle(LZ.inkSoft)
                }

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(AppIconVariant.allCases) { variant in
                        Button {
                            select(variant)
                        } label: {
                            tile(for: variant)
                        }
                        .buttonStyle(.plain)
                        .disabled(pending != nil)
                    }
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundStyle(LZ.zVitality)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("App icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { current = AlternateIconService.current }
    }

    private func tile(for variant: AppIconVariant) -> some View {
        let isCurrent = current == variant
        let isPending = pending == variant
        return VStack(spacing: 10) {
            // Icon preview — rounded square with the polygon mark
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(variant.previewBackground)
                    .frame(width: 110, height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                IslandPolygon(
                    offsets: [0.95, 0.78, 1.0, 0.86, 0.92, 0.74, 1.0],
                    radiusFactor: 0.42
                )
                .fill(variant.previewForeground.opacity(0.94))
                .frame(width: 110, height: 110)
                Circle()
                    .fill(variant.previewBackground)
                    .frame(width: 3.5, height: 3.5)
                if isPending {
                    Color.black.opacity(0.25)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(width: 110, height: 110)
                    ProgressView().tint(.white)
                }
            }

            Text(variant.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isCurrent ? LZ.tealDeep : LZ.ink)
            if isCurrent {
                Text("Current")
                    .uppercaseCaption(color: LZ.tealDeep, size: 9, tracking: 1.6)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isCurrent ? LZ.tealDeep.opacity(0.07) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isCurrent ? LZ.tealDeep.opacity(0.4) : LZ.ruleSoft, lineWidth: 0.5)
        )
    }

    private func select(_ variant: AppIconVariant) {
        guard variant != current, pending == nil else { return }
        pending = variant
        errorMessage = nil
        Task {
            do {
                try await AlternateIconService.apply(variant)
                current = variant
            } catch {
                errorMessage = error.localizedDescription
            }
            pending = nil
        }
    }
}
