' ============================================================
' TITLE:    Sierpinski Triangle Two Ways
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     fractals, recursion, chaos game, random, SCREEN 12
' SUMMARY:  Build the same famous triangle by recursion and then by a random dice game - and see they match.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Sierpinski triangle is a triangle with a triangular hole cut
'   out of its middle, leaving 3 smaller triangles; each of those has
'   its middle cut out, and so on forever.
'
'   Method 1 - RECURSION: a SUB draws a triangle by calling ITSELF
'   three times for the three corner triangles, each half the size.
'
'   Method 2 - THE CHAOS GAME: put a dot anywhere.  Then over and
'   over: pick one of the 3 corners at random and move the dot HALF
'   WAY towards it, plotting a pixel.  Amazingly, the same triangle
'   appears out of pure randomness!
'
' HOW TO USE
'   Press 1 for recursion, 2 for the chaos game, Esc to quit.
'   In recursion mode, + / - change the depth.
'
' CONCEPTS YOU WILL LEARN
'   * Recursive SUBs and the "base case" that stops them
'   * Midpoints: ((x1 + x2) / 2, (y1 + y2) / 2)
'   * Random numbers with RND and INT
'   * How simple rules + randomness can create order
'
' THINGS TO TRY
'   * In the chaos game move 2/3 of the way instead of 1/2
'   * Use 4 corners of a square (hint: you get a filled square -
'     unless you forbid picking the same corner twice in a row!)
'   * Draw the recursion with filled triangles using PAINT
' ============================================================
DECLARE SUB Tri (x1!, y1!, x2!, y2!, x3!, y3!, d%)
DECLARE SUB Chaos ()
DECLARE SUB Recursive ()

DIM SHARED depth%
DIM SHARED ax(1 TO 3), ay(1 TO 3)     ' the three big corners
' SCREEN 12 is 640 x 480 with 16 colors.
SCREEN 12
RANDOMIZE TIMER
ax(1) = 320: ay(1) = 30               ' top
ax(2) = 40: ay(2) = 450               ' bottom left
ax(3) = 600: ay(3) = 450              ' bottom right
depth% = 6

mode% = 1
DO
    IF mode% = 1 THEN Recursive ELSE Chaos
    LOCATE 30, 1: COLOR 7
    PRINT "1 = recursion  2 = chaos game  +/- depth  Esc = quit";
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "1": mode% = 1
        CASE "2": mode% = 2
        CASE "+", "=": IF depth% < 9 THEN depth% = depth% + 1
        CASE "-", "_": IF depth% > 0 THEN depth% = depth% - 1
        CASE CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0: WIDTH 80
END

SUB Chaos
    CLS
    COLOR 14: PRINT "The chaos game: jump halfway to a random corner"
    FOR i% = 1 TO 3: CIRCLE (ax(i%), ay(i%)), 4, 12: NEXT
    x! = RND * 640: y! = RND * 480       ' start anywhere at all
    FOR n& = 1 TO 30000
        c% = INT(RND * 3) + 1             ' roll a 3-sided die: 1, 2 or 3
        x! = (x! + ax(c%)) / 2            ' move halfway to that corner
        y! = (y! + ay(c%)) / 2
        ' Skip the first few dots: the starting point may be outside
        ' the triangle, but after ~10 jumps it is always "trapped".
        IF n& > 10 THEN PSET (x!, y!), 9 + c%   ' color by corner chosen
        IF n& MOD 1000 = 0 THEN
            LOCATE 2, 1: PRINT "dots:"; n&
            IF INKEY$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
        END IF
    NEXT
END SUB

SUB Recursive
    CLS
    COLOR 14: PRINT "Recursion depth"; depth%; "-"; 3 ^ depth%; "small triangles"
    Tri ax(1), ay(1), ax(2), ay(2), ax(3), ay(3), depth%
END SUB

' Draws a Sierpinski triangle with corners (x1,y1) (x2,y2) (x3,y3).
SUB Tri (x1!, y1!, x2!, y2!, x3!, y3!, d%)
    IF d% = 0 THEN
        ' BASE CASE: no more splitting - just draw the outline.
        ' Without a base case the SUB would call itself forever.
        c% = 9 + (x1! + y1!) \ 160 MOD 6        ' a color by position
        LINE (x1!, y1!)-(x2!, y2!), c%
        LINE -(x3!, y3!), c%                     ' LINE - continues
        LINE -(x1!, y1!), c%                     ' from the last point
        EXIT SUB
    END IF
    ' Midpoints of the three sides.
    mx12! = (x1! + x2!) / 2: my12! = (y1! + y2!) / 2
    mx23! = (x2! + x3!) / 2: my23! = (y2! + y3!) / 2
    mx13! = (x1! + x3!) / 2: my13! = (y1! + y3!) / 2
    ' Three half-size triangles, one at each corner.  The middle
    ' one (mx12, mx23, mx13) is the hole - we never draw it.
    Tri x1!, y1!, mx12!, my12!, mx13!, my13!, d% - 1
    Tri mx12!, my12!, x2!, y2!, mx23!, my23!, d% - 1
    Tri mx13!, my13!, mx23!, my23!, x3!, y3!, d% - 1
END SUB
