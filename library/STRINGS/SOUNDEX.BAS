' ============================================================
' TITLE:    Soundex Name Matcher
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     soundex, phonetic, hashing, names, genealogy
' SUMMARY:  Encodes names by how they SOUND, so Smith, Smyth and Smithe all match (code S530).
' ------------------------------------------------------------
' WHAT IT DOES
'   Soundex was invented around 1918 to index the US census, so that
'   clerks could find a family even when the name was spelled in
'   different ways.  Every name becomes a letter plus three digits:
'       ROBERT -> R163     RUPERT -> R163     RUBIN -> R150
'   The rules:
'     1. Keep the first letter.
'     2. Replace the other letters with digits:
'          B F P V       -> 1      L       -> 4
'          C G J K Q S X Z -> 2    M N     -> 5
'          D T           -> 3      R       -> 6
'          A E I O U Y H W -> (dropped)
'     3. Adjacent letters with the same digit count once.  H and W
'        do NOT separate them, but vowels DO.
'     4. Pad with zeros / cut to exactly 4 characters.
'   The program encodes a list of names from DATA, groups the ones
'   that sound alike, then lets you search the list by sound.
'
' HOW TO USE
'   Type a name and press Enter to find sound-alikes.
'   Empty line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Lookup strings: MID$("01230120022455012623010202", n, 1)
'   * Remembering the previous code to skip duplicates
'   * "Hashing": many different inputs mapping to the same short key
'
' THINGS TO TRY
'   * Look up "Metaphone", a smarter successor to Soundex
'   * Add your friends' names to the DATA list
' ============================================================

DECLARE FUNCTION Soundex$ (nm$)

CONST MAXN = 60
DIM nm$(MAXN), code$(MAXN), done(MAXN)

n = 0
DO
    READ a$
    IF a$ = "*" THEN EXIT DO
    n = n + 1: nm$(n) = a$: code$(n) = Soundex$(a$)
LOOP

CLS
COLOR 14: PRINT "SOUNDEX NAME MATCHER": COLOR 7
PRINT
PRINT "Names in the list that sound alike:"
FOR i = 1 TO n
    IF done(i) = 0 THEN
        COLOR 11: PRINT "  "; code$(i); "  "; : COLOR 7
        PRINT nm$(i);
        FOR j = i + 1 TO n
            IF code$(j) = code$(i) THEN PRINT ", "; nm$(j); : done(j) = 1
        NEXT j
        PRINT
    END IF
NEXT i

DO
    PRINT
    LINE INPUT "Name to search (Enter = quit): "; q$
    q$ = LTRIM$(RTRIM$(q$))
    IF q$ = "" OR UCASE$(q$) = "Q" THEN EXIT DO
    c$ = Soundex$(q$)
    IF c$ = "" THEN
        PRINT "  Please type a name made of letters."
    ELSE
        PRINT "  Soundex code: "; c$
        found = 0
        FOR i = 1 TO n
            IF code$(i) = c$ THEN
                IF found = 0 THEN PRINT "  Sounds like:";
                PRINT " "; nm$(i);
                found = found + 1
            END IF
        NEXT i
        IF found = 0 THEN PRINT "  No sound-alike names in the list." ELSE PRINT
    END IF
LOOP
PRINT "Goodbye!"
END

DATA Smith, Smyth, Smithe, Schmidt, Johnson, Jonson, Johnsen, Jensen
DATA Robert, Rupert, Rubin, Ashcraft, Ashcroft, Tymczak, Pfister
DATA Lee, Leigh, Li, Thompson, Thomson, Tomson, Catherine, Kathryn
DATA Katherine, Clark, Clarke, Klerk, Miller, Muller, Mueller, Moller
DATA Brown, Braun, Browne, Green, Greene, Gareen, *

' ------------------------------------------------------------
' Soundex$: the 26-character string below holds the digit for
' A, B, C, ... Z in order.  "0" means "dropped" (vowels, Y),
' and H and W get "-" because they are special in rule 3.
'   A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
'   0 1 2 3 0 1 2 - 0 2 2 4 5 5 0 1 2 6 2 3 0 1 - 2 0 2
' ------------------------------------------------------------
FUNCTION Soundex$ (nm$)
    tbl$ = "0123012-02245501262301-202"
    u$ = UCASE$(nm$)
    ' find the first letter (skip spaces, apostrophes ...)
    s$ = "": prev$ = ""
    FOR i = 1 TO LEN(u$)
        ch$ = MID$(u$, i, 1)
        IF ch$ >= "A" AND ch$ <= "Z" THEN
            d$ = MID$(tbl$, ASC(ch$) - 64, 1)
            IF s$ = "" THEN
                s$ = ch$                  ' rule 1: keep the first letter
                prev$ = d$                ' ...but remember its digit
            ELSEIF d$ = "-" THEN
                ' H or W: ignore completely; prev$ stays the same
            ELSEIF d$ = "0" THEN
                prev$ = "0"               ' a vowel separates duplicates
            ELSE
                IF d$ <> prev$ THEN s$ = s$ + d$
                prev$ = d$
            END IF
            IF LEN(s$) = 4 THEN EXIT FOR
        END IF
    NEXT i
    IF s$ <> "" THEN s$ = LEFT$(s$ + "000", 4)   ' rule 4: pad with zeros
    Soundex$ = s$
END FUNCTION
