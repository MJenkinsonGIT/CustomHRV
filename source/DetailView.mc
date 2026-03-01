import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DetailView extends WatchUi.View {

    private var _reading    as Dictionary;
    private var _flag       as Dictionary;
    private var _origIdx    as Number;
    private var _confirmDel as Boolean;

    public function initialize(reading as Dictionary, flag as Dictionary, origIdx as Number) {
        View.initialize();
        _reading    = reading;
        _flag       = flag;
        _origIdx    = origIdx;
        _confirmDel = false;
    }

    public function onShow() as Void { WatchUi.requestUpdate(); }

    public function toggleExclusion() as Void {
        _confirmDel = false;
        HRVStorage.toggleExclusion(_origIdx);
        var readings = HRVStorage.loadReadings();
        if (_origIdx < readings.size()) {
            _reading = readings[_origIdx] as Dictionary;
        }
        WatchUi.requestUpdate();
    }

    public function requestDelete() as Void {
        if (!_confirmDel) {
            _confirmDel = true;
            WatchUi.requestUpdate();
        } else {
            HRVStorage.deleteReading(_origIdx);
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }

    public function cancelConfirm() as Void {
        _confirmDel = false;
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, "Reading Detail",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var excluded = (_reading.get("excluded") == true);

        var dateStr = _reading.get("date");
        if (dateStr == null) { dateStr = "??-??-??"; }
        var timeStr = _reading.get("time");
        var dtLabel = (timeStr instanceof String)
            ? (dateStr as String) + "  " + (timeStr as String)
            : (dateStr as String);

        var rmssd    = _reading.get("rmssd");
        var rmssdStr = (rmssd instanceof Number) ? (rmssd as Number).toString() + " ms" : "??";

        var qual     = _reading.get("quality");
        var emptyPct = (qual instanceof Number) ? 100 - (qual as Number) : 100;

        dc.setColor(excluded ? 0x888888 : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 95, Graphics.FONT_SMALL, dtLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(excluded ? 0x888888 : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 138, Graphics.FONT_NUMBER_MILD, rmssdStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 178, Graphics.FONT_XTINY, emptyPct.toString() + "% empty callbacks",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (excluded) {
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 198, Graphics.FONT_XTINY, "[excluded from baseline]",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var flagY = 220;
        var flagH = 22;

        if (!excluded && HRVStorage.isAnyFlagSet(_flag)) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, flagY, Graphics.FONT_XTINY, "! Data quality warnings:",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            flagY += flagH;

            if (_flag.get(:qualityBad) == true) {
                var maxAllowed = HRVStorage.getSettingMaxEmptyPct();
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, flagY, Graphics.FONT_XTINY,
                    emptyPct.toString() + "% empty > " + maxAllowed.toString() + "% limit",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH;
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, flagY, Graphics.FONT_XTINY, "Signal lost during reading",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH + 4;
            }

            if (_flag.get(:duplicateDate) == true) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, flagY, Graphics.FONT_XTINY, "Date matches another reading",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH;
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, flagY, Graphics.FONT_XTINY, "One reading per day",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH;
                dc.drawText(cx, flagY, Graphics.FONT_XTINY, "is recommended",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH + 4;
            }

            if (_flag.get(:timeOutlier) == true) {
                var threshHours = HRVStorage.TIME_OFFSET_THRESHOLD_MINS / 60;
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, flagY, Graphics.FONT_XTINY,
                    "Time >" + threshHours.toString() + "hr from other readings",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH;
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, flagY, Graphics.FONT_XTINY, "Same time daily for consistency",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                flagY += flagH + 4;
            }
        } else if (!excluded) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, flagY, Graphics.FONT_XTINY, "No issues detected",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 355, w, 24);

        if (_confirmDel) {
            ArrowUtils.drawArrowLabel(dc, cx, 367, true, "=Confirm Delete",
                Graphics.FONT_XTINY, Graphics.COLOR_RED);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 393, Graphics.FONT_XTINY, "Back=Cancel",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var rightLabel = excluded ? "=Include" : "=Exclude";
            ArrowUtils.drawUpDownPair(dc, cx, 367, "=Delete", rightLabel,
                Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);
        }
    }
}

class DetailDelegate extends WatchUi.BehaviorDelegate {

    private var _view        as DetailView;
    private var _historyView as HistoryView;

    public function initialize(view as DetailView, historyView as HistoryView) {
        BehaviorDelegate.initialize();
        _view        = view;
        _historyView = historyView;
    }

    public function onPreviousPage() as Boolean {
        _view.toggleExclusion();
        return true;
    }

    public function onNextPage() as Boolean {
        _view.requestDelete();
        return true;
    }

    public function onBack() as Boolean {
        _view.cancelConfirm();
        _historyView.reload();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
