10 ' ============================================================
20 ' TITLE:    CGA Bar Chart
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     graphics, screen 1, cga, chart, data, palette
60 ' SUMMARY:  Draws a labelled bar chart of a year of rainfall in four-colour 320x200 CGA graphics.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Reads twelve monthly rainfall figures from DATA, scales
100 '   them to fit the screen and draws a bar for each month,
110 '   with gridlines, an axis and labels. Press P to flip
120 '   between the two famous CGA palettes.
130 '
140 ' HOW TO USE
150 '   P  switch palette (green/red/brown or cyan/magenta/white)
160 '   B  change background colour
170 '   Q  quit
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * SCREEN 1: 320x200 pixels, 4 colours, 40x25 text
210 '   * COLOR background, palette  - the CGA way to pick colours
220 '   * LINE (x1,y1)-(x2,y2),c,BF to draw solid bars
230 '   * Scaling data: pixels = value * height / maximum
240 '   * Mixing text (LOCATE/PRINT) with graphics
250 '
260 ' THINGS TO TRY
270 '   * Put your own data in the DATA line
280 '   * Draw a line graph instead with LINE -(x,y)
290 '   * Print the value above each bar
300 ' ============================================================
310 '
1000 KEY OFF: SCREEN 1: CLS
1010 PA = 0: BG = 1
1020 ' In SCREEN 1, COLOR b,p sets the background colour b (0-15)
1030 ' and palette p: 0 = green/red/brown, 1 = cyan/magenta/white.
1040 COLOR BG, PA
1050 DIM V(12), M$(12)
1060 MX = 0
1070 FOR I = 1 TO 12
1080   READ M$(I), V(I)
1090   IF V(I) > MX THEN MX = V(I)
1100 NEXT I
1110 DATA J,78, F,62, M,55, A,48, M,40, J,33
1120 DATA J,29, A,35, S,51, O,74, N,92, D,85
1130 '
2000 ' ---------- draw the chart ------------------------------
2010 CLS
2020 LOCATE 1, 9: PRINT "RAINFALL (mm) - YEAR 1986"
2030 ' Chart area: x from 40 to 310, y from 30 (top) to 170 (bottom)
2040 ' Gridlines every 20 mm, using colour 1 and a dotted style.
2050 FOR G = 0 TO 100 STEP 20
2060   Y = 170 - G * 140 / 100
2070   LINE (40, Y)-(310, Y), 1, , &H8888
2080   LOCATE INT(Y / 8) + 1, 2: PRINT USING "###"; G
2090 NEXT G
2100 LINE (40, 30)-(40, 170), 3          ' y axis
2110 LINE (40, 170)-(310, 170), 3        ' x axis
2120 FOR I = 1 TO 12
2130   X = 22 + I * 22                     ' left edge of bar I
2140   H = V(I) * 140 / 100                ' scale mm to pixels
2150   ' wet months (above average 57mm) in colour 2, dry in 1
2160   C = 1: IF V(I) > 57 THEN C = 2
2170   LINE (X, 170 - H)-(X + 14, 169), C, BF
2180   LINE (X, 170 - H)-(X + 14, 169), 3, B   ' outline
2190   ' Text cell column = pixel x / 8 + 1 (each cell is 8 wide)
2200   LOCATE 23, INT((X + 4) / 8) + 1: PRINT M$(I);
2210 NEXT I
2220 LOCATE 25, 3: PRINT "P=palette  B=background  Q=quit";
2230 '
3000 ' ---------- keys ---------------------------------------------
3010 K$ = INKEY$: IF K$ = "" THEN 3010
3020 IF K$ = "p" OR K$ = "P" THEN PA = 1 - PA: COLOR BG, PA
3030 IF K$ = "b" OR K$ = "B" THEN BG = (BG + 1) MOD 16: COLOR BG, PA
3040 IF K$ = "q" OR K$ = "Q" THEN SCREEN 0: WIDTH 80: PRINT "Bye!": END
3050 GOTO 3010
