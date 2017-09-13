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

  // Return the initial view of your application here
  function getInitialView() {
    if (dataIsOld()) {
      App.getApp().deleteProperty(ForecastLine.CURRENTLY);
    }

    verifyDonation();

    // New version data resetter
    if (App.getApp().getProperty(ForecastLine.RESET_DATA) != 1) {
      App.getApp().clearProperties();
      App.getApp().setProperty(ForecastLine.RESET_DATA, 1);
    }

    //register for temporal events if they are supported
    if(canDoBackground() && hasApiKey()) {
      Background.registerForTemporalEvent(new Time.Duration(15 * 60));
    }

    _view = new ForecastLineView();
    getPosition();
    return [_view];
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
      var params = {"coordinates" => App.getApp().getProperty(ForecastLine.COORDINATES)};
      if (hasApiKey()) {
      	params.put("api_key", App.getApp().getProperty("ds_api_key"));
      }
      Comm.makeWebRequest(ForecastLineSecrets.URL, params, {:headers => {"Authorization" => ForecastLineSecrets.AUTH}}, method(:onResponse));
    }
  }

  function phoneConnected() {
    return System.getDeviceSettings().phoneConnected;
  }

  function hasCoordinates() {
    return (App.getApp().getProperty(ForecastLine.COORDINATES) != null);
  }

  function isNotRefreshingNow() {
    return (_lastRefresh == null || _lastRefresh > Time.now().value() - 10);
  }

  function dataIsOld() {
    var data_at = App.getApp().getProperty(ForecastLine.DATA_AT);
    return (data_at == null || data_at < Time.now().value() - (15 * 60));
  }

  function onPosition(info) {
    var latLon = info.position.toDegrees();
    var coordinates = latLon[0].toString() + "," + latLon[1].toString();
    App.getApp().setProperty(ForecastLine.COORDINATES, coordinates);
    App.getApp().setProperty(ForecastLine.LATITUDE, latLon[0]);
    App.getApp().setProperty(ForecastLine.LONGITUDE, latLon[1]);
    fetchData();
    _view.updateModel();
  }

  function onResponse(responseCode, data) {
    if(responseCode == 200) {
      saveData(data);
    } else {
      App.getApp().setProperty(ForecastLine.ERROR, responseCode);
      App.getApp().deleteProperty(ForecastLine.HOURLY);
      App.getApp().deleteProperty(ForecastLine.CURRENTLY);
      App.getApp().deleteProperty(ForecastLine.LOCATION);
      App.getApp().deleteProperty(ForecastLine.DATA_AT);
    }

    _view.updateModel();
  }

  function saveData(data) {
    App.getApp().deleteProperty(ForecastLine.ERROR);
    App.getApp().setProperty(ForecastLine.HOURLY, data["h"]);
    App.getApp().setProperty(ForecastLine.CURRENTLY, data["c"][0]);
    App.getApp().setProperty(ForecastLine.LOCATION, data["l"]);
    App.getApp().setProperty(ForecastLine.DATA_AT, Time.now().value());
  }

  function verifyDonation() {
    var donation = App.getApp().getProperty("donation");
    if (donation == null || !donation.toLower().equals(ForecastLineSecrets.DONATION)) {
      App.getApp().setProperty("background", false);
    }
  }
  
  function canDoBackground() {
  	return (Toybox.System has :ServiceDelegate);
  }
  
  function hasApiKey() {
  	var ds_api_key = App.getApp().getProperty("ds_api_key");
  	return (ds_api_key != null && ds_api_key.length() > 10);
  }
}
