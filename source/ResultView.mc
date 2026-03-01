import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// ResultView
// ─────────────────────────────────────────────────────────────────────────────
class ResultView extends WatchUi.View {

    private var _rmssd      as Number;
    private var _qualityPct as Number;
    private var _totalCbs   as Number;
    private var _emptyCbs   as Number;
    private var _timeStr    as String;
    private var _saved      as Boolean;

    public function initialize(rmssd as Number, qualityPct as Number,
                               totalCbs as Number, emptyCbs as Number,
                               timeStr as String) {
        View.initialize();
        _rmssd      = rmssd;
        _qualityPct = qualityPct;
        _totalCbs   = totalCbs;
        _emptyCbs   = emptyCbs;
        _timeStr    = timeStr;
        _saved      = false;
    }

    public function onShow() as Void { WatchUi.requestUpdate(); }

    public function saveReading() as Void {
        if (!_saved && _rmssd > 0) {
            HRVStorage.addReading(_rmssd, _qualityPct, _timeStr);
            _saved = true;
            WatchUi.requestUpdate();
        }
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Header
        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, "Result",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var midY = (70 + 355) / 2;  // ~212

        var emptyPct    = (_totalCbs > 0) ? (_emptyCbs * 100) / _totalCbs : 100;
        var maxAllowed  = HRVStorage.getSettingMaxEmptyPct();
        var tooMuchMotion = (emptyPct > maxAllowed);
        var noData        = (_rmssd <= 0);

        // Quality line under header
        var qualityColor;
        var qualityDesc;
        if (emptyPct <= 20)      { qualityColor = Graphics.COLOR_GREEN;  qualityDesc = "Excellent"; }
        else if (emptyPct <= 40) { qualityColor = Graphics.COLOR_YELLOW; qualityDesc = "Good"; }
        else if (emptyPct <= 60) { qualityColor = Graphics.COLOR_ORANGE; qualityDesc = "Fair"; }
        else                     { qualityColor = Graphics.COLOR_RED;    qualityDesc = "Poor"; }

        dc.setColor(qualityColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 82, Graphics.FONT_XTINY,
            emptyPct.toString() + "% empty - " + qualityDesc,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (noData) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 20, Graphics.FONT_SMALL, "No data",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY + 20, Graphics.FONT_XTINY, "Keep arm still and retry",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (tooMuchMotion) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 30, Graphics.FONT_NUMBER_MILD, _rmssd.toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY + 10, Graphics.FONT_XTINY, "ms RMSSD (unreliable)",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY + 35, Graphics.FONT_XTINY,
                ">" + maxAllowed.toString() + "% empty - try again",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var baselineInfo = HRVStorage.computeBaseline();
            var baseline     = baselineInfo.get("baseline");
            var validCount   = baselineInfo.get("validCount") as Number;
            var minRequired  = baselineInfo.get("minRequired") as Number;

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 50, Graphics.FONT_NUMBER_MILD, _rmssd.toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 5, Graphics.FONT_XTINY, "ms RMSSD",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (baseline == null) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                var needed = minRequired - validCount;
                if (needed < 0) { needed = 0; }
                dc.drawText(cx, midY + 30, Graphics.FONT_XTINY,
                    "Calibrating: " + needed.toString() + " more needed",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                var bl  = baseline as Number;
                var pct = (_rmssd.toFloat() / bl.toFloat()) * 100.0;
                var readinessColor;
                var readinessLabel;
                var readinessDetail;

                if (pct >= 95.0) {
                    readinessColor  = Graphics.COLOR_GREEN;
                    readinessLabel  = "Ready";
                    readinessDetail = "Proceed with planned training";
                } else if (pct >= 90.0) {
                    readinessColor  = Graphics.COLOR_YELLOW;
                    readinessLabel  = "Moderate";
                    readinessDetail = "Reduce intensity today";
                } else {
                    readinessColor  = Graphics.COLOR_RED;
                    readinessLabel  = "Low";
                    readinessDetail = "Rest or easy session only";
                }

                dc.setColor(readinessColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, midY + 25, Graphics.FONT_SMALL, readinessLabel,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, midY + 55, Graphics.FONT_XTINY, readinessDetail,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, midY + 81, Graphics.FONT_XTINY,
                    "Baseline: " + bl.toString() + " ms",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Footer
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 355, w, 24);

        if (_saved) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 367, Graphics.FONT_XTINY, "Saved!",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (noData || tooMuchMotion) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 367, Graphics.FONT_XTINY, "Back=Dismiss",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 367, Graphics.FONT_XTINY, "Tap=Save  Back=Discard",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class ResultDelegate extends WatchUi.BehaviorDelegate {
    private var _view as ResultView;
    public function initialize(view as ResultView) {
        BehaviorDelegate.initialize();
        _view = view;
    }
    public function onSelect() as Boolean {
        _view.saveReading();
        return true;
    }
    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
