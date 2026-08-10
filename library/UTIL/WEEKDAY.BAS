' ============================================================
' TITLE:    Day of the Week Finder
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     dates, doomsday, mental math, day number
' SUMMARY:  Find the weekday of any date using Conway's Doomsday rule, with every step explained.
' ------------------------------------------------------------
' WHAT IT DOES
'   Type a date and the program tells you what day of the week
'   it was (or will be).  It uses John Conway's "Doomsday"
'   method, which people can do in their HEADS, and prints each
'   step so you can learn to do it yourself:
'
'   1. Every year has a "doomsday" - a weekday shared by easy
'      dates: 4/4, 6/6, 8/8, 10/10, 12/12, 9/5, 5/9, 7/11, 11/7,
'      the last day of February, and 3/7 (well, 3/0 = last of Feb).
'   2. Find the century's anchor day (1900s = Wednesday,
'      2000s = Tuesday, ...).
'   3. Add the year's offset:  y\12 + y MOD 12 + (y MOD 12)\4.
'   4. Count from the nearest doomsday in your month.
'
' HOW TO USE
'   Enter month, day and year (e.g. 7, 20, 1969).  Enter 0 for
'   the month to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Modular arithmetic (MOD 7 for weekdays)
'   * Handling negative numbers with MOD (add 7 first!)
'   * Lookup tables with READ/DATA
'   * Input validation
'
' THINGS TO TRY
'   * Practise mode: show a random date and time how fast you
'     can answer.
'   * Find every Friday the 13th in a given year.
' ============================================================

DIM dayName$(0 TO 6), doom(1 TO 12)
FOR i = 0 TO 6: READ dayName$(i): NEXT i
DATA Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday

' The "doomsday" date in each month (for a NON-leap year).
' Jan 3 and Feb 28 become Jan 4 and Feb 29 in leap years.
FOR i = 1 TO 12: READ doom(i): NEXT i
DATA 3,28,14,4,9,6,11,8,5,10,7,12

CLS
PRINT "DAY OF THE WEEK FINDER  (Conway's Doomsday rule)"
PRINT STRING$(50, "=")
DO
    PRINT
    INPUT "Month (1-12, 0 to quit): ", m
    IF m = 0 THEN EXIT DO
    INPUT "Day: ", d
    INPUT "Year (e.g. 1969): ", y
    m = INT(m): d = INT(d): y = INT(y)

    ' ---- Check the date is real ----
    leap = (y MOD 4 = 0 AND y MOD 100 <> 0) OR (y MOD 400 = 0)
    maxd = 31
    IF m = 4 OR m = 6 OR m = 9 OR m = 11 THEN maxd = 30
    IF m = 2 THEN maxd = 28 - (leap <> 0)     ' TRUE is -1, so this adds 1
    IF m < 1 OR m > 12 OR d < 1 OR d > maxd OR y < 1583 OR y > 9999 THEN
        PRINT "  That is not a valid Gregorian date (1583-9999)."
    ELSE
        ' Step 1: century anchor.  The pattern repeats every 400
        ' years: Tue (2000), Sun (2100), Fri (2200), Wed (2300).
        c = (y \ 100) MOD 4
        anchor = (2 + 5 * c) MOD 7        ' 0->Tue(2) 1->Sun(0) 2->Fri(5) 3->Wed(3)
        PRINT "  Step 1: century anchor for"; (y \ 100) * 100; "is "; dayName$(anchor)

        ' Step 2: year offset inside the century.
        yy = y MOD 100
        a = yy \ 12: b = yy MOD 12: cc = b \ 4
        dd = (anchor + a + b + cc) MOD 7
        PRINT "  Step 2:"; yy; "->"; a; "+"; b; "+"; cc; "extra days"
        PRINT "          so doomsday in"; y; "is a "; dayName$(dd)

        ' Step 3: count from this month's doomsday date.
        ref = doom(m)
        IF leap AND m <= 2 THEN ref = ref + 1
        diff = d - ref
        ' MOD can give a negative answer in BASIC (-3 MOD 7 = -3),
        ' so we add a big multiple of 7 to keep it positive.
        w = (dd + diff + 70) MOD 7
        PRINT "  Step 3: doomsday date in this month is the"; ref
        PRINT "          your date is"; diff; "days from it"
        PRINT
        COLOR 14
        PRINT "  =>"; m; "/"; d; "/"; y; "is a "; dayName$(w)
        COLOR 7
    END IF
LOOP
PRINT "Goodbye."
END
