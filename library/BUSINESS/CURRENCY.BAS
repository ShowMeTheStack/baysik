' ============================================================
' TITLE:    Currency Converter Tables
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     currency, exchange rates, cross rates, tables, PRINT USING
' SUMMARY:  Convert money between eight currencies and print a traveller's ready-reckoner and a cross-rate grid.
' ------------------------------------------------------------
' WHAT IT DOES
'   Exchange rates are stored as "how many units of this currency
'   buy one US dollar". To go from currency A to currency B we go
'   through the dollar: amount / rateA * rateB. The program can:
'     1. convert any amount between two currencies (with a bank fee)
'     2. print a ready-reckoner table (1, 5, 10, 20 ... 1000) for a
'        trip - handy to stick in your wallet
'     3. show a full CROSS-RATE grid: every currency against every
'        other one, like the boards in an exchange office
'   (The rates are sample values, not today's real ones.)
'
' HOW TO USE
'   Choose from the menu. Currencies are picked by their number.
'   Choose 4 or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Converting through a common "base" currency
'   * Nested FOR loops to build a 2-D table
'   * Choosing a PRINT USING format depending on the size of a number
'   * Fees and the "spread" between buying and selling rates
'
' THINGS TO TRY
'   * Update the rates in the DATA lines from a newspaper
'   * Make the bank fee a percentage typed by the user
'   * Show the reverse table (foreign -> home) next to it
' ============================================================

CONST NCUR = 8
CONST FEE = .025               ' 2.5 % bank fee on conversions
DIM cname$(1 TO NCUR), ccode$(1 TO NCUR), perUSD#(1 TO NCUR)
FOR i = 1 TO NCUR
    READ ccode$(i), cname$(i), perUSD#(i)
NEXT i

DO
    CLS
    PRINT "CURRENCY CONVERTER   (sample rates: units per 1 US dollar)"
    PRINT
    FOR i = 1 TO NCUR
        PRINT USING " #. \ \ \                  \ ######.####"; i; ccode$(i); cname$(i); perUSD#(i)
    NEXT i
    PRINT
    PRINT "1) Convert an amount   2) Travel table   3) Cross rates   4) Quit"
    INPUT "Choice"; c$
    SELECT CASE UCASE$(LEFT$(c$, 1))
    CASE "1"
        GOSUB PickPair
        IF ok THEN
            INPUT "Amount"; amt#
            ' Step 1: to dollars. Step 2: dollars to target currency.
            usd# = amt# / perUSD#(a)
            gross# = usd# * perUSD#(b)
            fee# = gross# * FEE
            PRINT
            PRINT USING "##########,.## \ \ = ##########,.## \ \"; amt#; ccode$(a); gross#; ccode$(b)
            PRINT USING "     bank fee 2.5%:  ##########,.## \ \"; fee#; ccode$(b)
            PRINT USING "     you receive:    ##########,.## \ \"; gross# - fee#; ccode$(b)
            PRINT USING "  (1 \ \ = ####.###### \ \)"; ccode$(a); perUSD#(b) / perUSD#(a); ccode$(b)
        END IF
    CASE "2"
        GOSUB PickPair
        IF ok THEN
            CLS
            PRINT "TRAVEL TABLE:  "; cname$(a); " -> "; cname$(b)
            PRINT STRING$(40, "-")
            RESTORE Amounts
            DO
                READ v#
                IF v# = 0 THEN EXIT DO
                x# = v# / perUSD#(a) * perUSD#(b)
                ' Big numbers (like yen) don't need decimals; small do.
                IF x# >= 10000 THEN
                    PRINT USING "  ######,  \ \  =  ############,  \ \"; v#; ccode$(a); x#; ccode$(b)
                ELSE
                    PRINT USING "  ######,  \ \  =  #########,.##  \ \"; v#; ccode$(a); x#; ccode$(b)
                END IF
            LOOP
        END IF
    CASE "3"
        ' Cross-rate grid: row currency -> column currency.
        ' Entry = how many COLUMN units one ROW unit buys.
        CLS
        PRINT "CROSS RATES (1 unit of the row currency buys ...)"
        PRINT
        PRINT "     ";
        FOR j = 1 TO NCUR: PRINT USING "     \ \ "; ccode$(j); : NEXT j
        PRINT
        FOR i = 1 TO NCUR
            PRINT USING "\ \  "; ccode$(i);
            FOR j = 1 TO NCUR
                x# = perUSD#(j) / perUSD#(i)
                IF i = j THEN
                    PRINT "      -  ";
                ELSEIF x# >= 1000 THEN
                    PRINT USING " ####### "; x#;
                ELSEIF x# >= 1 THEN
                    PRINT USING " ###.### "; x#;
                ELSE
                    PRINT USING " #.##### "; x#;
                END IF
            NEXT j
            PRINT
        NEXT i
    CASE "4", "Q"
        EXIT DO
    END SELECT
    PRINT
    PRINT "Press a key...": k$ = INPUT$(1)
LOOP
END

' PickPair: asks for "from" and "to" currency numbers; sets ok.
PickPair:
    INPUT "From currency #"; a
    INPUT "To currency #"; b
    ok = (a >= 1 AND a <= NCUR AND b >= 1 AND b <= NCUR AND a = INT(a) AND b = INT(b))
    IF NOT ok THEN PRINT "Please choose numbers 1 to"; NCUR
RETURN

' code, name, units per US dollar (sample values)
DATA USD, "US Dollar", 1
DATA EUR, "Euro", 0.92
DATA GBP, "British Pound", 0.79
DATA JPY, "Japanese Yen", 149.50
DATA CAD, "Canadian Dollar", 1.36
DATA INR, "Indian Rupee", 83.20
DATA MXN, "Mexican Peso", 17.10
DATA CHF, "Swiss Franc", 0.88
Amounts:
DATA 1, 5, 10, 20, 50, 100, 200, 500, 1000, 5000, 0
