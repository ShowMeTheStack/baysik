' ============================================================
' TITLE:    Stock Market Simulator
' CATEGORY: Business & Finance
' LEVEL:    Advanced
' TAGS:     random walk, moving average, simulation, graphics, trading game
' SUMMARY:  A live random-walk stock chart with 10- and 30-day moving averages - buy low, sell high, beat the market!
' ------------------------------------------------------------
' WHAT IT DOES
'   Stock prices are often modelled as a RANDOM WALK: each day the
'   price moves up or down by a random percentage. This program
'   draws such a price day by day as a scrolling chart, together
'   with two MOVING AVERAGES (the average of the last 10 and last
'   30 days). Traders watch for the short average crossing above
'   the long one ("golden cross") as a buy signal and below it
'   ("death cross") as a sell signal - the program marks crosses.
'   You start with $10,000 and can buy and sell shares. After 250
'   trading days (one year) you see whether you beat simply buying
'   on day 1 and holding.
'
' HOW TO USE
'   B = buy as many shares as you can afford
'   S = sell all your shares
'   + / - = speed up / slow down,  Q or Esc = quit early
'
' CONCEPTS YOU WILL LEARN
'   * Random walks: price = price * (1 + drift + volatility * noise)
'   * Approximate bell-curve noise by adding several RND values
'   * Moving averages with a running sum (fast - no re-adding!)
'   * A scrolling chart: redraw from an array each frame
'   * Detecting a "cross" by comparing today's sign with yesterday's
'
' THINGS TO TRY
'   * Make volatility bigger: does buy-and-hold still win?
'   * Program an automatic trader that follows the cross signals
'   * Add a trading fee of $5 per trade
' ============================================================

DECLARE FUNCTION Gauss! ()

CONST DAYS = 250, SHOWN = 100       ' trading days, days on screen
CONST SHORTN = 10, LONGN = 30       ' moving-average lengths
DIM price!(0 TO DAYS), maS!(0 TO DAYS), maL!(0 TO DAYS)

RANDOMIZE TIMER
SCREEN 12

cash! = 10000: shares& = 0: trades = 0
price!(0) = 50
drift! = .0004                      ' tiny average daily rise
vol! = .022                         ' daily volatility, about 2.2%
delay! = .08
sumS! = 0: sumL! = 0

FOR d = 0 TO DAYS
    ' ---- Tomorrow's price: a random % change ------------------------
    IF d > 0 THEN
        chg! = drift! + vol! * Gauss!
        price!(d) = price!(d - 1) * (1 + chg!)
        IF price!(d) < 1 THEN price!(d) = 1
    END IF

    ' ---- Moving averages with a running sum -----------------------
    ' Add today's price; once we have more than N days, subtract the
    ' price that just dropped out of the window. No inner loop needed.
    sumS! = sumS! + price!(d): IF d >= SHORTN THEN sumS! = sumS! - price!(d - SHORTN)
    sumL! = sumL! + price!(d): IF d >= LONGN THEN sumL! = sumL! - price!(d - LONGN)
    IF d >= SHORTN - 1 THEN maS!(d) = sumS! / SHORTN
    IF d >= LONGN - 1 THEN maL!(d) = sumL! / LONGN

    ' ---- Cross signal ---------------------------------------------
    sig$ = ""
    IF d >= LONGN THEN
        ' The sign of (short - long) flips on the day of a cross.
        today = SGN(maS!(d) - maL!(d)): yday = SGN(maS!(d - 1) - maL!(d - 1))
        IF today > 0 AND yday <= 0 THEN sig$ = "GOLDEN CROSS - buy signal"
        IF today < 0 AND yday >= 0 THEN sig$ = "DEATH CROSS - sell signal"
    END IF

    GOSUB DrawChart

    ' ---- Keyboard during the pause -----------------------------------
    t! = TIMER
    DO
        k$ = UCASE$(INKEY$)
        SELECT CASE k$
        CASE "B"
            n& = INT(cash! / price!(d))
            IF n& > 0 THEN shares& = shares& + n&: cash! = cash! - n& * price!(d): trades = trades + 1
        CASE "S"
            IF shares& > 0 THEN cash! = cash! + shares& * price!(d): shares& = 0: trades = trades + 1
        CASE "+": delay! = delay! / 2
        CASE "-": IF delay! < 1 THEN delay! = delay! * 2
        CASE "Q", CHR$(27): EXIT FOR
        END SELECT
        IF k$ <> "" THEN GOSUB Status
    LOOP WHILE TIMER - t! < delay! AND TIMER >= t!
