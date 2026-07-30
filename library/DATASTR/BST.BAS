' ============================================================
' TITLE:    Binary Search Tree Explorer
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     binary search tree, recursion, traversal, delete, tree drawing
' SUMMARY:  Insert and delete numbers in a binary search tree, draw it on screen, and see all four traversal orders.
' ------------------------------------------------------------
' WHAT IT DOES
'   A BINARY SEARCH TREE (BST) stores numbers so that, for every
'   node, everything in its LEFT subtree is smaller and everything
'   in its RIGHT subtree is bigger. Searching is like the "guess
'   my number" game: each step throws away half of the tree (if it
'   is balanced).
'
'   Nodes live in an array of TYPE records; lft and rgt hold the
'   array index of each child (0 = no child). The tree is drawn
'   in text mode: each node's COLUMN is its position in sorted
'   (in-order) order and its ROW is its depth, so the picture can
'   never overlap.
'
' HOW TO USE
'   Type a command and press Enter:
'     42     or  I 42   insert 42
'     D 42              delete 42
'     F 42              find 42 (shows the search path)
'     R                 build a random tree
'     C                 clear the tree
'     Q                 quit
'
' CONCEPTS YOU WILL LEARN
'   * Recursive SUBs and FUNCTIONs on a tree
'   * In-order, pre-order, post-order and level-order traversals
'   * The three delete cases: leaf, one child, two children
'   * Using a queue for breadth-first (level) order
'
' THINGS TO TRY
'   * Insert 10 20 30 40 50 in order. Why is the tree so lopsided?
'     (Then see AVL.BAS for the cure.)
'   * Add a command that prints the tree's height
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Insert% (r AS INTEGER, v AS INTEGER)
DECLARE FUNCTION Remove% (r AS INTEGER, v AS INTEGER)
DECLARE SUB Layout (r AS INTEGER, depth AS INTEGER)
DECLARE SUB Walk (r AS INTEGER, mode AS INTEGER)
DECLARE SUB DrawTree ()
DECLARE FUNCTION NewNode% (v AS INTEGER)

TYPE TreeNode
    value AS INTEGER
    lft AS INTEGER
    rgt AS INTEGER
    col AS INTEGER          ' screen column (filled in by Layout)
    row AS INTEGER          ' screen row
END TYPE

CONST MAXN = 17             ' enough to fit across 80 columns
DIM SHARED t(1 TO MAXN) AS TreeNode
DIM SHARED freeHead, root, counter, outS$, count, msg$
DIM qu(1 TO MAXN)          ' queue used for level-order walks

' Free list threaded through the lft field.
FOR i = 1 TO MAXN - 1: t(i).lft = i + 1: NEXT i
t(MAXN).lft = 0: freeHead = 1
RANDOMIZE TIMER

' Starting tree.
FOR i = 1 TO 9
    READ v: root = Insert%(root, v)
NEXT i
DATA 50, 30, 70, 20, 40, 60, 80, 35, 65
msg$ = "Try: D 30 (a node with two children)"

DO
    CLS
    DrawTree
    LOCATE 18, 1
    ' ---- the four traversals ----
    FOR m = 1 TO 3
        outS$ = ""
        Walk root, m
        IF m = 1 THEN PRINT "In-order  (L,N,R):"; outS$
        IF m = 2 THEN PRINT "Pre-order (N,L,R):"; outS$
        IF m = 3 THEN PRINT "Post-order(L,R,N):"; outS$
    NEXT m
    ' Level order: a simple array queue of node indexes.
    qh = 1: qt = 0: outS$ = ""
    IF root THEN qt = 1: qu(1) = root
    DO WHILE qh <= qt
        n = qu(qh): qh = qh + 1
        outS$ = outS$ + STR$(t(n).value)
        IF t(n).lft THEN qt = qt + 1: qu(qt) = t(n).lft
        IF t(n).rgt THEN qt = qt + 1: qu(qt) = t(n).rgt
    LOOP
    PRINT "Level order       :"; outS$
    PRINT LEFT$(msg$, 79)
    LINE INPUT "Command (num, I n, D n, F n, R, C, Q): "; c$
    c$ = UCASE$(LTRIM$(RTRIM$(c$)))
    IF c$ = "" THEN c$ = "?"
    op$ = LEFT$(c$, 1)
    ' A bare number means insert.
    IF (op$ >= "0" AND op$ <= "9") OR op$ = "-" THEN c$ = "I " + c$: op$ = "I"
    v = VAL(MID$(c$, 2))
    msg$ = ""
    SELECT CASE op$
    CASE "I"
        IF v < 0 OR v > 99 THEN
            msg$ = "Please use numbers from 0 to 99 (so they fit the drawing)."
        ELSEIF count >= MAXN THEN
            msg$ = "Tree is full (max" + STR$(MAXN) + " nodes)."
        ELSE
            root = Insert%(root, v): msg$ = "Inserted" + STR$(v)
        END IF
    CASE "D"
        root = Remove%(root, v)
    CASE "F"
        ' Iterative search: go left if smaller, right if bigger.
        p = root: msg$ = "Path:"
        DO WHILE p
            msg$ = msg$ + STR$(t(p).value)
            IF v = t(p).value THEN EXIT DO
            IF v < t(p).value THEN p = t(p).lft ELSE p = t(p).rgt
            msg$ = msg$ + " ->"
        LOOP
        IF p THEN msg$ = msg$ + "  FOUND!" ELSE msg$ = msg$ + " (null) not found"
    CASE "R", "C"
        ' Free every node by rebuilding the free list.
        FOR i = 1 TO MAXN - 1: t(i).lft = i + 1: NEXT i
        t(MAXN).lft = 0: freeHead = 1: root = 0: count = 0
        IF op$ = "R" THEN
            FOR i = 1 TO 12
                root = Insert%(root, INT(RND * 99) + 1)
            NEXT i
        END IF
    CASE "Q"
        EXIT DO
    CASE ELSE
        msg$ = "Unknown command."
    END SELECT
