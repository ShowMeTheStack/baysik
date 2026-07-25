' ============================================================
' TITLE:    String Padding Library
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     FUNCTION, padding, centering, alignment, tables, reusable code
' SUMMARY:  A toolbox of reusable string FUNCTIONs - pad, centre, repeat, trim, truncate - with a table demo.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows how to build your OWN library of handy string functions
'   that you can copy into any program:
'     PadRight$(s$, w)    "cat" -> "cat   "      (left aligned)
'     PadLeft$(s$, w)     "cat" -> "   cat"      (right aligned)
'     Center$(s$, w)      "cat" -> " cat  "
'     PadNum$(n, w)       7     -> "007"         (leading zeros)
'     Repeat$(s$, n)      "ab",3 -> "ababab"     (STRING$ only does 1 char)
'     Truncate$(s$, w)    "elephant",6 -> "ele..."
'     Trim$(s$)           "  hi  " -> "hi"
'     Dots$(a$, b$, w)    "Tea", "1.50" -> "Tea.........1.50"
'   Then it uses them together to print a neat price list in a box.
'
' HOW TO USE
'   Just run it and read the output.  Press a key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Writing FUNCTIONs with parameters and string results
'   * SPACE$, STRING$, LEFT$, RIGHT$, LTRIM$, RTRIM$, STR$
'   * Why every function must handle "too long" input sensibly
'   * Box-drawing characters from code page 437
'
' THINGS TO TRY
'   * Add a Wrap$ that inserts line breaks
'   * Write PadMoney$ that always shows two decimals
'   * Use these functions in your own programs!
' ============================================================

DECLARE FUNCTION PadRight$ (s$, w)
DECLARE FUNCTION PadLeft$ (s$, w)
DECLARE FUNCTION Center$ (s$, w)
DECLARE FUNCTION PadNum$ (n, w)
DECLARE FUNCTION Repeat$ (s$, n)
DECLARE FUNCTION Truncate$ (s$, w)
DECLARE FUNCTION Trim$ (s$)
DECLARE FUNCTION Dots$ (a$, b$, w)

CLS
COLOR 14: PRINT Center$("STRING PADDING LIBRARY", 78): COLOR 7
PRINT
' ---- quick tour: brackets show exactly where the spaces are ----
' BASIC has no escape code for a quote mark inside a string, so we
' keep one in q$ (CHR$(34) is the ASCII code of ") and glue it in.
q$ = CHR$(34)
PRINT "PadRight$(" + q$ + "cat" + q$ + ", 8)      = ["; PadRight$("cat", 8); "]"
PRINT "PadLeft$(" + q$ + "cat" + q$ + ", 8)       = ["; PadLeft$("cat", 8); "]"
PRINT "Center$(" + q$ + "cat" + q$ + ", 8)        = ["; Center$("cat", 8); "]"
PRINT "PadNum$(7, 3)            = ["; PadNum$(7, 3); "]"
PRINT "Repeat$(" + q$ + "ab" + q$ + ", 3)         = ["; Repeat$("ab", 3); "]"
PRINT "Truncate$(" + q$ + "elephant" + q$ + ", 6) = ["; Truncate$("elephant", 6); "]"
PRINT "Trim$(" + q$ + "   hi   " + q$ + ")        = ["; Trim$("   hi   "); "]"
PRINT "Dots$(" + q$ + "Tea" + q$ + ", " + q$ + "1.50" + q$ + ", 16) = ["; Dots$("Tea", "1.50", 16); "]"
PRINT

' ---- the price list: the functions working together ----
W = 40                                   ' inner width of the box
LOCATE , 20: PRINT CHR$(201); STRING$(W, 205); CHR$(187)
LOCATE , 20: PRINT CHR$(186); : COLOR 15: PRINT Center$("CAFE BASIC MENU", W); : COLOR 7: PRINT CHR$(186)
LOCATE , 20: PRINT CHR$(199); STRING$(W, 196); CHR$(182)
RESTORE Menu
FOR i = 1 TO 6
    READ item$, price
    pr$ = "$" + Trim$(STR$(INT(price))) + "." + PadNum$(INT(price * 100 + .5) MOD 100, 2)
    row$ = PadNum$(i, 2) + "  " + Dots$(Truncate$(item$, 22), pr$, W - 6)
    LOCATE , 20: PRINT CHR$(186); " "; row$; " "; CHR$(186)
NEXT i
LOCATE , 20: PRINT CHR$(199); STRING$(W, 196); CHR$(182)
LOCATE , 20: PRINT CHR$(186); PadLeft$("prices include tax ", W); CHR$(186)
LOCATE , 20: PRINT CHR$(200); STRING$(W, 205); CHR$(188)
PRINT Repeat$("-=", 39)
PRINT "Press any key to quit...";
DO: LOOP WHILE INKEY$ = ""
END

Menu:
DATA "Coffee", 2.5, "Tea", 1.75, "Hot chocolate with whipped cream", 3.2
DATA "Bagel", 2, "Fruit salad", 4.05, "Cake of the day", 3.99

' --- PadRight$: add spaces on the right up to width w ---------
' If s$ is already wider than w we cut it, so columns never break.
FUNCTION PadRight$ (s$, w)
    IF LEN(s$) >= w THEN PadRight$ = LEFT$(s$, w) ELSE PadRight$ = s$ + SPACE$(w - LEN(s$))
END FUNCTION

' --- PadLeft$: add spaces on the left (right-aligns numbers) --
FUNCTION PadLeft$ (s$, w)
    IF LEN(s$) >= w THEN PadLeft$ = RIGHT$(s$, w) ELSE PadLeft$ = SPACE$(w - LEN(s$)) + s$
END FUNCTION

' --- Center$: half the spare room goes left, the rest right ---
' With an odd amount of spare room, the extra space goes right.
FUNCTION Center$ (s$, w)
    IF LEN(s$) >= w THEN Center$ = LEFT$(s$, w): EXIT FUNCTION
    spare = w - LEN(s$)
    lft = spare \ 2
    Center$ = SPACE$(lft) + s$ + SPACE$(spare - lft)
END FUNCTION

' --- PadNum$: whole number with leading zeros ----------------
' STR$ puts a space in front of positive numbers - LTRIM$ removes it.
FUNCTION PadNum$ (n, w)
    s$ = LTRIM$(STR$(INT(n)))
    IF LEN(s$) < w THEN s$ = STRING$(w - LEN(s$), "0") + s$
    PadNum$ = s$
END FUNCTION

' --- Repeat$: like STRING$ but for whole strings -------------
FUNCTION Repeat$ (s$, n)
    r$ = ""
    FOR i = 1 TO n: r$ = r$ + s$: NEXT i
    Repeat$ = r$
END FUNCTION

' --- Truncate$: cut long text and show "..." -----------------
FUNCTION Truncate$ (s$, w)
    IF LEN(s$) <= w THEN
        Truncate$ = s$
    ELSEIF w <= 3 THEN
        Truncate$ = LEFT$(s$, w)
    ELSE
        Truncate$ = LEFT$(s$, w - 3) + "..."
    END IF
END FUNCTION

' --- Trim$: remove spaces from both ends ---------------------
FUNCTION Trim$ (s$)
    Trim$ = LTRIM$(RTRIM$(s$))
END FUNCTION

' --- Dots$: left text, dot leader, right text, exactly w wide -
FUNCTION Dots$ (a$, b$, w)
    gap = w - LEN(a$) - LEN(b$)
    IF gap < 1 THEN gap = 1
    Dots$ = a$ + STRING$(gap, ".") + b$
END FUNCTION
