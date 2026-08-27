' ============================================================
' TITLE:    Price & Discount Calculator
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     percentages, discounts, markup, margin, PRINT USING
' SUMMARY:  Work out sale prices, stacked discounts, markup vs margin and "buy X get Y free" deals.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shops are full of percentage puzzles. Is "20% off, then another
'   10% off" the same as 30% off? (No!) What is the difference
'   between a 50% MARKUP and a 50% MARGIN? Which is cheaper per item:
'   "buy 3 get 1 free" or "25% off"? This little toolbox answers:
'     1. Sale price from a % discount (and a price-tag table)
'     2. Stacked discounts
'     3. Markup vs margin for a shop owner
'     4. Compare multi-buy deals by unit price
'
' HOW TO USE
'   Choose 1-4 from the menu and answer the questions. 5 quits.
'
' CONCEPTS YOU WILL LEARN
'   * Percent as a multiplier: 20% off = multiply by 0.80
'   * Why discounts multiply instead of adding
'   * Markup is based on COST, margin is based on PRICE
'   * PRINT USING with "###%" and "$$" money formats
'
' THINGS TO TRY
'   * Add a "what discount gives this target price?" option
'   * Print a whole price-tag sheet for 10%, 20% ... 70% off
'   * Add sales tax after the discount
' ============================================================

DO
    CLS
    PRINT "PRICE & DISCOUNT TOOLBOX"
    PRINT "------------------------"
    PRINT "1. Sale price (% off)"
    PRINT "2. Stacked discounts (x% then y% off)"
    PRINT "3. Markup vs margin"
    PRINT "4. Compare multi-buy deals"
    PRINT "5. Quit"
    INPUT "Choice"; c
    PRINT
    SELECT CASE c
    CASE 1
        INPUT "Original price $"; p
        INPUT "Discount %"; d
        ' "d% off" means you pay (100 - d)% of the price.
        sale = p * (1 - d / 100)
        PRINT USING "You save $$#,###.## and pay $$#,###.##"; p - sale; sale
        PRINT
        PRINT "Price tag table for this item:"
        FOR pct = 10 TO 70 STEP 10
            PRINT USING "   ##% off  ->  $$#,###.##"; pct; p * (1 - pct / 100)
        NEXT pct
    CASE 2
        INPUT "Price $"; p
        IF p <= 0 THEN p = 100      ' avoid dividing by zero below
        INPUT "First discount %"; d1
        INPUT "Second discount %"; d2
        ' The second discount works on the ALREADY reduced price,
        ' so the multipliers multiply: 0.8 * 0.9 = 0.72 -> 28% off.
        final = p * (1 - d1 / 100) * (1 - d2 / 100)
        realPct = (1 - final / p) * 100
        PRINT USING "Final price: $$#,###.##"; final
        PRINT USING "Total discount: ##.##% (not ###%_!)"; realPct; d1 + d2
    CASE 3
        INPUT "What the item costs you $"; cost
        IF cost <= 0 THEN cost = 10
        INPUT "Percentage to add"; pct
        ' MARKUP: price = cost * (1 + pct)       -> % of COST
        ' MARGIN: price = cost / (1 - pct)       -> % of PRICE
        mkPrice = cost * (1 + pct / 100)
        PRINT USING "With a ###% MARKUP the price is $$#,###.##"; pct; mkPrice
        IF mkPrice > 0 THEN PRINT USING "   ... which is a margin of only ##.#%"; (mkPrice - cost) / mkPrice * 100
        IF pct < 100 THEN
            mgPrice = cost / (1 - pct / 100)
            PRINT USING "With a ###% MARGIN the price is $$#,###.##"; pct; mgPrice
            PRINT USING "   ... which is a markup of ####.#%"; (mgPrice - cost) / cost * 100
        ELSE
            PRINT "A margin of 100% or more is impossible (price would be infinite)."
        END IF
    CASE 4
        INPUT "Normal price of one item $"; p
        IF p <= 0 THEN p = 4
        PRINT
        PRINT "Deal                         Pay for  Get   Price/item  Saving"
        RESTORE Deals
        FOR i = 1 TO 5
            READ deal$, buy, getFree, pctOff
            ' total paid, items received, cost per item
            paid = buy * p * (1 - pctOff / 100)
            items = buy + getFree
            per = paid / items
            PRINT USING "\                         \  ###     ###   $$###.##   ###.#%"; deal$; buy; items; per; (1 - per / p) * 100
        NEXT i
        PRINT
        PRINT "Lower price/item = better deal (if you need that many!)"
    CASE 5
        EXIT DO
    CASE ELSE
        PRINT "Please type 1 to 5."
    END SELECT
    PRINT
    PRINT "Press a key...": k$ = INPUT$(1)
LOOP
END

Deals:
' name, items paid for, free items, percent off
DATA "Buy 1 get 1 free", 1, 1, 0
DATA "Buy 2 get 1 free", 2, 1, 0
DATA "Buy 3 get 1 free", 3, 1, 0
DATA "25% off everything", 1, 0, 25
DATA "Buy 4 get 2 free", 4, 2, 0
