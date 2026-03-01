import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DashboardView extends WatchUi.View {

    public function initialize() { View.initialize(); }
    public function onShow() as Void { WatchUi.requestUpdate(); }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, "CustomHRV",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var readings     = HRVStorage.loadReadings();
        var baselineInfo = HRVStorage.computeBaseline();
        var baseline     = baselineInfo.get("baseline");
        var validCount   = baselineInfo.get("validCount") as Number;
        var minRequired  = baselineInfo.get("minRequired") as Number;
        var windowTarget = baselineInfo.get("windowTarget") as Number;

        var todayStr     = HRVStorage.todayString();
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

        // Recommendation hint — only shown when today has a reading
        if (todayReading != null) {
            var recText = "Recommendation";
            var recDims = dc.getTextDimensions(recText, Graphics.FONT_XTINY);
            var recW    = recDims[0] as Number;
            var aSize   = ArrowUtils.HINT_ARROW_SIZE;
            var totalW  = recW + 4 + aSize;
            var recStartX = cx - totalW / 2;
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(recStartX, 342, Graphics.FONT_XTINY, recText,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            ArrowUtils.drawUpArrow(dc, recStartX + recW + 4 + aSize / 2, 342, aSize, Graphics.COLOR_RED);
        }

        var midY = (70 + 355) / 2;

        if (todayReading == null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 20, Graphics.FONT_SMALL, "No reading today",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (baseline == null) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, midY + 20, Graphics.FONT_XTINY,
                    "Calibrating: " + validCount + "/" + minRequired + " Readings",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, midY + 20, Graphics.FONT_XTINY,
                    "Baseline: " + baseline + " ms",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            var todayRmssd = todayReading.get("rmssd") as Number;
            var readinessColor;
            var readinessLabel;

            if (baseline == null) {
                readinessColor = Graphics.COLOR_LT_GRAY;
                readinessLabel = "Calibrating";
            } else {
                var pctOfBaseline = (todayRmssd.toFloat() / (baseline as Number).toFloat()) * 100.0;
                if (pctOfBaseline >= 95.0) {
                    readinessColor = Graphics.COLOR_GREEN;
                    readinessLabel = "Ready";
                } else if (pctOfBaseline >= 90.0) {
                    readinessColor = Graphics.COLOR_YELLOW;
                    readinessLabel = "Moderate";
                } else {
                    readinessColor = Graphics.COLOR_RED;
                    readinessLabel = "Low";
                }
            }

            dc.setColor(readinessColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 50, Graphics.FONT_NUMBER_MILD, todayRmssd.toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY - 5, Graphics.FONT_XTINY, "ms RMSSD",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(readinessColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, midY + 28, Graphics.FONT_SMALL, readinessLabel,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (baseline != null) {
                dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, midY + 60, Graphics.FONT_XTINY,
                    "Baseline: " + (baseline as Number).toString() + " ms",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 355, w, 24);
        // "Tap=Measure  ▼=Hist" with drawn down arrow
        var hintText = "Tap=Measure";
        var hintSuffix = "=Hist";
        var hintDims = dc.getTextDimensions(hintText, Graphics.FONT_XTINY);
        var suffDims = dc.getTextDimensions(hintSuffix, Graphics.FONT_XTINY);
        var hintW = hintDims[0] as Number;
        var suffW = suffDims[0] as Number;
        var aSize = ArrowUtils.HINT_ARROW_SIZE;
        var totalHintW = hintW + 10 + aSize + 2 + suffW;
        var hintStartX = cx - totalHintW / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hintStartX, 367, Graphics.FONT_XTINY, hintText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        var arrowCx = hintStartX + hintW + 10 + aSize / 2;
        ArrowUtils.drawDownArrow(dc, arrowCx, 367, aSize, Graphics.COLOR_LT_GRAY);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(arrowCx + aSize / 2 + 2, 367, Graphics.FONT_XTINY, hintSuffix,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 384, w, 20);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 393, Graphics.FONT_XTINY, "Hold Back=Settings",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 418, Graphics.FONT_XTINY,
            validCount.toString() + "/" + windowTarget.toString() + " Readings",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class DashboardDelegate extends WatchUi.BehaviorDelegate {

    public function initialize(view as DashboardView) {
        BehaviorDelegate.initialize();
    }

    public function onSelect() as Boolean {
        var measureView = new MeasureView();
        var measureDelegate = new MeasureDelegate(measureView);
        WatchUi.pushView(measureView, measureDelegate, WatchUi.SLIDE_LEFT);
        return true;
    }

    public function onNextPage() as Boolean {
        var readings = HRVStorage.loadReadings();
        var todayStr = HRVStorage.todayString();
        for (var i = readings.size() - 1; i >= 0; i--) {
            var r = readings[i];
            if (r instanceof Dictionary &&
                r.get("date").equals(todayStr) &&
                r.get("excluded") != true) {
                var recView = new RecommendationView();
                var recDel  = new RecommendationDelegate();
                WatchUi.pushView(recView, recDel, WatchUi.SLIDE_UP);
                return true;
            }
        }
        return true; // swallow gesture silently if no reading today
    }

    public function onPreviousPage() as Boolean {
        var histView     = new HistoryView();
        var histDelegate = new HistoryDelegate(histView);
        WatchUi.pushView(histView, histDelegate, WatchUi.SLIDE_UP);
        return true;
    }

    public function onMenu() as Boolean {
        var settView = new SettingsMenuView();
        var settDel  = new SettingsMenuDelegate(settView);
        WatchUi.pushView(settView, settDel, WatchUi.SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
