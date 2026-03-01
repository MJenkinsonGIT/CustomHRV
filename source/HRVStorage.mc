import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.System;

// ─────────────────────────────────────────────────────────────────────────────
// HRVStorage
// Central data layer. All reads/writes to Application.Storage go through here.
//
// Storage schema — each reading is a Dictionary:
//   "date"     => String "YYYY-MM-DD"
//   "time"     => String "HH:MM"  (24hr, added in v1.1 — may be null on old entries)
//   "rmssd"    => Number (ms, integer)
//   "quality"  => Number (0-100: percentage of valid callbacks)
//   "excluded" => Boolean
//
// ─────────────────────────────────────────────────────────────────────────────
class HRVStorage {

    private static const KEY_READINGS = "readings";

    // Maximum age of a reading before it is ignored in baseline (days)
    static const MAX_READING_AGE_DAYS = 30;

    // Time offset threshold for outlier flagging (minutes)
    static const TIME_OFFSET_THRESHOLD_MINS = 180;   // 3 hours

    // ── Load / Save ──────────────────────────────────────────────────────────

    static function loadReadings() as Array {
        var raw = Application.Storage.getValue(KEY_READINGS);
        if (raw instanceof Array) { return raw; }
        return [] as Array;
    }

    static function saveReadings(readings as Array) as Void {
        Application.Storage.setValue(KEY_READINGS, readings);
    }

    // ── Add a new reading ────────────────────────────────────────────────────

    static function addReading(rmssd as Number, qualityPct as Number, timeStr as String) as Void {
        var readings = loadReadings();
        var entry = {
            "date"     => todayString(),
            "time"     => timeStr,
            "rmssd"    => rmssd,
            "quality"  => qualityPct,
            "excluded" => false
        };
        readings.add(entry);
        saveReadings(readings);
    }

    // ── Toggle exclusion on a reading by original storage index ──────────────

    static function toggleExclusion(index as Number) as Void {
        var readings = loadReadings();
        if (index < 0 || index >= readings.size()) { return; }
        var entry = readings[index];
        if (entry instanceof Dictionary) {
            var current = entry.get("excluded");
            entry["excluded"] = (current == true) ? false : true;
            readings[index] = entry;
            saveReadings(readings);
        }
    }

    // ── Delete a reading by original storage index ───────────────────────────

    static function deleteReading(index as Number) as Void {
        var readings = loadReadings();
        if (index < 0 || index >= readings.size()) { return; }
        var newReadings = [] as Array;
        for (var i = 0; i < readings.size(); i++) {
            if (i != index) { newReadings.add(readings[i]); }
        }
        saveReadings(newReadings);
    }

    // ── Compute baseline from stored readings ─────────────────────────────────
    // Returns Dictionary:
    //   "baseline"     => Number or null
    //   "validCount"   => Number
    //   "windowTarget" => Number
    //   "minRequired"  => Number
    //   "method"       => Number (0=simple, 1=EWMA)

    static function computeBaseline() as Dictionary {
        var windowSize  = getSettingWindowSize();
        var minRequired = getSettingMinReadings();
        var method      = getSettingAvgMethod();

        if (minRequired > windowSize) { minRequired = windowSize; }

        var readings = loadReadings();
        var today = todayString();

        // Collect valid readings newest-first up to windowSize
        var valid = [] as Array;
        for (var i = readings.size() - 1; i >= 0; i--) {
            var r = readings[i];
            if (!(r instanceof Dictionary)) { continue; }
            if (r.get("excluded") == true) { continue; }
            if (ageDays(r.get("date") as String, today) > MAX_READING_AGE_DAYS) { continue; }
            valid.add(r);
            if (valid.size() >= windowSize) { break; }
        }

        var result = {
            "validCount"   => valid.size(),
            "windowTarget" => windowSize,
            "minRequired"  => minRequired,
            "method"       => method,
            "baseline"     => null
        };

        if (valid.size() < minRequired) { return result; }

        var baseline = (method == 1) ? computeEWMA(valid) : computeSimpleAvg(valid);
        result["baseline"] = baseline;
        return result;
    }

    // ── Compute flags for an array of readings ────────────────────────────────
    // Input:  any ordering of readings (e.g. reversed for display)
    // Output: Array<Dictionary> — one entry per input reading, same order
    //   Keys: :qualityBad, :duplicateDate, :timeOutlier  (all Boolean)

