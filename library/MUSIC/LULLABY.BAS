' ============================================================
' TITLE:    Brahms Lullaby and the Rocking Cradle
' CATEGORY: Music & Sound
' LEVEL:    Intermediate
' TAGS:     play, background music, mb, animation, screen 13, trigonometry
' SUMMARY:  Brahms' Lullaby plays in the background while a cradle rocks under the moon and Zzz's float up.
' ------------------------------------------------------------
' WHAT IT DOES
'   Plays Johannes Brahms' "Wiegenlied" (Lullaby, 1868, public
'   domain) using background music (MB). Because the music plays
'   by itself, the program is free to animate: a cradle rocks
'   gently from side to side and sleepy "z" letters drift upward.
'   The song is fed to PLAY one phrase at a time, topping up the
'   music queue whenever it is nearly empty.
'
' HOW TO USE
'   Watch and listen. Esc quits at any time.
'
' CONCEPTS YOU WILL LEARN
'   * MB background music and the PLAY(0) queue counter
'   * Feeding a long song in chunks so the queue never overflows
'   * Rotating points with SIN and COS to rock a drawing
'   * Erase-and-redraw animation in SCREEN 13
'
' THINGS TO TRY
'   * Make the cradle rock in time with the beat (hint: TIMER).
'   * Add twinkling stars that blink on each new phrase.
' ============================================================

DECLARE SUB Cradle (ang!, c%)

' The song as phrases, in 3/4 time, roughly one line of words each.
DATA "O4 L8 E E G4. E8 E4 G2 E8 G8"
DATA "> C4 < B4. A8 A4 G4 D8 E8"
DATA "F4 D4 D8 E8 F2 D8 F8"
DATA "B8 A8 G4 B4 > C2 < C8 C8"
DATA "> C2 < A8 F8 G2 E8 C8"
DATA "F4 G4 A4 G2 C8 C8"
DATA "> C2 < A8 F8 G2 E8 C8"
DATA "F4 E4 D4 C2."
DATA ""

' The cradle's outline: number of corners, then (dx,dy) pairs
' measured from the pivot point the cradle rocks around.
DATA 6
DATA -35,-15, 35,-15, 28,10, 10,14, -10,14, -28,10

' Read everything into arrays FIRST. (If the SUB used READ while
' the main loop was also reading phrases, they would fight over
' the single DATA pointer.)
DIM song$(20)
nPhr = 0
DO
  READ p$
  IF p$ = "" THEN EXIT DO
  nPhr = nPhr + 1: song$(nPhr) = p$
LOOP
DIM SHARED cx(10), cy(10), nCorner
READ nCorner
FOR i = 1 TO nCorner: READ cx(i), cy(i): NEXT

SCREEN 13
CLS
' A starry night sky.
RANDOMIZE 7               ' fixed seed: the same sky every time
FOR i = 1 TO 80: PSET (RND * 319, RND * 120), 15 - INT(RND * 2) * 8: NEXT
' The moon: a yellow circle with a dark circle over it = crescent.
CIRCLE (260, 40), 22, 14: PAINT (260, 40), 14, 14
CIRCLE (270, 34), 20, 0: PAINT (272, 34), 0, 0
' The floor.
LINE (0, 182)-(319, 199), 6, BF
COLOR 11: LOCATE 1, 2: PRINT "Brahms' Lullaby";
COLOR 7: LOCATE 25, 2: PRINT "Esc = quit";

' Start in background mode at a gentle tempo, legato.
PLAY "MB T90 ML"
nextPhr = 1                  ' the next phrase to queue

DIM zx(5), zy(5)             ' positions of up to 5 floating z's
FOR i = 1 TO 5: zx(i) = -1: NEXT

t0 = TIMER: lastAng = 0
DO
  ' ---- Keep the music queue topped up -----------------------
  ' PLAY(0) = notes still waiting. When fewer than 6 are left we
  ' queue the next phrase. QBasic's background queue holds 32
  ' notes, and no phrase here is longer than 12.
  IF nextPhr <= nPhr AND PLAY(0) < 6 THEN
    PLAY song$(nextPhr)
    nextPhr = nextPhr + 1
  END IF

  ' ---- Rock the cradle ---------------------------------------
  ' The angle swings like a pendulum: SIN gives a smooth wave
  ' between -1 and 1; times 0.25 radians (about 14 degrees).
  t = TIMER - t0
  IF t < 0 THEN t = t + 86400        ' midnight wrap-around
  ang = .25 * SIN(t * 2)
  Cradle lastAng, 0                  ' erase old drawing (black)
  Cradle ang, 12                     ' draw new one (light red)
  lastAng = ang

  ' ---- Float the z's -----------------------------------------
  ' Each z moves up one pixel per frame and wiggles sideways.
  FOR i = 1 TO 5
    IF zx(i) >= 0 THEN
      LINE (zx(i), zy(i))-(zx(i) + 4, zy(i) + 4), 0, BF   ' erase
      zy(i) = zy(i) - 1
      zx(i) = zx(i) + SIN(zy(i) / 6)
      IF zy(i) < 30 THEN
        zx(i) = -1                    ' gone off the top
      ELSE
        ' Draw a tiny "z" with three lines.
        LINE (zx(i), zy(i))-(zx(i) + 4, zy(i)), 9
        LINE (zx(i) + 4, zy(i))-(zx(i), zy(i) + 4), 9
        LINE (zx(i), zy(i) + 4)-(zx(i) + 4, zy(i) + 4), 9
      END IF
    ELSEIF RND < .02 THEN
      zx(i) = 150 + RND * 20: zy(i) = 120   ' new z from the cradle
    END IF
  NEXT

  ' Frame delay of about 1/30 second.
  w = TIMER: DO WHILE TIMER - w < .033 AND TIMER >= w: LOOP
  IF INKEY$ = CHR$(27) THEN EXIT DO
LOOP UNTIL nextPhr > nPhr AND PLAY(0) = 0

PLAY "MF MN"
COLOR 14: LOCATE 12, 14: PRINT "Sweet dreams...";
LOCATE 25, 2: COLOR 7: PRINT "Press any key";
k$ = INPUT$(1)
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' Cradle: draws the cradle tilted by ang! (radians) around its
' pivot point at (160,150). Each corner (dx,dy) relative to the
' pivot is rotated with the standard formula:
'     x' = dx*COS(a) - dy*SIN(a)
'     y' = dx*SIN(a) + dy*COS(a)
' ------------------------------------------------------------
SUB Cradle (ang!, c%)
  ca = COS(ang!): sa = SIN(ang!)
  px = 160: py = 150
  ' Corners of the basket: a trapezoid, wider at the top.
  dx = cx(1): dy = cy(1)
  fx = px + dx * ca - dy * sa: fy = py + dx * sa + dy * ca
  ox = fx: oy = fy
  FOR i = 2 TO nCorner
    dx = cx(i): dy = cy(i)
    nx = px + dx * ca - dy * sa: ny = py + dx * sa + dy * ca
    LINE (ox, oy)-(nx, ny), c%
    ox = nx: oy = ny
  NEXT
  LINE (ox, oy)-(fx, fy), c%          ' close the shape
  ' Rockers: an arc under the cradle (just a line here, tilted).
  LINE (px - 40 * ca - 16 * sa, py - 40 * sa + 16 * ca)-(px + 40 * ca - 16 * sa, py + 40 * sa + 16 * ca), c%
END SUB
