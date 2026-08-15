' ============================================================
' TITLE:    Periodic Table Explorer
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     chemistry, elements, data, search, strings
' SUMMARY:  Look up chemical elements by name, symbol or number and see where they sit in the periodic table.
' ------------------------------------------------------------
' WHAT IT DOES
'   Holds facts about the first 54 elements (hydrogen to xenon) plus
'   a few famous heavy ones (gold, mercury, lead, uranium...) in
'   DATA statements.  It draws the top of the periodic table and
'   lets you search.  The element you find lights up in the table,
'   and the program explains its atomic number, mass, family and
'   whether it is a solid, liquid or gas at room temperature.
'
' HOW TO USE
'   Type a symbol (Fe), a name (iron) or a number (26) and press
'   Enter.  Type Q or just press Enter to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Atomic number = number of protons (and electrons)
'   * Periods (rows) and groups (columns); elements in a group
'     behave alike because of their outer electrons
'   * Searching an array, case-insensitive with UCASE$
'   * Storing a table in DATA statements
'
' THINGS TO TRY
'   * Find all the noble gases (group 18).  Why are they so unreactive?
'   * Add a "discovered in" year to each DATA line.
'   * Add a quiz mode: show a symbol, ask for the name.
' ============================================================

DEFINT A-Z
CONST NEL = 61

' One record per element
TYPE Element
    num AS INTEGER
    sym AS STRING * 2
    nm AS STRING * 10
    mass AS SINGLE
    grp AS INTEGER          ' column 1-18 (0 = not drawn in our table)
    per AS INTEGER          ' row (period) 1-7
    fam AS INTEGER          ' family code, see famName$ below
    phase AS STRING * 1     ' S solid, L liquid, G gas (at 20 C)
END TYPE
DIM el(NEL) AS Element

DIM famName$(9), famCol(9)
FOR i = 0 TO 9: READ famName$(i), famCol(i): NEXT
DATA "Nonmetal",10,"Noble gas",13,"Alkali metal",12,"Alkaline earth metal",6
DATA "Metalloid",3,"Halogen",11,"Transition metal",9,"Post-transition metal",7
DATA "Lanthanide",5,"Actinide",4

FOR i = 1 TO NEL
    READ el(i).num, el(i).sym, el(i).nm, el(i).mass, el(i).grp, el(i).per, el(i).fam, el(i).phase
NEXT
' number, symbol, name, atomic mass, group, period, family, phase
DATA 1,H,Hydrogen,1.008,1,1,0,G
DATA 2,He,Helium,4.003,18,1,1,G
DATA 3,Li,Lithium,6.94,1,2,2,S
DATA 4,Be,Beryllium,9.012,2,2,3,S
DATA 5,B,Boron,10.81,13,2,4,S
DATA 6,C,Carbon,12.011,14,2,0,S
DATA 7,N,Nitrogen,14.007,15,2,0,G
DATA 8,O,Oxygen,15.999,16,2,0,G
DATA 9,F,Fluorine,18.998,17,2,5,G
DATA 10,Ne,Neon,20.18,18,2,1,G
DATA 11,Na,Sodium,22.99,1,3,2,S
DATA 12,Mg,Magnesium,24.305,2,3,3,S
DATA 13,Al,Aluminium,26.982,13,3,7,S
DATA 14,Si,Silicon,28.085,14,3,4,S
DATA 15,P,Phosphorus,30.974,15,3,0,S
DATA 16,S,Sulfur,32.06,16,3,0,S
DATA 17,Cl,Chlorine,35.45,17,3,5,G
DATA 18,Ar,Argon,39.948,18,3,1,G
DATA 19,K,Potassium,39.098,1,4,2,S
DATA 20,Ca,Calcium,40.078,2,4,3,S
DATA 21,Sc,Scandium,44.956,3,4,6,S
DATA 22,Ti,Titanium,47.867,4,4,6,S
DATA 23,V,Vanadium,50.942,5,4,6,S
DATA 24,Cr,Chromium,51.996,6,4,6,S
DATA 25,Mn,Manganese,54.938,7,4,6,S
DATA 26,Fe,Iron,55.845,8,4,6,S
DATA 27,Co,Cobalt,58.933,9,4,6,S
DATA 28,Ni,Nickel,58.693,10,4,6,S
DATA 29,Cu,Copper,63.546,11,4,6,S
DATA 30,Zn,Zinc,65.38,12,4,6,S
DATA 31,Ga,Gallium,69.723,13,4,7,S
DATA 32,Ge,Germanium,72.63,14,4,4,S
DATA 33,As,Arsenic,74.922,15,4,4,S
DATA 34,Se,Selenium,78.971,16,4,0,S
DATA 35,Br,Bromine,79.904,17,4,5,L
DATA 36,Kr,Krypton,83.798,18,4,1,G
DATA 37,Rb,Rubidium,85.468,1,5,2,S
DATA 38,Sr,Strontium,87.62,2,5,3,S
DATA 39,Y,Yttrium,88.906,3,5,6,S
DATA 40,Zr,Zirconium,91.224,4,5,6,S
DATA 41,Nb,Niobium,92.906,5,5,6,S
DATA 42,Mo,Molybdenum,95.95,6,5,6,S
DATA 43,Tc,Technetium,98,7,5,6,S
DATA 44,Ru,Ruthenium,101.07,8,5,6,S
DATA 45,Rh,Rhodium,102.91,9,5,6,S
DATA 46,Pd,Palladium,106.42,10,5,6,S
DATA 47,Ag,Silver,107.87,11,5,6,S
DATA 48,Cd,Cadmium,112.41,12,5,6,S
DATA 49,In,Indium,114.82,13,5,7,S
DATA 50,Sn,Tin,118.71,14,5,7,S
DATA 51,Sb,Antimony,121.76,15,5,4,S
DATA 52,Te,Tellurium,127.6,16,5,4,S
DATA 53,I,Iodine,126.9,17,5,5,S
DATA 54,Xe,Xenon,131.29,18,5,1,G
DATA 55,Cs,Caesium,132.91,1,6,2,S
DATA 74,W,Tungsten,183.84,6,6,6,S
DATA 78,Pt,Platinum,195.08,10,6,6,S
DATA 79,Au,Gold,196.97,11,6,6,S
DATA 80,Hg,Mercury,200.59,12,6,6,L
DATA 82,Pb,Lead,207.2,14,6,7,S
DATA 92,U,Uranium,238.03,0,7,9,S

