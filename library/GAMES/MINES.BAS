' ============================================================
' TITLE:    Minesweeper
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     puzzle, flood fill, stack, arrays, cursor, logic
' SUMMARY:  Clear a minefield using number clues, with flags and an automatic flood-fill.
' ------------------------------------------------------------
' WHAT IT DOES
'   A 16 x 12 field hides 25 mines.  Uncover a square: if it is a mine
'   you lose; otherwise it shows how many of its 8 neighbours are
'   mines.  A square with no neighbouring mines opens up all the
'   squares around it automatically ("flood fill").  Mark squares you
'   think are mines with flags.  Uncover every safe square to win.
'   Your first click is always safe.
'
' HOW TO USE
'   Arrow keys move the cursor.
'   Space = uncover     F = place / remove a flag     Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Counting neighbours with two nested loops from -1 to +1
'   * Flood fill using an explicit stack (no deep recursion needed)
'   * Keeping two layers of data: what is there, and what you can see
'   * Measuring play time with TIMER
'
' THINGS TO TRY
'   * Change W, H and MINES for beginner or expert boards
'   * "Chording": Space on an open number whose flags are all placed
'     uncovers the remaining neighbours
'   * Save the best time to a file
' ============================================================

DEFINT A-Z
CONST W = 16, H = 12, MINES = 25
CONST LEFTX = 24, TOPY = 5               ' screen position of the field

DIM mine(0 TO W + 1, 0 TO H + 1)          ' 1 = mine.  A border of 0s around
DIM near(1 TO W, 1 TO H)                  '   the edge means no bounds checks
DIM state(1 TO W, 1 TO H)                 ' 0 hidden, 1 open, 2 flagged
' flood-fill stack: a square can be pushed once by each of its 8
' neighbours, so W * H * 8 entries is always enough
DIM stkX(1 TO W * H * 8), stkY(1 TO W * H * 8)
DIM numColor(1 TO 8)                      ' colour for each clue number
DATA 9, 10, 12, 1, 4, 3, 13, 7
FOR i = 1 TO 8: READ numColor(i): NEXT
DIM t0 AS SINGLE

RANDOMIZE TIMER

NewGame:
  ERASE mine, near, state
  placed = 0                 ' mines go in on the first uncover
  opened = 0: flags = 0
  cx = W \ 2: cy = H \ 2
  over = 0
  CLS
  COLOR 14: LOCATE 1, 33: PRINT "MINESWEEPER": COLOR 7
  LOCATE 3, 16: PRINT "Arrows move   Space uncovers   F flags   Esc quits"
  FOR y = 1 TO H: FOR x = 1 TO W: GOSUB DrawCell: NEXT: NEXT
  GOSUB Status

DO
  ' ---- show the cursor as a blinking-looking highlight ----
  x = cx: y = cy: hilite = -1: GOSUB DrawCell: hilite = 0
  DO
    k$ = INKEY$
    ' keep the clock ticking, redrawing only when the second changes
    IF placed AND INT(TIMER) <> lastSec THEN lastSec = INT(TIMER): GOSUB Status
  LOOP UNTIL k$ <> ""
  GOSUB DrawCell                                    ' remove the highlight
  IF k$ = CHR$(27) THEN GOTO Quit
  IF LEN(k$) = 2 THEN
    SELECT CASE ASC(RIGHT$(k$, 1))
      CASE 72: IF cy > 1 THEN cy = cy - 1
      CASE 80: IF cy < H THEN cy = cy + 1
      CASE 75: IF cx > 1 THEN cx = cx - 1
      CASE 77: IF cx < W THEN cx = cx + 1
    END SELECT
  ELSEIF UCASE$(k$) = "F" THEN
    ' toggle a flag on a hidden square
    IF state(cx, cy) = 0 THEN
      state(cx, cy) = 2: flags = flags + 1: SOUND 1500, .3
    ELSEIF state(cx, cy) = 2 THEN
      state(cx, cy) = 0: flags = flags - 1: SOUND 1000, .3
    END IF
    x = cx: y = cy: GOSUB DrawCell: GOSUB Status
  ELSEIF k$ = " " AND state(cx, cy) = 0 THEN
    IF NOT placed THEN GOSUB PlaceMines
    IF mine(cx, cy) THEN
      GOSUB Boom
      EXIT DO
    END IF
    GOSUB Flood
    SOUND 700, .3
    GOSUB Status
    IF opened = W * H - MINES THEN
      over = -1
      LOCATE 20, 30: COLOR 10: PRINT "YOU CLEARED THE FIELD!": COLOR 7
      PLAY "MB T200 L16 CEGCEG>C"
      EXIT DO
    END IF
  END IF
