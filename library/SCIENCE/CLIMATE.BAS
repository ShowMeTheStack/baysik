' ============================================================
' TITLE:    Climate Data Plotter
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     weather, climate, data, charts, graphs
' SUMMARY:  Draw climate charts (temperature line + rainfall bars) for world cities and the global warming curve.
' ------------------------------------------------------------
' WHAT IT DOES
'   Climate is the AVERAGE weather over many years.  Scientists
'   show it with a "climograph": bars for the rain in each month and
'   a line for the average temperature.  Built into this program
'   (as DATA) are approximate long-term averages for six cities in
'   very different climates, plus the approximate global average
'   temperature change for each decade since the 1880s.
'   Compare them: rainy-all-year Singapore, the Mumbai monsoon,
'   bone-dry Cairo, Sydney where July is winter...
'
' HOW TO USE
'   Press 1-6 to chart a city, G for the global temperature graph,
'   C to compare all cities' temperatures, ESC to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Reading tables of numbers with READ / DATA / RESTORE
'   * Drawing axes, bars and lines with a scale factor
'   * Two different units on one chart (mm and degrees C)
'   * Seasons, monsoons, hemispheres and climate change
'
' THINGS TO TRY
'   * Add your own town's climate data (find it online).
'   * Show the yearly total rainfall and the warmest month.
'   * Plot temperatures in Fahrenheit instead.
' ============================================================

DEFINT A-Z
CONST NC = 6
DIM city$(NC), temp!(NC, 12), rain!(NC, 12), ccol(NC)
DIM mon$(12)
FOR m = 1 TO 12: READ mon$(m): NEXT
DATA J,F,M,A,M,J,J,A,S,O,N,D

' ---- the data: name, colour, 12 temperatures (C), 12 rainfall (mm)
FOR c = 1 TO NC
    READ city$(c), ccol(c)
    FOR m = 1 TO 12: READ temp!(c, m): NEXT
    FOR m = 1 TO 12: READ rain!(c, m): NEXT
NEXT
DATA "London (UK)", 9
DATA 5.2,5.3,7.6,9.9,13.3,16.5,18.7,18.5,15.7,12.0,8.0,5.5
DATA 55,41,42,44,49,45,45,50,49,69,59,55
DATA "Cairo (Egypt)", 14
DATA 14.0,15.1,17.6,21.3,24.8,27.5,28.3,28.3,26.6,23.8,19.2,15.6
DATA 5,4,4,1,0,0,0,0,0,1,3,5
DATA "Mumbai (India)", 12
DATA 24.4,25.2,27.0,28.6,30.0,29.0,27.6,27.3,27.5,28.7,27.6,25.7
DATA 1,0,0,1,11,537,840,598,355,92,8,2
DATA "Sydney (Australia)", 11
DATA 23.5,23.4,22.1,19.5,16.6,14.2,13.4,14.5,17.0,18.9,20.4,22.1
DATA 101,118,130,127,92,132,98,80,68,77,83,77
DATA "Moscow (Russia)", 15
DATA -6.5,-6.7,-1.0,6.7,13.2,17.0,19.2,17.0,11.3,5.6,-1.2,-5.2
DATA 53,44,39,37,61,78,84,78,66,70,52,51
DATA "Singapore", 10
DATA 26.5,27.1,27.5,28.0,28.3,28.3,27.9,27.9,27.6,27.6,26.9,26.4
DATA 234,114,176,154,171,162,158,176,170,194,256,288

SCREEN 12
GOSUB Menu
DO
    k$ = UCASE$(INKEY$)
    IF k$ >= "1" AND k$ <= "6" THEN c = VAL(k$): GOSUB CityChart
    IF k$ = "G" THEN GOSUB GlobalChart
    IF k$ = "C" THEN GOSUB Compare
    IF k$ = CHR$(27) THEN EXIT DO
LOOP
SCREEN 0: WIDTH 80
END

Menu:
    CLS
    COLOR 14: LOCATE 3, 25: PRINT "CLIMATE DATA PLOTTER": COLOR 7
    FOR c = 1 TO NC
        LOCATE 5 + c, 25: COLOR ccol(c): PRINT c; city$(c)
    NEXT
    COLOR 7
    LOCATE 13, 25: PRINT " G  Global temperature 1880-2020s"
    LOCATE 14, 25: PRINT " C  Compare city temperatures"
    LOCATE 15, 25: PRINT " ESC quit"
    LOCATE 20, 20: PRINT "(Data are approximate long-term averages.)"
RETURN

