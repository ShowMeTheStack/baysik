' ============================================================
' TITLE:    Word Counter (Hash Table with Chaining)
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     hash table, chaining, hashing, linked list, word frequency
' SUMMARY:  Counts every word in a poem using a hash table whose buckets are linked lists, and shows the buckets.
' ------------------------------------------------------------
' WHAT IT DOES
'   A HASH TABLE finds things almost instantly. A HASH FUNCTION
'   turns a word into a number (the bucket), so we only look in
'   that one bucket instead of searching everything.
'
'   Two different words can land in the same bucket - a COLLISION.
'   With CHAINING, each bucket is the head of a small linked list
'   of all the words that hashed there.
'
'   The program reads a short poem from DATA lines, splits it into
'   words, and counts each word. Then it shows every bucket and its
'   chain, the most common words, and lets you look words up.
'
' HOW TO USE
'   Watch the counting, press a key to see the buckets, then type
'   words to look up. Blank line or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * A polynomial string hash:  h = (h * 31 + ASC(c)) MOD size
'   * Buckets as linked-list heads (index pointers in a TYPE)
'   * Load factor = items / buckets, and why it matters
'   * Splitting text into words with MID$
'
' THINGS TO TRY
'   * Change NBUCKETS to 5 or 53 and compare chain lengths
'   * Try a bad hash (just LEN(word)) and see the chains pile up
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Hash% (w$)
DECLARE SUB AddWord (w$)
DECLARE FUNCTION FindWord% (w$)

TYPE WordNode
    word AS STRING * 12
    count AS INTEGER
    nxt AS INTEGER
END TYPE

CONST NBUCKETS = 17          ' a prime number spreads keys more evenly
CONST MAXW = 150
DIM SHARED bucket(0 TO NBUCKETS - 1) AS INTEGER   ' head of each chain
DIM SHARED w(1 TO MAXW) AS WordNode
DIM SHARED used, total

CLS
PRINT "Reading the poem..."
PRINT
DO
    READ ln$
    IF ln$ = "*" THEN EXIT DO
    PRINT "  "; ln$
    ' Split the line into words: collect letters, and whenever a
    ' non-letter appears, the word so far is finished.
    cur$ = ""
    FOR i = 1 TO LEN(ln$) + 1
        c$ = UCASE$(MID$(ln$, i, 1))       ' past the end gives ""
        IF (c$ >= "A" AND c$ <= "Z") OR c$ = "'" THEN
            cur$ = cur$ + c$
        ELSE
            IF cur$ <> "" THEN AddWord cur$: total = total + 1
            cur$ = ""
        END IF
    NEXT i
LOOP
DATA "The owl and the pussy-cat went to sea"
DATA "In a beautiful pea-green boat,"
DATA "They took some honey, and plenty of money,"
DATA "Wrapped up in a five-pound note."
DATA "The owl looked up to the stars above,"
DATA "And sang to a small guitar,"
DATA "O lovely pussy! O pussy, my love,"
DATA "What a beautiful pussy you are!"
DATA "*"
PRINT
PRINT total; "words,"; used; "different words,"; NBUCKETS; "buckets."
PRINT USING "Load factor = ##.## words per bucket"; used / NBUCKETS
PRINT : PRINT "Press a key to see the buckets..."
k$ = INPUT$(1)

' ---- Show each bucket's chain ------------------------------
CLS
PRINT "BUCKET  CHAIN  (word:count -> ...)"
longest = 0
FOR b = 0 TO NBUCKETS - 1
    PRINT USING "  ##  "; b;
    p = bucket(b): length = 0
    DO WHILE p <> 0
        t$ = RTRIM$(w(p).word) + ":" + LTRIM$(STR$(w(p).count))
        IF POS(0) + LEN(t$) > 76 THEN PRINT "...";: EXIT DO
        PRINT " "; t$;
        IF w(p).nxt THEN PRINT " ->";
        length = length + 1
        p = w(p).nxt
    LOOP
    IF length > longest THEN longest = length
    PRINT
NEXT b
PRINT "Longest chain:"; longest; "  (an even spread would give about"; CINT(used / NBUCKETS + .5); ")"
PRINT "Press a key..."
k$ = INPUT$(1)

' ---- Top words: simple repeated "find the max" -------------
CLS
PRINT "Most common words:"
DIM done(1 TO MAXW)
FOR r = 1 TO 6
    best = 0
    FOR i = 1 TO used
        IF done(i) = 0 THEN
            IF best = 0 THEN best = i ELSE IF w(i).count > w(best).count THEN best = i
        END IF
    NEXT i
    IF best = 0 THEN EXIT FOR
    done(best) = 1
    PRINT USING "  #. \          \ x##  "; r; w(best).word; w(best).count;
    PRINT STRING$(w(best).count, 219)
NEXT r

' ---- Lookups -----------------------------------------------
PRINT
DO
    LINE INPUT "Look up a word (blank = quit): "; q$
    q$ = UCASE$(LTRIM$(RTRIM$(q$)))
    IF q$ = "" OR q$ = "Q" THEN EXIT DO
    p = FindWord%(q$)
    PRINT "  hash("; q$; ") ="; Hash%(q$);
    IF p THEN PRINT " -> found, appears"; w(p).count; "time(s)" ELSE PRINT " -> not in the poem"
LOOP
END

' AddWord: if the word exists, bump its count; otherwise make a
' new node and push it on the front of its bucket's chain.
SUB AddWord (w$)
    p = FindWord%(w$)
    IF p THEN w(p).count = w(p).count + 1: EXIT SUB
    IF used = MAXW THEN EXIT SUB
    used = used + 1
    h = Hash%(w$)
    w(used).word = w$
    w(used).count = 1
    w(used).nxt = bucket(h)      ' old chain hangs off the new node
    bucket(h) = used
END SUB

' FindWord%: hash, then walk just that one chain.
FUNCTION FindWord% (w$)
    p = bucket(Hash%(w$))
    k$ = LEFT$(w$ + SPACE$(12), 12)   ' fixed strings are space padded
    DO WHILE p <> 0
        IF w(p).word = k$ THEN EXIT DO
        p = w(p).nxt
    LOOP
    FindWord% = p
END FUNCTION

' Hash%: treat the word like a number in base 31. Taking MOD at
' each step keeps it small (h stays below NBUCKETS, and 31*h+255
' fits easily in a LONG).
FUNCTION Hash% (w$)
    DIM h AS LONG
    FOR i = 1 TO LEN(w$)
        h = (h * 31 + ASC(MID$(w$, i, 1))) MOD NBUCKETS
    NEXT i
    Hash% = h
END FUNCTION
