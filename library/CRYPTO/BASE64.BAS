' ============================================================
' TITLE:    Binary, Hex & Base64 Encoder
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     base64, binary, hexadecimal, bits, encoding, email
' SUMMARY:  Shows text as bytes in binary and hex, then regroups the bits 6 at a time to build Base64 - and decodes it again.
' ------------------------------------------------------------
' WHAT IT DOES
'   Computers store every character as a BYTE: 8 bits, a number
'   from 0 to 255.  "A" is 65 = 01000001 in binary = 41 in hex.
'
'   HEXADECIMAL (base 16) writes each byte as exactly two symbols
'   0-9, A-F, because 4 bits = 16 values = one hex digit.
'
'   BASE64 solves an old problem: early e-mail could only carry
'   plain printable characters, so how do you send a picture?
'   Answer (MIME standard, 1992): take the bits 6 at a time instead
'   of 8.  6 bits = 64 values, and we pick 64 safe characters:
'        A-Z (0-25)  a-z (26-51)  0-9 (52-61)  + (62)  / (63)
'   3 bytes = 24 bits = exactly 4 Base64 characters.  If the input
'   doesn't divide into groups of 3, "=" signs pad the end.
'   Base64 is everywhere today: e-mail attachments, web pages with
'   embedded images (data: URLs), and the keys in password files.
'
'   IMPORTANT: Base64 is an ENCODING, not encryption.  Anybody can
'   decode it - it just changes how the data looks.
'
' HOW TO USE
'   1 = encode text (shows the bits being regrouped)
'   2 = decode Base64 back to text
'   Q = quit
'
' CONCEPTS YOU WILL LEARN
'   * Converting numbers to binary strings by repeated division
'   * Bit fields: taking 6 bits out of a 24-bit number with \ and MOD
'   * Lookup with MID$ (encode) and INSTR (decode)
'   * Padding with "="
'
' THINGS TO TRY
'   * Encode "Man" (the classic example) - it becomes TWFu
'   * Encode one letter, two letters, three letters - watch the "="
'   * Write Base32 (5 bits per character, used for 2FA codes)
' ============================================================

DECLARE FUNCTION Bin$ (v, bits)
DECLARE FUNCTION B64Encode$ (t$, showWork%)
DECLARE FUNCTION B64Decode$ (t$)

DIM SHARED alpha$
alpha$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

DO
    CLS
    COLOR 14: PRINT "BINARY, HEX & BASE64": COLOR 7
    PRINT
    PRINT "1) Encode text   2) Decode Base64   Q) Quit"
    LINE INPUT "Choice: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    IF c$ = "Q" OR c$ = CHR$(27) THEN EXIT DO
    IF c$ = "1" THEN
        LINE INPUT "Text: "; t$
        IF t$ = "" THEN t$ = "Man"
        PRINT
        ' ---- Byte table: char, decimal, hex, binary --------------
        PRINT " Char  Dec  Hex  Binary"
        FOR i = 1 TO LEN(t$)
            IF i > 6 THEN PRINT " ... (first 6 shown)": EXIT FOR
            b = ASC(MID$(t$, i, 1))
            PRINT "  "; MID$(t$, i, 1); "  ";
            PRINT USING "####"; b;
            PRINT "   "; RIGHT$("0" + HEX$(b), 2); "   "; Bin$(b, 8)
        NEXT i
        PRINT
        e$ = B64Encode$(t$, 1)
        PRINT
        COLOR 10: PRINT "Base64: "; e$: COLOR 7
        PRINT "Length:"; LEN(t$); "bytes ->"; LEN(e$); "characters (about 4/3 as long)"
    ELSEIF c$ = "2" THEN
        LINE INPUT "Base64: "; t$
        IF t$ = "" THEN t$ = "SGVsbG8sIFdvcmxkIQ=="
        COLOR 10: PRINT "Text: "; B64Decode$(t$): COLOR 7
    ELSE
        PRINT "Choose 1, 2 or Q."
    END IF
    PRINT
    PRINT "Press any key...";
    k$ = INPUT$(1)
LOOP
CLS
END

