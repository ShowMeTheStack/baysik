' ============================================================
' TITLE:    Screen Capture with BSAVE and BLOAD
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     bsave, bload, video memory, files, binary, screen 13
' SUMMARY:  Save a SCREEN 13 picture as a raw memory dump, inspect the 7-byte BSAVE header, and load it back.
' ------------------------------------------------------------
' WHAT IT DOES
'   BSAVE copies a block of memory straight into a file, and BLOAD
'   copies it back.  Point DEF SEG at video memory and you have an
'   instant screenshot!  In SCREEN 13 the picture is 64000 bytes at
'   &HA000, so one line saves it and one line restores it.
'   The program draws a random scene, saves it, wipes the screen,
'   opens the file in BINARY mode to show you the header BASIC
'   wrote, and then BLOADs the picture back.
'
' HOW TO USE
'   Follow the prompts; press a key at each step.  Esc quits.
'   At the end, D draws a new scene and saves it again.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = &HA000 : BSAVE "file", 0, 64000
'   * BLOAD "file", 0  (offset given = load there, in current DEF SEG)
'   * The BSAVE header: &HFD, segment (2 bytes), offset (2), length (2)
'   * Reading bytes with OPEN ... FOR BINARY and GET
'
' THINGS TO TRY
'   * Save only the top half of the screen (length 32000)
'   * Save the text screen: DEF SEG = &HB800 : BSAVE "TEXT.BSV", 0, 4000
'   * Keep several screenshots and flip through them like a slide show
' ============================================================

DEFINT A-Z
DECLARE SUB Pause ()
CONST PICFILE = "SCENE.BSV"

DIM b AS STRING * 1             ' a 1-byte buffer for GET in BINARY mode
DIM h(1 TO 7)                   ' the 7 header bytes
SCREEN 13
RANDOMIZE TIMER

DO
    GOSUB DrawScene
    LOCATE 1, 1: COLOR 15: PRINT "Original scene. Key = BSAVE it";
    Pause

    ' ---- save: 64000 bytes from A000:0000 -------------------------------
    DEF SEG = &HA000
    BSAVE PICFILE, 0, 64000
    DEF SEG

    ' ---- wipe the screen --------------------------------------------------
    CLS
    LOCATE 2, 1: PRINT "Saved and cleared!"
    PRINT
    ' ---- look inside the file ---------------------------------------------
    OPEN PICFILE FOR BINARY AS #1
    PRINT "File size:"; LOF(1); "bytes"
    PRINT "(64000 picture + 7 header)"
    PRINT
    PRINT "Header bytes:"
    FOR i = 1 TO 7
        GET #1, i, b                     ' byte number i of the file
        h(i) = ASC(b)
        PRINT " byte"; i; "= &H"; HEX$(h(i))
    NEXT i
    CLOSE #1
    PRINT
    PRINT "ID   ="; h(1); "(&HFD means BSAVE)"
    PRINT "Seg  = &H"; HEX$(h(2) + h(3) * 256&)
    PRINT "Off  ="; h(4) + h(5) * 256&
    PRINT "Len  ="; h(6) + h(7) * 256&
    PRINT
    PRINT "Key = BLOAD it back"
    Pause

    ' ---- load it back into video memory ---------------------------------
    DEF SEG = &HA000
    BLOAD PICFILE, 0
    DEF SEG
    LOCATE 1, 1: COLOR 15: PRINT "Restored by BLOAD! D=again Esc=quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "D" OR k$ = CHR$(27)
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
PRINT "Your last picture is still on disk as "; PICFILE
END

' ---- a random landscape: sky, sun, hills, houses --------------------
DrawScene:
    CLS
    FOR y = 0 TO 120                         ' sky gradient (grey ramp 16..31)
        LINE (0, y)-(319, y), 16 + y \ 8
    NEXT y
    CIRCLE (40 + RND * 240, 30 + RND * 30), 15, 44
    PAINT STEP(0, 0), 44
    FOR hx = 0 TO 319 STEP 4                 ' rolling hills
        hy = 120 + 15 * SIN(hx / 30 + RND * .1) + 10 * SIN(hx / 11)
        LINE (hx, hy)-(hx + 3, 199), 2, BF
    NEXT hx
    FOR n = 1 TO 4                           ' a few houses
        x = 20 + RND * 260: y = 150 + RND * 30
        LINE (x, y)-(x + 24, y + 18), 6, BF
        LINE (x - 2, y)-(x + 12, y - 12), 4
        LINE -(x + 26, y), 4
        LINE (x + 9, y + 8)-(x + 15, y + 18), 0, BF
    NEXT n
RETURN

SUB Pause
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
END SUB
