' ============================================================
' TITLE:    Scrolling Marquee
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     animation, mid$, strings, timer, scrolling
' SUMMARY:  Three news-ticker style marquees scrolling left, right and bouncing, all made with MID$.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows three animated text strips, like the scrolling signs in
'   shop windows and TV news tickers:
'     1. a message that scrolls right-to-left forever,
'     2. a message that scrolls left-to-right,
'     3. a short word that bounces between the edges.
'   A row of "chaser lights" runs around the top and bottom too.
'
' HOW TO USE
'   Just watch.  Press any key to stop.
'
' CONCEPTS YOU WILL LEARN
'   * MID$(text$, start, length) to cut a "window" out of a string
'   * Repeating a string so the window can wrap around smoothly
'   * Using TIMER to run an animation at a steady speed
'   * MOD to make counters go round and round
'
' THINGS TO TRY
'   * Change the messages to your own news.
'   * Make the speed variable faster or slower.
'   * Make marquee 2 change colour each time it wraps around.
' ============================================================

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS

' The text for each marquee.  Padding with spaces leaves a gap
' between the end of the message and its next repeat.
msg1$ = "*** BREAKING NEWS: BASIC programmer makes text move across the screen!   "
msg1$ = msg1$ + "Weather: 100% chance of pixels.   Sports: Bubble Sort beats Bogo Sort 1000 to 0.   "
msg2$ = "<<< scrolling the other way is just counting backwards >>>      "
bounce$ = "[ BOING! ]"

W = 60          ' width of the visible window in characters
LEFTCOL = 11    ' column where each strip starts

' Draw the "sign frames" once; only the text inside changes later.
COLOR 8
FOR r = 6 TO 16 STEP 5
    LOCATE r - 1, LEFTCOL - 1: PRINT CHR$(218); STRING$(W, 196); CHR$(191)
    LOCATE r, LEFTCOL - 1: PRINT CHR$(179); : LOCATE r, LEFTCOL + W: PRINT CHR$(179)
    LOCATE r + 1, LEFTCOL - 1: PRINT CHR$(192); STRING$(W, 196); CHR$(217)
NEXT r
COLOR 15
LOCATE 2, 30: PRINT "THE MARQUEE THEATRE"
COLOR 7
LOCATE 23, 30: PRINT "press any key to stop"

' Doubling the message makes wrapping easy: any window of W
' characters starting inside the first copy is still "whole".
' (We may need several copies if the message is shorter than W.)
big1$ = msg1$: DO WHILE LEN(big1$) < LEN(msg1$) + W: big1$ = big1$ + msg1$: LOOP
big2$ = msg2$: DO WHILE LEN(big2$) < LEN(msg2$) + W: big2$ = big2$ + msg2$: LOOP

p1 = 0            ' scroll position of marquee 1
p2 = 0            ' scroll position of marquee 2
bx = 0: dx = 1    ' bouncing word position and direction
frame = 0
speed = .06       ' seconds between frames

DO
    t = TIMER

    ' --- Marquee 1: moves LEFT, so the start position increases ---
    p1 = (p1 + 1) MOD LEN(msg1$)
    COLOR 14, 1
    LOCATE 6, LEFTCOL: PRINT MID$(big1$, p1 + 1, W);

    ' --- Marquee 2: moves RIGHT, so the start position decreases ---
    p2 = (p2 - 1 + LEN(msg2$)) MOD LEN(msg2$)
    COLOR 11, 0
    LOCATE 11, LEFTCOL: PRINT MID$(big2$, p2 + 1, W);

    ' --- Bouncer: build a line of spaces with the word inside ---
    bx = bx + dx
    IF bx <= 0 OR bx >= W - LEN(bounce$) THEN dx = -dx   ' hit an edge: reverse
    ln$ = SPACE$(bx) + bounce$ + SPACE$(W - LEN(bounce$) - bx)
    COLOR 12, 0
    LOCATE 16, LEFTCOL: PRINT ln$;

    ' --- Chaser lights: every 3rd bulb is lit, and the pattern shifts ---
    frame = frame + 1
    FOR c = 1 TO 79
        IF (c + frame) MOD 3 = 0 THEN COLOR 14 ELSE COLOR 6
        LOCATE 1, c: PRINT CHR$(4);      ' CHR$(4) is a diamond
        ' bottom row runs the opposite direction
        IF (c - frame + 300) MOD 3 = 0 THEN COLOR 14 ELSE COLOR 6
        LOCATE 21, c: PRINT CHR$(4);
    NEXT c

    ' Wait until "speed" seconds have passed since the frame began.
    ' (TIMER wraps at midnight, so also stop waiting if it goes backwards.)
    DO WHILE TIMER - t < speed AND TIMER >= t: LOOP
LOOP WHILE INKEY$ = ""

COLOR 7, 0: CLS
END
