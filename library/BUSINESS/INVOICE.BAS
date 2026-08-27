' ============================================================
' TITLE:    Invoice Generator
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     PRINT USING, LPRINT, DATA, invoice, tax, formatting
' SUMMARY:  Build a neat customer invoice with aligned columns, tax and totals - on screen or on the printer.
' ------------------------------------------------------------
' WHAT IT DOES
'   A small shop needs to bill a customer. This program reads the
'   price list from DATA lines, lets you pick items and quantities,
'   then prints a professional-looking invoice: line items, a
'   subtotal, a discount for big orders, sales tax and a grand total.
'   Every number lines up because we use PRINT USING templates.
'   You can choose to send the invoice to the printer (LPRINT) too.
'
' HOW TO USE
'   Type an item number (1-8) and a quantity. Enter 0 as the item
'   number when the order is complete. Answer Y to also print the
'   invoice (in Compendium, look at the Printer panel).
'
' CONCEPTS YOU WILL LEARN
'   * PRINT USING templates: "###,###.##", "$$", "\    \" and "&"
'   * LPRINT / LPRINT USING - the same output, sent to the printer
'   * Storing a price list in DATA and arrays
'   * Writing ONE routine that can print to screen or printer
'
' THINGS TO TRY
'   * Add more products to the DATA list (remember to change NITEMS)
'   * Change the tax rate or the discount rules
'   * Number each invoice and save it to a file with PRINT #
' ============================================================

CONST NITEMS = 8           ' how many products are in the DATA list
CONST TAXRATE = .0725      ' 7.25 % sales tax

DIM pname$(1 TO NITEMS), price(1 TO NITEMS)

' ---- Load the price list into arrays ---------------------------
' Arrays let us look up "item 3" instantly instead of re-reading DATA.
FOR i = 1 TO NITEMS
    READ pname$(i), price(i)
NEXT i

' Each line on the invoice remembers which item and how many.
DIM lineItem(1 TO 20), lineQty(1 TO 20)
nLines = 0

CLS
PRINT "ACME HARDWARE - INVOICE ENTRY"
PRINT STRING$(40, "=")
' The template "##. \              \ $$###.##" means:
'   ##.           a 2-digit number followed by a dot
'   \       \     a fixed-width text field (width = number of chars
'                 between and including the backslashes)
'   $$###.##      a dollar sign that "floats" right up to the number
FOR i = 1 TO NITEMS
    PRINT USING "##. \                  \ $$###.##"; i; pname$(i); price(i)
NEXT i
PRINT

' ---- Take the order --------------------------------------------
DO
    INPUT "Item number (0 = done)"; it
    IF it = 0 THEN EXIT DO
    IF it < 1 OR it > NITEMS OR it <> INT(it) THEN
        PRINT "  Sorry, no such item."
    ELSE
        INPUT "  Quantity"; q
        IF q > 0 AND nLines < 20 THEN
            nLines = nLines + 1
            lineItem(nLines) = it
            lineQty(nLines) = INT(q)
        END IF
    END IF
LOOP

IF nLines = 0 THEN PRINT "No items - nothing to bill.": END

INPUT "Customer name"; cust$
IF cust$ = "" THEN cust$ = "Cash Customer"
INPUT "Also send to printer (Y/N)"; ans$
toPrinter = (UCASE$(LEFT$(ans$, 1)) = "Y")

' ---- Show the invoice on screen, then maybe on paper ------------
CLS
dest = 0: GOSUB PrintInvoice
IF toPrinter THEN
    dest = 1: GOSUB PrintInvoice
    PRINT
    PRINT "(Invoice also sent to the printer.)"
END IF
END

' ============================================================
' PrintInvoice: prints the whole invoice.
'   dest = 0 -> screen (PRINT), dest = 1 -> printer (LPRINT)
' Because PRINT and LPRINT are different statements we build each
' line as a string first with a helper, then send it to the right
' place in ONE spot (the PutLine subroutine). That avoids writing the
' invoice twice.
' ============================================================
PrintInvoice:
    o$ = "ACME HARDWARE           INVOICE": GOSUB PutLine
    o$ = "Bill to: " + cust$ + "    Date: " + DATE$: GOSUB PutLine
    o$ = STRING$(56, "-"): GOSUB PutLine
    o$ = "Qty  Description              Unit Price      Amount": GOSUB PutLine
    o$ = STRING$(56, "-"): GOSUB PutLine

    subtotal = 0
    FOR i = 1 TO nLines
        it = lineItem(i)
        amt = lineQty(i) * price(it)
        subtotal = subtotal + amt
        ' Each line is printed with PRINT USING (or LPRINT USING).
        IF dest = 0 THEN
            PRINT USING "###  \                    \ ##,###.##  ###,###.##"; lineQty(i); pname$(it); price(it); amt
        ELSE
            LPRINT USING "###  \                    \ ##,###.##  ###,###.##"; lineQty(i); pname$(it); price(it); amt
        END IF
    NEXT i

    ' Discount rule: 5% off orders of $500 or more.
    IF subtotal >= 500 THEN disc = subtotal * .05 ELSE disc = 0
    ' Round money to whole cents: multiply by 100, round, divide.
    disc = INT(disc * 100 + .5) / 100
    tax = INT((subtotal - disc) * TAXRATE * 100 + .5) / 100
    total = subtotal - disc + tax

    o$ = STRING$(56, "-"): GOSUB PutLine
    lab$ = "Subtotal": v = subtotal: GOSUB OutMoney
    IF disc > 0 THEN lab$ = "Discount (5%)": v = -disc: GOSUB OutMoney
    lab$ = "Sales tax 7.25%": v = tax: GOSUB OutMoney
    o$ = SPACE$(38) + STRING$(11, "="): GOSUB PutLine
    lab$ = "TOTAL DUE": v = total: GOSUB OutMoney
    o$ = "": GOSUB PutLine
    o$ = "Thank you for your business!": GOSUB PutLine
RETURN

' PutLine: send o$ to the screen or the printer.
PutLine:
    IF dest = 0 THEN PRINT o$ ELSE LPRINT o$
RETURN

' OutMoney: a right-aligned label and a money amount.
' "**$##,###.##" would fill with asterisks (cheque style); here we
' use "$$##,###.##-" where the trailing minus shows negatives.
OutMoney:
    IF dest = 0 THEN
        PRINT USING "\                   \                 $$##,###.##-"; lab$; v
    ELSE
        LPRINT USING "\                   \                 $$##,###.##-"; lab$; v
    END IF
RETURN

' ---- Price list: name, unit price ---------------------------------
DATA "Claw Hammer", 14.95
DATA "Box of Nails (1 lb)", 4.49
DATA "Cordless Drill", 89.00
DATA "Paint Brush Set", 12.50
DATA "Gallon of Paint", 32.99
DATA "Tape Measure 25 ft", 9.75
DATA "Step Ladder", 129.00
DATA "Work Gloves", 7.25
