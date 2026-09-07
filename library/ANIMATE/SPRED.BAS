' ============================================================
' TITLE:    Sprite Editor and Animator
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     sprite editor, pixel art, GET, PUT, files, keyboard
' SUMMARY:  Paint a two-frame 16x16 sprite with the keyboard, then press A to watch it come alive and bounce around.
' ------------------------------------------------------------
' WHAT IT DOES
'   A tiny pixel-art editor.  The big grid on the left is a
'   zoomed-in view of a 16x16 sprite; next to it you see both
'   animation frames at real size.  Draw with the arrow keys and
'   SPACE, then press A: the frames are captured with GET and the
'   sprite runs around the screen, flipping between frame 1 and
'   frame 2 like a cartoon.  You can save your art to a file and
'   load it again later.
'
' HOW TO USE
'   Arrows     move the cursor          SPACE   paint a pixel
'   [  ]       choose color             X       erase pixel
'   TAB        switch frame 1 / 2       K       copy this frame to the other
'   C          clear frame              M       mirror frame left-right
'   S / L      save / load SPRITE.DAT   A       animate!
'   Esc        quit
'
' CONCEPTS YOU WILL LEARN
'   * A 3-D array: pix(frame, x, y) holds every pixel
'   * Drawing a zoomed grid: each pixel becomes an 8x8 box
'   * Turning your drawing into sprites with GET, playing it
'     with PUT
'   * Saving and loading data with OPEN ... FOR OUTPUT / INPUT
'   * Handling "file not found" with ON ERROR
'
' THINGS TO TRY
'   * Add a third frame
'   * Add a "fill" key that floods an area with the color
' ============================================================
DEFINT A-Z
DECLARE SUB DrawCell (x, y)
DECLARE SUB DrawAll ()
DECLARE SUB Status (m$)

CONST Z = 8                        ' zoom: each sprite pixel = 8x8 screen pixels
CONST GX = 8, GY = 16              ' top-left of the editing grid
DIM SHARED pix(1, 15, 15)          ' two frames of 16x16 colors
DIM SHARED fr, cx, cy, curCol
DIM SHARED loadErr
DIM sprA(170), sprB(170)           ' sprites: 4 + 18*18 = 328 bytes = 164 integers

SCREEN 13
' A little starter sprite (a smiley) so there is something to animate.
FOR f = 0 TO 1
    FOR y = 0 TO 15
        READ row$
        FOR x = 0 TO 15
            ch$ = MID$(row$, x + 1, 1)
            IF ch$ = "#" THEN pix(f, x, y) = 14       ' yellow face
            IF ch$ = "o" THEN pix(f, x, y) = 1        ' blue eyes
            IF ch$ = "m" THEN pix(f, x, y) = 4        ' red mouth
        NEXT
    NEXT
NEXT
' Frame 1: smiling, eyes open        Frame 2: mouth open, blinking
DATA "................",".....######.....","...##########...","..############..","..###oo##oo###..",".####oo##oo####.",".##############.",".##############."
DATA ".##m########m##.",".###m######m###.","..###mmmmmm###..","..############..","...##########...",".....######.....","................","................"
DATA "................",".....######.....","...##########...","..############..","..############..",".####oo##oo####.",".##############.",".##############."
DATA ".#####mmmm#####.",".####m####m####.","..###m####m###..","..####mmmm####..","...##########...",".....######.....","................","................"

curCol = 12: cx = 8: cy = 8
DrawAll
DO
    k$ = UCASE$(INKEY$)
    IF k$ <> "" THEN
        ox = cx: oy = cy
        SELECT CASE k$
            CASE CHR$(0) + "H": cy = (cy + 15) MOD 16      ' up (wraps)
            CASE CHR$(0) + "P": cy = (cy + 1) MOD 16       ' down
            CASE CHR$(0) + "K": cx = (cx + 15) MOD 16      ' left
            CASE CHR$(0) + "M": cx = (cx + 1) MOD 16       ' right
            CASE " ": pix(fr, cx, cy) = curCol
            CASE "X": pix(fr, cx, cy) = 0
            CASE "[": curCol = (curCol + 15) MOD 16: DrawAll
            CASE "]": curCol = (curCol + 1) MOD 16: DrawAll
            CASE CHR$(9): fr = 1 - fr: DrawAll
            CASE "C"
                FOR y = 0 TO 15: FOR x = 0 TO 15: pix(fr, x, y) = 0: NEXT: NEXT
                DrawAll
            CASE "K"
                FOR y = 0 TO 15: FOR x = 0 TO 15: pix(1 - fr, x, y) = pix(fr, x, y): NEXT: NEXT
                DrawAll
                Status "Copied to frame" + STR$(2 - fr)
            CASE "M"
                ' Mirror: swap pixel x with pixel 15-x on every row.
                FOR y = 0 TO 15: FOR x = 0 TO 7
                    SWAP pix(fr, x, y), pix(fr, 15 - x, y)
                NEXT: NEXT
                DrawAll
            CASE "S": GOSUB SaveFile
            CASE "L": GOSUB LoadFile
            CASE "A": GOSUB Animate: DrawAll
        END SELECT
        DrawCell ox, oy: DrawCell cx, cy   ' redraw old & new cursor spot
    END IF
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

