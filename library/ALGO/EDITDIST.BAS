' ============================================================
' TITLE:    Edit Distance Spell Checker
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     dynamic programming, strings, levenshtein, spelling
' SUMMARY:  Levenshtein distance counts the fewest typing fixes between two words; use it to explain edits and suggest spellings.
' ------------------------------------------------------------
' WHAT IT DOES
'   Mode 1: type two words.  The program computes their EDIT DISTANCE
'   - the smallest number of single-letter insertions, deletions and
'   substitutions that turn the first word into the second - prints
'   the DP table and lists the exact edits, e.g.
'       KITTEN -> SITTEN (substitute K with S) -> ...
'   Mode 2: a mini spell checker.  Type a word; it is compared with
'   every word in a small dictionary and the closest ones are offered
'   as "Did you mean...?" suggestions.
'
' HOW TO USE
'   Choose 1 or 2 from the menu, Q to quit.  Enter an empty word to
'   return to the menu.
'
' CONCEPTS YOU WILL LEARN
'   * The Levenshtein recurrence (min of three neighbours + cost)
'   * Base cases: turning a word into "" takes len deletions
'   * Tracing back through a DP table to list operations
'   * O(m * n) time; a FUNCTION that returns a number
'
' THINGS TO TRY
'   * Make swapping two neighbouring letters cost 1 (Damerau distance)
'   * Make substitutions cost 2 and see how the answers change
' ============================================================
DECLARE FUNCTION Lev% (a$, b$)
DEFINT A-Z
DIM SHARED D(0 TO 20, 0 TO 20)      ' the DP table (words up to 20 letters)

DO
    COLOR 7, 0: CLS
    COLOR 15: PRINT "EDIT DISTANCE (LEVENSHTEIN)": COLOR 7
    PRINT
    PRINT "  1 - Explain the edits between two words"
    PRINT "  2 - Spell checker: did you mean...?"
    PRINT "  Q - Quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO

    IF k$ = "1" THEN
        DO
            PRINT
            LINE INPUT "From word (Enter = menu): "; a$
            IF a$ = "" THEN EXIT DO
            LINE INPUT "To word:                  "; b$
            a$ = UCASE$(LEFT$(a$, 20)): b$ = UCASE$(LEFT$(b$, 20))
            m = LEN(a$): n = LEN(b$)
            dist = Lev(a$, b$)

            ' -- show the table (row = letter of a$, column = of b$) --
            IF n <= 18 THEN
                PRINT "        ";
                FOR j = 1 TO n: PRINT "  "; MID$(b$, j, 1); : NEXT
                PRINT
                FOR i = 0 TO m
                    IF i = 0 THEN PRINT "     "; ELSE PRINT "   "; MID$(a$, i, 1); " ";
                    FOR j = 0 TO n: PRINT USING "###"; D(i, j); : NEXT
                    PRINT
                NEXT
            END IF
            COLOR 14: PRINT "Edit distance ="; dist: COLOR 7

            ' -- trace back from D(m, n) to D(0, 0) -----------------
            ' At each cell, find which neighbour it came from:
            '   diagonal, same letter      -> keep (free)
            '   diagonal + 1               -> substitute
            '   up + 1                     -> delete a$'s letter
            '   left + 1                   -> insert b$'s letter
            ' We record the steps backwards, then print them forwards.
            REDIM op$(1 TO m + n)
            cnt = 0: i = m: j = n
            DO WHILE i > 0 OR j > 0
                cnt = cnt + 1
                IF i > 0 AND j > 0 THEN
                    IF MID$(a$, i, 1) = MID$(b$, j, 1) AND D(i, j) = D(i - 1, j - 1) THEN
                        op$(cnt) = "K" + MID$(a$, i, 1) + CHR$(i): i = i - 1: j = j - 1
                        GOTO Traced
                    END IF
                    IF D(i, j) = D(i - 1, j - 1) + 1 THEN
                        op$(cnt) = "S" + MID$(b$, j, 1) + CHR$(i): i = i - 1: j = j - 1
                        GOTO Traced
                    END IF
                END IF
                IF i > 0 THEN
                    IF D(i, j) = D(i - 1, j) + 1 THEN
                        op$(cnt) = "D" + MID$(a$, i, 1) + CHR$(i): i = i - 1
                        GOTO Traced
                    END IF
                END IF
                op$(cnt) = "I" + MID$(b$, j, 1) + CHR$(i): j = j - 1
