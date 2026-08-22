' ============================================================
' TITLE:    Arithmetic Drill
' CATEGORY: Education & Quizzes
' LEVEL:    Beginner
' TAGS:     math, quiz, timer, scoring, random
' SUMMARY:  Ten quick sums against the clock - earn bonus points for fast, correct answers!
' ------------------------------------------------------------
' WHAT IT DOES
'   Asks you ten arithmetic questions.  You pick the operation
'   (add, subtract, multiply, divide or a mix) and how hard the
'   numbers are.  Every correct answer is worth 10 points, plus a
'   speed bonus if you answer quickly.  At the end you see your
'   score, how long you took and a friendly message.
'
' HOW TO USE
'   Choose an operation (1-5) and a level (1-3) from the menus.
'   Type each answer and press Enter.  Choose Q on the menu to quit.
'
' CONCEPTS YOU WILL LEARN
'   * RANDOMIZE TIMER and RND to make new questions each time
'   * TIMER to measure how many seconds something takes
'   * SELECT CASE to choose between several kinds of question
'   * Making division questions that always come out even
'
' THINGS TO TRY
'   * Change the number of questions from 10 to 20
'   * Add a "powers" operation, like 2 ^ 5
'   * Keep a best score in a file so you can try to beat it
' ============================================================

RANDOMIZE TIMER           ' seed the random numbers from the clock

CONST NUMQ = 10           ' how many questions per round

DO
    ' ---------------- main menu ----------------
    CLS
    COLOR 14: PRINT "  *** ARITHMETIC DRILL ***"
    COLOR 11: PRINT
    PRINT "  1) Addition        (+)"
    PRINT "  2) Subtraction     (-)"
    PRINT "  3) Multiplication  (x)"
    PRINT "  4) Division        (/)"
    PRINT "  5) Mixed bag"
    PRINT "  Q) Quit"
    COLOR 7: PRINT
    PRINT "  Your choice? ";
    ' Wait for one valid key.  INKEY$ returns "" until a key is pressed.
    DO
        k$ = UCASE$(INKEY$)
    LOOP UNTIL INSTR("12345Q" + CHR$(27), k$) > 0 AND k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    op = VAL(k$)
    PRINT k$

    PRINT
    PRINT "  Level 1 (numbers to 10), 2 (to 20) or 3 (to 100)? ";
    DO
        l$ = INKEY$
    LOOP UNTIL l$ >= "1" AND l$ <= "3" AND LEN(l$) = 1
    PRINT l$
    level = VAL(l$)
    SELECT CASE level
        CASE 1: top = 10
        CASE 2: top = 20
        CASE ELSE: top = 100
    END SELECT

    ' ---------------- the quiz ----------------
    score = 0: correct = 0
    startAll = TIMER                ' when the whole round began
    FOR q = 1 TO NUMQ
        ' For the mixed bag, pick an operation at random each time
        IF op = 5 THEN thisOp = INT(RND * 4) + 1 ELSE thisOp = op
        a = INT(RND * top) + 1      ' a number from 1 to top
        b = INT(RND * top) + 1
        SELECT CASE thisOp
            CASE 1
                sign$ = "+": answer = a + b
            CASE 2
                ' Swap so the answer is never negative - kinder for kids
                IF b > a THEN SWAP a, b
                sign$ = "-": answer = a - b
            CASE 3
                ' Keep multiplication friendly: second number at most 12
                b = INT(RND * 12) + 1
                IF top = 100 THEN a = INT(RND * 25) + 1 ELSE a = INT(RND * top) + 1
                sign$ = "x": answer = a * b
            CASE 4
                ' Build division BACKWARDS: choose the answer and the
                ' divisor first, then multiply to get the dividend.
                ' That way the answer is always a whole number.
                b = INT(RND * 10) + 1
                answer = INT(RND * (top \ 2)) + 1
                a = answer * b
                sign$ = "/"
        END SELECT

        PRINT
        COLOR 15
        PRINT USING "  Question ## of ##:  "; q; NUMQ;
        PRINT LTRIM$(STR$(a)); " "; sign$; " "; LTRIM$(STR$(b)); " = ";
        t0 = TIMER                  ' start the stopwatch for this question
        LINE INPUT reply$
        secs = TIMER - t0
        IF secs < 0 THEN secs = secs + 86400   ' TIMER resets at midnight!

        IF LTRIM$(RTRIM$(reply$)) <> "" AND VAL(reply$) = answer THEN
            correct = correct + 1
            ' Speed bonus: up to 10 extra points, 1 lost per second
            bonus = 10 - INT(secs)
            IF bonus < 0 THEN bonus = 0
            score = score + 10 + bonus
            COLOR 10: PRINT "    Correct! +10";
            IF bonus > 0 THEN PRINT " and speed bonus +"; LTRIM$(STR$(bonus)) ELSE PRINT
        ELSE
            COLOR 12: PRINT "    Not quite - the answer is"; answer
        END IF
    NEXT q
    total = TIMER - startAll
    IF total < 0 THEN total = total + 86400

    ' ---------------- results ----------------
    PRINT
    COLOR 14
    PRINT "  You got"; correct; "out of"; NUMQ; "correct."
    PRINT USING "  Time taken: ###.# seconds   Score: ###"; total; score
    COLOR 13
    SELECT CASE correct
        CASE NUMQ: PRINT "  PERFECT! You are a math superstar!"
        CASE IS >= 8: PRINT "  Great work! Almost perfect!"
        CASE IS >= 5: PRINT "  Good job! Practice makes progress."
        CASE ELSE: PRINT "  Keep trying - every practice makes your brain stronger!"
    END SELECT
    COLOR 7
    PRINT: PRINT "  Press any key for the menu..."
    DO: LOOP WHILE INKEY$ = ""
LOOP

CLS
PRINT "Thanks for practising. Bye!"
END
