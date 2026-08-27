' ============================================================
' TITLE:    Inventory with Reorder Alerts
' CATEGORY: Business & Finance
' LEVEL:    Advanced
' TAGS:     RANDOM files, TYPE, GET, PUT, inventory, reorder point
' SUMMARY:  A warehouse stock system stored in a random-access file, with sales, deliveries and reorder alerts.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every product is one fixed-size RECORD in the file STOCK.DAT.
'   Because all records are the same size, BASIC can jump straight
'   to record number 7 without reading records 1-6 first - that is
'   "random access", just like a real database.
'   Each product has a REORDER POINT: when stock falls to or below
'   it, the item is flagged and a suggested purchase order is made
'   (enough to get back up to the "max" level).
'
' HOW TO USE
'   L = list stock     S = sell (stock goes down)
'   R = receive delivery (stock goes up)
'   N = new product    O = reorder report   Q = quit
'   On the first run the file is filled with sample products.
'
' CONCEPTS YOU WILL LEARN
'   * TYPE ... END TYPE to describe a record layout
'   * OPEN ... FOR RANDOM ... LEN = LEN(record)
'   * GET #1, n, rec and PUT #1, n, rec to read/write record n
'   * LOF(1) \ LEN(rec) = number of records in the file
'   * Inventory value and reorder-point logic
'
' THINGS TO TRY
'   * Add a "supplier" field to the TYPE (the file layout changes,
'     so delete STOCK.DAT first!)
'   * Keep a separate log file of every sale with the date
'   * Sort the listing by value instead of by record number
' ============================================================

TYPE Product
    code AS STRING * 6         ' product code, e.g. "BLT-08"
    desc AS STRING * 20        ' description
    qty AS INTEGER             ' units in stock
    reorder AS INTEGER         ' reorder point
    maxQty AS INTEGER          ' fill back up to this level
    cost AS SINGLE             ' what we pay per unit
    price AS SINGLE            ' what we sell for
END TYPE

DIM SHARED p AS Product

' ---- Open the file; seed it with sample data if empty -------------
' A RANDOM file is created automatically if it doesn't exist.
OPEN "STOCK.DAT" FOR RANDOM AS #1 LEN = LEN(p)
n = LOF(1) \ LEN(p)            ' how many records are stored
IF n = 0 THEN
    RESTORE Samples
    DO
        READ p.code, p.desc, p.qty, p.reorder, p.maxQty, p.cost, p.price
        IF RTRIM$(p.code) = "END" THEN EXIT DO
        n = n + 1
        PUT #1, n, p           ' write record number n
    LOOP
END IF

DO
    CLS
    PRINT "WAREHOUSE INVENTORY  -"; n; "products in STOCK.DAT"
    PRINT
    PRINT "L)ist  S)ell  R)eceive  N)ew product  O)rder report  Q)uit"
    INPUT "Choice"; c$
    SELECT CASE UCASE$(LEFT$(c$, 1))
    CASE "L": GOSUB ListAll
    CASE "S", "R"
        sell = (UCASE$(LEFT$(c$, 1)) = "S")
        INPUT "Record # (1..n)"; r
        IF r >= 1 AND r <= n THEN
            GET #1, r, p                       ' read that ONE record
            PRINT RTRIM$(p.desc); " - in stock:"; p.qty
            INPUT "How many"; q
            q = INT(ABS(q))
            IF sell THEN
                IF q > p.qty THEN
                    PRINT "Only"; p.qty; "available - sold all of them."
                    q = p.qty
                END IF
                p.qty = p.qty - q
                PRINT USING "Sale: ### x $$##.## = $$#,###.##"; q; p.price; q * p.price
            ELSE
                IF p.qty + q > 32000 THEN q = 32000 - p.qty
                p.qty = p.qty + q
            END IF
            PUT #1, r, p                       ' write it back
            IF p.qty <= p.reorder THEN
                COLOR 12: PRINT "*** REORDER ALERT: "; RTRIM$(p.desc); " is at or below"; p.reorder: COLOR 7
            END IF
        ELSE
            PRINT "No such record."
        END IF
        PRINT "Press a key": k$ = INPUT$(1)
    CASE "N"
        INPUT "Code (6 chars)"; p.code
        INPUT "Description"; p.desc
        ' One value per INPUT keeps typing mistakes simple to fix.
        INPUT "Quantity in stock"; p.qty
        INPUT "Reorder point"; p.reorder
        INPUT "Maximum stock level"; p.maxQty
        INPUT "Unit cost"; p.cost
        INPUT "Selling price"; p.price
        n = n + 1
        PUT #1, n, p        ' a new record goes at the end
        PRINT "Saved as record"; n: k$ = INPUT$(1)
    CASE "O": GOSUB OrderReport
    CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLOSE #1
