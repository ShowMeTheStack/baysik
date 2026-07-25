' ============================================================
' TITLE:    Text Compression Workshop
' CATEGORY: Strings & Text Processing
' LEVEL:    Advanced
' TAGS:     compression, LZ77, dictionary, Huffman, bits, entropy
' SUMMARY:  Compares three compression ideas on the same text: word dictionary, LZ77 back-references and Huffman bit counts.
' ------------------------------------------------------------
' WHAT IT DOES
'   How do ZIP files make text smaller?  By noticing repetition.
'   This workshop tries three classic ideas on one passage:
'
'   1. WORD DICTIONARY - common words are swapped for one-byte
'      codes (CHR$(128) and up).  "the" -> 1 byte instead of 3.
'
'   2. LZ77 (the heart of ZIP and PNG) - whenever text repeats
'      something seen earlier, write a pointer instead:
'         "to be or not to be"  ->  "to be or not <13,5>"
'      meaning "go back 13 characters and copy 5".  We encode,
'      show the tokens, then DECODE to prove nothing was lost.
'
'   3. HUFFMAN CODING - common letters get short bit codes and
'      rare letters long ones.  We build the Huffman tree and
'      count exactly how many bits the text would need.
'
' HOW TO USE
'   Press a key to move from one stage to the next.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Searching backwards for the longest earlier match
'   * Encoding and decoding must be exact mirror images
'   * Counting frequencies; building a tree by merging the two
'     smallest weights again and again (a greedy algorithm)
'   * Bits vs bytes: why 8 bits per letter is wasteful
'
' THINGS TO TRY
'   * Change the window size W and minimum match length
'   * Compress your own text (change the DATA)
'   * Print the actual Huffman bit code for each letter
' ============================================================

DECLARE FUNCTION Lz77$ (s$)
DECLARE FUNCTION UnLz77$ (s$)
DECLARE SUB WaitKey ()

CONST WIN = 255              ' how far back LZ77 may look
CONST MINMATCH = 4           ' shorter repeats are not worth a pointer
DIM SHARED quit

' ---- load the passage ----
txt$ = ""
DO
    READ a$
    IF a$ = "*" THEN EXIT DO
    IF txt$ <> "" THEN txt$ = txt$ + " "
    txt$ = txt$ + a$
LOOP
DATA "the rain in spain falls mainly on the plain, and the plain is"
DATA "where the rain in spain falls. to be or not to be, that is the"
DATA "question; the answer is in the rain on the plain in spain.", "*"
orig = LEN(txt$)

CLS
COLOR 14: PRINT "TEXT COMPRESSION WORKSHOP": COLOR 7
PRINT
PRINT "The passage ("; LTRIM$(STR$(orig)); " bytes):"
COLOR 8: PRINT txt$: COLOR 7
WaitKey
IF quit THEN END

' ============ 1. WORD DICTIONARY =============================
PRINT
COLOR 11: PRINT "1. WORD DICTIONARY": COLOR 7
' each dictionary word is replaced by one byte: CHR$(127 + index)
DIM dw$(8)
FOR i = 1 TO 8: READ dw$(i): NEXT i
DATA "the ", "rain", "spain", "plain", " in ", "falls", "is ", "ain"
c$ = txt$
FOR i = 1 TO 8
    p = INSTR(c$, dw$(i))
    DO WHILE p > 0
        c$ = LEFT$(c$, p - 1) + CHR$(127 + i) + MID$(c$, p + LEN(dw$(i)))
        p = INSTR(p + 1, c$, dw$(i))
    LOOP
NEXT i
' display codes as [1] [2] ... so they are readable
show$ = ""
FOR i = 1 TO LEN(c$)
    k = ASC(MID$(c$, i, 1))
    IF k >= 128 THEN show$ = show$ + "[" + CHR$(48 + k - 127) + "]" ELSE show$ = show$ + CHR$(k)
NEXT i
PRINT "Dictionary: ";
FOR i = 1 TO 8: PRINT "["; LTRIM$(STR$(i)); "]="; CHR$(34); dw$(i); CHR$(34); " "; : NEXT i
PRINT : PRINT
PRINT show$
PRINT
PRINT USING "Size: ### -> ### bytes (###%) - plus the dictionary itself"; orig; LEN(c$); LEN(c$) * 100 / orig
WaitKey
IF quit THEN END

' ============ 2. LZ77 ========================================
PRINT
COLOR 11: PRINT "2. LZ77 BACK-REFERENCES  <distance,length>": COLOR 7
z$ = Lz77$(txt$)
PRINT z$
back$ = UnLz77$(z$)
PRINT
PRINT USING "As text: ### -> ### characters  (###%)"; orig; LEN(z$); LEN(z$) * 100 / orig
' Written as text, "<121,4>" wastes space.  A real compressor packs
' each pointer into 2 bytes (12 bits distance + 4 bits length), so
' count literals and pointers to see the true size.
lits = 0: ptrs = 0: inPtr = 0
FOR i = 1 TO LEN(z$)
    c$ = MID$(z$, i, 1)
    IF c$ = "<" THEN
        inPtr = 1: ptrs = ptrs + 1
    ELSEIF c$ = ">" THEN
        inPtr = 0
    ELSEIF inPtr = 0 THEN
        lits = lits + 1
    END IF
