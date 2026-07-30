' ============================================================
' TITLE:    AVL Tree Self-Balancing
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     AVL tree, rotations, balanced tree, recursion, height
' SUMMARY:  Watch an AVL tree rotate itself back into balance as sorted numbers are inserted one by one.
' ------------------------------------------------------------
' WHAT IT DOES
'   A plain binary search tree turns into a long "stick" if you
'   insert numbers in sorted order - searching becomes as slow as
'   a list. An AVL tree (named after Adelson-Velsky and Landis,
'   1962) fixes this. Every node stores its HEIGHT, and after each
'   insert we check the BALANCE = height(left) - height(right).
'   If it becomes +2 or -2 we ROTATE nodes to fix it.
'
'   There are four cases:
'     LL  (left-left)   -> one right rotation
'     RR  (right-right) -> one left rotation
'     LR  (left-right)  -> left-rotate child, then right-rotate
'     RL  (right-left)  -> right-rotate child, then left-rotate
'
'   The program inserts 1, 2, 3 ... 15 (the worst case for a plain
'   BST) and shows each rotation and the tree after every step.
'   Then you can insert your own numbers.
'
' HOW TO USE
'   Press a key to step through the inserts. Afterwards type
'   numbers (0-99) to insert, or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Tree rotations done purely by swapping child indexes
'   * Keeping a cached height up to date on the way back up
'   * Why balanced trees guarantee about log2(N) steps per search
'
' THINGS TO TRY
'   * Insert in reverse order (15 down to 1)
'   * Insert 50 30 40 to trigger an LR double rotation
'   * Add delete (it re-balances the same way on the way up)
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Ins% (r AS INTEGER, v AS INTEGER)
DECLARE FUNCTION H% (r AS INTEGER)
DECLARE SUB UpdH (r AS INTEGER)
DECLARE FUNCTION RotL% (x AS INTEGER)
DECLARE FUNCTION RotR% (y AS INTEGER)
DECLARE SUB Layout (r AS INTEGER, d AS INTEGER)
DECLARE SUB Show ()

TYPE AvlNode
    value AS INTEGER
    lft AS INTEGER
    rgt AS INTEGER
    ht AS INTEGER            ' height of the subtree rooted here (leaf = 1)
    col AS INTEGER
    row AS INTEGER
END TYPE

CONST MAXN = 18
DIM SHARED t(1 TO MAXN) AS AvlNode
DIM SHARED used, root, counter, log$

' ---- Part 1: insert 1..15 in order -------------------------
FOR v = 1 TO 15
    log$ = ""
    root = Ins%(root, v)
    CLS
    PRINT "Inserted"; v; "  ";
    IF log$ = "" THEN PRINT "(no rotation needed)" ELSE PRINT "Rotations:"; log$
    Show
    LOCATE 22, 1: PRINT "Press a key (Esc skips ahead)...";
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN EXIT FOR
NEXT v

' ---- Part 2: your own inserts ------------------------------
DO
    CLS
    Show
    LOCATE 20, 1: PRINT LEFT$(log$, 79)
    LOCATE 21, 1: PRINT "Nodes:"; used; " Height:"; H%(root); " (a plain BST could be"; used; "tall!)"
    LOCATE 22, 1: LINE INPUT "Number 0-99 to insert (Q to quit): "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF a$ = "Q" OR a$ = "" OR a$ = CHR$(27) THEN EXIT DO
    v = VAL(a$)
    IF used >= MAXN THEN
        log$ = "Tree full."
    ELSEIF v < 0 OR v > 99 THEN
        log$ = "Out of range."
    ELSE
        log$ = "": root = Ins%(root, v)
        IF log$ = "" THEN log$ = "No rotation." ELSE log$ = "Rotations:" + log$
    END IF
LOOP
END

' UpdH: recompute a node's height from its children.
SUB UpdH (r AS INTEGER)
    a = H%((t(r).lft)): b = H%((t(r).rgt))
    IF a > b THEN t(r).ht = a + 1 ELSE t(r).ht = b + 1
END SUB

