using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.Position;

class ForecastLineApp extends App.AppBase {
    hidden var _view;

    function initialize() {
        AppBase.initialize();
        App.getApp().deleteProperty(ForecastLine.CURRENTLY);

        // New version data resetter
        if (App.getApp().getProperty(ForecastLine.RESET_DATA) != 1) {
            App.getApp().clearProperties();
            App.getApp().setProperty(ForecastLine.RESET_DATA, 1);
        }
    }

    // For this app all that needs to be done is trigger a Ui refresh
    // since the settings are only used in onUpdate().
    function onSettingsChanged() {
        verifyDonation();
        _view.updateModel();
    }

    // Return the initial view of your application here
    function getInitialView() {
        verifyDonation();
        fetchData();
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        _view = new ForecastLineView();
        _view.updateModel();
        return [_view];
    }

    function onPosition(info) {
        var latLon = info.position.toDegrees();
        var coordinates = latLon[0].toString() + "," + latLon[1].toString();
        App.getApp().setProperty(ForecastLine.COORDINATES, coordinates);
        fetchData();
        _view.updateModel();
    }

    function fetchData() {
        var coordinates = App.getApp().getProperty(ForecastLine.COORDINATES);
        if (coordinates != null) {
            Comm.makeWebRequest(ForecastLineSecrets.URL, {"coordinates" => coordinates}, {:headers => {"Authorization" => ForecastLineSecrets.AUTH}}, method(:onResponse));
        }
    }

    // Handles response from server
    function onResponse(responseCode, data) {
        if(responseCode == 200) {
            App.getApp().deleteProperty(ForecastLine.ERROR);
            App.getApp().setProperty(ForecastLine.HOURLY, data["h"]);
            App.getApp().setProperty(ForecastLine.CURRENTLY, data["c"][0]);
        } else {
            App.getApp().setProperty(ForecastLine.ERROR, responseCode);
        }

        _view.updateModel();
    }

    function verifyDonation() {
        var donation = App.getApp().getProperty("donation").toLower();
        if (!donation.equals(ForecastLineSecrets.DONATION)) {
            App.getApp().setProperty("background", false);
        }
    }
}
