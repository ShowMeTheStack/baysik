' ============================================================
' TITLE:    ASCII Aquarium
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     ascii art, animation, arrays, random, locate
' SUMMARY:  A relaxing fish tank of ASCII-art fish swimming both ways, rising bubbles and swaying seaweed.
' ------------------------------------------------------------
' WHAT IT DOES
'   Fills the screen with a blue "tank" and animates:
'     * fish made of characters like  ><>  and  <><  that swim left
'       or right at different speeds and wrap around the tank,
'     * bubbles that rise from the bottom and pop at the surface,
'     * seaweed that sways from side to side.
'   Press F to feed the fish - food sprinkles down from the top.
'
' HOW TO USE
'   F = drop food    Space = add a fish    Esc or Q = quit
'
' CONCEPTS YOU WILL LEARN
'   * Erase-move-draw animation: print spaces over the old spot,
'     change the position, print at the new spot
'   * Arrays that hold the state of many objects (x, y, speed...)
'   * Different shapes for different directions
'   * Using RND to make things look natural
'
' THINGS TO TRY
'   * Draw your own fish shapes in the DATA lines.
'   * Make fish swim toward the food when it is dropped.
'   * Add a crab walking along the sand.
' ============================================================

DEFINT A-Z
CONST MAXF = 12, MAXB = 15, MAXFOOD = 20
CONST TOP = 3, BOT = 21            ' water rows

' ---- fish ----
DIM fx!(1 TO MAXF), fy(1 TO MAXF), fs!(1 TO MAXF), fc(1 TO MAXF), fk(1 TO MAXF)
DIM fR$(1 TO 4), fL$(1 TO 4)       ' 4 fish shapes, facing right and left
' ---- bubbles and food ----
DIM bx(1 TO MAXB), by!(1 TO MAXB)
DIM foodX(1 TO MAXFOOD), foodY!(1 TO MAXFOOD)

' Fish pictures: the right-facing version, then the left-facing one.
FOR i = 1 TO 4: READ fR$(i), fL$(i): NEXT i
DATA "><>", "<><"
DATA "><(('>", "<'))><"
DATA ">=))*>", "<*((=<"
DATA "}-<o>", "<o>-{"

RANDOMIZE TIMER
SCREEN 0: WIDTH 80, 25
LOCATE , , 0

' ---- draw the tank ----
COLOR 7, 0: CLS
COLOR 11, 1
FOR r = TOP - 1 TO BOT
    LOCATE r, 1: PRINT SPACE$(80);
NEXT r
LOCATE TOP - 1, 1: PRINT STRING$(80, 247);   ' wavy water surface
COLOR 6, 1
LOCATE BOT + 1, 1: PRINT STRING$(80, 177);   ' sand
LOCATE BOT + 2, 1: PRINT STRING$(80, 178);
COLOR 15, 0
LOCATE 1, 30: PRINT "THE ASCII AQUARIUM";
COLOR 8, 0
LOCATE 25, 18: PRINT "F = feed    Space = new fish    Esc = quit";

nf = 6
FOR i = 1 TO nf: GOSUB NewFish: NEXT i
FOR i = 1 TO MAXB: bx(i) = 0: NEXT i       ' bx = 0 means "no bubble"
frame = 0

