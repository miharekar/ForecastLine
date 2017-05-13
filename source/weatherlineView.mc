using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.Time.Gregorian;

class weatherlineView extends Ui.View {
    var _screenSize = new[2];
    var degreeHeight;
    var midScreen;
    var spacing;
    var data;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        _screenSize[0] = dc.getWidth();
        _screenSize[1] = dc.getHeight();
        degreeHeight = -_screenSize[1] / 50;
        midScreen = _screenSize[1] / 2;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        drawBackground(dc);
        data = App.getApp().getProperty("hourly");
        if ((data instanceof Toybox.Lang.Array) && (data.size() > 0)) {
            display(dc);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    function updateModel() {
        Ui.requestUpdate();
    }

    function display(dc) {
        spacing = (_screenSize[0]) / (data.size() - 1).toFloat();
        drawVerticalLines(dc, data.size());
        drawHours(dc);
        drawTemperatureLines(dc);
        drawIcons(dc);
    }

    function drawBackground(dc) {
        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, _screenSize[0], _screenSize[1]);
    }

    function drawVerticalLines(dc, size) {
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var x;
        for(var i = 0; i < size; i++) {
            x = i * spacing + (spacing/2);
            dc.drawLine(x, 0, x, _screenSize[1]);
        }
    }

    function drawHours(dc) {
        var x;
        var hour;
        var value;
        for(var i = 0; i < data.size(); i++) {
            x = i * spacing;
            hour = Gregorian.info(new Time.Moment(data[i]["time"]), Time.FORMAT_SHORT).hour;
            if (!System.getDeviceSettings().is24Hour && hour > 12) { hour -= 12; }
            value = hour.format("%02d");
            new Ui.Text({:text => value, :color => Gfx.COLOR_LT_GRAY, :font => Gfx.FONT_XTINY, :justification => Gfx.TEXT_JUSTIFY_CENTER, :locX => x, :locY => 50}).draw(dc);
        }
    }

    function drawTemperatureLines(dc) {
        var temperature;
        var x;
        var y;
        var previous_x = null;
        var previous_y = null;
        var precipitation = ["snow", "rain", "sleet"];
        dc.setPenWidth(2);
        for(var i = 0; i < data.size(); i++) {
            temperature = data[i]["temperature"];
            x = i * spacing;
            y = midScreen + ((temperature - data[0]["temperature"]) * degreeHeight);

            if(previous_x != null) {
                if (precipitation.indexOf(data[i]["icon"]) == -1) {
                    dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
                }
                dc.drawLine(previous_x, previous_y, x, y);
            }

            previous_x = x;
            previous_y = y;
        }
    }

    function drawIcons(dc) {
        var x;
        var y;
        var icon;
        var value;
        var fahrenheit = (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE);

        for(var i = 1; i < data.size(); i = i + 2) {
            x = i * spacing;
            y = midScreen + ((data[i]["temperature"] - data[0]["temperature"]) * degreeHeight);

            icon = getIcon(data[i]["icon"]);
            icon.setLocation(x - 10, y - 25);
            icon.draw(dc);

            if (fahrenheit) {
                value = data[i]["temperature"] * 9 / 5 + 32;
            } else {
                value = data[i]["temperature"];
            }

            new Ui.Text({:text => Math.round(value).format("%i"), :color => Gfx.COLOR_BLACK, :font => Gfx.FONT_TINY, :justification => Gfx.TEXT_JUSTIFY_CENTER, :locX => x, :locY => y}).draw(dc);
        }
    }

    var iconIds = {
        "clear-day" => Rez.Drawables.ClearDay,
        "clear-night" => Rez.Drawables.ClearNight,
        "rain" => Rez.Drawables.Rain,
        "snow" => Rez.Drawables.Snow,
        "sleet" => Rez.Drawables.Sleet,
        "wind" => Rez.Drawables.Wind,
        "fog" => Rez.Drawables.Fog,
        "cloudy" => Rez.Drawables.Cloudy,
        "partly-cloudy-day" => Rez.Drawables.PartlyCloudyDay,
        "partly-cloudy-night" => Rez.Drawables.PartlyCloudyNight
    };

    function getIcon(name) {
        return new Ui.Bitmap({:rezId=>iconIds[name]});
    }
}
