' ============================================================
' TITLE:    XOR File Scrambler
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     XOR, binary files, hex dump, OPEN BINARY, GET, PUT
' SUMMARY:  Encrypts any file byte-by-byte with XOR and a password, shows hex dumps, then decrypts it back.
' ------------------------------------------------------------
' WHAT IT DOES
'   XOR ("exclusive or") compares two bits: the answer is 1 when
'   they are DIFFERENT and 0 when they are the same.
'
'        0 XOR 0 = 0     1 XOR 0 = 1
'        0 XOR 1 = 1     1 XOR 1 = 0
'
'   Its magic property:  (A XOR K) XOR K = A.   XOR-ing with the
'   same key twice gives back the original, so one routine both
'   encrypts and decrypts.  Gilbert Vernam built the first XOR
'   cipher machine for teleprinters in 1917, and XOR is still the
'   final step inside modern ciphers like AES and ChaCha20.
'
'   This program XORs every BYTE of a file with the bytes of your
'   password (repeating it).  It works on any file - text, pictures,
'   anything - because it never cares what the bytes mean.
'
'   Warning: a short repeating password is weak!  Repeating-key XOR
'   can be broken exactly like Vigenere (see KASISKI.BAS).  With a
'   random key as long as the file, it becomes a one-time pad.
'
' HOW TO USE
'   The program first creates SECRET.TXT as a demo.  Enter a file
'   name (Enter = SECRET.TXT) and a password.  It writes
'   SECRET.XOR (scrambled) and SECRET.OUT (unscrambled) and shows
'   hex dumps of all three so you can compare.
'
' CONCEPTS YOU WILL LEARN
'   * OPEN ... FOR BINARY with GET and PUT of string buffers
'   * The XOR operator on numbers 0-255
'   * Reading a file in chunks (fast) instead of byte by byte
'   * Hex dumps: HEX$ and RIGHT$("0" + ..., 2)
'   * ON ERROR to handle a missing file
'
' THINGS TO TRY
'   * Encrypt with password "A" and look at the dump - spot the pattern
'   * XOR the .XOR file with the original: you get the password back!
'   * Encrypt twice with two passwords; decrypt in the other order
' ============================================================

DECLARE SUB XorFile (src$, dst$, pw$)
DECLARE SUB HexDump (f$, maxBytes%)

CONST CHUNK = 64

ON ERROR GOTO Oops

' ---- Make a demo file to play with ---------------------------
OPEN "SECRET.TXT" FOR OUTPUT AS #1
PRINT #1, "Dear Agent X,"
PRINT #1, "The microfilm is inside the hollow book on shelf 3."
PRINT #1, "Burn this note after reading!  -- HQ"
CLOSE #1

CLS
COLOR 14: PRINT "XOR FILE SCRAMBLER": COLOR 7
PRINT "Demo file SECRET.TXT created."
PRINT
LINE INPUT "File to scramble (Enter = SECRET.TXT): "; f$
IF f$ = "" THEN f$ = "SECRET.TXT"
f$ = UCASE$(f$)
LINE INPUT "Password (Enter = SPY): "; pw$
IF pw$ = "" THEN pw$ = "SPY"

' Build output names from the input name: NAME.XOR and NAME.OUT
dot = INSTR(f$, ".")
IF dot > 0 THEN stem$ = LEFT$(f$, dot - 1) ELSE stem$ = f$
IF stem$ = "" THEN stem$ = "FILE"
encF$ = stem$ + ".XOR"
decF$ = stem$ + ".OUT"

fileOK = 1
XorFile f$, encF$, pw$
IF fileOK = 0 THEN
    PRINT "Could not read "; f$; " - does it exist?"
    END
END IF
XorFile encF$, decF$, pw$       ' the SAME operation undoes it!

