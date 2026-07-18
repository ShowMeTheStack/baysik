' ============================================================
' TITLE:    Pop-up Windows & Dialogs
' CATEGORY: Console & Text
' LEVEL:    Advanced
' TAGS:     windows, dialogs, video memory, peek, poke, user interface
' SUMMARY:  A tiny text-mode windowing kit: pop-up message boxes, Yes/No buttons and an input box that restore the screen underneath when closed.
' ------------------------------------------------------------
' WHAT IT DOES
'   Old DOS programs (like the QBasic editor itself!) had pop-up
'   windows that appeared over the screen and vanished cleanly,
'   leaving whatever was underneath untouched.  The trick: before
'   drawing a window, COPY the screen memory under it into an
'   array; when the window closes, copy it BACK.  This program builds
'   that kit and demos it:
'     * a stack of overlapping windows that open and close,
'     * a message box with an OK button,
'     * a Yes / No question with selectable buttons,
'     * an input box with a simple line editor.
'
' HOW TO USE
'   Follow the dialogs.  In button dialogs use Left/Right or Tab to
'   pick a button and Enter to press it (or the button's first
'   letter).  In the input box type, use Backspace, Enter to accept,
'   Esc to cancel.
'
' CONCEPTS YOU WILL LEARN
'   * Text video memory at segment &HB800: 2 bytes per cell
'   * Saving and restoring rectangles with PEEK and POKE
'   * A stack of saved screens (like a pile of plates)
'   * Writing reusable dialog FUNCTIONs that return the user's answer
'
' THINGS TO TRY
'   * Add a third button ("Cancel") to the Yes/No dialog.
'   * Make windows "explode" open by drawing growing boxes first.
'   * Let the user drag a window around with the arrow keys:
'     restore, move, save again, redraw.
' ============================================================

DEFINT A-Z
DECLARE SUB OpenWin (t, l, b, r, title$, fg, bg)
DECLARE SUB CloseWin ()
DECLARE SUB Center (row, txt$)
DECLARE SUB MsgBox (title$, txt$)
DECLARE FUNCTION Ask (title$, txt$)
DECLARE FUNCTION InputBox$ (title$, prompt$, maxLen)
DECLARE SUB Pause (s!)

' ---- The window stack ------------------------------------------
' saved(n, i) holds the bytes that were under window n.  A window
' can be at most 80 x 25 cells = 4000 bytes, so 4000 per slot.
CONST MAXWIN = 6
DIM SHARED saved(1 TO MAXWIN, 0 TO 3999) AS INTEGER
DIM SHARED wt(1 TO MAXWIN), wl(1 TO MAXWIN), wb(1 TO MAXWIN), wr(1 TO MAXWIN)
DIM SHARED nWin                     ' how many windows are open now

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS

' ---- A "desktop" to draw over ---------------------------------
' A shaded background plus some text, so you can SEE that the
' windows restore what was under them.
COLOR 1, 7
FOR r = 1 TO 24
    LOCATE r, 1: PRINT STRING$(80, 177);
NEXT r
COLOR 15, 1: LOCATE 1, 1: PRINT SPACE$(80);
LOCATE 1, 3: PRINT "TEXT WINDOWS DEMO";
COLOR 0, 3: LOCATE 25, 1: PRINT SPACE$(80);
LOCATE 25, 3: PRINT "Windows save the screen under them and restore it when closed";
COLOR 0, 7
LOCATE 5, 10: PRINT " This text is on the desktop. ";
LOCATE 12, 45: PRINT " So is this. Watch it come back! ";

' ---- Demo 1: a pile of windows --------------------------------
FOR i = 1 TO 4
    OpenWin 3 + i * 2, 5 + i * 8, 12 + i * 2, 40 + i * 8, "Window" + STR$(i), 15, i
    COLOR 15, i
    LOCATE 5 + i * 2, 8 + i * 8: PRINT "I am window number"; i
    Pause .5
NEXT i
Pause .6
FOR i = 1 TO 4
    CloseWin                ' closes the TOP window each time
    Pause .4
NEXT i

' ---- Demo 2: message box --------------------------------------
MsgBox "Welcome", "All four windows closed and the desktop is intact!"

' ---- Demo 3: input box ----------------------------------------
nm$ = InputBox$("Your name", "What should I call you?", 20)
IF nm$ = "" THEN nm$ = "Mystery Guest"

' ---- Demo 4: a Yes/No question --------------------------------
IF Ask("Question", "Hi " + nm$ + "! Do you like text-mode programs?") THEN
    MsgBox "Excellent", "Me too, " + nm$ + ". Box characters are art."
ELSE
    MsgBox "Hmm", "Maybe after this demo you will, " + nm$ + "."
END IF

COLOR 7, 0: CLS
PRINT "Dialog demo finished."
END

' Ask a Yes/No question.  Returns -1 (true) for Yes, 0 for No.
FUNCTION Ask (title$, txt$)
    w = LEN(txt$) + 6: IF w < 30 THEN w = 30
    l = 41 - w \ 2: r = l + w - 1
    OpenWin 9, l, 15, r, title$, 0, 7
    Center 11, txt$
    sel = 0                         ' 0 = Yes, 1 = No
    DO
        ' Draw the two buttons; the selected one is highlighted.
        FOR b = 0 TO 1
            IF b = sel THEN COLOR 15, 2 ELSE COLOR 0, 3
            LOCATE 13, 41 - 11 + b * 13
            IF b = 0 THEN PRINT "  Yes  "; ELSE PRINT "  No   ";
        NEXT b
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        SELECT CASE UCASE$(k$)
            CASE CHR$(9), CHR$(0) + "K", CHR$(0) + "M": sel = 1 - sel   ' Tab, Left, Right
            CASE "Y": sel = 0: EXIT DO
            CASE "N", CHR$(27): sel = 1: EXIT DO
            CASE CHR$(13): EXIT DO
        END SELECT
    LOOP
    CloseWin
    Ask = (sel = 0)
