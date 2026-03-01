import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class HistoryView extends WatchUi.View {

    private var _readings     as Array;
    private var _flags        as Array;
    private var _scrollPos    as Number;

    private const ROWS         = 4;
    private const CONTENT_Y    = 98;
    private const FOOTER_Y     = 355;
    private const FOOTER_H     = 24;
    private const ROW_H        = 64;

    public function initialize() {
        View.initialize();
        _readings  = [];
        _flags     = [];
        _scrollPos = 0;
    }

    public function onShow() as Void { reload(); }

    public function reload() as Void {
        var raw = HRVStorage.loadReadings();
        _readings = [] as Array;
        for (var i = raw.size() - 1; i >= 0; i--) {
            _readings.add(raw[i]);
        }
        _flags     = HRVStorage.computeFlags(_readings);
        _scrollPos = 0;
        WatchUi.requestUpdate();
    }

    public function scrollUp() as Void {
        if (_scrollPos > 0) { _scrollPos--; WatchUi.requestUpdate(); }
    }

    public function scrollDown() as Void {
        if (_scrollPos + ROWS < _readings.size()) { _scrollPos++; WatchUi.requestUpdate(); }
    }

    public function rowForTapY(tapY as Number) as Number {
        if (tapY < CONTENT_Y || tapY >= FOOTER_Y) { return -1; }
        var relY = tapY - CONTENT_Y;
        var row  = relY / ROW_H;
        var displayIdx = _scrollPos + row;
        if (displayIdx >= _readings.size()) { return -1; }
        return displayIdx;
    }

    public function openDetail(displayIdx as Number) as Void {
        if (displayIdx < 0 || displayIdx >= _readings.size()) { return; }
        var r    = _readings[displayIdx];
        var flag = _flags[displayIdx] as Dictionary;
        var origIdx = _readings.size() - 1 - displayIdx;
        var detail  = new DetailView(r as Dictionary, flag, origIdx);
        var delg    = new DetailDelegate(detail, self);
        WatchUi.pushView(detail, delg, WatchUi.SLIDE_LEFT);
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, "History",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var baselineInfo = HRVStorage.computeBaseline();
        var baseline     = baselineInfo.get("baseline");
        var validCount   = baselineInfo.get("validCount") as Number;
        var windowTarget = baselineInfo.get("windowTarget") as Number;
        var method       = baselineInfo.get("method") as Number;
        var methodStr    = (method == 1) ? "EWMA" : "Avg";
        var blStr;
        if (baseline != null) {
            blStr = methodStr + ": " + (baseline as Number).toString() + " ms (" +
                    validCount.toString() + "/" + windowTarget.toString() + ")";
        } else {
            blStr = "Calibrating: " + validCount.toString() + "/" +
                    (baselineInfo.get("minRequired") as Number).toString();
        }
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 82, Graphics.FONT_XTINY, blStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (_readings.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, CONTENT_Y + (FOOTER_Y - CONTENT_Y) / 2, Graphics.FONT_SMALL,
                "No Readings Yet",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            for (var i = 0; i < ROWS; i++) {
                var idx = _scrollPos + i;
                if (idx >= _readings.size()) { break; }

                var r    = _readings[idx];
                if (!(r instanceof Dictionary)) { continue; }
                var flag = _flags[idx] as Dictionary;

                var rowY     = CONTENT_Y + i * ROW_H;
                var excluded = (r.get("excluded") == true);

                if (i % 2 == 1) {
                    dc.setColor(0x0A0A0A, Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(0, rowY, w, ROW_H - 1);
                }

                var dateStr = r.get("date");
                if (dateStr == null) { dateStr = "??-??-??"; }
                var timeStr = r.get("time");
                var hasTime = (timeStr instanceof String);

                var rmssd    = r.get("rmssd");
                var rmssdStr = (rmssd instanceof Number) ? (rmssd as Number).toString() + " ms" : "??";

                var qual     = r.get("quality");
                var emptyPct = (qual instanceof Number) ? 100 - (qual as Number) : 100;

                var dateY = rowY + 14;
                var qualY = rowY + 36;

                var dateColor;
                if (excluded)                              { dateColor = 0x444444; }
                else if (flag.get(:duplicateDate) == true) { dateColor = Graphics.COLOR_RED; }
                else                                       { dateColor = Graphics.COLOR_WHITE; }

                var timeColor;
                if (excluded)                              { timeColor = 0x444444; }
                else if (flag.get(:timeOutlier) == true)   { timeColor = Graphics.COLOR_RED; }
                else                                       { timeColor = Graphics.COLOR_LT_GRAY; }

                var qualColor;
                if (excluded)                              { qualColor = 0x444444; }
                else if (flag.get(:qualityBad) == true)    { qualColor = Graphics.COLOR_RED; }
                else                                       { qualColor = 0x666666; }

                dc.setColor(dateColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(30, dateY, Graphics.FONT_XTINY, dateStr as String,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

                if (hasTime) {
                    dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(185, dateY, Graphics.FONT_XTINY, timeStr as String,
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                }

                var rmssdColor = excluded ? 0x444444 : Graphics.COLOR_WHITE;
                dc.setColor(rmssdColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(w - 30, dateY, Graphics.FONT_XTINY, rmssdStr,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

                dc.setColor(qualColor, Graphics.COLOR_TRANSPARENT);
                var qualLine = excluded ? "[excluded] " + emptyPct.toString() + "% empty"
                                        : emptyPct.toString() + "% empty";
                dc.drawText(30, qualY, Graphics.FONT_XTINY, qualLine,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

                dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
                dc.drawText(w - 30, qualY, Graphics.FONT_XTINY, ">",
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

                dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(20, rowY + ROW_H - 1, w - 20, rowY + ROW_H - 1);
            }
        }

        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, FOOTER_Y, w, FOOTER_H);
        ArrowUtils.drawUpDownHint(dc, cx, FOOTER_Y + FOOTER_H / 2,
            "=Scroll  Tap=Details", Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);

        dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
        var endIdx = _scrollPos + ROWS;
        if (endIdx > _readings.size()) { endIdx = _readings.size(); }
        var scrollInfo = (_readings.size() == 0) ? "0 Readings" :
            (_scrollPos + 1).toString() + "-" + endIdx.toString() +
            " of " + _readings.size().toString();
        dc.drawText(cx, FOOTER_Y + FOOTER_H + 14, Graphics.FONT_XTINY, scrollInfo,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class HistoryDelegate extends WatchUi.BehaviorDelegate {
    private var _view as HistoryView;

    public function initialize(view as HistoryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onNextPage() as Boolean {
        _view.scrollDown();
        return true;
    }

    public function onPreviousPage() as Boolean {
        _view.scrollUp();
        return true;
    }

    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var tapY   = coords[1];
        var rowIdx = _view.rowForTapY(tapY);
        if (rowIdx >= 0) {
            _view.openDetail(rowIdx);
            return true;
        }
        return false;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
