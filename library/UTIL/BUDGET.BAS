' ============================================================
' TITLE:    Budget Tracker
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     random access files, type, put, get, finance, bar chart
' SUMMARY:  Record income and spending in a random-access file, then see your balance and a chart by category.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every money movement is one RECORD: date, category,
'   description and amount (positive = money in, negative =
'   money out).  Records are kept in BUDGET.DAT, a RANDOM-ACCESS
'   file: every record is exactly the same size, so BASIC can jump
'   straight to record number N with GET and PUT without reading
'   everything before it - like pulling a numbered card out of a
'   box.
'
'   The summary adds up spending per category and draws a
'   horizontal bar chart, plus total income, total spending and
'   the balance.
'
' HOW TO USE
'   I = add income      E = add expense     L = list entries
'   S = summary chart   D = delete an entry X = start a fresh file
'   Q or Esc = quit.    (A few sample entries are added the very
'   first time so the chart has something to show.)
'
' CONCEPTS YOU WILL LEARN
'   * TYPE ... END TYPE to describe a fixed-size record
'   * OPEN ... FOR RANDOM ... LEN = LEN(record)
'   * PUT #1, n, rec  and  GET #1, n, rec
'   * LOF(1) \ LEN(rec) = how many records the file holds
'   * Fixed-length strings (STRING * 12) and RTRIM$
'
' THINGS TO TRY
'   * Add a monthly filter: only show entries for "10-2026".
'   * Set a budget limit per category and warn when it's exceeded.
'   * Export the entries to a CSV text file for a real spreadsheet.
' ============================================================

DECLARE SUB AddEntry (sign%)

' One record = 10 + 10 + 20 + 8 = 48 bytes, always.
TYPE Entry
    dat AS STRING * 10          ' "MM-DD-YYYY" like DATE$
    cat AS STRING * 10          ' category
    desc AS STRING * 20         ' description
    amount AS DOUBLE            ' + income, - expense
END TYPE

DIM SHARED rec AS Entry
CONST NCAT = 8
DIM SHARED catName$(1 TO NCAT)
DIM tot#(1 TO NCAT)             ' running total per category
FOR i = 1 TO NCAT: READ catName$(i): NEXT i
DATA Income,Food,Housing,Transport,Fun,Bills,Shopping,Other

OPEN "BUDGET.DAT" FOR RANDOM AS #1 LEN = LEN(rec)

' First run?  The file is empty, so add some example entries.
IF LOF(1) = 0 THEN
    RESTORE Samples
    FOR i = 1 TO 7
        READ rec.dat, rec.cat, rec.desc, rec.amount
        PUT #1, i, rec
    NEXT i
END IF

