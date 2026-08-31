' ============================================================
' TITLE:    Password Strength Meter
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     passwords, entropy, LOG, brute force, INKEY$, security
' SUMMARY:  A live meter that rates your password as you type, estimating how long a computer would need to guess it.
' ------------------------------------------------------------
' WHAT IT DOES
'   An attacker who steals a password database can try BILLIONS of
'   guesses per second on a gaming graphics card.  How long would it
'   take to guess yours?
'
'   ENTROPY measures how unpredictable a password is, in bits:
'        entropy = length * LOG2(size of the character pool)
'   The pool is the set of characters you seem to use:
'        lowercase 26, UPPERCASE 26, digits 10, symbols about 33
'   Every extra bit DOUBLES the number of guesses needed:
'        guesses = 2 ^ entropy
'
'   But attackers are smart: they try common passwords and patterns
'   FIRST.  "password1" uses letters and digits, yet it is in every
'   cracking list and falls instantly.  So this meter also subtracts
'   points for common words, repeats (aaaa) and runs (abcd, 1234).
'
'   The lesson: LENGTH beats complexity.  Four random common words
'   ("correct horse battery staple", from the XKCD comic) are easier
'   to remember and stronger than "Tr0ub4dor&3".
'
'   This meter is only an ESTIMATE.  It can't tell that a passphrase
'   is built from dictionary words, so it over-rates them: four words
'   picked at random from a 2048-word list really give 4 * 11 = 44
'   bits - still far better than most "clever" short passwords.
'
' HOW TO USE
'   Type a password - the meter updates on every key.
'   Backspace = delete,  TAB = show/hide the password,
'   Enter = clear,  Esc = quit.
'   (Don't type your REAL password into any program you don't trust -
'   including this one!)
'
' CONCEPTS YOU WILL LEARN
'   * Logarithms:  LOG(x) / LOG(2) gives log base 2
'   * Exponential growth: why 1 more character matters so much
'   * Pattern detection with INSTR and ASC differences
'   * A live-updating screen with INKEY$ and LOCATE
'
' THINGS TO TRY
'   * Compare "aaaaaaaaaaaa", "Password1!" and "purple monkey dishwasher"
'   * Add more words to the common list in DATA
'   * Change GUESSES (guesses per second) to model a slower attacker
' ============================================================

DECLARE SUB Analyze (pw$)
DECLARE FUNCTION CrackTime$ (bits!)

CONST GUESSES = 1E+10          ' guesses per second (a fast GPU rig)

DIM SHARED common$(30), nCommon
DO
    READ w$
    IF w$ = "*" THEN EXIT DO
    nCommon = nCommon + 1: common$(nCommon) = w$
LOOP
DATA password,123456,qwerty,letmein,dragon,monkey,football,iloveyou
DATA admin,welcome,abc123,sunshine,princess,master,shadow,baseball
DATA superman,trustno1,hello,freedom,whatever,login,starwars,pokemon
DATA *

pw$ = "": showIt = 0
CLS
COLOR 14: PRINT " PASSWORD STRENGTH METER": COLOR 7
PRINT " Type a password.  Backspace=delete  TAB=show/hide  Enter=clear  Esc=quit"
DO
    ' ---- Show the password (or stars) ----
    LOCATE 4, 2: PRINT SPACE$(78);
    LOCATE 4, 2: PRINT "Password: ";
    IF showIt THEN PRINT pw$; ELSE PRINT STRING$(LEN(pw$), "*");
    COLOR 15: PRINT "_"; : COLOR 7
    Analyze pw$

    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE k$
    CASE CHR$(27): EXIT DO
    CASE CHR$(8): IF LEN(pw$) > 0 THEN pw$ = LEFT$(pw$, LEN(pw$) - 1)
    CASE CHR$(13): pw$ = ""
    CASE CHR$(9): showIt = 1 - showIt
    CASE ELSE
        IF LEN(k$) = 1 AND ASC(k$) >= 32 AND LEN(pw$) < 60 THEN pw$ = pw$ + k$
    END SELECT
LOOP
CLS
PRINT "Stay safe: use long passphrases and a different one for every site!"
END

