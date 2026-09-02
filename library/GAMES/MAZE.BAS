' ============================================================
' TITLE:    Maze Runner
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     maze generation, depth-first search, stack, text mode, timer
' SUMMARY:  Race through freshly generated mazes, grabbing gems before the clock runs out.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every level builds a brand-new random maze using the "recursive
'   backtracker" algorithm.  You start in the top-left corner and must
'   reach the exit (E) in the bottom-right.  Gems (*) scattered in the
'   maze give bonus points and extra seconds.  Each level has a time
'   limit; the time you have left is added to your score.
'
' HOW TO USE
'   Arrow keys move.  Esc quits.
'   Tip: walking into dead ends costs time - look ahead!
'
' CONCEPTS YOU WILL LEARN
'   * Maze generation by depth-first search with an explicit stack
'   * Grids where odd positions are rooms and even positions are walls
'   * Picking a random unvisited neighbour
'   * A countdown clock using TIMER
'
' THINGS TO TRY
'   * Show the solution path (search from exit back to start)
'   * Add a monster that wanders the corridors
'   * Make the maze "braided" by knocking out a few extra walls
' ============================================================

DEFINT A-Z
CONST GW = 39, GH = 23                 ' grid size (must be odd numbers)
DIM g(0 TO GW - 1, 0 TO GH - 1)        ' 1 = wall, 0 = path, 2 = gem
DIM stkX(1 TO GW * GH), stkY(1 TO GW * GH)
DIM ddx(0 TO 3), ddy(0 TO 3)
DATA 0,-2, 2,0, 0,2, -2,0
FOR i = 0 TO 3: READ ddx(i), ddy(i): NEXT
DIM opts(0 TO 3)
DIM t0 AS SINGLE, timeLeft AS SINGLE

RANDOMIZE TIMER
level = 1: score = 0

NewLevel:
  ' ================= build the maze =================
  ' Start with solid wall everywhere.  The "rooms" are the cells with
  ' odd x and odd y; walls sit between them.
  FOR y = 0 TO GH - 1: FOR x = 0 TO GW - 1: g(x, y) = 1: NEXT: NEXT
  sp = 1: stkX(1) = 1: stkY(1) = 1: g(1, 1) = 0
  DO WHILE sp > 0
    cx = stkX(sp): cy = stkY(sp)
    ' collect the neighbouring rooms (2 steps away) still unvisited
    n = 0
    FOR d = 0 TO 3
      nx = cx + ddx(d): ny = cy + ddy(d)
      IF nx > 0 AND nx < GW - 1 AND ny > 0 AND ny < GH - 1 THEN
        IF g(nx, ny) = 1 THEN opts(n) = d: n = n + 1
      END IF
    NEXT
    IF n = 0 THEN
      sp = sp - 1                      ' dead end: back up ("backtrack")
    ELSE
      d = opts(INT(RND * n))           ' pick one at random
      nx = cx + ddx(d): ny = cy + ddy(d)
      g(cx + ddx(d) \ 2, cy + ddy(d) \ 2) = 0   ' knock down the wall between
      g(nx, ny) = 0
      sp = sp + 1: stkX(sp) = nx: stkY(sp) = ny  ' and go there next
    END IF
  LOOP
  ' scatter gems on random open squares
  gems = 3 + level
  FOR i = 1 TO gems
    DO: x = INT(RND * GW): y = INT(RND * GH): LOOP UNTIL g(x, y) = 0 AND x + y > 4
    g(x, y) = 2
  NEXT

  ' ================= draw it =================
  CLS
  FOR y = 0 TO GH - 1
    LOCATE y + 1, 2
    FOR x = 0 TO GW - 1
      SELECT CASE g(x, y)
        CASE 1: COLOR 1: PRINT CHR$(219); CHR$(219);
        CASE 2: COLOR 14: PRINT "* ";
        CASE ELSE: PRINT "  ";
      END SELECT
    NEXT
  NEXT
  ex = GW - 2: ey = GH - 2                 ' the exit
  LOCATE ey + 1, ex * 2 + 2: COLOR 10: PRINT "E";
  COLOR 7

  px = 1: py = 1
  timeLeft = 40 + level * 10
  t0 = TIMER

  ' ================= play =================
  DO
    LOCATE py + 1, px * 2 + 2: COLOR 15: PRINT CHR$(2); : COLOR 7
    ' the clock
    secsLeft! = timeLeft - (TIMER - t0)
    IF TIMER < t0 THEN t0 = t0 - 86400       ' passed midnight
    LOCATE 25, 2: PRINT USING "LEVEL ##   SCORE ######   TIME ###   "; level; score; secsLeft!;
    PRINT "Arrows move, Esc quits";
    IF secsLeft! <= 0 THEN EXIT DO

    k$ = INKEY$
    IF k$ = CHR$(27) THEN GOTO Quit
    nx = px: ny = py
    IF LEN(k$) = 2 THEN
      SELECT CASE ASC(RIGHT$(k$, 1))
        CASE 72: ny = py - 1
        CASE 80: ny = py + 1
        CASE 75: nx = px - 1
        CASE 77: nx = px + 1
      END SELECT
    END IF
    IF g(nx, ny) <> 1 AND (nx <> px OR ny <> py) THEN
      LOCATE py + 1, px * 2 + 2: COLOR 8: PRINT CHR$(250); : COLOR 7  ' footprints
      px = nx: py = ny
      IF g(px, py) = 2 THEN
        g(px, py) = 0: score = score + 50: timeLeft = timeLeft + 5
        PLAY "MB T255 L32 O4 CEG"
      END IF
      IF px = ex AND py = ey THEN
        bonus = secsLeft! * 10
        score = score + 100 * level + bonus
        LOCATE 12, 28: COLOR 10: PRINT " LEVEL COMPLETE! +"; bonus; " ": COLOR 7
        PLAY "MF T200 L16 CEGCEG>C"
        level = level + 1
        GOTO NewLevel
      END IF
    END IF
  LOOP

' ---- out of time ----
LOCATE 12, 30: COLOR 12: PRINT " OUT OF TIME! ": COLOR 7
LOCATE 13, 27: PRINT " Final score:"; score; "  "
PLAY "MB T100 L8 C <G <E <C"
LOCATE 14, 27: PRINT " Press Esc to exit "
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
COLOR 7, 0: CLS
PRINT "Maze Runner - reached level"; level; "with"; score; "points."
END
