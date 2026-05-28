import Foundation

/// A single curated reflection prompt. Static — defined in code, identified
/// by a stable string id so user responses can link to it across versions.
struct Prompt: Identifiable, Hashable {
    let id: String        // stable, never reuse
    let text: String
    let zone: ZoneID?     // nil = cross-zone / open

    var category: String {
        zone.map { ZoneRegistry.definition(for: $0).name } ?? "Open"
    }
}

enum PromptLibrary {

    /// 75 evergreen prompts. Order within a zone is stable, ids never change.
    static let all: [Prompt] = vitality + deepWork + connection + innerWorld
        + creation + foundation + growth + open

    static func filtered(by zone: ZoneID?) -> [Prompt] {
        guard let z = zone else { return all }
        return all.filter { $0.zone == z }
    }

    static func prompt(id: String) -> Prompt? {
        all.first { $0.id == id }
    }

    // MARK: - By zone

    static let vitality: [Prompt] = [
        Prompt(id: "v1",  text: "When did you feel most physically alive this month?",                       zone: .vitality),
        Prompt(id: "v2",  text: "What's a small body-care habit you've been letting slide?",                 zone: .vitality),
        Prompt(id: "v3",  text: "If your energy was a weather forecast, what would today's say?",            zone: .vitality),
        Prompt(id: "v4",  text: "What does 'enough sleep' actually look like for you?",                      zone: .vitality),
        Prompt(id: "v5",  text: "Which meal of this week do you remember most clearly?",                     zone: .vitality),
        Prompt(id: "v6",  text: "If you had 20 minutes of pure movement right now, what would it be?",       zone: .vitality),
        Prompt(id: "v7",  text: "What's your body asking for that you haven't been giving it?",              zone: .vitality),
        Prompt(id: "v8",  text: "When did you last feel rested — really rested?",                            zone: .vitality),
        Prompt(id: "v9",  text: "If you could redo one meal from this week, what would you change?",         zone: .vitality),
        Prompt(id: "v10", text: "What was your most thoughtful act of self-care recently?",                  zone: .vitality)
    ]

    static let deepWork: [Prompt] = [
        Prompt(id: "w1",  text: "What's the one piece of work you most want to ship this season?",           zone: .deepWork),
        Prompt(id: "w2",  text: "Which task on your list scares you a little?",                              zone: .deepWork),
        Prompt(id: "w3",  text: "When did you last lose track of time in a good way?",                       zone: .deepWork),
        Prompt(id: "w4",  text: "What's the smallest, most boring step that would unstick a stuck project?", zone: .deepWork),
        Prompt(id: "w5",  text: "What work would you do even if no one paid you?",                           zone: .deepWork),
        Prompt(id: "w6",  text: "Which colleague's mind do you most want to think alongside?",               zone: .deepWork),
        Prompt(id: "w7",  text: "What craft skill have you been wanting to get sharper at?",                 zone: .deepWork),
        Prompt(id: "w8",  text: "What's pulling you off-focus this week?",                                   zone: .deepWork),
        Prompt(id: "w9",  text: "If you had to remove one recurring meeting, which one?",                    zone: .deepWork),
        Prompt(id: "w10", text: "What was the most satisfying problem you solved recently?",                 zone: .deepWork)
    ]

    static let connection: [Prompt] = [
        Prompt(id: "c1",  text: "Who haven't you reached out to in too long?",                                zone: .connection),
        Prompt(id: "c2",  text: "When did someone really listen to you?",                                     zone: .connection),
        Prompt(id: "c3",  text: "Which relationship in your life is undertended?",                            zone: .connection),
        Prompt(id: "c4",  text: "Who understands a part of you no one else does?",                            zone: .connection),
        Prompt(id: "c5",  text: "When did you last spend an evening phone-free with someone?",                zone: .connection),
        Prompt(id: "c6",  text: "What's a small recurring kindness you could offer someone?",                 zone: .connection),
        Prompt(id: "c7",  text: "Who needs a check-in from you this week?",                                   zone: .connection),
        Prompt(id: "c8",  text: "When did you last feel deeply seen?",                                        zone: .connection),
        Prompt(id: "c9",  text: "What's a relationship that's grown in an unexpected direction?",             zone: .connection),
        Prompt(id: "c10", text: "Who would you call if you only had ten minutes?",                            zone: .connection)
    ]

