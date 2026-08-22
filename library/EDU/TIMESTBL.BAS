' ============================================================
' TITLE:    Times Table Ladder
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     multiplication, times tables, arrays, shuffle, text graphics
' SUMMARY:  Climb a colourful ladder by answering a whole times table in shuffled order.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick a times table from 2 to 12.  The program asks all twelve
'   facts (x1 up to x12) in a random order, so you cannot just count
'   up.  Each right answer adds a rung to a ladder on the right of the
'   screen and the little climber moves up.  Get them all and the
'   climber reaches the star!  You can also look at the full 12 x 12
'   multiplication square first.
'
' HOW TO USE
'   Type a table number (2-12) and press Enter.  Type S to see the
'   whole multiplication square, or 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Arrays to remember which facts are left
'   * The Fisher-Yates shuffle for a fair random order
'   * LOCATE and COLOR to draw pictures with text characters
'   * Nested FOR loops to build a table
'
' THINGS TO TRY
'   * Ask each wrong fact again at the end until it is right
'   * Make the ladder 20 rungs and go up to x20
'   * Add a sound with SOUND or PLAY when the climber reaches the top
' ============================================================

RANDOMIZE TIMER
DIM order(1 TO 12)              ' the 12 multipliers in shuffled order

DO
    CLS
    COLOR 14: PRINT " ===  TIMES TABLE LADDER  ==="
    COLOR 7
    PRINT
    PRINT " Which table shall we climb? (2-12)"
    PRINT " S = show the whole square, 0 = quit"
    PRINT
    LINE INPUT " > "; t$
    t$ = UCASE$(LTRIM$(RTRIM$(t$)))
    IF t$ = "0" OR t$ = "Q" THEN EXIT DO
    IF t$ = "S" THEN
        GOSUB ShowSquare
    ELSE
        tbl = VAL(t$)
        IF tbl >= 2 AND tbl <= 12 THEN GOSUB PlayTable
    END IF
LOOP
CLS
COLOR 7
PRINT "See you next time, table champion!"
END

' ------------------------------------------------------------
' PlayTable: shuffle 1..12 then ask each fact once.
' ------------------------------------------------------------
PlayTable:
    ' Put 1..12 in the array...
    FOR i = 1 TO 12: order(i) = i: NEXT i
    ' ...then shuffle with Fisher-Yates: walk from the end, swapping
    ' each slot with a random slot at or before it.  Every possible
    ' order is equally likely.
    FOR i = 12 TO 2 STEP -1
        j = INT(RND * i) + 1
        SWAP order(i), order(j)
    NEXT i

    CLS
    rungs = 0
    GOSUB DrawLadder
    FOR q = 1 TO 12
        m = order(q)
        LOCATE 3 + q, 2: COLOR 15
        PRINT USING "## x ## = "; tbl; m;
        LINE INPUT a$
        LOCATE 3 + q, 22
        IF VAL(a$) = tbl * m AND LEN(a$) > 0 THEN
            COLOR 10: PRINT "Yes!         ";
            rungs = rungs + 1
            GOSUB DrawLadder
        ELSE
            COLOR 12: PRINT "It is"; tbl * m;
        END IF
    NEXT q

    LOCATE 18, 2: COLOR 14
    PRINT "You climbed"; rungs; "of 12 rungs!"
    LOCATE 19, 2
    IF rungs = 12 THEN
        COLOR 13: PRINT "You reached the star - AMAZING!"
        PLAY "T180 O4 C8 E8 G8 O5 C4"
    ELSEIF rungs >= 9 THEN
        PRINT "So close! Try once more."
    ELSE
        PRINT "Good climbing - practice makes it easier."
    END IF
    LOCATE 21, 2: COLOR 7: PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' DrawLadder: the ladder lives in columns 50-60, rows 3-21.
' Rung 1 is at the bottom.  Each rung is drawn green once earned.
' ------------------------------------------------------------
DrawLadder:
    LOCATE 2, 54: COLOR 14: PRINT "*";       ' the star at the top
    ' First the two side rails, all the way down...
    COLOR 7
    FOR row = 3 TO 21
        LOCATE row, 50: PRINT "|       |";
    NEXT row
    ' ...then the rungs on top of them
    FOR r = 1 TO 12
        row = 22 - r * 1.5                    ' rungs spaced 1.5 rows apart
        LOCATE INT(row), 50
        IF r <= rungs THEN COLOR 10 ELSE COLOR 8
        PRINT "|=======|";
    NEXT r
    ' The climber stands on the highest earned rung
    IF rungs > 0 THEN
        cr = INT(22 - rungs * 1.5) - 1
        IF cr < 1 THEN cr = 1
        LOCATE cr, 61: COLOR 11: PRINT "o";
        ' wipe the old climber below
        IF rungs > 1 THEN LOCATE INT(22 - (rungs - 1) * 1.5) - 1, 61: PRINT " ";
    END IF
    RETURN

' ------------------------------------------------------------
' ShowSquare: the classic 12 x 12 multiplication square.
' Square numbers (where row = column) are highlighted.
' ------------------------------------------------------------
ShowSquare:
    CLS
    COLOR 14: PRINT "   x";
    FOR c = 1 TO 12: PRINT USING "####"; c;: NEXT c
    PRINT
    FOR r = 1 TO 12
        COLOR 14: PRINT USING "####"; r;
        FOR c = 1 TO 12
            IF r = c THEN COLOR 13 ELSE IF (r + c) MOD 2 = 0 THEN COLOR 11 ELSE COLOR 3
            PRINT USING "####"; r * c;
        NEXT c
        PRINT
    NEXT r
    COLOR 7
    PRINT
    PRINT " Pink numbers are SQUARE numbers (a number times itself)."
    PRINT " Notice the square is a mirror image: 3 x 7 = 7 x 3!"
    PRINT " Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN
