using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.Position;

class weatherlineApp extends App.AppBase {
    hidden var _view;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    function onEvent(properties) {
        System.println(properties);
    }

    // Return the initial view of your application here
    function getInitialView() {
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        _view = new weatherlineView();
        return [_view];
    }

    function onPosition(info)
    {
        _view.updateModel(:coordinates);
        var latLon = info.position.toDegrees();
        var coordinates = latLon[0].toString() + "," + latLon[1].toString();
        var url = "https://api.darksky.net/forecast/35f98da0680c7efd4692173115deda93/";
        coordinates = "46.060368,14.509909"; //REMOVE THIS
        Comm.makeWebRequest(
            url + coordinates,
            {"exclude" => "currently,minutely,daily,alerts,flags", "units" => "si"},
            {},
            method(:onResponse)
        );
    }

    // Handles response from server
    function onResponse(responseCode, data) {
        System.println(responseCode);
        if(responseCode == 200) {
            var hourly = data["hourly"]["data"].slice(0, 15);
            _view.updateModel(hourly);
        }
    }

}