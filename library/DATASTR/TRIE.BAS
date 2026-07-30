' ============================================================
' TITLE:    Autocomplete Trie
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     trie, prefix tree, autocomplete, recursion, strings
' SUMMARY:  Type letters and watch a trie (prefix tree) suggest matching words instantly as you type.
' ------------------------------------------------------------
' WHAT IT DOES
'   A TRIE (from "reTRIEval", say "try") stores words letter by
'   letter in a tree. The root has up to 26 children, one per
'   first letter; each of those has children for the second
'   letter, and so on. Words that share a beginning share nodes:
'   CAT, CAR and CART all live under the path C -> A.
'
'   To find every word starting with a prefix, walk down the
'   prefix (one step per letter - no matter how many words are
'   stored!) and then collect everything below that node.
'
'   Each node is a row of a 2-D array: kid(node, letter) holds the
'   child node index for that letter (0 = none). isWord(node) marks
'   nodes where a complete word ends.
'
' HOW TO USE
'   Just type letters. Suggestions update after each key.
'   Backspace deletes a letter. Enter adds the current text as a
'   new word. Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * A tree where each node has a fixed array of 26 child slots
'   * Prefix search cost depends on prefix LENGTH, not word count
'   * Recursive depth-first collection of words
'   * Shared prefixes save memory
'
' THINGS TO TRY
'   * Add more words to the DATA lines
'   * Store a "times used" count and suggest popular words first
' ============================================================

DEFINT A-Z
DECLARE SUB AddWord (w$)
DECLARE FUNCTION Walk% (p$)
DECLARE SUB Collect (node AS INTEGER, sofar$)

CONST MAXNODE = 700
DIM SHARED kid(0 TO MAXNODE, 0 TO 25)   ' node 0 is the root
DIM SHARED isWord(0 TO MAXNODE), nodes, found, words, letters
DIM SHARED hits$(1 TO 12)

nodes = 0                         ' root exists; no other nodes yet
DO
    READ w$
    IF w$ = "*" THEN EXIT DO
    AddWord w$
LOOP
DATA apple, apply, ape, apron, april, arch, archer, arrow, art, artist
DATA bake, baker, ball, balloon, banana, band, bank, bar, bark, barn
DATA cab, cabin, cake, call, camel, camp, can, candle, candy, car
DATA card, care, cart, carton, cast, castle, cat, catch, cattle
DATA dog, doll, dolphin, door, dot, dove, dragon, draw, dream, drum
DATA tea, team, tear, ten, tent, test, the, then, there, they, this
DATA trie, tree, trick, trip, troll, truck, true, trumpet, try
DATA *

prefix$ = ""
DO
    ' ---- Find the node for the prefix, then collect words ------
    found = 0
    node = Walk%(prefix$)
    IF node >= 0 THEN Collect node, prefix$

    CLS
    PRINT "AUTOCOMPLETE TRIE   ("; LTRIM$(STR$(words)); " words,"; nodes; "nodes for"; letters; "letters)"
    PRINT "Type letters, Backspace to erase, Enter to add a word, Esc to quit."
    PRINT
    PRINT "  > "; prefix$; "_"
    PRINT
    IF node < 0 THEN
        PRINT "  No word starts with '"; prefix$; "'. (Press Enter to add it!)"
    ELSE
        PRINT "  Path walked:"; LEN(prefix$); "steps from the root to node"; node
        PRINT
        FOR i = 1 TO found
            IF i <= 12 THEN PRINT "    "; hits$(i)
        NEXT i
        IF found > 12 THEN PRINT "    ... and"; found - 12; "more"
        IF found = 0 THEN PRINT "    (nothing)"
    END IF
    ' Draw the trie branch under the prefix as a row of letters:
    ' which letters can come NEXT?
    IF node >= 0 THEN
        LOCATE 22, 1: PRINT "  Next letters possible: ";
        FOR L = 0 TO 25
            IF kid(node, L) THEN PRINT CHR$(65 + L); " ";
        NEXT L
    END IF

    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE k$
    CASE CHR$(27): EXIT DO
    CASE CHR$(8)
        IF LEN(prefix$) > 0 THEN prefix$ = LEFT$(prefix$, LEN(prefix$) - 1)
    CASE CHR$(13)
        IF prefix$ <> "" THEN AddWord prefix$
    CASE ELSE
        k$ = UCASE$(k$)
        IF k$ >= "A" AND k$ <= "Z" AND LEN(prefix$) < 20 THEN prefix$ = prefix$ + k$
    END SELECT
LOOP
CLS : PRINT "Bye! The trie held"; words; "words."
END

' AddWord: walk down letter by letter, creating missing nodes.
SUB AddWord (w$)
    w$ = UCASE$(w$)
    n = 0
    FOR i = 1 TO LEN(w$)
        L = ASC(MID$(w$, i, 1)) - 65      ' "A" -> 0 ... "Z" -> 25
        IF L < 0 OR L > 25 THEN EXIT SUB
        IF kid(n, L) = 0 THEN
            IF nodes = MAXNODE THEN EXIT SUB   ' out of room
            nodes = nodes + 1
            kid(n, L) = nodes
        END IF
        n = kid(n, L)
    NEXT i
    IF isWord(n) = 0 THEN isWord(n) = 1: words = words + 1: letters = letters + LEN(w$)
END SUB

' Collect: depth-first walk below node, building each word as we
' go. Children are visited A..Z, so results come out sorted!
SUB Collect (node AS INTEGER, sofar$)
    IF isWord(node) THEN
        found = found + 1
        IF found <= 12 THEN hits$(found) = sofar$
    END IF
    FOR L = 0 TO 25
        IF kid(node, L) THEN Collect (kid(node, L)), sofar$ + CHR$(65 + L)
    NEXT L
END SUB

' Walk%: follow the prefix from the root. Returns the node, or -1
' if some letter has no child (no word has this prefix).
FUNCTION Walk% (p$)
    n = 0
    FOR i = 1 TO LEN(p$)
        n = kid(n, ASC(MID$(p$, i, 1)) - 65)
        IF n = 0 THEN Walk% = -1: EXIT FUNCTION
    NEXT i
    Walk% = n
END FUNCTION
