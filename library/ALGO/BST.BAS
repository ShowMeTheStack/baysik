' ============================================================
' TITLE:    Binary Search Tree Workshop
' CATEGORY: Algorithms
' LEVEL:    Intermediate
' TAGS:     binary tree, BST, recursion, traversal, data structures
' SUMMARY:  Build a binary search tree out of plain arrays, draw it, search it, delete from it and walk it in four orders.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps a binary search tree (BST) in three parallel arrays:
'       value(i)  the number stored in node i
'       lft(i)    index of node i's left child  (0 = none)
'       rgt(i)    index of node i's right child (0 = none)
'   Rule of a BST: everything in a node's LEFT subtree is smaller,
'   everything in its RIGHT subtree is bigger.  The tree is drawn on
'   screen after every change, and you can print the in-order,
'   pre-order, post-order and level-order (breadth-first) walks.
'
' HOW TO USE
'   I = insert a number    S = search    D = delete
'   R = 12 random numbers  T = traversals  C = clear   Q = quit
'
' CONCEPTS YOU WILL LEARN
'   * Linked structures without pointers: indexes into arrays
'   * Insert / search in O(height): O(log n) when balanced,
'     O(n) when the tree degenerates into a "stick" (insert 1..10!)
'   * Recursive traversals; in-order prints values SORTED
'   * Level-order traversal with a queue
'   * Deleting a node with two children using its successor
'
' THINGS TO TRY
'   * Insert 10, 20, 30, 40, 50 in order - why is the tree so tall?
'   * Write a function that counts the leaves
' ============================================================
DECLARE SUB Insert (v%)
DECLARE SUB Layout (n%, depth%)
DECLARE SUB InOrder (n%)
DECLARE SUB PreOrder (n%)
DECLARE SUB PostOrder (n%)
DECLARE SUB DrawTree ()
DECLARE SUB DeleteVal (v%)
DECLARE FUNCTION Height% (n%)
DEFINT A-Z
CONST MAXN = 18
DIM SHARED value(1 TO MAXN), lft(1 TO MAXN), rgt(1 TO MAXN)
DIM SHARED root, used, free(1 TO MAXN), nFree
DIM SHARED px(1 TO MAXN), py(1 TO MAXN), col, msg$
DIM SHARED q(1 TO MAXN)          ' a queue for level-order walks

' All slots start on the "free list" so deleted nodes can be reused.
FOR i = MAXN TO 1 STEP -1: nFree = nFree + 1: free(nFree) = i: NEXT
RANDOMIZE TIMER
msg$ = "Empty tree. Press R for random numbers or I to insert."
DO
    DrawTree
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    LOCATE 23, 1: PRINT SPACE$(79);
    LOCATE 23, 1
    SELECT CASE k$
    CASE "I", "S", "D"
        LINE INPUT "Number (1-99): "; t$
        v = VAL(t$)
        IF v < 1 OR v > 99 THEN
            msg$ = "Please use numbers 1 to 99."
        ELSEIF k$ = "I" THEN
            Insert v
        ELSEIF k$ = "D" THEN
            DeleteVal v
        ELSE
            ' ---- SEARCH: one comparison per level ----------------
            ' Smaller? go left.  Bigger? go right.  Equal? found.
            n = root: path$ = ""
            DO WHILE n <> 0
                path$ = path$ + STR$(value(n))
                IF v = value(n) THEN EXIT DO
                IF v < value(n) THEN n = lft(n) ELSE n = rgt(n)
            LOOP
            IF n THEN msg$ = "Found " ELSE msg$ = "Not found "
            msg$ = msg$ + STR$(v) + ". Visited:" + path$
        END IF
    CASE "R"
        FOR i = 1 TO MAXN: lft(i) = 0: rgt(i) = 0: NEXT
        root = 0: used = 0: nFree = 0
        FOR i = MAXN TO 1 STEP -1: nFree = nFree + 1: free(nFree) = i: NEXT
        FOR i = 1 TO 12: Insert INT(RND * 99) + 1: NEXT
        msg$ = "12 random inserts (duplicates are ignored)."
    CASE "C"
        root = 0: used = 0: nFree = 0
        FOR i = MAXN TO 1 STEP -1: nFree = nFree + 1: free(nFree) = i: NEXT
        msg$ = "Cleared."
    CASE "T"
        CLS
        PRINT "In-order   (left, node, right) - sorted!:": InOrder root: PRINT
        PRINT "Pre-order  (node, left, right) - rebuilds the same tree:": PreOrder root: PRINT
        PRINT "Post-order (left, right, node) - children before parent:": PostOrder root: PRINT
        ' ---- LEVEL ORDER: BFS with a simple array queue ----------
        PRINT "Level-order (row by row, using a queue):"
        h = 1: t = 0
        IF root THEN t = 1: q(1) = root
        DO WHILE h <= t
            n = q(h): h = h + 1
            PRINT value(n);
            IF lft(n) THEN t = t + 1: q(t) = lft(n)
            IF rgt(n) THEN t = t + 1: q(t) = rgt(n)
        LOOP
        PRINT : PRINT : PRINT "Height of tree:"; Height(root); " nodes:"; used
        PRINT : PRINT "Press a key..."
        DO: LOOP WHILE INKEY$ = ""
        msg$ = ""
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
CLS
END

