' ============================================================
' TITLE:    Video Memory Lab
' CATEGORY: Console & Text
' LEVEL:    Advanced
' TAGS:     def seg, peek, poke, b800, plasma, video memory
' SUMMARY:  Four experiments with text video memory at &HB800: the memory map, a speed race, an attribute plasma and a screen melt.
' ------------------------------------------------------------
' WHAT IT DOES
'   In text mode, what you see on screen is simply a block of memory
'   starting at segment &HB800.  Each cell is 2 bytes:
'       byte 0 = character code     byte 1 = attribute (colour)
'   so cell (row, col) lives at offset ((row-1)*80 + (col-1)) * 2.
'   This lab runs four experiments:
'     1. MAP     - pokes characters to show the address formula
'     2. RACE    - fills the screen with PRINT, then with POKE
'     3. PLASMA  - animates only the COLOUR bytes for a plasma effect
'     4. MELT    - reads the screen with PEEK and lets letters fall
'
' HOW TO USE
'   Press a key to go to the next experiment.  In PLASMA and MELT,
'   any key moves on.  Esc quits at any pause.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = &HB800 to point PEEK/POKE at the screen
'   * The character/attribute byte layout
'   * Precomputed lookup tables (SIN) for fast animation
'   * Treating the screen itself as a data structure
'
' THINGS TO TRY
'   * In PLASMA, change the formula or the colour table.
'   * In MELT, make letters fall upwards, or only vowels fall.
'   * Write a SUB that scrolls one rectangle sideways using PEEK/POKE.
' ============================================================

DEFINT A-Z
DECLARE SUB Pause ()
DECLARE SUB Header (t$)
DIM SHARED quit

SCREEN 0: WIDTH 80, 25

' ===================== 1. THE MEMORY MAP ======================
Header "EXPERIMENT 1: the memory map"
COLOR 7, 0
LOCATE 3, 3: PRINT "offset = ((row - 1) * 80 + (col - 1)) * 2       attribute is at offset + 1"
DEF SEG = &HB800
' Write the letters of "POKE!" diagonally, each in a new colour.
w$ = "POKED!"
FOR i = 1 TO LEN(w$)
    row = 6 + i * 2: col = 10 + i * 9
    ofs = ((row - 1) * 80 + (col - 1)) * 2
    POKE ofs, ASC(MID$(w$, i, 1))          ' the character
    POKE ofs + 1, 16 * i + 15              ' white on background i
    LOCATE row, col + 2: COLOR 8, 0
    PRINT USING "row ## col ## -> offset ####"; row; col; ofs;
NEXT i
DEF SEG
CALL Pause: IF quit THEN GOTO Finish

' ===================== 2. THE SPEED RACE ======================
' Fill 23 rows with a pattern, first using LOCATE + PRINT, then using
' POKE straight into memory.  We time both with TIMER.
Header "EXPERIMENT 2: PRINT versus POKE"
COLOR 14, 0
t! = TIMER
FOR pass = 1 TO 3
    FOR r = 2 TO 24
        FOR c = 1 TO 80 STEP 8
            LOCATE r, c: PRINT CHR$(176 + pass - 1); STRING$(7, 176 + pass - 1);
        NEXT c
    NEXT r
NEXT pass
tPrint! = TIMER - t!

t! = TIMER
DEF SEG = &HB800
FOR pass = 1 TO 3
    FOR ofs = 160 TO 3998 STEP 2       ' row 2 onwards (row 1 = 160 bytes)
        POKE ofs, 176 + pass - 1
        POKE ofs + 1, &H1B             ' light cyan on blue
    NEXT ofs
NEXT pass
DEF SEG
tPoke! = TIMER - t!

COLOR 15, 4
LOCATE 10, 20: PRINT SPACE$(42);
LOCATE 11, 20: PRINT USING "  PRINT took ##.### seconds              "; tPrint!;
LOCATE 12, 20: PRINT USING "  POKE  took ##.### seconds              "; tPoke!;
LOCATE 13, 20: PRINT "  (POKE also set every colour byte!)     ";
LOCATE 14, 20: PRINT SPACE$(42);
CALL Pause: IF quit THEN GOTO Finish

' ===================== 3. ATTRIBUTE PLASMA ======================
' The characters stay the same (a shaded block); only the colour
' bytes change.  Each cell's colour comes from adding up a few sine
' waves that move over time.  SIN is slow, so we compute a table once.
Header "EXPERIMENT 3: plasma (only colour bytes change)"
DIM sn(0 TO 255)
FOR i = 0 TO 255
    sn(i) = INT(SIN(i * 6.2832 / 256) * 63) + 64    ' values 1..127
NEXT i
' Colour ramp: dark to bright and back, foreground + background.
DIM pal(0 TO 15)
FOR i = 0 TO 15: READ pal(i): NEXT i
DATA &H01,&H19,&H13,&H3B,&H3F,&H7F,&H7E,&H6E,&H4E,&H4C,&H45,&H54,&H51,&H15,&H11,&H10

DEF SEG = &HB800
FOR ofs = 160 TO 3998 STEP 2: POKE ofs, 177: NEXT ofs   ' fill with shade char
t = 0
DO
    t = (t + 3) AND 255             ' keep t small so it never overflows
    ofs = 161                           ' first ATTRIBUTE byte of row 2
    FOR r = 0 TO 23
        a = sn((r * 9 + t) AND 255)    ' AND 255 wraps into the table
        FOR c = 0 TO 79
            v = a + sn((c * 6 - t) AND 255) + sn((r * 4 + c * 3 + t * 2) AND 255)
            POKE ofs, pal((v \ 24) AND 15)
            ofs = ofs + 2
        NEXT c
    NEXT r
    k$ = INKEY$
LOOP WHILE k$ = ""
DEF SEG
IF k$ = CHR$(27) THEN GOTO Finish

' ===================== 4. THE MELT ======================
' Put some text on screen, then repeatedly scan the screen from the
' bottom up.  Any character with an empty cell below it moves down
' one row.  We READ the screen with PEEK - the screen IS our data.
Header "EXPERIMENT 4: the melt (PEEK reads the screen)"
COLOR 7, 0
FOR r = 3 TO 12
    LOCATE r, 1
    FOR c = 1 TO 79
        COLOR 9 + (r + c) MOD 7
        PRINT MID$("VIDEOMEMORY*B800*PEEK*POKE*", (r * 3 + c) MOD 27 + 1, 1);
    NEXT c
NEXT r
DEF SEG = &HB800
DO
    moved = 0
    FOR r = 23 TO 3 STEP -1            ' bottom to top, so a letter moves once per sweep
        FOR c = 0 TO 79
            ofs = ((r - 1) * 80 + c) * 2
            below = ofs + 160
            IF PEEK(ofs) <> 32 AND PEEK(below) = 32 THEN
                ' Randomness makes it look like melting, not a block falling.
                IF RND < .5 THEN
                    POKE below, PEEK(ofs): POKE below + 1, PEEK(ofs + 1)
                    POKE ofs, 32
                    moved = 1
                END IF
            END IF
        NEXT c
    NEXT r
    k$ = INKEY$
LOOP UNTIL k$ <> "" OR moved = 0
DEF SEG
IF k$ = "" THEN Pause

Finish:
COLOR 7, 0: CLS
END

' Clear the screen and show a title bar on row 1.
SUB Header (t$)
    COLOR 7, 0: CLS
    COLOR 15, 1: LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 3: PRINT t$;
    LOCATE 1, 60: PRINT "key = next";
    COLOR 7, 0
END SUB

' Wait for a key; Esc sets the shared quit flag.
SUB Pause
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN quit = 1
END SUB
