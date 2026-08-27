' ============================================================
' TITLE:    Till Receipt Printer
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     LPRINT, string formatting, centering, arrays of strings, taxes
' SUMMARY:  Lay out a narrow supermarket till receipt - centred headers, taxable flags, savings, a barcode - and print it.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shop receipts are printed on narrow paper, only about 32
'   characters wide, so every line has to be planned carefully.
'   This program fills a random shopping basket from a product
'   list, then builds the receipt line by line into an ARRAY OF
'   STRINGS. Building it first means we can show it on the screen
'   (inside a paper-coloured box) AND send exactly the same lines
'   to the printer with LPRINT.
'   Details that real receipts have:
'     * centred shop name and address
'     * "T" after items that are taxed (food is tax-free here)
'     * multi-buy savings shown under the item ("2 for $5")
'     * subtotal, tax, total, card payment with a masked number
'     * a barcode built from block characters
'
' HOW TO USE
'   A receipt appears. Press P to print it (see the Printer panel),
'   N for a new random basket, or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Building text in memory with functions (Center$, LeftRight$)
'   * RIGHT$(SPACE$(n) + s$, n) to right-align text
'   * Sending a whole array of lines to LPRINT
'   * Separate tax treatment for different item classes
'
' THINGS TO TRY
'   * Make the paper 40 characters wide (change W)
'   * Add a loyalty-points line: 1 point per whole dollar
'   * Print a "You saved $x today!" box at the bottom
' ============================================================

