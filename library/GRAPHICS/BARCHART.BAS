' ============================================================
' TITLE:    3-D Bar Chart
' CATEGORY: Graphics
' LEVEL:    Beginner
' TAGS:     bar chart, line, bf, data, scaling, screen 12
' SUMMARY:  Draws an animated 3-D bar chart of monthly rainfall with gridlines, axis labels and value tags.
' ------------------------------------------------------------
' WHAT IT DOES
'   Reads twelve monthly rainfall numbers from DATA and draws a
'   bar chart. Each bar "grows" upward from the axis, and gets a
'   shaded top and side so it looks three-dimensional.
'
' HOW TO USE
'   Watch the bars grow. Press any key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Scaling: turning data values into pixel heights
'   * LINE ... , BF for solid bars
'   * Faking 3-D with two extra shapes (top and side)
'   * Simple polygons made of LINE, filled with PAINT
'   * Rounding a maximum up to a "nice" number for the axis
'
' THINGS TO TRY
'   * Put in your own data (test scores, pocket money...)
'   * Colour bars above the average differently
'   * Make the bars horizontal instead of vertical
' ============================================================

DIM mon$(12), rain(12)

' ---- Read the data and find the largest value ---------------------
maxv = 0
FOR i = 1 TO 12
    READ mon$(i), rain(i)
    IF rain(i) > maxv THEN maxv = rain(i)
NEXT i
' Round the axis top up to the next multiple of 20 so the
' gridlines fall on friendly numbers.
top = (INT(maxv / 20) + 1) * 20

SCREEN 12
CLS

' ---- Chart area (in pixels) ----------------------------------------
x0 = 70: y0 = 420          ' bottom-left corner of the plot area
w = 540: h = 340           ' size of the plot area
scale = h / top            ' pixels per millimetre of rain

COLOR 15
LOCATE 2, 25: PRINT "Monthly Rainfall (millimetres)"

' Gridlines and y-axis labels every 20 mm.
FOR v = 0 TO top STEP 20
    y = y0 - v * scale
    LINE (x0, y)-(x0 + w, y), 8, , &HCCCC     ' dashed grey
    ' Text rows are 16 pixels tall in SCREEN 12.
    ' Subtracting 8 centres the number on the line.
    LOCATE INT((y - 8) / 16) + 1, 3: PRINT USING "###"; v
NEXT v
LINE (x0, y0 - h)-(x0, y0), 15                 ' y axis
LINE (x0, y0)-(x0 + w, y0), 15                 ' x axis

' ---- The bars --------------------------------------------------------
barw = 26                  ' bar width
gap = w / 12               ' room per month
d = 8                      ' depth of the 3-D effect

FOR i = 1 TO 12
    bx = x0 + (i - 1) * gap + 10
    hgt = rain(i) * scale
    ' Colour: blue for wet months, cyan for normal, yellow for dry
    IF rain(i) >= 80 THEN c = 9 ELSE IF rain(i) >= 40 THEN c = 3 ELSE c = 14

    ' Animate: grow from 0 to the full height in 10 steps.
    ' TIMER only ticks about 18 times a second, so each pause
    ' below lasts roughly one tick.
    FOR g = 1 TO 10
        LINE (bx, y0 - hgt * g / 10)-(bx + barw, y0 - 1), c, BF
        t! = TIMER: DO: LOOP WHILE TIMER - t! < .03 AND TIMER >= t!
    NEXT g
    yt = y0 - hgt
    LINE (bx, yt)-(bx + barw, y0 - 1), c, BF

    ' 3-D top: a parallelogram leaning back and to the right.
    ' Outline it in white and fill it with bright white (15).
    LINE (bx, yt)-(bx + d, yt - d), 15
    LINE -(bx + barw + d, yt - d), 15
    LINE -(bx + barw, yt), 15
    LINE -(bx, yt), 15
    IF hgt > 0 THEN PAINT (bx + barw \ 2 + d \ 2, yt - d \ 2), 7, 15

    ' 3-D side: a darker parallelogram on the right.
    LINE (bx + barw, yt)-(bx + barw + d, yt - d), 15
    LINE -(bx + barw + d, y0 - d), 15
    LINE -(bx + barw, y0 - 1), 15
    LINE -(bx + barw, yt), 15          ' close the shape or PAINT leaks!
    IF hgt > d THEN PAINT (bx + barw + d \ 2, (yt + y0) \ 2), 1, 15

    ' Month name under the bar and value above it
    LOCATE 28, INT(bx / 8) + 1: PRINT mon$(i);
    vr = INT((yt - d) / 16)            ' text row just above the bar
    IF vr < 1 THEN vr = 1
    LOCATE vr, INT(bx / 8) + 1: PRINT USING "###"; rain(i);
NEXT i

LOCATE 30, 28: PRINT "Press any key to quit";
SLEEP
SCREEN 0: WIDTH 80
END

' Month, rainfall in millimetres
DATA Jan, 78, Feb, 55, Mar, 61, Apr, 47, May, 52, Jun, 38
DATA Jul, 21, Aug, 30, Sep, 49, Oct, 84, Nov, 102, Dec, 96
