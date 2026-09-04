' ============================================================
' TITLE:    Snake in the Rocks
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     action, arcade, circular buffer, screen function, text mode
' SUMMARY:  Steer a growing snake to the food while dodging the walls, rocks and your own tail.
' ------------------------------------------------------------
' WHAT IT DOES
'   The classic snake game in 40-column text mode, with a twist:
'   every level scatters rocky obstacles around the field.  Eat the
'   food (a diamond) to grow longer and score.  Eat 8 pieces to reach
'   the next level, which has more rocks and a faster snake.  Hitting
'   a wall, a rock or your own body ends the game.
'
' HOW TO USE
'   Arrow keys (or W A S D) steer.  P pauses.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * A circular buffer: the snake's body positions live in arrays
'     where the head index wraps around with MOD
'   * The SCREEN(row, col) function: ask the screen what character is
'     already at a spot - perfect for collision tests
'   * Smooth pacing by counting screen refreshes (WAIT &H3DA)
'   * Ignoring a reverse turn so the snake can't bite its own neck
'
' THINGS TO TRY
'   * Let the snake wrap around the edges instead of dying
'   * Add a golden food that appears for a few seconds only
'   * Make the rocks move slowly!
' ============================================================

DEFINT A-Z
CONST BUF = 1024                     ' size of the circular buffer
CONST WALL = 219, ROCK = 177, BODY = 254, FOOD = 4
CONST TOP = 2, BOTTOM = 24, LEFTC = 1, RIGHTC = 40

DIM sx(0 TO BUF - 1), sy(0 TO BUF - 1)    ' body squares, oldest to newest

RANDOMIZE TIMER
SCREEN 0: WIDTH 40, 25
level = 1: score = 0: best = 0

NewLevel:
  CLS
  ' ---- border ----
  COLOR 7
  LOCATE TOP, LEFTC: PRINT STRING$(40, WALL);
  LOCATE BOTTOM, LEFTC: PRINT STRING$(40, WALL);
  FOR r = TOP TO BOTTOM
    LOCATE r, LEFTC: PRINT CHR$(WALL);
    LOCATE r, RIGHTC: PRINT CHR$(WALL);
  NEXT
  ' ---- rocks: short random lines, kept away from the start area ----
  COLOR 6
  FOR i = 1 TO 2 + level * 2
    DO
      r = INT(RND * 19) + TOP + 2: c = INT(RND * 34) + 4
    LOOP WHILE ABS(r - 13) < 3 AND c < 22        ' the snake starts at row 13
    lenR = INT(RND * 5) + 3
    vertical = INT(RND * 2)
    FOR j = 0 TO lenR - 1
      rr = r + j * vertical: cc = c + j * (1 - vertical)
      IF rr < BOTTOM AND cc < RIGHTC THEN LOCATE rr, cc: PRINT CHR$(ROCK);
    NEXT
  NEXT
  COLOR 7

  ' ---- the snake: 4 squares long, heading right ----
  length = 4: head = 3
  FOR i = 0 TO 3: sx(i) = 6 + i: sy(i) = 13: NEXT
  COLOR 10
  FOR i = 0 TO 3: LOCATE sy(i), sx(i): PRINT CHR$(BODY); : NEXT
  COLOR 7
  dx = 1: dy = 0
  grow = 0: eaten = 0
  GOSUB PlaceFood
  GOSUB Status
  ' frames between moves: fewer = faster
  delay = 8 - level: IF delay < 3 THEN delay = 3
  LOCATE 13, 14: PRINT "LEVEL"; level; "- GO!";
  t! = TIMER: DO: LOOP WHILE TIMER < t! + 1.2 AND TIMER >= t!
  LOCATE 13, 14: PRINT SPACE$(12);

' ================= MAIN LOOP =================
DO
  ' ---- wait "delay" screen refreshes; read keys meanwhile ----
  FOR f = 1 TO delay
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    k$ = INKEY$
    IF k$ <> "" THEN
      IF k$ = CHR$(27) THEN GOTO Quit
      IF UCASE$(k$) = "P" THEN
        LOCATE 1, 30: PRINT "PAUSED";
        DO: LOOP WHILE INKEY$ = ""
        LOCATE 1, 30: PRINT "      ";
      END IF
      ndx = dx: ndy = dy
      kk = 0: IF LEN(k$) = 2 THEN kk = ASC(RIGHT$(k$, 1))
      u$ = UCASE$(k$)
      IF kk = 72 OR u$ = "W" THEN ndx = 0: ndy = -1
      IF kk = 80 OR u$ = "S" THEN ndx = 0: ndy = 1
      IF kk = 75 OR u$ = "A" THEN ndx = -1: ndy = 0
      IF kk = 77 OR u$ = "D" THEN ndx = 1: ndy = 0
      ' no U-turns: the new direction must not be the exact opposite
      IF NOT (ndx = -dx AND ndy = -dy) THEN dx = ndx: dy = ndy
    END IF
  NEXT

  ' ---- move the head one square ----
  nx = sx(head) + dx: ny = sy(head) + dy
  ' What is already on the screen there?  SCREEN(row, col) tells us.
  hit = SCREEN(ny, nx)
  IF hit = WALL OR hit = ROCK OR hit = BODY THEN
    ' (moving onto the very end of the tail is fine - it moves away -
    '  but we keep it simple: any body square is a crash)
    EXIT DO
  END IF

  head = (head + 1) MOD BUF              ' circular buffer: wrap around
  sx(head) = nx: sy(head) = ny
  COLOR 10: LOCATE ny, nx: PRINT CHR$(BODY); : COLOR 7

  IF hit = FOOD THEN
    score = score + 10 * level: eaten = eaten + 1
    grow = grow + 3
    SOUND 1000, .5: SOUND 1400, .5
    GOSUB Status
    IF eaten = 8 THEN
      PLAY "MB T200 L16 CEGCEG>C"
      level = level + 1
      GOTO NewLevel
    END IF
    GOSUB PlaceFood
  END IF

  ' ---- remove the tail unless we are still growing ----
  IF grow > 0 THEN
    grow = grow - 1: length = length + 1
  ELSE
    tailI = (head - length + BUF) MOD BUF
    LOCATE sy(tailI), sx(tailI): PRINT " ";
  END IF
LOOP

' ---- crash! ----
COLOR 12: LOCATE sy(head), sx(head): PRINT "X"; : COLOR 7
FOR f = 400 TO 80 STEP -40: SOUND f, 1: NEXT
LOCATE 12, 15: COLOR 14: PRINT " GAME OVER ";
LOCATE 13, 12: PRINT " Score:"; score; " ";
COLOR 7
LOCATE 15, 9: PRINT " Space = again, Esc = quit ";
DO
  k$ = INKEY$
  IF k$ = " " THEN level = 1: score = 0: GOTO NewLevel
LOOP UNTIL k$ = CHR$(27)

Quit:
WIDTH 80: COLOR 7, 0: CLS
PRINT "Snake - final score:"; score
END

' ---- put food on a random empty square ----
PlaceFood:
  DO
    r = INT(RND * (BOTTOM - TOP - 1)) + TOP + 1
    c = INT(RND * (RIGHTC - LEFTC - 1)) + LEFTC + 1
  LOOP UNTIL SCREEN(r, c) = 32            ' 32 = a space
  COLOR 12: LOCATE r, c: PRINT CHR$(FOOD); : COLOR 7
RETURN

Status:
  LOCATE 1, 1: PRINT "SCORE"; score; "  LEVEL"; level; "  FOOD"; eaten; "/8 ";
RETURN
