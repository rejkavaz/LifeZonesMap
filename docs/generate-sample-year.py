"""
Generate a year of realistic mock data for Life Zones Map.

Produces docs/sample-year.lifezones.json — a complete backup file the app's
"Import from file" feature can ingest. Hand-tuned to demonstrate every
pattern the engine can detect (correlations, trends, drains, recovery,
weekday patterns, milestones) without looking artificial.

Story arc:
  W1–13   (Mar-May): Settling in. Everything in the 5-6 band.
  W14–26  (Jun-Aug): A stressful work stretch. Vitality + Inner World drop.
                     Deep Work pushes upward but at cost.
  W27–39  (Sep-Nov): Recovery. Deliberate effort on Connection (you reach
                     out). Inner World climbs as a result. Vitality stabilizes.
  W40–52  (Dec-Feb): Stronger overall. Creation and Growth move together.
                     Foundation steady. The year-shape view will look like an
                     actual life.

Run: python docs/generate-sample-year.py
"""
import json
import math
import random
import uuid
from datetime import datetime, timedelta, timezone

random.seed(42)  # deterministic output across runs

# --- Setup ----------------------------------------------------------------

# 52 weeks ending on the Monday before today
TODAY = datetime(2027, 1, 11, tzinfo=timezone.utc)  # use a fixed "now" for reproducibility
LAST_MONDAY = TODAY - timedelta(days=TODAY.weekday())

ZONES = ["vitality", "deepWork", "connection", "innerWorld",
         "creation", "foundation", "growth"]

# --- Score generator ------------------------------------------------------

def clamp(v, lo=1, hi=10):
    return max(lo, min(hi, int(round(v))))

def base_curve(week_index):
    """
    Returns per-zone score trajectories across 52 weeks.
    Each is (mean at week 0) + drift over time + sinusoidal monthly variation
    + per-zone noise. Tuned so the story arc shows up in the trend chart.
    """
    t = week_index / 52  # 0..1 across the year

    # Story arc:
    # vitality:    starts mid, dips weeks 14-26, recovers by 40
    if week_index < 14:
        vit = 6.0 + 0.3 * math.sin(week_index * 0.4)
    elif week_index < 27:
        vit = 5.5 - (week_index - 14) * 0.18 + 0.3 * math.sin(week_index * 0.5)
    elif week_index < 40:
        vit = 3.5 + (week_index - 27) * 0.25 + 0.3 * math.sin(week_index * 0.4)
    else:
        vit = 7.0 + 0.2 * math.sin(week_index * 0.6)

    # deepWork: ramps up through stress period (overwork), then settles
    if week_index < 13:
        work = 5.5 + week_index * 0.05
    elif week_index < 27:
        work = 6.5 + (week_index - 13) * 0.15  # climbs hard
    elif week_index < 40:
        work = 8.0 - (week_index - 27) * 0.08
    else:
        work = 7.2 + 0.2 * math.sin(week_index * 0.5)

    # connection: low during stress, deliberate climb in recovery
    if week_index < 27:
        con = 6.0 - week_index * 0.05 + 0.2 * math.sin(week_index * 0.6)
    elif week_index < 40:
        con = 5.0 + (week_index - 27) * 0.25
    else:
        con = 7.5 + 0.2 * math.sin(week_index * 0.7)

    # innerWorld: closely tracks vitality (creates a correlation insight)
    inner = vit - 0.5 + 0.2 * math.sin(week_index * 0.3)

    # creation: rises with the year, with monthly oscillation
    cre = 5.5 + t * 1.5 + 0.5 * math.sin(week_index * 0.4)

    # foundation: steady, slowly improving
    fnd = 6.5 + t * 1.0 + 0.2 * math.sin(week_index * 0.5)

    # growth: rises with vitality + creation
    gro = (cre + vit) / 2 - 0.5 + 0.2 * math.sin(week_index * 0.6)

    raw = {
        "vitality":   vit,
        "deepWork":   work,
        "connection": con,
        "innerWorld": inner,
        "creation":   cre,
        "foundation": fnd,
        "growth":     gro,
    }
    # Per-zone noise so weeks aren't suspiciously smooth
    return {z: clamp(v + random.uniform(-0.7, 0.7)) for z, v in raw.items()}


# --- Tags + notes pools ---------------------------------------------------

