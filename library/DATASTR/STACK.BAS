' ============================================================
' TITLE:    Stack of Plates
' CATEGORY: Data Structures
' LEVEL:    Beginner
' TAGS:     stack, arrays, LIFO, push, pop
' SUMMARY:  Push and pop numbers on an array-based stack and watch the pile grow and shrink.
' ------------------------------------------------------------
' WHAT IT DOES
'   A STACK is like a pile of plates: you can only put a plate on
'   the top (PUSH) or take the top plate off (POP). The last thing
'   you put in is the first thing that comes out - "LIFO", Last In
'   First Out. This program keeps the stack in an ordinary array
'   and draws it on screen as a tower of boxes after every action.
'
' HOW TO USE
'   P = push a number (you will be asked to type it)
'   O = pop the top number off
'   K = peek: look at the top without removing it
'   C = clear the whole stack
'   Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Using an array plus a "top" counter as a stack
'   * Overflow (pushing onto a full stack) and underflow
'     (popping an empty stack) and how to guard against them
'   * SUBs and FUNCTIONs that share data with DIM SHARED
'   * Drawing simple text graphics with LOCATE and STRING$
'
' THINGS TO TRY
'   * Change MAXSIZE to make a taller or shorter stack
'   * Add a "D" command that duplicates the top item
'   * Add an "S" command that swaps the top two items
' ============================================================

DECLARE SUB Push (v AS INTEGER)
DECLARE FUNCTION Pop% ()
DECLARE SUB DrawStack ()
DECLARE SUB Msg (t$)

' ---- The stack itself -------------------------------------
' MAXSIZE is how many plates fit. items() holds the values.
' sp ("stack pointer") counts how many items are on the stack.
' When sp = 0 the stack is empty; items(sp) is always the top.
CONST MAXSIZE = 10
DIM SHARED items(1 TO MAXSIZE) AS INTEGER
DIM SHARED sp AS INTEGER

sp = 0
CLS
DrawStack
Msg "Welcome! Press P to push, O to pop."

' ---- Main loop: read one key at a time ---------------------
DO
    k$ = UCASE$(INKEY$)          ' INKEY$ returns "" if no key waiting
    SELECT CASE k$
        CASE "P"
            IF sp = MAXSIZE THEN
                ' Guard against OVERFLOW: no room for another plate.
                Msg "Stack overflow! The stack is full."
            ELSE
                LOCATE 22, 1: PRINT SPACE$(79);
                LOCATE 22, 1: INPUT "Number to push"; v$
                ' VAL turns text into a number; bad text becomes 0.
                Push VAL(v$)
                Msg "Pushed" + STR$(VAL(v$))
            END IF
        CASE "O"
            IF sp = 0 THEN
                ' Guard against UNDERFLOW: nothing to take off.
                Msg "Stack underflow! The stack is empty."
            ELSE
                v = Pop%
                Msg "Popped" + STR$(v)
            END IF
        CASE "K"
            IF sp = 0 THEN
                Msg "Nothing to peek at - stack is empty."
            ELSE
                ' Peeking just reads items(sp) without changing sp.
                Msg "Top of stack is" + STR$(items(sp))
            END IF
        CASE "C"
            sp = 0          ' resetting the counter "forgets" everything
            Msg "Stack cleared."
        CASE "Q", CHR$(27)
            EXIT DO
    END SELECT
    IF k$ <> "" THEN DrawStack
LOOP

CLS
PRINT "Goodbye! Remember: Last In, First Out."
END

' ------------------------------------------------------------
' DrawStack: shows the array as a tower of boxes.
' Row 3 is the top slot (MAXSIZE) and lower rows hold lower slots,
' so the picture looks like a real pile growing upward.
' ------------------------------------------------------------
SUB DrawStack
    LOCATE 1, 1
    PRINT "  STACK OF PLATES   (P)ush  P(O)p  (K)Peek  (C)lear  (Q)uit"
    FOR slot = MAXSIZE TO 1 STEP -1
        row = 3 + (MAXSIZE - slot) * 1
        LOCATE row, 10
        IF slot <= sp THEN
            ' A filled slot: draw the value inside a "plate".
            PRINT USING "[######]"; items(slot);
        ELSE
            PRINT "[      ]";            ' empty slot
        END IF
        ' Point an arrow at the current top.
        IF slot = sp THEN PRINT " <-- top (sp ="; sp; ")   " ELSE PRINT SPACE$(20)
    NEXT slot
    LOCATE 4 + MAXSIZE, 9: PRINT STRING$(10, "=")   ' the table
    LOCATE 5 + MAXSIZE, 10: PRINT "Items:"; sp; "of"; MAXSIZE; "  "
END SUB

' Msg prints a status line near the bottom of the screen.
SUB Msg (t$)
    LOCATE 20, 1: PRINT SPACE$(79);
    LOCATE 20, 1: PRINT t$;
    LOCATE 22, 1: PRINT SPACE$(79);
END SUB

' Pop: hand back the top item and shrink the stack by one.
' The caller must check sp > 0 first.
FUNCTION Pop%
    Pop% = items(sp)
    sp = sp - 1
END FUNCTION

' Push: grow the stack by one and store the value on top.
SUB Push (v AS INTEGER)
    sp = sp + 1
    items(sp) = v
END SUB
