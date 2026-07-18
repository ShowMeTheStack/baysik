' ============================================================
' TITLE:    Data Entry Form
' CATEGORY: Console & Text
' LEVEL:    Advanced
' TAGS:     forms, field editor, validation, files, user interface
' SUMMARY:  A full-screen form with a hand-made field editor, Tab navigation, input validation and records saved to a file.
' ------------------------------------------------------------
' WHAT IT DOES
'   Business programs in the DOS days were mostly FORMS: a screen of
'   labelled boxes you tab between and type into.  INPUT can't do
'   that (it only reads one thing, at the cursor, and scrolls the
'   screen), so programmers wrote their own field editors.  This is
'   one: a "Club Membership" form with six fields.  Each field has
'   a type (text, number, or date) and the editor refuses keys that
'   don't fit.  F10 checks every field and appends the record to
'   MEMBERS.DAT; F2 lists the saved members.
'
' HOW TO USE
'   Tab / Down / Enter  next field      Shift+Tab / Up  previous field
'   Left / Right / Home / End  move inside a field
'   Backspace / Del  delete       Ins  toggle insert/overwrite
'   F10  save record    F2  list saved records    Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * A TYPE to describe each field (position, width, kind, label)
'   * A real line editor: cursor position, insert vs overwrite
'   * Validating input both per-key and per-field
'   * Appending records to a text file and reading them back
'
' THINGS TO TRY
'   * Add a Yes/No field type that only accepts Y or N.
'   * Make F3 load the last saved record back into the form.
'   * Add a field that is calculated (e.g. age from date of birth).
' ============================================================

DEFINT A-Z
TYPE FieldT
    row AS INTEGER
    col AS INTEGER           ' column where the input box starts
    wid AS INTEGER           ' box width (max characters)
    kind AS STRING * 1       ' "T" text, "N" number, "D" date MM-DD-YYYY
    label AS STRING * 16
END TYPE
' The typed text lives in a normal string array, fv$(), rather than in
' the TYPE: a fixed-length STRING * n is always padded with spaces, so
' we could not tell "Pac " (with a real space typed) from "Pac".

DECLARE SUB DrawForm ()
DECLARE SUB DrawField (i, active)
DECLARE SUB EditField (i, ky$)
DECLARE SUB StatusMsg (t$, colr)
DECLARE SUB ListRecords ()
DECLARE FUNCTION Valid$ (i)
DECLARE FUNCTION FileExists (f$)

CONST NF = 6
CONST DATAFILE = "MEMBERS.DAT"
DIM SHARED fld(1 TO NF) AS FieldT, fv$(1 TO NF)
DIM SHARED cur, curPos, insMode

' Field definitions: label, row, width, kind
FOR i = 1 TO NF
    READ lb$, fld(i).row, fld(i).wid, fld(i).kind
    fld(i).label = lb$
    fld(i).col = 30
    fv$(i) = ""
NEXT i
DATA "First name",6,20,"T"
DATA "Last name",8,20,"T"
DATA "Age",10,3,"N"
DATA "Joined (date)",12,10,"D"
DATA "Favourite game",14,30,"T"
DATA "High score",16,8,"N"

SCREEN 0: WIDTH 80, 25
cur = 1: curPos = 1: insMode = 1
DrawForm

