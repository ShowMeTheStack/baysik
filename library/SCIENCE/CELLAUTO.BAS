' ============================================================
' TITLE:    Elementary Cellular Automata (Rule 30, 110...)
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     cellular automata, binary, rules, complexity, graphics
' SUMMARY:  A row of cells and an 8-entry rulebook grow amazing patterns - chaos from Rule 30, computers from Rule 110.
' ------------------------------------------------------------
' WHAT IT DOES
'   Imagine a row of cells, each ON or OFF.  To make the next row,
'   each cell looks at itself and its two neighbours: 3 cells, so
'   there are 2*2*2 = 8 possible patterns.  A "rule" says whether
'   each pattern gives ON or OFF.  8 yes/no answers = 8 bits, so
'   every rule is a number from 0 to 255.  Stephen Wolfram studied
'   all 256.  Some make boring stripes, some make the Sierpinski
'   triangle (Rule 90), Rule 30 makes randomness (used as a random
'   number generator!) and Rule 110 can compute anything a computer can.
'
' HOW TO USE
'   Type a rule number 0-255 (Enter = 30).  Then choose whether to
'   start from a single cell or a random row.  Each new row is drawn
'   below the last.  Press a key when done; type -1 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Binary numbers: reading bits of a number with AND
'   * Neighbourhoods and update rules
'   * Double buffering an array (old row -> new row)
'   * Emergence: simple local rules, complex global patterns
'
' THINGS TO TRY
'   * Rules 30, 90, 110, 184, 150, 54, 73
'   * Look at the rule bit table printed on screen and predict the
'     first few rows by hand.
'   * Wrap the edges (the left neighbour of cell 0 is the last cell).
' ============================================================

DEFINT A-Z
CONST W = 320                   ' cells across (2 pixels each = 640)
CONST H = 222                   ' rows to draw (2 pixels each)

DIM cur(W + 1), nxt(W + 1)      ' cells 0 and W+1 are always-off edges
DIM bit(7)                      ' the rulebook: bit(pattern) = 0 or 1

RANDOMIZE TIMER
DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "ELEMENTARY CELLULAR AUTOMATA": COLOR 7
    PRINT "Famous rules: 30 (chaos), 90 (Sierpinski), 110 (complex), 184 (traffic)"
    INPUT "Rule number 0-255 (Enter = 30, -1 = quit)"; ruleIn$
    IF VAL(ruleIn$) < 0 THEN EXIT DO
    rule = VAL(ruleIn$)
    IF ruleIn$ = "" THEN rule = 30
    IF rule > 255 THEN rule = 255
    INPUT "Start with (S)ingle cell or (R)andom row"; st$

    ' ---- unpack the rule into 8 bits -----------------------------
    ' Pattern number = left*4 + centre*2 + right.  Bit p of the rule
    ' number tells what the new cell is for pattern p.
    FOR p = 0 TO 7
        IF rule AND (2 ^ p) THEN bit(p) = 1 ELSE bit(p) = 0
    NEXT

    ' ---- first row --------------------------------------------------
    FOR i = 0 TO W + 1: cur(i) = 0: NEXT
    IF UCASE$(LEFT$(st$, 1)) = "R" THEN
        FOR i = 1 TO W: cur(i) = INT(RND * 2): NEXT
    ELSE
        cur(W \ 2) = 1
    END IF

    SCREEN 12: CLS
    ' show the rulebook at the top: 8 little pictures
    LOCATE 1, 1: COLOR 15: PRINT "Rule"; rule; ":";
    FOR p = 7 TO 0 STEP -1
        bx = 120 + (7 - p) * 64
        FOR b = 2 TO 0 STEP -1        ' draw the 3-cell pattern
            c = 8: IF p AND (2 ^ b) THEN c = 15
            LINE (bx + (2 - b) * 8, 2)-(bx + (2 - b) * 8 + 6, 8), c, BF
        NEXT
        c = 8: IF bit(p) THEN c = 14  ' and the result below it
        LINE (bx + 8, 11)-(bx + 14, 17), c, BF
    NEXT

    ' ---- grow the pattern row by row --------------------------------
    FOR row = 0 TO H - 1
        y = 34 + row * 2
        FOR i = 1 TO W
            IF cur(i) THEN LINE ((i - 1) * 2, y)-((i - 1) * 2 + 1, y + 1), 14, BF
        NEXT
        ' compute the next row from the current one
        FOR i = 1 TO W
            p = cur(i - 1) * 4 + cur(i) * 2 + cur(i + 1)
            nxt(i) = bit(p)
        NEXT
        ' copy next -> current (the "double buffer" swap)
        FOR i = 1 TO W: cur(i) = nxt(i): NEXT
        IF INKEY$ = CHR$(27) THEN EXIT FOR
    NEXT
    LOCATE 2, 1: COLOR 7: PRINT "Press a key";
    DO: LOOP WHILE INKEY$ = ""
LOOP
SCREEN 0: WIDTH 80
END
