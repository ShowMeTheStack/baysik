' ============================================================
' TITLE:    Spring-Mass Oscillator
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     physics, hooke's law, oscillation, damping, graph
' SUMMARY:  A weight bounces on a spring while a live graph traces its position over time.
' ------------------------------------------------------------
' WHAT IT DOES
'   A mass hangs on a spring.  Hooke's Law says the spring pulls
'   back with a force proportional to how far it is stretched:
'        F = -k * x
'   Add friction ("damping") and the bounces slowly die away.
'   The left side shows the moving spring; the right side draws a
'   graph of position against time - a SINE WAVE that shrinks when
'   damping is switched on.
'
' HOW TO USE
'   K / k   stiffer / softer spring       M / m   heavier / lighter mass
'   D / d   more / less damping           SPACE   pull the mass down again
'   ESC     quit
'
' CONCEPTS YOU WILL LEARN
'   * Hooke's law and Newton's second law (a = F / m)
'   * Simple harmonic motion and its period T = 2*pi*SQR(m/k)
'   * Damping: under-damped, critically damped, over-damped
'   * Kinetic + potential energy and where it goes
'
' THINGS TO TRY
'   * Make the spring 4x stiffer: the period should halve.
'   * Find the damping where the mass returns without overshooting
'     (critical damping: c = 2*SQR(k*m)).
'   * Add a "driving force" F = A*SIN(w*t) and look for resonance.
' ============================================================

DEFDBL A-Z
CONST PI = 3.14159265358979#

k = 20                  ' spring constant (newtons per metre)
m = 1                   ' mass (kg)
c = .3                  ' damping coefficient (newton-seconds per metre)
x = 1                   ' displacement from rest (metres, + is down)
v = 0                   ' velocity (m/s)
dt = 1 / 240            ' 4 physics steps per frame
gx = 200                ' graph x position (pixels)

SCREEN 12
GOSUB DrawFrame
DO
    k$ = INKEY$
    SELECT CASE k$
        CASE "K": k = k * 1.25
        CASE "k": k = k / 1.25
        CASE "M": m = m * 1.25
        CASE "m": m = m / 1.25
        CASE "D": c = c + .2
        CASE "d": c = c - .2: IF c < 0 THEN c = 0
        CASE " ": x = 1: v = 0
        CASE CHR$(27): EXIT DO
    END SELECT
    ' Keep values in a sensible range (a huge k/m ratio would make
    ' our simple step-by-step method unstable and blow up).
    IF k > 2000 THEN k = 2000
    IF k < 1 THEN k = 1
    IF m > 50 THEN m = 50
    IF m < .05 THEN m = .05

    ' ---- physics: 4 small steps ---------------------------------
    FOR s = 1 TO 4
        f = -k * x - c * v      ' spring force + friction force
        a = f / m               ' Newton's 2nd law
        v = v + a * dt
        x = x + v * dt
    NEXT

    ' ---- draw the spring ----------------------------------------
    ' The top of the spring is fixed at y=60.  The mass rests at
    ' y=240; 1 metre of displacement = 120 pixels.
    my = 240 + x * 120
    LINE (40, 62)-(150, 460), 0, BF          ' wipe old spring
    LINE (30, 55)-(160, 60), 7, BF           ' the ceiling
    ' zig-zag coil: 16 turns from the ceiling to the mass
    py = 60: px = 95
    FOR i = 1 TO 16
        ny = 60 + (my - 80) * i / 16
        nx = 95 + 20 * ((i MOD 2) * 2 - 1)
        IF i = 16 THEN nx = 95
        LINE (px, py)-(nx, ny), 11
        px = nx: py = ny
    NEXT
    LINE (70, my - 20)-(120, my + 20), 12, BF   ' the mass block
    LINE (40, 240)-(55, 240), 8                 ' rest position mark

    ' ---- graph position against time ----------------------------
    PSET (gx, 240 + x * 120), 14
    gx = gx + 1
    IF gx > 630 THEN gx = 200: GOSUB DrawFrame

    ' ---- energy --------------------------------------------------
    ke = .5 * m * v * v         ' kinetic energy (motion)
    pe = .5 * k * x * x         ' potential energy (stored in spring)
    LOCATE 2, 27
    PRINT USING "k=###.# N/m  m=##.## kg  c=##.# Ns/m"; k; m; c
    LOCATE 3, 27
    PRINT USING "Period 2*pi*SQR(m/k) = ##.## s  Energy ###.## J"; 2 * PI * SQR(m / k); ke + pe
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' DrawFrame: clear the graph area and draw its axes and labels
' ------------------------------------------------------------
DrawFrame:
    LINE (195, 40)-(639, 479), 0, BF
    LINE (200, 240)-(630, 240), 8       ' zero line (rest position)
    LINE (200, 100)-(200, 380), 8       ' vertical axis
    LOCATE 1, 27: COLOR 15
    PRINT "Position vs time   (K/k M/m D/d SPACE ESC)"
    COLOR 7
    LOCATE 28, 27: PRINT "time -->"
RETURN
