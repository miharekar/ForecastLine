using Toybox.Application as App;
using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.Position;

(:background)
class ForecastLineApp extends App.AppBase {
  hidden var _view;
  hidden var _lastRefresh;

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state) {
    if (dataIsOld()) {
      App.getApp().deleteProperty(ForecastLine.CURRENTLY);
    }
    verifyDonation();
    // New version data resetter
    if (Application.Storage.getValue(ForecastLine.RESET_DATA) != 1) {
      App.getApp().clearProperties();
      Application.Storage.setValue(ForecastLine.RESET_DATA, 1);
    }
  }

  // Return the initial view of your application here
  function getInitialView() {
    //register for temporal events if they are supported
    if(canDoBackground() && hasApiKey()) {
      Background.registerForTemporalEvent(new Time.Duration(15 * 60));
    }

    _view = new ForecastLineView();
    getPosition();
    return [_view];
  }

  function onStop(state) {
  }

  // For this app all that needs to be done is trigger a Ui refresh
  // since the settings are only used in onUpdate().
  function onSettingsChanged() {
    verifyDonation();
    _view.data_at = null;
    _view.updateModel();
  }

  function onBackgroundData(data) {
    if (data != null) {
      saveData(data);
    }
  }

  function getServiceDelegate(){
    return [new ForecastLineBackgroundServiceDelegate()];
  }

  function getPosition() {
    var info = Position.getInfo();
    if (info.accuracy != Position.QUALITY_NOT_AVAILABLE) {
      onPosition(info);
    } else {
      fetchData();
      _view.updateModel();
    }
    Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
  }

  function fetchData() {
    if (phoneConnected() && hasCoordinates() && isNotRefreshingNow() && dataIsOld()) {
      _lastRefresh = Time.now().value();
      var params = {"coordinates" => Application.Storage.getValue(ForecastLine.COORDINATES)};
      if (hasApiKey()) {
      	params.put("api_key", Application.Properties.getValue("ds_api_key"));
      }
      Comm.makeWebRequest(ForecastLineSecrets.URL, params, {:headers => {"Authorization" => ForecastLineSecrets.AUTH}}, method(:onResponse));
    }
  }

  function phoneConnected() {
    return System.getDeviceSettings().phoneConnected;
  }

  function hasCoordinates() {
    return (Application.Storage.getValue(ForecastLine.COORDINATES) != null);
  }

  function isNotRefreshingNow() {
    return (_lastRefresh == null || _lastRefresh > Time.now().value() - 10);
  }

  function dataIsOld() {
    var data_at = Application.Storage.getValue(ForecastLine.DATA_AT);
    return (data_at == null || data_at < Time.now().value() - (15 * 60));
  }

  function onPosition(info) {
    var latLon = info.position.toDegrees();
    var coordinates = latLon[0].toString() + "," + latLon[1].toString();
    Application.Storage.setValue(ForecastLine.COORDINATES, coordinates);
    Application.Storage.setValue(ForecastLine.LATITUDE, latLon[0]);
    Application.Storage.setValue(ForecastLine.LONGITUDE, latLon[1]);
    fetchData();
    _view.updateModel();
  }

  function onResponse(responseCode, data) {
    if(responseCode == 200) {
      saveData(data);
    } else {
      Application.Storage.setValue(ForecastLine.ERROR, responseCode);
      App.getApp().deleteProperty(ForecastLine.HOURLY);
      App.getApp().deleteProperty(ForecastLine.CURRENTLY);
      App.getApp().deleteProperty(ForecastLine.LOCATION);
      App.getApp().deleteProperty(ForecastLine.DATA_AT);
    }

    _view.updateModel();
  }

  function saveData(data) {
    App.getApp().deleteProperty(ForecastLine.ERROR);
    Application.Storage.setValue(ForecastLine.HOURLY, data["h"]);
    Application.Storage.setValue(ForecastLine.CURRENTLY, data["c"][0]);
    Application.Storage.setValue(ForecastLine.LOCATION, data["l"]);
    Application.Storage.setValue(ForecastLine.DATA_AT, Time.now().value());
  }

  function verifyDonation() {
    var donation = Application.Properties.getValue("donation");
    if (donation == null || !donation.toLower().equals(ForecastLineSecrets.DONATION)) {
      Application.Properties.setValue("background", false);
    }
  }

  function canDoBackground() {
  	return (Toybox.System has :ServiceDelegate);
  }

  function hasApiKey() {
  	var ds_api_key = Application.Properties.getValue("ds_api_key");
  	return (ds_api_key != null && ds_api_key.length() == 32);
  }
}
