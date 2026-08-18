10 ' ============================================================
20 ' TITLE:    CGA Kaleidoscope
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     graphics, screen 1, symmetry, on timer, random
60 ' SUMMARY:  Endless eight-way symmetric patterns in CGA colours, with ON TIMER flipping the palette.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   A random "pen" wanders around the screen. Every line it
100 '   draws is copied eight times - mirrored left/right, up/down
110 '   and across the diagonals - so the picture always looks
120 '   like the view down a kaleidoscope tube. Every few seconds
130 '   an ON TIMER interrupt switches the CGA palette.
140 '
150 ' HOW TO USE
160 '   Just watch. C clears the screen, Q quits.
170 '
180 ' CONCEPTS YOU WILL LEARN
190 '   * Symmetry: (x,y), (-x,y), (x,-y), (y,x) ... about a centre
200 '   * ON TIMER(n) GOSUB / TIMER ON - an event that fires by
210 '     itself while the main loop keeps drawing
220 '   * LINE with a starting point and the CGA 4 colours
230 '   * The CGA pixel aspect ratio (pixels are taller than wide)
240 '
250 ' THINGS TO TRY
260 '   * Use only four-way symmetry: remove the "swapped" lines
270 '   * Draw CIRCLEs instead of lines
280 '   * Make the timer faster or slower
290 ' ============================================================
300 '
1000 KEY OFF: SCREEN 1: COLOR 0, 1: CLS
1010 RANDOMIZE TIMER
1020 ' Centre of the screen. CGA pixels are about 1.2 times
1030 ' taller than wide, so we stretch x by AR to keep shapes round.
1040 CX = 160: CY = 100: AR = 1.2
1050 X = 0: Y = 0: C = 1: PA = 1
1060 ' ---- install the timer event ---------------------------
1070 ' Every 3 seconds, GW-BASIC interrupts whatever line is
1080 ' running and does GOSUB 5000, then carries on.
1090 ON TIMER(3) GOSUB 5000
1100 TIMER ON
1110 '
2000 ' ---------- main drawing loop ---------------------------
2010 ' Move the pen a small random step, staying inside radius 95.
2020 NX = X + INT(RND * 21) - 10
2030 NY = Y + INT(RND * 21) - 10
2040 IF ABS(NX) > 95 OR ABS(NY) > 95 THEN NX = X / 2: NY = Y / 2
2050 ' Now draw the segment (X,Y)-(NX,NY) in all 8 positions.
2060 ' The next four LINEs are the plain mirror images; the
2070 LINE (CX + X * AR, CY + Y)-(CX + NX * AR, CY + NY), C
2080 LINE (CX - X * AR, CY + Y)-(CX - NX * AR, CY + NY), C
2090 LINE (CX + X * AR, CY - Y)-(CX + NX * AR, CY - NY), C
2100 LINE (CX - X * AR, CY - Y)-(CX - NX * AR, CY - NY), C
2110 ' four after that repeat them with x and y swapped (diagonal).
2120 LINE (CX + Y * AR, CY + X)-(CX + NY * AR, CY + NX), C
2130 LINE (CX - Y * AR, CY + X)-(CX - NY * AR, CY + NX), C
2140 LINE (CX + Y * AR, CY - X)-(CX + NY * AR, CY - NX), C
2150 LINE (CX - Y * AR, CY - X)-(CX - NY * AR, CY - NX), C
2160 X = NX: Y = NY
2170 ' Change pen colour now and then (colours 1, 2, 3).
2180 IF RND < .03 THEN C = INT(RND * 3) + 1
2190 ' Occasionally fade by drawing in black (colour 0).
2200 IF RND < .005 THEN C = 0
2210 K$ = INKEY$
2220 IF K$ = "c" OR K$ = "C" THEN CLS
2230 IF K$ = "q" OR K$ = "Q" THEN 9000
2240 GOTO 2000
2250 '
5000 ' ---------- timer event: flip palette + new background ----
5010 PA = 1 - PA
5020 COLOR INT(RND * 8), PA
5030 RETURN
5040 '
9000 TIMER OFF
9010 SCREEN 0: WIDTH 80: CLS
9020 PRINT "Kaleidoscope closed."
9030 END
