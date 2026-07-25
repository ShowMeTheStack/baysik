' ============================================================
' TITLE:    Key=Value Config Parser
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     parsing, INI files, files, key value, sections, INSTR
' SUMMARY:  Writes and reads an INI-style settings file with [sections], key=value pairs and comments.
' ------------------------------------------------------------
' WHAT IT DOES
'   Lots of programs store their settings in plain text like:
'       ; my game settings
'       [player]
'       name = Ada
'       lives = 3
'   This program writes such a file (GAME.INI) to disk, reads it
'   back line by line, and parses it:
'     * blank lines and lines starting with ; or # are comments
'     * [name] starts a new section
'     * key = value  is split at the FIRST "=" and both sides trimmed
'     * values in "quotes" keep their spaces
'   Keys are stored as "section.key" so you can look them up.
'   Then you can query, change and save settings interactively.
'
' HOW TO USE
'   Commands at the > prompt:
'     LIST                  show all settings
'     GET player.name       show one value
'     SET sound.volume=7    change or add a value
'     SAVE                  write the file back to disk
'     QUIT                  leave
'
' CONCEPTS YOU WILL LEARN
'   * OPEN ... FOR OUTPUT / INPUT and LINE INPUT # / PRINT #
'   * Splitting a line at a delimiter with INSTR, LEFT$ and MID$
'   * Trimming, comment handling, error reporting with line numbers
'   * VAL to turn a setting into a number
'
' THINGS TO TRY
'   * Keep the comments when saving the file
'   * Support "include = other.ini"
'   * Add a DEL command to remove a key
' ============================================================

DECLARE SUB ParseFile (f$)
DECLARE SUB SetValue (k$, v$)
DECLARE FUNCTION FindKey% (k$)
DECLARE FUNCTION Trim$ (s$)

CONST MAXK = 50
DIM SHARED key$(MAXK), value$(MAXK), nk

CLS
COLOR 14: PRINT "KEY=VALUE CONFIG PARSER": COLOR 7
PRINT

' ---- 1. write a sample file so there is something to read ----
OPEN "GAME.INI" FOR OUTPUT AS #1
PRINT #1, "; Settings for an imaginary game"
PRINT #1, "title = Space Rescue"
PRINT #1, ""
PRINT #1, "[player]"
PRINT #1, "name = Ada"
PRINT #1, "lives=3"
PRINT #1, "greeting = " + CHR$(34) + "  Hello, pilot!  " + CHR$(34)
PRINT #1, "# speed in pixels per frame"
PRINT #1, "speed = 2.5"
PRINT #1, ""
PRINT #1, "[sound]"
PRINT #1, "volume = 8"
PRINT #1, "music = on"
PRINT #1, "this line is broken"
PRINT #1, "equation = a=b+c"
CLOSE #1
PRINT "Wrote GAME.INI.  Its contents:"
COLOR 8
OPEN "GAME.INI" FOR INPUT AS #1
DO WHILE NOT EOF(1)
    LINE INPUT #1, L$
    PRINT "  | "; L$
LOOP
CLOSE #1
COLOR 7
PRINT

' ---- 2. parse it ----
ParseFile "GAME.INI"
PRINT "Parsed"; nk; "settings.  ";
' an example of using a value as a number
lv = VAL(value$(FindKey%("player.lives")))
PRINT "Ada has"; lv; "lives, so"; lv * 100; "bonus points!"

