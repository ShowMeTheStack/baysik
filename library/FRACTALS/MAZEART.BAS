' ============================================================
' TITLE:    Rainbow Maze Art
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     generative art, maze, depth-first search, stack, palette cycling
' SUMMARY:  Carves a random maze with a depth-first explorer, painting each corridor by its distance from the start.
' ------------------------------------------------------------
' WHAT IT DOES
'   A maze generator turned into an art machine.  An explorer starts
'   in the middle of a grid of closed rooms.  Again and again it
'   picks a random neighbouring room it has NOT visited yet, knocks
'   down the wall between them and steps in.  When it gets stuck it
'   walks back (using a STACK of where it has been) until it finds a
'   room with an unvisited neighbour.  This is the "recursive
'   backtracker" and it makes a "perfect maze": exactly one path
'   between any two rooms.
'
'   Every room is colored by how many steps it is from the start,
'   along the maze.  Because there is only ONE path to each room,
'   the colors flow like a river delta.  At the end, palette
'   cycling makes the colors stream outward from the centre.
'
' HOW TO USE
'   Watch the maze grow.  Then:
'   Space = new maze    P = pause/run the color flow    Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Depth-first search with an explicit stack (arrays + pointer)
'   * Representing a maze on a grid of pixels
'   * Distance along a tree (each room = parent's distance + 1)
'   * Palette cycling for animation without redrawing
'
' THINGS TO TRY
'   * Start the explorer in a corner instead of the centre
'   * Prefer going straight (pick the same direction 70% of the time)
'   * Color by depth MOD 2 for a zebra pattern
' ============================================================
DEFINT A-Z
DECLARE SUB SetPal (shift)

CONST MW = 52, MH = 31        ' rooms across and down
CONST CS = 6                  ' pixels per room (4 floor + 2 wall)
CONST X0 = 4, Y0 = 4          ' top-left of the maze on screen
DIM seen(MW - 1, MH - 1)      ' 0 = not visited yet
DIM dist(MW - 1, MH - 1)      ' steps from the start
DIM stx(MW * MH), sty(MW * MH) ' the explorer's stack
DIM dx(3), dy(3)              ' the 4 directions
dx(0) = 1: dx(1) = -1: dy(2) = 1: dy(3) = -1
DIM opts(3)                   ' list of possible moves

SCREEN 13
RANDOMIZE TIMER

DO
    SetPal 0
    CLS
    ' Walls everywhere: a dark blue background.
    LINE (X0 - 2, Y0 - 2)-(X0 + MW * CS, Y0 + MH * CS), 255, BF
    FOR y = 0 TO MH - 1: FOR x = 0 TO MW - 1: seen(x, y) = 0: NEXT: NEXT

    ' ---- Start in the middle --------------------------------
    sp = 1: stx(1) = MW \ 2: sty(1) = MH \ 2
    seen(stx(1), sty(1)) = -1: dist(stx(1), sty(1)) = 0
    GOSUB DrawRoom
    k$ = ""
    DO WHILE sp > 0
        cx = stx(sp): cy = sty(sp)
        ' Collect the directions that lead to unvisited rooms.
        n = 0
        FOR d = 0 TO 3
            nx = cx + dx(d): ny = cy + dy(d)
            IF nx >= 0 AND nx < MW AND ny >= 0 AND ny < MH THEN
                IF NOT seen(nx, ny) THEN opts(n) = d: n = n + 1
            END IF
        NEXT
        IF n = 0 THEN
            sp = sp - 1                    ' dead end: backtrack (pop)
        ELSE
            d = opts(INT(RND * n))         ' pick one at random
            nx = cx + dx(d): ny = cy + dy(d)
            seen(nx, ny) = -1
            dist(nx, ny) = dist(cx, cy) + 1
            ' Knock down the wall: fill the gap between the two rooms
            ' with the new room's color.
            c = 1 + dist(nx, ny) MOD 192
            LINE (X0 + cx * CS + dx(d) * 4, Y0 + cy * CS + dy(d) * 4)-STEP(3, 3), c, BF
            sp = sp + 1: stx(sp) = nx: sty(sp) = ny   ' push
            GOSUB DrawRoom
        END IF
        ' Slow down a little so you can watch: every 16 moves wait for
        ' one screen refresh (vertical retrace, bit 3 of port &H3DA).
        moves = moves + 1
        IF moves MOD 16 = 0 THEN
            DO WHILE INP(&H3DA) AND 8: LOOP
            DO UNTIL INP(&H3DA) AND 8: LOOP
        END IF
        k$ = INKEY$
        IF k$ = CHR$(27) THEN EXIT DO
    LOOP
    IF k$ = CHR$(27) THEN EXIT DO

    ' ---- Color flow --------------------------------------------
    shift = 0: running = -1
    DO
        k$ = UCASE$(INKEY$)
        IF k$ = "P" THEN running = NOT running
        IF running THEN
            shift = (shift + 191) MOD 192      ' colors flow outward
            SetPal shift
            ' Wait for one screen refresh to keep a steady speed.
            DO WHILE INP(&H3DA) AND 8: LOOP
            DO UNTIL INP(&H3DA) AND 8: LOOP
        END IF
    LOOP UNTIL k$ = " " OR k$ = CHR$(27)
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Fills the 4x4 floor of room (nx, ny) - or the start room the first
' time - with the color for its distance.
DrawRoom:
    rx = stx(sp): ry = sty(sp)
    c = 1 + dist(rx, ry) MOD 192
    LINE (X0 + rx * CS, Y0 + ry * CS)-STEP(3, 3), c, BF
    RETURN

' Colors 1..192 make a rainbow; "shift" rotates it.
' Color 255 is the dark blue wall color.
SUB SetPal (shift)
    OUT &H3C8, 1
    FOR i = 0 TO 191
        h! = ((i + shift) MOD 192) / 192 * 6.2832
        OUT &H3C9, 32 + 31 * COS(h!)
        OUT &H3C9, 32 + 31 * COS(h! - 2.094)
        OUT &H3C9, 32 + 31 * COS(h! + 2.094)
    NEXT
    OUT &H3C8, 255: OUT &H3C9, 4: OUT &H3C9, 4: OUT &H3C9, 14
END SUB