DO
    t! = TIMER
    frame = frame + 1

    ' ---- seaweed: 4 plants, sway every few frames ----
    IF frame MOD 6 = 0 THEN
        COLOR 2, 1
        FOR p = 1 TO 4
            px = p * 18
            FOR r = BOT - 5 TO BOT
                ' each row leans left or right depending on time & height
                sway = ((frame \ 6 + r) MOD 2)
                LOCATE r, px: PRINT "  ";
                LOCATE r, px + sway
                IF sway THEN PRINT ")"; ELSE PRINT "(";
            NEXT r
        NEXT p
    END IF

    ' ---- fish ----
    FOR i = 1 TO nf
        k = fk(i)
        IF fs!(i) > 0 THEN s$ = fR$(k) ELSE s$ = fL$(k)
        ' erase old position
        COLOR 11, 1
        x = INT(fx!(i))
        IF x >= 1 AND x + LEN(s$) - 1 <= 80 THEN LOCATE fy(i), x: PRINT SPACE$(LEN(s$));
        ' move
        fx!(i) = fx!(i) + fs!(i)
        IF fx!(i) > 81 THEN fx!(i) = -LEN(s$)       ' swam off the right edge
        IF fx!(i) < -LEN(s$) THEN fx!(i) = 81       ' swam off the left edge
        ' now and then a fish turns around
        IF RND < .005 THEN fs!(i) = -fs!(i)
        ' draw new position (only when fully inside the screen)
        x = INT(fx!(i))
        IF fs!(i) > 0 THEN s$ = fR$(k) ELSE s$ = fL$(k)
        IF x >= 1 AND x + LEN(s$) - 1 <= 80 THEN
            COLOR fc(i), 1: LOCATE fy(i), x: PRINT s$;
        END IF
    NEXT i

    ' ---- bubbles ----
    IF RND < .15 THEN                        ' maybe start a new bubble
        FOR b = 1 TO MAXB
            IF bx(b) = 0 THEN bx(b) = INT(RND * 78) + 2: by!(b) = BOT: EXIT FOR
        NEXT b
    END IF
    COLOR 15, 1
    FOR b = 1 TO MAXB
        IF bx(b) > 0 THEN
            IF SCREEN(INT(by!(b)), bx(b)) = 111 OR SCREEN(INT(by!(b)), bx(b)) = 248 THEN
                LOCATE INT(by!(b)), bx(b): PRINT " ";
            END IF
            by!(b) = by!(b) - .5
            IF by!(b) < TOP THEN
                bx(b) = 0                     ' popped at the surface
            ELSEIF SCREEN(INT(by!(b)), bx(b)) = 32 THEN
                ' small bubbles low down, bigger ones higher up
                LOCATE INT(by!(b)), bx(b)
                IF by!(b) > 12 THEN PRINT CHR$(248); ELSE PRINT "o";
            END IF
        END IF
    NEXT b

    ' ---- food flakes sink slowly ----
    COLOR 14, 1
    FOR i = 1 TO MAXFOOD
        IF foodX(i) > 0 THEN
            IF SCREEN(INT(foodY!(i)), foodX(i)) = 250 THEN LOCATE INT(foodY!(i)), foodX(i): PRINT " ";
            foodY!(i) = foodY!(i) + .25
            IF foodY!(i) > BOT THEN
                foodX(i) = 0                  ' reached the sand
            ELSEIF SCREEN(INT(foodY!(i)), foodX(i)) = 32 THEN
                LOCATE INT(foodY!(i)), foodX(i): PRINT CHR$(250);
            END IF
        END IF
    NEXT i

    ' ---- keys ----
    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "F"
            FOR i = 1 TO MAXFOOD
                foodX(i) = INT(RND * 70) + 5: foodY!(i) = TOP + RND * 2
            NEXT i
        CASE " "
            IF nf < MAXF THEN nf = nf + 1: i = nf: GOSUB NewFish
        CASE CHR$(27), "Q"
            EXIT DO
    END SELECT

    DO WHILE TIMER - t! < .07 AND TIMER >= t!: LOOP
LOOP
COLOR 7, 0: CLS
LOCATE , , 1
END

' Give fish number i a random shape, colour, row, place and speed.
NewFish:
    fk(i) = INT(RND * 4) + 1
    fc(i) = 9 + INT(RND * 7)                ' a bright colour 9..15
    fy(i) = TOP + 1 + INT(RND * (BOT - TOP - 7))   ' stay above the seaweed
    fx!(i) = INT(RND * 70) + 2
    fs!(i) = .3 + RND * .8
    IF RND < .5 THEN fs!(i) = -fs!(i)       ' half swim left
    RETURN
