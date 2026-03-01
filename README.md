# CustomHRV — Garmin Connect IQ Watch App

A Heart Rate Variability (HRV) tracker for daily morning check-ins. Each day you take a short, still measurement (1–3 minutes) that captures the natural variation in the time gaps between your heartbeats. Over several days the app builds a personal baseline. It then compares each new reading against that baseline and gives a readiness recommendation:

| Score | Meaning |
|-------|---------|
| **Ready** | HRV at or above normal. Train as planned. |
| **Moderate** | Slightly below baseline. Reduce intensity. |
| **Low** | Well below baseline. Rest or easy session only. |

This is the same principle used by professional HRV apps, implemented directly on-watch with no phone required during measurements.

**Device:** Garmin Venu 3 · **SDK:** Connect IQ 8.4.1 / API Level 5.2 · **App Type:** Watch App

---

## About This Project

This app was built through **vibecoding** — a development approach where the human provides direction, intent, and testing, and an AI (in this case, Claude by Anthropic) writes all of the code. I have no formal programming background; this is an experiment in what's possible when curiosity and AI assistance meet.

Every line of Monkey C in this project was written by Claude. My role was to describe what I wanted, test each iteration on a real Garmin Venu 3, report back what worked and what didn't, and keep pushing until the result was something I was happy with.

As part of this process, I've been building a knowledge base — a growing collection of Markdown documents that capture the real-world lessons Claude and I have uncovered together: non-obvious API behaviours, compiler quirks, layout constraints specific to the Venu 3's circular display, and fixes for bugs that aren't covered anywhere in the official SDK documentation. These files are fed back into Claude at the start of each new session so the knowledge carries forward rather than being rediscovered from scratch every time.

The knowledge base is open source. If you're building Connect IQ apps for the Venu 3 and want to skip some of the trial and error, you're welcome to use it:

