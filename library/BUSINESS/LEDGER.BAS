' ============================================================
' TITLE:    Double-Entry General Ledger
' CATEGORY: Business & Finance
' LEVEL:    Advanced
' TAGS:     accounting, double entry, journal, trial balance, arrays, files
' SUMMARY:  Post journal entries as debits and credits, then produce account ledgers, a trial balance and a balance check.
' ------------------------------------------------------------
' WHAT IT DOES
'   Real bookkeeping uses DOUBLE ENTRY: every transaction touches
'   at least two accounts, and the DEBITS always equal the CREDITS.
'   Buying $500 of supplies with cash, for example, DEBITS Supplies
'   (it goes up) and CREDITS Cash (it goes down).
'   This program has a small chart of accounts, a journal of sample
'   transactions for a new business, and lets you add your own.
'   It then prints:
'     * the JOURNAL (every entry in date order)
'     * the LEDGER for any one account (a "T-account" history)
'     * the TRIAL BALANCE - if total debits = total credits, the
'       books balance! It also checks Assets = Liabilities + Equity.
'   The journal is saved to JOURNAL.TXT.
'
' HOW TO USE
'   J = show journal, L = ledger for an account, T = trial balance,
'   A = add an entry, Q = save and quit.
'
' CONCEPTS YOU WILL LEARN
'   * Debits and credits; "normal balance" of each account type
'   * The accounting equation A = L + E (+ Revenue - Expenses)
'   * Parallel arrays as a tiny database, searching by account no.
'   * Saving records to a text file with WRITE #
'
' THINGS TO TRY
'   * Add an income statement: Revenue - Expenses = Net income
'   * Allow an entry with three lines (a "compound" entry)
'   * Load JOURNAL.TXT at start-up if it exists
' ============================================================

CONST MAXACC = 12, MAXJ = 100
DIM accNo(1 TO MAXACC), accName$(1 TO MAXACC), accType$(1 TO MAXACC)
DIM jDate$(1 TO MAXJ), jDesc$(1 TO MAXJ), jDr(1 TO MAXJ), jCr(1 TO MAXJ), jAmt#(1 TO MAXJ)
DIM bal#(1 TO MAXACC)

' ---- Chart of accounts ------------------------------------------------
' Type: A = asset, L = liability, E = equity, R = revenue, X = expense
' Assets and expenses normally have DEBIT balances; the others CREDIT.
RESTORE Accounts
nAcc = 0
DO
    READ n, nm$, t$
    IF n = 0 THEN EXIT DO
    nAcc = nAcc + 1
    accNo(nAcc) = n: accName$(nAcc) = nm$: accType$(nAcc) = t$
LOOP

' ---- Sample journal --------------------------------------------------
RESTORE Journal
nJ = 0
DO
    READ d$, ds$, dr, cr, amt#
    IF d$ = "END" THEN EXIT DO
    nJ = nJ + 1
    jDate$(nJ) = d$: jDesc$(nJ) = ds$: jDr(nJ) = dr: jCr(nJ) = cr: jAmt#(nJ) = amt#
LOOP

DO
    CLS
    PRINT "SUNNY DAYS BIKE REPAIR - GENERAL LEDGER"
    PRINT nJ; "journal entries,"; nAcc; "accounts"
    PRINT
    PRINT "J)ournal  L)edger account  T)rial balance  A)dd entry  Q)uit"
    INPUT "Choice"; c$
    SELECT CASE UCASE$(LEFT$(c$, 1))
    CASE "J": GOSUB ShowJournal
    CASE "L": GOSUB ShowLedger
    CASE "T": GOSUB Trial
    CASE "A": GOSUB AddEntry
    CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP

' ---- Save the journal ------------------------------------------------
OPEN "JOURNAL.TXT" FOR OUTPUT AS #1
FOR i = 1 TO nJ
    WRITE #1, jDate$(i), jDesc$(i), jDr(i), jCr(i), jAmt#(i)
NEXT i
CLOSE #1
PRINT "Journal saved to JOURNAL.TXT"
END

' ------------------------------------------------------------
ShowJournal:
    CLS
    PRINT "Date   Description            Account                 Debit         Credit"
    PRINT STRING$(76, "-")
    FOR i = 1 TO nJ
        ' Each entry prints two lines: the debit, then the credit
        ' (indented, as accountants traditionally write it).
        a = jDr(i): GOSUB FindAcc
        PRINT USING "\   \  \                    \ \                 \ ##,###.##"; jDate$(i); jDesc$(i); accName$(idx); jAmt#(i)
        a = jCr(i): GOSUB FindAcc
        PRINT USING "                              \                 \                ##,###.##"; accName$(idx); jAmt#(i)
        IF i MOD 9 = 0 AND i < nJ THEN PRINT "-- more --": k$ = INPUT$(1)
    NEXT i
    PRINT "Press a key": k$ = INPUT$(1)
RETURN

' ------------------------------------------------------------
' ShowLedger: every line that touches one account, with a
' running balance.
' ------------------------------------------------------------
ShowLedger:
    CLS
    FOR i = 1 TO nAcc
        PRINT USING "### \                  \  "; accNo(i); accName$(i);
        IF i MOD 2 = 0 THEN PRINT
    NEXT i
    PRINT
    INPUT "Account number"; a
    GOSUB FindAcc
    IF idx = 0 THEN PRINT "No such account.": k$ = INPUT$(1): RETURN
    CLS
    PRINT "LEDGER:"; accNo(idx); accName$(idx)
    PRINT "Date   Description                    Debit    Credit     Balance"
    PRINT STRING$(68, "-")
    run# = 0
    ' Debit-normal accounts (A, X) grow with debits; others with credits.
    debitNormal = (accType$(idx) = "A" OR accType$(idx) = "X")
    FOR i = 1 TO nJ
        IF jDr(i) = a OR jCr(i) = a THEN
            IF jDr(i) = a THEN dr# = jAmt#(i): cr# = 0 ELSE dr# = 0: cr# = jAmt#(i)
            IF debitNormal THEN run# = run# + dr# - cr# ELSE run# = run# + cr# - dr#
            PRINT USING "\   \  \                        \ ##,###.## ##,###.##  ###,###.##"; jDate$(i); jDesc$(i); dr#; cr#; run#
        END IF
    NEXT i
    PRINT STRING$(68, "-")
    PRINT "Press a key": k$ = INPUT$(1)