' H%: height of a subtree; an empty subtree (0) has height 0.
FUNCTION H% (r AS INTEGER)
    IF r = 0 THEN H% = 0 ELSE H% = t(r).ht
END FUNCTION

' Ins%: ordinary BST insert, then re-balance on the way back up.
FUNCTION Ins% (r AS INTEGER, v AS INTEGER)
    IF r = 0 THEN
        used = used + 1
        t(used).value = v: t(used).ht = 1
        t(used).lft = 0: t(used).rgt = 0
        Ins% = used: EXIT FUNCTION
    END IF
    IF v < t(r).value THEN
        t(r).lft = Ins%((t(r).lft), v)
    ELSEIF v > t(r).value THEN
        t(r).rgt = Ins%((t(r).rgt), v)
    ELSE
        Ins% = r: EXIT FUNCTION            ' duplicate: nothing to do
    END IF
    UpdH r
    bal = H%((t(r).lft)) - H%((t(r).rgt))
    IF bal > 1 THEN
        ' Left side too tall. Which grandchild did we go into?
        IF v < t(t(r).lft).value THEN
            log$ = log$ + " LL@" + LTRIM$(STR$(t(r).value))
        ELSE
            log$ = log$ + " LR@" + LTRIM$(STR$(t(r).value))
            t(r).lft = RotL%((t(r).lft))   ' turn LR into LL first
        END IF
        Ins% = RotR%(r)
    ELSEIF bal < -1 THEN
        IF v > t(t(r).rgt).value THEN
            log$ = log$ + " RR@" + LTRIM$(STR$(t(r).value))
        ELSE
            log$ = log$ + " RL@" + LTRIM$(STR$(t(r).value))
            t(r).rgt = RotR%((t(r).rgt))   ' turn RL into RR first
        END IF
        Ins% = RotL%(r)
    ELSE
        Ins% = r
    END IF
END FUNCTION

' Layout: in-order position = column, depth = row.
SUB Layout (r AS INTEGER, d AS INTEGER)
    IF r = 0 THEN EXIT SUB
    Layout (t(r).lft), d + 1
    counter = counter + 1
    t(r).col = counter * 4
    t(r).row = 3 + d * 3
    Layout (t(r).rgt), d + 1
END SUB

' RotL%: left rotation around x.
'      x                y
'     / \              / \
'    A   y     ==>    x   C
'       / \          / \
'      B   C        A   B
FUNCTION RotL% (x AS INTEGER)
    y = t(x).rgt
    t(x).rgt = t(y).lft       ' B moves across
    t(y).lft = x              ' x drops down to the left
    UpdH x: UpdH y              ' x first: it is now below y
    RotL% = y
END FUNCTION

' RotR%: the mirror image of RotL%.
FUNCTION RotR% (y AS INTEGER)
    x = t(y).lft
    t(y).lft = t(x).rgt
    t(x).rgt = y
    UpdH y: UpdH x
    RotR% = x
END FUNCTION

' Show: draw every node with its balance factor underneath.
SUB Show
    counter = 0
    Layout root, 0
    FOR i = 1 TO used
        FOR side = 1 TO 2
            IF side = 1 THEN c = t(i).lft ELSE c = t(i).rgt
            IF c THEN
                a = t(c).col + 1: b = t(i).col + 1
                IF a > b THEN SWAP a, b
                LOCATE t(i).row + 2, a: PRINT STRING$(b - a + 1, "-");
                LOCATE t(i).row + 2, t(c).col + 1: PRINT "+";
            END IF
        NEXT side
        IF t(i).row <= 18 THEN
            LOCATE t(i).row, t(i).col: PRINT USING "##"; t(i).value;
            bal = H%((t(i).lft)) - H%((t(i).rgt))
            COLOR 8: LOCATE t(i).row + 1, t(i).col
            PRINT USING "+#"; bal; : COLOR 7
        END IF
    NEXT i
    LOCATE 19, 1: COLOR 8: PRINT "(small numbers under each node = balance: always -1, 0 or +1)": COLOR 7
END SUB
