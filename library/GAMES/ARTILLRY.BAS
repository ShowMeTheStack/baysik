' ============================================================
' TITLE:    Hilltop Artillery
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     physics, projectile, trigonometry, terrain, graphics, ai
' SUMMARY:  Two cannons on rolling hills lob shells at each other, allowing for gravity and wind.
' ------------------------------------------------------------
' WHAT IT DOES
'   A random landscape of hills is generated with a cannon at each
'   end.  Take turns choosing an angle and a power, then fire.  The
'   shell flies in a curve pulled down by gravity and pushed by the
'   wind (shown by the arrow at the top).  Shells blast craters out
'   of the hills.  First to 3 direct hits wins.  Play against a
'   friend or against the computer, which corrects its aim after
'   every miss like a real gunner.
'
' HOW TO USE
'   Choose 1 (two players) or 2 (versus computer) at the start.
'   Up / Down arrows   change the angle
'   Left / Right       change the power
'   Space              fire!          Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Projectile motion: splitting a launch speed into x and y parts
'     with COS and SIN, then adding gravity each time step
'   * A height map array for terrain, made from added sine waves
'   * Destructible terrain: lowering the height map inside a circle
'   * A self-correcting AI (adjust power by how far the miss was)
'
' THINGS TO TRY
'   * Add a different weapon with a bigger crater
'   * Make the wind change during the shell's flight
'   * Let the computer also adjust its angle, not just its power
' ============================================================

DEFINT A-Z
CONST G = 60!                  ' gravity in pixels per second^2
CONST GROUNDCOL = 6, SKYCOL = 0

DIM h(0 TO 319)                ' ground height (y of the surface) at each x
DIM gunX(1 TO 2), gunY(1 TO 2), angle(1 TO 2), power(1 TO 2), wins(1 TO 2)
DIM sx AS SINGLE, sy AS SINGLE, vx AS SINGLE, vy AS SINGLE
DIM wind AS SINGLE, dt AS SINGLE, a AS SINGLE
DIM aiPower AS SINGLE
DIM trX(1 TO 2000), trY(1 TO 2000)   ' the dotted trail, so we can erase it

RANDOMIZE TIMER
SCREEN 13
CLS
LOCATE 8, 11: PRINT "HILLTOP ARTILLERY"
LOCATE 11, 9: PRINT "1 = two players"
LOCATE 12, 9: PRINT "2 = versus computer"
DO
  k$ = INKEY$
  IF k$ = CHR$(27) THEN GOTO Quit
LOOP UNTIL k$ = "1" OR k$ = "2"
vsCpu = (k$ = "2")
player = 1

NewRound:
  GOSUB MakeTerrain
  angle(1) = 45: power(1) = 50
  angle(2) = 45: power(2) = 50
  aiPower = 40 + RND * 20: lastMiss = 0
  wind = RND * 30 - 15                      ' negative = blowing left
  GOSUB DrawWind

' ================= one shot per pass =================
DO
  GOSUB Status
  ' ---- aiming ----
  IF vsCpu AND player = 2 THEN
    ' the computer "thinks" for a moment, then fires
    angle(2) = 45 + INT(RND * 11) - 5
    power(2) = aiPower
    IF power(2) > 100 THEN power(2) = 100
    IF power(2) < 10 THEN power(2) = 10
    GOSUB Status
    t! = TIMER: DO: LOOP WHILE TIMER < t! + .8 AND TIMER >= t!
  ELSE
    DO
      DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
      IF k$ = CHR$(27) THEN GOTO Quit
      k = 0: IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
      IF k = 72 AND angle(player) < 89 THEN angle(player) = angle(player) + 1
      IF k = 80 AND angle(player) > 1 THEN angle(player) = angle(player) - 1
      IF k = 77 AND power(player) < 100 THEN power(player) = power(player) + 1
      IF k = 75 AND power(player) > 5 THEN power(player) = power(player) - 1
      GOSUB Status
    LOOP UNTIL k$ = " "
  END IF

  ' ---- fire!  player 1 shoots to the right, player 2 to the left ----
  a = angle(player) * 3.14159 / 180
  dirn = 1: IF player = 2 THEN dirn = -1
  vx = COS(a) * power(player) * 2.2 * dirn
  vy = -SIN(a) * power(player) * 2.2       ' negative = upwards on screen
  sx = gunX(player): sy = gunY(player) - 6
  dt = .03
  hitWho = 0: landed = 0: steps = 0
  SOUND 100, 1
  DO
    ' one small time step of the physics
    vx = vx + wind * dt
    vy = vy + G * dt
    sx = sx + vx * dt: sy = sy + vy * dt
    IF sx < 0 OR sx > 319 OR sy > 199 THEN EXIT DO      ' left the screen
    steps = steps + 1
    IF sy >= 0 THEN
      PSET (sx, sy), 15                     ' leave a dotted trail
      IF steps <= 2000 THEN trX(steps) = sx: trY(steps) = sy
      ' did it reach a cannon?  (ignore our own until the shell is clear)
      FOR p = 1 TO 2
        IF p <> player OR steps > 20 THEN
          IF ABS(sx - gunX(p)) < 6 AND ABS(sy - (gunY(p) - 3)) < 6 THEN hitWho = p
        END IF
      NEXT
      IF hitWho THEN EXIT DO
      ' did it hit the ground?
      IF sy >= h(INT(sx)) THEN landed = -1: EXIT DO
    END IF
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8        ' one step per screen refresh (~60 a second)
  LOOP

  ' ---- rub out the trail (only the dots that are in the sky) ----
  IF steps > 2000 THEN steps = 2000
  FOR i = 1 TO steps
    IF trY(i) > 0 AND trY(i) < h(trX(i)) THEN PSET (trX(i), trY(i)), SKYCOL
  NEXT
  FOR i = 1 TO 2000: trY(i) = 0: NEXT   ' (points above the screen were never stored)

  ' ---- results of the shot ----
  IF landed OR hitWho THEN
    GOSUB Crater
  END IF
  IF hitWho THEN
    winner = 3 - hitWho                     ' (hitting yourself counts for the other side!)
    wins(winner) = wins(winner) + 1
    FOR f = 1 TO 25: CIRCLE (gunX(hitWho), gunY(hitWho)), f, 40 + f MOD 8: SOUND 50 + f * 20, .3: NEXT
    LOCATE 4, 10: PRINT "PLAYER"; winner; "SCORES!"
    IF wins(winner) >= 3 THEN EXIT DO
    t! = TIMER: DO: LOOP WHILE TIMER < t! + 1.5 AND TIMER >= t!
    player = hitWho                         ' the one who was hit goes first
    GOTO NewRound
  END IF

  ' ---- the computer learns from its miss ----
  IF vsCpu AND player = 2 THEN
    ' miss distance: positive = shell fell short (still to the right of the target)
    IF landed THEN miss = sx - gunX(1) ELSE miss = -100   ' flew off: too far
    IF sx > 319 THEN miss = 100                           ' off the right edge: too short
    aiPower = aiPower + miss / 12
  END IF
  t! = TIMER: DO: LOOP WHILE TIMER < t! + .5 AND TIMER >= t!
  player = 3 - player