    static let innerWorld: [Prompt] = [
        Prompt(id: "i1",  text: "What feeling have you been avoiding this week?",                             zone: .innerWorld),
        Prompt(id: "i2",  text: "When did you last feel quiet inside?",                                       zone: .innerWorld),
        Prompt(id: "i3",  text: "What have you been ruminating on that no longer serves you?",                zone: .innerWorld),
        Prompt(id: "i4",  text: "If your inner critic took a day off, what would change?",                    zone: .innerWorld),
        Prompt(id: "i5",  text: "What's a belief about yourself you're ready to question?",                   zone: .innerWorld),
        Prompt(id: "i6",  text: "When did you last surprise yourself with how you felt?",                     zone: .innerWorld),
        Prompt(id: "i7",  text: "What does 'okay' look like for you right now?",                              zone: .innerWorld),
        Prompt(id: "i8",  text: "What's been heavy on your mind lately?",                                     zone: .innerWorld),
        Prompt(id: "i9",  text: "Where in your body do you carry your stress?",                               zone: .innerWorld),
        Prompt(id: "i10", text: "What's something you wish someone had told you this week?",                  zone: .innerWorld)
    ]

    static let creation: [Prompt] = [
        Prompt(id: "r1",  text: "What did you make this week — anything from a sketch to a sentence?",        zone: .creation),
        Prompt(id: "r2",  text: "Which creative pursuit have you been postponing?",                           zone: .creation),
        Prompt(id: "r3",  text: "What's the last thing you made that surprised even you?",                    zone: .creation),
        Prompt(id: "r4",  text: "If you had a free Saturday with no expectations, what would you create?",    zone: .creation),
        Prompt(id: "r5",  text: "When were you last in flow?",                                                zone: .creation),
        Prompt(id: "r6",  text: "What's a creative habit you want to start small with?",                      zone: .creation),
        Prompt(id: "r7",  text: "What old project deserves another look?",                                    zone: .creation),
        Prompt(id: "r8",  text: "Who's making things that make you want to make things?",                     zone: .creation),
        Prompt(id: "r9",  text: "What's the smallest creative experiment you could run this week?",           zone: .creation),
        Prompt(id: "r10", text: "What are you afraid people will think of what you make?",                    zone: .creation)
    ]

    static let foundation: [Prompt] = [
        Prompt(id: "f1",  text: "What's the one admin task you've been putting off the longest?",             zone: .foundation),
        Prompt(id: "f2",  text: "If your home was a person, what would they need from you this week?",        zone: .foundation),
        Prompt(id: "f3",  text: "What's your relationship with money like right now — honestly?",             zone: .foundation),
        Prompt(id: "f4",  text: "What's a routine that's serving you well?",                                  zone: .foundation),
        Prompt(id: "f5",  text: "What's a habit you'd like to take less seriously?",                          zone: .foundation),
        Prompt(id: "f6",  text: "If you had a free Sunday afternoon, what would feel most restorative?",      zone: .foundation),
        Prompt(id: "f7",  text: "What's something you signed up for that you can quit guilt-free?",           zone: .foundation),
        Prompt(id: "f8",  text: "What feels stable in your life right now?",                                  zone: .foundation),
        Prompt(id: "f9",  text: "Where in your day-to-day are you wasting energy?",                           zone: .foundation),
        Prompt(id: "f10", text: "What's something small you could automate or eliminate?",                    zone: .foundation)
    ]

    static let growth: [Prompt] = [
        Prompt(id: "g1",  text: "What did you learn this month that's reshaping how you see something?",      zone: .growth),
        Prompt(id: "g2",  text: "What's a skill you've been circling but not pursuing?",                      zone: .growth),
        Prompt(id: "g3",  text: "When were you last meaningfully wrong about something?",                     zone: .growth),
        Prompt(id: "g4",  text: "What's a question you've been sitting with?",                                zone: .growth),
        Prompt(id: "g5",  text: "Who is becoming someone you'd like to be?",                                  zone: .growth),
        Prompt(id: "g6",  text: "What's a book, podcast, or conversation that's been with you?",              zone: .growth),
        Prompt(id: "g7",  text: "Where are you growing slowly that you can't yet see?",                       zone: .growth),
        Prompt(id: "g8",  text: "What's the next edge for you?",                                              zone: .growth),
        Prompt(id: "g9",  text: "What's a comfort you're outgrowing?",                                        zone: .growth),
        Prompt(id: "g10", text: "What would your future self thank you for starting today?",                  zone: .growth)
    ]

    static let open: [Prompt] = [
        Prompt(id: "o1", text: "What surprised you this week?",                                              zone: nil),
        Prompt(id: "o2", text: "What did this week ask of you that you weren't expecting?",                  zone: nil),
        Prompt(id: "o3", text: "When did you feel most yourself?",                                           zone: nil),
        Prompt(id: "o4", text: "What's a small thing from this week worth remembering?",                     zone: nil),
        Prompt(id: "o5", text: "If you had to describe this week in three words, what would they be?",       zone: nil)
    ]
}
