' ============================================================
' TITLE:    Isometric City
' CATEGORY: Graphics
' LEVEL:    Advanced
' TAGS:     isometric, painter's algorithm, hercules, shading, screen 3
' SUMMARY:  Builds a random isometric city of shaded blocks on the 720x348 Hercules monochrome screen using the painter's algorithm.
' ------------------------------------------------------------
' WHAT IT DOES
'   Lays out an 8 x 8 isometric grid (the "diamond" view used by
'   many strategy games) and puts a random building on most
'   squares. Each building has three visible faces. Because the
'   screen has only black and white, the faces are shaded with
'   dot patterns made by LINE styles. Buildings are drawn from
'   the back of the grid to the front, so nearer ones correctly
'   hide farther ones - the "painter's algorithm".
'
' HOW TO USE
'   R        build a new random city
'   Q / Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Isometric projection: screen x = (i - j) * W,
'     screen y = (i + j) * H - height
'   * The painter's algorithm: draw far things first
'   * Filling shapes column by column with vertical LINEs
'   * Shading in a 2-colour mode with LINE style patterns
'   * SCREEN 3: Hercules graphics, 720 x 348 pixels
'
' THINGS TO TRY
'   * Make a pyramid: height = 8 - the distance from the centre
'   * Add roads by leaving whole rows of the grid at height 0
'   * Swap the shading patterns of the left and right faces
' ============================================================

DECLARE SUB Block (i%, j%, h%)
CONST GN = 8                       ' grid is GN x GN cells
' Shared projection constants: half-width / half-height of one
' diamond cell, height of one storey, and the screen origin.
CONST TW = 30, TH = 15, ZH = 12, OX = 360, OY = 70

DIM SHARED ht%(GN - 1, GN - 1)

SCREEN 3
RANDOMIZE TIMER

DO
    CLS
    ' ---- Invent a city: taller buildings near the middle ---------
    FOR i% = 0 TO GN - 1
        FOR j% = 0 TO GN - 1
            d = ABS(i% - 3.5) + ABS(j% - 3.5)    ' distance from centre
            ht%(i%, j%) = INT(RND * (9 - d)) + 1
            IF RND < .15 THEN ht%(i%, j%) = 0      ' some empty lots
            IF ht%(i%, j%) < 0 THEN ht%(i%, j%) = 0
        NEXT j%
    NEXT i%

    ' ---- Painter's algorithm --------------------------------------
    ' Cells with a smaller i + j are further away (higher up the
    ' screen), so we visit diagonals s = i + j from 0 upward.
    FOR s% = 0 TO 2 * (GN - 1)
        FOR i% = 0 TO GN - 1
            j% = s% - i%
            IF j% >= 0 AND j% < GN THEN Block i%, j%, ht%(i%, j%)
        NEXT i%
    NEXT s%

    LOCATE 1, 2: PRINT "Isometric City"
    LOCATE 25, 2: PRINT "R = rebuild   Q = quit";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
LOOP

SCREEN 0: WIDTH 80
END

' ---- Draw one building (or an empty lot if h% = 0) -------------------
' (xn, yn) is the screen position of the cell's back corner at roof
' level. For each column dx from -TW to +TW we know exactly where the
' roof diamond starts and ends, and the wall below it is h% storeys.
SUB Block (i%, j%, h%)
    xn% = OX + (i% - j%) * TW
    yn% = OY + (i% + j%) * TH - h% * ZH
    wallH% = h% * ZH
    FOR dx% = -TW TO TW
        x% = xn% + dx%
        slope% = ABS(dx%) * TH \ TW       ' how far the diamond edge drops
        yTop% = yn% + slope%              ' top edge of the roof
        yMid% = yn% + 2 * TH - slope%     ' bottom edge of the roof
        yBot% = yMid% + wallH%            ' foot of the wall
        ' 1. wipe this column so it hides anything drawn earlier
        LINE (x%, yTop%)-(x%, yBot%), 0
        ' 2. roof: light dots (every other pixel, offset per column)
        IF h% > 0 THEN
            IF x% MOD 2 THEN st% = &H5555 ELSE st% = &HAAAA
            LINE (x%, yTop%)-(x%, yMid%), 1, , st%
            ' 3. walls: left side dark (sparse dots), right side stripes
            IF dx% < 0 THEN
                IF x% MOD 4 = 0 THEN LINE (x%, yMid%)-(x%, yBot%), 1, , &H8888
            ELSE
                IF x% MOD 3 = 0 THEN LINE (x%, yMid%)-(x%, yBot%), 1
            END IF
        END IF
    NEXT dx%
    ' 4. outlines in solid white
    xs% = xn%: ys% = yn% + 2 * TH          ' front corner of the roof
    LINE (xn%, yn%)-(xn% + TW, yn% + TH), 1
    LINE -(xs%, ys%), 1
    LINE -(xn% - TW, yn% + TH), 1
    LINE -(xn%, yn%), 1
    IF h% > 0 THEN
        LINE (xn% - TW, yn% + TH)-(xn% - TW, yn% + TH + wallH%), 1
        LINE (xs%, ys%)-(xs%, ys% + wallH%), 1
        LINE (xn% + TW, yn% + TH)-(xn% + TW, yn% + TH + wallH%), 1
        LINE (xn% - TW, yn% + TH + wallH%)-(xs%, ys% + wallH%), 1
        LINE -(xn% + TW, yn% + TH + wallH%), 1
    END IF
END SUB
