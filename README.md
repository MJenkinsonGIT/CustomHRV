================================================================================
  CustomHRV — Garmin Connect IQ Watch App
  README & User Guide
================================================================================

Version:  1.0
Device:   Garmin Venu 3
SDK:      Connect IQ 8.4.1 / API Level 5.2
App Type: Watch App


--------------------------------------------------------------------------------
  WHAT THIS APP DOES
--------------------------------------------------------------------------------

CustomHRV is a Heart Rate Variability (HRV) tracker designed for daily morning
check-ins. Each day you take a short, still measurement (1-3 minutes) that
captures the natural variation in the time gaps between your heartbeats. Over
several days the app builds a personal baseline for you. It then compares each
new reading against that baseline and gives a readiness recommendation:

  Ready     — Your HRV is at or above normal. Train as planned.
  Moderate  — Slightly below baseline. Reduce intensity.
  Low       — Well below baseline. Rest or easy session only.

This is the same principle used by professional HRV apps, implemented directly
on-watch with no phone required during measurements.


--------------------------------------------------------------------------------
  HOW TO USE THE APP
--------------------------------------------------------------------------------

FIRST-TIME SETUP
----------------
Before you can get readiness scores, the app needs to build a personal baseline.
By default it requires 5 readings before showing a score. You can adjust this
in Settings (see the Settings section below).

Readings are most useful when taken consistently — same time each morning,
before eating or exercise, lying still. The more consistent your timing and
conditions, the more meaningful the baseline becomes.

DAILY WORKFLOW
--------------
1. Open the app. The Dashboard shows your current status.
2. Tap the screen to start a measurement.
3. Lie still with your arm relaxed for the duration (1-3 minutes, set in
   Settings). Keep as still as possible — movement causes missed heartbeat
   intervals and degrades the reading quality.
4. When the timer finishes, the Result screen appears automatically.
5. Review the result. If it looks valid, tap to save it.
6. After enough readings are saved, the Dashboard will show your readiness
   score. Swipe up from the Dashboard to see the full Recommendation screen.

SAVING VS DISCARDING
--------------------
After a measurement finishes you are shown the Result screen. The reading is
NOT automatically saved — you must tap the screen to save it. If the quality
was too poor (too much motion) the save option will not appear and you should
tap Back and try again.

GESTURE REFERENCE (applies to all screens)
------------------------------------------
  Swipe UP    = onNextPage  (goes DOWN in lists, increases values, confirms)
  Swipe DOWN  = onPreviousPage  (goes UP in lists, decreases values)
  Tap         = Select / Confirm
  Hold        = Settings menu (Dashboard only)
  Back button = Go back / Cancel

NOTE: Swipe UP and Swipe DOWN fire the callbacks named "onNextPage" and
"onPreviousPage" respectively in the Garmin SDK — the names are the opposite
of what you would expect. This is confirmed behaviour on the Venu 3.


--------------------------------------------------------------------------------
  SCREEN-BY-SCREEN GUIDE
--------------------------------------------------------------------------------

==========================
  DASHBOARD (Home Screen)
==========================

This is the first screen you see when you open the app.

WHAT IT SHOWS:
  - App name "CustomHRV" in the blue header bar.
  - If a reading was taken today (and not excluded):
      * Today's RMSSD value in the dominant colour for its readiness level
      * "ms RMSSD" label below the number
      * The readiness label (Ready / Moderate / Low) in its colour
      * Baseline value in dim grey below the label
  - If no reading has been taken today:
      * "No reading today" in grey
      * If still calibrating: "Calibrating: X/5 Readings" in yellow
      * If calibrated: "Baseline: X ms" in grey
  - If a reading exists for today, a red "Recommendation ▲" line appears
    just above the footer bar — swipe up to open the full recommendation.

FOOTER BARS (bottom of screen):
  - Dark grey bar: "Tap=Measure  ▼=Hist" — your main action hints
  - Slightly darker bar below that: "Hold Back=Settings"
  - Very bottom: "X/Y Readings" — readings used vs. baseline window size

