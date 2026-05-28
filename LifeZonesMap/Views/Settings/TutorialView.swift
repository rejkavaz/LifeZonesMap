import SwiftUI

/// In-app tour of every feature. Reachable from Settings → Tour & help.
/// Each section is a navigable card that explains one feature area with
/// the same design vocabulary the app uses elsewhere.
struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                VStack(spacing: 10) {
                    ForEach(TutorialTopic.allTopics) { topic in
                        NavigationLink {
                            TutorialDetailView(topic: topic)
                        } label: {
                            row(for: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle("Tour & help")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("All of it, in one place").uppercaseCaption()
            Text("Every feature, explained.")
                .font(.system(size: 24, weight: .medium))
                .tracking(-0.5)
                .foregroundStyle(LZ.ink)
            Text("Browse what's here. Tap any section for the details.")
                .font(LZType.serifItalic(13.5))
                .foregroundStyle(LZ.inkSoft)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private func row(for topic: TutorialTopic) -> some View {
        HStack(spacing: 14) {
            ZoneGlyph(glyph: topic.glyph, size: 20, stroke: 1.6)
                .foregroundStyle(topic.accent)
                .padding(10)
                .background(topic.accent.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LZ.ink)
                Text(topic.summary)
                    .font(LZType.serifItalic(12.5))
                    .foregroundStyle(LZ.inkSoft)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LZ.inkMute)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Detail

struct TutorialDetailView: View {
    let topic: TutorialTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ForEach(Array(topic.sections.enumerated()), id: \.offset) { _, section in
                    sectionCard(section: section)
                }
                if let footer = topic.footer {
                    Text(footer)
                        .font(LZType.serifItalic(12.5))
                        .lineSpacing(2)
                        .foregroundStyle(LZ.inkMute)
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(LZ.paper.ignoresSafeArea())
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZoneGlyph(glyph: topic.glyph, size: 22, stroke: 1.6)
                    .foregroundStyle(topic.accent)
                Text(topic.title)
                    .font(.system(size: 26, weight: .medium))
                    .tracking(-0.55)
                    .foregroundStyle(LZ.ink)
            }
            Text(topic.summary)
                .font(LZType.serifItalic(14))
                .lineSpacing(2)
                .foregroundStyle(LZ.inkSoft)
        }
    }

    private func sectionCard(section: TutorialSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let symbol = section.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(topic.accent)
                }
                Text(section.heading)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LZ.ink)
            }
            Text(section.body)
                .font(.system(size: 14))
                .lineSpacing(2.5)
                .foregroundStyle(LZ.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LZ.cream)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(LZ.ruleSoft, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Data

struct TutorialTopic: Identifiable {
    let id: String
    let title: String
    let summary: String
    let glyph: ZoneGlyphID
    let accent: Color
    let sections: [TutorialSection]
    let footer: String?

    init(id: String, title: String, summary: String, glyph: ZoneGlyphID, accent: Color,
         sections: [TutorialSection], footer: String? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.glyph = glyph
        self.accent = accent
        self.sections = sections
        self.footer = footer
    }
}

struct TutorialSection {
    let heading: String
    let symbol: String?
    let body: String
    init(_ heading: String, symbol: String? = nil, body: String) {
        self.heading = heading; self.symbol = symbol; self.body = body
    }
}

extension TutorialTopic {
    static let allTopics: [TutorialTopic] = [
        TutorialTopic(
            id: "map",
            title: "The Map",
            summary: "A weekly radar of your seven life zones.",
            glyph: .focus,
            accent: LZ.tealDeep,
            sections: [
                TutorialSection(
                    "The radar",
                    symbol: "circle.hexagongrid.fill",
                    body: "Seven axes, one per zone. The shape fills out as you score each zone 1–10 in the weekly check-in. Each axis is dashed grid rings at 25/50/75/100% so you can read scores without a legend."
                ),
                TutorialSection(
                    "Tap a zone",
                    symbol: "hand.tap",
                    body: "Tap any colored node (or any row in the list below the canvas) to open the zone detail sheet. From there you can quick-edit this week's score, see your sparkline history, your most-used mood tags, and your best/lowest weeks for that zone."
                ),
                TutorialSection(
                    "Mark today",
                    symbol: "plus.circle",
                    body: "The + icon in the header opens a mid-week mark. Pick one zone, set a score, optional sentence. Folds into this week's check-in if one exists, or starts a sparse new one with last week's values."
                ),
                TutorialSection(
                    "Center average",
                    symbol: "circle.dashed",
                    body: "The small AVG badge at the center of the radar shows your overall mean. Useful for at-a-glance reads of whether this week is broadly up or down."
                )
            ]
        ),

        TutorialTopic(
            id: "checkin",
            title: "The Check-In",
            summary: "The weekly ritual. About 90 seconds.",
            glyph: .pen,
            accent: LZ.zCreate,
            sections: [
                TutorialSection(
                    "Score each zone 1–10",
                    symbol: "slider.horizontal.3",
                    body: "Slider with light haptic at each integer step. Score updates in real time at the top right of each card. Until you touch a slider, the score reads '—' to remind you it isn't set yet."
                ),
                TutorialSection(
                    "Tag the feeling",
                    symbol: "tag",
                    body: "Four suggested mood tags per zone plus your three most-used custom tags from history. Single-select per zone. Optional — skip the tags row entirely if you'd rather just score."
                ),
                TutorialSection(
                    "Notes in serif",
                    symbol: "text.alignleft",
                    body: "Tap 'Add a note' to expand a short freeform field per zone (120 characters). Saved with the check-in and searchable from the Journal tab."
                ),
                TutorialSection(
                    "Memory hooks",
                    symbol: "photo.on.rectangle.angled",
                    body: "Below the zone cards, attach one photo and one voice note for the week. Both optional. The photo gets resized to 1024px and JPEG-compressed; the voice note is up to 90 seconds in AAC."
                ),
                TutorialSection(
                    "The reflection prompt",
                    symbol: "quote.bubble",
                    body: "After you save, a single data-aware question pops up (e.g. 'Vitality rose by 3 this week — what changed?'). Optional. Answers are saved to the Pulse and Journal reflection feed."
                )
            ]
        ),

        TutorialTopic(
            id: "pulse",
            title: "The Pulse",
            summary: "Your monthly report and pattern view.",
            glyph: .focus,
            accent: LZ.zDeepWork,
            sections: [
                TutorialSection(
                    "Stat cards",
                    symbol: "square.grid.3x1.below.line.grid.1x2",
                    body: "Three cards: overall average, most-improved zone (largest week-over-week gain), most-consistent zone (lowest standard deviation). Quick read of the month's shape."
                ),
                TutorialSection(
                    "Trend chart with comparison",
                    symbol: "chart.line.uptrend.xyaxis",
                    body: "All seven zone lines on one chart over the last 28 days. Toggle 'Compare' to overlay the prior 28-day window as dashed ghost lines — see whether things are trending up or down vs last month."
                ),
                TutorialSection(
                    "Goal bands",
                    symbol: "target",
                    body: "If you've set a goal range for any zone (Settings → Goals), it renders as a faint colored band behind that zone's line. Just a target — never enforced."
                ),
                TutorialSection(
                    "Insight feed",
                    symbol: "lightbulb",
                    body: "Watch (warning), Lift (positive), Pattern (correlation), Trend cards generated by the pattern engine. Dismissible. The engine looks for Pearson correlations >0.65, linear trends, drain pairs, recovery weeks, weekday patterns, and self-compassion triggers (3+ zones dropping)."
                ),
                TutorialSection(
                    "Year shape",
                    symbol: "square.grid.3x3",
                    body: "Top-right icon opens the small-multiples view: every week you've ever mapped as a tiny radar, grouped by month. Tap any tile to revisit/edit that week."
                ),
                TutorialSection(
                    "Milestone ribbon",
                    symbol: "leaf",
                    body: "Quiet acknowledgments at 4 / 10 / 26 / 52 / 78 / 104 weeks. No badges, no streaks. Just a line."
                )
            ]
        ),

        TutorialTopic(
            id: "journal",
            title: "The Journal",
            summary: "The qualitative surface of the app.",
            glyph: .moon,
            accent: LZ.zInner,
            sections: [
                TutorialSection(
                    "Prompt of the week",
                    symbol: "star",
                    body: "Top card. One library prompt picked based on what your data has been doing — the zone with the lowest 3-week average, or the biggest week-over-week drop. Stable for the calendar week."
                ),
                TutorialSection(
                    "Mood drops",
                    symbol: "drop",
                    body: "One-word capture between check-ins. Tap + to log 'steady', 'tired', 'curious', 'frayed' or whatever's true right now. Optional sentence. Horizontal strip shows recent drops."
                ),
                TutorialSection(
                    "Prompt library",
                    symbol: "books.vertical",
                    body: "87 evergreen reflection questions organized by zone, plus 12 if-then implementation-intention prompts, plus your own custom prompts. Each category has a small research note explaining where the questions come from."
                ),
                TutorialSection(
                    "Three good things",
                    symbol: "leaf",
                    body: "Seligman's weekly gratitude exercise. Three positive events from the week, with WHY they happened. The 'why' step is what creates the durability — multiple RCTs show wellbeing gains 1, 3, and 6 months out."
                ),
                TutorialSection(
                    "Best possible self",
                    symbol: "sparkles",
                    body: "Lyubomirsky's 15-minute exercise: visualize your best plausible future self 5 years from now, in present tense. Four weekly sessions produce sustained optimism gains. Distraction-free editor with word count."
                ),
                TutorialSection(
                    "Search everything",
                    symbol: "magnifyingglass",
                    body: "Top-right icon. Single search across check-in notes, weekly reflections, prompt answers, and mood drops. Grouped by source."
                )
            ],
            footer: "Every reflection exercise here is rooted in peer-reviewed research. See the README's 'Research foundations' for citations."
        ),

        TutorialTopic(
            id: "siri",
            title: "Siri shortcut",
            summary: "Log a single zone by voice.",
            glyph: .spark,
            accent: LZ.zVitality,
            sections: [
                TutorialSection(
                    "Hey Siri, log my Vitality at 7",
                    symbol: "mic.fill",
                    body: "Or any zone, any score 1–10. Updates this week's check-in in place (other zones preserved), or creates a new sparse one if no check-in exists yet."
                ),
                TutorialSection(
                    "Spotlight",
                    symbol: "magnifyingglass.circle",
                    body: "The shortcut also appears in iPhone Spotlight search — just type 'Log Zone' and tap to invoke without opening the app."
                )
            ]
        ),

        TutorialTopic(
            id: "widgets",
            title: "Widgets",
            summary: "Glanceable, never demanding.",
            glyph: .house,
            accent: LZ.zFound,
            sections: [
                TutorialSection(
                    "Small (2×2)",
                    symbol: "square.grid.2x2",
                    body: "Miniature 7-zone radar polygon plus your overall average score below. Cream background tinted slightly toward the dominant zone."
                ),
                TutorialSection(
                    "Medium (4×2)",
                    symbol: "rectangle.split.3x1",
                    body: "Seven zone rows. Colored dot, name, thin progress bar, score. No average, no streaks, no decoration."
                ),
                TutorialSection(
                    "Lock screen rectangular",
                    symbol: "rectangle.lefthalf.inset.filled",
                    body: "Three zones that need care this week (lowest three), color dotted with their scores. White-on-glass via Apple's accessoryRectangular family."
                )
            ]
        ),

        TutorialTopic(
            id: "goals",
            title: "Goals",
            summary: "Optional target bands per zone.",
            glyph: .leaf,
            accent: LZ.zGrowth,
            sections: [
                TutorialSection(
                    "Set a band, not a number",
                    symbol: "target",
                    body: "Settings → Zones → Goals. For each zone you can set a lower and upper bound (e.g. 'I'd like Vitality to live between 6 and 8'). Independent per zone — skip whichever you don't care about."
                ),
                TutorialSection(
                    "Shown as faint strips on charts",
                    symbol: "chart.line.uptrend.xyaxis",
                    body: "On the Pulse trend chart, each goal renders as a translucent colored strip behind that zone's line. Lets you see at a glance whether the line is inside or outside your target."
                ),
                TutorialSection(
                    "Never enforced",
                    symbol: "leaf",
                    body: "No nag, no notification, no failure state. Hitting the band is information, not a grade. Missing it is also information."
                )
            ]
        ),

        TutorialTopic(
            id: "notifications",
            title: "Notifications",
            summary: "One gentle nudge a week. Tappable.",
            glyph: .moon,
            accent: LZ.zInner,
            sections: [
                TutorialSection(
                    "Adaptive copy",
                    symbol: "bell",
                    body: "Three message pools based on your recent average: gentle 'recovery' tone if last week ran low, neutral if mid, slightly more energetic if you've been steady. 30% chance to reference a specific zone that's been moving."
                ),
                TutorialSection(
                    "Tappable",
                    symbol: "hand.tap",
                    body: "Tap the notification to jump straight into the Check-In tab. No 'open the app then navigate' friction."
                ),
                TutorialSection(
                    "Quiet by default",
                    symbol: "moon",
                    body: "Sunday 7pm by default, configurable to any day + hour. Skip a week and we'll keep quiet. Skip a month and we'll wait for you."
                )
            ]
        ),

        TutorialTopic(
            id: "appicon",
            title: "App icon variants",
            summary: "Four themed icons in Settings → Appearance.",
            glyph: .pen,
            accent: LZ.zCreate,
            sections: [
                TutorialSection(
                    "Pick a season",
                    symbol: "app.badge",
                    body: "Cream (default), Sage Coast (forest green on sage), Clay Valley (terracotta on sand), Twilight Ridge (steel blue on slate). Switch any time without restarting."
                ),
                TutorialSection(
                    "Where the palettes come from",
                    symbol: "paintpalette",
                    body: "The same color palettes used for the onboarding wallpaper variants in the original design — Sage Coast, Clay Valley, Twilight Ridge."
                )
            ]
        ),

        TutorialTopic(
            id: "privacy",
            title: "Privacy & data",
            summary: "Local-first. Yours.",
            glyph: .house,
            accent: LZ.zFound,
            sections: [
                TutorialSection(
                    "On-device by default",
                    symbol: "lock.shield",
                    body: "Everything — your scores, notes, reflections, mood drops, photos, voice notes — lives in SwiftData on your device. The app makes no network calls unless you opt into the Anthropic API for richer insights."
                ),
                TutorialSection(
                    "Export anytime",
                    symbol: "square.and.arrow.up",
                    body: "Settings → Data → Export as JSON, CSV, or PDF report. Take your data with you whenever you want."
                ),
                TutorialSection(
                    "Delete anytime",
                    symbol: "trash",
                    body: "Settings → Data → Delete all data. Permanent. The app respects that this is your private space."
                )
            ]
        ),

        TutorialTopic(
            id: "research",
            title: "Research foundations",
            summary: "Why everything here is the way it is.",
            glyph: .leaf,
            accent: LZ.zGrowth,
            sections: [
                TutorialSection(
                    "Why no streaks",
                    symbol: "xmark.circle",
                    body: "Self-Determination Theory (Deci & Ryan 2000): extrinsic motivators like badges and points undermine intrinsic motivation. Habit research (Fogg, Clear): consistency beats perfection. We never punish missed weeks."
                ),
                TutorialSection(
                    "Why weekly, not daily",
                    symbol: "calendar",
                    body: "Day Reconstruction Method (Kahneman et al. 2004): episode-by-episode recall is more accurate than global moods, but daily check-ins suffer from same-day reactivity. The weekly window lets signal emerge from noise."
                ),
                TutorialSection(
                    "Naming feelings as regulation",
                    symbol: "tag",
                    body: "Affect labeling (Lieberman et al. 2007, UCLA): putting feelings into words activates the right ventrolateral prefrontal cortex and reduces amygdala activity. Naming is regulating."
                ),
                TutorialSection(
                    "Three Good Things",
                    symbol: "leaf",
                    body: "Seligman, Steen, Park & Peterson (2005): writing 3 specific positive events with their causes weekly produced elevated happiness and reduced depressive symptoms at 1, 3, and 6 month follow-ups. The 'why' step is essential."
                ),
                TutorialSection(
                    "Best Possible Self",
                    symbol: "sparkles",
                    body: "King (2001), Sheldon & Lyubomirsky (2006), Layous et al. (2013): 15 minutes of weekly writing about your best possible future self for 4 weeks produced sustained increases in optimism and life satisfaction."
                ),
                TutorialSection(
                    "If-Then prompts",
                    symbol: "arrow.triangle.branch",
                    body: "Gollwitzer (1999): meta-analysis across 94 studies shows 'if X happens, I will do Y' formats produce 2-3× better follow-through than vague goals."
                ),
                TutorialSection(
                    "Self-compassion",
                    symbol: "heart.text.square",
                    body: "Neff (2003, 2011): meeting hard moments with kindness reduces shame and improves recovery. When 3+ zones drop in a week, we show a kindness-framed insight, not a warning."
                )
            ],
            footer: "Full citations live in the README at github.com/rejkavaz/LifeZonesMap under 'Research foundations'."
        )
    ]
}
