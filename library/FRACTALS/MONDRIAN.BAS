' ============================================================
' TITLE:    Mondrian Art Machine
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     generative art, recursion, random, rectangles, SCREEN 12
' SUMMARY:  Splits the canvas into random rectangles with bold black lines and primary colors, like Piet Mondrian.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Dutch painter Piet Mondrian (1872-1944) is famous for
'   paintings made of white rectangles, thick black lines and a few
'   blocks of pure red, blue and yellow.  This program paints new
'   "Mondrians" forever by recursive splitting:
'     - Take a rectangle.  If it is big enough, cut it in two with a
'       vertical or horizontal line at a random place, and do the
'       same to each half.
'     - If it is small (or by chance), stop and paint it: usually
'       white, sometimes red, blue, yellow or black.
'
' HOW TO USE
'   Space or Enter = paint a new picture
'   S = slideshow (a new painting every 2 seconds)
'   Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Recursive subdivision (the same idea as k-d trees and BSP trees)
'   * Weighted random choice of colors
'   * Avoiding ugly results: minimum sizes and keeping cuts away
'     from the edges
'
' THINGS TO TRY
'   * Make colored blocks more (or less) likely
'   * Always cut the LONGER side - does it look more balanced?
'   * Use pastel colors with PALETTE for a modern look
' ============================================================
DECLARE SUB Split (x1%, y1%, x2%, y2%, depth%)
DECLARE SUB Paint1 (x1%, y1%, x2%, y2%)

CONST MINSIZE = 50          ' rectangles smaller than this are not cut
CONST LINEW = 6             ' thickness of the black lines

SCREEN 12
RANDOMIZE TIMER
' Make color 15 a slightly warm "canvas" white, and pure primaries.
PALETTE 15, 60 + 256& * 60 + 65536 * 56
PALETTE 4, 58 + 256& * 4 + 65536 * 6         ' red
PALETTE 1, 2 + 256& * 12 + 65536 * 44        ' blue
PALETTE 14, 63 + 256& * 54 + 65536 * 8       ' yellow

slide% = 0
DO
    CLS
    ' Black background: the gaps between rectangles become the lines.
    LINE (0, 0)-(639, 479), 0, BF
    Split 0, 0, 639, 479, 0
    IF slide% THEN
        t! = TIMER
        DO
            k$ = UCASE$(INKEY$)
        LOOP UNTIL k$ <> "" OR TIMER - t! > 2 OR TIMER < t!
        IF k$ = "S" THEN slide% = 0
    ELSE
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
        IF k$ = "S" THEN slide% = -1
    END IF
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Recursively split the rectangle (x1,y1)-(x2,y2).
SUB Split (x1%, y1%, x2%, y2%, depth%)
    w% = x2% - x1%: h% = y2% - y1%
    ' Stop if too small, or sometimes stop early once we are a few
    ' levels deep (this leaves some big calm areas).
    IF (w% < MINSIZE * 2 AND h% < MINSIZE * 2) OR (depth% > 2 AND RND < .25) THEN
        Paint1 x1%, y1%, x2%, y2%
        EXIT SUB
    END IF
    ' Choose the direction: a wide rectangle is more likely to get a
    ' vertical cut, a tall one a horizontal cut.
    IF w% < MINSIZE * 2 THEN
        vertical% = 0
    ELSEIF h% < MINSIZE * 2 THEN
        vertical% = -1
    ELSE
        vertical% = (RND * (w% + h%) < w%)
    END IF
    IF vertical% THEN
        ' cut position between MINSIZE from the left and from the right
        cx% = x1% + MINSIZE + INT(RND * (w% - 2 * MINSIZE))
        Split x1%, y1%, cx%, y2%, depth% + 1
        Split cx%, y1%, x2%, y2%, depth% + 1
    ELSE
        cy% = y1% + MINSIZE + INT(RND * (h% - 2 * MINSIZE))
        Split x1%, y1%, x2%, cy%, depth% + 1
        Split x1%, cy%, x2%, y2%, depth% + 1
    END IF
END SUB

' Paints one finished rectangle, leaving LINEW/2 pixels of black on
' every side (so two neighbours make one LINEW-wide line).
SUB Paint1 (x1%, y1%, x2%, y2%)
    r! = RND
    IF r! < .62 THEN
        c% = 15             ' white (most common)
    ELSEIF r! < .74 THEN
        c% = 4              ' red
    ELSEIF r! < .84 THEN
        c% = 1              ' blue
    ELSEIF r! < .94 THEN
        c% = 14             ' yellow
    ELSE
        c% = 0              ' black
    END IF
    g% = LINEW \ 2
    LINE (x1% + g%, y1% + g%)-(x2% - g%, y2% - g%), c%, BF
END SUB
