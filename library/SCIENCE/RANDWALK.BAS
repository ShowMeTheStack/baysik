' ============================================================
' TITLE:    Random Walk and Diffusion
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     probability, diffusion, statistics, random, graphics
' SUMMARY:  Hundreds of drunken walkers stagger from the centre - their cloud spreads like ink in water.
' ------------------------------------------------------------
' WHAT IT DOES
'   Each dot takes one step per tick in a random direction (up,
'   down, left or right).  No single dot goes anywhere in
'   particular, yet the CROWD spreads out steadily.  This is how
'   diffusion works: perfume across a room, ink in water, sugar in
'   tea - all are countless molecules on random walks.
'   The right panel shows a histogram of the walkers' x positions:
'   it grows into the famous bell curve (normal distribution).
'   The program also measures the RMS (root-mean-square) distance
'   from the start and compares it with the theory: SQR(steps).
'
' HOW TO USE
'   Just watch.  R restarts, ESC quits.
'
' CONCEPTS YOU WILL LEARN
'   * Random walks and why spreading grows like the square root of time
'   * Histograms and the bell curve (central limit theorem)
'   * Root-mean-square averages
'   * Animating many objects stored in arrays
'
' THINGS TO TRY
'   * Make walkers prefer one direction slightly ("drift") - like
'     a breeze.  The cloud moves AND spreads.
'   * Put a wall in the middle with a small hole.
'   * After 400 steps the RMS should be about 20.  Check it!
' ============================================================

DEFINT A-Z
CONST NW = 400                  ' number of walkers
CONST CX = 200, CY = 240        ' starting point on screen
CONST SCL = 2                   ' pixels per step (makes the spread visible)

DIM wx(NW), wy(NW)              ' walker positions in steps from the start
DIM hist(-60 TO 60)             ' histogram of x positions (bins of 2 steps)

RANDOMIZE TIMER
SCREEN 12

Restart:
CLS
FOR i = 1 TO NW: wx(i) = 0: wy(i) = 0: NEXT
steps& = 0
LINE (0, 0)-(399, 479), 8, B
LOCATE 1, 2: PRINT "Random walkers (R = restart, ESC = quit)"
LOCATE 1, 53: PRINT "Histogram of x"

DO
    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(27) THEN EXIT DO
    IF k$ = "R" THEN GOTO Restart

    ' ---- every walker takes one random step ----------------------
    sum2! = 0
    FOR i = 1 TO NW
        PSET (CX + wx(i) * SCL, CY + wy(i) * SCL), 0      ' erase old dot
        SELECT CASE INT(RND * 4)       ' 0..3 with equal chances
            CASE 0: wx(i) = wx(i) + 1
            CASE 1: wx(i) = wx(i) - 1
            CASE 2: wy(i) = wy(i) + 1
            CASE 3: wy(i) = wy(i) - 1
        END SELECT
        ' keep walkers inside the box (they bounce off the edge)
        IF CX + wx(i) * SCL < 2 OR CX + wx(i) * SCL > 397 THEN wx(i) = SGN(wx(i)) * (ABS(wx(i)) - 1)
        IF CY + wy(i) * SCL < 2 OR CY + wy(i) * SCL > 477 THEN wy(i) = SGN(wy(i)) * (ABS(wy(i)) - 1)
        PSET (CX + wx(i) * SCL, CY + wy(i) * SCL), 14
        ' distance squared from the start (x^2 + y^2)
        sum2! = sum2! + CSNG(wx(i)) * wx(i) + CSNG(wy(i)) * wy(i)
    NEXT
    steps& = steps& + 1
    PSET (CX, CY), 12                  ' mark the starting point

    ' ---- histogram every 5 steps ---------------------------------
    IF steps& MOD 5 = 0 THEN
        FOR b = -60 TO 60: hist(b) = 0: NEXT
        FOR i = 1 TO NW
            b = INT(wx(i) / 2)          ' INT rounds down, so bins are fair on both sides
            IF b >= -60 AND b <= 60 THEN hist(b) = hist(b) + 1
        NEXT
        LINE (410, 40)-(639, 400), 0, BF
        LINE (410, 400)-(639, 400), 8
        FOR b = -55 TO 55
            ' each bin is 2 pixels wide, 4 pixels tall per walker
            hx = 525 + b * 2
            hy = 400 - hist(b) * 4
            IF hy < 40 THEN hy = 40
            IF hist(b) > 0 THEN LINE (hx, hy)-(hx + 1, 400), 10, BF
        NEXT
        ' ---- statistics --------------------------------------------
        rms! = SQR(sum2! / NW)          ' root-mean-square distance
        COLOR 15
        LOCATE 27, 53: PRINT USING "Steps:   #####"; steps&
        LOCATE 28, 53: PRINT USING "RMS dist: ###.#"; rms!
        LOCATE 29, 53: PRINT USING "SQR(steps): ###.#"; SQR(steps&)
        COLOR 7
    END IF
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END
