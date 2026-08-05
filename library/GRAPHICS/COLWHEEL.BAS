' ============================================================
' TITLE:    VGA Colour Wheel
' CATEGORY: Graphics
' LEVEL:    Advanced
' TAGS:     palette, out, dac, hsv, colour wheel, atn, screen 13
' SUMMARY:  Programs 240 custom VGA colours with OUT &H3C8/&H3C9 to paint a hue-and-saturation colour wheel, then spins it.
' ------------------------------------------------------------
' WHAT IT DOES
'   The VGA card holds 256 colours in a "DAC" table. Each entry
'   has red, green and blue levels from 0 to 63. We write our own
'   values straight to the hardware: 40 hues around the circle,
'   times 6 saturation rings from grey in the middle to vivid
'   colour at the edge. Then every pixel inside the disc is set
'   to the right entry using its angle and distance from the
'   centre. Finally, rotating the palette makes the wheel spin
'   without redrawing.
'
' HOW TO USE
'   Wait a few seconds while the wheel is drawn, then watch it
'   spin. Press any key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * OUT &H3C8, index then three OUT &H3C9 writes (R, G, B)
'   * HSV -> RGB conversion (hue = angle around the wheel)
'   * ATN and quadrants: finding the angle of a point
'   * Packing two numbers (ring, hue) into one colour index
'
' THINGS TO TRY
'   * Use 8 rings of 30 hues instead
'   * Make the centre white instead of grey
'   * Draw a square "colour picker" with hue across, saturation down
' ============================================================

DECLARE SUB SetHue (index%, hue!, sat!)
CONST PI = 3.14159265#
CONST HUES = 40
CONST RINGS = 6

SCREEN 13
CLS

' ---- Build the palette ---------------------------------------------
' Colour index = 16 + ring * HUES + hue   (16..255)
' We start at 16 so the first 16 standard colours stay usable
' for the text.
FOR ring% = 0 TO RINGS - 1
    FOR h% = 0 TO HUES - 1
        SetHue 16 + ring% * HUES + h%, h% / HUES, (ring% + 1) / RINGS
    NEXT h%
NEXT ring%

' ---- Paint the wheel pixel by pixel ---------------------------------
' SCREEN 13 pixels are about 1.2 times taller than wide, so we
' stretch y by 1.2 to keep the wheel round.
cx = 160: cy = 100: rad = 90       ' centre and radius
LOCATE 1, 1: PRINT "Painting..."
FOR y = -rad / 1.2 TO rad / 1.2
    yy = y * 1.2
    FOR x = -rad TO rad
        d = SQR(x * x + yy * yy)
        IF d <= rad THEN
            ' The angle of (x, -yy). ATN only covers -90..90 degrees,
            ' so we fix up the left half by adding PI.
            IF x = 0 THEN
                IF yy < 0 THEN a = PI / 2 ELSE a = -PI / 2
            ELSE
                a = ATN(-yy / x)
                IF x < 0 THEN a = a + PI
            END IF
            IF a < 0 THEN a = a + 2 * PI
            h% = INT(a / (2 * PI) * HUES) MOD HUES
            ring% = INT(d / rad * RINGS): IF ring% >= RINGS THEN ring% = RINGS - 1
            PSET (cx + x, cy + y), 16 + ring% * HUES + h%
        END IF
    NEXT x
NEXT y
LOCATE 1, 1: PRINT "Spinning! Any key quits"

' ---- Spin by rotating each ring's hues ------------------------------
offset = 0
DO
    offset = (offset + 1) MOD HUES
    FOR ring% = 0 TO RINGS - 1
        FOR h% = 0 TO HUES - 1
            SetHue 16 + ring% * HUES + h%, ((h% + offset) MOD HUES) / HUES, (ring% + 1) / RINGS
        NEXT h%
    NEXT ring%
    t! = TIMER: DO: LOOP WHILE TIMER - t! < .04 AND TIMER >= t!
LOOP WHILE INKEY$ = ""

SCREEN 0: WIDTH 80
END

' ---- Write one DAC entry from hue (0..1) and saturation (0..1) ------
' HSV to RGB with V (brightness) fixed at full. The hue circle
' is split into 6 sectors: red->yellow->green->cyan->blue->magenta.
SUB SetHue (index%, hue!, sat!)
    h6! = hue! * 6
    sector% = INT(h6!) MOD 6
    f! = h6! - INT(h6!)                 ' how far through the sector
    p! = 1 - sat!                       ' the "grey" part
    q! = 1 - sat! * f!                  ' falling edge
    t! = 1 - sat! * (1 - f!)            ' rising edge
    SELECT CASE sector%
        CASE 0: r! = 1: g! = t!: b! = p!
        CASE 1: r! = q!: g! = 1: b! = p!
        CASE 2: r! = p!: g! = 1: b! = t!
        CASE 3: r! = p!: g! = q!: b! = 1
        CASE 4: r! = t!: g! = p!: b! = 1
        CASE ELSE: r! = 1: g! = p!: b! = q!
    END SELECT
    ' Tell the DAC which entry we are about to write, then send
    ' red, green and blue (each 0..63).
    OUT &H3C8, index%
    OUT &H3C9, INT(r! * 63)
    OUT &H3C9, INT(g! * 63)
    OUT &H3C9, INT(b! * 63)
END SUB
