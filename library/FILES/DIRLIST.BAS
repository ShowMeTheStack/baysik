' ============================================================
' TITLE:    Directory Explorer with FILES
' CATEGORY: File I/O
' LEVEL:    Beginner
' TAGS:     files, directory, FILES, wildcards, DIR$, LOF
' SUMMARY:  Create some files, then list them with FILES and wildcards like *.TXT and DATA?.*
' ------------------------------------------------------------
' WHAT IT DOES
'   Makes a little collection of files of different types and sizes,
'   then shows how the FILES statement lists a directory, and how
'   wildcards pick out groups of files:
'       *      matches any number of characters
'       ?      matches exactly one character
'   Finally it measures each file's size with LOF and draws a chart.
'
' HOW TO USE
'   Press a key after each listing. At the end you can type your own
'   patterns; press Enter on an empty line to quit.
'
' CONCEPTS YOU WILL LEARN
'   * FILES and FILES "pattern"
'   * 8.3 file names: NAME.EXT
'   * Wildcards * and ?
'   * Getting a file's size with OPEN + LOF
'
' THINGS TO TRY
'   * Make a sub-folder with MKDIR and list it with FILES "SUB\*.*".
'   * Make a file bigger and watch its bar grow.
' ============================================================

DECLARE SUB MakeFile (f$, size%)
DECLARE SUB Pause ()

CLS
PRINT "Making some files to look at..."
' Each file gets a different number of bytes so the sizes vary.
MakeFile "README.TXT", 300
MakeFile "NOTES.TXT", 120
MakeFile "DATA1.DAT", 64
MakeFile "DATA2.DAT", 640
MakeFile "DATA10.DAT", 1000
MakeFile "GAME.BAS", 450
MakeFile "SCORES.TXT", 40
MakeFile "PIC.BIN", 800
PRINT

PRINT "FILES  (every file in the current directory):"
FILES
Pause

PRINT "FILES "; CHR$(34); "*.TXT"; CHR$(34); "  (only text files):"
FILES "*.TXT"
Pause

PRINT "FILES "; CHR$(34); "DATA?.DAT"; CHR$(34); "  (? = exactly one character):"
FILES "DATA?.DAT"
PRINT "Notice DATA10.DAT is missing: '10' is TWO characters."
Pause

PRINT "FILES "; CHR$(34); "DATA*.*"; CHR$(34); "  (* = any number of characters):"
FILES "DATA*.*"
Pause

' ---- size chart ----------------------------------------------
PRINT "File sizes (measured with LOF):"
PRINT
RESTORE Names
DO
    READ f$
    IF f$ = "*" THEN EXIT DO
    OPEN f$ FOR INPUT AS #1
    s& = LOF(1)
    CLOSE #1
    PRINT LEFT$(f$ + SPACE$(12), 12);
    PRINT USING "##### "; s&;
    PRINT STRING$(s& \ 25, 219)        ' one block per 25 bytes
LOOP
Pause

' ---- try your own -----------------------------------------------
DO
    PRINT
    LINE INPUT "Your pattern (e.g. *.BAS, ?????.TXT; Enter quits): "; p$
    IF p$ = "" THEN EXIT DO
    ' If nothing matches, FILES raises error 53 "File not found".
    ON ERROR GOTO NoMatch
    FILES p$
    ON ERROR GOTO 0
LOOP
END

NoMatch:
    PRINT "  (no files match "; p$; ")"
    RESUME NEXT

Names:
DATA README.TXT, NOTES.TXT, DATA1.DAT, DATA2.DAT, DATA10.DAT
DATA GAME.BAS, SCORES.TXT, PIC.BIN, *

' Write a file of exactly size% bytes (lines of dots, CR+LF ends).
SUB MakeFile (f$, size%)
    OPEN f$ FOR OUTPUT AS #1
    remain% = size%
    DO WHILE remain% > 0
        IF remain% >= 40 THEN
            PRINT #1, STRING$(38, ".")       ' 38 dots + CR LF = 40 bytes
            remain% = remain% - 40
        ELSE
            PRINT #1, STRING$(remain%, "-");   ' the last few bytes, no CR LF
            remain% = 0
        END IF
    LOOP
    CLOSE #1
    PRINT "  created "; f$
END SUB

SUB Pause
    PRINT
    PRINT "Press a key..."
    k$ = INPUT$(1)
    CLS
END SUB
