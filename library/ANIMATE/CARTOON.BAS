' ============================================================
' TITLE:    Day and Night Cartoon
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     cartoon, scene, palette fading, sprites, day/night
' SUMMARY:  A little town lives through day and night: the sun arcs over, clouds drift, a car drives by, and the windows light up after dusk.
' ------------------------------------------------------------
' WHAT IT DOES
'   Puts several animation tricks together into one scene:
'     * The sky, grass, road and house use their OWN palette
'       colors.  To make evening fall we never redraw them - we
'       just fade those palette colors darker.
'     * Stars are drawn all day in "star color"; by day that
'       color equals the sky so they are invisible, at night it
'       turns white and they appear.
'     * The sun and moon move along an arc (SIN gives the height).
'     * Clouds drift by: erase in sky color, redraw 1 pixel over.
'     * A car sprite (GET/PUT) drives along the road.  Its box
'       has a margin of road color so it wipes its own trail.
'
' HOW TO USE
'   Just watch a day go by (about half a minute).
'   + / -  speed time up / slow it down      Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Palette animation for lighting (fade by multiplying RGB)
'   * Mixing two colors: c = night + (day - night) * light
'   * Drawing filled circles with horizontal LINEs
'   * Layering several moving objects in the right order
'
' THINGS TO TRY
'   * Add a second car driving the other way
'   * Make the house's chimney puff smoke at night
' ============================================================
DEFINT A-Z
DECLARE SUB Disc (x, y, r, c)
DECLARE SUB Cloud (x, y, c)
DECLARE SUB SetCol (n, r, g, b, light!)

CONST SKY = 200, GRASS = 201, ROAD = 202, CLOUDC = 203
CONST WALL = 204, ROOF = 205, WINDOWC = 206, STAR = 207, TREE = 208, TRUNK = 209
CONST PI = 3.14159
CONST NSTARS = 40

DIM car(300)                      ' 4 + 34*16 = 548 bytes = 274 integers
DIM stx(NSTARS), sty(NSTARS)
DIM cx!(3), cy(3)                 ' cloud positions

SCREEN 13
RANDOMIZE TIMER
light! = 1: GOSUB SetPalette

' ---- 1. Build the car sprite (on road color) -------------------
LINE (0, 0)-(33, 15), ROAD, BF
LINE (2, 6)-(31, 11), 4, BF                    ' red body
LINE (8, 2)-(24, 6), 4, BF                     ' cabin
LINE (10, 3)-(15, 6), 11, BF: LINE (17, 3)-(22, 6), 11, BF   ' windows
Disc 9, 12, 3, 0: Disc 25, 12, 3, 0            ' wheels
PSET (9, 12), 7: PSET (25, 12), 7              ' hub caps
PSET (31, 8), 14                               ' headlight
GET (0, 0)-(33, 15), car

' ---- 2. The scenery (drawn once) --------------------------------
LINE (0, 0)-(319, 139), SKY, BF
LINE (0, 140)-(319, 199), GRASS, BF
LINE (0, 162)-(319, 186), ROAD, BF
FOR x = 0 TO 319 STEP 24: LINE (x, 173)-(x + 10, 174), 15, BF: NEXT  ' lane marks
FOR i = 1 TO NSTARS
    stx(i) = RND * 319: sty(i) = RND * 78       ' stay above the roof and tree
NEXT
' House
LINE (200, 105)-(270, 150), WALL, BF
FOR i = 0 TO 20                                 ' triangular roof, row by row
    LINE (195 + i * 2, 105 - i)-(275 - i * 2, 105 - i), ROOF
NEXT
LINE (212, 115)-(228, 128), WINDOWC, BF
LINE (242, 115)-(258, 128), WINDOWC, BF
LINE (229, 130)-(241, 150), TRUNK, BF          ' door
' Tree
LINE (55, 120)-(62, 150), TRUNK, BF
Disc 58, 108, 16, TREE: Disc 48, 118, 10, TREE: Disc 68, 118, 10, TREE

FOR i = 1 TO 3: cx!(i) = i * 100 - 40: cy(i) = 18 + i * 9: NEXT
COLOR 15: LOCATE 25, 1: PRINT "+/- time speed   Esc quit";

