' ============================================================
' TITLE:    Brick Breaker
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     action, arcade, graphics, arrays, collision, sound
' SUMMARY:  Bounce a ball off your paddle to smash a wall of coloured bricks.
' ------------------------------------------------------------
' WHAT IT DOES
'   Six rows of bricks sit at the top of the screen.  You steer a
'   paddle along the bottom and keep the ball in play.  Every brick
'   the ball touches disappears and scores points (higher rows are
'   worth more).  Clear the wall to advance to a faster level.
'   You have 3 balls.
'
' HOW TO USE
'   Left / Right arrows (or A / D) move the paddle.
'   Space launches the ball.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a grid of bricks in a 2-D array
'   * Converting a pixel position into a grid row/column
'   * Collision tests between a moving point and rectangles
'   * Using the hit position on the paddle to steer the ball
'   * Smooth frame pacing with the vertical retrace (WAIT &H3DA)
'   * Held-key detection with scan codes from INP(&H60)
'
' THINGS TO TRY
'   * Add bricks that need two hits (store 2 in the array)
'   * Drop a "wide paddle" bonus from random bricks
'   * Change ROWS and COLS for a different wall
' ============================================================

DEFINT A-Z

CONST ROWS = 6, COLS = 10          ' size of the brick wall
CONST BW = 30, BH = 8              ' brick width / height in pixels
CONST WALLX = 10, WALLY = 30       ' top-left corner of the wall
CONST PADW = 40, PADY = 185        ' paddle width and its y position

DIM brick(1 TO ROWS, 1 TO COLS)    ' 1 = brick present, 0 = gone
DIM bx AS SINGLE, by AS SINGLE, dx AS SINGLE, dy AS SINGLE
DIM ox AS SINGLE, oy AS SINGLE, speed AS SINGLE
DIM held(127)                       ' true while the key with that scan code is down

RANDOMIZE TIMER
SCREEN 13
score = 0: lives = 3: level = 1: speed = 2.2

NewLevel:
  ' ---- fill the wall and draw it ----
  CLS
  FOR r = 1 TO ROWS
    FOR c = 1 TO COLS
      brick(r, c) = 1
      GOSUB DrawBrick
    NEXT
  NEXT
  remain = ROWS * COLS                 ' bricks still standing
  LINE (WALLX - 2, 18)-(WALLX - 2, 199), 8        ' side walls
  LINE (WALLX + COLS * BW + 1, 18)-(WALLX + COLS * BW + 1, 199), 8
  LINE (WALLX - 2, 18)-(WALLX + COLS * BW + 1, 18), 8
  px = 140: pmove = 0

NewBall:
  GOSUB Status
  stuck = -1                          ' ball rides on the paddle until Space
  ox = px + PADW \ 2: oy = PADY - 4
  bx = ox: by = oy

