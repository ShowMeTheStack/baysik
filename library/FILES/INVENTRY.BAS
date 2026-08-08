' ============================================================
' TITLE:    Inventory Database with Search & Sort
' CATEGORY: File I/O
' LEVEL:    Advanced
' TAGS:     files, random, TYPE, database, sorting, index, search, report
' SUMMARY:  A shop stock-keeping system: RANDOM-file records, a sorted index, searching, stock moves and a printed report.
' ------------------------------------------------------------
' WHAT IT DOES
'   STOCK.DAT holds one fixed-size record per product (code, name,
'   category, quantity, reorder level, price). The program never
'   sorts the FILE itself - that would mean moving lots of bytes.
'   Instead it sorts a small INDEX: an array of record numbers in
'   the order we want. Real databases do the same thing.
'
' HOW TO USE
'   1 list by code     2 list by name     3 list by stock value
'   S search (part of a name or category)
'   R receive stock (+)   I issue stock (-)
'   N new product     L low-stock report saved to LOWSTOCK.TXT
'   Q quit
'
' CONCEPTS YOU WILL LEARN
'   * RANDOM files of TYPE records, updated in place with PUT
'   * Index sorting: sort record numbers, not the records
'   * Insertion sort with a "compare key" chosen at run time
'   * Validating user input before it touches the file
'   * Writing a formatted text report with PRINT # USING
'
' THINGS TO TRY
'   * Add a "delete product" option (mark the code as "*DEL*").
'   * Add a binary search on the code-sorted index.
' ============================================================

TYPE Product
    code   AS STRING * 6
    nm     AS STRING * 22
    cat    AS STRING * 10
    qty    AS INTEGER
    reord  AS INTEGER
    price  AS SINGLE
END TYPE

DECLARE SUB BuildIndex (order%)
DECLARE SUB ShowIndexed (title$)
DECLARE SUB Moves (sign%)
DECLARE SUB NewProduct ()
DECLARE SUB LowStock ()
DECLARE SUB Search ()
DECLARE FUNCTION FindCode% (c$)

CONST DBF = "STOCK.DAT"
DIM SHARED p AS Product, nRec AS INTEGER
DIM SHARED idx(1 TO 500) AS INTEGER     ' the sortable index

OPEN DBF FOR RANDOM AS #1 LEN = LEN(p)
nRec = LOF(1) \ LEN(p)
IF nRec = 0 THEN
    ' First run: load the starter catalogue from DATA.
    DO
        READ p.code
        IF RTRIM$(p.code) = "END" THEN EXIT DO
        READ p.nm, p.cat, p.qty, p.reord, p.price
        nRec = nRec + 1
        PUT #1, nRec, p
    LOOP
END IF

DO
    CLS
    PRINT "INVENTORY -"; nRec; "products in "; DBF
    PRINT
    PRINT " 1 List by code     2 List by name     3 List by stock value"
    PRINT " S Search           R Receive stock    I Issue stock"
    PRINT " N New product      L Low-stock report Q Quit"
    PRINT
    PRINT "Choice: ";
    k$ = UCASE$(INPUT$(1)): PRINT k$
    SELECT CASE k$
    CASE "1": BuildIndex 1: ShowIndexed "BY CODE"
    CASE "2": BuildIndex 2: ShowIndexed "BY NAME"
    CASE "3": BuildIndex 3: ShowIndexed "BY STOCK VALUE (highest first)"
    CASE "S": Search
    CASE "R": Moves 1
    CASE "I": Moves -1
    CASE "N": NewProduct
    CASE "L": LowStock
    CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLOSE #1
CLS : PRINT "Inventory saved."
END

' code, name, category, qty, reorder level, price
DATA "H-100", "Claw hammer 16oz", "Tools", 14, 5, 12.99
DATA "S-210", "Wood screws 4x40 (200)", "Fixings", 3, 10, 4.5
DATA "P-330", "Paint brush 2in", "Paint", 25, 8, 3.25
DATA "D-050", "Cordless drill 18V", "Power", 4, 2, 79
DATA "N-115", "Nails 50mm (1kg)", "Fixings", 0, 6, 6.8
DATA "T-900", "Tape measure 5m", "Tools", 9, 4, 7.45
DATA "G-020", "Safety goggles", "Safety", 2, 5, 5.99
DATA "P-410", "White emulsion 5L", "Paint", 11, 3, 24.5
DATA "W-777", "Work gloves (pair)", "Safety", 30, 10, 3.99
DATA "END"

' Fill idx() with 1..nRec, then insertion-sort it by the chosen key.
' Insertion sort: take each item and slide it left until the one
' before it is not "greater". Simple and fine for small lists.
SUB BuildIndex (order%)
    DIM key$(1 TO 500)
    FOR i = 1 TO nRec
        idx(i) = i
        GET #1, i, p
        SELECT CASE order%
        CASE 1: key$(i) = p.code
        CASE 2: key$(i) = UCASE$(p.nm)
        CASE 3
            ' Highest value first: sort ascending on (big number - value),
            ' formatted with leading zeros so string order = number order.
            v& = 9999999 - CLNG(p.qty * p.price * 100)
            key$(i) = RIGHT$("0000000" + LTRIM$(STR$(v&)), 8)
        END SELECT
    NEXT
    FOR i = 2 TO nRec
        j = i
        DO WHILE j > 1
            IF key$(idx(j - 1)) <= key$(idx(j)) THEN EXIT DO
            SWAP idx(j - 1), idx(j)
            j = j - 1
        LOOP
    NEXT
