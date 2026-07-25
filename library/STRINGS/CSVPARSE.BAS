' ============================================================
' TITLE:    CSV Parser with Quotes
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     CSV, parsing, state machine, quotes, files, tables
' SUMMARY:  Correctly splits CSV lines with "quoted, fields" and "" escapes, then prints a table with totals.
' ------------------------------------------------------------
' WHAT IT DOES
'   CSV ("comma separated values") is how spreadsheets swap data.
'   Splitting at every comma is NOT enough, because a field may
'   contain commas or quotes itself:
'       42,"Smith, John","He said ""hi""",3.50
'   has exactly FOUR fields:
'       42 | Smith, John | He said "hi" | 3.50
'   The rules (RFC 4180):
'     * a field in double quotes may contain commas
'     * inside quotes, two quotes "" stand for one quote character
'   This program writes a small CSV file, parses it with a tiny
'   "state machine", prints a neat table and adds up a column.
'   You can also type your own CSV lines to see how they split.
'
' HOW TO USE
'   Watch the table, then type CSV lines to test the parser.
'   Empty line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * A state machine: the meaning of a character depends on
'     whether we are inside quotes or not
'   * Looking one character AHEAD to spot the "" escape
'   * Writing quotes into a file with CHR$(34)
'   * Formatting a table with PRINT USING
'
' THINGS TO TRY
'   * Write the reverse: a function that QUOTES a field only when needed
'   * Support semicolon-separated files (common in Europe)
'   * Sort the table by any column
' ============================================================

DECLARE SUB ParseCSV (s$)

CONST MAXF = 20
DIM SHARED fld$(MAXF), nf, csvErr$

q$ = CHR$(34)            ' a double-quote character

CLS
COLOR 14: PRINT "CSV PARSER WITH QUOTES": COLOR 7
PRINT

' ---- write a sample file ------------------------------------
' Note how each embedded quote is written TWICE inside a quoted field.
' (BASIC itself has no way to put a quote inside "...", so we glue
' in q$ = CHR$(34) wherever the file needs one.)
OPEN "ORDERS.CSV" FOR OUTPUT AS #1
PRINT #1, "id,customer,item,qty,price"
PRINT #1, "1,Ada Lovelace,Notebook,3,2.50"
PRINT #1, "2," + q$ + "Babbage, Charles" + q$ + ",Gear set,1,19.99"
qq$ = q$ + q$            ' a doubled quote = one quote inside a field
PRINT #1, "3,Grace Hopper," + q$ + "Bug jar, " + qq$ + "moth" + qq$ + " edition" + q$ + ",2,4.25"
PRINT #1, "4,Alan Turing," + q$ + q$ + ",5,0.80"
PRINT #1, "5," + q$ + "Hedy " + qq$ + "H" + qq$ + " Lamarr" + q$ + ",Radio,1,12.00"
CLOSE #1

' ---- show the raw file --------------------------------------
PRINT "Raw ORDERS.CSV:"
COLOR 8
OPEN "ORDERS.CSV" FOR INPUT AS #1
DO WHILE NOT EOF(1)
    LINE INPUT #1, L$
    PRINT "  "; L$
LOOP
CLOSE #1
COLOR 7
PRINT

' ---- parse it into a table ----------------------------------
PRINT "Parsed:"
COLOR 15
PRINT "  ID  CUSTOMER          ITEM                     QTY   PRICE    TOTAL"
COLOR 7
grand = 0
OPEN "ORDERS.CSV" FOR INPUT AS #1
LINE INPUT #1, L$                      ' skip the header line
DO WHILE NOT EOF(1)
    LINE INPUT #1, L$
    ParseCSV L$
    IF nf = 5 THEN
        qty = VAL(fld$(4)): price = VAL(fld$(5))
        item$ = fld$(3): IF item$ = "" THEN item$ = "(none)"
        PRINT "  "; LEFT$(fld$(1) + "   ", 3); " "; LEFT$(fld$(2) + SPACE$(17), 17); " ";
        PRINT LEFT$(item$ + SPACE$(24), 24);
        PRINT USING "###  ###.##  ####.##"; qty; price; qty * price
        grand = grand + qty * price
    ELSE
        PRINT "  (skipped a line with"; nf; "fields)"
    END IF
LOOP
CLOSE #1
PRINT SPACE$(55); "--------"
PRINT SPACE$(48); "Total:";: PRINT USING " #####.##"; grand

' ---- interactive testing ------------------------------------
DO
    PRINT
    LINE INPUT "CSV line (Enter = quit): "; L$
    IF L$ = "" OR UCASE$(L$) = "Q" THEN EXIT DO
    ParseCSV L$
    PRINT "  "; nf; "field(s):"
    FOR i = 1 TO nf
        PRINT "   "; i; "["; fld$(i); "]"
    NEXT i
    IF csvErr$ <> "" THEN COLOR 12: PRINT "  Warning: "; csvErr$: COLOR 7
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' ParseCSV: the state machine.
'   inQ = 0  (outside quotes):  ,  ends the field
'                               "  at the start of a field enters quotes
'   inQ = 1  (inside quotes):   "" adds one quote and stays inside
'                               "  alone leaves the quotes
'                               ,  is just a normal character
' ------------------------------------------------------------
SUB ParseCSV (s$)
    q$ = CHR$(34)
    nf = 1: fld$(1) = "": inQ = 0: csvErr$ = ""
    i = 1
    DO WHILE i <= LEN(s$)
        c$ = MID$(s$, i, 1)
        IF inQ THEN
            IF c$ = q$ THEN
                IF MID$(s$, i + 1, 1) = q$ THEN
                    fld$(nf) = fld$(nf) + q$    ' "" -> one quote
                    i = i + 1                   ' skip the second one
                ELSE
                    inQ = 0                     ' closing quote
                END IF
            ELSE
                fld$(nf) = fld$(nf) + c$
            END IF
        ELSE
            IF c$ = "," THEN
                IF nf < MAXF THEN nf = nf + 1: fld$(nf) = ""
            ELSEIF c$ = q$ AND fld$(nf) = "" THEN
                inQ = 1                         ' opening quote
            ELSE
                fld$(nf) = fld$(nf) + c$
            END IF
        END IF
        i = i + 1
    LOOP
    IF inQ THEN csvErr$ = "a quoted field was never closed"
END SUB
