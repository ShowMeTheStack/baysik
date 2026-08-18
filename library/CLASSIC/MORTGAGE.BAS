10 ' ============================================================
20 ' TITLE:    Mortgage Table
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     finance, print using, def fn, loops, math
60 ' SUMMARY:  Works out a monthly loan payment and prints a year-by-year amortization table.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Type in how much you borrow, the yearly interest rate and
100 '   how many years you will take to pay. The program computes
110 '   the fixed monthly payment, then walks month by month
120 '   through the loan to show how much of each year's payments
130 '   went to interest and how much paid off the loan itself.
140 '
150 ' HOW TO USE
160 '   Enter amount (e.g. 80000), rate (e.g. 9.5 for 9.5%)
170 '   and term in years (e.g. 30). Enter 0 as the amount to quit.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * The annuity formula  P * r / (1 - (1 + r)^-n)
210 '   * DEF FN for a reusable formula with several inputs
220 '   * PRINT USING with $$, commas and decimal places
230 '   * Rounding to whole cents with INT(x * 100 + .5) / 100
240 '
250 ' THINGS TO TRY
260 '   * Add an extra payment each month and see years vanish
270 '   * Compare 15-year and 30-year loans side by side
280 '   * Print a full month-by-month table, 20 lines per page
290 ' ============================================================
300 '
1000 KEY OFF: CLS
1010 ' DEF FN can take several parameters. P = principal,
1020 ' R = monthly rate (e.g. 0.0075), N = number of months.
1030 DEF FNPAY(P, R, N) = P * R / (1 - (1 + R) ^ (-N))
1040 DEF FNCENT(X) = INT(X * 100 + .5) / 100
1050 '
2000 COLOR 14: PRINT "MORTGAGE TABLE": COLOR 7: PRINT
2010 INPUT "Amount borrowed (0 to quit)"; P
2020 IF P = 0 THEN END
2030 IF P < 0 THEN 2010
2040 INPUT "Yearly interest rate in %"; YR
2050 IF YR <= 0 OR YR > 50 THEN PRINT "Try something like 7.5": GOTO 2040
2060 INPUT "Number of years"; NY
2070 IF NY < 1 OR NY > 40 OR NY <> INT(NY) THEN PRINT "1 to 40 years.": GOTO 2060
2080 R = YR / 100 / 12                   ' monthly rate as a fraction
2090 N = NY * 12
2100 MP = FNCENT(FNPAY(P, R, N))
2110 PRINT
2120 PRINT USING "Monthly payment: $$##,###.##"; MP
2130 PRINT USING "Total paid over ## years: $$###,###.##"; NY; MP * N
2140 PRINT
2150 '
3000 ' ---------- year-by-year table -------------------------------
3010 PRINT "Year   Interest paid   Principal paid    Balance left"
3020 PRINT STRING$(54, "-")
3030 B = P: TI = 0
3040 FOR Y = 1 TO NY
3050   YI = 0: YP = 0
3060   FOR M = 1 TO 12
3070     ' Each month: interest is charged on what you still owe,
3080     ' and the rest of the payment reduces the balance.
3090     I = FNCENT(B * R)
3100     PR = MP - I
3110     IF PR > B THEN PR = B          ' last payment may be smaller
3115     IF Y = NY AND M = 12 THEN PR = B ' final payment sweeps up odd cents
3120     B = B - PR
3130     YI = YI + I: YP = YP + PR
3140   NEXT M
3150   TI = TI + YI
3160   PRINT USING " ##    ###,###.##      ###,###.##      ####,###.##"; Y; YI; YP; B
3170   ' Pause every 15 rows so the table doesn't scroll away.
3180   IF Y MOD 15 = 0 AND Y < NY THEN PRINT "-- press a key --"; : GOSUB 5000: PRINT
3190 NEXT Y
3200 PRINT STRING$(54, "-")
3210 PRINT USING "Total interest: $$###,###.##"; TI
3220 IF TI > P THEN PRINT "(That's more interest than the amount you borrowed!)"
3230 PRINT
3240 GOTO 2000
3250 '
5000 ' wait for a key
5010 IF INKEY$ = "" THEN 5010
5020 RETURN