END SUB

' Search the codes for an exact match; returns the record or 0.
FUNCTION FindCode% (c$)
    FindCode% = 0
    FOR i = 1 TO nRec
        GET #1, i, p
        IF RTRIM$(p.code) = UCASE$(c$) THEN FindCode% = i: EXIT FUNCTION
    NEXT
END FUNCTION

' Report every product at or below its reorder level, on screen and
' into LOWSTOCK.TXT.
SUB LowStock
    OPEN "LOWSTOCK.TXT" FOR OUTPUT AS #2
    PRINT #2, "LOW STOCK REPORT  "; DATE$; " "; TIME$
    PRINT #2, "Code   Product                 Qty  Reorder  Order"
    PRINT #2, STRING$(52, "-")
    n = 0
    FOR i = 1 TO nRec
        GET #1, i, p
        IF p.qty <= p.reord THEN
            ' Suggest ordering enough for twice the reorder level.
            sug = p.reord * 2 - p.qty
            PRINT #2, USING "\    \ \                    \ ####  ####   ####"; p.code; p.nm; p.qty; p.reord; sug
            n = n + 1
        END IF
    NEXT
    PRINT #2, STRING$(52, "-")
    PRINT #2, n; "item(s) need ordering."
    CLOSE #2
    ' Show the file we just wrote.
    PRINT
    OPEN "LOWSTOCK.TXT" FOR INPUT AS #2
    DO WHILE NOT EOF(2): LINE INPUT #2, l$: PRINT l$: LOOP
    CLOSE #2
    PRINT : PRINT "Saved to LOWSTOCK.TXT. Press a key."
    k$ = INPUT$(1)
END SUB

' Receive (sign% = 1) or issue (sign% = -1) stock for a product.
SUB Moves (sign%)
    PRINT
    LINE INPUT "Product code: "; c$
    r = FindCode%(c$)
    IF r = 0 THEN PRINT "Unknown code.": SLEEP 1: EXIT SUB
    GET #1, r, p
    PRINT RTRIM$(p.nm); " - in stock:"; p.qty
    INPUT "Quantity"; q
    q = INT(q)
    IF q <= 0 OR q > 9999 THEN PRINT "Quantity must be 1-9999.": SLEEP 1: EXIT SUB
    IF sign% < 0 AND q > p.qty THEN PRINT "Not enough stock!": SLEEP 1: EXIT SUB
    p.qty = p.qty + sign% * q
    PUT #1, r, p                 ' update just this one record on disk
    PRINT "New stock level:"; p.qty
    IF p.qty <= p.reord THEN PRINT "Warning: at or below reorder level ("; LTRIM$(STR$(p.reord)); ")"
    PRINT "Press a key.": k$ = INPUT$(1)
END SUB

SUB NewProduct
    PRINT
    LINE INPUT "New code (e.g. X-123): "; c$
    c$ = UCASE$(LEFT$(c$, 6))
    IF c$ = "" THEN EXIT SUB
    IF FindCode%(c$) THEN PRINT "That code already exists.": SLEEP 1: EXIT SUB
    p.code = c$
    LINE INPUT "Name: "; t$: p.nm = t$
    LINE INPUT "Category: "; t$: p.cat = t$
    INPUT "Quantity, reorder level, price"; p.qty, p.reord, p.price
    nRec = nRec + 1
    PUT #1, nRec, p              ' a new record goes on the end
    PRINT "Added as record"; nRec: SLEEP 1
END SUB

SUB Search
    PRINT
    LINE INPUT "Find (name or category): "; s$
    s$ = UCASE$(s$)
    IF s$ = "" THEN EXIT SUB
    n = 0
    FOR i = 1 TO nRec
        GET #1, i, p
        IF INSTR(UCASE$(p.nm + " " + p.cat), s$) THEN
            n = n + 1: idx(n) = i
        END IF
    NEXT
    ' Temporarily treat the matches as the whole list for display.
    saveN = nRec: nRec = n
    ShowIndexed "SEARCH: " + s$
    nRec = saveN
END SUB

' Print the records in the order given by idx(1..nRec).
SUB ShowIndexed (title$)
    CLS
    PRINT title$
    PRINT "Code   Product                Category    Qty    Price     Value"
    PRINT STRING$(68, "-")
    total# = 0
    FOR i = 1 TO nRec
        GET #1, idx(i), p
        v# = p.qty * p.price
        total# = total# + v#
        ' Out-of-stock lines in red, low stock in yellow.
        IF p.qty = 0 THEN
            COLOR 12
        ELSEIF p.qty <= p.reord THEN
            COLOR 14
        ELSE
            COLOR 7
        END IF
        PRINT USING "\    \ \                    \ \        \ #### ####.## ######.##"; p.code; p.nm; p.cat; p.qty; p.price; v#
    NEXT
    COLOR 7
    PRINT STRING$(68, "-")
    PRINT USING "\    \ items                                  total ######.##"; STR$(nRec); total#
    PRINT : PRINT "Press a key."
    k$ = INPUT$(1)
END SUB
