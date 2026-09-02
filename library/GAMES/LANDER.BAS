' ============================================================
' TITLE:    Lunar Lander
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     physics, gravity, simulation, graphics, timer
' SUMMARY:  Fire your thrusters to set a lunar module gently down on the landing pad.
' ------------------------------------------------------------
' WHAT IT DOES
'   Your lander starts high above a rugged moon surface.  The Moon's
'   gravity pulls it down faster and faster.  Fire the main engine
'   to slow your fall and the side jets to drift left or right.  Land
'   on the flat yellow pad slowly and you score points for the fuel
'   you saved.  Touch down too fast, or anywhere else, and you crash.
'
' HOW TO USE
'   Up arrow (or W) = main engine      Left / Right (or A / D) = side jets
'   Each key press fires the engine for a moment; hold the key down
'   for a steady burn.  Esc quits.  After a landing or crash press
'   Space to fly again.
'
' CONCEPTS YOU WILL LEARN
'   * Euler integration: velocity += acceleration * dt,
'     position += velocity * dt
'   * A fixed time step (dt) locked to the screen refresh with
'     WAIT &H3DA - and why TIMER (18.2 ticks a second) is too coarse
'   * Detecting held keys with scan codes from INP(&H60)
'   * Random terrain made from connected line segments
'   * Reading the terrain height under the lander by interpolation
'
' THINGS TO TRY
'   * Change GRAVITY to Mars (about 2.3x the Moon) or Earth (6x)
'   * Add wind that pushes the lander sideways
'   * Make the pad smaller on each new level
' ============================================================

DEFINT A-Z
CONST GRAVITY = 16!       ' pixels per second per second (the Moon is gentle)
CONST THRUST = 40!        ' main engine acceleration
CONST SIDE = 14!          ' side-jet acceleration
CONST SAFEVY = 22!, SAFEVX = 12!   ' fastest safe landing speeds
CONST NPTS = 16           ' terrain points

DIM tx(0 TO NPTS), ty(0 TO NPTS)    ' terrain corner points
DIM x AS SINGLE, y AS SINGLE, vx AS SINGLE, vy AS SINGLE
DIM ax AS SINGLE, ay AS SINGLE, fuel AS SINGLE, dt AS SINGLE
DIM ox AS SINGLE, oy AS SINGLE
DIM ground AS SINGLE, f AS SINGLE
DIM held(127)             ' true while the key with that scan code is down

RANDOMIZE TIMER
SCREEN 13
totalScore = 0

NewFlight:
  CLS
  ' ---- make random terrain with one flat pad ----
  padSeg = INT(RND * (NPTS - 4)) + 2       ' which segment is the pad
  FOR i = 0 TO NPTS
    tx(i) = i * 320 \ NPTS
    ty(i) = 130 + INT(RND * 60)
  NEXT
  ty(padSeg + 1) = ty(padSeg)              ' flat segment = landing pad
  ' draw it: grey hills, yellow pad
  FOR i = 0 TO NPTS - 1
    IF i = padSeg THEN c = 14 ELSE c = 7
    LINE (tx(i), ty(i))-(tx(i + 1), ty(i + 1)), c
  NEXT
  LINE (tx(padSeg), ty(padSeg) + 1)-(tx(padSeg + 1), ty(padSeg) + 1), 14
  ' a few stars
  FOR i = 1 TO 40: PSET (RND * 319, RND * 100 + 12), 8 + INT(RND * 2) * 7: NEXT

  x = 20 + RND * 280: y = 20: vx = RND * 20 - 10: vy = 0
  fuel = 100
  mainOn = 0: leftOn = 0: rightOn = 0     ' frames left on each engine
  ox = x: oy = y
  ' One frame per screen refresh, about 1/60 of a second.  We use this
  ' FIXED dt instead of measuring time with TIMER, because TIMER only
  ' changes every 1/18.2 s: measured dt values would jump between 0
  ' and 0.055 and the lander would move in jerks.
  dt = 1 / 60

