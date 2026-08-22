' ============================================================
' TITLE:    Number Line Frog
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     number line, negative numbers, decimals, graphics, arrow keys
' SUMMARY:  Help Freddy the frog hop to the right spot on a number line - with negatives and decimals too.
' ------------------------------------------------------------
' WHAT IT DOES
'   A number line is drawn across the screen with tick marks.  Only
'   some ticks have labels, so you must COUNT the steps.  There are
'   two games:
'     1) "Where is Freddy?" - type the number the frog is sitting on.
'     2) "Hop to it!"       - use the arrow keys to hop the frog to a
'                             target number and press Enter.
'   Level 1 uses 0 to 20, level 2 goes from -10 to 10, level 3 counts
'   in tenths between 0 and 2.
'
' HOW TO USE
'   Choose a game (1/2), then a level (1-3).  In game 2 use Left and
'   Right arrows and Enter.  Esc returns to the menu.
'
' CONCEPTS YOU WILL LEARN
'   * Mapping a value to a screen position:  x = left + (v - lo) * scale
'   * Negative numbers sit to the LEFT of zero
'   * Decimals as tick marks between whole numbers
'   * Avoiding floating point surprises by counting in whole steps
'
' THINGS TO TRY
'   * Add a level with steps of 5 from 0 to 100
'   * Show the "jump" from one number to another as an addition sum
'   * Draw the frog with DRAW instead of circles
' ============================================================

DECLARE SUB DrawLine ()
DECLARE SUB DrawFrog (i!, col!)
DECLARE FUNCTION Label$ (i!)

CONST LEFTX = 40, RIGHTX = 600, LINEY = 260
' The line has nSteps + 1 ticks, numbered i = 0 .. nSteps.
' The VALUE of tick i is lo + i * stepSize.  Working with the whole
' number i (not the decimal value) avoids rounding errors.
DIM SHARED lo, stepSize, nSteps, labelEvery
RANDOMIZE TIMER
SCREEN 12

DO
    CLS
    COLOR 10: LOCATE 4, 30: PRINT "NUMBER LINE FROG"
    COLOR 15
    LOCATE 8, 25: PRINT "1) Where is Freddy?"
    LOCATE 9, 25: PRINT "2) Hop to it!"
    LOCATE 10, 25: PRINT "Q) Quit"
    DO: g$ = UCASE$(INKEY$): LOOP UNTIL g$ <> ""
    IF g$ = "Q" OR g$ = CHR$(27) THEN EXIT DO
    IF g$ = "1" OR g$ = "2" THEN
        LOCATE 13, 25: PRINT "Level 1 (0 to 20), 2 (-10 to 10), 3 (tenths)? ";
        DO: l$ = INKEY$: LOOP UNTIL l$ <> ""
        SELECT CASE l$
            CASE "2": lo = -10: stepSize = 1: nSteps = 20: labelEvery = 5
            CASE "3": lo = 0: stepSize = .1: nSteps = 20: labelEvery = 5
            CASE ELSE: lo = 0: stepSize = 1: nSteps = 20: labelEvery = 5
        END SELECT
        IF g$ = "1" THEN GOSUB WhereIs ELSE GOSUB HopTo
    END IF
LOOP
SCREEN 0
END

' ------------------------------------------------------------
WhereIs:
    score = 0
    FOR round = 1 TO 6
        CLS
        DrawLine
        DO: f = INT(RND * (nSteps + 1)): LOOP WHILE f MOD labelEvery = 0  ' not on a label
        DrawFrog f, 10
        COLOR 14: LOCATE 3, 3: PRINT "Round"; round; "of 6.  Score:"; score
        COLOR 15: LOCATE 22, 20: PRINT "What number is Freddy sitting on? ";
        LINE INPUT a$
        IF UCASE$(a$) = "Q" THEN RETURN
        LOCATE 24, 20
        ' Compare by turning the answer back into a tick number
        IF ABS(VAL(a$) - (lo + f * stepSize)) < stepSize / 2 AND LEN(a$) > 0 THEN
            COLOR 10: PRINT "RIBBIT! Correct, it's "; Label$(f): score = score + 1
        ELSE
            COLOR 12: PRINT "Not quite - Freddy is on "; Label$(f)
            LOCATE 25, 20: COLOR 7: PRINT "Count the ticks from the nearest label."
        END IF
        LOCATE 27, 20: COLOR 7: PRINT "Press a key...";
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        IF k$ = CHR$(27) THEN RETURN
    NEXT round
    RETURN

