' ============================================================
' TITLE:    Text-Mode Paint
' CATEGORY: Console & Text
' LEVEL:    Advanced
' TAGS:     paint, video memory, flood fill, files, keyboard, stack
' SUMMARY:  A complete ANSI-art style paint program: brushes, 16 colours, pen mode, flood fill, and save/load to disk.
' ------------------------------------------------------------
' WHAT IT DOES
'   Turns the text screen into a canvas.  Every cell can hold any
'   character in any foreground/background colour, so you can draw
'   pictures out of blocks and shading characters - the way "ANSI
'   artists" decorated bulletin board systems in the 1990s.
'   Features:
'     * moving cursor with "pen down" mode for drawing lines
'     * 10 brushes (blocks, shades, symbols)
'     * foreground and background colour pickers
'     * flood fill (like a paint bucket)
'     * save and load your picture (PICTURE.TXP file)
'
' HOW TO USE
'   Arrows   move              Space  stamp one brush
'   P        pen up/down (when down, moving paints)
'   0-9      choose brush      E      eraser brush (a space)
'   F / G    foreground colour next / previous
'   B        background colour next
'   K        flood fill from the cursor
'   S / L    save / load PICTURE.TXP      C  clear canvas
'   Esc      quit
'
' CONCEPTS YOU WILL LEARN
'   * Text video memory: character byte + attribute byte per cell
'   * Attribute byte = background * 16 + foreground
'   * Flood fill with an explicit stack (no recursion needed)
'   * Saving binary-ish data with OPEN ... FOR BINARY, PUT and GET
'
' THINGS TO TRY
'   * Add a "line" tool: mark a start point, then draw to the cursor.
'   * Add Undo by copying the canvas to an array before each change.
'   * Add a "pick colour" key that copies the cell under the cursor.
' ============================================================

DEFINT A-Z
DECLARE SUB Stamp (r, c)
DECLARE SUB Status ()
DECLARE SUB FloodFill (r, c)
DECLARE SUB ClearCanvas ()
DECLARE FUNCTION CellOfs (r, c)

CONST TOPR = 2, BOTR = 23         ' canvas rows (row 1 = title, 24-25 = status)
CONST FILENAME = "PICTURE.TXP"

DIM SHARED brush$, fg, bg, penDown, cr, cc
DIM SHARED brushes$
' The ten brushes for keys 0..9: solid, shades, half blocks, symbols.
brushes$ = CHR$(219) + CHR$(178) + CHR$(177) + CHR$(176) + CHR$(223) + CHR$(220) + CHR$(254) + CHR$(3) + CHR$(15) + "*"

SCREEN 0: WIDTH 80, 25
fg = 14: bg = 0: brush$ = CHR$(219): penDown = 0
cr = 12: cc = 40
ClearCanvas

DO
    ' Show the cursor: a blinking underline at the current cell.
    LOCATE cr, cc, 1, 6, 7
    Status
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    moved = 0
    IF LEN(k$) = 2 THEN
        SELECT CASE ASC(RIGHT$(k$, 1))
            CASE 72: IF cr > TOPR THEN cr = cr - 1: moved = 1
            CASE 80: IF cr < BOTR THEN cr = cr + 1: moved = 1
            CASE 75: IF cc > 1 THEN cc = cc - 1: moved = 1
            CASE 77: IF cc < 80 THEN cc = cc + 1: moved = 1
        END SELECT
        ' Pen down?  Paint the cell we just moved onto.
        IF moved AND penDown THEN Stamp cr, cc
    ELSE
        SELECT CASE UCASE$(k$)
            CASE " ": Stamp cr, cc
            CASE "0" TO "9": brush$ = MID$(brushes$, VAL(k$) + 1, 1)
            CASE "E": brush$ = " "
            CASE "P": penDown = 1 - penDown: IF penDown THEN Stamp cr, cc
            CASE "F": fg = (fg + 1) MOD 16
            CASE "G": fg = (fg + 15) MOD 16       ' +15 MOD 16 = minus one, wrapping
            CASE "B": bg = (bg + 1) MOD 8         ' only 8 backgrounds (no blink)
            CASE "K": FloodFill cr, cc
            CASE "C": ClearCanvas
            CASE "S"
                ' Save: 80 x 22 cells x 2 bytes, written byte by byte
                ' as a long string with PUT in BINARY mode.
                d$ = ""
                DEF SEG = &HB800
                FOR i = CellOfs(TOPR, 1) TO CellOfs(BOTR, 80) + 1
                    d$ = d$ + CHR$(PEEK(i))
                NEXT i
                DEF SEG
                f = FREEFILE
                OPEN FILENAME FOR BINARY AS #f
                PUT #f, 1, d$
                CLOSE #f
                COLOR 15, 2: LOCATE 1, 60: PRINT " Saved! "; : SLEEP 1
                COLOR 15, 1: LOCATE 1, 60: PRINT SPACE$(8);
            CASE "L"
                ' First check the file exists: opening a missing file FOR
                ' INPUT causes an error, which our handler turns into a flag.
                loadErr = 0
                ON ERROR GOTO NoFile
                f = FREEFILE
                OPEN FILENAME FOR INPUT AS #f
                IF loadErr = 0 THEN CLOSE #f
                ON ERROR GOTO 0
                IF loadErr THEN
                    COLOR 15, 4: LOCATE 1, 55: PRINT " No saved picture yet! "; : SLEEP 1
                ELSE
                    f = FREEFILE
                    OPEN FILENAME FOR BINARY AS #f
                    d$ = SPACE$(LOF(f))
                    GET #f, 1, d$
                    CLOSE #f
                    DEF SEG = &HB800
                    startOfs = CellOfs(TOPR, 1)
                    FOR i = 1 TO LEN(d$)
                        POKE startOfs + i - 1, ASC(MID$(d$, i, 1))
                    NEXT i
                    DEF SEG
                END IF
                COLOR 15, 1: LOCATE 1, 50: PRINT SPACE$(31);   ' tidy the title bar
            CASE CHR$(27): EXIT DO
        END SELECT
    END IF
