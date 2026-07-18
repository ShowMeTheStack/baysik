' ============================================================
' TITLE:    Lightbar Menu
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     menu, inkey$, arrow keys, user interface, select case
' SUMMARY:  A classic DOS-style menu with a moving highlight bar, hot keys and colour themes.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a framed menu in the middle of the screen.  A coloured
'   "lightbar" marks the current choice; move it with the arrow keys
'   and press Enter, or press the highlighted hot-key letter.  The
'   menu items do small things (show the date, roll dice, switch the
'   colour theme) so you can see how a real program is organised
'   around a menu loop.
'
' HOW TO USE
'   Up / Down    move the bar (it wraps around)
'   Enter        run the highlighted item
'   D R T A Q    hot keys for each item
'   Esc          quit
'
' CONCEPTS YOU WILL LEARN
'   * Storing menu text in an array
'   * Drawing only the two lines that changed (fast, no flicker)
'   * Reading extended keys from INKEY$
'   * A "main loop" that waits, decides, and acts
'
' THINGS TO TRY
'   * Add a sixth item.  Only the DATA and the SELECT CASE change!
'   * Make a theme that uses a blinking colour for the bar.
' ============================================================

DEFINT A-Z
DECLARE SUB DrawMenu ()
DECLARE SUB DrawItem (i)
DECLARE SUB Message (t$)

CONST NITEMS = 5
DIM SHARED item$(1 TO NITEMS), hot(1 TO NITEMS)
DIM SHARED sel, theme
DIM SHARED fgN, bgN, fgH, bgH, fgK   ' normal, highlight, hot-key colours

' Each DATA item: the text, and the position of its hot-key letter.
FOR i = 1 TO NITEMS
    READ item$(i), hot(i)
NEXT i
DATA "Date and time",1
DATA "Roll two dice",1
DATA "Change theme",8
DATA "About this menu",1
DATA "Quit",1

SCREEN 0: WIDTH 80, 25
RANDOMIZE TIMER
sel = 1: theme = 0
DrawMenu

DO
    k$ = ""
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    old = sel
    choose = 0                  ' becomes 1 when an item should run
    IF LEN(k$) = 2 THEN         ' extended key: CHR$(0) + scan code
        SELECT CASE ASC(RIGHT$(k$, 1))
            CASE 72: sel = sel - 1          ' Up
            CASE 80: sel = sel + 1          ' Down
            CASE 71: sel = 1                ' Home
            CASE 79: sel = NITEMS           ' End
        END SELECT
        IF sel < 1 THEN sel = NITEMS        ' wrap from top to bottom
        IF sel > NITEMS THEN sel = 1        ' and bottom to top
    ELSE
        SELECT CASE UCASE$(k$)
            CASE CHR$(13): choose = 1       ' Enter
            CASE CHR$(27): sel = NITEMS: choose = 1   ' Esc = Quit
            CASE ELSE
                ' Is it one of the hot keys?  Compare with each item's letter.
                FOR i = 1 TO NITEMS
                    IF UCASE$(k$) = UCASE$(MID$(item$(i), hot(i), 1)) THEN
                        sel = i: choose = 1
                    END IF
                NEXT i
        END SELECT
    END IF

    ' Redraw only the two items that changed - much faster than
    ' redrawing the whole menu and it doesn't flicker.
    IF old <> sel THEN DrawItem old: DrawItem sel

    IF choose THEN
        SELECT CASE sel
            CASE 1
                Message "Today is " + DATE$ + "   The time is " + TIME$
            CASE 2
                d1 = INT(RND * 6) + 1: d2 = INT(RND * 6) + 1
                Message "You rolled" + STR$(d1) + " and" + STR$(d2) + "  =" + STR$(d1 + d2)
            CASE 3
                theme = (theme + 1) MOD 3
                DrawMenu
            CASE 4
                Message "Arrows move the bar, Enter or a hot key picks."
            CASE 5
                EXIT DO
        END SELECT
    END IF
LOOP

COLOR 7, 0: CLS
PRINT "Goodbye!"
END

' Draw the whole screen: background, frame, title and all items.
SUB DrawMenu
    ' Choose colours for the current theme.
    SELECT CASE theme
        CASE 0: bgS = 1: fgN = 15: bgN = 3: fgH = 15: bgH = 4: fgK = 14  ' blue desktop
        CASE 1: bgS = 0: fgN = 10: bgN = 0: fgH = 0: bgH = 10: fgK = 15  ' green terminal
        CASE 2: bgS = 7: fgN = 0: bgN = 7: fgH = 7: bgH = 0: fgK = 4     ' grey "paper"
    END SELECT
    COLOR 7, bgS: CLS
    ' fill the menu panel (rows 7..15, columns 28..52)
    COLOR fgN, bgN
    FOR r = 7 TO 15
        LOCATE r, 28: PRINT SPACE$(25);
    NEXT r
    ' frame with double lines
    LOCATE 7, 28: PRINT CHR$(201); STRING$(23, 205); CHR$(187);
    FOR r = 8 TO 14
        LOCATE r, 28: PRINT CHR$(186);
        LOCATE r, 52: PRINT CHR$(186);
    NEXT r
    LOCATE 15, 28: PRINT CHR$(200); STRING$(23, 205); CHR$(188);
    LOCATE 7, 35: PRINT " MAIN MENU ";
    FOR i = 1 TO NITEMS
        DrawItem i
    NEXT i
    COLOR fgN, bgS
    LOCATE 24, 15
    PRINT "Up/Down = move   Enter = select   letter = hot key   Esc = quit";
END SUB

' Draw one menu line.  The selected one uses the highlight colours.
' The hot-key letter is drawn in its own colour so users can spot it.
SUB DrawItem (i)
    IF i = sel THEN f = fgH: b = bgH ELSE f = fgN: b = bgN
    r = 8 + i
    t$ = " " + item$(i) + SPACE$(21 - LEN(item$(i)))   ' pad to fixed width
    COLOR f, b
    LOCATE r, 29: PRINT t$;
    ' overwrite the hot-key letter (+1 because of the leading space)
    IF i <> sel THEN COLOR fgK, b
    LOCATE r, 29 + hot(i): PRINT MID$(item$(i), hot(i), 1);
END SUB

' Pop up a one-line message under the menu and wait for a key.
SUB Message (t$)
    COLOR 0, 7
    w = LEN(t$) + 4
    c = 41 - w \ 2                 ' centre it on the 80-column screen
    LOCATE 18, c: PRINT SPACE$(w);
    LOCATE 19, c: PRINT "  "; t$; "  ";
    LOCATE 20, c: PRINT SPACE$(w);
    COLOR 8, 7
    LOCATE 20, 41 - 7: PRINT "(press a key)";
    k$ = INPUT$(1)
    DrawMenu                       ' redraw to erase the message
END SUB
