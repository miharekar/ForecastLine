using Toybox.Application as App;
using Toybox.Background;
using Toybox.Communications as Comm;
using Toybox.Position;

(:background)
class ForecastLineApp extends App.AppBase {
  hidden var _view;
  hidden var _lastRefresh;
  hidden var _lastPosition;

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state) {
    if (dataIsOld()) {
      App.Storage.deleteValue(ForecastLine.CURRENTLY);
    }
    verifyDonation();
    // New version data resetter
    if (App.Storage.getValue(ForecastLine.RESET_DATA) != 1) {
      App.Storage.clearValues();
      App.Storage.setValue(ForecastLine.RESET_DATA, 1);
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
    hasApiKey();
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
      var params = {"coordinates" => App.Storage.getValue(ForecastLine.COORDINATES)};
      if (hasApiKey()) {
      	params.put("api_key", App.Properties.getValue("ds_api_key"));
      }
      Comm.makeWebRequest(ForecastLineSecrets.URL, params, {:headers => {"Authorization" => ForecastLineSecrets.AUTH}}, method(:onResponse));
    }
  }

  function phoneConnected() {
    return System.getDeviceSettings().phoneConnected;
  }

  function hasCoordinates() {
    return (App.Storage.getValue(ForecastLine.COORDINATES) != null);
  }

  function isNotRefreshingNow() {
    return (_lastRefresh == null || _lastRefresh > Time.now().value() - 10);
  }
  
  function shouldRefreshPosition(info) {
    return (_lastPosition == null || _lastPosition < info.when.value() - 5);
  }

  function dataIsOld() {
    var data_at = App.Storage.getValue(ForecastLine.DATA_AT);
    return (data_at == null || data_at < Time.now().value() - (15 * 60));
  }

  function onPosition(info) {
  	if (shouldRefreshPosition(info)) { 
  	  _lastPosition = info.when.value();
  	  var latLon = info.position.toDegrees();
      var coordinates = latLon[0].toString() + "," + latLon[1].toString();
      App.Storage.deleteValue(ForecastLine.CURRENTLY);
      App.Storage.deleteValue(ForecastLine.DATA_AT);
      App.Storage.setValue(ForecastLine.COORDINATES, coordinates);
      App.Storage.setValue(ForecastLine.LATITUDE, latLon[0]);
      App.Storage.setValue(ForecastLine.LONGITUDE, latLon[1]);
      fetchData();
      _view.updateModel();
  	}
  }

  function onResponse(responseCode, data) {
    if(responseCode == 200) {
      saveData(data);
    } else {
      App.Storage.setValue(ForecastLine.ERROR, responseCode);
      App.Storage.deleteValue(ForecastLine.HOURLY);
      App.Storage.deleteValue(ForecastLine.CURRENTLY);
      App.Storage.deleteValue(ForecastLine.LOCATION);
      App.Storage.deleteValue(ForecastLine.DATA_AT);
    }

    _view.updateModel();
  }

  function saveData(data) {
    App.Storage.deleteValue(ForecastLine.ERROR);
    App.Storage.setValue(ForecastLine.HOURLY, data["h"]);
    App.Storage.setValue(ForecastLine.CURRENTLY, data["c"][0]);
    App.Storage.setValue(ForecastLine.LOCATION, data["l"]);
    App.Storage.setValue(ForecastLine.DATA_AT, Time.now().value());
  }

  function verifyDonation() {
    var donation = App.Properties.getValue("donation");
    if (donation == null || !donation.toLower().equals(ForecastLineSecrets.DONATION)) {
      App.Properties.setValue("donation", "");
      App.Properties.setValue("background", false);
    }
  }

  function canDoBackground() {
  	return (Toybox.System has :ServiceDelegate);
  }

  function hasApiKey() {
  	var ds_api_key = App.Properties.getValue("ds_api_key");
  	if (ds_api_key == null || ds_api_key.length() != 32) {
      App.Properties.setValue("ds_api_key", "");
      return false;
    }
  	return true;
  }
}