DO
    ' Put the blinking cursor in the right place.  Insert mode shows
    ' a thin underline cursor, overwrite mode a big block cursor.
    IF insMode THEN LOCATE , , 1, 6, 7 ELSE LOCATE , , 1, 0, 7
    LOCATE fld(cur).row, fld(cur).col + curPos - 1
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    LOCATE , , 0
    ' Shift+Tab gives CHR$(0) + CHR$(15).  F2 = 60, F10 = 68.
    SELECT CASE k$
        CASE CHR$(9), CHR$(13), CHR$(0) + "P"          ' Tab, Enter, Down
            DrawField cur, 0
            cur = cur MOD NF + 1: curPos = 1
            DrawField cur, 1
        CASE CHR$(0) + CHR$(15), CHR$(0) + "H"         ' Shift+Tab, Up
            DrawField cur, 0
            cur = (cur + NF - 2) MOD NF + 1: curPos = 1
            DrawField cur, 1
        CASE CHR$(0) + CHR$(68)                        ' F10 = save
            bad$ = ""
            FOR i = 1 TO NF
                e$ = Valid$(i)
                IF e$ <> "" AND bad$ = "" THEN bad$ = e$: badF = i
            NEXT i
            IF bad$ <> "" THEN
                StatusMsg bad$, 12
                DrawField cur, 0: cur = badF: curPos = 1: DrawField cur, 1
                SOUND 220, 4
            ELSE
                ' One record per line, fields separated by commas.  The
                ' text fields are written with quotes (WRITE does that)
                ' so names containing commas still read back correctly.
                f = FREEFILE
                OPEN DATAFILE FOR APPEND AS #f
                WRITE #f, RTRIM$(fv$(1)), RTRIM$(fv$(2)), VAL(fv$(3)), RTRIM$(fv$(4)), RTRIM$(fv$(5)), VAL(fv$(6))
                CLOSE #f
                FOR i = 1 TO NF: fv$(i) = "": NEXT i
                cur = 1: curPos = 1
                DrawForm
                StatusMsg "Record saved to " + DATAFILE + ". Form cleared for the next member.", 10
                SOUND 880, 2: SOUND 1320, 2
            END IF
        CASE CHR$(0) + CHR$(60)                        ' F2 = list
            ListRecords
            DrawForm
        CASE CHR$(27)
            EXIT DO
        CASE ELSE
            EditField cur, k$
    END SELECT
LOOP
COLOR 7, 0: CLS
LOCATE , , 1, 6, 7
END

SUB DrawField (i, active)
    ' The box shows the value padded with dots so you can see its size.
    v$ = LEFT$(fv$(i), fld(i).wid)
    IF active THEN COLOR 15, 2 ELSE COLOR 0, 3
    LOCATE fld(i).row, fld(i).col
    PRINT v$; STRING$(fld(i).wid - LEN(v$), 250);
    ' The label goes yellow when its field is the active one.
    IF active THEN COLOR 14, 1 ELSE COLOR 7, 1
    LOCATE fld(i).row, 8: PRINT fld(i).label;
    ' A hint showing the field type.
    COLOR 8, 1
    LOCATE fld(i).row, fld(i).col + fld(i).wid + 2
    SELECT CASE fld(i).kind
        CASE "N": PRINT "(number)  ";
        CASE "D": PRINT "MM-DD-YYYY";
        CASE ELSE: PRINT "          ";
    END SELECT
END SUB

SUB DrawForm
    COLOR 7, 1: CLS
    COLOR 15, 4: LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 3: PRINT "BASIC GAMERS CLUB  -  Membership Form";
    COLOR 11, 1
    LOCATE 3, 5: PRINT CHR$(218); STRING$(70, 196); CHR$(191)
    FOR r = 4 TO 18
        LOCATE r, 5: PRINT CHR$(179); : LOCATE r, 76: PRINT CHR$(179)
    NEXT r
    LOCATE 19, 5: PRINT CHR$(192); STRING$(70, 196); CHR$(217)
    FOR i = 1 TO NF
        DrawField i, (i = cur)
    NEXT i
    COLOR 0, 7
    LOCATE 23, 1: PRINT SPACE$(80);
    LOCATE 23, 2: PRINT "Tab/Shift+Tab fields  Arrows/Home/End move  Ins insert  F10 save  F2 list  Esc";
END SUB