LOOP

LOCATE 6, 9: PRINT "PLAYER"; winner; "WINS THE WAR!"
PLAY "MB T150 L8 CCG GAA G4"
LOCATE 8, 11: PRINT "Press Esc to exit"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
SCREEN 0: WIDTH 80
PRINT "Final score - player 1:"; wins(1); " player 2:"; wins(2)
END

' ---- build a random landscape from three sine waves ----
MakeTerrain:
  CLS
  p1! = RND * 6.28: p2! = RND * 6.28: p3! = RND * 6.28
  FOR x = 0 TO 319
    y! = 140 + 25 * SIN(x / 50 + p1!) + 12 * SIN(x / 23 + p2!) + 5 * SIN(x / 9 + p3!)
    h(x) = y!
    LINE (x, h(x))-(x, 199), GROUNDCOL
  NEXT
  ' place the cannons and flatten a little ledge under each
  gunX(1) = 20 + INT(RND * 30): gunX(2) = 300 - INT(RND * 30)
  FOR p = 1 TO 2
    gy = h(gunX(p))
    FOR x = gunX(p) - 6 TO gunX(p) + 6
      LINE (x, 0)-(x, 199), SKYCOL
      h(x) = gy
      LINE (x, gy)-(x, 199), GROUNDCOL
    NEXT
    gunY(p) = gy
    GOSUB DrawGun
  NEXT
RETURN

DrawGun:
  ' a little tank: body, turret dome, colour per player
  IF p = 1 THEN c = 11 ELSE c = 12
  LINE (gunX(p) - 5, gunY(p) - 3)-(gunX(p) + 5, gunY(p) - 1), c, BF
  CIRCLE (gunX(p), gunY(p) - 4), 3, c
RETURN

' ---- blow a hole in the ground around (sx, sy) ----
Crater:
  ' For each column the blast circle covers, find the circle's lowest
  ' point there (Pythagoras: dy = SQR(r^2 - dx^2)).  If that is below
  ' the ground surface, dig the surface down to it.
  r = 9
  FOR x = INT(sx) - r TO INT(sx) + r
    IF x >= 0 AND x <= 319 THEN
      dy! = SQR(ABS(r * r - (x - sx) ^ 2))
      bottom = sy + dy!
      IF bottom > 199 THEN bottom = 199
      IF bottom > h(x) THEN
        LINE (x, h(x))-(x, bottom), SKYCOL
        h(x) = bottom
      END IF
    END IF
  NEXT
  FOR f = 1 TO 5: SOUND 60 + RND * 60, .5: NEXT
  ' the blast may have uncovered (or buried) a cannon - redraw both
  FOR p = 1 TO 2: GOSUB DrawGun: NEXT
RETURN

DrawWind:
  LOCATE 1, 15: PRINT "WIND"
  wx = 160 + wind * 3
  LINE (160, 12)-(wx, 12), 14
  IF wind > 0 THEN LINE (wx, 12)-(wx - 3, 10), 14: LINE (wx, 12)-(wx - 3, 14), 14
  IF wind < 0 THEN LINE (wx, 12)-(wx + 3, 10), 14: LINE (wx, 12)-(wx + 3, 14), 14
RETURN

Status:
  LOCATE 1, 1: PRINT "P1:"; wins(1);
  LOCATE 1, 33: PRINT "P2:"; wins(2);
  LOCATE 3, 1: PRINT SPACE$(40);
  IF player = 1 THEN LOCATE 3, 1 ELSE LOCATE 3, 21
  PRINT "P"; LTRIM$(STR$(player)); " ang"; angle(player); "pow"; power(player);
RETURN
