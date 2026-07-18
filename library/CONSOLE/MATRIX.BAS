' ============================================================
' TITLE:    Digital Rain
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     animation, arrays, random, color, screen saver
' SUMMARY:  The famous green "digital rain" screen saver: falling streams of glowing characters with fading tails.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every one of the 80 columns has a "drop" falling down the screen
'   at its own speed.  The head of each drop is bright white, the
'   characters behind it turn bright green, then dark green, and the
'   tail is erased - so each stream seems to glow and fade.
'   Characters behind the head flicker at random to look like
'   streaming data.  A secret message appears now and then.
'
' HOW TO USE
'   Just watch.  + / - change the speed, M shows the message,
'   Esc or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Parallel arrays: one entry per column (position, speed, length)
'   * Fractional positions so drops can move at different speeds
'   * Drawing a "trail" by colouring the cells behind the head
'   * Frame timing with TIMER
'
' THINGS TO TRY
'   * Use only 0 and 1 characters for a "binary rain".
'   * Make the rain red or blue.
'   * Make the drops fall upwards!
' ============================================================

DEFINT A-Z
DECLARE FUNCTION RandChar$ ()

CONST COLS = 80, ROWS = 25
DIM y!(1 TO COLS)        ' head position (can be fractional)
DIM spd!(1 TO COLS)      ' rows per frame
DIM tail(1 TO COLS)      ' length of the trail
DIM lastRow(1 TO COLS)   ' last whole row the head was drawn on

RANDOMIZE TIMER
SCREEN 0: WIDTH 80, 25
COLOR 2, 0: CLS
LOCATE , , 0             ' hide the cursor

' Start every drop somewhere ABOVE the screen so they don't all
' arrive at the same moment.
FOR c = 1 TO COLS
    y!(c) = -RND * 30
    spd!(c) = .3 + RND * .7
    tail(c) = 6 + INT(RND * 14)
    lastRow(c) = INT(y!(c))
NEXT c

delay! = .04
msg$ = "WAKE UP, PROGRAMMER..."
msgTimer = 0

DO
    t! = TIMER
    FOR c = 1 TO COLS
        y!(c) = y!(c) + spd!(c)
        r = INT(y!(c))
        ' Only do work when the head reaches a NEW row.
        IF r <> lastRow(c) THEN
            lastRow(c) = r
            ' 1) old head (one row up) becomes bright green
            IF r - 1 >= 1 AND r - 1 <= ROWS THEN
                COLOR 10: LOCATE r - 1, c: PRINT RandChar$;
            END IF
            ' 2) a few rows further up it fades to dark green
            IF r - 4 >= 1 AND r - 4 <= ROWS THEN
                COLOR 2: LOCATE r - 4, c: PRINT RandChar$;
            END IF
            ' 3) the end of the tail is erased
            IF r - tail(c) >= 1 AND r - tail(c) <= ROWS THEN
                LOCATE r - tail(c), c: PRINT " ";
            END IF
            ' 4) the new head, bright white
            IF r >= 1 AND r <= ROWS THEN
                COLOR 15: LOCATE r, c: PRINT RandChar$;
            END IF
            ' When the whole tail has left the screen, restart at the top
            ' with a new random speed and length.
            IF r - tail(c) > ROWS THEN
                y!(c) = -RND * 10
                spd!(c) = .3 + RND * .7
                tail(c) = 6 + INT(RND * 14)
                lastRow(c) = INT(y!(c))
            END IF
        END IF
    NEXT c

    ' Random flicker: change a few characters that are already shown
    ' (only non-blank ones), keeping their colour dark green.
    FOR i = 1 TO 6
        rr = INT(RND * ROWS) + 1: cc = INT(RND * COLS) + 1
        IF SCREEN(rr, cc) <> 32 AND SCREEN(rr, cc, 1) = 2 THEN
            COLOR 2: LOCATE rr, cc: PRINT RandChar$;
        END IF
    NEXT i

    ' The secret message, shown for a while in the middle.
    IF msgTimer > 0 THEN
        msgTimer = msgTimer - 1
        COLOR 15, 0
        LOCATE 13, 40 - LEN(msg$) \ 2: PRINT msg$;
        IF msgTimer = 0 THEN LOCATE 13, 40 - LEN(msg$) \ 2: PRINT SPACE$(LEN(msg$));
    END IF

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "+", "=": IF delay! > .01 THEN delay! = delay! - .01
        CASE "-": IF delay! < .2 THEN delay! = delay! + .01
        CASE "M": msgTimer = 60
        CASE CHR$(27), "Q": EXIT DO
    END SELECT
    IF RND < .002 THEN msgTimer = 60     ' sometimes it appears by itself

    DO WHILE TIMER - t! < delay! AND TIMER >= t!: LOOP
LOOP

COLOR 7, 0: CLS
LOCATE , , 1
END

' A random "data" character: digits, capital letters or a few
' katakana-looking symbols from the upper half of the character set.
FUNCTION RandChar$
    SELECT CASE INT(RND * 3)
        CASE 0: RandChar$ = CHR$(48 + INT(RND * 10))        ' 0-9
        CASE 1: RandChar$ = CHR$(65 + INT(RND * 26))        ' A-Z
        CASE ELSE: RandChar$ = CHR$(224 + INT(RND * 20))    ' Greek/maths symbols
    END SELECT
END FUNCTION
