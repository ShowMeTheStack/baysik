' ============================================================
' TITLE:    Diffie-Hellman Key Exchange (Toy Numbers)
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     diffie-hellman, modular exponentiation, discrete log, primes, public key
' SUMMARY:  Alice and Bob agree on a shared secret over a public channel while Eve listens - then Eve tries to crack it.
' ------------------------------------------------------------
' WHAT IT DOES
'   For thousands of years every cipher had the same problem: the two
'   people needed to meet (or trust a courier) to share a key first.
'   In 1976 Whitfield Diffie and Martin Hellman published a way to
'   agree on a secret key while ENEMIES READ EVERY MESSAGE.  (Malcolm
'   Williamson at Britain's GCHQ had found it secretly in 1974.)
'
'   THE RECIPE
'     Public:  a prime number p and a "generator" g.
'     Alice picks a secret a and sends  A = g^a MOD p
'     Bob   picks a secret b and sends  B = g^b MOD p
'     Alice computes  B^a MOD p = g^(b*a) MOD p
'     Bob   computes  A^b MOD p = g^(a*b) MOD p   <- the SAME number!
'
'   Eve sees p, g, A and B.  To get the secret she must find a from
'   A = g^a MOD p - the "discrete logarithm problem".  For our tiny
'   primes she can just try every a.  For the 600-digit primes used
'   by real web browsers, all the computers on Earth would need far
'   longer than the age of the universe.
'
'   PAINT ANALOGY: mixing paint is easy, un-mixing is impossible.
'   Both start with yellow, each adds a secret colour, they swap
'   mixtures and add their secret again: both end with the same
'   brown, but Eve only ever saw the two half-mixed pots.
'
' HOW TO USE
'   Enter a prime p (Enter = 2087) and the program finds a
'   generator g, invents secrets for Alice and Bob, and shows every
'   step.  Then Eve brute-forces the secret and we count her tries.
'   Primes must be between 11 and 46337 so the math fits in LONG.
'   Enter Q at the prime prompt to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Fast modular exponentiation (square-and-multiply)
'   * Why we keep numbers below 46341 (46341^2 > 2^31)
'   * Primitive roots (generators) and the order of an element
'   * One-way functions: easy forwards, hard backwards
'
' THINGS TO TRY
'   * Use a non-generator g (e.g. one with small order) - fewer keys!
'   * Time Eve's search for p near 100, 1000, 10000, 40000
'   * Look up the "man in the middle" attack - DH needs authentication
' ============================================================

DECLARE FUNCTION PowMod& (b&, e&, m&)
DECLARE FUNCTION IsPrime% (n&)
DECLARE FUNCTION FindGenerator& (p&)

RANDOMIZE TIMER
DO
    CLS
    COLOR 14: PRINT "DIFFIE-HELLMAN KEY EXCHANGE": COLOR 7
    PRINT
    LINE INPUT "Public prime p (Enter = 2087, Q = quit): "; t$
    IF UCASE$(t$) = "Q" THEN EXIT DO
    IF t$ = "" THEN p& = 2087 ELSE p& = VAL(t$)
    IF p& < 11 OR p& > 46337 OR IsPrime%(p&) = 0 THEN
        PRINT "That is not a prime between 11 and 46337.  Some primes: 23 101 997 2087 40009"
    ELSE
        g& = FindGenerator&(p&)
        ' Secrets: random numbers from 2 to p - 2.
        a& = 2 + INT(RND * (p& - 3))
        b& = 2 + INT(RND * (p& - 3))
        bigA& = PowMod&(g&, a&, p&)
        bigB& = PowMod&(g&, b&, p&)
        sA& = PowMod&(bigB&, a&, p&)
        sB& = PowMod&(bigA&, b&, p&)

        PRINT
        COLOR 11: PRINT "PUBLIC (everyone, including Eve, sees these)": COLOR 7
        PRINT "  prime p ="; p&; "   generator g ="; g&
        PRINT
        COLOR 13: PRINT "  ALICE": COLOR 7
        PRINT "    secret a ="; a&; "  (never sent)"
        PRINT "    sends A = g^a MOD p = "; LTRIM$(STR$(g&)); "^"; LTRIM$(STR$(a&)); " MOD"; p&; "="; bigA&
        COLOR 10: PRINT "  BOB": COLOR 7
        PRINT "    secret b ="; b&; "  (never sent)"
        PRINT "    sends B = g^b MOD p = "; LTRIM$(STR$(g&)); "^"; LTRIM$(STR$(b&)); " MOD"; p&; "="; bigB&
        PRINT
        PRINT "  Alice computes B^a MOD p ="; sA&
        PRINT "  Bob   computes A^b MOD p ="; sB&
        IF sA& = sB& THEN
            COLOR 14: PRINT "  -> SHARED SECRET ="; sA&; " (both got the same number!)"
        END IF
        COLOR 7
        PRINT
        PRINT "Press a key to let Eve attack...";
        k$ = INPUT$(1)
        IF k$ = CHR$(27) THEN EXIT DO
        PRINT
        PRINT
        COLOR 12: PRINT "EVE's ATTACK: try x = 1, 2, 3 ... until g^x MOD p = A": COLOR 7
        ' Instead of calling PowMod for every x, keep a running power
        ' and multiply by g each step: one multiplication per try.
        v& = 1: tries& = 0
        FOR x& = 1 TO p& - 1
            v& = (v& * g&) MOD p&
            tries& = tries& + 1
            IF v& = bigA& THEN EXIT FOR
        NEXT x&
        PRINT "  Eve found x ="; x&; "after"; tries&; "tries."
        PRINT "  (x may differ from a, but g^x = g^a, so it works just as well.)"
        PRINT "  Eve's secret = B^x MOD p ="; PowMod&(bigB&, x&, p&)
        PRINT
        PRINT "  With a real 2048-bit prime there are about 10^616 values to try."
        PRINT "  At a billion billion tries per second that would still take"
        PRINT "  10^590 years.  That is why the internet can keep secrets."
    END IF
    PRINT
    PRINT "Press any key...";
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN EXIT DO
LOOP
CLS
END

