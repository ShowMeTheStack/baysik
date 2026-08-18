10 ' ============================================================
20 ' TITLE:    Biorhythm Chart
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     dates, trigonometry, sin, charts, date$
60 ' SUMMARY:  Prints a 3-week biorhythm chart from your birthday - the most 1980s computer printout of all.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Biorhythms were a huge fad in the 1970s and 80s: the idea
100 '   that your body, mood and mind follow sine waves of 23, 28
110 '   and 33 days starting the day you were born. (There is no
120 '   scientific evidence for it - but the maths is real!)
130 '   This program counts the days you have been alive and
140 '   plots the three waves sideways down the screen.
150 '
160 ' HOW TO USE
170 '   Enter your birth month, day and year. The chart starts
180 '   today (read from DATE$).  P = physical (23 days),
190 '   E = emotional (28), I = intellectual (33). Left of the
200 '   centre line is "low", right is "high". * = overlap.
210 '
220 ' CONCEPTS YOU WILL LEARN
230 '   * Turning a calendar date into a day number
240 '   * SIN() and the constant 2*pi for repeating cycles
250 '   * Building a line of text with the MID$ statement
260 '   * Reading DATE$ with VAL and MID$
270 '   * Month-length tables in DATA, with leap years
280 '
290 ' THINGS TO TRY
300 '   * Add a fourth cycle (the "intuition" cycle is 38 days)
310 '   * Let the user choose a start date other than today
320 '   * Mark "critical days" where a wave crosses zero
330 ' ============================================================
340 '
1000 KEY OFF: CLS
1010 PI = 3.141593
1020 DIM ML(12)
1030 FOR I = 1 TO 12: READ ML(I): NEXT I
1040 DATA 31,28,31,30,31,30,31,31,30,31,30,31
1050 COLOR 14: PRINT "BIORHYTHM CHART": COLOR 7: PRINT
1060 INPUT "Birth month (1-12)"; BM
1070 IF BM < 1 OR BM > 12 OR BM <> INT(BM) THEN 1060
1080 INPUT "Birth day   (1-31)"; BD
1090 IF BD < 1 OR BD > 31 OR BD <> INT(BD) THEN 1080
1100 INPUT "Birth year  (e.g. 1985)"; BY
1110 IF BY < 1800 OR BY > 2200 OR BY <> INT(BY) THEN PRINT "Four digits, please.": GOTO 1100
1120 ' Today's date: DATE$ looks like "10-15-1986".
1130 TM = VAL(LEFT$(DATE$, 2)): TD = VAL(MID$(DATE$, 4, 2)): TY = VAL(RIGHT$(DATE$, 4))
1140 M = BM: D = BD: Y = BY: GOSUB 5000: J1 = JD
1150 M = TM: D = TD: Y = TY: GOSUB 5000: J2 = JD
1160 N = J2 - J1
1170 IF N < 0 THEN PRINT "You haven't been born yet!": END
1180 CLS
1190 PRINT "Born"; BM; "/"; BD; "/"; BY; " - you are"; N; "days old today."
1200 PRINT "Date        low"; TAB(33); "|"; TAB(52); "high"
1210 '
2000 ' ---------- one line per day for three weeks ------------
2010 M = TM: D = TD: Y = TY
2020 FOR K = 0 TO 20
2030   L$ = STRING$(41, " ")
2040   MID$(L$, 21, 1) = "|"              ' centre line = zero
2050   ' For each cycle length C: value = SIN(2*pi*days/C),
2060   ' which swings between -1 and +1. Scale to -20..+20.
2070   RESTORE 2200
2080   FOR W = 1 TO 3
2090     READ C, C$
2100     V = SIN(2 * PI * (N + K) / C)
2110     X = 21 + INT(V * 20 + .5)
2120     IF MID$(L$, X, 1) = "P" OR MID$(L$, X, 1) = "E" THEN C$ = "*"
2130     MID$(L$, X, 1) = C$
2140   NEXT W
2150   IF K = 0 THEN COLOR 15 ELSE COLOR 7
2160   PRINT USING "##/##/####  "; M; D; Y;
2170   PRINT L$
2180   GOSUB 6000                         ' advance M/D/Y by a day
2190 NEXT K
2200 DATA 23,P, 28,E, 33,I
2210 COLOR 7
2220 PRINT "P=physical  E=emotional  I=intellectual  *=overlap";
2230 END
2240 '
5000 ' ---------- day number of M/D/Y -> JD --------------------
5010 ' This is the standard "Julian Day Number" formula. Shifting
5020 ' the year to start in March puts the awkward leap day at
5030 ' the END of the year, which makes the arithmetic tidy.
5040 A = INT((14 - M) / 12)
5050 YY = Y + 4800 - A
5060 MM = M + 12 * A - 3
5070 JD = D + INT((153 * MM + 2) / 5) + 365 * YY + INT(YY / 4) - INT(YY / 100) + INT(YY / 400) - 32045
5080 RETURN
5090 '
6000 ' ---------- add one day to M/D/Y ---------------------------
6010 ' Leap year rule: divisible by 4, except centuries, except
6020 ' every 400 years (so 2000 was a leap year, 1900 wasn't).
6030 LY = 0
6040 IF Y MOD 4 = 0 AND (Y MOD 100 <> 0 OR Y MOD 400 = 0) THEN LY = 1
6050 MX = ML(M): IF M = 2 THEN MX = MX + LY
6060 D = D + 1
6070 IF D <= MX THEN RETURN
6080 D = 1: M = M + 1
6090 IF M > 12 THEN M = 1: Y = Y + 1
6100 RETURN
