' ============================================================
' TITLE:    Growing Arrays with REDIM PRESERVE
' CATEGORY: Data Structures
' LEVEL:    Beginner
' TAGS:     dynamic array, REDIM PRESERVE, capacity, amortized growth, UBOUND
' SUMMARY:  A list that grows as you add items, using REDIM PRESERVE - and why doubling the size beats growing by one.
' ------------------------------------------------------------
' WHAT IT DOES
'   A normal DIM array has a fixed size. But often you don't know
'   how many items you'll get! REDIM PRESERVE makes an array bigger
'   while KEEPING what's already inside.
'
'   Behind the scenes, growing means making a new, bigger block
'   of memory and copying every old item over. So we keep two
'   numbers:
'       size     = how many items are really in use
'       capacity = how big the array actually is (UBOUND)
'   When size reaches capacity we grow. Growing by ONE each time
'   means copying again and again; DOUBLING means copying rarely.
'
'   Part 1 races the two strategies. Part 2 is a shopping list you
'   can add to and remove from, with a bar showing size vs capacity.
'
' HOW TO USE
'   Part 1 runs by itself; press a key. In part 2 type an item to
'   add it, "-3" to remove item 3, or just Enter to quit.
'
' CONCEPTS YOU WILL LEARN
'   * REDIM PRESERVE and UBOUND
'   * Size versus capacity
'   * Removing from the middle by shifting items left
'   * Why "double when full" makes adding cheap on average
'
' THINGS TO TRY
'   * Grow by 1.5x instead of 2x
'   * Shrink the array (to half) when it becomes less than 1/4 full
' ============================================================

DEFINT A-Z

' ---- Part 1: grow-by-one versus doubling ---------------------
CLS
PRINT "PART 1: adding 1000 numbers to a growing array"
PRINT
FOR strategy = 1 TO 2
    REDIM a(1 TO 1)                ' REDIM makes a DYNAMIC array
    size = 0: grows = 0: copies& = 0
    FOR i = 1 TO 1000
        IF size = UBOUND(a) THEN
            ' Full! Work out the new capacity.
            IF strategy = 1 THEN newCap = UBOUND(a) + 1 ELSE newCap = UBOUND(a) * 2
            copies& = copies& + size      ' every old item is copied
            REDIM PRESERVE a(1 TO newCap)
            grows = grows + 1
        END IF
        size = size + 1
        a(size) = i
    NEXT i
    IF strategy = 1 THEN PRINT "Grow by one:"; ELSE PRINT "Doubling:   ";
    PRINT USING " ####  resizes, #######  items copied, capacity ####"; grows; copies&; UBOUND(a)
NEXT strategy
PRINT
PRINT "Doubling wastes a little space (capacity > size) but saves a"
PRINT "huge amount of copying. On average each add costs about one copy."
PRINT
PRINT "Press a key for part 2..."
k$ = INPUT$(1)

' ---- Part 2: a growing shopping list --------------------------
REDIM item$(1 TO 2)
size = 0
msg$ = "Type something to add it."
DO
    CLS
    PRINT "PART 2: SHOPPING LIST    (size ="; size; " capacity ="; UBOUND(item$); ")"
    ' A bar: # = used slot, . = spare capacity
    PRINT "[";
    FOR i = 1 TO UBOUND(item$)
        IF i <= size THEN PRINT "#"; ELSE PRINT ".";
        IF i >= 64 THEN PRINT "...";: EXIT FOR
    NEXT i
    PRINT "]"
    PRINT
    FOR i = 1 TO size
        PRINT USING "##. &"; i; item$(i)
        IF i = 15 AND size > 15 THEN PRINT "    ..."; size - 15; "more": EXIT FOR
    NEXT i
    PRINT
    PRINT msg$
    LINE INPUT "Add item / -N to remove / Enter to quit: "; t$
    t$ = LTRIM$(RTRIM$(t$))
    IF t$ = "" OR UCASE$(t$) = "Q" THEN EXIT DO
    IF LEFT$(t$, 1) = "-" THEN
        ' ---- remove item N by shifting the rest left ----
        nRem = VAL(MID$(t$, 2))
        IF nRem < 1 OR nRem > size THEN
            msg$ = "No item number" + STR$(nRem)
        ELSE
            msg$ = "Removed " + item$(nRem)
            FOR i = nRem TO size - 1
                item$(i) = item$(i + 1)
            NEXT i
            item$(size) = ""
            size = size - 1
        END IF
    ELSEIF size >= 500 THEN
        msg$ = "That's a very long list! Remove something first."
    ELSE
        ' ---- add, doubling first if full ----
        IF size = UBOUND(item$) THEN
            REDIM PRESERVE item$(1 TO UBOUND(item$) * 2)
            msg$ = "Array was full - doubled capacity to" + STR$(UBOUND(item$)) + ". "
        ELSE
            msg$ = ""
        END IF
        size = size + 1
        item$(size) = t$
        msg$ = msg$ + "Added " + t$
    END IF
LOOP
PRINT "Final list has"; size; "items in an array of"; UBOUND(item$)
END
