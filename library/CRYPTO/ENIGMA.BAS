' ============================================================
' TITLE:    Rotor Machine (Enigma-Style Simulator)
' CATEGORY: Codes & Cryptography
' LEVEL:    Advanced
' TAGS:     enigma, rotors, permutations, reflector, plugboard, WWII
' SUMMARY:  A working three-rotor cipher machine with plugboard and lamp board; watch each key press travel through the wires.
' ------------------------------------------------------------
' WHAT IT DOES
'   The German Enigma machine (1920s-1945) looked like a typewriter.
'   Pressing a key sent electricity through a maze of wires and lit
'   a lamp showing the cipher letter.  Its secret was ROTORS: wheels
'   with 26 contacts on each side, wired in a scrambled order.  After
'   EVERY key press the right rotor turns one step (and like a car's
'   odometer, it sometimes kicks the next rotor along), so the whole
'   scramble changes from letter to letter.  "AAAAA" might come out
'   as "QDGXM".
'
'   The path of one key press in this simulator:
'     key -> plugboard -> right rotor -> middle -> left -> REFLECTOR
'         -> left (backwards) -> middle -> right -> plugboard -> lamp
'
'   The REFLECTOR sends the signal back through the rotors.  This
'   made the machine RECIPROCAL: with the same settings, typing the
'   ciphertext gives back the plaintext - handy for operators.  But it
'   also meant NO LETTER CAN EVER ENCRYPT TO ITSELF.  Polish
'   mathematicians (Marian Rejewski, 1932) and later Alan Turing's
'   team at Bletchley Park used flaws like this to break Enigma,
'   shortening WWII by an estimated two years.
'
'   NOTE: this is a SIMPLIFIED, ORIGINAL machine for learning.  Its
'   rotor wirings are made up (shuffled from a fixed seed), and the
'   stepping is a plain odometer without the real Enigma's
'   "double-step" quirk.
'
' HOW TO USE
'   Type letters: each one is encrypted, its lamp lights up, and the
'   signal path is printed.  Spaces are ignored like on the real thing.
'   Enter = reset rotors to the start position and clear the tapes
'   TAB   = new settings (start letters and plugboard pairs)
'   Esc   = quit
'   Try it: type a message, write down the output, press Enter, then
'   type the output - the original message comes back!
'
' CONCEPTS YOU WILL LEARN
'   * Permutations and their inverses stored in arrays
'   * Offsets: (x + position) MOD 26 to model a turned wheel
'   * Involutions (a mapping that undoes itself) - the reflector
'   * Odometer-style carry between counters
'
' THINGS TO TRY
'   * Hold down A: look how the output never contains A
'   * Count the possible settings: 26^3 start positions x rotor
'     orders x plugboard pairings (the real one: about 1.6 x 10^20)
'   * Add a fourth rotor, or the real double-stepping rule
' ============================================================

DECLARE SUB Settings ()
DECLARE SUB DrawMachine (lit%)
DECLARE SUB StepRotors ()
DECLARE FUNCTION Fwd% (r%, c%)
DECLARE FUNCTION Bwd% (r%, c%)
DECLARE FUNCTION Encipher% (c%)

' wire(r, i): rotor r maps contact i to wire(r, i).  inv() undoes it.
' r = 0 left, 1 middle, 2 right.
DIM SHARED wire(2, 25), inv(2, 25), refl(25), plug(25), rpos(2), notch(2)
DIM SHARED start$, plugs$, inTape$, outTape$, trace$

' ---- Build three rotors from a FIXED random seed ---------------
' RANDOMIZE with a constant gives the same "random" sequence every
' run, so the wiring is always the same (like a factory-built rotor).
RANDOMIZE 1918                     ' the year Enigma was patented
FOR r = 0 TO 2
    FOR i = 0 TO 25: wire(r, i) = i: NEXT i
    FOR i = 25 TO 1 STEP -1        ' Fisher-Yates shuffle
        j = INT(RND * (i + 1))
        SWAP wire(r, i), wire(r, j)
    NEXT i
    FOR i = 0 TO 25: inv(r, wire(r, i)) = i: NEXT i
NEXT r
notch(0) = 17: notch(1) = 4: notch(2) = 21   ' turnover letters R, E, V

