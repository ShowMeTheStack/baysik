' ============================================================
' TITLE:    Sprite Sheet in DATA
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     sprite sheet, DATA, masks, transparency, AND, OR
' SUMMARY:  Seven pixel-art frames typed as DATA strings become see-through sprites: spinning coins, a flapping bird and a hopping slime.
' ------------------------------------------------------------
' WHAT IT DOES
'   A "sprite sheet" is one picture holding every frame of every
'   character in a game.  Ours is typed straight into DATA lines:
'   each character is one pixel, a hex digit 0-F gives the color
'   and "." means "transparent".
'   The program decodes the sheet into two images per frame:
'     SPRITE: the colored pixels, with 0 where it is transparent
'     MASK:   0 where the sprite is solid, 255 where transparent
'   Drawing = PUT mask with AND (punches a black hole the shape
'   of the sprite but leaves the background elsewhere), then PUT
'   sprite with OR (fills the hole with color).  Result: a sprite
'   with no ugly black box around it!
'
' HOW TO USE
'   T   toggle transparency (see the boxes without masks)
'   S   view the sprite sheet enlarged
'   Esc quit
'
' CONCEPTS YOU WILL LEARN
'   * Storing artwork as text and decoding it with MID$ and VAL
'   * Masked sprites:  PUT ..., AND  then  PUT ..., OR
'   * Why it works: X AND 0 = 0 ; X AND 255 = X ; 0 OR c = c
'   * Saving the background under a moving sprite with GET
'   * Animation sequences: the coin plays frames 1,2,3,2,1,...
'
' THINGS TO TRY
'   * Design a new 10x10 character and add it to the DATA
'   * Make the slime jump when it reaches the middle
' ============================================================
DEFINT A-Z
DECLARE SUB DrawSprite (x, y, f)

CONST SW = 10, SH = 10            ' size of each frame
CONST NF = 7                      ' frames on the sheet
CONST FS = 60                     ' integers per frame (4 + 100 bytes = 52 ints)
DIM SHARED spr(NF * FS), msk(NF * FS)
DIM SHARED sheet$(NF - 1, SH - 1)
DIM SHARED transparent
DIM birdUnder(FS), slimeUnder(FS) ' saved backgrounds
DIM coinSeq(3)                    ' coin animation: frames 0,1,2,1
coinSeq(0) = 0: coinSeq(1) = 1: coinSeq(2) = 2: coinSeq(3) = 1

SCREEN 13
' ---- 1. Read the sheet ----------------------------------------
FOR f = 0 TO NF - 1
    FOR r = 0 TO SH - 1: READ sheet$(f, r): NEXT
NEXT

' ---- 2. Decode each frame into SPRITE and MASK images ---------
FOR f = 0 TO NF - 1
    FOR pass = 1 TO 2
        FOR r = 0 TO SH - 1
            FOR c = 0 TO SW - 1
                ch$ = MID$(sheet$(f, r), c + 1, 1)
                IF ch$ = "." THEN
                    ' transparent: sprite 0, mask 255
                    IF pass = 1 THEN PSET (c, r), 0 ELSE PSET (c, r), 255
                ELSE
                    ' solid: sprite = its color, mask 0
                    ' VAL("&H" + digit) turns hex "A" into 10, etc.
                    IF pass = 1 THEN PSET (c, r), VAL("&H" + ch$) ELSE PSET (c, r), 0
                END IF
            NEXT
        NEXT
        IF pass = 1 THEN GET (0, 0)-(SW - 1, SH - 1), spr(f * FS) ELSE GET (0, 0)-(SW - 1, SH - 1), msk(f * FS)
    NEXT
NEXT

' ---- 3. A detailed background, so transparency shows ----------
GOSUB DrawScene
transparent = -1

