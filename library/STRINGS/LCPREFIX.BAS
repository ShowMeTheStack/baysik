' ============================================================
' TITLE:    Longest Common Prefix & Suffix
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     prefix, suffix, comparison, autocomplete, LEFT$, RIGHT$
' SUMMARY:  Finds the longest beginning (and ending) shared by a group of words - the trick behind Tab completion.
' ------------------------------------------------------------
' WHAT IT DOES
'   Given several words, finds the longest PREFIX they all start
'   with, and the longest SUFFIX they all end with:
'      INTERNET, INTERVAL, INTERNAL, INTERFACE  -> prefix "INTER"
'      WALKING, TALKING, SINGING                -> suffix "ING"
'   Command lines use the common prefix for Tab completion: type
'   "PR", press Tab, and the computer fills in as much as it can.
'   The second half of the program is a small Tab-completion demo
'   over a list of BASIC keywords.
'
' HOW TO USE
'   Part 1 shows examples.  In part 2 type the start of a BASIC
'   keyword and press Enter to "complete" it.  Empty line quits.
'
' CONCEPTS YOU WILL LEARN
'   * Comparing strings column by column with MID$
'   * Shrinking a candidate prefix until it fits every word
'   * Reusing a function: suffix = reversed prefix of reversed words
'
' THINGS TO TRY
'   * Find the longest common SUBSTRING (anywhere, not just the start)
'   * Add more keywords to the completion list
' ============================================================

DECLARE SUB CommonPrefix (list$(), n, result$)
DECLARE FUNCTION Rev$ (s$)

DIM w$(40), r$(40)

CLS
COLOR 14: PRINT "LONGEST COMMON PREFIX & SUFFIX": COLOR 7
PRINT
' ---- Part 1: groups of words in DATA, each ending with "/" ----
FOR g = 1 TO 4
    n = 0
    DO
        READ a$
        IF a$ = "/" THEN EXIT DO
        n = n + 1: w$(n) = a$
        r$(n) = Rev$(a$)                 ' reversed copy for suffixes
    LOOP
    FOR i = 1 TO n: PRINT w$(i); " "; : NEXT i
    PRINT
    CommonPrefix w$(), n, p$
    CommonPrefix r$(), n, s$              ' prefix of the REVERSED words...
    s$ = Rev$(s$)                         ' ...reversed back = the suffix!
    COLOR 10: PRINT "   prefix: ["; p$; "]";
    COLOR 11: PRINT "   suffix: ["; s$; "]": COLOR 7
NEXT g
DATA INTERNET,INTERVAL,INTERNAL,INTERFACE,/
DATA WALKING,TALKING,SINGING,/
DATA FLOWER,FLOW,FLIGHT,/
DATA DOG,CAT,BIRD,/

' ---- Part 2: tab completion over BASIC keywords ----
nk = 0
DO
    READ a$
    IF a$ = "*" THEN EXIT DO
    nk = nk + 1: w$(nk) = a$
LOOP
DATA PRINT,PRESET,PSET,PAINT,PALETTE,PLAY,POKE,PEEK,POS,INPUT,INKEY$
DATA INSTR,INT,INTEGER,LEFT$,LEN,LET,LINE,LOCATE,LOOP,LCASE$,*

PRINT
PRINT "Tab-completion demo.  Keywords:";
FOR i = 1 TO nk: PRINT " "; w$(i); : NEXT i
PRINT
DO
    PRINT
    LINE INPUT "Start typing a keyword (Enter = quit): "; t$
    t$ = UCASE$(t$)
    IF t$ = "" THEN EXIT DO
    ' collect the keywords that start with what was typed
    m = 0
    FOR i = 1 TO nk
        IF LEFT$(w$(i), LEN(t$)) = t$ THEN m = m + 1: r$(m) = w$(i)
    NEXT i
    IF m = 0 THEN
        PRINT "  No keyword starts with "; t$
    ELSE
        CommonPrefix r$(), m, c$
        PRINT "  Completes to: ";
        COLOR 15: PRINT t$; : COLOR 10: PRINT MID$(c$, LEN(t$) + 1): COLOR 7
        IF m > 1 THEN
            PRINT "  Still"; m; "choices:";
            FOR i = 1 TO m: PRINT " "; r$(i); : NEXT i
            PRINT
        ELSE
            PRINT "  Unique match!"
        END IF
    END IF
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' CommonPrefix: (a SUB that hands back its answer in result$)
' Start by assuming the whole first word is the
' prefix.  For every other word, chop letters off the end of the
' candidate until the word starts with it.  What survives is
' shared by all the words.
' ------------------------------------------------------------
SUB CommonPrefix (list$(), n, result$)
    result$ = ""
    IF n = 0 THEN EXIT SUB
    p$ = list$(1)
    FOR i = 2 TO n
        DO WHILE LEFT$(list$(i), LEN(p$)) <> p$
            p$ = LEFT$(p$, LEN(p$) - 1)       ' shorten by one letter
        LOOP
        IF p$ = "" THEN EXIT FOR              ' nothing in common at all
    NEXT i
    result$ = p$
END SUB

FUNCTION Rev$ (s$)
    r$ = ""
    FOR i = LEN(s$) TO 1 STEP -1: r$ = r$ + MID$(s$, i, 1): NEXT i
    Rev$ = r$
END FUNCTION
