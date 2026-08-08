' ============================================================
' TITLE:    File Splitter & Joiner
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, binary, split, join, chunks, file names
' SUMMARY:  Chop a file into numbered pieces of any size, then glue them back together and check nothing was lost.
' ------------------------------------------------------------
' WHAT IT DOES
'   Back when files were carried around on 360 KB floppy disks, big
'   files had to be split into pieces and joined again later. This
'   program does exactly that:
'     * builds BIGFILE.TXT (a numbered poem, about 3 KB)
'     * splits it into BIGFILE.001, BIGFILE.002, ... of N bytes each
'     * joins the pieces into REJOIN.TXT
'     * compares REJOIN.TXT with the original, byte for byte
'   It also shows a second way to split TEXT files: by lines, so no
'   line is ever cut in half.
'
' HOW TO USE
'   Enter a piece size in bytes (Enter = 1000). Press keys as asked.
'
' CONCEPTS YOU WILL LEARN
'   * Making numbered file names: RIGHT$("00" + LTRIM$(STR$(n)), 3)
'   * Reading a file in chunks with GET and a sized buffer
'   * Testing for a file's existence while joining (ON ERROR)
'   * Byte-level vs line-level splitting
'
' THINGS TO TRY
'   * Add a tiny header to each piece: its number and the total.
'   * Split by a marker line, e.g. "---", instead of by size.
' ============================================================

DECLARE FUNCTION PieceName$ (base$, n%)
DECLARE FUNCTION Exists% (f$)

CLS
PRINT "FILE SPLITTER & JOINER"
PRINT
' ---- build the original file -------------------------------------
OPEN "BIGFILE.TXT" FOR OUTPUT AS #1
FOR i = 1 TO 60
    PRINT #1, USING "Line ##: Row, row, row your boat, gently down the stream."; i
NEXT
CLOSE #1
OPEN "BIGFILE.TXT" FOR BINARY AS #1: size& = LOF(1): CLOSE #1
PRINT "Created BIGFILE.TXT:"; size&; "bytes."
PRINT

INPUT "Piece size in bytes (Enter = 1000)"; chunk&
IF chunk& < 1 THEN chunk& = 1000
IF size& \ chunk& > 99 THEN chunk& = size& \ 99 + 1: PRINT "(Too many pieces - using"; chunk&; ")"

' ---- SPLIT by size -------------------------------------------------
OPEN "BIGFILE.TXT" FOR BINARY AS #1
piece = 0: remain& = size&
DO WHILE remain& > 0
    piece = piece + 1
    n& = chunk&: IF remain& < n& THEN n& = remain&
    buf$ = SPACE$(n&)
    GET #1, , buf$                 ' continues where the last GET ended
    f$ = PieceName$("BIGFILE", INT(piece))
    OPEN f$ FOR OUTPUT AS #2: CLOSE #2   ' make sure it starts empty
    OPEN f$ FOR BINARY AS #2
    PUT #2, 1, buf$
    CLOSE #2
    PRINT "  wrote "; f$; n&; "bytes"
    remain& = remain& - n&
LOOP
CLOSE #1
PRINT piece; "pieces made."
PRINT

' ---- JOIN ------------------------------------------------------------
' We do not trust our "piece" count: we keep opening .001, .002 ...
' until one is missing, just like a real joiner would have to.
OPEN "REJOIN.TXT" FOR OUTPUT AS #3: CLOSE #3
OPEN "REJOIN.TXT" FOR BINARY AS #3
p% = 1
DO WHILE Exists%(PieceName$("BIGFILE", p%))
    OPEN PieceName$("BIGFILE", p%) FOR BINARY AS #2
    buf$ = SPACE$(LOF(2))
    GET #2, 1, buf$
    CLOSE #2
    PUT #3, , buf$                 ' append at the current position
    p% = p% + 1
LOOP
CLOSE #3
PRINT "Joined"; p% - 1; "pieces into REJOIN.TXT."

' ---- VERIFY ---------------------------------------------------------
OPEN "BIGFILE.TXT" FOR BINARY AS #1
OPEN "REJOIN.TXT" FOR BINARY AS #2
same = (LOF(1) = LOF(2))
IF same THEN
    a$ = SPACE$(LOF(1)): b$ = SPACE$(LOF(2))
    GET #1, 1, a$: GET #2, 1, b$
    same = (a$ = b$)
END IF
CLOSE #1, #2
IF same THEN PRINT "Verified: identical to the original!" ELSE PRINT "Uh oh - files differ!"
PRINT
PRINT "Notice the pieces cut lines in the middle. Key = see piece 2..."
k$ = INPUT$(1)
CLS
IF Exists%(PieceName$("BIGFILE", 2)) THEN
    PRINT "Start of BIGFILE.002:"
    OPEN "BIGFILE.002" FOR INPUT AS #1
    FOR i = 1 TO 3
        IF NOT EOF(1) THEN LINE INPUT #1, l$: PRINT "  |"; l$
    NEXT
    CLOSE #1
END IF

' ---- SPLIT by lines (text-friendly) --------------------------------
PRINT
PRINT "Splitting by LINES instead: 25 lines per part..."
OPEN "BIGFILE.TXT" FOR INPUT AS #1
part% = 0: count = 25
DO WHILE NOT EOF(1)
    IF count = 25 THEN
        IF part% > 0 THEN CLOSE #2
        part% = part% + 1: count = 0
        OPEN PieceName$("PART", part%) FOR OUTPUT AS #2
    END IF
    LINE INPUT #1, l$
    PRINT #2, l$
    count = count + 1
LOOP
CLOSE
FOR i% = 1 TO part%
    OPEN PieceName$("PART", i%) FOR INPUT AS #1
    LINE INPUT #1, first$
    PRINT "  "; PieceName$("PART", i%); " starts with: "; LEFT$(first$, 30); "..."
    CLOSE #1
NEXT
PRINT
PRINT "Every part starts with a whole line. Press a key."
k$ = INPUT$(1)
END

NoPiece:
    pieceErr = ERR
    RESUME NEXT

FUNCTION Exists% (f$)
    SHARED pieceErr
    pieceErr = 0
    ON ERROR GOTO NoPiece
    OPEN f$ FOR INPUT AS #9
    ON ERROR GOTO 0
    IF pieceErr = 0 THEN CLOSE #9
    Exists% = (pieceErr = 0)
END FUNCTION

' "BIGFILE", 7 -> "BIGFILE.007"  (zero-padded so they sort nicely)
FUNCTION PieceName$ (base$, n%)
    PieceName$ = base$ + "." + RIGHT$("00" + LTRIM$(STR$(n%)), 3)
END FUNCTION
