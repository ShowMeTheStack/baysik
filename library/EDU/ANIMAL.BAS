' ============================================================
' TITLE:    Guess the Animal (It Learns!)
' CATEGORY: Education & Quizzes
' LEVEL:    Advanced
' TAGS:     binary tree, arrays, files, artificial intelligence, yes/no
' SUMMARY:  Think of an animal and the computer guesses it - when it is wrong, you teach it a new question.
' ------------------------------------------------------------
' WHAT IT DOES
'   A classic program from the 1970s.  The computer asks yes/no
'   questions ("Does it live in water?") and then guesses.  If it is
'   wrong, it asks you what your animal was and for a question that
'   tells the two apart.  Next time it knows!  Everything it learns is
'   saved in the file ANIMALS.DAT, so it gets cleverer every game.
'
'   The knowledge is a BINARY TREE: every box (node) is either a
'   question with a "yes" branch and a "no" branch, or an animal (a
'   leaf).  We store the tree in three parallel arrays:
'       txt$(i)  the question or animal name
'       yes(i)   which node to go to on "yes" (0 means: this is a leaf)
'       no(i)    which node to go to on "no"
'
' HOW TO USE
'   Think of an animal and answer Y or N.  After each game press Y to
'   play again, N to stop, or S to see everything it knows.
'
' CONCEPTS YOU WILL LEARN
'   * Binary trees stored in arrays (no pointers needed!)
'   * How a program can "learn" by changing its own data
'   * Saving and loading structured data with WRITE # and INPUT #
'   * Walking (traversing) a tree with a loop and with recursion
'
' THINGS TO TRY
'   * Delete ANIMALS.DAT (or press R on the end menu) to start fresh
'   * Teach it 20 animals and draw the tree on paper
'   * Count how many questions deep the deepest animal is
' ============================================================

DECLARE SUB SaveTree ()
DECLARE SUB ShowTree (node!, depth!)
DECLARE FUNCTION YesNo! (prompt$)
DECLARE FUNCTION Article$ (w$)

CONST MAXN = 500
DIM SHARED txt$(1 TO MAXN), yes(1 TO MAXN), no(1 TO MAXN), nodes, shown

' ---- load the tree, or start with a tiny one ----
found = -1
ON ERROR GOTO NoFile
OPEN "ANIMALS.DAT" FOR INPUT AS #1
ON ERROR GOTO 0
IF found THEN
    INPUT #1, nodes
    FOR i = 1 TO nodes
        INPUT #1, txt$(i), yes(i), no(i)
    NEXT i
    CLOSE #1
ELSE
    ' node 1 is the root question; nodes 2 and 3 are animals (leaves)
    nodes = 3
    txt$(1) = "Does it live in water": yes(1) = 2: no(1) = 3
    txt$(2) = "fish": yes(2) = 0: no(2) = 0
    txt$(3) = "dog": yes(3) = 0: no(3) = 0
    SaveTree
END IF

CLS
COLOR 14: PRINT "  ***  GUESS THE ANIMAL  ***"
COLOR 7
PRINT "  I know"; (nodes + 1) \ 2; "animals so far.  Teach me more!"