DO
    ' How many records are in the file right now?
    nRec = LOF(1) \ LEN(rec)
    CLS
    COLOR 15, 2: PRINT SPACE$(80);: LOCATE 1, 33: PRINT "BUDGET TRACKER": COLOR 7, 0
    PRINT
    PRINT "  Entries in BUDGET.DAT:"; nRec
    PRINT
    PRINT "  I  Add income        L  List entries"
    PRINT "  E  Add expense       S  Summary & chart"
    PRINT "  D  Delete an entry   X  Start a fresh file"
    PRINT "  Q  Quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    PRINT
    SELECT CASE k$
        CASE "I": AddEntry 1
        CASE "E": AddEntry -1
        CASE "L"
            CLS
            PRINT "  #  Date       Category   Description             Amount"
            PRINT "  "; STRING$(55, "-")
            FOR i = 1 TO nRec
                GET #1, i, rec          ' jump straight to record i
                IF rec.amount < 0 THEN COLOR 12 ELSE COLOR 10
                PRINT USING " ##  & & & ######.##"; i; rec.dat; rec.cat; rec.desc; rec.amount
                COLOR 7
                ' pause each screenful
                IF i MOD 18 = 0 AND i < nRec THEN
                    PRINT "  -- more (any key) --": DO: LOOP WHILE INKEY$ = ""
                END IF
            NEXT i
            GOSUB WaitKey
        CASE "S"
            ' ---- Add up each category ----
            ERASE tot#                    ' ERASE sets every total back to 0
            inc# = 0: spent# = 0
            FOR i = 1 TO nRec
                GET #1, i, rec
                IF rec.amount >= 0 THEN inc# = inc# + rec.amount ELSE spent# = spent# - rec.amount
                FOR c = 1 TO NCAT
                    IF RTRIM$(rec.cat) = catName$(c) THEN tot#(c) = tot#(c) + ABS(rec.amount)
                NEXT c
            NEXT i
            CLS
            PRINT "  SPENDING BY CATEGORY"
            PRINT
            ' Scale bars so the biggest spending category is 40 wide.
            big# = 1
            FOR c = 2 TO NCAT: IF tot#(c) > big# THEN big# = tot#(c)
            NEXT c
            FOR c = 2 TO NCAT              ' 1 = Income, not spending
                PRINT USING "  \        \ $$#####.## "; catName$(c); tot#(c);
                COLOR c + 7: PRINT STRING$(INT(tot#(c) / big# * 40), 219): COLOR 7
            NEXT c
            PRINT
            PRINT USING "  Total income:   $$######.##"; inc#
            PRINT USING "  Total spending: $$######.##"; spent#
            IF inc# - spent# >= 0 THEN COLOR 10 ELSE COLOR 12
            PRINT USING "  Balance:       $$#######.##"; inc# - spent#
            COLOR 7
            IF inc# > 0 THEN PRINT USING "  You spent ###% of your income."; spent# / inc# * 100
            GOSUB WaitKey
        CASE "D"
            INPUT "  Delete entry number"; d
            IF d >= 1 AND d <= nRec THEN
                ' Random files can't shrink, so we copy every later
                ' record down one place into a new file.
                OPEN "BUDGET.TMP" FOR RANDOM AS #2 LEN = LEN(rec)
                j = 0
                FOR i = 1 TO nRec
                    IF i <> d THEN GET #1, i, rec: j = j + 1: PUT #2, j, rec
                NEXT i
                CLOSE #1, #2
                KILL "BUDGET.DAT"
                NAME "BUDGET.TMP" AS "BUDGET.DAT"
                OPEN "BUDGET.DAT" FOR RANDOM AS #1 LEN = LEN(rec)
            END IF
        CASE "X"
            INPUT "  Erase ALL entries (Y/N)"; a$
            IF UCASE$(LEFT$(a$, 1)) = "Y" THEN
                CLOSE #1
                ' OPEN FOR OUTPUT creates an empty file.
                OPEN "BUDGET.DAT" FOR OUTPUT AS #1: CLOSE #1
                OPEN "BUDGET.DAT" FOR RANDOM AS #1 LEN = LEN(rec)
            END IF
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLOSE
CLS
PRINT "Budget saved in BUDGET.DAT"
END

WaitKey:
    PRINT
    PRINT "  Press any key..."
    DO: LOOP WHILE INKEY$ = ""
    RETURN

Samples:
DATA 10-01-2026,Income,Salary,2400
DATA 10-02-2026,Housing,Rent,-950
DATA 10-03-2026,Food,Groceries,-120.45
DATA 10-05-2026,Transport,Bus pass,-60
DATA 10-08-2026,Fun,Cinema,-24.5
DATA 10-09-2026,Bills,Electricity,-75.2
DATA 10-12-2026,Food,Pizza night,-31.99

' Ask for one entry and append it as a new record at the end.
SUB AddEntry (sign%)
    IF sign% > 0 THEN PRINT "  NEW INCOME" ELSE PRINT "  NEW EXPENSE - categories:"
    IF sign% < 0 THEN
        FOR c = 2 TO NCAT: PRINT "    "; LTRIM$(STR$(c)); " "; catName$(c): NEXT c
        INPUT "  Category number"; c
        IF c < 2 OR c > NCAT THEN c = NCAT          ' "Other"
    ELSE
        c = 1
    END IF
    LINE INPUT "  Description: "; d$
    INPUT "  Amount: ", a#
    IF a# = 0 THEN EXIT SUB
    rec.dat = DATE$
    rec.cat = catName$(c)          ' padded/cut to 10 chars automatically
    rec.desc = d$
    rec.amount = sign% * ABS(a#)
    n = LOF(1) \ LEN(rec)
    PUT #1, n + 1, rec             ' record n + 1 = a new one at the end
END SUB