TAG_POOLS = {
    "vitality":   ["Slept well", "Moved", "Foggy", "Wired"],
    "deepWork":   ["In flow", "Shipped", "Distracted", "Stuck"],
    "connection": ["Saw friends", "Called family", "Lonely", "Drained"],
    "innerWorld": ["Steady", "Anxious", "Curious", "Tender"],
    "creation":   ["Made things", "Stalled", "Inspired", "Quiet"],
    "foundation": ["On top", "Tidy", "Behind", "Worried"],
    "growth":     ["Learning", "Stretching", "Coasting", "Drifting"],
}

NOTE_POOLS = {
    "vitality": [
        "Walked twice this week. Sleep was uneven Tuesday-Thursday but came back by the weekend.",
        "Body felt tense most days. Need to leave the laptop downstairs.",
        "Three good nights of sleep. Body remembers what that feels like.",
        "Skipped exercise. The week ran me.",
        "First proper long walk in months. Should not have waited.",
    ],
    "deepWork": [
        "Two solid focus blocks Tuesday morning. Wednesday was meeting-shaped.",
        "Shipped the thing I'd been circling. Boring last step turned out to be the unlock.",
        "Couldn't get traction. Probably need fewer slack notifications.",
        "Felt the loss of time I usually have. The work that mattered didn't get done.",
        "Wrote three good paragraphs. Threw away one. Net positive.",
    ],
    "connection": [
        "Long call with M. We hadn't talked in two months.",
        "Family dinner Sunday. Phones in the basket.",
        "Skipped two opportunities to text people back. Habit I want to break.",
        "Coffee with someone I'd been undertending. They'd been worried.",
        "Quiet week, socially. Felt OK about it.",
    ],
    "innerWorld": [
        "Tense undertone Wednesday. Couldn't name it.",
        "Calm enough by Friday to read.",
        "Caught myself ruminating about the meeting. Talked myself out of it after.",
        "Steady. Surprised by how steady, given everything.",
        "Couldn't quite settle. Read instead of doom-scrolling. Small win.",
    ],
    "creation": [
        "Made nothing this week. Read three good things from other people though.",
        "Drafted the first half of something. Real start.",
        "Picked the guitar up after a year. Sounded terrible.",
        "Sketched for thirty minutes on Saturday morning. Honest fun.",
        "Wrote and threw away. Counts.",
    ],
    "foundation": [
        "Did the laundry. Did the dishes. Sometimes that's everything.",
        "Bills handled. Inbox almost at zero.",
        "Behind on the boring stuff and trying to make peace with that.",
        "Sorted the cupboard that had been bugging me for a month.",
        "Made the appointment I'd been avoiding.",
    ],
    "growth": [
        "Read two chapters of the thing I keep coming back to.",
        "Took the harder option in a small choice. Felt it after.",
        "Coasted. Comfortable. Worth naming.",
        "Tried something I was certain to be bad at. Was bad at it. OK.",
        "A long conversation that reshaped something I thought I'd settled.",
    ],
}

def iso(d):
    return d.isoformat().replace("+00:00", "Z")

def new_uuid():
    return str(uuid.uuid4()).upper()

# --- Build check-ins ------------------------------------------------------

def week_start(i):
    """Returns the Monday for week_index i (0 = oldest, 51 = latest)."""
    weeks_back = 51 - i
    return LAST_MONDAY - timedelta(weeks=weeks_back)

check_ins = []
for i in range(52):
    monday = week_start(i)
    scores = base_curve(i)

    # ~60% of weeks get at least one tag, ~40% get at least one note
    tags = {}
    notes = {}
    for zone in ZONES:
        if random.random() < 0.45:
            tags[zone] = random.choice(TAG_POOLS[zone])
        if random.random() < 0.20:
            notes[zone] = random.choice(NOTE_POOLS[zone])

    created = monday + timedelta(hours=19 + random.randint(0, 3),
                                 minutes=random.randint(0, 59))

    check_ins.append({
        "id":             new_uuid(),
        "weekStartDate":  iso(monday),
        "createdAt":      iso(created),
        "scores":         scores,
        "tags":           tags,
        "notes":          notes,
        "photoData":      None,
        "audioData":      None,
        "audioDuration":  0,
    })

# --- Reflections (post-checkin questions) ---------------------------------

