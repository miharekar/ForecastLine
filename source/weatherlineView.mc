using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Math;

class weatherlineView extends Ui.View {
    var _hourly = [];
    var _screenSize = new[2];
    var _bgcolor = Gfx.COLOR_BLACK;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        _screenSize[0] = dc.getWidth();
        _screenSize[1] = dc.getHeight();
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
        if ((_hourly instanceof Toybox.Lang.Array) && (_hourly.size() > 0)) {
            //drawChart(dc);
            drawCircles(dc);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    function drawBackground(dc)
    {
        dc.clear();
        dc.setColor(_bgcolor, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, _screenSize[0], _screenSize[1]);
    }

    function drawChart(dc) {
        var width = _screenSize[0]/_hourly.size();
        var startingPoint = _screenSize[1]/4*3;
        for( var i = 0; i < _hourly.size(); i++ ) {
            var hour = _hourly[i];
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
            var tempHeight = hour["temperature"]*5;
            dc.fillRectangle (i*width, startingPoint-tempHeight, width, tempHeight);
        }
    }

    function drawCircles(dc) {
        dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var spacing = (_screenSize[0] - 10) / (_hourly.size() - 1).toFloat();
        var degreeHeight = -_screenSize[1] / 50;
        var midScreen = _screenSize[1] / 2;
        var first = _hourly[0]["temperature"];
        var previous_x = null;
        var previous_y = null;

        for(var i = 0; i < _hourly.size(); i++) {
            var hour = _hourly[i];
            var x = 5 + i * spacing;
            var y = midScreen + ((hour["temperature"] - first) * degreeHeight);

            if( previous_x != null ) {
                dc.drawLine(previous_x, previous_y, x, y);
            }

            previous_x = x;
            previous_y = y;
        }

        for(var i = 1; i < _hourly.size(); i = i + 3) {
            var hour = _hourly[i];
            var x = 5 + i * spacing;
            var y = midScreen + ((hour["temperature"] - first) * degreeHeight);
            var icon = getIcon(hour["icon"]);
            icon.setLocation(x - 10, y - 25);
            icon.draw(dc);
            var value = (Math.round(hour["temperature"]*10)/10).format("%.1f");
            var text = new Ui.Text({:text => value, :color => Gfx.COLOR_BLACK, :font => Gfx.FONT_TINY, :justification => Gfx.TEXT_JUSTIFY_CENTER});
            text.setLocation(x, y);
            text.draw(dc);
        }
    }

    function getIcon(icon) {
        var ids = {
            "clear-day" => Rez.Drawables.ClearDay,
            "clear-night" => Rez.Drawables.ClearNight,
            "partly-cloudy-night" => Rez.Drawables.PartlyCloudyNight,
            "partly-cloudy-day" => Rez.Drawables.PartlyCloudyDay,
            "cloudy" => Rez.Drawables.Cloudy,
            "rain" => Rez.Drawables.Rain
        };
        System.println(icon);
        return new Ui.Bitmap({:rezId=>ids[icon]});
    }

    function maxDiff() {
        var diff = 0;
        for( var i = 0; i < _hourly.size(); i++ ) {
            var hour = _hourly[i];
            var currentDiff = (_hourly[0]["temperature"] - hour["temperature"]).abs();
            if (currentDiff > diff) {
                diff = currentDiff;
            }
        }
        return Math.ceil(diff);
    }

    function maxTemperature() {
        var max = _hourly[0]["temperature"];
        for( var i = 0; i < _hourly.size(); i++ ) {
            var hour = _hourly[i];
            if (hour["temperature"] > max) {
                max = hour["temperature"];
            }
        }
        return Math.ceil(max);
    }

    function minTemperature() {
        var min = _hourly[0]["temperature"];
        for( var i = 0; i < _hourly.size(); i++ ) {
            var hour = _hourly[i];
            if (hour["temperature"] < min) {
                min = hour["temperature"];
            }
        }
        return Math.floor(min);
    }

    function updateModel(data) {
        if (data == :coordinates) {
            _bgcolor = Gfx.COLOR_WHITE;
        }
        _hourly = data;
        Ui.requestUpdate();
    }
}