' ------------------------------------------------------------
' Bin$: write v in binary with exactly bits digits.
' We test bits from the highest down: 2^(bits-1) ... 2^0.
' ------------------------------------------------------------
FUNCTION Bin$ (v, bits)
    r$ = ""
    FOR b = bits - 1 TO 0 STEP -1
        IF v AND 2 ^ b THEN r$ = r$ + "1" ELSE r$ = r$ + "0"
    NEXT b
    Bin$ = r$
END FUNCTION

' ------------------------------------------------------------
' B64Encode$: take 3 bytes at a time and glue them into one 24-bit
' number:  n = b1 * 65536 + b2 * 256 + b3.  (LONG, since it can be
' up to 16,777,215.)  Then cut n into four 6-bit pieces:
'     piece 1 = n \ 262144          (262144 = 2^18)
'     piece 2 = (n \ 4096) MOD 64   (4096 = 2^12)
'     piece 3 = (n \ 64) MOD 64
'     piece 4 = n MOD 64
' Each piece (0-63) picks a character from alpha$.  Missing bytes
' at the end count as 0 and their characters are replaced by "=".
' ------------------------------------------------------------
FUNCTION B64Encode$ (t$, showWork%)
    r$ = ""
    shown = 0
    FOR i = 1 TO LEN(t$) STEP 3
        have = LEN(t$) - i + 1: IF have > 3 THEN have = 3
        b1 = ASC(MID$(t$, i, 1))
        b2 = 0: b3 = 0
        IF have > 1 THEN b2 = ASC(MID$(t$, i + 1, 1))
        IF have > 2 THEN b3 = ASC(MID$(t$, i + 2, 1))
        n& = b1 * 65536& + b2 * 256& + b3
        p1 = n& \ 262144
        p2 = (n& \ 4096) MOD 64
        p3 = (n& \ 64) MOD 64
        p4 = n& MOD 64
        grp$ = MID$(alpha$, p1 + 1, 1) + MID$(alpha$, p2 + 1, 1)
        IF have > 1 THEN grp$ = grp$ + MID$(alpha$, p3 + 1, 1) ELSE grp$ = grp$ + "="
        IF have > 2 THEN grp$ = grp$ + MID$(alpha$, p4 + 1, 1) ELSE grp$ = grp$ + "="
        r$ = r$ + grp$
        IF showWork% AND shown < 2 THEN
            ' Show how 3 x 8 bits become 4 x 6 bits.
            shown = shown + 1
            PRINT "Group"; shown; ": 8-bit bytes  "; Bin$(b1, 8); " "; Bin$(b2, 8); " "; Bin$(b3, 8)
            PRINT "          6-bit pieces ";
            PRINT Bin$(p1, 6); "  "; Bin$(p2, 6); "  "; Bin$(p3, 6); "  "; Bin$(p4, 6)
            PRINT "          values       ";
            PRINT USING "  ##    "; p1; p2; p3; p4;
            PRINT
            PRINT "          characters    ";
            FOR k = 1 TO 4: PRINT "  "; MID$(grp$, k, 1); "     "; : NEXT k
            PRINT
        END IF
    NEXT i
    B64Encode$ = r$
END FUNCTION

' ------------------------------------------------------------
' B64Decode$: the reverse.  INSTR finds each character's value
' (position in alpha$ minus 1).  Four 6-bit values make 24 bits,
' which split back into 3 bytes.  "=" means "no byte here".
' Characters that aren't Base64 (spaces, line breaks) are skipped.
' ------------------------------------------------------------
FUNCTION B64Decode$ (t$)
    r$ = "": n& = 0: cnt = 0: pad = 0
    FOR i = 1 TO LEN(t$)
        ch$ = MID$(t$, i, 1)
        v = INSTR(alpha$, ch$) - 1
        IF ch$ = "=" THEN v = 0: pad = pad + 1
        IF v >= 0 THEN
            n& = n& * 64 + v
            cnt = cnt + 1
            IF cnt = 4 THEN
                r$ = r$ + CHR$(n& \ 65536)
                IF pad < 2 THEN r$ = r$ + CHR$((n& \ 256) MOD 256)
                IF pad < 1 THEN r$ = r$ + CHR$(n& MOD 256)
                n& = 0: cnt = 0
            END IF
        END IF
    NEXT i
    IF cnt <> 0 THEN r$ = r$ + "  (warning: incomplete final group)"
    B64Decode$ = r$
END FUNCTION
