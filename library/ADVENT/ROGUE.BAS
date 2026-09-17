' ============================================================
' TITLE:    Torchlight Roguelike
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Advanced
' TAGS:     roguelike, field of view, line of sight, procedural, dungeon
' SUMMARY:  Explore random dungeons by torchlight - you only see what your light can reach.
' ------------------------------------------------------------
' WHAT IT DOES
'   A tiny "roguelike" in the style of Rogue (1980).  Every level is
'   generated fresh: rooms are dropped at random and joined by
'   L-shaped corridors.  The clever part is FIELD OF VIEW: from the
'   @ a ray is traced to every nearby square; if a wall gets in the
'   way first, that square stays dark.  Squares you have seen
'   before are remembered (drawn dim), but monsters there are hidden.
'   Find the stairs (>) on three levels to escape.  Collect gold ($)
'   and fight goblins (g) and orcs (o) by walking into them.
'
' HOW TO USE
'   Arrow keys or W A S D to move (walk into a monster to attack).
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Procedural generation: rooms + corridors
'   * Line of sight by stepping along a line from you to each square
'   * Three states per square: unseen, remembered, visible now
'   * Redrawing only the area that can change (fast screens)
'   * Simple chase AI: monsters step toward you when they see you
'
' THINGS TO TRY
'   * Change RADIUS to 3 (a candle) or 12 (a lantern)
'   * Add healing potions (!) that restore 10 HP
'   * Make orcs smarter: only chase when they can see you too
' ============================================================

DECLARE SUB MakeLevel ()
DECLARE SUB DrawCell (x%, y%)
DECLARE SUB UpdateView ()
DECLARE SUB Msg (t$)
DECLARE FUNCTION CanSee% (x1%, y1%, x2%, y2%)
DECLARE FUNCTION MonAt% (x%, y%)

DEFINT A-Z
CONST MW = 78, MH = 20, RADIUS = 6, MAXM = 12, TOPROW = 2
CONST WALL = 0, FLOOR = 1, GOLD = 2, STAIRS = 3
DIM SHARED t(1 TO MW, 1 TO MH)         ' what is on each square
DIM SHARED seen(1 TO MW, 1 TO MH)      ' 1 = seen at some time
DIM SHARED vis(1 TO MW, 1 TO MH)       ' 1 = visible right now
DIM SHARED mx(1 TO MAXM), my(1 TO MAXM), mhp(1 TO MAXM), mk$(1 TO MAXM), nMon
DIM SHARED px, py, hp, gp, depth
RANDOMIZE TIMER
hp = 30: gp = 0: depth = 1
COLOR 7: CLS
MakeLevel

