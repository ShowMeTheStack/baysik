' ============================================================
' TITLE:    Keyboard Code Viewer
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     inkey$, scan codes, inp, keyboard, ports, extended keys
' SUMMARY:  Press any key to see its INKEY$ code, ASCII value and raw hardware scan code from port &H60.
' ------------------------------------------------------------
' WHAT IT DOES
'   A handy reference tool for game and menu programmers.  For
'   every key you press it shows:
'     * what INKEY$ returned, as text and as numbers.
'       Normal keys give ONE character (its ASCII code).
'       Special keys (arrows, F1-F10, Home...) give TWO
'       characters: CHR$(0) followed by a "scan code".
'     * the RAW scan code read straight from the keyboard
'       controller with INP(&H60).  The keyboard sends a "make"
'       code when a key goes down and a "break" code (make + 128)
'       when it comes up - this is how games detect keys being
'       HELD, which INKEY$ cannot tell you.
'   A log of the last keys is kept on screen.
'
' HOW TO USE
'   Press keys and watch.  Press Esc twice in a row to quit
'   (the first Esc is shown like any other key).
'
' CONCEPTS YOU WILL LEARN
'   * INKEY$, LEN, ASC, and the CHR$(0) prefix for extended keys
'   * INP(port) to read a hardware I/O port
'   * Make and break codes; testing bit 7 with AND 128
'   * Looking up names in DATA with a key code
'
' THINGS TO TRY
'   * Keep an array of which keys are currently held down, using
'     make/break codes, and show it as a little keyboard map.
'   * Add names for more keys to the DATA list.
' ============================================================

DECLARE FUNCTION KeyName$ (code%)

CLS
COLOR 15, 1: PRINT SPACE$(80);: LOCATE 1, 28: PRINT "KEYBOARD CODE VIEWER": COLOR 7, 0
LOCATE 3, 3: PRINT "Press any key.  Esc twice = quit."
LOCATE 5, 3: PRINT "INKEY$ result :"
LOCATE 6, 3: PRINT "Length        :"
LOCATE 7, 3: PRINT "Codes         :"
LOCATE 8, 3: PRINT "Meaning       :"
LOCATE 10, 3: PRINT "Port &H60 raw :"
LOCATE 11, 3: PRINT "Up / down     :"
LOCATE 13, 3: COLOR 14: PRINT "Recent keys:": COLOR 7

lastScan% = -1: escCount = 0: logRow = 14

DO
    ' ---- 1. Watch the hardware port all the time ----
    ' INP(&H60) holds the most recent scan code the keyboard sent.
    s% = INP(&H60)
    IF s% <> lastScan% THEN
        lastScan% = s%
        LOCATE 10, 19: PRINT USING "###"; s%;
        PRINT "  (&H"; RIGHT$("0" + HEX$(s%), 2); ")   "
        LOCATE 11, 19
        ' Bit 7 (value 128) set = key RELEASED (a "break" code).
        IF s% AND 128 THEN
            PRINT "released, make code"; s% AND 127; "    "
        ELSE
            PRINT "pressed                    "
        END IF
    END IF

    ' ---- 2. And read keys the normal way with INKEY$ ----
    k$ = INKEY$
    IF k$ <> "" THEN
        LOCATE 5, 19: PRINT SPACE$(50)
        LOCATE 6, 19: PRINT SPACE$(50)
        LOCATE 7, 19: PRINT SPACE$(50)
        LOCATE 8, 19: PRINT SPACE$(50)
        LOCATE 6, 19: PRINT LEN(k$); "character(s)"
        IF LEN(k$) = 1 THEN
            c% = ASC(k$)
            LOCATE 5, 19
            ' Control characters (below 32) would mess up the screen,
            ' so show them as ^A, ^B ... instead.
            IF c% < 32 THEN PRINT "^"; CHR$(c% + 64) ELSE PRINT CHR$(34); k$; CHR$(34)
            LOCATE 7, 19: PRINT "ASC ="; c%; "  CHR$("; LTRIM$(STR$(c%)); ")"
            SELECT CASE c%
                CASE 8: m$ = "Backspace"
                CASE 9: m$ = "Tab"
                CASE 13: m$ = "Enter"
                CASE 27: m$ = "Escape"
                CASE 32: m$ = "Space"
                CASE IS < 32: m$ = "Ctrl+" + CHR$(c% + 64)
                CASE 48 TO 57: m$ = "digit"
                CASE 65 TO 90: m$ = "capital letter"
                CASE 97 TO 122: m$ = "small letter"
                CASE ELSE: m$ = "symbol"
            END SELECT
            entry$ = m$ + " =" + STR$(c%)
        ELSE
            ' Extended key: CHR$(0) then the scan code.
            sc% = ASC(MID$(k$, 2, 1))
            LOCATE 5, 19: PRINT "CHR$(0) + CHR$("; LTRIM$(STR$(sc%)); ")"
            LOCATE 7, 19: PRINT "0,"; sc%; "   test with: k$ = CHR$(0) + "; CHR$(34); CHR$(sc%); CHR$(34)
            m$ = KeyName$(sc%)
            entry$ = m$ + " = 0," + STR$(sc%)
        END IF
        LOCATE 8, 19: PRINT m$

        ' ---- Scrolling log of recent keys (rows 14..23) ----
        LOCATE logRow, 5: PRINT LEFT$(entry$ + SPACE$(40), 40)
        logRow = logRow + 1: IF logRow > 23 THEN logRow = 14
        LOCATE logRow, 5: PRINT SPACE$(40)

        ' Two Escapes in a row quits.
        IF k$ = CHR$(27) THEN escCount = escCount + 1 ELSE escCount = 0
        IF escCount >= 2 THEN EXIT DO
    END IF
LOOP
CLS
PRINT "Bye!"
END

' Names of common extended keys (the second byte after CHR$(0)).
FUNCTION KeyName$ (code%)
    RESTORE KeyNames
    DO
        READ c%, n$
        IF c% = -1 THEN KeyName$ = "extended key": EXIT FUNCTION
        IF c% = code% THEN KeyName$ = n$: EXIT FUNCTION
    LOOP
END FUNCTION

' DATA must live at module level (outside SUBs and FUNCTIONs).
' RESTORE KeyNames inside the function jumps the READ pointer here.
KeyNames:
DATA 59,F1,60,F2,61,F3,62,F4,63,F5,64,F6,65,F7,66,F8,67,F9,68,F10
DATA 133,F11,134,F12,71,Home,72,Up arrow,73,Page Up,75,Left arrow
DATA 77,Right arrow,79,End,80,Down arrow,81,Page Down,82,Insert
DATA 83,Delete,115,Ctrl+Left,116,Ctrl+Right,119,Ctrl+Home,117,Ctrl+End
DATA 15,Shift+Tab,-1,end
