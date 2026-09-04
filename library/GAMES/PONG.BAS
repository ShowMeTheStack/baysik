' ============================================================
' TITLE:    Two-Player Pong
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     action, two-player, graphics, inkey, timer, sound
' SUMMARY:  Classic bat-and-ball tennis for two players sharing one keyboard.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a court in 320x200 graphics with a paddle on each side.
'   A ball bounces between them; miss it and your opponent scores.
'   The first player to reach 7 points wins the match.
'
' HOW TO USE
'   Left player : W = up, S = down
'   Right player: Up arrow = up, Down arrow = down  (or O / L)
'   Esc quits at any time.  Both players can hold their keys down at
'   the same time: the program watches the keyboard's scan codes.
'   (A tap on a key also gives its paddle a short burst of movement.)
'
' CONCEPTS YOU WILL LEARN
'   * A game loop: read input -> update the world -> draw -> wait
'   * Frame timing: TIMER only ticks 18.2 times a second, so for
'     smooth motion we wait for the screen's vertical retrace instead
'   * Reading normal keys and arrow keys with INKEY$
'   * Reading key-down / key-up scan codes from port &H60 with INP,
'     so two players can hold keys at once
'   * Erasing and redrawing sprites with LINE ... BF
'   * Simple physics: velocity, bouncing, and changing angle
'
' THINGS TO TRY
'   * Change WINSCORE to make matches longer or shorter
'   * Make the paddles shorter as the score rises
'   * Add a computer player for the right paddle
' ============================================================

DEFINT A-Z                    ' integers are faster; we use SINGLE where needed

CONST WINSCORE = 7            ' points needed to win
CONST PADH = 30               ' paddle height in pixels
CONST PADW = 4                ' paddle width in pixels
CONST TOPY = 20               ' top wall of the court
CONST BOTY = 190              ' bottom wall of the court

DIM bx AS SINGLE, by AS SINGLE    ' ball position (fractional for smooth motion)
DIM dx AS SINGLE, dy AS SINGLE    ' ball velocity in pixels per frame
DIM oldbx AS SINGLE, oldby AS SINGLE  ' where the ball was last frame
DIM held(127)                 ' held(scan code) is true while that key is down

RANDOMIZE TIMER
SCREEN 13                     ' 320x200, 256 colours

' ---- Draw the title and wait for a key ----
LOCATE 10, 13: PRINT "TWO-PLAYER PONG"
LOCATE 12, 6: PRINT "Left: W / S    Right: "; CHR$(24); " / "; CHR$(25)
LOCATE 14, 9: PRINT "First to"; WINSCORE; "points wins"
LOCATE 17, 10: PRINT "Press any key to serve"
DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
IF k$ = CHR$(27) THEN GOTO Done

score1 = 0: score2 = 0
ly = 90: ry = 90              ' top of each paddle
lmove = 0: rmove = 0          ' remaining "burst" of movement (+ down, - up)

GOSUB DrawCourt
GOSUB Serve

