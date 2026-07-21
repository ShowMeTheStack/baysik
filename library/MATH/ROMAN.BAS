' ============================================================
' TITLE:    Roman Numeral Converter
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     roman numerals, strings, DATA, greedy algorithm
' SUMMARY:  Turns numbers into Roman numerals and back, explaining the subtraction rule.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Romans wrote numbers with letters:
'       I=1  V=5  X=10  L=50  C=100  D=500  M=1000
'   Symbols are added up (XVI = 10+5+1 = 16), except that a smaller
'   symbol written BEFORE a bigger one is subtracted (IV = 4,
'   XC = 90, CM = 900).
'   Type a number (1-3999) to get Roman numerals, or type Roman
'   numerals to get the number.
'
' HOW TO USE
'   Enter 1987 or MCMLXXXVII.  Enter a blank line or 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * A "greedy" algorithm: always use the biggest symbol that fits
'   * Lookup tables stored in DATA and READ into arrays
'   * Scanning a string left to right with a look-ahead
'   * Checking input by converting it back again (round trip)
'
' THINGS TO TRY
'   * Print every year from 1990 to 2030 in Roman numerals
'   * Which number below 4000 has the longest Roman numeral?
'   * Add a bar-over notation for numbers in the thousands
' ============================================================

DECLARE FUNCTION ToRoman$ (n AS INTEGER)
DECLARE FUNCTION FromRoman% (r$)

' 13 symbol groups, biggest first.  Including the subtractive pairs
' (CM, CD, XC, XL, IX, IV) makes the greedy method automatically
' produce correct Roman numerals.
DIM SHARED sym$(13), vals(13) AS INTEGER
FOR i = 1 TO 13: READ sym$(i), vals(i): NEXT i
DATA M,1000, CM,900, D,500, CD,400, C,100, XC,90, L,50, XL,40, X,10, IX,9, V,5, IV,4, I,1

CLS
COLOR 14: PRINT "ROMAN NUMERAL CONVERTER": COLOR 7
PRINT "I=1 V=5 X=10 L=50 C=100 D=500 M=1000"
PRINT

DO
    LINE INPUT "Number or numeral (blank = quit): "; a$
    a$ = UCASE$(LTRIM$(RTRIM$(a$)))
    IF a$ = "" OR a$ = "0" THEN EXIT DO
    IF a$ = "Q" THEN EXIT DO
    IF VAL(a$) > 0 THEN
        n = VAL(a$)
        IF n > 3999 THEN
            PRINT "  Roman numerals only go up to 3999 (MMMCMXCIX)."
        ELSE
            COLOR 11: PRINT "  "; n; "= "; ToRoman$(INT(n)): COLOR 7
        END IF
    ELSE
        v% = FromRoman%(a$)
        IF v% <= 0 THEN
            PRINT "  That contains letters that are not Roman numerals."
        ELSEIF ToRoman$(v%) <> a$ THEN
            ' The value is computable, but a Roman would have written
            ' it differently (e.g. IIII or VX).  Show the proper form.
            PRINT "  Value is"; v%; "but the standard way to write it is "; ToRoman$(v%)
        ELSE
            COLOR 11: PRINT "  "; a$; " ="; v%: COLOR 7
        END IF
    END IF
LOOP
PRINT "VALE! (goodbye)"
END

' Reads a Roman numeral.  Rule: if a symbol is smaller than the one
' after it, subtract it; otherwise add it.
FUNCTION FromRoman% (r$)
    total = 0
    FOR i = 1 TO LEN(r$)
        v = 0: nxt = 0
        SELECT CASE MID$(r$, i, 1)
            CASE "I": v = 1
            CASE "V": v = 5
            CASE "X": v = 10
            CASE "L": v = 50
            CASE "C": v = 100
            CASE "D": v = 500
            CASE "M": v = 1000
            CASE ELSE: FromRoman% = -1: EXIT FUNCTION
        END SELECT
        ' Look ahead at the next symbol (if there is one).
        IF i < LEN(r$) THEN
            SELECT CASE MID$(r$, i + 1, 1)
                CASE "I": nxt = 1
                CASE "V": nxt = 5
                CASE "X": nxt = 10
                CASE "L": nxt = 50
                CASE "C": nxt = 100
                CASE "D": nxt = 500
                CASE "M": nxt = 1000
            END SELECT
        END IF
        IF v < nxt THEN total = total - v ELSE total = total + v
    NEXT i
    IF total > 3999 THEN total = -1
    FromRoman% = total
END FUNCTION

' Greedy conversion: take the biggest value that still fits, write its
' symbol, subtract it, and repeat until nothing is left.
FUNCTION ToRoman$ (n AS INTEGER)
    remain% = n
    out$ = ""
    FOR i = 1 TO 13
        DO WHILE remain% >= vals(i)
            out$ = out$ + sym$(i)
            remain% = remain% - vals(i)
        LOOP
    NEXT i
    ToRoman$ = out$
END FUNCTION
