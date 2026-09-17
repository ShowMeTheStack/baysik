' ============================================================
' TITLE:    Maze Explorer AI (Wall Follower)
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     maze, ai, robot, right-hand rule, animation, stack
' SUMMARY:  Builds a random maze, then a little robot escapes it by keeping its hand on the wall.
' ------------------------------------------------------------
' WHAT IT DOES
'   First the program carves a random "perfect" maze (exactly one
'   path between any two spots) using the depth-first backtracker:
'   wander randomly, and when stuck, back up along your trail.
'   Then a robot enters at the top-left and uses the oldest maze
'   trick there is - the RIGHT-HAND RULE:
'       1. if there is no wall on your right, turn right and step
'       2. otherwise, if the way ahead is open, step forward
'       3. otherwise, turn left and try again
'   In a maze with no loops this ALWAYS finds the exit, even though
'   the robot has no map and no memory!
'
' HOW TO USE
'   Watch the robot (@) explore.  Its trail is shown with dots.
'   Press L to switch to the LEFT-hand rule for the next maze,
'   N for a new maze, Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Maze generation with an explicit stack (no recursion needed)
'   * Directions as numbers 0-3 with turning done by MOD 4
'   * A "reactive" AI that only looks at its surroundings
'   * Counting steps to compare strategies
'
' THINGS TO TRY
'   * Knock out a few extra walls to make loops - can the rule fail?
'   * Race the right-hand robot against the left-hand robot
'   * Speed it up or slow it down by changing the DELAY constant
' ============================================================

DEFINT A-Z
CONST CW = 19, CH = 10                 ' maze size in cells
CONST GW = CW * 2 + 1, GH = CH * 2 + 1 ' grid size: cells + walls between them
CONST DELAY = .03
DIM g(1 TO GW, 1 TO GH)                ' 1 = wall, 0 = open
DIM stx(1 TO CW * CH), sty(1 TO CW * CH)
DIM dx(0 TO 3), dy(0 TO 3)
' direction 0 = north, 1 = east, 2 = south, 3 = west (clockwise)
DATA 0,-1, 1,0, 0,1, -1,0
FOR d = 0 TO 3: READ dx(d), dy(d): NEXT
RANDOMIZE TIMER
hand = 1                               ' 1 = right hand, -1 = left hand

DO
  ' ================= 1. carve a maze =================
  FOR x = 1 TO GW: FOR y = 1 TO GH: g(x, y) = 1: NEXT y, x
  ' cell (cx, cy) lives at grid square (2*cx, 2*cy)
  sp = 1: stx(1) = 1: sty(1) = 1: g(2, 2) = 0
  DO WHILE sp > 0
    cx = stx(sp): cy = sty(sp)
    ' collect the neighbouring cells that are still solid (unvisited)
    n = 0: opts$ = ""
    FOR d = 0 TO 3
      nx = cx + dx(d): ny = cy + dy(d)
      IF nx >= 1 AND nx <= CW AND ny >= 1 AND ny <= CH THEN
        IF g(nx * 2, ny * 2) = 1 THEN opts$ = opts$ + CHR$(48 + d)
      END IF
    NEXT
    IF opts$ = "" THEN
      sp = sp - 1                      ' dead end: back up the trail
    ELSE
      d = VAL(MID$(opts$, INT(RND * LEN(opts$)) + 1, 1))
      nx = cx + dx(d): ny = cy + dy(d)
      g(cx * 2 + dx(d), cy * 2 + dy(d)) = 0   ' knock down the wall between
      g(nx * 2, ny * 2) = 0                   ' open the new cell
      sp = sp + 1: stx(sp) = nx: sty(sp) = ny
    END IF
  LOOP
  g(1, 2) = 0                           ' entrance on the left
  g(GW, GH - 1) = 0                     ' exit on the right

  ' ================= 2. draw it =================
  CLS
  COLOR 14
  IF hand = 1 THEN PRINT "RIGHT-HAND RULE robot";  ELSE PRINT "LEFT-HAND RULE robot";
  COLOR 7: PRINT "   (L = switch hand, N = new maze, Esc = quit)"
  FOR y = 1 TO GH
    LOCATE y + 2, 2
    FOR x = 1 TO GW
      IF g(x, y) THEN COLOR 1: PRINT CHR$(219); ELSE PRINT " ";
    NEXT
  NEXT
  COLOR 7

  ' ================= 3. let the robot loose =================
  rx = 1: ry = 2: facing = 1            ' start in the doorway, facing east
  steps = 0: quit = 0: again = 0
  DO
    LOCATE ry + 2, rx + 1: COLOR 15: PRINT "@";
    t! = TIMER: DO: LOOP WHILE TIMER - t! < DELAY AND TIMER >= t!
    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(27) THEN quit = 1: EXIT DO
    IF k$ = "N" THEN again = 1: EXIT DO
    IF k$ = "L" THEN hand = -hand: again = 1: EXIT DO
    LOCATE ry + 2, rx + 1: COLOR 2: PRINT CHR$(250);     ' leave a trail dot
    IF rx = GW AND ry = GH - 1 THEN EXIT DO              ' reached the exit!

    ' ---- the wall-following rule ----
    ' "side" is the direction of our hand: facing + 1 (right) or - 1 (left).
    ' Adding 4 before MOD keeps the number from going negative.
    FOR try = 1 TO 4
      IF try = 1 THEN nd = (facing + hand + 4) MOD 4 ELSE nd = (nd - hand + 4) MOD 4
      nx = rx + dx(nd): ny = ry + dy(nd)
      IF nx >= 1 AND nx <= GW AND ny >= 1 AND ny <= GH THEN
        IF g(nx, ny) = 0 THEN EXIT FOR
      END IF
    NEXT
    facing = nd: rx = nx: ry = ny
    steps = steps + 1
  LOOP
  IF quit THEN EXIT DO
  IF again = 0 THEN
    LOCATE GH + 4, 1: COLOR 10
    PRINT "Escaped in"; steps; "steps! Press N for a new maze, L to switch hands, Esc to quit."
    COLOR 7
    DO
      k$ = UCASE$(INKEY$)
    LOOP UNTIL k$ = "N" OR k$ = "L" OR k$ = CHR$(27)
    IF k$ = CHR$(27) THEN EXIT DO
    IF k$ = "L" THEN hand = -hand
  END IF
LOOP
COLOR 7: CLS
PRINT "The robot powers down. Bye!"
