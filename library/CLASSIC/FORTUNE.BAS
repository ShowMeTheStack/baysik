10 ' ============================================================
20 ' TITLE:    Madame Zelda's Crystal Ball
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Beginner
50 ' TAGS:     game, strings, asc, data, color, text art
60 ' SUMMARY:  Ask the swirling crystal ball a yes/no question - the same question always gets the same answer.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Madame Zelda gazes into a glowing ball drawn with text
100 '   block characters. The colours swirl, then she answers.
110 '   The trick: the answer isn't random at all! The program
120 '   adds up the character codes of your question to pick an
130 '   answer, so asking exactly the same thing twice gets the
140 '   same reply - which makes her seem spookily consistent.
150 '
160 ' HOW TO USE
170 '   Type a question and press Enter. A blank line leaves.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * ASC() turns a character into its code number
210 '   * A simple "hash": sum of codes MOD number of answers
220 '   * Reading the Nth item of a DATA list
230 '   * Text-mode art with CHR$(219) and friends
240 '
250 ' THINGS TO TRY
260 '   * Add more answers (change NA too)
270 '   * Make the hash care about letter order: S = S * 3 + code
280 '   * Give Zelda a mood that changes with the time of day
290 ' ============================================================
300 '
1000 KEY OFF: SCREEN 0: WIDTH 80: CLS
1010 NA = 12                              ' number of answers
1020 ' ---- draw the crystal ball once ----------------------
1030 COLOR 13: LOCATE 2, 28: PRINT "MADAME ZELDA SEES ALL"
1040 COLOR 6
1050 LOCATE 13, 33: PRINT CHR$(220); STRING$(12, 223); CHR$(220)
1060 LOCATE 14, 31: PRINT STRING$(18, 219)
1070 '
2000 ' ---------- ask a question ---------------------------------
2010 C = 1: GOSUB 5100                 ' dim the ball (dark blue)
2020 LOCATE 17, 1: PRINT SPACE$(79): LOCATE 18, 1: PRINT SPACE$(79)
2030 LOCATE 20, 1: PRINT SPACE$(79)
2040 LOCATE 17, 5: COLOR 7
2050 LINE INPUT "Your question (blank to leave): "; Q$
2060 IF Q$ = "" THEN 9000
2070 '
3000 ' ---------- the "hash" -------------------------------------
3010 ' Add up the codes of every letter, ignoring case, spaces
3020 ' and punctuation, so "Will I win?" = "will i win".
3030 S = 0
3040 FOR I = 1 TO LEN(Q$)
3050   A = ASC(MID$(Q$, I, 1))
3060   IF A >= 97 AND A <= 122 THEN A = A - 32
3070   IF A >= 65 AND A <= 90 THEN S = S + A
3080 NEXT I
3090 N = S MOD NA + 1
3100 '
4000 ' ---------- swirl, then reveal -----------------------------
4010 FOR F = 1 TO 24
4020   C = (F MOD 6) + 9: GOSUB 5100
4030   SOUND 300 + (F MOD 4) * 120, 1
4040 NEXT F
4050 RESTORE 9500
4060 FOR I = 1 TO N: READ A$: NEXT I
4070 C = 15: GOSUB 5100
4080 COLOR 14
4090 LOCATE 20, 40 - LEN(A$) \ 2: PRINT A$
4100 COLOR 7
4110 LOCATE 22, 30: PRINT "(press any key)"
4120 IF INKEY$ = "" THEN 4120
4130 LOCATE 22, 30: PRINT SPACE$(20)
4140 GOTO 2000
4150 '
5100 ' ---------- paint the ball in colour C ---------------------
5110 ' Rows of different widths make a rough circle.
5120 COLOR C
5130 RESTORE 9400
5140 FOR R = 4 TO 12
5150   READ W
5160   LOCATE R, 40 - W: PRINT STRING$(W * 2, 219)
5170 NEXT R
5180 RETURN
5190 '
9000 COLOR 7: CLS
9010 PRINT "Madame Zelda fades into the mist..."
9020 END
9400 ' half-widths of each row of the ball
9410 DATA 3, 6, 7, 8, 8, 8, 7, 6, 3
9500 ' the answers
9510 DATA "Yes, without a doubt."
9520 DATA "The spirits say NO."
9530 DATA "Ask again after dinner."
9540 DATA "It is written in the stars."
9550 DATA "Very doubtful."
9560 DATA "Only if you tidy your room first."
9570 DATA "The mist is too thick to see."
9580 DATA "Most certainly!"
9590 DATA "Do not count on it."
9600 DATA "A cat will tell you the answer."
9610 DATA "Signs point to yes."
9620 DATA "Zelda says: maybe on a Tuesday."
