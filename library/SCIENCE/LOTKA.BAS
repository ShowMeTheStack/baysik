' ============================================================
' TITLE:    Predator and Prey (Lotka-Volterra)
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     biology, ecology, differential equations, graph, phase plot
' SUMMARY:  Rabbits and foxes rise and crash in endless cycles - graphed over time and as a phase loop.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two populations depend on each other:
'     * Rabbits (prey) breed fast, but get eaten by foxes.
'     * Foxes (predators) starve without rabbits, and breed when fed.
'   In the 1920s Alfred Lotka and Vito Volterra wrote this as two
'   equations:
'        dR/dt =  a*R - b*R*F      (births - being eaten)
'        dF/dt =  d*R*F - c*F      (fed foxes breed - foxes die)
'   The result is a never-ending chase: lots of rabbits -> foxes
'   boom -> rabbits crash -> foxes starve -> rabbits recover...
'   The top graph shows both populations over time.  The bottom-right
'   "phase plot" puts rabbits on one axis and foxes on the other:
'   the cycle becomes a closed loop.
'
' HOW TO USE
'   Enter starting numbers of rabbits and foxes (or just press Enter
'   for 20 and 5).  The simulation runs for 60 "years".  Press a key
'   for a new run; ESC quits.
'
' CONCEPTS YOU WILL LEARN
'   * Coupled differential equations
'   * Runge-Kutta 4 - an accurate way to step equations forward
'   * Equilibrium points (R = c/d, F = a/b) and cycles
'   * Phase-space plots
'
' THINGS TO TRY
'   * Start exactly at the balance point: 40 rabbits, 10 foxes.
'   * Make foxes hungrier (bigger b) - what happens to the loop?
'   * Add a carrying capacity for rabbits: a*R*(1 - R/K).
' ============================================================

DEFDBL A-Z

' Model constants (per year)
a = 1.0         ' rabbit birth rate
b = .1          ' how often a fox meets and eats a rabbit
c = 1.5         ' fox death rate
d = .0375       ' how efficiently eaten rabbits become new foxes
' The balance point where nothing changes: R = c/d = 40, F = a/b = 10

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "PREDATOR AND PREY": COLOR 7
    PRINT "Balance point: 40 rabbits and 10 foxes."
    PRINT
    INPUT "Starting rabbits (Enter = 20)"; r0
    INPUT "Starting foxes   (Enter = 5) "; f0
    IF r0 <= 0 THEN r0 = 20
    IF f0 <= 0 THEN f0 = 5
    IF r0 > 150 THEN r0 = 150
    IF f0 > 50 THEN f0 = 50

    SCREEN 12: CLS
    ' Top graph: time 0-60 across 40..620, population 0..160 up 30..260
    LINE (40, 30)-(40, 260), 8: LINE (40, 260)-(620, 260), 8
    ' Phase plot: rabbits 0..160 across 340..620, foxes 0..50 up 290..470
    LINE (340, 290)-(340, 470), 8: LINE (340, 470)-(620, 470), 8
    COLOR 10: LOCATE 1, 6: PRINT "Rabbits";
    COLOR 12: PRINT "   Foxes x4";
    COLOR 7: PRINT "   (population over 60 years)";
    LOCATE 18, 44: PRINT "Phase plot: foxes vs rabbits"
    LOCATE 30, 60: PRINT "rabbits ->";
    LOCATE 20, 2: PRINT "Each loop in the phase"
    LOCATE 21, 2: PRINT "plot is one boom-and-"
    LOCATE 22, 2: PRINT "bust cycle.  The loop"
    LOCATE 23, 2: PRINT "never quite closes in a"
    LOCATE 24, 2: PRINT "simulation - but it is"
    LOCATE 25, 2: PRINT "very close with RK4."

    R = r0: F = f0: t = 0: h = .01
    oldX = 40: oldR = 260 - R * 1.4375: oldF = 260 - F * 4 * 1.4375
    oldPX = 340 + R * 1.75: oldPY = 470 - F * 3.6
    hiR = R: hiF = F
    DO WHILE t < 60
        ' ---- Runge-Kutta 4th order -------------------------------
        ' Instead of one slope per step (Euler) we sample the slope
        ' four times and take a weighted average.  Much more accurate.
        k1r = a * R - b * R * F: k1f = d * R * F - c * F
        r2 = R + h / 2 * k1r: f2 = F + h / 2 * k1f
        k2r = a * r2 - b * r2 * f2: k2f = d * r2 * f2 - c * f2
        r3 = R + h / 2 * k2r: f3 = F + h / 2 * k2f
        k3r = a * r3 - b * r3 * f3: k3f = d * r3 * f3 - c * f3
        r4 = R + h * k3r: f4 = F + h * k3f
        k4r = a * r4 - b * r4 * f4: k4f = d * r4 * f4 - c * f4
        R = R + h / 6 * (k1r + 2 * k2r + 2 * k3r + k4r)
        F = F + h / 6 * (k1f + 2 * k2f + 2 * k3f + k4f)
        t = t + h
        IF R > hiR THEN hiR = R
        IF F > hiF THEN hiF = F

        ' ---- plot (foxes drawn x4 so both fit on one scale) -------
        nx = 40 + t * 580 / 60
        nR = 260 - R * 1.4375: IF nR < 30 THEN nR = 30
        nF = 260 - F * 4 * 1.4375: IF nF < 30 THEN nF = 30
        LINE (oldX, oldR)-(nx, nR), 10
        LINE (oldX, oldF)-(nx, nF), 12
        oldX = nx: oldR = nR: oldF = nF
        px = 340 + R * 1.75: py = 470 - F * 3.6
        IF px > 630 THEN px = 630
        IF py < 290 THEN py = 290
        LINE (oldPX, oldPY)-(px, py), 14
        oldPX = px: oldPY = py
        n = n + 1
        IF n MOD 5 = 0 THEN WAIT &H3DA, 8      ' animate the drawing
        IF INKEY$ = CHR$(27) THEN EXIT DO
    LOOP
    COLOR 15
    LOCATE 27, 2: PRINT USING "Peak rabbits ###"; hiR
    LOCATE 28, 2: PRINT USING "Peak foxes   ###"; hiF
    LOCATE 30, 2: PRINT "Key = again, ESC = quit";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END
