' ============================================================
' TITLE:    Box Drawing Workshop
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     box drawing, chr$, sub, cp437, shadows
' SUMMARY:  Learn the CP437 line-drawing characters by building single, double and shadowed boxes with one reusable SUB.
' ------------------------------------------------------------
' WHAT IT DOES
'   The PC character set has special pieces for drawing frames:
'   corners, horizontal and vertical lines, T-joins and crosses,
'   in single-line and double-line versions.  This program shows
'   a labelled "parts list" and then builds a little gallery of
'   boxes: plain, double, with a drop shadow, a box split into
'   sections, and a grid made of crossing lines.
'
' HOW TO USE
'   Press a key to go from the parts list to the gallery, and a
'   key again to quit.
'
' CONCEPTS YOU WILL LEARN
'   * CHR$(n) to print characters that are not on the keyboard
'   * STRING$(count, code) to repeat a character
'   * Writing a reusable SUB with parameters
'   * Drawing a "shadow" by colouring cells next to a box
'
' THINGS TO TRY
'   * Add a third style that uses CHR$(219) solid blocks.
'   * Make a box that mixes double horizontal and single vertical
'     lines (codes 213, 184, 212, 190).
' ============================================================

DECLARE SUB DrawBox (top%, lft%, bottom%, rgt%, style%, fg%, bg%)
DECLARE SUB Shadow (top%, lft%, bottom%, rgt%)

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS

' ---- Page 1: the parts list ------------------------------------
' Each DATA line: a code number and its description.
COLOR 14: PRINT "  BOX DRAWING PARTS  (use with PRINT CHR$(code))": COLOR 7
PRINT
PRINT "   SINGLE LINE                       DOUBLE LINE"
FOR i = 1 TO 11
    READ c1, n1$, c2, n2$
    PRINT USING "   ###  "; c1;
    COLOR 15: PRINT CHR$(c1); : COLOR 7
    PRINT "  "; n1$; TAB(38);
    PRINT USING "###  "; c2;
    COLOR 15: PRINT CHR$(c2); : COLOR 7
    PRINT "  "; n2$
NEXT i
DATA 218,"top-left corner",201,"top-left corner"
DATA 191,"top-right corner",187,"top-right corner"
DATA 192,"bottom-left corner",200,"bottom-left corner"
DATA 217,"bottom-right corner",188,"bottom-right corner"
DATA 196,"horizontal line",205,"horizontal line"
DATA 179,"vertical line",186,"vertical line"
DATA 195,"T pointing right",204,"T pointing right"
DATA 180,"T pointing left",185,"T pointing left"
DATA 194,"T pointing down",203,"T pointing down"
DATA 193,"T pointing up",202,"T pointing up"
DATA 197,"cross",206,"cross"
PRINT
PRINT "   Shading blocks: ";
FOR c = 176 TO 178: PRINT CHR$(c); CHR$(c); " "; : NEXT c
PRINT CHR$(219); CHR$(219); "  (176, 177, 178, 219)"
PRINT
COLOR 10: PRINT "   Press any key to see them in action..."
k$ = INPUT$(1)

' ---- Page 2: the gallery -----------------------------------------
COLOR 7, 1: CLS          ' blue "desktop" background

DrawBox 2, 3, 8, 26, 1, 15, 1
LOCATE 3, 5: PRINT "Single-line box"
LOCATE 5, 5: PRINT "style 1"

DrawBox 2, 30, 8, 53, 2, 14, 1
LOCATE 3, 32: PRINT "Double-line box"
LOCATE 5, 32: PRINT "style 2"

' A window with a drop shadow: draw the
' box first, then darken the cells to its right and below.
DrawBox 2, 57, 8, 77, 2, 0, 7
LOCATE 3, 60: COLOR 1, 7: PRINT " Shadowed box "
Shadow 2, 57, 8, 77

