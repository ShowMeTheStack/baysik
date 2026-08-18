10 ' ============================================================
20 ' TITLE:    Metric Quiz
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     education, quiz, conversion, data, def fn
60 ' SUMMARY:  Ten questions converting between metric and imperial units, with a 5% "close enough" rule.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   In the early 1980s schools were busy "going metric", and
100 '   computer labs were full of quiz programs like this one.
110 '   It asks you to convert things like 5 miles to kilometres
120 '   or 30 degrees C to Fahrenheit. Answers within 5% count as
130 '   right, and you see the exact answer every time.
140 '
150 ' HOW TO USE
160 '   Type your answer as a number and press Enter.
170 '   Type Q to stop early.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * A table of conversions: unit names and factors in DATA
210 '   * DEF FN to round a value to one decimal place
220 '   * Tolerance checks: ABS(guess - exact) <= 5% of exact
230 '   * Treating temperature as a special case (it has an
240 '     offset as well as a factor)
250 '
260 ' THINGS TO TRY
270 '   * Add more rows to the table (and raise NC)
280 '   * Make the tolerance tighter for an "expert" level
290 '   * Time each answer with TIMER and give speed bonuses
300 ' ============================================================
310 '
1000 KEY OFF: CLS: RANDOMIZE TIMER
1010 NC = 10
1020 DIM A$(NC), B$(NC), FA(NC), LO(NC), HI(NC)
1030 ' Each row: from-unit, to-unit, factor, smallest and biggest
1040 ' starting amount. Factor 0 is our code for "temperature".
1050 FOR I = 1 TO NC: READ A$(I), B$(I), FA(I), LO(I), HI(I): NEXT I
1060 DEF FNR1(X) = INT(X * 10 + .5) / 10
1070 SC = 0: Q = 0
1080 COLOR 14: PRINT "METRIC QUIZ": COLOR 7
1090 PRINT "Answers within 5% are accepted. Type Q to quit."
1100 '
2000 ' ---------- ask a question ------------------------------
2010 Q = Q + 1
2020 IF Q > 10 THEN 3000
2030 K = INT(RND * NC) + 1
2040 ' A random whole amount between LO and HI
2050 X = LO(K) + INT(RND * (HI(K) - LO(K) + 1))
2060 ' Work out the exact answer
2070 IF FA(K) = 0 AND A$(K) = "degrees C" THEN Y = X * 9 / 5 + 32: GOTO 2100
2080 IF FA(K) = 0 THEN Y = (X - 32) * 5 / 9: GOTO 2100
2090 Y = X * FA(K)
2100 Y = FNR1(Y)
2110 PRINT
2120 PRINT "Question"; Q; ":"; X; A$(K); " is how many "; B$(K);
2130 INPUT G$
2140 IF G$ = "q" OR G$ = "Q" THEN Q = Q - 1: GOTO 3000
2150 G = VAL(G$)
2160 IF G$ = "" THEN 2120
2170 ' Allowed error TL is 5% of the answer - but never less than
2180 ' 1 unit, or answers near zero (32 F = 0 C) would be impossible.
2190 TL = ABS(Y) * .05: IF TL < 1 THEN TL = 1
2200 OK = ABS(G - Y) <= TL
2210 IF OK THEN COLOR 10: PRINT "Correct!"; : SC = SC + 1: SOUND 1000, 1 ELSE COLOR 12: PRINT "Not quite."; : SOUND 150, 3
2220 COLOR 7: PRINT " The answer is"; Y; B$(K)
2230 GOTO 2000
2240 '
3000 ' ---------- results ------------------------------------
3010 PRINT
3020 IF Q = 0 THEN PRINT "No questions answered. Bye!": END
3030 PRINT "You scored"; SC; "out of"; Q
3040 P = INT(SC / Q * 100)
3050 IF P = 100 THEN PRINT "Perfect! You think in metric!"
3060 IF P >= 70 AND P < 100 THEN PRINT "Very good."
3070 IF P < 70 THEN PRINT "Tip: 1 inch = 2.54 cm, 1 mile = 1.6 km, 1 kg = 2.2 lb."
3080 END
3090 '
9000 ' from, to, factor, low, high
9010 DATA "miles","kilometres",1.609,2,50
9020 DATA "kilometres","miles",.6214,5,100
9030 DATA "inches","centimetres",2.54,1,36
9040 DATA "feet","metres",.3048,3,100
9050 DATA "pounds","kilograms",.4536,1,200
9060 DATA "kilograms","pounds",2.2046,1,100
9070 DATA "gallons (US)","litres",3.785,1,20
9080 DATA "litres","pints (US)",2.113,1,10
9090 DATA "degrees C","degrees F",0,-10,40
9100 DATA "degrees F","degrees C",0,20,100
