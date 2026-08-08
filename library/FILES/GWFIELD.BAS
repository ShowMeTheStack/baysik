10 ' ============================================================
20 ' TITLE:    GW-BASIC Student Grades (FIELD / LSET / RSET)
30 ' CATEGORY: File I/O
40 ' LEVEL:    Intermediate
50 ' TAGS:     files, random, FIELD, LSET, RSET, MKI$, MKS$, CVI, CVS, gw-basic
60 ' SUMMARY:  The classic 1980s way to do random-access files: FIELD buffers, LSET/RSET and MKx$/CVx.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Before QBasic had TYPE records, GW-BASIC programs described a
100 '   record with FIELD: "the first 16 bytes are the name, the next 2
110 '   are an integer, the next 4 a single-precision number". Numbers
120 '   had to be packed into strings with MKI$/MKS$ and unpacked with
130 '   CVI/CVS. This program saves 6 students, then reads them back in
140 '   reverse order (proof of random access!) and computes averages.
150 '
160 ' HOW TO USE
170 '   Run it. Type a record number (1-6) to look one up, 0 to quit.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * OPEN "R", #1, file, reclen  (GW-BASIC OPEN syntax)
210 '   * FIELD #1, width AS var$, ...  maps variables onto the buffer
220 '   * LSET (left-justify) and RSET (right-justify) into a field
230 '   * MKI$ / MKS$ pack numbers;  CVI / CVS unpack them
240 '   * PUT #1, n  and  GET #1, n  with no variable: they use FIELD
250 '
260 ' THINGS TO TRY
270 '   * Add a third test score (another 4-byte field).
280 '   * Use MKD$/CVD (8 bytes) for double-precision scores.
290 ' ============================================================
300 '
310 ' Record layout: 16 name + 4 class + 2 year (integer) + 4 score
320 ' (single) + 4 score2 (single) = 30 bytes.
330 RL = 30
340 CLS
350 OPEN "R", #1, "GRADES.DAT", RL
360 ' FIELD does not copy anything. It makes N$, C$, Y$, S1$, S2$ point
370 ' INTO the file buffer. Never assign to them with "=" - that would
380 ' break the link. Use LSET or RSET instead.
390 FIELD #1, 16 AS N$, 4 AS C$, 2 AS Y$, 4 AS S1$, 4 AS S2$
400 '
410 ' ---- write the records ------------------------------------
420 PRINT "Writing records with LSET/RSET and MKI$/MKS$..."
430 FOR R = 1 TO 6
440   READ NAM$, KL$, YR%, A!, B!
450   LSET N$ = NAM$          ' "Mo" becomes "Mo              "
460   RSET C$ = KL$          ' "7B" becomes "  7B"
470   LSET Y$ = MKI$(YR%)     ' integer -> 2 raw bytes
480   LSET S1$ = MKS$(A!)     ' single  -> 4 raw bytes
490   LSET S2$ = MKS$(B!)
500   PUT #1, R               ' copy the buffer into record R
510 NEXT R
520 PRINT "File size:"; LOF(1); "bytes ="; LOF(1) / RL; "records of"; RL; "bytes"
530 PRINT
540 '
550 ' ---- read them back, last record first ----------------------
560 PRINT "Rec Name             Class Year  Test1  Test2   Avg"
570 PRINT STRING$(52, "-")
580 FOR R = 6 TO 1 STEP -1
590   GET #1, R               ' fills N$, C$... from record R
600   AV! = (CVS(S1$) + CVS(S2$)) / 2
610   TOT! = TOT! + AV!
620   PRINT USING "##  \              \ \  \ #### ###.# ###.# ###.#"; R; N$; C$; CVI(Y$); CVS(S1$); CVS(S2$); AV!
630 NEXT R
640 PRINT STRING$(52, "-")
650 PRINT USING "Class average: ###.##"; TOT! / 6
660 PRINT
670 ' ---- peek at the raw bytes of one record ---------------------
680 GET #1, 1
690 PRINT "Raw bytes of record 1's Year field (MKI$ of"; CVI(Y$); "):";
700 FOR I = 1 TO 2: PRINT ASC(MID$(Y$, I, 1)); : NEXT I
710 PRINT "  (low byte first)"
720 PRINT
730 ' ---- lookup loop --------------------------------------------
740 INPUT "Record to look up (1-6, 0 = quit)"; R
750 IF R = 0 THEN 820
760 IF R < 1 OR R > LOF(1) / RL THEN PRINT "Out of range.": GOTO 740
770 GET #1, R
780 PRINT "  "; RTRIM$(N$); " of class "; LTRIM$(C$); ", year"; CVI(Y$);
790 PRINT "scored"; CVS(S1$); "and"; CVS(S2$)
800 GOTO 740
810 '
820 CLOSE #1
830 PRINT "Done."
840 END
850 '
860 DATA "Mo Salah",    "7B", 2011, 88.5, 92
870 DATA "Lin Wei",     "8A", 2010, 95,   97.5
880 DATA "Priya Patel", "7B", 2011, 72,   81
890 DATA "Tom O'Neil",  "9C", 2009, 64.5, 70
900 DATA "Zara Khan",   "8A", 2010, 99,   100
910 DATA "Ben Okafor",  "9C", 2009, 83,   79.5
