' ============================================================
' TITLE:    A* Pathfinding Demo
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Advanced
' TAGS:     pathfinding, a-star, ai, heuristics, grid, games
' SUMMARY:  Watch the A* algorithm search a text-mode map and trace the shortest route.
' ------------------------------------------------------------
' WHAT IT DOES
'   A* ("A star") is how game characters find their way around
'   walls.  Every square gets a score:
'        f = g + h
'     g = steps already taken from the start (known exactly)
'     h = a GUESS of the steps still to go (here the Manhattan
'         distance: |dx| + |dy|, which never over-estimates)
'   A* always expands the "open" square with the smallest f next.
'   Because h is never too big, the first time it reaches the goal
'   it has found a SHORTEST path - while looking at far fewer
'   squares than a blind flood-fill would.
'   Colours:  yellow + = open (waiting),  blue . = closed (done),
'             green * = the final path.
'
' HOW TO USE
'   Space  run A* on the current map (animated)
'   R      make a new random map
'   H      toggle the heuristic on/off (off = plain Dijkstra search)
'   Esc    quit
'
' CONCEPTS YOU WILL LEARN
'   * The open list / closed list idea
'   * Admissible heuristics and why they guarantee shortest paths
'   * Rebuilding a path by following "parent" links backwards
'   * Comparing A* with Dijkstra by counting expanded squares
'
' THINGS TO TRY
'   * Allow diagonal moves (8 neighbours) with a cost of 1.4
'   * Make some squares "mud" that cost 3 to cross
'   * Multiply h by 2 - faster, but are the paths still shortest?
' ============================================================

DEFINT A-Z
CONST W = 60, H = 20, TOP = 3
DIM SHARED wall(1 TO W, 1 TO H)
DIM gc(1 TO W, 1 TO H), fc(1 TO W, 1 TO H)
DIM state(1 TO W, 1 TO H)          ' 0 = new, 1 = open, 2 = closed
DIM par(1 TO W, 1 TO H)            ' direction we came from (0-3)
DIM dx(0 TO 3), dy(0 TO 3)
DATA 1,0, -1,0, 0,1, 0,-1
FOR d = 0 TO 3: READ dx(d), dy(d): NEXT
RANDOMIZE TIMER
useH = 1
sx = 2: sy = 2: gx = W - 1: gy = H - 1
GOSUB NewMap

DO
  k$ = UCASE$(INKEY$)
  SELECT CASE k$
    CASE CHR$(27): EXIT DO
    CASE "R": GOSUB NewMap
    CASE "H"
      useH = 1 - useH
      GOSUB DrawMap
    CASE " "
      GOSUB DrawMap
      GOSUB Search
  END SELECT
LOOP
COLOR 7: CLS: PRINT "Path found. Bye!"
END

' ---------------- build a random map ----------------
NewMap:
  FOR x = 1 TO W: FOR y = 1 TO H
    ' a border all round, plus about 22% random wall blocks
    IF x = 1 OR y = 1 OR x = W OR y = H THEN
      wall(x, y) = 1
    ELSE
      wall(x, y) = (RND < .22) * -1     ' a true comparison is -1 in BASIC
    END IF
  NEXT y, x
  ' add a few long walls with gaps so the search must go around
  FOR i = 1 TO 4
    x = 10 + i * 10
    FOR y = 2 TO H - 1: wall(x, y) = 1: NEXT
    gap = INT(RND * (H - 2)) + 2         ' one doorway, cleared on both sides
    wall(x - 1, gap) = 0: wall(x, gap) = 0: wall(x + 1, gap) = 0
  NEXT
  ' keep the squares around the start and goal clear
  FOR x = 2 TO 4: FOR y = 2 TO 4: wall(x, y) = 0: NEXT y, x
  FOR x = W - 3 TO W - 1: FOR y = H - 3 TO H - 1: wall(x, y) = 0: NEXT y, x
  GOSUB DrawMap
RETURN

DrawMap:
  CLS
  COLOR 14: PRINT "A* PATHFINDING";: COLOR 7
  IF useH THEN PRINT "  (heuristic ON: A*)" ELSE PRINT "  (heuristic OFF: Dijkstra)"
  PRINT "Space = search   R = new map   H = heuristic on/off   Esc = quit"
  FOR y = 1 TO H
    LOCATE y + TOP, 1
    FOR x = 1 TO W
      IF wall(x, y) THEN COLOR 8: PRINT CHR$(219); ELSE PRINT " ";
    NEXT
  NEXT
  LOCATE sy + TOP, sx: COLOR 15: PRINT "S";
  LOCATE gy + TOP, gx: COLOR 12: PRINT "G";
  COLOR 7
RETURN

' ---------------- the A* search itself ----------------
Search:
  FOR x = 1 TO W: FOR y = 1 TO H: state(x, y) = 0: NEXT y, x
  gc(sx, sy) = 0
  fc(sx, sy) = useH * (ABS(gx - sx) + ABS(gy - sy))
  state(sx, sy) = 1
  expanded = 0: found = 0
  DO
    ' 1. pick the open square with the lowest f (ties: lowest h,
    '    i.e. the one that looks closest to the goal)
    best = 32000: bx = 0
    FOR y = 2 TO H - 1
      FOR x = 2 TO W - 1
        IF state(x, y) = 1 THEN
          IF fc(x, y) < best OR (fc(x, y) = best AND fc(x, y) - gc(x, y) < bh) THEN
            best = fc(x, y): bh = fc(x, y) - gc(x, y): bx = x: by = y
          END IF
        END IF
      NEXT
    NEXT
    IF bx = 0 THEN EXIT DO                 ' open list empty: no path exists
    IF bx = gx AND by = gy THEN found = 1: EXIT DO

    ' 2. move it to the closed list
    state(bx, by) = 2: expanded = expanded + 1
    IF NOT (bx = sx AND by = sy) THEN LOCATE by + TOP, bx: COLOR 9: PRINT ".";

    ' 3. look at its 4 neighbours
    FOR d = 0 TO 3
      nx = bx + dx(d): ny = by + dy(d)
      IF wall(nx, ny) = 0 AND state(nx, ny) <> 2 THEN
        ng = gc(bx, by) + 1
        ' new square, or a shorter way to an open one?  record it.
        IF state(nx, ny) = 0 OR ng < gc(nx, ny) THEN
          gc(nx, ny) = ng
          fc(nx, ny) = ng + useH * (ABS(gx - nx) + ABS(gy - ny))
          par(nx, ny) = d
          IF state(nx, ny) = 0 AND NOT (nx = gx AND ny = gy) THEN
            LOCATE ny + TOP, nx: COLOR 14: PRINT "+";
          END IF
          state(nx, ny) = 1
        END IF
      END IF
    NEXT
    k$ = INKEY$: IF k$ = CHR$(27) THEN RETURN
  LOOP

  LOCATE H + TOP + 1, 1: COLOR 7
  IF found = 0 THEN
    COLOR 12: PRINT "No path! The goal is walled off. Press R for a new map.";
  ELSE
    ' 4. walk backwards from the goal using the parent directions
    x = gx: y = gy: length = 0
    DO UNTIL x = sx AND y = sy
      d = par(x, y)
      x = x - dx(d): y = y - dy(d)
      length = length + 1
      IF NOT (x = sx AND y = sy) THEN LOCATE y + TOP, x: COLOR 10: PRINT "*";
    LOOP
    LOCATE H + TOP + 1, 1: COLOR 11
    PRINT "Path length"; length; "  squares expanded"; expanded; " ";
  END IF
  COLOR 7
RETURN