NEXT i
packed = lits + 2 * ptrs
PRINT USING "Packed : ### literals + ## pointers x 2 bytes = ### bytes (###%)"; lits; ptrs; packed; packed * 100 / orig
IF back$ = txt$ THEN COLOR 10: PRINT "Decoded perfectly - lossless!" ELSE COLOR 12: PRINT "DECODE MISMATCH"
COLOR 7
WaitKey
IF quit THEN END

' ============ 3. HUFFMAN =====================================
PRINT
COLOR 11: PRINT "3. HUFFMAN CODING": COLOR 7
' count how often each byte appears
DIM freq(255)
FOR i = 1 TO orig
    k = ASC(MID$(txt$, i, 1)): freq(k) = freq(k) + 1
NEXT i
' nodes: weight w(), and for leaves the character; parent link
DIM w(511), par(511), alive(511), sym(511)
nn = 0
FOR k = 0 TO 255
    IF freq(k) > 0 THEN nn = nn + 1: w(nn) = freq(k): sym(nn) = k: alive(nn) = 1
NEXT k
leaves = nn
' Greedy merge: pick the two lightest live nodes, join them under
' a new node whose weight is their sum.  Repeat until one is left.
FOR mg = 1 TO leaves - 1
    a = 0: b = 0
    FOR i = 1 TO nn
        IF alive(i) THEN
            IF a = 0 THEN
                a = i
            ELSEIF w(i) < w(a) THEN
                b = a: a = i
            ELSEIF b = 0 THEN
                b = i
            ELSEIF w(i) < w(b) THEN
                b = i
            END IF
        END IF
    NEXT i
    nn = nn + 1
    w(nn) = w(a) + w(b): alive(nn) = 1
    alive(a) = 0: alive(b) = 0
    par(a) = nn: par(b) = nn
NEXT mg
' a leaf's code length = how many steps up to the root
PRINT "Char Count Bits    Char Count Bits    Char Count Bits"
totalBits = 0: col = 0
FOR i = 1 TO leaves
    depth = 0: j = i
    DO WHILE par(j) <> 0
        depth = depth + 1: j = par(j)
    LOOP
    IF leaves = 1 THEN depth = 1
    totalBits = totalBits + depth * w(i)
    ch$ = CHR$(sym(i)): IF ch$ = " " THEN ch$ = "_"
    PRINT USING " !   ###  ##     "; ch$; w(i); depth;
    col = col + 1
    IF col = 3 THEN PRINT : col = 0
NEXT i
IF col THEN PRINT
PRINT
PRINT "Plain text:"; orig * 8; "bits.   Huffman:"; totalBits; "bits ";
PRINT USING "(##.# bits per letter, ###%)"; totalBits / orig; totalBits * 100 / (orig * 8)
WaitKey
END

' ------------------------------------------------------------
' Lz77$: at each position look back up to WIN characters for the
' longest earlier match.  If it is at least MINMATCH long, write
' <distance,length>; otherwise copy one character literally.
' (Matches may overlap the current position - "aaaaaa" becomes
' "a<1,5>" - the decoder copies one char at a time so it works.)
' The text must not contain "<" for this simple format.
' ------------------------------------------------------------
FUNCTION Lz77$ (s$)
    out$ = ""
    i = 1: n = LEN(s$)
    DO WHILE i <= n
        bestLen = 0: bestDist = 0
        st = i - WIN: IF st < 1 THEN st = 1
        FOR j = st TO i - 1
            L = 0
            DO WHILE i + L <= n
                IF MID$(s$, j + L, 1) <> MID$(s$, i + L, 1) THEN EXIT DO
                L = L + 1
            LOOP
            IF L > bestLen THEN bestLen = L: bestDist = i - j
        NEXT j
        IF bestLen >= MINMATCH THEN
            out$ = out$ + "<" + LTRIM$(STR$(bestDist)) + "," + LTRIM$(STR$(bestLen)) + ">"
            i = i + bestLen
        ELSE
            out$ = out$ + MID$(s$, i, 1)
            i = i + 1
        END IF
    LOOP
    Lz77$ = out$
END FUNCTION

' UnLz77$: literals are copied; <d,l> copies l characters from d back.
FUNCTION UnLz77$ (s$)
    out$ = ""
    i = 1
    DO WHILE i <= LEN(s$)
        c$ = MID$(s$, i, 1)
        IF c$ = "<" THEN
            comma = INSTR(i, s$, ","): shut = INSTR(i, s$, ">")
            d = VAL(MID$(s$, i + 1, comma - i - 1))
            L = VAL(MID$(s$, comma + 1, shut - comma - 1))
            FOR k = 1 TO L
                out$ = out$ + MID$(out$, LEN(out$) - d + 1, 1)
            NEXT k
            i = shut + 1
        ELSE
            out$ = out$ + c$
            i = i + 1
        END IF
    LOOP
    UnLz77$ = out$
END FUNCTION

SUB WaitKey
    PRINT
    COLOR 8: PRINT "-- press a key (Q quits) --": COLOR 7
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF UCASE$(k$) = "Q" OR k$ = CHR$(27) THEN quit = 1
END SUB
