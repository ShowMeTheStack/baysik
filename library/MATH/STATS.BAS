' ============================================================
' TITLE:    Statistics Explorer
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     statistics, mean, median, mode, standard deviation, histogram, sorting
' SUMMARY:  Computes mean, median, mode, range and standard deviation, then draws a histogram.
' ------------------------------------------------------------
' WHAT IT DOES
'   Statistics summarises a pile of numbers:
'     MEAN    the "average": add them all up, divide by how many
'     MEDIAN  the middle value once they are sorted (half are below)
'     MODE    the value that appears most often
'     RANGE   biggest minus smallest
'     STANDARD DEVIATION  how spread out the values are: roughly the
'             typical distance from the mean.
'               variance = average of (value - mean)^2
'               std dev  = SQR(variance)
'   The histogram groups values into bins and shows a bar per bin.
'   You can use the built-in class test scores, roll dice, or type
'   your own numbers.
'
' HOW TO USE
'   1 = test scores,  2 = 500 rolls of two dice,  3 = type numbers
'   (end your list with a blank line).  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Measures of centre and spread
'   * Sorting (insertion sort) as a step to finding the median
'   * Counting frequencies with an array
'   * Drawing a text-mode bar chart with STRING$
'
' THINGS TO TRY
'   * Add one huge value: watch the mean move but the median barely change
'   * Roll three dice instead of two - the histogram gets more "bell" shaped
'   * Add the "sample" standard deviation (divide by n - 1 instead of n)
' ============================================================

DEFDBL A-Z
DEFINT I-K, N
CONST MAXN = 1000
DIM d(1 TO MAXN)
RANDOMIZE TIMER

DO
    CLS
    COLOR 14: PRINT "STATISTICS EXPLORER": COLOR 7
    PRINT "1) Class test scores   2) Roll two dice 500 times   3) Type your own   Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    n = 0
    SELECT CASE k$
        CASE "1"
            RESTORE Scores
            DO
                READ v
                IF v < 0 THEN EXIT DO       ' -1 marks the end of the DATA
                n = n + 1: d(n) = v
            LOOP
        CASE "2"
            FOR i = 1 TO 500
                ' INT(RND * 6) + 1 gives a whole number from 1 to 6.
                n = n + 1: d(n) = INT(RND * 6) + 1 + INT(RND * 6) + 1
            NEXT i
        CASE "3"
            PRINT "Type numbers one per line, blank line to finish:"
            DO
                LINE INPUT "> "; t$
                IF LTRIM$(t$) = "" OR n = MAXN THEN EXIT DO
                n = n + 1: d(n) = VAL(t$)
            LOOP
    END SELECT
    IF n = 0 THEN GOTO Again

    ' ---- Sort (insertion sort: slide each value left into place) ----
    FOR i = 2 TO n
        v = d(i): j = i - 1
        DO WHILE j >= 1
            IF d(j) <= v THEN EXIT DO
            d(j + 1) = d(j): j = j - 1
        LOOP
        d(j + 1) = v
    NEXT i

    ' ---- Mean ----
    sum = 0
    FOR i = 1 TO n: sum = sum + d(i): NEXT i
    mean = sum / n

    ' ---- Median: middle value, or average of the two middle ones ----
    IF n MOD 2 = 1 THEN
        median = d((n + 1) \ 2)
    ELSE
        median = (d(n \ 2) + d(n \ 2 + 1)) / 2
    END IF

    ' ---- Mode: in a sorted list equal values sit together, so we
    '      just measure the longest "run" of equal values. ----
    bestRun = 0: runLen = 0
    FOR i = 1 TO n
        IF i > 1 THEN
            IF d(i) = d(i - 1) THEN runLen = runLen + 1 ELSE runLen = 1
        ELSE
            runLen = 1
        END IF
        IF runLen > bestRun THEN bestRun = runLen: modeV = d(i)
    NEXT i

    ' ---- Standard deviation ----
    ss = 0
    FOR i = 1 TO n: ss = ss + (d(i) - mean) ^ 2: NEXT i
    sd = SQR(ss / n)

    CLS
    COLOR 11: PRINT "Results for"; n; "values": COLOR 7
    PRINT USING "  Mean   ######.###"; mean
    PRINT USING "  Median ######.###"; median
    IF bestRun > 1 THEN
        PRINT USING "  Mode   ######.###   (appears ### times)"; modeV; bestRun
    ELSE
        PRINT "  Mode   none - every value is different"
    END IF
    PRINT USING "  Range  ######.###   (from ####.## to ####.##)"; d(n) - d(1); d(1); d(n)
    PRINT USING "  Std dev######.###"; sd
    PRINT USING "  About 2/3 of values usually lie between ####.## and ####.##"; mean - sd; mean + sd

    ' ---- Histogram: 10 equal bins from min to max ----
    lo = d(1): hi = d(n)
    IF hi = lo THEN hi = lo + 1
    ' Dice totals are whole numbers 2..12: use one bin per total instead.
    IF k$ = "2" THEN nb = 11: lo = 1.5: hi = 12.5 ELSE nb = 10
    REDIM cnt(1 TO nb)
    w = (hi - lo) / nb
    FOR i = 1 TO n
        b = INT((d(i) - lo) / w) + 1
        IF b > nb THEN b = nb               ' the maximum goes in the last bin
        IF b < 1 THEN b = 1
        cnt(b) = cnt(b) + 1
    NEXT i
    big = 0
    FOR b = 1 TO nb: IF cnt(b) > big THEN big = cnt(b)
    NEXT b
    PRINT
    COLOR 14: PRINT "  Histogram": COLOR 7
    FOR b = 1 TO nb
        PRINT USING "  ####.# - ####.# |"; lo + (b - 1) * w; lo + b * w;
        ' Scale bars so the longest is 45 characters.
        COLOR 10: PRINT STRING$(INT(cnt(b) / big * 45 + .5), 219);
        COLOR 7: PRINT cnt(b)
    NEXT b
    PRINT
    PRINT "Press a key...";
    k$ = INPUT$(1)
Again:
LOOP
END

Scores:
DATA 72, 85, 90, 66, 85, 78, 95, 58, 85, 70, 88, 92, 61, 79, 85, 74
DATA 81, 69, 77, 90, 100, 45, 83, 87, 72, 76, 80, 91, 68, 84
DATA -1
