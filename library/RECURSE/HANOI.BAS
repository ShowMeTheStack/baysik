' ============================================================
' TITLE:    Towers of Hanoi with Move Counter
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, towers of hanoi, puzzles, graphics, move counter
' SUMMARY:  Animated Towers of Hanoi solved by a five-line recursive SUB, with a move counter that proves the 2^n - 1 rule.
' ------------------------------------------------------------
' WHAT IT DOES
'   Move a stack of disks from peg A to peg C, one disk at a time,
'   never putting a big disk on a small one.  The recursive idea:
'     To move n disks from FROM to TO (using SPARE):
'       1. move n-1 disks from FROM to SPARE   (recursive)
'       2. move the biggest disk from FROM to TO
'       3. move n-1 disks from SPARE to TO     (recursive)
'   The pegs are drawn with text blocks and every move is animated.
'
' HOW TO USE
'   Enter the number of disks (1 to 8).  Press Esc during the
'   animation to skip to the end.  0 quits.
'
'   DEBUGGER TOUR
'   1. Use 3 disks.  Break on <<< BREAK in Hanoi.
'   2. At each stop look at n, src, dst, spare in the Variables
'      panel.  Notice the pegs ROTATE roles from frame to frame.
'   3. Open the CALL STACK at the first real move: Hanoi(3) ->
'      Hanoi(2) -> Hanoi(1).  The stack is never deeper than n.
'   4. WATCH moves.  Predict the final value before you start:
'      2^n - 1  (7 for 3 disks, 255 for 8).
'   5. Try STEP OVER on a recursive Hanoi call: the whole sub-tower
'      moves in one step.  That is exactly the "trust the
'      recursion" mindset.
'
' CONCEPTS YOU WILL LEARN
'   * Solving a big problem by assuming smaller ones are solved
'   * Exponential move count: 2^n - 1
'   * Simple stacks with arrays (each peg is a stack of disks)
'
' THINGS TO TRY
'   * At 1 move per second, how long would 64 disks take?
'   * Write the moves to a file instead of animating them.
' ============================================================
DECLARE SUB Hanoi (n AS INTEGER, src AS INTEGER, dst AS INTEGER, spare AS INTEGER)
DECLARE SUB MoveDisk (src AS INTEGER, dst AS INTEGER)
DECLARE SUB DrawPegs ()
DECLARE SUB Pause (secs!)

CONST MAXD = 8
DIM SHARED peg(1 TO 3, 1 TO MAXD) AS INTEGER   ' disk sizes, bottom first
DIM SHARED height(1 TO 3) AS INTEGER           ' disks on each peg
DIM SHARED moves AS LONG
DIM SHARED ndisks AS INTEGER
DIM SHARED fast AS INTEGER                     ' -1 after Esc pressed

DO
    CLS
    PRINT "TOWERS OF HANOI"
    INPUT "How many disks (1-8, 0 quits)"; ndisks
    IF ndisks <= 0 THEN EXIT DO
    IF ndisks > MAXD THEN ndisks = MAXD

    ' Put all disks on peg 1, biggest at the bottom.
    FOR i% = 1 TO 3: height(i%) = 0: NEXT i%
    FOR i% = 1 TO ndisks
        peg(1, i%) = ndisks - i% + 1
    NEXT i%
    height(1) = ndisks
    moves = 0: fast = 0

    CLS
    DrawPegs
    Hanoi ndisks, 1, 3, 2
    DrawPegs
    LOCATE 22, 1
    PRINT "Solved in"; moves; "moves.  2^n - 1 ="; 2 ^ ndisks - 1
    PRINT "Press a key..."
    k$ = INPUT$(1)
LOOP
END

SUB Hanoi (n AS INTEGER, src AS INTEGER, dst AS INTEGER, spare AS INTEGER)
    IF n = 0 THEN EXIT SUB              ' <<< BREAK  (nothing to move)
    Hanoi n - 1, src, spare, dst        ' 1. clear the way
    MoveDisk src, dst                   ' 2. move the biggest
    Hanoi n - 1, spare, dst, src        ' 3. pile the rest back on
END SUB

SUB MoveDisk (src AS INTEGER, dst AS INTEGER)
    ' Pop from src, push onto dst.
    d% = peg(src, height(src))
    height(src) = height(src) - 1
    height(dst) = height(dst) + 1
    peg(dst, height(dst)) = d%
    moves = moves + 1
    IF NOT fast THEN
        DrawPegs
        LOCATE 20, 1
        PRINT "Move"; moves; ": disk"; d%; "from "; CHR$(64 + src); " to "; CHR$(64 + dst); "     "
        Pause .15
    END IF
END SUB

SUB DrawPegs
    ' Each peg is 25 columns wide.  Disk of size s is 2*s+1 blocks.
    DIM p AS INTEGER, lvl AS INTEGER, s AS INTEGER, row AS INTEGER
    FOR p = 1 TO 3
        FOR lvl = 1 TO MAXD
            row = 17 - lvl
            LOCATE row, (p - 1) * 26 + 1
            IF lvl <= height(p) THEN
                s = peg(p, lvl)
                PRINT SPACE$(12 - s); STRING$(2 * s + 1, 219); SPACE$(12 - s);
            ELSE
                PRINT SPACE$(12); "|"; SPACE$(12);
            END IF
        NEXT lvl
        LOCATE 18, (p - 1) * 26 + 1
        PRINT STRING$(25, 223);
        LOCATE 19, (p - 1) * 26 + 13
        PRINT CHR$(64 + p);
    NEXT p
END SUB

' Wait a little, but let Esc switch to "fast" mode (no animation).
SUB Pause (secs!)
    t! = TIMER
    DO
        IF INKEY$ = CHR$(27) THEN fast = -1: EXIT SUB
    LOOP WHILE TIMER - t! < secs! AND TIMER >= t!
END SUB