    static function computeFlags(readings as Array) as Array {
        var n = readings.size();
        var flags = [] as Array;
        for (var i = 0; i < n; i++) {
            flags.add({ :qualityBad => false, :duplicateDate => false, :timeOutlier => false });
        }

        var maxEmpty = getSettingMaxEmptyPct();

        // --- Quality flag ---
        for (var i = 0; i < n; i++) {
            var r = readings[i];
            if (!(r instanceof Dictionary)) { continue; }
            if (r.get("excluded") == true) { continue; }
            var qual = r.get("quality");
            if (qual instanceof Number) {
                var emptyPct = 100 - (qual as Number);
                if (emptyPct > maxEmpty) {
                    var f1 = flags[i] as Dictionary;
                    f1[:qualityBad] = true;
                }
            }
        }

        // --- Duplicate date flag ---
        // Count non-excluded readings per date
        var dateCounts = {} as Dictionary;
        for (var i = 0; i < n; i++) {
            var r = readings[i];
            if (!(r instanceof Dictionary)) { continue; }
            if (r.get("excluded") == true) { continue; }
            var d = r.get("date");
            if (d == null) { continue; }
            var cnt = dateCounts.get(d);
            dateCounts.put(d, (cnt instanceof Number) ? (cnt as Number) + 1 : 1);
        }
        for (var i = 0; i < n; i++) {
            var r = readings[i];
            if (!(r instanceof Dictionary)) { continue; }
            if (r.get("excluded") == true) { continue; }
            var d = r.get("date");
            if (d != null) {
                var cnt = dateCounts.get(d);
                if (cnt instanceof Number && (cnt as Number) > 1) {
                    var f2 = flags[i] as Dictionary;
                    f2[:duplicateDate] = true;
                }
            }
        }

        // --- Time outlier flag ---
        // Build list of (index, minutesSinceMidnight) for non-excluded valid-time entries
        var timeEntries = [] as Array;   // each: [displayIndex, minuteValue]
        for (var i = 0; i < n; i++) {
            var r = readings[i];
            if (!(r instanceof Dictionary)) { continue; }
            if (r.get("excluded") == true) { continue; }
            var t = r.get("time");
            if (t instanceof String) {
                var mins = timeStringToMins(t as String);
                if (mins >= 0) {
                    timeEntries.add([i, mins]);
                }
            }
        }

        if (timeEntries.size() >= 2) {
            // Collect just the minute values for median
            var minuteVals = [] as Array<Number>;
            for (var i = 0; i < timeEntries.size(); i++) {
                minuteVals.add((timeEntries[i] as Array)[1] as Number);
            }
            var medianMins = computeMedianMins(minuteVals);

            for (var i = 0; i < timeEntries.size(); i++) {
                var entry = timeEntries[i] as Array;
                var displayIdx = entry[0] as Number;
                var mins = entry[1] as Number;
                var diff = mins - medianMins;
                if (diff < 0) { diff = -diff; }
                if (diff > 720) { diff = 1440 - diff; }  // wrap midnight
                if (diff > TIME_OFFSET_THRESHOLD_MINS) {
                    var f3 = flags[displayIdx] as Dictionary;
                    f3[:timeOutlier] = true;
                }
            }
        }

        return flags;
    }

    // Returns true if any flag in the dictionary is set
    static function isAnyFlagSet(flag as Dictionary) as Boolean {
        return (flag.get(:qualityBad) == true ||
                flag.get(:duplicateDate) == true ||
                flag.get(:timeOutlier) == true);
    }

    // ── RMSSD computation from raw R-R intervals ──────────────────────────────

    static function computeRMSSD(intervals as Array) as Number {
        if (intervals.size() < 2) { return -1; }

        var sumSqDiff = 0.0;
        var count = 0;

        for (var i = 1; i < intervals.size(); i++) {
            var diff = (intervals[i] - intervals[i - 1]).toFloat();
            sumSqDiff += diff * diff;
            count++;
        }

        if (count == 0) { return -1; }

        var meanSqDiff = sumSqDiff / count.toFloat();
        return Math.sqrt(meanSqDiff).toNumber();
    }

    // ── Date / Time helpers ───────────────────────────────────────────────────

    static function todayString() as String {
        var now  = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        return info.year.format("%04d") + "-" +
               info.month.format("%02d") + "-" +
               info.day.format("%02d");
    }

