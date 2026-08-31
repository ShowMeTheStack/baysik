' ============================================================
' TITLE:    ISBN Book Number Checker
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     ISBN, check digit, MOD 11, MOD 10, weights, validation
' SUMMARY:  Validates ISBN-10 and ISBN-13 book numbers step by step and converts old ISBN-10s to ISBN-13.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every book has an International Standard Book Number.  The last
'   digit is a CHECK DIGIT computed from the others, so a shop's
'   computer can spot a mistyped number instantly.
'
'   ISBN-10 (used 1970-2006): multiply the digits by 10, 9, 8 ... 1
'   and add.  The total must be divisible by 11.  Because the check
'   digit might need to be 10, the Roman numeral X is used for it!
'   Using the prime 11 means it catches EVERY single wrong digit AND
'   EVERY swap of two neighbouring digits.
'
'   ISBN-13 (since 2007, same as the EAN barcode on the back): use
'   weights 1, 3, 1, 3, ... and the total must be divisible by 10.
'   Simpler, but it misses some swaps (digits that differ by 5).
'
'   To convert ISBN-10 to ISBN-13: put 978 in front, drop the old
'   check digit, and compute a new ISBN-13 check digit.
'
' HOW TO USE
'   Type an ISBN with or without dashes, e.g. 0-306-40615-2 or
'   978-0-306-40615-7.  The program works out which kind it is,
'   shows the weighted sum and says whether it is valid.
'   Enter an empty line (or Q) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Weighted sums
'   * Why a PRIME modulus (11) catches more mistakes
'   * Handling the special "X" digit
'   * Computing a check digit:  (11 - sum MOD 11) MOD 11
'
' THINGS TO TRY
'   * Find the ISBN on a real book and test it
'   * Swap two neighbouring digits - which format notices?
'   * Write a "repair" mode: given one unreadable digit (?), find it
' ============================================================

DECLARE FUNCTION Clean$ (t$)
DECLARE FUNCTION Check10% (d$)
DECLARE FUNCTION Check13% (d$)

CLS
COLOR 14: PRINT "ISBN BOOK NUMBER CHECKER": COLOR 7
PRINT "Examples: 0-306-40615-2   978-0-306-40615-7   0-8044-2957-X"
PRINT
DO
    LINE INPUT "ISBN (Enter to quit): "; t$
    IF t$ = "" OR UCASE$(t$) = "Q" THEN EXIT DO
    d$ = Clean$(t$)

    IF LEN(d$) = 10 THEN
        ' ---- ISBN-10 ----------------------------------------
        sum = 0
        PRINT "  digit x weight: ";
        FOR i = 1 TO 10
            ch$ = MID$(d$, i, 1)
            IF ch$ = "X" THEN v = 10 ELSE v = VAL(ch$)
            w = 11 - i                  ' weights 10, 9, ... 1
            sum = sum + v * w
            PRINT LTRIM$(STR$(v)); "x"; LTRIM$(STR$(w)); " ";
        NEXT i
        PRINT
        PRINT "  sum ="; sum; "  sum MOD 11 ="; sum MOD 11
        IF INSTR(LEFT$(d$, 9), "X") > 0 THEN
            COLOR 12: PRINT "  X may only be the LAST character.": COLOR 7
        ELSEIF sum MOD 11 = 0 THEN
            COLOR 10: PRINT "  Valid ISBN-10!": COLOR 7
            ' Convert to ISBN-13.
            n13$ = "978" + LEFT$(d$, 9)
            c% = Check13%(n13$)
            PRINT "  As ISBN-13: "; n13$; LTRIM$(STR$(c%))
        ELSE
            c% = Check10%(LEFT$(d$, 9))
            IF c% = 10 THEN c$ = "X" ELSE c$ = LTRIM$(STR$(c%))
            COLOR 12: PRINT "  INVALID - the check digit should be "; c$: COLOR 7
        END IF

    ELSEIF LEN(d$) = 13 THEN
        ' ---- ISBN-13 ----------------------------------------
        IF INSTR(d$, "X") > 0 THEN
            COLOR 12: PRINT "  ISBN-13 never contains X.": COLOR 7
        ELSE
            sum = 0
            PRINT "  digit x weight: ";
            FOR i = 1 TO 13
                v = VAL(MID$(d$, i, 1))
                IF i MOD 2 = 1 THEN w = 1 ELSE w = 3
                sum = sum + v * w
                PRINT LTRIM$(STR$(v)); "x"; LTRIM$(STR$(w)); " ";
            NEXT i
            PRINT
            PRINT "  sum ="; sum; "  sum MOD 10 ="; sum MOD 10
            IF sum MOD 10 = 0 THEN
                COLOR 10: PRINT "  Valid ISBN-13!": COLOR 7
                IF LEFT$(d$, 3) = "978" THEN
                    c% = Check10%(MID$(d$, 4, 9))
                    IF c% = 10 THEN c$ = "X" ELSE c$ = LTRIM$(STR$(c%))
                    PRINT "  Old ISBN-10: "; MID$(d$, 4, 9); c$
                END IF
            ELSE
                COLOR 12
                PRINT "  INVALID - the check digit should be"; Check13%(LEFT$(d$, 12))
                COLOR 7
            END IF
        END IF
    ELSE
        PRINT "  An ISBN has 10 or 13 characters; you typed"; LEN(d$); "digits."
    END IF
    PRINT
LOOP
END

' ------------------------------------------------------------
' Clean$: keep digits and X (upper-cased); drop dashes/spaces.
' ------------------------------------------------------------
FUNCTION Clean$ (t$)
    r$ = ""
    FOR i = 1 TO LEN(t$)
        ch$ = UCASE$(MID$(t$, i, 1))
        IF (ch$ >= "0" AND ch$ <= "9") OR ch$ = "X" THEN r$ = r$ + ch$
    NEXT i
    Clean$ = r$
END FUNCTION

' ------------------------------------------------------------
' Check10%: check digit for the first 9 digits of an ISBN-10.
' The 10th digit has weight 1, so it must bring the total up to a
' multiple of 11:  check = (11 - sum MOD 11) MOD 11.  10 means "X".
' ------------------------------------------------------------
FUNCTION Check10% (d$)
    sum = 0
    FOR i = 1 TO 9: sum = sum + VAL(MID$(d$, i, 1)) * (11 - i): NEXT i
    Check10% = (11 - sum MOD 11) MOD 11
END FUNCTION

' ------------------------------------------------------------
' Check13%: check digit for the first 12 digits of an ISBN-13.
' The 13th digit has weight 1:  check = (10 - sum MOD 10) MOD 10.
' ------------------------------------------------------------
FUNCTION Check13% (d$)
    sum = 0
    FOR i = 1 TO 12
        IF i MOD 2 = 1 THEN w = 1 ELSE w = 3
        sum = sum + VAL(MID$(d$, i, 1)) * w
    NEXT i
    Check13% = (10 - sum MOD 10) MOD 10
END FUNCTION
