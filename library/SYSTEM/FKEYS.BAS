' ============================================================
' TITLE:    Function Key Control Panel
' CATEGORY: System, Events & Hardware
' LEVEL:    Beginner
' TAGS:     on key, key, function keys, arrow keys, events
' SUMMARY:  Trap F1-F10 and the arrow keys with ON KEY(n) and label them with KEY n, text.
' ------------------------------------------------------------
' WHAT IT DOES
'   GW-BASIC and QBasic can "trap" special keys: as soon as one is
'   pressed, BASIC jumps to your subroutine, no matter what the main
'   program is doing.  This panel traps F1..F10 and the four arrow
'   keys (KEY 11..14).  The arrows move a star around a box, and the
'   function keys do various jobs.  The bottom line of the screen
'   shows the soft-key labels set with KEY n, "text" and KEY ON.
'
' HOW TO USE
'   F1 help        F2 change star colour   F3 beep
'   F4 key line on/off                     F5 clear the trail
'   Arrows move the star.   F10 or Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Key numbers: 1-10 = F1-F10, 11 = Up, 12 = Left, 13 = Right,
'     14 = Down, 30/31 = F11/F12
'   * ON KEY(n) GOSUB label   and   KEY(n) ON
'   * KEY n, "label"  /  KEY ON  /  KEY OFF  (the 25th-line key bar)
'   * Sharing variables between the trap handlers and the main loop
'
' THINGS TO TRY
'   * Use KEY(n) STOP during a long calculation so presses wait
'   * Trap F11 and F12 (KEY 30 and KEY 31)
'   * Make F6 save the drawing to a file
' ============================================================

DEFINT A-Z
CONST BX1 = 10, BY1 = 4, BX2 = 70, BY2 = 20   ' the box the star lives in

' ---- give the function keys friendly labels ------------------------
' In GW-BASIC these strings are also TYPED when you press the key at
' an INPUT prompt.  KEY ON shows the first few characters of each one
' on line 25.
KEY 1, "Help"
KEY 2, "Color"
KEY 3, "Beep"
KEY 4, "KeyBar"
KEY 5, "Clear"
KEY 6, ""
KEY 7, ""
KEY 8, ""
KEY 9, ""
KEY 10, "Quit"
KEY ON
keybar = 1

' ---- connect each key to a handler ---------------------------------
ON KEY(1) GOSUB HelpKey
ON KEY(2) GOSUB ColorKey
ON KEY(3) GOSUB BeepKey
ON KEY(4) GOSUB BarKey
ON KEY(5) GOSUB ClearKey
ON KEY(10) GOSUB QuitKey
ON KEY(11) GOSUB UpKey
ON KEY(12) GOSUB LeftKey
ON KEY(13) GOSUB RightKey
ON KEY(14) GOSUB DownKey
FOR k = 1 TO 14: KEY(k) ON: NEXT k   ' switch trapping on for each key

GOSUB DrawScreen
x = 40: y = 12: starColor = 14: quitting = 0
GOSUB DrawStar

' ---- main loop: almost nothing to do! ------------------------------
' All the work happens in the trap handlers.  The loop only checks for
' Esc (a normal key that is not trapped) and the quit flag.
DO
    IF INKEY$ = CHR$(27) THEN quitting = 1
LOOP UNTIL quitting

KEY(0) OFF                     ' KEY(0) means "all keys"
KEY OFF
CLS
PRINT "Bye!  Function keys are back to normal."
END

' ======================= handlers ===================================
UpKey:    dy = -1: dx = 0: GOSUB MoveStar: RETURN
DownKey:  dy = 1: dx = 0: GOSUB MoveStar: RETURN
LeftKey:  dx = -1: dy = 0: GOSUB MoveStar: RETURN
RightKey: dx = 1: dy = 0: GOSUB MoveStar: RETURN

HelpKey:
    LOCATE 22, 2: COLOR 11
    PRINT "F1 Help F2 Colour F3 Beep F4 KeyBar F5 Clear F10 Quit - arrows move";
    COLOR 7
RETURN

ColorKey:
    starColor = starColor + 1
    IF starColor > 15 THEN starColor = 9
    GOSUB DrawStar
RETURN

BeepKey:
    SOUND 880, 2
RETURN

BarKey:
    keybar = 1 - keybar
    IF keybar THEN KEY ON ELSE KEY OFF
RETURN

ClearKey:
    GOSUB DrawScreen
    GOSUB DrawStar
RETURN

QuitKey:
    quitting = 1
RETURN

' ---- helpers used by the handlers ----------------------------------
MoveStar:
    ' leave a dim trail behind, then step if we stay inside the box
    COLOR 8: LOCATE y, x: PRINT CHR$(250);
    IF x + dx > BX1 AND x + dx < BX2 THEN x = x + dx
    IF y + dy > BY1 AND y + dy < BY2 THEN y = y + dy
    GOSUB DrawStar
RETURN

DrawStar:
    COLOR starColor: LOCATE y, x: PRINT "*";
    COLOR 7
    LOCATE 2, 50: PRINT USING "Star at x=## y=##"; x; y;
RETURN

DrawScreen:
    CLS
    LOCATE 1, 2: PRINT "FUNCTION KEY CONTROL PANEL  (ON KEY trapping)"
    ' draw the box with line-drawing characters
    LOCATE BY1, BX1: PRINT CHR$(201); STRING$(BX2 - BX1 - 1, 205); CHR$(187);
    FOR r = BY1 + 1 TO BY2 - 1
        LOCATE r, BX1: PRINT CHR$(186);
        LOCATE r, BX2: PRINT CHR$(186);
    NEXT r
    LOCATE BY2, BX1: PRINT CHR$(200); STRING$(BX2 - BX1 - 1, 205); CHR$(188);
RETURN
