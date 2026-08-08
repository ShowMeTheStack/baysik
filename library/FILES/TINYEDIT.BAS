' ============================================================
' TITLE:    Tiny Text Editor
' CATEGORY: File I/O
' LEVEL:    Advanced
' TAGS:     files, editor, arrays, keyboard, INKEY$, save, load
' SUMMARY:  A small full-screen text editor that loads and saves real text files.
' ------------------------------------------------------------
' WHAT IT DOES
'   Edits a text file held in an array of strings (one per line).
'   You can move around with the arrow keys, type, split and join
'   lines, and save the result back to disk. It opens NOTES.TXT,
'   creating a starter file the first time.
'
' HOW TO USE
'   Arrows, Home, End, PgUp, PgDn  move the cursor
'   Enter splits a line, Backspace/Del join lines at the ends
'   F2 = save    F3 = open another file    Esc = quit
'   (Esc asks whether to save if you changed something.)
'
' CONCEPTS YOU WILL LEARN
'   * Loading a whole text file into an array with LINE INPUT #
'   * Saving it back with PRINT #
'   * Inserting/deleting array elements by shifting
'   * Extended keys: INKEY$ returns CHR$(0) + scan code
'   * Scrolling a "window" over a larger document
'
' THINGS TO TRY
'   * Add F5 = find text.
'   * Show a "*" in the title when the file is modified.
'   * Add Tab support (insert 4 spaces).
' ============================================================

DECLARE SUB LoadFile (f$)
DECLARE SUB SaveFile (f$)
DECLARE SUB Redraw ()
DECLARE SUB Status (msg$)
DECLARE SUB InsertLine (at%)
DECLARE SUB DeleteLine (at%)

CONST MAXL = 500             ' most lines we can hold
CONST VIEWH = 23             ' text rows on screen (rows 2..24)
DIM SHARED txt$(1 TO MAXL), nLines AS INTEGER
DIM SHARED cx AS INTEGER, cy AS INTEGER, top AS INTEGER
DIM SHARED fileName$, changed AS INTEGER

fileName$ = "NOTES.TXT"
' Make a starter file on the first run (OPEN FOR APPEND creates it if
' missing, without destroying it if it is already there).
OPEN fileName$ FOR APPEND AS #1
IF LOF(1) = 0 THEN
    PRINT #1, "Welcome to Tiny Edit!"
    PRINT #1, ""
    PRINT #1, "Use the arrow keys to move around. Type to insert text."
    PRINT #1, "Press F2 to save, F3 to open a file, Esc to quit."
    PRINT #1, ""
    PRINT #1, "Everything you save goes into a real file on the disk."
END IF
CLOSE #1

LoadFile fileName$
Redraw

DO
    ' Keep the cursor inside the text and the view around the cursor.
    IF cy < 1 THEN cy = 1
    IF cy > nLines THEN cy = nLines
    IF cx < 1 THEN cx = 1
    IF cx > LEN(txt$(cy)) + 1 THEN cx = LEN(txt$(cy)) + 1
    IF cx > 79 THEN cx = 79                       ' screen width limit
    oldTop = top
    IF cy < top THEN top = cy
    IF cy >= top + VIEWH THEN top = cy - VIEWH + 1
    IF top <> oldTop THEN Redraw
    LOCATE 25, 60: COLOR 0, 3: PRINT USING "Ln ####  Col ##  "; cy; cx; : COLOR 7, 1
    LOCATE cy - top + 2, cx, 1                    ' show the cursor

    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    l$ = txt$(cy)
    IF LEN(k$) = 2 THEN
        ' ---- extended keys -----------------------------------
        SELECT CASE ASC(RIGHT$(k$, 1))
        CASE 72: cy = cy - 1                      ' Up
        CASE 80: cy = cy + 1                      ' Down
        CASE 75                                   ' Left (wraps up)
            IF cx > 1 THEN
                cx = cx - 1
            ELSEIF cy > 1 THEN
                cy = cy - 1: cx = 999
            END IF
        CASE 77: cx = cx + 1                      ' Right
        CASE 71: cx = 1                           ' Home
        CASE 79: cx = 999                         ' End
        CASE 73: cy = cy - VIEWH                  ' PgUp
        CASE 81: cy = cy + VIEWH                  ' PgDn
        CASE 83                                   ' Delete
            IF cx <= LEN(l$) THEN
                txt$(cy) = LEFT$(l$, cx - 1) + MID$(l$, cx + 1): changed = -1
            ELSEIF cy < nLines THEN               ' join with next line
                txt$(cy) = l$ + txt$(cy + 1): DeleteLine cy + 1: changed = -1: Redraw
            END IF
        CASE 60: SaveFile fileName$               ' F2
        CASE 61                                   ' F3
            Status "Open file: "
            LOCATE 25, 12: COLOR 15, 3: LINE INPUT ; f$
            IF f$ <> "" THEN fileName$ = UCASE$(f$): LoadFile fileName$
            Redraw
        END SELECT
    ELSE
        ' ---- normal keys -------------------------------------
        SELECT CASE k$
        CASE CHR$(27)                             ' Esc
            IF changed THEN
                Status "Save changes to " + fileName$ + " (Y/N/C)? "
                DO: a$ = UCASE$(INPUT$(1)): LOOP UNTIL INSTR("YNC" + CHR$(27), a$)
                IF a$ = "Y" THEN SaveFile fileName$: EXIT DO
                IF a$ = "N" THEN EXIT DO
                Redraw                            ' C / Esc = cancel
            ELSE
                EXIT DO
            END IF
        CASE CHR$(13)                             ' Enter: split line
            InsertLine cy + 1
            txt$(cy + 1) = MID$(l$, cx)
            txt$(cy) = LEFT$(l$, cx - 1)
            cy = cy + 1: cx = 1: changed = -1
            Redraw
        CASE CHR$(8)                              ' Backspace
            IF cx > 1 THEN
                txt$(cy) = LEFT$(l$, cx - 2) + MID$(l$, cx): cx = cx - 1
            ELSEIF cy > 1 THEN                    ' join with line above
                cx = LEN(txt$(cy - 1)) + 1
                txt$(cy - 1) = txt$(cy - 1) + l$
                DeleteLine cy: cy = cy - 1
                Redraw
            END IF
            changed = -1
        CASE IS >= " "                            ' printable: insert
            IF LEN(l$) < 78 THEN
                txt$(cy) = LEFT$(l$, cx - 1) + k$ + MID$(l$, cx)
                cx = cx + 1: changed = -1
            END IF
        END SELECT
    END IF
    ' Redraw just the current line (fast) after most edits.
    IF cy >= top AND cy < top + VIEWH THEN
        LOCATE cy - top + 2, 1, 0: PRINT txt$(cy); SPACE$(80 - LEN(txt$(cy)));
    END IF