DO
    PRINT
    COLOR 11: PRINT "  Think of an animal... and I'll try to guess it."
    COLOR 7
    ' ---- walk down the tree from the root ----
    node = 1
    DO WHILE yes(node) <> 0                  ' still a question
        IF YesNo(txt$(node) + "?") THEN node = yes(node) ELSE node = no(node)
    LOOP
    ' ---- we reached a leaf: make the guess ----
    IF YesNo("Is it " + Article$(txt$(node)) + "?") THEN
        COLOR 10: PRINT "  Hooray, I guessed it!": COLOR 7
        PLAY "T200 O4 C8 E8 G4"
    ELSE
        IF nodes + 2 > MAXN THEN
            PRINT "  My brain is full! I can't learn more."
        ELSE
            COLOR 13: PRINT "  You beat me!"
            COLOR 7
            LINE INPUT "  What was your animal? "; newA$
            newA$ = LCASE$(LTRIM$(RTRIM$(newA$)))
            IF newA$ <> "" THEN
                oldA$ = txt$(node)
                PRINT "  Type a yes/no question that is true for "; Article$(newA$)
                PRINT "  but false for "; Article$(oldA$); ":"
                LINE INPUT "  > "; q$
                q$ = LTRIM$(RTRIM$(q$))
                IF RIGHT$(q$, 1) = "?" THEN q$ = LEFT$(q$, LEN(q$) - 1)
                IF q$ <> "" THEN
                    ' The leaf turns into a question node with two new
                    ' leaves below it: yes -> new animal, no -> old one.
                    txt$(nodes + 1) = newA$: yes(nodes + 1) = 0: no(nodes + 1) = 0
                    txt$(nodes + 2) = oldA$: yes(nodes + 2) = 0: no(nodes + 2) = 0
                    txt$(node) = UCASE$(LEFT$(q$, 1)) + MID$(q$, 2)
                    yes(node) = nodes + 1: no(node) = nodes + 2
                    nodes = nodes + 2
                    SaveTree
                    COLOR 10: PRINT "  Thanks! I'll remember that.": COLOR 7
                END IF
            END IF
        END IF
    END IF
    PRINT
    PRINT "  Play again? (Y = yes, N = no, S = show what I know, R = reset)"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL INSTR("YNSR" + CHR$(27), k$) > 0 AND k$ <> ""
    IF k$ = "S" THEN
        CLS: shown = 0
        ShowTree 1, 0
        PRINT: PRINT "  Press a key...": DO: LOOP WHILE INKEY$ = ""
        CLS
    ELSEIF k$ = "R" THEN
        nodes = 3
        txt$(1) = "Does it live in water": yes(1) = 2: no(1) = 3
        txt$(2) = "fish": yes(2) = 0: no(2) = 0
        txt$(3) = "dog": yes(3) = 0: no(3) = 0
        SaveTree
        PRINT "  I have forgotten everything except fish and dogs!"
    ELSEIF k$ <> "Y" THEN
        EXIT DO
    END IF
LOOP
PRINT
PRINT "  Bye! I now know"; (nodes + 1) \ 2; "animals."
END

NoFile:
    found = 0
    RESUME NEXT

' Saves the node count, then one line per node
SUB SaveTree
    OPEN "ANIMALS.DAT" FOR OUTPUT AS #1
    WRITE #1, nodes
    FOR i = 1 TO nodes
        WRITE #1, txt$(i), yes(i), no(i)
    NEXT i
    CLOSE #1
END SUB

' ShowTree: a recursive walk.  A SUB that calls itself visits the
' "yes" side, then the "no" side, indenting deeper levels.
SUB ShowTree (node, depth)
    shown = shown + 1
    IF shown MOD 20 = 0 THEN PRINT "  -- more --": DO: LOOP WHILE INKEY$ = ""
    PRINT SPACE$(2 + depth * 3);
    IF yes(node) = 0 THEN
        COLOR 10: PRINT txt$(node): COLOR 7
    ELSE
        COLOR 14: PRINT txt$(node); "?": COLOR 7
        PRINT SPACE$(2 + depth * 3); " yes:"
        ShowTree yes(node), depth + 1
        PRINT SPACE$(2 + depth * 3); " no:"
        ShowTree no(node), depth + 1
    END IF
END SUB

' Asks a question until the answer starts with Y or N
FUNCTION YesNo (prompt$)
    DO
        PRINT "  "; prompt$; " (Y/N) ";
        LINE INPUT a$
        a$ = UCASE$(LEFT$(LTRIM$(a$), 1))
    LOOP UNTIL a$ = "Y" OR a$ = "N"
    YesNo = (a$ = "Y")
END FUNCTION

' "a dog" but "an elephant": use AN before a vowel sound
FUNCTION Article$ (w$)
    IF INSTR("aeiou", LCASE$(LEFT$(w$, 1))) > 0 THEN
        Article$ = "an " + w$
    ELSE
        Article$ = "a " + w$
    END IF
END FUNCTION
