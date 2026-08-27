' ============================================================
' TITLE:    Lemonade Stand Tycoon
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     game, simulation, supply and demand, RND, inventory, profit
' SUMMARY:  Run a lemonade stand for two weeks: watch the weather, buy supplies, set your price and try to get rich.
' ------------------------------------------------------------
' WHAT IT DOES
'   A tribute to the classic 1970s game. Every morning you see the
'   weather forecast, then decide:
'     * how many cups of lemonade to make (each cup costs money)
'     * how many advertising signs to put up
'     * what price to charge
'   How many people buy depends on the weather (hot = thirsty!),
'   your price (too expensive = fewer customers) and your signs.
'   Leftover lemonade goes sour overnight and is thrown away, so
'   making too much wastes money, and making too little loses sales.
'   After 14 days you see your total profit and a daily report.
'
' HOW TO USE
'   Each day answer three questions with numbers. Press Enter to
'   repeat yesterday's choices. Type Q at the cups question to
'   retire early.
'
' CONCEPTS YOU WILL LEARN
'   * Supply and demand: price up -> customers down
'   * Revenue - costs = profit, and the risk of unsold stock
'   * Random events with RND, and a simple demand formula
'   * Keeping a history in arrays for a final report
'
' THINGS TO TRY
'   * Add a "street works" event that halves customers for a day
'   * Make the cost per cup rise after day 7 (inflation!)
'   * Find the best price for a hot day by experimenting
' ============================================================

CONST DAYS = 14
DIM dayProfit(1 TO DAYS), daySold(1 TO DAYS), dayWeather$(1 TO DAYS)
DIM wName$(1 TO 4), wFactor(1 TO 4)
' weather names and how thirsty people are in that weather
wName$(1) = "Rainy": wFactor(1) = .3
wName$(2) = "Cloudy": wFactor(2) = .7
wName$(3) = "Sunny": wFactor(3) = 1.1
wName$(4) = "Hot & dry": wFactor(4) = 1.7

RANDOMIZE TIMER
cash = 5.00                       ' you start with $5 of pocket money
cups = 20: signs = 1: price = .50  ' defaults for the first day
playedDays = 0

CLS
PRINT "========================================"
PRINT "        LEMONADE STAND TYCOON"
PRINT "========================================"
PRINT "You have $5.00. Make lemonade, sell it, get rich!"
PRINT "Press a key to open the stand..."
k$ = INPUT$(1)

FOR d = 1 TO DAYS
    ' ---- Weather: hotter days are more likely in the middle ----
    w = 1 + INT(RND * 4)
    IF RND < .3 THEN w = 3        ' a bit of extra sunshine
    ' Cost of one cup goes up a little on later days.
    IF d <= 5 THEN cupCost = .02 ELSE IF d <= 10 THEN cupCost = .04 ELSE cupCost = .05
    signCost = .15

    CLS
    PRINT USING "DAY ##                       Cash: $$##.##"; d; cash
    PRINT "Forecast: "; wName$(w)
    PRINT USING "Lemonade costs $.## a cup to make, signs cost $.## each."; cupCost; signCost
    PRINT

    ' ---- Decisions (Enter = same as yesterday) ---------------------
    maxCups = INT(cash / cupCost)
    PRINT USING "Cups to make (you can afford ###) [###]"; maxCups; cups;
    LINE INPUT "? "; t$
    IF UCASE$(LEFT$(t$, 1)) = "Q" THEN EXIT FOR
    IF t$ <> "" THEN cups = INT(VAL(t$))
    IF cups < 0 THEN cups = 0
    IF cups > maxCups THEN cups = maxCups: PRINT "  (only"; cups; "- that's all you can afford)"

    remain = cash - cups * cupCost
    PRINT USING "Signs (15 cents each) [##]"; signs;
    LINE INPUT "? "; t$
    IF t$ <> "" THEN signs = INT(VAL(t$))
    IF signs < 0 THEN signs = 0
    IF signs * signCost > remain THEN signs = INT(remain / signCost): PRINT "  (only"; signs; "signs affordable)"

    PRINT USING "Price per cup in cents [###]"; price * 100;
    LINE INPUT "? "; t$
    IF t$ <> "" THEN price = INT(VAL(t$)) / 100
    IF price < .01 THEN price = .01
    IF price > 5 THEN price = 5

    ' ---- The day's business ----------------------------------------
    ' Demand model:
    '   base customers depend on weather,
    '   price: each extra 10 cents above 25 cents scares people off,
    '   signs: each sign brings more people, but with diminishing
    '          returns (1 - 0.5^signs approaches 1).
    expense = cups * cupCost + signs * signCost
    cash = cash - expense
    baseCust = 30 * wFactor(w)
    IF price <= .25 THEN
        priceEffect = 1 + (.25 - price) * 2          ' cheap: a few more buyers
    ELSE
        priceEffect = 1 / (1 + ((price - .25) * 4) ^ 2)   ' expensive: drops fast
    END IF
    signEffect = 1 + 1.5 * (1 - .5 ^ signs)
    demand = INT(baseCust * priceEffect * signEffect * (.8 + RND * .4))
    ' A surprise event now and then.
    ev$ = ""
    IF RND < .1 THEN
        IF w <= 2 THEN ev$ = "A football team jogged past - they were thirsty!": demand = demand + 25
    END IF
    IF RND < .07 AND w >= 3 THEN ev$ = "A thunderstorm in the afternoon sent everyone home!": demand = demand \ 3

    sold = demand
    IF sold > cups THEN sold = cups
    income = sold * price
    cash = cash + income
    profit = income - expense
    dayProfit(d) = profit: daySold(d) = sold: dayWeather$(d) = wName$(w)
    playedDays = d

    ' ---- Report ----------------------------------------------------
    PRINT
    IF ev$ <> "" THEN COLOR 14: PRINT ev$: COLOR 7
    PRINT USING "### people wanted lemonade. You sold ### of ### cups."; demand; sold; cups
    IF cups > sold THEN PRINT USING "### cups went sour and were poured away."; cups - sold
    IF demand > cups THEN PRINT USING "You ran out_! ### thirsty people went home."; demand - cups
    PRINT USING "Income   $$##.##"; income
    PRINT USING "Expenses $$##.##"; expense
    IF profit >= 0 THEN COLOR 10 ELSE COLOR 12
    PRINT USING "PROFIT   $$##.##-"; profit
    COLOR 7
    PRINT USING "Cash now $$##.##"; cash
    IF cash < .02 THEN PRINT "You're broke! The stand has to close.": EXIT FOR
    PRINT : PRINT "Press a key for tomorrow..."
    k$ = INPUT$(1)
NEXT d

' ---- Final report -------------------------------------------------
CLS
PRINT "FINAL REPORT"
PRINT "Day  Weather      Sold    Profit"
PRINT STRING$(34, "-")
tot = 0: totSold = 0
FOR i = 1 TO playedDays
    PRINT USING " ##  \         \  ###   $$##.##-"; i; dayWeather$(i); daySold(i); dayProfit(i)
    tot = tot + dayProfit(i): totSold = totSold + daySold(i)
NEXT i
PRINT STRING$(34, "-")
PRINT USING "Total cups sold: #####"; totSold
PRINT USING "Total profit:    $$###.##-"; tot
PRINT USING "Final cash:      $$###.##"; cash
IF cash >= 50 THEN
    PRINT "LEMONADE MOGUL! You could open a second stand."
ELSEIF cash > 5 THEN
    PRINT "Nice work - you made money!"
ELSE
    PRINT "Business is hard. Try different prices next time!"
END IF
END
