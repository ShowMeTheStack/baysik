' ============================================================
' TITLE:    Calculator with Memory
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     calculator, input, select case, variables, menu
' SUMMARY:  A four-function desk calculator with M+, M-, MR and MC memory keys, just like a real one.
' ------------------------------------------------------------
' WHAT IT DOES
'   Works like a pocket calculator.  There is always a "current
'   value" on the display.  You pick an operation (+ - * / and a
'   few extras), type a number, and the display updates.  A
'   separate MEMORY register lets you store a running total and
'   recall it later, exactly like the M+ / M- / MR / MC buttons.
'
' HOW TO USE
'   Press one key to choose what to do:
'     + - * /   apply that operation (you are asked for a number)
'     ^         raise the display to a power
'     S         square root of the display
'     N         negate (change sign)
'     E         enter a brand new number on the display
'     C         clear the display to 0
'     P         M+  add display to memory
'     M         M-  subtract display from memory
'     R         MR  recall memory onto the display
'     X         MC  clear memory
'     Q or Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Keeping "state" in variables (display and memory)
'   * INKEY$ for one-key commands, INPUT for numbers
'   * SELECT CASE to pick an action
'   * Guarding against errors (divide by zero, sqrt of negative)
'
' THINGS TO TRY
'   * Add a % key that works out display% of a number.
'   * Keep a "tape" of the last 10 operations and show it.
'   * Add a second memory register (M2).
' ============================================================

' disp# is the number on the calculator "screen", mem# is the memory.
' The # suffix makes them DOUBLE precision (about 15 digits).
disp# = 0
mem# = 0
msg$ = "Ready."

DO
    ' ---- Draw the calculator face every time round the loop ----
    CLS
    COLOR 14, 1
    PRINT SPACE$(80);
    LOCATE 1, 30: PRINT "CALCULATOR WITH MEMORY"
    COLOR 7, 0
    LOCATE 3, 10: PRINT "+--------------------------------+"
    LOCATE 4, 10: PRINT "|                                |"
    LOCATE 5, 10: PRINT "+--------------------------------+"
    ' Show the display right-aligned inside the box, like a real LCD.
    ' STR$ turns the number into text; we pad it on the left.
    d$ = STR$(disp#)
    COLOR 10, 0
    LOCATE 4, 42 - LEN(d$): PRINT d$
    COLOR 7, 0
    ' A little "M" appears when memory is not zero.
    IF mem# <> 0 THEN LOCATE 4, 12: COLOR 12: PRINT "M": COLOR 7
    LOCATE 6, 10: PRINT "Memory:"; mem#

    LOCATE 8, 10: PRINT "[+] [-] [*] [/] [^]   operations"
    LOCATE 9, 10: PRINT "[S]qrt  [N]egate  [E]nter  [C]lear"
    LOCATE 10, 10: PRINT "[P] M+  [M] M-  [R] MR  [X] MC"
    LOCATE 11, 10: PRINT "[Q] or Esc to quit"
    LOCATE 13, 10: COLOR 11: PRINT msg$: COLOR 7

    ' ---- Wait for a single key ----
    ' INKEY$ returns "" until a key is pressed, so we loop.
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""

    msg$ = ""
    SELECT CASE k$
        CASE "+", "-", "*", "/", "^"
            LOCATE 15, 10: INPUT "Number: ", n#
            ' Do the chosen operation on the display.
            SELECT CASE k$
                CASE "+": disp# = disp# + n#
                CASE "-": disp# = disp# - n#
                CASE "*": disp# = disp# * n#
                CASE "/"
                    ' Dividing by zero would crash, so we check first.
                    IF n# = 0 THEN msg$ = "Error: cannot divide by zero" ELSE disp# = disp# / n#
                CASE "^"
                    ' A negative number to a fractional power is not a
                    ' real number (e.g. (-8)^0.5), so refuse that case.
                    IF disp# < 0 AND n# <> INT(n#) THEN
                        msg$ = "Error: negative base needs a whole power"
                    ELSE
                        disp# = disp# ^ n#
                    END IF
            END SELECT
            IF msg$ = "" THEN msg$ = "Done: " + k$ + STR$(n#)
        CASE "S"
            IF disp# < 0 THEN msg$ = "Error: no square root of a negative" ELSE disp# = SQR(disp#): msg$ = "Square root taken"
        CASE "N": disp# = -disp#: msg$ = "Sign changed"
        CASE "E"
            LOCATE 15, 10: INPUT "New value: ", disp#
            msg$ = "Value entered"
        CASE "C": disp# = 0: msg$ = "Display cleared"
        ' ---- Memory keys ----
        CASE "P": mem# = mem# + disp#: msg$ = "Added to memory"
        CASE "M": mem# = mem# - disp#: msg$ = "Subtracted from memory"
        CASE "R": disp# = mem#: msg$ = "Memory recalled"
        CASE "X": mem# = 0: msg$ = "Memory cleared"
        CASE "Q", CHR$(27): EXIT DO      ' CHR$(27) is the Esc key
        CASE ELSE: msg$ = "Unknown key - see the list above"
    END SELECT
LOOP

CLS
PRINT "Final display:"; disp#
PRINT "Goodbye!"
END
