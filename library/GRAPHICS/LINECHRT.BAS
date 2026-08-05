' ============================================================
' TITLE:    Two-City Temperature Line Chart
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     line chart, window, markers, legend, screen 8
' SUMMARY:  Plots a year of average temperatures for two cities as a line chart with markers, a legend and a zero line.
' ------------------------------------------------------------
' WHAT IT DOES
'   Compares the monthly average temperature of a northern city
'   and a southern-hemisphere city. Each series is drawn as a
'   line joining twelve points, with a different marker shape.
'   It runs in SCREEN 8 (640x200, 16 colours), so pixels are
'   very tall and thin - perfect for showing why WINDOW is handy.
'
' HOW TO USE
'   Press any key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * WINDOW with data units (months across, degrees up)
'   * Negative numbers on a chart: the y range crosses zero
'   * LINE -(x, y) to continue a polyline from the last point
'   * Drawing markers: small boxes and small diamonds
'   * Using PMAP to place text labels next to data points
'
' THINGS TO TRY
'   * Add a third city in a new colour
'   * Fill the area between the two lines with vertical LINEs
'   * Show the yearly average as a dashed horizontal line
' ============================================================

DIM a(12), b(12)
FOR m = 1 TO 12: READ a(m): NEXT m
FOR m = 1 TO 12: READ b(m): NEXT m

SCREEN 8
CLS

' Plot area in pixels; leave room for text on the left/bottom.
VIEW (48, 16)-(630, 175), 0, 7
' Data space: months 0.5..12.5 across, -15..30 degrees up.
WINDOW (.5, -15)-(12.5, 30)

' ---- Gridlines ----------------------------------------------------
FOR t = -10 TO 30 STEP 10
    IF t = 0 THEN
        LINE (.5, 0)-(12.5, 0), 15            ' the freezing line
    ELSE
        LINE (.5, t)-(12.5, t), 8, , &H8888    ' faint dotted
    END IF
NEXT t
FOR m = 1 TO 12
    LINE (m, -15)-(m, 30), 8, , &H8080
NEXT m

' ---- Series A (red, square markers) ------------------------------
PSET (1, a(1)), 12
FOR m = 2 TO 12
    LINE -(m, a(m)), 12
NEXT m
' Markers: a box 0.12 months wide by 1.4 degrees tall. In data
' units this looks square on screen even though pixels are tall.
FOR m = 1 TO 12
    LINE (m - .06, a(m) - .7)-(m + .06, a(m) + .7), 12, BF
NEXT m

' ---- Series B (cyan, diamond markers) -----------------------------
PSET (1, b(1)), 11
FOR m = 2 TO 12
    LINE -(m, b(m)), 11
NEXT m
FOR m = 1 TO 12
    LINE (m - .09, b(m))-(m, b(m) + 1.1), 11
    LINE -(m + .09, b(m)), 11
    LINE -(m, b(m) - 1.1), 11
    LINE -(m - .09, b(m)), 11
NEXT m

' ---- Text: axes labels, title and legend ---------------------------
' PMAP converts a data y value to a pixel row inside the VIEW;
' we add the view's top (16) and divide by 8 (text row height).
FOR t = -10 TO 30 STEP 10
    py = PMAP(t, 1) + 16
    r = INT(py / 8) + 1
    LOCATE r, 2: PRINT USING "###"; t;
NEXT t
LOCATE 1, 2: PRINT "deg C"
LOCATE 1, 25: PRINT "Average monthly temperature"
m$ = "JFMAMJJASOND"
FOR m = 1 TO 12
    px = PMAP(m, 0) + 48
    LOCATE 24, INT(px / 8) + 1: PRINT MID$(m$, m, 1);
NEXT m
COLOR 12: LOCATE 25, 10: PRINT CHR$(254); " Moscow";
COLOR 11: LOCATE 25, 30: PRINT CHR$(4); " Buenos Aires";
COLOR 7: LOCATE 25, 55: PRINT "Press any key";

SLEEP
SCREEN 0: WIDTH 80
END

' Moscow (approximate monthly averages, degrees C)
DATA -7, -7, -1, 6, 13, 17, 19, 17, 11, 5, -1, -5
' Buenos Aires
DATA 25, 24, 22, 18, 15, 12, 11, 13, 15, 18, 21, 24
