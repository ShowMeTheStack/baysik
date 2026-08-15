' ============================================================
' TITLE:    Bouncing Balls with Gravity
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     physics, gravity, bounce, animation, page flipping
' SUMMARY:  Balls fall, bounce and slowly lose energy - change gravity and bounciness live.
' ------------------------------------------------------------
' WHAT IT DOES
'   A box full of coloured balls.  Gravity pulls each ball down a
'   little more every frame.  When a ball hits the floor or a wall
'   it bounces back, but loses some energy - just like a real ball,
'   which is why it bounces lower each time.
'
' HOW TO USE
'   SPACE  add a new ball           G  cycle gravity (Earth/Moon/Jupiter/none)
'   B      cycle bounciness         C  clear all balls
'   ESC    quit
'
' CONCEPTS YOU WILL LEARN
'   * Velocity and acceleration: position += velocity, velocity += gravity
'   * Coefficient of restitution (how "bouncy" something is)
'   * Arrays to hold many objects
'   * Smooth animation with two screen pages and PCOPY
'
' THINGS TO TRY
'   * Set bounciness above 1.0 - what happens to energy?
'   * Add air friction: multiply vx and vy by 0.999 every frame
'   * Make balls bounce off each other (hint: compare distances)
' ============================================================

DEFINT I-N                      ' integers for counters, singles for physics
CONST MAXB = 30                 ' most balls allowed at once
CONST FLOOR = 185, RIGHTW = 315, LEFTW = 4

DIM x(MAXB), y(MAXB)            ' ball positions (pixels)
DIM vx(MAXB), vy(MAXB)          ' ball velocities (pixels per frame)
DIM col(MAXB)                   ' ball colours
DIM gName$(3), gVal(3)

' Gravity values are scaled so Earth looks natural on screen.
' The ratios between them match the real planets!
gName$(0) = "Earth": gVal(0) = .25
gName$(1) = "Moon": gVal(1) = .25 * 1.62 / 9.81
gName$(2) = "Jupiter": gVal(2) = .25 * 24.8 / 9.81
gName$(3) = "Zero-G": gVal(3) = 0
gi = 0
bounce = .8                     ' keep 80% of the speed on each bounce
nb = 0

RANDOMIZE TIMER
' SCREEN 7 is 320x200 with 16 colours and several pages.
' We DRAW on page 1 (hidden) and SHOW page 0.  PCOPY copies the
' finished picture across in one go, so there is no flicker.
SCREEN 7, 0, 1, 0

FOR i = 1 TO 5: GOSUB AddBall: NEXT

DO
    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE " ": GOSUB AddBall
        CASE "G": gi = (gi + 1) MOD 4
        CASE "B"
            bounce = bounce + .1
            IF bounce > 1.05 THEN bounce = .3
        CASE "C": nb = 0
        CASE CHR$(27): EXIT DO
    END SELECT

    CLS
    LINE (LEFTW - 1, 10)-(RIGHTW + 4, FLOOR + 4), 8, B   ' the box
    g = gVal(gi)
    FOR i = 1 TO nb
        ' --- Physics for one frame -------------------------------
        vy(i) = vy(i) + g        ' gravity: speed downward grows
        x(i) = x(i) + vx(i)      ' move by the velocity
        y(i) = y(i) + vy(i)
        ' --- Collisions with the walls ---------------------------
        ' Put the ball back inside, then flip and shrink its speed.
        IF y(i) > FLOOR THEN y(i) = FLOOR: vy(i) = -vy(i) * bounce
        IF y(i) < 14 THEN y(i) = 14: vy(i) = -vy(i) * bounce
        IF x(i) > RIGHTW THEN x(i) = RIGHTW: vx(i) = -vx(i) * bounce
        IF x(i) < LEFTW + 3 THEN x(i) = LEFTW + 3: vx(i) = -vx(i) * bounce
        ' Rolling along the floor: a little friction slows sideways motion
        IF y(i) = FLOOR THEN vx(i) = vx(i) * .99
        CIRCLE (x(i), y(i)), 3, col(i)
        PAINT (x(i), y(i)), col(i), col(i)
    NEXT
    LOCATE 1, 1
    COLOR 15
    PRINT USING "Balls:## Gravity:\      \ Bounce:#.#"; nb; gName$(gi); bounce;
    LOCATE 25, 1: COLOR 7
    PRINT "SPC add G grav B bounce C clear ESC";
    PCOPY 1, 0                  ' show the finished frame
    WAIT &H3DA, 8               ' wait for the screen refresh (~60 fps)
LOOP

SCREEN 0: WIDTH 80
PRINT "Bye!"
END

' ------------------------------------------------------------
' AddBall: create a ball near the top with a random sideways speed
' ------------------------------------------------------------
AddBall:
    IF nb < MAXB THEN
        nb = nb + 1
        x(nb) = 20 + RND * 280
        y(nb) = 20 + RND * 40
        vx(nb) = RND * 4 - 2
        vy(nb) = 0
        col(nb) = 9 + INT(RND * 7)       ' bright colours 9..15
    END IF
RETURN
