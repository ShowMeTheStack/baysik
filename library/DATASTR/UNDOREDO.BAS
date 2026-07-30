' ============================================================
' TITLE:    Pixel Painter with Undo/Redo
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     undo, redo, stack, command pattern, editor
' SUMMARY:  Paint on a text-mode canvas while two stacks record every change so you can undo and redo - even whole-row fills.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every editor has Undo. The trick is to record each change as a
'   small record: WHERE it happened, the OLD value and the NEW
'   value. Records go onto an UNDO STACK.
'     * Undo pops a record, puts the OLD value back, and pushes the
'       record onto a REDO STACK.
'     * Redo pops from the redo stack, re-applies the NEW value and
'       pushes it back onto the undo stack.
'     * Making a brand-new change empties the redo stack (that
'       "future" no longer makes sense).
'
'   Some actions change many cells at once (fill a row, clear all).
'   Each record carries a GROUP number, and undo/redo moves a whole
'   group in one go, so one key press undoes the whole fill.
'
' HOW TO USE
'   Arrow keys or W A S D   move the cursor
'   Space    paint the cell      1-6  choose a colour
'   F        fill the whole row  X    clear the canvas
'   Z        undo                Y    redo
'   Q / Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Two stacks working as a pair
'   * Storing "what changed" instead of whole copies of the canvas
'   * Grouping many small changes into one undoable action
'
' THINGS TO TRY
'   * Skip recording a paint that doesn't change the colour
'   * Add a limit so very old undo records are dropped
' ============================================================

DEFINT A-Z
DECLARE SUB Record (x AS INTEGER, y AS INTEGER, newC AS INTEGER)
DECLARE SUB DrawCell (x AS INTEGER, y AS INTEGER)
DECLARE SUB DrawPanel ()

CONST W = 24, H = 14, MAXREC = 800
TYPE Change
    x AS INTEGER
    y AS INTEGER
    oldC AS INTEGER
    newC AS INTEGER
    grp AS INTEGER           ' records with the same grp undo together
END TYPE
DIM SHARED canvas(1 TO W, 1 TO H)
DIM SHARED undoS(1 TO MAXREC) AS Change, nUndo
DIM SHARED redoS(1 TO MAXREC) AS Change, nRedo
DIM SHARED grp, msg$

CLS
cx = 1: cy = 1: ink = 4
FOR y = 1 TO H: FOR x = 1 TO W: DrawCell x, y: NEXT x: NEXT y
msg$ = "Space paints. Try F (fill row), then Z (undo)."

