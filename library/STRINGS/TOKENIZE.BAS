' ============================================================
' TITLE:    Tokenizer
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     tokenizer, lexer, parsing, state machine, SELECT CASE
' SUMMARY:  Splits a line into labelled tokens - words, numbers, strings, operators - like a compiler's lexer.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every compiler and interpreter (including the one running this
'   program!) starts by chopping source text into "tokens".  This
'   tokenizer recognises:
'     WORD     letters, digits and _ starting with a letter  (total, x2)
'     NUMBER   digits with an optional decimal point          (3.14)
'     STRING   text inside double quotes                      ("hi there")
'     OPERATOR one or two symbol characters                   (+  <=  <>)
'     PUNCT    brackets, commas, semicolons, colons
'   Spaces are skipped.  Anything else is reported as UNKNOWN.
'   It also shows a simple word splitter that splits on a delimiter
'   of your choice, like SPLIT in other languages.
'
' HOW TO USE
'   Type a line (try: IF score >= 100 THEN PRINT "Win!", x2*3.5)
'   Press Enter on an empty line to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Scanning text with a position pointer that you move yourself
'   * "Maximal munch": grab the longest token you can (<= not < then =)
'   * Storing results in arrays of strings (kind and text)
'   * A delimiter-based SPLIT function filling a SHARED array
'
' THINGS TO TRY
'   * Recognise keywords (IF, THEN, PRINT) as their own token kind
'   * Allow numbers like 1E5 or &HFF
'   * Feed the tokens to the Calculator Parser program
' ============================================================

DECLARE SUB Tokenize (s$)
DECLARE SUB Split (s$, d$)
DECLARE FUNCTION IsLetter% (c$)
DECLARE FUNCTION IsDigit% (c$)

CONST MAXT = 100
DIM SHARED tkind$(MAXT), ttext$(MAXT), ntok
DIM SHARED part$(MAXT), nparts

CLS
COLOR 14: PRINT "TOKENIZER": COLOR 7
PRINT "Example:"
ex$ = "IF score >= 100 THEN PRINT " + CHR$(34) + "Win!" + CHR$(34) + ", x2*3.5"
GOSUB ShowTokens

DO
    PRINT
    LINE INPUT "Line to tokenize (Enter = quit): "; ex$
    IF ex$ = "" THEN EXIT DO
    GOSUB ShowTokens
    LINE INPUT "Delimiter for SPLIT demo (e.g. , or space): "; d$
    IF d$ = "" THEN d$ = " "
    Split ex$, LEFT$(d$, 1)
    PRINT "  Split into"; nparts; "parts:"
    FOR i = 1 TO nparts
        PRINT "   "; i; "["; part$(i); "]"
    NEXT i
LOOP
PRINT "Goodbye!"
END

ShowTokens:
    PRINT "  "; ex$
    Tokenize ex$
    FOR i = 1 TO ntok
        SELECT CASE tkind$(i)
            CASE "WORD": COLOR 11
            CASE "NUMBER": COLOR 10
            CASE "STRING": COLOR 13
            CASE "OPERATOR": COLOR 14
            CASE "UNKNOWN": COLOR 12
            CASE ELSE: COLOR 7
        END SELECT
        PRINT "   "; LEFT$(tkind$(i) + SPACE$(9), 9); ttext$(i)
    NEXT i
    COLOR 7
    PRINT "  ("; LTRIM$(STR$(ntok)); " tokens)"
RETURN

' ------------------------------------------------------------
' Tokenize: p is our "cursor".  At each step look at the
' character under the cursor, decide what kind of token starts
' here, then move p forward past the whole token.
' ------------------------------------------------------------
SUB Tokenize (s$)
    ntok = 0
    p = 1
    L = LEN(s$)
    DO WHILE p <= L AND ntok < MAXT
        c$ = MID$(s$, p, 1)
        start = p
        IF c$ = " " OR c$ = CHR$(9) THEN
            p = p + 1                       ' skip white space
            kind$ = ""
        ELSEIF IsLetter%(c$) THEN
            ' a word: letter followed by letters, digits or _
            DO WHILE p <= L
                c$ = MID$(s$, p, 1)
                IF NOT (IsLetter%(c$) OR IsDigit%(c$) OR c$ = "_") THEN EXIT DO
                p = p + 1
            LOOP
            kind$ = "WORD"
        ELSEIF IsDigit%(c$) OR (c$ = "." AND IsDigit%(MID$(s$, p + 1, 1))) THEN
            ' a number: digits with at most one decimal point
            dots = 0
            DO WHILE p <= L
                c$ = MID$(s$, p, 1)
                IF c$ = "." THEN
                    dots = dots + 1
                    IF dots > 1 THEN EXIT DO
                ELSEIF NOT IsDigit%(c$) THEN
                    EXIT DO
                END IF
                p = p + 1
            LOOP
            kind$ = "NUMBER"
        ELSEIF c$ = CHR$(34) THEN
            ' a string: everything up to the closing quote
            q = INSTR(p + 1, s$, CHR$(34))
            IF q = 0 THEN q = L                ' unterminated: take the rest
            p = q + 1
            kind$ = "STRING"
        ELSEIF INSTR("+-*/^=<>", c$) > 0 THEN
            ' maximal munch: <= >= <> are ONE token, not two
            two$ = MID$(s$, p, 2)
            IF two$ = "<=" OR two$ = ">=" OR two$ = "<>" THEN p = p + 2 ELSE p = p + 1
            kind$ = "OPERATOR"
        ELSEIF INSTR("(),;:", c$) > 0 THEN
            p = p + 1
            kind$ = "PUNCT"
        ELSE
            p = p + 1
            kind$ = "UNKNOWN"
        END IF
        IF kind$ <> "" THEN
            ntok = ntok + 1
            tkind$(ntok) = kind$
            ttext$(ntok) = MID$(s$, start, p - start)
        END IF
    LOOP
END SUB

' ------------------------------------------------------------
' Split: break s$ at every delimiter d$.  Two delimiters in a row
' give an empty part - that is how CSV files and SPLIT in other
' languages behave too (except for spaces, which we merge).
' ------------------------------------------------------------
SUB Split (s$, d$)
    nparts = 0
    p = 1
    DO
        q = INSTR(p, s$, d$)
        IF q = 0 THEN q = LEN(s$) + 1          ' last piece runs to the end
        piece$ = MID$(s$, p, q - p)
        IF NOT (d$ = " " AND piece$ = "") AND nparts < MAXT THEN
            nparts = nparts + 1
            part$(nparts) = piece$
        END IF
        p = q + 1
    LOOP WHILE p <= LEN(s$) + 1 AND q <= LEN(s$)
END SUB

FUNCTION IsLetter% (c$)
    u$ = UCASE$(c$)
    IsLetter% = (u$ >= "A" AND u$ <= "Z")
END FUNCTION

FUNCTION IsDigit% (c$)
    IsDigit% = (c$ >= "0" AND c$ <= "9" AND c$ <> "")
END FUNCTION
