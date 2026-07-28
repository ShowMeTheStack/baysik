' ============================================================
' TITLE:    Flood Fill: Stack vs Queue
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     flood fill, stack, queue, graphics, grids
' SUMMARY:  The paint-bucket tool, built two ways: a stack makes it snake around like DFS, a queue spreads like a ripple (BFS).
' ------------------------------------------------------------
' WHAT IT DOES
'   Makes a random "cave" map on a 40 x 25 grid of blocks, then fills
'   the open area around the centre, the way the paint-bucket tool in
'   a paint program does.  The fill colour changes as the fill goes
'   on, so you can SEE the order in which cells were reached:
'     STACK (depth-first)   - runs down long corridors first
'     QUEUE (breadth-first) - grows in rings, like ripples in a pond
'
' HOW TO USE
'   1 = fill using a stack     2 = fill using a queue
'   N = new random map         Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Grids as 2-D arrays and the 4 neighbours of a cell
'   * Replacing recursion with an explicit stack (no stack overflow!)
'   * Stack = last in, first out; queue = first in, first out
'   * Marking cells when they are PUSHED so nothing is added twice
'   * Each cell is handled once: O(width * height)
'
' THINGS TO TRY
'   * Add the 4 diagonal neighbours (8-way fill) and watch it leak
'   * Compare with QBasic's built-in PAINT statement
' ============================================================
DECLARE SUB NewMap ()
DECLARE SUB DrawCell (x%, y%, c%)
DECLARE SUB Fill (useQueue%)
DEFINT A-Z
CONST W = 40, H = 24          ' grid size in cells (8 x 8 pixel blocks)
CONST WALL = 1, FLOOR = 0, DONE = 2
DIM SHARED g(0 TO W - 1, 0 TO H - 1)
' The "to do" list.  We store x and y in two arrays.  Each cell can
' be added at most once, so W * H slots is always enough.
DIM SHARED tx(1 TO W * H), ty(1 TO W * H)
DIM SHARED dx(1 TO 4), dy(1 TO 4)
dx(1) = 1: dy(1) = 0          ' right
dx(2) = -1: dy(2) = 0         ' left
dx(3) = 0: dy(3) = 1          ' down
dx(4) = 0: dy(4) = -1         ' up

SCREEN 13
RANDOMIZE TIMER
NewMap
DO
    LOCATE 25, 1: PRINT "1=stack 2=queue N=new Q=quit";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "1": Fill 0
        CASE "2": Fill -1
        CASE "N": NewMap
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0: WIDTH 80
END

SUB DrawCell (x, y, c)
    LINE (x * 8, y * 8)-(x * 8 + 7, y * 8 + 7), c, BF
END SUB

' --------------------------------------------------------------
' Fill from the centre.  The SAME loop does DFS or BFS - the only
' difference is which end of the to-do list we take the next cell
' from:
'   stack: take the NEWEST item (top = last added)
'   queue: take the OLDEST item (head = first added)
' For each cell we take, look at its 4 neighbours; any OPEN one is
' marked DONE immediately and added to the list.
' --------------------------------------------------------------
SUB Fill (useQueue)
    ' reset any previous fill back to open
    FOR y = 0 TO H - 1: FOR x = 0 TO W - 1
        IF g(x, y) = DONE THEN g(x, y) = FLOOR: DrawCell x, y, 0
    NEXT x, y
    sx = W \ 2: sy = H \ 2
    g(sx, sy) = DONE
    head = 1: tail = 1                  ' list holds items head..tail
    tx(1) = sx: ty(1) = sy
    order = 0
    DO WHILE tail >= head
        IF useQueue THEN
            cx = tx(head): cy = ty(head): head = head + 1     ' dequeue
        ELSE
            cx = tx(tail): cy = ty(tail): tail = tail - 1     ' pop
        END IF
        ' colour by visiting order: cycles through the 24 bright rainbow hues 32..55
        order = order + 1
        DrawCell cx, cy, 32 + (order \ 10) MOD 24
        FOR d& = 1 TO 300: NEXT                ' slow enough to watch
        FOR i = 1 TO 4
            nx = cx + dx(i): ny = cy + dy(i)
            IF nx >= 0 AND nx < W AND ny >= 0 AND ny < H THEN
                IF g(nx, ny) = FLOOR THEN
                    g(nx, ny) = DONE           ' mark now, so it's added once
                    tail = tail + 1
                    tx(tail) = nx: ty(tail) = ny
                END IF
            END IF
        NEXT
        IF INKEY$ = CHR$(27) THEN EXIT DO
    LOOP
    LOCATE 25, 30: PRINT order; "  ";
END SUB

' Random cave: scattered walls plus some solid "rocks".
SUB NewMap
    CLS
    FOR y = 0 TO H - 1
        FOR x = 0 TO W - 1
            IF RND < .28 THEN g(x, y) = WALL ELSE g(x, y) = FLOOR
        NEXT
    NEXT
    FOR r = 1 TO 8                              ' a few round rocks
        cx = INT(RND * W): cy = INT(RND * H): rad = INT(RND * 3) + 1
        FOR y = cy - rad TO cy + rad
            FOR x = cx - rad TO cx + rad
                IF x >= 0 AND x < W AND y >= 0 AND y < H THEN
                    IF (x - cx) ^ 2 + (y - cy) ^ 2 <= rad * rad THEN g(x, y) = WALL
                END IF
            NEXT
        NEXT
    NEXT
    ' keep the start cell and its neighbours open
    FOR y = H \ 2 - 1 TO H \ 2 + 1: FOR x = W \ 2 - 1 TO W \ 2 + 1
        g(x, y) = FLOOR
    NEXT x, y
    FOR y = 0 TO H - 1: FOR x = 0 TO W - 1
        IF g(x, y) = WALL THEN DrawCell x, y, 8
    NEXT x, y
END SUB