LOOP

COLOR 7, 0: CLS
LOCATE , , 0
END

' Error handler used while checking for the saved file.
NoFile:
    loadErr = 1
    RESUME NEXT

' Memory offset of row r, column c (both starting at 1).
FUNCTION CellOfs (r, c)
    CellOfs = ((r - 1) * 80 + (c - 1)) * 2
END FUNCTION

SUB ClearCanvas
    COLOR 7, 0: CLS
    COLOR 15, 1: LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 3: PRINT "TEXT-MODE PAINT";
    ' A faint dotted canvas so you can see where you are.
    DEF SEG = &HB800
    FOR r = TOPR TO BOTR
        FOR c = 1 TO 80
            POKE CellOfs(r, c), 250            ' small dot
            POKE CellOfs(r, c) + 1, &H8        ' dark grey on black
        NEXT c
    NEXT r
    DEF SEG
    COLOR 8, 0
    LOCATE 24, 1: PRINT "Arrows Space=stamp P=pen 0-9/E=brush F/G/B=colour K=fill S/L=save/load C=clear";
END SUB

' Flood fill: replace the connected area that has the SAME character
' and colour as the starting cell.  Instead of a recursive SUB (which
' could run out of stack) we keep our own list of cells "to visit".
SUB FloodFill (r, c)
    DEF SEG = &HB800
    o = CellOfs(r, c)
    oldCh = PEEK(o): oldAt = PEEK(o + 1)
    newCh = ASC(brush$): newAt = bg * 16 + fg
    IF oldCh = newCh AND oldAt = newAt THEN DEF SEG: EXIT SUB   ' nothing to do
    DIM sr(1 TO 7100), sc(1 TO 7100)      ' our stack of cells
    ' (1760 canvas cells x 4 neighbours each = at most 7040 pushes)
    sp = 1: sr(1) = r: sc(1) = c
    DO WHILE sp > 0
        y = sr(sp): x = sc(sp): sp = sp - 1          ' pop a cell
        o = CellOfs(y, x)
        IF PEEK(o) = oldCh AND PEEK(o + 1) = oldAt THEN
            POKE o, newCh: POKE o + 1, newAt
            ' push the 4 neighbours (if they are inside the canvas)
            IF y > TOPR THEN sp = sp + 1: sr(sp) = y - 1: sc(sp) = x
            IF y < BOTR THEN sp = sp + 1: sr(sp) = y + 1: sc(sp) = x
            IF x > 1 THEN sp = sp + 1: sr(sp) = y: sc(sp) = x - 1
            IF x < 80 THEN sp = sp + 1: sr(sp) = y: sc(sp) = x + 1
        END IF
    LOOP
    DEF SEG
END SUB

' Put the current brush at (r, c) in the current colours.
SUB Stamp (r, c)
    DEF SEG = &HB800
    POKE CellOfs(r, c), ASC(brush$)
    ' The attribute byte packs both colours: high 4 bits background,
    ' low 4 bits foreground.  bg * 16 shifts it into the high half.
    POKE CellOfs(r, c) + 1, bg * 16 + fg
    DEF SEG
END SUB

' The status line at the bottom: shows brush, colours and pen state.
SUB Status
    COLOR 7, 0
    LOCATE 25, 1: PRINT "Brush ";
    COLOR fg, bg: PRINT brush$; brush$; brush$;
    COLOR 7, 0: PRINT USING "  FG ##  BG #  "; fg; bg;
    IF penDown THEN COLOR 12: PRINT "PEN DOWN"; ELSE COLOR 10: PRINT "pen up  ";
    COLOR 7: PRINT USING "   Row ## Col ##  "; cr; cc;
    COLOR 8: PRINT "Esc quits";
    LOCATE cr, cc
END SUB
