import Toybox.Graphics;
import Toybox.Lang;

module ArrowUtils {

    // Arrow size for footer hint text (matches FONT_XTINY scale)
    const HINT_ARROW_SIZE = 10;

    // Draw a filled upward-pointing triangle
    function drawUpArrow(dc as Graphics.Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var half = size / 2;
        var vOff = (size * 0.45).toNumber();
        dc.fillPolygon([
            [cx, cy - vOff],
            [cx - half, cy + vOff],
            [cx + half, cy + vOff]
        ]);
    }

    // Draw a filled downward-pointing triangle
    function drawDownArrow(dc as Graphics.Dc, cx as Number, cy as Number, size as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var half = size / 2;
        var vOff = (size * 0.45).toNumber();
        dc.fillPolygon([
            [cx, cy + vOff],
            [cx - half, cy - vOff],
            [cx + half, cy - vOff]
        ]);
    }

    // Draw "▲/▼=<suffix>" centered at cx, cy using drawn arrows
    function drawUpDownHint(dc as Graphics.Dc, cx as Number, cy as Number,
                            suffix as String, font as Graphics.FontType, color as Number) as Void {
        var aSize = HINT_ARROW_SIZE;
        var slashDims = dc.getTextDimensions("/", font);
        var slashW = slashDims[0] as Number;
        var suffDims = dc.getTextDimensions(suffix, font);
        var suffW = suffDims[0] as Number;
        var totalW = aSize + 2 + slashW + 2 + aSize + suffW;
        var startX = cx - totalW / 2;

        drawUpArrow(dc, startX + aSize / 2, cy, aSize, color);

        var slashX = startX + aSize + 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(slashX, cy, font, "/",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var ax2 = slashX + slashW + 2 + aSize / 2;
        drawDownArrow(dc, ax2, cy, aSize, color);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ax2 + aSize / 2, cy, font, suffix,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Draw "▲=<text>" or "▼=<text>" centered at cx, cy
    function drawArrowLabel(dc as Graphics.Dc, cx as Number, cy as Number,
                            isUp as Boolean, label as String,
                            font as Graphics.FontType, color as Number) as Void {
        var aSize = HINT_ARROW_SIZE;
        var labelDims = dc.getTextDimensions(label, font);
        var labelW = labelDims[0] as Number;
        var totalW = aSize + 2 + labelW;
        var startX = cx - totalW / 2;

        if (isUp) {
            drawUpArrow(dc, startX + aSize / 2, cy, aSize, color);
        } else {
            drawDownArrow(dc, startX + aSize / 2, cy, aSize, color);
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + aSize + 2, cy, font, label,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Draw "▲=<left>  ▼=<right>" centered at cx, cy
    function drawUpDownPair(dc as Graphics.Dc, cx as Number, cy as Number,
                            leftLabel as String, rightLabel as String,
                            font as Graphics.FontType, color as Number) as Void {
        var aSize = HINT_ARROW_SIZE;
        var gap = 10;
        var leftDims = dc.getTextDimensions(leftLabel, font);
        var leftW = leftDims[0] as Number;
        var rightDims = dc.getTextDimensions(rightLabel, font);
        var rightW = rightDims[0] as Number;
        var totalW = aSize + 2 + leftW + gap + aSize + 2 + rightW;
        var startX = cx - totalW / 2;

        drawUpArrow(dc, startX + aSize / 2, cy, aSize, color);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + aSize + 2, cy, font, leftLabel,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var rightStart = startX + aSize + 2 + leftW + gap;
        drawDownArrow(dc, rightStart + aSize / 2, cy, aSize, color);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightStart + aSize + 2, cy, font, rightLabel,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
