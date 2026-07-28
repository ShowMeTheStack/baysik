' ============================================================
' TITLE:    Heap Sort with a Living Tree
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     sorting, heap, binary tree, arrays
' SUMMARY:  See an ordinary array drawn as a binary tree, turned into a max-heap, and emptied into sorted order.
' ------------------------------------------------------------
' WHAT IT DOES
'   Takes 15 random numbers and draws them as a binary tree (array
'   element i has children 2i and 2i+1).  First it "heapifies" the
'   array so every parent is bigger than its children.  Then, one
'   step at a time, it swaps the biggest value (the root) to the end
'   of the array and repairs the heap.  Sorted values appear in green.
'
' HOW TO USE
'   Press any key to take the next step.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a complete binary tree in a plain array (no pointers!)
'   * The heap property and the "sift down" operation
'   * Building a heap bottom-up in O(n)
'   * Heap sort: O(n log n) always, in place, but NOT stable
'
' THINGS TO TRY
'   * Make it a MIN-heap (flip the comparisons) - what order results?
'   * Count the comparisons for N = 15 and compare with n*log2(n)
' ============================================================
DECLARE SUB SiftDown (start%, size%)
DECLARE SUB Show (msg$, size%)
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST N = 15                     ' 15 = a perfect tree with 4 levels
DIM SHARED a(1 TO N), comps
' Screen columns for each tree node.  Level 1 has 1 node, level 2
' has 2, level 3 has 4, level 4 has 8: each level halves the spacing.
DIM SHARED col(1 TO N), row(1 TO N)
RANDOMIZE TIMER
FOR i = 1 TO N
    a(i) = INT(RND * 99) + 1
    lvl = INT(LOG(i) / LOG(2) + .0001)       ' 0,1,1,2,2,2,2,3...
    first = 2 ^ lvl                          ' index of first node on level
    spacing = 80 \ (2 ^ lvl)                 ' columns per node
    col(i) = (i - first) * spacing + spacing \ 2 - 1
    row(i) = 4 + lvl * 4
NEXT
COLOR 7, 0: CLS

Show "The array drawn as a tree. Children of i are 2i and 2i+1.", N
WaitKey

' ---- PHASE 1: BUILD THE HEAP ---------------------------------
' A MAX-HEAP has the rule: every parent >= its children.  Leaves
' (the bottom row, i > N\2) are tiny heaps already.  So we go
' through the parents from the LAST one (N\2) back to the root and
' "sift down" each.  Surprisingly this costs only O(n) total,
' because most nodes are near the bottom and sift only a little.
FOR i = N \ 2 TO 1 STEP -1
    SiftDown i, N
    Show "Heapify node" + STR$(i) + ": parent must beat both children", N
    WaitKey
NEXT

' ---- PHASE 2: SORT -------------------------------------------
' The biggest value is at the root a(1).  Swap it with the last
' item of the heap; now it is in its final sorted place.  The heap
' shrinks by one, and the new root is probably small, so sift it
' down to repair the heap - that costs at most log2(n) swaps.
' Doing this n times gives O(n log n).
FOR size = N TO 2 STEP -1
    SWAP a(1), a(size)
    SiftDown 1, size - 1
    Show "Root moved to slot" + STR$(size) + ", heap repaired", size - 1
    WaitKey
NEXT
Show "Sorted!  Comparisons:" + STR$(comps) + "   Press a key to quit.", 0
WaitKey
END

' --------------------------------------------------------------
' SiftDown: the node at "start" may be smaller than its children.
' Swap it with the BIGGER child, and keep going down until it is
' bigger than both children or it reaches a leaf.
' Only the first "size" elements count as part of the heap.
' --------------------------------------------------------------
SUB SiftDown (start, size)
    root = start
    DO
        child = root * 2                     ' left child
        IF child > size THEN EXIT DO         ' no children: a leaf
        ' pick the bigger of the two children
        IF child + 1 <= size THEN
            comps = comps + 1
            IF a(child + 1) > a(child) THEN child = child + 1
        END IF
        comps = comps + 1
        IF a(root) >= a(child) THEN EXIT DO  ' heap rule holds: done
        SWAP a(root), a(child)
        root = child                         ' follow the value down
    LOOP
END SUB

' Draws the tree and the flat array.  Elements beyond "size" are
' already sorted and are shown in green.
SUB Show (msg$, size)
    CLS
    COLOR 15: PRINT "HEAP SORT": COLOR 7
    PRINT msg$
    FOR i = 1 TO N
        ' draw little connector marks toward the children
        IF 2 * i <= N THEN
            COLOR 8
            LOCATE row(i) + 2, (col(i) + col(2 * i)) \ 2 + 2: PRINT "/";
            LOCATE row(i) + 2, (col(i) + col(2 * i + 1)) \ 2 + 1: PRINT "\";
        END IF
        IF i > size THEN COLOR 10 ELSE COLOR 14
        LOCATE row(i), col(i) + 1: PRINT USING "##"; a(i);
    NEXT
    LOCATE 21, 1: COLOR 7: PRINT "Array: ";
    FOR i = 1 TO N
        IF i > size THEN COLOR 10 ELSE COLOR 14
        PRINT USING "### "; a(i);
    NEXT
    LOCATE 22, 1: COLOR 7: PRINT "Index: ";
    FOR i = 1 TO N: PRINT USING "### "; i; : NEXT
    LOCATE 24, 1: COLOR 8: PRINT "yellow = heap   green = sorted   (any key, Esc quits)";
    COLOR 7
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN CLS : END
END SUB