' ---- 3. little command interpreter ----
DO
    PRINT
    LINE INPUT "> "; cmd$
    cmd$ = Trim$(cmd$)
    sp = INSTR(cmd$, " ")
    IF sp THEN verb$ = UCASE$(LEFT$(cmd$, sp - 1)): arg$ = Trim$(MID$(cmd$, sp + 1)) ELSE verb$ = UCASE$(cmd$): arg$ = ""
    SELECT CASE verb$
        CASE "LIST"
            FOR i = 1 TO nk
                PRINT "  "; LEFT$(key$(i) + SPACE$(18), 18); "= ["; value$(i); "]"
            NEXT i
        CASE "GET"
            i = FindKey%(LCASE$(arg$))
            IF i THEN PRINT "  ["; value$(i); "]" ELSE PRINT "  No such key: "; arg$
        CASE "SET"
            eq = INSTR(arg$, "=")
            IF eq = 0 THEN
                PRINT "  Use: SET section.key=value"
            ELSE
                SetValue LCASE$(Trim$(LEFT$(arg$, eq - 1))), Trim$(MID$(arg$, eq + 1))
                PRINT "  OK"
            END IF
        CASE "SAVE"
            ' rebuild the file, grouping keys by their section part
            OPEN "GAME.INI" FOR OUTPUT AS #1
            PRINT #1, "; saved by KEYVALUE.BAS"
            lastSec$ = ""
            FOR i = 1 TO nk
                dot = INSTR(key$(i), ".")
                IF dot THEN sec$ = LEFT$(key$(i), dot - 1) ELSE sec$ = ""
                IF sec$ <> lastSec$ THEN PRINT #1, "[" + sec$ + "]": lastSec$ = sec$
                PRINT #1, MID$(key$(i), dot + 1) + " = " + value$(i)
            NEXT i
            CLOSE #1
            PRINT "  Saved"; nk; "settings to GAME.INI"
        CASE "QUIT", "Q", "EXIT"
            EXIT DO
        CASE ""
        CASE ELSE
            PRINT "  Commands: LIST, GET key, SET key=value, SAVE, QUIT"
    END SELECT
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' ParseFile: read every line and decide what kind it is.
' Keys outside any section (like "title") have no prefix.
' Lines without "=" are reported as errors but do not stop us.
' ------------------------------------------------------------
SUB ParseFile (f$)
    nk = 0: section$ = "": ln = 0
    OPEN f$ FOR INPUT AS #1
    DO WHILE NOT EOF(1)
        LINE INPUT #1, L$
        ln = ln + 1
        L$ = Trim$(L$)
        first$ = LEFT$(L$, 1)
        IF L$ = "" OR first$ = ";" OR first$ = "#" THEN
            ' blank or comment: skip
        ELSEIF first$ = "[" AND RIGHT$(L$, 1) = "]" THEN
            section$ = LCASE$(Trim$(MID$(L$, 2, LEN(L$) - 2)))
        ELSE
            eq = INSTR(L$, "=")              ' FIRST "=" only: a=b+c is fine
            IF eq = 0 THEN
                COLOR 12: PRINT "  Line"; ln; "ignored (no '='): "; L$: COLOR 7
            ELSE
                k$ = LCASE$(Trim$(LEFT$(L$, eq - 1)))
                v$ = Trim$(MID$(L$, eq + 1))
                ' strip surrounding quotes, keeping the spaces inside
                IF LEN(v$) >= 2 AND LEFT$(v$, 1) = CHR$(34) AND RIGHT$(v$, 1) = CHR$(34) THEN
                    v$ = MID$(v$, 2, LEN(v$) - 2)
                END IF
                IF section$ <> "" THEN k$ = section$ + "." + k$
                SetValue k$, v$
            END IF
        END IF
    LOOP
    CLOSE #1
END SUB

' SetValue: replace the value if the key exists, else add it.
SUB SetValue (k$, v$)
    i = FindKey%(k$)
    IF i = 0 THEN
        IF nk >= MAXK THEN PRINT "  Too many keys!": EXIT SUB
        nk = nk + 1: i = nk: key$(i) = k$
    END IF
    value$(i) = v$
END SUB

' FindKey%: index of the key, or 0 if it is not there.
FUNCTION FindKey% (k$)
    FindKey% = 0
    FOR i = 1 TO nk
        IF key$(i) = k$ THEN FindKey% = i: EXIT FUNCTION
    NEXT i
END FUNCTION

' Trim$: remove spaces and tabs from both ends.
FUNCTION Trim$ (s$)
    a = 1: b = LEN(s$)
    DO WHILE a <= b
        IF MID$(s$, a, 1) <> " " AND MID$(s$, a, 1) <> CHR$(9) THEN EXIT DO
        a = a + 1
    LOOP
    DO WHILE b >= a
        IF MID$(s$, b, 1) <> " " AND MID$(s$, b, 1) <> CHR$(9) THEN EXIT DO
        b = b - 1
    LOOP
    Trim$ = MID$(s$, a, b - a + 1)
END FUNCTION
