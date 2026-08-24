' ============================================================
' TITLE:    Mandelbrot Explorer
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, complex numbers, palette, zoom, SCREEN 13
' SUMMARY:  Fly into the Mandelbrot set with a movable zoom box and a smooth custom 256-color palette.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws the famous Mandelbrot set: for every pixel it takes a
'   complex number c, repeats z = z*z + c starting from z = 0, and
'   counts how many steps it takes for z to "escape" (grow bigger
'   than 2).  Points that never escape are inside the set (black);
'   the others are colored by how fast they escaped.
'   A box cursor lets you pick an area and zoom in on it.
'
' HOW TO USE
'   Arrow keys   move the zoom box
'   + / -        make the box smaller / bigger
'   Enter/Space  zoom into the box
'   Z            zoom back out (x2)
'   I            more iterations (more detail, slower)
'   F            toggle Fast (2x2 blocks) / Fine (every pixel)
'   R            reset to the full view
'   Esc          quit (also stops a drawing in progress)
'
' CONCEPTS YOU WILL LEARN
'   * Complex number arithmetic using two ordinary numbers
'   * The escape-time algorithm for drawing fractals
'   * Mapping screen pixels to coordinates in the math plane
'   * Programming the VGA palette with OUT &H3C8 / &H3C9
'   * XOR drawing to make a cursor that does not damage the picture
'
' THINGS TO TRY
'   * Zoom into the "valleys" between the bulbs - seahorses live there
'   * Change the palette formula in SetupPalette for new moods
'   * Replace z*z + c by z*z*z + c (a "Multibrot") and see what changes
' ============================================================
DECLARE SUB SetupPalette ()
DECLARE SUB Render ()
DECLARE SUB DrawBox ()
DECLARE SUB Status (msg$)

' ---- The view: centre of the picture and its width -----------
' Using DOUBLE precision lets us zoom much deeper before the
' picture turns blocky (single precision runs out at ~1e-6).
DIM SHARED cx#, cy#, wid#       ' centre (cx#, cy#) and width wid#
DIM SHARED maxIt%               ' how many z = z*z + c steps to try
DIM SHARED blk%                 ' pixel block size: 2 = fast, 1 = fine
DIM SHARED bx%, by%, bw%        ' zoom box: top-left corner and width
DIM SHARED aborted%             ' -1 if the user pressed Esc mid-draw

CONST SW = 320, SH = 192        ' drawing area (bottom 8 rows = status)

SCREEN 13
SetupPalette

cx# = -.6: cy# = 0: wid# = 3.4
maxIt% = 48: blk% = 2
bw% = 80: bx% = (SW - bw%) \ 2: by% = (SH - bw% * SH \ SW) \ 2

DO
    Render
    IF aborted% THEN EXIT DO
    DrawBox                         ' XOR draw: box appears
    DO
        k$ = INKEY$
        IF k$ <> "" THEN
            DrawBox                 ' XOR again: box disappears
            bh% = bw% * SH \ SW     ' box keeps the screen's shape
            SELECT CASE k$
                CASE CHR$(0) + "H": by% = by% - 4      ' up arrow
                CASE CHR$(0) + "P": by% = by% + 4      ' down arrow
                CASE CHR$(0) + "K": bx% = bx% - 4      ' left arrow
                CASE CHR$(0) + "M": bx% = bx% + 4      ' right arrow
                CASE "+", "=": IF bw% > 16 THEN bw% = bw% - 8
                CASE "-", "_": IF bw% < 312 THEN bw% = bw% + 8
                CASE CHR$(13), " "
                    ' New centre = middle of the box, converted to
                    ' math coordinates.  New width = box width scaled.
                    sc# = wid# / SW               ' math units per pixel
                    cx# = cx# + (bx% + bw% / 2 - SW / 2) * sc#
                    cy# = cy# + (by% + bh% / 2 - SH / 2) * sc#
                    wid# = bw% * sc#
                    maxIt% = maxIt% + 8           ' deeper zoom needs more steps
                    EXIT DO
                CASE "z", "Z": wid# = wid# * 2: EXIT DO
                CASE "i", "I": maxIt% = maxIt% + 32: EXIT DO
                CASE "f", "F": blk% = 3 - blk%: EXIT DO   ' 2 <-> 1
                CASE "r", "R"
                    cx# = -.6: cy# = 0: wid# = 3.4: maxIt% = 48: EXIT DO
                CASE CHR$(27): aborted% = -1: EXIT DO
            END SELECT
            ' keep the box on screen
            bh% = bw% * SH \ SW
            IF bx% < 0 THEN bx% = 0
            IF by% < 0 THEN by% = 0
            IF bx% + bw% > SW - 1 THEN bx% = SW - 1 - bw%
            IF by% + bh% > SH - 1 THEN by% = SH - 1 - bh%
            DrawBox
        END IF
    LOOP