CLS
COLOR 11: PRINT "ORIGINAL  "; f$: COLOR 7
HexDump f$, 48
COLOR 12: PRINT "SCRAMBLED "; encF$; "  (password: "; pw$; ")": COLOR 7
HexDump encF$, 48
COLOR 10: PRINT "UNSCRAMBLED "; decF$: COLOR 7
HexDump decF$, 48

' ---- Verify: compare the original and the round-trip copy -----
OPEN f$ FOR BINARY AS #1: a$ = SPACE$(LOF(1)): GET #1, 1, a$: CLOSE #1
OPEN decF$ FOR BINARY AS #1: b$ = SPACE$(LOF(1)): GET #1, 1, b$: CLOSE #1
IF a$ = b$ THEN
    COLOR 10: PRINT "Round trip OK:"; LEN(a$); "bytes identical."
ELSE
    COLOR 12: PRINT "Mismatch!"
END IF
COLOR 7
PRINT "First byte: "; HEX$(ASC(a$)); " XOR "; HEX$(ASC(pw$)); " (";
PRINT LEFT$(pw$, 1); ") = "; HEX$(ASC(a$) XOR ASC(pw$))
PRINT "Press any key...";
k$ = INPUT$(1)
END

Oops:
    ' Any file error (e.g. file not found) lands here.
    fileOK = 0
    RESUME NEXT

' ------------------------------------------------------------
' XorFile: copy src$ to dst$, XOR-ing each byte with the password.
'   We read CHUNK bytes at a time into a string buffer with GET,
'   change the buffer in place with MID$, and PUT it out.
'   'kp' counts bytes over the whole file so the password keeps
'   cycling correctly across chunk boundaries.
' ------------------------------------------------------------
SUB XorFile (src$, dst$, pw$)
    SHARED fileOK
    OPEN src$ FOR INPUT AS #1      ' fails (error 53) if missing
    IF fileOK = 0 THEN EXIT SUB
    CLOSE #1
    OPEN src$ FOR BINARY AS #1
    ' Delete any old output first so it can't keep extra bytes.
    OPEN dst$ FOR OUTPUT AS #2: CLOSE #2
    OPEN dst$ FOR BINARY AS #2
    total& = LOF(1)
    kp& = 0
    p& = 1
    DO WHILE p& <= total&
        n = CHUNK
        IF total& - p& + 1 < n THEN n = total& - p& + 1
        buf$ = SPACE$(n)
        GET #1, p&, buf$
        FOR i = 1 TO n
            k = ASC(MID$(pw$, (kp& MOD LEN(pw$)) + 1, 1))
            MID$(buf$, i, 1) = CHR$(ASC(MID$(buf$, i, 1)) XOR k)
            kp& = kp& + 1
        NEXT i
        PUT #2, p&, buf$
        p& = p& + n
    LOOP
    CLOSE #1, #2
END SUB

' ------------------------------------------------------------
' HexDump: show bytes as two-digit hex numbers (16 per line) next
' to their characters.  Unprintable bytes are shown as "."
' ------------------------------------------------------------
SUB HexDump (f$, maxBytes%)
    OPEN f$ FOR BINARY AS #3
    n& = LOF(3)
    IF n& > maxBytes% THEN n& = maxBytes%
    d$ = SPACE$(n&)
    GET #3, 1, d$
    CLOSE #3
    FOR row = 0 TO (n& - 1) \ 16
        PRINT RIGHT$("000" + HEX$(row * 16), 4); ": ";
        txt$ = ""
        FOR i = 1 TO 16
            p = row * 16 + i
            IF p <= n& THEN
                b = ASC(MID$(d$, p, 1))
                PRINT RIGHT$("0" + HEX$(b), 2); " ";
                IF b >= 32 AND b < 127 THEN txt$ = txt$ + CHR$(b) ELSE txt$ = txt$ + "."
            ELSE
                PRINT "   ";
            END IF
        NEXT i
        COLOR 8: PRINT txt$: COLOR 7
    NEXT row
    PRINT
END SUB
