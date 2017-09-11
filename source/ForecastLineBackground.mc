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
    var coordinates = App.getApp().getProperty(ForecastLine.COORDINATES);
    if (coordinates != null && System.getDeviceSettings().phoneConnected) {
      Comm.makeWebRequest(ForecastLineSecrets.URL, {"coordinates" => coordinates}, {:headers => {"Authorization" => ForecastLineSecrets.AUTH}}, method(:onResponse));
    }
  }

  function onResponse(responseCode, data) {
    if(responseCode != 200) {
      data = null;
    }
    Background.exit(data);
  }
}
