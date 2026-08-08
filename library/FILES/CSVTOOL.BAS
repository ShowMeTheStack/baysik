' ============================================================
' TITLE:    CSV Reader & Report Writer
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, csv, parsing, strings, reports, PRINT USING
' SUMMARY:  Parse a real-world CSV file (with quoted fields) and write a summary report CSV.
' ------------------------------------------------------------
' WHAT IT DOES
'   1. Creates SALES.CSV, a small spreadsheet-style file with a header
'      row and some tricky fields: commas and "doubled quotes" inside
'      quotes, and an empty cell.
'   2. Reads it with a hand-written CSV parser (no INPUT # tricks), so
'      you can see how each character is handled.
'   3. Totals the sales per region and writes REPORT.CSV.
'   4. Shows both files on screen.
'
' HOW TO USE
'   Run it; press a key between screens.
'
' CONCEPTS YOU WILL LEARN
'   * The CSV format rules (RFC 4180, the simple parts)
'   * A character-by-character parser with an "in quotes" state
'   * Quoting a field correctly when writing CSV
'   * Parallel arrays to group and total data
'
' THINGS TO TRY
'   * Add a "Month" column and total by month instead.
'   * Make the parser accept semicolons (used in many countries).
' ============================================================

DECLARE SUB ParseCSV (lin$, fld$(), n)
DECLARE FUNCTION CsvQuote$ (s$)

DIM fld$(1 TO 20)                 ' fields of the current row
DIM region$(1 TO 20), total(1 TO 20), cnt(1 TO 20)
nReg = 0

' ---- Step 1: create the input file -----------------------------
' Inside a BASIC string we write a quote mark as CHR$(34).
q$ = CHR$(34)
OPEN "SALES.CSV" FOR OUTPUT AS #1
PRINT #1, "Rep,Region,Product,Amount"
PRINT #1, "Alice,North,Widgets,120.50"
PRINT #1, "Bob,South," + q$ + "Bolts, large" + q$ + ",80"
PRINT #1, "Chen,North," + q$ + "The " + q$ + q$ + "Best" + q$ + q$ + " Gadget" + q$ + ",310.25"
PRINT #1, "Dana,East,Nuts,"
PRINT #1, "Eve,South,Widgets,99.99"
PRINT #1, "Femi,East," + q$ + "Gears, 10-pack" + q$ + ",45"
PRINT #1, "Gus,North,Bolts,12"
CLOSE #1

CLS
PRINT "SALES.CSV as stored on disk:"
PRINT STRING$(60, "-")
OPEN "SALES.CSV" FOR INPUT AS #1
DO WHILE NOT EOF(1): LINE INPUT #1, l$: PRINT l$: LOOP
CLOSE #1
PRINT STRING$(60, "-")
PRINT : PRINT "Press a key to parse it..."
k$ = INPUT$(1)

' ---- Step 2: parse it ------------------------------------------
CLS
PRINT "Rep    Region  Product                    Amount"
PRINT STRING$(60, "-")
OPEN "SALES.CSV" FOR INPUT AS #1
LINE INPUT #1, header$            ' skip the header row
DO WHILE NOT EOF(1)
    LINE INPUT #1, l$
    ParseCSV l$, fld$(), n
    ' An empty Amount cell gives VAL("") = 0, which is what we want.
    amt = VAL(fld$(4))
    PRINT USING "\    \ \     \ \                      \ ####.##"; fld$(1); fld$(2); fld$(3); amt

    ' Find this region in our list, or add it.
    found = 0
    FOR r = 1 TO nReg
        IF region$(r) = fld$(2) THEN found = r: EXIT FOR
    NEXT
    IF found = 0 THEN nReg = nReg + 1: region$(nReg) = fld$(2): found = nReg
    total(found) = total(found) + amt
    cnt(found) = cnt(found) + 1
LOOP
CLOSE #1

' ---- Step 3: write the report ----------------------------------
OPEN "REPORT.CSV" FOR OUTPUT AS #2
PRINT #2, "Region,Sales,Count,Average"
FOR r = 1 TO nReg
    avg = total(r) / cnt(r)
    ' STR$ adds a leading space for positive numbers; LTRIM$ removes it.
    ' We round to 2 decimals with INT(x * 100 + .5) / 100.
    PRINT #2, CsvQuote$(region$(r)); ","; LTRIM$(STR$(total(r))); ",";
    PRINT #2, LTRIM$(STR$(cnt(r))); ","; LTRIM$(STR$(INT(avg * 100 + .5) / 100))
NEXT
CLOSE #2

PRINT
PRINT "REPORT.CSV written:"
PRINT STRING$(60, "-")
OPEN "REPORT.CSV" FOR INPUT AS #2
DO WHILE NOT EOF(2): LINE INPUT #2, l$: PRINT l$: LOOP
CLOSE #2
PRINT
PRINT "Press a key to finish."
k$ = INPUT$(1)
END

' ---------------------------------------------------------------
' ParseCSV splits one CSV line into fld$(1..n) and sets n.
' (A SUB, so it can hand back both the array and the count.)
' The rules:
'   * fields are separated by commas
'   * a field may be wrapped in quotes; then commas inside are text
'   * inside quotes, two quotes ("") stand for one real quote
' We walk the line one character at a time and remember whether we
' are currently "inside quotes" - a tiny state machine.
' ---------------------------------------------------------------
SUB ParseCSV (lin$, fld$(), n)
    FOR i = LBOUND(fld$) TO UBOUND(fld$): fld$(i) = "": NEXT
    n = 1: cur$ = "": inQ = 0: i = 1
    DO WHILE i <= LEN(lin$)
        c$ = MID$(lin$, i, 1)
        IF inQ THEN
            IF c$ = CHR$(34) THEN
                ' Is it a doubled quote "" (a literal quote)?
                IF MID$(lin$, i + 1, 1) = CHR$(34) THEN
                    cur$ = cur$ + c$: i = i + 1
                ELSE
                    inQ = 0           ' closing quote
                END IF
            ELSE
                cur$ = cur$ + c$
            END IF
        ELSE
            SELECT CASE c$
            CASE CHR$(34): inQ = -1   ' opening quote
            CASE ","                  ' end of this field
                fld$(n) = cur$: cur$ = ""
                IF n < UBOUND(fld$) THEN n = n + 1
            CASE ELSE: cur$ = cur$ + c$
            END SELECT
        END IF
        i = i + 1
    LOOP
    fld$(n) = cur$
END SUB

' Wrap a value in quotes only if it needs it (has a comma or quote),
' doubling any quotes inside.
FUNCTION CsvQuote$ (s$)
    IF INSTR(s$, ",") = 0 AND INSTR(s$, CHR$(34)) = 0 THEN CsvQuote$ = s$: EXIT FUNCTION
    r$ = CHR$(34)
    FOR i = 1 TO LEN(s$)
        c$ = MID$(s$, i, 1)
        IF c$ = CHR$(34) THEN r$ = r$ + c$
        r$ = r$ + c$
    NEXT
    CsvQuote$ = r$ + CHR$(34)
END FUNCTION