NEXT d
IF d > DAYS THEN d = DAYS

' ---- Final scorecard ------------------------------------------------
worth! = cash! + shares& * price!(d)
hold! = 10000 / price!(0) * price!(d)     ' buy on day 0 and never sell
LOCATE 26, 1: PRINT SPACE$(79);
LOCATE 26, 1
PRINT USING "Day ###  Your portfolio: $$##,###.##   Buy-and-hold: $$##,###.##"; d; worth!; hold!
LOCATE 27, 1: PRINT SPACE$(79); : LOCATE 27, 1
IF worth! > hold! THEN PRINT "You BEAT the market! "; ELSE PRINT "The market beat you this time. ";
PRINT trades; "trades.  Press a key."
DO: LOOP WHILE INKEY$ <> ""
k$ = INPUT$(1)
SCREEN 0
END

' ------------------------------------------------------------
' DrawChart: shows the last SHOWN days. The vertical scale is
' re-computed every frame from the lowest and highest visible
' prices, so the line always fills the chart.
' ------------------------------------------------------------
DrawChart:
    first = d - SHOWN + 1: IF first < 0 THEN first = 0
    lo! = price!(first): hi! = lo!
    FOR i = first TO d
        IF price!(i) < lo! THEN lo! = price!(i)
        IF price!(i) > hi! THEN hi! = price!(i)
    NEXT i
    IF hi! - lo! < 1 THEN hi! = lo! + 1
    ' Pad the range a little so the line doesn't touch the edges.
    pad! = (hi! - lo!) * .1: lo! = lo! - pad!: hi! = hi! + pad!

    ' Draw into a VIEW box with world coords: x = day, y = price.
    VIEW (60, 30)-(630, 380), 0, 8
    WINDOW (first, lo!)-(first + SHOWN - 1, hi!)
    CLS 1                              ' clears only the view
    FOR i = first + 1 TO d
        LINE (i - 1, price!(i - 1))-(i, price!(i)), 15
        IF i >= SHORTN THEN LINE (i - 1, maS!(i - 1))-(i, maS!(i)), 14
        IF i >= LONGN THEN LINE (i - 1, maL!(i - 1))-(i, maL!(i)), 13
    NEXT i
    VIEW: WINDOW
    LOCATE 1, 1: COLOR 15: PRINT "ACME CORP (ACM)   ";
    COLOR 15: PRINT "price  "; : COLOR 14: PRINT "10-day avg  "; : COLOR 13: PRINT "30-day avg"; : COLOR 15
    LOCATE 2, 1: PRINT USING "###.##"; hi!;
    LOCATE 24, 1: PRINT USING "###.##"; lo!;
    LOCATE 25, 1: PRINT SPACE$(79);
    IF sig$ <> "" THEN
        IF LEFT$(sig$, 1) = "G" THEN COLOR 10 ELSE COLOR 12
        LOCATE 25, 10: PRINT sig$;
        COLOR 15
    END IF
    GOSUB Status
RETURN

Status:
    LOCATE 26, 1
    PRINT USING "Day ###  Price $$###.##  Shares ######  Cash $$##,###.##  Worth $$###,###.##"; d; price!(d); shares&; cash!; cash! + shares& * price!(d);
    LOCATE 28, 1: PRINT "B = buy all   S = sell all   +/- speed   Q = quit";
RETURN

' ------------------------------------------------------------
' Gauss: a quick bell-curve random number (mean 0, spread about 1).
' Adding 12 uniform RND values gives a sum with mean 6 and
' standard deviation 1 (the Central Limit Theorem at work!).
' ------------------------------------------------------------
FUNCTION Gauss!
    s! = 0
    FOR i = 1 TO 12: s! = s! + RND: NEXT i
    Gauss! = s! - 6
END FUNCTION
