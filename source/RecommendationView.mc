import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationView
// Full readiness breakdown for today's HRV reading.
// Accessible from dashboard via swipe up (only when today's reading exists).
//
// Layout (y):
//   42-70  : blue header
//   ~130   : RMSSD value (FONT_NUMBER_MILD)
//   ~168   : "ms RMSSD" label
//   ~200   : readiness label (FONT_SMALL, coloured)
//   ~232   : calculation line  e.g. "47 / 30 = 63.8%"
//   ~260   : threshold context e.g. "<90% → Low"
//   ~290   : recommendation detail text
//   355-379: footer
// ─────────────────────────────────────────────────────────────────────────────
class RecommendationView extends WatchUi.View {

    public function initialize() { View.initialize(); }
    public function onShow() as Void { WatchUi.requestUpdate(); }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Header
        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, "Recommendation",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Find today's reading
        var readings    = HRVStorage.loadReadings();
        var todayStr    = HRVStorage.todayString();
        var todayReading = null;
        for (var i = readings.size() - 1; i >= 0; i--) {
            var r = readings[i];
            if (r instanceof Dictionary &&
                r.get("date").equals(todayStr) &&
                r.get("excluded") != true) {
                todayReading = r;
                break;
            }
        }

        if (todayReading == null) {
            // Shouldn't normally be reachable, but handle gracefully
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 212, Graphics.FONT_SMALL, "No reading today",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var baselineInfo = HRVStorage.computeBaseline();
            var baseline     = baselineInfo.get("baseline");
            var rmssd        = todayReading.get("rmssd") as Number;

            // RMSSD value
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 130, Graphics.FONT_NUMBER_MILD, rmssd.toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 168, Graphics.FONT_XTINY, "ms RMSSD",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (baseline == null) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 212, Graphics.FONT_SMALL, "Calibrating",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 248, Graphics.FONT_XTINY, "Not enough readings yet",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(cx, 274, Graphics.FONT_XTINY, "to compute a baseline",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                var bl  = baseline as Number;
                var pct = (rmssd.toFloat() / bl.toFloat()) * 100.0;

                var readinessColor;
                var readinessLabel;
                var readinessDetail;
                var thresholdNote;

                if (pct >= 95.0) {
                    readinessColor  = Graphics.COLOR_GREEN;
                    readinessLabel  = "Ready";
                    readinessDetail = "Proceed with planned training";
                    thresholdNote   = ">=95%  Ready";
                } else if (pct >= 90.0) {
                    readinessColor  = Graphics.COLOR_YELLOW;
                    readinessLabel  = "Moderate";
                    readinessDetail = "Reduce intensity today";
                    thresholdNote   = ">=90%  Moderate";
                } else {
                    readinessColor  = Graphics.COLOR_RED;
                    readinessLabel  = "Low";
                    readinessDetail = "Rest or easy session only";
                    thresholdNote   = "<90%   Low";
                }

                // Readiness label
                dc.setColor(readinessColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 204, Graphics.FONT_SMALL, readinessLabel,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Calculation: "47 / 30 = 63.8%"
                var pctStr = pct.format("%.1f");
                var calcStr = rmssd.toString() + " / " + bl.toString() + " = " + pctStr + "%";
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 238, Graphics.FONT_XTINY, calcStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Threshold context line
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 262, Graphics.FONT_XTINY, thresholdNote,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Recommendation detail
                dc.setColor(readinessColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 294, Graphics.FONT_XTINY, readinessDetail,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Baseline reference
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 322, Graphics.FONT_XTINY, "Baseline: " + bl.toString() + " ms",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Footer
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 355, w, 24);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 367, Graphics.FONT_XTINY, "Back=Dashboard",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class RecommendationDelegate extends WatchUi.BehaviorDelegate {
    public function initialize() { BehaviorDelegate.initialize(); }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
