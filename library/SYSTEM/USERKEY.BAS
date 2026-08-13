' ============================================================
' TITLE:    Custom Hotkeys with KEY 15-25
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     key trapping, scan codes, hotkeys, ctrl, alt, events
' SUMMARY:  Define your own trappable hotkeys (Ctrl+U, Alt+R...) from shift flags and scan codes.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keys 1-14 (F-keys and arrows) are built in, but BASIC also gives
'   you eleven spare trap slots, KEY 15 to KEY 25.  You fill a slot
'   with a 2-byte string:
'       KEY n, CHR$(shiftflags) + CHR$(scancode)
'   The scan code is the number the keyboard hardware sends for a
'   physical key (it is NOT the ASCII code).  The shift flags say which
'   modifier keys must be held down.
'   This little editor uses five custom hotkeys to edit a line of text.
'
' HOW TO USE
'   Type some text.  Then try the hotkeys:
'     Ctrl+U  UPPERCASE the line     Ctrl+L  lowercase the line
'     Alt+R   reverse the line       Alt+C   clear the line
'     Alt+X   quit   (Esc also quits)
'
' CONCEPTS YOU WILL LEARN
'   * Keyboard scan codes (Q=16, W=17 ... see the table in DATA lines)
'   * Shift-flag byte: 1/2 = Shift, 4 = Ctrl, 8 = Alt, 64 = Caps Lock
'   * KEY n, CHR$(flags) + CHR$(scan) then ON KEY(n) GOSUB
'   * A trapped key is "eaten": INKEY$ never sees it
'
' THINGS TO TRY
'   * Add Ctrl+T to swap the last two characters
'   * Trap the plain Space bar: KEY 20, CHR$(0) + CHR$(57)
'   * Print the scan code table for the whole keyboard
' ============================================================

DEFINT A-Z
CONST FCTRL = 4, FALT = 8      ' shift-flag bits

' ---- scan codes for the letters we use -----------------------------
' Scan codes follow the physical layout of the keyboard rows:
'   Q W E R T Y U I O P  = 16..25
'   A S D F G H J K L    = 30..38
'   Z X C V B N M        = 44..50
CONST SCANU = 22, SCANL = 38, SCANR = 19, SCANC = 46, SCANX = 45

KEY 15, CHR$(FCTRL) + CHR$(SCANU)    ' Ctrl+U
KEY 16, CHR$(FCTRL) + CHR$(SCANL)    ' Ctrl+L
KEY 17, CHR$(FALT) + CHR$(SCANR)     ' Alt+R
KEY 18, CHR$(FALT) + CHR$(SCANC)     ' Alt+C
KEY 19, CHR$(FALT) + CHR$(SCANX)     ' Alt+X

ON KEY(15) GOSUB DoUpper
ON KEY(16) GOSUB DoLower
ON KEY(17) GOSUB DoReverse
ON KEY(18) GOSUB DoClear
ON KEY(19) GOSUB DoQuit
FOR k = 15 TO 19: KEY(k) ON: NEXT k

CLS
PRINT "CUSTOM HOTKEY EDITOR"
PRINT STRING$(60, 196)
PRINT "Ctrl+U upper   Ctrl+L lower   Alt+R reverse   Alt+C clear"
PRINT "Alt+X or Esc quits"
PRINT
PRINT "Slot  Flags  Scan  Meaning"
RESTORE SlotTable
FOR i = 1 TO 5
    READ slot, fl, sc, m$
    PRINT USING " ##    ###   ###  &"; slot; fl; sc; m$
NEXT i

text$ = "": quitting = 0: lastAction$ = "(none yet)"
GOSUB ShowLine

DO
    k$ = INKEY$
    IF k$ = CHR$(27) THEN quitting = 1
    IF k$ = CHR$(8) AND LEN(text$) > 0 THEN text$ = LEFT$(text$, LEN(text$) - 1): GOSUB ShowLine
    IF LEN(k$) = 1 THEN
        IF k$ >= " " AND LEN(text$) < 60 THEN text$ = text$ + k$: GOSUB ShowLine
    END IF
LOOP UNTIL quitting

KEY(0) OFF
CLS
PRINT "Final text: "; text$
END

' ---------------- handlers -------------------------------------------
DoUpper:   text$ = UCASE$(text$): lastAction$ = "Ctrl+U -> UCASE$": GOSUB ShowLine: RETURN
DoLower:   text$ = LCASE$(text$): lastAction$ = "Ctrl+L -> LCASE$": GOSUB ShowLine: RETURN
DoClear:   text$ = "": lastAction$ = "Alt+C -> cleared": GOSUB ShowLine: RETURN
DoQuit:    quitting = 1: RETURN

DoReverse:
    r$ = ""
    FOR i = LEN(text$) TO 1 STEP -1        ' walk backwards through the text
        r$ = r$ + MID$(text$, i, 1)
    NEXT i
    text$ = r$
    lastAction$ = "Alt+R -> reversed"
    GOSUB ShowLine
RETURN

ShowLine:
    LOCATE 15, 1: PRINT "Text: "; text$; SPACE$(62 - LEN(text$));
    LOCATE 17, 1: PRINT "Last hotkey: "; lastAction$; SPACE$(30);
    LOCATE 15, 7 + LEN(text$)
RETURN

SlotTable:
DATA 15, 4, 22, "Ctrl + U"
DATA 16, 4, 38, "Ctrl + L"
DATA 17, 8, 19, "Alt + R"
DATA 18, 8, 46, "Alt + C"
DATA 19, 8, 45, "Alt + X"
