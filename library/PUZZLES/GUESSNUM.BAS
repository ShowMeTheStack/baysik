' ============================================================
' TITLE:    Number Guessing & Binary Search
' CATEGORY: Puzzles & Logic
' LEVEL:    Beginner
' TAGS:     guessing game, binary search, logarithms, input, beginner
' SUMMARY:  Guess my number, then let the computer guess yours - it never needs more than 7 tries for 1-100, and explains why.
' ------------------------------------------------------------
' WHAT IT DOES
'   Mode 1: the computer thinks of a number from 1 to 100.  You
'   guess, and it says "higher" or "lower".
'
'   Mode 2: YOU think of a number and the computer guesses, using
'   BINARY SEARCH: always guess the middle of the numbers that are
'   still possible.  Each answer throws away half of them:
'        100 -> 50 -> 25 -> 12 -> 6 -> 3 -> 1
'   So 7 guesses are always enough, because 2^7 = 128 >= 100.
'   For a million numbers you'd need only 20!  A bar shows the range
'   shrinking, and the computer catches you if you cheat.
'
' HOW TO USE
'   Choose 1 or 2 from the menu.  In mode 2 answer each guess with
'   H (my number is higher), L (lower) or C (correct).  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Binary search: halve the problem every step
'   * Logarithms: steps needed = how many times you can halve N
'   * Loops with low / high bounds, integer division
'   * Validating user input
'
' THINGS TO TRY
'   * Change MAXNUM to 1000 or 1000000 - how many guesses now?
'   * Make the computer guess at a random spot instead of the middle
'     and count how many more guesses it needs on average.
' ============================================================
DECLARE SUB RangeBar (lo AS LONG, hi AS LONG)
DEFINT A-Z

CONST MAXNUM = 100
RANDOMIZE TIMER

' The smallest number of guesses that ALWAYS works: the smallest s
' with 2^s - 1 >= MAXNUM (s guesses can tell apart 2^s - 1 numbers).
best = 0
DO WHILE 2 ^ best - 1 < MAXNUM: best = best + 1: LOOP

DO
    CLS
    COLOR 14: PRINT "NUMBER GUESSING & BINARY SEARCH": COLOR 7
    PRINT
    PRINT "  1) You guess my number (1 -"; MAXNUM; ")"
    PRINT "  2) I guess your number"
    PRINT "  Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    SELECT CASE a$
        CASE "1"
            secret = INT(RND * MAXNUM) + 1
            tries = 0: lo = 1: hi = MAXNUM
            PRINT
            PRINT "  I'm thinking of a number from 1 to"; MAXNUM; ". (Q gives up)"
            DO
                PRINT "  Guess ("; LTRIM$(STR$(lo)); "-"; LTRIM$(STR$(hi)); ")";
                LINE INPUT "? "; g$
                IF INSTR(UCASE$(g$), "Q") OR INSTR(g$, CHR$(27)) THEN
                    PRINT "  It was"; secret; "."
                    EXIT DO
                END IF
                g = VAL(g$)
                IF g < 1 OR g > MAXNUM THEN
                    PRINT "  Please guess a number from 1 to"; MAXNUM
                ELSE
                    tries = tries + 1
                    IF g < secret THEN
                        PRINT "  Higher!"
                        IF g >= lo THEN lo = g + 1
                    ELSEIF g > secret THEN
                        PRINT "  Lower!"
                        IF g <= hi THEN hi = g - 1
                    ELSE
                        COLOR 10: PRINT "  Correct! You got it in"; tries; "tries.": COLOR 7
                        IF tries <= best THEN
                            PRINT "  That's as good as binary search ("; LTRIM$(STR$(best)); " or fewer)."
                        ELSE
                            PRINT "  Binary search never needs more than"; best; "- try guessing the middle!"
                        END IF
                        EXIT DO
                    END IF
                END IF
            LOOP
        CASE "2"
            PRINT
            PRINT "  Think of a whole number from 1 to"; MAXNUM; "- don't tell me!"
            PRINT "  Answer H (higher), L (lower) or C (correct)."
            lo& = 1: hi& = MAXNUM: tries = 0
            DO
                IF lo& > hi& THEN
                    ' Nothing is left - some answer must have been wrong.
                    COLOR 12: PRINT "  Hmm, no number fits your answers. Did you cheat?": COLOR 7
                    EXIT DO
                END IF
                ' Guess the middle of what's left.
                guess& = (lo& + hi&) \ 2
                tries = tries + 1
                RangeBar lo&, hi&
                PRINT "  Guess"; tries; ": is it"; guess&;
                LINE INPUT "? "; r$
                r$ = UCASE$(LEFT$(LTRIM$(r$), 1))
                SELECT CASE r$
                    CASE "H"
                        PRINT "    -> numbers"; lo&; "to"; guess&; "are out."
                        lo& = guess& + 1
                    CASE "L"
                        PRINT "    -> numbers"; guess&; "to"; hi&; "are out."
                        hi& = guess& - 1
                    CASE "C"
                        COLOR 10: PRINT "  Got it in"; tries; "guesses!": COLOR 7
                        PRINT "  (With"; MAXNUM; "numbers I never need more than"; best; "guesses.)"
                        EXIT DO
                    CASE "Q", CHR$(27)
                        EXIT DO
                    CASE ELSE
                        PRINT "  Please answer H, L or C."
                        tries = tries - 1
                END SELECT
            LOOP
        CASE ELSE
            PRINT "  Please choose 1, 2 or Q."
    END SELECT
    PRINT
    LINE INPUT "  Press Enter for the menu (Q quits) "; k$
    IF INSTR(UCASE$(k$), "Q") OR INSTR(k$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

SUB RangeBar (lo AS LONG, hi AS LONG)
    ' Draw 1..MAXNUM as 50 characters; the still-possible part glows.
    PRINT "  [";
    FOR i = 1 TO 50
        ' Which numbers does this character stand for?
        a& = (i - 1) * MAXNUM \ 50 + 1: b& = i * MAXNUM \ 50
        IF b& >= lo AND a& <= hi THEN COLOR 14: PRINT CHR$(219); ELSE COLOR 8: PRINT CHR$(176);
    NEXT
    COLOR 7: PRINT "]"; hi - lo + 1; "left"
END SUB
