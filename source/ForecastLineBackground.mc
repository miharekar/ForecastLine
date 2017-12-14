using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;

// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.

(:background)
class ForecastLineBackgroundServiceDelegate extends System.ServiceDelegate {
  function initialize() {
    System.ServiceDelegate.initialize();
  }

  function onTemporalEvent() {
    var coordinates = Application.Storage.getValue(ForecastLine.COORDINATES);
    var ds_api_key = Application.Properties.getValue("ds_api_key");
    if (coordinates != null && ds_api_key != null && ds_api_key.length() == 32 && System.getDeviceSettings().phoneConnected) {
      var params = {"coordinates" => coordinates, "api_key" => ds_api_key};
      Comm.makeWebRequest(ForecastLineSecrets.URL, params, {:headers => {"Authorization" => ForecastLineSecrets.AUTH}}, method(:onResponse));
    } else {
      Background.exit(null);
    }
  }

  function onResponse(responseCode, data) {
    if(responseCode != 200) {
      data = null;
    }
    Background.exit(data);
  }
}
