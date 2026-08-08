' ============================================================
' TITLE:    XOR File Encryption
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, binary, XOR, encryption, passwords, bytes
' SUMMARY:  Scramble any file with a password using XOR, then unscramble it with the same password.
' ------------------------------------------------------------
' WHAT IT DOES
'   XOR has a magic property:  (A XOR K) XOR K = A.
'   So if we XOR every byte of a file with a key, we get gibberish,
'   and XOR-ing the gibberish with the SAME key gives the original
'   back. This program encrypts SECRET.TXT into SECRET.XOR using a
'   password, shows the scrambled bytes, then decrypts it with a
'   password you type. The wrong password gives nonsense!
'
'   To make the key stream less obvious than just repeating the
'   password, we mix in a simple pseudo-random generator seeded from
'   the password. (This is a fun lesson, NOT real security - use
'   proper tools for real secrets.)
'
' HOW TO USE
'   Enter a password to encrypt (Enter = "dragon").
'   Then enter a password to decrypt: try a wrong one first!
'   Enter on an empty decrypt prompt quits.
'
' CONCEPTS YOU WILL LEARN
'   * XOR on bytes:  ASC(c$) XOR k
'   * BINARY mode reading/writing in blocks
'   * Turning a password into a number (a "hash")
'   * A linear congruential generator (LCG) for a key stream
'
' THINGS TO TRY
'   * Encrypt using only the repeated password (no LCG) and look
'     for patterns in the hex dump of a file full of spaces.
'   * Store a checksum so the program can SAY "wrong password".
' ============================================================

DECLARE SUB Crypt (src$, dst$, pw$)
DECLARE SUB ShowFile (f$, asHex%)

CLS
OPEN "SECRET.TXT" FOR OUTPUT AS #1
PRINT #1, "TOP SECRET - for agents only"
PRINT #1, "The treasure is buried under the third oak tree,"
PRINT #1, "twelve paces north of the old well."
CLOSE #1

PRINT "XOR ENCRYPTOR"
PRINT
PRINT "Original SECRET.TXT:"
ShowFile "SECRET.TXT", 0
PRINT
LINE INPUT "Password to encrypt with (Enter = dragon): "; pw$
IF pw$ = "" THEN pw$ = "dragon"
Crypt "SECRET.TXT", "SECRET.XOR", pw$
PRINT
PRINT "Encrypted SECRET.XOR (first bytes in hex):"
ShowFile "SECRET.XOR", -1

DO
    PRINT
    LINE INPUT "Password to decrypt (Enter = quit): "; try$
    IF try$ = "" THEN EXIT DO
    ' Decrypting is the very same operation as encrypting!
    Crypt "SECRET.XOR", "DECODED.TXT", try$
    PRINT "DECODED.TXT:"
    ShowFile "DECODED.TXT", 0
LOOP
END

' XOR every byte of src$ with a key stream made from pw$.
SUB Crypt (src$, dst$, pw$)
    ' 1. Turn the password into a seed number (a tiny hash).
    '    Multiplying by 31 and adding each character spreads the
    '    letters' influence over the whole number.
    seed& = 7
    FOR i = 1 TO LEN(pw$)
        seed& = (seed& * 31 + ASC(MID$(pw$, i, 1))) MOD 65521
    NEXT

    OPEN src$ FOR BINARY AS #1
    OPEN dst$ FOR OUTPUT AS #2: CLOSE #2       ' empty the target
    OPEN dst$ FOR BINARY AS #2
    total& = LOF(1)
    done& = 0: x& = seed&
    DO WHILE done& < total&
        n = 256: IF total& - done& < n THEN n = total& - done&
        buf$ = SPACE$(n)
        GET #1, done& + 1, buf$
        FOR i = 1 TO n
            ' 2. Next number from the LCG: x = (a*x + c) MOD m.
            '    These small constants keep everything inside a LONG.
            x& = (x& * 75 + 74) MOD 65537
            ' 3. Key byte = LCG output mixed with a password letter.
            k = (x& AND 255) XOR ASC(MID$(pw$, ((done& + i - 1) MOD LEN(pw$)) + 1, 1))
            MID$(buf$, i, 1) = CHR$(ASC(MID$(buf$, i, 1)) XOR k)
        NEXT
        PUT #2, done& + 1, buf$
        done& = done& + n
    LOOP
    CLOSE #1, #2
END SUB

' Print a file as text, or (asHex%) its first 64 bytes as hex.
' Control characters in decrypted junk are shown as dots so they do
' not mess up the screen.
SUB ShowFile (f$, asHex%)
    OPEN f$ FOR BINARY AS #3
    s$ = SPACE$(LOF(3))
    GET #3, 1, s$
    CLOSE #3
    IF asHex% THEN
        FOR i = 1 TO LEN(s$)
            IF i > 64 THEN PRINT "...": EXIT FOR
            PRINT RIGHT$("0" + HEX$(ASC(MID$(s$, i, 1))), 2); " ";
            IF i MOD 16 = 0 THEN PRINT
        NEXT
        PRINT
    ELSE
        row$ = "  "
        FOR i = 1 TO LEN(s$)
            c = ASC(MID$(s$, i, 1))
            IF c = 13 THEN
                PRINT row$: row$ = "  "
            ELSEIF c = 10 THEN
                ' skip: CR already ended the line
            ELSEIF c < 32 OR c > 126 THEN
                row$ = row$ + "."
            ELSE
                row$ = row$ + CHR$(c)
            END IF
            IF LEN(row$) >= 78 THEN PRINT row$: row$ = "  "
        NEXT
        IF row$ <> "  " THEN PRINT row$
    END IF
END SUB
