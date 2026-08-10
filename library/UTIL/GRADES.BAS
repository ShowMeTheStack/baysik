' ============================================================
' TITLE:    Grade Book Calculator
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     statistics, arrays, weighted average, sorting, median
' SUMMARY:  A teacher's grade book with weighted averages, letter grades, class statistics and a grade chart.
' ------------------------------------------------------------
' WHAT IT DOES
'   Holds a class of students and their scores (0-100) on four
'   pieces of work, each with a WEIGHT: homework counts 20%,
'   quizzes 20%, project 25%, final exam 35%.  For every student
'   it works out the WEIGHTED AVERAGE:
'
'       average = sum of (score * weight) / sum of weights
'
'   and a letter grade.  The statistics page shows the class
'   mean, median, standard deviation, best and worst, and a bar
'   chart of how many students got each letter.
'
' HOW TO USE
'   V = view grade table         S = statistics and chart
'   A = add a student            E = edit a score
'   W = change the weights       Q / Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Weighted averages (why the final exam "counts more")
'   * 2-D arrays: score(student, assignment)
'   * Median: sort a copy, take the middle (or average two)
'   * Standard deviation: how spread out the marks are
'   * Letter grades with SELECT CASE ranges
'
' THINGS TO TRY
'   * Drop each student's lowest quiz before averaging.
'   * Save the class to a file and load it next time.
'   * "Curve" the grades so the class average becomes 75.
' ============================================================

DECLARE FUNCTION Avg! (s%)
DECLARE FUNCTION Letter$ (a!)

' Plain variables are INTEGERs unless they carry a ! suffix.
' (Avg! wants an INTEGER student number - passing a SINGLE would
' be a "Parameter type mismatch".)
DEFINT A-Z

CONST MAXS = 20, NA = 4
DIM SHARED nm$(1 TO MAXS), score(1 TO MAXS, 1 TO NA), wt(1 TO NA)
DIM SHARED aName$(1 TO NA)
DIM sorted!(1 TO MAXS)

FOR a = 1 TO NA: READ aName$(a), wt(a): NEXT a
DATA Homework,20, Quizzes,20, Project,25, Final,35

' ---- Sample class ----
n = 0
DO
    READ t$
    IF t$ = "*" THEN EXIT DO
    n = n + 1: nm$(n) = t$
    FOR a = 1 TO NA: READ score(n, a): NEXT a
LOOP
DATA Amara,92,88,95,90, Ben,75,68,80,71, Carlos,58,62,70,55
DATA Dana,85,91,78,88, Eli,99,97,100,96, Fatima,66,72,60,69
DATA Gus,81,77,85,79, Hana,45,55,62,50, Ivan,88,84,90,93
DATA *