REFLECTION_SAMPLES = [
    ("Deep Work rose by 2 this week. What changed?",
     "I closed Slack between 9 and 11 every morning. That's it. That was the whole trick."),
    ("Vitality dropped by 3. Anything worth naming?",
     "Two nights of poor sleep + the meeting I'd been dreading. Body knew before I did."),
    ("Connection has been quiet — how is it?",
     "I noticed I'd been letting texts pile up. Wrote back to three people today."),
    ("Inner World is at 4 this week. What would a 6 look like?",
     "Less time on my phone before bed. Reading instead. The thing I keep saying I'll do."),
    ("What did this week ask of you that you weren't expecting?",
     "Saying no to something I'd already agreed to. It was harder than I thought it would be."),
    ("What's a small thing from this week worth remembering?",
     "Sunday morning walk with no phone. Heard birds I'd been missing."),
]

reflections = []
for i, (prompt, response) in enumerate(REFLECTION_SAMPLES):
    week_i = 8 + i * 7
    monday = week_start(week_i)
    reflections.append({
        "id":            new_uuid(),
        "weekStartDate": iso(monday),
        "createdAt":     iso(monday + timedelta(hours=20)),
        "prompt":        prompt,
        "response":      response,
    })

# --- Prompt responses (from the library + practices) ----------------------

PROMPT_RESPONSE_SAMPLES = [
    ("c1", "Reached out to Sam — we hadn't talked in months. Took 90 seconds."),
    ("i1", "The dread about Wednesday's meeting. I've been pretending it wasn't there."),
    ("w3", "Saturday morning. Working on the cabinet. Three hours felt like twenty minutes."),
    ("v8", "Last Sunday. Slept ten hours and woke up without an alarm. Felt almost foreign."),
    ("g4", "What I actually want my work to look like in five years vs what it looks like now."),
    ("if4", "When I open my laptop, the first thing I will do is open the doc I'm avoiding — not Slack."),

    # Best Possible Self entries
    ("bps-current",
     "Five years from now I live somewhere with a real morning. Coffee, the long walk, then work that I chose. The work is harder than now but I'm steadier inside it. There's a person I love and we know each other well by then. My body still works — I take it on long walks and it surprises me. I have time to make things badly. I read more than I scroll. Money isn't the constant background hum it is now. I'm closer to my parents than I ever expected to be."),

    # Gratitude letter
    ("gratitude-letter",
     "To J:\n\nI don't think I ever properly thanked you for the call last September. I was unraveling and didn't quite know it, and you noticed before I did. You asked one specific question that I'd been avoiding for months, and you didn't let me deflect. The answer took me three more weeks to find, but the question was the unlock. I don't think you've thought about that call since. I think about it almost weekly."),

    # Self-compassion break
    ("self-compassion-break", "Self-compassion break · \"The meeting felt like a verdict and I'd been carrying it around for three days.\""),

    # LKM session
    ("lkm-session", "Loving-kindness session · 5:23 over 5 steps"),

    # Naikan
    ("naikan-reflection",
     "About: Mom\n\nRECEIVED\nTime, mostly. So much of it. The phone calls every Sunday. The visits. The small noticing.\n\nGIVEN\nLess than I should have. I called less than she'd have liked. Showed up when I needed to, not when she did.\n\nTROUBLES CAUSED\nLong stretches of quiet she had to be patient through. The worry I gave her when I went silent. The conversations she wanted to have that I deferred."),

    # Behavioral activation plans
    ("behavioral-activation",
     "category=connection\nstatus=DONE\nactivity=Call A. on Tuesday evening for at least 30 minutes.\nwhen=Tuesday after dinner"),
    ("behavioral-activation",
     "category=pleasure\nstatus=DONE\nactivity=Long Saturday walk with no podcast — just notice things.\nwhen=Saturday 10am"),
    ("behavioral-activation",
     "category=mastery\nstatus=SKIPPED\nactivity=Finish the cabinet that's been sitting half-built.\nwhen=Sunday afternoon"),
]

prompt_responses = []
for i, (prompt_id, body) in enumerate(PROMPT_RESPONSE_SAMPLES):
    base_week = max(0, 52 - 3 - i * 3)
    created = week_start(base_week) + timedelta(hours=20)
    prompt_responses.append({
        "id":        new_uuid(),
        "promptID":  prompt_id,
        "response":  body,
        "createdAt": iso(created),
    })

# --- Mood drops (between check-ins) ---------------------------------------

