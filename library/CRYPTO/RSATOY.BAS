' ============================================================
' TITLE:    RSA with Small Primes
' CATEGORY: Codes & Cryptography
' LEVEL:    Advanced
' TAGS:     RSA, public key, modular exponentiation, Euler phi, signatures, factoring
' SUMMARY:  Builds a real (tiny) RSA key pair, encrypts and decrypts a message, signs it, then breaks the key by factoring.
' ------------------------------------------------------------
' WHAT IT DOES
'   RSA (Rivest, Shamir and Adleman, 1977; Clifford Cocks at GCHQ
'   found it in 1973 but it stayed secret) is a PUBLIC-KEY cipher.
'   You publish one key so ANYONE can lock a message for you, but
'   only your private key can unlock it.  It still protects web
'   traffic, software updates and bank cards today.
'
'   MAKING KEYS
'     1. pick two primes p and q             (here: small ones)
'     2. n = p * q                           (public "modulus")
'     3. phi = (p - 1) * (q - 1)             (Euler's totient of n)
'     4. pick e with GCD(e, phi) = 1         (public exponent)
'     5. d = inverse of e MOD phi            (PRIVATE exponent)
'        so  e * d MOD phi = 1
'   Public key: (n, e).   Private key: d.
'
'   USING THEM (m = message number smaller than n)
'     encrypt:   c = m^e MOD n
'     decrypt:   m = c^d MOD n
'   Why it works: Euler's theorem says m^phi MOD n = 1 (when m and n
'   share no factor), and e*d = 1 + k*phi, so
'     m^(e*d) = m * (m^phi)^k = m * 1^k = m      (all MOD n)
'
'   SECURITY: anyone who can FACTOR n into p * q can compute phi and
'   d.  Our n is tiny, so the program factors it instantly.  Real RSA
'   uses n with 617 decimal digits - nobody knows how to factor that.
'
'   ALSO NOTE: we encrypt one character at a time, which makes this
'   just a fancy substitution cipher (same letter -> same number).
'   Real RSA uses random "padding" so that can't happen.
'
' HOW TO USE
'   Enter two primes (Enter = 61 and 53, the classic textbook pair)
'   with p * q between 256 and 46340, then a message.  Press keys to
'   go through the steps.  Esc quits at any pause.
'
' CONCEPTS YOU WILL LEARN
'   * Modular exponentiation (square-and-multiply) with LONG numbers
'   * Extended Euclid to compute a modular inverse
'   * Digital signatures: encrypt with the PRIVATE key, check with public
'   * Why factoring is the heart of RSA's security
'
' THINGS TO TRY
'   * Use p = q.  Why does that break things?  (Hint: phi is wrong)
'   * Change e to 3, 17, 257 and see how d changes
'   * Encrypt a number bigger than n - what comes back?
' ============================================================

DECLARE FUNCTION PowMod& (b&, e&, m&)
DECLARE FUNCTION IsPrime% (n&)
DECLARE FUNCTION Gcd& (a&, b&)
DECLARE FUNCTION InvMod& (a&, m&)
DECLARE SUB Pause ()

CLS
COLOR 14: PRINT "RSA WITH SMALL PRIMES": COLOR 7
PRINT
DO
    LINE INPUT "Prime p (Enter = 61): "; t$
    IF t$ = "" THEN p& = 61 ELSE p& = VAL(t$)
    LINE INPUT "Prime q (Enter = 53): "; t$
    IF t$ = "" THEN q& = 53 ELSE q& = VAL(t$)
    ok = 1
    IF p& < 2 OR q& < 2 OR p& > 46340 OR q& > 46340 THEN
        ok = 0
    ELSEIF IsPrime%(p&) = 0 OR IsPrime%(q&) = 0 THEN
        PRINT "  Both numbers must be prime.": ok = 0
    ELSEIF p& = q& THEN
        PRINT "  p and q must be different.": ok = 0
    ELSEIF p& * q& < 256 OR p& * q& > 46340 THEN
        PRINT "  p * q must be between 256 and 46340 (try 61 and 53, or 101 and 227).": ok = 0
    END IF
    IF ok = 0 THEN
        PRINT "  Please try again, or press Esc to quit."
        k$ = INPUT$(1): IF k$ = CHR$(27) THEN END
    END IF
LOOP UNTIL ok

' ---- Key generation -------------------------------------------
n& = p& * q&
phi& = (p& - 1) * (q& - 1)
' Choose the smallest e >= 17 that shares no factor with phi.
' (Real systems almost always use e = 65537.)
e& = 17
DO WHILE Gcd&(e&, phi&) <> 1: e& = e& + 2: LOOP
d& = InvMod&(e&, phi&)

PRINT
COLOR 11: PRINT "KEY GENERATION": COLOR 7
PRINT "  n   = p * q             ="; p&; "*"; q&; "="; n&
PRINT "  phi = (p-1) * (q-1)     ="; p& - 1; "*"; q& - 1; "="; phi&
PRINT "  e   (coprime with phi)  ="; e&
PRINT "  d   = e^-1 MOD phi      ="; d&
PRINT "  check: e * d MOD phi    ="; (e& * d&) MOD phi&
PRINT
COLOR 10: PRINT "  PUBLIC KEY  (n, e) = ("; LTRIM$(STR$(n&)); ", "; LTRIM$(STR$(e&)); ")"
COLOR 12: PRINT "  PRIVATE KEY d ="; d&: COLOR 7
PRINT
LINE INPUT "Message to encrypt: "; m$
IF m$ = "" THEN m$ = "HELLO RSA"
IF LEN(m$) > 40 THEN m$ = LEFT$(m$, 40)
Pause

' ---- Encrypt each character -----------------------------------
CLS
COLOR 11: PRINT "ENCRYPT with the PUBLIC key:  c = m ^"; e&; "MOD"; n&: COLOR 7
DIM c&(40)
FOR i = 1 TO LEN(m$)
    m& = ASC(MID$(m$, i, 1))
    c&(i) = PowMod&(m&, e&, n&)
    IF i <= 6 THEN PRINT "  '"; MID$(m$, i, 1); "' ="; m&; " ->"; c&(i)
NEXT i
PRINT "  Ciphertext:";
FOR i = 1 TO LEN(m$): PRINT c&(i); : NEXT i
PRINT
PRINT
COLOR 11: PRINT "DECRYPT with the PRIVATE key:  m = c ^"; d&; "MOD"; n&: COLOR 7
back$ = ""
FOR i = 1 TO LEN(m$)
    v& = PowMod&(c&(i), d&, n&)
    IF v& >= 0 AND v& <= 255 THEN back$ = back$ + CHR$(v&) ELSE back$ = back$ + "?"
NEXT i
COLOR 10: PRINT "  Decrypted: "; back$: COLOR 7
Pause

' ---- Digital signature ----------------------------------------
CLS
COLOR 11: PRINT "DIGITAL SIGNATURE": COLOR 7
PRINT "Run RSA BACKWARDS: lock with the PRIVATE key, unlock with the PUBLIC one."
PRINT "Only the key owner could have made the signature, but anyone can check it."
PRINT
' A toy "hash": sum of (position * character code), MOD n.
h& = 0
FOR i = 1 TO LEN(m$): h& = (h& + i * ASC(MID$(m$, i, 1))) MOD n&: NEXT i
sig& = PowMod&(h&, d&, n&)
PRINT "  hash of message       ="; h&
PRINT "  signature = hash^d    ="; sig&
PRINT "  verify: sig^e MOD n   ="; PowMod&(sig&, e&, n&);
IF PowMod&(sig&, e&, n&) = h& THEN COLOR 10: PRINT " matches the hash - GENUINE" ELSE PRINT
COLOR 7
' Tamper with the message: change its first letter.
fake$ = CHR$(ASC(m$) XOR 1) + MID$(m$, 2)
h2& = 0
FOR i = 1 TO LEN(fake$): h2& = (h2& + i * ASC(MID$(fake$, i, 1))) MOD n&: NEXT i
PRINT
PRINT "  Forged message: "; fake$
PRINT "  its hash ="; h2&; " but sig^e MOD n ="; PowMod&(sig&, e&, n&);
IF h2& <> PowMod&(sig&, e&, n&) THEN COLOR 12: PRINT " - FORGERY DETECTED" ELSE PRINT
COLOR 7
Pause

' ---- Attack: factor n -----------------------------------------
CLS
COLOR 12: PRINT "ATTACK: Eve knows only the public key (n, e) and factors n": COLOR 7
f& = 2: tries& = 0
DO WHILE n& MOD f& <> 0
    f& = f& + 1: tries& = tries& + 1
LOOP
PRINT "  Trial division found"; n&; "="; f&; "*"; n& \ f&; "after"; tries&; "tries."
phi2& = (f& - 1) * (n& \ f& - 1)
d2& = InvMod&(e&, phi2&)
PRINT "  So phi ="; phi2&; "and the private key d ="; d2&
eve$ = ""
FOR i = 1 TO LEN(m$): eve$ = eve$ + CHR$(PowMod&(c&(i), d2&, n&)): NEXT i
COLOR 12: PRINT "  Eve reads: "; eve$: COLOR 7
PRINT
PRINT "  A real 2048-bit n has 617 digits.  Trial division would need about"
PRINT "  10^300 tries, and even the best known method (the number field"
PRINT "  sieve) would take millions of years on today's computers."
PRINT
PRINT "Press any key to finish."
k$ = INPUT$(1)
END

' ------------------------------------------------------------
' Gcd&: Euclid's algorithm.
' ------------------------------------------------------------
FUNCTION Gcd& (a&, b&)
    x& = a&: y& = b&
    DO WHILE y& <> 0: t& = x& MOD y&: x& = y&: y& = t&: LOOP
    Gcd& = x&
END FUNCTION

' ------------------------------------------------------------
' InvMod&: Extended Euclid (see AFFINE.BAS for a step-by-step
' table).  Finds s with a*s MOD m = 1.
' ------------------------------------------------------------
FUNCTION InvMod& (a&, m&)
    r0& = m&: r1& = a&: s0& = 0: s1& = 1
    DO WHILE r1& <> 0
        q& = r0& \ r1&
        t& = r0& - q& * r1&: r0& = r1&: r1& = t&
        t& = s0& - q& * s1&: s0& = s1&: s1& = t&
    LOOP
    InvMod& = ((s0& MOD m&) + m&) MOD m&
END FUNCTION

' ------------------------------------------------------------
' IsPrime%: trial division by 2 and odd numbers up to sqrt(n).
' ------------------------------------------------------------
FUNCTION IsPrime% (n&)
    IsPrime% = 0
    IF n& < 2 THEN EXIT FUNCTION
    IF n& = 2 THEN IsPrime% = 1: EXIT FUNCTION
    IF n& MOD 2 = 0 THEN EXIT FUNCTION
    d& = 3
    DO WHILE d& * d& <= n&
        IF n& MOD d& = 0 THEN EXIT FUNCTION
        d& = d& + 2
    LOOP
    IsPrime% = 1
END FUNCTION

' ------------------------------------------------------------
' Pause: wait for a key; Esc ends the program.
' ------------------------------------------------------------
SUB Pause
    PRINT
    COLOR 8: PRINT "Press any key (Esc = quit)..."; : COLOR 7
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN CLS : END
END SUB

' ------------------------------------------------------------
' PowMod&: b^e MOD m by square-and-multiply.  Because n <= 46340,
' every product is below 46340^2 = 2,147,395,600, which just fits
' in a LONG (max 2,147,483,647).
' ------------------------------------------------------------
FUNCTION PowMod& (b&, e&, m&)
    r& = 1: x& = b& MOD m&: k& = e&
    DO WHILE k& > 0
        IF k& AND 1 THEN r& = (r& * x&) MOD m&
        x& = (x& * x&) MOD m&
        k& = k& \ 2
    LOOP
    PowMod& = r&
END FUNCTION
