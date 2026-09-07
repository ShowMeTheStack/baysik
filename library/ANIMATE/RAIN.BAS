' ============================================================
' TITLE:    Rain and Snow
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     weather, particles, wind, accumulation, animation
' SUMMARY:  Switch between slanting rain with splashes and drifting snow that slowly piles up on the ground.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two weather effects built from the same idea - many small
'   particles falling down the screen:
'     RAIN  - fast streaks drawn with LINE, slanted by the wind,
'             making a tiny splash where they hit the ground.
'     SNOW  - slow flakes that sway side to side (using SIN)
'             and STICK where they land, so snow drifts grow.
'   A height-map array remembers how deep the snow is in every
'   column of the screen.
'
' HOW TO USE
'   R = rain    S = snow    Left/Right arrows = wind
'   C = clear the snow      Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Recycling particles: when one lands, restart it at the top
'   * Wind as a sideways velocity added to every particle
'   * Swaying motion with SIN(phase)
'   * A height map: ground(x) = the top of the snow at column x
'
' THINGS TO TRY
'   * Raise N for a blizzard
'   * Add a house or tree for snow to land on (draw it and set
'     ground() lower under its roof)
' ============================================================
DEFINT A-Z
DECLARE SUB DrawLandscape ()

CONST N = 150
CONST BASEY = 185                 ' y of the bare ground

DIM x(N) AS SINGLE, y(N) AS SINGLE, sp(N) AS SINGLE, ph(N) AS SINGLE
DIM splash(N)                     ' x of a splash still on screen, or -1
DIM SHARED ground(319)            ' top of the ground at each x

SCREEN 13
RANDOMIZE TIMER
mode$ = "R": wind! = .6
DrawLandscape
FOR i = 1 TO N
    x(i) = RND * 320: y(i) = 14 + RND * 166: splash(i) = -1
    sp(i) = 2 + RND * 2: ph(i) = RND * 6.28
NEXT

DO
    FOR i = 1 TO N
        IF mode$ = "R" THEN
            ' ---- RAIN: a short slanted line --------------------
            ' Erase the old streak, move, draw the new streak.
            LINE (x(i), y(i))-(x(i) - wind! * 2, y(i) - 6), 0
            ' Remove last frame's splash (if this drop made one).
            IF splash(i) >= 0 THEN
                PSET (splash(i) - 2, BASEY - 2), 0: PSET (splash(i) + 2, BASEY - 2), 0
                splash(i) = -1
            END IF
            y(i) = y(i) + sp(i) * 2.5
            x(i) = x(i) + wind!
            IF y(i) >= BASEY - 1 THEN
                ' Splash: two tiny droplets, then restart at the top.
                ' It stays for one frame and is erased next time.
                PSET (x(i) - 2, BASEY - 2), 11: PSET (x(i) + 2, BASEY - 2), 11
                splash(i) = x(i)
                y(i) = 14 + RND * 10: x(i) = RND * 360 - 20
            ELSE
                LINE (x(i), y(i))-(x(i) - wind! * 2, y(i) - 6), 9
            END IF
        ELSE
            ' ---- SNOW: a swaying dot ---------------------------
            ' Erase the flake - but only if it is above the drift,
            ' or we would dig holes in the snow!
            IF y(i) < ground(INT(x(i))) THEN PSET (x(i), y(i)), 0
            ph(i) = ph(i) + .1
            y(i) = y(i) + sp(i) * .35
            x(i) = x(i) + wind! * .5 + SIN(ph(i)) * .5
            IF x(i) < 0 THEN x(i) = x(i) + 319
            IF x(i) > 319 THEN x(i) = x(i) - 319
            gx = INT(x(i))
            IF y(i) >= ground(gx) - 1 THEN
                ' Landed!  Paint the flake into the drift and raise
                ' the snow level of that column by one pixel.
                IF ground(gx) > 40 THEN
                    ground(gx) = ground(gx) - 1
                    PSET (gx, ground(gx)), 15
                END IF
                y(i) = 8: x(i) = RND * 319
            ELSE
                PSET (x(i), y(i)), 15
            END IF
        END IF
    NEXT

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "R", "S"
            IF k$ <> mode$ THEN
                mode$ = k$
                ' Rain washes away the snow, so start a fresh scene.
                DrawLandscape
                FOR i = 1 TO N
                    x(i) = RND * 319: y(i) = 14 + RND * 166: splash(i) = -1
                NEXT
            END IF
        CASE "C": DrawLandscape
        CASE CHR$(0) + "K": IF wind! > -3 THEN wind! = wind! - .3
        CASE CHR$(0) + "M": IF wind! < 3 THEN wind! = wind! + .3
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SUB DrawLandscape
    CLS
    LINE (0, BASEY)-(319, 199), 2, BF          ' green field
    FOR gx = 0 TO 319: ground(gx) = BASEY: NEXT
    COLOR 7: LOCATE 1, 1
    PRINT "R rain S snow <-> wind C clear Esc";
END SUB