' ------------------------------------------------------------
' CityChart: rain bars (left axis, mm) + temperature line (right
' axis, C).  Chart area: x 80..560, y 60..400
'   rain:  0..600 mm   -> 400..60  (0.5667 pixels per mm)
'   temp: -10..35 C    -> 400..60  (7.556 pixels per degree)
' ------------------------------------------------------------
CityChart:
    CLS
    COLOR 15: LOCATE 1, 3: PRINT "Climate of "; city$(c)
    LINE (80, 60)-(80, 400), 7: LINE (80, 400)-(560, 400), 7: LINE (560, 60)-(560, 400), 7
    FOR mm = 0 TO 600 STEP 100            ' left axis labels (rain)
        y = 400 - mm * .5667
        LINE (76, y)-(80, y), 9
        LOCATE (y - 8) \ 16 + 1, 4: COLOR 9: PRINT USING "###"; mm;
    NEXT
    FOR t = -10 TO 35 STEP 5              ' right axis labels (temperature)
        y = 400 - (t + 10) * 7.556
        LINE (560, y)-(564, y), 12
        LOCATE (y - 8) \ 16 + 1, 72: COLOR 12: PRINT USING "###"; t;
    NEXT
    LOCATE 2, 2: COLOR 9: PRINT "rain mm";
    LOCATE 2, 70: COLOR 12: PRINT "temp C";
    ' zero-degree line (freezing)
    y0 = 400 - 10 * 7.556
    LINE (80, y0)-(560, y0), 8, , &HAAAA
    total! = 0: hot = 1: cold = 1
    FOR m = 1 TO 12
        x = 80 + (m - 1) * 40
        ' rain bar
        bh = rain!(c, m) * .5667
        IF bh > 340 THEN bh = 340
        IF bh > 0 THEN LINE (x + 8, 400 - bh)-(x + 32, 400), 1, BF: LINE (x + 8, 400 - bh)-(x + 32, 400), 9, B
        total! = total! + rain!(c, m)
        IF temp!(c, m) > temp!(c, hot) THEN hot = m
        IF temp!(c, m) < temp!(c, cold) THEN cold = m
        LOCATE 26, x \ 8 + 3: COLOR 7: PRINT mon$(m);
    NEXT
    ' temperature line with dots
    FOR m = 1 TO 12
        x = 100 + (m - 1) * 40
        y = 400 - (temp!(c, m) + 10) * 7.556
        IF m > 1 THEN LINE (px, py)-(x, y), 12
        CIRCLE (x, y), 3, 12: PAINT (x, y), 12, 12
        px = x: py = y
    NEXT
    COLOR 15
    LOCATE 28, 3: PRINT USING "Yearly rain #### mm.  Warmest month: ### C   Coldest: ### C"; total!; temp!(c, hot); temp!(c, cold)
    LOCATE 30, 3: COLOR 7: PRINT "Press a key...";
    GOSUB WaitKey
RETURN

' ------------------------------------------------------------
' GlobalChart: approximate global surface temperature change
' per decade compared with the 1951-1980 average.
' ------------------------------------------------------------
GlobalChart:
    CLS
    COLOR 15: LOCATE 1, 3: PRINT "Global temperature change by decade (vs 1951-1980 average)"
    ' x: 15 decades across 60..600, y: -0.5..+1.2 C over 420..60
    LINE (60, 60)-(60, 420), 7
    yz = 420 - .5 * 211.8
    LINE (60, yz)-(610, yz), 7                ' the zero line
    FOR t = -5 TO 12 STEP 5
        y = 420 - (t / 10 + .5) * 211.8
        LOCATE (y - 8) \ 16 + 1, 1: PRINT USING "+#.#"; t / 10;
    NEXT
    RESTORE GlobalData
    FOR d = 0 TO 14
        READ an!
        x = 60 + d * 36
        y = 420 - (an! + .5) * 211.8
        ' blue bars below zero, red above - the "warming stripes" idea
        IF an! < 0 THEN cl = 9 ELSE cl = 12
        LINE (x + 4, yz)-(x + 30, y), cl, BF
        IF d MOD 2 = 0 THEN LOCATE 28, x \ 8 + 1: COLOR 7: PRINT LTRIM$(STR$(1880 + d * 10));
    NEXT
    COLOR 15
    LOCATE 4, 10: PRINT "The world has warmed by over 1 degree C since the late 1800s."
    LOCATE 30, 3: COLOR 7: PRINT "Press a key...";
    GOSUB WaitKey
RETURN
GlobalData:
DATA -0.20,-0.25,-0.28,-0.33,-0.22,-0.09,0.04,-0.04,-0.02,0.01,0.21,0.37,0.60,0.85,1.03

' ------------------------------------------------------------
' Compare: all six temperature lines on one chart
' ------------------------------------------------------------
Compare:
    CLS
    COLOR 15: LOCATE 1, 3: PRINT "Monthly average temperature (C) - all cities"
    LINE (80, 60)-(80, 400), 7: LINE (80, 400)-(560, 400), 7
    FOR t = -10 TO 35 STEP 5
        y = 400 - (t + 10) * 7.556
        LOCATE (y - 8) \ 16 + 1, 6: COLOR 7: PRINT USING "###"; t;
    NEXT
    FOR c = 1 TO NC
        FOR m = 1 TO 12
            x = 100 + (m - 1) * 40
            y = 400 - (temp!(c, m) + 10) * 7.556
            IF m > 1 THEN LINE (px, py)-(x, y), ccol(c)
            px = x: py = y
        NEXT
        LOCATE 4 + c, 72: COLOR ccol(c): PRINT LEFT$(city$(c), INSTR(city$(c) + " (", " (") - 1);
    NEXT
    FOR m = 1 TO 12: LOCATE 26, (100 + (m - 1) * 40) \ 8 + 1: COLOR 7: PRINT mon$(m); : NEXT
    LOCATE 28, 3: PRINT "Sydney is upside-down: southern hemisphere summer is in January!"
    LOCATE 30, 3: PRINT "Press a key...";
    GOSUB WaitKey
RETURN

WaitKey:
    DO: LOOP WHILE INKEY$ = ""
    GOSUB Menu
RETURN