DO
    DrawPanel
    LOCATE 25, 1: PRINT "Colour:"; ink; "  "; LEFT$(msg$ + SPACE$(65), 65);
    ' Show the cursor by drawing the cell with a marker.
    LOCATE 2 + cy, 2 + (cx - 1) * 2: COLOR 15, canvas(cx, cy): PRINT "<>"; : COLOR 7, 0
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    DrawCell cx, cy                       ' erase the cursor marker
    IF LEN(k$) = 2 THEN
        SELECT CASE ASC(RIGHT$(k$, 1))
            CASE 72: k$ = "W"
            CASE 80: k$ = "S"
            CASE 75: k$ = "A"
            CASE 77: k$ = "D"
        END SELECT
    END IF
    k$ = UCASE$(k$)
    SELECT CASE k$
    CASE "W": IF cy > 1 THEN cy = cy - 1
    CASE "S": IF cy < H THEN cy = cy + 1
    CASE "A": IF cx > 1 THEN cx = cx - 1
    CASE "D": IF cx < W THEN cx = cx + 1
    CASE "1" TO "6": ink = VAL(k$): msg$ = "Pen colour changed."
    CASE " "
        grp = grp + 1
        Record cx, cy, ink
        msg$ = "Painted (1 change recorded)."
    CASE "F"
        grp = grp + 1                       ' one group for the whole row
        FOR x = 1 TO W: Record x, cy, ink: NEXT x
        msg$ = "Filled row" + STR$(cy) + " (" + LTRIM$(STR$(W)) + " changes, ONE group)."
    CASE "X"
        grp = grp + 1
        FOR y = 1 TO H: FOR x = 1 TO W
            IF canvas(x, y) THEN Record x, y, 0
        NEXT x: NEXT y
        msg$ = "Cleared canvas (undo brings it all back)."
    CASE "Z"
        IF nUndo = 0 THEN
            msg$ = "Nothing to undo."
        ELSE
            g = undoS(nUndo).grp: n = 0
            ' pop every record of the top group
            DO WHILE nUndo > 0
                IF undoS(nUndo).grp <> g THEN EXIT DO
                r = nUndo
                canvas(undoS(r).x, undoS(r).y) = undoS(r).oldC
                DrawCell undoS(r).x, undoS(r).y
                nRedo = nRedo + 1: redoS(nRedo) = undoS(r)
                nUndo = nUndo - 1: n = n + 1
            LOOP
            msg$ = "Undid group" + STR$(g) + " (" + LTRIM$(STR$(n)) + " changes)."
        END IF
    CASE "Y"
        IF nRedo = 0 THEN
            msg$ = "Nothing to redo."
        ELSE
            g = redoS(nRedo).grp: n = 0
            DO WHILE nRedo > 0
                IF redoS(nRedo).grp <> g THEN EXIT DO
                r = nRedo
                canvas(redoS(r).x, redoS(r).y) = redoS(r).newC
                DrawCell redoS(r).x, redoS(r).y
                nUndo = nUndo + 1: undoS(nUndo) = redoS(r)
                nRedo = nRedo - 1: n = n + 1
            LOOP
            msg$ = "Redid group" + STR$(g) + " (" + LTRIM$(STR$(n)) + " changes)."
        END IF
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
COLOR 7, 0: CLS
PRINT "Bye! You made"; grp; "undoable actions."
END

' DrawCell: each canvas cell is two characters of background colour.
SUB DrawCell (x AS INTEGER, y AS INTEGER)
    LOCATE 2 + y, 2 + (x - 1) * 2
    IF canvas(x, y) = 0 THEN
        COLOR 8, 0: PRINT ". ";
    ELSE
        COLOR 0, canvas(x, y): PRINT "  ";
    END IF
    COLOR 7, 0
END SUB

' DrawPanel: the right side shows the top of both stacks.
SUB DrawPanel
    LOCATE 1, 1: PRINT "PIXEL PAINTER - Z undo, Y redo, F fill row, X clear, Q quit";
    LOCATE 3, 54: PRINT "UNDO stack:"; nUndo; "  "
    LOCATE 4, 54: PRINT "grp  x  y old new"
    FOR i = 0 TO 6
        LOCATE 5 + i, 54
        r = nUndo - i
        IF r >= 1 THEN
            PRINT USING "### ## ##  #   #  "; undoS(r).grp; undoS(r).x; undoS(r).y; undoS(r).oldC; undoS(r).newC;
        ELSE
            PRINT SPACE$(20);
        END IF
    NEXT i
    LOCATE 13, 54: PRINT "REDO stack:"; nRedo; "  "
    FOR i = 0 TO 6
        LOCATE 14 + i, 54
        r = nRedo - i
        IF r >= 1 THEN
            PRINT USING "### ## ##  #   #  "; redoS(r).grp; redoS(r).x; redoS(r).y; redoS(r).oldC; redoS(r).newC;
        ELSE
            PRINT SPACE$(20);
        END IF
    NEXT i
    LOCATE 22, 54: PRINT "(top of each stack first)";
END SUB

' Record: make a change AND remember how to undo it.
SUB Record (x AS INTEGER, y AS INTEGER, newC AS INTEGER)
    IF nUndo = MAXREC THEN msg$ = "Undo memory full!": EXIT SUB
    nUndo = nUndo + 1
    undoS(nUndo).x = x: undoS(nUndo).y = y
    undoS(nUndo).oldC = canvas(x, y)
    undoS(nUndo).newC = newC
    undoS(nUndo).grp = grp
    canvas(x, y) = newC
    DrawCell x, y
    nRedo = 0          ' a new action wipes out the redo "future"
END SUB
