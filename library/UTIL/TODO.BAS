' ============================================================
' TITLE:    To-Do List Manager
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     files, arrays, list, menu, on error, persistence
' SUMMARY:  Add, tick off, delete and prioritise tasks - your list is saved to TODO.TXT between runs.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps a list of up to 50 tasks.  Each task has a text, a
'   priority (1 = high, 2 = normal, 3 = low) and a done flag.
'   The list is loaded from TODO.TXT when the program starts
'   and saved back every time you change it, so nothing is lost.
'
'   The file format is one task per line:   P,D,text
'   e.g.  1,0,Buy milk    (priority 1, not done)
'
' HOW TO USE
'   Up/Down arrows move the highlight.
'   A = add task    Space = done / not done    D = delete
'   P = change priority    S = sort by priority
'   C = clear all finished tasks    Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Saving and loading data with OPEN FOR INPUT / OUTPUT
'   * ON ERROR to cope with the file not existing yet
'   * Parallel arrays (text$, pri, done) for records
'   * Deleting from an array by shifting items down
'   * A simple bubble sort
'
' THINGS TO TRY
'   * Add a due date to each task.
'   * Use a TYPE ... END TYPE record instead of parallel arrays.
'   * Show how many tasks are done as a percentage bar.
' ============================================================

DECLARE SUB SaveList ()
DECLARE SUB LoadList ()
DECLARE SUB DrawList ()

CONST MAXT = 50
CONST LISTFILE$ = "TODO.TXT"
DIM SHARED text$(1 TO MAXT), pri(1 TO MAXT), done(1 TO MAXT)
DIM SHARED n, cur, fileErr

LoadList
' If the list is empty (first run) put in a couple of examples.
IF n = 0 THEN
    n = 2
    text$(1) = "Try adding a task with A": pri(1) = 1
    text$(2) = "Tick me off with Space": pri(2) = 2
    SaveList
END IF
cur = 1

DO
    DrawList
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "H": IF cur > 1 THEN cur = cur - 1
        CASE CHR$(0) + "P": IF cur < n THEN cur = cur + 1
        CASE "A"
            IF n < MAXT THEN
                LOCATE 22, 2: LINE INPUT "New task: "; t$
                t$ = LTRIM$(RTRIM$(t$))
                IF t$ <> "" THEN
                    n = n + 1
                    ' commas would confuse our file format, so swap them
                    DO WHILE INSTR(t$, ",")
                        MID$(t$, INSTR(t$, ","), 1) = ";"
                    LOOP
                    text$(n) = t$: pri(n) = 2: done(n) = 0
                    cur = n
                    SaveList
                END IF
            END IF
        CASE " "
            ' NOT 0 = -1, NOT -1 = 0: flips the flag.
            IF n > 0 THEN done(cur) = NOT done(cur): SaveList
        CASE "P"
            ' cycle 1 -> 2 -> 3 -> 1
            IF n > 0 THEN pri(cur) = pri(cur) MOD 3 + 1: SaveList
        CASE "D"
            IF n > 0 THEN
                ' Shift every task after cur down one place.
                FOR i = cur TO n - 1
                    text$(i) = text$(i + 1): pri(i) = pri(i + 1): done(i) = done(i + 1)
                NEXT i
                n = n - 1
                IF cur > n THEN cur = n
                IF cur < 1 THEN cur = 1
                SaveList
            END IF
        CASE "S"
            ' Bubble sort by priority, keeping undone tasks first.
            FOR i = 1 TO n - 1
                FOR j = 1 TO n - i
                    ka = pri(j) - done(j) * 10        ' done adds +10
                    kb = pri(j + 1) - done(j + 1) * 10
                    IF ka > kb THEN
                        SWAP text$(j), text$(j + 1)
                        SWAP pri(j), pri(j + 1)
                        SWAP done(j), done(j + 1)
                    END IF
                NEXT j
            NEXT i
            SaveList
        CASE "C"
            ' Keep only unfinished tasks: copy them down in place.
            m = 0
            FOR i = 1 TO n
                IF NOT done(i) THEN
                    m = m + 1
                    text$(m) = text$(i): pri(m) = pri(i): done(m) = 0
                END IF
            NEXT i
            n = m: cur = 1
            SaveList
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
PRINT "Your list is saved in "; LISTFILE$
END

' If OPEN fails (no file yet) we land here and just note it.
NoFile:
    fileErr = -1
    RESUME NEXT

SUB DrawList
    CLS
    COLOR 15, 1: PRINT SPACE$(80);: LOCATE 1, 34: PRINT "TO-DO LIST": COLOR 7, 0
    IF n = 0 THEN LOCATE 4, 4: PRINT "(nothing to do - press A to add a task)"
    FOR i = 1 TO n
        LOCATE 2 + i, 2
        IF i = cur THEN COLOR 0, 7 ELSE COLOR 7, 0
        ' Colour by priority: red, yellow, grey.  Done = dark grey.
        IF done(i) THEN mark$ = "[X] " ELSE mark$ = "[ ] "
        PRINT mark$; "P"; LTRIM$(STR$(pri(i))); "  ";
        IF i <> cur THEN
            ' priority 1 = light red, 2 = yellow, 3 = grey; done = dark grey
            IF done(i) THEN
                COLOR 8
            ELSE
                SELECT CASE pri(i)
                    CASE 1: COLOR 12
                    CASE 2: COLOR 14
                    CASE ELSE: COLOR 7
                END SELECT
            END IF
        END IF
        PRINT LEFT$(text$(i), 66); SPACE$(66 - LEN(LEFT$(text$(i), 66)));
        COLOR 7, 0
        IF i >= 18 THEN EXIT FOR        ' keep it on one screen
    NEXT i
    LOCATE 24, 1
    COLOR 0, 3
    PRINT " A Add  Space Done  D Del  P Priority  S Sort  C Clear done  Q Quit "; SPACE$(11);
    COLOR 7, 0
END SUB

SUB LoadList
    n = 0: fileErr = 0
    ON ERROR GOTO NoFile
    OPEN LISTFILE$ FOR INPUT AS #1
    ON ERROR GOTO 0
    IF fileErr THEN EXIT SUB          ' no file yet: start empty
    DO WHILE NOT EOF(1) AND n < MAXT
        LINE INPUT #1, ln$
        ' split "P,D,text" at the first two commas
        c1 = INSTR(ln$, ","): c2 = INSTR(c1 + 1, ln$, ",")
        IF c1 > 0 AND c2 > 0 THEN
            n = n + 1
            pri(n) = VAL(LEFT$(ln$, c1 - 1))
            done(n) = VAL(MID$(ln$, c1 + 1, c2 - c1 - 1))
            text$(n) = MID$(ln$, c2 + 1)
            IF pri(n) < 1 OR pri(n) > 3 THEN pri(n) = 2
        END IF
    LOOP
    CLOSE #1
END SUB

SUB SaveList
    OPEN LISTFILE$ FOR OUTPUT AS #1
    FOR i = 1 TO n
        PRINT #1, LTRIM$(STR$(pri(i))); ","; LTRIM$(STR$(done(i))); ","; text$(i)
    NEXT i
    CLOSE #1
END SUB
