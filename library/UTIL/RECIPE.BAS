' ============================================================
' TITLE:    Metric Recipe Scaler
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     cooking, scaling, ratios, metric, data, rounding
' SUMMARY:  Scale a recipe to any number of servings and convert cups and ounces to grams and millilitres.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick one of the built-in recipes (or type your own), say how
'   many people you are cooking for, and every ingredient is
'   multiplied by   new servings / original servings.
'   American-style amounts (cups, tablespoons, ounces, pounds,
'   Fahrenheit) are converted to metric along the way.  Flour,
'   sugar and butter weigh different amounts per cup, so "dry"
'   cups are converted with a per-ingredient density.
'
'   Amounts are rounded sensibly: big ones to the nearest 5 g,
'   small ones to one decimal place, and eggs to whole eggs.
'
' HOW TO USE
'   Choose a recipe number, then the number of servings.
'   Q or Esc at the menu quits.
'
' CONCEPTS YOU WILL LEARN
'   * Ratios and scaling: new = old * (wanted / original)
'   * Storing structured data (amount, unit, name) in DATA
'   * Unit conversion with SELECT CASE
'   * Rounding to the nearest 5 with INT(x / 5 + .5) * 5
'
' THINGS TO TRY
'   * Add your favourite recipe to the DATA.
'   * Add a "convert metric back to cups" mode.
'   * Print a shopping list combining two recipes.
' ============================================================

DECLARE FUNCTION Nice$ (x#)

DIM title$(1 TO 3), serves(1 TO 3), oven(1 TO 3), start(1 TO 3)

' ---- Index the recipes: remember where each starts in DATA ----
' Each recipe:  title, serves, oven temp F (0 = none), then lines
' of amount, unit, grams-per-cup (0 if not needed), ingredient,
' ending with 0,"END",0,"".
RESTORE Recipes
FOR r = 1 TO 3
    READ title$(r), serves(r), oven(r)
    DO
        READ a#, u$, g, ing$
    LOOP UNTIL u$ = "END"
NEXT r

DO
    CLS
    COLOR 14: PRINT "METRIC RECIPE SCALER": COLOR 7
    PRINT
    FOR r = 1 TO 3
        PRINT "  "; LTRIM$(STR$(r)); ". "; title$(r); " (serves"; serves(r); ")"
    NEXT r
    PRINT "  Q. Quit"
    PRINT
    PRINT "  Recipe: ";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    r = VAL(k$)
    IF r >= 1 AND r <= 3 THEN
        PRINT k$
        INPUT "  How many servings"; want
        IF want <= 0 THEN want = serves(r)
        f# = want / serves(r)            ' THE scale factor
        PRINT
        COLOR 15: PRINT "  "; UCASE$(title$(r)); " for"; want; "(x";
        PRINT USING "#.##"; f#;: PRINT ")": COLOR 7
        PRINT "  "; STRING$(50, "-")

        ' Skip forward in the DATA to recipe r.
        RESTORE Recipes
        FOR skip = 1 TO r
            READ t$, s, o
            IF skip < r THEN
                DO: READ a#, u$, g, ing$: LOOP UNTIL u$ = "END"
            END IF
        NEXT skip

        DO
            READ a#, u$, g, ing$
            IF u$ = "END" THEN EXIT DO
            amt# = a# * f#
            ' Convert to metric.  g = grams in one cup of THIS
            ' ingredient (flour is light, sugar heavier, ...).
            SELECT CASE u$
                CASE "cup"
                    IF g > 0 THEN out$ = Nice$(amt# * g) + " g" ELSE out$ = Nice$(amt# * 240) + " ml"
                CASE "tbsp": out$ = Nice$(amt# * 15) + " ml"
                CASE "tsp": out$ = Nice$(amt# * 5) + " ml"
                CASE "oz": out$ = Nice$(amt# * 28.35) + " g"
                CASE "lb": out$ = Nice$(amt# * 453.6) + " g"
                CASE "g": out$ = Nice$(amt#) + " g"
                CASE "ml": out$ = Nice$(amt#) + " ml"
                CASE "whole"
                    ' You can't use 2.4 eggs - round, but never to 0.
                    n = INT(amt# + .5): IF n < 1 THEN n = 1
                    out$ = LTRIM$(STR$(n))
                CASE ELSE: out$ = Nice$(amt#) + " " + u$
            END SELECT
            PRINT "  "; LEFT$(out$ + SPACE$(12), 12); ing$
        LOOP
        IF oven(r) > 0 THEN
            ' C = (F - 32) * 5 / 9, rounded to the nearest 5 degrees
            c = INT((oven(r) - 32) * 5 / 9 / 5 + .5) * 5
            PRINT
            PRINT "  Oven:"; oven(r); "F ="; c; "C  (fan oven about"; c - 20; "C)"
        END IF
    ELSE
        PRINT "?"
    END IF
    PRINT
    PRINT "  Press any key..."
    DO: LOOP WHILE INKEY$ = ""
LOOP
CLS
END

Recipes:
DATA "Pancakes", 4, 0
DATA 1.5,cup,125,plain flour
DATA 1.25,cup,0,milk
DATA 1,whole,0,egg(s)
DATA 3,tbsp,0,melted butter
DATA 1,tbsp,0,sugar
DATA 3.5,tsp,0,baking powder
DATA 0,END,0,""
DATA "Chocolate chip cookies", 24, 375
DATA 2.25,cup,125,plain flour
DATA 1,cup,227,butter
DATA 0.75,cup,200,white sugar
DATA 0.75,cup,220,brown sugar
DATA 2,whole,0,egg(s)
DATA 1,tsp,0,vanilla extract
DATA 12,oz,0,chocolate chips
DATA 0,END,0,""
DATA "Tomato soup", 6, 0
DATA 2,lb,0,ripe tomatoes
DATA 1,whole,0,onion(s)
DATA 2,tbsp,0,olive oil
DATA 4,cup,0,vegetable stock
DATA 0.5,cup,0,cream
DATA 0,END,0,""

' Round to a "kitchen-friendly" amount and return it as text.
FUNCTION Nice$ (x#)
    IF x# >= 50 THEN
        v# = INT(x# / 5 + .5) * 5        ' nearest 5
    ELSEIF x# >= 10 THEN
        v# = INT(x# + .5)                ' nearest whole
    ELSE
        v# = INT(x# * 10 + .5) / 10      ' one decimal place
    END IF
    t$ = LTRIM$(STR$(v#))
    IF LEFT$(t$, 1) = "." THEN t$ = "0" + t$   ' ".5" -> "0.5"
    Nice$ = t$
END FUNCTION
