' ============================================================
' TITLE:    Customer Database Search & Sort
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     database, TYPE, sorting, searching, INSTR, CSV files
' SUMMARY:  Keep a customer list, search it by any part of a name or city, and sort it by name, city or sales.
' ------------------------------------------------------------
' WHAT IT DOES
'   A small business keeps a list of customers: name, city, phone
'   and total purchases this year. This program loads the list from
'   a CSV file (it creates CUSTOMER.CSV the first time), and lets
'   you:
'     * list everyone, page by page
'     * SEARCH: find every customer whose name or city CONTAINS the
'       text you type (so "son" finds Johnson and Jackson)
'     * SORT by name, by city or by sales (biggest first)
'     * see the TOP 5 customers and the total sales
'     * add a new customer (saved back to the file)
'
' HOW TO USE
'   Choose a letter from the menu: L, F (find), N/C/S (sort by
'   name/city/sales), T (top 5), A (add), Q (quit and save).
'
' CONCEPTS YOU WILL LEARN
'   * An array of TYPE records as an in-memory table
'   * Case-insensitive substring search with UCASE$ and INSTR
'   * Insertion sort on records, with a choice of sort key
'   * Reading and writing comma-separated files
'
' THINGS TO TRY
'   * Add an "email" field (and update the file format)
'   * Delete a customer by number
'   * Use a faster sort (Shell sort) when you have 1000 customers
' ============================================================

DECLARE SUB SortBy (key$)
DECLARE SUB ShowRow (i%)
DECLARE FUNCTION Before% (a AS ANY, b AS ANY, key$)

TYPE Customer
    nm AS STRING * 20
    city AS STRING * 14
    phone AS STRING * 12
    sales AS DOUBLE
END TYPE

CONST MAXC = 200
DIM SHARED c(1 TO MAXC) AS Customer
DIM SHARED nC AS INTEGER

' ---- Create the CSV file on the first run ----------------------------
ON ERROR GOTO NoFile
OPEN "CUSTOMER.CSV" FOR INPUT AS #1
CLOSE #1
ON ERROR GOTO 0
GOSUB LoadFile

DO
    CLS
    PRINT "CUSTOMER DATABASE -"; nC; "customers"
    PRINT
    PRINT "L)ist   F)ind   sort by N)ame C)ity S)ales   T)op 5   A)dd   Q)uit"
    INPUT "Choice"; k$
    SELECT CASE UCASE$(LEFT$(k$, 1))
    CASE "L"
        GOSUB ListAll
    CASE "F"
        INPUT "Search for (part of name or city)"; f$
        f$ = UCASE$(LTRIM$(RTRIM$(f$)))
        CLS
        PRINT "Customers matching '"; f$; "':"
        GOSUB Head
        hits = 0
        FOR i% = 1 TO nC
            ' INSTR returns the position of f$ inside the text, or 0.
            ' Comparing in UPPER CASE makes "smith" match "Smith".
            IF INSTR(UCASE$(c(i%).nm), f$) > 0 OR INSTR(UCASE$(c(i%).city), f$) > 0 THEN
                ShowRow i%
                hits = hits + 1
            END IF
        NEXT i%
        PRINT hits; "found. Press a key": x$ = INPUT$(1)
    CASE "N": SortBy "N": GOSUB ListAll
    CASE "C": SortBy "C": GOSUB ListAll
    CASE "S": SortBy "S": GOSUB ListAll
    CASE "T"
        SortBy "S"
        CLS
        PRINT "TOP 5 CUSTOMERS"
        GOSUB Head
        tot# = 0
        FOR i% = 1 TO nC: tot# = tot# + c(i%).sales: NEXT i%
        FOR i% = 1 TO 5
            IF i% <= nC THEN ShowRow i%
        NEXT i%
        PRINT
        PRINT USING "Total sales, all customers: $$#,###,###.##"; tot#
        IF nC > 0 THEN PRINT USING "Average per customer:        $$#,###,###.##"; tot# / nC
        PRINT "Press a key": x$ = INPUT$(1)
    CASE "A"
        IF nC < MAXC THEN
            nC = nC + 1
            LINE INPUT "Name: "; t$: c(nC).nm = t$
            LINE INPUT "City: "; t$: c(nC).city = t$
            LINE INPUT "Phone: "; t$: c(nC).phone = t$
            INPUT "Sales this year"; c(nC).sales
        END IF
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
GOSUB SaveFile
PRINT "Saved"; nC; "customers to CUSTOMER.CSV"
END

