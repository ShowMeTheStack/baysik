' ============================================================
' TITLE:    Number Base Converter
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     binary, hexadecimal, bases, place value, strings
' SUMMARY:  Converts numbers between any bases from 2 to 36 and shows the place-value working.
' ------------------------------------------------------------
' WHAT IT DOES
'   We normally count in base 10: the number 352 means
'   3 hundreds + 5 tens + 2 ones = 3*10^2 + 5*10^1 + 2*10^0.
'   Computers use base 2 (binary) and programmers love base 16
'   (hexadecimal, digits 0-9 then A-F).  Any base works the same way.
'   This program reads a number written in one base, explains its
'   value digit by digit, and writes it out in another base by
'   repeated division.
'
' HOW TO USE
'   Enter the number (letters for digits above 9, e.g. FF), the base
'   it is written in, and the base you want.  Enter a blank number
'   (or Q) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Place value in any base
'   * Converting TO base 10: multiply-and-add (Horner's method)
'   * Converting FROM base 10: repeated division, reading remainders
'   * INSTR as a quick "digit lookup table"
'
' THINGS TO TRY
'   * Convert 255 to bases 2, 8, 16 - notice the patterns
'   * Write a number in base 36 that spells a word, e.g. HELLO
'   * Add support for negative numbers or fractions
' ============================================================

DEFDBL A-Z
' The position of a character in this string is its digit value + 1.
DIGITS$ = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

CLS
COLOR 14: PRINT "NUMBER BASE CONVERTER (bases 2 to 36)": COLOR 7
PRINT "Built-in shortcuts also exist: HEX$(255) ="; HEX$(255); "  OCT$(255) ="; OCT$(255)
PRINT

DO
    LINE INPUT "Number (blank or Q = quit): "; num$
    num$ = UCASE$(LTRIM$(RTRIM$(num$)))
    IF num$ = "" OR num$ = "Q" THEN EXIT DO
    INPUT "  written in base"; b1
    INPUT "  convert to base"; b2
    IF b1 < 2 OR b1 > 36 OR b2 < 2 OR b2 > 36 THEN
        PRINT "  Bases must be between 2 and 36."
        GOTO NextOne
    END IF

    ' --- Step 1: read the digits and build the value ---------
    ' Horner's method: value = ((d1 * b + d2) * b + d3) * b + ...
    ' which is the same as d1*b^2 + d2*b + d3 but needs no powers.
    value = 0
    ok = -1
    FOR i = 1 TO LEN(num$)
        d = INSTR(DIGITS$, MID$(num$, i, 1)) - 1
        IF d < 0 OR d >= b1 THEN
            PRINT "  '"; MID$(num$, i, 1); "' is not a digit in base"; b1
            ok = 0
            EXIT FOR
        END IF
        value = value * b1 + d
    NEXT i
    IF NOT ok THEN GOTO NextOne
    IF value > 1E+15 THEN PRINT "  Too big for exact arithmetic.": GOTO NextOne

    ' Show the place-value breakdown (only for short numbers).
    IF LEN(num$) <= 8 THEN
        PRINT "  ";
        p = LEN(num$) - 1
        FOR i = 1 TO LEN(num$)
            PRINT MID$(num$, i, 1); "x"; LTRIM$(STR$(b1)); "^"; LTRIM$(STR$(p));
            IF i < LEN(num$) THEN PRINT " + ";
            p = p - 1
        NEXT i
        PRINT
    END IF
    PRINT "  = "; LTRIM$(STR$(value)); " in base 10"

    ' --- Step 2: write the value in base b2 -------------------
    ' Divide by b2 again and again.  The remainders are the digits,
    ' from the ones place upward, so we glue each new one on the LEFT.
    IF value = 0 THEN
        out$ = "0"
    ELSE
        out$ = ""
        v = value
        DO WHILE v > 0
            q = INT(v / b2)
            r = v - q * b2              ' remainder (like MOD, but safe for big numbers)
            out$ = MID$(DIGITS$, r + 1, 1) + out$
            v = q
        LOOP
    END IF
    COLOR 11
    PRINT "  = "; out$; " in base"; b2
    COLOR 7
NextOne:
    PRINT
LOOP
PRINT "Bye!"
