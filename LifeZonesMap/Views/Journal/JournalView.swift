import SwiftUI
import SwiftData

/// The Journal tab — the qualitative surface of the app. Hosts:
/// - A mood-drop bar at the top (one-word entries between check-ins)
/// - The Prompt Library (75 evergreen questions)
/// - Recent reflections from the post-checkin flow
/// - A search bar that finds matches across every text field
struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodDrop.date, order: .reverse) private var moodDrops: [MoodDrop]
    @Query(sort: \PromptResponse.createdAt, order: .reverse) private var responses: [PromptResponse]
    @Query(sort: \WeeklyReflection.weekStartDate, order: .reverse) private var reflections: [WeeklyReflection]
    @Query(sort: \WeeklyCheckIn.weekStartDate, order: .reverse) private var checkIns: [WeeklyCheckIn]

    @State private var showingMoodEntry = false
    @State private var searchText = ""
    @State private var showingSearch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .padding(.bottom, 14)

                    moodSection
                    libraryCallout
                    goodThingsCallout
                    bestPossibleSelfCallout
                    answeredCallout
                    recentReflectionsSection
                }
                .padding(.bottom, 110)
            }
            .background(LZ.paper.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(LZ.tealDeep)
                    }
                    .accessibilityLabel("Search")
                }
            }
            .sheet(isPresented: $showingMoodEntry) {
                MoodDropEntryView { drop in
                    modelContext.insert(drop)
                    try? modelContext.save()
                    showingMoodEntry = false
                }
            }
            .sheet(isPresented: $showingSearch) {
                JournalSearchView()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Journal").uppercaseCaption()
            HStack(alignment: .firstTextBaseline) {
                Text("Where you've been")
                    .font(.system(size: 28, weight: .medium))
                    .tracking(-0.6)
                    .foregroundStyle(LZ.ink)
                Spacer()
                Text("\(totalEntries) entries")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(LZ.inkMute)
            }
        }
    }

    private var totalEntries: Int {
        moodDrops.count + responses.count + reflections.count
            + checkIns.filter { c in
                ZoneID.allCases.contains { c.note(for: $0)?.isEmpty == false }
            }.count
    }

    // MARK: - Mood drops strip

    private var moodSection: some View {
        VStack(spacing: 10) {
            HStack {
                SectionTitle(text: "Mood drops")
                Button { showingMoodEntry = true } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LZ.tealDeep)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Add mood drop")
            }
            .padding(.horizontal, 24)

            if moodDrops.isEmpty {
                emptyMoodHint
                    .padding(.horizontal, 18)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(moodDrops.prefix(20)) { drop in
                            MoodDropChip(drop: drop)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
        .padding(.bottom, 6)
    }

    private var emptyMoodHint: some View {
        Button { showingMoodEntry = true } label: {
            HStack(spacing: 10) {
                ZoneGlyph(glyph: .moon, size: 16, stroke: 1.6)
                    .foregroundStyle(LZ.tealDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Drop one word.")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(LZ.ink)
                    Text("How are you, between check-ins?")
                        .font(LZType.serifItalic(12))
                        .foregroundStyle(LZ.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(14)
            .background(LZ.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Library callout

    private var libraryCallout: some View {
        VStack(spacing: 10) {
            HStack { SectionTitle(text: "Prompt library") }
                .padding(.horizontal, 24)

            NavigationLink {
                PromptLibraryView()
            } label: {
                HStack(spacing: 14) {
                    ZoneGlyph(glyph: .pen, size: 22, stroke: 1.6)
                        .foregroundStyle(LZ.tealDeep)
                        .padding(10)
                        .background(LZ.tealDeep.opacity(0.10))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(PromptLibrary.all.count) questions, none of them small")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(LZ.ink)
                            .multilineTextAlignment(.leading)
                        Text("Browse by zone. Answer when you're ready.")
                            .font(LZType.serifItalic(12.5))
                            .foregroundStyle(LZ.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LZ.inkMute)
                }
                .padding(14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
        }
    }

    private var goodThingsCallout: some View {
        NavigationLink {
            ThreeGoodThingsView()
        } label: {
            HStack(spacing: 14) {
                ZoneGlyph(glyph: .leaf, size: 22, stroke: 1.6)
                    .foregroundStyle(LZ.zGrowth)
                    .padding(10)
                    .background(LZ.zGrowth.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Three good things")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(LZ.ink)
                    Text("A weekly gratitude exercise from Seligman's research.")
                        .font(LZType.serifItalic(12.5))
                        .foregroundStyle(LZ.inkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var bestPossibleSelfCallout: some View {
        NavigationLink {
            BestPossibleSelfView()
        } label: {
            HStack(spacing: 14) {
                ZoneGlyph(glyph: .moon, size: 22, stroke: 1.6)
                    .foregroundStyle(LZ.zInner)
                    .padding(10)
                    .background(LZ.zInner.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best possible self")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(LZ.ink)
                    Text("Fifteen minutes a week. Lyubomirsky's protocol.")
                        .font(LZType.serifItalic(12.5))
                        .foregroundStyle(LZ.inkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LZ.inkMute)
            }
            .padding(14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var answeredCallout: some View {
        Group {
            if !responses.isEmpty {
                NavigationLink {
                    AnsweredPromptsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "text.book.closed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(LZ.inkSoft)
                        Text("\(responses.count) answer\(responses.count == 1 ? "" : "s") so far")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(LZ.inkSoft)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(LZ.inkMute)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(LZ.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
        }
    }

    // MARK: - Reflections

    private var recentReflectionsSection: some View {
        Group {
            if !reflections.isEmpty {
                HStack { SectionTitle(text: "Recent reflections") }
                    .padding(.horizontal, 24)

                ReflectionFeedView(limit: 5)
            }
        }
    }
}
