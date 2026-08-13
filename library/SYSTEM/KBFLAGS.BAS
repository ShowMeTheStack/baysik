' ============================================================
' TITLE:    Keyboard Status Lights (PEEK &H417)
' CATEGORY: System, Events & Hardware
' LEVEL:    Beginner
' TAGS:     peek, poke, bios data area, bits, caps lock, shift
' SUMMARY:  Watch the BIOS keyboard flag byte at 0:0417 light up as you hold Shift, Ctrl, Alt or toggle Caps Lock.
' ------------------------------------------------------------
' WHAT IT DOES
'   The PC BIOS keeps a "data area" in low memory (segment 0).  The
'   byte at address &H417 holds eight on/off flags about the keyboard,
'   one per BIT:
'       bit 0 (1)   Right Shift held     bit 4 (16)  Scroll Lock on
'       bit 1 (2)   Left Shift held      bit 5 (32)  Num Lock on
'       bit 2 (4)   Ctrl held            bit 6 (64)  Caps Lock on
'       bit 3 (8)   Alt held             bit 7 (128) Insert mode on
'   This program PEEKs that byte many times a second and draws each
'   bit as a little lamp.  It can also POKE the byte to switch Caps
'   Lock and Num Lock from software!
'
' HOW TO USE
'   Hold Shift / Ctrl / Alt, press Caps Lock, Num Lock, Insert.
'   Press C to flip Caps Lock by POKE, N to flip Num Lock by POKE.
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = 0 and PEEK / POKE in the BIOS data area
'   * Testing a bit with AND:  IF (flags AND 64) THEN ...
'   * Flipping a bit with XOR: flags XOR 64
'   * Showing a number in binary
'
' THINGS TO TRY
'   * Make a "Caps Lock is on!" warning for a password prompt
'   * Beep whenever Ctrl is pressed
'   * PEEK(&H418) holds more flags on a real PC - look them up
' ============================================================

DEFINT A-Z
DIM nm$(7)
FOR i = 0 TO 7: READ nm$(i): NEXT i
DATA "Right Shift","Left Shift","Ctrl","Alt","Scroll Lock","Num Lock","Caps Lock","Insert"

CLS
COLOR 15: PRINT "BIOS KEYBOARD FLAGS  -  byte at 0000:0417": COLOR 7
PRINT "C = toggle Caps Lock by POKE   N = toggle Num Lock by POKE   Esc = quit"
old = -1

DO
    DEF SEG = 0                      ' segment 0 = the very start of memory
    f = PEEK(&H417)                  ' read the flag byte
    DEF SEG                          ' back to BASIC's own data segment

    IF f <> old THEN                 ' only redraw when something changed
        old = f
        FOR b = 7 TO 0 STEP -1
            mask = 2 ^ b             ' 1, 2, 4, 8 ... 128
            row = 5 + (7 - b) * 2
            LOCATE row, 4
            IF f AND mask THEN       ' is this bit set?
                COLOR 10: PRINT CHR$(219); CHR$(219);    ' lamp ON
            ELSE
                COLOR 8: PRINT CHR$(176); CHR$(176);     ' lamp OFF
            END IF
            COLOR 7
            PRINT USING "  bit #  (value ###)  "; b; mask;
            PRINT nm$(b); SPACE$(12)
        NEXT b

        ' show the whole byte in binary and hex
        bin$ = ""
        FOR b = 7 TO 0 STEP -1
            IF f AND 2 ^ b THEN bin$ = bin$ + "1" ELSE bin$ = bin$ + "0"
        NEXT b
        LOCATE 22, 4: COLOR 14
        PRINT "PEEK(&H417) ="; f; "  binary "; bin$; "  hex &H"; HEX$(f); "    ";
        COLOR 7
    END IF

    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(27) THEN EXIT DO
    IF k$ = "C" OR k$ = "N" THEN
        IF k$ = "C" THEN bit = 64 ELSE bit = 32
        DEF SEG = 0
        POKE &H417, PEEK(&H417) XOR bit   ' flip just that one bit
        DEF SEG
    END IF
LOOP

CLS
PRINT "Last flag value was"; old
END
