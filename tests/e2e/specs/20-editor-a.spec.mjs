// Code editor part A: typing with real keys, syntax highlighting, keyword auto-capitalization.
import { open, caret, cur, lines, spans, cls, rendered, clickChar, closeOthers, cleanAll, typeKeys } from './_editor-helpers.mjs';

export default (t) => {
  t.beforeEach(async (p) => { await closeOthers(p); });
  t.afterEach(async (p) => { await cleanAll(p); });

  // ---- typing ----------------------------------------------------------------------------------
  t.test('typing with real key events inserts text into the editor', async (p) => {
    await open(p, '');
    await typeKeys(p, 'PRINT 42');
    p.assert.equal(await p.code(), 'PRINT 42');
  });
  t.test('typed text appears in the highlight layer', async (p) => {
    await open(p, '');
    await typeKeys(p, 'X = 5');
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.children[0].textContent'), 'X = 5');
  });
  t.test('typing inserts at the caret in the middle of a line', async (p) => {
    await open(p, 'PRINT 12', { line: 0, col: 6 });
    await typeKeys(p, '99');
    p.assert.equal(await p.code(), 'PRINT 9912');
  });
  t.test('Backspace deletes the character before the caret', async (p) => {
    await open(p, 'PRINT 123');
    await p.key('Backspace');
    await p.key('Backspace');
    p.assert.equal(await p.code(), 'PRINT 1');
  });
  t.test('Delete removes the character after the caret', async (p) => {
    await open(p, 'ABCDEF', { line: 0, col: 2 });
    await p.key('Delete');
    p.assert.equal(await p.code(), 'ABDEF');
  });
  t.test('Backspace at the start of a line joins it to the previous line', async (p) => {
    await open(p, 'A = 1\nB = 2', { line: 1, col: 0 });
    await p.key('Backspace');
    p.assert.equal(await p.code(), 'A = 1B = 2');
  });
  t.test('Enter splits the line at the caret', async (p) => {
    await open(p, 'CLS PRINT', { line: 0, col: 3 });
    await p.key('Enter');
    const l = await lines(p);
    p.assert.equal(l.length, 2);
    p.assert.equal(l[0], 'CLS');
    p.assert.equal(l[1].trim(), 'PRINT');
  });
  t.test('typing several lines with Enter creates several lines', async (p) => {
    await open(p, '');
    await typeKeys(p, 'A = 1\nB = 2\nC = 3');
    p.assert.deepEqual(await lines(p), ['A = 1', 'B = 2', 'C = 3']);
  });
  t.test('arrow keys move the caret and the status bar shows Ln/Col', async (p) => {
    await open(p, 'AAAA\nBBBB\nCCCC', { line: 0, col: 0 });
    await p.key('ArrowDown');
    await p.key('ArrowDown');
    await p.key('ArrowRight');
    await p.key('ArrowRight');
    p.assert.deepEqual(await cur(p), { line: 2, col: 2 });
    p.assert.match(await p.status(), /Ln 3, Col 3/);
  });
  t.test('ArrowUp and ArrowLeft move the caret back', async (p) => {
    await open(p, 'AAAA\nBBBB', { line: 1, col: 3 });
    await p.key('ArrowUp');
    await p.key('ArrowLeft');
    p.assert.deepEqual(await cur(p), { line: 0, col: 2 });
  });
  t.test('status bar column updates as you type', async (p) => {
    await open(p, '');
    await typeKeys(p, 'ABCDE');
    p.assert.match(await p.status(), /Ln 1, Col 6/);
  });
  t.test('clicking in the text places the caret at that character', async (p) => {
    await open(p, 'PRINT "HELLO"\nX = 1\nY = 2', { line: 0, col: 0 });
    await clickChar(p, 2, 2);
    const c = await cur(p);
    p.assert.equal(c.line, 2);
    p.assert.ok(c.col === 2 || c.col === 3, 'col ' + c.col);
  });
  t.test('the editor textarea has spellcheck and autocorrect turned off', async (p) => {
    await open(p, '');
    p.assert.equal(await p.ev('RC.app.active.editor.ta.getAttribute("spellcheck")'), 'false');
    p.assert.equal(await p.ev('RC.app.active.editor.ta.getAttribute("autocorrect")'), 'off');
    p.assert.equal(await p.ev('RC.app.active.editor.ta.getAttribute("aria-label")'), 'Code editor');
  });

  // ---- syntax highlighting --------------------------------------------------------------------------
  const HL = [
    ['statement keyword', 'PRINT X', 's-kw', ['PRINT']],
    ['control keywords IF/THEN/ELSE', 'IF A THEN B ELSE C', 's-kw', ['IF', 'THEN', 'ELSE']],
    ['FOR/TO/STEP keywords', 'FOR I = 1 TO 9 STEP 2', 's-kw', ['FOR', 'TO', 'STEP']],
    ['lowercase keyword before capitalization', 'print x', 's-kw', ['print']],
    ['builtin function LEN', 'N = LEN(A$)', 's-fn', ['LEN']],
    ['builtin string function CHR$', 'C$ = CHR$(65)', 's-fn', ['CHR$']],
    ['several builtin functions', 'X = ABS(SIN(Y)) + INT(RND * 6)', 's-fn', ['ABS', 'SIN', 'INT', 'RND']],
    ['SCREEN statement is a keyword not a function', 'SCREEN 13', 's-kw', ['SCREEN']],
    ['LINE statement is a keyword', 'LINE (0, 0)-(9, 9)', 's-kw', ['LINE']],
    ['INPUT statement is a keyword', 'INPUT N', 's-kw', ['INPUT']],
    ['string literal including quotes', 'PRINT "Hello, World"', 's-str', ['"Hello, World"']],
    ['unterminated string runs to end of line', 'PRINT "abc', 's-str', ['"abc']],
    ['empty string', 'A$ = ""', 's-str', ['""']],
    ['integer number', 'X = 42', 's-num', ['42']],
    ['decimal and exponent numbers', 'X = 1.5E3 + .25', 's-num', ['1.5E3', '.25']],
    ['hex and octal literals', 'X = &H1F + &O17', 's-num', ['&H1F', '&O17']],
    ['number with type suffix', 'X# = 3#', 's-num', ['3#']],
    ['apostrophe comment covers rest of line', "X = 1 ' set x to one", 's-com', ["' set x to one"]],
    ['whole-line apostrophe comment', "' just a comment", 's-com', ["' just a comment"]],
    ['REM keyword is a comment', 'REM hello', 's-com', ['REM hello']],
    ['$INCLUDE metacommand', "'$INCLUDE: 'LIB.BI'", 's-meta', ["'$INCLUDE: 'LIB.BI'"]],
    ['$DYNAMIC metacommand', "'$DYNAMIC", 's-meta', ["'$DYNAMIC"]],
    ['DATA body', 'DATA 1, two, "three"', 's-data', ['1, two, "three"']],
    ['DATA keyword itself', 'DATA 5', 's-kw', ['DATA']],
    ['leading line number', '10 PRINT "HI"', 's-ln', ['10']],
    ['label at start of line', 'Main:', 's-lbl', ['Main:']],
    ['label followed by a statement', 'Again: PRINT', 's-lbl', ['Again:']],
    ['arithmetic operators', 'X = A + B - C * D / E ^ F', 's-op', ['=', '+', '-', '*', '/', '^']],
    ['comparison operators', 'IF A <> B OR C <= D OR E >= F THEN', 's-op', ['<>', '<=', '>=']],
    ['punctuation operators', 'PRINT A; B, C: CLS', 's-op', [';', ',', ':']],
    ['parentheses are operators', 'X = (1)', 's-op', ['=', '(', ')']],
    ['FN name in DEF FN', 'DEF FNsq (X) = X * X', 's-fn', ['FNsq']],
    ['FN name in a call', 'Y = FNsq(3)', 's-fn', ['FNsq']],
    ['bad character', 'X = 1 ` 2', 's-bad', ['`']],
  ];
  for (const [name, text, c, want] of HL) {
    t.test('highlight: ' + name + ' → ' + c, async (p) => {
      await open(p, '');
      await typeKeys(p, text);
      p.assert.equal(await p.code(), text);
      p.assert.deepEqual(await cls(p, 0, c), want);
    });
  }
  t.test('highlight: REM comment text is highlighted as a comment', async (p) => {
    await open(p, '');
    await typeKeys(p, 'REM hello world');
    const s = await spans(p, 0);
    const commentText = s.filter((x) => x[0] === 's-com').map((x) => x[1]).join('');
    p.assert.equal(commentText, 'REM hello world', 'spans: ' + JSON.stringify(s));
  });
  t.test('highlight: REM $DYNAMIC metacommand text is highlighted as metacommand', async (p) => {
    await open(p, '');
    await typeKeys(p, 'REM $DYNAMIC');
    const s = await spans(p, 0);
    p.assert.equal(s.filter((x) => x[0] === 's-meta').map((x) => x[1]).join(''), 'REM $DYNAMIC', JSON.stringify(s));
  });
  t.test('highlight: GOTO target is a number, not a line-number label', async (p) => {
    await open(p, '');
    await typeKeys(p, 'GOTO 100');
    p.assert.deepEqual(await cls(p, 0, 's-num'), ['100']);
    p.assert.deepEqual(await cls(p, 0, 's-ln'), []);
  });
  t.test('highlight: DATA body stops at a colon', async (p) => {
    await open(p, '');
    await typeKeys(p, 'DATA 1,2: PRINT');
    p.assert.deepEqual(await cls(p, 0, 's-data'), ['1,2']);
    p.assert.deepEqual(await cls(p, 0, 's-kw'), ['DATA', 'PRINT']);
  });
  t.test('highlight: plain identifiers are not wrapped in a span', async (p) => {
    await open(p, '');
    await typeKeys(p, 'total = count');
    const s = await spans(p, 0);
    p.assert.ok(s.some((x) => x[0] === '' && x[1].includes('total')), JSON.stringify(s));
    p.assert.ok(s.some((x) => x[0] === '' && x[1].includes('count')), JSON.stringify(s));
  });
  t.test('highlight: keywords inside a string are not keywords', async (p) => {
    await open(p, '');
    await typeKeys(p, 'PRINT "FOR NEXT GOTO"');
    p.assert.deepEqual(await cls(p, 0, 's-kw'), ['PRINT']);
  });
  t.test('highlight: keywords inside a comment are not keywords', async (p) => {
    await open(p, '');
    await typeKeys(p, "CLS ' PRINT FOR");
    p.assert.deepEqual(await cls(p, 0, 's-kw'), ['CLS']);
  });
  t.test('highlight: HTML characters in code are shown literally', async (p) => {
    await open(p, '');
    await typeKeys(p, 'PRINT "<b>&amp;</b>"');
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.children[0].textContent'), 'PRINT "<b>&amp;</b>"');
    p.assert.equal(await p.ev('RC.app.active.editor.hl.querySelectorAll("b").length'), 0);
  });
  t.test('highlight: typing an opening quote turns the rest of the line into a string', async (p) => {
    await open(p, 'PRINT X + Y', { line: 0, col: 6 });
    p.assert.deepEqual(await cls(p, 0, 's-str'), []);
    await typeKeys(p, '"');
    p.assert.deepEqual(await cls(p, 0, 's-str'), ['"X + Y']);
  });
  t.test('highlight: deleting the comment marker restores highlighting', async (p) => {
    await open(p, "'PRINT 5", { line: 0, col: 1 });
    p.assert.deepEqual(await cls(p, 0, 's-kw'), []);
    await p.key('Backspace');
    p.assert.deepEqual(await cls(p, 0, 's-kw'), ['PRINT']);
    p.assert.deepEqual(await cls(p, 0, 's-num'), ['5']);
  });
  t.test('highlight layer text matches the textarea on every line', async (p) => {
    const src = '10 CLS\nMain:\n  FOR I = 1 TO 3 \' loop\n    PRINT "x"; I\n  NEXT\nDATA 1, 2\nREM end';
    await open(p, src);
    await rendered(p);
    const hl = await p.ev('[...RC.app.active.editor.hl.children].map((e) => e.textContent)');
    p.assert.deepEqual(hl.map((s) => s === ' ' ? '' : s), src.split('\n'));
  });
  t.test('highlight: a mixed line gets the right class for each token', async (p) => {
    await open(p, '');
    await typeKeys(p, '20 IF LEN(A$) > 3 THEN PRINT "LONG" \' check');
    const s = (await spans(p, 0)).filter((x) => x[0]);
    p.assert.deepEqual(s, [['s-ln', '20'], ['s-kw', 'IF'], ['s-fn', 'LEN'], ['s-op', '('], ['s-op', ')'], ['s-op', '>'], ['s-num', '3'], ['s-kw', 'THEN'], ['s-kw', 'PRINT'], ['s-str', '"LONG"'], ['s-com', "' check"]]);
  });
  t.test('highlight colors differ for keywords, strings, numbers and comments', async (p) => {
    await open(p, 'PRINT "S"; 1 \' c');
    await rendered(p);
    const colors = await p.ev('["s-kw","s-str","s-num","s-com"].map((c) => getComputedStyle(RC.app.active.editor.hl.querySelector("." + c)).color)');
    p.assert.equal(new Set(colors).size, 4, JSON.stringify(colors));
  });

  // ---- keyword auto-capitalization ---------------------------------------------------------------------
  t.test('keywords are capitalized when Enter leaves the line', async (p) => {
    await open(p, '');
    await typeKeys(p, 'print x\n');
    p.assert.equal((await lines(p))[0], 'PRINT x');
  });
  t.test('keywords are not capitalized while still on the line', async (p) => {
    await open(p, '');
    await typeKeys(p, 'print x');
    p.assert.equal(await p.code(), 'print x');
  });
  t.test('keywords are capitalized when ArrowDown leaves the line', async (p) => {
    await open(p, '\nCLS', { line: 0, col: 0 });
    await typeKeys(p, 'for i = 1 to 5 step 2');
    await p.key('ArrowDown');
    p.assert.equal((await lines(p))[0], 'FOR i = 1 TO 5 STEP 2');
  });
  t.test('keywords are capitalized when ArrowUp leaves the line', async (p) => {
    await open(p, 'CLS\n', { line: 1, col: 0 });
    await typeKeys(p, 'goto 10');
    await p.key('ArrowUp');
    p.assert.equal((await lines(p))[1], 'GOTO 10');
  });
  t.test('keywords are capitalized when clicking onto another line', async (p) => {
    await open(p, 'CLS\nX = 1\n', { line: 2, col: 0 });
    await typeKeys(p, 'locate 1, 1: color 14');
    await clickChar(p, 0, 1);
    p.assert.equal((await lines(p))[2], 'LOCATE 1, 1: COLOR 14');
  });
  t.test('keywords are capitalized when the editor loses focus', async (p) => {
    await open(p, '');
    await typeKeys(p, 'beep');
    await p.click('#statusbar');
    await p.sleep(50);
    p.assert.equal(await p.code(), 'BEEP');
  });
  t.test('builtin functions are capitalized too', async (p) => {
    await open(p, '');
    await typeKeys(p, 'n = len(a$) + asc(chr$(65))\n');
    p.assert.equal((await lines(p))[0], 'n = LEN(a$) + ASC(CHR$(65))');
  });
  t.test('words inside strings are not capitalized', async (p) => {
    await open(p, '');
    await typeKeys(p, 'print "print for next"\n');
    p.assert.equal((await lines(p))[0], 'PRINT "print for next"');
  });
  t.test('words inside apostrophe comments are not capitalized', async (p) => {
    await open(p, '');
    await typeKeys(p, "cls ' print the screen\n");
    p.assert.equal((await lines(p))[0], "CLS ' print the screen");
  });
  t.test('words after REM are not capitalized', async (p) => {
    await open(p, '');
    await typeKeys(p, 'REM print this later\n');
    p.assert.equal((await lines(p))[0], 'REM print this later');
  });
  t.test('lowercase rem keyword is capitalized like other keywords', async (p) => {
    await open(p, '');
    await typeKeys(p, 'rem note\n');
    p.assert.equal((await lines(p))[0], 'REM note');
  });
  t.test('identifiers that contain keywords are left alone', async (p) => {
    await open(p, '');
    await typeKeys(p, 'printer = format + tone\n');
    p.assert.equal((await lines(p))[0], 'printer = format + tone');
  });
  t.test('variable names keep their case while keywords are capitalized', async (p) => {
    await open(p, '');
    await typeKeys(p, 'if myScore > 10 then print myScore\n');
    p.assert.equal((await lines(p))[0], 'IF myScore > 10 THEN PRINT myScore');
  });
  t.test('capitalization keeps the caret on the new line', async (p) => {
    await open(p, '');
    await typeKeys(p, 'cls\nab');
    p.assert.deepEqual(await lines(p), ['CLS', 'ab']);
    p.assert.deepEqual(await cur(p), { line: 1, col: 2 });
  });
  t.test('Options menu shows "Capitalize Keywords As You Type" checked by default', async (p) => {
    await p.click('.menu-btn', 'Options');
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((x) => x.label === 'Capitalize Keywords As You Type');
    await p.closeMenus();
    p.assert.ok(it && it.checked);
  });
  t.test('turning off capitalization in Options leaves keywords as typed', async (p) => {
    await p.menu('Options', 'Capitalize Keywords As You Type');
    p.assert.equal(await p.ev('RC.app.settings.autoFormat'), false);
    await open(p, '');
    await typeKeys(p, 'print x\ncls\n');
    p.assert.deepEqual((await lines(p)).slice(0, 2), ['print x', 'cls']);
    await p.click('.menu-btn', 'Options');
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((x) => x.label === 'Capitalize Keywords As You Type');
    await p.closeMenus();
    p.assert.equal(it.checked, false);
  });
  t.test('capitalization setting off persists across reload', async (p) => {
    await cleanAll(p);
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.autoFormat'), false);
    await open(p, '');
    await typeKeys(p, 'end\n');
    p.assert.equal((await lines(p))[0], 'end');
  });
  t.test('turning capitalization back on restores it', async (p) => {
    await p.menu('Options', 'Capitalize Keywords As You Type');
    p.assert.equal(await p.ev('RC.app.settings.autoFormat'), true);
    await open(p, '');
    await typeKeys(p, 'end\n');
    p.assert.equal((await lines(p))[0], 'END');
  });
  t.test('Edit ▸ Capitalize Keywords formats the whole file', async (p) => {
    await open(p, 'cls\nfor i = 1 to 3\nprint "for"; i\nnext i');
    await p.menu('Edit', 'Capitalize Keywords');
    await p.sleep(50);
    p.assert.deepEqual(await lines(p), ['CLS', 'FOR i = 1 TO 3', 'PRINT "for"; i', 'NEXT i']);
  });
  t.test('Edit ▸ Capitalize Keywords works with auto-capitalize off and is undoable in one step', async (p) => {
    await p.ev('RC.app.settings.autoFormat = false');
    await open(p, 'cls\nbeep\n');
    await p.menu('Edit', 'Capitalize Keywords');
    p.assert.equal(await p.code(), 'CLS\nBEEP\n');
    await p.menu('Edit', 'Undo');
    await p.ev('RC.app.settings.autoFormat = true');
    p.assert.equal(await p.code(), 'cls\nbeep\n');
  });
};
