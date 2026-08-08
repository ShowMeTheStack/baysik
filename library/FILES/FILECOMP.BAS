' ============================================================
' TITLE:    File Compare (FC)
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, binary, compare, diff, text
' SUMMARY:  Compare two files byte by byte AND line by line, and report exactly where they differ.
' ------------------------------------------------------------
' WHAT IT DOES
'   Creates two versions of a short poem (POEM1.TXT and POEM2.TXT)
'   with a few small changes, then compares them two ways:
'     1. BINARY compare - lists the first differing bytes with their
'        offsets, like the DOS "FC /B" command.
'     2. LINE compare - reads both files line by line and shows which
'        lines changed, side by side.
'   You may also compare any two files of your own.
'
' HOW TO USE
'   Press Enter twice to compare the demo poems, or type two names.
'
' CONCEPTS YOU WILL LEARN
'   * Reading two files at the same time with two file numbers
'   * Byte-level comparison with BINARY mode and 1-char strings
'   * Line-level comparison with LINE INPUT # and EOF
'   * Handling files of different lengths
'
' THINGS TO TRY
'   * Make the line compare smarter: detect an inserted line.
'   * Stop after 10 differences and ask "show more?".
' ============================================================

CLS
' ---- make the demo files ----------------------------------------
OPEN "POEM1.TXT" FOR OUTPUT AS #1
PRINT #1, "Twinkle, twinkle, little star,"
PRINT #1, "How I wonder what you are!"
PRINT #1, "Up above the world so high,"
PRINT #1, "Like a diamond in the sky."
CLOSE #1
OPEN "POEM2.TXT" FOR OUTPUT AS #1
PRINT #1, "Twinkle, twinkle, little star,"
PRINT #1, "How I wonder where you are!"
PRINT #1, "Up above the world so high,"
PRINT #1, "Like a diamond in the SKY."
PRINT #1, "(by Jane Taylor, 1806)"
CLOSE #1

PRINT "FILE COMPARE"
LINE INPUT "First file  (Enter = POEM1.TXT): "; a$
LINE INPUT "Second file (Enter = POEM2.TXT): "; b$
IF a$ = "" THEN a$ = "POEM1.TXT"
IF b$ = "" THEN b$ = "POEM2.TXT"

ON ERROR GOTO OpenFail
OPEN a$ FOR INPUT AS #1: CLOSE #1
OPEN b$ FOR INPUT AS #1: CLOSE #1
ON ERROR GOTO 0

' ---- 1. binary compare --------------------------------------------
PRINT
PRINT "== Binary compare =="
OPEN a$ FOR BINARY AS #1
OPEN b$ FOR BINARY AS #2
la& = LOF(1): lb& = LOF(2)
PRINT "Sizes:"; la&; "and"; lb&; "bytes"
shorter& = la&: IF lb& < shorter& THEN shorter& = lb&
c1$ = " ": c2$ = " "           ' 1-byte buffers for GET
diffs = 0
FOR p& = 1 TO shorter&
    GET #1, p&, c1$
    GET #2, p&, c2$
    IF c1$ <> c2$ THEN
        diffs = diffs + 1
        IF diffs <= 8 THEN
            ' Show offset (0-based, in hex like DOS), both bytes in hex,
            ' and the characters themselves.
            PRINT "  offset "; RIGHT$("0000" + HEX$(p& - 1), 4); ":  ";
            PRINT RIGHT$("0" + HEX$(ASC(c1$)), 2); " '"; c1$; "'   vs   ";
            PRINT RIGHT$("0" + HEX$(ASC(c2$)), 2); " '"; c2$; "'"
        END IF
    END IF
NEXT
IF diffs > 8 THEN PRINT "  ..."; diffs - 8; "more differing bytes"
IF la& <> lb& THEN PRINT "  The files differ in length by"; ABS(la& - lb&); "bytes."
IF diffs = 0 AND la& = lb& THEN PRINT "  No differences: the files are identical."
CLOSE #1, #2

' ---- 2. line compare ----------------------------------------------
PRINT
PRINT "== Line compare =="
OPEN a$ FOR INPUT AS #1
OPEN b$ FOR INPUT AS #2
ln = 0: changed = 0
' Keep going while EITHER file still has lines.
DO WHILE NOT EOF(1) OR NOT EOF(2)
    ln = ln + 1
    l1$ = "": l2$ = ""
    e1 = EOF(1): e2 = EOF(2)
    IF NOT e1 THEN LINE INPUT #1, l1$
    IF NOT e2 THEN LINE INPUT #2, l2$
    IF e1 THEN
        PRINT USING "  ### + "; ln; : PRINT l2$; "   (only in "; b$; ")"
        changed = changed + 1
    ELSEIF e2 THEN
        PRINT USING "  ### - "; ln; : PRINT l1$; "   (only in "; a$; ")"
        changed = changed + 1
    ELSEIF l1$ <> l2$ THEN
        PRINT USING "  ### < "; ln; : PRINT l1$
        PRINT "      > "; l2$
        changed = changed + 1
    END IF
LOOP
CLOSE #1, #2
PRINT
PRINT changed; "of"; ln; "lines differ."
PRINT "Press a key."
k$ = INPUT$(1)
END

OpenFail:
    PRINT "Could not open one of the files (error"; ERR; ")."
    END
