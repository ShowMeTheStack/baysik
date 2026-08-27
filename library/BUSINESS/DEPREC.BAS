' ============================================================
' TITLE:    Depreciation Schedules
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     accounting, depreciation, SUB, arrays, PRINT USING, comparison
' SUMMARY:  Compare straight-line, double-declining and sum-of-years depreciation for a business asset, side by side.
' ------------------------------------------------------------
' WHAT IT DOES
'   When a business buys a truck or a machine, it doesn't count the
'   whole cost as an expense in year one. Instead it spreads the
'   cost over the asset's useful life: that is DEPRECIATION. The
'   "book value" (cost minus depreciation so far) shows what the
'   asset is still worth on paper. Three common methods:
'     STRAIGHT LINE   - the same amount every year
'     DOUBLE DECLINING BALANCE - twice the straight-line RATE applied
'                       to the remaining book value (big early,
'                       small later), switching to straight line
'                       when that gives more
'     SUM OF THE YEARS' DIGITS - fractions 5/15, 4/15, 3/15 ...
'   The program prints a schedule for each and then a comparison
'   with a little text graph of the book value.
'
' HOW TO USE
'   Enter the asset cost, its salvage (scrap) value at the end and
'   its useful life in years (2-20). Press a key between pages.
'
' CONCEPTS YOU WILL LEARN
'   * Three standard accounting formulas
'   * A SUB that fills an array passed to it
'   * Never depreciating below salvage value (clamping)
'   * Printing tables of several arrays side by side
'
' THINGS TO TRY
'   * Add 150% declining balance (rate = 1.5 / life)
'   * Handle a part year when the asset is bought mid-year
'   * Draw the three book-value curves in SCREEN 12
' ============================================================

DECLARE SUB StraightLine (cost#, salv#, life%, dep#())
DECLARE SUB DoubleDecl (cost#, salv#, life%, dep#())
DECLARE SUB SumYears (cost#, salv#, life%, dep#())
DECLARE SUB ShowSchedule (title$, cost#, life%, dep#())

CLS
PRINT "DEPRECIATION CALCULATOR"
PRINT
INPUT "Asset description      "; desc$
INPUT "Cost ($)               "; cost#
INPUT "Salvage value ($)      "; salv#
INPUT "Useful life (years)    "; life%
IF desc$ = "" THEN desc$ = "Delivery van"
IF cost# <= 0 THEN cost# = 36000
IF salv# < 0 OR salv# >= cost# THEN salv# = cost# / 10
IF life% < 2 OR life% > 20 THEN life% = 5

DIM sl#(1 TO life%), ddb#(1 TO life%), syd#(1 TO life%)
StraightLine cost#, salv#, life%, sl#()
DoubleDecl cost#, salv#, life%, ddb#()
SumYears cost#, salv#, life%, syd#()

ShowSchedule "STRAIGHT LINE: " + desc$, cost#, life%, sl#()
ShowSchedule "DOUBLE DECLINING BALANCE: " + desc$, cost#, life%, ddb#()
ShowSchedule "SUM OF THE YEARS' DIGITS: " + desc$, cost#, life%, syd#()

' ---- Comparison of book values ---------------------------------------
CLS
PRINT "BOOK VALUE AT YEAR END - all three methods"
PRINT "Year  Straight  Declining  Sum-years   (bar = straight-line book value)"
PRINT STRING$(76, "-")
bS# = cost#: bD# = cost#: bY# = cost#
FOR y = 1 TO life%
    bS# = bS# - sl#(y): bD# = bD# - ddb#(y): bY# = bY# - syd#(y)
    PRINT USING " ##  ###,###  ###,###    ###,###   "; y; bS#; bD#; bY#;
    ' A bar 30 characters long = the full cost.
    PRINT STRING$(INT(bS# / cost# * 30 + .5), 177)
NEXT y
PRINT
PRINT "Accelerated methods (declining, sum-of-years) give bigger"
PRINT "expenses early - which lowers taxes sooner - but every method"
PRINT USING "depreciates the same total: $$###,###.##"; cost# - salv#
END

' ------------------------------------------------------------
' StraightLine: (cost - salvage) / life, every single year.
' ------------------------------------------------------------
SUB StraightLine (cost#, salv#, life%, dep#())
    FOR y = 1 TO life%
        dep#(y) = (cost# - salv#) / life%
    NEXT y
END SUB

' ------------------------------------------------------------
' DoubleDecl: rate = 2 / life. Each year's depreciation is
' rate * book value at the start of the year. Two rules:
'   * never go below salvage value
'   * switch to straight line over the remaining years when that
'     would give a bigger amount (otherwise we'd never reach salvage)
' ------------------------------------------------------------
SUB DoubleDecl (cost#, salv#, life%, dep#())
    rate# = 2 / life%
    book# = cost#
    FOR y = 1 TO life%
        d# = book# * rate#
        slRest# = (book# - salv#) / (life% - y + 1)   ' straight line on what's left
        IF slRest# > d# THEN d# = slRest#
        IF book# - d# < salv# THEN d# = book# - salv#  ' clamp
        dep#(y) = d#
        book# = book# - d#
    NEXT y
END SUB

' ------------------------------------------------------------
' SumYears: for a 5-year life the digits add up to 1+2+3+4+5 = 15
' (formula n(n+1)/2). Year 1 gets 5/15, year 2 gets 4/15, ...
' ------------------------------------------------------------
SUB SumYears (cost#, salv#, life%, dep#())
    total = life% * (life% + 1) / 2
    FOR y = 1 TO life%
        dep#(y) = (cost# - salv#) * (life% - y + 1) / total
    NEXT y
END SUB

' ------------------------------------------------------------
' ShowSchedule: one table with the yearly expense, the running
' total (accumulated depreciation) and the book value.
' ------------------------------------------------------------
SUB ShowSchedule (title$, cost#, life%, dep#())
    CLS
    PRINT title$
    PRINT USING "Cost $$###,###.##"; cost#
    PRINT
    PRINT "Year   Depreciation   Accumulated    Book value   % of cost"
    PRINT STRING$(60, "-")
    acc# = 0
    FOR y = 1 TO life%
        acc# = acc# + dep#(y)
        PRINT USING " ##     ###,###.##    ###,###.##    ###,###.##     ###.#%"; y; dep#(y); acc#; cost# - acc#; dep#(y) / cost# * 100
    NEXT y
    PRINT STRING$(60, "-")
    PRINT
    PRINT "Press a key..."
    k$ = INPUT$(1)
END SUB
