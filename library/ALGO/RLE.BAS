' ============================================================
' TITLE:    Run-Length Encoding
' CATEGORY: Algorithms
' LEVEL:    Beginner
' TAGS:     compression, strings, encoding, graphics
' SUMMARY:  Squash repeated letters and pixels into (count, value) pairs, then unpack them again - the simplest compression there is.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 draws a little pixel-art picture (stored in DATA lines) in
'   SCREEN 13, encodes each row with RLE and shows how many bytes the
'   compressed picture needs compared with the original.  Then it
'   decodes the RLE data and redraws the picture next to the first
'   one to prove nothing was lost.
'   Part 2 lets you type any text and shows its RLE form, the
'   compression ratio, and the decoded text.
'
' HOW TO USE
'   Press a key after the picture.  Then type lines of text; an empty
'   line quits.  Try "AAAAABBBBBBBBCCCCCC" and then "ABCDEFG".
'
' CONCEPTS YOU WILL LEARN
'   * Run-length encoding: AAAABBC -> 4A 2B 1C
'   * Loss-less compression: decode(encode(x)) = x exactly
'   * Why RLE helps pictures with flat colours but can make normal
'     text BIGGER (every single letter costs 2 bytes!)
'   * Storing numbers in strings with CHR$ and reading them with ASC
'   * O(n) - one pass to encode, one pass to decode
'
' THINGS TO TRY
'   * Draw your own picture in the DATA lines
'   * Improve the format: only write a count when a run is 3 or more
' ============================================================
DECLARE FUNCTION Encode$ (s$)
DECLARE FUNCTION Decode$ (e$)
DECLARE FUNCTION Pretty$ (e$)
DEFINT A-Z
CONST PW = 16, PH = 12            ' picture width and height

' A 16 x 12 picture: each letter is a colour.
'   . = black   Y = yellow   K = dark   R = red   W = white
DATA "......YYYY......"
DATA "....YYYYYYYY...."
DATA "...YYYYYYYYYY..."
DATA "..YYYKKYYKKYYY.."
DATA "..YYYKKYYKKYYY.."
DATA ".YYYYYYYYYYYYYY."
DATA ".YYYYYYYYYYYYYY."
DATA ".YYKYYYYYYYYKYY."
DATA "..YYKKYYYYKKYY.."
DATA "...YYYKKKKYYY..."
DATA "....YYYYYYYY...."
DATA "......YYYY......"
DIM row$(1 TO PH), enc$(1 TO PH)

SCREEN 13
COLOR 15: PRINT "RLE: picture compression": COLOR 7
total = 0
FOR y = 1 TO PH
    READ row$(y)
    enc$(y) = Encode$(row$(y))
    total = total + LEN(enc$(y))
    ' draw the original picture, each pixel as a 5x5 block
    FOR x = 1 TO PW
        SELECT CASE MID$(row$(y), x, 1)
            CASE "Y": c = 14
            CASE "K": c = 6
            CASE "R": c = 12
            CASE "W": c = 15
            CASE ELSE: c = 0
        END SELECT
        LINE (10 + x * 5, 20 + y * 5)-(14 + x * 5, 24 + y * 5), c, BF
    NEXT
NEXT
LINE (14, 24)-(15 + PW * 5 + 5, 25 + PH * 5 + 4), 8, B
' Show a few encoded rows in readable form
LOCATE 12, 1
FOR y = 1 TO 5
    PRINT "row"; y; ":"; Pretty$(enc$(y))
NEXT
PRINT "..."
PRINT "Original:"; PW * PH; "bytes"
PRINT "RLE:     "; total; "bytes"
PRINT USING "Saved ##%"; 100 - total * 100 \ (PW * PH)

' Decode every row and draw it a second time on the right.  If the
' algorithm is correct the two pictures are identical.
ok = -1
FOR y = 1 TO PH
    d$ = Decode$(enc$(y))
    IF d$ <> row$(y) THEN ok = 0
    FOR x = 1 TO LEN(d$)
        SELECT CASE MID$(d$, x, 1)
            CASE "Y": c = 14
            CASE "K": c = 6
            CASE "R": c = 12
            CASE "W": c = 15
            CASE ELSE: c = 0
        END SELECT
        LINE (180 + x * 5, 20 + y * 5)-(184 + x * 5, 24 + y * 5), c, BF
    NEXT
NEXT
LINE (184, 24)-(185 + PW * 5 + 5, 25 + PH * 5 + 4), 8, B
LOCATE 3, 3: PRINT "original";
LOCATE 3, 23: IF ok THEN PRINT "decoded: same!" ELSE PRINT "MISMATCH!"
LOCATE 25, 1: PRINT "Press a key...";
DO: k$ = INKEY$: LOOP WHILE k$ = ""

' ---- Part 2: your own text ----------------------------------------
SCREEN 0: WIDTH 80: CLS
COLOR 15: PRINT "RLE on text  (empty line = quit)": COLOR 7
DO
    PRINT
    LINE INPUT "Text: "; s$
    IF s$ = "" THEN EXIT DO
    e$ = Encode$(s$)
    PRINT "Encoded: "; Pretty$(e$)
    PRINT USING "Size: ### -> ### bytes"; LEN(s$); LEN(e$);
    IF LEN(e$) > LEN(s$) THEN
        COLOR 12: PRINT "  (bigger! too few repeats)": COLOR 7
    ELSE
        COLOR 10: PRINT "  (smaller)": COLOR 7
    END IF
    d$ = Decode$(e$)
    PRINT "Decoded: "; d$; "   ";
    IF d$ = s$ THEN PRINT "(matches)" ELSE PRINT "(MISMATCH)"
LOOP
END

' --------------------------------------------------------------
' Encode: walk along the string.  Count how many times the current
' character repeats, then output TWO bytes: the count (as CHR$) and
' the character.  Runs longer than 255 are split, because one byte
' can only hold 0..255.
' Storing the count as a byte (not as digits) means the format still
' works when the text itself contains digits like "111222".
' --------------------------------------------------------------
FUNCTION Encode$ (s$)
    res$ = ""
    i = 1
    DO WHILE i <= LEN(s$)
        ch$ = MID$(s$, i, 1)
        runLen = 1
        DO WHILE i + runLen <= LEN(s$) AND runLen < 255
            IF MID$(s$, i + runLen, 1) <> ch$ THEN EXIT DO
            runLen = runLen + 1
        LOOP
        res$ = res$ + CHR$(runLen) + ch$
        i = i + runLen                    ' jump past the whole runLen
    LOOP
    Encode$ = res$
END FUNCTION

' Decode: read the pairs back and repeat each character.
FUNCTION Decode$ (e$)
    res$ = ""
    FOR i = 1 TO LEN(e$) - 1 STEP 2
        res$ = res$ + STRING$(ASC(MID$(e$, i, 1)), MID$(e$, i + 1, 1))
    NEXT
    Decode$ = res$
END FUNCTION

' Turns the binary pairs into readable text like "4xA 2xB 1xC".
FUNCTION Pretty$ (e$)
    p$ = ""
    FOR i = 1 TO LEN(e$) - 1 STEP 2
        p$ = p$ + LTRIM$(STR$(ASC(MID$(e$, i, 1)))) + "x" + MID$(e$, i + 1, 1) + " "
    NEXT
    Pretty$ = p$
END FUNCTION
