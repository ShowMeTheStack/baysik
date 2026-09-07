' ============================================================
' TITLE:    Text Flipbook
' CATEGORY: Animation & Sprites
' LEVEL:    Beginner
' TAGS:     flipbook, DATA, text mode, frames, ASCII art
' SUMMARY:  ASCII-art cartoons stored as DATA frames come to life when flipped quickly, just like a paper flipbook.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every animation is a stack of "pages" (frames) typed into
'   DATA lines as rows of characters.  The program READs them
'   into an array, then shows one frame after another in the
'   same spot.  Flip fast enough and your eyes see movement!
'   You can slow it right down, pause, and step one page at a
'   time to study each drawing.
'
' HOW TO USE
'   1 / 2 / 3   choose a cartoon (jumping jacks, bird, bouncing ball)
'   + / -       faster / slower
'   P           pause; while paused , and . step back / forward
'   B           "bounce" mode: play forward then backward
'   Esc         quit
'
' CONCEPTS YOU WILL LEARN
'   * Storing pictures as text in DATA statements
'   * RESTORE label + READ to load a chosen block of DATA
'   * A 2-D string array: frame$(frame, row)
'   * Forward-and-back ("ping-pong") playback
'   * Timing with TIMER so the speed is the same on any PC
'
' THINGS TO TRY
'   * Add your own cartoon as a 4th DATA block
'   * Make each frame a different color
' ============================================================
DEFINT A-Z
DECLARE SUB LoadToon (n)
DECLARE SUB ShowFrame (f)

DIM SHARED frame$(10, 8), nFrames, nRows, title$
DIM SHARED curF

SCREEN 0: WIDTH 80: CLS
COLOR 14: LOCATE 1, 28: PRINT "~ THE TEXT FLIPBOOK ~"
COLOR 7
LOCATE 22, 8: PRINT "1-3 cartoon   +/- speed   P pause   , . step   B bounce   Esc quit"
' A "paper" page border made of box-drawing characters.
COLOR 15
LOCATE 5, 28: PRINT CHR$(201); STRING$(22, 205); CHR$(187)
FOR r = 6 TO 16
    LOCATE r, 28: PRINT CHR$(186); SPACE$(22); CHR$(186)
NEXT
LOCATE 17, 28: PRINT CHR$(200); STRING$(22, 205); CHR$(188)

LoadToon 1
delay! = .15: paused = 0: bounce = 0: dirn = 1
nextT! = TIMER

DO
    ' Advance to the next frame when it is time (and not paused).
    IF NOT paused AND TIMER >= nextT! THEN
        nextT! = TIMER + delay!
        IF bounce THEN
            ' Ping-pong: reverse direction at either end.
            IF curF + dirn >= nFrames OR curF + dirn < 0 THEN dirn = -dirn
            curF = curF + dirn
        ELSE
            curF = (curF + 1) MOD nFrames
        END IF
        ShowFrame curF
    END IF
    ' Guard against TIMER resetting at midnight.
    IF nextT! - TIMER > 5 THEN nextT! = TIMER

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "1" TO "3": LoadToon VAL(k$)
        CASE "+", "=": IF delay! > .04 THEN delay! = delay! - .03
        CASE "-": IF delay! < 1 THEN delay! = delay! + .03
        CASE "P": paused = NOT paused
        CASE "B": bounce = NOT bounce
        CASE ".": IF paused THEN curF = (curF + 1) MOD nFrames: ShowFrame curF
        CASE ",": IF paused THEN curF = (curF + nFrames - 1) MOD nFrames: ShowFrame curF
    END SELECT
    IF k$ <> "" THEN
        COLOR 11: LOCATE 19, 28
        PRINT USING "speed: ##.## s/frame"; delay!;
        IF paused THEN PRINT " PAUSED"; ELSE PRINT "       ";
    END IF
LOOP UNTIL k$ = CHR$(27)

COLOR 7: CLS
END

' ---- The cartoons --------------------------------------------
' Each block: title, number of frames, rows per frame, then rows.
Toon1:
DATA "Jumping Jacks", 4, 6
DATA "    O    ","   /|\   ","  / | \  ","    |    ","   / \   ","  /   \  "
DATA "    O    ","  --|--  ","    |    ","    |    ","   / \   ","  /   \  "
DATA " \  O  / ","  \ | /  ","   \|/   ","    |    ","  /   \  "," /     \ "
DATA "         ","    O    ","  --|--  ","    |    ","   / \   ","  |   |  "
Toon2:
DATA "Flapping Bird", 4, 5
DATA "\       /"," \  _  / ","  \(o)/  ","   \_/   ","         "
DATA "         "," \_ _ _/ ","   (o)   ","   \_/   ","         "
DATA "         ","    _    "," __(o)__ "," / \_/ \ ","         "
DATA "         ","    _    ","  _(o)_  "," / \_/ \ ","/       \"
Toon3:
DATA "Bouncing Ball", 6, 8
DATA "   ___   ","  /   \  ","  \___/  ","         ","         ","         ","         ","_________"
DATA "         ","         ","   ___   ","  /   \  ","  \___/  ","         ","         ","_________"
DATA "         ","         ","         ","         ","   ___   ","  /   \  ","  \___/  ","_________"
DATA "         ","         ","         ","         ","         ","  _____  "," (_____) ","_________"
DATA "         ","         ","         ","         ","   ___   ","  /   \  ","  \___/  ","_________"
DATA "         ","         ","   ___   ","  /   \  ","  \___/  ","         ","         ","_________"

SUB LoadToon (n)
    SELECT CASE n
        CASE 1: RESTORE Toon1
        CASE 2: RESTORE Toon2
        CASE 3: RESTORE Toon3
    END SELECT
    READ title$, nFrames, nRows
    FOR f = 0 TO nFrames - 1
        FOR r = 0 TO nRows - 1
            READ frame$(f, r)
        NEXT
    NEXT
    ' Clear the page and show the title.
    FOR r = 6 TO 16: LOCATE r, 29: PRINT SPACE$(22); : NEXT
    COLOR 10: LOCATE 3, 1: PRINT SPACE$(80);
    LOCATE 3, 40 - LEN(title$) \ 2: PRINT title$;
    curF = 0: ShowFrame 0
END SUB

SUB ShowFrame (f)
    ' Draw every row of frame f centred on the page, then the
    ' page number in the corner like a real flipbook.
    COLOR 15
    top = 11 - nRows \ 2
    FOR r = 0 TO nRows - 1
        LOCATE top + r, 35: PRINT frame$(f, r);
    NEXT
    COLOR 8: LOCATE 16, 43: PRINT USING "page ##"; f + 1;
END SUB
