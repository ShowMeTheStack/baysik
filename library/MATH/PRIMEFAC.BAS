' ============================================================
' TITLE:    Prime Factorizer
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     primes, factors, division, loops
' SUMMARY:  Breaks any whole number into its prime factors, like 360 = 2^3 x 3^2 x 5.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every whole number bigger than 1 can be written as a product of
'   prime numbers in exactly one way (the "Fundamental Theorem of
'   Arithmetic").  This program finds that product by "trial
'   division": it keeps dividing by the smallest number that goes in
'   evenly until nothing is left.  It also tells you how many
'   divisors the number has, using the exponents it found.
'
' HOW TO USE
'   Type a whole number (2 to 999,999,999) and press Enter.
'   Type 0 (or just press Enter) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Trial division and why we only test up to the square root
'   * MOD (remainder) and integer division with \
'   * Building an output string piece by piece
'   * Counting divisors from prime exponents
'
' THINGS TO TRY
'   * Factor 2^31 - 1 = 2147483647 (it is prime!) - how long does it take?
'   * Print the factor tree as a list of steps instead of a summary
'   * Find the number below 1000 with the most divisors
' ============================================================

DEFDBL A-Z              ' use double precision so big numbers stay exact

CLS
COLOR 14
PRINT "PRIME FACTORIZER"
COLOR 7
PRINT "Every number > 1 is a product of primes in exactly one way."
PRINT

DO
    INPUT "Number to factor (0 = quit)"; n
    n = INT(ABS(n))                 ' ignore signs and fractions
    IF n = 0 THEN EXIT DO
    IF n = 1 THEN
        PRINT "1 has no prime factors (it is neither prime nor composite)."
    ELSEIF n > 999999999 THEN
        PRINT "Please keep it below one billion."
    ELSE
        GOSUB Factor
    END IF
    PRINT
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' Factor: works on a copy of n called m.
' We try divisors d = 2, 3, 5, 7, 9, 11 ... (2 and then odd numbers).
' Every time d divides m evenly, d must be prime -- any smaller
' factors of d would already have been removed from m earlier.
' ------------------------------------------------------------
Factor:
    m = n
    result$ = ""
    divisors = 1                    ' running product of (exponent + 1)
    d = 2
    ' We only need d*d <= m.  If m had a factor bigger than its square
    ' root, it would also have one smaller than the square root, which
    ' we would already have found.
    DO WHILE d * d <= m
        e = 0                       ' exponent: how many times d divides m
        ' Using m - INT(m/d)*d instead of MOD keeps it exact for big DOUBLEs
        DO WHILE m - INT(m / d) * d = 0
            m = m / d
            e = e + 1
        LOOP
        IF e > 0 THEN
            IF result$ <> "" THEN result$ = result$ + " x "
            result$ = result$ + LTRIM$(STR$(d))
            IF e > 1 THEN result$ = result$ + "^" + LTRIM$(STR$(e))
            divisors = divisors * (e + 1)
        END IF
        IF d = 2 THEN d = 3 ELSE d = d + 2   ' after 2 only odd numbers
    LOOP
    ' Whatever is left over (if > 1) must itself be a prime.
    IF m > 1 THEN
        IF result$ <> "" THEN result$ = result$ + " x "
        result$ = result$ + LTRIM$(STR$(m))
        divisors = divisors * 2
    END IF

    COLOR 11
    PRINT LTRIM$(STR$(n)); " = "; result$
    COLOR 7
    IF divisors = 2 THEN
        PRINT "  -> "; LTRIM$(STR$(n)); " is PRIME."
    ELSE
        ' If n = p^a * q^b * ..., every divisor picks an exponent 0..a
        ' for p, 0..b for q, etc. so there are (a+1)(b+1)... of them.
        PRINT "  -> it has"; divisors; "divisors (including 1 and itself)."
    END IF
    RETURN
