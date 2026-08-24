' ============================================================
' TITLE:    Recursive Squares
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     fractals, recursion, squares, T-square, whirl, SCREEN 12
' SUMMARY:  Three squares-only fractals: the T-square, a corner-stacked tower and a spinning whirl of nested squares.
' ------------------------------------------------------------
' WHAT IT DOES
'   Squares are the simplest shape to draw with LINE ... BF, and with
'   recursion they turn into surprising fractals:
'
'   1  T-SQUARE: draw a square, then put a half-size square centred
'      on each of its 4 corners, and so on.  Drawing the small ones
'      FIRST and the big ones on top gives the "T-square" fractal.
'   2  STACKED: the same, but the small squares are drawn LAST, on
'      top - the same rule makes a totally different picture!
'   3  WHIRL: a square inside a square, each one turned a little and
'      shrunk to fit exactly - curved spirals appear from straight
'      lines only.
'
' HOW TO USE
'   1 / 2 / 3 choose a picture,  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Recursion with 4 calls per level (4^n squares!)
'   * How the ORDER of drawing changes the final picture
'   * Interpolating between two points: P + t * (Q - P)
'
' THINGS TO TRY
'   * In the T-square, use 1/3 instead of 1/2 for the child size
'   * In the whirl, change t from 0.1 to 0.5 or 0.03
'   * Recurse into only 3 of the 4 corners
' ============================================================
DECLARE SUB TSquare (x!, y!, half!, level%, smallFirst%)
DECLARE SUB Whirl ()

SCREEN 12
pic% = 1
DO
    CLS
    SELECT CASE pic%
        CASE 1
            COLOR 15: PRINT "T-square: small squares drawn first"
            TSquare 320, 250, 100, 6, -1
        CASE 2
            COLOR 15: PRINT "Stacked: small squares drawn on top"
            TSquare 320, 250, 100, 6, 0
        CASE 3
            COLOR 15: PRINT "Whirl: each square turned and shrunk"
            Whirl
    END SELECT
    LOCATE 30, 1: COLOR 7: PRINT "1 T-square   2 stacked   3 whirl   Esc quit";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    IF k$ >= "1" AND k$ <= "3" THEN pic% = VAL(k$)
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' A square centred at (x, y) with "half" = half its side length.
SUB TSquare (x!, y!, half!, level%, smallFirst%)
    IF level% = 0 THEN EXIT SUB
    h2! = half! / 2
    c% = 8 + level%                     ' each level its own color
    IF smallFirst% THEN
        ' Recurse first (children underneath), then draw this square.
        TSquare x! - half!, y! - half!, h2!, level% - 1, smallFirst%
        TSquare x! + half!, y! - half!, h2!, level% - 1, smallFirst%
        TSquare x! - half!, y! + half!, h2!, level% - 1, smallFirst%
        TSquare x! + half!, y! + half!, h2!, level% - 1, smallFirst%
        LINE (x! - half!, y! - half!)-(x! + half!, y! + half!), c%, BF
        LINE (x! - half!, y! - half!)-(x! + half!, y! + half!), 0, B
    ELSE
        ' Draw this square first, then children on top of it.
        LINE (x! - half!, y! - half!)-(x! + half!, y! + half!), c%, BF
        LINE (x! - half!, y! - half!)-(x! + half!, y! + half!), 0, B
        TSquare x! - half!, y! - half!, h2!, level% - 1, smallFirst%
        TSquare x! + half!, y! - half!, h2!, level% - 1, smallFirst%
        TSquare x! - half!, y! + half!, h2!, level% - 1, smallFirst%
        TSquare x! + half!, y! + half!, h2!, level% - 1, smallFirst%
    END IF
END SUB

' Nested squares: each new corner is 10% of the way along a side of
' the previous square.  Done with a loop (no recursion needed - this
' is "tail recursion" turned into iteration).
SUB Whirl
    DIM px!(3), py!(3), nx!(3), ny!(3)
    ' Four big squares side by side, alternately spinning left/right.
    FOR q% = 0 TO 3
        ox! = 160 + (q% MOD 2) * 320: oy! = 136 + (q% \ 2) * 210
        s! = 100                         ' half the side
        px!(0) = ox! - s!: py!(0) = oy! - s!
        px!(1) = ox! + s!: py!(1) = oy! - s!
        px!(2) = ox! + s!: py!(2) = oy! + s!
        px!(3) = ox! - s!: py!(3) = oy! + s!
        ' Spin direction: reverse the corner order on 2 of the 4 squares.
        IF q% = 1 OR q% = 2 THEN SWAP px!(1), px!(3): SWAP py!(1), py!(3)
        t! = .1
        FOR n% = 1 TO 40
            c% = 9 + n% MOD 6
            LINE (px!(0), py!(0))-(px!(1), py!(1)), c%
            LINE -(px!(2), py!(2)), c%
            LINE -(px!(3), py!(3)), c%
            LINE -(px!(0), py!(0)), c%
            ' New corner i = old corner i + t * (old corner i+1 - corner i)
            FOR i% = 0 TO 3
                j% = (i% + 1) MOD 4
                nx!(i%) = px!(i%) + t! * (px!(j%) - px!(i%))
                ny!(i%) = py!(i%) + t! * (py!(j%) - py!(i%))
            NEXT
            FOR i% = 0 TO 3: px!(i%) = nx!(i%): py!(i%) = ny!(i%): NEXT
        NEXT
    NEXT
END SUB
