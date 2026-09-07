' ============================================================
' TITLE:    Page Flipping Aquarium
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     page flipping, PCOPY, SCREEN 7, apage, vpage
' SUMMARY:  Fish swim through a detailed aquarium with zero flicker using three video pages and PCOPY.
' ------------------------------------------------------------
' WHAT IT DOES
'   SCREEN 7 has several video "pages" - whole screens of memory.
'   This program uses three of them:
'     page 2 = the background (sand, rocks, weeds), drawn ONCE
'     page 1 = the work page, where each new frame is built
'     page 0 = the page you actually see
'   Every frame: copy background 2 -> 1, draw fish and bubbles
'   on page 1, then copy the finished frame 1 -> 0 in one go.
'   You never see a half-drawn picture, so there is no flicker.
'
' HOW TO USE
'   Watch the fish.  Press 0, 1 or 2 to choose which page is
'   VISIBLE (vpage) - peek behind the curtain!  Page 1 looks
'   just like page 0; page 2 is the empty tank.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * SCREEN mode, , apage, vpage  - choose the active page
'     (where drawing goes) and the visual page (what you see)
'   * PCOPY src, dest  - copy one whole page to another
'   * Keeping a clean background on a spare page
'   * Arrays of objects (position, speed, color for each fish)
'
' THINGS TO TRY
'   * Add more fish (raise NF)
'   * Draw directly on page 0 (SCREEN 7, , 0, 0) and see flicker
' ============================================================
DEFINT A-Z
DECLARE SUB DrawFish (x, y, dir, c)

CONST NF = 6, NB = 12

' ---- 1. Draw the background on page 2 -----------------------
SCREEN 7, , 2, 0          ' draw on page 2 while showing page 0
CLS
LINE (0, 0)-(319, 199), 1, BF                    ' deep blue water
FOR y = 0 TO 60 STEP 6                           ' lighter bands near the top
    LINE (0, y)-(319, y + 2), 9, BF
NEXT
LINE (0, 170)-(319, 199), 6, BF                  ' sand
FOR i = 1 TO 150: PSET (RND * 319, 171 + RND * 28), 14: NEXT
CIRCLE (60, 175), 30, 8, , , .5: PAINT (60, 172), 7, 8      ' rocks
CIRCLE (250, 178), 22, 8, , , .6: PAINT (250, 175), 8, 8
FOR p = 0 TO 7                                   ' wavy sea weed
    bx = 20 + p * 40 + RND * 10
    FOR y = 175 TO 110 + RND * 30 STEP -1
        PSET (bx + 4 * SIN(y / 6), y), 2
        PSET (bx + 1 + 4 * SIN(y / 6), y), 10
    NEXT
NEXT
COLOR 15: LOCATE 1, 2: PRINT "Press 0/1/2 to view a page, Esc=quit";

' ---- 2. Set up the fish and bubbles -------------------------
DIM fx(NF), fy(NF), fdx(NF), fc(NF)
DIM bx(NB), by(NB)
RANDOMIZE TIMER
FOR i = 1 TO NF
    fx(i) = 20 + RND * 280: fy(i) = 30 + RND * 120
    fdx(i) = 1 + INT(RND * 3): IF RND < .5 THEN fdx(i) = -fdx(i)
    fc(i) = 12 + INT(RND * 3)    ' red, magenta or yellow fish
NEXT
FOR i = 1 TO NB: bx(i) = RND * 319: by(i) = RND * 170: NEXT

vp = 0
' ---- 3. Animation loop --------------------------------------
DO
    SCREEN 7, , 1, vp         ' draw on page 1, show the chosen page
    PCOPY 2, 1                ' fresh copy of the background

    FOR i = 1 TO NF
        fx(i) = fx(i) + fdx(i)
        ' Turn around at the glass, and wander up/down a little.
        IF fx(i) < 10 OR fx(i) > 309 THEN fdx(i) = -fdx(i)
        fy(i) = fy(i) + INT(RND * 3) - 1
        IF fy(i) < 20 THEN fy(i) = 20
        IF fy(i) > 160 THEN fy(i) = 160
        DrawFish fx(i), fy(i), SGN(fdx(i)), fc(i)
    NEXT

    FOR i = 1 TO NB
        by(i) = by(i) - 1                     ' bubbles rise
        bx(i) = bx(i) + INT(RND * 3) - 1      ' and wobble
        IF by(i) < 12 THEN by(i) = 170: bx(i) = RND * 319
        CIRCLE (bx(i), by(i)), 2, 11
    NEXT

    ' The frame is finished on page 1: copy it to the visible page.
    IF vp = 0 THEN PCOPY 1, 0
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    k$ = INKEY$
    IF k$ >= "0" AND k$ <= "2" THEN vp = VAL(k$)
LOOP UNTIL k$ = CHR$(27)

SCREEN 0, , 0, 0: WIDTH 80
END

SUB DrawFish (x, y, dir, c)
    ' A fish = oval body + triangle tail + eye.  dir is +1 when
    ' swimming right and -1 when swimming left: multiplying the
    ' x offsets by dir mirrors the drawing.
    CIRCLE (x, y), 9, c, , , .5
    PAINT (x, y), c, c
    LINE (x - 9 * dir, y)-(x - 15 * dir, y - 5), c
    LINE (x - 15 * dir, y - 5)-(x - 15 * dir, y + 5), c
    LINE (x - 15 * dir, y + 5)-(x - 9 * dir, y), c
    PSET (x + 5 * dir, y - 1), 0                ' eye
END SUB
