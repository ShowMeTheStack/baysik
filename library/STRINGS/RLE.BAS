' ============================================================
' TITLE:    Run-Length Encoding
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     compression, RLE, encode, decode, VAL, STR$
' SUMMARY:  Squeezes repeated characters ("AAAABBB" -> "4A3B") and expands them back again.
' ------------------------------------------------------------
' WHAT IT DOES
'   Run-length encoding is one of the simplest ways to compress
'   data.  A "run" is a group of the same character in a row:
'        WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWW
'   becomes
'        12W1B12W3B4W
'   Old fax machines and the PCX picture format used this idea.
'   The program encodes text, decodes it again to prove nothing
'   was lost, and shows the compression ratio.  It also shows a
'   small black-and-white picture stored as RLE in DATA lines.
'
' HOW TO USE
'   Type text to encode (try "aaaaabbbbbbcccccc" and "abcdef").
'   Type a line starting with = to DECODE it instead, e.g. =3A2B5C
'   Empty line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Counting runs by comparing each character with the previous one
'   * Reading numbers made of several digits while decoding
'   * Why compression can make some data BIGGER ("abc" -> "1a1b1c")
'
' THINGS TO TRY
'   * Only write the count when it is bigger than 1 (what breaks
'     if the text contains digits?)
'   * Draw your own RLE picture in the DATA lines
' ============================================================

DECLARE FUNCTION Encode$ (s$)
DECLARE FUNCTION Decode$ (s$)

CLS
COLOR 14: PRINT "RUN-LENGTH ENCODING": COLOR 7
PRINT
' ---- a picture stored as RLE: "." = blank, "#" = block ----
PRINT "A picture stored with RLE (each DATA line is one row):"
DO
    READ row$
    IF row$ = "*" THEN EXIT DO
    pic$ = Decode$(row$)
    PRINT "  "; LEFT$(row$ + SPACE$(16), 16); "  ";
    FOR i = 1 TO LEN(pic$)
        IF MID$(pic$, i, 1) = "#" THEN PRINT CHR$(219); ELSE PRINT " ";
    NEXT i
    PRINT
LOOP
DATA 4.6#4., 3.8#3., 2.2#2.2#2.2#2., 2.10#2., 2.1#1.6#1.1#2.
DATA 2.2#1.4#1.2#2., 3.8#3., 4.6#4., *
PRINT

DO
    LINE INPUT "Text to encode, or =code to decode (Enter = quit): "; t$
    IF t$ = "" OR UCASE$(t$) = "Q" THEN EXIT DO
    IF LEFT$(t$, 1) = "=" THEN
        PRINT "  Decoded: "; Decode$(MID$(t$, 2))
    ELSE
        e$ = Encode$(t$)
        COLOR 11: PRINT "  Encoded: "; e$: COLOR 7
        d$ = Decode$(e$)
        PRINT "  Decoded: "; d$;
        IF d$ = t$ THEN COLOR 10: PRINT "  (matches!)" ELSE COLOR 12: PRINT "  (MISMATCH)"
        COLOR 7
        PRINT USING "  Size: ### -> ### characters (###% of original)"; LEN(t$); LEN(e$); LEN(e$) * 100 / LEN(t$)
    END IF
    PRINT
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' Encode$: walk along the string.  While the next character is
' the same as the current one, keep counting.  When it changes,
' write "count + character" and start a new run.
' Note: digits in the text would confuse the decoder (is "33" a
' count of 33 or a count of 3 of the digit "3"?) - try it!
' ------------------------------------------------------------
FUNCTION Encode$ (s$)
    out$ = ""
    i = 1
    DO WHILE i <= LEN(s$)
        ch$ = MID$(s$, i, 1)
        runLen = 1
        DO WHILE i + runLen <= LEN(s$)
            IF MID$(s$, i + runLen, 1) <> ch$ THEN EXIT DO
            runLen = runLen + 1
        LOOP
        out$ = out$ + LTRIM$(STR$(runLen)) + ch$
        i = i + runLen                   ' jump past the whole run
    LOOP
    Encode$ = out$
END FUNCTION

' ------------------------------------------------------------
' Decode$: collect digits into num$ until we meet a non-digit;
' that character is repeated VAL(num$) times with STRING$.
' A character with no number in front counts once.
' ------------------------------------------------------------
FUNCTION Decode$ (s$)
    out$ = "": num$ = ""
    FOR i = 1 TO LEN(s$)
        ch$ = MID$(s$, i, 1)
        IF ch$ >= "0" AND ch$ <= "9" THEN
            num$ = num$ + ch$
        ELSE
            IF num$ = "" THEN k = 1 ELSE k = VAL(num$)
            IF LEN(out$) + k > 32000 THEN k = 0      ' safety limit
            out$ = out$ + STRING$(k, ch$)
            num$ = ""
        END IF
    NEXT i
    Decode$ = out$
END FUNCTION
