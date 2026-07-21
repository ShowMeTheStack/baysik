' ============================================================
' TITLE:    Newton's Method Square Roots
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     newton-raphson, iteration, square roots, convergence
' SUMMARY:  Computes square and cube roots by guess-and-improve, showing correct digits double each step.
' ------------------------------------------------------------
' WHAT IT DOES
'   How does a calculator find SQR(2)?  One classic way is Newton's
'   method (also known to the Babylonians 4000 years ago!):
'     1. Make a guess g.
'     2. If g is too big, N/g is too small (and vice versa), so the
'        average of the two is a better guess:  g = (g + N/g) / 2
'     3. Repeat.
'   In general, to solve f(x) = 0, Newton slides down the tangent
'   line:  x_new = x - f(x) / f'(x).  For f(x) = x^2 - N that gives
'   exactly the averaging rule above.  For cube roots, f(x) = x^3 - N
'   gives  x_new = (2x + N/x^2) / 3.
'   The table shows the error shrinking: the number of correct
'   digits roughly DOUBLES every step ("quadratic convergence").
'
' HOW TO USE
'   Enter a positive number.  Enter 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Iteration: repeat a rule until the answer stops changing
'   * Derivatives as slopes of tangent lines
'   * Measuring convergence with the error and LOG
'
' THINGS TO TRY
'   * Start with a terrible guess like 1000000 - it still works
'   * Change the rule to find 4th roots: x = (3x + N/x^3) / 4
'   * Use Newton to solve COS(x) = x
' ============================================================

DEFDBL A-Z

CLS
COLOR 14: PRINT "NEWTON'S METHOD:  ROOTS BY GUESS-AND-IMPROVE": COLOR 7
PRINT

DO
    INPUT "Find the roots of (0 = quit)"; n
    IF n = 0 THEN EXIT DO
    IF n < 0 THEN PRINT "Please enter a positive number.": PRINT : GOTO Again

    ' ---------- square root ----------
    COLOR 11: PRINT "Square root:  g = (g + N/g) / 2": COLOR 7
    PRINT " step          guess                error     correct digits"
    g = n                           ' a deliberately simple first guess
    IF g < 1 THEN g = 1
    exact = SQR(n)
    FOR s = 0 TO 30
        errv = ABS(g - exact)
        PRINT USING " ##  #########.############### "; s; g;
        PRINT USING "  ##.##^^^^"; errv;
        ' digits correct ~ -LOG10(relative error).  LOG is natural log,
        ' so divide by LOG(10) to get base 10.
        IF errv > 0 THEN
            PRINT USING "     ##.#"; -LOG(errv / exact) / LOG(10)
        ELSE
            PRINT "     all"
        END IF
        newg = (g + n / g) / 2
        IF newg = g OR errv = 0 THEN EXIT FOR    ' stopped changing: done
        g = newg
    NEXT s

    ' ---------- cube root ----------
    COLOR 11: PRINT "Cube root:  x = (2x + N/x^2) / 3": COLOR 7
    x = n
    IF x < 1 THEN x = 1
    FOR s = 0 TO 60
        nx = (2 * x + n / (x * x)) / 3
        IF ABS(nx - x) <= 1E-15 * x THEN EXIT FOR
        x = nx
    NEXT s
    PRINT "After"; s; "steps:"; nx; "   check: x^3 ="; nx * nx * nx
    PRINT
Again:
LOOP
PRINT "Bye!"
