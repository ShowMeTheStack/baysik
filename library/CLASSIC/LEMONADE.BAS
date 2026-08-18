10 ' ============================================================
20 ' TITLE:    Lemonade Stand
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     game, business, simulation, def fn, data
60 ' SUMMARY:  Run a summer lemonade stand for 12 days: buy cups, paint signs, set a price and watch the weather.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Each morning you get a weather report and the cost of
100 '   lemonade. You decide how many cups to make, how many
110 '   advertising signs to paint and what to charge. The program
120 '   works out how many thirsty customers came by and how much
130 '   money you made. Can you double your two dollars?
140 '
150 ' HOW TO USE
160 '   Answer the three questions each day with whole numbers.
170 '   Prices are in cents. Type 0 cups to skip a day.
180 '   Type -1 for the number of cups to quit early.
190 '
200 ' CONCEPTS YOU WILL LEARN
210 '   * DEF FN to define a one-line formula you can reuse
220 '   * Reading a weather table from DATA with RESTORE
230 '   * Validating INPUT and jumping back with IF ... THEN line
240 '   * PRINT USING to show money as $##.##
250 '
260 ' THINGS TO TRY
270 '   * Add a new weather type (a heat wave?) to the DATA table
280 '   * Make signs work better on sunny days
290 '   * Let a "street fair" day appear at random
300 ' ============================================================
310 '
1000 KEY OFF: CLS
1010 RANDOMIZE TIMER
1020 ' Money is kept in cents so that we never get rounding
1030 ' surprises like 1.9999999 dollars.
1040 A = 200: DY = 0
1050 ' ---- DEF FN: demand formula ----------------------------
1060 ' Fewer people buy as the price goes up. With price P in
1070 ' cents, a fair price of about 10c sells roughly 20 cups.
1080 ' The "W" factor comes from the weather table.
1090 DEF FNB(P, W) = INT(W * 250 / (P + 2))
1100 ' Signs help, but each extra sign helps a bit less than the
1110 ' one before: 1 - 1/(S+1) grows 0, .5, .67, .75 ...
1120 DEF FNS(S) = 1 - 1 / (S + 1)
1130 COLOR 14: PRINT "  ~~~ LEMONADE STAND ~~~": COLOR 7
1140 PRINT
1150 PRINT "You have $2.00 and 12 days of summer holiday."
1160 PRINT "Signs cost 15 cents each. Good luck!"
1170 '
2000 ' ---------- a new day ---------------------------------------
2010 DY = DY + 1
2020 IF DY > 12 THEN 5000
2030 ' Pick today's weather: 1 of 4 rows in the DATA table.
2040 ' We RESTORE to the table and READ past the rows we skip.
2050 WX = INT(RND * 4) + 1
2060 RESTORE 9000
2070 FOR I = 1 TO WX: READ W$, WF: NEXT I
2080 ' Cost per cup creeps up as sugar gets dearer.
2090 C = 2: IF DY > 4 THEN C = 3
2100 IF DY > 8 THEN C = 4
2110 PRINT
2120 COLOR 11: PRINT "=== DAY"; DY; "==="; : COLOR 7
2130 PRINT "  Weather: "; W$
2140 PRINT "Lemonade costs"; C; "cents a cup today."
2150 PRINT USING "You have $##.##"; A / 100
2160 '
2200 ' ---------- the three decisions -----------------------------
2210 INPUT "How many cups will you make"; G
2220 IF G = -1 THEN 5000
2230 IF G < 0 OR G <> INT(G) THEN PRINT "Whole numbers please.": GOTO 2210
2240 IF G * C > A THEN PRINT "You can't afford that many.": GOTO 2210
2250 INPUT "How many signs (15c each)"; S
2260 IF S < 0 OR S <> INT(S) THEN 2250
2270 IF G * C + S * 15 > A THEN PRINT "Not enough money for those.": GOTO 2250
2280 INPUT "Price per cup in cents"; P
2290 IF P < 0 OR P > 100 OR P <> INT(P) THEN PRINT "Pick 0 to 100.": GOTO 2280
2300 '
3000 ' ---------- what happened -----------------------------------
3010 ' Customers who would buy = base demand * (1 + sign boost)
3020 N = INT(FNB(P, WF) * (1 + FNS(S)))
3030 ' A thunderstorm can wash out the day completely.
3040 IF WX = 4 AND RND < .5 THEN PRINT "A thunderstorm! Everyone ran home.": N = 0
3050 IF N > G THEN N = G          ' you cannot sell more than you made
3060 E = G * C + S * 15             ' expenses
3070 IN = N * P                     ' income
3080 A = A - E + IN
3090 PRINT
3100 PRINT "You sold"; N; "of"; G; "cups."
3110 PRINT USING "Income $##.##  Expenses $##.##  Profit $###.##"; IN / 100; E / 100; (IN - E) / 100
3120 IF N = G AND G > 0 THEN PRINT "Sold out! You could have made more.": SOUND 1200, 2
3130 IF A < 2 THEN PRINT "You are broke!": GOTO 5000
3140 GOTO 2000
3150 '
5000 ' ---------- end of summer --------------------------------
5010 PRINT
5020 COLOR 14
5030 PRINT USING "Summer is over. You finish with $###.##"; A / 100
5040 COLOR 7
5050 IF A > 400 THEN PRINT "Fantastic - you more than doubled your money!": PLAY "T200 O4 L16 C E G > C": END
5060 IF A > 200 THEN PRINT "Well done, you made a profit.": END
5070 PRINT "Better luck next summer."
5080 END
5090 '
9000 ' ---------- weather table: description, demand factor ----
9010 DATA "Hot and sunny", 1.6
9020 DATA "Warm", 1.1
9030 DATA "Cloudy", .7
9040 DATA "Stormy skies", .4
