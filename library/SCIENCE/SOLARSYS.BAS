' ============================================================
' TITLE:    Solar System Scale Model
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     astronomy, scale, ratios, data, tables
' SUMMARY:  Shrink the Sun to a ball you choose and find out how small and far away the planets become.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pictures in books squash the planets close together, so most
'   people never realise how EMPTY space is.  Tell this program how
'   big you want the Sun to be (say, a 30 cm beach ball) and it
'   works out how big each planet would be and how far away you
'   would have to put it.  Then it draws the planets' true SIZES
'   side by side.
'
' HOW TO USE
'   Type the Sun's diameter in centimetres (e.g. 30) and press
'   Enter.  Read the table, press a key to see the size picture,
'   press a key again to try another size.  Type 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Scale factors: model size = real size * (model Sun / real Sun)
'   * Converting units (km -> cm -> m -> km)
'   * READ / DATA tables and RESTORE
'   * PRINT USING for neat columns
'
' THINGS TO TRY
'   * Make the Sun 1 metre wide.  How far is Neptune?  Could you walk it?
'   * Add the Moon (3,474 km wide, 384,400 km from Earth).
'   * Add Proxima Centauri: 40,000,000,000,000 km away!
' ============================================================

CONST SUNKM = 1392700           ' the Sun's real diameter in km
CONST NPL = 8

DIM nm$(NPL), dia(NPL), dist(NPL), col(NPL)
FOR i = 1 TO NPL
    READ nm$(i), dia(i), dist(i), col(i)
NEXT
' name, diameter (km), average distance from Sun (millions of km), colour
DATA "Mercury", 4879, 57.9, 7
DATA "Venus", 12104, 108.2, 14
DATA "Earth", 12756, 149.6, 9
DATA "Mars", 6792, 227.9, 12
DATA "Jupiter", 142984, 778.6, 6
DATA "Saturn", 120536, 1433.5, 14
DATA "Uranus", 51118, 2872.5, 11
DATA "Neptune", 49528, 4495.1, 1

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "SOLAR SYSTEM SCALE MODEL": COLOR 7
    PRINT "How big is the model Sun?  (30 = beach ball, 7 = orange, 0 = quit)"
    INPUT "Sun diameter in cm"; sunCm
    IF sunCm <= 0 THEN EXIT DO

    ' One number does all the work: how many model-cm per real km.
    scale# = sunCm / SUNKM

    PRINT
    COLOR 15
    PRINT "Planet      Model size        Distance from model Sun"
    PRINT "-------     ----------        -----------------------"
    COLOR 7
    FOR i = 1 TO NPL
        sizeCm# = dia(i) * scale#
        ' distance: millions of km -> km -> model cm -> metres
        distM# = dist(i) * 1000000# * scale# / 100
        PRINT USING "\       \"; nm$(i);
        IF sizeCm# < 1 THEN
            PRINT USING "  ###.## mm     "; sizeCm# * 10;
        ELSE
            PRINT USING "  ###.## cm     "; sizeCm#;
        END IF
        IF distM# >= 1000 THEN
            PRINT USING "  ####.## km"; distM# / 1000
        ELSE
            PRINT USING "  ####.## m"; distM#
        END IF
    NEXT
    PRINT
    ' A walking person covers about 1.4 metres every second.
    walk# = dist(NPL) * 1000000# * scale# / 100 / 1.4 / 60
    PRINT USING "Walking from the Sun to Neptune would take about ####### minutes."; walk#
    PRINT
    PRINT "Press any key to compare the planets' sizes..."
    DO: LOOP WHILE INKEY$ = ""

    ' ---- size picture -------------------------------------------
    ' Everything here is to the SAME scale: Jupiter's width sets
    ' the scale so it fills about 1/4 of the screen.
    SCREEN 12: CLS
    pxPerKm = 140 / dia(5)
    ' a slice of the Sun at the left edge, same scale
    sunR = SUNKM / 2 * pxPerKm
    CIRCLE (-sunR + 60, 240), sunR, 14
    PAINT (5, 240), 14, 14
    x = 80
    FOR i = 1 TO NPL
        r = dia(i) / 2 * pxPerKm
        IF r < 1 THEN r = 1
        x = x + r + 6
        CIRCLE (x, 240), r, col(i)
        PAINT (x, 240), col(i), col(i)
        ' label below each planet
        LOCATE 22 + (i MOD 2), INT(x / 8) - 2
        COLOR col(i): PRINT LEFT$(nm$(i), 4);
        x = x + r + 6
    NEXT
    COLOR 15
    LOCATE 2, 2: PRINT "Planet sizes to scale (the yellow edge is part of the Sun!)"
    LOCATE 28, 2: PRINT "Press any key...";
    DO: LOOP WHILE INKEY$ = ""
LOOP
SCREEN 0: WIDTH 80: CLS
PRINT "Space is big.  Really big."
END
