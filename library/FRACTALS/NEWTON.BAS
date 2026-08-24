' ============================================================
' TITLE:    Newton's Method Fractal
' CATEGORY: Fractals & Generative Art
' LEVEL:    Advanced
' TAGS:     fractals, complex numbers, newton raphson, roots, palette
' SUMMARY:  Colors each point by which cube root of 1 Newton's method finds from it - revealing wild fractal borders.
' ------------------------------------------------------------
' WHAT IT DOES
'   Newton's method is a famous trick for solving equations: guess,
'   then improve the guess with  z = z - f(z) / f'(z)  again and
'   again.  For f(z) = z^3 - 1 there are three answers (roots) in the
'   complex plane: 1, and -0.5 +/- 0.866i.
'
'   We start Newton's method from every pixel and color the pixel by
'   WHICH root it ends up at (red, green or blue), and shade it by
'   HOW MANY steps that took.  You would expect three simple regions,
'   but the borders between them are infinitely detailed fractals!
'
' HOW TO USE
'   Watch it draw.  Then:  + zoom in, - zoom out, Esc quit.
'
' CONCEPTS YOU WILL LEARN
'   * Complex division done by hand with real numbers
'   * Newton-Raphson iteration and convergence
'   * Building three color ramps in one 256-color palette
'   * Why "nearby starting points can have very different futures"
'
' THINGS TO TRY
'   * Change f to z^4 - 1 (four roots - you will need a 4th color)
'   * Use a "relaxed" Newton step: z = z - 1.5 * f/f'
'   * Color only by step count and ignore which root was found
' ============================================================
DECLARE SUB Render (scale!)
DIM SHARED quit%
CONST MAXIT = 24

SCREEN 13
' ---- Palette: three ramps of 64 shades --------------------------
' colors  1..64  : red   family   (root 1)
' colors 65..128 : green family   (root 2)
' colors 129..192: blue  family   (root 3)
' A low shade number = found quickly = bright.
OUT &H3C8, 1
FOR root% = 0 TO 2
    FOR s% = 0 TO 63
        v% = 63 - s%                ' bright to dark
        w% = v% \ 3                 ' a little of the other colors
        SELECT CASE root%
            CASE 0: OUT &H3C9, v%: OUT &H3C9, w%: OUT &H3C9, w%
            CASE 1: OUT &H3C9, w%: OUT &H3C9, v%: OUT &H3C9, w%
            CASE 2: OUT &H3C9, w%: OUT &H3C9, w%: OUT &H3C9, v%
        END SELECT
    NEXT
NEXT

' Color 255 = white, for the help text.
OUT &H3C8, 255: OUT &H3C9, 63: OUT &H3C9, 63: OUT &H3C9, 63

scale! = 1.5                     ' half-width of the view in math units
DO
    Render scale!
    IF quit% THEN EXIT DO
    LOCATE 25, 1: COLOR 255: PRINT "+ zoom in   - zoom out   Esc quit";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "+", "=": scale! = scale! / 2
        CASE "-", "_": scale! = scale! * 2
        CASE CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0: WIDTH 80
END

SUB Render (scale!)
    CLS
    ' The three roots of z^3 = 1.
    CONST R3 = .8660254          ' SQR(3) / 2
    ' SYMMETRY SHORTCUT: z^3 - 1 has real coefficients, so the picture
    ' below the real axis is a mirror image of the picture above it,
    ' with the green and blue roots swapped.  We compute only the top
    ' half (rows 0..100) and draw every result twice.
    FOR py% = 0 TO 100 STEP 2
        FOR px% = 0 TO 319 STEP 2
            ' Map pixel -> complex number.  1.2 = aspect ratio fix
            ' because 320x200 pixels are not square on a 4:3 screen.
            zr! = (px% - 160) / 160 * scale!
            zi! = (py% - 100) / 160 * scale! * 1.2
            col% = 0
            FOR n% = 0 TO MAXIT - 1
                ' Newton step for f(z) = z^3 - 1, f'(z) = 3 z^2:
                '   z_new = z - (z^3 - 1) / (3 z^2)
                '         = (2/3) z + 1 / (3 z^2)
                ' First compute z^2 = (a + bi)^2 = (a^2 - b^2) + 2ab i
                ar! = zr! * zr! - zi! * zi!
                ai! = 2 * zr! * zi!
                d! = ar! * ar! + ai! * ai!        ' |z^2|^2
                IF d! < .000001 THEN EXIT FOR     ' too close to 0: give up
                ' 1 / (a + bi) = (a - bi) / (a^2 + b^2)
                zr! = 2 / 3 * zr! + ar! / (3 * d!)
                zi! = 2 / 3 * zi! - ai! / (3 * d!)
                ' Close enough to one of the roots?  (distance^2 < 0.001)
                ' (Multiplying is much faster than using ^ 2.)
                IF zr! > .9 THEN
                    IF (zr! - 1) * (zr! - 1) + zi! * zi! < .001 THEN col% = 1: EXIT FOR
                ELSEIF zr! < -.4 THEN
                    e! = ABS(zi!) - R3        ' the two other roots are mirror images
                    IF (zr! + .5) * (zr! + .5) + e! * e! < .001 THEN
                        IF zi! > 0 THEN col% = 65 ELSE col% = 129
                        EXIT FOR
                    END IF
                END IF
            NEXT
            ' Shade: each step makes the color 4 shades darker.
            IF col% > 0 THEN
                sh% = n% * 4: IF sh% > 63 THEN sh% = 63
                col% = col% + sh%
            END IF
            LINE (px%, py%)-STEP(1, 1), col%, BF
            ' mirror row: swap green (65..128) and blue (129..192)
            IF col% >= 129 THEN
                col% = col% - 64
            ELSEIF col% >= 65 THEN
                col% = col% + 64
            END IF
            IF py% < 100 THEN LINE (px%, 200 - py%)-STEP(1, 1), col%, BF
        NEXT
        IF INKEY$ = CHR$(27) THEN quit% = -1: EXIT SUB
    NEXT
END SUB
