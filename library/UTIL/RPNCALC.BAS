' ============================================================
' TITLE:    RPN Stack Calculator
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     stack, rpn, parsing, arrays, strings
' SUMMARY:  A Reverse Polish Notation calculator like the classic HP models, with a visible stack.
' ------------------------------------------------------------
' WHAT IT DOES
'   In Reverse Polish Notation (RPN) you type the numbers FIRST
'   and the operator AFTER.  "3 4 +" means 3 + 4.  Every number
'   is pushed onto a STACK; every operator pops its inputs off
'   the stack and pushes the answer back.  No brackets needed:
'   (2 + 3) * 4  becomes  2 3 + 4 *
'
'   You can type a whole line of tokens separated by spaces, and
'   the program shows the stack after each line.
'
' HOW TO USE
'   Type tokens separated by spaces and press Enter, e.g.
'       5 1 2 + 4 * + 3 -        (answer 14)
'   Operators:  + - * / ^   SQRT  NEG  INV (1/x)
'   Stack ops:  DUP (copy top)  SWAP  DROP  CLEAR
'   Type Q (or an empty line) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * The stack data structure (push / pop) using an array
'   * Splitting a line into tokens with INSTR and MID$
'   * VAL to turn text into a number, and spotting non-numbers
'   * Why RPN needs no parentheses
'
' THINGS TO TRY
'   * Add SIN, COS and PI tokens.
'   * Add a ROLL command that rotates the top three items.
'   * Let the user store values in named variables (STO A / RCL A).
' ============================================================

DECLARE SUB Push (x#)
DECLARE FUNCTION Pop# ()
DECLARE SUB DoToken (t$)

' The stack lives in a shared array.  sp is the "stack pointer":
' how many items are on the stack right now.
CONST MAXSTACK = 20
DIM SHARED stack#(1 TO MAXSTACK)
DIM SHARED sp, errMsg$

CLS
PRINT "RPN CALCULATOR  -  type tokens like:  2 3 + 4 *"
PRINT "Ops: + - * / ^ SQRT NEG INV  DUP SWAP DROP CLEAR   Q = quit"
PRINT STRING$(70, "-")

DO
    LINE INPUT "> "; ln$
    ln$ = UCASE$(LTRIM$(RTRIM$(ln$)))
    IF ln$ = "" OR ln$ = "Q" THEN EXIT DO

    ' ---- Split the line into tokens at each space ----
    ' We add a space on the end so the last token is found too.
    ln$ = ln$ + " "
    errMsg$ = ""
    DO WHILE LEN(ln$) > 0 AND errMsg$ = ""
        p = INSTR(ln$, " ")
        tok$ = LEFT$(ln$, p - 1)          ' text before the space
        ln$ = LTRIM$(MID$(ln$, p + 1))    ' the rest of the line
        IF tok$ <> "" THEN DoToken tok$
    LOOP
    IF errMsg$ <> "" THEN PRINT "  ! "; errMsg$

    ' ---- Show the stack, top item last (nearest the prompt) ----
    IF sp = 0 THEN
        PRINT "  (stack empty)"
    ELSE
        FOR i = 1 TO sp
            PRINT USING "  ##: "; sp - i + 1;
            PRINT stack#(i)
        NEXT i
    END IF
LOOP
PRINT "Bye."
END

' Carry out ONE token: either a number to push or an operator.
SUB DoToken (t$)
    SELECT CASE t$
        CASE "+", "-", "*", "/", "^"
            ' Binary operators need TWO items.  Note the order: the
            ' top of the stack is the SECOND operand (b), so "8 2 /"
            ' gives 8 / 2 and not 2 / 8.
            IF sp < 2 THEN errMsg$ = "Need 2 numbers for " + t$: EXIT SUB
            b# = Pop#: a# = Pop#
            SELECT CASE t$
                CASE "+": Push a# + b#
                CASE "-": Push a# - b#
                CASE "*": Push a# * b#
                CASE "/"
                    IF b# = 0 THEN errMsg$ = "Divide by zero": Push a#: Push b#: EXIT SUB
                    Push a# / b#
                CASE "^"
                    IF a# < 0 AND b# <> INT(b#) THEN errMsg$ = "Bad power": Push a#: Push b#: EXIT SUB
                    Push a# ^ b#
            END SELECT
        CASE "SQRT", "NEG", "INV", "DUP", "DROP"
            ' These need one item.
            IF sp < 1 THEN errMsg$ = t$ + " needs a number": EXIT SUB
            a# = Pop#
            SELECT CASE t$
                CASE "SQRT"
                    IF a# < 0 THEN errMsg$ = "SQRT of negative": Push a#: EXIT SUB
                    Push SQR(a#)
                CASE "NEG": Push -a#
                CASE "INV"
                    IF a# = 0 THEN errMsg$ = "1/0 is undefined": Push a#: EXIT SUB
                    Push 1 / a#
                CASE "DUP": Push a#: Push a#
                CASE "DROP"          ' already popped: nothing to push back
            END SELECT
        CASE "SWAP"
            IF sp < 2 THEN errMsg$ = "SWAP needs 2 numbers": EXIT SUB
            b# = Pop#: a# = Pop#: Push b#: Push a#
        CASE "CLEAR"
            sp = 0
        CASE ELSE
            ' Is it a number?  VAL("abc") is 0, so we also check the
            ' first character looks numeric before trusting VAL.
            c$ = LEFT$(t$, 1)
            IF INSTR("0123456789.-", c$) = 0 THEN errMsg$ = "Unknown token: " + t$: EXIT SUB
            Push VAL(t$)
    END SELECT
END SUB

' Take the top item off the stack and return it.
FUNCTION Pop#
    Pop# = stack#(sp)
    sp = sp - 1
END FUNCTION

' Put a new item on top of the stack (if there is room).
SUB Push (x#)
    IF sp >= MAXSTACK THEN errMsg$ = "Stack full": EXIT SUB
    sp = sp + 1
    stack#(sp) = x#
END SUB
