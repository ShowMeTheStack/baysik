' ============================================================
' TITLE:    Cryptarithm Solver (SEND + MORE = MONEY)
' CATEGORY: Puzzles & Logic
' LEVEL:    Advanced
' TAGS:     cryptarithm, backtracking, pruning, strings, arithmetic
' SUMMARY:  Cracks letter-arithmetic puzzles like SEND+MORE=MONEY by guessing digits column by column.
' ------------------------------------------------------------
' WHAT IT DOES
'   In a cryptarithm every letter stands for a different digit, and
'   the sum must be correct.  Words may not start with 0.
'
'         S E N D
'       + M O R E
'       ---------
'       M O N E Y        answer: 9567 + 1085 = 10652
'
'   Trying every assignment of 8 letters to 10 digits means 1,814,400
'   cases - far too many for BASIC.  Instead we assign letters in the
'   order they appear from the RIGHTMOST column, and as soon as a whole
'   column is decided we check its sum (with carries).  A wrong guess
'   is thrown away immediately along with everything that depends on
'   it.  This "pruning" makes the search thousands of times faster.
'
' HOW TO USE
'   Pick a built-in puzzle or type your own as  WORD+WORD=WORD  (two
'   or more words to add, letters only, at most 10 different letters).
'   All solutions are listed.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Parsing a string into parts with INSTR and MID$
'   * Recursive backtracking over digit assignments
'   * Pruning: test partial answers early
'   * Column addition with carries, exactly like on paper
'
' THINGS TO TRY
'   * Count how many nodes the search visits with and without the
'     column check (comment it out - but be patient!).
'   * Try  TWO+TWO=FOUR  (several answers) and  CROSS+ROADS=DANGER.
'   * Extend it to subtraction puzzles.
' ============================================================
DECLARE SUB Assign (k AS INTEGER)
DECLARE FUNCTION ColumnsOK% (upTo AS INTEGER)
DECLARE FUNCTION Parse% (p$)
DEFINT A-Z

DIM SHARED w$(1 TO 8), nw            ' addend words
DIM SHARED res$                      ' the result word
DIM SHARED order$                    ' letters in the order we assign them
DIM SHARED lastCol(1 TO 10)          ' after letter k, columns 0..lastCol(k) are complete
DIM SHARED v(25)                     ' v(letter) = digit, -1 = unassigned
DIM SHARED used(9)                   ' -1 if that digit is taken
DIM SHARED lead(25)                  ' -1 if the letter starts some word
DIM SHARED nSol, nodes&

DO
    CLS
    COLOR 14: PRINT "CRYPTARITHM SOLVER": COLOR 7
    PRINT
    PRINT "  1) SEND+MORE=MONEY       2) TWO+TWO=FOUR"
    PRINT "  3) CROSS+ROADS=DANGER    4) BASE+BALL=GAMES"
    PRINT "  5) Type your own         Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    p$ = ""
    SELECT CASE a$
        CASE "1": p$ = "SEND+MORE=MONEY"
        CASE "2": p$ = "TWO+TWO=FOUR"
        CASE "3": p$ = "CROSS+ROADS=DANGER"
        CASE "4": p$ = "BASE+BALL=GAMES"
        CASE "5"
            LINE INPUT "  Puzzle (like ABC+DEF=GHIJ): "; p$
            p$ = UCASE$(p$)
    END SELECT
    IF p$ <> "" THEN
        e = INSTR(p$, "=")
        many = 0
        IF e > 0 THEN many = INSTR(MID$(p$, e + 1), "+")
        IF many THEN
            PRINT "  Sorry, only WORD+WORD=WORD (one word after the =)."
        ELSEIF Parse%(p$) THEN
            PRINT
            ' Show it written like a school sum, right-aligned.
            wd = LEN(res$) + 2
            FOR i = 1 TO nw
                IF i = nw THEN pre$ = "+ " ELSE pre$ = "  "
                PRINT "    "; pre$; SPACE$(wd - LEN(w$(i))); w$(i)
            NEXT
            PRINT "    "; STRING$(wd + 2, "-")
            PRINT "    "; "  "; SPACE$(wd - LEN(res$)); res$
            PRINT
            PRINT "  Letters in search order: "; order$
            PRINT
            nSol = 0: nodes& = 0
            FOR i = 0 TO 25: v(i) = -1: NEXT
            FOR i = 0 TO 9: used(i) = 0: NEXT
            t! = TIMER
            Assign 1
            PRINT
            PRINT "  Solutions:"; nSol; "   search nodes:"; nodes&;
            PRINT USING "   time ###.## s"; TIMER - t!
        END IF
    END IF
    PRINT
    LINE INPUT "Press Enter (Q quits) "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

