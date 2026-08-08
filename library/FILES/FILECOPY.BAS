' ============================================================
' TITLE:    File Copier with Progress Bar
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, binary, copy, buffers, progress bar
' SUMMARY:  Copy any file byte-for-byte using a buffer, with a live progress bar.
' ------------------------------------------------------------
' WHAT IT DOES
'   Copies a source file to a destination file in BINARY mode, a
'   block (buffer) at a time, which is how real copy programs work.
'   A progress bar shows how far along it is. At the end it re-reads
'   both files to verify the copy is perfect.
'   If you just press Enter it builds a 20 KB demo file first.
'
' HOW TO USE
'   Type a source name (or Enter for the demo) and a destination name
'   (or Enter for COPY.BIN). If the destination exists you are asked
'   before it is overwritten.
'
' CONCEPTS YOU WILL LEARN
'   * Reading/writing blocks with GET/PUT and a string buffer
'   * Handling the last, smaller block at the end of the file
'   * Why bigger buffers mean fewer disk operations
'   * A text-mode progress bar with LOCATE and CHR$(219)
'
' THINGS TO TRY
'   * Change BUFSIZE to 1 and then to 8192. Count the blocks.
'   * Make it refuse to copy a file onto itself.
' ============================================================

DECLARE FUNCTION Exists% (f$)

CONST BUFSIZE = 1024      ' bytes moved per GET/PUT

CLS
PRINT "FILE COPIER"
PRINT
LINE INPUT "Source file (Enter = make DEMO.BIN): "; src$
IF src$ = "" THEN
    src$ = "DEMO.BIN"
    PRINT "Building a 20000-byte demo file..."
    ' Any byte pattern will do; this one is easy to verify by eye.
    OPEN src$ FOR OUTPUT AS #1: CLOSE #1        ' start empty
    OPEN src$ FOR BINARY AS #1
    chunk$ = ""
    FOR i = 0 TO 199: chunk$ = chunk$ + CHR$((i * 7) AND 255): NEXT
    FOR i = 1 TO 100: PUT #1, , chunk$: NEXT
    CLOSE #1
END IF
IF NOT Exists%(src$) THEN PRINT "Source "; src$; " not found.": END

LINE INPUT "Destination (Enter = COPY.BIN): "; dst$
IF dst$ = "" THEN dst$ = "COPY.BIN"
IF UCASE$(dst$) = UCASE$(src$) THEN PRINT "Cannot copy a file onto itself!": END
IF Exists%(dst$) THEN
    PRINT dst$; " already exists. Overwrite (Y/N)? ";
    IF UCASE$(INPUT$(1)) <> "Y" THEN PRINT "Cancelled.": END
    PRINT
    KILL dst$             ' delete it, so a shorter copy leaves no junk
END IF

OPEN src$ FOR BINARY AS #1
OPEN dst$ FOR BINARY AS #2
total& = LOF(1)
PRINT
PRINT "Copying"; total&; "bytes in blocks of"; BUFSIZE; "..."
row = CSRLIN + 1
LOCATE row, 1: PRINT "[" + STRING$(50, 176) + "]"

done& = 0: blocks = 0
DO WHILE done& < total&
    ' The last block is usually smaller than BUFSIZE.
    n& = total& - done&
    IF n& > BUFSIZE THEN n& = BUFSIZE
    ' GET into a string reads exactly LEN(string) bytes, so we size
    ' the buffer first with SPACE$.
    buf$ = SPACE$(n&)
    GET #1, , buf$
    PUT #2, , buf$
    done& = done& + n&
    blocks = blocks + 1
    ' Fill the bar proportionally: 50 cells for 100%.
    cells = INT(50 * done& / total&)
    LOCATE row, 2: PRINT STRING$(cells, 219);
    LOCATE row, 54: PRINT USING "###%"; 100 * done& / total&
LOOP
CLOSE #1, #2

' ---- Verify: compare both files block by block -----------------
PRINT
PRINT "Copied in"; blocks; "blocks. Verifying..."
OPEN src$ FOR BINARY AS #1
OPEN dst$ FOR BINARY AS #2
ok = (LOF(1) = LOF(2))
IF ok THEN
    DO WHILE NOT EOF(1) AND ok
        n& = LOF(1) - LOC(1)                ' bytes still to read
        IF n& > BUFSIZE THEN n& = BUFSIZE
        IF n& <= 0 THEN EXIT DO
        a$ = SPACE$(n&): b$ = SPACE$(n&)
        GET #1, , a$: GET #2, , b$
        IF a$ <> b$ THEN ok = 0
    LOOP
END IF
CLOSE
IF ok THEN PRINT "Verified: "; dst$; " is identical to "; src$ ELSE PRINT "MISMATCH!"
PRINT
PRINT "Press a key."
k$ = INPUT$(1)
END

NoSuch:
    existsErr = ERR
    RESUME NEXT

' TRUE if the file can be opened for INPUT (i.e. it exists).
FUNCTION Exists% (f$)
    SHARED existsErr
    existsErr = 0
    ON ERROR GOTO NoSuch
    OPEN f$ FOR INPUT AS #9
    ON ERROR GOTO 0
    IF existsErr = 0 THEN CLOSE #9
    Exists% = (existsErr = 0)
END FUNCTION