SaveFile:
    OPEN "SPRITE.DAT" FOR OUTPUT AS #1
    FOR f = 0 TO 1: FOR y = 0 TO 15: FOR x = 0 TO 15
        PRINT #1, pix(f, x, y)
    NEXT: NEXT: NEXT
    CLOSE #1
    Status "Saved SPRITE.DAT"
    RETURN

LoadFile:
    loadErr = 0
    ON ERROR GOTO NoFile
    OPEN "SPRITE.DAT" FOR INPUT AS #1
    ON ERROR GOTO 0
    IF loadErr THEN Status "No SPRITE.DAT yet - press S first": RETURN
    FOR f = 0 TO 1: FOR y = 0 TO 15: FOR x = 0 TO 15
        IF NOT EOF(1) THEN INPUT #1, pix(f, x, y)
    NEXT: NEXT: NEXT
    CLOSE #1
    DrawAll
    Status "Loaded SPRITE.DAT"
    RETURN

NoFile:
    loadErr = -1
    RESUME NEXT

Animate:
    ' 1. Draw both frames on a clean screen with a 1-pixel black
    '    border and GET them (18x18 boxes).  The border erases the
    '    previous position when the sprite moves 1 pixel.
    CLS
    FOR f = 0 TO 1
        FOR y = 0 TO 15: FOR x = 0 TO 15
            PSET (1 + x + f * 20, 1 + y), pix(f, x, y)
        NEXT: NEXT
    NEXT
    GET (0, 0)-(17, 17), sprA
    GET (20, 0)-(37, 17), sprB
    CLS
    COLOR 7: LOCATE 25, 1: PRINT "Any key = back to the editor";
    ' 2. Bounce it around, switching frames every 10 moves.
    x = 50: y = 40: dx = 1: dy = 1: n = 0
    DO
        IF (n \ 10) MOD 2 = 0 THEN PUT (x, y), sprA, PSET ELSE PUT (x, y), sprB, PSET
        x = x + dx: y = y + dy: n = n + 1
        IF x <= 0 OR x >= 319 - 18 THEN dx = -dx
        IF y <= 0 OR y >= 185 - 18 THEN dy = -dy
        WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    LOOP WHILE INKEY$ = ""
    RETURN

SUB DrawAll
    CLS
    ' The grid
    FOR y = 0 TO 15: FOR x = 0 TO 15: DrawCell x, y: NEXT: NEXT
    LINE (GX - 1, GY - 1)-(GX + 16 * Z, GY + 16 * Z), 7, B
    ' Real-size previews of both frames (the current one is boxed)
    FOR f = 0 TO 1
        px = 160 + f * 40: py = 30
        FOR y = 0 TO 15: FOR x = 0 TO 15
            PSET (px + x, py + y), pix(f, x, y)
        NEXT: NEXT
        IF f = fr THEN bc = 15 ELSE bc = 8
        LINE (px - 2, py - 2)-(px + 17, py + 17), bc, B
    NEXT
    COLOR 7
    LOCATE 2, 20: PRINT "Frame 1  Frame 2"
    ' Palette bar: 16 colors, current one marked.
    FOR c = 0 TO 15
        LINE (160 + (c MOD 8) * 18, 70 + (c \ 8) * 18)-STEP(15, 15), c, BF
        IF c = curCol THEN LINE (159 + (c MOD 8) * 18, 69 + (c \ 8) * 18)-STEP(17, 17), 15, B
    NEXT
    LOCATE 15, 21: PRINT "Arrows SPACE X [ ]"
    LOCATE 16, 21: PRINT "TAB frame  K copy"
    LOCATE 17, 21: PRINT "C clear  M mirror"
    LOCATE 18, 21: PRINT "S save  L load"
    LOCATE 19, 21: PRINT "A animate  Esc quit"
END SUB

SUB DrawCell (x, y)
    ' One sprite pixel as a zoomed box; color 0 shows a faint dot
    ' so you can see the empty grid.  The cursor gets a white frame.
    sx = GX + x * Z: sy = GY + y * Z
    LINE (sx, sy)-STEP(Z - 1, Z - 1), pix(fr, x, y), BF
    IF pix(fr, x, y) = 0 THEN PSET (sx + Z \ 2, sy + Z \ 2), 8
    IF x = cx AND y = cy THEN
        IF pix(fr, x, y) = 15 THEN cc = 8 ELSE cc = 15   ' visible on white too
        LINE (sx, sy)-STEP(Z - 1, Z - 1), cc, B
    END IF
    ' keep the real-size preview up to date too
    PSET (160 + fr * 40 + x, 30 + y), pix(fr, x, y)
END SUB

SUB Status (m$)
    LOCATE 23, 1: PRINT SPACE$(39);
    LOCATE 23, 1: PRINT m$;
END SUB