' ---- Reflector: shuffle, then pair neighbours ------------------
' Pairing guarantees refl(refl(x)) = x and refl(x) <> x.
DIM order(25)
FOR i = 0 TO 25: order(i) = i: NEXT i
FOR i = 25 TO 1 STEP -1: j = INT(RND * (i + 1)): SWAP order(i), order(j): NEXT i
FOR i = 0 TO 24 STEP 2
    refl(order(i)) = order(i + 1): refl(order(i + 1)) = order(i)
NEXT i

start$ = "CAB": plugs$ = "AZ BY"
Settings

DO
    DrawMachine lit%
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    lit% = -1
    SELECT CASE k$
    CASE CHR$(27): EXIT DO
    CASE CHR$(13)                  ' reset to start position
        FOR r = 0 TO 2: rpos(r) = ASC(MID$(start$, r + 1, 1)) - 65: NEXT r
        inTape$ = "": outTape$ = "": trace$ = ""
    CASE CHR$(9)                   ' TAB: new settings
        CLS
        COLOR 14: PRINT "MACHINE SETTINGS": COLOR 7
        LINE INPUT "Start letters for left, middle, right rotor (e.g. CAB): "; s$
        s$ = UCASE$(s$)
        IF LEN(s$) = 3 THEN
            ok = 1
            FOR i = 1 TO 3
                IF MID$(s$, i, 1) < "A" OR MID$(s$, i, 1) > "Z" THEN ok = 0
            NEXT i
            IF ok THEN start$ = s$
        END IF
        LINE INPUT "Plugboard pairs (e.g. AZ BY QM, Enter = none): "; p$
        plugs$ = UCASE$(p$)
        Settings
    CASE ELSE
        c$ = UCASE$(k$)
        IF LEN(c$) = 1 AND c$ >= "A" AND c$ <= "Z" THEN
            StepRotors                 ' rotors move BEFORE the signal flows
            lit% = Encipher%(ASC(c$) - 65)
            inTape$ = inTape$ + c$
            outTape$ = outTape$ + CHR$(65 + lit%)
            ' Group the tape in fives, as real operators did.
            IF LEN(inTape$) MOD 6 = 5 THEN inTape$ = inTape$ + " ": outTape$ = outTape$ + " "
            IF LEN(inTape$) > 66 THEN inTape$ = MID$(inTape$, 7): outTape$ = MID$(outTape$, 7)
        END IF
    END SELECT
LOOP
CLS
PRINT "Machine switched off."
END

' ------------------------------------------------------------
' Bwd%: the signal on its way BACK from the reflector through rotor r.
' Same offset trick as Fwd% but using the inverse wiring.
' ------------------------------------------------------------
FUNCTION Bwd% (r%, c%)
    p = rpos(r%)
    Bwd% = (inv(r%, (c% + p) MOD 26) - p + 26) MOD 26
END FUNCTION

' ------------------------------------------------------------
' DrawMachine: rotor windows, lamp board, tapes and signal trace.
' ------------------------------------------------------------
SUB DrawMachine (lit%)
    CLS
    COLOR 14: PRINT " ROTOR MACHINE  (Enigma-style simulator)": COLOR 7
    LOCATE 3, 4: PRINT "Rotor windows:   L   M   R          Start: "; start$
    LOCATE 4, 21
    FOR r = 0 TO 2
        COLOR 0, 7: PRINT " "; CHR$(65 + rpos(r)); " "; : COLOR 7, 0: PRINT " ";
    NEXT r
    LOCATE 4, 37: PRINT "Plugboard: ";
    IF plugs$ = "" THEN PRINT "(none)" ELSE PRINT LEFT$(plugs$, 30)
    ' Lamp board in QWERTZ layout, like the German original.
    rowsTxt$ = "QWERTZUIO ASDFGHJK PYXCVBNML"
    rr = 7: cc = 10
    FOR i = 1 TO LEN(rowsTxt$)
        ch$ = MID$(rowsTxt$, i, 1)
        IF ch$ = " " THEN
            rr = rr + 2: IF rr = 9 THEN cc = 12 ELSE cc = 10   ' middle row is indented
        ELSE
            LOCATE rr, cc
            IF lit% >= 0 AND ASC(ch$) - 65 = lit% THEN COLOR 0, 14 ELSE COLOR 8, 0
            PRINT "("; ch$; ")";
            COLOR 7, 0
            cc = cc + 5
        END IF
    NEXT i
    LOCATE 14, 2: COLOR 11: PRINT "Typed : "; inTape$
    LOCATE 15, 2: COLOR 10: PRINT "Lamps : "; outTape$
    LOCATE 17, 2: COLOR 8: PRINT "Signal path of the last key:"
    LOCATE 18, 2: COLOR 7: PRINT trace$
    LOCATE 21, 2: COLOR 8
    PRINT "Letters = type   Enter = reset to start   TAB = settings   Esc = quit"
    LOCATE 22, 2
    PRINT "Wheels L, M, R turn over after R, E, V (like an odometer)."
    COLOR 7
