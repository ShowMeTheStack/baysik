' ============================================================
' TITLE:    Tower of Hanoi - No Recursion!
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     hanoi, iteration, binary, bitwise, animation, graphics
' SUMMARY:  Solves the Tower of Hanoi with a plain loop and a magic binary trick - no recursion needed.
' ------------------------------------------------------------
' WHAT IT DOES
'   Move a stack of disks from the left peg to the right peg.  Only
'   one disk moves at a time and a bigger disk may never sit on a
'   smaller one.  The famous solution is recursive, but there is a
'   beautiful ITERATIVE one hidden in binary counting:
'
'     For move number m = 1, 2, 3 ... 2^n - 1:
'       * the disk to move is (number of trailing zero bits of m) + 1
'       * it goes FROM peg  (m AND (m - 1)) MOD 3
'       *          TO   peg ((m OR (m - 1)) + 1) MOD 3
'
'   With an even number of disks this ends on the middle peg, so we
'   simply swap the names of pegs 1 and 2 in that case.
'
' HOW TO USE
'   Type how many disks (1-8).  Watch the animation.
'   + / - change speed, Esc stops.  At the end press a key to go
'   again, or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Bitwise AND / OR on integers
'   * Counting trailing zeros with a loop
'   * Why the puzzle needs exactly 2^n - 1 moves
'   * Stacks stored in arrays, and SCREEN 13 animation
'
' THINGS TO TRY
'   * Print the binary value of m next to each move and spot the
'     pattern: the smallest disk moves on every odd move.
'   * Use the other famous rule: "move the smallest disk one peg
'     clockwise, then make the only other legal move" and compare.
' ============================================================
DECLARE SUB DrawPegs ()
DECLARE SUB DrawDisk (p AS INTEGER, level AS INTEGER, size AS INTEGER, col AS INTEGER)
DEFINT A-Z

CONST BASEY = 170          ' y coordinate of the floor
CONST DISKH = 10           ' height of one disk in pixels
DIM SHARED peg(2, 1 TO 8)  ' peg(p, level) = size of disk at that level
DIM SHARED cnt(2)          ' how many disks on each peg
DIM SHARED px(2)           ' x centre of each peg
px(0) = 60: px(1) = 160: px(2) = 260
delay! = .15

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "TOWER OF HANOI (iterative version)": COLOR 7
    PRINT
    DO
        LINE INPUT "How many disks (1-8, Q quits)? "; a$
        IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN END
        n = VAL(a$)
    LOOP UNTIL n >= 1 AND n <= 8

    ' Set up: all disks on peg 0, biggest (size n) at the bottom.
    cnt(0) = n: cnt(1) = 0: cnt(2) = 0
    FOR i = 1 TO n: peg(0, i) = n + 1 - i: NEXT

    SCREEN 13
    DrawPegs
    FOR i = 1 TO n: DrawDisk 0, i, peg(0, i), 31 + peg(0, i) * 4: NEXT

    total& = 2 ^ n - 1        ' the minimum number of moves
    stopped = 0
    FOR m& = 1 TO total&
        ' --- 1. Which disk?  Count trailing zero bits of m. ---------
        disk = 1: t& = m&
        DO WHILE (t& AND 1) = 0
            disk = disk + 1: t& = t& \ 2
        LOOP
        ' --- 2. From which peg to which peg? --------------------------
        fromP = (m& AND (m& - 1)) MOD 3
        toP = ((m& OR (m& - 1)) + 1) MOD 3
        ' Even number of disks: swap pegs 1 and 2 so we end on peg 2.
        IF n MOD 2 = 0 THEN
            IF fromP > 0 THEN fromP = 3 - fromP
            IF toP > 0 THEN toP = 3 - toP
        END IF

        ' --- 3. Do the move on our arrays and on screen -------------
        size = peg(fromP, cnt(fromP))
        ' (size always equals "disk" - the binary trick guarantees it.)
        DrawDisk fromP, cnt(fromP), size, 0  ' erase
        cnt(fromP) = cnt(fromP) - 1
        cnt(toP) = cnt(toP) + 1
        peg(toP, cnt(toP)) = size
        DrawDisk toP, cnt(toP), size, 31 + size * 4

        LOCATE 1, 1
        PRINT "Move"; m&; "of"; total&; ": disk"; disk; CHR$(65 + fromP); "->"; CHR$(65 + toP); "  "

        ' --- 4. Wait a little, handling speed keys ------------------
        t! = TIMER
        DO
            k$ = INKEY$
            IF k$ = "+" AND delay! > .01 THEN delay! = delay! / 2
            IF k$ = "-" AND delay! < 2 THEN delay! = delay! * 2
            IF k$ = CHR$(27) THEN stopped = -1
        LOOP UNTIL TIMER - t! >= delay! OR TIMER < t! OR stopped
        IF stopped THEN EXIT FOR
    NEXT
    LOCATE 24, 1
    IF stopped THEN PRINT "Stopped."; ELSE PRINT "Done in"; total&; "moves!";
    LOCATE 25, 1: PRINT "Any key = again, Q = quit";
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF UCASE$(k$) = "Q" OR k$ = CHR$(27) THEN EXIT DO
LOOP
SCREEN 0: WIDTH 80: CLS
END

SUB DrawDisk (p AS INTEGER, level AS INTEGER, size AS INTEGER, col AS INTEGER)
    ' A disk of "size" s is 10 + 10*s pixels wide, centred on its peg.
    ' Colour 0 erases it.
    w = 5 + 5 * size
    y = BASEY - level * DISKH
    LINE (px(p) - w, y)-(px(p) + w, y + DISKH - 2), col, BF
    ' When erasing, repaint the little piece of peg that was hidden.
    IF col = 0 THEN LINE (px(p) - 1, y)-(px(p) + 1, y + DISKH - 1), 6, BF
END SUB

SUB DrawPegs
    CLS
    LINE (0, BASEY)-(319, BASEY + 4), 6, BF         ' floor
    FOR p = 0 TO 2
        LINE (px(p) - 1, BASEY - 9 * DISKH)-(px(p) + 1, BASEY - 1), 6, BF
        LOCATE 23, px(p) \ 8 + 1: PRINT CHR$(65 + p);
    NEXT
END SUB
