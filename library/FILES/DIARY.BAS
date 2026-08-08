' ============================================================
' TITLE:    Daily Diary (APPEND mode)
' CATEGORY: File I/O
' LEVEL:    Beginner
' TAGS:     files, append, LINE INPUT#, menu, dates
' SUMMARY:  Keep a diary that grows every time you add an entry, using APPEND.
' ------------------------------------------------------------
' WHAT IT DOES
'   Stores diary entries in DIARY.TXT. New entries are added at the
'   END of the file with OPEN ... FOR APPEND, so nothing older is
'   lost. You can list every entry or search for a word.
'
' HOW TO USE
'   A  add an entry (type one line, press Enter)
'   L  list all entries
'   S  search entries for a word
'   C  clear the diary (asks first)
'   Q  quit
'
' CONCEPTS YOU WILL LEARN
'   * OUTPUT vs APPEND vs INPUT modes
'   * Testing whether a file exists with ON ERROR
'   * LINE INPUT # and EOF loops
'   * DATE$ and TIME$ for time stamps
'
' THINGS TO TRY
'   * Add a "mood" (1-5) to each entry and show an average.
'   * Show only entries from today's date.
' ============================================================

DECLARE FUNCTION FileExists% (f$)
DECLARE SUB ListEntries (find$)

CONST DIARY = "DIARY.TXT"

' If there is no diary yet, start one with a welcome entry.
' FOR APPEND would also create it, but we want a nice first line.
IF NOT FileExists%(DIARY) THEN
    OPEN DIARY FOR OUTPUT AS #1
    PRINT #1, DATE$ + " " + LEFT$(TIME$, 5) + "  Started my diary!"
    CLOSE #1
END IF

DO
    CLS
    PRINT "+------------------------------+"
    PRINT "|        MY  DIARY             |"
    PRINT "+------------------------------+"
    PRINT
    PRINT "  A) Add entry"
    PRINT "  L) List entries"
    PRINT "  S) Search"
    PRINT "  C) Clear diary"
    PRINT "  Q) Quit"
    PRINT
    PRINT "Choice: ";
    k$ = UCASE$(INPUT$(1))
    PRINT k$
    SELECT CASE k$
    CASE "A"
        PRINT
        LINE INPUT "Today I... "; t$
        IF LEN(t$) > 0 THEN
            ' APPEND opens the file and jumps to the end, so the new
            ' line goes after everything already there.
            OPEN DIARY FOR APPEND AS #1
            PRINT #1, DATE$ + " " + LEFT$(TIME$, 5) + "  " + t$
            CLOSE #1
            PRINT "Saved."
        END IF
        SLEEP 1
    CASE "L"
        ListEntries ""
    CASE "S"
        PRINT
        LINE INPUT "Word to find: "; w$
        IF LEN(w$) > 0 THEN ListEntries w$
    CASE "C"
        PRINT
        PRINT "Really erase everything (Y/N)? ";
        IF UCASE$(INPUT$(1)) = "Y" THEN
            ' OUTPUT mode truncates the file to zero length.
            OPEN DIARY FOR OUTPUT AS #1
            CLOSE #1
            PRINT "Erased."
        END IF
        SLEEP 1
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
CLS
PRINT "Goodbye! Your diary is safe in "; DIARY
END

' -------------------------------------------------------------
' Error handler used by FileExists%. Error 53 = "File not found".
' We just remember that an error happened and carry on.
' -------------------------------------------------------------
NoFile:
    fileErr = ERR
    RESUME NEXT

' Returns TRUE (-1) if the file can be opened for reading.
FUNCTION FileExists% (f$)
    SHARED fileErr
    fileErr = 0
    ON ERROR GOTO NoFile
    OPEN f$ FOR INPUT AS #9
    ON ERROR GOTO 0          ' turn the handler off again
    IF fileErr = 0 THEN CLOSE #9
    FileExists% = (fileErr = 0)
END FUNCTION

' Prints every entry, or only those containing find$ (any case).
SUB ListEntries (find$)
    PRINT
    OPEN DIARY FOR INPUT AS #1
    shown = 0
    DO WHILE NOT EOF(1)
        LINE INPUT #1, e$
        ' INSTR returns 0 if the word is not found. An empty search
        ' word matches everything.
        IF find$ = "" OR INSTR(UCASE$(e$), UCASE$(find$)) > 0 THEN
            PRINT e$
            shown = shown + 1
            ' Pause every 18 lines so the list does not scroll away.
            IF shown MOD 18 = 0 THEN PRINT "-- more --": k$ = INPUT$(1)
        END IF
    LOOP
    CLOSE #1
    PRINT
    PRINT shown; "entr"; : IF shown = 1 THEN PRINT "y" ELSE PRINT "ies"
    PRINT "Press a key..."
    k$ = INPUT$(1)
END SUB
