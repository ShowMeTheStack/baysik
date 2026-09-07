' ============================================================
' TITLE:    Fireworks
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     particles, gravity, palette, physics, arrays
' SUMMARY:  Rockets whoosh up and burst into hundreds of glowing, fading sparks pulled down by gravity.
' ------------------------------------------------------------
' WHAT IT DOES
'   A particle system: lots of tiny dots, each with its own
'   position, velocity and remaining life.  Each frame every
'   particle moves by its velocity, gravity pulls its velocity
'   down a little, and its life ticks away.  As life runs out the
'   spark's color steps down a custom palette ramp from white-hot
'   to dark, so bursts glow and fade.
'
' HOW TO USE
'   Rockets launch automatically.  Press SPACE to launch an
'   extra one.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Particle systems with a fixed "pool" of particles that
'     get reused when they die
'   * Velocity and gravity: v = v + g ; p = p + v
'   * Exploding in a circle: vx = speed * COS(angle), vy = ...SIN
'   * Building color ramps with OUT &H3C8 / &H3C9 (VGA DAC)
'
' THINGS TO TRY
'   * Change GRAV to 0 (space fireworks!) or .1 (heavy sparks)
'   * Make some bursts ring-shaped by giving all sparks the
'     same speed
' ============================================================
DEFINT A-Z
DECLARE SUB Burst (x!, y!, rmp)
DECLARE SUB Launch ()

CONST MAXP = 400              ' size of the particle pool
CONST GRAV = .04              ' gravity added to vy each frame
CONST PI = 3.14159

' Particle data.  life = 0 means "this slot is free".
DIM SHARED px(MAXP) AS SINGLE, py(MAXP) AS SINGLE
DIM SHARED vx(MAXP) AS SINGLE, vy(MAXP) AS SINGLE
DIM SHARED life(MAXP), ramp(MAXP), kind(MAXP)  ' kind 1 = rocket, 2 = spark
DIM SHARED nextSlot

SCREEN 13
RANDOMIZE TIMER

' ---- Build 4 color ramps of 16 shades each -----------------
' Ramp r uses colors 32+16*r .. 47+16*r.  Shade 15 is nearly
' white, shade 0 is almost black.  The DAC takes values 0-63.
FOR r = 0 TO 3
    READ cr, cg, cb             ' the ramp's main color
    FOR s = 0 TO 15
        OUT &H3C8, 32 + r * 16 + s           ' choose color number
        f! = s / 15
        ' Blend: dark -> main color -> white at the very top.
        w! = 0: IF s > 11 THEN w! = (s - 11) / 4
        OUT &H3C9, (cr * f! * (1 - w!) + 63 * w!)
        OUT &H3C9, (cg * f! * (1 - w!) + 63 * w!)
        OUT &H3C9, (cb * f! * (1 - w!) + 63 * w!)
    NEXT
NEXT
DATA 63,15,10,  20,63,20,  25,35,63,  63,50,10

' A little city skyline at the bottom.
FOR b = 0 TO 15
    bh = 10 + RND * 30
    LINE (b * 20, 199 - bh)-(b * 20 + 18, 199), 8, BF
    FOR wy = 199 - bh + 4 TO 195 STEP 6
        IF RND < .4 THEN PSET (b * 20 + 4 + INT(RND * 3) * 5, wy), 14
    NEXT
NEXT
COLOR 7: LOCATE 1, 1: PRINT "SPACE = launch   Esc = quit";

timer0 = 0
DO
    ' Launch a rocket every so often by itself.
    timer0 = timer0 + 1
    IF timer0 > 40 + RND * 40 THEN Launch: timer0 = 0

    ' ---- update every live particle ---------------------------
    FOR i = 1 TO MAXP
        IF life(i) > 0 THEN
            PSET (px(i), py(i)), 0            ' erase old spot
            vy(i) = vy(i) + GRAV              ' gravity
            px(i) = px(i) + vx(i)
            py(i) = py(i) + vy(i)
            life(i) = life(i) - 1
            IF kind(i) = 1 THEN
                ' A rocket explodes when it stops rising (vy >= 0).
                IF vy(i) >= 0 THEN life(i) = 0: Burst px(i), py(i), ramp(i)
            END IF
            ' Kill particles that leave the sky.
            IF px(i) < 0 OR px(i) > 319 OR py(i) > 155 OR py(i) < 9 THEN life(i) = 0
            IF life(i) > 0 THEN
                IF kind(i) = 1 THEN
                    c = 14
                ELSE
                    ' Life 0..60 -> shade 0..15 of this ramp.
                    sh = life(i) \ 4: IF sh > 15 THEN sh = 15
                    c = 32 + ramp(i) * 16 + sh
                END IF
                PSET (px(i), py(i)), c
            END IF
        END IF
    NEXT

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    k$ = INKEY$
    IF k$ = " " THEN Launch
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SUB Burst (x!, y!, rmp)
    ' Turn one point into 60 sparks flying out in all directions.
    SOUND 60 + RND * 40, 1
    FOR n = 1 TO 60
        i = nextSlot MOD MAXP + 1: nextSlot = i     ' reuse slots round-robin
        a! = RND * 2 * PI                           ' random direction
        s! = .5 + RND * 1.8                         ' random speed
        px(i) = x!: py(i) = y!
        vx(i) = s! * COS(a!): vy(i) = s! * SIN(a!)
        life(i) = 40 + RND * 25
        ramp(i) = rmp: kind(i) = 2
    NEXT
END SUB

SUB Launch
    ' A rocket is just a particle that flies up fast.
    i = nextSlot MOD MAXP + 1: nextSlot = i
    px(i) = 40 + RND * 240: py(i) = 155
    vx(i) = RND * 1 - .5
    vy(i) = -2.6 - RND * .6         ' negative = upwards
    life(i) = 200
    kind(i) = 1: ramp(i) = INT(RND * 4)
END SUB
