# Life Zones Map

A weekly self-reflection iOS app that visualizes life balance as an interactive island map, detects patterns across zones, and surfaces personal insights over time.

![Map · Check-In · Pulse](docs/screenshots/08-hifi-three.png)

## Design

The visual identity, palette, and screen design come from a Claude Design handoff (`design/life-zones/`). The Swift code reimplements each screen pixel-by-pixel in SwiftUI + Canvas.

### The three tabs

| Map | Check-In | Pulse |
|:---:|:---:|:---:|
| ![Map](docs/screenshots/01-map.png) | ![Check-In](docs/screenshots/02-checkin.png) | ![Pulse](docs/screenshots/03-pulse.png) |
| 7-zone radar, corner ticks, center avg badge, topo backdrop | Custom slider with tick marks, tag pills, serif-italic notes | Stat cards, line chart, insight feed, connection web |

### Onboarding — 4 screens

| Welcome | Zones | Schedule | First check-in |
|:---:|:---:|:---:|:---:|
| ![Welcome](docs/screenshots/04-onboard-welcome.png) | ![Zones](docs/screenshots/05-onboard-zones.png) | ![Schedule](docs/screenshots/06-onboard-schedule.png) | ![First](docs/screenshots/07-onboard-first.png) |

### Widgets

![Widgets](docs/screenshots/09-widgets.png)

Small (radar + avg), medium (7-zone bars), lock-screen rectangular ("Needs care").

### Visual identity

![Identity](docs/screenshots/10-identity.png)

App icon (7-point polygon), Inter Medium wordmark, cream + ink + 7 muted earthy zone colors.

---

## Overview

Life Zones Map lets you check in once a week on 7 life zones — each rated 1–10. The map updates visually as scores change. After 3+ weeks, the app surfaces correlations, trends, and patterns. No streaks, no gamification, fully private by default.

### The 7 Zones

| Zone | Focus |
|---|---|
| **Vitality** | Energy, body, health |
| **Deep Work** | Focus, productivity, craft |
| **Connection** | Relationships, belonging |
| **Inner World** | Emotions, clarity, peace |
| **Creation** | Making, expression, play |
| **Foundation** | Stability, finances, routines |
| **Growth** | Learning, purpose, direction |

## Tech Stack

- **Swift 6 / SwiftUI** — iOS 17+
- **SwiftData** — on-device persistence
- **Swift Charts** — trend visualization
- **Canvas API** — custom radar map rendering
- **WidgetKit** — home screen zone snapshot
- **UserNotifications** — weekly check-in prompt
- **CoreHaptics** — slider feedback
- **Anthropic API** *(opt-in)* — richer pattern insights

## Project Structure

```
LifeZonesMap/
├── App/                    ← Entry point, TabView host
├── Models/                 ← SwiftData models, ZoneDefinition, ZoneRegistry, DesignSystem
├── Services/               ← CheckInService, PatternEngine, NotificationScheduler, ExportService
├── ViewModels/             ← @Observable VMs for Map, CheckIn, Pulse tabs
├── Views/
│   ├── Map/                ← Radar canvas, ZoneDetailSheet, history chart
│   ├── CheckIn/            ← Zone card flow, summary
│   ├── Pulse/              ← Monthly summary, trend chart, insight feed, connection web
│   ├── Onboarding/         ← 4-screen intro flow
│   └── Settings/           ← Schedule, export, zone names, API key
├── Resources/              ← Assets.xcassets
LifeZonesWidget/            ← WidgetKit extension (small/medium/lock screen)
LifeZonesMapTests/          ← Swift Testing unit tests (PatternEngine)
```

## Getting Started

### Prerequisites

- macOS 14+ with Xcode 15+
- iOS 17+ device or simulator

### Xcode Setup

1. Open Xcode → **File → New → Project** → App
2. Set:
   - **Product Name:** LifeZonesMap
   - **Team:** your team
   - **Bundle ID:** com.yourteam.lifezonesmap
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData
3. Delete the auto-generated files (`ContentView.swift`, `Item.swift`)
4. **File → Add Files to "LifeZonesMap"** → select all folders from this repo's `LifeZonesMap/` directory
5. Add a new **Widget Extension** target named `LifeZonesWidget`
6. Add the `LifeZonesWidget/` files to that target
7. Configure an **App Group** (`group.com.yourteam.lifezonesmap`) for both targets in Signing & Capabilities

### App Group Setup

In `WidgetDataProvider.swift` and `LifeZonesWidget.swift`, replace `group.com.yourteam.lifezonesmap` with your actual App Group identifier.

### Anthropic API (optional)

Users can opt in under Settings → Insights → AI Insights. The API key is stored in `UserPreferences` (never leaves the device except when making API calls).

## Architecture

```
MVVM + Services
Views ↔ @Observable ViewModels ↔ Services ↔ SwiftData
```

- **`@Observable`** (iOS 17 Observation framework) replaces `ObservableObject`
- **`PatternEngine`** runs synchronously on small datasets; no async overhead needed
- **`CheckInService`** enforces one check-in per ISO week (Mon–Sun)
- **Widget** reads from shared `UserDefaults` App Group, refreshes daily + after each check-in

## Intelligence Layer

