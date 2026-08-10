' ============================================================
' TITLE:    Mini Spreadsheet
' CATEGORY: Utilities & Tools
' LEVEL:    Advanced
' TAGS:     spreadsheet, parser, recursion, formulas, grid, files
' SUMMARY:  A tiny VisiCalc-style spreadsheet with cell formulas like =B2*C2 and =SUM(D2:D5).
' ------------------------------------------------------------
' WHAT IT DOES
'   A grid of 7 columns (A-G) by 15 rows.  Each cell can hold:
'     * a number          42   or  -3.5
'     * text              Apples
'     * a formula         =B2*C2+1   =SUM(D2:D5)   =AVG(B2:B5)
'   Formulas may use + - * / ^, brackets, cell references, and
'   the functions SUM, AVG, MIN, MAX over a range like A1:C3.
'   Every time anything changes, the whole sheet is recalculated.
'
'   The heart of it is a RECURSIVE DESCENT PARSER - a set of
'   functions that call each other to follow the grammar:
'       expr   = term   { (+|-) term }
'       term   = power  { (*|/) power }
'       power  = factor [ ^ power ]
'       factor = number | cell | FUNC(range) | (expr) | -factor
'   Because "term" is inside "expr", * is done before + - that's
'   operator precedence for free!  A formula that refers to
'   another formula cell simply evaluates that cell first (more
'   recursion).  A depth limit catches circular references.
'
' HOW TO USE
'   Arrow keys move.  Enter or E edits the current cell (type a
'   new value; empty Enter keeps the old one; a single space
'   clears it).  S saves to SHEET.TXT, L loads it.
'   Q or Esc quits.  The top line shows the cell's raw contents.
'
' CONCEPTS YOU WILL LEARN
'   * Recursive FUNCTIONs and a recursive descent parser
'   * Saving and restoring "global" parser state around recursion
'   * Converting "B12" into column/row numbers with ASC and VAL
'   * Error flags instead of crashing on bad formulas
'
' THINGS TO TRY
'   * Add a COUNT function, or IF(cond, a, b).
'   * Make columns wider or narrower with a key.
'   * Copy a formula down a column, adjusting the row numbers.
' ============================================================

DECLARE FUNCTION CellVal# (c%, r%)
DECLARE FUNCTION Expr# ()
DECLARE FUNCTION Term# ()
DECLARE FUNCTION Power# ()
DECLARE FUNCTION Factor# ()
DECLARE FUNCTION NextCh$ ()
DECLARE FUNCTION ReadRef% (c%, r%)
DECLARE FUNCTION Show$ (c%, r%)
DECLARE SUB DrawSheet ()

CONST NC = 7, NR = 15, CW = 10      ' columns, rows, column width
DIM SHARED cell$(1 TO NC, 1 TO NR)
' Parser state: the text being parsed, where we are in it, any
' error message, and how deep the cell-to-cell recursion is.
DIM SHARED ex$, px%, perr$, depth%
DIM SHARED curC%, curR%

' ---- A small example sheet ----
RESTORE Sample
DO
    READ ref$, v$
    IF ref$ = "*" THEN EXIT DO
    cell$(ASC(ref$) - 64, VAL(MID$(ref$, 2))) = v$
LOOP
curC% = 2: curR% = 2

