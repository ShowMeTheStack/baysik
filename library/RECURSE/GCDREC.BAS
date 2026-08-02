' ============================================================
' TITLE:    Euclid's GCD, Recursively
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, gcd, lcm, euclid, tail recursion
' SUMMARY:  A 2300-year-old algorithm in three lines of recursion, plus LCM and fraction reducing built on top of it.
' ------------------------------------------------------------
' WHAT IT DOES
'   The greatest common divisor (GCD) of two numbers is the largest
'   number that divides both.  Euclid noticed that
'        GCD(a, b) = GCD(b, a MOD b)     and     GCD(a, 0) = a
'   The program shows every step, then uses GCD to compute the
'   least common multiple and to reduce a fraction.
'
' HOW TO USE
'   Enter two positive whole numbers.  Enter 0 to quit.
'
'   DEBUGGER TOUR
'   1. Put a breakpoint on <<< BREAK in FUNCTION Gcd.
'   2. Enter 1071 and 462.  Each stop shows a new (a, b) pair:
'      (1071,462) (462,147) (147,21) (21,0).
'   3. Notice: the recursive call is the LAST thing Gcd does.  On the
'      way back up, every frame just passes the answer through
'      unchanged.  This is called TAIL RECURSION - it could be
'      rewritten as a simple loop (see GcdLoop).
'   4. Try STEP OUT from the deepest frame: the answer 21 pops up
'      through all the frames without being changed.
'
' CONCEPTS YOU WILL LEARN
'   * Euclid's algorithm and the MOD operator
'   * Tail recursion and how it turns into a loop
'   * Reusing a function to build others (LCM, fraction reduce)
'
' THINGS TO TRY
'   * Use two consecutive Fibonacci numbers like 89 and 55.  They
'     need the MOST steps for their size.  Why?
'   * Extend Gcd to work with three numbers: GCD(a, GCD(b, c)).
' ============================================================
DECLARE FUNCTION Gcd& (a AS LONG, b AS LONG, depth AS INTEGER)
DECLARE FUNCTION GcdLoop& (a AS LONG, b AS LONG)

CLS
PRINT "EUCLID'S GREATEST COMMON DIVISOR"
PRINT
DO
    INPUT "First number  (0 quits)"; x&
    IF x& <= 0 THEN EXIT DO
    INPUT "Second number (0 quits)"; y&
    IF y& <= 0 THEN EXIT DO

    PRINT "Steps:"
    g& = Gcd&(x&, y&, 1)
    PRINT "GCD ="; g&; "   (loop version agrees:"; GcdLoop&(x&, y&); ")"

    ' LCM: a*b = GCD * LCM, so LCM = a / GCD * b
    ' (divide FIRST so the number stays small and does not overflow.
    '  The parentheses matter: in QBasic * binds tighter than \, so
    '  x \ g * y would mean x \ (g * y) - a classic precedence bug!)
    PRINT "LCM ="; (x& \ g&) * y&

    ' Reduce the fraction x/y by dividing top and bottom by the GCD.
    PRINT "Fraction"; x&; "/"; y&; " reduces to"; x& \ g&; "/"; y& \ g&
    PRINT
LOOP
PRINT "Bye!"
END

FUNCTION Gcd& (a AS LONG, b AS LONG, depth AS INTEGER)
    ' depth is only here so we can indent the printout nicely.
    PRINT SPACE$(depth * 2); "Gcd("; LTRIM$(STR$(a)); ", "; LTRIM$(STR$(b)); ")"
    IF b = 0 THEN                       ' <<< BREAK
        Gcd& = a                        ' base case
    ELSE
        Gcd& = Gcd&(b, a MOD b, depth + 1)   ' tail call
    END IF
END FUNCTION

FUNCTION GcdLoop& (a AS LONG, b AS LONG)
    ' Same algorithm, with the tail call replaced by "update and loop".
    ' We copy into locals so the caller's variables are not changed
    ' (parameters are passed BY REFERENCE in QBasic!).
    DIM x AS LONG, y AS LONG, t AS LONG
    x = a: y = b
    DO WHILE y <> 0
        t = x MOD y
        x = y
        y = t
    LOOP
    GcdLoop& = x
END FUNCTION
