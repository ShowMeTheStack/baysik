' ============================================================
' TITLE:    Starship Alert Panel
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     blink, color, attributes, text mode, sound
' SUMMARY:  A spaceship control panel where alarms switch to BLINKING text using colours 16-31.
' ------------------------------------------------------------
' WHAT IT DOES
'   Text mode has a built-in effect that needs no animation code at
'   all: blinking!  Add 16 to any foreground colour (COLOR 28 is a
'   blinking light red) and the video card makes the text flash on
'   its own.  This panel shows six ship systems.  Press a number to
'   break or fix a system: broken systems blink red, and when three
'   or more are broken a big RED ALERT banner blinks too.
'
' HOW TO USE
'   1-6   toggle a ship system between OK and FAULT
'   A     all systems OK
'   Esc or Q  quit
'
' CONCEPTS YOU WILL LEARN
'   * COLOR fg + 16 makes blinking text
'   * Why only 8 background colours: the "blink bit" in the attribute
'     byte uses the place where a 9th-16th background would go
'   * Keeping program state in an array and redrawing from it
'
' THINGS TO TRY
'   * Make faults appear at random as time passes.
'   * Add a "shield level" bar that drops while systems are broken.
' ============================================================

DEFINT A-Z
DECLARE SUB DrawPanel ()

DIM SHARED sys$(1 TO 6), broken(1 TO 6)
FOR i = 1 TO 6: READ sys$(i): NEXT i
DATA "Warp engines","Shields","Life support","Navigation","Phasers","Coffee machine"

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS
broken(6) = 1            ' the coffee machine is always broken first :-)
DrawPanel

DO
    k$ = UCASE$(INPUT$(1))
    SELECT CASE k$
        CASE "1" TO "6"
            n = VAL(k$)
            broken(n) = 1 - broken(n)          ' flip 0 <-> 1
            IF broken(n) THEN SOUND 300, 3 ELSE SOUND 1200, 2
        CASE "A"
            FOR i = 1 TO 6: broken(i) = 0: NEXT i
            SOUND 1500, 2
        CASE CHR$(27), "Q"
            EXIT DO
    END SELECT
    DrawPanel
LOOP
COLOR 7, 0: CLS
END

SUB DrawPanel
    COLOR 7, 0: CLS
    ' ---- title ----
    COLOR 11, 1
    LOCATE 2, 20: PRINT "  U.S.S. QBASIC  -  SYSTEM STATUS PANEL  "

    ' ---- one line per system ----
    nBroken = 0
    FOR i = 1 TO 6
        r = 5 + i * 2
        COLOR 7, 0
        LOCATE r, 15: PRINT i; " "; sys$(i);
        LOCATE r, 35: PRINT STRING$(10, 250);
        LOCATE r, 47
        IF broken(i) THEN
            nBroken = nBroken + 1
            ' 12 = light red.  12 + 16 = 28 = BLINKING light red.
            ' Inside the video card each cell has an attribute byte:
            '    bit 7    = blink      bits 6-4 = background (0-7)
            '    bits 3-0 = foreground (0-15)
            ' COLOR 28, 0 stores 1 000 1100 binary = &H8C.  Because bit
            ' 7 is used for blinking, only 3 bits are left for the
            ' background - that's why backgrounds only go up to 7.
            COLOR 12 + 16, 0
            PRINT CHR$(4); " FAULT "; CHR$(4);
        ELSE
            COLOR 10, 0
            PRINT "   OK    ";
        END IF
        ' A little "LED" on the left: a blinking yellow dot for faults.
        LOCATE r, 11
        IF broken(i) THEN COLOR 14 + 16, 0 ELSE COLOR 2, 0
        ' (We use CHR$(254), a small square.  PRINT CHR$(7) would not
        ' show a dot - code 7 is the "bell" control code and beeps!)
        PRINT CHR$(254);
    NEXT i

    ' ---- the RED ALERT banner ----
    IF nBroken >= 3 THEN
        ' Blinking white text on a red background: COLOR 15 + 16, 4
        COLOR 31, 4
        LOCATE 21, 25: PRINT SPACE$(30);
        LOCATE 22, 25: PRINT "    *** RED  ALERT ***        ";
        LOCATE 23, 25: PRINT SPACE$(30);
    ELSEIF nBroken > 0 THEN
        COLOR 14, 0
        LOCATE 22, 25: PRINT "  Caution: systems need repair";
    ELSE
        COLOR 10, 0
        LOCATE 22, 25: PRINT "  All systems nominal, Captain.";
    END IF

    COLOR 8, 0
    LOCATE 25, 12: PRINT "1-6 = break/fix a system    A = repair all    Esc = quit";
END SUB
