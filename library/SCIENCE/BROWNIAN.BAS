' ============================================================
' TITLE:    Brownian Motion
' CATEGORY: Science & Simulation
' LEVEL:    Advanced
' TAGS:     physics, molecules, collisions, momentum, statistics
' SUMMARY:  A heavy grain jiggles randomly as invisible molecules smash into it - the clue that proved atoms exist.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1827 Robert Brown saw pollen grains in water jiggling for no
'   visible reason.  In 1905 Einstein explained it: the grain is
'   being hit from all sides by water molecules, too small to see.
'   By chance, a few more hit one side than the other, so the grain
'   is nudged around in a random zig-zag.
'   Here, 300 small fast "molecules" (grey) bounce around a box.
'   One big slow "grain" (yellow) gets bumped by them.  Its path is
'   drawn in red.  Press M to hide the molecules and see only what
'   Brown could see through his microscope.
'
' HOW TO USE
'   M  show/hide molecules     T  clear the trail
'   +  hotter (faster molecules)  -  colder
'   ESC quit
'
' CONCEPTS YOU WILL LEARN
'   * Elastic collisions: momentum and energy are conserved
'   * Vectors: normals, dot products and impulses
'   * Temperature = average speed of molecules
'   * How randomness at small scale shows up at large scale
'
' THINGS TO TRY
'   * Heat the gas: the grain jiggles harder.
'   * Make the grain heavier (BIGM) - it moves less.  Why?
'   * Track the grain's distance from the centre over time.
' ============================================================

DEFSNG A-Z
DEFINT I-N
CONST NM = 300                  ' number of molecules
CONST BIGR = 18, SMALLR = 1     ' radii in pixels
CONST BIGM = 30, SMALLM = 1     ' masses
CONST X0 = 20, Y0 = 30, X1 = 620, Y1 = 460   ' the box

DIM px(NM), py(NM), vx(NM), vy(NM)

RANDOMIZE TIMER
speed = 3                       ' typical molecule speed (pixels/frame)
showMol = 1
GOSUB Init

SCREEN 12
GOSUB Frame
DO
    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE CHR$(27): EXIT DO
        CASE "M": showMol = 1 - showMol: GOSUB Frame
        CASE "T": GOSUB Frame
        CASE "+", "="
            ' heating: every molecule speeds up by 20%
            FOR i = 1 TO NM: vx(i) = vx(i) * 1.2: vy(i) = vy(i) * 1.2: NEXT
            speed = speed * 1.2
        CASE "-"
            FOR i = 1 TO NM: vx(i) = vx(i) / 1.2: vy(i) = vy(i) / 1.2: NEXT
            speed = speed / 1.2
    END SELECT

    ' ---- erase the old picture ----------------------------------
    IF showMol THEN
        FOR i = 1 TO NM: PSET (px(i), py(i)), 0: NEXT
    END IF
    CIRCLE (bx, by), BIGR, 0

    ' ---- move the molecules and check collisions -----------------
    FOR i = 1 TO NM
        px(i) = px(i) + vx(i): py(i) = py(i) + vy(i)
        ' bounce off the walls
        IF px(i) < X0 + 1 THEN px(i) = X0 + 1: vx(i) = ABS(vx(i))
        IF px(i) > X1 - 1 THEN px(i) = X1 - 1: vx(i) = -ABS(vx(i))
        IF py(i) < Y0 + 1 THEN py(i) = Y0 + 1: vy(i) = ABS(vy(i))
        IF py(i) > Y1 - 1 THEN py(i) = Y1 - 1: vy(i) = -ABS(vy(i))

        ' ---- collision with the big grain -------------------------
        dx = px(i) - bx: dy = py(i) - by
        d2 = dx * dx + dy * dy
        IF d2 < (BIGR + SMALLR) ^ 2 AND d2 > 0 THEN
            d = SQR(d2)
            ux = dx / d: uy = dy / d          ' unit vector from grain to molecule
            ' relative speed along that line (dot product)
            vrel = (vx(i) - bvx) * ux + (vy(i) - bvy) * uy
            IF vrel < 0 THEN                  ' only if they are approaching
                ' Impulse for a perfectly elastic collision:
                '   j = 2 * vrel * m1 * m2 / (m1 + m2)
                j! = 2 * vrel * SMALLM * BIGM / (SMALLM + BIGM)
                vx(i) = vx(i) - j! / SMALLM * ux
                vy(i) = vy(i) - j! / SMALLM * uy
                bvx = bvx + j! / BIGM * ux
                bvy = bvy + j! / BIGM * uy
                hits& = hits& + 1
            END IF
        END IF
        IF showMol THEN PSET (px(i), py(i)), 7
    NEXT

    ' ---- move the grain --------------------------------------------
    ox = bx: oy = by
    bx = bx + bvx: by = by + bvy
    IF bx < X0 + BIGR THEN bx = X0 + BIGR: bvx = ABS(bvx)
    IF bx > X1 - BIGR THEN bx = X1 - BIGR: bvx = -ABS(bvx)
    IF by < Y0 + BIGR THEN by = Y0 + BIGR: bvy = ABS(bvy)
    IF by > Y1 - BIGR THEN by = Y1 - BIGR: bvy = -ABS(bvy)
    LINE (ox, oy)-(bx, by), 12         ' the trail
    CIRCLE (bx, by), BIGR, 14
    LINE (X0, Y0)-(X1, Y1), 8, B

    LOCATE 1, 2: COLOR 15
    PRINT USING "Hits: ####### grain speed #.##  gas speed ##.#   M T + - ESC"; hits&; SQR(bvx * bvx + bvy * bvy); speed;
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' Init: grain still in the middle; molecules scattered with
' random directions but the same speed.
' ------------------------------------------------------------
Init:
    bx = (X0 + X1) / 2: by = (Y0 + Y1) / 2: bvx = 0: bvy = 0
    FOR i = 1 TO NM
        DO
            px(i) = X0 + 2 + RND * (X1 - X0 - 4)
            py(i) = Y0 + 2 + RND * (Y1 - Y0 - 4)
        LOOP WHILE (px(i) - bx) ^ 2 + (py(i) - by) ^ 2 < (BIGR + 3) ^ 2
        a = RND * 6.2832
        vx(i) = speed * COS(a): vy(i) = speed * SIN(a)
    NEXT
RETURN

' Frame: clear the box (and the trail) and redraw the border
Frame:
    LINE (X0 + 1, Y0 + 1)-(X1 - 1, Y1 - 1), 0, BF
    LINE (X0, Y0)-(X1, Y1), 8, B
RETURN
