10 ' ============================================================
20 ' TITLE:    Checkbook Balancer
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Advanced
50 ' TAGS:     files, random access, field, lset, mks$, cvs, menu
60 ' SUMMARY:  A checkbook register kept in a random-access file using FIELD, LSET, MKS$ and CVS.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Keeps your deposits and checks in CHECKBK.DAT, a random
100 '   access file of fixed-size 34-byte records. You can add
110 '   entries, list the register with a running balance, mark
120 '   entries as cleared by the bank, and reconcile against
130 '   your bank statement. Data survives between runs.
140 '
150 ' HOW TO USE
160 '   Pick a menu number. Amounts are in dollars (12.50).
170 '   The first run creates three sample entries for you.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * OPEN "R",#1,"file",length  - GW-BASIC random files
210 '   * FIELD to carve a record buffer into named strings
220 '   * LSET / RSET to put text into field variables
230 '   * MKS$ / CVS to store a single-precision number in
240 '     exactly 4 bytes, and turn it back again
250 '   * LOF(1) / record length = number of records
260 '   * PUT #1,n and GET #1,n to write and read record n
270 '
280 ' THINGS TO TRY
290 '   * Add a "category" field (food, rent...) and a report
300 '   * Add a delete option (hint: mark the record void)
310 '   * Print the register with PRINT USING to a text file
320 ' ============================================================
330 '
1000 KEY OFF: CLS
1010 ' ---- open the data file --------------------------------
1020 ' Record layout (34 bytes):
1030 '   DT$  8 bytes  date as MM/DD/YY
1040 '   DS$ 20 bytes  description
1050 '   AM$  4 bytes  amount, packed by MKS$ (+deposit, -check)
1060 '   CL$  1 byte   "Y" if cleared by the bank, else "N"
1070 '   CK$  1 byte   type: "D" deposit or "C" check
1080 RL = 34
1090 OPEN "R", #1, "CHECKBK.DAT", RL
1100 FIELD #1, 8 AS DT$, 20 AS DS$, 4 AS AM$, 1 AS CL$, 1 AS CK$
1110 ' IMPORTANT: never assign to DT$ etc. with "=" - that would
1120 ' detach them from the buffer. Always use LSET or RSET.
1130 NR = LOF(1) \ RL
1140 IF NR = 0 THEN GOSUB 7000            ' first run: sample data
1150 '
2000 ' ---------- main menu ---------------------------------------
2010 PRINT
2020 COLOR 14: PRINT "CHECKBOOK  -"; NR; "entries": COLOR 7
2030 PRINT "  1  Record a deposit"
2040 PRINT "  2  Write a check"
2050 PRINT "  3  Show the register"
2060 PRINT "  4  Mark an entry cleared"
2070 PRINT "  5  Reconcile with bank statement"
2080 PRINT "  6  Quit"
2090 INPUT "Choice"; C
2100 IF C < 1 OR C > 6 OR C <> INT(C) THEN 2090
2110 ON C GOSUB 3000, 3100, 4000, 5000, 6000, 9000
2120 GOTO 2000
2130 '
3000 ' ---------- deposit -----------------------------------------
3010 T$ = "D": SG = 1: GOTO 3200
3100 ' ---------- check -------------------------------------------
3110 T$ = "C": SG = -1
3200 ' shared code for both: ask the details, then PUT a record
3210 LINE INPUT "Description: "; D$
3220 IF D$ = "" THEN PRINT "Cancelled.": RETURN
3230 INPUT "Amount"; A
3240 IF A <= 0 THEN PRINT "Amount must be positive.": GOTO 3230
3250 GOSUB 8000                          ' build today's date in TD$
3260 LSET DT$ = TD$
3270 LSET DS$ = D$                        ' LSET pads/truncates to 20
3280 LSET AM$ = MKS$(A * SG)             ' 4 packed bytes
3290 LSET CL$ = "N"
3300 LSET CK$ = T$
3310 NR = NR + 1
3320 PUT #1, NR
3330 PRINT "Saved as entry"; NR
3340 RETURN
3350 '
4000 ' ---------- register listing -------------------------------
4010 BL = 0
4020 PRINT
4030 PRINT " #  Date      Description            Amount   Balance  Clr"
4040 PRINT STRING$(62, "-")
4050 FOR I = 1 TO NR
4060   GET #1, I
4070   A = CVS(AM$): BL = BL + A
4080   PRINT USING "##  \      \  \                  \ #####.## ######.##   !"; I; DT$; DS$; A; BL; CL$
4090 NEXT I
4100 PRINT STRING$(62, "-")
4110 PRINT USING "Current balance: $######.##"; BL
4120 RETURN
4130 '
5000 ' ---------- mark cleared --------------------------------------
5010 INPUT "Entry number to mark cleared"; N
5020 IF N < 1 OR N > NR THEN PRINT "No such entry.": RETURN
5030 GET #1, N
5040 LSET CL$ = "Y"
5050 PUT #1, N                            ' write the same record back
5060 PRINT "Entry"; N; "("; DS$; ") marked cleared."
5070 RETURN
5080 '
6000 ' ---------- reconcile ------------------------------------------
6010 ' Your statement balance should equal the sum of all the
6020 ' CLEARED entries. Uncleared ones are "in transit".
6030 INPUT "Ending balance on your bank statement"; SB
6040 CB = 0: UB = 0: UN = 0
6050 FOR I = 1 TO NR
6060   GET #1, I
6070   A = CVS(AM$)
6080   IF CL$ = "Y" THEN CB = CB + A ELSE UB = UB + A: UN = UN + 1
6090 NEXT I
6100 PRINT USING "Cleared total:      $######.##"; CB
6110 PRINT USING "Statement says:     $######.##"; SB
6120 PRINT USING "Not yet cleared: ### entries, $######.##"; UN; UB
6130 ' Compare in cents to avoid tiny floating-point differences.
6140 IF ABS(CB - SB) < .005 THEN COLOR 10: PRINT "Balanced! Your books agree with the bank.": COLOR 7: RETURN
6150 COLOR 12: PRINT USING "Out of balance by $#####.##"; SB - CB: COLOR 7
6160 RETURN
6170 '
7000 ' ---------- create sample entries on first run --------------
7010 PRINT "Creating CHECKBK.DAT with sample entries..."
7020 FOR I = 1 TO 3
7030   READ D$, A, T$, C$, X$
7040   LSET DT$ = D$: LSET DS$ = T$: LSET AM$ = MKS$(A)
7050   LSET CL$ = C$: LSET CK$ = X$
7060   PUT #1, I
7070 NEXT I
7080 NR = 3
7090 RETURN
7100 DATA "01/02/86", 500, "Paycheck", "Y", "D"
7110 DATA "01/05/86", -45.25, "Electric company", "Y", "C"
7120 DATA "01/09/86", -12.99, "Computer magazine", "N", "C"
7130 '
8000 ' ---------- today's date as MM/DD/YY -------------------------
8010 TD$ = LEFT$(DATE$, 2) + "/" + MID$(DATE$, 4, 2) + "/" + RIGHT$(DATE$, 2)
8020 RETURN
8030 '
9000 ' ---------- quit -------------------------------------------
9010 CLOSE #1
9020 PRINT "Register saved in CHECKBK.DAT. Goodbye."
9030 END
