' ============================================================
' TITLE:    Langford Pairings
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     combinatorics, backtracking, recursion, sequences, parity
' SUMMARY:  Arrange 1,1,2,2,...,n,n so the two k's have exactly k numbers between them - a puzzle a dad spotted watching his son play with blocks.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1958 the Scottish mathematician C. Dudley Langford watched his
'   son stack coloured blocks: two of each colour, with one block
'   between the reds, two between the blues, three between the yellows.
'       2 3 1 2 1 3        <- the n = 3 answer
'   The two 1s have one number between them, the 2s have two, the 3s
'   have three.
'
'   The program searches for such arrangements by backtracking.  It
'   places the BIGGEST pair first (it has the fewest places to go),
'   then the next biggest, and so on, undoing choices that lead to a
'   dead end.  It counts all solutions (each one also works
'   backwards, so the total is halved to ignore mirror images).
'
'   Solutions exist only when n MOD 4 is 0 or 3.  Try n = 5 to see
'   why the search gives up: a clever parity argument proves it.
'
' HOW TO USE
'   Enter n from 1 to 12.  For n up to 8 all solutions are counted;
'   for bigger n we stop after the first.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Backtracking with "most constrained first" ordering
'   * Breaking symmetry to avoid counting mirror images twice
'   * Parity arguments (why some puzzles have NO answer)
'
' THINGS TO TRY
'   * Count solutions for n = 3, 4, 7, 8 and look the numbers up
'     (1, 1, 26, 150).
'   * Change the rule to Skolem sequences (k-1 numbers between).
' ============================================================
DECLARE SUB Place (k AS INTEGER)
DECLARE SUB ShowSeq ()
DEFINT A-Z

CONST MAXN = 12
DIM SHARED n, seq(1 TO 2 * MAXN)   ' 0 = empty slot
DIM SHARED count&, nodes&, firstOnly, best(1 TO 2 * MAXN)

DO
    CLS
    COLOR 14: PRINT "LANGFORD PAIRINGS": COLOR 7
    PRINT
    LINE INPUT "n = 1 to 12 (Q quits): "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    n = VAL(a$)
    IF n >= 1 AND n <= MAXN THEN
        FOR i = 1 TO 2 * n: seq(i) = 0: NEXT
        count& = 0: nodes& = 0
        firstOnly = (n > 8)
        PRINT
        PRINT "Searching..."
        t! = TIMER
        ' For big impossible n the search would grind through millions
        ' of dead ends, so trust the parity proof and skip it.
        ' (For small n we let the search fail, so you can watch it.)
        IF (n MOD 4 = 1 OR n MOD 4 = 2) AND n > 6 THEN
            PRINT "(skipping the long search - maths already says no)"
        ELSE
            Place n
        END IF
        LOCATE CSRLIN - 1, 1: PRINT SPACE$(40)
        IF count& = 0 THEN
            COLOR 12
            PRINT "No Langford pairing exists for n ="; n; "."
            COLOR 7
            PRINT
            PRINT "Why?  Number the slots 1.."; 2 * n; ".  An EVEN k uses one odd and one"
            PRINT "even slot; an ODD k uses two slots of the same kind.  There must be"
            PRINT "as many odd slots as even ones, which only works out when n MOD 4"
            PRINT "is 0 or 3.  Here n MOD 4 ="; n MOD 4; "."
        ELSE
            FOR i = 1 TO 2 * n: seq(i) = best(i): NEXT
            ShowSeq
            PRINT
            IF firstOnly THEN
                PRINT "First solution found (n > 8: counting all would take ages)."
            ELSE
                ' A Langford sequence can never read the same backwards,
                ' so solutions come in mirror pairs: halve the count.
                PRINT "Solutions:"; count& \ 2; "(not counting mirror images)."
            END IF
        END IF
        PRINT "Search steps:"; nodes&;
        PRINT USING "   time: ###.## s"; TIMER - t!
    ELSE
        PRINT "Please type a number from 1 to 12."
    END IF
    PRINT
    LINE INPUT "Press Enter (Q quits) "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

SUB Place (k AS INTEGER)
    ' Put the two copies of k into slots p and p + k + 1.
    IF k = 0 THEN
        ' Every pair is placed: a solution!  (Its mirror image will be
        ' found too - we halve the count at the end.)
        count& = count& + 1
        IF count& = 1 THEN
            FOR i = 1 TO 2 * n: best(i) = seq(i): NEXT
        END IF
        EXIT SUB
    END IF
    IF firstOnly AND count& > 0 THEN EXIT SUB
    FOR p = 1 TO 2 * n - k - 1
        q = p + k + 1
        IF seq(p) = 0 AND seq(q) = 0 THEN
            nodes& = nodes& + 1
            seq(p) = k: seq(q) = k
            Place k - 1
            seq(p) = 0: seq(q) = 0          ' backtrack
        END IF
    NEXT
END SUB

SUB ShowSeq
    ' Print the sequence, then one line per pair with a bracket
    ' joining the two copies so you can count the gap.
    COLOR 15: PRINT "   ";
    FOR i = 1 TO 2 * n: PRINT USING "###"; seq(i); : NEXT
    PRINT
    FOR k = n TO 1 STEP -1
        COLOR 9 + k MOD 6
        a = 0: b = 0
        FOR i = 1 TO 2 * n
            IF seq(i) = k THEN
                IF a = 0 THEN a = i ELSE b = i
            END IF
        NEXT
        PRINT "   ";
        FOR i = 1 TO 2 * n
            IF i = a OR i = b THEN
                PRINT USING "###"; k;
            ELSEIF i > a AND i < b THEN
                PRINT "---";
            ELSE
                PRINT "   ";
            END IF
        NEXT
        PRINT
    NEXT
    COLOR 7
END SUB