DECLARE FUNCTION Center$ (s$)
DECLARE FUNCTION LeftRight$ (l$, r$)
DECLARE FUNCTION Money$ (v#)

CONST W = 32                     ' paper width in characters
CONST TAXRATE = .08
CONST NPROD = 12

DIM pName$(1 TO NPROD), pPrice#(1 TO NPROD), pTax$(1 TO NPROD), pDeal%(1 TO NPROD), pDealPrice#(1 TO NPROD)
FOR i = 1 TO NPROD
    ' name, price, taxable?, multi-buy quantity, price for that many
    READ pName$(i), pPrice#(i), pTax$(i), pDeal%(i), pDealPrice#(i)
NEXT i

DIM SHARED rcpt$(1 TO 60)        ' the receipt, one string per line
DIM SHARED nLines AS INTEGER
RANDOMIZE TIMER
receiptNo = 1040

DO
    GOSUB BuildReceipt
    ' ---- Show it on a "paper" background -----------------------
    CLS
    COLOR 0, 7                   ' black ink on light grey paper
    top = 1
    FOR i = 1 TO nLines
        IF i <= 24 THEN
            LOCATE i, 4: PRINT " "; rcpt$(i); SPACE$(W - LEN(rcpt$(i))); " ";
        END IF
    NEXT i
    COLOR 7, 0
    IF nLines > 24 THEN LOCATE 25, 4: PRINT "(receipt continues on paper...)";
    LOCATE 3, 45: PRINT "P = print receipt"
    LOCATE 4, 45: PRINT "N = new customer"
    LOCATE 5, 45: PRINT "Q = quit"
    DO
        k$ = UCASE$(INKEY$)
    LOOP UNTIL k$ = "P" OR k$ = "N" OR k$ = "Q" OR k$ = CHR$(27)
    IF k$ = "P" THEN
        ' The same lines go to the printer, one LPRINT each.
        FOR i = 1 TO nLines: LPRINT rcpt$(i): NEXT i
        LPRINT : LPRINT
        LOCATE 7, 45: PRINT "Printed!"
        LOCATE 8, 45: PRINT "Press a key...": k$ = INPUT$(1)
        k$ = "N"
    END IF
    receiptNo = receiptNo + 1
LOOP UNTIL k$ = "Q" OR k$ = CHR$(27)
CLS
END

' ------------------------------------------------------------
' BuildReceipt: choose a random basket and lay out every line.
' AddLine is a tiny GOSUB that appends L$ to the array.
' ------------------------------------------------------------
BuildReceipt:
    nLines = 0
    L$ = Center$("SUNRISE MARKET"): GOSUB AddLine
    L$ = Center$("12 Harbour Road, Bayview"): GOSUB AddLine
    L$ = Center$("Tel 555-0190"): GOSUB AddLine
    L$ = STRING$(W, "="): GOSUB AddLine
    L$ = LeftRight$("Receipt" + STR$(receiptNo), DATE$ + " " + LEFT$(TIME$, 5)): GOSUB AddLine
    L$ = STRING$(W, "-"): GOSUB AddLine

    sub# = 0: taxable# = 0: saved# = 0: nItems = 0
    nKinds = 4 + INT(RND * 4)              ' 4 to 7 different products
    FOR k = 1 TO nKinds
        p = 1 + INT(RND * NPROD)
        q = 1 + INT(RND * 3)               ' 1 to 3 of each
        lineTot# = q * pPrice#(p)
        nItems = nItems + q
        IF q > 1 THEN
            ' Quantity line: "  3 @ 1.29" then the total on the right.
            L$ = LEFT$(pName$(p), 20): GOSUB AddLine
            L$ = LeftRight$("  " + LTRIM$(STR$(q)) + " @ " + Money$(pPrice#(p)), Money$(lineTot#) + " " + pTax$(p)): GOSUB AddLine
        ELSE
            L$ = LeftRight$(LEFT$(pName$(p), 22), Money$(lineTot#) + " " + pTax$(p)): GOSUB AddLine
        END IF
        ' Multi-buy: every full group of pDeal% items costs the deal price.
        IF pDeal%(p) > 0 AND q >= pDeal%(p) THEN
            groups = q \ pDeal%(p)
            save# = groups * (pDeal%(p) * pPrice#(p) - pDealPrice#(p))
            L$ = LeftRight$("  *" + LTRIM$(STR$(pDeal%(p))) + " for " + Money$(pDealPrice#(p)) + " saving", "-" + Money$(save#) + "  "): GOSUB AddLine
            lineTot# = lineTot# - save#
            saved# = saved# + save#
        END IF
        sub# = sub# + lineTot#
        IF pTax$(p) = "T" THEN taxable# = taxable# + lineTot#
    NEXT k

    tax# = INT(taxable# * TAXRATE * 100 + .5) / 100
    total# = sub# + tax#
    L$ = STRING$(W, "-"): GOSUB AddLine
    L$ = LeftRight$(LTRIM$(STR$(nItems)) + " items   SUBTOTAL", Money$(sub#) + "  "): GOSUB AddLine
    L$ = LeftRight$("Tax 8% on " + Money$(taxable#) + " (T)", Money$(tax#) + "  "): GOSUB AddLine
    L$ = LeftRight$("TOTAL", "$" + Money$(total#) + "  "): GOSUB AddLine
    L$ = "": GOSUB AddLine
    ' Mask the card number: only the last 4 digits are shown.
    card$ = "**** **** **** " + RIGHT$(STR$(1000 + INT(RND * 9000)), 4)
    L$ = LeftRight$("VISA", card$): GOSUB AddLine
    L$ = LeftRight$("Card payment", Money$(total#) + "  "): GOSUB AddLine
    IF saved# > 0 THEN
        L$ = "": GOSUB AddLine
        L$ = Center$("You saved $" + Money$(saved#) + " today!"): GOSUB AddLine
    END IF
    L$ = STRING$(W, "="): GOSUB AddLine
    ' A pretend barcode: thick, thin and half blocks chosen from the
    ' receipt number's digits, so each receipt looks different.
    bc$ = ""
    num$ = LTRIM$(STR$(receiptNo * 7919&))
    FOR i = 1 TO LEN(num$)
        d = VAL(MID$(num$, i, 1))
        bc$ = bc$ + CHR$(219) + MID$(CHR$(221) + CHR$(222) + " " + CHR$(219), d MOD 4 + 1, 1)
    NEXT i
    L$ = Center$(bc$): GOSUB AddLine
    L$ = Center$(num$): GOSUB AddLine
    L$ = Center$("Thank you - come again!"): GOSUB AddLine
RETURN

AddLine:
    IF nLines < 60 THEN nLines = nLines + 1: rcpt$(nLines) = L$
RETURN

' name, price, T = taxable or blank, deal qty (0 = none), deal price
DATA "Bananas (bunch)", 1.89, " ", 0, 0
DATA "Whole milk 1 gal", 3.49, " ", 0, 0
DATA "Sourdough bread", 4.25, " ", 0, 0
DATA "Cola 2 liter", 2.19, "T", 2, 3.50
DATA "Paper towels 6pk", 7.99, "T", 0, 0
DATA "Free-range eggs", 4.79, " ", 0, 0
DATA "Dish soap", 2.99, "T", 2, 5.00
DATA "Cheddar cheese", 5.49, " ", 0, 0
DATA "Potato chips", 3.29, "T", 3, 8.00
DATA "Apples 3 lb", 4.99, " ", 0, 0
DATA "Batteries AA 4pk", 6.49, "T", 0, 0
DATA "Orange juice", 3.99, " ", 2, 7.00

' Center$: pad s$ on the left so it sits in the middle of W columns.
FUNCTION Center$ (s$)
    pad = (W - LEN(s$)) \ 2
    IF pad < 0 THEN pad = 0
    Center$ = SPACE$(pad) + s$
END FUNCTION

' LeftRight$: l$ at the left edge and r$ at the right edge of W.
FUNCTION LeftRight$ (l$, r$)
    gap = W - LEN(l$) - LEN(r$)
    IF gap < 1 THEN gap = 1
    LeftRight$ = l$ + SPACE$(gap) + r$
END FUNCTION

' Money$: 3.5 -> "3.50"  (always two decimals, no leading space)
FUNCTION Money$ (v#)
    c& = INT(v# * 100 + .5)
    Money$ = LTRIM$(STR$(c& \ 100)) + "." + RIGHT$("0" + LTRIM$(STR$(c& MOD 100)), 2)
END FUNCTION
