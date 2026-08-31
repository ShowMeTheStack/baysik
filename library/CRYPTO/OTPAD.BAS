' ============================================================
' TITLE:    One-Time Pad - Perfect Secrecy
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     one-time pad, vernam, RND, perfect secrecy, key reuse
' SUMMARY:  Encrypts with a random key as long as the message, proves no attacker can tell what it says, then shows why reusing a pad is fatal.
' ------------------------------------------------------------
' WHAT IT DOES
'   The one-time pad (Gilbert Vernam & Joseph Mauborgne, 1917-1919)
'   is the only cipher PROVEN unbreakable (Claude Shannon, 1949) -
'   as long as these rules are followed:
'     1. the key is truly random,
'     2. the key is at least as long as the message,
'     3. the key is used ONCE and then destroyed.
'   Spies carried pads of random letters printed on tiny sheets, and
'   the Moscow-Washington hotline used one-time tapes.
'
'   Encryption is Vigenere with a key that never repeats:
'        C = (P + K) MOD 26          P = (C - K) MOD 26
'
'   WHY IT'S PERFECT: for ANY guess of the plaintext with the right
'   length, there is a key that turns the ciphertext into that guess.
'   So the ciphertext gives the enemy no information at all.  Part 2
'   of this program finds the "fake" key for your guess to prove it.
'
'   WHY REUSE IS FATAL: if two messages use the same pad, then
'        C1 - C2 = (P1 + K) - (P2 + K) = P1 - P2
'   The key cancels out!  In the VENONA project (1943-1980) American
'   codebreakers read thousands of Soviet messages because some pads
'   had been printed twice.  Part 3 shows this.
'
'   NOTE: QBasic's RND is NOT truly random - it is a formula.  Real
'   pads use dice, radioactive decay or hardware noise.
'
' HOW TO USE
'   Type a message.  Then press keys to walk through the three parts.
'   Esc quits at any pause.
'
' CONCEPTS YOU WILL LEARN
'   * Generating random keys with RANDOMIZE and RND
'   * Why key length and key reuse matter
'   * Working with letter values in arrays
'
' THINGS TO TRY
'   * In part 3, guess a common word ("THE") in one message and drag
'     it along the other to reveal pieces ("crib dragging")
'   * Replace the letters-only pad with bytes and XOR (see XORFILE.BAS)
' ============================================================

DECLARE FUNCTION Letters$ (t$)
DECLARE FUNCTION AddKey$ (t$, k$, sign%)
DECLARE SUB Pause ()

RANDOMIZE TIMER
CLS
COLOR 14: PRINT "ONE-TIME PAD": COLOR 7
PRINT
LINE INPUT "Secret message: "; m$
p$ = Letters$(m$)
IF LEN(p$) < 4 THEN p$ = "MEETATTHEBRIDGEATNOON": PRINT "(using MEET AT THE BRIDGE AT NOON)"
IF LEN(p$) > 60 THEN p$ = LEFT$(p$, 60)

' ---- Part 1: make a pad and encrypt ---------------------------
' One random letter per message letter.  INT(RND * 26) gives a
' whole number from 0 to 25, each equally likely.
pad$ = ""
FOR i = 1 TO LEN(p$): pad$ = pad$ + CHR$(65 + INT(RND * 26)): NEXT i
c$ = AddKey$(p$, pad$, 1)

PRINT
COLOR 11: PRINT "PART 1 - ENCRYPT": COLOR 7
PRINT "Plain : "; p$
PRINT "Pad   : "; pad$
COLOR 10: PRINT "Cipher: "; c$: COLOR 7
PRINT "Decrypted with the pad: "; AddKey$(c$, pad$, -1)
PRINT
PRINT "Each cipher letter = (plain + pad) MOD 26.  First letter:"
a = ASC(p$) - 65: b = ASC(pad$) - 65
PRINT "  "; LEFT$(p$, 1); "("; LTRIM$(STR$(a)); ") + "; LEFT$(pad$, 1); "("; LTRIM$(STR$(b)); ") ->";
PRINT (a + b) MOD 26; "= "; LEFT$(c$, 1)
Pause

