' ============================================================
' TITLE:    Times Tables Drill
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     multiplication, quiz, timer, random, education
' SUMMARY:  A timed 10-question multiplication quiz with scores, hints and a table of the facts you missed.
' ------------------------------------------------------------
' WHAT IT DOES
'   Practise your times tables!  Choose one table (like the 7s) or a
'   mixed quiz.  You get 10 questions; the program times each answer,
'   gives a hint when you are wrong (using a trick that makes the
'   fact easier) and shows a report card at the end.
'
' HOW TO USE
'   Type the table number 2-12, or 0 for a mixed quiz.  Type each
'   answer and press Enter.  Type Q as an answer to stop early.
'   After the report, press Y to play again or N to quit.
'
' CONCEPTS YOU WILL LEARN
'   * RND to make random questions, TIMER to measure speed
'   * LINE INPUT + VAL so wrong typing never crashes the program
'   * Remembering mistakes in arrays to review them later
'   * Multiplication tricks: doubling, "times 10 minus", nines finger trick
'
' THINGS TO TRY
'   * Make it harder: tables up to 20, or division questions
'   * Repeat the facts you got wrong until you get them right
'   * Add a high score that is saved to a file
' ============================================================

RANDOMIZE TIMER
DIM missA(10), missB(10)

DO
    CLS
    COLOR 14: PRINT "TIMES TABLES DRILL": COLOR 7
    PRINT
    INPUT "Which table (2-12), or 0 for a mixed quiz"; tbl
    IF tbl <> 0 AND (tbl < 2 OR tbl > 12) THEN tbl = 0
    score = 0: misses = 0: totalTime = 0: asked = 0

    FOR q = 1 TO 10
        ' Pick the two numbers.
        IF tbl = 0 THEN a = INT(RND * 11) + 2 ELSE a = tbl
        b = INT(RND * 11) + 2                  ' 2 to 12
        IF RND < .5 THEN SWAP a, b             ' 7 x 4 or 4 x 7
        PRINT
        COLOR 11: PRINT "Q"; LTRIM$(STR$(q)); ":  "; a; "x"; b; "= ";: COLOR 15
        t = TIMER
        LINE INPUT ans$
        took = TIMER - t
        IF took < 0 THEN took = took + 86400   ' clock passed midnight
        COLOR 7
        IF UCASE$(LEFT$(ans$, 1)) = "Q" THEN EXIT FOR
        asked = asked + 1
        totalTime = totalTime + took
        IF VAL(ans$) = a * b AND LTRIM$(ans$) <> "" THEN
            score = score + 1
            COLOR 10: PRINT "  Correct!";
            IF took < 3 THEN PRINT "  Lightning fast!" ELSE PRINT
        ELSE
            COLOR 12: PRINT "  Not quite.  "; a; "x"; b; "="; a * b
            COLOR 7
            ' A hint that shows a way to work it out.
            big = a: small = b: IF small > big THEN SWAP big, small
            SELECT CASE small
                CASE 2: PRINT "  Hint: x2 is just doubling:"; big; "+"; big
                CASE 4: PRINT "  Hint: x4 = double, then double again:"; big * 2; "->"; big * 4
                CASE 5: PRINT "  Hint: x5 = half of x10:  half of"; big * 10
                CASE 9: PRINT "  Hint: x9 = x10 minus one lot:"; big * 10; "-"; big
                CASE 11: PRINT "  Hint: x11 = x10 plus one more:"; big * 10; "+"; big
                CASE ELSE
                    IF big = 9 THEN
                        PRINT "  Hint: x9 = x10 minus one lot:"; small * 10; "-"; small
                    ELSE
                        PRINT "  Hint: split it up: "; small; "x"; big - 2; "+"; small; "x 2 ="; small * (big - 2); "+"; small * 2
                    END IF
            END SELECT
            misses = misses + 1
            missA(misses) = a: missB(misses) = b
        END IF
    NEXT q

    ' ---- Report card ----
    PRINT
    COLOR 14: PRINT "REPORT CARD": COLOR 7
    PRINT "Score:"; score; "out of"; asked
    IF asked > 0 THEN PRINT USING "Average time per question: ##.# seconds"; totalTime / asked
    IF asked > 0 THEN
        pct = score / asked * 100
        IF pct = 100 THEN
            PRINT "PERFECT!  You are a times-table champion!"
        ELSEIF pct >= 70 THEN
            PRINT "Great work - nearly there."
        ELSE
            PRINT "Keep practising, you will get it!"
        END IF
    END IF
    IF misses > 0 THEN
        PRINT "Facts to practise:";
        FOR i = 1 TO misses
            PRINT " "; LTRIM$(STR$(missA(i))); "x"; LTRIM$(STR$(missB(i))); "="; LTRIM$(STR$(missA(i) * missB(i)));
        NEXT i
        PRINT
    END IF
    PRINT
    PRINT "Play again (Y/N)?"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
LOOP WHILE k$ = "Y"
PRINT "Bye!"
