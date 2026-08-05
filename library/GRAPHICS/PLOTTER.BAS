' ============================================================
' TITLE:    Function Plotter
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     window, math, functions, graphs, axes, screen 12
' SUMMARY:  Graphs y = f(x) for several functions on real math axes using WINDOW, with zoom in and out.
' ------------------------------------------------------------
' WHAT IT DOES
'   Uses WINDOW to turn the 640x480 screen into a piece of graph
'   paper whose coordinates are ordinary maths numbers (x from
'   -10 to 10, y going UP). Then it plots one of six functions
'   with a grid, labelled axes and a smooth curve.
'
' HOW TO USE
'   1-6   choose a function
'   + / - zoom in / zoom out
'   Q or Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * WINDOW (x1, y1)-(x2, y2): your own coordinate system where
'     y grows upward like in maths class
'   * Plotting a curve by joining many short line segments
'   * Handling gaps (like TAN at 90 degrees) by "lifting the pen"
'   * SELECT CASE inside a FUNCTION to choose a formula
'   * PMAP to convert maths coordinates to pixels for labels
'
' THINGS TO TRY
'   * Add your own function as case 7
'   * Plot two functions at once in different colours
'   * Shade the area under the curve with vertical lines
' ============================================================

DECLARE FUNCTION F! (which%, x!, ok%)
DECLARE SUB DrawAxes (sz!)

DIM SHARED nm$(6)
nm$(1) = "y = sin(x)"
nm$(2) = "y = x^2 / 4 - 3"
nm$(3) = "y = x^3 / 20 - x"
nm$(4) = "y = tan(x)"
nm$(5) = "y = 5 * exp(-x^2/8)"
nm$(6) = "y = sqr(abs(x)) * sin(3x)"

SCREEN 12
which% = 1
size! = 10                       ' half-width of the visible area

DO
    ' ---- Draw one complete graph --------------------------------
    CLS
    ' WINDOW maps the screen so that the lower-left corner is
    ' (-size, -size*0.75) and the upper-right is (size, size*0.75).
    ' The 0.75 keeps squares square (480/640 = 0.75).
    WINDOW (-size!, -size! * .75)-(size!, size! * .75)
    DrawAxes size!

    ' Plot: step across the window one pixel's width at a time.
    dx! = (2 * size!) / 640
    penDown% = 0
    FOR x! = -size! TO size! STEP dx!
        y! = F(which%, x!, ok%)
        ' If the value is invalid or wildly off screen, lift the pen
        ' so we do not draw a vertical line across the gap.
        IF ok% = 0 OR ABS(y!) > size! * 3 THEN
            penDown% = 0
        ELSEIF penDown% THEN
            LINE -(x!, y!), 14   ' continue from the last point
        ELSE
            PSET (x!, y!), 14    ' start a fresh piece of curve
            penDown% = -1
        END IF
    NEXT x!

    ' Text uses rows/columns, not WINDOW coordinates.
    LOCATE 1, 2: COLOR 15: PRINT "["; which%; "] "; nm$(which%)
    LOCATE 2, 2: COLOR 7: PRINT USING "x from -##.# to ##.#"; size!; size!
    LOCATE 30, 2: PRINT "1-6 function   +/- zoom   Q quit";

    ' ---- Wait for a command --------------------------------------
    DO
        k$ = UCASE$(INKEY$)
    LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "1" TO "6": which% = VAL(k$)
        CASE "+", "=": IF size! > 1 THEN size! = size! / 2
        CASE "-", "_": IF size! < 80 THEN size! = size! * 2
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP

WINDOW                           ' back to normal pixel coordinates
SCREEN 0: WIDTH 80
END

' ---- Draw grid lines, axes and numbers ---------------------------
SUB DrawAxes (sz!)
    ' Pick a grid spacing that gives about 10 lines each way.
    g! = 1
    IF sz! > 12 THEN g! = 5
    IF sz! > 40 THEN g! = 10
    IF sz! < 3 THEN g! = .5
    ' Faint grid
    FOR gx! = 0 TO sz! STEP g!
        LINE (gx!, -sz!)-(gx!, sz!), 8
        LINE (-gx!, -sz!)-(-gx!, sz!), 8
    NEXT gx!
    FOR gy! = 0 TO sz! STEP g!
        LINE (-sz!, gy!)-(sz!, gy!), 8
        LINE (-sz!, -gy!)-(sz!, -gy!), 8
    NEXT gy!
    ' Bright axes through the origin
    LINE (-sz!, 0)-(sz!, 0), 15
    LINE (0, -sz!)-(0, sz!), 15
    ' Numbers along the x axis. PMAP(value, 0) converts a WINDOW
    ' x into a screen pixel x; PMAP(value, 1) does the same for y.
    ' Dividing pixels by 8 or 16 gives a text column or row.
    row% = INT(PMAP(0, 1) / 16) + 2
    IF row% > 29 THEN row% = 29
    FOR gx! = -sz! + g! TO sz! - g! STEP g! * 2
        col% = INT(PMAP(gx!, 0) / 8) + 1
        IF col% >= 1 AND col% <= 76 AND ABS(gx!) > .001 THEN
            LOCATE row%, col%: COLOR 7: PRINT LTRIM$(STR$(gx!));
        END IF
    NEXT gx!
END SUB

' ---- The functions ------------------------------------------------
' ok% is set to 0 when the function has no value at this x.
FUNCTION F! (which%, x!, ok%)
    ok% = -1
    SELECT CASE which%
        CASE 1: F! = SIN(x!)
        CASE 2: F! = x! * x! / 4 - 3
        CASE 3: F! = x! ^ 3 / 20 - x!
        CASE 4
            ' TAN blows up where COS is zero
            IF ABS(COS(x!)) < .01 THEN ok% = 0: F! = 0 ELSE F! = TAN(x!)
        CASE 5
            IF x! * x! / 8 > 80 THEN F! = 0 ELSE F! = 5 * EXP(-x! * x! / 8)
        CASE 6: F! = SQR(ABS(x!)) * SIN(3 * x!)
    END SELECT
END FUNCTION
