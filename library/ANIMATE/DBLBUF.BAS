' ============================================================
' TITLE:    Double Buffering Lab
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     double buffering, page flipping, SCREEN 9, flicker
' SUMMARY:  Compare flickery single-buffer drawing with smooth double buffering by swapping two video pages.
' ------------------------------------------------------------
' WHAT IT DOES
'   Animates a spinning wagon wheel and a bouncing box.  It can
'   draw them in two ways:
'     SINGLE buffer: clear the visible screen and redraw it.  You
'       can catch the picture half-drawn, so it flickers.
'     DOUBLE buffer: SCREEN 9 has two pages.  We draw on the
'       hidden one, then SWAP which page is visible.  Next frame
'       we draw on the other one.  Nothing is copied - the two
'       pages just trade jobs, like two flip-chart sheets.
'
' HOW TO USE
'   S = single buffering, D = double buffering, Esc = quit.
'   Watch the top-left label to see which mode is active.
'
' CONCEPTS YOU WILL LEARN
'   * SCREEN 9, , apage, vpage  with apage and vpage alternating
'   * The "ping-pong" trick: page = 1 - page
'   * Why drawing on a visible screen causes flicker
'   * Rotating points with COS and SIN
'
' THINGS TO TRY
'   * Add more spokes, or make the wheel roll across the screen
'   * Compare with PAGEFLIP.BAS which uses PCOPY instead
' ============================================================
DEFINT A-Z
CONST PI = 3.14159

SCREEN 9                  ' 640x350, 16 colors, 2 video pages
dbl = -1                  ' start in double-buffer mode (-1 = true)
drawPage = 1              ' the page we will draw on next
ang! = 0
bx = 100: by = 60: dx = 5: dy = 3
frames& = 0

DO
    ' ---- choose where to draw ------------------------------
    IF dbl THEN
        ' Draw on the hidden page; keep showing the other one.
        SCREEN 9, , drawPage, 1 - drawPage
    ELSE
        ' Draw straight onto the page we are looking at.
        SCREEN 9, , 0, 0
    END IF

    CLS                   ' in single mode you SEE this blank screen!

    ' ---- the wheel -----------------------------------------
    cx = 320: cy = 190: r = 120
    CIRCLE (cx, cy), r, 6
    CIRCLE (cx, cy), r - 6, 6
    FOR s = 0 TO 11
        ' Each spoke points at angle ang + s*30 degrees.
        a! = ang! + s * PI / 6
        ' SCREEN 9 pixels are taller than wide, so y is squashed
        ' by 0.73 to keep the wheel looking round.
        LINE (cx, cy)-(cx + r * COS(a!), cy + r * SIN(a!) * .73), 14
    NEXT
    CIRCLE (cx, cy), 10, 4: PAINT (cx, cy), 4, 4
    ang! = ang! + .05

    ' ---- the bouncing box ----------------------------------
    bx = bx + dx: by = by + dy
    IF bx < 0 OR bx > 590 THEN dx = -dx
    IF by < 20 OR by > 300 THEN dy = -dy
    LINE (bx, by)-(bx + 50, by + 40), 10, BF
    LINE (bx, by)-(bx + 50, by + 40), 15, B

    ' ---- labels --------------------------------------------
    frames& = frames& + 1
    LOCATE 1, 1
    IF dbl THEN PRINT "DOUBLE buffer"; ELSE PRINT "SINGLE buffer";
    PRINT "   frame"; frames&; "   S=single D=double Esc=quit"

    ' ---- show the frame ------------------------------------
    IF dbl THEN
        ' Make the page we just finished visible, and switch to
        ' drawing on the other page next time.
        SCREEN 9, , drawPage, drawPage
        drawPage = 1 - drawPage
    END IF
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8      ' one frame = one screen refresh

    k$ = UCASE$(INKEY$)
    IF k$ = "S" THEN dbl = 0
    IF k$ = "D" THEN dbl = -1
LOOP UNTIL k$ = CHR$(27)

SCREEN 0, , 0, 0: WIDTH 80