DO
  LOCATE 1, 1: COLOR 14
  PRINT "Depth"; depth; "  HP"; hp; "  Gold"; gp; "   arrows/WASD move, Esc quit      ";
  ' ---------- read a key ----------
  DO: k$ = INKEY$: LOOP WHILE k$ = ""
  dx = 0: dy = 0
  SELECT CASE UCASE$(k$)
    CASE CHR$(0) + "H", "W": dy = -1
    CASE CHR$(0) + "P", "S": dy = 1
    CASE CHR$(0) + "K", "A": dx = -1
    CASE CHR$(0) + "M", "D": dx = 1
    CASE CHR$(27): EXIT DO
  END SELECT

  IF dx <> 0 OR dy <> 0 THEN
    nx = px + dx: ny = py + dy
    m = MonAt(nx, ny)
    IF m > 0 THEN
      ' ---- attack! ----
      dmg = INT(RND * 6) + 1
      mhp(m) = mhp(m) - dmg
      IF mhp(m) <= 0 THEN
        Msg "You slay the " + mk$(m) + "!"
        mhp(m) = 0
        DrawCell nx, ny
      ELSE
        Msg "You hit the " + mk$(m) + " for" + STR$(dmg) + "."
      END IF
    ELSEIF t(nx, ny) <> WALL THEN
      ox = px: oy = py
      px = nx: py = ny
      DrawCell ox, oy
      IF t(px, py) = GOLD THEN
        g = INT(RND * 10 * depth) + 5
        gp = gp + g: t(px, py) = FLOOR
        Msg "You pick up" + STR$(g) + " gold."
      ELSEIF t(px, py) = STAIRS THEN
        IF depth = 3 THEN
          COLOR 10: CLS
          PRINT "You climb the last stairs into the sunlight with"; gp; "gold!"
          PRINT "YOU ESCAPED THE DUNGEON."
          COLOR 7: END
        END IF
        depth = depth + 1
        Msg "You go down the stairs..."
        MakeLevel
      ELSE
        Msg ""
      END IF
    END IF

    ' ---------- monsters' turn ----------
    FOR m = 1 TO nMon
      IF mhp(m) > 0 THEN
        ddx = SGN(px - mx(m)): ddy = SGN(py - my(m))
        IF ABS(px - mx(m)) <= 1 AND ABS(py - my(m)) <= 1 THEN
          d = INT(RND * 3) + depth - 1
          hp = hp - d
          IF d > 0 THEN Msg "The " + mk$(m) + " hits you for" + STR$(d) + "!"
        ELSEIF vis(mx(m), my(m)) THEN
          ' it can see you: step toward you (try straight, then each axis)
          nx = mx(m) + ddx: ny = my(m) + ddy
          IF t(nx, ny) = WALL OR MonAt(nx, ny) THEN nx = mx(m) + ddx: ny = my(m)
          IF t(nx, ny) = WALL OR MonAt(nx, ny) THEN nx = mx(m): ny = my(m) + ddy
          IF t(nx, ny) <> WALL AND MonAt(nx, ny) = 0 AND NOT (nx = px AND ny = py) THEN
            ox = mx(m): oy = my(m)
            mx(m) = nx: my(m) = ny
            DrawCell ox, oy
          END IF
        END IF
      END IF
    NEXT
    IF hp <= 0 THEN
      COLOR 12: LOCATE 24, 1: PRINT "You have died on depth"; depth; "with"; gp; "gold. Press Esc.";
      DO: LOOP UNTIL INKEY$ = CHR$(27)
      EXIT DO
    END IF
    UpdateView
  END IF
LOOP
COLOR 7: CLS
PRINT "Thanks for playing Torchlight."

' Can (x1,y1) see (x2,y2)?  Walk along the straight line between
' them in small even steps; if any square on the way is a wall,
' the view is blocked.  (The end square itself may be a wall -
' that is how we get to see the walls of a room.)
FUNCTION CanSee% (x1, y1, x2, y2)
  ddx = x2 - x1: ddy = y2 - y1
  steps = ABS(ddx): IF ABS(ddy) > steps THEN steps = ABS(ddy)
  CanSee% = 1
  FOR i = 1 TO steps - 1
    cx = x1 + CINT(ddx * i / steps)
    cy = y1 + CINT(ddy * i / steps)
    IF t(cx, cy) = WALL THEN CanSee% = 0: EXIT FUNCTION
  NEXT
END FUNCTION

' Draw one square in the right style for what we know about it.
SUB DrawCell (x, y)
  LOCATE y + TOPROW, x + 1
  IF x = px AND y = py THEN COLOR 15: PRINT "@";: EXIT SUB
  IF seen(x, y) = 0 THEN PRINT " ";: EXIT SUB
  IF vis(x, y) THEN
    m = MonAt(x, y)
    IF m THEN
      IF mk$(m) = "orc" THEN COLOR 12: PRINT "o"; ELSE COLOR 10: PRINT "g";
      EXIT SUB
    END IF
  END IF
  ' visible squares are bright, remembered ones dim
  SELECT CASE t(x, y)
    CASE WALL: IF vis(x, y) THEN COLOR 6 ELSE COLOR 8
      PRINT CHR$(178);
    CASE FLOOR: IF vis(x, y) THEN COLOR 7 ELSE COLOR 8
      PRINT CHR$(250);
    CASE GOLD: COLOR 14: PRINT "$";
    CASE STAIRS: COLOR 11: PRINT ">";
  END SELECT
END SUB

