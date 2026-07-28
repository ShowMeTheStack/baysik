' ============================================================
' TITLE:    Euclid's GCD and LCM
' CATEGORY: Algorithms
' LEVEL:    Beginner
' TAGS:     math, gcd, lcm, recursion, number theory
' SUMMARY:  The oldest algorithm still in daily use: find greatest common divisors step by step, then LCMs and simplified fractions.
' ------------------------------------------------------------
' WHAT IT DOES
'   You type two whole numbers.  The program runs Euclid's algorithm
'   and prints every step in the form  a = q x b + r,  then gives:
'     * the GCD (greatest common divisor)
'     * the LCM (least common multiple)
'     * the fraction a/b in lowest terms
'     * how many steps the slow "subtract only" method would need
'   It also computes the GCD a second time with a RECURSIVE FUNCTION
'   to show that both versions agree.
'
' HOW TO USE
'   Enter the first number and the second number.  Enter 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Euclid's key fact: gcd(a, b) = gcd(b, a MOD b)
'   * Loops vs. recursion for the same algorithm
'   * LCM from GCD: lcm(a, b) = a / gcd(a, b) * b
'   * Why Euclid is fast: O(log(min(a, b))) steps
'   * LONG integers (the & suffix) for big values
'
' THINGS TO TRY
'   * Try two neighbouring Fibonacci numbers like 832040 and 514229:
'     they are the slowest possible input for Euclid
'   * Find the GCD of three numbers: gcd(gcd(a, b), c)
' ============================================================
DECLARE FUNCTION GcdRec& (a&, b&)
DEFINT A-Z
COLOR 7, 0: CLS
COLOR 15: PRINT "EUCLID'S ALGORITHM": COLOR 7
PRINT "Enter 0 to quit."
DO
    PRINT
    LINE INPUT "First number:  "; s$: a& = ABS(VAL(s$))
    IF a& = 0 THEN EXIT DO
    LINE INPUT "Second number: "; s$: b& = ABS(VAL(s$))
    IF b& = 0 THEN EXIT DO
    IF a& > 2000000000 OR b& > 2000000000 THEN
        PRINT "Please keep the numbers below 2 billion."
    ELSE
        ' ---- Euclid, iterative version ---------------------------
        ' Why does it work?  Any number d that divides both a and b
        ' also divides a - q*b = r (the remainder).  And anything that
        ' divides b and r also divides a = q*b + r.  So the pairs
        ' (a, b) and (b, r) have exactly the SAME common divisors -
        ' including the greatest one.  The numbers shrink quickly, and
        ' when the remainder hits 0, the last divisor is the GCD.
        x& = a&: y& = b&: steps = 0
        DO WHILE y& <> 0
            q& = x& \ y&
            r& = x& MOD y&
            steps = steps + 1
            PRINT USING "  ########## = ########## x ########## + ##########"; x&; q&; y&; r&
            x& = y&                ' (a, b) becomes (b, r)
            y& = r&
        LOOP
        g& = x&
        COLOR 14: PRINT "  GCD ="; g&; "  found in"; steps; "steps": COLOR 7

        ' ---- Recursive version, as a cross-check ----------------
        IF GcdRec&(a&, b&) <> g& THEN PRINT "  (recursive version disagrees?!)"

        ' ---- LCM ------------------------------------------------
        ' a * b = gcd * lcm.  Divide FIRST to keep the numbers small,
        ' otherwise a * b could overflow even a LONG.
        l# = (a& \ g&) * CDBL(b&)
        PRINT "  LCM ="; l#
        PRINT "  Fraction"; a&; "/"; b&; "="; a& \ g&; "/"; b& \ g&

        ' ---- The slow way: repeated subtraction -----------------
        ' Euclid's original method subtracted the smaller number from
        ' the bigger one.  It gives the same answer, but for something
        ' like gcd(1000000, 1) it needs a million steps, while MOD
        ' needs only 1.  We just COUNT the subtractions with division.
        x& = a&: y& = b&: subs# = 0
        DO WHILE y& <> 0
            subs# = subs# + x& \ y&     ' that many subtractions happen
            r& = x& MOD y&: x& = y&: y& = r&
        LOOP
        PRINT "  The subtract-only method would need"; subs#; "subtractions."
    END IF
LOOP
PRINT "Goodbye!"
END

' Recursive GCD: the whole algorithm in one line of logic.
'   gcd(a, 0) = a                  (base case)
'   gcd(a, b) = gcd(b, a MOD b)    (recursive case)
' Each call at least halves the larger number every two steps, so
' the depth is at most about 2 * log2(b).
FUNCTION GcdRec& (a&, b&)
    IF b& = 0 THEN
        GcdRec& = a&
    ELSE
        GcdRec& = GcdRec&(b&, a& MOD b&)
    END IF
END FUNCTION