' ================= FLIGHT LOOP =================
DO
  ' ---- input part 1: held keys (scan codes: 72 up, 75 left, 77 right,
  '      17 W, 30 A, 32 D; a code + 128 means the key was released) ----
  sc = INP(&H60)
  IF sc < 128 THEN held(sc) = -1 ELSE held(sc - 128) = 0
  IF held(72) OR held(17) THEN mainOn = 2
  IF held(75) OR held(30) THEN rightOn = 2
  IF held(77) OR held(32) THEN leftOn = 2
  ' ---- input part 2: INKEY$ (a tap fires an engine for a moment) ----
  DO
    k$ = INKEY$
    IF k$ = "" THEN EXIT DO
    IF k$ = CHR$(27) THEN GOTO Quit
    k = 0: IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
    u$ = UCASE$(k$)
    IF k = 72 OR u$ = "W" THEN mainOn = 8
    IF k = 75 OR u$ = "A" THEN rightOn = 8   ' the RIGHT jet pushes you LEFT
    IF k = 77 OR u$ = "D" THEN leftOn = 8
  LOOP

  ' ---- physics ----
  ax = 0: ay = GRAVITY
  IF fuel <= 0 THEN mainOn = 0: leftOn = 0: rightOn = 0
  IF mainOn THEN ay = ay - THRUST: fuel = fuel - 12 * dt: mainOn = mainOn - 1
  IF leftOn THEN ax = ax + SIDE: fuel = fuel - 4 * dt: leftOn = leftOn - 1
  IF rightOn THEN ax = ax - SIDE: fuel = fuel - 4 * dt: rightOn = rightOn - 1
  IF fuel < 0 THEN fuel = 0
  vx = vx + ax * dt: vy = vy + ay * dt   ' acceleration changes velocity
  x = x + vx * dt: y = y + vy * dt       ' velocity changes position
  IF x < 4 THEN x = 4: vx = 0
  IF x > 315 THEN x = 315: vx = 0

  ' ---- draw: erase old lander + flame, draw new ----
  LINE (ox - 5, oy - 6)-(ox + 5, oy + 9), 0, BF
  GOSUB DrawLander
  ox = x: oy = y
  LOCATE 1, 1: PRINT USING "FUEL ###  VX ###.#  VY ###.#  "; fuel; vx; -vy;

  ' ---- terrain height under the lander (straight-line interpolation) ----
  segNo = INT(x * NPTS / 320): IF segNo > NPTS - 1 THEN segNo = NPTS - 1
  f = (x - tx(segNo)) / (tx(segNo + 1) - tx(segNo))
  ground = ty(segNo) + (ty(segNo + 1) - ty(segNo)) * f

  IF y + 5 >= ground THEN EXIT DO           ' touched the surface

  ' wait for the next screen refresh (the vertical retrace)
  WAIT &H3DA, 8, 8: WAIT &H3DA, 8
LOOP

' ---- landed or crashed? ----
onPad = (segNo = padSeg AND x - 4 >= tx(padSeg) AND x + 4 <= tx(padSeg + 1))
IF onPad AND vy <= SAFEVY AND ABS(vx) <= SAFEVX THEN
  pts = 50 + INT(fuel) * 5
  totalScore = totalScore + pts
  LOCATE 6, 12: PRINT "THE EAGLE HAS LANDED!"
  LOCATE 8, 12: PRINT "Points:"; pts; " Total:"; totalScore
  PLAY "MB T160 L8 CEG>C"
ELSE
  ' crash: a little explosion of random pixels
  FOR i = 1 TO 120
    PSET (x + RND * 30 - 15, y + RND * 20 - 15), 40 + INT(RND * 6)
    IF i MOD 10 = 0 THEN SOUND 60 + RND * 80, .5
  NEXT
  LOCATE 6, 14: PRINT "CRASH!"
  IF NOT onPad THEN
    LOCATE 8, 6: PRINT "You missed the landing pad."
  ELSE
    LOCATE 8, 6: PRINT "Too fast! Keep VY under"; INT(SAFEVY)
  END IF
END IF
LOCATE 10, 8: PRINT "Space = fly again, Esc = quit"
DO
  k$ = INKEY$
  IF k$ = " " THEN GOTO NewFlight
LOOP UNTIL k$ = CHR$(27)

Quit:
SCREEN 0: WIDTH 80
PRINT "Total landing score:"; totalScore
END

DrawLander:
  ' body, legs and window
  LINE (x - 3, y - 4)-(x + 3, y + 1), 15, BF
  PSET (x, y - 2), 9
  LINE (x - 3, y + 1)-(x - 5, y + 5), 7
  LINE (x + 3, y + 1)-(x + 5, y + 5), 7
  ' flames for whichever engines are firing
  IF mainOn THEN LINE (x - 1, y + 2)-(x + 1, y + 4 + INT(RND * 4)), 42, BF
  IF leftOn THEN PSET (x - 5, y - 2), 44
  IF rightOn THEN PSET (x + 5, y - 2), 44
RETURN
