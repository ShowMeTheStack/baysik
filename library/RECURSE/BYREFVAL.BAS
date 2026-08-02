' ============================================================
' TITLE:    By Reference vs By Value
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     parameters, BYREF, BYVAL, by reference, by value, SUB, FUNCTION, side effects
' SUMMARY:  Discover that QBasic SUBs can change your variables behind your back - and three ways to pass a safe copy instead.
' ------------------------------------------------------------
' WHAT IT DOES
'   In QBasic, arguments are passed BY REFERENCE: the SUB receives the
'   caller's actual variable, not a copy.  If the SUB changes its
'   parameter, the caller's variable changes too.  Sometimes that is
'   exactly what you want (a Swap routine), sometimes it is a nasty
'   surprise.
'   To pass BY VALUE (a copy) in QBasic you can:
'     a) wrap the argument in parentheses:   Twice (x)
'     b) pass an expression:                 Twice x + 0
'     c) copy the parameter into a local inside the SUB.
'   (QBasic's BYVAL keyword only works for routines written in other
'    languages, so these tricks are the BASIC way.)
'
' HOW TO USE
'   Just run it.  Each experiment prints the variable before and
'   after the call.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK DOUBLE.  Look at n in the Variables panel,
'      then click the main-program frame in the CALL STACK and look
'      at x.  Step once: BOTH change together - they are the same
'      memory, two names.
'   2. Continue to the second call  Twice (x) .  Now when n changes,
'      x in the main frame stays the same: n is a temporary copy.
'   3. Break on <<< BREAK SWAP and watch a and b in the main frame
'      as SwapInts runs.  By-reference is what makes Swap possible.
'   4. In the CountDigits experiment, WATCH num.  The buggy version
'      destroys it - classic side-effect bug.
'
' CONCEPTS YOU WILL LEARN
'   * Passing by reference (QBasic default) vs by value
'   * Side effects and why they cause bugs
'   * Using parentheses or a local copy to protect the caller
'   * "Parameter type mismatch": by-reference needs matching types
'
' THINGS TO TRY
'   * Call  Twice 5  (a constant).  Why is that allowed?
'   * Pass an array element: Twice arr(3).  Does arr(3) change?
' ============================================================
DECLARE SUB Twice (n AS INTEGER)
    ' (It cannot be called "Double": DOUBLE is a QBasic keyword.)
DECLARE SUB SwapInts (p AS INTEGER, q AS INTEGER)
DECLARE FUNCTION DigitsBuggy% (n AS LONG)
DECLARE FUNCTION DigitsSafe% (n AS LONG)

DIM x AS INTEGER, a AS INTEGER, b AS INTEGER, num AS LONG

CLS
PRINT "BY REFERENCE vs BY VALUE"
PRINT

PRINT "1) Twice x        (by reference)"
x = 7
PRINT "     before: x ="; x
Twice x
PRINT "     after:  x ="; x; " <- the SUB changed MY variable"
PRINT

PRINT "2) Twice (x)      (parentheses = pass a copy)"
x = 7
Twice (x)
PRINT "     after:  x ="; x; " <- unchanged"
PRINT

PRINT "3) Twice x + 0    (an expression is always a copy)"
x = 7
Twice x + 0
PRINT "     after:  x ="; x; " <- unchanged"
PRINT

PRINT "4) SwapInts a, b   (by reference is USEFUL here)"
a = 1: b = 2
SwapInts a, b
PRINT "     a ="; a; "  b ="; b
PRINT

PRINT "5) A FUNCTION with a side effect"
num = 90210
PRINT "     DigitsBuggy(num) ="; DigitsBuggy%(num); "  but now num ="; num
num = 90210
PRINT "     DigitsSafe(num)  ="; DigitsSafe%(num); "  and num ="; num
END

SUB Twice (n AS INTEGER)
    ' (It cannot be called "Double": DOUBLE is a QBasic keyword.)
    n = n * 2                        ' <<< BREAK DOUBLE
    PRINT "     inside Twice: n ="; n
END SUB

SUB SwapInts (p AS INTEGER, q AS INTEGER)
    DIM t AS INTEGER
    t = p                            ' <<< BREAK SWAP
    p = q
    q = t
END SUB

' Counts digits by chopping n down... but n IS the caller's variable!
FUNCTION DigitsBuggy% (n AS LONG)
    DIM c AS INTEGER
    DO
        c = c + 1
        n = n \ 10                   ' destroys the caller's num
    LOOP WHILE n > 0
    DigitsBuggy% = c
END FUNCTION

' Same algorithm, but works on a LOCAL copy.
FUNCTION DigitsSafe% (n AS LONG)
    DIM c AS INTEGER, work AS LONG
    work = n                         ' private copy; n is never changed
    DO
        c = c + 1
        work = work \ 10
    LOOP WHILE work > 0
    DigitsSafe% = c
END FUNCTION
