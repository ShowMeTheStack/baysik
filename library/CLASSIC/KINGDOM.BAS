10 ' ============================================================
20 ' TITLE:    The Baron of Thornwick
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     simulation, strategy, game, on gosub, economy
60 ' SUMMARY:  Rule a small medieval barony for ten years, trading land, feeding peasants and surviving random events.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   An original resource-management game in the tradition of
100 '   the 1970s "kingdom" simulations. Each year your steward
110 '   reports on the harvest. You decide how much land to buy or
120 '   sell, how much grain to feed your people, and how many
130 '   acres to plant. Then fate takes a hand: rats, fairs, wolves
140 '   or bumper crops. Starve too many people and you are thrown
150 '   out of the castle!
160 '
170 ' HOW TO USE
180 '   Answer each question with a whole number. A negative
190 '   number when buying land means "sell". Rules of thumb:
200 '     * every peasant eats 20 bushels a year
210 '     * planting uses 1 bushel of seed per acre
220 '     * each peasant can work at most 10 acres
230 '
240 ' CONCEPTS YOU WILL LEARN
250 '   * The classic turn loop: report, decide, simulate, repeat
260 '   * Input checks with IF ... THEN line number
270 '   * ON n GOSUB to pick one of several random events
280 '   * Keeping running totals for a final score
290 '
300 ' THINGS TO TRY
310 '   * Add a sixth event to the ON ... GOSUB list
320 '   * Let the player build a granary that stops the rats
330 '   * Make the game last 20 years
335 '   * Debug like it's 1983: add TRON before line 4000 and TROFF
336 '     after it to trace exactly which lines the simulation runs
340 ' ============================================================
350 '
1000 KEY OFF: CLS: RANDOMIZE TIMER
1010 DEF FNR(N) = INT(RND * N) + 1
1020 ' Starting state of the barony
1030 YR = 0: PP = 90: GR = 2800: AC = 900: ST = 0: TS = 0: NB = 0
1040 HY = 3: RT = 0: LP = 20
1050 COLOR 14: PRINT "THE BARON OF THORNWICK": COLOR 7
1060 PRINT "Your father has died and left you his barony. Rule well!"
1070 '
2000 ' ---------- the steward's annual report -------------------
2010 YR = YR + 1
2020 PRINT
2030 COLOR 11: PRINT "--- Year"; YR; "of your reign ---": COLOR 7
2040 IF YR > 1 THEN PRINT ST; "people starved and"; NB; "newcomers arrived."
2050 IF YR > 1 THEN PRINT "Each acre yielded"; HY; "bushels."
2060 IF RT > 0 THEN PRINT "Rats ate"; RT; "bushels in the storehouse."
2070 PRINT "Population:"; PP; "  Acres:"; AC; "  Grain:"; GR
2080 IF YR > 10 THEN 8000
2090 LP = 16 + FNR(10)               ' land price this year
2100 PRINT "Land is trading at"; LP; "bushels per acre."
2110 '
3000 ' ---------- decisions ---------------------------------------
3010 INPUT "Acres to buy (negative to sell)"; B
3020 B = INT(B)
3030 IF B * LP > GR THEN PRINT "Think again, my lord - we have only"; GR; "bushels.": GOTO 3010
3040 IF -B > AC THEN PRINT "We own only"; AC; "acres!": GOTO 3010
3050 AC = AC + B: GR = GR - B * LP
3060 INPUT "Bushels to feed the people"; F
3070 F = INT(F)
3080 IF F < 0 OR F > GR THEN PRINT "We have"; GR; "bushels.": GOTO 3060
3090 GR = GR - F
3100 INPUT "Acres to plant"; PL
3110 PL = INT(PL)
3120 IF PL < 0 OR PL > AC THEN PRINT "We own"; AC; "acres.": GOTO 3100
3130 IF PL > GR THEN PRINT "Not enough seed grain.": GOTO 3100
3140 IF PL > PP * 10 THEN PRINT "Only enough peasants for"; PP * 10; "acres.": GOTO 3100
3150 GR = GR - PL
3160 '
4000 ' ---------- the year passes -------------------------------
4010 ' Harvest: 2 to 6 bushels per planted acre.
4020 HY = FNR(5) + 1: GR = GR + PL * HY
4030 ' Rats: sometimes they eat a slice of the store.
4040 RT = 0: IF RND < .35 THEN RT = INT(GR * FNR(3) / 10): GR = GR - RT
4050 ' Feeding: how many people got their 20 bushels?
4060 FD = INT(F / 20): ST = 0
4070 IF FD < PP THEN ST = PP - FD
4080 IF ST > PP * .45 THEN 8500          ' too many starved: revolt
4090 TS = TS + ST: PP = PP - ST
4100 ' Newcomers are attracted by plenty of land and grain.
4110 NB = INT(FNR(5) * (20 * AC + GR) / PP / 100 + 1)
4120 IF ST > 0 THEN NB = 0
4130 PP = PP + NB
4140 ' A random event (1 in 3 chance), chosen by ON ... GOSUB.
4150 IF RND < .33 THEN PRINT: COLOR 13: ON FNR(5) GOSUB 6000, 6100, 6200, 6300, 6400: COLOR 7
4160 IF PP < 1 THEN 8500
4170 GOTO 2000
4180 '
6000 ' ---------- events ---------------------------------------
6010 PRINT "A travelling fair comes to town! Trade brings 300 bushels."
6020 GR = GR + 300: RETURN
6100 PRINT "Wolves raid the outlying farms. 5 families flee."
6110 PP = PP - 5: IF PP < 1 THEN PP = 1
6120 RETURN
6200 PRINT "A plague sweeps the village!"
6210 PP = INT(PP * .8): SOUND 110, 6: RETURN
6300 PRINT "Monks teach better farming. The land is fertile!"
6310 GR = GR + AC: RETURN
6400 PRINT "The King demands a tax of one tenth of your grain."
6410 GR = GR - INT(GR / 10): RETURN
6420 '
8000 ' ---------- end of ten years: judgement ------------------
8010 PRINT
8020 PRINT "In ten years"; TS; "people starved."
8030 A = AC / PP
8040 PRINT "You end with"; INT(A * 10) / 10; "acres per person."
8050 IF TS < 30 AND A > 9 THEN PRINT "A legendary ruler! Minstrels sing your name.": PLAY "T150 O3 L8 C E G > C2": END
8060 IF TS < 100 AND A > 7 THEN PRINT "A fair and steady baron. The people are content.": END
8070 PRINT "The people grumble. Few will mourn the end of your rule."
8080 END
8500 ' ---------- revolt --------------------------------------------
8510 PRINT
8520 COLOR 12
8530 PRINT ST; "people starved in one year! The angry villagers storm"
8540 PRINT "the castle and you flee in the night."
8550 COLOR 7
8560 FOR I = 400 TO 100 STEP -30: SOUND I, 1: NEXT I
8570 END
