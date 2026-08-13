' ============================================================
' TITLE:    Custom Errors with ERROR n
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     error, on error, err, custom errors, validation, piggy bank
' SUMMARY:  A piggy-bank command line that raises its own error codes (ERROR 201..205) and handles them in one place.
' ------------------------------------------------------------
' WHAT IT DOES
'   The ERROR statement makes BASIC behave exactly as if a runtime
'   error had happened.  Numbers 1..~76 are BASIC's own errors, but
'   unused numbers (such as 200-255) are free for YOUR program.  So a
'   SUB deep inside your program can simply say  ERROR 201  when
'   something is wrong, and one central handler prints the message.
'   This is the same idea as "throw" and "catch" in modern languages.
'
' HOW TO USE
'   Type commands at the  Bank>  prompt:
'     DEPOSIT 20     WITHDRAW 5     BALANCE     HISTORY     QUIT
'   Try breaking it: WITHDRAW 1000, DEPOSIT -3, DEPOSIT abc, FLY 9
'
' CONCEPTS YOU WILL LEARN
'   * ERROR n to raise your own numbered errors
'   * A single ON ERROR handler that knows about both BASIC's errors
'     and your custom ones
'   * Errors raised inside a SUB travel back to the module handler
'   * RESUME label to continue at a safe place
'
' THINGS TO TRY
'   * Add error 206 "Daily limit exceeded" for withdrawals over 50
'   * Count how many errors of each type happened
'   * Make the handler also print ERR for BASIC's built-in errors
' ============================================================

DECLARE SUB Deposit (amt AS SINGLE)
DECLARE SUB Withdraw (amt AS SINGLE)
DECLARE FUNCTION ParseAmount! (s$)

' Our own error codes - CONSTs make the code readable.
CONST ENOFUNDS = 201, ENEGATIVE = 202, EUNKNOWN = 203, ENOTNUM = 204, EBIGNUM = 205

DIM SHARED balance AS SINGLE
DIM SHARED hist$(1 TO 100), nHist AS INTEGER

ON ERROR GOTO Handler
CLS
PRINT "PIGGY BANK  (custom error demo)"
PRINT "Commands: DEPOSIT n, WITHDRAW n, BALANCE, HISTORY, QUIT"
PRINT

NextCmd:
DO
    LINE INPUT "Bank> "; cmd$
    cmd$ = UCASE$(LTRIM$(RTRIM$(cmd$)))
    sp = INSTR(cmd$, " ")                ' split "VERB argument"
    IF sp THEN
        verb$ = LEFT$(cmd$, sp - 1): arg$ = MID$(cmd$, sp + 1)
    ELSE
        verb$ = cmd$: arg$ = ""
    END IF

    SELECT CASE verb$
        CASE "DEPOSIT", "D": Deposit ParseAmount(arg$)
        CASE "WITHDRAW", "W": Withdraw ParseAmount(arg$)
        CASE "BALANCE", "B": PRINT USING "  Balance: $$#####.##"; balance
        CASE "HISTORY", "H"
            FOR i = 1 TO nHist: PRINT "  "; hist$(i): NEXT i
            IF nHist = 0 THEN PRINT "  (no transactions yet)"
        CASE "QUIT", "Q", "EXIT": EXIT DO
        CASE "": ' empty line - ignore it
        CASE ELSE: ERROR EUNKNOWN          ' "throw" our own error
    END SELECT
LOOP
PRINT "Goodbye!"         ' (no "!" inside PRINT USING: it is a format character)
PRINT USING "Final balance $$#####.##"; balance
END

' ==== the one-and-only error handler ("catch") ======================
Handler:
    SELECT CASE ERR
        CASE ENOFUNDS:  msg$ = "Not enough money in the piggy bank."
        CASE ENEGATIVE: msg$ = "Amounts must be more than zero."
        CASE EUNKNOWN:  msg$ = "Unknown command.  Try DEPOSIT, WITHDRAW, BALANCE, HISTORY, QUIT."
        CASE ENOTNUM:   msg$ = "That amount is not a number."
        CASE EBIGNUM:   msg$ = "Whoa, that is too much money for a piggy bank!"
        CASE ELSE:      msg$ = "BASIC error" + STR$(ERR)   ' a real bug
    END SELECT
    COLOR 12: PRINT "  ERROR"; ERR; "- "; msg$: COLOR 7
    RESUME NextCmd                    ' abandon the command, ask again

' ---------------------------------------------------------------------
' Turn the text after the verb into a number, or raise an error.
FUNCTION ParseAmount! (s$)
    IF s$ = "" THEN ERROR ENOTNUM
    ' VAL() quietly returns 0 for junk, so check every character first
    dots = 0
    FOR i = 1 TO LEN(s$)
        c$ = MID$(s$, i, 1)
        IF c$ = "." THEN
            dots = dots + 1
        ELSEIF c$ = "-" AND i = 1 THEN
            ' a leading minus sign is allowed here; Deposit/Withdraw reject it
        ELSEIF c$ < "0" OR c$ > "9" THEN
            ERROR ENOTNUM
        END IF
    NEXT i
    IF dots > 1 THEN ERROR ENOTNUM
    v! = VAL(s$)
    IF v! > 99999 THEN ERROR EBIGNUM
    ParseAmount! = v!
END FUNCTION

SUB Deposit (amt AS SINGLE)
    IF amt <= 0 THEN ERROR ENEGATIVE
    balance = balance + amt
    IF nHist < 100 THEN nHist = nHist + 1: hist$(nHist) = "+" + STR$(amt)
    PRINT USING "  Deposited $$####.##"; amt
END SUB

SUB Withdraw (amt AS SINGLE)
    IF amt <= 0 THEN ERROR ENEGATIVE
    IF amt > balance THEN ERROR ENOFUNDS
    balance = balance - amt
    IF nHist < 100 THEN nHist = nHist + 1: hist$(nHist) = "-" + STR$(amt)
    PRINT USING "  Withdrew  $$####.##"; amt
END SUB
