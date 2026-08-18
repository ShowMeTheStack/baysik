10 ' ============================================================
20 ' TITLE:    Mailing Labels
30 ' CATEGORY: Classic GW-BASIC
40 ' LEVEL:    Intermediate
50 ' TAGS:     files, sequential, write #, on error, sorting
60 ' SUMMARY:  Keep a mailing list in a sequential file and print it as two-across sticky labels sorted by ZIP.
70 ' ------------------------------------------------------------
80 ' WHAT IT DOES
90 '   Every club and small business in 1985 had a program like
100 '   this one. Names and addresses are stored in LABELS.DAT,
110 '   a plain text file of comma-separated fields. You can add
120 '   people, sort the list by ZIP code (the post office gave
130 '   discounts for sorted mail!), and print labels two across.
140 '
150 ' HOW TO USE
160 '   Choose from the menu by number. When adding, leave the
170 '   name blank to stop.
180 '
190 ' CONCEPTS YOU WILL LEARN
200 '   * OPEN "I" / "O" / "A" - the short GW-BASIC file modes
210 '   * WRITE # puts quotes and commas in for you
220 '   * EOF(1) to read until the end of a file
230 '   * ON ERROR GOTO to handle a missing file on the first run
240 '   * A simple bubble sort that swaps whole records
250 '   * Printing side-by-side columns with TAB
260 '
270 ' THINGS TO TRY
280 '   * Sort by last name instead of ZIP
290 '   * Print three labels across
300 '   * Add a search option that finds everyone in one city
310 ' ============================================================
320 '
1000 KEY OFF: CLS
1010 MX = 50
1020 DIM N$(MX), S$(MX), C$(MX), Z$(MX)
1030 GOSUB 5000                         ' load the file (if any)
1040 '
2000 ' ---------- menu -----------------------------------------
2010 PRINT
2020 COLOR 14: PRINT "MAILING LIST -"; NA; "names": COLOR 7
2030 PRINT "1 Add names   2 Print labels   3 Sort by ZIP   4 Quit"
2040 INPUT "Choice"; CH
2050 IF CH < 1 OR CH > 4 OR CH <> INT(CH) THEN 2040
2060 ON CH GOSUB 3000, 4000, 6000, 9000
2070 GOTO 2000
2080 '
3000 ' ---------- add names -----------------------------------
3010 IF NA >= MX THEN PRINT "The list is full.": RETURN
3020 PRINT "(Leave the name blank to finish.)"
3030 LINE INPUT "Name:   "; T$
3040 IF T$ = "" THEN GOSUB 5500: RETURN    ' save and go back
3050 NA = NA + 1: N$(NA) = T$
3060 LINE INPUT "Street: "; S$(NA)
3070 LINE INPUT "City/State: "; C$(NA)
3080 LINE INPUT "ZIP:    "; Z$(NA)
3090 GOTO 3010
3100 '
4000 ' ---------- print labels two across ----------------------
4010 ' Each label is 4 lines tall plus a blank gap. We handle
4020 ' two people (I and I+1) at once so they sit side by side.
4030 CLS
4040 FOR I = 1 TO NA STEP 2
4050   J = I + 1
4060   PRINT CHR$(218); STRING$(34, 196); CHR$(191);
4070   IF J <= NA THEN PRINT TAB(40); CHR$(218); STRING$(34, 196); CHR$(191) ELSE PRINT
4080   PRINT CHR$(179); " "; N$(I); TAB(36); CHR$(179);
4090   IF J <= NA THEN PRINT TAB(40); CHR$(179); " "; N$(J); TAB(75); CHR$(179) ELSE PRINT
4100   PRINT CHR$(179); " "; S$(I); TAB(36); CHR$(179);
4110   IF J <= NA THEN PRINT TAB(40); CHR$(179); " "; S$(J); TAB(75); CHR$(179) ELSE PRINT
4120   PRINT CHR$(179); " "; C$(I); "  "; Z$(I); TAB(36); CHR$(179);
4130   IF J <= NA THEN PRINT TAB(40); CHR$(179); " "; C$(J); "  "; Z$(J); TAB(75); CHR$(179) ELSE PRINT
4140   PRINT CHR$(192); STRING$(34, 196); CHR$(217);
4150   IF J <= NA THEN PRINT TAB(40); CHR$(192); STRING$(34, 196); CHR$(217) ELSE PRINT
4160 NEXT I
4170 RETURN
4180 '
5000 ' ---------- load LABELS.DAT ------------------------------
5010 NA = 0
5020 ' If the file does not exist, OPEN raises error 53 (File not
5030 ' found). ON ERROR sends us to 5900, which makes sample data.
5040 ON ERROR GOTO 5900
5050 OPEN "I", #1, "LABELS.DAT"
5060 ON ERROR GOTO 0                    ' back to normal error handling
5070 WHILE NOT EOF(1) AND NA < MX
5080   NA = NA + 1
5090   INPUT #1, N$(NA), S$(NA), C$(NA), Z$(NA)
5100 WEND
5110 CLOSE #1
5120 RETURN
5500 ' ---------- save LABELS.DAT -----------------------------
5510 OPEN "O", #1, "LABELS.DAT"
5520 FOR I = 1 TO NA
5530   ' WRITE # wraps each string in quotes, so commas inside a
5540   ' field (like "Springfield, IL") are read back correctly.
5550   WRITE #1, N$(I), S$(I), C$(I), Z$(I)
5560 NEXT I
5570 CLOSE #1
5580 PRINT NA; "names saved."
5590 RETURN
5900 ' ---------- error handler: first run ------------------------
5910 IF ERR <> 53 THEN ON ERROR GOTO 0     ' some other problem: stop
5920 PRINT "No LABELS.DAT yet - creating a sample list."
5930 RESTORE 5960
5940 FOR I = 1 TO 4: READ N$(I), S$(I), C$(I), Z$(I): NEXT I
5950 NA = 4: RESUME 5955
5955 ON ERROR GOTO 0: GOSUB 5500: RETURN
5960 DATA "Ada Byron","12 Engine Row","Lovelace, NY","10012"
5970 DATA "Grace Hopper","1 Cobol Court","Arlington, VA","22201"
5980 DATA "Tom Kilburn","Baby Lane 48","Manchester, NH","03101"
5990 DATA "Mary Keller","5 Basic Blvd","Dubuque, IA","52001"
6000 ' ---------- sort by ZIP (bubble sort) --------------------
6010 ' Compare neighbours; if they are out of order swap ALL
6020 ' four fields so the record stays together. Repeat until a
6030 ' whole pass makes no swaps.
6040 SW = 0
6050 FOR I = 1 TO NA - 1
6060   IF Z$(I) <= Z$(I + 1) THEN 6120
6070   SWAP N$(I), N$(I + 1)
6080   SWAP S$(I), S$(I + 1)
6090   SWAP C$(I), C$(I + 1)
6100   SWAP Z$(I), Z$(I + 1)
6110   SW = 1
6120 NEXT I
6130 IF SW THEN 6040
6140 PRINT "Sorted by ZIP code."
6150 GOSUB 5500
6160 RETURN
9000 ' ---------- quit -------------------------------------------
9010 PRINT "Goodbye."
9020 END