LOOP

LOCATE 22, 26: PRINT "N = new game,  Esc = quit"
DO
  k$ = UCASE$(INKEY$)
  IF k$ = "N" THEN GOTO NewGame
LOOP UNTIL k$ = CHR$(27)

Quit:
CLS
PRINT "Thanks for sweeping!"
END

' ---- put the mines anywhere except the first square clicked ----
PlaceMines:
  n = 0
  DO WHILE n < MINES
    x = INT(RND * W) + 1: y = INT(RND * H) + 1
    ' keep the clicked square and its neighbours clear for a fair start
    IF mine(x, y) = 0 AND (ABS(x - cx) > 1 OR ABS(y - cy) > 1) THEN
      mine(x, y) = 1: n = n + 1
    END IF
  LOOP
  ' count the mines around every square
  FOR y = 1 TO H
    FOR x = 1 TO W
      total = 0
      FOR dy = -1 TO 1
        FOR dx = -1 TO 1
          total = total + mine(x + dx, y + dy)   ' the border makes this safe
        NEXT
      NEXT
      near(x, y) = total - mine(x, y)
    NEXT
  NEXT
  placed = -1
  t0 = TIMER
RETURN

' ---- open (cx, cy); if it is a 0, keep opening its neighbours ----
Flood:
  sp = 1: stkX(1) = cx: stkY(1) = cy
  DO WHILE sp > 0
    x = stkX(sp): y = stkY(sp): sp = sp - 1
    IF state(x, y) = 0 THEN
      state(x, y) = 1: opened = opened + 1
      GOSUB DrawCell
      IF near(x, y) = 0 THEN
        ' push every hidden neighbour that is inside the field
        FOR dy = -1 TO 1
          FOR dx = -1 TO 1
            nx = x + dx: ny = y + dy
            IF nx >= 1 AND nx <= W AND ny >= 1 AND ny <= H THEN
              IF state(nx, ny) = 0 THEN sp = sp + 1: stkX(sp) = nx: stkY(sp) = ny
            END IF
          NEXT
        NEXT
      END IF
    END IF
  LOOP
RETURN

' ---- you hit a mine: show them all ----
Boom:
  over = -1
  FOR y = 1 TO H
    FOR x = 1 TO W
      IF mine(x, y) THEN state(x, y) = 1: GOSUB DrawCell
    NEXT
  NEXT
  LOCATE 20, 33: COLOR 12: PRINT "*** BOOM! ***": COLOR 7
  FOR f = 200 TO 50 STEP -30: SOUND f, 1: NEXT
RETURN

' ---- draw square (x, y) ----
DrawCell:
  LOCATE TOPY + y, LEFTX + x * 2
  IF hilite THEN COLOR 0, 7
  SELECT CASE state(x, y)
    CASE 0: IF NOT hilite THEN COLOR 8
            PRINT CHR$(254);
    CASE 2: IF NOT hilite THEN COLOR 12
            PRINT "F";
    CASE 1
      IF mine(x, y) THEN
        IF NOT hilite THEN COLOR 15, 4
        PRINT "*";
      ELSEIF near(x, y) = 0 THEN
        PRINT " ";
      ELSE
        ' each number gets its own colour, like the classic game
        IF NOT hilite THEN COLOR numColor(near(x, y))
        PRINT LTRIM$(STR$(near(x, y)));
      END IF
  END SELECT
  COLOR 7, 0
RETURN

Status:
  IF placed THEN secs = INT(TIMER - t0) ELSE secs = 0
  IF secs < 0 THEN secs = secs + 86400          ' past midnight
  LOCATE 19, 26: PRINT "Mines left:"; MINES - flags; "  Time:"; secs; "  "
RETURN
