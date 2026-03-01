import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsMenuView extends WatchUi.View {

    private var _scrollPos  as Number;
    private const ROWS      = 4;
    private const CONTENT_Y = 98;
    private const FOOTER_Y  = 355;
    private const FOOTER_H  = 24;
    private const ROW_H     = 64;

    private var _settings  as Array;

    public function initialize() {
        View.initialize();
        _scrollPos = 0;
        _settings  = buildDescriptors();
    }

    private function buildDescriptors() as Array {
        return [
            { :label   => "Avg Method",
              :desc1   => "Simple Avg weights all readings",
              :desc2   => "equally. EWMA gives more",
              :desc3   => "weight to recent readings.",
              :formula => "",
              :key     => "avgMethod",
              :type    => :toggle,
              :opts    => ["Simple Avg", "EWMA"] },
            { :label   => "Window Size",
              :desc1   => "Number of recent readings used",
              :desc2   => "to compute your baseline.",
              :desc3   => "(More = smoother, less reactive)",
              :formula => "",
              :key     => "windowSize",
              :type    => :range,
              :min     => 5, :max => 30, :step => 1, :unit => " Readings" },
            { :label   => "Min Readings",
              :desc1   => "How many readings are needed",
              :desc2   => "before a baseline score",
              :desc3   => "is shown.",
              :formula => "",
              :key     => "minReadings",
              :type    => :range,
              :min     => 3, :max => 10, :step => 1, :unit => " Needed" },
            { :label   => "EWMA Alpha",
              :desc1   => "How EWMA weights data.",
              :desc2   => "Higher=More weight to new data",
              :desc3   => "Lower=More stable baseline.",
              :formula => "EWMA = a*HRV + (1-a)*prev",
              :key     => "ewmaAlphaTimes10",
              :type    => :range,
              :min     => 1, :max => 9, :step => 1, :unit => "/10" },
            { :label   => "Max Empty %",
              :desc1   => "Flag a reading if this % of",
              :desc2   => "sensor callbacks returned",
              :desc3   => "no data.",
              :formula => "",
              :key     => "maxEmptyPct",
              :type    => :range,
              :min     => 0, :max => 100, :step => 5, :unit => "%" },
            { :label   => "Duration",
              :desc1   => "How long each HRV",
              :desc2   => "measurement session lasts.",
              :desc3   => "",
              :formula => "",
              :key     => "measureDurationMins",
              :type    => :range,
              :min     => 1, :max => 3, :step => 1, :unit => " Min" }
        ] as Array;
    }

    public function numSettings() as Number { return _settings.size(); }
    public function getSetting(idx as Number) as Dictionary { return _settings[idx] as Dictionary; }

    public function scrollUp() as Void {
        if (_scrollPos > 0) { _scrollPos--; WatchUi.requestUpdate(); }
    }

    public function scrollDown() as Void {
        if (_scrollPos + ROWS < _settings.size()) { _scrollPos++; WatchUi.requestUpdate(); }
    }

    public function rowForTapY(tapY as Number) as Number {
        if (tapY < CONTENT_Y || tapY >= FOOTER_Y) { return -1; }
        var idx = _scrollPos + (tapY - CONTENT_Y) / ROW_H;
        return (idx < _settings.size()) ? idx : -1;
    }

    private function formatValue(desc as Dictionary) as String {
        var key = desc.get(:key) as String;
        var raw = Application.Properties.getValue(key);
        var n   = (raw instanceof Number) ? raw as Number : 0;
        if (desc.get(:type) == :toggle) {
            var opts = desc.get(:opts) as Array;
            return (n == 0) ? (opts[0] as String) : (opts[1] as String);
        }
        if (key.equals("ewmaAlphaTimes10")) { return "0." + n.toString(); }
        return n.toString() + (desc.get(:unit) as String);
    }

    public function onShow() as Void { WatchUi.requestUpdate(); }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, "Settings",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        for (var i = 0; i < ROWS; i++) {
            var idx = _scrollPos + i;
            if (idx >= _settings.size()) { break; }

            var desc = _settings[idx] as Dictionary;
            var rowY = CONTENT_Y + i * ROW_H;

            if (i % 2 == 1) {
                dc.setColor(0x0A0A0A, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0, rowY, w, ROW_H - 1);
            }

            var textY = rowY + ROW_H / 2;

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(30, textY, Graphics.FONT_XTINY, desc.get(:label) as String,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w - 30, textY, Graphics.FONT_XTINY, formatValue(desc),
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(20, rowY + ROW_H - 1, w - 20, rowY + ROW_H - 1);
        }

        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, FOOTER_Y, w, FOOTER_H);
        ArrowUtils.drawUpDownHint(dc, cx, FOOTER_Y + FOOTER_H / 2,
            "=Scroll  Tap=Adjust", Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);

        dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
        var endIdx = _scrollPos + ROWS;
        if (endIdx > _settings.size()) { endIdx = _settings.size(); }
        dc.drawText(cx, FOOTER_Y + FOOTER_H + 14, Graphics.FONT_XTINY,
            (_scrollPos + 1).toString() + "-" + endIdx.toString() +
            " of " + _settings.size().toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class SettingsMenuDelegate extends WatchUi.BehaviorDelegate {
    private var _view as SettingsMenuView;

    public function initialize(view as SettingsMenuView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    public function onPreviousPage() as Boolean { _view.scrollUp();   return true; }
    public function onNextPage()     as Boolean { _view.scrollDown(); return true; }

    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var idx    = _view.rowForTapY(coords[1]);
        if (idx >= 0) {
            var desc = _view.getSetting(idx);
            var adjV = new SettingAdjustView(desc);
            var adjD = new SettingAdjustDelegate(adjV, _view);
            WatchUi.pushView(adjV, adjD, WatchUi.SLIDE_LEFT);
            return true;
        }
        return false;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// Layout (y):
//   42-70  : header
//   90     : up arrow hint
//   140    : current value (FONT_NUMBER_MILD) [was 150]
//   186    : range hint / toggle options label [was 196]
//   218    : down arrow hint
//   248    : desc line 1
//   278    : desc line 2
//   308    : desc line 3
//   322    : formula line (EWMA only)
//   355-379: footer

class SettingAdjustView extends WatchUi.View {

    private var _desc    as Dictionary;
    private var _current as Number;

    public function initialize(desc as Dictionary) {
        View.initialize();
        _desc    = desc;
        var raw  = Application.Properties.getValue(desc.get(:key) as String);
        _current = (raw instanceof Number) ? raw as Number : 0;
    }

    public function increment() as Void {
        if (_desc.get(:type) == :toggle) {
            _current = (_current == 0) ? 1 : 0;
        } else {
            var step = _desc.get(:step) as Number;
            var max  = _desc.get(:max)  as Number;
            _current += step;
            if (_current > max) { _current = max; }
        }
        WatchUi.requestUpdate();
    }

    public function decrement() as Void {
        if (_desc.get(:type) == :toggle) {
            _current = (_current == 0) ? 1 : 0;
        } else {
            var step = _desc.get(:step) as Number;
            var min  = _desc.get(:min)  as Number;
            _current -= step;
            if (_current < min) { _current = min; }
        }
        WatchUi.requestUpdate();
    }

    public function save() as Void {
        Application.Properties.setValue(_desc.get(:key) as String, _current);
    }

    public function onShow() as Void { WatchUi.requestUpdate(); }

    public function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0x004488, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 42, w, 28);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 56, Graphics.FONT_TINY, _desc.get(:label) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        ArrowUtils.drawUpArrow(dc, cx, 90, ArrowUtils.HINT_ARROW_SIZE, 0x555555);

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 140, Graphics.FONT_NUMBER_MILD, formatCurrentValue(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (_desc.get(:type) != :toggle) {
            var min  = _desc.get(:min)  as Number;
            var max  = _desc.get(:max)  as Number;
            var unit = _desc.get(:unit) as String;
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 186, Graphics.FONT_XTINY,
                "Range: " + min.toString() + " - " + max.toString() + unit,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var opts = _desc.get(:opts) as Array;
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 186, Graphics.FONT_XTINY,
                (opts[0] as String) + " or " + (opts[1] as String),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        ArrowUtils.drawDownArrow(dc, cx, 218, ArrowUtils.HINT_ARROW_SIZE, 0x555555);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 248, Graphics.FONT_XTINY, _desc.get(:desc1) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, 278, Graphics.FONT_XTINY, _desc.get(:desc2) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var d3 = _desc.get(:desc3) as String;
        if (!d3.equals("")) {
            dc.drawText(cx, 308, Graphics.FONT_XTINY, d3,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var formula = _desc.get(:formula) as String;
        if (!formula.equals("")) {
            dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 334, Graphics.FONT_XTINY, formula,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 355, w, 24);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 367, Graphics.FONT_XTINY, "Tap=Save  Back=Cancel",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function formatCurrentValue() as String {
        if (_desc.get(:type) == :toggle) {
            var opts = _desc.get(:opts) as Array;
            return (_current == 0) ? (opts[0] as String) : (opts[1] as String);
        }
        var key = _desc.get(:key) as String;
        if (key.equals("ewmaAlphaTimes10")) { return "0." + _current.toString(); }
        return _current.toString() + (_desc.get(:unit) as String);
    }
}

class SettingAdjustDelegate extends WatchUi.BehaviorDelegate {
    private var _view     as SettingAdjustView;
    private var _menuView as SettingsMenuView;

    public function initialize(view as SettingAdjustView, menuView as SettingsMenuView) {
        BehaviorDelegate.initialize();
        _view     = view;
        _menuView = menuView;
    }

    public function onPreviousPage() as Boolean { _view.decrement(); return true; }
    public function onNextPage()     as Boolean { _view.increment(); return true; }

    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.save();
        _menuView.onShow();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