' ------------------------------------------------------------
' PowMod&: compute b^e MOD m without ever making a huge number.
' SQUARE-AND-MULTIPLY: look at the bits of e from the lowest up.
'   result starts at 1, base starts at b.
'   If the current bit of e is 1, multiply result by base.
'   Square the base, move to the next bit (e \ 2).
' Example 3^13: 13 = 1101 in binary = 8 + 4 + 1, so
'   3^13 = 3^8 * 3^4 * 3^1 - only 4 squarings instead of 12 multiplies.
' Every product stays below m*m, which must fit in a LONG.
' ------------------------------------------------------------
FUNCTION PowMod& (b&, e&, m&)
    result& = 1
    base1& = b& MOD m&
    ex& = e&
    DO WHILE ex& > 0
        IF ex& MOD 2 = 1 THEN result& = (result& * base1&) MOD m&
        base1& = (base1& * base1&) MOD m&
        ex& = ex& \ 2
    LOOP
    PowMod& = result&
END FUNCTION

' ------------------------------------------------------------
' IsPrime%: trial division by odd numbers up to the square root.
' ------------------------------------------------------------
FUNCTION IsPrime% (n&)
    IsPrime% = 0
    IF n& < 2 THEN EXIT FUNCTION
    IF n& MOD 2 = 0 THEN IsPrime% = (n& = 2) * -1: EXIT FUNCTION
    d& = 3
    DO WHILE d& * d& <= n&
        IF n& MOD d& = 0 THEN EXIT FUNCTION
        d& = d& + 2
    LOOP
    IsPrime% = 1
END FUNCTION

' ------------------------------------------------------------
' FindGenerator&: a generator g makes g^1, g^2 ... g^(p-1) hit
' every number 1..p-1, so Eve has the most values to search.
' Test: for every prime factor q of (p - 1), g^((p-1)/q) MOD p
' must NOT be 1.  We try g = 2, 3, 4 ... until one passes.
' ------------------------------------------------------------
FUNCTION FindGenerator& (p&)
    ' Collect the prime factors of p - 1.
    DIM f&(20)
    nf = 0: n& = p& - 1: d& = 2
    DO WHILE d& * d& <= n&
        IF n& MOD d& = 0 THEN
            nf = nf + 1: f&(nf) = d&
            DO WHILE n& MOD d& = 0: n& = n& \ d&: LOOP
        END IF
        d& = d& + 1
    LOOP
    IF n& > 1 THEN nf = nf + 1: f&(nf) = n&
    FOR g& = 2 TO p& - 1
        good = 1
        FOR i = 1 TO nf
            IF PowMod&(g&, (p& - 1) \ f&(i), p&) = 1 THEN good = 0: EXIT FOR
        NEXT i
        IF good THEN FindGenerator& = g&: EXIT FUNCTION
    NEXT g&
    FindGenerator& = 2
END FUNCTION