GESTURES:
  Tap             → Go to Measure screen
  Swipe UP        → Go to Recommendation screen (only if today has a reading;
                    silently does nothing if not)
  Swipe DOWN      → Go to History screen
  Hold (long press) → Go to Settings menu


==========================
  MEASURE SCREEN
==========================

Starts automatically when you navigate to it. The sensor begins recording
immediately — do not wait, just lie still as soon as the screen appears.

WHAT IT SHOWS:
  - Top area (above blue bar): Countdown timer in MM:SS format
  - Blue header bar: Real-time quality — "X% empty - [Quality Label]"
      Quality labels: Excellent (0-20% empty), Good (21-40%), Fair (41-60%),
      Poor (61%+)
  - Main area: A live feed of incoming heartbeat interval data. Each row
    is one sensor callback, showing the R-R intervals received in that
    callback as a list of millisecond values e.g. [823,791,808]
      * Most recent callback at the top, in white
      * 2nd and 3rd rows in light grey
      * Older rows fade to dark grey
      * "-- no hrData" means no heart rate data arrived that callback
      * "[]" means the callback arrived but contained no intervals
      * "Waiting for signal..." shows before the first callback
  - Footer bar: "Stay Still  |  Back=Cancel"
  - Below footer: Count of total R-R intervals collected so far

WHAT "EMPTY %" MEANS:
  The sensor fires callbacks once per second. An "empty" callback is one
  where no valid heartbeat intervals were returned — usually because you moved
  or the sensor temporarily lost contact. The empty percentage is the proportion
  of callbacks that came back empty. Lower is better.

WHEN IT FINISHES:
  When the countdown reaches zero the sensor stops and the app automatically
  calculates RMSSD and navigates to the Result screen. You cannot extend the
  session — if you need more time, cancel and adjust Duration in Settings.

GESTURES:
  Back → Cancel the measurement and return to Dashboard (reading is discarded)


==========================
  RESULT SCREEN
==========================

Shown automatically after a measurement finishes. Review this before deciding
whether to save.

WHAT IT SHOWS (normal valid reading, calibrated):
  - Quality line under header: "X% empty - [Quality Label]" in a colour
    matching quality (green/yellow/orange/red)
  - Large RMSSD number in white
  - "ms RMSSD" label
  - Readiness label (Ready / Moderate / Low) in its colour (green/yellow/red)
  - Recommendation detail text in the same colour
  - "Baseline: X ms" in dim grey

WHAT IT SHOWS (calibrating — not enough readings yet):
  - RMSSD number in white
  - "Calibrating: X more needed" in yellow — tells you how many more valid
    readings are required before a baseline can be computed

WHAT IT SHOWS (too much motion):
  - RMSSD number in orange
  - "ms RMSSD (unreliable)" label
  - ">X% empty - try again" in red
  - The reading is flagged as unreliable. Save option is not available.

WHAT IT SHOWS (no data at all):
  - "No data" in red
  - "Keep arm still and retry" in grey
  - Save option is not available.

FOOTER:
  - If the reading is saveable: "Tap=Save  Back=Discard"
  - If saved: "Saved!" in green
  - If not saveable: "Back=Dismiss"

GESTURES:
  Tap  → Save the reading and mark as "Saved!" (can only save once)
  Back → Discard (if not yet saved) or return to Dashboard


==========================
  RECOMMENDATION SCREEN
==========================

Only accessible from the Dashboard when a reading exists for today. Shows the
full breakdown of how the recommendation was calculated.

WHAT IT SHOWS:
  - Today's RMSSD number in white
  - "ms RMSSD" label
  - Readiness label in its colour (green/yellow/red)
  - Calculation line: e.g. "47 / 30 = 63.8%"
      This shows: today's reading / baseline = percentage of baseline
  - Threshold context line showing which band this falls into, e.g.:
      ">=95%  Ready"
      ">=90%  Moderate"
      "<90%   Low"
  - Recommendation detail text in the readiness colour
  - "Baseline: X ms" in dim grey

If still calibrating (somehow reached before baseline exists):
  - RMSSD number in white
  - "Calibrating" in yellow
  - "Not enough readings yet / to compute a baseline"