' ---- Part 2: perfect secrecy ---------------------------------
CLS
COLOR 11: PRINT "PART 2 - THE ENEMY CAN'T TELL WHAT IT SAYS": COLOR 7
PRINT
PRINT "Intercepted cipher: "; c$
PRINT "Its length is"; LEN(c$); "letters.  Type ANY guess of that length"
PRINT "(shorter guesses are padded with X, longer ones cut)."
LINE INPUT "Guess: "; g$
g$ = Letters$(g$)
IF g$ = "" THEN g$ = "ATTACKTHECASTLEATDAWNWITHALLTHEKNIGHTSANDDRAGONSATONCE"
DO WHILE LEN(g$) < LEN(c$): g$ = g$ + "X": LOOP
g$ = LEFT$(g$, LEN(c$))
' The fake key that maps the guess to the cipher:  K = C - P
fake$ = AddKey$(c$, g$, -1)
PRINT
PRINT "Cipher    : "; c$
PRINT "Fake pad  : "; fake$
COLOR 10: PRINT "Decrypts to: "; AddKey$(c$, fake$, -1): COLOR 7
PRINT
PRINT "Both the real pad and this fake pad are random-looking letters."
PRINT "Without the real pad, every message of this length is equally"
PRINT "possible - so the ciphertext tells the enemy NOTHING."
Pause

' ---- Part 3: the danger of reusing a pad ----------------------
CLS
COLOR 11: PRINT "PART 3 - NEVER USE A PAD TWICE": COLOR 7
PRINT
p2$ = LEFT$("THEMONEYISHIDDENUNDERTHEOLDOAKTREEBYTHERIVERBENDNEARTHEMILLPONDATMIDNIGHT", LEN(p$))
c2$ = AddKey$(p2$, pad$, 1)
PRINT "Message 1 cipher: "; c$
PRINT "Msg 2, SAME pad : "; c2$
' Subtracting the two ciphertexts cancels the key completely.
d$ = AddKey$(c$, c2$, -1)
PRINT "C1 - C2         : "; d$
PRINT "P1 - P2         : "; AddKey$(p$, p2$, -1)
PRINT "The two lines above are identical - the key has vanished!"
PRINT
PRINT "An attacker guesses that message 2 starts with THE ..."
crib$ = "THE"
' If P2 starts with THE, then P1 = (C1 - C2) + P2 for those letters.
rev$ = AddKey$(LEFT$(d$, 3), crib$, 1)
COLOR 12: PRINT "...and instantly learns message 1 starts with: "; rev$: COLOR 7
PRINT "Real message 1 starts with:                     "; LEFT$(p$, 3)
PRINT
PRINT "Guess more words and the whole of both messages unravels."
PRINT "This is how the VENONA codebreakers read Soviet spy traffic."
PRINT
PRINT "Press any key to finish."
k$ = INPUT$(1)
END

' ------------------------------------------------------------
' AddKey$: letter-wise (t + sign*k) MOD 26.  sign% = 1 adds,
' -1 subtracts.  Both strings are capital letters only.
' ------------------------------------------------------------
FUNCTION AddKey$ (t$, k$, sign%)
    r$ = t$
    FOR i = 1 TO LEN(t$)
        x = ASC(MID$(t$, i, 1)) - 65
        y = ASC(MID$(k$, i, 1)) - 65
        MID$(r$, i, 1) = CHR$((x + sign% * y + 26) MOD 26 + 65)
    NEXT i
    AddKey$ = r$
END FUNCTION

' ------------------------------------------------------------
' Letters$: capital letters only (pads work on letters A-Z).
' ------------------------------------------------------------
FUNCTION Letters$ (t$)
    r$ = ""
    FOR i = 1 TO LEN(t$)
        ch$ = UCASE$(MID$(t$, i, 1))
        IF ch$ >= "A" AND ch$ <= "Z" THEN r$ = r$ + ch$
    NEXT i
    Letters$ = r$
END FUNCTION

SUB Pause
    PRINT
    COLOR 8: PRINT "Press any key (Esc = quit)..."; : COLOR 7
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN CLS : END
END SUB