' --------------------------------------------------------------
' Insert v: walk down from the root like a search.  When we fall
' off the tree (child = 0), hang a new node there.
' --------------------------------------------------------------
SUB Insert (v)
    IF nFree = 0 THEN msg$ = "Tree is full.": EXIT SUB
    IF root = 0 THEN
        n = free(nFree): nFree = nFree - 1
        value(n) = v: lft(n) = 0: rgt(n) = 0
        root = n: used = used + 1: msg$ = "Inserted" + STR$(v) + " as the root."
        EXIT SUB
    END IF
    cur = root
    DO
        IF v = value(cur) THEN msg$ = STR$(v) + " is already in the tree.": EXIT SUB
        IF v < value(cur) THEN
            IF lft(cur) = 0 THEN EXIT DO
            cur = lft(cur)
        ELSE
            IF rgt(cur) = 0 THEN EXIT DO
            cur = rgt(cur)
        END IF
    LOOP
    n = free(nFree): nFree = nFree - 1          ' grab an unused slot
    value(n) = v: lft(n) = 0: rgt(n) = 0
    IF v < value(cur) THEN lft(cur) = n ELSE rgt(cur) = n
    used = used + 1
    msg$ = "Inserted" + STR$(v) + " under" + STR$(value(cur)) + "."
END SUB

' --------------------------------------------------------------
' Delete v.  Three cases:
'   1. leaf            -> just unhook it from its parent
'   2. one child       -> the child takes its place
'   3. two children    -> copy in the SUCCESSOR (smallest value in
'                         the right subtree), then delete the
'                         successor, which has no left child.
' --------------------------------------------------------------
SUB DeleteVal (v)
    parent = 0: n = root
    DO WHILE n <> 0                              ' find the node
        IF v = value(n) THEN EXIT DO
        parent = n
        IF v < value(n) THEN n = lft(n) ELSE n = rgt(n)
    LOOP
    IF n = 0 THEN msg$ = STR$(v) + " is not in the tree.": EXIT SUB
    msg$ = "Deleted" + STR$(v) + "."
    IF lft(n) <> 0 AND rgt(n) <> 0 THEN          ' case 3
        sp = n: s = rgt(n)
        DO WHILE lft(s) <> 0: sp = s: s = lft(s): LOOP
        value(n) = value(s)                      ' copy successor up
        msg$ = msg$ + " Successor" + STR$(value(s)) + " moved up."
        n = s: parent = sp                       ' now remove s instead
    END IF
    ' n now has at most one child
    IF lft(n) <> 0 THEN child = lft(n) ELSE child = rgt(n)
    IF parent = 0 THEN
        root = child
    ELSEIF lft(parent) = n THEN
        lft(parent) = child
    ELSE
        rgt(parent) = child
    END IF
    nFree = nFree + 1: free(nFree) = n: used = used - 1   ' recycle slot
END SUB

' Height = number of levels (empty tree = 0).
FUNCTION Height (n)
    IF n = 0 THEN Height = 0: EXIT FUNCTION
    a = Height(lft(n)): b = Height(rgt(n))
    IF a > b THEN Height = a + 1 ELSE Height = b + 1
END FUNCTION

SUB InOrder (n)
    IF n = 0 THEN EXIT SUB
    InOrder lft(n): PRINT value(n); : InOrder rgt(n)
END SUB

SUB PreOrder (n)
    IF n = 0 THEN EXIT SUB
    PRINT value(n); : PreOrder lft(n): PreOrder rgt(n)
END SUB

SUB PostOrder (n)
    IF n = 0 THEN EXIT SUB
    PostOrder lft(n): PostOrder rgt(n): PRINT value(n);
END SUB

' Layout gives each node a screen position: x comes from its
' in-order rank (so the drawing is sorted left to right), y from
' its depth.  A neat trick - no two nodes ever overlap.
SUB Layout (n, depth)
    IF n = 0 THEN EXIT SUB
    Layout lft(n), depth + 1
    col = col + 1
    px(n) = col * 4: py(n) = 3 + depth * 2
    Layout rgt(n), depth + 1
END SUB

SUB DrawTree
    CLS
    COLOR 15: PRINT "BINARY SEARCH TREE": COLOR 7
    col = 0
    Layout root, 0
    IF Height(root) > 10 THEN
        LOCATE 5, 1: PRINT "(tree too tall to draw - try C to clear)"
    ELSE
        ' Walk the tree level by level (the queue approach again) so we
        ' only draw nodes that are really linked in - deleted slots
        ' still hold old values but are no longer reachable.
        h = 1: t = 0
        IF root THEN t = 1: q(1) = root
        DO WHILE h <= t
            n = q(h): h = h + 1
            ' a "/" or "\" halfway toward each child, one row lower
            COLOR 8
            IF lft(n) THEN LOCATE py(n) + 1, (px(n) + px(lft(n))) \ 2 + 1: PRINT "/";
            IF rgt(n) THEN LOCATE py(n) + 1, (px(n) + px(rgt(n))) \ 2 + 1: PRINT "\";
            IF n = root THEN COLOR 14 ELSE COLOR 11
            LOCATE py(n), px(n): PRINT USING "##"; value(n);
            IF lft(n) THEN t = t + 1: q(t) = lft(n)
            IF rgt(n) THEN t = t + 1: q(t) = rgt(n)
        LOOP
    END IF
    COLOR 7
    LOCATE 22, 1: PRINT msg$
    LOCATE 24, 1: COLOR 8
    PRINT "I=insert S=search D=delete R=random T=traversals C=clear Q=quit";
    COLOR 7
END SUB
