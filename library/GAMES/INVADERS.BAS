' ============================================================
' TITLE:    Space Invaders Lite
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     action, arcade, sprites, get put, graphics, timer
' SUMMARY:  Defend Earth from a marching formation of pixel aliens with your laser cannon.
' ------------------------------------------------------------
' WHAT IT DOES
'   Forty aliens march left and right across the screen, dropping
'   lower each time they reach an edge, and they speed up as their
'   numbers shrink.  They drop bombs on you.  Shoot them all to win
'   the wave; if they reach the ground or you lose 3 ships, it's over.
'
' HOW TO USE
'   Left / Right arrows (or A / D) move your cannon.
'   Space fires (one shot on screen at a time).  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Designing a sprite with DATA strings and capturing it with GET
'   * Drawing sprites fast with PUT
'   * Moving a whole formation with one origin point
'   * Turning a bullet position into a row / column hit test
'   * Several moving objects (bombs) stored in small arrays
'   * Held keys via scan codes (INP(&H60)) and retrace frame pacing
'
' THINGS TO TRY
'   * Add a second alien design for the top rows (more points!)
'   * Add shields that get chipped away by bombs
'   * Add a mystery saucer flying across the top
' ============================================================

DEFINT A-Z
CONST AROWS = 4, ACOLS = 10          ' size of the alien formation
CONST GAPX = 18, GAPY = 14           ' spacing between aliens
CONST SHIPY = 182, MAXB = 3          ' ship row; maximum bombs at once

DIM alive(1 TO AROWS, 1 TO ACOLS)
DIM alienSpr(60), shipSpr(60)        ' GET buffers for the sprites
DIM bombX(1 TO MAXB), bombY(1 TO MAXB)
DIM held(127)                        ' true while that scan code's key is down

RANDOMIZE TIMER
SCREEN 13

' ---- build the sprites from DATA pictures ("#" = lit pixel) ----
DATA "..#.....#..", ".#.#...#.#.", ".#########.", "##..###..##"
DATA "###########", "#.#######.#", "#.#.....#.#", "...##.##..."
FOR y = 0 TO 7
  READ row$
  FOR x = 0 TO 10
    IF MID$(row$, x + 1, 1) = "#" THEN PSET (x, y), 10
  NEXT
NEXT
GET (0, 0)-(10, 7), alienSpr
DATA ".......#.......", "......###......", "......###......", ".#############."
DATA "###############", "###############"
FOR y = 0 TO 5
  READ row$
  FOR x = 0 TO 14
    IF MID$(row$, x + 1, 1) = "#" THEN PSET (x + 20, y), 11
  NEXT
NEXT
GET (20, 0)-(34, 5), shipSpr

score = 0: lives = 3: wave = 1

NewWave:
  CLS
  FOR r = 1 TO AROWS: FOR c = 1 TO ACOLS: alive(r, c) = 1: NEXT: NEXT
  remain = AROWS * ACOLS
  fx = 20: fy = 20 + wave * 6          ' formation's top-left corner
  fdir = 3                             ' pixels per march step (+ right / - left)
  shipX = 150: shotY = -1              ' shotY < 0 means "no shot flying"
  FOR i = 1 TO MAXB: bombY(i) = -1: NEXT
  frame = 0
  GOSUB DrawFormation
  LINE (0, SHIPY + 8)-(319, SHIPY + 8), 2
  GOSUB Status

