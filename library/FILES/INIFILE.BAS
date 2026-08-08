' ============================================================
' TITLE:    INI Settings File
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, settings, ini, parsing, configuration
' SUMMARY:  Read and write a Windows-style .INI settings file with [sections] and key=value pairs.
' ------------------------------------------------------------
' WHAT IT DOES
'   Many programs remember your preferences in a text file like:
'       [Display]
'       Color=14
'       ; this is a comment
'   This program keeps GAME.INI in that format. It loads it into
'   memory, lets you change values, and writes it back, keeping
'   comments and the order of everything intact. A little preview
'   uses the settings (colour, player name, a sound on/off flag).
'
' HOW TO USE
'   V view the file   C change a setting   P preview with settings
'   R reset to defaults   Q quit
'
' CONCEPTS YOU WILL LEARN
'   * Parsing lines: comments, [section] headers, key=value
'   * Looking values up by section + key (case-insensitive)
'   * Updating a value in place, or adding a missing key
'   * Default values when a key is not present
'
' THINGS TO TRY
'   * Add a "D" option to delete a key.
'   * Support values in quotes with spaces at both ends.
' ============================================================

DECLARE FUNCTION GetIni$ (sect$, key$, default$)
DECLARE SUB SetIni (sect$, key$, value$)
DECLARE SUB LoadIni ()
DECLARE SUB SaveIni ()
DECLARE SUB WriteDefaults ()

CONST INIF = "GAME.INI"
CONST MAXL = 200
DIM SHARED ini$(1 TO MAXL), nIni

' ---- create the file the first time ----------------------------
ON ERROR GOTO Missing
OPEN INIF FOR INPUT AS #1
ON ERROR GOTO 0
CLOSE #1
LoadIni

DO
    CLS
    PRINT "SETTINGS MANAGER for "; INIF
    PRINT
    PRINT "  Player name : "; GetIni$("Player", "Name", "Nobody")
    PRINT "  Difficulty  : "; GetIni$("Player", "Difficulty", "1")
    PRINT "  Text color  : "; GetIni$("Display", "Color", "7")
    PRINT "  Sound       : "; GetIni$("Sound", "Enabled", "yes")
    PRINT
    PRINT "V)iew file  C)hange  P)review  R)eset  Q)uit"
    k$ = UCASE$(INPUT$(1))
    SELECT CASE k$
    CASE "V"
        PRINT : PRINT "--- "; INIF; " ---"
        FOR i = 1 TO nIni: PRINT ini$(i): NEXT
        PRINT "--- end ---": PRINT "Press a key."
        k$ = INPUT$(1)
    CASE "C"
        PRINT
        LINE INPUT "Section (e.g. Player): "; s$
        LINE INPUT "Key     (e.g. Name)  : "; ky$
        IF s$ <> "" AND ky$ <> "" THEN
            PRINT "Current value: "; GetIni$(s$, ky$, "(not set)")
            LINE INPUT "New value: "; v$
            SetIni s$, ky$, v$
            SaveIni                          ' write straight back to disk
            PRINT "Saved.": SLEEP 1
        END IF
    CASE "P"
        ' Use the settings for real.
        c = VAL(GetIni$("Display", "Color", "7"))
        IF c < 1 OR c > 15 THEN c = 7
        CLS : COLOR c
        PRINT "Hello, "; GetIni$("Player", "Name", "Nobody"); "!"
        PRINT "Difficulty level "; GetIni$("Player", "Difficulty", "1"); " selected."
        IF LCASE$(GetIni$("Sound", "Enabled", "yes")) = "yes" THEN
            PRINT "(beep!)": SOUND 880, 2
        ELSE
            PRINT "(sound is off)"
        END IF
        COLOR 7: PRINT : PRINT "Press a key."
        k$ = INPUT$(1)
    CASE "R"
        WriteDefaults: LoadIni
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
CLS
END