END SUB

' ------------------------------------------------------------
' Encipher%: follow one letter (0-25) through the whole machine,
' recording each stop in trace$ so the player can see the path.
' ------------------------------------------------------------
FUNCTION Encipher% (c%)
    t$ = CHR$(65 + c%)
    x = plug(c%): t$ = t$ + " >plug " + CHR$(65 + x)
    x = Fwd%(2, (x)): t$ = t$ + " >R " + CHR$(65 + x)
    x = Fwd%(1, (x)): t$ = t$ + " >M " + CHR$(65 + x)
    x = Fwd%(0, (x)): t$ = t$ + " >L " + CHR$(65 + x)
    x = refl(x): t$ = t$ + " >REFL " + CHR$(65 + x)
    x = Bwd%(0, (x)): t$ = t$ + " >L " + CHR$(65 + x)
    x = Bwd%(1, (x)): t$ = t$ + " >M " + CHR$(65 + x)
    x = Bwd%(2, (x)): t$ = t$ + " >R " + CHR$(65 + x)
    x = plug(x): t$ = t$ + " >plug " + CHR$(65 + x)
    trace$ = t$ + "  = lamp " + CHR$(65 + x)
    Encipher% = x
END FUNCTION

' ------------------------------------------------------------
' Fwd%: signal entering rotor r at contact c.
'   A rotor turned by p steps is like the same wiring with every
'   contact relabelled: enter at c + p, follow the wire, then
'   subtract p again on the way out.  MOD 26 wraps around the wheel.
' ------------------------------------------------------------
FUNCTION Fwd% (r%, c%)
    p = rpos(r%)
    Fwd% = (wire(r%, (c% + p) MOD 26) - p + 26) MOD 26
END FUNCTION

' ------------------------------------------------------------
' Settings: apply start positions and plugboard.  The plugboard
' simply swaps pairs of letters before and after the rotors; any
' letter without a cable maps to itself.
' ------------------------------------------------------------
SUB Settings
    FOR r = 0 TO 2: rpos(r) = ASC(MID$(start$, r + 1, 1)) - 65: NEXT r
    FOR i = 0 TO 25: plug(i) = i: NEXT i
    clean$ = ""
    i = 1
    DO WHILE i < LEN(plugs$)
        a = ASC(MID$(plugs$, i, 1)) - 65
        b = ASC(MID$(plugs$, i + 1, 1)) - 65
        ' Use the pair only if both are letters and still unplugged.
        IF a >= 0 AND a <= 25 AND b >= 0 AND b <= 25 AND a <> b THEN
            IF plug(a) = a AND plug(b) = b THEN
                plug(a) = b: plug(b) = a
                clean$ = clean$ + CHR$(65 + a) + CHR$(65 + b) + " "
            END IF
            i = i + 2
        ELSE
            i = i + 1
        END IF
    LOOP
    plugs$ = RTRIM$(clean$)
    inTape$ = "": outTape$ = "": trace$ = ""
END SUB

' ------------------------------------------------------------
' StepRotors: the right rotor always moves.  If it was sitting at
' its notch letter, it also kicks the middle rotor; the middle
' rotor kicks the left one the same way.
' ------------------------------------------------------------
SUB StepRotors
    kickMiddle = (rpos(2) = notch(2))
    rpos(2) = (rpos(2) + 1) MOD 26
    IF kickMiddle THEN
        kickLeft = (rpos(1) = notch(1))
        rpos(1) = (rpos(1) + 1) MOD 26
        IF kickLeft THEN rpos(0) = (rpos(0) + 1) MOD 26
    END IF
END SUB
