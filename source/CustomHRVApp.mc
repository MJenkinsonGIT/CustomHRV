import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class CustomHRVApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
    }

    // Called by the OS when settings are changed via Garmin Connect app
    public function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    public function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new DashboardView();
        var delegate = new DashboardDelegate(view);
        return [view, delegate];
    }
}