' ---- Load / save: one customer per line, fields separated by commas.
' WRITE # puts quotes around text, so a comma inside a name is safe.
LoadFile:
    nC = 0
    OPEN "CUSTOMER.CSV" FOR INPUT AS #1
    DO WHILE NOT EOF(1) AND nC < MAXC
        nC = nC + 1
        INPUT #1, n$, ct$, ph$, c(nC).sales
        c(nC).nm = n$: c(nC).city = ct$: c(nC).phone = ph$
    LOOP
    CLOSE #1
RETURN

SaveFile:
    OPEN "CUSTOMER.CSV" FOR OUTPUT AS #1
    FOR i% = 1 TO nC
        ' RTRIM$ removes the padding spaces of the fixed-length strings.
        WRITE #1, RTRIM$(c(i%).nm), RTRIM$(c(i%).city), RTRIM$(c(i%).phone), c(i%).sales
    NEXT i%
    CLOSE #1
RETURN

ListAll:
    CLS
    GOSUB Head
    FOR i% = 1 TO nC
        ShowRow i%
        IF i% MOD 20 = 0 AND i% < nC THEN PRINT "-- more --": x$ = INPUT$(1): CLS : GOSUB Head
    NEXT i%
    PRINT "Press a key": x$ = INPUT$(1)
RETURN

Head:
    PRINT "  # Name                 City           Phone              Sales"
    PRINT STRING$(66, "-")
RETURN

' Runs when CUSTOMER.CSV is missing: write sample customers to it.
NoFile:
    OPEN "CUSTOMER.CSV" FOR OUTPUT AS #2
    RESTORE Samples
    DO
        READ n$, ct$, ph$, s#
        IF n$ = "*" THEN EXIT DO
        WRITE #2, n$, ct$, ph$, s#
    LOOP
    CLOSE #2
    RESUME NEXT

Samples:
DATA "Johnson, Mary", "Springfield", "555-0142", 12450.75
DATA "Garcia Hardware", "Riverton", "555-0199", 48210.00
DATA "Lee & Sons", "Springfield", "555-0110", 7340.20
DATA "Patel Pharmacy", "Lakeside", "555-0177", 22980.50
DATA "Jackson Diner", "Riverton", "555-0156", 15600.00
DATA "Nguyen Bakery", "Hill Valley", "555-0133", 9875.40
DATA "Okafor Builders", "Lakeside", "555-0164", 61234.99
DATA "Smith, Alan", "Hill Valley", "555-0128", 1520.00
DATA "Weber Auto", "Springfield", "555-0181", 33410.10
DATA "Zhang Florist", "Riverton", "555-0105", 4890.65
DATA "*", "", "", 0

' ------------------------------------------------------------
' ShowRow: print customer i as one formatted line.
' ------------------------------------------------------------
SUB ShowRow (i%)
    PRINT USING "### \                  \ \            \ \          \ ###,###.##"; i%; c(i%).nm; c(i%).city; c(i%).phone; c(i%).sales
END SUB

' ------------------------------------------------------------
' Before: TRUE if record a should come before record b for the
' chosen key: "N" name A-Z, "C" city A-Z (then name), "S" sales
' highest first.
' ------------------------------------------------------------
FUNCTION Before% (a AS Customer, b AS Customer, key$)
    SELECT CASE key$
    CASE "N": Before% = UCASE$(a.nm) < UCASE$(b.nm)
    CASE "C"
        IF a.city <> b.city THEN
            Before% = a.city < b.city
        ELSE
            Before% = a.nm < b.nm
        END IF
    CASE "S": Before% = a.sales > b.sales
    END SELECT
END FUNCTION

' ------------------------------------------------------------
' SortBy: INSERTION SORT. Take each record in turn and slide it
' left past every record that should come after it - like
' sorting playing cards in your hand.
' ------------------------------------------------------------
SUB SortBy (key$)
    DIM tmp AS Customer
    FOR i% = 2 TO nC
        tmp = c(i%)
        j% = i% - 1
        DO WHILE j% >= 1
            IF NOT Before%(tmp, c(j%), key$) THEN EXIT DO
            c(j% + 1) = c(j%)          ' shift the bigger one right
            j% = j% - 1
        LOOP
        c(j% + 1) = tmp                ' drop the card into the gap
    NEXT i%
END SUB