' ================= MAIN LOOP =================
DO
  ' ---- input part 1: held keys.  Port &H60 gives the latest scan
  '      code: below 128 = key pressed, +128 = key released ----
  sc = INP(&H60)
  IF sc < 128 THEN held(sc) = -1 ELSE held(sc - 128) = 0

  ' ---- input part 2: read every waiting key from INKEY$ ----
  DO
    k$ = INKEY$
    IF k$ = "" THEN EXIT DO
    IF k$ = CHR$(27) THEN GOTO Quit
    IF k$ = " " AND stuck THEN
      stuck = 0
      dx = speed * (RND - .5): dy = -speed  ' launch upward, slightly random
    END IF
    k = 0
    IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
    IF k = 75 OR UCASE$(k$) = "A" THEN pmove = -16   ' left arrow
    IF k = 77 OR UCASE$(k$) = "D" THEN pmove = 16    ' right arrow
  LOOP

  ' ---- move the paddle 4 pixels per frame while an arrow is held
  '      (scan 75 = left, 77 = right), or during a short burst after
  '      a key press ----
  opx = px
  IF held(75) OR pmove < 0 THEN px = px - 4
  IF held(77) OR pmove > 0 THEN px = px + 4
  pmove = pmove - 4 * SGN(pmove)
  IF px < WALLX THEN px = WALLX
  IF px > WALLX + COLS * BW - PADW THEN px = WALLX + COLS * BW - PADW

  ' ---- move the ball ----
  ox = bx: oy = by
  IF stuck THEN
    bx = px + PADW \ 2: by = PADY - 4
  ELSE
    bx = bx + dx: by = by + dy
    ' side and top walls
    IF bx < WALLX THEN bx = WALLX: dx = -dx: SOUND 400, .3
    IF bx > WALLX + COLS * BW - 3 THEN bx = WALLX + COLS * BW - 3: dx = -dx: SOUND 400, .3
    IF by < 20 THEN by = 20: dy = -dy: SOUND 400, .3

    ' paddle: only when the ball is falling and level with the paddle
    IF dy > 0 AND by + 3 >= PADY AND by + 3 <= PADY + 4 THEN
      IF bx + 3 >= px AND bx <= px + PADW THEN
        ' hit position from -1 (left end) to +1 (right end)
        hit! = ((bx + 1.5) - (px + PADW / 2)) / (PADW / 2)
        dx = hit! * speed * 1.2
        dy = -SQR(ABS(speed * speed * 2 - dx * dx)) ' keep overall speed
        IF dy > -1 THEN dy = -1
        SOUND 600, .3
      END IF
    END IF

    ' bricks: work out which grid cell the ball's centre is in
    c = INT((bx + 1.5 - WALLX) / BW) + 1
    r = INT((by + 1.5 - WALLY) / BH) + 1
    IF r >= 1 AND r <= ROWS AND c >= 1 AND c <= COLS THEN
      IF brick(r, c) THEN
        brick(r, c) = 0
        LINE (WALLX + (c - 1) * BW, WALLY + (r - 1) * BH)-STEP(BW - 1, BH - 1), 0, BF
        dy = -dy                       ' simple bounce: reverse vertical
        score = score + (ROWS - r + 1) * 10
        remain = remain - 1
        SOUND 200 + (ROWS - r) * 120, .4
        GOSUB Status
      END IF
    END IF

    ' fell off the bottom?
    IF by > 199 THEN
      lives = lives - 1
      LINE (ox, oy)-STEP(3, 3), 0, BF
      SOUND 120, 6
      IF lives = 0 THEN EXIT DO
      GOTO NewBall
    END IF
  END IF

  ' ---- draw ----
  IF opx <> px THEN LINE (opx, PADY)-STEP(PADW, 4), 0, BF
  LINE (px, PADY)-STEP(PADW, 4), 7, BF
  LINE (ox, oy)-STEP(3, 3), 0, BF
  LINE (bx, by)-STEP(3, 3), 15, BF

  IF remain = 0 THEN
    PLAY "MB T200 L16 CEGCEG>C"
    level = level + 1: speed = speed + .5
    GOTO NewLevel
  END IF

  ' wait for the next vertical retrace: about 60 frames a second
  ' (TIMER only ticks 18.2 times a second - too coarse for this)
  WAIT &H3DA, 8, 8: WAIT &H3DA, 8
LOOP

' ---- game over ----
LOCATE 12, 15: PRINT "GAME OVER"
LOCATE 14, 11: PRINT "Final score:"; score
LOCATE 16, 10: PRINT "Press Esc to exit"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
SCREEN 0: WIDTH 80
PRINT "Brick Breaker - final score:"; score
END

' ---- draw brick (r, c); each row gets its own colour ----
DrawBrick:
  LINE (WALLX + (c - 1) * BW, WALLY + (r - 1) * BH)-STEP(BW - 2, BH - 2), 31 + r * 8, BF
RETURN

' ---- status line at the very top ----
Status:
  LOCATE 1, 1: PRINT "SCORE"; score; "  LEVEL"; level; "  BALLS"; lives; "  "
RETURN
