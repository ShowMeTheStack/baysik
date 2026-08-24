' ============================================================
' TITLE:    Sierpinski Carpet
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     fractals, recursion, squares, SCREEN 12
' SUMMARY:  Cut a square into nine, throw away the middle, repeat - watch a holey carpet grow level by level.
' ------------------------------------------------------------
' WHAT IT DOES
'   Start with a filled square.  Split it into a 3 x 3 grid of nine
'   smaller squares and cut out the middle one.  Then do the same
'   to each of the 8 squares that are left, and again, and again.
'   The program shows each level for a moment so you can watch the
'   holes multiply, and prints how much of the carpet is left.
'
' HOW TO USE
'   Just watch.  Press any key to skip ahead, Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * A recursive SUB that calls itself 8 times
'   * Nested FOR loops to visit a 3 x 3 grid
'   * Integer division (\) and why the size must divide by 3
'   * The strange math of fractals: the area shrinks to zero
'     (each level keeps 8/9 of it) while the holes' edges grow forever
'
' THINGS TO TRY
'   * Keep the middle and remove the corners instead (Vicsek fractal)
'   * Color each square by its level of recursion
'   * Make a 3-D version: the "Menger sponge"
' ============================================================
DECLARE SUB Carpet (x%, y%, size%, level%)

SCREEN 12
CONST CSIZE = 405               ' 405 = 5 * 3^4, so it divides by 3 cleanly
x0% = (640 - CSIZE) \ 2: y0% = 40

FOR lev% = 0 TO 4
    CLS
    COLOR 15
    PRINT "Sierpinski carpet - level"; lev%
    ' Draw the whole square first, then let Carpet punch the holes.
    LINE (x0%, y0%)-(x0% + CSIZE - 1, y0% + CSIZE - 1), 1 + lev%, BF
    Carpet x0%, y0%, CSIZE, lev%
    ' What fraction of the square is left?  (8/9) to the power lev
    LOCATE 30, 1
    PRINT USING "Squares: #####   Area left: ###.#%"; 8 ^ lev%; 100 * (8 / 9) ^ lev%;
    ' wait up to 2 seconds (or until a key is pressed)
    t! = TIMER
    DO
        k$ = INKEY$
        IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
    LOOP UNTIL k$ <> "" OR TIMER - t! > 2 OR TIMER < t!
NEXT
LOCATE 29, 1: COLOR 14: PRINT "Done!  Press any key to quit.";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END

' Cuts the holes into the square at (x%, y%) of the given size.
' level% says how many more times we may subdivide.
SUB Carpet (x%, y%, size%, level%)
    IF level% = 0 THEN EXIT SUB          ' base case: nothing to cut
    s% = size% \ 3                       ' size of one of the 9 parts
    ' The middle part becomes a hole (color 0 = black).
    LINE (x% + s%, y% + s%)-(x% + 2 * s% - 1, y% + 2 * s% - 1), 0, BF
    ' Visit the 3 x 3 grid and recurse into the 8 outer parts.
    FOR row% = 0 TO 2
        FOR col% = 0 TO 2
            IF NOT (row% = 1 AND col% = 1) THEN
                Carpet x% + col% * s%, y% + row% * s%, s%, level% - 1
            END IF
        NEXT
    NEXT
END SUB
