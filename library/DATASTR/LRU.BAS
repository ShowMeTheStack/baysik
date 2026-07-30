' ============================================================
' TITLE:    LRU Cache Simulator
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     LRU cache, hash table, doubly linked list, eviction, caching
' SUMMARY:  A least-recently-used cache built from a hash table plus a doubly linked list, simulating a web browser cache.
' ------------------------------------------------------------
' WHAT IT DOES
'   A CACHE keeps a few recently used things close at hand because
'   fetching them again is slow. When it is full, something must
'   be thrown out. "Least Recently Used" (LRU) throws out the item
'   that has gone unused the longest.
'
'   Two structures work together so every operation is fast:
'     * a DOUBLY LINKED LIST in order of use: most recent at the
'       front, least recent at the back. Using an item = unlink it
'       and move it to the front. Evicting = drop the back node.
'     * a HASH TABLE from page name to list node, so we can find a
'       page without walking the list.
'
'   The demo "visits" web pages. A HIT is instant; a MISS costs a
'   slow download of 100 ms (pretend!). Watch the list reorder.
'
' HOW TO USE
'   Part 1 plays a recorded browsing session; press a key per step
'   (Esc skips to part 2). Part 2: type page names yourself, blank
'   line or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Combining two data structures, each covering the other's weakness
'   * Move-to-front in a doubly linked list
'   * Removing an entry from a hash chain
'   * Hit rate = hits / (hits + misses)
'
' THINGS TO TRY
'   * Change CAP to 3 or 6 - how does the hit rate change?
'   * Turn it into "least FREQUENTLY used" by keeping a use counter
' ============================================================

DEFINT A-Z
DECLARE SUB Visit (pg$)
DECLARE SUB MoveToFront (n AS INTEGER)
DECLARE SUB Unlink (n AS INTEGER)
DECLARE FUNCTION Hash% (k$)
DECLARE FUNCTION Lookup% (k$)
DECLARE SUB ShowCache ()

CONST CAP = 4, NB = 7
TYPE CNode
    page AS STRING * 12
    prv AS INTEGER           ' list links (use order)
    nxt AS INTEGER
    hnext AS INTEGER         ' next node in the same hash bucket
END TYPE
DIM SHARED c(1 TO CAP) AS CNode
DIM SHARED bucket(0 TO NB - 1), head, tail, size
DIM SHARED hits, misses, last$

' ---- Part 1: a recorded browsing session --------------------
CLS
DO
    READ pg$
    IF pg$ = "*" THEN EXIT DO
    Visit pg$
    CLS
    ShowCache
    LOCATE 22, 1: PRINT "Press a key for the next page (Esc skips)...";
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN EXIT DO
LOOP
DATA news, mail, maps, news, video, mail, shop, news, maps, wiki
DATA news, mail, video, news, mail, *

' ---- Part 2: your turn --------------------------------------
DO
    CLS
    ShowCache
    LOCATE 22, 1: LINE INPUT "Visit page (blank or Q quits): "; pg$
    pg$ = LCASE$(LTRIM$(RTRIM$(pg$)))
    IF pg$ = "" OR pg$ = "q" THEN EXIT DO
    Visit pg$
LOOP
PRINT : PRINT "Final hit rate:"; hits; "hits,"; misses; "misses."
END

' Hash%: add up character codes, MOD the bucket count.
FUNCTION Hash% (k$)
    h = 0
    FOR i = 1 TO LEN(k$): h = (h + ASC(MID$(k$, i, 1))) MOD NB: NEXT i
    Hash% = h
END FUNCTION

' Lookup%: find the node for page k$ through its hash bucket.
FUNCTION Lookup% (k$)
    pad$ = LEFT$(k$ + SPACE$(12), 12)
    n = bucket(Hash%(k$))
    DO WHILE n
        IF c(n).page = pad$ THEN EXIT DO
        n = c(n).hnext
    LOOP
    Lookup% = n
END FUNCTION

' MoveToFront: put node n at the head of the use-order list.
SUB MoveToFront (n AS INTEGER)
    c(n).prv = 0
    c(n).nxt = head
    IF head THEN c(head).prv = n
    head = n
    IF tail = 0 THEN tail = n
END SUB

' ShowCache: list from most to least recent, plus the buckets.
SUB ShowCache
    PRINT "LRU CACHE  (capacity"; CAP; ")"
    PRINT
    PRINT "  most recent ";
    n = head
    DO WHILE n
        PRINT "["; RTRIM$(c(n).page); "]";
        IF c(n).nxt THEN PRINT " <-> ";
        n = c(n).nxt
    LOOP
    PRINT " least recent"
    PRINT
    PRINT "  hash buckets:"
    FOR b = 0 TO NB - 1
        PRINT "    "; b; ":";
        n = bucket(b)
        DO WHILE n: PRINT " "; RTRIM$(c(n).page); : n = c(n).hnext: LOOP
        PRINT
    NEXT b
    PRINT
    PRINT "  "; last$
    PRINT
    total = hits + misses
    PRINT "  Hits:"; hits; "  Misses:"; misses;
    IF total THEN PRINT USING "  Hit rate: ###%"; 100 * hits / total ELSE PRINT
    PRINT "  Time spent downloading:"; misses * 100; "ms (a hit costs 0)"
END SUB

' Unlink: take node n out of the use-order list.
SUB Unlink (n AS INTEGER)
    IF c(n).prv THEN c(c(n).prv).nxt = c(n).nxt ELSE head = c(n).nxt
    IF c(n).nxt THEN c(c(n).nxt).prv = c(n).prv ELSE tail = c(n).prv
END SUB

' Visit: the heart of the LRU cache.
SUB Visit (pg$)
    pg$ = LEFT$(pg$, 12)
    n = Lookup%(pg$)
    IF n THEN
        ' HIT: just move it to the front.
        hits = hits + 1
        last$ = "HIT  '" + pg$ + "' - moved to the front."
        Unlink n: MoveToFront n
        EXIT SUB
    END IF
    ' MISS: "download" it, then find a node to put it in.
    misses = misses + 1
    IF size < CAP THEN
        size = size + 1: n = size
        last$ = "MISS '" + pg$ + "' - downloaded and added."
    ELSE
        ' Cache full: evict the least recently used = the tail.
        n = tail
        last$ = "MISS '" + pg$ + "' - evicted '" + RTRIM$(c(n).page) + "' (least recently used)."
        Unlink n
        ' Also remove the old page from its hash chain.
        b = Hash%(RTRIM$(c(n).page))
        IF bucket(b) = n THEN
            bucket(b) = c(n).hnext
        ELSE
            p = bucket(b)
            DO WHILE c(p).hnext <> n: p = c(p).hnext: LOOP
            c(p).hnext = c(n).hnext
        END IF
    END IF
    ' Fill the node and add it to its bucket and the list front.
    c(n).page = pg$
    b = Hash%(pg$)
    c(n).hnext = bucket(b): bucket(b) = n
    MoveToFront n
END SUB
