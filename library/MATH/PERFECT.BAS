' ============================================================
' TITLE:    Perfect & Amicable Numbers
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     divisors, number theory, arrays, sieve
' SUMMARY:  Hunts for perfect, abundant, deficient and amicable numbers using a divisor-sum sieve.
' ------------------------------------------------------------
' WHAT IT DOES
'   The "proper divisors" of a number are the divisors smaller than
'   it.  For 6 they are 1, 2, 3 and 1+2+3 = 6, so 6 is PERFECT.
'   If the sum is bigger the number is ABUNDANT (12: 1+2+3+4+6=16),
'   if smaller it is DEFICIENT (8: 1+2+4=7).
'   Two numbers are AMICABLE ("friendly") if each one's divisor sum
'   equals the other: 220 -> 284 and 284 -> 220.  The ancient Greeks
'   knew this pair; the program finds all pairs up to a limit.
'
' HOW TO USE
'   Just run it.  It builds a table of divisor sums up to 20000,
'   then prints what it finds.  Press any key at the end.
'
' CONCEPTS YOU WILL LEARN
'   * A "sieve" that adds each divisor to all of its multiples
'   * Why that is far faster than testing every number separately
'   * Classifying numbers with SELECT CASE
'
' THINGS TO TRY
'   * Raise LIMIT (watch memory and time) - the next perfect number is 33550336
'   * Look for "sociable" chains: a -> b -> c -> ... -> a
'   * Count how many abundant numbers are odd (the first is 945!)
' ============================================================

CONST LIMIT = 20000
DIM s(LIMIT) AS LONG            ' s(n) will hold the sum of proper divisors of n

CLS
COLOR 14: PRINT "PERFECT & AMICABLE NUMBERS up to"; LIMIT: COLOR 7
PRINT "Building divisor sums..."

' ------------------------------------------------------------
' The sieve.  Instead of asking "what divides n?" for every n,
' we turn it around: for each d, add d to every multiple of d
' (2d, 3d, 4d ...).  d is then a proper divisor of each of those.
' Total work is about LIMIT * (1 + 1/2 + 1/3 + ...) = LIMIT * ln(LIMIT),
' much less than LIMIT * LIMIT.
' ------------------------------------------------------------
FOR d = 1 TO LIMIT \ 2
    FOR m = 2 * d TO LIMIT STEP d
        s(m) = s(m) + d
    NEXT m
NEXT d

' Count each kind of number.
FOR n = 2 TO LIMIT
    SELECT CASE s(n)
        CASE IS < n: deficient = deficient + 1
        CASE n: perfect = perfect + 1
        CASE ELSE: abundant = abundant + 1
    END SELECT
NEXT n

PRINT
PRINT "Deficient:"; deficient; "  Perfect:"; perfect; "  Abundant:"; abundant
PRINT

COLOR 11: PRINT "Perfect numbers:": COLOR 7
FOR n = 2 TO LIMIT
    IF s(n) = n THEN
        ' Show the divisors so you can check the sum yourself.
        PRINT USING "#####  = "; n;
        first = 1
        FOR d = 1 TO n \ 2
            IF n MOD d = 0 THEN
                IF first = 0 THEN PRINT "+";
                PRINT LTRIM$(STR$(d));
                first = 0
            END IF
        NEXT d
        PRINT
    END IF
NEXT n
PRINT "(Euclid: if 2^p - 1 is prime then 2^(p-1) * (2^p - 1) is perfect.)"
PRINT

COLOR 11: PRINT "Amicable pairs:": COLOR 7
FOR a = 2 TO LIMIT
    b = s(a)
    ' b > a stops us printing each pair twice (and skips perfect numbers,
    ' which are "friends with themselves").
    IF b > a AND b <= LIMIT THEN
        IF s(b) = a THEN
            PRINT USING "  #####  and  #####"; a; b
        END IF
    END IF
NEXT a

COLOR 11: PRINT "First 10 abundant numbers:";: COLOR 7
c = 0
FOR n = 2 TO LIMIT
    IF s(n) > n THEN PRINT n;: c = c + 1
    IF c = 10 THEN EXIT FOR
NEXT n
PRINT
PRINT "Press any key...";
k$ = INPUT$(1)