PRINT "Inventory file closed."
END

' ------------------------------------------------------------
' ListAll: read every record in turn and show it. Items at or
' below the reorder point are shown in red.
' ------------------------------------------------------------
ListAll:
    CLS
    PRINT " # Code   Description            Qty Reord   Cost  Price      Value"
    PRINT STRING$(74, "-")
    total = 0
    FOR r = 1 TO n
        GET #1, r, p
        IF p.qty <= p.reorder THEN COLOR 12 ELSE COLOR 7
        ' "Value" is what the stock cost us: qty * cost.
        PRINT USING "## \    \ \                  \ ##### ##### ###.## ###.## ###,###.##"; r; p.code; p.desc; p.qty; p.reorder; p.cost; p.price; p.qty * p.cost
        total = total + p.qty * p.cost
    NEXT r
    COLOR 7
    PRINT STRING$(74, "-")
    PRINT USING "Total inventory value at cost:                       $$#,###,###.##"; total
    PRINT "(red = at or below reorder point)  Press a key"
    k$ = INPUT$(1)
RETURN

' ------------------------------------------------------------
' OrderReport: a purchase order for everything that is low.
' Order quantity = maxQty - qty, so stock goes back to the max.
' ------------------------------------------------------------
OrderReport:
    CLS
    PRINT "PURCHASE ORDER SUGGESTIONS   "; DATE$
    PRINT "Code   Description           Have  Order Unit cost    Line total"
    PRINT STRING$(70, "-")
    total = 0: cnt = 0
    FOR r = 1 TO n
        GET #1, r, p
        IF p.qty <= p.reorder THEN
            oq = p.maxQty - p.qty
            IF oq > 0 THEN
                PRINT USING "\    \ \                  \ #####  #####   ####.##    ###,###.##"; p.code; p.desc; p.qty; oq; p.cost; oq * p.cost
                total = total + oq * p.cost
                cnt = cnt + 1
            END IF
        END IF
    NEXT r
    IF cnt = 0 THEN PRINT "Nothing needs ordering - all stock levels are healthy."
    PRINT STRING$(70, "-")
    PRINT USING "Items: ###        Order total:                    $$#,###,###.##"; cnt; total
    PRINT "Press a key"
    k$ = INPUT$(1)
RETURN

Samples:
' code, description, qty, reorder point, max, cost, price
DATA "BLT-08","Hex bolt M8 (box)",42,20,100,3.10,5.95
DATA "NUT-08","Hex nut M8 (box)",15,20,100,1.80,3.49
DATA "WSH-08","Washer M8 (box)",60,25,120,0.95,1.99
DATA "SCR-35","Wood screw 3.5 (box)",8,15,80,2.40,4.75
DATA "GLU-01","Wood glue 250ml",33,10,50,2.75,6.50
DATA "SND-12","Sandpaper 120 pack",5,10,40,3.90,7.95
DATA "DRL-ST","Drill bit set",12,5,25,11.00,24.99
DATA "TAP-50","Masking tape 50m",19,12,60,1.25,2.99
DATA "END","",0,0,0,0,0
