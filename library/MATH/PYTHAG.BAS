' ============================================================
' TITLE:    Pythagorean Triples
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     pythagoras, triples, euclid's formula, gcd, graphics
' SUMMARY:  Generates every right triangle with whole-number sides using Euclid's formula, then plots them.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pythagoras' theorem says a right triangle with legs a, b and
'   hypotenuse c obeys  a^2 + b^2 = c^2.  Usually c is not a whole
'   number, but sometimes it is: 3-4-5, 5-12-13, 8-15-17 ...
'   These are Pythagorean triples.  Euclid found a recipe for ALL of
'   them: pick whole numbers m > n > 0, then
'        a = m^2 - n^2      b = 2mn      c = m^2 + n^2
'   (check: (m^2-n^2)^2 + (2mn)^2 = (m^2+n^2)^2).  If m and n share no
'   common factor and one of them is even, the triple is "primitive"
'   (not just a bigger copy of a smaller one, like 6-8-10).
'   Part 2 plots every triple with legs a, b up to 1000 as a dot.
'   Surprising curved lines appear!
'
' HOW TO USE
'   Read the list, press a key for the plot, press a key to exit.
'
' CONCEPTS YOU WILL LEARN
'   * Algebraic identities and a formula that generates solutions
'   * GCD to test whether two numbers are "coprime"
'   * Multiples k*(a, b, c) giving the non-primitive triples
'
' THINGS TO TRY
'   * Brute force: test every a, b below 100 and compare the count
'   * Find triples where b = a + 1 (like 20-21-29)
'   * Which numbers can never be the hypotenuse of a primitive triple?
' ============================================================

DECLARE FUNCTION Gcd% (x%, y%)
DEFINT A-Z

CLS
COLOR 14: PRINT "PRIMITIVE PYTHAGOREAN TRIPLES with hypotenuse up to 100": COLOR 7
PRINT "  m  n     a    b    c     a^2 + b^2 = c^2"
cnt = 0
FOR c = 1 TO 100                   ' list them ordered by hypotenuse
    FOR m = 2 TO 10
        FOR n = 1 TO m - 1
            ' Primitive only if m, n coprime and of opposite parity.
            IF (m + n) MOD 2 = 1 AND Gcd%(m, n) = 1 THEN
                IF m * m + n * n = c THEN
                    a = m * m - n * n: b = 2 * m * n
                    IF a > b THEN SWAP a, b       ' smaller leg first
                    PRINT USING " ## ##  #### #### ####   "; m; n; a; b; c;
                    PRINT USING "#### + #### = ####"; a * a; b * b; c * c
                    cnt = cnt + 1
                END IF
            END IF
        NEXT n
    NEXT m
NEXT c
PRINT cnt; "primitive triples.  Multiply any of them by 2, 3, ... for more."
PRINT "Press a key to plot every triple with legs up to 1000..."
k$ = INPUT$(1)

' ---- Plot ----
SCREEN 12: CLS
' Map leg lengths 0..1000 to a 440 x 440 square of pixels.
x0 = 20: y0 = 460
LINE (x0, y0)-(x0 + 440, y0), 8: LINE (x0, y0)-(x0, y0 - 440), 8
total = 0
FOR m = 2 TO 32
    FOR n = 1 TO m - 1
        IF (m + n) MOD 2 = 1 AND Gcd%(m, n) = 1 THEN
            a = m * m - n * n: b = 2 * m * n: c = m * m + n * n
            ' every multiple k of the primitive triple
            k = 1
            DO WHILE k * a <= 1000 AND k * b <= 1000
                colr = 14: IF k > 1 THEN colr = 3   ' primitives in yellow
                ' plot both (a, b) and (b, a): the picture is symmetric
                PSET (x0 + k * a * .44, y0 - k * b * .44), colr
                PSET (x0 + k * b * .44, y0 - k * a * .44), colr
                total = total + 1
                k = k + 1
            LOOP
        END IF
    NEXT n
NEXT m
COLOR 15
LOCATE 2, 60: PRINT "Triples with legs"
LOCATE 3, 60: PRINT "up to 1000:"; total
COLOR 14: LOCATE 5, 60: PRINT "yellow = primitive"
COLOR 3: LOCATE 6, 60: PRINT "cyan = multiples"
COLOR 7
LOCATE 8, 60: PRINT "x axis = leg a"
LOCATE 9, 60: PRINT "y axis = leg b"
LOCATE 11, 60: PRINT "The dots line up"
LOCATE 12, 60: PRINT "along straight rays"
LOCATE 13, 60: PRINT "and faint curves."
LOCATE 29, 60: PRINT "Press a key";
k$ = INPUT$(1)
SCREEN 0: WIDTH 80

' Euclid's algorithm for the greatest common divisor.
FUNCTION Gcd% (x%, y%)
    a = x%: b = y%
    DO WHILE b <> 0
        t = a MOD b: a = b: b = t
    LOOP
    Gcd% = a
END FUNCTION