' Build a new level: rooms, corridors, gold, stairs and monsters.
SUB MakeLevel
  FOR x = 1 TO MW: FOR y = 1 TO MH
    t(x, y) = WALL: seen(x, y) = 0: vis(x, y) = 0
  NEXT y, x
  nRooms = 0: tries = 0
  DIM rx(1 TO 9), ry(1 TO 9), rw(1 TO 9), rh(1 TO 9)
  DO WHILE nRooms < 9 AND tries < 200
    tries = tries + 1
    w = INT(RND * 10) + 5: h = INT(RND * 4) + 3
    x = INT(RND * (MW - w - 2)) + 2: y = INT(RND * (MH - h - 2)) + 2
    ' reject rooms that overlap (or touch) an existing room
    ok = 1
    FOR r = 1 TO nRooms
      IF x <= rx(r) + rw(r) + 1 AND x + w + 1 >= rx(r) AND y <= ry(r) + rh(r) + 1 AND y + h + 1 >= ry(r) THEN ok = 0
    NEXT
    IF ok THEN
      nRooms = nRooms + 1
      rx(nRooms) = x: ry(nRooms) = y: rw(nRooms) = w: rh(nRooms) = h
      FOR i = x TO x + w - 1: FOR j = y TO y + h - 1: t(i, j) = FLOOR: NEXT j, i
      IF nRooms > 1 THEN
        ' L-shaped corridor from this room's centre to the previous one's
        x1 = x + w \ 2: y1 = y + h \ 2
        x2 = rx(nRooms - 1) + rw(nRooms - 1) \ 2: y2 = ry(nRooms - 1) + rh(nRooms - 1) \ 2
        FOR i = x1 TO x2 STEP SGN(x2 - x1) + (x1 = x2): t(i, y1) = FLOOR: NEXT
        FOR j = y1 TO y2 STEP SGN(y2 - y1) + (y1 = y2): t(x2, j) = FLOOR: NEXT
      END IF
    END IF
  LOOP
  ' scatter gold
  FOR i = 1 TO 8
    r = INT(RND * nRooms) + 1
    t(rx(r) + INT(RND * rw(r)), ry(r) + INT(RND * rh(r))) = GOLD
  NEXT
  ' you start in room 1, the stairs are in the last room
  px = rx(1) + rw(1) \ 2: py = ry(1) + rh(1) \ 2
  t(px, py) = FLOOR
  t(rx(nRooms) + rw(nRooms) \ 2, ry(nRooms) + rh(nRooms) \ 2) = STAIRS
  ' monsters, more of them on deeper levels (never in room 1)
  nMon = 3 + depth * 2
  FOR m = 1 TO nMon
    r = INT(RND * (nRooms - 1)) + 2
    mx(m) = rx(r) + INT(RND * rw(r)): my(m) = ry(r) + INT(RND * rh(r))
    IF RND < .3 * depth THEN mk$(m) = "orc": mhp(m) = 8 ELSE mk$(m) = "goblin": mhp(m) = 4
  NEXT
  ERASE rx, ry, rw, rh
  COLOR 7: CLS
  UpdateView
END SUB

FUNCTION MonAt% (x, y)
  MonAt% = 0
  FOR m = 1 TO nMon
    IF mhp(m) > 0 AND mx(m) = x AND my(m) = y THEN MonAt% = m: EXIT FUNCTION
  NEXT
END FUNCTION

SUB Msg (t$)
  LOCATE 24, 1: COLOR 11: PRINT LEFT$(t$ + SPACE$(79), 79);
END SUB

' Recompute what is visible around the player and redraw that box.
' Only squares within RADIUS+1 can change, so we skip the rest of
' the map - that keeps the game quick.
SUB UpdateView
  x1 = px - RADIUS - 1: IF x1 < 1 THEN x1 = 1
  x2 = px + RADIUS + 1: IF x2 > MW THEN x2 = MW
  y1 = py - RADIUS - 1: IF y1 < 1 THEN y1 = 1
  y2 = py + RADIUS + 1: IF y2 > MH THEN y2 = MH
  FOR y = y1 TO y2
    FOR x = x1 TO x2
      vis(x, y) = 0
      ' inside the torch's circle?  (x distance is halved because
      ' text characters are about twice as tall as they are wide)
      ddx = (x - px) \ 2: ddy = y - py
      IF ddx * ddx + ddy * ddy <= RADIUS * RADIUS \ 2 + 2 THEN
        IF CanSee(px, py, x, y) THEN vis(x, y) = 1: seen(x, y) = 1
      END IF
      DrawCell x, y
    NEXT
  NEXT
END SUB