' Handle one key inside the current field: movement, deleting and
' typing.  Per-key validation: numbers only accept digits, dates
' only digits and "-".
SUB EditField (i, ky$)
    v$ = fv$(i)
    w = fld(i).wid
    IF LEN(ky$) = 2 THEN
        SELECT CASE RIGHT$(ky$, 1)
            CASE "K": IF curPos > 1 THEN curPos = curPos - 1            ' Left
            CASE "M": IF curPos <= LEN(v$) AND curPos < w THEN curPos = curPos + 1  ' Right
            CASE "G": curPos = 1                                        ' Home
            CASE "O": curPos = LEN(v$) + 1: IF curPos > w THEN curPos = w ' End
            CASE "R": insMode = 1 - insMode                            ' Ins
            CASE "S"                                                   ' Del
                IF curPos <= LEN(v$) THEN v$ = LEFT$(v$, curPos - 1) + MID$(v$, curPos + 1)
        END SELECT
    ELSEIF ky$ = CHR$(8) THEN                                          ' Backspace
        IF curPos > 1 THEN
            v$ = LEFT$(v$, curPos - 2) + MID$(v$, curPos)
            curPos = curPos - 1
        END IF
    ELSEIF ky$ >= " " AND ky$ <= "~" THEN
        ok = 1
        IF fld(i).kind = "N" AND INSTR("0123456789", ky$) = 0 THEN ok = 0
        IF fld(i).kind = "D" AND INSTR("0123456789-", ky$) = 0 THEN ok = 0
        IF ok = 0 THEN
            SOUND 150, 1                    ' a low "nope" buzz
        ELSEIF insMode THEN
            IF LEN(v$) < w THEN
                v$ = LEFT$(v$, curPos - 1) + ky$ + MID$(v$, curPos)
                IF curPos < w THEN curPos = curPos + 1
            END IF
        ELSE                                ' overwrite mode
            IF curPos > LEN(v$) THEN
                v$ = v$ + ky$
            ELSE
                MID$(v$, curPos, 1) = ky$   ' MID$ as a statement replaces in place
            END IF
            IF curPos < w THEN curPos = curPos + 1
        END IF
    END IF
    fv$(i) = v$
    DrawField i, 1
END SUB

FUNCTION FileExists (f$)
    ' A trick that needs no error handling: OPEN FOR APPEND creates the
    ' file if it is missing, and LOF tells us how big it is.
    h = FREEFILE
    OPEN f$ FOR APPEND AS #h
    FileExists = (LOF(h) > 0)
    CLOSE #h
END FUNCTION

' Show every saved record in a table, then wait for a key.
SUB ListRecords
    COLOR 7, 0: CLS
    COLOR 15, 4: LOCATE 1, 1: PRINT SPACE$(80); : LOCATE 1, 3: PRINT "SAVED MEMBERS";
    COLOR 14, 0
    LOCATE 3, 2: PRINT "Name                       Age  Joined      Favourite game          Score"
    COLOR 8, 0: LOCATE 4, 2: PRINT STRING$(76, 196)
    n = 0
    IF FileExists(DATAFILE) THEN
        f = FREEFILE
        OPEN DATAFILE FOR INPUT AS #f
        COLOR 7, 0
        DO WHILE NOT EOF(f) AND n < 17
            INPUT #f, fn$, ln$, age, jd$, game$, score&
            n = n + 1
            LOCATE 4 + n, 2
            PRINT USING "\                       \ ###  \        \  \                    \ ########"; fn$ + " " + ln$; age; jd$; game$; score&
        LOOP
        CLOSE #f
    END IF
    IF n = 0 THEN COLOR 12, 0: LOCATE 6, 2: PRINT "No members saved yet - fill in the form and press F10."
    COLOR 10, 0: LOCATE 24, 2: PRINT n; "record(s).  Press any key to go back to the form.";
    k$ = INPUT$(1)
END SUB

SUB StatusMsg (t$, colr)
    COLOR colr, 1
    LOCATE 21, 1: PRINT SPACE$(80);
    LOCATE 21, 41 - LEN(t$) \ 2: PRINT t$;
END SUB

' Check a whole field.  Returns "" when it is fine, otherwise a
' message explaining what's wrong.
FUNCTION Valid$ (i)
    v$ = RTRIM$(fv$(i))
    l$ = RTRIM$(fld(i).label)
    Valid$ = ""
    IF i <= 2 AND v$ = "" THEN Valid$ = l$ + " must not be empty.": EXIT FUNCTION
    SELECT CASE fld(i).kind
        CASE "N"
            IF v$ = "" THEN Valid$ = l$ + " needs a number.": EXIT FUNCTION
            IF i = 3 AND (VAL(v$) < 5 OR VAL(v$) > 120) THEN Valid$ = "Age should be between 5 and 120."
        CASE "D"
            ' Expect MM-DD-YYYY with a real month and day.
            IF LEN(v$) <> 10 OR MID$(v$, 3, 1) <> "-" OR MID$(v$, 6, 1) <> "-" THEN
                Valid$ = "Date must look like 10-15-1995 (MM-DD-YYYY)."
            ELSE
                m = VAL(LEFT$(v$, 2)): d = VAL(MID$(v$, 4, 2))
                IF m < 1 OR m > 12 OR d < 1 OR d > 31 THEN Valid$ = "That date has an impossible month or day."
            END IF
    END SELECT
END FUNCTION
