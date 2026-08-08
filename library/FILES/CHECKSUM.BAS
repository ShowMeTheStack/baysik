' ============================================================
' TITLE:    Checksums: Sum, XOR, Adler-32 and CRC-32
' CATEGORY: File I/O
' LEVEL:    Advanced
' TAGS:     files, binary, checksum, crc32, adler32, bit operations
' SUMMARY:  Compute four kinds of file checksum and watch a single changed byte get caught.
' ------------------------------------------------------------
' WHAT IT DOES
'   A checksum is a small "fingerprint" of a file. If even one bit of
'   the file changes, a good checksum changes too. This program:
'     1. Verifies its CRC-32 code with the official test string
'        "123456789" (the answer must be CBF43926).
'     2. Writes MESSAGE.TXT, fingerprints it, then flips ONE byte and
'        fingerprints it again.
'     3. Shows that the simple checksums can miss a swap of two bytes
'        while Adler-32 and CRC-32 catch it.
'
' HOW TO USE
'   Run it and read the results. Press a key to finish.
'
' CONCEPTS YOU WILL LEARN
'   * Reading a whole file in BINARY mode into a string
'   * AND / OR / XOR on LONG integers as bit operations
'   * A logical (unsigned) right shift using signed LONGs
'   * Table-driven CRC-32, as used by ZIP files and PNG images
'   * Adler-32, as used inside zlib
'
' THINGS TO TRY
'   * Fingerprint a big file and time each method with TIMER.
'   * Add a "verify" mode that stores the CRC in a .CRC file and
'     checks it next time.
' ============================================================

DECLARE FUNCTION ReadAll$ (f$)
DECLARE FUNCTION Crc32& (s$)
DECLARE FUNCTION Hex8$ (v&)
DECLARE SUB Report (title$, s$)

' The CRC-32 table: one precomputed 32-bit value per byte value.
DIM SHARED crcTab(0 TO 255) AS LONG

' ---- Build the table ------------------------------------------
' &HEDB88320 is the famous CRC-32 polynomial written "backwards".
' For each byte value we run 8 rounds of: shift right by one bit,
' and if the bit that fell off was 1, XOR in the polynomial.
' BASIC has no unsigned numbers, so a right shift of a negative LONG
' needs care: we clear the sign bit, divide by 2, then put the old
' sign bit back in as bit 30.
FOR n = 0 TO 255
    c& = n
    FOR k = 1 TO 8
        lowBit = c& AND 1
        shifted& = (c& AND &H7FFFFFFF) \ 2
        IF c& < 0 THEN shifted& = shifted& OR &H40000000
        IF lowBit THEN c& = shifted& XOR &HEDB88320 ELSE c& = shifted&
    NEXT
    crcTab(n) = c&
NEXT

CLS
PRINT "CHECKSUM LAB"
PRINT
PRINT "Self-test: CRC-32 of "; CHR$(34); "123456789"; CHR$(34); " = "; Hex8$(Crc32&("123456789"));
PRINT "   (should be CBF43926)"
PRINT

' ---- Make a file and fingerprint it --------------------------
OPEN "MESSAGE.TXT" FOR OUTPUT AS #1
PRINT #1, "Meet me at the old oak tree at 9 o'clock."
PRINT #1, "Bring the map. Tell no one!"
CLOSE #1
Report "Original MESSAGE.TXT", ReadAll$("MESSAGE.TXT")

' ---- Change ONE byte (9 -> 8) in place, in BINARY mode --------
' (Find the position first: ReadAll$ opens the file itself, and a
' file should not be open twice at the same time.)
p& = INSTR(ReadAll$("MESSAGE.TXT"), "9")
OPEN "MESSAGE.TXT" FOR BINARY AS #1
b$ = "8"
PUT #1, p&, b$
CLOSE #1
Report "One byte changed ('9' -> '8')", ReadAll$("MESSAGE.TXT")

PRINT "Every checksum changed. Press a key for a harder test..."
k$ = INPUT$(1)
CLS

' ---- Swap two bytes: "oak" -> "aok" ---------------------------
s$ = ReadAll$("MESSAGE.TXT")
p& = INSTR(s$, "oak")
MID$(s$, p&, 2) = "ao"
OPEN "MESSAGE.TXT" FOR OUTPUT AS #1: CLOSE #1
OPEN "MESSAGE.TXT" FOR BINARY AS #1: PUT #1, 1, s$: CLOSE #1
Report "Two bytes swapped ('oak' -> 'aok')", ReadAll$("MESSAGE.TXT")

PRINT "Notice: SUM and XOR did not notice the swap, because adding or"
PRINT "XOR-ing the same bytes in any order gives the same answer."
PRINT "Adler-32 and CRC-32 care about ORDER, so they caught it."
PRINT
PRINT "Press a key."
k$ = INPUT$(1)
END

' Table-driven CRC-32 over a string of bytes.
' crc starts as all 1-bits (-1), and is inverted again at the end.
FUNCTION Crc32& (s$)
    crc& = -1
    FOR i = 1 TO LEN(s$)
        idx = (crc& XOR ASC(MID$(s$, i, 1))) AND 255
        ' crc >> 8, done the "unsigned" way as explained above
        sh& = (crc& AND &H7FFFFFFF) \ 256
        IF crc& < 0 THEN sh& = sh& OR &H800000
        crc& = sh& XOR crcTab(idx)
    NEXT
    Crc32& = NOT crc&
END FUNCTION

' 8 hex digits with leading zeros.
FUNCTION Hex8$ (v&)
    Hex8$ = RIGHT$("0000000" + HEX$(v&), 8)
END FUNCTION

' Read a whole file into one string (fine for small files).
FUNCTION ReadAll$ (f$)
    OPEN f$ FOR BINARY AS #7
    s$ = SPACE$(LOF(7))
    GET #7, 1, s$
    CLOSE #7
    ReadAll$ = s$
END FUNCTION

' Print the four fingerprints of s$.
SUB Report (title$, s$)
    sum& = 0: x = 0: a& = 1: b& = 0
    FOR i = 1 TO LEN(s$)
        v = ASC(MID$(s$, i, 1))
        sum& = (sum& + v) AND &HFFFF          ' 16-bit byte sum
        x = x XOR v                            ' 8-bit XOR
        ' Adler-32: two running sums, kept below the prime 65521
        a& = (a& + v) MOD 65521
        b& = (b& + a&) MOD 65521
    NEXT
    COLOR 14: PRINT title$; " -"; LEN(s$); "bytes": COLOR 7
    PRINT "  SUM-16 : "; RIGHT$("000" + HEX$(sum&), 4)
    PRINT "  XOR-8  : "; RIGHT$("0" + HEX$(x), 2)
    ' Adler-32 = b * 65536 + a, which can overflow a LONG, so we
    ' print the two halves side by side instead of multiplying.
    PRINT "  ADLER32: "; RIGHT$("000" + HEX$(b&), 4); RIGHT$("000" + HEX$(a&), 4)
    PRINT "  CRC-32 : "; Hex8$(Crc32&(s$))
    PRINT
END SUB