page$ = "V"
DO
    CLS
    COLOR 15, 2: PRINT SPACE$(80);: LOCATE 1, 33: PRINT "GRADE BOOK": COLOR 7, 0
    IF page$ = "V" THEN
        ' ---- The table ----
        LOCATE 3, 1
        PRINT "  #  Student      ";
        FOR a = 1 TO NA: PRINT USING "\      \ "; aName$(a);: NEXT a
        PRINT " Average  Grade"
        PRINT "                  ";
        FOR a = 1 TO NA: PRINT USING "  (###%) "; wt(a);: NEXT a
        PRINT
        FOR s = 1 TO n
            PRINT USING " ##  \          \ "; s; nm$(s);
            FOR a = 1 TO NA: PRINT USING "   ###   "; score(s, a);: NEXT a
            av! = Avg!(s)
            g$ = Letter$(av!)
            ' colour by grade: A green ... F red
            SELECT CASE LEFT$(g$, 1)
                CASE "A": COLOR 10
                CASE "B": COLOR 11
                CASE "C": COLOR 14
                CASE "D": COLOR 6
                CASE ELSE: COLOR 12
            END SELECT
            PRINT USING "  ###.#    \\"; av!; g$
            COLOR 7
        NEXT s
    ELSE
        ' ---- Statistics ----
        IF n = 0 THEN
            PRINT : PRINT "  No students yet."
        ELSE
            tot! = 0: hi = 1: lo = 1
            FOR s = 1 TO n
                sorted!(s) = Avg!(s)
                tot! = tot! + sorted!(s)
                IF sorted!(s) > Avg!(hi) THEN hi = s
                IF sorted!(s) < Avg!(lo) THEN lo = s
            NEXT s
            mean! = tot! / n
            ' Standard deviation: square root of the average squared
            ' distance from the mean.
            ss! = 0
            FOR s = 1 TO n: ss! = ss! + (sorted!(s) - mean!) ^ 2: NEXT s
            sd! = SQR(ss! / n)
            ' Median: sort, then take the middle value.
            FOR i = 1 TO n - 1
                FOR j = i + 1 TO n
                    IF sorted!(j) < sorted!(i) THEN SWAP sorted!(i), sorted!(j)
                NEXT j
            NEXT i
            IF n MOD 2 = 1 THEN med! = sorted!((n + 1) \ 2) ELSE med! = (sorted!(n \ 2) + sorted!(n \ 2 + 1)) / 2
            LOCATE 3, 4: PRINT USING "Students:       ##"; n
            LOCATE 4, 4: PRINT USING "Class mean:     ###.#"; mean!
            LOCATE 5, 4: PRINT USING "Median:         ###.#"; med!
            LOCATE 6, 4: PRINT USING "Std deviation:  ###.#"; sd!
            LOCATE 7, 4: PRINT USING "Top:            ###.#  &"; Avg!(hi); nm$(hi)
            LOCATE 8, 4: PRINT USING "Lowest:         ###.#  &"; Avg!(lo); nm$(lo)

            ' Bar chart: how many of each letter.
            LOCATE 10, 4: PRINT "Grade spread:"
            letters$ = "ABCDF"
            FOR L = 1 TO 5
                cnt = 0
                FOR s = 1 TO n
                    IF LEFT$(Letter$(Avg!(s)), 1) = MID$(letters$, L, 1) THEN cnt = cnt + 1
                NEXT s
                LOCATE 11 + L, 6: PRINT MID$(letters$, L, 1); " ";
                COLOR 9 + L MOD 6: PRINT STRING$(cnt * 4, 219);: COLOR 7
                PRINT cnt
            NEXT L
        END IF
    END IF

    LOCATE 23, 1
    PRINT " V View  S Stats  A Add student  E Edit score  W Weights  Q Quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "V", "S": page$ = k$
        CASE "A"
            IF n < MAXS THEN
                LOCATE 21, 1: LINE INPUT " Student name: "; t$
                IF LTRIM$(t$) <> "" THEN
                    n = n + 1: nm$(n) = LEFT$(LTRIM$(t$), 12)
                    FOR a = 1 TO NA
                        LOCATE 21, 1: PRINT SPACE$(79);
                        LOCATE 21, 1: PRINT " "; aName$(a);
                        INPUT " score: ", v
                        IF v < 0 THEN v = 0
                        IF v > 100 THEN v = 100
                        score(n, a) = v
                    NEXT a
                END IF
            END IF
        CASE "E"
            LOCATE 21, 1: INPUT " Student number"; s
            IF s >= 1 AND s <= n THEN
                LOCATE 21, 1: PRINT SPACE$(79);
                LOCATE 21, 1: INPUT " Which work (1-4)"; a
                IF a >= 1 AND a <= NA THEN
                    LOCATE 21, 1: PRINT SPACE$(79);
                    ' INPUT's prompt must be a fixed "string", so we PRINT
                    ' the changing part first and end it with ; to stay
                    ' on the same line.
                    LOCATE 21, 1: PRINT " New "; aName$(a); " score for "; nm$(s);
                    INPUT ": ", v
                    IF v >= 0 AND v <= 100 THEN score(s, a) = v
                END IF
            END IF
        CASE "W"
            LOCATE 21, 1: PRINT " Enter 4 weights (they don't have to add up to 100)"
            FOR a = 1 TO NA
                LOCATE 22, 1: PRINT SPACE$(79);
                LOCATE 22, 1: PRINT " "; aName$(a); " weight";
                INPUT ": ", v
                IF v >= 0 THEN wt(a) = v
            NEXT a
            ' all-zero weights would mean dividing by zero later
            IF wt(1) + wt(2) + wt(3) + wt(4) = 0 THEN wt(4) = 100
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END

' Weighted average for student s.
FUNCTION Avg! (s%)
    tot! = 0: w! = 0
    FOR a = 1 TO NA
        tot! = tot! + score(s%, a) * wt(a)
        w! = w! + wt(a)
    NEXT a
    ' Dividing by the total weight means weights like 1,1,2,4
    ' work just as well as percentages.
    IF w! > 0 THEN Avg! = tot! / w!
END FUNCTION

FUNCTION Letter$ (a!)
    SELECT CASE a!
        CASE IS >= 93: Letter$ = "A "
        CASE IS >= 90: Letter$ = "A-"
        CASE IS >= 87: Letter$ = "B+"
        CASE IS >= 83: Letter$ = "B "
        CASE IS >= 80: Letter$ = "B-"
        CASE IS >= 77: Letter$ = "C+"
        CASE IS >= 73: Letter$ = "C "
        CASE IS >= 70: Letter$ = "C-"
        CASE IS >= 60: Letter$ = "D "
        CASE ELSE: Letter$ = "F "
    END SELECT
END FUNCTION