found = 0
DO
    GOSUB DrawTable
    LOCATE 19, 1: COLOR 7
    IF found THEN GOSUB ShowInfo
    LOCATE 24, 1: COLOR 15
    LINE INPUT "Element (symbol, name or number; Enter = quit): "; q$
    q$ = UCASE$(LTRIM$(RTRIM$(q$)))
    IF q$ = "" OR q$ = "Q" THEN EXIT DO
    ' ---- search: compare against number, symbol and name -----------
    found = 0
    FOR i = 1 TO NEL
        IF VAL(q$) > 0 AND VAL(q$) = el(i).num THEN found = i
        IF q$ = UCASE$(RTRIM$(el(i).sym)) THEN found = i
        IF q$ = UCASE$(RTRIM$(el(i).nm)) THEN found = i
    NEXT
    IF found = 0 THEN
        LOCATE 25, 1: COLOR 12: PRINT "Sorry, '"; LEFT$(q$, 20); "' is not in this table. Press a key.";
        DO: LOOP WHILE INKEY$ = ""
    END IF
LOOP
COLOR 7: CLS
END

' ------------------------------------------------------------
' DrawTable: each element is a 4-character box at column grp*4,
' row per*2.  The found element is shown in reverse colours.
' ------------------------------------------------------------
DrawTable:
    CLS
    COLOR 14: LOCATE 1, 1: PRINT "PERIODIC TABLE EXPLORER  (periods 1-6, partial)"
    FOR i = 1 TO NEL
        IF el(i).grp > 0 THEN
            LOCATE 1 + el(i).per * 2, el(i).grp * 4 - 2
            IF i = found THEN COLOR 0, 7 ELSE COLOR famCol(el(i).fam), 0
            PRINT " "; el(i).sym; " ";
            COLOR 7, 0
        END IF
    NEXT
    ' a key of the family colours along the bottom
    LOCATE 16, 1
    FOR f = 0 TO 7
        COLOR famCol(f): PRINT famName$(f); "  ";
    NEXT
    COLOR 7
RETURN

' ShowInfo: the facts about element number "found"
ShowInfo:
    e = found
    COLOR 15
    PRINT RTRIM$(el(e).nm); " ("; RTRIM$(el(e).sym); ")   atomic number"; el(e).num;
    PRINT USING "   mass ###.### u"; el(e).mass
    COLOR famCol(el(e).fam): PRINT "Family: "; famName$(el(e).fam);
    COLOR 7
    SELECT CASE el(e).phase
        CASE "S": p$ = "solid"
        CASE "L": p$ = "liquid"
        CASE ELSE: p$ = "gas"
    END SELECT
    PRINT "   - a "; p$; " at room temperature"
    PRINT "It has"; el(e).num; "protons and (when neutral)"; el(e).num; "electrons,";
    PRINT " about"; CINT(el(e).mass) - el(e).num; "neutrons."
    IF el(e).grp > 0 THEN PRINT "Period"; el(e).per; " group"; el(e).grp ELSE PRINT "Period"; el(e).per; "(actinide row, not drawn)"
RETURN
