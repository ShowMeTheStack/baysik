' ============================================================
' TITLE:    Steganography: Secrets in the Pixels
' CATEGORY: Codes & Cryptography
' LEVEL:    Advanced
' TAGS:     steganography, least significant bit, SCREEN 13, palette, POINT, PSET
' SUMMARY:  Hides a text message inside the colours of a picture by changing invisible low bits, then digs it back out.
' ------------------------------------------------------------
' WHAT IT DOES
'   CRYPTOGRAPHY hides what a message SAYS.  STEGANOGRAPHY ("covered
'   writing" in Greek) hides that a message EXISTS at all.  The Greek
'   historian Herodotus tells of a messenger whose head was shaved,
'   tattooed with a secret, and sent off once his hair grew back.
'   Later came invisible ink and microdots - and today, pictures.
'
'   THE LSB TRICK: every pixel here has a colour number 0-255.  We
'   set up the palette so colours 2k and 2k+1 look EXACTLY alike.
'   So the LAST BIT (the "least significant bit") of each pixel can
'   hold one bit of secret data without changing the picture at all.
'   Each character = 8 bits = 8 pixels.
'
'   Layout of the hidden data, reading pixels left to right from
'   the top-left corner:
'       first 8 pixels  = the message length (0-255)
'       then 8 pixels per character, highest bit first
'
'   Real tools do the same with photo files, where changing the
'   lowest bit of red, green and blue is invisible to the human eye.
'
' HOW TO USE
'   H = hide a new message (type it at the bottom)
'   R = reveal: read the bits back out of the screen with POINT
'   D = "detective view": a magnified map of the hidden bits of the
'       top 4 rows - white for 1, dark for 0 - so you SEE the secret
'   N = normal picture,  Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Programming the VGA palette with OUT &H3C8 / &H3C9
'   * Reading pixels with POINT and writing them with PSET
'   * Bit manipulation:  (c AND 254) OR bit   and   c AND 1
'   * Splitting a byte into bits with \ and MOD
'
' THINGS TO TRY
'   * Hide the bits every 7th pixel instead of every pixel
'   * Use the last TWO bits per pixel to double the capacity
'   * Encrypt the message (e.g. with XOR) before hiding it
' ============================================================

DECLARE SUB SetPalette ()
DECLARE SUB DrawScene ()
DECLARE SUB HideMsg (m$)
DECLARE FUNCTION RevealMsg$ ()
DECLARE SUB Status (t$)
DECLARE SUB Detective ()

SCREEN 13
SetPalette
secret$ = "Meet at the old oak at midnight. Bring the map!"
DrawScene
HideMsg secret$
Status "H=hide R=reveal D=detect N=norm Q=quit"

DO
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
    CASE "Q", CHR$(27)
        EXIT DO
    CASE "H"
        Status ""
        LOCATE 24, 1: LINE INPUT "Secret: "; t$
        IF LEN(t$) > 0 THEN secret$ = LEFT$(t$, 255)
        DrawScene
        HideMsg secret$
        Status "Hidden" + STR$(LEN(secret$)) + " chars. R=reveal"
    CASE "R"
        found$ = RevealMsg$
        Status ""
        LOCATE 22, 1: PRINT LEFT$(found$, 80);
        LOCATE 25, 1: PRINT "Found"; LEN(found$); "chars. N=clear";
    CASE "D"
        Detective
        Status "Hidden bits: white=1 dark=0. N=normal"
    CASE "N"
        DrawScene
        HideMsg secret$
        Status "H=hide R=reveal D=detect N=norm Q=quit"
    END SELECT
LOOP
SCREEN 0: WIDTH 80
PRINT "The secret was: "; secret$
END

' ------------------------------------------------------------
' Detective: a MAGNIFIED view of the hidden bit layer.
' The first 1280 pixels (4 screen rows) are read with POINT; each
' pixel's last bit is drawn as a small block: white = 1, dark = 0.
' 64 bits per line, with a small gap after every 8 bits, so each
' group of 8 blocks is exactly one hidden character.
' (The very first group is the length byte.)
' ------------------------------------------------------------
SUB Detective
    LINE (8, 18)-(311, 128), 0, BF
    FOR i = 0 TO 1279
        x = i MOD 320: y = i \ 320
        col = i MOD 64
        bx = 12 + col * 4 + (col \ 8) * 3
        by = 22 + (i \ 64) * 5
        IF POINT(x, y) AND 1 THEN c = 255 ELSE c = 192
        LINE (bx, by)-(bx + 2, by + 3), c, BF
    NEXT i
END SUB

