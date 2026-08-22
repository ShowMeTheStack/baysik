' ============================================================
' TITLE:    Roman Numeral Quiz
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     roman numerals, history, strings, greedy algorithm, quiz
' SUMMARY:  Learn how the Romans wrote numbers, see conversions step by step, then test yourself both ways.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Romans used letters for numbers: I=1, V=5, X=10, L=50,
'   C=100, D=500, M=1000.  A smaller letter BEFORE a bigger one is
'   taken away (IV = 4, XC = 90).  This program:
'     E) explains any number step by step (e.g. 1994 = M CM XC IV)
'     1) asks you to write a number in Roman numerals
'     2) asks you to read Roman numerals as a normal number
'   The levels grow from 1-20 up to 1-3999.
'
' HOW TO USE
'   Choose E, 1 or 2, Q to quit.  For quizzes pick a level 1-3, then
'   type answers and press Enter.  Type Q to leave a quiz early.
'
' CONCEPTS YOU WILL LEARN
'   * A "greedy" algorithm: always take the biggest piece that fits
'   * Lookup tables in DATA including the subtractive pairs (CM, IV)
'   * Reading a string from remain to right and peeking at the next letter
'   * Checking answers by converting both ways
'
' THINGS TO TRY
'   * Make the quiz show clock faces with Roman numerals
'   * Reject badly formed numerals like IIII or VX
'   * Find the number below 4000 with the LONGEST Roman numeral
' ============================================================

DECLARE FUNCTION ToRoman$ (n!)
DECLARE FUNCTION FromRoman! (r$)
DECLARE FUNCTION LetterVal! (c$)
DIM SHARED rv(1 TO 13), rs$(1 TO 13)
' The 13 "pieces", biggest first.  Including CM, CD, XC, XL, IX and
' IV as pieces means the greedy method handles subtraction for free.
FOR i = 1 TO 13: READ rv(i), rs$(i): NEXT i
DATA 1000, M, 900, CM, 500, D, 400, CD, 100, C, 90, XC
DATA 50, L, 40, XL, 10, X, 9, IX, 5, V, 4, IV, 1, I
RANDOMIZE TIMER

DO
    CLS
    COLOR 14: PRINT "  ===  ROMAN NUMERAL QUIZ  ==="
    COLOR 6: PRINT "      I=1  V=5  X=10  L=50  C=100  D=500  M=1000"
    COLOR 7: PRINT
    PRINT "  E) Explain a number"
    PRINT "  1) Number -> Roman quiz"
    PRINT "  2) Roman -> number quiz"
    PRINT "  Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "E": GOSUB Explain
        CASE "1", "2": mode = VAL(k$): GOSUB Quiz
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
PRINT "VALE! (That's Latin for goodbye.)"
END

' ------------------------------------------------------------
Explain:
    PRINT
    INPUT "  Number to explain (1-3999)"; n
    n = INT(n)
    IF n < 1 OR n > 3999 THEN RETURN
    PRINT
    remain = n
    ' Greedy: for each piece, take it as many times as it fits.
    FOR i = 1 TO 13
        DO WHILE remain >= rv(i)
            COLOR 11: PRINT USING "  #### - #### = ####   "; remain; rv(i); remain - rv(i);
            COLOR 14: PRINT "write "; rs$(i)
            remain = remain - rv(i)
        LOOP
    NEXT i
    PRINT
    COLOR 15: PRINT "  So"; n; "= "; : COLOR 10: PRINT ToRoman$(n)
    COLOR 7: PRINT: PRINT "  Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
Quiz:
    PRINT
    PRINT "  Level 1 (1-20), 2 (1-100) or 3 (1-3999)? ";
    DO: l$ = INKEY$: LOOP UNTIL l$ <> ""
    SELECT CASE l$
        CASE "1": top = 20
        CASE "2": top = 100
        CASE ELSE: top = 3999
    END SELECT
    score = 0
    CLS
    FOR q = 1 TO 10
        n = INT(RND * top) + 1
        COLOR 7: PRINT USING "  ##) "; q;
        IF mode = 1 THEN
            COLOR 15: PRINT "Write"; n; "in Roman numerals: ";
            LINE INPUT a$
            a$ = UCASE$(LTRIM$(RTRIM$(a$)))
            ok = (a$ = ToRoman$(n))
        ELSE
            COLOR 15: PRINT "What number is "; ToRoman$(n); "? ";
            LINE INPUT a$
            a$ = UCASE$(LTRIM$(RTRIM$(a$)))
            ok = (VAL(a$) = n AND a$ <> "")
        END IF
        IF a$ = "Q" THEN EXIT FOR
        IF ok THEN
            score = score + 1
            COLOR 10: PRINT "      Correct!"
        ELSE
            COLOR 12: PRINT "      No -"; n; "= "; ToRoman$(n);
            ' If they typed letters, tell them what THEIR numeral means
            IF mode = 1 AND a$ <> "" THEN PRINT "   (you wrote"; FromRoman(a$); ")" ELSE PRINT
        END IF
    NEXT q
    PRINT
    COLOR 14: PRINT "  Score:"; score; "/ 10  ";
    IF score >= 8 THEN PRINT "Magnificent, Caesar!" ELSE PRINT "Keep practising, young Roman!"
    COLOR 7: PRINT "  Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' Greedy conversion: number -> Roman
FUNCTION ToRoman$ (n)
    r$ = "": remain = n
    FOR i = 1 TO 13
        DO WHILE remain >= rv(i)
            r$ = r$ + rs$(i): remain = remain - rv(i)
        LOOP
    NEXT i
    ToRoman$ = r$
END FUNCTION

' Roman -> number: add each letter, but SUBTRACT it if the next
' letter is bigger (that's how IV = 5 - 1 = 4 works).
FUNCTION FromRoman (r$)
    total = 0
    FOR i = 1 TO LEN(r$)
        v = LetterVal(MID$(r$, i, 1))
        IF i < LEN(r$) THEN nxt = LetterVal(MID$(r$, i + 1, 1)) ELSE nxt = 0
        IF v < nxt THEN total = total - v ELSE total = total + v
    NEXT i
    FromRoman = total
END FUNCTION

FUNCTION LetterVal (c$)
    SELECT CASE c$
        CASE "I": LetterVal = 1
        CASE "V": LetterVal = 5
        CASE "X": LetterVal = 10
        CASE "L": LetterVal = 50
        CASE "C": LetterVal = 100
        CASE "D": LetterVal = 500
        CASE "M": LetterVal = 1000
        CASE ELSE: LetterVal = 0
    END SELECT
END FUNCTION
