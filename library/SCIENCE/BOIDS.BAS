' ============================================================
' TITLE:    Boids Flocking
' CATEGORY: Science & Simulation
' LEVEL:    Advanced
' TAGS:     flocking, emergence, vectors, artificial life, animation
' SUMMARY:  Craig Reynolds' three simple rules turn random dots into a swirling flock of birds.
' ------------------------------------------------------------
' WHAT IT DOES
'   How does a flock of starlings move as one, with no leader?  In
'   1986 Craig Reynolds showed that each "boid" (bird-oid) only needs
'   to look at its nearby neighbours and follow three rules:
'     1. SEPARATION - don't crowd: steer away from boids too close
'     2. ALIGNMENT  - steer toward the average heading of neighbours
'     3. COHESION   - steer toward the average position of neighbours
'   Add a speed limit and wrap-around edges, and flocking appears.
'   Switch the rules on and off to see what each one does.
'
' HOW TO USE
'   1  toggle separation    2  toggle alignment    3  toggle cohesion
'   P  toggle a predator (a red hawk the boids flee from)
'   ESC quit
'
' CONCEPTS YOU WILL LEARN
'   * Vectors: position, velocity, adding and scaling steering forces
'   * Neighbourhoods and averages
'   * Emergent behaviour from local rules
'   * Wrap-around ("toroidal") space
'
' THINGS TO TRY
'   * Cohesion only: boids clump into tight balls.
'   * Alignment only: boids line up into streams.
'   * Change VIEWR (how far a boid can see) - small values make many
'     little flocks, large values one big flock.
' ============================================================

DEFSNG A-Z
DEFINT I-N
CONST NB = 40                   ' number of boids
CONST VIEWR = 60                ' how far a boid can see (pixels)
CONST SEPR = 18                 ' "personal space" radius
CONST MAXV = 3.5, MINV = 1.5    ' speed limits
CONST W = 640, H = 480

DIM bx(NB), by(NB), bvx(NB), bvy(NB)
DIM ox1(NB), oy1(NB), ox2(NB), oy2(NB)     ' last drawn line, for erasing

RANDOMIZE TIMER
FOR i = 1 TO NB
    bx(i) = RND * W: by(i) = RND * H
    a = RND * 6.2832
    bvx(i) = COS(a) * 2: bvy(i) = SIN(a) * 2
NEXT
useSep = 1: useAli = 1: useCoh = 1
hawk = 0: hx = W / 2: hy = H / 2: hvx = 2.5: hvy = 1.7

SCREEN 12
DO
    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "1": useSep = 1 - useSep
        CASE "2": useAli = 1 - useAli
        CASE "3": useCoh = 1 - useCoh
        CASE "P": hawk = 1 - hawk: CIRCLE (hx, hy), 6, 0
        CASE CHR$(27): EXIT DO
    END SELECT

    ' ---- steering for every boid --------------------------------------
    FOR i = 1 TO NB
        sepX = 0: sepY = 0          ' push away from crowding
        aliX = 0: aliY = 0          ' sum of neighbour velocities
        cohX = 0: cohY = 0          ' sum of neighbour positions
        cnt = 0
        FOR j = 1 TO NB
            IF j <> i THEN
                dx = bx(j) - bx(i): dy = by(j) - by(i)
                ' shortest way round the wrap-around world
                IF dx > W / 2 THEN dx = dx - W
                IF dx < -W / 2 THEN dx = dx + W
                IF dy > H / 2 THEN dy = dy - H
                IF dy < -H / 2 THEN dy = dy + H
                d2 = dx * dx + dy * dy
                IF d2 < VIEWR * VIEWR THEN
                    cnt = cnt + 1
                    aliX = aliX + bvx(j): aliY = aliY + bvy(j)
                    cohX = cohX + dx: cohY = cohY + dy   ' relative position
                    IF d2 < SEPR * SEPR AND d2 > 0 THEN
                        ' closer = stronger push (divide by distance squared)
                        sepX = sepX - dx / d2: sepY = sepY - dy / d2
                    END IF
                END IF
            END IF
        NEXT
        IF cnt > 0 THEN
            ' each rule nudges the velocity a little; the weights set
            ' how strongly each rule matters
            IF useAli THEN
                bvx(i) = bvx(i) + (aliX / cnt - bvx(i)) * .05
                bvy(i) = bvy(i) + (aliY / cnt - bvy(i)) * .05
            END IF
            IF useCoh THEN
                bvx(i) = bvx(i) + cohX / cnt * .005
                bvy(i) = bvy(i) + cohY / cnt * .005
            END IF
        END IF
        IF useSep THEN
            bvx(i) = bvx(i) + sepX * 6: bvy(i) = bvy(i) + sepY * 6
        END IF
        ' flee from the hawk if it is close
        IF hawk THEN
            dx = bx(i) - hx: dy = by(i) - hy
            d2 = dx * dx + dy * dy
            IF d2 < 100 * 100 AND d2 > 0 THEN
                bvx(i) = bvx(i) + dx / SQR(d2) * .6
                bvy(i) = bvy(i) + dy / SQR(d2) * .6
            END IF
        END IF
        ' ---- speed limits -----------------------------------------
        sp = SQR(bvx(i) * bvx(i) + bvy(i) * bvy(i))
        IF sp > MAXV THEN bvx(i) = bvx(i) * MAXV / sp: bvy(i) = bvy(i) * MAXV / sp
        IF sp < MINV AND sp > 0 THEN bvx(i) = bvx(i) * MINV / sp: bvy(i) = bvy(i) * MINV / sp
    NEXT

    ' ---- move and draw (after ALL steering, so everyone reacts to
    '      the same moment - otherwise early boids would get an edge)
    FOR i = 1 TO NB
        LINE (ox1(i), oy1(i))-(ox2(i), oy2(i)), 0          ' erase
        bx(i) = bx(i) + bvx(i): by(i) = by(i) + bvy(i)
        IF bx(i) < 0 THEN bx(i) = bx(i) + W
        IF bx(i) >= W THEN bx(i) = bx(i) - W
        IF by(i) < 0 THEN by(i) = by(i) + H
        IF by(i) >= H THEN by(i) = by(i) - H
        ' draw a short line pointing the way the boid flies
        sp = SQR(bvx(i) * bvx(i) + bvy(i) * bvy(i))
        ox1(i) = bx(i): oy1(i) = by(i)
        ox2(i) = bx(i) - bvx(i) / sp * 7: oy2(i) = by(i) - bvy(i) / sp * 7
        LINE (ox1(i), oy1(i))-(ox2(i), oy2(i)), 11
        PSET (ox1(i), oy1(i)), 15                          ' the head
    NEXT

    ' ---- the hawk bounces around the screen ---------------------------
    IF hawk THEN
        CIRCLE (hx, hy), 6, 0
        hx = hx + hvx: hy = hy + hvy
        IF hx < 10 OR hx > W - 10 THEN hvx = -hvx
        IF hy < 30 OR hy > H - 10 THEN hvy = -hvy
        CIRCLE (hx, hy), 6, 12
    END IF

    LOCATE 1, 1: COLOR 7
    PRINT "1 Separation:"; MID$("offon ", useSep * 3 + 1, 3);
    PRINT "  2 Alignment:"; MID$("offon ", useAli * 3 + 1, 3);
    PRINT "  3 Cohesion:"; MID$("offon ", useCoh * 3 + 1, 3);
    PRINT "  P hawk  ESC quit";
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END
