' ============================================================
' TITLE:    Text File Viewer
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     files, paging, scrolling, search, line input, arrays
' SUMMARY:  A scrolling text file viewer with page up/down, line numbers, search and a status bar.
' ------------------------------------------------------------
' WHAT IT DOES
'   Loads a text file into memory and lets you scroll through it
'   a screen at a time, like the DOS "MORE" command but in both
'   directions.  It can search for a word and jump between
'   matches, which are highlighted.
'
'   If you just press Enter at the file-name prompt it writes a
'   demo file called VIEWDEMO.TXT (60 numbered lines) so there is
'   always something to look at.
'
' HOW TO USE
'   Up/Down       one line          PgUp/PgDn (or Space)  one page
'   Home/End      top / bottom      /  search for text
'   N             next match        L  toggle line numbers
'   O             open another file Q / Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * LINE INPUT # to read whole lines into a string array
'   * ON ERROR GOTO to catch "File not found" nicely
'   * The "top line" idea behind every scrolling viewer
'   * Clamping a value between a minimum and a maximum
'   * Case-insensitive search with UCASE$ and INSTR
'
' THINGS TO TRY
'   * Add a "goto line number" command.
'   * Show long lines with horizontal scrolling (Left/Right).
'   * Count words and characters and show them in the status bar.
' ============================================================

DECLARE SUB MakeDemo ()

CONST MAXL = 2000          ' most lines we will load
CONST PAGE = 22            ' text rows on screen (rows 2..23)
DIM SHARED lines$(1 TO MAXL)
DIM SHARED openErr

CLS
GOSUB AskFile

top = 1: showNums = -1: find$ = ""
DO
    ' ---- Keep "top" in range: 1 .. (last line that still fills the page)
    maxTop = nl - PAGE + 1: IF maxTop < 1 THEN maxTop = 1
    IF top > maxTop THEN top = maxTop
    IF top < 1 THEN top = 1

    ' ---- Title bar ----
    LOCATE 1, 1: COLOR 0, 7
    PRINT LEFT$(" " + fileName$ + SPACE$(80), 80);
    ' ---- The page of text ----
    FOR r = 0 TO PAGE - 1
        i = top + r
        LOCATE 2 + r, 1
        COLOR 7, 0
        IF i <= nl THEN
            IF showNums THEN
                COLOR 8: PRINT USING "#### "; i;: COLOR 7
                w = 75
            ELSE
                w = 80
            END IF
            t$ = LEFT$(lines$(i), w)
            ' Highlight lines that contain the search text.
            IF find$ <> "" THEN IF INSTR(UCASE$(lines$(i)), find$) THEN COLOR 0, 14
            PRINT t$; : COLOR 7, 0: PRINT SPACE$(w - LEN(t$));
        ELSE
            COLOR 1: PRINT "~"; SPACE$(79);        ' past the end of file
        END IF
    NEXT r
    ' ---- Status bar ----
    last = top + PAGE - 1: IF last > nl THEN last = nl
    LOCATE 24, 1: COLOR 15, 1
    s$ = " Lines" + STR$(top) + "-" + LTRIM$(STR$(last)) + " of" + STR$(nl)
    IF nl > 0 THEN s$ = s$ + "  (" + LTRIM$(STR$(INT(last * 100 / nl))) + "%)"
    s$ = s$ + "   PgUp PgDn Home End  / find  N next  L nums  O open  Q quit"
    PRINT LEFT$(s$ + SPACE$(80), 80);
    COLOR 7, 0

    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "H": top = top - 1                ' Up
        CASE CHR$(0) + "P": top = top + 1                ' Down
        CASE CHR$(0) + "I": top = top - PAGE             ' PgUp
        CASE CHR$(0) + "Q", " ": top = top + PAGE        ' PgDn / Space
        CASE CHR$(0) + "G": top = 1                      ' Home
        CASE CHR$(0) + "O": top = maxTop                 ' End
        CASE "L": showNums = NOT showNums
        CASE "/"
            LOCATE 24, 1: COLOR 15, 4: PRINT SPACE$(80);: LOCATE 24, 2
            LINE INPUT "Find: "; f$
            COLOR 7, 0
            find$ = UCASE$(f$)
            start = top: GOSUB FindNext
        CASE "N": start = top + 1: GOSUB FindNext
        CASE "O": CLS : GOSUB AskFile: top = 1: find$ = ""
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END

' ---- Search from line "start" for find$, wrapping round ----
FindNext:
    IF find$ = "" OR nl = 0 THEN RETURN
    FOR j = 0 TO nl - 1
        i = (start - 1 + j) MOD nl + 1        ' wraps past the end to line 1
        IF INSTR(UCASE$(lines$(i)), find$) THEN top = i: RETURN
    NEXT j
    BEEP                                      ' not found anywhere
    RETURN

' ---- Ask for a file name and load it ----
AskFile:
    DO
        COLOR 14: PRINT "TEXT FILE VIEWER": COLOR 7
        LINE INPUT "File to view (Enter = demo file, Q = quit): "; fileName$
        fileName$ = UCASE$(LTRIM$(RTRIM$(fileName$)))
        IF fileName$ = "Q" THEN CLS : END
        IF fileName$ = "" THEN MakeDemo: fileName$ = "VIEWDEMO.TXT"
        openErr = 0
        ON ERROR GOTO OpenFailed
        OPEN fileName$ FOR INPUT AS #1
        ON ERROR GOTO 0
        IF openErr = 0 THEN EXIT DO
        PRINT "Cannot open "; fileName$; " - try again."
        PRINT
    LOOP
    nl = 0
    DO WHILE NOT EOF(1) AND nl < MAXL
        nl = nl + 1
        LINE INPUT #1, lines$(nl)
        ' Tabs would show as odd symbols - expand them to spaces.
        DO WHILE INSTR(lines$(nl), CHR$(9))
            p = INSTR(lines$(nl), CHR$(9))
            lines$(nl) = LEFT$(lines$(nl), p - 1) + SPACE$(4) + MID$(lines$(nl), p + 1)
        LOOP
    LOOP
    CLOSE #1
    CLS
    RETURN

OpenFailed:
    openErr = ERR          ' remember the error number (53 = not found)
    RESUME NEXT

' Write a demo file so the viewer always has something to show.
SUB MakeDemo
    OPEN "VIEWDEMO.TXT" FOR OUTPUT AS #2
    PRINT #2, "VIEWDEMO.TXT - a sample file for the text viewer"
    PRINT #2, STRING$(50, "=")
    FOR i = 1 TO 60
        SELECT CASE i MOD 5
            CASE 0: t$ = "Every fifth line mentions the word BASIC."
            CASE 1: t$ = "The quick brown fox jumps over the lazy dog."
            CASE 2: t$ = "Try searching with / for the word fox."
            CASE 3: t$ = "PgDn moves a whole screen; Down moves one line."
            CASE ELSE: t$ = CHR$(9) + "This line started with a TAB character."
        END SELECT
        PRINT #2, "Line"; i; ": "; t$
    NEXT i
    PRINT #2, "*** END OF DEMO ***"
    CLOSE #2
END SUB
