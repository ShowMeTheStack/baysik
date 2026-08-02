' ============================================================
' TITLE:    Mutual Recursion: IsEven and IsOdd
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, mutual recursion, call stack, DECLARE, Hofstadter
' SUMMARY:  Two functions that only work by calling each other - plus Hofstadter's Female and Male sequences.
' ------------------------------------------------------------
' WHAT IT DOES
'   IsEven(n) asks "is n-1 odd?"  and  IsOdd(n) asks "is n-1 even?"
'   Neither function can answer alone; they bounce the question back
'   and forth, one step smaller each time, until n reaches 0
'   (0 is even, and not odd).  This is MUTUAL recursion.
'   It is a silly way to test even/odd (n MOD 2 is instant!) but a
'   perfect way to see two different functions alternate on the
'   call stack.
'   Part 2 shows a less silly example: Douglas Hofstadter's F and M
'   sequences from "Godel, Escher, Bach":
'       F(0) = 1,  F(n) = n - M(F(n-1))
'       M(0) = 0,  M(n) = n - F(M(n-1))
'
' HOW TO USE
'   Enter a small number (0 to 40).  Negative quits.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK EVEN and <<< BREAK ODD.  Enter 5.  The
'      stops alternate: IsOdd 5, IsEven 4, IsOdd 3, IsEven 2 ...
'   2. Open the CALL STACK at n = 0: frames alternate between the two
'      function names like a zipper.
'   3. Use STEP INTO and watch the current line jump between the two
'      functions.  Then STEP OUT several times to unzip.
'   4. Hofstadter: set a conditional breakpoint  n = 3  in FemaleF.
'      How many times is F(3) computed for F(12)?  (Lots - a memo
'      would help, just like in FIBMEMO.BAS.)
'
' CONCEPTS YOU WILL LEARN
'   * Mutual recursion: A calls B, B calls A
'   * Why DECLARE lines matter: each function must be known before
'     the other one uses it
'   * The answer is decided at the bottom and passed up unchanged
'
' THINGS TO TRY
'   * Write a three-way version: remainder 0, 1, 2 when dividing by 3.
'   * Print F and M side by side up to 30 - they differ only rarely!
' ============================================================
DECLARE FUNCTION IsEven% (n AS INTEGER)
DECLARE FUNCTION IsOdd% (n AS INTEGER)
DECLARE FUNCTION FemaleF% (n AS INTEGER)
DECLARE FUNCTION MaleM% (n AS INTEGER)

DIM SHARED trail$          ' records the bouncing, for the printout

CLS
PRINT "MUTUAL RECURSION - IsEven / IsOdd"
PRINT
DO
    INPUT "Number 0..40 (negative quits)"; n%
    IF n% < 0 THEN EXIT DO
    IF n% > 40 THEN n% = 40
    trail$ = ""
    e% = IsEven%(n%)
    PRINT "  path: "; trail$
    IF e% THEN PRINT "  "; n%; "is EVEN" ELSE PRINT "  "; n%; "is ODD"
    PRINT
LOOP

PRINT
PRINT "Hofstadter's Female and Male sequences:"
PRINT " n: ";
FOR i% = 0 TO 15: PRINT USING "###"; i%;: NEXT i%
PRINT
PRINT " F: ";
FOR i% = 0 TO 15: PRINT USING "###"; FemaleF%(i%);: NEXT i%
PRINT
PRINT " M: ";
FOR i% = 0 TO 15: PRINT USING "###"; MaleM%(i%);: NEXT i%
PRINT
END

FUNCTION IsEven% (n AS INTEGER)
    trail$ = trail$ + "E" + LTRIM$(STR$(n)) + " "
    IF n = 0 THEN                       ' <<< BREAK EVEN
        IsEven% = -1                    ' 0 is even: TRUE
    ELSE
        IsEven% = IsOdd%(n - 1)         ' n is even if n-1 is odd
    END IF
END FUNCTION

FUNCTION IsOdd% (n AS INTEGER)
    trail$ = trail$ + "O" + LTRIM$(STR$(n)) + " "
    IF n = 0 THEN                       ' <<< BREAK ODD
        IsOdd% = 0                      ' 0 is not odd: FALSE
    ELSE
        IsOdd% = IsEven%(n - 1)         ' n is odd if n-1 is even
    END IF
END FUNCTION

FUNCTION FemaleF% (n AS INTEGER)
    IF n = 0 THEN FemaleF% = 1 ELSE FemaleF% = n - MaleM%(FemaleF%(n - 1))
END FUNCTION

FUNCTION MaleM% (n AS INTEGER)
    IF n = 0 THEN MaleM% = 0 ELSE MaleM% = n - FemaleF%(MaleM%(n - 1))
END FUNCTION