### Local (always on)

`PatternEngine` runs four algorithms after every check-in:

| Algorithm | Trigger | Output |
|---|---|---|
| Pearson correlation | `\|r\| > 0.65`, N ≥ 4 weeks | Zone pair insight |
| Linear trend | slope ≥ 0.8 or ≤ −0.8, last 4 weeks | Rising / declining warning |
| Drain detection | zone ≥ 8 while other drops ≥ 2, repeated | Energy-drain insight |
| Recovery | 5+ zones below 5 | Recalibration prompt |

### API (opt-in)

One call per month after 4+ check-ins. Sends only zone scores (no notes, no tags) to the Anthropic API. Results cached as `ZoneInsight` with `source: .api`.

## Design System

Color tokens live in `LZ` (`Theme.swift`); typography helpers in `LZType`; spacing/radii in `DS`. All zone colors are pulled from worn cartography — muted, earthy, never neon.

| Token | Value |
|---|---|
| Cream / paper | `#F2EBDC` / `#FAF6EB` |
| Ink / ink soft / ink mute | `#262320` / `#5B554A` / `#9A9182` |
| Brand teal / teal deep | `#1D9E75` / `#15795A` |
| Vitality (terracotta) | `#BE5A45` |
| Deep Work (ink blue) | `#3C6E91` |
| Connection (moss) | `#2D9474` |
| Inner World (dusky violet) | `#6E5B8A` |
| Creation (burnt orange) | `#CC8A4A` |
| Foundation (amber ochre) | `#B6913E` |
| Growth (forest green) | `#5E8C5A` |

Typography is Inter (humanist sans, all UI) + Source Serif 4 italic (notes, quotes, page subtitles — the "field guide" voice).

---

## Roadmap

Beyond the manual weekly ritual, the obvious next step is letting the iPhone *quietly inform* each zone without ever filling in the score for you. Every integration below is **opt-in**, **on-device by default**, and **read-only** unless explicitly noted.

### HealthKit — `Vitality` becomes data-aware
Pull last 7 days of:
- Sleep duration + consistency (HKCategoryTypeIdentifierSleepAnalysis)
- Steps / active energy
- Resting heart rate, HRV
- Mindful minutes

These don't *set* your Vitality score — they appear as a small "Suggested: 7.4" chip beside the slider that you can accept or ignore. The weekly note can auto-include a one-line sleep summary ("Avg 7h12m, two short nights") if you opt in.

### Screen Time (Family Controls) — `Deep Work` and `Inner World`
With user-granted access to `DeviceActivityCenter`:
- Total productive vs. distracting app time → suggested Deep Work range
- Late-night phone use → could nudge a lower Inner World score
- Picks Up count → trends shown in Pulse

Family Controls runs in an isolated extension; raw app names never leave the device.

### Calendar / EventKit — `Connection` and `Deep Work`
- Read-only access to the user's calendar
- Count of meeting hours, # distinct people met → seeds a Connection suggestion
- Detected "focus blocks" (≥ 90min uninterrupted) → Deep Work hint
- Never reads event titles or attendee details — just durations + counts

### Focus Filters & iOS Focus modes
- Custom Focus Filter so the app can auto-mute non-essential notifications during the check-in
- Reflect the user's current Focus state on the Map header ("Currently: Reading")

### Journaling Suggestions API (iOS 17.2+)
- After a notable workout, photo cluster, or significant location visit, iOS proposes a "moment"
- App can opt into receiving relevance signals (no content) so the weekly note prompt is contextual

### App Intents & Shortcuts
- `Log my Vitality at 7` via Siri
- Home screen "Quick check-in" widget that drops you into the rating flow for a single zone
- Shortcuts can read the latest pulse insight for use in routines ("Good morning, Vitality is trending up")

### CloudKit private sync
- Opt-in iCloud sync of check-ins across iPhone / iPad / Apple Watch
- End-to-end encrypted (CloudKit Private Database)
- Sync excludes API keys and never touches a shared zone

### watchOS companion
- Complication showing this week's lowest zone
- Tap to log a one-zone quick update from the wrist
- Mirror of the lock-screen "Needs care" widget

### Apple Intelligence (iOS 18.1+)
- On-device summarization of the past month's notes ("This month you mentioned 'tired' across 3 weeks")
- Writing Tools support inside the note field
- Visual Intelligence integration is explicitly **out of scope** — this app stays text-first

### What's intentionally **not** on the roadmap
- Social features, sharing, leaderboards
- Streaks, badges, gamification
- Advertising, growth loops, retention nudges
- Background location tracking
- AI-generated reflections that don't cite the user's own data

## Milestones

| # | Milestone | Est. effort |
|---|---|---|
| 1 | Project scaffold + data models | 2h |
| 2 | Map canvas rendering | 4h |
| 3 | Check-in flow | 3h |
| 4 | Persistence + CheckInService wiring | 2h |
| 5 | PatternEngine + tests | 4h |
| 6 | Pulse view + charts | 3h |
| 7 | Notifications | 1h |
| 8 | Onboarding | 2h |
| 9 | Settings + export | 2h |
| 10 | Widget | 3h |
| 11 | Polish + TestFlight | 4h |

**Total: ~30h**

## License

MIT
