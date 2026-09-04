' ============================================================
' TITLE:    Space Rocks
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     action, arcade, trigonometry, vectors, graphics, arrays
' SUMMARY:  Pilot a triangle ship through an asteroid field, blasting big rocks into smaller ones.
' ------------------------------------------------------------
' WHAT IT DOES
'   Your ship floats in space with no friction to stop it (almost!).
'   Rotate, thrust and fire at the drifting asteroids.  Big rocks break
'   into two medium rocks, medium into two small, and small ones are
'   destroyed.  Everything wraps around the screen edges.  Clear the
'   field to start a new wave with more rocks.  Touching a rock costs
'   one of your 3 ships.
'
' HOW TO USE
'   Left / Right arrows rotate    Up arrow thrusts
'   Space fires                   Esc quits
'
' CONCEPTS YOU WILL LEARN
'   * Angles, SIN and COS: turning a direction into x and y parts
'   * Velocity vectors and "screen wrap-around"
'   * Circle-to-point collision with distance squared (no SQR needed)
'   * Managing lists of objects (rocks, bullets) with "active" flags
'   * Held keys via scan codes (INP(&H60)) and retrace frame pacing
'
' THINGS TO TRY
'   * Add hyperspace: jump to a random spot on the H key
'   * Give each rock a jagged shape using DRAW
'   * Add a small UFO that shoots back
' ============================================================

DEFINT A-Z
CONST MAXR = 24, MAXS = 4                  ' max rocks, max shots
CONST PI = 3.14159

DIM rx(1 TO MAXR) AS SINGLE, ry(1 TO MAXR) AS SINGLE
DIM rvx(1 TO MAXR) AS SINGLE, rvy(1 TO MAXR) AS SINGLE
DIM rsize(1 TO MAXR)                       ' radius; 0 = slot unused
DIM sx(1 TO MAXS) AS SINGLE, sy(1 TO MAXS) AS SINGLE
DIM svx(1 TO MAXS) AS SINGLE, svy(1 TO MAXS) AS SINGLE
DIM slife(1 TO MAXS)                       ' frames left; 0 = unused
DIM px AS SINGLE, py AS SINGLE, pvx AS SINGLE, pvy AS SINGLE
DIM ang AS SINGLE, dx AS SINGLE, dy AS SINGLE
DIM held(127)                               ' true while that scan code's key is down
DIM nx(1 TO 3), ny(1 TO 3), ox(1 TO 3), oy(1 TO 3)   ' ship corners now / last frame

RANDOMIZE TIMER
SCREEN 13
score = 0: lives = 3: wave = 1

NewWave:
  CLS
  FOR i = 1 TO MAXR: rsize(i) = 0: NEXT
  FOR i = 1 TO MAXS: slife(i) = 0: NEXT
  FOR i = 1 TO 3 + wave
    ' start rocks along the edges, away from the ship in the middle
    rsize(i) = 16
    IF RND < .5 THEN rx(i) = RND * 320: ry(i) = 15 ELSE rx(i) = 10: ry(i) = RND * 200
    a! = RND * 2 * PI
    rvx(i) = COS(a!) * (.6 + RND * .6): rvy(i) = SIN(a!) * (.6 + RND * .6)
  NEXT
  GOSUB Status

NewShip:
  px = 160: py = 100: pvx = 0: pvy = 0: ang = -PI / 2   ' pointing up
  safe = 120                               ' frames of invulnerability
  FOR i = 1 TO 3: ox(i) = 160: oy(i) = 100: NEXT

