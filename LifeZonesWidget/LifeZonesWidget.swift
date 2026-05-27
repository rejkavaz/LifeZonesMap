import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct LifeZonesEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetDataProvider.Snapshot?
}

// MARK: - Provider

struct LifeZonesProvider: TimelineProvider {
    func placeholder(in context: Context) -> LifeZonesEntry {
        LifeZonesEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeZonesEntry) -> Void) {
        completion(LifeZonesEntry(date: Date(), snapshot: WidgetDataProvider.latestSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeZonesEntry>) -> Void) {
        let entry = LifeZonesEntry(date: Date(), snapshot: WidgetDataProvider.latestSnapshot())
        // Refresh once a day; will also refresh after a check-in via WidgetCenter.shared.reloadAllTimelines()
        let nextRefresh = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

// MARK: - Widget Configuration

struct LifeZonesWidget: Widget {
    let kind = "LifeZonesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeZonesProvider()) { entry in
            LifeZonesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Life Zones")
        .description("See your current zone balance at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@main
struct LifeZonesWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeZonesWidget()
    }
}