' ---- 4. Animate -------------------------------------------------
bx = 0: sx = 0: n = 0
by = 40: sy = 160
GET (bx, by)-(bx + SW - 1, by + SH - 1), birdUnder
GET (sx, sy)-(sx + SW - 1, sy + SH - 1), slimeUnder
DO
    n = n + 1
    ' Coins don't move, so the sky behind them never needs
    ' saving: each new frame is drawn on a freshly cleared spot.
    IF n MOD 6 = 0 THEN
        cf = coinSeq((n \ 6) MOD 4)
        FOR i = 0 TO 4
            LINE (60 + i * 45, 110)-STEP(SW - 1, SH - 1), 11, BF   ' sky color behind coins
            DrawSprite 60 + i * 45, 110, cf
        NEXT
    END IF

    ' Moving sprites: 1) restore background  2) move
    ' 3) save the new background  4) draw.
    PUT (bx, by), birdUnder, PSET
    PUT (sx, sy), slimeUnder, PSET
    bx = (bx + 2) MOD (320 - SW)
    by = 40 + 15 * SIN(n / 8)                ' gentle up-and-down glide
    IF n MOD 4 = 0 THEN sx = (sx + 1) MOD (320 - SW)  ' slimes are slow
    GET (bx, by)-(bx + SW - 1, by + SH - 1), birdUnder
    GET (sx, sy)-(sx + SW - 1, sy + SH - 1), slimeUnder
    DrawSprite bx, by, 3 + (n \ 5) MOD 2     ' bird frames 3,4
    DrawSprite sx, sy, 5 + (n \ 10) MOD 2    ' slime frames 5,6

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    k$ = UCASE$(INKEY$)
    IF k$ = "T" THEN transparent = NOT transparent
    IF k$ = "S" THEN
        GOSUB ShowSheet
        GOSUB DrawScene
        GET (bx, by)-(bx + SW - 1, by + SH - 1), birdUnder
        GET (sx, sy)-(sx + SW - 1, sy + SH - 1), slimeUnder
    END IF
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

DrawScene:
    LINE (0, 0)-(319, 169), 11, BF                 ' sky
    FOR i = 0 TO 5                                 ' fluffy clouds
        CIRCLE (30 + i * 55, 25 + (i MOD 2) * 15), 14, 15
        PAINT (30 + i * 55, 25 + (i MOD 2) * 15), 15, 15
    NEXT
    LINE (0, 170)-(319, 199), 6, BF                ' dirt
    FOR x = 0 TO 319 STEP 3                        ' grass blades
        LINE (x, 170)-(x + 1, 164 + (x * 7) MOD 5), 2
    NEXT
    COLOR 15: LOCATE 1, 1: PRINT "T transparency  S sheet  Esc quit";
    RETURN

ShowSheet:
    CLS
    COLOR 15: LOCATE 1, 1: PRINT "The sprite sheet (zoomed x4):"
    FOR f = 0 TO NF - 1
        FOR r = 0 TO SH - 1
            FOR c = 0 TO SW - 1
                ch$ = MID$(sheet$(f, r), c + 1, 1)
                IF ch$ = "." THEN clr = 8 + 16 * ((r + c) MOD 2) ELSE clr = VAL("&H" + ch$)
                LINE (4 + f * 45 + c * 4, 30 + r * 4)-STEP(3, 3), clr, BF
            NEXT
        NEXT
        LOCATE 10, 2 + f * 45 \ 8 + 2: PRINT LTRIM$(STR$(f));
    NEXT
    LOCATE 14, 1: PRINT "Grey checks = transparent pixels."
    PRINT "0-2 coin, 3-4 bird, 5-6 slime"
    PRINT : PRINT "Press any key..."
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ---- the sheet: 7 frames of 10 rows each ----------------------
' coin, front view
DATA "...6666...","..6EEEE6..",".6EEFEEE6.",".6EFEEEE6.",".6EFEEEE6."
DATA ".6EEEEEE6.",".6EEEEEE6.","..6EEEE6..","...6666...",".........."
' coin, turning
DATA "....66....","...6EE6...","...6FE6...","...6FE6...","...6EE6..."
DATA "...6EE6...","...6EE6...","...6EE6...","....66....",".........."
' coin, edge on
DATA "....66....","....66....","....66....","....66....","....66...."
DATA "....66....","....66....","....66....","....66....",".........."
' bird, wings up
DATA "9........9",".9......9.","..9....9..","...9999...","..999F99E."
DATA "...9999...","..........","..........","..........",".........."
' bird, wings down
DATA "..........","..........","..........","...9999...","..999F99E."
DATA "..999999..",".9......9.","9........9","..........",".........."
' slime, tall
DATA "..........","..........","....AA....","...AAAA...","..AAAAAA.."
DATA ".AF0AAF0A.",".AAAAAAAA.","AAAAAAAAAA","AAAA22AAAA",".AAAAAAAA."
' slime, squashed
DATA "..........","..........","..........","..........","...AAAA..."
DATA ".AAAAAAAA.","AAF0AAF0AA","AAAAAAAAAA","AAAA22AAAA","AAAAAAAAAA"

SUB DrawSprite (x, y, f)
    IF transparent THEN
        PUT (x, y), msk(f * FS), AND    ' cut a sprite-shaped hole
        PUT (x, y), spr(f * FS), OR     ' fill it with color
    ELSE
        PUT (x, y), spr(f * FS), PSET   ' no mask: black box shows
    END IF
END SUB
