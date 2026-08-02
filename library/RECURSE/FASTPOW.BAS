' ============================================================
' TITLE:    Fast Exponentiation
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, power, divide and conquer, multiplication count
' SUMMARY:  Raise a number to a power with far fewer multiplications by halving the exponent each recursive call.
' ------------------------------------------------------------
' WHAT IT DOES
'   To compute 3^13 the slow way you multiply 3 by itself 12 times.
'   The fast way uses two facts:
'       x^n = (x^(n/2))^2            when n is even
'       x^n = x * x^(n-1)            when n is odd
'   Each step at least halves the exponent, so 3^1000 needs only
'   about 15 multiplications instead of 999!
'   The program compares the slow and fast methods and counts the
'   multiplications each one uses.
'
' HOW TO USE
'   Enter a base and an exponent.  Exponent 0 or less quits.
'
'   DEBUGGER TOUR
'   1. Break on the line marked <<< BREAK in FastPow.
'   2. Enter base 2, exponent 13.  At each stop look at e in the
'      Variables panel: 13, 12, 6, 3, 2, 1, 0.  It shrinks FAST.
'   3. Look at the CALL STACK when e = 0: only 7 frames deep.
'      Compare with SlowPow which needs 13 loop trips.
'   4. Step Out of each frame and watch "half" get squared on the
'      way back up.  Edit half in the Variables panel while paused
'      to see how a wrong value spreads up through every frame.
'
' CONCEPTS YOU WILL LEARN
'   * Divide and conquer: solve half the problem, reuse the answer
'   * Why storing a result in a local (half) matters: calling
'     FastPow twice instead would throw away all the speed-up
'   * Logarithmic recursion depth
'
' THINGS TO TRY
'   * Replace  half * half  with  FastPow(b, e \ 2) * FastPow(b, e \ 2)
'     and watch the multiplication counter explode.
'   * Add a MOD m to every multiply to compute (b^e) MOD m: the basis
'     of RSA encryption.
' ============================================================
DECLARE FUNCTION FastPow# (b AS DOUBLE, e AS LONG)
DECLARE FUNCTION SlowPow# (b AS DOUBLE, e AS LONG)

DIM SHARED mults AS LONG          ' multiplication counter

CLS
PRINT "FAST EXPONENTIATION (exponentiation by squaring)"
PRINT
DO
    INPUT "Base (e.g. 2 or 1.01)"; b#
    INPUT "Exponent (whole number, 0 to quit)"; e&
    IF e& <= 0 THEN EXIT DO
    IF e& > 2000 THEN e& = 2000: PRINT "(exponent limited to 2000)"

    mults = 0
    s# = SlowPow#(b#, e&)
    slowCount& = mults

    mults = 0
    f# = FastPow#(b#, e&)
    fastCount& = mults

    PRINT "  Slow:"; s#; " using"; slowCount&; "multiplications"
    PRINT "  Fast:"; f#; " using"; fastCount&; "multiplications"
    PRINT
LOOP
PRINT "Bye!"
END

' ------------------------------------------------------------
' SlowPow - multiply b into the total e times.
' ------------------------------------------------------------
FUNCTION SlowPow# (b AS DOUBLE, e AS LONG)
    DIM t AS DOUBLE, i AS LONG
    t = 1
    FOR i = 1 TO e
        t = t * b
        mults = mults + 1
    NEXT i
    SlowPow# = t
END FUNCTION

' ------------------------------------------------------------
' FastPow - recursive squaring.
' ------------------------------------------------------------
FUNCTION FastPow# (b AS DOUBLE, e AS LONG)
    DIM half AS DOUBLE
    IF e = 0 THEN                       ' <<< BREAK (watch e shrink)
        FastPow# = 1                    ' base case: anything^0 = 1
    ELSEIF e MOD 2 = 0 THEN
        ' EVEN: compute b^(e/2) ONCE, keep it in a local, square it.
        half = FastPow#(b, e \ 2)
        mults = mults + 1
        FastPow# = half * half
    ELSE
        ' ODD: peel off one factor of b so the rest is even.
        mults = mults + 1
        FastPow# = b * FastPow#(b, e - 1)
    END IF
END FUNCTION