Traced:
            LOOP
            ' Replay the operations on a working copy so we can show
            ' the word changing.  Positions shift as letters are inserted
            ' or deleted, so we track an offset.
            w$ = a$: shift = 0
            PRINT "  "; w$
            FOR s = cnt TO 1 STEP -1
                t$ = LEFT$(op$(s), 1): c$ = MID$(op$(s), 2, 1)
                p = ASC(MID$(op$(s), 3, 1)) + shift      ' position in w$
                SELECT CASE t$
                    CASE "S"
                        old$ = MID$(w$, p, 1)
                        MID$(w$, p, 1) = c$
                        PRINT "  "; w$; "   substitute "; old$; " -> "; c$
                    CASE "D"
                        w$ = LEFT$(w$, p - 1) + MID$(w$, p + 1)
                        shift = shift - 1
                        PRINT "  "; w$; "   delete "; c$
                    CASE "I"
                        w$ = LEFT$(w$, p) + c$ + MID$(w$, p + 1)
                        shift = shift + 1
                        PRINT "  "; w$; "   insert "; c$
                END SELECT
            NEXT
        LOOP
    ELSEIF k$ = "2" THEN
        ' The dictionary lives in DATA statements.  "*" marks the end.
        DO
            PRINT
            LINE INPUT "Word to check (Enter = menu): "; w$
            IF w$ = "" THEN EXIT DO
            w$ = UCASE$(LEFT$(w$, 20))
            RESTORE Dictionary
            best = 99: sugg$ = ""
            DO
                READ dw$
                IF dw$ = "*" THEN EXIT DO
                d1 = Lev(w$, dw$)
                IF d1 < best THEN
                    best = d1: sugg$ = dw$: ties = 1  ' a new best
                ELSEIF d1 = best AND ties < 4 THEN
                    sugg$ = sugg$ + ", " + dw$      ' a tie (list up to 4)
                    ties = ties + 1
                END IF
            LOOP
            IF best = 0 THEN
                COLOR 10: PRINT w$; " is spelled correctly."
            ELSEIF best <= 2 THEN
                COLOR 14: PRINT "Did you mean: "; sugg$; " ?  (distance"; best; ")"
            ELSE
                COLOR 12: PRINT "No close match. Nearest: "; sugg$; " (distance"; best; ")"
            END IF
            COLOR 7
        LOOP
    END IF
LOOP
CLS
END

Dictionary:
DATA ALGORITHM,ARRAY,BINARY,BASIC,COMPUTER,DISTANCE,EDIT,FUNCTION
DATA GRAPH,HEAP,INTEGER,KEYBOARD,LETTER,MEMORY,NUMBER,PROGRAM
DATA QUEUE,RECURSION,SEARCH,SORTING,STACK,STRING,TABLE,VARIABLE
DATA WORD,SPELLING,DICTIONARY,KITTEN,SITTING,PYTHON,SCREEN,PIXEL
DATA *

' --------------------------------------------------------------
' Lev fills D() and returns the edit distance from a$ to b$.
'   D(i, j) = distance from the first i letters of a$ to the first
'             j letters of b$.
'   D(i, 0) = i   (delete all i letters)
'   D(0, j) = j   (insert all j letters)
'   D(i, j) = minimum of
'       D(i-1, j)   + 1        delete a$'s i-th letter
'       D(i, j-1)   + 1        insert b$'s j-th letter
'       D(i-1, j-1) + cost     keep (cost 0) or substitute (cost 1)
' Every cell is computed once from 3 neighbours: O(m * n).
' --------------------------------------------------------------
FUNCTION Lev (a$, b$)
    m = LEN(a$): n = LEN(b$)
    FOR i = 0 TO m: D(i, 0) = i: NEXT
    FOR j = 0 TO n: D(0, j) = j: NEXT
    FOR i = 1 TO m
        FOR j = 1 TO n
            IF MID$(a$, i, 1) = MID$(b$, j, 1) THEN cost = 0 ELSE cost = 1
            v = D(i - 1, j) + 1
            IF D(i, j - 1) + 1 < v THEN v = D(i, j - 1) + 1
            IF D(i - 1, j - 1) + cost < v THEN v = D(i - 1, j - 1) + cost
            D(i, j) = v
        NEXT
    NEXT
    Lev = D(m, n)
END FUNCTION