' ------------------------------------------------------------
' Analyze: compute the pool size, the entropy and penalties, then
' draw the meter and the list of findings.
' ------------------------------------------------------------
SUB Analyze (pw$)
    n = LEN(pw$)
    lower = 0: upper = 0: digit = 0: symbol = 0
    FOR i = 1 TO n
        c$ = MID$(pw$, i, 1)
        IF c$ >= "a" AND c$ <= "z" THEN
            lower = 1
        ELSEIF c$ >= "A" AND c$ <= "Z" THEN
            upper = 1
        ELSEIF c$ >= "0" AND c$ <= "9" THEN
            digit = 1
        ELSE
            symbol = 1
        END IF
    NEXT i
    pool = lower * 26 + upper * 26 + digit * 10 + symbol * 33

    ' ---- Pattern penalties -------------------------------------
    ' We count "predictable" characters and remove them from the
    ' effective length.  A repeat (same as previous) or a run step
    ' (next letter/digit up or down) adds almost no new surprise.
    predictable = 0
    FOR i = 2 TO n
        d = ASC(MID$(pw$, i, 1)) - ASC(MID$(pw$, i - 1, 1))
        IF d = 0 OR d = 1 OR d = -1 THEN predictable = predictable + 1
    NEXT i
    ' Common password inside?  Then those letters count for ~nothing.
    found$ = ""
    low$ = LCASE$(pw$)
    FOR i = 1 TO nCommon
        IF INSTR(low$, common$(i)) > 0 THEN
            IF LEN(common$(i)) > LEN(found$) THEN found$ = common$(i)
        END IF
    NEXT i
    effLen = n - predictable - LEN(found$) * 3 \ 4
    IF found$ <> "" THEN effLen = effLen + 1   ' the word itself is ~1 guess in a list
    IF effLen < 0 THEN effLen = 0

    IF pool > 0 THEN bits! = effLen * LOG(pool) / LOG(2) ELSE bits! = 0

    ' ---- Draw the meter (0 .. 100 bits across 50 columns) ------
    IF bits! < 28 THEN
        clr = 12: verdict$ = "VERY WEAK"
    ELSEIF bits! < 40 THEN
        clr = 6: verdict$ = "WEAK"
    ELSEIF bits! < 60 THEN
        clr = 14: verdict$ = "OK"
    ELSEIF bits! < 80 THEN
        clr = 10: verdict$ = "STRONG"
    ELSE
        clr = 11: verdict$ = "VERY STRONG"
    END IF
    bar = INT(bits! / 2): IF bar > 50 THEN bar = 50
    LOCATE 6, 2: PRINT "Strength: ";
    COLOR clr: PRINT STRING$(bar, 219); : COLOR 8: PRINT STRING$(50 - bar, 176);
    COLOR clr: PRINT " "; LEFT$(verdict$ + "      ", 11): COLOR 7

    LOCATE 8, 2: PRINT USING "Length: ##   Character pool: ###   Effective entropy: ###.# bits"; n; pool; bits!
    LOCATE 9, 2: PRINT "Time to guess at 10 billion tries/second: "; LEFT$(CrackTime$(bits!) + SPACE$(30), 30)

    ' ---- Findings list ------------------------------------------
    FOR r = 11 TO 20: LOCATE r, 2: PRINT SPACE$(78); : NEXT r
    r = 11
    LOCATE r, 2: COLOR 7: PRINT "Uses: ";
    IF lower THEN COLOR 10 ELSE COLOR 8
    PRINT "lowercase  ";
    IF upper THEN COLOR 10 ELSE COLOR 8
    PRINT "UPPERCASE  ";
    IF digit THEN COLOR 10 ELSE COLOR 8
    PRINT "digits  ";
    IF symbol THEN COLOR 10 ELSE COLOR 8
    PRINT "symbols"
    COLOR 12
    IF n > 0 AND n < 8 THEN r = r + 1: LOCATE r, 2: PRINT "* Too short - aim for at least 12 characters."
    IF found$ <> "" THEN r = r + 1: LOCATE r, 2: PRINT "* Contains the common password '"; found$; "' - attackers try it first!"
    IF predictable > 2 THEN r = r + 1: LOCATE r, 2: PRINT "*"; predictable; "characters are repeats or runs (aaa, abc, 123)."
    COLOR 10
    IF n >= 16 THEN r = r + 1: LOCATE r, 2: PRINT "+ Nice and long - length is the best defence."
    IF lower + upper + digit + symbol >= 3 THEN r = r + 1: LOCATE r, 2: PRINT "+ Good mix of character types."
    COLOR 7
END SUB

' ------------------------------------------------------------
' CrackTime$: on average an attacker finds the password after
' trying HALF of all possibilities:  seconds = 2^bits / 2 / GUESSES
' Then pick a friendly unit.  We compute with LOG10 sizes because
' 2^100 is far too big to print nicely.
' ------------------------------------------------------------
FUNCTION CrackTime$ (bits!)
    secs# = 2# ^ bits! / 2# / GUESSES
    IF secs# < 1 THEN
        CrackTime$ = "instantly"
    ELSEIF secs# < 60 THEN
        CrackTime$ = LTRIM$(STR$(INT(secs#))) + " seconds"
    ELSEIF secs# < 3600 THEN
        CrackTime$ = LTRIM$(STR$(INT(secs# / 60))) + " minutes"
    ELSEIF secs# < 86400 THEN
        CrackTime$ = LTRIM$(STR$(INT(secs# / 3600))) + " hours"
    ELSEIF secs# < 31557600 THEN
        CrackTime$ = LTRIM$(STR$(INT(secs# / 86400))) + " days"
    ELSE
        years# = secs# / 31557600
        IF years# < 1000000 THEN
            CrackTime$ = LTRIM$(STR$(INT(years#))) + " years"
        ELSE
            ' Scientific: 10^k years
            CrackTime$ = "about 10^" + LTRIM$(STR$(INT(LOG(years#) / LOG(10)))) + " years"
        END IF
    END IF
END FUNCTION
