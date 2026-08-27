' ============================================================
' TITLE:    Break-Even Analysis Graph
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     break-even, graphs, WINDOW, LINE, PAINT, cost volume profit
' SUMMARY:  Find how many units a business must sell to stop losing money, and see it on a cost/revenue graph.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every business has FIXED costs (rent, salaries - paid even if
'   you sell nothing) and VARIABLE costs (materials for each unit).
'   Each sale brings in the price, but costs the variable cost, so
'   each unit "contributes" (price - variable cost) towards paying
'   the fixed costs. When enough units have been sold to cover the
'   fixed costs, you reach the BREAK-EVEN POINT:
'        units = fixed costs / (price - variable cost)
'   The graph shows the revenue line and the total cost line; they
'   cross at break-even. The area before is a loss (red), after it
'   is a profit (green). Use the arrow keys to try other prices!
'
' HOW TO USE
'   Enter fixed costs, variable cost per unit and selling price.
'   On the graph: Up/Down arrows change the price by $1,
'   Left/Right change the variable cost. Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Contribution margin and break-even formulas
'   * WINDOW to draw in business units (units sold, dollars)
'   * Shading regions with LINE between two lines
'   * Reading arrow keys from INKEY$ (CHR$(0) + scan code)
'
' THINGS TO TRY
'   * Add a "target profit" and find units needed to reach it
'   * Show the margin of safety for a given expected sales volume
'   * Draw the profit line itself (revenue - cost)
' ============================================================

DECLARE SUB DrawGraph (fixed!, vc!, price!)

CLS
PRINT "BREAK-EVEN ANALYSIS"
PRINT
INPUT "Fixed costs per month ($)  [e.g. 6000]"; fixed!
INPUT "Variable cost per unit ($) [e.g. 12]"; vc!
INPUT "Selling price per unit ($) [e.g. 27]"; price!
IF fixed! <= 0 THEN fixed! = 6000
IF vc! < 0 THEN vc! = 12
IF price! <= vc! THEN
    PRINT "Price must be higher than the variable cost, or you never break even!"
    price! = vc! + 15
    PRINT USING "Using a price of $$###.## instead. Press a key."; price!
    k$ = INPUT$(1)
END IF

SCREEN 12
DO
    DrawGraph fixed!, vc!, price!
    ' Wait for a key. Arrow keys arrive as two characters:
    ' CHR$(0) followed by a scan code (72 up, 80 down, 75 left, 77 right).
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    SELECT CASE k$
    CASE CHR$(0) + "H": price! = price! + 1
    CASE CHR$(0) + "P": IF price! - 1 > vc! THEN price! = price! - 1
    CASE CHR$(0) + "M": IF vc! + 1 < price! THEN vc! = vc! + 1
    CASE CHR$(0) + "K": IF vc! >= 1 THEN vc! = vc! - 1
    CASE CHR$(27), "q", "Q": EXIT DO
    END SELECT
LOOP
SCREEN 0
END

' ------------------------------------------------------------
' DrawGraph: plots revenue and total cost from 0 to twice the
' break-even volume, so the crossing is always in the middle.
' ------------------------------------------------------------
SUB DrawGraph (fixed!, vc!, price!)
    cm! = price! - vc!                ' contribution margin per unit
    be! = fixed! / cm!                ' break-even units
    maxU! = be! * 2                   ' x axis goes to 2 x break-even
    maxD! = price! * maxU!            ' y axis: revenue at that volume

    CLS
    ' World coordinates: x = units, y = dollars. Margins for labels.
    VIEW (80, 40)-(620, 400), 0, 15
    WINDOW (0, 0)-(maxU!, maxD!)

    ' Shade the gap between the two lines, one thin strip per step.
    ' Left of break-even cost > revenue (loss, red); right of it
    ' revenue > cost (profit, green).
    steps = 270
    FOR s = 0 TO steps
        u! = maxU! * s / steps
        rev! = price! * u!
        cost! = fixed! + vc! * u!
        IF rev! < cost! THEN c = 4 ELSE c = 2
        LINE (u!, rev!)-(u!, cost!), c
    NEXT s

    ' Fixed cost: a flat dashed line (style &HF0F0 = dash pattern).
    LINE (0, fixed!)-(maxU!, fixed!), 7, , &HF0F0
    ' Total cost = fixed + variable * units (starts at fixed cost)
    LINE (0, fixed!)-(maxU!, fixed! + vc! * maxU!), 12
    ' Revenue = price * units (starts at zero)
    LINE (0, 0)-(maxU!, maxD!), 10
    ' Mark the break-even point with a circle and a drop line.
    LINE (be!, 0)-(be!, price! * be!), 14, , &HCCCC
    ' CIRCLE in WINDOW coordinates uses the x scale for its radius.
    CIRCLE (be!, price! * be!), maxU! / 60, 14

    VIEW                                ' back to full screen
    WINDOW
    COLOR 15
    LOCATE 1, 24: PRINT "BREAK-EVEN CHART  (Esc to quit)"
    LOCATE 2, 11: COLOR 10: PRINT "Revenue";
    COLOR 12: PRINT "   Total cost";
    COLOR 7: PRINT "   Fixed cost";
    COLOR 2: PRINT "   Profit";
    COLOR 4: PRINT "   Loss"
    COLOR 15
    ' Axis labels: top dollars and right units
    LOCATE 3, 1: PRINT USING "######"; maxD!
    LOCATE 25, 1: PRINT "     0"
    LOCATE 26, 10: PRINT "0";
    LOCATE 26, 72: PRINT USING "#######"; maxU!;
    LOCATE 26, 35: PRINT "units sold per month";

    ' -INT(-x) rounds UP (a "ceiling"): you can't sell 399.2 units,
    ' so 400 is the first whole number that breaks even.
    LOCATE 27, 1
    PRINT USING "Price $$###.##   Variable cost $$###.##   Margin $$###.##/unit"; price!; vc!; cm!
    PRINT USING "Fixed costs $$###,###   BREAK-EVEN at ####### units = $$#,###,### of sales"; fixed!; -INT(-be!); price! * -INT(-be!)
    PRINT "Up/Down: change price    Left/Right: change variable cost";
END SUB
