' ============================================================
' TITLE:    Spirograph Studio
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     generative art, trigonometry, gcd, parametric curves, SCREEN 12
' SUMMARY:  Simulates the classic toy: a small gear rolling inside a big ring traces looping flower patterns.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Spirograph has a big ring with teeth on the inside (radius R)
'   and a small wheel (radius r) that rolls around inside it.  A pen
'   in a hole of the wheel, d away from the wheel's centre, draws the
'   pattern.  The math curve is called a "hypotrochoid":
'       x = (R - r) * COS(t) + d * COS((R - r) / r * t)
'       y = (R - r) * SIN(t) - d * SIN((R - r) / r * t)
'   The pattern closes up after the wheel has gone around the ring
'   r / GCD(R, r) times, so we use the Greatest Common Divisor to
'   know when to stop.
'
'   Each picture layers 3 random curves in different colors.
'
' HOW TO USE
'   Space = new random picture,  A = toggle animated drawing,
'   Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Parametric curves: x and y both computed from one variable t
'   * The GCD (Euclid's algorithm) and why the curve closes
'   * Drawing smooth curves by joining many short lines (LINE -)
'
' THINGS TO TRY
'   * Make d bigger than r (the pen outside the wheel!)
'   * Roll the wheel OUTSIDE the ring: use R + r instead of R - r
'     and change the minus to plus in the y formula (an epitrochoid)
'   * Use a negative r
' ============================================================
DECLARE FUNCTION Gcd% (a%, b%)

CONST PI = 3.14159265#
SCREEN 12
RANDOMIZE TIMER
animate% = -1

DO
    CLS
    COLOR 15: PRINT "Spirograph";
    FOR layer% = 1 TO 3
        ' Random gear sizes (whole numbers, like teeth on a real gear).
        bigR% = 96 + INT(RND * 6) * 16              ' ring: 96..176
        ' Pick a wheel size that closes after 3 to 16 laps: too few
        ' laps is boring, too many turns into a solid blob.
        DO
            smallR% = 20 + INT(RND * (bigR% - 30))  ' wheel: smaller
            laps% = smallR% \ Gcd%(bigR%, smallR%)
        LOOP UNTIL laps% >= 3 AND laps% <= 16
        d! = smallR% * (.4 + RND * .9)              ' pen distance
        c% = 9 + INT(RND * 7)                       ' color 9..15
        ' laps (computed above) = trips around the ring before the
        ' curve closes: the wheel must roll a whole number of its own
        ' turns AND the ring's, which first happens after r / GCD laps.
        LOCATE 1 + layer%, 1: COLOR c%
        PRINT USING "R=### r=### d=###  laps=##"; bigR%; smallR%; d!; laps%
        ' Scale so the biggest possible size fits 220 pixels.
        sc! = 220 / (bigR% - smallR% + d!)
        k! = (bigR% - smallR%) / smallR%            ' wheel spin ratio
        steps& = laps% * 200&     ' 200 lines per lap (LONG: can pass 32767)
        FOR i& = 0 TO steps&
            t! = i& / 200 * 2 * PI
            x! = (bigR% - smallR%) * COS(t!) + d! * COS(k! * t!)
            y! = (bigR% - smallR%) * SIN(t!) - d! * SIN(k! * t!)
            sx! = 320 + x! * sc!: sy! = 250 + y! * sc!
            IF i& = 0 THEN PSET (sx!, sy!), c% ELSE LINE -(sx!, sy!), c%
            ' Every 40 lines wait for the screen's vertical retrace
            ' (bit 3 of port &H3DA): about 1/70 of a second, so you
            ' can watch the pen move.
            IF animate% AND i& MOD 40 = 0 THEN
                DO WHILE INP(&H3DA) AND 8: LOOP
                DO UNTIL INP(&H3DA) AND 8: LOOP
            END IF
            k$ = INKEY$
            IF k$ <> "" THEN EXIT FOR
        NEXT
        IF k$ <> "" THEN EXIT FOR
    NEXT
    IF k$ = "" THEN
        LOCATE 30, 1: COLOR 7: PRINT "Space = new   A = animation on/off   Esc = quit";
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    END IF
    IF UCASE$(k$) = "A" THEN animate% = NOT animate%
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Euclid's algorithm: GCD(a, b) = GCD(b, a MOD b), and GCD(a, 0) = a.
FUNCTION Gcd% (a%, b%)
    x% = a%: y% = b%            ' copies, so the caller's values stay safe
    DO WHILE y% <> 0
        t% = x% MOD y%
        x% = y%: y% = t%
    LOOP
    Gcd% = x%
END FUNCTION
