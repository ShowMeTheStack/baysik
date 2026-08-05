' ============================================================
' TITLE:    Keyboard Paint
' CATEGORY: Graphics
' LEVEL:    Advanced
' TAGS:     paint program, cursor, point, pset, line, circle, paint, screen 12
' SUMMARY:  A tiny paint program driven entirely by the keyboard: freehand pen, lines, boxes, circles and flood fill in 16 colours.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a crosshair cursor you move with the arrow keys. You
'   can draw freehand, drop an "anchor" point and then make a
'   line, box or circle from the anchor to the cursor, or flood
'   fill an area. A palette bar at the bottom shows the colours.
'   The cursor never damages your picture because the program
'   remembers the pixels underneath it and puts them back.
'
' HOW TO USE
'   Arrows     move the cursor     Tab   big / small steps
'   Space      pen up / pen down (draws as you move)
'   A          set the anchor point at the cursor
'   L  B  O    line / box / circle from anchor to cursor
'   F          flood fill at the cursor
'   0-9, + -   choose colour (+ and - step through all 16)
'   E          erase everything      Q or Esc   quit
'
' CONCEPTS YOU WILL LEARN
'   * Reading arrow keys: INKEY$ returns CHR$(0) + a scan code
'   * Saving and restoring pixels with POINT and PSET
'   * A simple "state machine": pen up/down, anchor set or not
'   * LINE, LINE ,B, CIRCLE and PAINT used as drawing tools
'   * Keeping a drawing area separate from a status area (VIEW)
'
' THINGS TO TRY
'   * Add a "spray can" that PSETs random dots near the cursor
'   * Add BF for filled boxes on the K key
'   * Save the picture with BSAVE (SCREEN 13 is easiest for that)
' ============================================================

DECLARE SUB ShowStatus ()
DIM SHARED colr, penDown, stepSz, ax, ay, anchorSet
DIM under(1 TO 2, -6 TO 6)        ' pixels hidden by the cursor arms

SCREEN 12
CLS
colr = 15: penDown = 0: stepSz = 1: anchorSet = 0
cx = 320: cy = 220                ' cursor position

' ---- Status area: rows 27-30 (pixels 416..479) -------------------
' The canvas is y = 0..409. We draw a line to separate them.
LINE (0, 410)-(639, 410), 7
' Palette swatches along the bottom
FOR c = 0 TO 15
    LINE (c * 40 + 2, 452)-(c * 40 + 37, 476), c, BF
    LINE (c * 40 + 2, 452)-(c * 40 + 37, 476), 8, B
NEXT c
ShowStatus

GOSUB SaveUnder
GOSUB DrawCursor

DO
    k$ = INKEY$
    IF k$ <> "" THEN
        ' Before changing anything, take the cursor off the picture.
        GOSUB RestoreUnder
        nx = cx: ny = cy
        SELECT CASE UCASE$(k$)
            CASE CHR$(0) + "H": ny = cy - stepSz        ' up arrow
            CASE CHR$(0) + "P": ny = cy + stepSz        ' down
            CASE CHR$(0) + "K": nx = cx - stepSz        ' left
            CASE CHR$(0) + "M": nx = cx + stepSz        ' right
            CASE CHR$(9): IF stepSz = 1 THEN stepSz = 8 ELSE stepSz = 1
            CASE " ": penDown = NOT penDown
                IF penDown THEN PSET (cx, cy), colr
            CASE "A": ax = cx: ay = cy: anchorSet = -1
            CASE "L": IF anchorSet THEN LINE (ax, ay)-(cx, cy), colr
            CASE "B": IF anchorSet THEN LINE (ax, ay)-(cx, cy), colr, B
            CASE "O"
                IF anchorSet THEN
                    ' Radius = distance from anchor to cursor
                    r = SQR((cx - ax) ^ 2 + (cy - ay) ^ 2)
                    CIRCLE (ax, ay), r, colr
                END IF
            CASE "F"
                ' PAINT spreads out until it meets ONE border colour.
                ' We use the current colour as both fill and border,
                ' so an outline drawn in this colour holds the paint
                ' in. (Outlines in other colours will let it leak!)
                IF POINT(cx, cy) <> colr THEN PAINT (cx, cy), colr, colr
            CASE "0" TO "9": colr = VAL(k$)
            CASE "+", "=": colr = (colr + 1) MOD 16
            CASE "-": colr = (colr + 15) MOD 16
            CASE "E": LINE (0, 0)-(639, 409), 0, BF: anchorSet = 0
            CASE "Q", CHR$(27): EXIT DO
        END SELECT

        ' Keep the cursor inside the canvas.
        IF nx < 0 THEN nx = 0
        IF nx > 639 THEN nx = 639
        IF ny < 0 THEN ny = 0
        IF ny > 409 THEN ny = 409

        ' Pen down: draw a line along the path we just moved.
        IF penDown AND (nx <> cx OR ny <> cy) THEN LINE (cx, cy)-(nx, ny), colr
        cx = nx: cy = ny

        ShowStatus
        GOSUB SaveUnder
        GOSUB DrawCursor
    END IF
LOOP

SCREEN 0: WIDTH 80
END

' ---- Cursor helpers (GOSUB routines share all main variables) ------
' The cursor is a "+" with arms 6 pixels long. under(1, i) holds the
' horizontal arm's pixels, under(2, i) the vertical arm's.
SaveUnder:
    FOR i = -6 TO 6
        under(1, i) = POINT(cx + i, cy)       ' -1 if off screen
        under(2, i) = POINT(cx, cy + i)
    NEXT i
RETURN

DrawCursor:
    ' Draw in a colour that contrasts with the pixel underneath.
    FOR i = -6 TO 6
        IF i <> 0 THEN
            IF under(1, i) = 15 THEN PSET (cx + i, cy), 8 ELSE PSET (cx + i, cy), 15
            IF under(2, i) = 15 THEN PSET (cx, cy + i), 8 ELSE PSET (cx, cy + i), 15
        END IF
    NEXT i
RETURN

RestoreUnder:
    ' Put back the vertical arm first, then the horizontal one, so
    ' the centre pixel ends up correct either way.
    FOR i = -6 TO 6
        IF under(2, i) >= 0 THEN PSET (cx, cy + i), under(2, i)
    NEXT i
    FOR i = -6 TO 6
        IF under(1, i) >= 0 THEN PSET (cx + i, cy), under(1, i)
    NEXT i
RETURN

' ---- Status line ------------------------------------------------------
SUB ShowStatus
    LOCATE 27, 1
    COLOR 7
    PRINT "Colour:"; colr; " ";
    LINE (104, 418)-(132, 430), colr, BF     ' a swatch of the colour
    LINE (104, 418)-(132, 430), 7, B
    LOCATE 27, 19
    IF penDown THEN PRINT "Pen DOWN"; ELSE PRINT "Pen up  ";
    IF stepSz = 1 THEN PRINT "  Step 1 "; ELSE PRINT "  Step 8 ";
    IF anchorSet THEN PRINT USING "  Anchor ###/###"; ax; ay; ELSE PRINT "  No anchor     ";
    LOCATE 28, 1
    PRINT "Arrows Tab Space=pen A=anchor L/B/O=line/box/circle F=fill 0-9+-=colour E Q";
END SUB
