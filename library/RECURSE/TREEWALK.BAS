' ============================================================
' TITLE:    Binary Tree Traversals
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, binary search tree, traversal, inorder, preorder, postorder, arrays
' SUMMARY:  Build a binary search tree in arrays, draw it sideways, and walk it in pre-, in- and post-order with recursion.
' ------------------------------------------------------------
' WHAT IT DOES
'   A binary search tree (BST) keeps smaller keys to the left and
'   bigger keys to the right.  QBasic has no pointers, so each node
'   lives in a slot of three parallel arrays:
'       nkey(i)   lft(i)   rgt(i)      (0 means "no child")
'   (We cannot call the array key() - KEY is a QBasic keyword.)
'   Insert, Height, Count, the three classic traversals and a
'   sideways drawing are all short recursive SUBs/FUNCTIONs.
'     PRE-order : visit node, then left subtree, then right
'     IN-order  : left, node, right    -> keys come out SORTED
'     POST-order: left, right, node    -> children before parents
'
' HOW TO USE
'   Just run it: it inserts some keys, prints everything, then lets
'   you add your own keys (0 to quit).
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK VISIT in InOrder.  At each stop look at
'      the CALL STACK: the frames are the path from the root down to
'      the node being visited.  Click each frame and read node.
'   2. Add a WATCH on  nkey(node)  - it shows the key of the current
'      frame.  Notice the keys come out in increasing order.
'   3. Break on <<< BREAK HEIGHT.  Height asks its children first and
'      only knows its answer on the way BACK UP - postorder thinking.
'   4. Try inserting keys already in order (10 20 30 40 ...).  The
'      tree becomes a long stick, and the stack in InOrder becomes as
'      deep as the number of keys.
'
' CONCEPTS YOU WILL LEARN
'   * Trees stored in parallel arrays (index = "pointer")
'   * Recursive insert, count, height
'   * Pre/in/post-order traversals and what each is good for
'
' THINGS TO TRY
'   * Write Search(node, k) that returns -1 if k is in the tree.
'   * Print the smallest and largest key (follow left / right).
'   * Write a "mirror" SUB that swaps every left and right child.
' ============================================================
DECLARE SUB Insert (node AS INTEGER, k AS INTEGER)
DECLARE SUB PreOrder (node AS INTEGER)
DECLARE SUB InOrder (node AS INTEGER)
DECLARE SUB PostOrder (node AS INTEGER)
DECLARE SUB Sideways (node AS INTEGER, depth AS INTEGER)
DECLARE FUNCTION Height% (node AS INTEGER)
DECLARE FUNCTION CountNodes% (node AS INTEGER)
DECLARE FUNCTION NewNode% (k AS INTEGER)
DECLARE SUB ShowAll ()

CONST MAXN = 60
DIM SHARED nkey(1 TO MAXN) AS INTEGER
DIM SHARED lft(1 TO MAXN) AS INTEGER     ' left child index, 0 = none
DIM SHARED rgt(1 TO MAXN) AS INTEGER     ' right child index, 0 = none
DIM SHARED used AS INTEGER               ' slots in use
DIM SHARED root AS INTEGER               ' index of the root, 0 = empty

' Build the starting tree.
DO
    READ k%
    IF k% = 0 THEN EXIT DO
    IF root = 0 THEN root = NewNode%(k%) ELSE Insert root, k%
LOOP
DATA 50, 30, 70, 20, 40, 60, 80, 35, 65, 0

CLS
ShowAll
DO
    INPUT "Add a key (1-999, 0 quits)"; k%
    IF k% <= 0 OR k% > 999 THEN EXIT DO
    IF used >= MAXN THEN PRINT "Tree is full.": EXIT DO
    Insert root, k%
    CLS
    ShowAll
LOOP
PRINT "Bye!"
END

SUB ShowAll
    PRINT "Tree drawn sideways (root on the left, right subtree on top):"
    Sideways root, 0
    PRINT
    PRINT "Pre-order : ";: PreOrder root: PRINT
    PRINT "In-order  : ";: InOrder root: PRINT
    PRINT "Post-order: ";: PostOrder root: PRINT
    PRINT "Nodes:"; CountNodes%(root); "   Height:"; Height%(root)
    PRINT
END SUB

FUNCTION NewNode% (k AS INTEGER)
    used = used + 1
    nkey(used) = k: lft(used) = 0: rgt(used) = 0
    NewNode% = used
END FUNCTION

' Walk down from node to the right empty spot and hang k there.
SUB Insert (node AS INTEGER, k AS INTEGER)
    IF k < nkey(node) THEN
        IF lft(node) = 0 THEN lft(node) = NewNode%(k) ELSE Insert lft(node), k
    ELSEIF k > nkey(node) THEN
        IF rgt(node) = 0 THEN rgt(node) = NewNode%(k) ELSE Insert rgt(node), k
    END IF
    ' equal keys are ignored: a BST keeps each key once
END SUB

SUB PreOrder (node AS INTEGER)
    IF node = 0 THEN EXIT SUB
    PRINT nkey(node);                ' visit FIRST
    PreOrder lft(node)
    PreOrder rgt(node)
END SUB

SUB InOrder (node AS INTEGER)
    IF node = 0 THEN EXIT SUB        ' empty subtree: nothing to do
    InOrder lft(node)
    PRINT nkey(node);                ' <<< BREAK VISIT (in the MIDDLE)
    InOrder rgt(node)
END SUB

SUB PostOrder (node AS INTEGER)
    IF node = 0 THEN EXIT SUB
    PostOrder lft(node)
    PostOrder rgt(node)
    PRINT nkey(node);                ' visit LAST
END SUB

FUNCTION CountNodes% (node AS INTEGER)
    IF node = 0 THEN CountNodes% = 0: EXIT FUNCTION
    CountNodes% = 1 + CountNodes%(lft(node)) + CountNodes%(rgt(node))
END FUNCTION

FUNCTION Height% (node AS INTEGER)
    DIM hl AS INTEGER, hr AS INTEGER
    IF node = 0 THEN Height% = 0: EXIT FUNCTION
    hl = Height%(lft(node))
    hr = Height%(rgt(node))
    IF hl > hr THEN Height% = hl + 1 ELSE Height% = hr + 1   ' <<< BREAK HEIGHT
END FUNCTION

' Reverse in-order (right, node, left) with indentation = a tree
' lying on its side.  Tilt your head to the left to see it!
SUB Sideways (node AS INTEGER, depth AS INTEGER)
    IF node = 0 THEN EXIT SUB
    Sideways rgt(node), depth + 1
    PRINT SPACE$(depth * 5); nkey(node)
    Sideways lft(node), depth + 1
END SUB
