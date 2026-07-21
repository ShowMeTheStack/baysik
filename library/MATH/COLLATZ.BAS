' ============================================================
' TITLE:    Collatz Hailstones
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     collatz, sequences, unsolved problems, graphics, records
' SUMMARY:  Plots the wild up-and-down "hailstone" journeys of the 3n+1 problem and hunts for record holders.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick any whole number n and follow two rules:
'      if n is even, halve it:            n = n / 2
'      if n is odd, triple it and add 1:  n = 3n + 1
'   Keep going.  It seems you ALWAYS reach 1 eventually - but nobody
'   has ever proved it!  This is the Collatz conjecture (1937), one of
'   the most famous unsolved problems in mathematics.  The values
'   bounce up and down like hailstones in a cloud before falling.
'   The program graphs a sequence, then finds which starting number
'   below 10000 takes the most steps.
'
' HOW TO USE
'   Type a starting number to see its graph (try 27!).  0 quits the
'   graph section and runs the record search.  Press a key at the end.
'
' CONCEPTS YOU WILL LEARN
'   * Following a rule repeatedly (iteration) with DO WHILE
'   * Scaling data to fit the screen (finding the maximum first)
'   * Logarithmic scale: LOG makes huge peaks fit
'   * "Memo" tables: reusing answers we already worked out
'
' THINGS TO TRY
'   * Change 3n+1 to 3n-1: now some numbers get stuck in loops!
'   * Plot step counts for every n from 1 to 600 as dots
'   * Find the number below 10000 whose sequence climbs the highest
' ============================================================

DEFLNG A-Z
CONST MAXSTEP = 1000
DIM seq(MAXSTEP) AS DOUBLE

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "COLLATZ HAILSTONES": COLOR 7
    PRINT "Even: n/2     Odd: 3n+1     Stop at 1."
    INPUT "Starting number (try 27, 0 = go to record search)"; start&
    IF start& <= 0 THEN EXIT DO
    IF start& > 100000000 THEN start& = 100000000

    ' Build the sequence and remember the highest point.
    n# = start&: steps = 0: hi# = n#
    seq(0) = n#
    DO WHILE n# <> 1 AND steps < MAXSTEP
        ' n# - 2 * INT(n# / 2) is n MOD 2, but works beyond LONG range.
        IF n# - 2 * INT(n# / 2) = 0 THEN n# = n# / 2 ELSE n# = 3 * n# + 1
        steps = steps + 1
        seq(steps) = n#
        IF n# > hi# THEN hi# = n#
    LOOP

    ' ---- Graph it ----
    SCREEN 12: CLS
    ' Leave room at the top for text: graph area x 40..630, y 60..460
    LINE (40, 60)-(40, 460), 8: LINE (40, 460)-(630, 460), 8
    FOR i = 0 TO steps
        x = 40 + i * 590 / (steps + 1)
        ' Linear scale: value / highest * 400 pixels tall
        y = 460 - seq(i) / hi# * 400
        ' Log scale for comparison: LOG(value) / LOG(highest)
        y2 = 460 - LOG(seq(i)) / LOG(hi# + 1) * 400
        IF i = 0 THEN
            PSET (x, y), 14: px = x: py = y: py2 = y2
        ELSE
            LINE (px, py2)-(x, y2), 3       ' log scale in dark cyan
            LINE (px, py)-(x, y), 14        ' normal scale in yellow
            px = x: py = y: py2 = y2
        END IF
    NEXT i
    COLOR 15
    LOCATE 1, 1: PRINT "Start"; start&; "  steps to reach 1:"; steps; "  highest value:"; hi#
    COLOR 14: LOCATE 2, 1: PRINT "Yellow = actual values";
    COLOR 3: PRINT "    Cyan = log scale (shows the small wiggles)";
    COLOR 7: LOCATE 30, 1: PRINT "Press a key...";
    k$ = INPUT$(1)
LOOP

' ------------------------------------------------------------
' Record search.  memo(n) stores the step count for n once known.
' When a sequence drops below its start, we can look up the rest
' instead of computing it again - a big speed-up.
' ------------------------------------------------------------
SCREEN 0: WIDTH 80: CLS
CONST LIMIT = 10000
DIM memo(LIMIT) AS INTEGER
COLOR 14: PRINT "Who takes the longest to reach 1?  (starting numbers up to"; LIMIT; ")": COLOR 7
PRINT
PRINT "Record breakers, shown as  start:steps"
best = 0
FOR s = 2 TO LIMIT
    n# = s: c = 0
    DO
        IF n# - 2 * INT(n# / 2) = 0 THEN n# = n# / 2 ELSE n# = 3 * n# + 1
        c = c + 1
        IF n# < s THEN c = c + memo(n#): EXIT DO   ' already known!
    LOOP
    memo(s) = c
    IF c > best THEN
        best = c
        PRINT USING "  #####:###"; s; c;
        shown = shown + 1
        IF shown MOD 6 = 0 THEN PRINT     ' 6 records per line
    END IF
NEXT s
PRINT : PRINT
PRINT "Notice how few numbers break the record - and how big the jumps are."
PRINT "Press a key to exit."
k$ = INPUT$(1)
