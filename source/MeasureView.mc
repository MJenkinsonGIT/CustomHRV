import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// ─────────────────────────────────────────────────────────────────────────────
// MeasureView
// Layout:
//   y=0-42   : black — countdown timer centered
//   y=42-70  : blue bar — quality % and label
//   y=70-355 : interval feed (newest at top, fading down)
//   y=355-379: dark footer — "stay still | back=cancel"
//   y=393    : interval count
// ─────────────────────────────────────────────────────────────────────────────
class MeasureView extends WatchUi.View {

    private var _lines          as Array<String>;
    private const MAX_LINES     = 8;
    private var _sensorActive   as Boolean;
    private var _session        as ActivityRecording.Session?;
    private var _durationSecs   as Number;
    private var _elapsedSecs    as Number;
    private var _timer          as Timer.Timer?;
    private var _totalCallbacks as Number;
    private var _emptyCallbacks as Number;
    private var _allIntervals   as Array<Number>;
    private var _finished       as Boolean;

    public function initialize() {
        View.initialize();
        _lines          = [] as Array<String>;
        _sensorActive   = false;
        _session        = null;
        _durationSecs   = HRVStorage.getSettingDurationMins() * 60;
        _elapsedSecs    = 0;
        _timer          = null;
        _totalCallbacks = 0;
        _emptyCallbacks = 0;
        _allIntervals   = [] as Array<Number>;
        _finished       = false;
    }

    public function onShow() as Void { startSession(); }
    public function onHide() as Void { stopSession(); }

    private function startSession() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
        startSensor();
    }

    private function stopSession() as Void {
        if (_timer != null) { _timer.stop(); _timer = null; }
        stopSensor();
    }

    public function onTick() as Void {
        _elapsedSecs++;
        if (_elapsedSecs >= _durationSecs && !_finished) {
            _finished = true;
            stopSession();
            finishMeasurement();
        }
        WatchUi.requestUpdate();
    }

    private function startSensor() as Void {
        if (_sensorActive) { return; }
        try {
            if (Toybox has :ActivityRecording) {
                _session = ActivityRecording.createSession({ :name => "HRV", :sport => Activity.SPORT_GENERIC });
                _session.start();
            }
        } catch (e instanceof Lang.Exception) {
            addLine("ERR:session " + e.getErrorMessage());
        }
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_ONBOARD_HEARTRATE]);
            Sensor.registerSensorDataListener(method(:onSensorData),
                { :period => 1, :heartBeatIntervals => { :enabled => true } });
            _sensorActive = true;
        } catch (e instanceof Sensor.TooManySensorDataListenersException) {
            addLine("ERR:TooManyListeners");
        } catch (e instanceof Lang.Exception) {
            addLine("ERR:" + e.getErrorMessage());
        }
    }

    private function stopSensor() as Void {
        if (!_sensorActive) { return; }
        Sensor.unregisterSensorDataListener();
        Sensor.setEnabledSensors([]);
        _sensorActive = false;
        if (_session != null) {
            try {
                if (_session.isRecording()) { _session.stop(); _session.discard(); }
            } catch (e instanceof Lang.Exception) {}
            _session = null;
        }
    }

    public function onSensorData(sensorData as Sensor.SensorData) as Void {
        if (_finished) { return; }
        _totalCallbacks++;

        if (!(sensorData has :heartRateData) || sensorData.heartRateData == null) {
            _emptyCallbacks++;
            addLine("-- no hrData");
            WatchUi.requestUpdate();
            return;
        }

        var raw = sensorData.heartRateData.heartBeatIntervals;

        if (raw.size() == 0) {
            _emptyCallbacks++;
            addLine("[]");
            WatchUi.requestUpdate();
            return;
        }

        var filtered = [] as Array<Number>;
        for (var i = 0; i < raw.size(); i++) {
            if (raw[i] > 0) { filtered.add(raw[i]); _allIntervals.add(raw[i]); }
        }

        if (filtered.size() == 0) {
            _emptyCallbacks++;
            addLine("[zeros]");
        } else {
            addLine(formatIntervals(filtered));
        }
        WatchUi.requestUpdate();
    }

    private function finishMeasurement() as Void {
        var qualityPct = (_totalCallbacks == 0) ? 0 :
            100 - ((_emptyCallbacks * 100) / _totalCallbacks);
        var rmssd   = HRVStorage.computeRMSSD(_allIntervals);
        var timeStr = HRVStorage.currentTimeString();

        var resultView     = new ResultView(rmssd, qualityPct, _totalCallbacks, _emptyCallbacks, timeStr);
        var resultDelegate = new ResultDelegate(resultView);
        WatchUi.switchToView(resultView, resultDelegate, WatchUi.SLIDE_LEFT);
    }

    private function addLine(line as String) as Void {
        _lines.add(line);
        while (_lines.size() > MAX_LINES) { _lines.remove(_lines[0]); }
    }

    private function formatIntervals(intervals as Array<Number>) as String {
        var s = "[";
        for (var i = 0; i < intervals.size(); i++) {
            if (i > 0) { s += ","; }
            s += intervals[i].toString();
        }
        return s + "]";
    }

    private function qualityLabel(emptyPct as Number) as String {
        if (emptyPct <= 20) { return "Excellent"; }
        if (emptyPct <= 40) { return "Good"; }
        if (emptyPct <= 60) { return "Fair"; }
        return "Poor";
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Timer in black zone above header
        var remaining = _durationSecs - _elapsedSecs;
        if (remaining < 0) { remaining = 0; }
        var mins = remaining / 60;
        var secs = remaining - (mins * 60);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 21, Graphics.FONT_SMALL, mins.format("%d") + ":" + secs.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Blue header — quality
        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        var emptyPct = (_totalCallbacks > 0) ? (_emptyCallbacks * 100) / _totalCallbacks : 0;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_XTINY,
            emptyPct.toString() + "% empty - " + qualityLabel(emptyPct),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Interval feed
        var lineH  = 26;
        var startY = 76;
        var count  = _lines.size();

        if (count == 0) {
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, startY + 40, Graphics.FONT_XTINY, "Waiting for signal...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            for (var i = 0; i < count && i < MAX_LINES; i++) {
                var lineIdx = count - 1 - i;
                var y = startY + i * lineH;
                if (y + lineH > 355) { break; }
                var color;
                if (i == 0)      { color = Graphics.COLOR_WHITE; }
                else if (i <= 2) { color = Graphics.COLOR_LT_GRAY; }
                else             { color = 0x555555; }
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_XTINY, _lines[lineIdx],
                    Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Footer
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 355, w, 24);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 367, Graphics.FONT_XTINY, "Stay Still  |  Back=Cancel",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 393, Graphics.FONT_XTINY, _allIntervals.size().toString() + " intervals",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class MeasureDelegate extends WatchUi.BehaviorDelegate {
    public function initialize(view as MeasureView) {
        BehaviorDelegate.initialize();
    }
    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