    static function currentTimeString() as String {
        var ct = System.getClockTime();
        return ct.hour.format("%02d") + ":" + ct.min.format("%02d");
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static function computeSimpleAvg(valid as Array) as Number {
        var sum = 0.0;
        for (var i = 0; i < valid.size(); i++) {
            sum += ((valid[i] as Dictionary).get("rmssd") as Number).toFloat();
        }
        return (sum / valid.size().toFloat()).toNumber();
    }

    // valid is ordered newest-first; index 0 = most recent
    private static function computeEWMA(valid as Array) as Number {
        var alphaTimes10 = getSettingAlpha();
        var alpha = alphaTimes10.toFloat() / 10.0;
        var oneMinusAlpha = 1.0 - alpha;

        var n = valid.size();
        var ewma = ((valid[n - 1] as Dictionary).get("rmssd") as Number).toFloat();

        for (var i = n - 2; i >= 0; i--) {
            var rmssd = ((valid[i] as Dictionary).get("rmssd") as Number).toFloat();
            ewma = alpha * rmssd + oneMinusAlpha * ewma;
        }

        return ewma.toNumber();
    }

    private static function timeStringToMins(timeStr as String) as Number {
        if (timeStr == null || timeStr.length() < 5) { return -1; }
        var h = timeStr.substring(0, 2).toNumber();
        var m = timeStr.substring(3, 5).toNumber();
        if (h == null || m == null) { return -1; }
        return h * 60 + m;
    }

    private static function computeMedianMins(vals as Array<Number>) as Number {
        var n = vals.size();
        // Copy and insertion-sort (small array, fast enough)
        var sorted = [] as Array<Number>;
        for (var i = 0; i < n; i++) { sorted.add(vals[i]); }
        for (var i = 1; i < n; i++) {
            var key = sorted[i];
            var j = i - 1;
            while (j >= 0 && (sorted[j] as Number) > key) {
                sorted[j + 1] = sorted[j];
                j--;
            }
            sorted[j + 1] = key;
        }
        return sorted[n / 2] as Number;
    }

    private static function ageDays(dateStr as String, todayStr as String) as Number {
        if (dateStr == null || dateStr.length() < 10) { return 9999; }
        if (todayStr == null || todayStr.length() < 10) { return 9999; }

        var dy = dateStr.substring(0, 4).toNumber();
        var dm = dateStr.substring(5, 7).toNumber();
        var dd = dateStr.substring(8, 10).toNumber();
        var ty = todayStr.substring(0, 4).toNumber();
        var tm = todayStr.substring(5, 7).toNumber();
        var td = todayStr.substring(8, 10).toNumber();

        if (dy == null || dm == null || dd == null ||
            ty == null || tm == null || td == null) { return 9999; }

        var dJD = julianDay(dy, dm, dd);
        var tJD = julianDay(ty, tm, td);
        var diff = tJD - dJD;
        return diff >= 0 ? diff : -diff;
    }

    private static function julianDay(y as Number, m as Number, d as Number) as Number {
        return 365 * y + (y / 4) - (y / 100) + (y / 400) + (367 * m / 12) + d;
    }

    // ── Settings accessors ────────────────────────────────────────────────────

    static function getSettingAvgMethod() as Number {
        var v = Application.Properties.getValue("avgMethod");
        return (v instanceof Number) ? v : 1;
    }

    static function getSettingWindowSize() as Number {
        var v = Application.Properties.getValue("windowSize");
        var n = (v instanceof Number) ? v : 7;
        if (n < 5)  { n = 5; }
        if (n > 30) { n = 30; }
        return n;
    }

    static function getSettingMinReadings() as Number {
        var v = Application.Properties.getValue("minReadings");
        var n = (v instanceof Number) ? v : 5;
        if (n < 3)  { n = 3; }
        if (n > 10) { n = 10; }
        return n;
    }

    static function getSettingAlpha() as Number {
        var v = Application.Properties.getValue("ewmaAlphaTimes10");
        var n = (v instanceof Number) ? v : 3;
        if (n < 1) { n = 1; }
        if (n > 9) { n = 9; }
        return n;
    }

    static function getSettingMaxEmptyPct() as Number {
        var v = Application.Properties.getValue("maxEmptyPct");
        var n = (v instanceof Number) ? v : 40;
        if (n < 0)   { n = 0; }
        if (n > 100) { n = 100; }
        return n;
    }

    static function getSettingDurationMins() as Number {
        var v = Application.Properties.getValue("measureDurationMins");
        var n = (v instanceof Number) ? v : 2;
        if (n < 1) { n = 1; }
        if (n > 3) { n = 3; }
        return n;
    }
}
