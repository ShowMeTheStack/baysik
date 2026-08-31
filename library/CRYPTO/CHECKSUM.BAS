' ============================================================
' TITLE:    Checksum Lab: Sum, Adler-32, CRC-16, CRC-32
' CATEGORY: Codes & Cryptography
' LEVEL:    Advanced
' TAGS:     checksum, CRC, Adler-32, error detection, bitwise, LONG
' SUMMARY:  Computes four checksums of your text and shows which ones catch a flipped bit or swapped letters.
' ------------------------------------------------------------
' WHAT IT DOES
'   A checksum is a short "fingerprint" of some data.  Send the
'   fingerprint along with the data; the receiver recomputes it and
'   if the two differ, something got damaged on the way.
'
'   1. SIMPLE SUM  - add all the bytes, keep the low 16 bits.  Easy,
'      but blind to swapped bytes:  "AB" and "BA" have the same sum.
'
'   2. ADLER-32 (Mark Adler, 1995, used in zlib).  Two running sums
'      modulo 65521 (the largest prime below 65536):
'          a = 1 + all bytes
'          b = sum of every intermediate value of a
'      b depends on the ORDER of bytes, so swaps are caught.
'
'   3. CRC-16 and 4. CRC-32 (Cyclic Redundancy Check, W. Wesley
'      Peterson, 1961).  The data is treated as one giant binary
'      number and DIVIDED by a fixed "polynomial"; the remainder is
'      the checksum.  The division uses XOR instead of subtraction
'      (polynomial arithmetic over GF(2)), so it is just shifts and
'      XORs.  CRC-32 protects every ZIP file, PNG image and Ethernet
'      packet.  It catches ALL single-bit and double-bit errors and
'      every burst of up to 32 wrong bits in a row.
'
'   Checksums are NOT secret codes: anyone can recompute them.  For
'   security you need a cryptographic hash (SHA-256), which is built
'   from the same ingredients - shifts, XOR, addition - just many more.
'
' HOW TO USE
'   Type a line of text (Enter = test string 123456789).  The lab
'   shows the four checksums for: your text, your text with ONE bit
'   flipped, and with two neighbouring letters swapped.  Changed
'   checksums are green (error caught), unchanged ones red (missed).
'   Type Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * LONG integers and the & suffix on hex constants (&HA001&)
'   * Shifting right by dividing by 2 - and the sign-bit problem
'   * XOR, AND and OR on 32-bit values
'   * Why a checksum must care about ORDER
'
' THINGS TO TRY
'   * Known answers for "123456789": CRC-32 = CBF43926,
'     CRC-16/ARC = BB3D.  Adler-32 of "Wikipedia" is 11E60398.
'   * Find two different short strings with the same simple sum
'   * Speed up CRC-32 with a 256-entry lookup table
' ============================================================

DECLARE FUNCTION SumCheck& (t$)
DECLARE FUNCTION Adler$ (t$)
DECLARE FUNCTION Crc16& (t$)
DECLARE FUNCTION Crc32& (t$)
DECLARE FUNCTION ShiftR& (x&)
DECLARE FUNCTION Hex4$ (x&)
DECLARE FUNCTION Hex8$ (x&)

DIM v$(2), r$(2, 3)     ' three versions of the text, four checksums each

DO
    CLS
    COLOR 14: PRINT "CHECKSUM LAB": COLOR 7
    PRINT
    LINE INPUT "Text (Enter = 123456789, Q = quit): "; t$
    IF UCASE$(t$) = "Q" THEN EXIT DO
    IF t$ = "" THEN t$ = "123456789"
    IF LEN(t$) < 2 THEN t$ = t$ + "!"

    ' Version 2: flip the lowest bit of the first character.
    ' (e.g. "1" = 00110001 becomes "0" = 00110000)
    flip$ = t$
    MID$(flip$, 1, 1) = CHR$(ASC(flip$) XOR 1)
    ' Version 3: swap the first two characters (if they differ,
    ' otherwise find a differing pair further along).
    swp$ = t$
    FOR i = 1 TO LEN(t$) - 1
        IF MID$(t$, i, 1) <> MID$(t$, i + 1, 1) THEN
            MID$(swp$, i, 1) = MID$(t$, i + 1, 1)
            MID$(swp$, i + 1, 1) = MID$(t$, i, 1)
            EXIT FOR
        END IF
    NEXT i

    v$(0) = t$: v$(1) = flip$: v$(2) = swp$
    FOR k = 0 TO 2
        r$(k, 0) = Hex4$(SumCheck&(v$(k)))
        r$(k, 1) = Adler$(v$(k))
        r$(k, 2) = Hex4$(Crc16&(v$(k)))
        r$(k, 3) = Hex8$(Crc32&(v$(k)))
    NEXT k

    PRINT
    PRINT "                    Sum16    Adler-32   CRC-16   CRC-32"
    label$ = "Original      Bit flipped   Letters swap  "
    FOR k = 0 TO 2
        COLOR 7: PRINT " "; MID$(label$, k * 14 + 1, 14); "    ";
        FOR j = 0 TO 3
            ' Compare with the original row: green = change detected.
            IF k = 0 THEN
                COLOR 15
            ELSEIF r$(k, j) <> r$(0, j) THEN
                COLOR 10
            ELSE
                COLOR 12
            END IF
            PRINT r$(k, j); "   ";
        NEXT j
        PRINT
    NEXT k
    COLOR 8
    PRINT
    PRINT " original: "; LEFT$(t$, 60)
    PRINT " flipped:  "; LEFT$(flip$, 60)
    PRINT " swapped:  "; LEFT$(swp$, 60)
    COLOR 7
    PRINT
    PRINT " Green = the checksum changed, so the error was DETECTED."
    PRINT " Red   = the checksum stayed the same, the error slipped through."
    PRINT
    PRINT "Press any key...";
    k$ = INPUT$(1)
