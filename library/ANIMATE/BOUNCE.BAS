' ============================================================
' TITLE:    Bouncing Logo Screensaver
' CATEGORY: Animation & Sprites
' LEVEL:    Beginner
' TAGS:     screensaver, GET, PUT, PALETTE, POINT, bounce
' SUMMARY:  A big logo drifts around the screen, changing color every time it bounces - will it ever hit a corner exactly?
' ------------------------------------------------------------
' WHAT IT DOES
'   Builds a chunky logo by printing a word in tiny text and
'   blowing up every pixel into a 3x3 block (using POINT to read
'   the pixels).  The logo is captured with GET and bounced
'   around the screen like an old DVD-player screensaver.
'   On each bounce the color changes - but the logo is NOT
'   redrawn: we just change what color number 1 looks like with
'   PALETTE.  It also counts perfect corner hits.
'
' HOW TO USE
'   Sit back and wait for a corner hit.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * POINT(x, y) reads the color of a pixel
'   * Scaling a bitmap up by drawing boxes
'   * Bouncing: reverse dx when hitting a side, dy for top/bottom
'   * PALETTE attribute, color  - recolor a whole picture at once
'   * Self-erasing sprites: a black margin wipes the trail
'
' THINGS TO TRY
'   * Change the word in LOGO$
'   * Start at x=0, y=0 with dx=dy - it will hit corners a lot!
' ============================================================
DEFINT A-Z

CONST LOGO$ = "QBASIC"
CONST SCALE = 3

SCREEN 12                        ' 640 x 480, 16 colors
RANDOMIZE TIMER

' ---- 1. Print the word small, then draw it big ---------------
' In SCREEN 12 each character is 8 pixels wide, 16 tall.
COLOR 1
LOCATE 1, 1: PRINT LOGO$
wPix = LEN(LOGO$) * 8: hPix = 16
FOR y = 0 TO hPix - 1
    FOR x = 0 TO wPix - 1
        IF POINT(x, y) <> 0 THEN
            ' One small pixel -> one SCALE x SCALE block,
            ' placed below the small text, around (40, 60).
            LINE (40 + x * SCALE, 60 + y * SCALE)-STEP(SCALE - 1, SCALE - 1), 1, BF
        END IF
    NEXT
NEXT
' An oval ring around the word makes it look like a badge.
' The aspect ratio (last CIRCLE number) is height / width.
cx = 40 + wPix * SCALE \ 2: cy = 60 + hPix * SCALE \ 2
rx = wPix * SCALE \ 2 + 24: ry = hPix * SCALE \ 2 + 18
CIRCLE (cx, cy), rx, 1, , , ry / rx

' ---- 2. Capture it with GET ----------------------------------
' Include a 5-pixel black margin all round.  The logo moves
' only 2 pixels per frame, so the margin paints over the old
' edge and no trail is left behind.
x1 = cx - rx - 5: y1 = cy - ry - 5
x2 = cx + rx + 5: y2 = cy + ry + 5
w = x2 - x1: h = y2 - y1
' SCREEN 12 GET needs 4 + rows * 4 planes * bytes-per-row bytes.
' Divide by 2 to get the number of INTEGERs.
DIM badge(2 + (h + 1) * 2 * ((w + 8) \ 8))
GET (x1, y1)-(x2, y2), badge
CLS

' ---- 3. Bounce ------------------------------------------------
x = RND * (639 - w): y = RND * (463 - h)
dx = 2: dy = 2
hue = 0: corners = 0: bounces = 0
DIM pal&(5)                      ' some nice colors (DATA below)
FOR i = 0 TO 5: READ r, g, b: pal&(i) = r + g * 256& + b * 65536: NEXT
DATA 63,20,20, 20,63,20, 30,30,63, 63,63,10, 63,20,63, 10,63,63
PALETTE 1, pal&(0)

DO
    PUT (x, y), badge, PSET
    x = x + dx: y = y + dy
    hitX = 0: hitY = 0
    IF x <= 0 OR x >= 639 - w THEN dx = -dx: hitX = -1
    IF y <= 0 OR y >= 463 - h THEN dy = -dy: hitY = -1
    IF x < 0 THEN x = 0
    IF y < 0 THEN y = 0
    IF x > 639 - w THEN x = 639 - w
    IF y > 463 - h THEN y = 463 - h

    IF hitX OR hitY THEN
        bounces = bounces + 1
        hue = (hue + 1) MOD 6
        PALETTE 1, pal&(hue)     ' instant recolor!
        IF hitX AND hitY THEN corners = corners + 1: SOUND 880, 2
    END IF

    COLOR 7: LOCATE 30, 2
    PRINT "Bounces:"; bounces; "  Corner hits:"; corners; "   Esc quits";
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
LOOP UNTIL INKEY$ = CHR$(27)

PALETTE                          ' restore the default colors
SCREEN 0: WIDTH 80
