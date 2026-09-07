' ============================================================
' TITLE:    Keyboard Mouse Cursor
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     cursor, GET, PUT, background save, acceleration, GUI
' SUMMARY:  Drive an arrow pointer with the arrow keys - it speeds up as you hold a key - and click buttons on a tiny desktop.
' ------------------------------------------------------------
' WHAT IT DOES
'   No mouse?  No problem.  This program draws its own arrow
'   pointer and moves it with the keyboard, exactly the way old
'   DOS programs drew a "software cursor":
'     1. GET the patch of screen the cursor is about to cover
'     2. draw the cursor on top
'     3. before moving, PUT the saved patch back (erasing the
'        cursor and restoring whatever was underneath)
'   Pressing the same arrow quickly again and again (or holding
'   it down) makes the pointer accelerate, like a real mouse.
'   ENTER "clicks": try the buttons, or doodle on the canvas.
'
' HOW TO USE
'   Arrow keys   move the pointer (hold to speed up)
'   ENTER        click (buttons / draw a dot on the canvas)
'   Esc          quit (or click the QUIT button)
'
' CONCEPTS YOU WILL LEARN
'   * Saving and restoring the background under a sprite
'   * A sprite with transparent pixels drawn from a DATA bitmap
'   * Acceleration using TIMER to see how fast keys repeat
'   * Hit-testing: is the point inside a rectangle?
'
' THINGS TO TRY
'   * Add a fourth button that clears the canvas
'   * Change the arrow shape into a hand or crosshair
' ============================================================
DEFINT A-Z
DECLARE SUB DrawPointer (x, y)
DECLARE SUB Button (n, label$, c)

CONST PW = 11, PH = 16             ' pointer bitmap size
DIM SHARED shape$(PH - 1)
DIM SHARED under(100)              ' 4 + 11*16 = 180 bytes = 90 integers
DIM SHARED bx1(3), by1(3), bx2(3), by2(3)

' The arrow: X = black outline, . = white fill, space = see-through
FOR i = 0 TO PH - 1: READ shape$(i): NEXT
DATA "X          ", "XX         ", "X.X        ", "X..X       "
DATA "X...X      ", "X....X     ", "X.....X    ", "X......X   "
DATA "X.......X  ", "X........X ", "X.....XXXXX", "X..X..X    "
DATA "X.X X..X   ", "XX  X..X   ", "X    X..X  ", "      XX   "

SCREEN 13
' ---- the "desktop" -------------------------------------------
canvas = 3
LINE (0, 0)-(319, 199), canvas, BF
LINE (0, 0)-(319, 12), 1, BF
LINE (0, 13)-(319, 13), 15        ' white edge: stops PAINT entering the title bar
COLOR 15: LOCATE 1, 2: PRINT "Keyboard Mouse - arrows + ENTER";
Button 1, "COLOR", 2
Button 2, "BEEP", 5
Button 3, "QUIT", 4

' ---- pointer state --------------------------------------------
x = 160: y = 100
GET (x, y)-(x + PW - 1, y + PH - 1), under   ' save what is underneath
DrawPointer x, y
speed = 1: lastKey$ = "": lastT! = TIMER

DO
    k$ = INKEY$
    IF k$ = CHR$(27) THEN EXIT DO
    IF LEN(k$) = 2 THEN
        ' ---- acceleration ----------------------------------
        ' If the same arrow arrives again within 0.15 s, the key is
        ' being held down: speed up (to a maximum of 8 pixels).
        now! = TIMER
        IF k$ = lastKey$ AND now! - lastT! < .15 THEN
            IF speed < 8 THEN speed = speed + 1
        ELSE
            speed = 1
        END IF
        lastKey$ = k$: lastT! = now!

        nx = x: ny = y
        SELECT CASE k$
            CASE CHR$(0) + "H": ny = y - speed
            CASE CHR$(0) + "P": ny = y + speed
            CASE CHR$(0) + "K": nx = x - speed
            CASE CHR$(0) + "M": nx = x + speed
        END SELECT
        ' Keep the whole pointer box on the screen (PUT/GET fail
        ' if any part is outside).
        IF nx < 0 THEN nx = 0
        IF ny < 0 THEN ny = 0
        IF nx > 319 - PW + 1 THEN nx = 319 - PW + 1
        IF ny > 199 - PH + 1 THEN ny = 199 - PH + 1

        IF nx <> x OR ny <> y THEN
            PUT (x, y), under, PSET                    ' 1. restore background
            x = nx: y = ny
            GET (x, y)-(x + PW - 1, y + PH - 1), under ' 2. save new spot
            DrawPointer x, y                           ' 3. draw pointer
        END IF
    ELSEIF k$ = CHR$(13) THEN
        ' ---- click! -----------------------------------------
        ' The pointer's "hot spot" is its tip at (x, y).
        PUT (x, y), under, PSET        ' hide pointer while we draw
        hit = 0
        FOR b = 1 TO 3
            IF x >= bx1(b) AND x <= bx2(b) AND y >= by1(b) AND y <= by2(b) THEN hit = b
        NEXT
        SELECT CASE hit
            CASE 1                      ' new canvas color
                canvas = 16 + INT(RND * 200)
                ' PAINT floods everything up to white borders - the
                ' buttons and title bar are fenced off with white.
                PAINT (319, 199), canvas, 15
            CASE 2: SOUND 660, 2: SOUND 880, 2
            CASE 3: EXIT DO
            CASE ELSE
                IF y > 17 THEN CIRCLE (x, y), 2, 15: PAINT (x, y), 15, 15  ' doodle
        END SELECT
        GET (x, y)-(x + PW - 1, y + PH - 1), under
        DrawPointer x, y
    END IF
LOOP

SCREEN 0: WIDTH 80
END

SUB Button (n, label$, c)
    ' Buttons sit in a row near the bottom; remember each box so
    ' clicks can be tested against it later.
    bx1(n) = 20 + (n - 1) * 100: by1(n) = 170
    bx2(n) = bx1(n) + 80: by2(n) = 190
    LINE (bx1(n), by1(n))-(bx2(n), by2(n)), c, BF
    LINE (bx1(n), by1(n))-(bx2(n), by2(n)), 15, B
    COLOR 15
    LOCATE 23, (bx1(n) + 40) \ 8 - LEN(label$) \ 2 + 1: PRINT label$;
END SUB

SUB DrawPointer (x, y)
    ' Draw only the X and . pixels; spaces are left alone, so the
    ' background shows through around the arrow.
    FOR r = 0 TO PH - 1
        FOR c = 0 TO PW - 1
            SELECT CASE MID$(shape$(r), c + 1, 1)
                CASE "X": PSET (x + c, y + r), 0
                CASE ".": PSET (x + c, y + r), 15
            END SELECT
        NEXT
    NEXT
END SUB