' ---- 3. Animate -------------------------------------------------
t! = .02: dt! = .0012: carX = 0: oldX = -1: oldY = -1
DO
    ' t goes 0 -> 1 for a full day.  0-0.5 = day (sun), 0.5-1 = night (moon).
    t! = t! + dt!: IF t! >= 1 THEN t! = t! - 1
    half! = t! * 2: IF half! >= 1 THEN half! = half! - 1   ' 0..1 within day or night

    ' Brightness: rises at dawn, 1 at midday, falls at dusk, 0 at night.
    IF t! < .5 THEN light! = SIN(half! * PI) * 2.5 ELSE light! = 0
    IF light! > 1 THEN light! = 1
    GOSUB SetPalette

    ' ---- sun or moon --------------------------------------------
    IF oldY >= 0 THEN Disc oldX, oldY, 12, SKY       ' erase last one
    FOR i = 1 TO NSTARS: PSET (stx(i), sty(i)), STAR: NEXT
    bx = half! * 340 - 10                           ' left to right
    by = 112 - 95 * SIN(half! * PI)                 ' up and over
    IF t! < .5 THEN Disc bx, by, 12, 14 ELSE Disc bx, by, 10, 15: Disc bx + 5, by - 3, 8, SKY
    oldX = bx: oldY = by

    ' ---- clouds --------------------------------------------------
    FOR i = 1 TO 3
        Cloud INT(cx!(i)), cy(i), SKY                ' erase
        cx!(i) = cx!(i) + .3 * i                    ' far clouds move slower
        IF cx!(i) > 360 THEN cx!(i) = -40
        Cloud INT(cx!(i)), cy(i), CLOUDC             ' draw
    NEXT

    ' ---- car -----------------------------------------------------
    carX = carX + 2: IF carX > 319 - 34 THEN carX = 0: LINE (284, 166)-(319, 181), ROAD, BF
    PUT (carX, 166), car, PSET

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    k$ = INKEY$
    IF (k$ = "+" OR k$ = "=") AND dt! < .01 THEN dt! = dt! * 1.5
    IF k$ = "-" AND dt! > .0003 THEN dt! = dt! / 1.5
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SetPalette:
    ' Each scenery color = night color + (day color - night color) * light.
    ' SetCol does that mixing for one color.
    SetCol SKY, 20, 45, 63, light!
    SetCol GRASS, 10, 50, 10, light!
    SetCol ROAD, 30, 30, 32, light!
    SetCol CLOUDC, 63, 63, 63, light!
    SetCol WALL, 55, 45, 30, light!
    SetCol ROOF, 50, 15, 10, light!
    SetCol TREE, 5, 40, 10, light!
    SetCol TRUNK, 35, 20, 8, light!
    ' Windows: dark glass by day, warm yellow light at night.
    IF light! < .3 THEN SetCol WINDOWC, 63, 55, 20, 1 ELSE SetCol WINDOWC, 15, 25, 35, light!
    ' Stars: same as the sky by day, white at night.
    IF light! < .15 THEN SetCol STAR, 63, 63, 63, 1 ELSE SetCol STAR, 20, 45, 63, light!
    RETURN

SUB Cloud (x, y, c)
    ' A cloud is three overlapping discs.
    Disc x, y, 9, c: Disc x + 12, y - 4, 11, c: Disc x + 25, y, 9, c
END SUB

SUB Disc (x, y, r, c)
    ' Filled circle made of horizontal lines.  For each row dy,
    ' the half-width is SQR(r^2 - dy^2) (Pythagoras).
    FOR dy = -r TO r
        hw = SQR(r * r - dy * dy)
        LINE (x - hw, y + dy)-(x + hw, y + dy), c
    NEXT
END SUB

SUB SetCol (n, r, g, b, light!)
    ' Night is a dark blue-ish version of every color: 15% of the
    ' day color plus a little blue.  Mix towards day by 'light'.
    nr = r * .15: ng = g * .15: nb = b * .15 + 8
    OUT &H3C8, n
    OUT &H3C9, nr + (r - nr) * light!
    OUT &H3C9, ng + (g - ng) * light!
    OUT &H3C9, nb + (b - nb) * light!
END SUB
