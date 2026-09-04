10 ' ============================================================
20 ' TITLE:    Nim - Matchstick Strategy
30 ' CATEGORY: Games
40 ' LEVEL:    Intermediate
50 ' TAGS:     strategy, xor, binary, math, gw-basic, line numbers
60 ' SUMMARY:  Take matches from the rows; whoever takes the last match wins - against a computer that knows the secret.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Four rows of matches (1, 3, 5 and 7).  On your turn take as
100 '  many matches as you like, but only from ONE row.  Whoever takes
110 '  the very last match wins.  The computer plays perfectly using
120 '  the "nim-sum": XOR all the row sizes together.  If the nim-sum
130 '  is 0, the player to move is losing; otherwise there is always a
140 '  move that makes it 0.  You CAN win - but only by learning the trick!
150 '
160 ' HOW TO USE
170 '   Type the row number (1-4), then how many matches to take.
180 '   Row 0 quits.  Choose whether you or the computer goes first.
190 '
200 ' CONCEPTS YOU WILL LEARN
210 '   * Classic GW-BASIC style: line numbers, GOSUB and GOTO
220 '   * The XOR operator and binary numbers
230 '   * A provably perfect strategy (Bouton's theorem, 1901)
240 '   * Checking user input so wrong answers can't crash the game
250 '
260 ' THINGS TO TRY
270 '   * Try "misere" Nim: whoever takes the LAST match LOSES
280 '   * Start with random row sizes
290 '   * Print each row size in binary to see why XOR works
300 ' ============================================================
310 DEFINT A-Z
320 DIM ROW(4)
330 RANDOMIZE TIMER
340 CLS
350 PRINT "N I M  -  take the last match to win"
360 PRINT
370 ' --- set up the rows: 1, 3, 5, 7 ---
380 FOR I = 1 TO 4: ROW(I) = I * 2 - 1: NEXT I
390 INPUT "Do you want to go first (Y/N)"; A$
400 IF UCASE$(LEFT$(A$, 1)) = "N" THEN GOTO 600
410 ' ============ PLAYER'S TURN ============
420 GOSUB 900
430 PRINT
440 INPUT "Take from which row (0 = quit)"; R$
450 R = VAL(R$)
460 IF R = 0 THEN PRINT "Bye!": END
470 IF R < 1 OR R > 4 THEN PRINT "Rows are numbered 1 to 4.": GOTO 440
480 IF ROW(R) = 0 THEN PRINT "That row is empty.": GOTO 440
490 PRINT "How many (1 -"; ROW(R); ")";
500 INPUT N$
510 N = VAL(N$)
520 IF N < 1 OR N > ROW(R) THEN PRINT "You can take 1 to"; ROW(R); "from that row.": GOTO 490
530 ROW(R) = ROW(R) - N
540 SOUND 700, 1
550 GOSUB 1100
560 IF MLEFT = 0 THEN PRINT : PRINT "You took the last match - YOU WIN!": PLAY "MB T180 L8 CEG>C": GOTO 800
570 ' ============ COMPUTER'S TURN ============
600 GOSUB 900
610 PRINT : PRINT "Computer is thinking..."
620 ' nim-sum = XOR of all the rows
630 X = 0
640 FOR I = 1 TO 4: X = X XOR ROW(I): NEXT I
650 IF X = 0 THEN GOTO 720
660 ' a winning move exists: find a row where (row XOR X) < row,
670 ' and shrink that row to (row XOR X).  That makes the nim-sum 0.
680 FOR I = 1 TO 4
690   T = ROW(I) XOR X
700   IF T < ROW(I) THEN R = I: N = ROW(I) - T: GOTO 760
710 NEXT I
720 ' losing position: take one match from a random non-empty row and hope
730 R = INT(RND * 4) + 1
740 IF ROW(R) = 0 THEN GOTO 730
750 N = 1
760 ROW(R) = ROW(R) - N
770 PRINT "The computer takes"; N; "from row"; R: SOUND 400, 1
780 GOSUB 1100
790 IF MLEFT = 0 THEN PRINT : PRINT "The computer took the last match. Computer wins!": GOTO 800
795 GOTO 420
800 PRINT
810 INPUT "Play again (Y/N)"; A$
820 IF UCASE$(LEFT$(A$, 1)) = "Y" THEN GOTO 340
830 END
900 ' ---- subroutine: draw the rows of matches ----
910 PRINT
920 FOR I = 1 TO 4
930   PRINT "Row"; I; ": ";
940   ' each match is a "|" - centre them for a pyramid look
950   PRINT SPACE$(8 - ROW(I));
960   FOR J = 1 TO ROW(I): PRINT "| "; : NEXT J
970   PRINT TAB(32); "("; ROW(I); ")"
980 NEXT I
990 RETURN
1100 ' ---- subroutine: count the matches left (into MLEFT) ----
1110 MLEFT = 0
1120 FOR I = 1 TO 4: MLEFT = MLEFT + ROW(I): NEXT I
1130 RETURN