DO
    DrawSheet
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "H": IF curR% > 1 THEN curR% = curR% - 1
        CASE CHR$(0) + "P": IF curR% < NR THEN curR% = curR% + 1
        CASE CHR$(0) + "K": IF curC% > 1 THEN curC% = curC% - 1
        CASE CHR$(0) + "M", CHR$(9): IF curC% < NC THEN curC% = curC% + 1
        CASE CHR$(13), "E"
            LOCATE 21, 1: PRINT SPACE$(80);
            LOCATE 21, 1: PRINT CHR$(64 + curC%); LTRIM$(STR$(curR%));
            LINE INPUT " new value: "; t$
            IF t$ = " " THEN
                cell$(curC%, curR%) = ""
            ELSEIF LTRIM$(t$) <> "" THEN
                t$ = LTRIM$(RTRIM$(t$))
                IF LEFT$(t$, 1) = "=" THEN t$ = UCASE$(t$)    ' formulas in capitals
                cell$(curC%, curR%) = t$
            END IF
            IF curR% < NR THEN curR% = curR% + 1           ' like a real spreadsheet
        CASE "S"
            OPEN "SHEET.TXT" FOR OUTPUT AS #1
            FOR r% = 1 TO NR: FOR c% = 1 TO NC
                ' WRITE # puts quotes round strings, so commas are safe.
                IF cell$(c%, r%) <> "" THEN WRITE #1, c%, r%, cell$(c%, r%)
            NEXT c%, r%
            CLOSE #1
        CASE "L"
            ON ERROR GOTO NoSheet
            OPEN "SHEET.TXT" FOR INPUT AS #1
            ON ERROR GOTO 0
            IF loadFail = 0 THEN
                FOR r% = 1 TO NR: FOR c% = 1 TO NC: cell$(c%, r%) = "": NEXT c%, r%
                DO WHILE NOT EOF(1)
                    INPUT #1, c%, r%, t$
                    IF c% >= 1 AND c% <= NC AND r% >= 1 AND r% <= NR THEN cell$(c%, r%) = t$
                LOOP
                CLOSE #1
            END IF
            loadFail = 0
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END

NoSheet:
    loadFail = -1: BEEP
    RESUME NEXT

Sample:
' Formulas containing ":" MUST be in quotes - an unquoted colon
' would end the DATA statement, just like it ends any statement.
DATA A1,Item, B1,Qty, C1,Price, D1,Total
DATA A2,Apples, B2,6, C2,0.45, D2,=B2*C2
DATA A3,Bread, B3,2, C3,1.80, D3,=B3*C3
DATA A4,Milk, B4,3, C4,0.99, D4,=B4*C4
DATA A5,Cheese, B5,1, C5,4.25, D5,=B5*C5
DATA A7,Subtotal, D7,"=SUM(D2:D5)"
DATA A8,Tax 8%, D8,=D7*0.08
DATA A9,TOTAL, D9,=D7+D8
DATA A11,Avg price, D11,"=AVG(C2:C5)"
DATA A12,Dearest, D12,"=MAX(C2:C5)"
DATA F1,"Try:", F2,=2+3*4, F3,=(2+3)*4, F4,=2^10, F5,=D9/0
DATA *,*

' ===== Value of one cell (numbers, text = 0, formulas evaluated) =====
FUNCTION CellVal# (c%, r%)
    s$ = cell$(c%, r%)
    IF LEFT$(s$, 1) <> "=" THEN
        CellVal# = VAL(s$)          ' text gives 0, like old spreadsheets
        EXIT FUNCTION
    END IF
    ' A formula: guard against A1 = B1, B1 = A1 loops.
    depth% = depth% + 1
    IF depth% > 30 THEN perr$ = "CIRC": depth% = depth% - 1: EXIT FUNCTION
    ' Save the parser's state - we may be in the middle of
    ' parsing another formula that referred to this cell!
    saveEx$ = ex$: savePx% = px%
    ex$ = MID$(s$, 2): px% = 1
    v# = Expr#
    IF px% <= LEN(ex$) AND perr$ = "" THEN perr$ = "SYNTAX"   ' leftovers
    ex$ = saveEx$: px% = savePx%
    depth% = depth% - 1
    CellVal# = v#
END FUNCTION

