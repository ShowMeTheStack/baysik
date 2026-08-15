' ============================================================
' TITLE:    Population Growth: Exponential vs Logistic
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     biology, growth, exponential, logistic, graph
' SUMMARY:  Watch bacteria multiply without limits, then see how limited food bends the curve into an S.
' ------------------------------------------------------------
' WHAT IT DOES
'   Start with a few bacteria in a dish.  Each hour the population
'   grows by a fixed percentage.
'     EXPONENTIAL growth: new = old * (1 + rate)
'       - doubling again and again, it rockets upward forever.
'     LOGISTIC growth: new = old + rate * old * (1 - old / K)
'       - K is the "carrying capacity", the most the dish can feed.
'         Growth slows as the population nears K, giving an S-curve.
'   The program prints a table and draws both curves.
'
' HOW TO USE
'   Enter the growth rate per hour in percent (try 30), and the
'   carrying capacity (try 1000).  Press a key after the table to
'   see the graph.  Enter 0 as the rate to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Repeated multiplication = exponential growth
'   * The "rule of 70": doubling time is about 70 / rate%
'   * Carrying capacity and the logistic equation
'   * FOR loops, tables with PRINT USING, simple line graphs
'
' THINGS TO TRY
'   * Rate 200%: the logistic curve starts to wobble and even
'     bounce chaotically around K!  (This is the famous "logistic map".)
'   * Compare the doubling time the program measures with 70 / rate.
'   * Start with more bacteria (change START).
' ============================================================

CONST START = 10                ' bacteria at hour 0
CONST HOURS = 30

DIM ex(HOURS), lg(HOURS)        ' populations each hour

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "POPULATION GROWTH": COLOR 7
    INPUT "Growth rate per hour in % (0 = quit)"; rate
    IF rate <= 0 THEN EXIT DO
    IF rate > 300 THEN rate = 300
    INPUT "Carrying capacity K (e.g. 1000)"; K
    IF K < START * 2 THEN K = 1000
    r = rate / 100

    ' ---- compute both models hour by hour ------------------------
    ex(0) = START: lg(0) = START
    doubled = 0
    FOR h = 1 TO HOURS
        ex(h) = ex(h - 1) * (1 + r)
        lg(h) = lg(h - 1) + r * lg(h - 1) * (1 - lg(h - 1) / K)
        IF lg(h) < 0 THEN lg(h) = 0   ' can't have negative bacteria
        ' first hour when the exponential population passes 2 * START
        IF doubled = 0 AND ex(h) >= 2 * START THEN doubled = h
    NEXT

    PRINT
    PRINT " Hour   Exponential      Logistic"
    PRINT " ----   -----------      --------"
    FOR h = 0 TO HOURS STEP 2
        PRINT USING " ###   ##########     ######"; h; ex(h); lg(h)
    NEXT
    PRINT
    PRINT USING "Rule of 70 says doubling every ##.# hours;"; 70 / rate;
    PRINT USING " it first doubled by hour ##."; doubled
    PRINT "Press a key for the graph...";
    DO: LOOP WHILE INKEY$ = ""

    ' ---- graph ------------------------------------------------------
    SCREEN 12: CLS
    top = K * 2                 ' vertical scale: 0 .. 2K people
    WINDOW (-2, -top * .08)-(HOURS + 1, top * 1.05)
    LINE (0, 0)-(HOURS, 0), 8
    LINE (0, 0)-(0, top), 8
    LINE (0, K)-(HOURS, K), 5, , &HCCCC      ' dashed carrying-capacity line
    FOR h = 1 TO HOURS
        ' exponential, clipped to the top of the graph
        y1 = ex(h - 1): y2 = ex(h)
        IF y1 > top THEN y1 = top
        IF y2 > top THEN y2 = top
        IF ex(h - 1) < top THEN LINE (h - 1, y1)-(h, y2), 12   ' stop once it leaves the chart
        LINE (h - 1, lg(h - 1))-(h, lg(h)), 10
        CIRCLE (h, lg(h)), .15, 10
    NEXT
    COLOR 12: LOCATE 1, 3: PRINT "Exponential (off the chart soon!)"
    COLOR 10: LOCATE 2, 3: PRINT "Logistic (levels off at K)"
    COLOR 5: LOCATE 3, 3: PRINT "Dashed line = carrying capacity K"
    COLOR 7: LOCATE 30, 30: PRINT "hours -> (0 to"; HOURS; ")";
    DO: LOOP WHILE INKEY$ = ""
LOOP
SCREEN 0: WIDTH 80: CLS
END
