' ============================================================
' TITLE:    Lissajous Curve Oscilloscope
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     lissajous, oscilloscope, page flipping, sine, screen 10
' SUMMARY:  Imitates an old monochrome oscilloscope showing slowly turning Lissajous figures, drawn flicker-free on two pages.
' ------------------------------------------------------------
' WHAT IT DOES
'   Feed one sine wave to the X input of an oscilloscope and
'   another to the Y input and you get a Lissajous figure:
'       x = sin(a * t + phase),   y = sin(b * t)
'   The ratio a:b decides the shape (1:1 ellipse, 1:2 figure
'   eight, 3:2 pretzel...). Slowly changing the phase makes the
'   figure appear to spin in 3-D. SCREEN 10 is the monochrome
'   EGA mode with "colours" 0 black, 1 dim, 2 blinking and
'   3 bright - just like a green-screen scope tube (shown here
'   in white).
'
' HOW TO USE
'   1..6     pick a frequency ratio
'   Q / Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Parametric curves from two sine waves
'   * SCREEN 10, , apage, vpage: draw on one page, show the other
'   * Swapping pages each frame for smooth animation
'   * Drawing a graticule (the scope's grid) with dotted LINE styles
'
' THINGS TO TRY
'   * Add damping: multiply x and y by EXP(-t / 20) (a harmonograph)
'   * Use ratios like 5:4 or 7:6
'   * Leave the previous frame visible in "dim" colour 1
' ============================================================

CONST PI = 3.14159265#
DIM ra(6), rb(6)
FOR i = 1 TO 6: READ ra(i), rb(i): NEXT i

SCREEN 10
sel = 2                    ' current ratio
phase = 0
apage = 1                  ' page we are drawing on
DO
    ' Draw on the hidden page, keep showing the other one.
    SCREEN 10, , apage, 1 - apage
    CLS

    ' ---- The graticule: a 10 x 8 grid of dotted lines -------------
    FOR gx = 70 TO 570 STEP 50
        LINE (gx, 25)-(gx, 325), 1, , &H8888
    NEXT gx
    FOR gy = 25 TO 325 STEP 37.5
        LINE (70, gy)-(570, gy), 1, , &H8888
    NEXT gy
    LINE (70, 25)-(570, 325), 3, B          ' screen border
    LINE (320, 25)-(320, 325), 1            ' centre cross
    LINE (70, 175)-(570, 175), 1

    ' ---- The trace -----------------------------------------------
    a = ra(sel): b = rb(sel)
    ' The x amplitude is 230 pixels, the y amplitude is 140. The
    ' different sizes make up for SCREEN 10's tall pixels.
    PSET (320 + 230 * SIN(phase), 175), 3
    FOR t = 0 TO 2 * PI + .01 STEP .02
        LINE -(320 + 230 * SIN(a * t + phase), 175 - 140 * SIN(b * t)), 3
    NEXT t

    LOCATE 1, 10: PRINT USING "X:Y = #:#    phase = ###.# deg"; a; b; (phase * 180 / PI)
    LOCATE 25, 10: PRINT "1-6 = ratio   Q = quit";

    ' Show the page we just finished, and draw on the other next time.
    SCREEN 10, , apage, apage
    apage = 1 - apage

    phase = phase + .03
    IF phase > 2 * PI THEN phase = phase - 2 * PI

    k$ = UCASE$(INKEY$)
    IF k$ >= "1" AND k$ <= "6" THEN sel = VAL(k$)
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    t! = TIMER: DO: LOOP WHILE TIMER - t! < .03 AND TIMER >= t!
LOOP

SCREEN 0: WIDTH 80
END

' Frequency ratios X:Y
DATA 1,1, 1,2, 3,2, 3,4, 5,4, 5,6