SUB DrawSheet
    LOCATE 1, 1: COLOR 0, 7
    raw$ = cell$(curC%, curR%)
    PRINT LEFT$(" " + CHR$(64 + curC%) + LTRIM$(STR$(curR%)) + ": " + raw$ + SPACE$(80), 80);
    ' Column headers
    COLOR 15, 1
    LOCATE 2, 1: PRINT "    ";
    FOR c% = 1 TO NC
        h$ = SPACE$(CW): MID$(h$, CW \ 2, 1) = CHR$(64 + c%)
        PRINT h$;
    NEXT c%
    PRINT SPACE$(80 - 4 - NC * CW);
    FOR r% = 1 TO NR
        COLOR 15, 1: LOCATE 2 + r%, 1: PRINT USING "### "; r%;
        FOR c% = 1 TO NC
            IF c% = curC% AND r% = curR% THEN COLOR 0, 3 ELSE COLOR 7, 0
            PRINT Show$(c%, r%);
        NEXT c%
    NEXT r%
    COLOR 7, 0
    LOCATE 19, 1: PRINT "Arrows move   Enter/E edit   S save   L load   Q quit"
    LOCATE 20, 1: PRINT "Formulas: =B2*C2   =SUM(A1:A5)  AVG MIN MAX   + - * / ^ ( )"
    LOCATE 21, 1: PRINT SPACE$(80);
END SUB

' ===== expr = term { (+|-) term } =====
FUNCTION Expr#
    v# = Term#
    DO
        op$ = NextCh$
        IF op$ <> "+" AND op$ <> "-" THEN EXIT DO
        px% = px% + 1
        IF op$ = "+" THEN v# = v# + Term# ELSE v# = v# - Term#
    LOOP
    Expr# = v#
END FUNCTION

' ===== factor: the smallest pieces =====
FUNCTION Factor#
    Factor# = 0
    ch$ = NextCh$
    IF ch$ = "" THEN perr$ = "SYNTAX": EXIT FUNCTION
    IF ch$ = "-" THEN px% = px% + 1: Factor# = -Factor#: EXIT FUNCTION
    IF ch$ = "(" THEN
        px% = px% + 1
        Factor# = Expr#
        IF NextCh$ <> ")" THEN perr$ = "SYNTAX" ELSE px% = px% + 1
        EXIT FUNCTION
    END IF
    IF INSTR("0123456789.", ch$) THEN
        ' a number: collect digits and dots
        st% = px%
        DO WHILE px% <= LEN(ex$) AND INSTR("0123456789.", MID$(ex$, px%, 1)) > 0
            px% = px% + 1
        LOOP
        Factor# = VAL(MID$(ex$, st%, px% - st%))
        EXIT FUNCTION
    END IF
    IF ch$ >= "A" AND ch$ <= "Z" THEN
        ' Either a function name like SUM( or a cell like B12.
        IF MID$(ex$, px% + 3, 1) = "(" THEN
            func$ = MID$(ex$, px%, 3): px% = px% + 4
            IF NOT ReadRef%(c1%, r1%) THEN EXIT FUNCTION
            IF NextCh$ <> ":" THEN perr$ = "SYNTAX": EXIT FUNCTION
            px% = px% + 1
            IF NOT ReadRef%(c2%, r2%) THEN EXIT FUNCTION
            IF NextCh$ <> ")" THEN perr$ = "SYNTAX": EXIT FUNCTION
            px% = px% + 1
            ' make sure c1 <= c2 and r1 <= r2
            IF c1% > c2% THEN SWAP c1%, c2%
            IF r1% > r2% THEN SWAP r1%, r2%
            tot# = 0: n% = 0
            FOR c% = c1% TO c2%
                FOR r% = r1% TO r2%
                    v# = CellVal#(c%, r%)
                    IF n% = 0 THEN mn# = v#: mx# = v#
                    IF v# < mn# THEN mn# = v#
                    IF v# > mx# THEN mx# = v#
                    tot# = tot# + v#: n% = n% + 1
                NEXT r%
            NEXT c%
            SELECT CASE func$
                CASE "SUM": Factor# = tot#
                CASE "AVG": Factor# = tot# / n%
                CASE "MIN": Factor# = mn#
                CASE "MAX": Factor# = mx#
                CASE ELSE: perr$ = "FUNC?"
            END SELECT
        ELSE
            IF ReadRef%(c%, r%) THEN Factor# = CellVal#(c%, r%)
        END IF
        EXIT FUNCTION
    END IF
    perr$ = "SYNTAX"
