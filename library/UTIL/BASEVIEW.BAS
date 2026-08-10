' ============================================================
' TITLE:    Binary Hex Decimal Viewer
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     binary, hexadecimal, octal, bits, number bases, hex$
' SUMMARY:  See any 16-bit number in decimal, hex, octal and binary at once - and flip its bits one by one.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows one 16-bit value in every common base, plus a row of
'   16 "switches" (bits).  Move the cursor along the bits and
'   flip them to watch the decimal and hex numbers change.  It
'   also shows the value as a SIGNED integer (two's complement)
'   and as an ASCII character for values 32-126.
'
'   Every place in binary is worth twice the one to its right:
'   bit 0 = 1, bit 1 = 2, bit 2 = 4 ... bit 15 = 32768.
'   Each hex digit is exactly 4 bits, which is why programmers
'   like hex: it's a short way to write binary.
'
' HOW TO USE
'   Left/Right  move the bit cursor      Space  flip that bit
'   + / -       add or subtract 1        < / >  shift left/right
'   N           NOT (flip every bit)     E      enter a number
'               (you can type decimal, or &H1F hex, or &O17 octal)
'   Q / Esc     quit
'
' CONCEPTS YOU WILL LEARN
'   * HEX$ and OCT$ built-ins, and building a binary string
'   * Testing a bit with AND, flipping it with XOR
'   * Powers of two: 2 ^ bit
'   * Two's complement: how negative numbers are stored
'   * VAL understands "&H" and "&O" prefixes
'
' THINGS TO TRY
'   * Make it 32 bits wide using LONG (&) variables.
'   * Add AND / OR with a second number and show both.
'   * Show the value as BCD (binary-coded decimal).
' ============================================================

v& = 2026          ' the value, always kept in 0..65535
cur = 0            ' which bit the cursor is on (0 = rightmost)

DO
    CLS
    COLOR 15, 1: PRINT SPACE$(80);: LOCATE 1, 27: PRINT "BINARY / HEX / DECIMAL": COLOR 7, 0

    ' ---- Draw the 16 bits, bit 15 on the LEFT ----
    LOCATE 4, 8: PRINT "bit:";
    FOR b = 15 TO 0 STEP -1
        x = 14 + (15 - b) * 4 - (b < 8) * 2  ' (b < 8) is -1 for the low byte: adds a gap
        LOCATE 4, x: PRINT RIGHT$(" " + LTRIM$(STR$(b)), 2);
        ' Is bit b set?  AND with 2^b leaves only that bit.
        IF v& AND 2 ^ b THEN bit$ = "1": COLOR 14 ELSE bit$ = "0": COLOR 8
        IF b = cur THEN COLOR 0, 7
        LOCATE 5, x: PRINT "["; bit$; "]";
        COLOR 7, 0
    NEXT b
    LOCATE 6, 4: PRINT "place value of cursor bit:"; 2 ^ cur

    ' ---- The number in every base ----
    ' Build binary text by testing each bit from high to low.
    bin$ = ""
    FOR b = 15 TO 0 STEP -1
        IF v& AND 2 ^ b THEN bin$ = bin$ + "1" ELSE bin$ = bin$ + "0"
        IF b MOD 4 = 0 AND b > 0 THEN bin$ = bin$ + " "   ' group by nibble
    NEXT b
    ' Signed: values 32768..65535 stand for -32768..-1.
    IF v& >= 32768 THEN signed& = v& - 65536 ELSE signed& = v&

    LOCATE 9, 10: PRINT "Decimal (unsigned) : "; LTRIM$(STR$(v&))
    LOCATE 10, 10: PRINT "Decimal (signed)   : "; LTRIM$(STR$(signed&))
    LOCATE 11, 10: PRINT "Hexadecimal        : &H"; RIGHT$("000" + HEX$(v&), 4)
    LOCATE 12, 10: PRINT "Octal              : &O"; OCT$(v&)
    LOCATE 13, 10: PRINT "Binary             : "; bin$
    LOCATE 14, 10: PRINT "High byte, low byte: "; v& \ 256; ","; v& MOD 256
    LOCATE 15, 10: PRINT "ASCII (low byte)   : ";
    lb = v& MOD 256
    IF lb >= 32 AND lb <= 126 THEN PRINT CHR$(34); CHR$(lb); CHR$(34) ELSE PRINT "(not printable)"

    LOCATE 19, 4: PRINT "<- -> move   Space flip   + - add/sub 1   < > shift   N not"
    LOCATE 20, 4: PRINT "E enter a number (123, &HFF, &O17)      Q quit"

    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "K": IF cur < 15 THEN cur = cur + 1      ' left = higher bit
        CASE CHR$(0) + "M": IF cur > 0 THEN cur = cur - 1
        CASE " "
            ' XOR flips exactly one bit and leaves the others alone.
            v& = v& XOR (2 ^ cur)
        CASE "+", "=": v& = (v& + 1) MOD 65536
        CASE "-", "_": v& = (v& + 65535) MOD 65536      ' -1, wrapping 0 -> 65535
        CASE "<", ",": v& = (v& * 2) MOD 65536          ' shift left = times 2
        CASE ">", ".": v& = v& \ 2                      ' shift right = divide by 2
        CASE "N": v& = 65535 - v&                       ' NOT for 16 bits
        CASE "E"
            LOCATE 22, 4: LINE INPUT "Value: "; t$
            n& = VAL(UCASE$(LTRIM$(t$)))
            ' Hex like &HFFFF comes back as -1 (a signed integer),
            ' so wrap negatives into 0..65535.
            IF n& < 0 THEN n& = n& + 65536
            IF n& >= 0 AND n& <= 65535 THEN v& = n&
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END
