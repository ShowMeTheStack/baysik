' ============================================================
' TITLE:    Words to Number
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     parsing, numbers, words, accumulators, lookup
' SUMMARY:  Reads English like "two thousand and twenty-four" and turns it back into 2024.
' ------------------------------------------------------------
' WHAT IT DOES
'   The reverse of "Number to Words".  It understands phrases such
'   as
'       three hundred and forty-five thousand six hundred
'       minus twelve
'       one million two hundred thousand and seven
'       a hundred and one
'   using two running totals:
'     current - the small number being built (0..999)
'     total   - everything already finished by a big multiplier
'   Words like "hundred" multiply "current"; words like "thousand"
'   and "million" multiply current and move it into total.
'
' HOW TO USE
'   Type a number in words and press Enter.  Empty line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Looking a word up in a table to get its value
'   * Accumulator variables and when to "flush" them
'   * Ignoring filler words ("and", "a") and hyphens
'   * Reporting errors for words we do not understand
'
' THINGS TO TRY
'   * Accept ordinals: "twenty-first" -> 21
'   * Accept digits mixed in: "3 million"
'   * Feed the result into Number to Words and check you get the same words
' ============================================================

DEFDBL A-Z
DECLARE FUNCTION WordValue (w$)
DECLARE FUNCTION Parse (s$, ok%)

DIM SHARED nm$(27), nv(27)
FOR i = 0 TO 27: READ nm$(i), nv(i): NEXT i
DATA zero,0, one,1, two,2, three,3, four,4, five,5, six,6, seven,7
DATA eight,8, nine,9, ten,10, eleven,11, twelve,12, thirteen,13
DATA fourteen,14, fifteen,15, sixteen,16, seventeen,17, eighteen,18
DATA nineteen,19, twenty,20, thirty,30, forty,40, fifty,50
DATA sixty,60, seventy,70, eighty,80, ninety,90

CLS
COLOR 14: PRINT "WORDS TO NUMBER": COLOR 7
PRINT
PRINT "Examples:"
DO
    READ ex$
    IF ex$ = "*" THEN EXIT DO
    v = Parse(ex$, ok%)
    PRINT "  "; ex$; " = ";
    COLOR 11: PRINT LTRIM$(STR$(v)): COLOR 7
LOOP
DATA "forty-two", "a hundred and one", "two thousand and twenty-four"
DATA "minus seventeen", "one million two hundred thousand and seven"
DATA "nine hundred ninety-nine billion nine hundred ninety-nine million", "*"

DO
    PRINT
    LINE INPUT "Number in words (Enter = quit): "; s$
    IF s$ = "" OR UCASE$(s$) = "Q" THEN EXIT DO
    v = Parse(s$, ok%)
    IF ok% THEN
        COLOR 11: PRINT "  = "; LTRIM$(STR$(v)): COLOR 7
        PRINT USING "  = ###,###,###,###,###"; v
    END IF
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' WordValue: value of a basic number word, or -1 if unknown.
' ------------------------------------------------------------
FUNCTION WordValue (w$)
    FOR i = 0 TO 27
        IF nm$(i) = w$ THEN WordValue = nv(i): EXIT FUNCTION
    NEXT i
    WordValue = -1
END FUNCTION

' ------------------------------------------------------------
' Parse: hyphens become spaces, then go word by word.
'   number word -> current = current + value
'   hundred     -> current = current * 100
'   thousand / million / billion
'               -> total = total + current * big ; current = 0
'   and, a      -> ignored ("a hundred" works because current 0
'                  times 100 is fixed up to 100)
' At the end the answer is total + current.
' ok% is set to 0 and a message printed on any unknown word.
' ------------------------------------------------------------
FUNCTION Parse (s$, ok%)
    t$ = LCASE$(s$) + " "
    FOR i = 1 TO LEN(t$)
        IF MID$(t$, i, 1) = "-" OR MID$(t$, i, 1) = "," THEN MID$(t$, i, 1) = " "
    NEXT i
    total = 0: current = 0: sign = 1: ok% = -1: w$ = ""
    FOR i = 1 TO LEN(t$)
        c$ = MID$(t$, i, 1)
        IF c$ <> " " THEN
            w$ = w$ + c$
        ELSEIF w$ <> "" THEN
            SELECT CASE w$
                CASE "and", "a", "an"
                    ' filler words: nothing to do
                CASE "minus", "negative"
                    sign = -1
                CASE "hundred"
                    IF current = 0 THEN current = 1     ' "a hundred"
                    current = current * 100
                CASE "thousand", "million", "billion"
                    IF current = 0 THEN current = 1     ' "a thousand"
                    IF w$ = "thousand" THEN big = 1000
                    IF w$ = "million" THEN big = 1000000
                    IF w$ = "billion" THEN big = 1000000000
                    total = total + current * big
                    current = 0
                CASE ELSE
                    v = WordValue(w$)
                    IF v < 0 THEN
                        COLOR 12: PRINT "  Sorry, I don't know the word '"; w$; "'.": COLOR 7
                        ok% = 0
                        Parse = 0: EXIT FUNCTION
                    END IF
                    current = current + v
            END SELECT
            w$ = ""
        END IF
    NEXT i
    Parse = sign * (total + current)
END FUNCTION
