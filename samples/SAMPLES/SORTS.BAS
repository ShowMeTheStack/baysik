' SORTS.BAS - Watch bubble sort and selection sort work, bar by bar
' Tip: change the speed with the toolbar Speed menu, or try "Animate execution".
DECLARE SUB DrawBar (i%)
DECLARE SUB Shuffle ()
DEFINT A-Z
CONST N = 64
DIM SHARED a(1 TO N)
SCREEN 13
Shuffle
LOCATE 1, 1: PRINT "Bubble sort"
FOR i = N TO 2 STEP -1
    FOR j = 1 TO i - 1
        IF a(j) > a(j + 1) THEN SWAP a(j), a(j + 1): DrawBar j: DrawBar j + 1
    NEXT
NEXT
SLEEP 1
Shuffle
LOCATE 1, 1: PRINT "Selection sort"
FOR i = 1 TO N - 1
    m = i
    FOR j = i + 1 TO N: IF a(j) < a(m) THEN m = j
    NEXT
    SWAP a(i), a(m): DrawBar i: DrawBar m
    FOR d = 1 TO 2000: NEXT
NEXT
LOCATE 1, 1: PRINT "Sorted! Press a key."
SLEEP

SUB DrawBar (i)
    x = (i - 1) * 5
    LINE (x, 20)-(x + 3, 199), 0, BF
    LINE (x, 199 - a(i) * 2.7)-(x + 3, 199), 32 + a(i) MOD 72, BF
END SUB

SUB Shuffle
    RANDOMIZE TIMER
    FOR i = 1 TO N: a(i) = i: NEXT
    FOR i = N TO 2 STEP -1: SWAP a(i), a(INT(RND * i) + 1): NEXT
    CLS
    FOR i = 1 TO N: DrawBar i: NEXT
END SUB
