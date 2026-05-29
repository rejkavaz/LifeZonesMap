import TipKit
import SwiftUI

/// Catalog of TipKit hints attached around the app. Each fires once-ever per
/// install. Configure() runs at launch (App.init) to register them.

@available(iOS 17.0, *)
enum AppTips {
    static func configure() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
}

// MARK: - Tips

@available(iOS 17.0, *)
struct MarkTodayTip: Tip {
    var id: String { "MarkTodayTip" }
    var title: Text { Text("Mark today") }
    var message: Text? {
        Text("Drop a one-zone update between weekly check-ins.")
    }
    var image: Image? { Image(systemName: "plus.circle") }
}

@available(iOS 17.0, *)
struct TapZoneTip: Tip {
    var id: String { "TapZoneTip" }
    var title: Text { Text("Tap any zone") }
    var message: Text? {
        Text("Open its history, mood tags, and a quick-edit slider for this week.")
    }
    var image: Image? { Image(systemName: "hand.tap") }
}

@available(iOS 17.0, *)
struct CompareLastWeekTip: Tip {
    var id: String { "CompareLastWeekTip" }
    var title: Text { Text("Compare to last week") }
    var message: Text? {
        Text("Toggle this for a dashed overlay of the previous check-in.")
    }
    var image: Image? { Image(systemName: "rectangle.on.rectangle") }
}

@available(iOS 17.0, *)
struct PracticesTip: Tip {
    var id: String { "PracticesTip" }
    var title: Text { Text("Evidence-based practices") }
    var message: Text? {
        Text("Three good things, gratitude letter, loving-kindness, more — each cited.")
    }
    var image: Image? { Image(systemName: "leaf") }
}

@available(iOS 17.0, *)
struct JournalSearchTip: Tip {
    var id: String { "JournalSearchTip" }
    var title: Text { Text("Search everything") }
    var message: Text? {
        Text("Find any word across your check-in notes, reflections, prompts, and mood drops.")
    }
    var image: Image? { Image(systemName: "magnifyingglass") }
}

@available(iOS 17.0, *)
struct InsightExplainTip: Tip {
    var id: String { "InsightExplainTip" }
    var title: Text { Text("Tap to see why") }
    var message: Text? {
        Text("Every insight card opens to show the underlying data.")
    }
    var image: Image? { Image(systemName: "info.circle") }
}