SUB Assign (k AS INTEGER)
    ' Give a digit to the k-th letter of order$, then recurse.
    IF k > LEN(order$) THEN
        ' Every letter has a digit and every column checked out.
        nSol = nSol + 1
        IF nSol <= 12 THEN
            PRINT "  ";
            FOR i = 1 TO nw
                IF i > 1 THEN PRINT " + ";
                FOR j = 1 TO LEN(w$(i)): PRINT CHR$(48 + v(ASC(MID$(w$(i), j, 1)) - 65)); : NEXT
            NEXT
            PRINT " = ";
            FOR j = 1 TO LEN(res$): PRINT CHR$(48 + v(ASC(MID$(res$, j, 1)) - 65)); : NEXT
            PRINT
        ELSEIF nSol = 13 THEN
            PRINT "  (more solutions not shown)"
        END IF
        EXIT SUB
    END IF
    L = ASC(MID$(order$, k, 1)) - 65
    lo = 0: IF lead(L) THEN lo = 1        ' no leading zeros
    FOR d = lo TO 9
        IF NOT used(d) THEN
            nodes& = nodes& + 1
            v(L) = d: used(d) = -1
            ' PRUNING: if this letter completed one or more columns,
            ' check the sum so far before going any deeper.
            IF lastCol(k) < 0 THEN
                Assign k + 1
            ELSEIF ColumnsOK%(lastCol(k)) THEN
                Assign k + 1
            END IF
            v(L) = -1: used(d) = 0
        END IF
    NEXT
END SUB

FUNCTION ColumnsOK% (upTo AS INTEGER)
    ' Add the columns 0 (units) .. upTo like on paper, with carries.
    ' The result digit in each column must match.
    carry = 0
    FOR j = 0 TO upTo
        s = carry
        FOR i = 1 TO nw
            IF LEN(w$(i)) > j THEN s = s + v(ASC(MID$(w$(i), LEN(w$(i)) - j, 1)) - 65)
        NEXT
        IF j < LEN(res$) THEN
            IF s MOD 10 <> v(ASC(MID$(res$, LEN(res$) - j, 1)) - 65) THEN ColumnsOK% = 0: EXIT FUNCTION
        ELSE
            IF s MOD 10 <> 0 THEN ColumnsOK% = 0: EXIT FUNCTION
        END IF
        carry = s \ 10
    NEXT
    ' After the very last column there must be nothing left over.
    IF upTo = LEN(res$) - 1 AND carry <> 0 THEN ColumnsOK% = 0: EXIT FUNCTION
    ColumnsOK% = -1
END FUNCTION

FUNCTION Parse% (p$)
    ' Split "AAA+BBB=CCC" into w$() and res$, and work out the order in
    ' which letters will be assigned.  Returns 0 if the text is bad.
    Parse% = 0
    q$ = ""
    FOR i = 1 TO LEN(p$)                ' remove spaces
        IF MID$(p$, i, 1) <> " " THEN q$ = q$ + MID$(p$, i, 1)
    NEXT
    e = INSTR(q$, "=")
    IF e = 0 THEN PRINT "  Need an = sign.": EXIT FUNCTION
    res$ = MID$(q$, e + 1): rest$ = LEFT$(q$, e - 1) + "+"
    nw = 0
    DO WHILE LEN(rest$) > 0
        pl = INSTR(rest$, "+")
        IF nw = 8 THEN PRINT "  At most 8 words before the =.": EXIT FUNCTION
        nw = nw + 1: w$(nw) = LEFT$(rest$, pl - 1)
        rest$ = MID$(rest$, pl + 1)
    LOOP
    ' Every word must be letters only and not empty.
    FOR i = 0 TO nw
        IF i = 0 THEN t$ = res$ ELSE t$ = w$(i)
        IF t$ = "" THEN PRINT "  Empty word found.": EXIT FUNCTION
        FOR j = 1 TO LEN(t$)
            ch$ = MID$(t$, j, 1)
            IF ch$ < "A" OR ch$ > "Z" THEN PRINT "  Only letters A-Z please.": EXIT FUNCTION
        NEXT
        IF i > 0 AND LEN(t$) > LEN(res$) THEN PRINT "  The answer word is too short.": EXIT FUNCTION
    NEXT
    ' Build the assignment order: column 0 (units) first, then the
    ' tens column, and so on.  Note after which letter each column is
    ' complete.
    FOR i = 0 TO 25: lead(i) = 0: NEXT
    order$ = ""
    FOR k = 1 TO 10: lastCol(k) = -1: NEXT
    FOR j = 0 TO LEN(res$) - 1
        FOR i = 0 TO nw
            IF i = 0 THEN t$ = res$ ELSE t$ = w$(i)
            IF LEN(t$) > j THEN
                ch$ = MID$(t$, LEN(t$) - j, 1)
                IF INSTR(order$, ch$) = 0 THEN
                    IF LEN(order$) = 10 THEN PRINT "  More than 10 different letters!": EXIT FUNCTION
                    order$ = order$ + ch$
                END IF
            END IF
        NEXT
        lastCol(LEN(order$)) = j      ' column j is decided by now
    NEXT
    ' Leading letters may not be zero (unless the word is 1 letter).
    FOR i = 0 TO nw
        IF i = 0 THEN t$ = res$ ELSE t$ = w$(i)
        IF LEN(t$) > 1 THEN lead(ASC(t$) - 65) = -1
    NEXT
    Parse% = -1
END FUNCTION