**[Venu 3 Claude Coding Knowledge Base](https://github.com/MJenkinsonGIT/Venu3ClaudeCodingKnowledge)**

---

## Installation

1. Download the `.prg` file from the [Releases](#) section
2. Connect your Venu 3 via USB
3. Copy the `.prg` file to `GARMIN\APPS\` on the watch
4. Press the **Back button** on the watch — it will show "Verifying Apps"
5. Unplug once the watch finishes

The app will appear in your app list. No activity data screen setup is needed — CustomHRV is a standalone watch app, not a data field.

> **To uninstall:** Use Garmin Express. Sideloaded apps cannot be removed directly from the watch or the Garmin Connect phone app.

---

## Device Compatibility

Built and tested on: **Garmin Venu 3**
SDK Version: **8.4.1 / API Level 5.2**

Compatibility with other devices has not been tested.

---

## How to Use

### First-Time Setup

Before you can get readiness scores, the app needs to build a personal baseline. By default it requires 5 readings before showing a score. You can adjust this in Settings.

Readings are most useful when taken consistently — same time each morning, before eating or exercise, lying still. The more consistent your timing and conditions, the more meaningful the baseline becomes.

### Daily Workflow

1. Open the app. The Dashboard shows your current status.
2. Tap the screen to start a measurement.
3. Lie still with your arm relaxed for the duration (1–3 minutes, set in Settings). Keep as still as possible — movement causes missed heartbeat intervals and degrades the reading quality.
4. When the timer finishes, the Result screen appears automatically.
5. Review the result. If it looks valid, tap to save it.
6. After enough readings are saved, the Dashboard will show your readiness score. Swipe up from the Dashboard to see the full Recommendation screen.

### Saving vs Discarding

After a measurement finishes you are shown the Result screen. The reading is **not** automatically saved — you must tap the screen to save it. If the quality was too poor (too much motion) the save option will not appear and you should tap Back and try again.

### Gesture Reference (all screens)

| Gesture | Action |
|---------|--------|
| Swipe UP | `onNextPage` — goes down in lists, increases values, confirms |
| Swipe DOWN | `onPreviousPage` — goes up in lists, decreases values |
| Tap | Select / Confirm |
| Hold | Settings menu (Dashboard only) |
| Back button | Go back / Cancel |

> **Note:** Swipe UP and Swipe DOWN fire the callbacks named `onNextPage` and `onPreviousPage` respectively in the Garmin SDK — the names are the opposite of what you would expect. This is confirmed behaviour on the Venu 3.

---

## Screen-by-Screen Guide

### Dashboard (Home Screen)

The first screen you see when you open the app.

**What it shows:**
- App name "CustomHRV" in the blue header bar
- If a reading was taken today (and not excluded): today's RMSSD value in the readiness colour, the readiness label (Ready / Moderate / Low), and the baseline in dim grey
- If no reading today: "No reading today" in grey; if still calibrating, "Calibrating: X/5 Readings" in yellow; if calibrated, "Baseline: X ms" in grey
- If a reading exists for today, a red "Recommendation ▲" line appears just above the footer — swipe up to open the full recommendation

**Footer:** `Tap=Measure  ▼=Hist` and `Hold Back=Settings` · Bottom: `X/Y Readings`

**Gestures:**
- Tap → Measure screen
- Swipe UP → Recommendation screen (only if today has a reading)
- Swipe DOWN → History screen
- Hold → Settings menu

---

### Measure Screen

Starts automatically when you navigate to it. The sensor begins recording immediately — lie still as soon as the screen appears.

**What it shows:**
- Countdown timer in MM:SS
- Blue header: real-time quality — "X% empty - [Quality Label]"
  - Excellent (0–20% empty) · Good (21–40%) · Fair (41–60%) · Poor (61%+)
- Live feed of incoming heartbeat interval data, newest at top, fading to dark grey for older rows
  - `-- no hrData` = no HR data that callback · `[]` = callback arrived but no intervals · `Waiting for signal...` = before first callback
- Footer: `Stay Still  |  Back=Cancel`
- Below footer: count of total R-R intervals collected

**What "empty %" means:** The sensor fires once per second. An "empty" callback is one where no valid intervals were returned — usually because you moved or the sensor temporarily lost contact. Lower is better.

**When it finishes:** The app automatically calculates RMSSD and navigates to the Result screen. You cannot extend the session — adjust Duration in Settings if you need more time.

**Gestures:** Back → Cancel and return to Dashboard (reading discarded)

---

### Result Screen

Shown automatically after a measurement. Review this before deciding whether to save.

**Normal valid reading (calibrated):** RMSSD in white, readiness label in its colour (green/yellow/red), recommendation detail text, baseline in dim grey

**Calibrating (not enough readings yet):** RMSSD in white, "Calibrating: X more needed" in yellow

**Too much motion:** RMSSD in orange, ">X% empty - try again" in red. Save option not available.

**No data at all:** "No data" in red, "Keep arm still and retry" in grey. Save option not available.

**Footer:** `Tap=Save  Back=Discard` (if saveable) · `Saved!` in green (after saving) · `Back=Dismiss` (if not saveable)

**Gestures:** Tap → Save · Back → Discard (if unsaved) or return to Dashboard

---

### Recommendation Screen

Only accessible from the Dashboard when a reading exists for today.

**What it shows:**
- Today's RMSSD in white
- Readiness label in its colour
- Calculation line, e.g. "47 / 30 = 63.8%"
- Threshold context showing which band this falls into
- Recommendation detail text
- Baseline in dim grey

**Gestures:** Back → Dashboard

---

### History Screen

A scrollable list of all saved readings, newest first. Up to 4 rows visible at once.

**Each row shows:** Date · Time (if recorded) · RMSSD value · Empty % below the date · `>` chevron to open detail

**Colour coding:**
- Excluded readings: everything in dark grey
- Date in red: duplicate readings exist for that date
- Time in red: reading time is >3 hours from your typical measurement time
- Empty % in red: exceeds your Max Empty % setting

**Footer:** `▲/▼=Scroll  Tap=Details` · Below footer: scroll position e.g. `1-4 of 7`

**Gestures:** Swipe UP → scroll down (older) · Swipe DOWN → scroll up (newer) · Tap row → Reading Detail · Back → Dashboard

---

### Reading Detail Screen

Everything about a single reading, including data quality warnings.

**Data quality flags (shown if not excluded):**
- **Quality warning:** "X% empty > Y% limit" in orange
- **Duplicate date:** "Date matches another reading" in orange
- **Time outlier:** "Time >Xhr from other readings" in orange
- **No issues:** "No issues detected" in green

**Footer (normal):** `▲=Delete  ▼=Include/Exclude`
**Footer (confirm delete):** `▲=Confirm Delete` in red · `Back=Cancel`

**Gestures:** Swipe UP → initiate/confirm delete · Swipe DOWN → toggle excluded/included · Back → History (list reloads)

---

### Settings Menu

Reached by holding the Back button on the Dashboard. A scrollable list of 6 settings, 4 visible at once. Setting name on the left, current value in yellow on the right.

| # | Setting | Range / Options |
|---|---------|-----------------|
| 1 | Avg Method | Simple Avg / EWMA |
| 2 | Window Size | 5–30 Readings |
| 3 | Min Readings | 3–10 Needed |
| 4 | EWMA Alpha | 0.1–0.9 |
| 5 | Max Empty % | 0%–100% |
| 6 | Duration | 1–3 Min |

**Gestures:** Swipe UP/DOWN → scroll · Tap row → Setting Adjust · Back → Dashboard

---

### Setting Adjust Screen

**What it shows:** Setting name in blue header · ▲ above and ▼ below the current value · value in large yellow text · range or options in grey · description lines · `Tap=Save  Back=Cancel`

**Gestures:** Swipe UP → increase/toggle · Swipe DOWN → decrease/toggle · Tap → save · Back → cancel

---

## Settings Explained

**Avg Method** (default: EWMA)
Controls how the baseline is calculated. *Simple Avg* weights all readings equally. *EWMA* gives more weight to recent readings — better if your HRV has been trending up or down.

**Window Size** (default: 7, range: 5–30)
How many of your most recent non-excluded readings are used to compute the baseline. Only readings within the last 30 calendar days are eligible regardless of this setting. Larger = smoother; smaller = more reactive.

**Min Readings** (default: 5, range: 3–10)
How many valid readings must exist before the app will compute a baseline. Until this threshold is met, you will see "Calibrating" everywhere.

**EWMA Alpha** (default: 0.3, range: 0.1–0.9)
Only relevant when Avg Method is EWMA. Controls how strongly each new reading influences the baseline. Higher = more reactive; lower = more stable. Formula: `EWMA = alpha × today + (1 - alpha) × previous EWMA`.

**Max Empty %** (default: 40%, range: 0–100%)
The threshold above which a reading is flagged as potentially unreliable. The reading is still saved if you choose to — this flag is informational. Setting to 100% disables quality flagging.

**Duration** (default: 2 minutes, range: 1–3 minutes)
How long each measurement session runs. 1 min = quick but more variable. 3 min = most data, most stable RMSSD.

---

## How the Maths Works

### R-R Intervals

Your heart does not beat at perfectly regular intervals. The gaps between beats (in milliseconds) vary slightly with every breath and with your nervous system state. These are called R-R intervals. The Venu 3's optical sensor measures these and reports them via `heartBeatIntervals` in sensor callbacks.

### RMSSD Calculation

RMSSD (Root Mean Square of Successive Differences) is the standard HRV metric for short-term measurements:

1. Collect all R-R intervals during the session, e.g. `[823, 791, 808, 795...]`
2. Compute the difference between each consecutive pair: `-32, 17, -13...`
3. Square each difference: `1024, 289, 169...`
4. Average the squared differences
5. Take the square root

Higher RMSSD = more variability = generally better recovery. Lower RMSSD = less variability = may indicate fatigue or stress. Result stored as a whole number in milliseconds.

### Quality Percentage

The "quality" stored with each reading is the percentage of sensor callbacks that returned at least one valid interval. Displayed in the app as "empty %" = 100 − quality.

### Baseline Computation

- **Simple Average:** Sum all eligible readings, divide by count
- **EWMA:** Start from the oldest eligible reading, apply `ewma = alpha × current + (1 − alpha) × ewma` repeatedly toward newest

### Readiness Bands

```
today / baseline × 100 = percentage of baseline

>= 95%  →  Ready     (green)
>= 90%  →  Moderate  (yellow)
<  90%  →  Low       (red)
```

Example: baseline = 47 ms, today = 30 ms → 30 / 47 × 100 = 63.8% → **Low**

### Data Quality Flags

Computed at display time, not stored. Purely informational — they do not automatically exclude readings.

| Flag | Condition |
|------|-----------|
| `:qualityBad` | Empty % exceeded Max Empty % setting |
| `:duplicateDate` | More than one non-excluded reading shares this date |
| `:timeOutlier` | Reading time is >3 hours from median measurement time |

Excluded readings are never flagged.

---

## How Data is Stored

All readings are stored on-watch using `Application.Storage` — a key-value store that survives app restarts and watch restarts, but is wiped if you uninstall the app. Settings are stored in `Application.Properties` and persist across installs when synced through Garmin Connect.

### Reading Record Format

Each reading is a dictionary:

| Field | Type | Notes |
|-------|------|-------|
| `"date"` | String | `"YYYY-MM-DD"` local date |
| `"time"` | String | `"HH:MM"` 24hr — may be absent on older records |
| `"rmssd"` | Number | Integer milliseconds |
| `"quality"` | Number | Integer 0–100 (% of valid callbacks) |
| `"excluded"` | Boolean | `true` if manually excluded from baseline |

Readings are stored oldest-first under the key `"readings"`. History reverses this for display.

### What Counts Toward the Baseline

A reading is eligible if **all** of the following apply:
- Not marked as excluded
- Date is within the last 30 days
- Falls within the most recent [Window Size] eligible readings

Quality-flagged readings are included unless manually excluded.

---

## Navigation Map

```
[Dashboard] ──── Tap ──────────────────────────────► [Measure]
    │                                                     │
    │                                          (auto when done)
    │                                                     ▼
    │                                               [Result]
    │                                         Tap=Save · Back=Discard
    │
    ├── Swipe UP (today reading exists) ──────────► [Recommendation]
    │                                               Back=Dashboard
    │
    ├── Swipe DOWN ───────────────────────────────► [History]
    │                                              Tap row=Detail
    │                                              Back=Dashboard
    │                                                    │
    │                                                    ▼
    │                                             [Reading Detail]
    │                                          SwipeUp=Delete
    │                                          SwipeDown=Include/Exclude
    │                                          Back=History
    │
    └── Hold ─────────────────────────────────────► [Settings Menu]
                                                    Tap row=Adjust
                                                    Back=Dashboard
                                                          │
                                                          ▼
                                                  [Setting Adjust]
                                                  SwipeUp=Increase
                                                  SwipeDown=Decrease
                                                  Tap=Save · Back=Cancel
```

---

## Source File Overview

| File | Responsibility |
|------|---------------|
| `CustomHRVApp.mc` | App entry point; creates Dashboard view; handles `onSettingsChanged()` |
| `HRVStorage.mc` | Entire data layer — all reads/writes to `Application.Storage`; `computeBaseline()`, `computeFlags()`, `computeRMSSD()`, all settings accessors, date/time helpers |
| `DashboardView.mc` | Home screen; reads today's reading and baseline on every repaint; handles all Dashboard gestures |
| `MeasureView.mc` | Live measurement session; starts `ActivityRecording` session and sensor listener on show; stops both on hide/cancel; drives countdown via `Timer`; navigates to Result via `switchToView()` |
| `ResultView.mc` | Displays measurement result; calls `computeBaseline()` on each repaint; writes to storage once (guarded by `_saved` flag); Back returns to Dashboard not Measure |
| `RecommendationView.mc` | Read-only readiness detail; recalculates baseline and reads today's reading on every repaint |
| `HistoryView.mc` | Loads all readings on show (reversed); calls `computeFlags()` for warning colours; maps tap Y-coordinates to row indices; scroll state preserved while in stack |
| `DetailView.mc` | Shows all fields plus computed flags; two-step delete confirmation via `_confirmDel`; calls `HistoryView.reload()` on pop |
| `SettingsView.mc` | Two view/delegate pairs: `SettingsMenuView` (scrollable list) and `SettingAdjustView` (individual adjust); settings descriptors built in `buildDescriptors()`; changes written to `Application.Properties` only on Tap=Save |
| `ArrowUtils.mc` | Shared module for drawing filled triangle arrows via `fillPolygon()` — Unicode arrow characters (▲▼) cannot be used on Venu 3 as the built-in fonts lack those glyphs |

---

## Building and Deploying

### Simulator

In VS Code with the Garmin Connect IQ extension, press **F5** or run "Build and Run" for the `venu3` target.

### Real Device

1. Connect your Venu 3 via USB
2. Build for the `venu3` target (not `venu3_sim`) — **Ctrl+F5**
3. Copy the `.prg` from `bin/` to `GARMIN\APPS\` on the watch
4. Press the **Back button** on the watch — it will show "Verifying Apps"
5. Unplug once the watch finishes

### Debug vs Release

**Debug builds** generate `bin/CustomHRV.prg.debug.xml` which maps crash addresses to source lines. `System.println()` output is active. Use during development.

**Release builds** strip debug symbols, ignore `println`, and produce a smaller binary. Required for Connect IQ Store submission.

To decode a crash log from `GARMIN\APPS\LOGS\CIQ_LOG.YAML`: cross-reference the PC addresses in the log with the `.prg.debug.xml` file to find the exact source line that crashed.
