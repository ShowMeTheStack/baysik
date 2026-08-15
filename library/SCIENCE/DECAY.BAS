' ============================================================
' TITLE:    Radioactive Decay and Half-Life
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     physics, radioactivity, probability, half-life, graph
' SUMMARY:  900 unstable atoms decay at random, yet together they follow a perfect half-life curve.
' ------------------------------------------------------------
' WHAT IT DOES
'   A radioactive atom might decay this second, or in a thousand
'   years - nobody can say WHEN.  All we know is the chance per
'   second.  But with lots of atoms, the randomness averages out:
'   after one HALF-LIFE about half are left, after two about a
'   quarter, then an eighth...
'   Left: a 30 x 30 block of atoms.  Yellow = not yet decayed,
'   dark = decayed.  Right: a graph of how many remain (green dots)
'   against the theory N = N0 * (1/2)^(t / halfLife) (red line).
'   Every tick the Geiger counter clicks once per decay.
'
' HOW TO USE
'   Enter a half-life in ticks (try 20).  Watch the atoms vanish.
'   Press a key afterwards to try again, or ESC to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Random events with a fixed probability: IF RND < p
'   * Half-life and exponential decay
'   * Why big samples match theory better than small ones
'   * Comparing a simulation with a formula on one graph
'
' THINGS TO TRY
'   * Carbon-14 has a half-life of 5730 years.  If each tick is 573
'     years, what half-life should you enter?
'   * Use only 25 atoms (change SIDE to 5).  How well does it fit now?
'   * Model a decay CHAIN: A decays to B, which decays to C.
' ============================================================

DEFINT A-Z
CONST SIDE = 30                 ' 30 x 30 = 900 atoms
CONST TMAX = 150                ' ticks to simulate

DIM alive(SIDE, SIDE)

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "RADIOACTIVE DECAY": COLOR 7
    INPUT "Half-life in ticks (2-100, e.g. 20)"; hl!
    IF hl! < 2 THEN hl! = 20
    IF hl! > 100 THEN hl! = 100
    ' The chance of decaying in ONE tick, p, must give a 50% chance of
    ' surviving hl! ticks:  (1 - p) ^ hl! = 0.5   so   p = 1 - 0.5^(1/hl!)
    p! = 1 - .5 ^ (1 / hl!)

    SCREEN 12: CLS
    n0 = SIDE * SIDE: n = n0
    FOR y = 1 TO SIDE: FOR x = 1 TO SIDE
        alive(x, y) = 1
        LINE (x * 9, 40 + y * 9)-(x * 9 + 6, 46 + y * 9), 14, BF
    NEXT: NEXT
    ' graph frame: time 0..TMAX across 320..620, atoms 0..n0 up 420..60
    LINE (320, 60)-(320, 420), 8: LINE (320, 420)-(620, 420), 8
    ' theory curve and half-life markers
    FOR t = 0 TO TMAX
        th! = n0 * .5 ^ (t / hl!)
        PSET (320 + t * 2, 420 - th! * 360 / n0), 12
    NEXT
    FOR h = 1 TO 6
        tx = 320 + hl! * h * 2
        IF tx < 620 THEN LINE (tx, 415)-(tx, 425), 7
    NEXT
    LOCATE 2, 2: COLOR 15: PRINT USING "Half-life ### ticks, chance per tick #.####"; hl!; p!
    LOCATE 28, 41: COLOR 7: PRINT "ticks (marks = each half-life)"
    LOCATE 3, 42: COLOR 10: PRINT "o atoms left  ";: COLOR 12: PRINT "-- theory"

    FOR t = 1 TO TMAX
        decays = 0
        FOR y = 1 TO SIDE: FOR x = 1 TO SIDE
            IF alive(x, y) THEN
                IF RND < p! THEN        ' this atom decays now
                    alive(x, y) = 0
                    decays = decays + 1
                    LINE (x * 9, 40 + y * 9)-(x * 9 + 6, 46 + y * 9), 8, BF
                END IF
            END IF
        NEXT: NEXT
        n = n - decays
        CIRCLE (320 + t * 2, 420 - n * 360! / n0), 1, 10
        ' Geiger counter: a short click for each decay (up to a few)
        FOR c = 1 TO decays
            IF c > 4 THEN EXIT FOR
            SOUND 800 + RND * 400, .1
        NEXT
        LOCATE 23, 2: COLOR 15
        PRINT USING "Tick ###   atoms left ###   decayed this tick ##"; t; n; decays
        LOCATE 24, 2
        PRINT USING "Theory says ###.#"; n0 * .5 ^ (t / hl!)
        IF n = 0 THEN EXIT FOR
        IF INKEY$ = CHR$(27) THEN EXIT FOR
        WAIT &H3DA, 8
    NEXT
    LOCATE 30, 2: PRINT "Key = again, ESC = quit";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END