Missing:
    ' No INI file yet: write the defaults and try again.
    WriteDefaults
    RESUME

' Look up sect$/key$. Walk through the lines remembering which
' section we are in; return the text after "=" when we match.
FUNCTION GetIni$ (sect$, key$, default$)
    cur$ = ""
    FOR i = 1 TO nIni
        l$ = LTRIM$(RTRIM$(ini$(i)))
        IF LEFT$(l$, 1) = "[" THEN
            cur$ = UCASE$(MID$(l$, 2, INSTR(l$, "]") - 2))
        ELSEIF LEFT$(l$, 1) <> ";" AND INSTR(l$, "=") > 0 THEN
            IF cur$ = UCASE$(sect$) THEN
                eq = INSTR(l$, "=")
                IF UCASE$(RTRIM$(LEFT$(l$, eq - 1))) = UCASE$(key$) THEN
                    GetIni$ = LTRIM$(MID$(l$, eq + 1))
                    EXIT FUNCTION
                END IF
            END IF
        END IF
    NEXT
    GetIni$ = default$
END FUNCTION

SUB LoadIni
    nIni = 0
    OPEN INIF FOR INPUT AS #1
    DO WHILE NOT EOF(1) AND nIni < MAXL
        nIni = nIni + 1
        LINE INPUT #1, ini$(nIni)
    LOOP
    CLOSE #1
END SUB

SUB SaveIni
    OPEN INIF FOR OUTPUT AS #1
    FOR i = 1 TO nIni: PRINT #1, ini$(i): NEXT
    CLOSE #1
END SUB

' Set a value. Three cases:
'   1. the key exists in the section  -> replace that line
'   2. the section exists, key doesn't -> insert after the last line
'      of that section
'   3. no such section                 -> add section + key at the end
SUB SetIni (sect$, key$, value$)
    cur$ = "": lastInSect = 0
    FOR i = 1 TO nIni
        l$ = LTRIM$(RTRIM$(ini$(i)))
        IF LEFT$(l$, 1) = "[" THEN
            cur$ = UCASE$(MID$(l$, 2, INSTR(l$, "]") - 2))
            IF cur$ = UCASE$(sect$) THEN lastInSect = i
        ELSEIF cur$ = UCASE$(sect$) THEN
            IF l$ <> "" THEN lastInSect = i
            eq = INSTR(l$, "=")
            IF eq > 0 AND LEFT$(l$, 1) <> ";" THEN
                IF UCASE$(RTRIM$(LEFT$(l$, eq - 1))) = UCASE$(key$) THEN
                    ini$(i) = RTRIM$(LEFT$(l$, eq - 1)) + "=" + value$
                    EXIT SUB
                END IF
            END IF
        END IF
    NEXT
    IF nIni + 3 > MAXL THEN EXIT SUB
    IF lastInSect = 0 THEN
        nIni = nIni + 1: ini$(nIni) = ""          ' blank line for neatness
        nIni = nIni + 1: ini$(nIni) = "[" + sect$ + "]"
        lastInSect = nIni
    END IF
    ' Shift lines down to open a gap after lastInSect.
    FOR i = nIni TO lastInSect + 1 STEP -1: ini$(i + 1) = ini$(i): NEXT
    ini$(lastInSect + 1) = key$ + "=" + value$
    nIni = nIni + 1
END SUB

SUB WriteDefaults
    OPEN INIF FOR OUTPUT AS #1
    PRINT #1, "; Settings for the demo game"
    PRINT #1, "; Lines starting with ; are comments"
    PRINT #1, ""
    PRINT #1, "[Player]"
    PRINT #1, "Name=Hero"
    PRINT #1, "Difficulty=2"
    PRINT #1, ""
    PRINT #1, "[Display]"
    PRINT #1, "Color=11"
    PRINT #1, ""
    PRINT #1, "[Sound]"
    PRINT #1, "Enabled=yes"
    CLOSE #1
END SUB
