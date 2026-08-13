' ============================================================
' TITLE:    Text Video Memory at B800
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     def seg, peek, poke, video memory, attributes, text mode
' SUMMARY:  POKE characters and colour attributes straight into the text screen at segment &HB800.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 80x25 colour text mode the whole screen lives in memory at
'   segment &HB800.  Each character cell uses TWO bytes:
'       even offset : the character code (ASCII)
'       odd offset  : the attribute = background*16 + foreground
'                     (+128 for blinking)
'   Cell (row r, column c), counting from 0, starts at offset
'       (r * 80 + c) * 2
'   PRINT never needs to be involved - we write memory, and the video
'   card shows it.  Five little demos show what you can do with that.
'
' HOW TO USE
'   Press a key to go to the next demo.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = &HB800, POKE offset, value
'   * The character/attribute byte pairs of text mode
'   * Changing colours WITHOUT reprinting text (attribute-only pokes)
'   * Reading the screen back with PEEK ("screen scraping")
'
' THINGS TO TRY
'   * Write a SUB that draws a shadow under any rectangle
'   * Make a scrolling marquee by shifting bytes left
'   * Find out what offset 4000 and up holds (hint: page 1, see PCOPY)
' ============================================================

DEFINT A-Z
DECLARE SUB WaitKey ()
DECLARE SUB Title (t$)
SCREEN 0: WIDTH 80, 25
DEF SEG = &HB800                 ' every PEEK/POKE now talks to the text screen

' ---- Demo 1: fill the screen with POKE ---------------------------------
CLS
FOR cell = 0 TO 1999             ' 80*25 = 2000 cells
    POKE cell * 2, 65 + (cell MOD 26)       ' letters A..Z
    POKE cell * 2 + 1, 1 + (cell MOD 15)    ' foreground 1..15 on black
NEXT cell
Title "Demo 1: 2000 cells filled by POKE (no PRINT at all)"
WaitKey

' ---- Demo 2: rainbow sweep - change ONLY the attribute bytes ----------
FOR shift = 0 TO 63
    FOR r = 0 TO 24
        a = ((r + shift) MOD 7 + 1) * 16 + 15   ' background colour band, white text
        rowOff = r * 160
        FOR c = 0 TO 79
            POKE rowOff + c * 2 + 1, a            ' odd byte = attribute
        NEXT c
    NEXT r
    IF INKEY$ = CHR$(27) THEN EXIT FOR
NEXT shift
Title "Demo 2: only attribute bytes changed - the letters never moved"
WaitKey

' ---- Demo 3: a window with a drop shadow ------------------------------
CLS
FOR cell = 0 TO 1999
    POKE cell * 2, 177: POKE cell * 2 + 1, &H17   ' blue desktop pattern
NEXT cell
FOR r = 6 TO 15
    FOR c = 20 TO 59
        POKE (r * 80 + c) * 2, 32: POKE (r * 80 + c) * 2 + 1, &H70  ' grey box
    NEXT c
NEXT r
' the shadow: keep the characters, but set attribute to dark grey on black
FOR r = 7 TO 16
    FOR c = 60 TO 61: POKE (r * 80 + c) * 2 + 1, 8: NEXT c
NEXT r
FOR c = 22 TO 61: POKE (16 * 80 + c) * 2 + 1, 8: NEXT c
msg$ = "Shadows are just attribute 8!"
FOR i = 1 TO LEN(msg$)
    POKE (10 * 80 + 24 + i) * 2, ASC(MID$(msg$, i, 1))
NEXT i
Title "Demo 3: a dialog box with a drop shadow"
WaitKey

' ---- Demo 4: blinking (attribute bit 7) ---------------------------------
msg$ = "  BLINK BIT = 128  "
FOR i = 1 TO LEN(msg$)
    o = (12 * 80 + 29 + i) * 2
    POKE o, ASC(MID$(msg$, i, 1))
    POKE o + 1, 128 + &H4E          ' blinking yellow on red
NEXT i
Title "Demo 4: attribute + 128 makes text blink"
WaitKey

' ---- Demo 5: read the screen back with PEEK ---------------------------
CLS
PRINT "This line was written with PRINT."
PRINT "Now we PEEK it back, one byte pair at a time:"
s$ = ""
FOR c = 0 TO 32
    s$ = s$ + CHR$(PEEK(c * 2))      ' row 0, even bytes = characters
NEXT c
LOCATE 4, 1
PRINT "Characters read: "; s$
PRINT "Attribute of first cell ="; PEEK(1); "(7 = grey on black)"
PRINT
PRINT "First 8 raw bytes: ";
FOR i = 0 TO 7: PRINT PEEK(i); : NEXT i
PRINT : PRINT : PRINT "Press a key to finish."
WaitKey
DEF SEG                              ' back to BASIC's data segment
COLOR 7, 0: CLS
PRINT "Done."
END

' Write a title in the top line directly into video memory.
SUB Title (t$)
    FOR c = 0 TO 79
        POKE c * 2, 32: POKE c * 2 + 1, &H1F        ' white on blue bar
    NEXT c
    FOR i = 1 TO LEN(t$)
        POKE (i) * 2, ASC(MID$(t$, i, 1))
    NEXT i
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN DEF SEG: COLOR 7, 0: CLS : END
END SUB