' ------------------------------------------------------------
' DrawScene: a landscape using ONLY EVEN colour numbers, so every
' pixel starts with its last bit = 0.  Shade s uses colour s * 2.
'   shades  0-31 sky,  32-63 grass,  64-95 sun,  96-127 rock/text
' ------------------------------------------------------------
SUB DrawScene
    ' Sky: one horizontal line per row, darker at the top.
    FOR y = 0 TO 199
        s = y * 31 \ 199
        LINE (0, y)-(319, y), s * 2
    NEXT y
    ' Sun: for every pixel near the centre, measure its distance d
    ' from the centre and pick a brighter shade for smaller d.
    ' SCREEN 13 pixels are taller than they are wide (about 1.2 : 1),
    ' so y distances are stretched by 1.2 to keep the sun round.
    FOR dy = -20 TO 20
        FOR dx = -24 TO 24
            d = SQR(dx * dx + (dy * 1.2) ^ 2)
            IF d <= 24 THEN PSET (250 + dx, 50 + dy), (95 - INT(d * 31 / 24)) * 2
        NEXT dx
    NEXT dy
    ' Rolling hills: a wavy top edge using SIN; shade gets lighter
    ' towards the bottom of the screen.
    FOR x = 0 TO 319
        top = 130 + SIN(x / 40) * 15 + SIN(x / 13) * 4
        FOR y = top TO 199
            s = 32 + (y - top) \ 3: IF s > 63 THEN s = 63
            PSET (x, y), s * 2
        NEXT y
    NEXT x
END SUB

' ------------------------------------------------------------
' HideMsg: write the length byte, then each character's 8 bits.
' For each bit:  colour = (old AND 254) OR bit
'   AND 254 clears the last bit (254 = 11111110 in binary),
'   OR bit sets it to 0 or 1.
' ------------------------------------------------------------
SUB HideMsg (m$)
    data$ = CHR$(LEN(m$)) + m$
    px& = 0                         ' pixel counter, row by row
    FOR i = 1 TO LEN(data$)
        v = ASC(MID$(data$, i, 1))
        FOR b = 7 TO 0 STEP -1      ' highest bit first
            bit = (v \ 2 ^ b) MOD 2
            x = px& MOD 320: y = px& \ 320
            PSET (x, y), (POINT(x, y) AND 254) OR bit
            px& = px& + 1
        NEXT b
    NEXT i
END SUB

' ------------------------------------------------------------
' RevealMsg$: rebuild each byte from 8 pixels: shift what we have
' left (multiply by 2) and add the next pixel's last bit.
' ------------------------------------------------------------
FUNCTION RevealMsg$
    px& = 0
    r$ = ""
    count = -1                      ' -1 means "length not read yet"
    DO
        v = 0
        FOR b = 1 TO 8
            x = px& MOD 320: y = px& \ 320
            v = v * 2 + (POINT(x, y) AND 1)
            px& = px& + 1
        NEXT b
        IF count = -1 THEN
            count = v
        ELSE
            r$ = r$ + CHR$(v)
        END IF
    LOOP UNTIL LEN(r$) >= count
    RevealMsg$ = r$
END FUNCTION

' ------------------------------------------------------------
' SetPalette: the VGA DAC has 256 entries, each red/green/blue
' 0-63.  OUT &H3C8, n selects entry n; then three OUT &H3C9 calls
' give its red, green and blue.  Entries 2k and 2k+1 get the SAME
' colour, so the lowest bit is invisible.
' ------------------------------------------------------------
SUB SetPalette
    FOR i = 0 TO 255
        s = i \ 2: b = s MOD 32
        SELECT CASE s \ 32
        CASE 0: r = b \ 2: g = 10 + b: bl = 30 + b       ' sky blues
        CASE 1: r = b \ 3: g = 20 + b: bl = b \ 3        ' grass greens
        CASE 2: r = 63: g = 30 + b: bl = b               ' sun yellow
        CASE 3: r = 30 + b: g = 30 + b: bl = 30 + b      ' greys / text
        END SELECT
        IF bl > 63 THEN bl = 63
        OUT &H3C8, i
        OUT &H3C9, r: OUT &H3C9, g: OUT &H3C9, bl
    NEXT i
END SUB

' ------------------------------------------------------------
' Status: a text line at the bottom of the screen.  The text is
' drawn in colour 255 (a light grey with this palette).
' ------------------------------------------------------------
SUB Status (t$)
    COLOR 255
    LOCATE 22, 1: PRINT SPACE$(40);
    LOCATE 23, 1: PRINT SPACE$(40);
    LOCATE 24, 1: PRINT SPACE$(40);
    LOCATE 25, 1: PRINT LEFT$(t$ + SPACE$(39), 39);
END SUB