MOOD_WORDS = [
    "steady", "tired", "curious", "wired", "foggy", "soft", "frayed",
    "hopeful", "scattered", "lit", "quiet", "tender", "anxious",
    "restless", "content", "sharp", "alive", "stuck", "purposeful",
    "vague", "calm", "buzzy", "patient", "worn", "open", "guarded"
]
MOOD_DETAILS = [
    "", "", "",  # weight empty
    "Could not pinpoint why.",
    "Slept well last night.",
    "Meeting tomorrow weighing on me.",
    "Cold rain. Liked it.",
    "Calmed by the time I made coffee.",
    "Caught it before it became something bigger.",
    "Sunday-morning kind.",
]

mood_drops = []
for i in range(60):
    days_ago = i * 5 + random.randint(0, 4)
    when = TODAY - timedelta(days=days_ago)
    mood_drops.append({
        "id":     new_uuid(),
        "date":   iso(when),
        "mood":   random.choice(MOOD_WORDS),
        "detail": random.choice(MOOD_DETAILS),
    })

# --- Zone goals (a couple) ------------------------------------------------

goals = [
    {
        "id":           new_uuid(),
        "zoneIDRaw":    "vitality",
        "lowerBound":   6,
        "upperBound":   8,
        "note":         "Don't grind past 8 — leave room for life.",
        "createdAt":    iso(week_start(20)),
    },
    {
        "id":           new_uuid(),
        "zoneIDRaw":    "deepWork",
        "lowerBound":   6,
        "upperBound":   9,
        "note":         "8s are great. 9s mean I'm overdoing it.",
        "createdAt":    iso(week_start(20)),
    },
]

# --- Three Good Things ----------------------------------------------------

GOOD_THINGS = [
    ("Coffee on the porch on Saturday morning",
     "Because I went to bed early Friday. Compounding effect."),
    ("Finished the cabinet I'd been avoiding",
     "Because I gave myself 25 minutes instead of telling myself it had to be the whole afternoon."),
    ("Long honest conversation with J",
     "Because I asked the question I'd been avoiding instead of the small-talk one."),
    ("Walked 11k steps on a workday",
     "Because I took meetings on foot."),
    ("Read for an hour without picking up my phone",
     "Because I left it in the other room."),
    ("Cooked the meal I'd been thinking about",
     "Because Saturday had no other commitments."),
]

good_things = []
for i, (text, why) in enumerate(GOOD_THINGS):
    week_i = 30 + i * 3
    monday = week_start(min(51, week_i))
    good_things.append({
        "id":            new_uuid(),
        "weekStartDate": iso(monday),
        "text":          text,
        "why":           why,
        "createdAt":     iso(monday + timedelta(hours=21)),
    })

# --- Custom prompts -------------------------------------------------------

custom_prompts = [
    {
        "id":         new_uuid(),
        "text":       "What did I almost talk myself out of this week, and did I do it anyway?",
        "zoneIDRaw":  "growth",
        "createdAt":  iso(week_start(35)),
    },
    {
        "id":         new_uuid(),
        "text":       "Whose voice was I hearing in my head this week?",
        "zoneIDRaw":  "innerWorld",
        "createdAt":  iso(week_start(40)),
    },
]

# --- Preferences ----------------------------------------------------------

preferences = {
    "id":                       new_uuid(),
    "checkInDayOfWeek":         0,    # Sunday
    "checkInHour":              19,
    "enableHaptics":            True,
    "enableInsights":           True,
    "insightAPIEnabled":        False,
    "anthropicAPIKey":          "",
    "customZoneNames":          {},
    "onboardingComplete":       True,
    "notificationsEnabled":     True,
    "hasSeenMapTip":            True,
    "appLockEnabled":           False,
    "healthKitVitalityEnabled": False,
}

# --- Assemble + write -----------------------------------------------------

archive = {
    "version":         1,
    "exportedAt":      iso(TODAY),
    "appVersion":      "sample-year",
    "checkIns":        check_ins,
    "reflections":     reflections,
    "promptResponses": prompt_responses,
    "moodDrops":       mood_drops,
    "goals":           goals,
    "goodThings":      good_things,
    "customPrompts":   custom_prompts,
    "preferences":     preferences,
}

import os
out_path = os.path.join(os.path.dirname(__file__), "sample-year.lifezones.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(archive, f, indent=2, sort_keys=True)
print(f"Wrote {out_path}")
print(f"  {len(check_ins)} check-ins")
print(f"  {len(reflections)} reflections")
print(f"  {len(prompt_responses)} prompt responses")
print(f"  {len(mood_drops)} mood drops")
print(f"  {len(goals)} goals")
print(f"  {len(good_things)} good things")
print(f"  {len(custom_prompts)} custom prompts")
