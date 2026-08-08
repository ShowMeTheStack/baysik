' ============================================================
' TITLE:    Safe File Handling with ON ERROR
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, ON ERROR, RESUME, ERR, ERL, error handling
' SUMMARY:  Deliberately trigger common file errors and recover from each one gracefully.
' ------------------------------------------------------------
' WHAT IT DOES
'   Real programs meet missing files, bad names and full disks. This
'   program runs a series of small "experiments", each of which
'   causes a different file error, and shows how ON ERROR catches it,
'   how ERR tells you which error happened, and the three ways to
'   continue: RESUME (try again), RESUME NEXT (skip), RESUME label.
'   It ends with a friendly "open file" prompt that never crashes.
'
' HOW TO USE
'   Press a key between experiments. At the end, type file names to
'   open; try one that doesn't exist. Enter on its own quits.
'
' CONCEPTS YOU WILL LEARN
'   * ON ERROR GOTO handler / ON ERROR GOTO 0
'   * ERR (error number) and ERL (line number, for numbered lines)
'   * RESUME, RESUME NEXT, RESUME label
'   * Common file errors: 52, 53, 54, 55, 62, 64, 75, 76
'
' THINGS TO TRY
'   * Make the handler log every error to ERRORS.LOG.
'   * What happens if you remove ON ERROR? (The program stops!)
' ============================================================

DECLARE FUNCTION ErrName$ (e%)

CLS
PRINT "FILE ERROR LABORATORY"
PRINT
ON ERROR GOTO Handler
mode$ = "next"            ' tells the handler which RESUME to use

' Experiment 1: open a file that is not there.
PRINT "1) OPEN a missing file FOR INPUT"
OPEN "GHOST.TXT" FOR INPUT AS #1
PRINT "   ...and the program carried on."
PRINT

' Experiment 2: read past the end of a file.
PRINT "2) Read 3 lines from a 1-line file"
OPEN "ONELINE.TXT" FOR OUTPUT AS #1: PRINT #1, "only line": CLOSE #1
OPEN "ONELINE.TXT" FOR INPUT AS #1
FOR i = 1 TO 3
    failed = 0                ' the handler sets this to -1
    LINE INPUT #1, l$
    ' After RESUME NEXT, l$ still holds the OLD value, so only print
    ' it when the read really worked.
    IF NOT failed THEN PRINT "   got: "; l$
NEXT
CLOSE #1
PRINT

' Experiment 3: use a file number that was never opened.
PRINT "3) PRINT #5 without opening #5"
PRINT #5, "hello?"
PRINT

' Experiment 4: open the same number twice.
PRINT "4) OPEN #1 twice"
OPEN "A.TXT" FOR OUTPUT AS #1
OPEN "B.TXT" FOR OUTPUT AS #1
CLOSE
PRINT

' Experiment 5: wrong mode - writing to a file opened for INPUT.
PRINT "5) PRINT # to a file opened FOR INPUT"
OPEN "ONELINE.TXT" FOR INPUT AS #1
PRINT #1, "can I write?"
CLOSE #1
PRINT

PRINT "Press a key for more...": k$ = INPUT$(1): CLS

' Experiment 6: bad file name.
PRINT "6) OPEN a file with an illegal name"
OPEN "BAD*NAME?.TXT" FOR OUTPUT AS #1
CLOSE
PRINT

' Experiment 7: CHDIR to a folder that is not there.
PRINT "7) CHDIR into a missing folder"
CHDIR "NOWHERE"
PRINT

' Experiment 8: RESUME (retry). The handler creates the missing
' file, then RESUME runs the failing OPEN again - and now it works.
PRINT "8) RESUME: fix the problem, then retry"
mode$ = "retry"
OPEN "CONFIG.TXT" FOR INPUT AS #1
LINE INPUT #1, l$
CLOSE #1
PRINT "   CONFIG.TXT now says: "; l$
mode$ = "next"
PRINT

' Experiment 9: RESUME label - jump somewhere else entirely.
PRINT "9) RESUME label: give up on this part"
mode$ = "label"
KILL "NOFILE.XYZ"
PRINT "   (this line is skipped)"
AfterNine:
mode$ = "next"
PRINT "   ...landed at label AfterNine."
PRINT

' ---- a crash-proof file opener ---------------------------------
PRINT "Press a key for the safe opener...": k$ = INPUT$(1): CLS
PRINT "SAFE OPENER - existing files: ONELINE.TXT, CONFIG.TXT"
DO
    PRINT
    LINE INPUT "File to show (Enter quits): "; f$
    IF f$ = "" THEN EXIT DO
    failed = 0
    OPEN f$ FOR INPUT AS #1
    IF failed = 0 THEN
        DO WHILE NOT EOF(1): LINE INPUT #1, l$: PRINT "  | "; l$: LOOP
        CLOSE #1
    END IF
LOOP
ON ERROR GOTO 0
END

' ---------------------------------------------------------------
' The error handler. Keep handlers short and always end with RESUME.
' ---------------------------------------------------------------
Handler:
    failed = -1
    COLOR 12
    PRINT "   ! Error"; ERR; "- "; ErrName$(ERR)
    COLOR 7
    SELECT CASE mode$
    CASE "retry"
        PRINT "   Handler creates CONFIG.TXT and retries..."
        OPEN "CONFIG.TXT" FOR OUTPUT AS #1
        PRINT #1, "volume=7"
        CLOSE #1
        RESUME                ' run the failing statement again
    CASE "label"
        RESUME AfterNine
    CASE ELSE
        RESUME NEXT           ' skip the failing statement
    END SELECT

' Human-readable names for the errors we expect.
FUNCTION ErrName$ (e%)
    SELECT CASE e%
    CASE 52: ErrName$ = "Bad file name or number"
    CASE 53: ErrName$ = "File not found"
    CASE 54: ErrName$ = "Bad file mode"
    CASE 55: ErrName$ = "File already open"
    CASE 62: ErrName$ = "Input past end of file"
    CASE 64: ErrName$ = "Bad file name"
    CASE 75: ErrName$ = "Path/File access error"
    CASE 76: ErrName$ = "Path not found"
    CASE ELSE: ErrName$ = "Some other error"
    END SELECT
END FUNCTION