LOOP
COLOR 7, 0: CLS
PRINT "Bye! Last file: "; fileName$
END

NoFile:
    loadErr = ERR
    RESUME NEXT

SUB DeleteLine (at%)
    FOR i = at% TO nLines - 1: txt$(i) = txt$(i + 1): NEXT
    txt$(nLines) = ""
    IF nLines > 1 THEN nLines = nLines - 1
END SUB

' Make room for a new empty line at position at% by shifting the
' rest of the document down one place.
SUB InsertLine (at%)
    IF nLines >= MAXL THEN EXIT SUB
    FOR i = nLines TO at% STEP -1: txt$(i + 1) = txt$(i): NEXT
    txt$(at%) = ""
    nLines = nLines + 1
END SUB

' Read the file into txt$(). A missing file just gives an empty
' document (which F2 will create).
SUB LoadFile (f$)
    SHARED loadErr
    FOR i = 1 TO MAXL: txt$(i) = "": NEXT
    nLines = 0
    loadErr = 0
    ON ERROR GOTO NoFile
    OPEN f$ FOR INPUT AS #1
    ON ERROR GOTO 0
    IF loadErr = 0 THEN
        DO WHILE NOT EOF(1) AND nLines < MAXL
            nLines = nLines + 1
            LINE INPUT #1, txt$(nLines)
            ' Long lines are cut, because we do not scroll sideways.
            txt$(nLines) = LEFT$(txt$(nLines), 78)
        LOOP
        CLOSE #1
    END IF
    IF nLines = 0 THEN nLines = 1      ' always at least one line
    cx = 1: cy = 1: top = 1: changed = 0
END SUB

SUB Redraw
    COLOR 0, 3: LOCATE 1, 1
    PRINT LEFT$(" TINY EDIT - " + fileName$ + SPACE$(80), 80);
    COLOR 7, 1
    FOR r = 0 TO VIEWH - 1
        LOCATE r + 2, 1
        i = top + r
        IF i <= nLines THEN
            PRINT txt$(i); SPACE$(80 - LEN(txt$(i)));
        ELSE
            COLOR 8: PRINT "~"; SPACE$(79); : COLOR 7
        END IF
    NEXT
    Status "F2 Save  F3 Open  Esc Quit"
END SUB

' Write every line out. OUTPUT mode replaces the old file contents.
SUB SaveFile (f$)
    OPEN f$ FOR OUTPUT AS #1
    FOR i = 1 TO nLines
        PRINT #1, txt$(i)
    NEXT
    CLOSE #1
    changed = 0
    Status "Saved" + STR$(nLines) + " lines to " + f$
END SUB

SUB Status (msg$)
    LOCATE 25, 1: COLOR 0, 3
    PRINT LEFT$(" " + msg$ + SPACE$(80), 58);
    COLOR 7, 1
END SUB