' ================= MAIN LOOP =================
DO
  thrust = 0

  ' ---- input part 1: keys held down (scan codes from port &H60;
  '      75 = left, 77 = right, 72 = up; +128 means released) ----
  sc = INP(&H60)
  IF sc < 128 THEN held(sc) = -1 ELSE held(sc - 128) = 0
  IF held(75) THEN ang = ang - .09                ' about 5 degrees a frame
  IF held(77) THEN ang = ang + .09
  IF held(72) THEN pvx = pvx + COS(ang) * .06: pvy = pvy + SIN(ang) * .06: thrust = -1

  ' ---- input part 2: INKEY$ for taps, Space and Esc ----
  DO
    k$ = INKEY$
    IF k$ = "" THEN EXIT DO
    IF k$ = CHR$(27) THEN GOTO Quit
    k = 0: IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
    IF k = 75 AND NOT held(75) THEN ang = ang - PI / 12   ' a tap turns 15 degrees
    IF k = 77 AND NOT held(77) THEN ang = ang + PI / 12
    IF k = 72 AND NOT held(72) THEN
      ' thrust adds a little velocity in the direction we face
      pvx = pvx + COS(ang) * .5: pvy = pvy + SIN(ang) * .5: thrust = -1
    END IF
    IF k$ = " " THEN
      FOR i = 1 TO MAXS
        IF slife(i) = 0 THEN
          sx(i) = px + COS(ang) * 7: sy(i) = py + SIN(ang) * 7
          svx(i) = pvx + COS(ang) * 4: svy(i) = pvy + SIN(ang) * 4
          slife(i) = 40: SOUND 1800, .2
          EXIT FOR
        END IF
      NEXT
    END IF
  LOOP

  ' ---- move the ship (with a tiny bit of space friction) ----
  pvx = pvx * .99: pvy = pvy * .99
  px = px + pvx: py = py + pvy
  GOSUB WrapShip
  ' the three corners of the triangle: nose, back-left, back-right
  nx(1) = px + COS(ang) * 7: ny(1) = py + SIN(ang) * 7
  nx(2) = px + COS(ang + 2.5) * 5: ny(2) = py + SIN(ang + 2.5) * 5
  nx(3) = px + COS(ang - 2.5) * 5: ny(3) = py + SIN(ang - 2.5) * 5

  ' ---- erase everything at its OLD position ----
  LINE (ox(1), oy(1))-(ox(2), oy(2)), 0: LINE -(ox(3), oy(3)), 0: LINE -(ox(1), oy(1)), 0
  FOR i = 1 TO MAXR
    IF rsize(i) THEN CIRCLE (rx(i), ry(i)), rsize(i), 0
  NEXT
  FOR i = 1 TO MAXS
    IF slife(i) THEN PSET (sx(i), sy(i)), 0
  NEXT

  ' ---- move rocks and shots, wrapping at the edges ----
  FOR i = 1 TO MAXR
    IF rsize(i) THEN
      rx(i) = rx(i) + rvx(i): ry(i) = ry(i) + rvy(i)
      IF rx(i) < 0 THEN rx(i) = rx(i) + 320
      IF rx(i) >= 320 THEN rx(i) = rx(i) - 320
      IF ry(i) < 10 THEN ry(i) = ry(i) + 190
      IF ry(i) >= 200 THEN ry(i) = ry(i) - 190
    END IF
  NEXT
  FOR s = 1 TO MAXS
    IF slife(s) THEN
      slife(s) = slife(s) - 1
      sx(s) = sx(s) + svx(s): sy(s) = sy(s) + svy(s)
      IF sx(s) < 0 THEN sx(s) = sx(s) + 320
      IF sx(s) >= 320 THEN sx(s) = sx(s) - 320
      IF sy(s) < 10 THEN sy(s) = sy(s) + 190
      IF sy(s) >= 200 THEN sy(s) = sy(s) - 190
      ' did this shot hit a rock?  compare distance squared with radius squared
      FOR i = 1 TO MAXR
        IF rsize(i) AND slife(s) THEN
          dx = sx(s) - rx(i): dy = sy(s) - ry(i)
          IF dx * dx + dy * dy < rsize(i) * rsize(i) THEN
            slife(s) = 0
            GOSUB SplitRock
          END IF
        END IF
      NEXT
    END IF
  NEXT

  ' ---- ship hit by a rock? ----
  IF safe > 0 THEN safe = safe - 1
  IF safe = 0 THEN
    FOR i = 1 TO MAXR
      IF rsize(i) THEN
        dx = px - rx(i): dy = py - ry(i)
        IF dx * dx + dy * dy < (rsize(i) + 4) * (rsize(i) + 4) THEN
          lives = lives - 1: GOSUB Status
          FOR f = 1 TO 20
            CIRCLE (px, py), f, 40 + f MOD 8
            SOUND 40 + RND * 100, .3
          NEXT
          FOR f = 1 TO 20: CIRCLE (px, py), f, 0: NEXT
          IF lives = 0 THEN EXIT DO
          LINE (ox(1), oy(1))-(ox(2), oy(2)), 0: LINE -(ox(3), oy(3)), 0: LINE -(ox(1), oy(1)), 0
          GOTO NewShip
        END IF
      END IF
    NEXT
  END IF

  ' ---- draw everything at its NEW position ----
  ' (the score line is refreshed now and then, as rocks drift over it)
  frameNo = frameNo + 1: IF frameNo MOD 10 = 0 THEN GOSUB Status
  FOR i = 1 TO MAXR
    IF rsize(i) THEN CIRCLE (rx(i), ry(i)), rsize(i), 7
  NEXT
  FOR i = 1 TO MAXS
    IF slife(i) THEN PSET (sx(i), sy(i)), 14
  NEXT
  IF safe > 0 AND (safe \ 4) MOD 2 = 0 THEN c = 8 ELSE c = 15   ' blink while safe
  LINE (nx(1), ny(1))-(nx(2), ny(2)), c: LINE -(nx(3), ny(3)), c: LINE -(nx(1), ny(1)), c
  IF thrust THEN SOUND 60, .2
  FOR i = 1 TO 3: ox(i) = nx(i): oy(i) = ny(i): NEXT

  ' ---- all rocks gone? ----
  rocksLeft = 0
  FOR i = 1 TO MAXR: IF rsize(i) THEN rocksLeft = rocksLeft + 1
  NEXT
  IF rocksLeft = 0 THEN wave = wave + 1: PLAY "MB T200 L16 CEG>C": GOTO NewWave

  ' pace the game to the screen refresh (about 60 frames a second)
  WAIT &H3DA, 8, 8: WAIT &H3DA, 8
