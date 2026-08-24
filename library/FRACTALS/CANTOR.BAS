' ============================================================
' TITLE:    Cantor Set and Cantor Dust
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     fractals, recursion, thirds, infinity, SCREEN 12
' SUMMARY:  Remove the middle third of a line, again and again - then do it in 2-D to make Cantor dust.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Cantor set (Georg Cantor, 1883) is one of the very first
'   fractals.  Take the line from 0 to 1.  Remove the middle third.
'   From each of the two pieces that remain, remove THEIR middle
'   thirds.  Keep going forever.  What is left is "dust": infinitely
'   many points, but with total length zero!
'
'   Screen 1 shows each step as a row of bars, one below the other.
'   Screen 2 does the same in two dimensions: a square keeps its 4
'   corner squares at each step, giving "Cantor dust".
'
' HOW TO USE
'   Press any key to go from screen 1 to screen 2.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Recursion with two calls (1-D) and four calls (2-D)
'   * Why the remaining length is (2/3)^n and goes to zero
'   * Counting: 2^n pieces in 1-D, 4^n squares in 2-D
'   * PRINT USING to format a table of numbers
'
' THINGS TO TRY
'   * Remove the middle FIFTH instead of the middle third
'   * Keep pieces 1 and 3 out of 4 (a different Cantor set)
'   * Combine: keep the 5 squares of a "+" shape (Vicsek fractal)
' ============================================================
DECLARE SUB Cantor (x!, w!, y%, level%)
DECLARE SUB Dust (x!, y!, w!, level%)

SCREEN 12
CLS
COLOR 15: PRINT "The Cantor set: remove the middle third, repeat"
PRINT
COLOR 7
' Draw levels 0 to 7, each as a row of bars 16 pixels tall.
' Bars start every 48 pixels = every 3 text rows (text rows are 16
' pixels tall in SCREEN 12), so the labels line up with the bars.
FOR lev% = 0 TO 7
    y% = 48 + lev% * 48
    Cantor 16, 405, y%, lev%           ' 405 = 5 * 3^4 pixels wide
    ' Label on the right: level, number of pieces, length left.
    LOCATE y% \ 16 + 1, 55
    COLOR 14
    PRINT USING "#: ### pieces, #.### left"; lev%; 2 ^ lev%; (2 / 3) ^ lev%
NEXT
LOCATE 30, 1: COLOR 15: PRINT "Press any key for Cantor dust (Esc = quit)";
DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END

CLS
COLOR 15: PRINT "Cantor dust: keep the 4 corner squares, repeat"
' Five levels side by side in a pyramid of sizes.
Dust 20, 40, 162, 0
Dust 236, 40, 162, 1
Dust 456, 40, 162, 2
Dust 80, 215, 243, 3
Dust 360, 215, 243, 4
LOCATE 30, 1: PRINT "Squares at level 4:"; 4 ^ 4; "  Press any key to quit";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END

' 1-D: a bar from x to x+w at height y, split "level" more times.
SUB Cantor (x!, w!, y%, level%)
    IF level% = 0 THEN
        ' Base case: draw the bar.  Color it by its position so you
        ' can see which original third it came from.
        IF x! < 16 + 405 / 3 THEN
            c% = 9                       ' came from the left third
        ELSE
            c% = 12                      ' came from the right third
        END IF
        ' Tiny pieces are less than 1 pixel wide - draw at least 1.
        x2! = x! + w! - 1: IF x2! < x! THEN x2! = x!
        LINE (x!, y%)-(x2!, y% + 15), c%, BF
        EXIT SUB
    END IF
    t! = w! / 3
    Cantor x!, t!, y%, level% - 1                ' left third
    Cantor x! + 2 * t!, t!, y%, level% - 1       ' right third
END SUB

' 2-D: the square with top-left (x, y) and side w.
SUB Dust (x!, y!, w!, level%)
    IF level% = 0 THEN
        LINE (x!, y!)-(x! + w! - 1, y! + w! - 1), 11, BF
        EXIT SUB
    END IF
    t! = w! / 3
    Dust x!, y!, t!, level% - 1                  ' top left
    Dust x! + 2 * t!, y!, t!, level% - 1         ' top right
    Dust x!, y! + 2 * t!, t!, level% - 1         ' bottom left
    Dust x! + 2 * t!, y! + 2 * t!, t!, level% - 1 ' bottom right
END SUB
