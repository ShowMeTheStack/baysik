' ============================================================
' TITLE:    PRINT USING Sales Report
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     print using, formatting, reports, arrays, data
' SUMMARY:  A neatly aligned quarterly sales report with totals and a bar chart, plus a PRINT USING cheat sheet.
' ------------------------------------------------------------
' WHAT IT DOES
'   PRINT USING is BASIC's built-in number formatter.  It can line
'   up decimal points, add thousands commas and dollar signs, pad
'   strings to a fixed width and much more.  This program:
'     1. prints a sales report for a small (imaginary) shop, with
'        columns for four quarters, row totals, column totals,
'        growth percentages and a little bar chart;
'     2. shows a "cheat sheet" of format strings and what each one
'        prints, so you can find the one you need.
'
' HOW TO USE
'   Press a key to move from the report to the cheat sheet, and a
'   key again to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Numeric fields: #  .  ,  $$  **  **$  +  -  ^^^^
'   * String fields: \  \ (fixed width),  ! (first letter),  & (whole)
'   * _ to print a special character literally
'   * Totals with nested loops over a 2-D array
'
' THINGS TO TRY
'   * Add a fifth product to the DATA.
'   * Show which quarter was the best for each product.
'   * Send the report to a file with OPEN ... FOR OUTPUT and
'     PRINT #1, USING ...
' ============================================================

DEFINT I-K
CONST NP = 6                 ' number of products
DIM prod$(1 TO NP), sales!(1 TO NP, 1 TO 4)
FOR i = 1 TO NP
    READ prod$(i)
    FOR k = 1 TO 4: READ sales!(i, k): NEXT k
NEXT i
'    product              Q1        Q2        Q3        Q4
DATA "Floppy disks",    1250.5,   1310.25,  980.0,    1420.75
DATA "Joysticks",       3400.0,   2890.4,   3105.6,   5120.0
DATA "Modems 14.4k",    8120.99,  9020.0,   10230.5,  12840.0
DATA "BASIC manuals",   410.0,    385.5,    402.25,   615.0
DATA "Sound cards",     6020.0,   5810.75,  6600.0,   9915.5
DATA "Mouse pads",      95.5,     120.0,    88.25,    210.0

SCREEN 0: WIDTH 80, 25
COLOR 7, 1: CLS

' ---- Title ---------------------------------------------------
COLOR 14, 1
PRINT "  BITS & BYTES COMPUTER SHOP                         Annual sales report, 1993"
COLOR 11, 1
PRINT "  "; STRING$(76, 205)

' ---- Column headings ------------------------------------------
' The heading uses the same widths as the data format below.
COLOR 15, 1
PRINT "  Product" + SPACE$(15) + "Q1" + SPACE$(8) + "Q2" + SPACE$(8) + "Q3" + SPACE$(8) + "Q4" + SPACE$(9) + "Year  Grow"
COLOR 11, 1
PRINT "  "; STRING$(76, 196)

' The format string for one row:
'   \            \     product name padded/cut to 14 characters
'   ##,###.##          number with commas, 2 decimals (9 chars)
'   $$###,###.##       floating dollar sign right before the digits
'   +###%              always show the sign, then a literal %
row$ = "  \            \ ##,###.## ##,###.## ##,###.## ##,###.## $$###,###.## +###%"

DIM qTot!(1 TO 4)
grand! = 0
COLOR 7, 1
FOR i = 1 TO NP
    yr! = 0
    FOR k = 1 TO 4
        yr! = yr! + sales!(i, k)
        qTot!(k) = qTot!(k) + sales!(i, k)       ' column totals
    NEXT k
    grand! = grand! + yr!
    ' growth from Q1 to Q4 as a percentage
    g! = (sales!(i, 4) - sales!(i, 1)) / sales!(i, 1) * 100
    PRINT USING row$; prod$(i); sales!(i, 1); sales!(i, 2); sales!(i, 3); sales!(i, 4); yr!; g!
NEXT i

COLOR 11, 1
PRINT "  "; STRING$(76, 196)
COLOR 15, 1
g! = (qTot!(4) - qTot!(1)) / qTot!(1) * 100
PRINT USING row$; "TOTAL"; qTot!(1); qTot!(2); qTot!(3); qTot!(4); grand!; g!
COLOR 11, 1
PRINT "  "; STRING$(76, 205)

' ---- A bar chart of the yearly totals --------------------------
' Scale so the biggest product fills 50 characters.
best! = 0
FOR i = 1 TO NP
    yr! = sales!(i, 1) + sales!(i, 2) + sales!(i, 3) + sales!(i, 4)
    IF yr! > best! THEN best! = yr!
NEXT i
PRINT
FOR i = 1 TO NP
    yr! = sales!(i, 1) + sales!(i, 2) + sales!(i, 3) + sales!(i, 4)
    n = INT(yr! / best! * 50 + .5)
    COLOR 7, 1: PRINT USING "  \          \ "; prod$(i);
    COLOR 10 + i MOD 4, 1: PRINT STRING$(n, 219);
    COLOR 7, 1: PRINT USING " ##.#%"; yr! / grand! * 100
NEXT i
COLOR 14, 1
PRINT : PRINT "  Press any key for the PRINT USING cheat sheet...";
k$ = INPUT$(1)

' ---- Page 2: cheat sheet --------------------------------------
COLOR 7, 0: CLS
COLOR 14: PRINT "  PRINT USING CHEAT SHEET": COLOR 8: PRINT "  "; STRING$(70, 196)
COLOR 15: PRINT "  Format string        Value            Result        Meaning": COLOR 7
DO
    READ f$, v!, note$
    IF f$ = "*" THEN EXIT DO
    COLOR 11: PRINT "  "; f$; TAB(24);
    COLOR 7: PRINT v!; TAB(41);
    COLOR 14: PRINT "["; : PRINT USING f$; v!; : PRINT "]";
    COLOR 8: PRINT TAB(56); note$
LOOP
' String fields need string values, so they are shown separately.
COLOR 11: PRINT "  \  \  (4 wide)"; TAB(24); : COLOR 7: PRINT CHR$(34); "Basically"; CHR$(34); TAB(41);
COLOR 14: PRINT "["; : PRINT USING "\  \"; "Basically"; : PRINT "]"; : COLOR 8: PRINT TAB(56); "fixed width string"
COLOR 11: PRINT "  !"; TAB(24); : COLOR 7: PRINT CHR$(34); "Basically"; CHR$(34); TAB(41);
COLOR 14: PRINT "["; : PRINT USING "!"; "Basically"; : PRINT "]"; : COLOR 8: PRINT TAB(56); "first character only"
COLOR 11: PRINT "  _#Item ##"; TAB(24); : COLOR 7: PRINT 7; TAB(41);
COLOR 14: PRINT "["; : PRINT USING "_#Item ##"; 7; : PRINT "]"; : COLOR 8: PRINT TAB(56); "_ makes # literal"

DATA "###",42,"right-aligned integer"
DATA "###.##",3.14159,"rounds to 2 places"
DATA "##,###,###",1234567,"thousands commas"
DATA "$$####.##",19.5,"floating dollar sign"
DATA "**####.##",19.5,"fill with asterisks"
DATA "**$###.##",19.5,"asterisks + dollar"
DATA "+###",-17,"leading sign"
DATA "###-",-17,"trailing minus"
DATA "##.##^^^^",123456,"scientific notation"
DATA "##",12345,"too big: % warning"
DATA "*",0,"*"

COLOR 10: PRINT : PRINT "  Press any key to quit.";
k$ = INPUT$(1)
COLOR 7, 0: CLS
END