END FUNCTION

' Write txt$ centred on a row, in the current colours.
SUB Center (row, txt$)
    LOCATE row, 41 - LEN(txt$) \ 2: PRINT txt$;
END SUB

' Restore the top window's saved screen and pop it off the stack.
SUB CloseWin
    IF nWin = 0 THEN EXIT SUB
    DEF SEG = &HB800
    i = 0
    FOR r = wt(nWin) TO wb(nWin)
        FOR c = wl(nWin) TO wr(nWin)
            ofs = ((r - 1) * 80 + (c - 1)) * 2
            POKE ofs, saved(nWin, i)        ' character
            POKE ofs + 1, saved(nWin, i + 1) ' colour
            i = i + 2
        NEXT c
    NEXT r
    DEF SEG
    nWin = nWin - 1
END SUB

' A text input box with a tiny line editor.  Returns "" on Esc.
FUNCTION InputBox$ (title$, prompt$, maxLen)
    w = maxLen + 8: IF w < LEN(prompt$) + 6 THEN w = LEN(prompt$) + 6
    l = 41 - w \ 2
    OpenWin 9, l, 15, l + w - 1, title$, 15, 1
    COLOR 15, 1: Center 11, prompt$
    t$ = ""
    fx = 41 - maxLen \ 2             ' where the field starts
    DO
        ' The field: black on cyan, with a block "cursor" at the end.
        COLOR 0, 3
        LOCATE 13, fx: PRINT t$; CHR$(219); SPACE$(maxLen - LEN(t$));
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        SELECT CASE k$
            CASE CHR$(13): EXIT DO
            CASE CHR$(27): t$ = "": EXIT DO
            CASE CHR$(8)                       ' Backspace
                IF LEN(t$) > 0 THEN t$ = LEFT$(t$, LEN(t$) - 1)
            CASE " " TO "~"                    ' any normal printable key
                IF LEN(t$) < maxLen THEN t$ = t$ + k$
        END SELECT
    LOOP
    CloseWin
    InputBox$ = t$
END FUNCTION

' Show a message with an OK button; wait for Enter, Space or Esc.
SUB MsgBox (title$, txt$)
    w = LEN(txt$) + 6: IF w < 24 THEN w = 24
    l = 41 - w \ 2
    OpenWin 9, l, 15, l + w - 1, title$, 15, 4
    COLOR 15, 4: Center 11, txt$
    COLOR 0, 7: Center 13, "   OK   "
    DO
        k$ = INKEY$
    LOOP UNTIL k$ = CHR$(13) OR k$ = " " OR k$ = CHR$(27)
    CloseWin
END SUB

' Save the rectangle (t,l)-(b,r) PLUS a shadow strip, then draw a
' framed window there.  Rows t..b, columns l..r, 1-based.
SUB OpenWin (t, l, b, r, title$, fg, bg)
    IF nWin = MAXWIN THEN EXIT SUB
    nWin = nWin + 1
    ' include room for the shadow (1 row below, 2 columns right)
    sb = b + 1: IF sb > 25 THEN sb = 25
    sr = r + 2: IF sr > 80 THEN sr = 80
    wt(nWin) = t: wl(nWin) = l: wb(nWin) = sb: wr(nWin) = sr

    ' 1) Save what is under the window.
    DEF SEG = &HB800
    i = 0
    FOR y = t TO sb
        FOR x = l TO sr
            ofs = ((y - 1) * 80 + (x - 1)) * 2
            saved(nWin, i) = PEEK(ofs)
            saved(nWin, i + 1) = PEEK(ofs + 1)
            i = i + 2
        NEXT x
    NEXT y

    ' 2) Shadow: keep the characters but change their colour byte
    '    to dark grey on black (&H08).
    FOR y = t + 1 TO sb
        FOR x = r + 1 TO sr
            POKE ((y - 1) * 80 + (x - 1)) * 2 + 1, &H8
        NEXT x
    NEXT y
    IF sb > b THEN
        FOR x = l + 2 TO sr
            POKE ((sb - 1) * 80 + (x - 1)) * 2 + 1, &H8
        NEXT x
    END IF
    DEF SEG

    ' 3) Frame and empty inside.
    COLOR fg, bg
    w = r - l - 1
    LOCATE t, l: PRINT CHR$(201); STRING$(w, 205); CHR$(187);
    FOR y = t + 1 TO b - 1
        LOCATE y, l: PRINT CHR$(186); SPACE$(w); CHR$(186);
    NEXT y
    LOCATE b, l: PRINT CHR$(200); STRING$(w, 205); CHR$(188);
    ' title centred in the top border, e.g.  ===[ Title ]===
    tt$ = "[ " + title$ + " ]"
    LOCATE t, l + (w + 2 - LEN(tt$)) \ 2: PRINT tt$;
END SUB

SUB Pause (s!)
    t! = TIMER
    DO WHILE TIMER - t! < s! AND TIMER >= t!: LOOP
END SUB
