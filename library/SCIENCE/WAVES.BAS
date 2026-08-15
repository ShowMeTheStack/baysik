' ============================================================
' TITLE:    Wave Interference (Two Sources)
' CATEGORY: Science & Simulation
' LEVEL:    Advanced
' TAGS:     waves, interference, physics, palette animation, trigonometry
' SUMMARY:  Two ripple sources overlap to make bright and dark bands - animated with a palette-cycling trick.
' ------------------------------------------------------------
' WHAT IT DOES
'   Drop two pebbles in a pond and the ripples cross.  Where a crest
'   meets a crest the water rises twice as high (CONSTRUCTIVE
'   interference).  Where a crest meets a trough they cancel and the
'   water stays flat (DESTRUCTIVE interference).  The flat lines fan
'   out from between the sources - these "nodal lines" are what
'   Thomas Young saw with light in 1801, proving light is a wave.
'
'   The maths: the wave from source 1 at distance r1 is COS(k*r1 - w*t).
'   Adding the two waves with a trig identity gives
'       2 * COS(k*(r1-r2)/2) * COS(k*(r1+r2)/2 - w*t)
'        \_____ how big ____/   \_____ wiggles in time ___/
'
' THE TRICK
'   Drawing 64,000 pixels every frame is too slow.  Instead each
'   pixel is drawn ONCE with a colour number that encodes its
'   amplitude (4 levels) and its phase (60 steps).  Then only the
'   256-colour PALETTE is changed every frame, and the whole picture
'   ripples for free!
'
' HOW TO USE
'   W / w   longer / shorter wavelength     S / s   sources further / closer
'   ESC     quit.  (The picture takes a moment to redraw after a change.)
'
' CONCEPTS YOU WILL LEARN
'   * Superposition of waves; path difference r1 - r2
'   * Nodal lines where the path difference is half a wavelength
'   * VGA palette programming with OUT &H3C8 / &H3C9
'   * Encoding two numbers into one (index = 16 + a*60 + p)
'
' THINGS TO TRY
'   * Count the nodal lines and check: about 2 * separation / wavelength.
'   * Add a third source.
'   * Make the waves fade with distance: multiply by 1 / SQR(r).
' ============================================================

DEFSNG A-Z
DEFINT I-N
CONST PI = 3.141593
CONST NP = 60                   ' phase steps in one cycle

DIM ctab(NP - 1)                ' a pre-computed cosine table
FOR i = 0 TO NP - 1
    ctab(i) = (1 + COS(2 * PI * i / NP)) / 2   ' 0..1, a smooth wave
NEXT
DIM bright(3)                      ' brightness for the 4 amplitude levels
bright(0) = .05: bright(1) = .35: bright(2) = .7: bright(3) = 1

wl = 14                         ' wavelength in pixels
sep = 40                        ' distance between the two sources

SCREEN 13
GOSUB DrawField
shift = 0
DO
    k$ = INKEY$
    redraw = 1
    SELECT CASE k$
        CASE "W": wl = wl + 2: IF wl > 40 THEN wl = 40
        CASE "w": wl = wl - 2: IF wl < 6 THEN wl = 6
        CASE "S": sep = sep + 10: IF sep > 200 THEN sep = 200
        CASE "s": sep = sep - 10: IF sep < 10 THEN sep = 10
        CASE CHR$(27): EXIT DO
        CASE ELSE: redraw = 0
    END SELECT
    IF redraw THEN GOSUB DrawField

    ' ---- the palette animation -------------------------------------
    ' Colour (16 + a*60 + p) shows brightness bright(a) times the wave
    ' value at phase p, shifted by the current time step.
    OUT &H3C8, 16                    ' start writing at colour 16
    FOR a = 0 TO 3
        FOR p = 0 TO NP - 1
            v = 63 * bright(a) * ctab((p + shift) MOD NP)
            OUT &H3C9, INT(v * .3)   ' red
            OUT &H3C9, INT(v * .7)   ' green
            OUT &H3C9, INT(v)        ' blue
        NEXT
    NEXT
    shift = (shift + NP - 2) MOD NP  ' move the phase backward = waves move outward
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' DrawField: compute amplitude & phase for every 2x2 block.
' ------------------------------------------------------------
DrawField:
    wk = 2 * PI / wl                 ' wave number: radians per pixel
    s1x = 160 - sep / 2: s2x = 160 + sep / 2: sy = 60
    FOR y = 0 TO 189 STEP 2
        dy2 = (y - sy) ^ 2
        FOR x = 0 TO 319 STEP 2
            r1 = SQR((x - s1x) ^ 2 + dy2)
            r2 = SQR((x - s2x) ^ 2 + dy2)
            amp = COS(wk * (r1 - r2) / 2)    ' -1..1, how big the wiggle is here
            ph = wk * (r1 + r2) / 2          ' where in its cycle this point is
            IF amp < 0 THEN amp = -amp: ph = ph + PI   ' negative amp = half a cycle later
            a = INT(amp * 3.999)
            p = INT(ph / (2 * PI) * NP) MOD NP
            LINE (x, y)-(x + 1, y + 1), 16 + a * NP + p, BF
        NEXT
    NEXT
    ' mark the sources and show the settings
    CIRCLE (s1x, sy), 2, 14: CIRCLE (s2x, sy), 2, 14
    LOCATE 25, 1: COLOR 15
    PRINT USING "wavelength ## sep ### W/w S/s ESC"; wl; sep;
RETURN