' A box split into a title section and a body with a T-join line.
DrawBox 11, 3, 20, 36, 2, 11, 1
COLOR 11, 1
LOCATE 15, 3: PRINT CHR$(199); STRING$(32, 196); CHR$(182)
' 199 and 182 are the "double vertical, single horizontal" T-joins
COLOR 15, 1
LOCATE 13, 10: PRINT "INVENTORY  REPORT"
LOCATE 17, 6: PRINT "Swords ..........  3"
LOCATE 18, 6: PRINT "Potions ......... 12"

' A grid of 4 columns x 3 rows built from crosses and T-pieces.
COLOR 10, 1
gtop = 11: gleft = 42
FOR r = 0 TO 6                 ' 7 text lines: 4 border lines + 3 cell lines
    LOCATE gtop + r, gleft
    IF r MOD 2 = 0 THEN
        ' a border line: choose the left/middle/right pieces
        SELECT CASE r
            CASE 0: l$ = CHR$(218): m$ = CHR$(194): rt$ = CHR$(191)
            CASE 6: l$ = CHR$(192): m$ = CHR$(193): rt$ = CHR$(217)
            CASE ELSE: l$ = CHR$(195): m$ = CHR$(197): rt$ = CHR$(180)
        END SELECT
        ln$ = l$
        FOR c = 1 TO 4
            ln$ = ln$ + STRING$(6, 196)
            IF c < 4 THEN ln$ = ln$ + m$ ELSE ln$ = ln$ + rt$
        NEXT c
    ELSE
        ' a cell line: vertical bars with spaces between
        ln$ = CHR$(179)
        FOR c = 1 TO 4
            ln$ = ln$ + SPACE$(6) + CHR$(179)
        NEXT c
    END IF
    PRINT ln$
NEXT r
' put some numbers in the cells
COLOR 15, 1
FOR r = 0 TO 2
    FOR c = 0 TO 3
        LOCATE gtop + 1 + r * 2, gleft + 2 + c * 7
        PRINT USING "##"; (r + 1) * (c + 1);
    NEXT c
NEXT r
LOCATE 19, 48: PRINT "a times table!"

COLOR 14, 1
LOCATE 23, 28: PRINT "Press any key to quit";
k$ = INPUT$(1)
COLOR 7, 0: CLS
END

' Draw a frame from (top,lft) to (bottom,rgt).
' style 1 = single lines, style 2 = double lines.
' The inside of the box is filled with spaces in the given colours.
SUB DrawBox (top%, lft%, bottom%, rgt%, style%, fg%, bg%)
    IF style% = 1 THEN
        tl$ = CHR$(218): tr$ = CHR$(191): bl$ = CHR$(192): br$ = CHR$(217)
        h$ = CHR$(196): v$ = CHR$(179)
    ELSE
        tl$ = CHR$(201): tr$ = CHR$(187): bl$ = CHR$(200): br$ = CHR$(188)
        h$ = CHR$(205): v$ = CHR$(186)
    END IF
    w% = rgt% - lft% - 1               ' width of the inside
    COLOR fg%, bg%
    LOCATE top%, lft%: PRINT tl$; STRING$(w%, h$); tr$;
    FOR r% = top% + 1 TO bottom% - 1
        LOCATE r%, lft%: PRINT v$; SPACE$(w%); v$;
    NEXT r%
    LOCATE bottom%, lft%: PRINT bl$; STRING$(w%, h$); br$;
END SUB

' A shadow is just the cells one row below and two columns to the
' right of the box, redrawn in dark grey on black.  We read back the
' character already there with SCREEN(row, col) so the text under the
' shadow stays visible - just dimmed, like a real shadow.
SUB Shadow (top%, lft%, bottom%, rgt%)
    COLOR 8, 0
    FOR r% = top% + 1 TO bottom% + 1
        FOR c% = rgt% + 1 TO rgt% + 2
            IF c% <= 80 THEN LOCATE r%, c%: PRINT CHR$(SCREEN(r%, c%));
        NEXT c%
    NEXT r%
    FOR c% = lft% + 2 TO rgt% + 2
        IF c% <= 80 THEN LOCATE bottom% + 1, c%: PRINT CHR$(SCREEN(bottom% + 1, c%));
    NEXT c%
END SUB
