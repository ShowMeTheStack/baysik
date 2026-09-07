' ============================================================
' TITLE:    Colliding Balls
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     physics, collisions, momentum, vectors, page flipping
' SUMMARY:  Balls of different sizes bounce off the walls and off each other with realistic, momentum-conserving collisions.
' ------------------------------------------------------------
' WHAT IT DOES
'   Each ball has a position, a velocity and a mass (bigger ball
'   = heavier).  Every frame:
'     1. move every ball by its velocity (and gravity, if on)
'     2. bounce off the walls
'     3. check every PAIR of balls; if they overlap, push them
'        apart and swap momentum along the line joining their
'        centres - an "elastic collision", like snooker balls.
'   Frames are drawn on a hidden page and copied to the screen.
'
' HOW TO USE
'   G      gravity on / off
'   SPACE  give every ball a random kick
'   +      add a ball (up to 14)     -  remove a ball
'   Esc    quit
'
' CONCEPTS YOU WILL LEARN
'   * Distance between two points: SQR(dx^2 + dy^2)
'   * The normal vector (nx, ny) = direction from one centre to
'     the other, scaled to length 1
'   * Conservation of momentum: heavy balls barely notice a
'     small one; equal balls trade speeds
'   * Checking all pairs with a nested loop (j starts at i + 1)
'
' THINGS TO TRY
'   * Make collisions lose a little energy (multiply impulse by 0.9)
'   * Line up five equal balls for a Newton's cradle
' ============================================================
DEFINT A-Z
DECLARE SUB NewBall (i)

CONST MAXB = 14
DIM SHARED x(MAXB) AS SINGLE, y(MAXB) AS SINGLE
DIM SHARED vx(MAXB) AS SINGLE, vy(MAXB) AS SINGLE
DIM SHARED r(MAXB) AS SINGLE, m(MAXB) AS SINGLE, c(MAXB)

SCREEN 7, , 1, 0                  ' draw on page 1, show page 0
RANDOMIZE TIMER
nb = 7: grav = 0
FOR i = 1 TO MAXB: NewBall i: NEXT

DO
    ' ---- 1 + 2: move and bounce off walls --------------------
    FOR i = 1 TO nb
        IF grav THEN vy(i) = vy(i) + .15
        x(i) = x(i) + vx(i): y(i) = y(i) + vy(i)
        IF x(i) < r(i) THEN x(i) = r(i): vx(i) = ABS(vx(i))
        IF x(i) > 319 - r(i) THEN x(i) = 319 - r(i): vx(i) = -ABS(vx(i))
        IF y(i) < 10 + r(i) THEN y(i) = 10 + r(i): vy(i) = ABS(vy(i))
        IF y(i) > 199 - r(i) THEN y(i) = 199 - r(i): vy(i) = -ABS(vy(i))
    NEXT

    ' ---- 3: ball-ball collisions ------------------------------
    FOR i = 1 TO nb - 1
        FOR j = i + 1 TO nb             ' each pair only once
            dx! = x(j) - x(i): dy! = y(j) - y(i)
            d! = SQR(dx! * dx! + dy! * dy!)
            IF d! < r(i) + r(j) AND d! > 0 THEN
                ' Unit normal: points from ball i to ball j.
                nx! = dx! / d!: ny! = dy! / d!
                ' Push them apart so they no longer overlap, sharing
                ' the correction by mass (light ball moves more).
                ov! = r(i) + r(j) - d!
                tm! = m(i) + m(j)
                x(i) = x(i) - nx! * ov! * m(j) / tm!: y(i) = y(i) - ny! * ov! * m(j) / tm!
                x(j) = x(j) + nx! * ov! * m(i) / tm!: y(j) = y(j) + ny! * ov! * m(i) / tm!
                ' How fast are they closing along the normal?
                vn! = (vx(i) - vx(j)) * nx! + (vy(i) - vy(j)) * ny!
                IF vn! > 0 THEN                 ' only if approaching
                    ' Elastic collision impulse along the normal.
                    imp! = 2 * vn! / tm!
                    vx(i) = vx(i) - imp! * m(j) * nx!: vy(i) = vy(i) - imp! * m(j) * ny!
                    vx(j) = vx(j) + imp! * m(i) * nx!: vy(j) = vy(j) + imp! * m(i) * ny!
                END IF
            END IF
        NEXT
    NEXT

    ' ---- draw the frame on page 1, then show it ---------------
    CLS
    LINE (0, 9)-(319, 9), 8
    e! = 0
    FOR i = 1 TO nb
        CIRCLE (x(i), y(i)), r(i), c(i)
        PAINT (x(i), y(i)), c(i), c(i)
        CIRCLE (x(i) - r(i) / 3, y(i) - r(i) / 3), r(i) / 4, 15   ' shine
        e! = e! + .5 * m(i) * (vx(i) ^ 2 + vy(i) ^ 2)       ' kinetic energy
    NEXT
    LOCATE 1, 1
    PRINT USING "Balls:## Energy:####### G:"; nb; e!;
    IF grav THEN PRINT "on "; ELSE PRINT "off";
    PCOPY 1, 0
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "G": grav = NOT grav
        CASE " "
            FOR i = 1 TO nb
                vx(i) = vx(i) + RND * 6 - 3: vy(i) = vy(i) + RND * 6 - 3
            NEXT
        CASE "+", "=": IF nb < MAXB THEN nb = nb + 1: NewBall nb
        CASE "-": IF nb > 1 THEN nb = nb - 1
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0, , 0, 0: WIDTH 80
END

SUB NewBall (i)
    ' Random size 6-20 pixels; mass grows with the area (r squared).
    r(i) = 6 + RND * 14
    m(i) = r(i) * r(i)
    x(i) = r(i) + RND * (319 - 2 * r(i))
    y(i) = 10 + r(i) + RND * (189 - 2 * r(i))
    vx(i) = RND * 4 - 2: vy(i) = RND * 4 - 2
    c(i) = 9 + INT(RND * 6)            ' bright colors 9-14
END SUB
