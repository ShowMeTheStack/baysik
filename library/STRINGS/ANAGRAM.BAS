' ============================================================
' TITLE:    Anagram Finder
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     anagrams, sorting, signatures, DATA, arrays
' SUMMARY:  Finds every word in a built-in dictionary that uses exactly the same letters as yours.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two words are anagrams when they contain the same letters the
'   same number of times: LISTEN / SILENT / ENLIST.  The trick for
'   finding them quickly is a "signature": sort the letters of a
'   word alphabetically.  LISTEN -> EILNST and SILENT -> EILNST.
'   Words with equal signatures are anagrams of each other!
'
'   The program loads a small dictionary from DATA lines, computes
'   every word's signature once, then shows all anagram groups in
'   the dictionary and lets you look up your own words.
'
' HOW TO USE
'   Type a word and press Enter to see its anagrams.
'   Press Enter on an empty line (or type Q) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Sorting the characters of a string (insertion sort on MID$)
'   * Using a "canonical form" / signature to compare things
'   * Parallel arrays: word$(i) and sig$(i) belong together
'   * Reading a word list from DATA until a sentinel value
'
' THINGS TO TRY
'   * Add your own words to the DATA list (keep "*" last)
'   * Count letters with an array of 26 counters instead of sorting
'   * Find "sub-anagrams": words that can be built from SOME of the letters
' ============================================================

DECLARE FUNCTION Signature$ (w$)

CONST MAXWORDS = 200
DIM word$(MAXWORDS), sig$(MAXWORDS), shown(MAXWORDS)

' ---- Load the dictionary and compute signatures -------------
n = 0
DO
    READ w$
    IF w$ = "*" THEN EXIT DO
    n = n + 1
    word$(n) = UCASE$(w$)
    sig$(n) = Signature$(word$(n))
LOOP

CLS
COLOR 14: PRINT "ANAGRAM FINDER": COLOR 7
PRINT "Dictionary holds"; n; "words."
PRINT
PRINT "Anagram groups found in the dictionary:"

' ---- Show every group of 2+ words sharing a signature -------
' shown(i) remembers words already printed so each group
' appears only once.
FOR i = 1 TO n
    IF shown(i) = 0 THEN
        grp$ = word$(i)
        cnt = 1
        FOR j = i + 1 TO n
            IF sig$(j) = sig$(i) THEN
                grp$ = grp$ + " " + word$(j)
                cnt = cnt + 1
                shown(j) = 1
            END IF
        NEXT j
        IF cnt > 1 THEN PRINT "  "; sig$(i); " : "; grp$
    END IF
NEXT i
PRINT

' ---- Interactive lookup ------------------------------------
DO
    LINE INPUT "Word to look up (Enter = quit): "; w$
    w$ = UCASE$(LTRIM$(RTRIM$(w$)))
    IF w$ = "" OR w$ = "Q" THEN EXIT DO
    s$ = Signature$(w$)
    PRINT "  Signature: "; s$
    found = 0
    FOR i = 1 TO n
        ' same signature but not the very same word
        IF sig$(i) = s$ AND word$(i) <> w$ THEN
            IF found = 0 THEN PRINT "  Anagrams:";
            PRINT " "; word$(i);
            found = found + 1
        END IF
    NEXT i
    IF found = 0 THEN PRINT "  No anagrams in my dictionary." ELSE PRINT
    PRINT
LOOP
PRINT "Goodbye!"
END

' A small dictionary rich in anagram families.
DATA listen, silent, enlist, tinsel, inlets
DATA stop, pots, tops, spot, opts, post
DATA evil, vile, live, veil
DATA angel, glean, angle
DATA heart, earth, hater
DATA night, thing
DATA dusty, study
DATA state, taste, teats
DATA least, steal, tales, slate, stale
DATA below, elbow, bowel
DATA cat, act, tac
DATA dog, god
DATA race, care, acre
DATA lemon, melon
DATA peach, cheap
DATA arc, car
DATA basic, cabin, binary, brainy
DATA apple, orange, banana, computer, *

' ------------------------------------------------------------
' Signature$: returns the letters of w$ sorted A..Z, ignoring
' anything that is not a letter.
' Insertion sort: take each letter and slide it left past every
' bigger letter already in the result.  Fine for short words.
' ------------------------------------------------------------
FUNCTION Signature$ (w$)
    s$ = ""
    FOR i = 1 TO LEN(w$)
        ch$ = UCASE$(MID$(w$, i, 1))
        IF ch$ >= "A" AND ch$ <= "Z" THEN
            ' find where ch$ belongs in the already-sorted s$
            p = 1
            DO WHILE p <= LEN(s$)
                IF MID$(s$, p, 1) > ch$ THEN EXIT DO
                p = p + 1
            LOOP
            s$ = LEFT$(s$, p - 1) + ch$ + MID$(s$, p)
        END IF
    NEXT i
    Signature$ = s$
END FUNCTION
