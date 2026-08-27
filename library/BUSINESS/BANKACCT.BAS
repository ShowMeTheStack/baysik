' ============================================================
' TITLE:    Bank Account Simulator
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     TYPE records, arrays of records, SUB, transactions, statements
' SUMMARY:  Open accounts, deposit, withdraw and transfer, run month-end interest and fees, and print statements.
' ------------------------------------------------------------
' WHAT IT DOES
'   A tiny bank. Each ACCOUNT is a TYPE record holding its number,
'   owner, kind (Checking or Savings) and balance. Every money
'   movement is also stored as a TRANSACTION record (date, account,
'   description, amount, balance after), which is how real banks
'   produce statements.
'   Rules of this bank:
'     * Savings earn 3% a year, paid monthly at month-end.
'     * Checking accounts below $500 pay a $5 monthly fee.
'     * Withdrawals can't take a balance below zero.
'
' HOW TO USE
'   O = open account  D = deposit  W = withdraw  T = transfer
'   M = month-end (interest & fees)  S = statement  L = list
'   Q = quit. Three sample accounts exist when you start.
'
' CONCEPTS YOU WILL LEARN
'   * TYPE ... END TYPE records with strings and numbers
'   * Arrays of records shared by SUBs (DIM SHARED)
'   * Keeping an audit trail: every change is a transaction
'   * Business rules expressed as IF tests
'
' THINGS TO TRY
'   * Add an overdraft limit for checking accounts
'   * Save the accounts to a RANDOM file and load them next run
'   * Add a loan account type with interest charged instead of paid
' ============================================================