GESTURES:
  Back → Return to Dashboard


==========================
  HISTORY SCREEN
==========================

A scrollable list of all saved readings, newest first.

WHAT IT SHOWS:
  - Blue header: "History"
  - Sub-header: Current baseline status — either:
      "Avg: X ms (Y/Z)"  or  "EWMA: X ms (Y/Z)"  — baseline value and how
      many readings contributed vs. the window size
      "Calibrating: Y/Z" — still collecting readings
  - Up to 4 readings visible at once. Each row shows:
      Left:   Date (YYYY-MM-DD format)
      Middle: Time (HH:MM, 24hr) — only shown if the reading has a time
      Right:  RMSSD value in ms
      Below date: Empty callback percentage, e.g. "12% empty"
              If excluded: "[excluded] 12% empty"
      Far right: ">" chevron (tap this row to open Reading Detail)

  COLOUR CODING IN ROWS:
      Excluded readings: everything shown in dark grey (#444444)
      Date shown in red if that date has more than one reading (duplicate)
      Time shown in red if the reading time is more than 3 hours away from
        your typical measurement time (time outlier)
      Empty % shown in red if it exceeds your Max Empty % setting (quality bad)
      Normal readings: date in white, time in light grey, RMSSD in white

  - Alternating rows have a very slightly lighter background for readability
  - Thin divider lines between rows

- Footer: "▲/▼=Scroll  Tap=Details"
- Below footer: Scroll position, e.g. "1-4 of 7"

GESTURES:
  Swipe UP    → Scroll down (see older readings)
  Swipe DOWN  → Scroll up (see newer readings)
  Tap a row   → Open Reading Detail for that entry
  Back        → Return to Dashboard


==========================
  READING DETAIL SCREEN
==========================

Shows everything about a single reading, including any data quality warnings.

WHAT IT SHOWS:
  - Blue header: "Reading Detail"
  - Date and time of the reading (time omitted if not recorded)
    shown in grey if excluded, white if not
  - RMSSD value — grey if excluded, white if not
  - Empty callback percentage
  - "[excluded from baseline]" shown in dim grey if the reading is excluded

DATA QUALITY FLAGS (shown if the reading is not excluded):
  If any issues exist, they appear here in red/orange/grey:

  Quality warning (too many empty callbacks):
    "! Data quality warnings:" in red
    "X% empty > Y% limit" in orange
    "Signal lost during reading" in grey

  Duplicate date warning:
    "Date matches another reading" in orange
    "One reading per day" / "is recommended" in grey

  Time outlier warning:
    "Time >Xhr from other readings" in orange
    "Same time daily for consistency" in grey

  If no issues: "No issues detected" in green

FOOTER (normal state):
  "▲=Delete  ▼=Include/Exclude"

FOOTER (confirm delete state — after first swipe up):
  "▲=Confirm Delete" in red
  "Back=Cancel" in grey below the bar

GESTURES (normal):
  Swipe UP    → Initiate delete (shows confirm prompt)
  Swipe DOWN  → Toggle excluded/included status
  Back        → Return to History (history list reloads)

GESTURES (confirm delete):
  Swipe UP    → Confirm and permanently delete the reading
  Back        → Cancel delete, return to normal state


==========================
  SETTINGS MENU
==========================

Reached by holding the back button on the Dashboard.

Shows a scrollable list of 6 settings, 4 visible at once. Each row shows the
setting name on the left and the current value in yellow on the right.

SETTINGS LIST:
  1. Avg Method       — Simple Avg or EWMA
  2. Window Size      — 5 to 30 Readings
  3. Min Readings     — 3 to 10 Needed
  4. EWMA Alpha       — 0.1 to 0.9 (displayed as 0.X)
  5. Max Empty %      — 0% to 100%
  6. Duration         — 1 to 3 Min

GESTURES:
  Swipe UP    → Scroll down the list
  Swipe DOWN  → Scroll up the list
  Tap a row   → Open the adjust screen for that setting
  Back        → Return to Dashboard


==========================
  SETTING ADJUST SCREEN
==========================

Reached by tapping a row in the Settings Menu.

WHAT IT SHOWS:
  - Blue header: The setting name
  - Small ▲ arrow above the value (swipe up to increase)
  - Current value in large yellow text
  - For range settings: "Range: min - max unit" in grey
  - For toggle settings: "Option A or Option B" in grey
  - Small ▼ arrow below the value (swipe down to decrease)
  - Three description lines explaining what the setting does
  - For EWMA Alpha only: the formula "EWMA = a*HRV + (1-a)*prev"
  - Footer: "Tap=Save  Back=Cancel"

GESTURES:
  Swipe UP    → Increase value (or toggle option)
  Swipe DOWN  → Decrease value (or toggle option)
  Tap         → Save and return to Settings Menu
  Back        → Cancel (discard changes) and return to Settings Menu


--------------------------------------------------------------------------------
  SETTINGS EXPLAINED
--------------------------------------------------------------------------------

AVG METHOD  (default: EWMA)
  Controls how the baseline is calculated from your recent readings.

  Simple Avg: Adds up all readings in the window and divides by the count.
  Every reading within the window is equally weighted. Good if your readings
  are relatively consistent.

  EWMA (Exponentially Weighted Moving Average): Gives more weight to recent
  readings and progressively less to older ones. Better if your HRV has been
  trending up or down, since the baseline will track that trend rather than
  being dragged by old data.

WINDOW SIZE  (default: 7, range: 5-30)
  How many of your most recent non-excluded readings are used to compute the
  baseline. Only readings within the last 30 calendar days are eligible
  regardless of this setting.

  Larger window = smoother baseline, less reactive to short-term changes.
  Smaller window = more reactive baseline, may fluctuate more day-to-day.

MIN READINGS  (default: 5, range: 3-10)
  How many valid readings must exist before the app will compute a baseline
  at all. Until this threshold is met, you will see "Calibrating" everywhere
  instead of a score.

  Setting this too low means the baseline is computed from very little data
  and may not be representative yet.

EWMA ALPHA  (default: 0.3, range: 0.1-0.9)
  Only relevant when Avg Method is set to EWMA.

  Alpha controls how strongly each new reading influences the baseline:
    Higher alpha (e.g. 0.7): New readings have more influence. The baseline
    tracks recent changes quickly but may feel unstable.
    Lower alpha (e.g. 0.2): More weight given to older history. Very stable
    baseline but slower to adapt to genuine fitness changes.

  The formula is: EWMA = alpha * today's HRV + (1 - alpha) * previous EWMA
  Applied repeatedly from oldest reading to newest.

MAX EMPTY %  (default: 40%, range: 0-100%)
  The threshold above which a reading is flagged as potentially unreliable
  due to motion or sensor dropout.

  If a reading's empty callback percentage exceeds this value:
  - It is still saved if you choose to save it
  - It is flagged with a warning in the History and Detail screens
  - The Result screen shows it in orange as "unreliable"
  - The flag appears in orange on the Detail screen

  Setting this to 0% means any empty callback at all triggers a flag.
  Setting this to 100% effectively disables quality flagging.

DURATION  (default: 2 minutes, range: 1-3 minutes)
  How long each measurement session runs. The countdown begins the moment
  the Measure screen appears.

  1 minute: Quick but fewer intervals collected — more variable results.
  2 minutes: Reasonable balance for most people.
  3 minutes: Most data, most stable RMSSD — recommended if you have time.


--------------------------------------------------------------------------------
  HOW THE MATH WORKS
--------------------------------------------------------------------------------

R-R INTERVALS
  Your heart does not beat at perfectly regular intervals. The gaps between
  beats (measured in milliseconds) vary slightly with every breath and with
  your nervous system state. These gaps are called R-R intervals (or IBI —
  inter-beat intervals). The Garmin optical sensor on the Venu 3 measures these
  and reports them via the heartBeatIntervals field in sensor callbacks.

RMSSD CALCULATION
  RMSSD (Root Mean Square of Successive Differences) is the standard HRV metric
  used in short-term measurements. It is calculated as follows:

  1. Collect all R-R intervals during the session (e.g. [823, 791, 808, 795...])
  2. Compute the difference between each consecutive pair:
       791-823 = -32,  808-791 = 17,  795-808 = -13 ...
  3. Square each difference:
       1024,  289,  169 ...
  4. Average the squared differences
  5. Take the square root of that average

  Higher RMSSD = more variability = generally better recovery and autonomic
  function. Lower RMSSD = less variability = may indicate fatigue or stress.

  The result is stored as a whole number in milliseconds.

QUALITY PERCENTAGE
  The "quality" stored with each reading is the percentage of sensor callbacks
  that returned at least one valid interval. A quality of 88 means 88% of
  callbacks were valid (i.e. 12% were empty).

  In the app, quality is usually displayed as "empty %" (= 100 - quality).

BASELINE COMPUTATION
  Simple Average mode: Sum all eligible readings and divide by count.

  EWMA mode: Start from the oldest eligible reading and apply the formula
  repeatedly toward the newest:
    ewma = alpha * current_reading + (1 - alpha) * ewma

  The result is rounded to the nearest whole millisecond.

READINESS BANDS
  After baseline is established, today's reading is compared:
    today / baseline * 100 = percentage of baseline

    >= 95%   → Ready    (green)
    >= 90%   → Moderate (yellow)
    <  90%   → Low      (red)

  Example: baseline = 47ms, today = 30ms
    30 / 47 * 100 = 63.8%  →  Low  →  "Rest or easy session only"

DATA QUALITY FLAGS (computed at display time, not stored)
  Three types of flags can appear on readings in History and Detail views.
  These are purely informational — they do not automatically exclude readings.

  :qualityBad     — Empty % exceeded your Max Empty % setting
  :duplicateDate  — More than one non-excluded reading shares this date
  :timeOutlier    — This reading's time is more than 3 hours away from your
                    median measurement time (suggests inconsistent timing)

  Excluded readings are never flagged (they are already out of the baseline).
  A flagged reading shown in History will have its relevant field in red.


--------------------------------------------------------------------------------
  HOW DATA IS STORED
--------------------------------------------------------------------------------

All readings are stored on-watch using Application.Storage — a key-value store
that survives app restarts and watch restarts, but is wiped if you uninstall
the app.

Settings (Window Size, Duration, etc.) are stored using Application.Properties,
which are part of the app's configuration system and persist across installs
when synced through Garmin Connect.

READING RECORD FORMAT
  Each reading is stored as a dictionary with these fields:
    "date"     — "YYYY-MM-DD" (local date when saved)
    "time"     — "HH:MM" in 24hr format (may be absent on older records)
    "rmssd"    — Integer milliseconds
    "quality"  — Integer 0-100 (percentage of valid callbacks)
    "excluded" — Boolean (true if manually excluded from baseline)

  Readings are stored oldest-first in a single array under the key "readings".
  The History screen reverses this for display (newest at top).

WHAT COUNTS TOWARD THE BASELINE
  A reading is eligible for baseline calculation if ALL of the following apply:
    - It is not marked as excluded
    - Its date is within the last 30 days
    - It falls within the most recent [Window Size] eligible readings

  Readings that are flagged for quality issues are still included unless you
  manually exclude them.


--------------------------------------------------------------------------------
  NAVIGATION MAP
--------------------------------------------------------------------------------

  [Dashboard] ──── Tap ──────────────────────────────► [Measure]
      │                                                     │
      │                                          (auto when done)
      │                                                     ▼
      │                                               [Result]
      │                                         Tap=Save, Back=Discard
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
                                                    Tap=Save
                                                    Back=Cancel


--------------------------------------------------------------------------------
  SOURCE FILE OVERVIEW
--------------------------------------------------------------------------------

CustomHRVApp.mc
  The app entry point. Creates the initial Dashboard view when the app launches.
  Also handles the onSettingsChanged() callback from Garmin Connect when
  settings are changed remotely.

HRVStorage.mc
  The entire data layer. All reads and writes to Application.Storage go through
  this class. Contains:
    - loadReadings() / saveReadings()
    - addReading() / deleteReading() / toggleExclusion()
    - computeBaseline() — returns baseline value + metadata
    - computeFlags() — analyses an array of readings for quality warnings
    - computeRMSSD() — the core HRV calculation
    - All settings accessors (getSettingWindowSize(), etc.)
    - Date/time helpers (todayString(), currentTimeString(), ageDays())
    - Private math helpers (computeSimpleAvg, computeEWMA, julianDay, etc.)

DashboardView.mc
  The home screen. Reads today's reading and baseline on every repaint.
  Handles tap (→ Measure), swipe up (→ Recommendation, conditional),
  swipe down (→ History), and hold (→ Settings).

MeasureView.mc
  Manages the live measurement session. Starts an ActivityRecording session
  and a Sensor listener when shown; stops both when hidden or cancelled.
  Uses a 1-second Timer to drive the countdown. Collects all R-R intervals
  into _allIntervals. On completion calls finishMeasurement() which computes
  RMSSD and navigates to ResultView via switchToView() (replacing itself in
  the view stack rather than pushing on top).

ResultView.mc
  Displays the measurement result. Calls HRVStorage.computeBaseline() on each
  repaint to determine the readiness category. The saveReading() method writes
  to storage exactly once (guarded by _saved flag). Navigation to this screen
  uses switchToView so pressing Back from ResultView returns to Dashboard, not
  the Measure screen.

RecommendationView.mc
  A read-only detail view of today's readiness. Recalculates baseline and reads
  today's reading on every repaint. Shows the full arithmetic breakdown.

HistoryView.mc
  Loads all readings on show (reversed for newest-first display). Calls
  HRVStorage.computeFlags() to determine warning colours. Maps tap Y-coordinates
  to row indices for detail navigation. Scroll state is preserved while the
  view stays in the stack.

DetailView.mc
  Shows all fields of a single reading plus computed flags. Manages a
  two-step delete confirmation via the _confirmDel boolean. Calls back to
  HistoryView.reload() when popped so the list reflects any changes.

SettingsView.mc
  Contains two view/delegate pairs:
    SettingsMenuView / SettingsMenuDelegate — the scrollable list of settings
    SettingAdjustView / SettingAdjustDelegate — the individual adjust screen
  Settings descriptors are built in buildDescriptors() as an array of
  dictionaries containing type, range/options, key name, and description text.
  Changes are not written to Application.Properties until Tap=Save is pressed.

ArrowUtils.mc
  A shared module with helper functions for drawing filled triangle arrows
  using fillPolygon(). Used everywhere in the app for footer hint text.
  Unicode arrow characters (▲▼) cannot be used because the Venu 3's built-in
  fonts do not include those glyphs.


--------------------------------------------------------------------------------
  BUILDING AND DEPLOYING
--------------------------------------------------------------------------------

SIMULATOR TEST
  In VS Code with the Garmin Connect IQ extension:
  Press F5 or run "Build and Run" for the venu3 or venu3_sim target.
  The simulator will launch showing the app.

REAL DEVICE
  1. Connect your Venu 3 to your PC via USB.
  2. Build for the "venu3" target (not venu3_sim).
  3. The .prg file is generated in the bin/ folder.
  4. Copy it to the GARMIN/APPS/ folder on the watch.
  5. Safely eject the watch, then find CustomHRV in your app list.

  Note: To add a custom data screen on the Venu 3, you must start an
  activity first — the data screen configuration menu is only accessible
  during an active session.

DEBUG BUILDS VS RELEASE BUILDS
  Debug: Generates bin/CustomHRV.prg.debug.xml which maps crash addresses to
    source lines. System.println() output is active. Use this during development.
  Release: Strips debug symbols, ignores println, produces a smaller binary.
    Required for Connect IQ Store submission.

  To decode a crash log (from GARMIN/APPS/LOGS/CIQ_LOG.YAML): cross-reference
  the PC addresses in the log with the .prg.debug.xml file to find the exact
  source line that crashed.


================================================================================
  END OF README
================================================================================