' ================= MAIN LOOP =================
DO
  frame = frame + 1

  ' ---- keyboard: held arrows move smoothly (scan 75 = left, 77 = right) ----
  oldShip = shipX
  sc = INP(&H60)
  IF sc < 128 THEN held(sc) = -1 ELSE held(sc - 128) = 0
  IF held(75) THEN shipX = shipX - 3
  IF held(77) THEN shipX = shipX + 3
  ' ...and INKEY$ handles taps, letters, Space and Esc
  DO
    k$ = INKEY$
    IF k$ = "" THEN EXIT DO
    IF k$ = CHR$(27) THEN GOTO Quit
    k = 0: IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
    IF (k = 75 AND NOT held(75)) OR UCASE$(k$) = "A" THEN shipX = shipX - 6
    IF (k = 77 AND NOT held(77)) OR UCASE$(k$) = "D" THEN shipX = shipX + 6
    IF k$ = " " AND shotY < 0 THEN shotX = shipX + 7: shotY = SHIPY - 4: SOUND 1500, .3
  LOOP
  IF shipX < 0 THEN shipX = 0
  IF shipX > 304 THEN shipX = 304
  IF shipX <> oldShip THEN LINE (oldShip, SHIPY)-STEP(14, 5), 0, BF
  PUT (shipX, SHIPY), shipSpr, PSET

  ' ---- march the formation: fewer aliens = fewer frames between steps ----
  IF frame MOD (3 + remain \ 4) = 0 THEN
    ' find the leftmost and rightmost living columns
    minC = ACOLS: maxC = 1: maxR = 1
    FOR r = 1 TO AROWS: FOR c = 1 TO ACOLS
      IF alive(r, c) THEN
        IF c < minC THEN minC = c
        IF c > maxC THEN maxC = c
        IF r > maxR THEN maxR = r
      END IF
    NEXT: NEXT
    LINE (fx + (minC - 1) * GAPX, fy)-(fx + (maxC - 1) * GAPX + 10, fy + (maxR - 1) * GAPY + 7), 0, BF
    leftEdge = fx + (minC - 1) * GAPX + fdir
    rightEdge = fx + (maxC - 1) * GAPX + 10 + fdir
    IF leftEdge < 2 OR rightEdge > 317 THEN
      fdir = -fdir: fy = fy + 6        ' bounce and drop down a row
    ELSE
      fx = fx + fdir
    END IF
    GOSUB DrawFormation
    SOUND 80 + (frame \ (3 + remain \ 4)) MOD 4 * 10, .4   ' the famous march beat
    IF fy + (maxR - 1) * GAPY + 7 >= SHIPY THEN lives = 0: EXIT DO  ' they landed
  END IF

  ' ---- your shot ----
  IF shotY >= 0 THEN
    LINE (shotX, shotY)-(shotX, shotY + 3), 0
    shotY = shotY - 5
    IF shotY < 10 THEN
      shotY = -1
    ELSE
      ' which alien cell is the shot in?
      c = (shotX - fx) \ GAPX + 1: r = (shotY - fy) \ GAPY + 1
      hit = 0
      IF shotX >= fx AND shotY >= fy AND c >= 1 AND c <= ACOLS AND r >= 1 AND r <= AROWS THEN
        ' inside the cell, but is it on the alien and not in the gap?
        IF alive(r, c) AND (shotX - fx) MOD GAPX <= 10 AND (shotY - fy) MOD GAPY <= 7 THEN hit = -1
      END IF
      IF hit THEN
        alive(r, c) = 0: remain = remain - 1
        LINE (fx + (c - 1) * GAPX, fy + (r - 1) * GAPY)-STEP(10, 7), 0, BF
        score = score + (AROWS - r + 1) * 10
        shotY = -1
        SOUND 300, .5
        GOSUB Status
        IF remain = 0 THEN
          PLAY "MB T200 L16 CEG>C"
          wave = wave + 1
          GOTO NewWave
        END IF
      ELSE
        LINE (shotX, shotY)-(shotX, shotY + 3), 15
      END IF
    END IF
  END IF

  ' ---- alien bombs ----
  FOR i = 1 TO MAXB
    IF bombY(i) >= 0 THEN
      LINE (bombX(i), bombY(i))-(bombX(i), bombY(i) + 3), 0
      bombY(i) = bombY(i) + 2
      IF bombY(i) > SHIPY + 4 THEN
        bombY(i) = -1
      ELSEIF bombY(i) + 3 >= SHIPY AND bombX(i) >= shipX AND bombX(i) <= shipX + 14 THEN
        ' hit!  flash the ship and lose a life
        bombY(i) = -1
        lives = lives - 1
        GOSUB Status
        FOR f = 1 TO 6
          LINE (shipX, SHIPY)-STEP(14, 5), (f MOD 2) * 12, BF
          SOUND 100 + f * 30, 1
        NEXT
        LINE (shipX, SHIPY)-STEP(14, 5), 0, BF
        IF lives = 0 THEN EXIT DO
      ELSE
        LINE (bombX(i), bombY(i))-(bombX(i), bombY(i) + 3), 12
      END IF
    ELSEIF RND < .006 + wave * .002 THEN
      ' drop a new bomb from the lowest alien in a random column
      c = INT(RND * ACOLS) + 1
      FOR r = AROWS TO 1 STEP -1
        IF alive(r, c) THEN
          bombX(i) = fx + (c - 1) * GAPX + 5
          bombY(i) = fy + (r - 1) * GAPY + 9
          EXIT FOR
        END IF
      NEXT
    END IF
  NEXT

  ' pace the game to the screen refresh (about 60 frames a second)
  WAIT &H3DA, 8, 8: WAIT &H3DA, 8
LOOP

' ---- game over ----
LOCATE 12, 15: PRINT "GAME OVER"
LOCATE 14, 12: PRINT "Score:"; score
PLAY "MB T100 L8 C <G <E <C"
LOCATE 16, 10: PRINT "Press Esc to exit"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
SCREEN 0: WIDTH 80
PRINT "Space Invaders Lite - final score:"; score
END

DrawFormation:
  FOR r = 1 TO AROWS
    FOR c = 1 TO ACOLS
      IF alive(r, c) THEN PUT (fx + (c - 1) * GAPX, fy + (r - 1) * GAPY), alienSpr, PSET
    NEXT
  NEXT
RETURN

Status:
  LOCATE 1, 1: PRINT "SCORE"; score; "   WAVE"; wave; "   SHIPS"; lives; " "
RETURN