LOOP
CLS
END

' ------------------------------------------------------------
' Hex4$ / Hex8$: fixed-width hex with leading zeros.
' ------------------------------------------------------------
FUNCTION Hex4$ (x&)
    Hex4$ = RIGHT$("000" + HEX$(x&), 4)
END FUNCTION

FUNCTION Hex8$ (x&)
    Hex8$ = RIGHT$("0000000" + HEX$(x&), 8)
END FUNCTION

' ------------------------------------------------------------
' SumCheck&: add the byte values, keep 16 bits (MOD 65536).
' ------------------------------------------------------------
FUNCTION SumCheck& (t$)
    s& = 0
    FOR i = 1 TO LEN(t$)
        s& = (s& + ASC(MID$(t$, i, 1))) MOD 65536
    NEXT i
    SumCheck& = s&
END FUNCTION

' ------------------------------------------------------------
' Adler$: returns the 8 hex digits.  The real 32-bit value is
' b * 65536 + a, but that can be bigger than a signed LONG can
' hold (2,147,483,647), so we just print b and a side by side.
' ------------------------------------------------------------
FUNCTION Adler$ (t$)
    a& = 1: b& = 0
    FOR i = 1 TO LEN(t$)
        a& = (a& + ASC(MID$(t$, i, 1))) MOD 65521
        b& = (b& + a&) MOD 65521
    NEXT i
    Adler$ = Hex4$(b&) + Hex4$(a&)
END FUNCTION

' ------------------------------------------------------------
' Crc16&: CRC-16/ARC, polynomial x^16 + x^15 + x^2 + 1.
' Written "reflected" (least significant bit first), the
' polynomial is &HA001.  NOTE the & suffix: &HA001 alone would be
' the INTEGER -24575, which as a LONG has 16 extra 1-bits on top!
' For each byte: XOR it into the low 8 bits, then 8 times:
'   if the lowest bit is 1: shift right and XOR the polynomial
'   otherwise:              just shift right
' ------------------------------------------------------------
FUNCTION Crc16& (t$)
    crc& = 0
    FOR i = 1 TO LEN(t$)
        crc& = crc& XOR ASC(MID$(t$, i, 1))
        FOR b = 1 TO 8
            IF crc& AND 1 THEN
                crc& = (crc& \ 2) XOR &HA001&
            ELSE
                crc& = crc& \ 2
            END IF
        NEXT b
    NEXT i
    Crc16& = crc&
END FUNCTION

' ------------------------------------------------------------
' ShiftR&: logical shift right by one bit for a 32-bit value.
' Dividing a NEGATIVE LONG by 2 keeps the sign bit (and rounds),
' which is not what we want.  So: clear the sign bit, divide, then
' put the old sign bit back one place lower (&H40000000).
' (x& < 0) is -1 (all bits set) when true, 0 when false.
' ------------------------------------------------------------
FUNCTION ShiftR& (x&)
    ShiftR& = ((x& AND &H7FFFFFFF) \ 2) OR (&H40000000 AND (x& < 0))
END FUNCTION

' ------------------------------------------------------------
' Crc32&: the CRC used by ZIP and PNG.  Reflected polynomial
' &HEDB88320.  It starts with all 32 bits set (&HFFFFFFFF = -1)
' and inverts the result at the end, so leading zero bytes
' still change the answer.
' ------------------------------------------------------------
FUNCTION Crc32& (t$)
    crc& = -1
    FOR i = 1 TO LEN(t$)
        crc& = crc& XOR ASC(MID$(t$, i, 1))
        FOR b = 1 TO 8
            IF crc& AND 1 THEN
                crc& = ShiftR&(crc&) XOR &HEDB88320
            ELSE
                crc& = ShiftR&(crc&)
            END IF
        NEXT b
    NEXT i
    Crc32& = crc& XOR -1
END FUNCTION
