10 REM CLASSIC.BAS - A GW-BASIC style program with line numbers
20 REM Concepts: GOTO, GOSUB/RETURN, READ/DATA, ON...GOTO, string functions
30 CLS : KEY OFF
40 PRINT "*** STATES AND CAPITALS QUIZ ***"
50 PRINT
60 SCORE = 0 : Q = 0
70 READ STATE$, CAP$
80 IF STATE$ = "END" THEN GOTO 200
90 Q = Q + 1
100 PRINT "What is the capital of "; STATE$;
110 INPUT A$
120 IF UCASE$(LEFT$(A$, 4)) = UCASE$(LEFT$(CAP$, 4)) THEN GOSUB 300 ELSE GOSUB 400
130 GOTO 70
200 PRINT : PRINT "You scored"; SCORE; "out of"; Q
210 R = INT(SCORE / Q * 3) + 1
220 ON R GOTO 230, 240, 250, 250
230 PRINT "Keep studying!" : END
240 PRINT "Not bad!" : END
250 PRINT "Geography genius!" : END
300 SCORE = SCORE + 1 : PRINT "  Correct!" : RETURN
400 PRINT "  Sorry, it's "; CAP$ : RETURN
500 DATA France, Paris, Japan, Tokyo, Kenya, Nairobi
510 DATA Peru, Lima, Canada, Ottawa, END, END