LOOP

LOCATE 12, 15: PRINT "GAME OVER"
LOCATE 14, 13: PRINT "Score:"; score
LOCATE 16, 10: PRINT "Press Esc to exit"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
SCREEN 0: WIDTH 80
PRINT "Space Rocks - final score:"; score
END

' ---- rock i was hit: shrink it and add a twin going another way ----
SplitRock:
  CIRCLE (rx(i), ry(i)), rsize(i), 0
  score = score + (20 - rsize(i)) * 5
  SOUND 100 + rsize(i) * 10, .5
  IF rsize(i) <= 4 THEN
    rsize(i) = 0                      ' smallest size: gone
  ELSE
    rsize(i) = rsize(i) \ 2
    FOR j = 1 TO MAXR
      IF rsize(j) = 0 THEN
        rsize(j) = rsize(i): rx(j) = rx(i): ry(j) = ry(i)
        ' the twin flies off at right angles, both get a bit faster
        rvx(j) = -rvy(i) * 1.3: rvy(j) = rvx(i) * 1.3
        EXIT FOR
      END IF
    NEXT
    tmp! = rvx(i)                      ' keep the old x speed before changing it
    rvx(i) = rvy(i) * 1.3: rvy(i) = -tmp! * 1.3
  END IF
  GOSUB Status
RETURN

WrapShip:
  IF px < 0 THEN px = px + 320
  IF px >= 320 THEN px = px - 320
  IF py < 10 THEN py = py + 190
  IF py >= 200 THEN py = py - 190
RETURN

Status:
  LOCATE 1, 1: PRINT "SCORE"; score; "  WAVE"; wave; "  SHIPS"; lives; " "
RETURN
