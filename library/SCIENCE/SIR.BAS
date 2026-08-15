' ============================================================
' TITLE:    Epidemic Simulator (SIR Model)
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     biology, epidemiology, differential equations, graph, vaccination
' SUMMARY:  Model how a disease spreads through a town and see how vaccination flattens the curve.
' ------------------------------------------------------------
' WHAT IT DOES
'   Epidemiologists split a population into three groups:
'     S - Susceptible  (can still catch it)
'     I - Infected     (sick and contagious)
'     R - Recovered    (immune, or vaccinated)
'   Each day:
'     new infections = beta * S * I / N    (sick people meet healthy ones)
'     new recoveries = gamma * I           (sick people get better)
'   The famous number R0 = beta / gamma is how many people one sick
'   person infects in a fully susceptible town.  If R0 > 1 an
'   outbreak grows; if it is < 1 it fizzles out.
'
' HOW TO USE
'   Enter R0 (try 2.5), the days a person stays sick (try 7), and
'   the percentage already vaccinated (try 0, then 40, then 65).
'   Watch the three curves.  Press a key to run again, ESC to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Compartment models and rates of change
'   * Herd immunity threshold: 1 - 1/R0
'   * Why "flattening the curve" lowers the peak
'   * Plotting several series on one graph
'
' THINGS TO TRY
'   * R0 = 2.5: herd immunity needs 1 - 1/2.5 = 60% immune.  Try
'     55% and 65% vaccinated and compare.
'   * Measles has R0 around 15 - what vaccination level is needed?
'   * Add a D (deaths) group: a small fraction of I each day.
' ============================================================

DEFDBL A-Z
CONST N = 10000                 ' town population
CONST DAYS = 200

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "EPIDEMIC SIMULATOR (SIR MODEL)": COLOR 7
    PRINT "Population"; N; "with 5 people sick on day 0."
    PRINT
    INPUT "R0, people infected by each sick person (e.g. 2.5)"; r0
    IF r0 <= 0 OR r0 > 20 THEN r0 = 2.5
    INPUT "Days a person stays contagious (e.g. 7)"; sickDays
    IF sickDays < 1 OR sickDays > 60 THEN sickDays = 7
    INPUT "Percent vaccinated before the outbreak (0-99)"; vac
    IF vac < 0 OR vac > 99 THEN vac = 0

    gamma = 1 / sickDays        ' fraction recovering per day
    beta = r0 * gamma           ' contacts that infect per day
    I = 5
    R = N * vac / 100           ' vaccinated people start out immune
    S = N - I - R
    peak = I: peakDay = 0
    dt = .1                     ' 10 steps per day for accuracy

    SCREEN 12: CLS
    ' graph area: x 60..620 = days 0..200, y 420..40 = 0..N people
    LINE (60, 40)-(60, 420), 8: LINE (60, 420)-(620, 420), 8
    FOR p = 0 TO 100 STEP 25
        yy = 420 - p * 3.8
        LINE (56, yy)-(620, yy), 8, , &H8888       ' dotted grid line
        LOCATE INT(yy / 16) + 1, 2: PRINT USING "###%"; p;
    NEXT
    FOR d = 0 TO DAYS STEP 50
        LOCATE 28, INT((60 + d * 2.8) / 8): PRINT LTRIM$(STR$(d));
    NEXT
    LOCATE 29, 35: PRINT "days";
    ' herd-immunity level as a horizontal line
    herd = 1 - 1 / r0
    IF herd > 0 THEN
        yy = 420 - herd * 380
        LINE (60, yy)-(620, yy), 5, , &HF0F0
    END IF
    LOCATE 1, 9: COLOR 9: PRINT "Susceptible  ";
    COLOR 12: PRINT "Infected  ";
    COLOR 10: PRINT "Recovered/immune  ";
    COLOR 5: PRINT "herd-immunity line";

    ox = 60: lastS = 420 - S / N * 380: lastI = 420 - I / N * 380: lastR = 420 - R / N * 380
    FOR day = 1 TO DAYS
        FOR st = 1 TO 10
            newInf = beta * S * I / N * dt
            newRec = gamma * I * dt
            S = S - newInf
            I = I + newInf - newRec
            R = R + newRec
        NEXT
        IF I > peak THEN peak = I: peakDay = day
        nx = 60 + day * 2.8
        nS = 420 - S / N * 380: nI = 420 - I / N * 380: nR = 420 - R / N * 380
        LINE (ox, lastS)-(nx, nS), 9
        LINE (ox, lastI)-(nx, nI), 12
        LINE (ox, lastR)-(nx, nR), 10
        ox = nx: lastS = nS: lastI = nI: lastR = nR
        WAIT &H3DA, 8
        IF INKEY$ = CHR$(27) THEN EXIT FOR
    NEXT
    COLOR 15
    LOCATE 3, 40: PRINT USING "Peak: ##### sick on day ###"; peak; peakDay
    ' total ever infected = everyone recovered minus the vaccinated
    LOCATE 4, 40: PRINT USING "Caught it in total: #####"; R + I - N * vac / 100
    LOCATE 5, 40: PRINT USING "Herd immunity needs ###% immune"; herd * 100
    LOCATE 30, 40: PRINT "Key = again, ESC = quit";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END
