' ============================================================
' TITLE:    Packing Numbers: MKI$, MKL$, MKS$, MKD$
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, binary, MKI$, CVI, MKL$, MKS$, MKD$, bytes
' SUMMARY:  See how numbers are stored as raw bytes, and why binary files are smaller than text.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1: type a number and see its raw bytes when packed as an
'           INTEGER (2 bytes), LONG (4), SINGLE (4) and DOUBLE (8).
'           It unpacks them again with CVI/CVL/CVS/CVD to prove the
'           round trip works (and shows what gets lost!).
'   Part 2: saves the same 500 random numbers as text (PRINT #) and
'           as packed binary (MKI$), then compares the file sizes and
'           reads number #250 directly from the binary file with SEEK.
'
' HOW TO USE
'   Enter numbers to inspect. Press Enter on an empty line to go on
'   to Part 2.
'
' CONCEPTS YOU WILL LEARN
'   * MKx$ turns a number into a short string of raw bytes
'   * CVx turns those bytes back into a number
'   * "Little-endian": the low byte comes first
'   * Two's complement: how negative integers look in memory
'   * Fixed-size binary data lets you jump to item N instantly
'
' THINGS TO TRY
'   * Enter 32767 then 32768. Why does the INTEGER line complain?
'   * Enter 0.1 and compare the SINGLE and DOUBLE results.
' ============================================================

DECLARE FUNCTION HexBytes$ (s$)

CLS
PRINT "PART 1 - what does a number look like inside a file?"
PRINT
DO
    LINE INPUT "Number (Enter = next part): "; t$
    IF t$ = "" THEN EXIT DO
    v# = VAL(t$)
    PRINT

    ' INTEGER holds -32768..32767; anything else would overflow, so
    ' we check before calling MKI$.
    IF v# >= -32768 AND v# <= 32767 THEN
        i$ = MKI$(CINT(v#))
        PRINT "  INTEGER  MKI$ -> "; HexBytes$(i$); TAB(48); "CVI ="; CVI(i$)
    ELSE
        PRINT "  INTEGER  (out of range -32768..32767)"
    END IF
    IF ABS(v#) <= 2147483647# THEN
        l$ = MKL$(CLNG(v#))
        PRINT "  LONG     MKL$ -> "; HexBytes$(l$); TAB(48); "CVL ="; CVL(l$)
    ELSE
        PRINT "  LONG     (out of range)"
    END IF
    s$ = MKS$(CSNG(v#))
    PRINT "  SINGLE   MKS$ -> "; HexBytes$(s$); TAB(48); "CVS ="; CVS(s$)
    d$ = MKD$(v#)
    PRINT "  DOUBLE   MKD$ -> "; HexBytes$(d$); TAB(48); "CVD ="; CVD(d$)
    PRINT
    PRINT "  As text it would be "; LEN(LTRIM$(STR$(v#))) + 2; "bytes (digits + CR LF)."
    PRINT
LOOP

' ---------------------------------------------------------------
CLS
PRINT "PART 2 - text file vs binary file"
PRINT
RANDOMIZE 7          ' fixed seed so the result is the same every run
CONST N = 500
DIM nums(1 TO N) AS INTEGER
FOR i = 1 TO N: nums(i) = INT(RND * 20001) - 10000: NEXT

' Text version: each number becomes digits + CR LF.
OPEN "NUMS.TXT" FOR OUTPUT AS #1
FOR i = 1 TO N: PRINT #1, nums(i): NEXT
CLOSE #1

' Binary version: each number is exactly 2 bytes. PUT # with an
' empty position ("PUT #2, , x$") writes at the current position.
OPEN "NUMS.BIN" FOR BINARY AS #2
FOR i = 1 TO N
    p$ = MKI$(nums(i))
    PUT #2, , p$
NEXT
CLOSE #2

OPEN "NUMS.TXT" FOR INPUT AS #1: tl& = LOF(1): CLOSE #1
OPEN "NUMS.BIN" FOR BINARY AS #2: bl& = LOF(2)
PRINT "  NUMS.TXT :"; tl&; "bytes"
PRINT "  NUMS.BIN :"; bl&; "bytes  ("; INT(100 * bl& / tl&); "% of the text size)"
PRINT

' Random access: number #k lives at byte (k-1)*2 + 1 (files start
' at byte 1 in BASIC). We read 2 bytes into a 2-char string.
k = 250
two$ = SPACE$(2)
GET #2, (k - 1) * 2 + 1, two$
PRINT "  Number #"; LTRIM$(STR$(k)); " read straight from byte"; (k - 1) * 2 + 1; "of NUMS.BIN:"; CVI(two$)
PRINT "  The same number from our array:              "; nums(k)
CLOSE #2

' To find number #250 in the TEXT file we must read 249 lines first!
OPEN "NUMS.TXT" FOR INPUT AS #1
FOR i = 1 TO k: INPUT #1, x: NEXT
CLOSE #1
PRINT "  ...and from NUMS.TXT, after reading"; k; "lines:"; x
PRINT
PRINT "Binary: smaller and faster to jump around in."
PRINT "Text:   readable by humans and by any program."
PRINT
PRINT "Press a key to finish."
k$ = INPUT$(1)
END

' Show each byte of a string as two hex digits, e.g. "DB 07".
FUNCTION HexBytes$ (s$)
    r$ = ""
    FOR i = 1 TO LEN(s$)
        r$ = r$ + RIGHT$("0" + HEX$(ASC(MID$(s$, i, 1))), 2) + " "
    NEXT
    HexBytes$ = r$
END FUNCTION