DECLARE SUB Post (acc%, desc$, amt#)
DECLARE SUB Statement (acc%)
DECLARE FUNCTION FindAcc% ()

TYPE Account
    number AS LONG
    owner AS STRING * 18
    kind AS STRING * 1         ' "C" checking or "S" savings
    balance AS DOUBLE
END TYPE

TYPE Txn
    day AS INTEGER             ' simulated day number
    acc AS INTEGER             ' index into the accounts array
    desc AS STRING * 22
    amount AS DOUBLE           ' + money in, - money out
    after AS DOUBLE            ' balance after this transaction
END TYPE

CONST MAXA = 20, MAXT = 500
DIM SHARED acct(1 TO MAXA) AS Account
DIM SHARED tx(1 TO MAXT) AS Txn
DIM SHARED nA AS INTEGER, nT AS INTEGER, today AS INTEGER

today = 1
' ---- Sample accounts --------------------------------------------------
FOR i = 1 TO 3
    READ o$, k$, d#
    nA = nA + 1
    acct(nA).number = 10000 + nA * 37       ' made-up account numbers
    acct(nA).owner = o$
    acct(nA).kind = k$
    Post nA, "Opening deposit", d#
NEXT i
DATA "Maria Santos", "C", 1250, "Maria Santos", "S", 5000, "Tom Becker", "C", 320

DO
    CLS
    PRINT USING "FIRST BASIC BANK                         Day ###"; today
    PRINT
    PRINT "O)pen  D)eposit  W)ithdraw  T)ransfer  M)onth-end  S)tatement  L)ist  Q)uit"
    INPUT "Choice"; c$
    SELECT CASE UCASE$(LEFT$(c$, 1))
    CASE "O"
        IF nA < MAXA THEN
            LINE INPUT "Owner name: "; o$
            INPUT "Checking or Savings (C/S)"; k$
            k$ = UCASE$(LEFT$(k$, 1)): IF k$ <> "S" THEN k$ = "C"
            nA = nA + 1
            acct(nA).number = 10000 + nA * 37
            acct(nA).owner = o$: acct(nA).kind = k$
            acct(nA).balance = 0
            PRINT "New account number:"; acct(nA).number
            k$ = INPUT$(1)
        END IF
    CASE "D"
        a% = FindAcc%
        IF a% THEN
            INPUT "Deposit amount"; amt#
            IF amt# > 0 THEN Post a%, "Deposit", amt#
        END IF
    CASE "W"
        a% = FindAcc%
        IF a% THEN
            INPUT "Withdraw amount"; amt#
            IF amt# > acct(a%).balance THEN
                PRINT "Insufficient funds!": k$ = INPUT$(1)
            ELSEIF amt# > 0 THEN
                Post a%, "Cash withdrawal", -amt#
            END IF
        END IF
    CASE "T"
        PRINT "FROM:": a% = FindAcc%
        PRINT "TO:": b% = FindAcc%
        IF a% > 0 AND b% > 0 AND a% <> b% THEN
            INPUT "Amount"; amt#
            IF amt# > 0 AND amt# <= acct(a%).balance THEN
                ' A transfer is TWO transactions: out of one, into the other.
                Post a%, "Transfer to" + STR$(acct(b%).number), -amt#
                Post b%, "Transfer from" + STR$(acct(a%).number), amt#
            ELSE
                PRINT "Transfer refused.": k$ = INPUT$(1)
            END IF
        END IF
    CASE "M"
        ' ---- Month-end processing for every account --------------
        today = today + 30
        ' i% is an INTEGER because Post expects an INTEGER account index
        ' (passing a single-precision i would be a type mismatch).
        FOR i% = 1 TO nA
            IF acct(i%).kind = "S" THEN
                ' 3% per year = 0.25% per month, rounded to cents.
                intr# = INT(acct(i%).balance * .03 / 12 * 100 + .5) / 100
                IF intr# > 0 THEN Post i%, "Interest earned", intr#
            ELSEIF acct(i%).balance < 500 THEN
                fee# = 5
                IF fee# > acct(i%).balance THEN fee# = acct(i%).balance
                IF fee# > 0 THEN Post i%, "Low balance fee", -fee#
            END IF
        NEXT i%
        PRINT "Month-end done: interest paid and fees charged."
        k$ = INPUT$(1)
    CASE "S"
        a% = FindAcc%
        IF a% THEN Statement a%
    CASE "L"
        CLS
        PRINT "Number  Owner              Type        Balance"
        PRINT STRING$(48, "-")
        tot# = 0
        FOR i = 1 TO nA
            IF acct(i).kind = "S" THEN t$ = "Savings " ELSE t$ = "Checking"
            PRINT USING "###### \                \ \      \ ###,###.##"; acct(i).number; acct(i).owner; t$; acct(i).balance
            tot# = tot# + acct(i).balance
        NEXT i
        PRINT STRING$(48, "-")
        PRINT USING "Total deposits held by the bank:   $$###,###.##"; tot#
        k$ = INPUT$(1)
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
    today = today + 1              ' each action takes a "day"
LOOP
PRINT "Bank closed. Goodbye!"
END

' ------------------------------------------------------------
' FindAcc%: ask for an account number; return its index (0 if
' not found). Typing 1, 2, 3 ... also works as a shortcut.
' ------------------------------------------------------------
FUNCTION FindAcc%
    INPUT "Account number (or 1, 2, 3...)"; n&
    FindAcc% = 0
    IF n& >= 1 AND n& <= nA THEN FindAcc% = n&: EXIT FUNCTION
    FOR i = 1 TO nA
        IF acct(i).number = n& THEN FindAcc% = i: EXIT FUNCTION
    NEXT i
    PRINT "No such account.": k$ = INPUT$(1)
END FUNCTION

' ------------------------------------------------------------
' Post: THE only place where a balance changes. Changing it here
' and recording a transaction at the same time guarantees the
' statement always matches the balance.
' ------------------------------------------------------------
SUB Post (acc%, desc$, amt#)
    acct(acc%).balance = acct(acc%).balance + amt#
    IF nT < MAXT THEN
        nT = nT + 1
        tx(nT).day = today
        tx(nT).acc = acc%
        tx(nT).desc = desc$
        tx(nT).amount = amt#
        tx(nT).after = acct(acc%).balance
    END IF
END SUB

' ------------------------------------------------------------
' Statement: list every transaction for one account.
' ------------------------------------------------------------
SUB Statement (acc%)
    CLS
    PRINT "STATEMENT  Account"; acct(acc%).number; "  "; acct(acc%).owner
    PRINT
    PRINT "Day  Description              Money in   Money out     Balance"
    PRINT STRING$(66, "-")
    FOR i = 1 TO nT
        IF tx(i).acc = acc% THEN
            IF tx(i).amount >= 0 THEN
                PRINT USING "###  \                    \ ###,###.##              ###,###.##"; tx(i).day; tx(i).desc; tx(i).amount; tx(i).after
            ELSE
                PRINT USING "###  \                    \             ###,###.##  ###,###.##"; tx(i).day; tx(i).desc; -tx(i).amount; tx(i).after
            END IF
        END IF
    NEXT i
    PRINT STRING$(66, "-")
    PRINT USING "Closing balance                                   $$###,###.##"; acct(acc%).balance
    k$ = INPUT$(1)
END SUB