END FUNCTION

' Look at the next non-space character without using it up.
FUNCTION NextCh$
    DO WHILE MID$(ex$, px%, 1) = " ": px% = px% + 1: LOOP
    NextCh$ = MID$(ex$, px%, 1)        ' "" at the end of the text
END FUNCTION

' ===== power = factor [ ^ power ]   (right-associative) =====
FUNCTION Power#
    b# = Factor#
    IF NextCh$ = "^" THEN
        px% = px% + 1
        e# = Power#
        IF b# < 0 AND e# <> INT(e#) THEN
            perr$ = "MATH": Power# = 0
        ELSEIF b# = 0 AND e# < 0 THEN
            perr$ = "DIV/0": Power# = 0
        ELSE
            Power# = b# ^ e#
        END IF
    ELSE
        Power# = b#
    END IF
END FUNCTION

' Read a cell reference like "C12" at px%.  Returns -1 if OK.
FUNCTION ReadRef% (c%, r%)
    ReadRef% = 0
    ch$ = NextCh$
    IF ch$ < "A" OR ch$ > CHR$(64 + NC) THEN perr$ = "REF": EXIT FUNCTION
    c% = ASC(ch$) - 64: px% = px% + 1
    st% = px%
    DO WHILE INSTR("0123456789", MID$(ex$, px%, 1)) > 0 AND px% <= LEN(ex$)
        px% = px% + 1
    LOOP
    r% = VAL(MID$(ex$, st%, px% - st%))
    IF r% < 1 OR r% > NR THEN perr$ = "REF": EXIT FUNCTION
    ReadRef% = -1
END FUNCTION

' Text to show in a cell, exactly CW characters wide.
FUNCTION Show$ (c%, r%)
    s$ = cell$(c%, r%)
    IF s$ = "" THEN Show$ = SPACE$(CW): EXIT FUNCTION
    IF LEFT$(s$, 1) = "=" OR INSTR("0123456789.-+", LEFT$(s$, 1)) > 0 THEN
        ' numeric: evaluate, then right-align
        perr$ = "": depth% = 0
        v# = CellVal#(c%, r%)
        IF perr$ <> "" THEN
            t$ = "#" + perr$
        ELSEIF ABS(v#) >= 1E+07 THEN
            t$ = "#BIG"
        ELSEIF v# = INT(v#) THEN
            t$ = LTRIM$(STR$(v#))
        ELSE
            ' Two decimal places, rounded: work in whole hundredths
            ' so 14.6 shows as "14.60" and 0.45 as "0.45".
            cents& = INT(ABS(v#) * 100 + .5)
            t$ = LTRIM$(STR$(cents& \ 100)) + "." + RIGHT$("0" + LTRIM$(STR$(cents& MOD 100)), 2)
            IF v# < 0 THEN t$ = "-" + t$
        END IF
        Show$ = RIGHT$(SPACE$(CW) + t$ + " ", CW)
    ELSE
        ' text: left-aligned, cut to fit
        Show$ = LEFT$(" " + s$ + SPACE$(CW), CW)
    END IF
END FUNCTION

' ===== term = power { (*|/) power } =====
FUNCTION Term#
    v# = Power#
    DO
        op$ = NextCh$
        IF op$ <> "*" AND op$ <> "/" THEN EXIT DO
        px% = px% + 1
        d# = Power#
        IF op$ = "*" THEN
            v# = v# * d#
        ELSEIF d# = 0 THEN
            perr$ = "DIV/0": v# = 0
        ELSE
            v# = v# / d#
        END IF
    LOOP
    Term# = v#
END FUNCTION
