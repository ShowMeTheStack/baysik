' ============================================================
' TITLE:    Vibrating String and Harmonics
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     sound, waves, harmonics, music, physics, SOUND
' SUMMARY:  See and hear the standing waves of a guitar string - pick a harmonic or pluck it and watch them mix.
' ------------------------------------------------------------
' WHAT IT DOES
'   A guitar string is tied down at both ends, so it can only wiggle
'   in shapes that fit exactly: half a wave, a whole wave, one and a
'   half waves...  These are STANDING WAVES or HARMONICS.  Harmonic n
'   vibrates n times faster than the first (the "fundamental"):
'        f(n) = n * f(1)         f(1) = SQR(Tension / density) / (2 * Length)
'   Points that never move are NODES; points that move most are
'   ANTINODES.  A real pluck is a MIX of many harmonics at once - the
'   mix is what makes a guitar sound different from a flute.
'
' HOW TO USE
'   1-8    show a single harmonic (and hear its pitch)
'   P      pluck the string near one end (mix of harmonics)
'   M      pluck in the middle (only odd harmonics!)
'   T / t  tighten / loosen the string (higher / lower pitch)
'   ESC    quit
'
' CONCEPTS YOU WILL LEARN
'   * Standing waves: y = A * SIN(n*pi*x/L) * COS(2*pi*f*t)
'   * Fourier series: any shape is a sum of sine waves
'   * Frequency, pitch and the SOUND statement
'   * Why tension and length change the note
'
' THINGS TO TRY
'   * Pluck in the middle: the even harmonics vanish.  Why?
'     (They all have a NODE in the middle!)
'   * Double the tension: does the pitch double?  (No - SQR(2) times.)
'   * Play a melody using harmonics 4, 5, 6 (a major chord!)
' ============================================================

DEFSNG A-Z
DEFINT I-N
CONST PI = 3.141593
CONST NPTS = 64                 ' points along the string
CONST NH = 8                    ' harmonics we keep track of
CONST X0 = 40, X1 = 600, YC = 220   ' string ends and rest line on screen

DIM amp(NH)                     ' amplitude of each harmonic (pixels)
DIM oldY(NPTS)                  ' last drawn shape, used to erase it
DIM shapeTab(NH, NPTS)          ' SIN(n*pi*x/L) pre-computed

FOR h = 1 TO NH
    FOR p = 0 TO NPTS
        shapeTab(h, p) = SIN(h * PI * p / NPTS)
    NEXT
NEXT

tension = 100                   ' newtons
dens = .001                       ' mass per metre of the string (kg/m)
strLen = .65                     ' a guitar string is about 65 cm long
amp(1) = 80
tm = 0

SCREEN 12
GOSUB Labels
FOR p = 0 TO NPTS: oldY(p) = YC: NEXT
DO
    k$ = INKEY$
    IF k$ >= "1" AND k$ <= "8" THEN
        FOR h = 1 TO NH: amp(h) = 0: NEXT
        amp(VAL(k$)) = 80
        f1 = SQR(tension / dens) / (2 * strLen)
        SOUND f1 * VAL(k$), 4
        GOSUB Labels
    END IF
    SELECT CASE k$
        CASE "P": pluckAt = .2: GOSUB Pluck
        CASE "p": pluckAt = .2: GOSUB Pluck
        CASE "M", "m": pluckAt = .5: GOSUB Pluck
        CASE "T": tension = tension * 1.25: IF tension > 400 THEN tension = 400
            GOSUB Labels
        CASE "t": tension = tension / 1.25: IF tension < 20 THEN tension = 20
            GOSUB Labels
        CASE CHR$(27): EXIT DO
    END SELECT

    ' ---- compute and draw the string shape ----------------------------
    ' Real strings vibrate hundreds of times a second - far too fast to
    ' see - so we run time in slow motion: harmonic h turns h times
    ' faster than harmonic 1, which is what really matters.
    tm = tm + .05
    ' 1) erase the old shape by drawing it again in black
    FOR p = 1 TO NPTS
        px = X0 + (X1 - X0) * p / NPTS
        LINE (px - (X1 - X0) / NPTS, oldY(p - 1))-(px, oldY(p)), 0
    NEXT
    ' 2) work out the new shape: add up all the harmonics
    FOR p = 0 TO NPTS
        y = 0
        FOR h = 1 TO NH
            IF amp(h) <> 0 THEN y = y + amp(h) * shapeTab(h, p) * COS(h * tm)
        NEXT
        oldY(p) = YC - y
    NEXT
    ' 3) draw it
    LINE (X0, YC)-(X1, YC), 8                          ' rest line
    FOR p = 1 TO NPTS
        px = X0 + (X1 - X0) * p / NPTS
        LINE (px - (X1 - X0) / NPTS, oldY(p - 1))-(px, oldY(p)), 14   ' draw new
    NEXT
    CIRCLE (X0, YC), 4, 15: CIRCLE (X1, YC), 4, 15      ' fixed ends
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' Pluck: pull the string into a triangle at position pluckAt (0..1)
' and let go.  The Fourier series of that triangle gives the
' amplitude of each harmonic:
'    A(n) = 2*h / (n^2 * pi^2 * pos * (1-pos)) * SIN(n*pi*pos)
' ------------------------------------------------------------
Pluck:
    FOR h = 1 TO NH
        amp(h) = 2 * 90 / (h * h * PI * PI * pluckAt * (1 - pluckAt)) * SIN(h * PI * pluckAt)
        IF ABS(amp(h)) < .5 THEN amp(h) = 0     ' too small to matter
    NEXT
    tm = 0
    f1 = SQR(tension / dens) / (2 * strLen)
    SOUND f1, 3: SOUND f1 * 2, 1               ' a short twang
    GOSUB Labels
RETURN

' ------------------------------------------------------------
' Labels: a bar chart of the harmonic mix and the frequencies
' ------------------------------------------------------------
Labels:
    f1 = SQR(tension / dens) / (2 * strLen)
    LINE (0, 330)-(639, 479), 0, BF
    LOCATE 1, 1: COLOR 15
    PRINT USING "Tension ###.# N   fundamental f1 = ####.# Hz      "; tension; f1
    COLOR 7
    PRINT "1-8 harmonic   P pluck near end   M pluck middle   T/t tension   ESC"
    LOCATE 22, 2: COLOR 15: PRINT "Harmonic mix (bar = amplitude):"
    FOR h = 1 TO NH
        bx = 40 + (h - 1) * 72
        bh = ABS(amp(h)) * .8
        IF bh > 0 THEN LINE (bx, 440 - bh)-(bx + 40, 440), 9 + (h MOD 6), BF
        LOCATE 29, bx \ 8 + 1: COLOR 7: PRINT USING "n=#"; h;
        LOCATE 30, bx \ 8 + 1: PRINT USING "####Hz"; f1 * h;
    NEXT
RETURN