RETURN

' ------------------------------------------------------------
' Trial: total all debits and credits per account. The balance of
' each account goes in the debit or credit column depending on
' which side is bigger.
' ------------------------------------------------------------
Trial:
    FOR i = 1 TO nAcc: bal#(i) = 0: NEXT i
    FOR i = 1 TO nJ
        a = jDr(i): GOSUB FindAcc: bal#(idx) = bal#(idx) + jAmt#(i)
        a = jCr(i): GOSUB FindAcc: bal#(idx) = bal#(idx) - jAmt#(i)
    NEXT i
    CLS
    PRINT "TRIAL BALANCE"
    PRINT "No.  Account             Type        Debit      Credit"
    PRINT STRING$(60, "-")
    tDr# = 0: tCr# = 0
    asset# = 0: liab# = 0: eq# = 0: rev# = 0: expn# = 0
    FOR i = 1 TO nAcc
        b# = bal#(i)       ' positive = debit balance
        IF b# <> 0 THEN
            IF b# > 0 THEN
                PRINT USING "###  \                  \  !    ###,###.##"; accNo(i); accName$(i); accType$(i); b#
                tDr# = tDr# + b#
            ELSE
                PRINT USING "###  \                  \  !                ###,###.##"; accNo(i); accName$(i); accType$(i); -b#
                tCr# = tCr# - b#
            END IF
        END IF
        SELECT CASE accType$(i)
            CASE "A": asset# = asset# + b#
            CASE "L": liab# = liab# - b#
            CASE "E": eq# = eq# - b#
            CASE "R": rev# = rev# - b#
            CASE "X": expn# = expn# + b#
        END SELECT
    NEXT i
    PRINT STRING$(60, "-")
    PRINT USING "     TOTALS                     ###,###.##  ###,###.##"; tDr#; tCr#
    PRINT
    IF ABS(tDr# - tCr#) < .005 THEN
        COLOR 10: PRINT "Debits = credits: the books BALANCE.": COLOR 7
    ELSE
        COLOR 12: PRINT "Out of balance!": COLOR 7
    END IF
    ' The accounting equation, with this period's profit added to equity.
    PRINT USING "Net income (revenue - expenses):          $$###,###.##"; rev# - expn#
    PRINT USING "Assets                                    $$###,###.##"; asset#
    PRINT USING "Liabilities + Equity + Net income         $$###,###.##"; liab# + eq# + rev# - expn#
    PRINT "Press a key": k$ = INPUT$(1)
RETURN

' ------------------------------------------------------------
AddEntry:
    IF nJ >= MAXJ THEN PRINT "Journal full.": k$ = INPUT$(1): RETURN
    INPUT "Date (e.g. 03/15)"; d$
    INPUT "Description"; ds$
    INPUT "DEBIT account no."; a: GOSUB FindAcc: i1 = idx
    INPUT "CREDIT account no."; a: GOSUB FindAcc: i2 = idx
    INPUT "Amount"; amt#
    IF i1 = 0 OR i2 = 0 OR i1 = i2 OR amt# <= 0 THEN
        PRINT "Entry rejected (bad account or amount).": k$ = INPUT$(1)
    ELSE
        nJ = nJ + 1
        jDate$(nJ) = LEFT$(d$, 5): jDesc$(nJ) = ds$
        jDr(nJ) = accNo(i1): jCr(nJ) = accNo(i2): jAmt#(nJ) = amt#
    END IF
RETURN

' FindAcc: look up account number a; idx = its position or 0.
FindAcc:
    idx = 0
    FOR j = 1 TO nAcc
        IF accNo(j) = a THEN idx = j: EXIT FOR
    NEXT j
RETURN

Accounts:
DATA 101, "Cash", A, 110, "Accounts receivable", A, 120, "Parts inventory", A
DATA 150, "Tools & equipment", A, 201, "Accounts payable", L, 220, "Bank loan", L
DATA 301, "Owner's capital", E, 401, "Repair revenue", R, 402, "Parts sales", R
DATA 501, "Rent expense", X, 502, "Wages expense", X, 503, "Utilities", X
DATA 0, "", ""

Journal:
' date, description, debit account, credit account, amount
DATA "03/01", "Owner invests cash", 101, 301, 15000
DATA "03/01", "Bank loan received", 101, 220, 8000
DATA "03/02", "Buy tools for cash", 150, 101, 6200
DATA "03/03", "Parts bought on credit", 120, 201, 2400
DATA "03/05", "Pay March rent", 501, 101, 1100
DATA "03/09", "Repairs for cash", 101, 401, 1850
DATA "03/12", "Repairs billed to club", 110, 401, 960
DATA "03/15", "Pay assistant wages", 502, 101, 1300
DATA "03/18", "Sell parts for cash", 101, 402, 740
DATA "03/22", "Pay supplier", 201, 101, 1200
DATA "03/25", "Club pays its bill", 101, 110, 960
DATA "03/28", "Electricity bill", 503, 101, 185
DATA "END", "", 0, 0, 0