LOOP UNTIL aborted%
SCREEN 0: WIDTH 80
PRINT "Thanks for exploring the Mandelbrot set!"
END

' Draws (or erases - XOR is its own undo) the zoom rectangle.
SUB DrawBox
    bh% = bw% * SH \ SW
    ' LINE has no XOR mode, so we flip each pixel's color ourselves:
    ' read it with POINT, XOR it with 255, write it back with PSET.
    ' Doing the same thing twice restores the original picture.
    FOR x% = bx% TO bx% + bw%
        PSET (x%, by%), POINT(x%, by%) XOR 255
        PSET (x%, by% + bh%), POINT(x%, by% + bh%) XOR 255
    NEXT
    FOR y% = by% + 1 TO by% + bh% - 1
        PSET (bx%, y%), POINT(bx%, y%) XOR 255
        PSET (bx% + bw%, y%), POINT(bx% + bw%, y%) XOR 255
    NEXT
END SUB

SUB Render
    sc# = wid# / SW                 ' size of one pixel in math units
    left# = cx# - wid# / 2          ' math x of the left edge
    top# = cy# - SH * sc# / 2       ' math y of the top edge
    Status "Drawing...  it=" + STR$(maxIt%) + "  Esc=stop"
    FOR py% = 0 TO SH - 1 STEP blk%
        ci# = top# + py% * sc#      ' imaginary part of c for this row
        FOR px% = 0 TO SW - 1 STEP blk%
            cr# = left# + px% * sc# ' real part of c
            ' ---- the escape-time loop ----
            ' z = zr + zi*i.  Squaring a complex number:
            '   (zr + zi*i)^2 = zr^2 - zi^2  +  2*zr*zi * i
            zr# = 0: zi# = 0: zr2# = 0: zi2# = 0
            n% = 0
            DO WHILE n% < maxIt% AND zr2# + zi2# < 4
                zi# = 2 * zr# * zi# + ci#
                zr# = zr2# - zi2# + cr#
                zr2# = zr# * zr#: zi2# = zi# * zi#   ' reuse the squares
                n% = n% + 1
            LOOP
            IF n% = maxIt% THEN
                c% = 0                       ' inside the set: black
            ELSE
                c% = 1 + (n% * 6) MOD 255    ' cycle through palette 1..255
            END IF
            IF blk% = 1 THEN
                PSET (px%, py%), c%
            ELSE
                LINE (px%, py%)-(px% + blk% - 1, py% + blk% - 1), c%, BF
            END IF
        NEXT
        ' Check the keyboard once per row so Esc works mid-drawing.
        IF INKEY$ = CHR$(27) THEN aborted% = -1: EXIT SUB
    NEXT
    Status "Arrows +- box  Enter zoom  Z F I R Esc"
END SUB

' Builds a smooth 255-color palette.  The VGA DAC holds 256 colors;
' you write the color number to port &H3C8, then three values
' (red, green, blue, each 0-63) to port &H3C9.
SUB SetupPalette
    OUT &H3C8, 0
    OUT &H3C9, 0: OUT &H3C9, 0: OUT &H3C9, 0       ' color 0 = black
    FOR i% = 1 TO 255
        t! = i% / 255 * 6.2832                   ' one trip around a circle
        ' Three cosine waves.  At t = 0 we get deep blue, a quarter of
        ' the way round it is green, halfway it is red, and at the end
        ' it is back to blue, so colors can wrap around without a jump.
        r% = 31 * (1 - COS(t!))
        g% = 31 * (1 - COS(2 * t!))
        b% = 31 * (1 + COS(t!))
        OUT &H3C9, r%: OUT &H3C9, g%: OUT &H3C9, b%
    NEXT
END SUB

SUB Status (msg$)
    LINE (0, SH)-(319, 199), 0, BF
    LOCATE 25, 1: COLOR 85: PRINT LEFT$(msg$, 39);
END SUB
