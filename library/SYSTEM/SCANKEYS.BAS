' ============================================================
' TITLE:    Two-Player Gem Grab (Keyboard Port &H60)
' CATEGORY: System, Events & Hardware
' LEVEL:    Advanced
' TAGS:     inp, port 60h, scan codes, multi-key, two-player, game
' SUMMARY:  Read raw make/break scan codes from keyboard port &H60 so two players can hold keys at the same time.
' ------------------------------------------------------------
' WHAT IT DOES
'   INKEY$ only gives you ONE key at a time, and holding a key gives
'   a slow auto-repeat.  Real DOS games read the keyboard controller
'   directly at I/O port &H60.  Every time a key goes DOWN the port
'   shows its scan code (a "make" code, 1..127); when the key comes
'   UP it shows the scan code + 128 (a "break" code).  By remembering
'   these in an array we always know exactly which keys are held -
'   so two players can share one keyboard smoothly.
'
' HOW TO USE
'   Player 1 (yellow): W A S D        Player 2 (cyan): arrow keys
'   Grab the white gems.  First to 10 wins.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * INP(&H60) and make/break scan codes
'   * A "key held" table: down(scan) = 1 or 0
'   * Emptying the BIOS key buffer with INKEY$ so it never fills up
'   * Simple game loop with fixed frame timing
'
' THINGS TO TRY
'   * Add a "boost" key for each player (Left Shift = 42, Right Shift = 54)
'   * Print the raw INP(&H60) value in a corner to explore other keys
'   * Make the gems move
' ============================================================

DEFINT A-Z
DIM down(127)                  ' 1 while a key is physically held
' scan codes (physical keys, not letters)
CONST KESC = 1, KW = 17, KA = 30, KS = 31, KD = 32
CONST KUP = 72, KLEFT = 75, KRIGHT = 77, KDOWN = 80

SCREEN 13
RANDOMIZE TIMER
x1 = 80: y1 = 100: x2 = 240: y2 = 100: s1 = 0: s2 = 0
GOSUB NewGem
GOSUB DrawScore
LINE (0, 10)-(319, 199), 8, B           ' arena border

DO
    ' ---- 1. read the keyboard port ------------------------------------
    sc = INP(&H60)
    IF sc < 128 THEN
        down(sc) = 1                    ' make code: key went down
    ELSE
        down(sc - 128) = 0              ' break code: key came up
    END IF
    ' Throw away anything in the normal key buffer (so it never beeps
    ' "buffer full") - but still honour Esc typed the normal way.
    k$ = INKEY$
    IF k$ = CHR$(27) OR down(KESC) THEN EXIT DO

    ' ---- 2. move the players (erase, move, redraw) --------------------
    LINE (x1 - 3, y1 - 3)-(x1 + 3, y1 + 3), 0, BF
    LINE (x2 - 3, y2 - 3)-(x2 + 3, y2 + 3), 0, BF
    x1 = x1 + 4 * (down(KD) - down(KA))  ' right minus left: -1, 0 or +1
    y1 = y1 + 4 * (down(KS) - down(KW))
    x2 = x2 + 4 * (down(KRIGHT) - down(KLEFT))
    y2 = y2 + 4 * (down(KDOWN) - down(KUP))
    GOSUB Clamp
    LINE (x1 - 3, y1 - 3)-(x1 + 3, y1 + 3), 14, BF
    LINE (x2 - 3, y2 - 3)-(x2 + 3, y2 + 3), 11, BF
    CIRCLE (gx, gy), 3, 15              ' redraw the gem in case we erased it

    ' ---- 3. gem collisions ---------------------------------------------
    IF ABS(x1 - gx) < 7 AND ABS(y1 - gy) < 7 THEN s1 = s1 + 1: GOSUB Grab
    IF ABS(x2 - gx) < 7 AND ABS(y2 - gy) < 7 THEN s2 = s2 + 1: GOSUB Grab
    IF s1 >= 10 OR s2 >= 10 THEN EXIT DO

    ' ---- 4. show which keys are held (great for learning!) -----------
    LOCATE 25, 1
    PRINT "Port 60h ="; sc; "  ";
    FOR i = 1 TO 4
        READ code, nm$
        IF down(code) THEN COLOR 14 ELSE COLOR 8
        PRINT nm$;
    NEXT i
    FOR i = 1 TO 4
        READ code, nm$
        IF down(code) THEN COLOR 11 ELSE COLOR 8
        PRINT nm$;
    NEXT i
    RESTORE
    COLOR 15

    ' wait for the next clock tick (TIMER changes 18.2 times a second)
    t! = TIMER
    DO WHILE TIMER = t!: LOOP
LOOP

SCREEN 0: WIDTH 80
IF s1 >= 10 THEN PRINT "Player 1 (WASD) wins!"
IF s2 >= 10 THEN PRINT "Player 2 (arrows) wins!"
PRINT "Final score:"; s1; "to"; s2
END

Grab:
    SOUND 1200, 1
    LINE (gx - 3, gy - 3)-(gx + 3, gy + 3), 0, BF
    GOSUB NewGem
    GOSUB DrawScore
RETURN

NewGem:
    gx = 20 + INT(RND * 280): gy = 25 + INT(RND * 160)
    CIRCLE (gx, gy), 3, 15
RETURN

DrawScore:
    LOCATE 1, 1: COLOR 14: PRINT USING "P1: ##"; s1;
    LOCATE 1, 33: COLOR 11: PRINT USING "P2: ##"; s2;
    COLOR 15
RETURN

Clamp:
    IF x1 < 5 THEN x1 = 5
    IF x1 > 314 THEN x1 = 314
    IF y1 < 15 THEN y1 = 15
    IF y1 > 194 THEN y1 = 194
    IF x2 < 5 THEN x2 = 5
    IF x2 > 314 THEN x2 = 314
    IF y2 < 15 THEN y2 = 15
    IF y2 > 194 THEN y2 = 194
RETURN

' scan code / label pairs for the on-screen key display
DATA 17," W",30," A",31," S",32," D"
DATA 72," Up",75," Lt",77," Rt",80," Dn"
