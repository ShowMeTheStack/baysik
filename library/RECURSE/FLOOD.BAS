' ============================================================
' TITLE:    Recursive Flood Fill
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, flood fill, grids, paint bucket, stack depth
' SUMMARY:  The paint-bucket tool, written as a four-way recursive SUB, coloring a text-mode map cell by cell.
' ------------------------------------------------------------
' WHAT IT DOES
'   A map of walls (#) and empty cells is drawn on screen.  Flood
'   fill starts at one cell and spreads to every connected empty
'   cell: it colors the cell, then calls itself on the four
'   neighbours (up, down, left, right).  Cells that are a wall,
'   already colored, or off the map stop the recursion.
'   It is exactly what the "paint bucket" does in a paint program.
'   The status line shows the current and maximum recursion depth.
'
' HOW TO USE
'   Arrow keys move the cursor (the blinking block).  Press SPACE to
'   flood-fill from there with the next color.  R resets the map.
'   Q or Esc quits.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK in Fill.  Press Space.  Look at r and c:
'      the first few calls all go UP (that call is first in Fill),
'      then the stack starts to unwind and tries other directions.
'   2. Open the CALL STACK when depth is large (use a CONDITIONAL
'      breakpoint  depth = 30 ).  Every frame is one cell in a
'      long snake-like path through the region.
'   3. WATCH  maxDepth.  For a big open room it can reach the
'      number of cells in the room!  Real paint programs use an
'      explicit queue instead, to avoid running out of stack.
'
' CONCEPTS YOU WILL LEARN
'   * Four-way recursion on a 2-D grid
'   * Base cases that check bounds, walls and "already visited"
'   * Why deep recursion can be risky, and how big it can get
'
' THINGS TO TRY
'   * Add the 4 diagonal neighbours (8-way fill).  What leaks?
'   * Change the order of the four calls and watch the fill pattern.
'   * Count the cells in each region (the size of an "island").
' ============================================================
DECLARE SUB Fill (r AS INTEGER, c AS INTEGER, col AS INTEGER, depth AS INTEGER)
DECLARE SUB LoadMap ()
DECLARE SUB DrawCell (r AS INTEGER, c AS INTEGER)
DECLARE SUB Status (msg$)

CONST ROWS = 15, COLS = 40
CONST TOP = 3, LEFTX = 20            ' where the map sits on screen
DIM SHARED cell(1 TO ROWS, 1 TO COLS) AS INTEGER  ' -1 wall, 0 empty, >0 color
DIM SHARED maxDepth AS INTEGER, filled AS INTEGER

LoadMap
cr% = 2: cc% = 2: colr% = 1
DO
    LOCATE TOP + cr% - 1, LEFTX + cc% - 1, 1   ' show the cursor there
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "H": IF cr% > 1 THEN cr% = cr% - 1
        CASE CHR$(0) + "P": IF cr% < ROWS THEN cr% = cr% + 1
        CASE CHR$(0) + "K": IF cc% > 1 THEN cc% = cc% - 1
        CASE CHR$(0) + "M": IF cc% < COLS THEN cc% = cc% + 1
        CASE " "
            IF cell(cr%, cc%) <> 0 THEN
                Status "That cell is not empty - move to a blank cell."
            ELSE
                colr% = colr% MOD 6 + 1          ' cycle colors 2..7, 1
                maxDepth = 0: filled = 0
                Fill cr%, cc%, colr% + 8, 1
                Status "Filled" + STR$(filled) + " cells, max depth" + STR$(maxDepth)
            END IF
        CASE "R": LoadMap
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
COLOR 7, 0: CLS
END

SUB Fill (r AS INTEGER, c AS INTEGER, col AS INTEGER, depth AS INTEGER)
    ' ---- base cases: stop here ----
    IF r < 1 OR r > ROWS OR c < 1 OR c > COLS THEN EXIT SUB  ' off map
    IF cell(r, c) <> 0 THEN EXIT SUB    ' wall or already painted

    ' ---- do the work for THIS cell ----
    cell(r, c) = col                    ' <<< BREAK
    DrawCell r, c
    filled = filled + 1
    IF depth > maxDepth THEN maxDepth = depth

    ' ---- recurse into the four neighbours ----
    Fill r - 1, c, col, depth + 1       ' up
    Fill r + 1, c, col, depth + 1       ' down
    Fill r, c - 1, col, depth + 1       ' left
    Fill r, c + 1, col, depth + 1       ' right
END SUB

SUB LoadMap
    DIM r AS INTEGER, c AS INTEGER, row$
    COLOR 7, 0: CLS
    PRINT "RECURSIVE FLOOD FILL   arrows=move  Space=fill  R=reset  Q=quit"
    RESTORE MapData
    FOR r = 1 TO ROWS
        READ row$
        FOR c = 1 TO COLS
            IF MID$(row$, c, 1) = "#" THEN cell(r, c) = -1 ELSE cell(r, c) = 0
            DrawCell r, c
        NEXT c
    NEXT r
    Status "Move to an empty area and press Space."
END SUB

SUB DrawCell (r AS INTEGER, c AS INTEGER)
    LOCATE TOP + r - 1, LEFTX + c - 1, 0
    IF cell(r, c) = -1 THEN
        COLOR 8, 0: PRINT CHR$(219);         ' wall
    ELSEIF cell(r, c) = 0 THEN
        COLOR 7, 0: PRINT CHR$(250);         ' empty: a small dot
    ELSE
        COLOR cell(r, c), 0: PRINT CHR$(178);  ' painted
    END IF
END SUB

SUB Status (msg$)
    COLOR 15, 0
    LOCATE TOP + ROWS + 1, 1, 0: PRINT SPACE$(79);
    LOCATE TOP + ROWS + 1, 1: PRINT msg$;
END SUB

MapData:
DATA "########################################"
DATA "#        #           #                 #"
DATA "#        #           #     #####       #"
DATA "#        #   #####   #     #   #       #"
DATA "#####  ###   #   #   #     # # #       #"
DATA "#            #   #         #   #       #"
DATA "#            #####         ## ##       #"
DATA "##########            ######   #########"
DATA "#        #            #                #"
DATA "#  ####  #    ####    #   ##########   #"
DATA "#  #  #  #    #  #    #   #        #   #"
DATA "#  ####  #    ####    #   ##########   #"
DATA "#        #            #                #"
DATA "#        ########     #                #"
DATA "########################################"