' ------------------------------------------------------------
HopTo:
    score = 0
    FOR round = 1 TO 6
        target = INT(RND * (nSteps + 1))
        f = nSteps \ 2                        ' start in the middle
        DO
            CLS
            DrawLine
            DrawFrog f, 10
            COLOR 14: LOCATE 3, 3: PRINT "Round"; round; "of 6.  Score:"; score
            COLOR 15: LOCATE 5, 3: PRINT "Hop Freddy to  "; Label$(target); "  then press Enter"
            LOCATE 6, 3: COLOR 7: PRINT "(Left/Right arrows to hop)"
            DO: k$ = INKEY$: LOOP WHILE k$ = ""
            IF k$ = CHR$(0) + "K" AND f > 0 THEN f = f - 1
            IF k$ = CHR$(0) + "M" AND f < nSteps THEN f = f + 1
            IF k$ = CHR$(27) THEN RETURN
        LOOP UNTIL k$ = CHR$(13)
        LOCATE 22, 20
        IF f = target THEN
            COLOR 10: PRINT "Perfect landing on "; Label$(target); "!": score = score + 1
            PLAY "T200 O5 C16 G16"
        ELSE
            COLOR 12: PRINT "Freddy landed on "; Label$(f); " - the target was "; Label$(target)
            DrawFrog target, 12
        END IF
        LOCATE 24, 20: COLOR 7: PRINT "Press a key...";
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
    NEXT round
    RETURN

' ------------------------------------------------------------
' DrawLine: the line, a tick for every step, labels on some ticks.
' ------------------------------------------------------------
SUB DrawLine
    LINE (LEFTX - 20, LINEY)-(RIGHTX + 20, LINEY), 15
    ' arrow heads: the line goes on forever both ways
    LINE (RIGHTX + 20, LINEY)-(RIGHTX + 12, LINEY - 5), 15
    LINE (RIGHTX + 20, LINEY)-(RIGHTX + 12, LINEY + 5), 15
    LINE (LEFTX - 20, LINEY)-(LEFTX - 12, LINEY - 5), 15
    LINE (LEFTX - 20, LINEY)-(LEFTX - 12, LINEY + 5), 15
    FOR i = 0 TO nSteps
        x = LEFTX + i * (RIGHTX - LEFTX) / nSteps
        IF i MOD labelEvery = 0 THEN
            LINE (x, LINEY - 12)-(x, LINEY + 12), 14
            t$ = Label$(i)
            ' text cell under the tick (8 x 16 pixel characters)
            LOCATE (LINEY + 20) \ 16 + 1, INT(x / 8) + 1 - LEN(t$) \ 2
            COLOR 14: PRINT t$;
        ELSE
            LINE (x, LINEY - 6)-(x, LINEY + 6), 7
        END IF
    NEXT i
END SUB

' Freddy: a green blob with two eyes, sitting above tick i
SUB DrawFrog (i, col)
    x = LEFTX + i * (RIGHTX - LEFTX) / nSteps
    y = LINEY - 30
    CIRCLE (x, y), 14, col, , , .7
    PAINT (x, y), col, col
    CIRCLE (x - 6, y - 10), 4, 15: PAINT (x - 6, y - 10), 15, 15
    CIRCLE (x + 6, y - 10), 4, 15: PAINT (x + 6, y - 10), 15, 15
    PSET (x - 6, y - 10), 0: PSET (x + 6, y - 10), 0
    LINE (x, y + 10)-(x, LINEY - 2), col          ' pointer to the tick
END SUB

' The value of tick i as neat text, e.g. "-3" or "1.4"
FUNCTION Label$ (i)
    v = lo + i * stepSize
    v = INT(v * 10 + .5) / 10             ' round to one decimal place
    t$ = LTRIM$(STR$(v))
    IF LEFT$(t$, 1) = "." THEN t$ = "0" + t$  ' STR$(.5) gives ".5"
    Label$ = t$
END FUNCTION
