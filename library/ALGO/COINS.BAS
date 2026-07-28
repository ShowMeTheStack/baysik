' ============================================================
' TITLE:    Coin Change: Greedy vs. Dynamic Programming
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     greedy, dynamic programming, optimization, money
' SUMMARY:  Make change with the fewest coins - and discover the coin systems where the "obvious" greedy method fails.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick a coin system and an amount.  The program makes change two ways:
'     GREEDY - always grab the biggest coin that still fits
'     DP     - dynamic programming: work out the best answer for every
'              amount from 0 up to the target, reusing smaller answers
'   For ordinary coins (1, 5, 10, 25) both agree.  For odd systems such
'   as (1, 3, 4) greedy can lose: for 6 it gives 4+1+1, but 3+3 is
'   better.  The program also searches for the smallest such amount.
'
' HOW TO USE
'   Choose a coin system (1-4), then type amounts.  Enter 0 to go back
'   to the menu.  Q at the menu quits.
'
' CONCEPTS YOU WILL LEARN
'   * The greedy strategy and when it is (and isn't) correct
'   * Dynamic programming: best(a) = 1 + min over coins c of best(a-c)
'   * Rebuilding the actual answer from a "last coin used" table
'   * Greedy is O(number of coins); DP is O(amount * coins)
'
' THINGS TO TRY
'   * Invent your own coin system in the DATA lines
'   * Make the DP count the NUMBER OF WAYS to make change instead
' ============================================================
DECLARE SUB Greedy (amt%)
DECLARE SUB DP (amt%, quiet%)
DECLARE SUB PrintTally ()
DEFINT A-Z
CONST MAXAMT = 2000
DIM SHARED coin(1 TO 6), nc                   ' current coin system
DIM SHARED best(0 TO MAXAMT), lastCoin(0 TO MAXAMT)
DIM SHARED gCount                             ' coins used by greedy
DIM SHARED tally(1 TO 6)                      ' how many of each coin
DIM sysName$(1 TO 4)

' Coin systems: name, count, coins (largest first)
DATA "US coins",4,25,10,5,1
DATA "Euro cents",6,50,20,10,5,2,1
DATA "Odd coins",3,4,3,1
DATA "Old UK (1,3,6,12,24,30)",6,30,24,12,6,3,1

DO
    COLOR 7, 0: CLS
    COLOR 15: PRINT "COIN CHANGE: GREEDY vs DYNAMIC PROGRAMMING": COLOR 7
    PRINT
    RESTORE
    FOR s = 1 TO 4
        READ sysName$(s), cnt
        PRINT "  "; s; "- "; sysName$(s); " :";
        FOR i = 1 TO cnt: READ c: PRINT c; : NEXT
        PRINT
    NEXT
    PRINT "  Q - quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    sel = VAL(k$)
    IF sel >= 1 AND sel <= 4 THEN
        ' load the chosen system into coin()
        RESTORE
        FOR s = 1 TO sel
            READ nm$, nc
            FOR i = 1 TO nc: READ coin(i): NEXT
        NEXT
        PRINT : PRINT "Using "; nm$
        ' Find the smallest amount where greedy is NOT optimal.
        DP 200, -1                       ' fill best() for 0..200 quietly
        bad = 0
        FOR a = 1 TO 200
            Greedy -a                    ' negative = don't print
            IF gCount > best(a) THEN bad = a: EXIT FOR
        NEXT
        IF bad THEN
            COLOR 12
            PRINT "Greedy fails! Smallest bad amount:"; bad; "(greedy"; gCount; "coins, best"; best(bad); ")"
        ELSE
            COLOR 10
            PRINT "Greedy is optimal for every amount up to 200 with these coins."
        END IF
        COLOR 7
        DO
            PRINT
            LINE INPUT "Amount (1-2000, 0 = menu): "; t$
            amt = VAL(t$)
            IF amt <= 0 OR amt > MAXAMT THEN EXIT DO
            Greedy amt
            DP amt, 0
        LOOP
    END IF
LOOP
CLS
END

' --------------------------------------------------------------
' DP: best(a) = the fewest coins that add up to exactly a.
'   best(0) = 0                       (no coins needed for nothing)
'   best(a) = 1 + smallest best(a - c) over every coin c <= a
' The idea: the LAST coin we use is some c; what remains, a - c,
' must itself be paid in the best possible way - and we already
' know that answer because we fill the table from small to large.
' lastCoin(a) remembers which c won, so we can list the coins.
' Time O(amount * number of coins), memory O(amount).
' --------------------------------------------------------------
SUB DP (amt, quiet)
    CONST INF = 32000
    best(0) = 0
    FOR a = 1 TO amt
        best(a) = INF
        FOR i = 1 TO nc
            c = coin(i)
            IF c <= a THEN
                IF best(a - c) + 1 < best(a) THEN
                    best(a) = best(a - c) + 1
                    lastCoin(a) = c
                END IF
            END IF
        NEXT
    NEXT
    IF quiet THEN EXIT SUB
    PRINT "  DP:     ";
    IF best(amt) >= INF THEN PRINT "impossible!": EXIT SUB
    FOR i = 1 TO nc: tally(i) = 0: NEXT
    a = amt
    DO WHILE a > 0                    ' walk back through the choices
        FOR i = 1 TO nc               ' which slot is this coin?
            IF coin(i) = lastCoin(a) THEN tally(i) = tally(i) + 1
        NEXT
        a = a - lastCoin(a)
    LOOP
    PrintTally
    PRINT " ="; best(amt); "coins"
END SUB

' Prints the coins in tally() as "3x25 2x10 ..." (biggest first).
SUB PrintTally
    FOR i = 1 TO nc
        IF tally(i) > 0 THEN PRINT LTRIM$(STR$(tally(i))); "x"; LTRIM$(STR$(coin(i))); " ";
    NEXT
END SUB

' --------------------------------------------------------------
' GREEDY: take as many of the biggest coin as fit, then the next.
' It never reconsiders a choice.  Super fast, and correct for
' "canonical" systems like US or Euro coins - but not for all.
' A negative amount means "just count, don't print".
' --------------------------------------------------------------
SUB Greedy (amt)
    quiet = amt < 0
    rest = ABS(amt)
    gCount = 0
    IF NOT quiet THEN PRINT "  Greedy: ";
    FOR i = 1 TO nc                       ' coins are stored largest first
        tally(i) = 0
        DO WHILE rest >= coin(i)
            rest = rest - coin(i)
            gCount = gCount + 1
            tally(i) = tally(i) + 1
        LOOP
    NEXT
    IF quiet THEN EXIT SUB
    PrintTally
    IF rest > 0 THEN
        PRINT " (stuck with"; rest; "left over!)"
    ELSE
        PRINT " ="; gCount; "coins"
    END IF
END SUB
