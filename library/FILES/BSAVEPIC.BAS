' ============================================================
' TITLE:    Save & Load a Picture with BSAVE / BLOAD
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, BSAVE, BLOAD, SCREEN 13, DEF SEG, video memory, graphics
' SUMMARY:  Paint a SCREEN 13 picture, dump the video memory to disk with BSAVE, and bring it back with BLOAD.
' ------------------------------------------------------------
' WHAT IT DOES
'   In SCREEN 13 (320x200, 256 colours) every pixel is one byte in
'   video memory, starting at segment &HA000. 320 * 200 = 64000 bytes.
'   BSAVE copies a block of memory straight into a file, and BLOAD
'   copies it back - the fastest way to save a whole screen.
'   The program draws a sunset scene, saves it as SUNSET.PIC, wipes
'   the screen with noise, then loads the picture back. It also saves
'   the palette to SUNSET.PAL so the colours come back too.
'
' HOW TO USE
'   Press a key at each stage: draw -> save -> scramble -> load.
'   Esc at any prompt quits.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = &HA000 to point at video memory
'   * BSAVE file, offset, length  and  BLOAD file, offset
'   * PEEK/POKE on video memory: one byte = one pixel
'   * Reading/writing the VGA palette with OUT &H3C8/&H3C9, INP &H3C9
'   * Storing the palette in a small BINARY file
'
' THINGS TO TRY
'   * BSAVE only the top half: length 32000.
'   * BLOAD the picture at offset 3200 to shift it down 10 lines.
' ============================================================

DECLARE SUB WaitKey (msg$)

SCREEN 13
' ---- 1. a custom palette: colours 16..79 fade orange -> purple --
' Port &H3C8 picks the first colour number to change, then each
' colour takes three writes to &H3C9: red, green, blue (0..63).
FOR i = 0 TO 63
    OUT &H3C8, 16 + i
    OUT &H3C9, 63 - i \ 3          ' red fades a little
    OUT &H3C9, 40 - (i * 40) \ 63  ' green fades out
    OUT &H3C9, i \ 2               ' blue rises
NEXT

' ---- 2. draw the scene -----------------------------------------
' Sky: horizontal stripes from colour 16 (top) to 79 (horizon).
FOR y = 0 TO 139
    LINE (0, y)-(319, y), 16 + (y * 63) \ 139
NEXT
CIRCLE (160, 130), 40, 14: PAINT (160, 120), 14, 14   ' the sun
LINE (0, 140)-(319, 191), 1, BF                       ' the sea
' (Rows 192-199 = text line 25 are kept for our messages.)
' Sun reflections on the water: short yellow dashes.
RANDOMIZE 3
FOR i = 1 TO 120
    y = 142 + RND * 48
    w = 30 - (y - 140) / 3
    x = 160 + (RND - .5) * w * 2
    LINE (x, y)-(x + 4, y), 14
NEXT
' Two little birds drawn with DRAW.
PSET (80, 50), 0: DRAW "C0 E4 F4 E4 F4"
PSET (230, 30), 0: DRAW "C0 E3 F3 E3 F3"
COLOR 15: LOCATE 2, 2: PRINT "SUNSET.PIC"
WaitKey "Picture drawn. Key = save it"

' ---- 3. save it ------------------------------------------------
DEF SEG = &HA000            ' memory segment of SCREEN 13 pixels
BSAVE "SUNSET.PIC", 0, 64000
' Also save the 256-colour palette (768 bytes) so it looks right
' when loaded later, even by another program.
OPEN "SUNSET.PAL" FOR OUTPUT AS #1: CLOSE #1
OPEN "SUNSET.PAL" FOR BINARY AS #1
OUT &H3C7, 0                ' &H3C7 = start READING at colour 0
pal$ = ""
FOR i = 0 TO 767: pal$ = pal$ + CHR$(INP(&H3C9)): NEXT
PUT #1, 1, pal$
CLOSE #1
OPEN "SUNSET.PIC" FOR BINARY AS #1: sz& = LOF(1): CLOSE #1
WaitKey "Saved" + STR$(sz&) + " bytes. Key = scramble"

' ---- 4. destroy the screen and the palette ---------------------
FOR i = 1 TO 6000
    PSET (RND * 319, RND * 199), RND * 255
NEXT
FOR i = 16 TO 79                        ' turn the sky colours grey
    OUT &H3C8, i: OUT &H3C9, 20: OUT &H3C9, 20: OUT &H3C9, 20
NEXT
WaitKey "Scrambled! Key = BLOAD it back"

' ---- 5. load it back -------------------------------------------
DEF SEG = &HA000
BLOAD "SUNSET.PIC", 0      ' bytes go straight back into video RAM
OPEN "SUNSET.PAL" FOR BINARY AS #1
pal$ = SPACE$(768)
GET #1, 1, pal$
CLOSE #1
OUT &H3C8, 0
FOR i = 1 TO 768: OUT &H3C9, ASC(MID$(pal$, i, 1)): NEXT
DEF SEG                    ' back to BASIC's own data segment

' Prove that PEEK sees the same pixel the screen shows.
DEF SEG = &HA000
p = PEEK(130& * 320 + 160)
DEF SEG
WaitKey "Restored! Pixel(160,130)=" + LTRIM$(STR$(p)) + "  Key=end"
SCREEN 0: WIDTH 80
PRINT "Files written:"
PRINT "  SUNSET.PIC -"; sz&; "bytes (64000 pixels + a 7-byte BSAVE header)"
PRINT "  SUNSET.PAL - 768 bytes (256 colours x red, green, blue)"
END

' Show a message on the bottom line and wait for a key.
SUB WaitKey (msg$)
    LOCATE 25, 1: COLOR 15: PRINT LEFT$(msg$ + SPACE$(39), 39);
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
    LOCATE 25, 1: PRINT SPACE$(39);
END SUB
