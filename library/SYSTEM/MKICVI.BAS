' ============================================================
' TITLE:    MKI$ / CVI Byte Layout Explorer
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     mki$, cvi, mkl$, cvl, mks$, cvs, mkd$, binary data, packing
' SUMMARY:  Turn numbers into the raw byte strings BASIC stores on disk, look at every byte, and pack a score table.
' ------------------------------------------------------------
' WHAT IT DOES
'   Random-access files store numbers as raw bytes, not as text.
'   The MK..$ functions turn a number into that byte string and the
'   CV.. functions turn it back:
'       MKI$(n%)  -> 2 bytes     CVI(s$)  -> INTEGER
'       MKL$(n&)  -> 4 bytes     CVL(s$)  -> LONG
'       MKS$(n!)  -> 4 bytes     CVS(s$)  -> SINGLE
'       MKD$(n#)  -> 8 bytes     CVD(s$)  -> DOUBLE
'   Part 1 lets you type numbers and see their bytes.
'   Part 2 packs a high-score table into ONE compact string (6 bytes
'   per entry), writes it to a file, reads it back and unpacks it.
'
' HOW TO USE
'   Part 1: type numbers, Enter on an empty line (or Q) moves on.
'   Part 2 runs by itself.
'
' CONCEPTS YOU WILL LEARN
'   * Fixed-size binary encoding of numbers
'   * Little-endian byte order (low byte first)
'   * Packing several fields into one string and slicing with MID$
'   * Why "1000000" as text needs 7 bytes but MKL$ needs only 4
'
' THINGS TO TRY
'   * Add the player's initials (3 bytes) to each packed record
'   * Compare the file size of the packed table with a PRINT # version
'   * Feed CVI a string made with CHR$: CVI(CHR$(1) + CHR$(1)) = 257
' ============================================================

DEFINT A-Z
DECLARE FUNCTION HexBytes$ (s$)

CLS
PRINT "PART 1 - what do numbers look like as bytes?"
PRINT STRING$(60, 196)
DO
    LINE INPUT "Number (Enter or Q = next part): "; t$
    t$ = UCASE$(LTRIM$(RTRIM$(t$)))
    IF t$ = "" OR t$ = "Q" THEN EXIT DO
    v# = VAL(t$)
    IF v# = INT(v#) AND v# >= -32768 AND v# <= 32767 THEN
        s$ = MKI$(v#)
        PRINT "  MKI$ ->"; HexBytes$(s$); "  back with CVI ="; CVI(s$)
    END IF
    IF v# = INT(v#) AND ABS(v#) < 2147483647# THEN
        s$ = MKL$(v#)
        PRINT "  MKL$ ->"; HexBytes$(s$); "  back with CVL ="; CVL(s$)
    END IF
    IF ABS(v#) < 1E+38 THEN
        s$ = MKS$(v#)
        PRINT "  MKS$ ->"; HexBytes$(s$); "  back with CVS ="; CVS(s$)
    END IF
    s$ = MKD$(v#)
    PRINT "  MKD$ ->"; HexBytes$(s$); "  back with CVD ="; CVD(s$)
    PRINT "  As text, "; t$; " needs"; LEN(t$); "bytes."
    PRINT
LOOP

' ---- PART 2: pack a table into one string ---------------------------
PRINT
PRINT "PART 2 - packing a high-score table"
PRINT STRING$(60, 196)
' each record = level (INTEGER, 2 bytes) + score (LONG, 4 bytes)
packed$ = ""
FOR i = 1 TO 5
    READ lvl, sc&
    packed$ = packed$ + MKI$(lvl) + MKL$(sc&)
NEXT i
DATA 3, 12500, 7, 98000, 12, 1500000, 1, 450, 9, 333333
PRINT "5 records packed into"; LEN(packed$); "bytes:"
PRINT HexBytes$(LEFT$(packed$, 18)); " ..."

' save it as a raw binary file
OPEN "SCORES.BIN" FOR OUTPUT AS #1: CLOSE #1   ' make sure it is empty
OPEN "SCORES.BIN" FOR BINARY AS #1
PUT #1, 1, packed$
CLOSE #1

' read it back into a string of the right length
OPEN "SCORES.BIN" FOR BINARY AS #1
back$ = SPACE$(LOF(1))           ' GET fills a string of this length
GET #1, 1, back$
CLOSE #1
PRINT "Read back"; LEN(back$); "bytes from SCORES.BIN"
PRINT
PRINT " #  Level      Score"
FOR i = 0 TO LEN(back$) \ 6 - 1
    rec$ = MID$(back$, i * 6 + 1, 6)       ' slice one record
    PRINT USING " #  #####  #########"; i + 1; CVI(LEFT$(rec$, 2)); CVL(MID$(rec$, 3, 4))
NEXT i
PRINT
PRINT "Fun fact: CVI(CHR$(1) + CHR$(1)) ="; CVI(CHR$(1) + CHR$(1)); "(1 + 1*256)"
END

' Show every byte of a string as two hex digits.
FUNCTION HexBytes$ (s$)
    h$ = ""
    FOR i = 1 TO LEN(s$)
        h$ = h$ + " " + RIGHT$("0" + HEX$(ASC(MID$(s$, i, 1))), 2)
    NEXT i
    HexBytes$ = h$
END FUNCTION