' ================= MAIN GAME LOOP =================
DO
  ' ---- 1a. INPUT: which keys are held down right now? ----
  ' Port &H60 holds the scan code of the latest keyboard event.  A
  ' number below 128 means "pressed", the same number + 128 "released".
  ' Checking it every frame lets us track keys that are held down.
  sc = INP(&H60)
  IF sc < 128 THEN held(sc) = -1 ELSE held(sc - 128) = 0

  ' ---- 1b. INPUT: empty the INKEY$ buffer (so it never fills up) ----
  DO
    k$ = INKEY$
    IF k$ = "" THEN EXIT DO
    IF k$ = CHR$(27) THEN GOTO Done
    ' Arrow keys arrive as two characters: CHR$(0) + scan code.
    IF LEN(k$) = 2 THEN
      SELECT CASE ASC(RIGHT$(k$, 1))
        CASE 72: rmove = -12      ' up arrow
        CASE 80: rmove = 12       ' down arrow
      END SELECT
    ELSE
      SELECT CASE UCASE$(k$)
        CASE "W": lmove = -12
        CASE "S": lmove = 12
        CASE "O": rmove = -12
        CASE "L": rmove = 12
      END SELECT
    END IF
  LOOP

  ' ---- 2. UPDATE paddles: 3 pixels per frame while a key is held
  '         (scan codes: W=17 S=31 O=24 L=38 Up=72 Down=80)
  '         or while the burst from a key press lasts ----
  oldly = ly: oldry = ry
  IF held(17) OR lmove < 0 THEN ly = ly - 3
  IF held(31) OR lmove > 0 THEN ly = ly + 3
  IF held(72) OR held(24) OR rmove < 0 THEN ry = ry - 3
  IF held(80) OR held(38) OR rmove > 0 THEN ry = ry + 3
  lmove = lmove - 3 * SGN(lmove): rmove = rmove - 3 * SGN(rmove)
  ' keep paddles inside the court
  IF ly < TOPY + 1 THEN ly = TOPY + 1
  IF ly > BOTY - PADH THEN ly = BOTY - PADH
  IF ry < TOPY + 1 THEN ry = TOPY + 1
  IF ry > BOTY - PADH THEN ry = BOTY - PADH

  ' ---- 3. UPDATE ball ----
  oldbx = bx: oldby = by
  bx = bx + dx: by = by + dy

  ' bounce off the top and bottom walls by flipping the vertical speed
  IF by < TOPY + 2 THEN by = TOPY + 2: dy = -dy: SOUND 300, .5
  IF by > BOTY - 4 THEN by = BOTY - 4: dy = -dy: SOUND 300, .5

  ' left paddle sits at x = 10..13
  IF dx < 0 AND bx <= 14 AND bx >= 8 THEN
    IF by + 3 >= ly AND by <= ly + PADH THEN
      GOSUB HitPaddle
      dy = (by + 1.5 - (ly + PADH / 2)) / 5    ' where it hits sets the angle
    END IF
  END IF
  ' right paddle sits at x = 306..309
  IF dx > 0 AND bx >= 303 AND bx <= 309 THEN
    IF by + 3 >= ry AND by <= ry + PADH THEN
      GOSUB HitPaddle
      dy = (by + 1.5 - (ry + PADH / 2)) / 5
    END IF
  END IF

  ' ---- 4. Did somebody miss? ----
  IF bx < 0 THEN score2 = score2 + 1: GOSUB Scored
  IF bx > 316 THEN score1 = score1 + 1: GOSUB Scored
  IF score1 >= WINSCORE OR score2 >= WINSCORE THEN EXIT DO

  ' ---- 5. DRAW: erase the old pictures, then draw the new ones ----
  LINE (10, oldly)-(10 + PADW - 1, oldly + PADH), 0, BF
  LINE (306, oldry)-(306 + PADW - 1, oldry + PADH), 0, BF
  LINE (oldbx, oldby)-(oldbx + 3, oldby + 3), 0, BF
  LINE (159, TOPY + 1)-(159, BOTY - 1), 8, , &HF0F0   ' redraw the dashed net
  LINE (10, ly)-(10 + PADW - 1, ly + PADH), 14, BF
  LINE (306, ry)-(306 + PADW - 1, ry + PADH), 11, BF
  LINE (bx, by)-(bx + 3, by + 3), 15, BF

  ' ---- 6. WAIT for the next screen refresh ----
  ' Bit 8 of port &H3DA is on while the monitor's beam returns to the
  ' top of the screen ("vertical retrace").  Waiting for it to go off
  ' and then on again paces the game at the monitor's refresh rate
  ' (about 60-70 frames a second) on any speed of PC.  TIMER would be
  ' too coarse: it only changes 18.2 times a second.
  WAIT &H3DA, 8, 8
  WAIT &H3DA, 8
LOOP

' ---- Game over ----
IF score1 > score2 THEN w$ = "LEFT PLAYER WINS!" ELSE w$ = "RIGHT PLAYER WINS!"
LOCATE 12, 20 - LEN(w$) \ 2: PRINT w$
PLAY "MB T180 L8 CEG >C4"
LOCATE 14, 12: PRINT "Press Esc to exit"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Done:
SCREEN 0: WIDTH 80
PRINT "Thanks for playing Pong!"
END

' ================= SUBROUTINES =================

DrawCourt:
  CLS
  LINE (0, TOPY)-(319, TOPY), 7          ' top wall
  LINE (0, BOTY)-(319, BOTY), 7          ' bottom wall
  GOSUB ShowScore
RETURN

ShowScore:
  LOCATE 1, 8: PRINT "LEFT:"; score1
  LOCATE 1, 26: PRINT "RIGHT:"; score2
RETURN

HitPaddle:
  dx = -dx * 1.05                         ' reverse and speed up a little
  IF dx > 6 THEN dx = 6                   ' but never too fast to see
  IF dx < -6 THEN dx = -6
  SOUND 800, .5
RETURN

Scored:
  SOUND 150, 4
  LINE (oldbx, oldby)-(oldbx + 3, oldby + 3), 0, BF
  LINE (bx, by)-(bx + 3, by + 3), 0, BF
  GOSUB ShowScore
  GOSUB Serve
RETURN

Serve:
  ' put the ball in the centre and send it toward a random side
  bx = 158: by = 100
  oldbx = bx: oldby = by
  dx = 2: IF RND < .5 THEN dx = -2
  dy = RND * 2 - 1
RETURN
