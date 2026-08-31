' ============================================================
' TITLE:    Luhn Check-Digit Detective
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     luhn, check digit, credit card, MOD 10, validation
' SUMMARY:  Checks credit-card-style numbers with the Luhn formula, showing every doubled digit, and finds missing check digits.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every credit card number ends with a CHECK DIGIT.  It is not a
'   secret - it catches typing mistakes.  Hans Peter Luhn, an IBM
'   scientist, invented the formula in 1954.  It is also used for
'   IMEI phone numbers and Canadian social insurance numbers.
'
'   THE LUHN RULE
'     1. Start from the RIGHTMOST digit (the check digit).
'     2. Double every SECOND digit moving left.
'     3. If doubling gives 10 or more, subtract 9
'        (same as adding its two digits: 16 -> 1+6 = 7 = 16-9).
'     4. Add up all the digits.
'     5. The number is valid if the total ends in 0 (total MOD 10 = 0).
'
'   It catches every single wrong digit and almost every swap of two
'   neighbouring digits (all except 09 <-> 90).
'
' HOW TO USE
'   1 = check a number (spaces and dashes are ignored)
'   2 = compute the check digit for a number without one
'   3 = run the demo test numbers,   Q = quit
'   (Use only made-up or published TEST numbers, never a real card!)
'
' CONCEPTS YOU WILL LEARN
'   * Walking a string from right to left with STEP -1
'   * Converting a digit character to a number: ASC(d$) - 48
'   * Using MOD 10 to test "ends in zero"
'   * Computing a missing value: (10 - total MOD 10) MOD 10
'
' THINGS TO TRY
'   * Change one digit of a valid number: is it ever still valid?
'   * Swap 0 and 9 next to each other - Luhn misses that one!
'   * Look up the "Verhoeff" algorithm, which catches ALL swaps
' ============================================================

DECLARE FUNCTION Digits$ (t$)
DECLARE FUNCTION LuhnTotal% (d$, showWork%)

DO
    CLS
    COLOR 14: PRINT "LUHN CHECK-DIGIT DETECTIVE": COLOR 7
    PRINT
    PRINT "1) Check a number   2) Find check digit   3) Demo numbers   Q) Quit"
    LINE INPUT "Choice: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    IF c$ = "Q" OR c$ = CHR$(27) THEN EXIT DO
    SELECT CASE c$
    CASE "1"
        LINE INPUT "Number: "; n$
        d$ = Digits$(n$)
        IF LEN(d$) < 2 THEN
            PRINT "Please type at least 2 digits."
        ELSE
            tot% = LuhnTotal%(d$, 1)
            PRINT "Total ="; tot%;
            IF tot% MOD 10 = 0 THEN
                COLOR 10: PRINT " -> ends in 0: VALID"
            ELSE
                COLOR 12: PRINT " -> does not end in 0: INVALID (typo?)"
            END IF
            COLOR 7
        END IF
    CASE "2"
        LINE INPUT "Number without check digit: "; n$
        d$ = Digits$(n$)
        IF d$ = "" THEN d$ = "7992739871"
        ' Put a 0 in the check position, compute the total, then
        ' pick the digit that makes the total a multiple of 10.
        tot% = LuhnTotal%(d$ + "0", 1)
        chk% = (10 - tot% MOD 10) MOD 10
        PRINT "Total with a 0 placeholder ="; tot%
        PRINT "Check digit = (10 - "; LTRIM$(STR$(tot% MOD 10)); ") MOD 10 ="; chk%
        COLOR 10: PRINT "Full number: "; d$; LTRIM$(STR$(chk%)): COLOR 7
    CASE "3"
        ' Published test numbers (not real accounts).
        RESTORE
        DO
            READ nm$, n$
            IF nm$ = "*" THEN EXIT DO
            d$ = Digits$(n$)
            tot% = LuhnTotal%(d$, 0)
            PRINT LEFT$(nm$ + SPACE$(24), 24); LEFT$(n$ + SPACE$(22), 22);
            IF tot% MOD 10 = 0 THEN COLOR 10: PRINT "valid" ELSE COLOR 12: PRINT "INVALID"
            COLOR 7
        LOOP
    CASE ELSE
        PRINT "Choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    PRINT "Press any key...";
    k$ = INPUT$(1)
LOOP
CLS
END

DATA "Visa test","4111 1111 1111 1111"
DATA "Mastercard test","5555 5555 5555 4444"
DATA "Amex test","3782 822463 10005"
DATA "Wikipedia example","7992739871 3"
DATA "One digit changed","4111 1111 1111 1112"
DATA "Another valid number","4111 1111 1111 1210"
DATA "...2 and 1 swapped","4111 1111 1111 1120"
DATA "Valid, contains 09","4111 1111 1111 1095"
DATA "...0 9 swapped (MISSED)","4111 1111 1111 1905"
DATA "*","*"

' ------------------------------------------------------------
' Digits$: keep only the characters 0-9.
' ------------------------------------------------------------
FUNCTION Digits$ (t$)
    r$ = ""
    FOR i = 1 TO LEN(t$)
        ch$ = MID$(t$, i, 1)
        IF ch$ >= "0" AND ch$ <= "9" THEN r$ = r$ + ch$
    NEXT i
    Digits$ = r$
END FUNCTION

' ------------------------------------------------------------
' LuhnTotal%: the Luhn sum.  pos counts from the right starting
' at 1, so the digits in EVEN positions (2, 4, 6...) are doubled.
' With showWork% = 1 it prints a little table of each step.
' ------------------------------------------------------------
FUNCTION LuhnTotal% (d$, showWork%)
    total = 0
    IF showWork% THEN
        PRINT
        PRINT "Digit:  ";
        FOR i = 1 TO LEN(d$): PRINT " "; MID$(d$, i, 1); " "; : NEXT i
        PRINT
        PRINT "Double? ";
        FOR i = 1 TO LEN(d$)
            IF (LEN(d$) - i + 1) MOD 2 = 0 THEN PRINT " x2"; ELSE PRINT "   ";
        NEXT i
        PRINT
        PRINT "Value: ";
    END IF
    FOR i = 1 TO LEN(d$)
        v = ASC(MID$(d$, i, 1)) - 48      ' "0" is ASCII 48
        pos1 = LEN(d$) - i + 1            ' position from the right
        IF pos1 MOD 2 = 0 THEN
            v = v * 2
            IF v > 9 THEN v = v - 9
        END IF
        total = total + v
        IF showWork% THEN
            IF pos1 MOD 2 = 0 THEN COLOR 14 ELSE COLOR 7
            PRINT USING "###"; v;
        END IF
    NEXT i
    IF showWork% THEN COLOR 7: PRINT : PRINT
    LuhnTotal% = total
END FUNCTION
