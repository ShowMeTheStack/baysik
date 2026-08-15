' ============================================================
' TITLE:    Lens Ray Diagram
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     optics, light, lenses, geometry, interactive graphics
' SUMMARY:  Move an object in front of a lens and watch the light rays build a real or virtual image.
' ------------------------------------------------------------
' WHAT IT DOES
'   A lens bends light.  A CONVERGING lens (like a magnifying glass)
'   brings parallel rays together at its FOCAL POINT F.  A DIVERGING
'   lens spreads them out as if they came from a focal point.
'   This program draws the three "principal rays" from the top of an
'   object (the green arrow):
'     1. parallel to the axis -> bends through the focal point
'     2. through the centre   -> goes straight on
'     3. through the near F   -> comes out parallel
'   Where the rays meet is the IMAGE (the red arrow).  If they only
'   SEEM to meet when traced backwards (dotted), the image is
'   VIRTUAL - you see it by looking through the lens, but you can't
'   project it onto a screen.
'   The thin-lens equation predicts it:   1/f = 1/do + 1/di
'   and the magnification is  m = -di / do.
'
' HOW TO USE
'   Left / Right arrows  move the object      Up / Down  taller / shorter
'   + / -   longer / shorter focal length      D  converging <-> diverging
'   ESC     quit
'
' CONCEPTS YOU WILL LEARN
'   * Refraction by a thin lens: slope_out = slope_in - y / f
'   * Real vs virtual, upright vs inverted images
'   * Using one general rule to draw every ray
'   * Dashed lines with the LINE style argument
'
' THINGS TO TRY
'   * Put the object exactly at 2F: the image is the same size, upside down.
'   * Move it inside F: a magnifying glass!  (upright, virtual, bigger)
'   * Put it exactly on F: the rays leave parallel - no image at all.
' ============================================================

DEFSNG A-Z
CONST LX = 320, AY = 240        ' lens position and optical axis on screen

objD = 200                        ' object distance (pixels, left of lens)
h = 60                          ' object height
f = 100                         ' focal length (+ converging, - diverging)

SCREEN 12
GOSUB Redraw
DO
    k$ = INKEY$
    changed = 1
    SELECT CASE k$
        CASE CHR$(0) + "K": objD = objD + 5: IF objD > 310 THEN objD = 310
        CASE CHR$(0) + "M": objD = objD - 5: IF objD < 10 THEN objD = 10
        CASE CHR$(0) + "H": h = h + 5: IF h > 120 THEN h = 120
        CASE CHR$(0) + "P": h = h - 5: IF h < 10 THEN h = 10
        CASE "+", "=": f = f + SGN(f) * 5: IF ABS(f) > 250 THEN f = 250 * SGN(f)
        CASE "-": f = f - SGN(f) * 5: IF ABS(f) < 30 THEN f = 30 * SGN(f)
        CASE "D", "d": f = -f
        CASE CHR$(27): EXIT DO
        CASE ELSE: changed = 0
    END SELECT
    IF changed THEN GOSUB Redraw
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' Redraw: everything from scratch.  Inside the maths, x is measured
' from the lens (negative = left) and y upward from the axis.
' Screen point = (LX + x, AY - y).
' ------------------------------------------------------------
Redraw:
    CLS
    LINE (0, AY)-(639, AY), 8                      ' optical axis
    ' the lens: a tall ellipse (converging) or a pinched shape
    IF f > 0 THEN
        CIRCLE (LX, AY), 150, 11, , , 12
    ELSE
        LINE (LX - 8, AY - 150)-(LX + 8, AY - 150), 11
        LINE (LX - 8, AY + 150)-(LX + 8, AY + 150), 11
        LINE (LX - 8, AY - 150)-(LX - 2, AY), 11: LINE (LX - 2, AY)-(LX - 8, AY + 150), 11
        LINE (LX + 8, AY - 150)-(LX + 2, AY), 11: LINE (LX + 2, AY)-(LX + 8, AY + 150), 11
    END IF
    ' focal points on both sides, and 2F marks
    FOR s = -1 TO 1 STEP 2
        CIRCLE (LX + s * f, AY), 3, 14
        CIRCLE (LX + s * 2 * f, AY), 2, 6
    NEXT
    ' the object: a green arrow standing on the axis
    ox = -objD
    LINE (LX + ox, AY)-(LX + ox, AY - h), 10
    LINE (LX + ox, AY - h)-(LX + ox - 5, AY - h + 8), 10
    LINE (LX + ox, AY - h)-(LX + ox + 5, AY - h + 8), 10

    ' ---- the three principal rays --------------------------------
    ' Each ray starts at the arrow tip (-objD, h) and hits the lens at
    ' height y.  The thin-lens rule then gives its new slope.
    FOR ray = 1 TO 3
        SELECT CASE ray
            CASE 1: y = h                       ' parallel ray
            CASE 2: y = 0                       ' through the centre
            CASE 3                              ' through the near focal point
                IF ABS(objD - f) < .01 THEN GOTO NextRay
                y = h * (-f) / (objD - f)
                IF ABS(y) > 230 THEN GOTO NextRay   ' would miss the screen
        END SELECT
        rc = 11 + ray                           ' ray colours 12, 13, 14
        slopeIn = (y - h) / objD                      ' slope before the lens
        slopeOut = slopeIn - y / f                      ' slope after the lens
        ' incoming part
        LINE (LX - objD, AY - h)-(LX, AY - y), rc
        ' outgoing part, out to the right edge
        LINE (LX, AY - y)-(LX + 320, AY - (y + slopeOut * 320)), rc
        ' backwards extension (dotted) - shows where virtual images form
        LINE (LX, AY - y)-(LX - 320, AY - (y - slopeOut * 320)), 8, , &HAAAA
NextRay:
    NEXT

    ' ---- the image from the thin-lens equation ------------------------
    LOCATE 1, 1: COLOR 15
    IF f > 0 THEN PRINT "CONVERGING lens"; ELSE PRINT "DIVERGING lens";
    PRINT USING "   f = ####   object distance do = ####   height ###"; f; objD; h
    LOCATE 2, 1
    IF ABS(objD - f) < .01 THEN
        PRINT "Object at the focal point: rays leave parallel, no image forms."
    ELSE
        di = 1 / (1 / f - 1 / objD)
        m = -di / objD
        hi = m * h
        ' draw the image arrow (solid if real, dashed if virtual)
        IF di > 0 THEN st = &HFFFF ELSE st = &HCCCC
        IF ABS(di) < 330 AND ABS(hi) < 235 THEN
            LINE (LX + di, AY)-(LX + di, AY - hi), 12, , st
            LINE (LX + di - 5, AY - hi + 8 * SGN(hi))-(LX + di, AY - hi), 12
            LINE (LX + di + 5, AY - hi + 8 * SGN(hi))-(LX + di, AY - hi), 12
        END IF
        PRINT USING "Image distance di = #####.#   magnification m = ###.##"; di; m
        IF di > 0 THEN t$ = "REAL" ELSE t$ = "VIRTUAL"
        IF m < 0 THEN t$ = t$ + ", INVERTED" ELSE t$ = t$ + ", UPRIGHT"
        IF ABS(ABS(m) - 1) < .01 THEN
            t$ = t$ + ", SAME SIZE"
        ELSEIF ABS(m) > 1 THEN
            t$ = t$ + ", ENLARGED"
        ELSE
            t$ = t$ + ", REDUCED"
        END IF
        PRINT "Image is "; t$
    END IF
    LOCATE 30, 1: COLOR 7
    PRINT "Arrows: move/size object   +/- focal length   D lens type   ESC quit";
RETURN