LOOP
CLS : PRINT "Bye!"
END

' ------------------------------------------------------------
' DrawTree: first Layout assigns rows/columns, then we print
' each node and a connector line to its parent.
' ------------------------------------------------------------
SUB DrawTree
    PRINT "BINARY SEARCH TREE  ("; LTRIM$(STR$(count)); " nodes)"
    IF root = 0 THEN PRINT : PRINT "  (empty tree)": EXIT SUB
    counter = 0
    Layout root, 0
    FOR i = 1 TO MAXN
        IF t(i).row > 0 THEN
            ' draw connectors to children on the row below
            FOR side = 1 TO 2
                IF side = 1 THEN c = t(i).lft ELSE c = t(i).rgt
                IF c THEN
                    a = t(c).col + 1: b = t(i).col + 1
                    IF a > b THEN SWAP a, b
                    LOCATE t(i).row + 1, a
                    PRINT STRING$(b - a + 1, "-");
                    LOCATE t(i).row + 1, t(c).col + 1: PRINT "+";
                END IF
            NEXT side
            LOCATE t(i).row, t(i).col: PRINT USING "##"; t(i).value;
        END IF
    NEXT i
END SUB

' Insert%: returns the (possibly new) root of subtree r.
' If r is empty we create the node right here; otherwise we
' recurse into the correct side and re-attach the result.
' Duplicates are ignored.
FUNCTION Insert% (r AS INTEGER, v AS INTEGER)
    IF r = 0 THEN Insert% = NewNode%(v): EXIT FUNCTION
    IF v < t(r).value THEN
        t(r).lft = Insert%((t(r).lft), v)   ' (..) passes a copy
    ELSEIF v > t(r).value THEN
        t(r).rgt = Insert%((t(r).rgt), v)
    END IF
    Insert% = r
END FUNCTION

' Layout: in-order walk. Each node gets the next column, so left
' subtrees end up to the left, and depth decides the row.
SUB Layout (r AS INTEGER, depth AS INTEGER)
    IF r = 0 THEN EXIT SUB
    Layout (t(r).lft), depth + 1
    counter = counter + 1
    t(r).col = counter * 4
    t(r).row = 3 + depth * 2
    IF t(r).row > 15 THEN t(r).row = 15   ' squash very deep trees
    Layout (t(r).rgt), depth + 1
END SUB

FUNCTION NewNode% (v AS INTEGER)
    n = freeHead: freeHead = t(n).lft
    t(n).value = v: t(n).lft = 0: t(n).rgt = 0: t(n).row = 0
    count = count + 1
    NewNode% = n
END FUNCTION

' Remove%: delete v from subtree r, returning the new subtree root.
FUNCTION Remove% (r AS INTEGER, v AS INTEGER)
    IF r = 0 THEN msg$ = STR$(v) + " is not in the tree.": Remove% = 0: EXIT FUNCTION
    IF v < t(r).value THEN
        t(r).lft = Remove%((t(r).lft), v): Remove% = r
    ELSEIF v > t(r).value THEN
        t(r).rgt = Remove%((t(r).rgt), v): Remove% = r
    ELSEIF t(r).lft = 0 OR t(r).rgt = 0 THEN
        ' CASE 1 & 2: zero or one child. The child (or 0) simply
        ' takes this node's place, and the node is freed.
        IF t(r).lft THEN Remove% = t(r).lft ELSE Remove% = t(r).rgt
        t(r).row = 0: t(r).lft = freeHead: freeHead = r
        count = count - 1
        msg$ = "Deleted" + STR$(v)
    ELSE
        ' CASE 3: two children. Find the in-order SUCCESSOR (the
        ' smallest value in the right subtree), copy it here, then
        ' delete the successor from the right subtree instead.
        s = t(r).rgt
        DO WHILE t(s).lft: s = t(s).lft: LOOP
        t(r).value = t(s).value
        t(r).rgt = Remove%((t(r).rgt), (t(s).value))
        msg$ = "Deleted" + STR$(v) + " (replaced by successor" + STR$(t(r).value) + ")"
        Remove% = r
    END IF
END FUNCTION

' Walk: recursive traversal. mode 1=in, 2=pre, 3=post order.
' The only difference is WHEN we "visit" (record) the node.
SUB Walk (r AS INTEGER, mode AS INTEGER)
    IF r = 0 THEN EXIT SUB
    IF mode = 2 THEN outS$ = outS$ + STR$(t(r).value)
    Walk (t(r).lft), mode
    IF mode = 1 THEN outS$ = outS$ + STR$(t(r).value)
    Walk (t(r).rgt), mode
    IF mode = 3 THEN outS$ = outS$ + STR$(t(r).value)
END SUB
