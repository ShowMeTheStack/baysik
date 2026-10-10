// Code editor part B: auto-indent, Tab/Shift+Tab, toggle comment, duplicate line, smart Home,
// undo/redo, gutter line numbers and the current-line highlight.
import { open, caret, select, cur, lines, rendered, closeOthers, cleanAll, typeKeys, undo, redo, selText, posXY } from './_editor-helpers.mjs';

const gutterNums = (p) => p.ev('[...RC.app.active.editor.inner.children].map((e) => e.textContent)');
const curlines = (p) => p.ev('[...RC.app.active.editor.hl.children].map((e, i) => e.classList.contains("curline") ? i : -1).filter((i) => i >= 0)');

export default (t) => {
  t.beforeEach(async (p) => { await closeOthers(p); });
  t.afterEach(async (p) => { await cleanAll(p); });

  // ---- auto-indent ---------------------------------------------------------------------------------
  const INDENT = [
    ['IF … THEN', 'IF X > 1 THEN'],
    ['IF … THEN with a trailing comment', "IF X THEN ' big"],
    ['ELSE', 'ELSE'],
    ['ELSEIF', 'ELSEIF X = 2 THEN'],
    ['FOR', 'FOR I = 1 TO 10'],
    ['DO', 'DO'],
    ['DO WHILE', 'DO WHILE X < 5'],
    ['WHILE', 'WHILE X < 5'],
    ['SELECT CASE', 'SELECT CASE K'],
    ['CASE', 'CASE 1 TO 3'],
    ['SUB', 'SUB DrawBox (X, Y)'],
    ['FUNCTION', 'FUNCTION Area (R)'],
    ['TYPE', 'TYPE Point'],
    ['multi-line DEF FN', 'DEF FNmax (A, B)'],
    ['line-numbered FOR', '10 FOR I = 1 TO 3'],
    ['lowercase for', 'for i = 1 to 3'],
  ];
  for (const [name, line] of INDENT) {
    t.test('auto-indent after ' + name, async (p) => {
      await open(p, '');
      await typeKeys(p, line + '\n');
      const l = await lines(p);
      p.assert.equal(l.length, 2);
      p.assert.equal(l[1], '    ');
      p.assert.deepEqual(await cur(p), { line: 1, col: 4 });
    });
  }
  const NOINDENT = [
    ['single-line IF … THEN statement', 'IF X THEN PRINT X'],
    ['FOR … NEXT on one line', 'FOR I = 1 TO 3: PRINT I: NEXT'],
    ['DO … LOOP on one line', 'DO: X = X + 1: LOOP UNTIL X > 3'],
    ['WHILE … WEND on one line', 'WHILE X < 3: X = X + 1: WEND'],
    ['a plain statement', 'PRINT "HELLO"'],
    ['single-line DEF FN', 'DEF FNsq (X) = X * X'],
    ['END SUB', 'END SUB'],
    ['NEXT', 'NEXT I'],
  ];
  for (const [name, line] of NOINDENT) {
    t.test('no extra indent after ' + name, async (p) => {
      await open(p, '');
      await typeKeys(p, line + '\n');
      p.assert.equal((await lines(p))[1], '');
    });
  }
  t.test('Enter keeps the current indentation on a plain line', async (p) => {
    await open(p, '    PRINT 1');
    await p.key('Enter');
    p.assert.equal((await lines(p))[1], '    ');
  });
  t.test('nested blocks indent cumulatively', async (p) => {
    await open(p, '');
    await typeKeys(p, 'FOR I = 1 TO 3\nFOR J = 1 TO 3\nPRINT I * J');
    p.assert.deepEqual(await lines(p), ['FOR I = 1 TO 3', '    FOR J = 1 TO 3', '        PRINT I * J']);
  });
  t.test('Enter in the middle of indentation does not add more than the caret column', async (p) => {
    await open(p, '        X = 1', { line: 0, col: 2 });
    await p.key('Enter');
    const l = await lines(p);
    p.assert.equal(l[0], '  ');
    p.assert.equal(l[1], '  ' + '      X = 1');
  });
  t.test('turning off Auto Indent stops the extra indent', async (p) => {
    await p.menu('Options', 'Auto Indent');
    p.assert.equal(await p.ev('RC.app.settings.autoIndent'), false);
    await open(p, '');
    await typeKeys(p, 'FOR I = 1 TO 3\n');
    p.assert.equal((await lines(p))[1], '');
  });
  t.test('with Auto Indent off, existing indentation is still kept', async (p) => {
    await open(p, '  IF X THEN');
    await p.key('Enter');
    p.assert.equal((await lines(p))[1], '  ');
    await p.menu('Options', 'Auto Indent');
    p.assert.equal(await p.ev('RC.app.settings.autoIndent'), true);
  });

  // ---- Tab / Shift+Tab ------------------------------------------------------------------------------------
  t.test('Tab inserts 4 spaces by default', async (p) => {
    await open(p, 'X');
    await caret(p, 0, 0);
    await p.key('Tab');
    p.assert.equal(await p.code(), '    X');
  });
  t.test('Tab keeps focus in the editor', async (p) => {
    await open(p, '');
    await p.key('Tab');
    p.assert.equal(await p.ev('document.activeElement === RC.app.active.editor.ta'), true);
  });
  t.test('Tab inside a line inserts spaces at the caret', async (p) => {
    await open(p, 'AB', { line: 0, col: 1 });
    await p.key('Tab');
    p.assert.equal(await p.code(), 'A    B');
  });
  t.test('Tab with a selection inside one line replaces it with spaces', async (p) => {
    await open(p, 'ABCD');
    await select(p, 0, 1, 0, 3);
    await p.key('Tab');
    p.assert.equal(await p.code(), 'A    D');
  });
  for (const n of [2, 8, 4]) {
    t.test(`Tab Width ${n} (Options menu) makes Tab insert ${n} spaces`, async (p) => {
      await p.menu('Options', 'Tab Width', n + ' spaces');
      p.assert.equal(await p.ev('RC.app.settings.tabSize'), n);
      await open(p, '');
      await p.key('Tab');
      p.assert.equal(await p.code(), ' '.repeat(n));
    });
  }
  t.test('Tab Width menu shows the current width checked', async (p) => {
    await p.menu('Options', 'Tab Width', '2 spaces');
    await p.click('.menu-btn', 'Options');
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.hover('.menu-pop .menu-item', 'Tab Width');
    await p.wait('document.querySelectorAll(".menu-pop").length >= 2');
    const sub = await p.ev('[...document.querySelectorAll(".menu-pop")].pop().innerText');
    const checked = await p.ev('[...[...document.querySelectorAll(".menu-pop")].pop().querySelectorAll(".menu-item.checked")].map((e) => e.innerText)');
    await p.closeMenus();
    p.assert.match(sub, /2 spaces[\s\S]*4 spaces[\s\S]*8 spaces/);
    p.assert.deepEqual(checked, ['2 spaces']);
  });
  t.test('auto-indent uses the tab width setting', async (p) => {
    await open(p, '');
    await typeKeys(p, 'DO\n');
    p.assert.equal((await lines(p))[1], '  ');
  });
  t.test('Shift+Tab with tab width 2 removes 2 spaces', async (p) => {
    await open(p, '      X', { line: 0, col: 6 });
    await p.key('Tab', { shift: true });
    p.assert.equal(await p.code(), '    X');
    await p.menu('Options', 'Tab Width', '4 spaces');
    p.assert.equal(await p.ev('RC.app.settings.tabSize'), 4);
  });
  t.test('Tab on a multi-line selection indents every line', async (p) => {
    await open(p, 'A\nB\nC\nD');
    await select(p, 0, 0, 2, 1);
    await p.key('Tab');
    p.assert.deepEqual(await lines(p), ['    A', '    B', '    C', 'D']);
  });
  t.test('Tab on a multi-line selection keeps the block selected', async (p) => {
    await open(p, 'A\nB\nC');
    await select(p, 0, 0, 1, 1);
    await p.key('Tab');
    p.assert.equal(await selText(p), '    A\n    B');
  });
  t.test('Tab on a partial multi-line selection indents whole lines', async (p) => {
    await open(p, 'PRINT 1\nPRINT 2');
    await select(p, 0, 3, 1, 2);
    await p.key('Tab');
    p.assert.deepEqual(await lines(p), ['    PRINT 1', '    PRINT 2']);
  });
  t.test('Tab on a multi-line selection skips blank lines', async (p) => {
    await open(p, 'A\n\nB');
    await select(p, 0, 0, 2, 1);
    await p.key('Tab');
    p.assert.deepEqual(await lines(p), ['    A', '', '    B']);
  });
  t.test('Tab twice indents a block by 8', async (p) => {
    await open(p, 'A\nB');
    await select(p, 0, 0, 1, 1);
    await p.key('Tab');
    await p.key('Tab');
    p.assert.deepEqual(await lines(p), ['        A', '        B']);
  });
  t.test('Shift+Tab on a multi-line selection outdents every line', async (p) => {
    await open(p, '    A\n        B\n    C');
    await select(p, 0, 0, 2, 5);
    await p.key('Tab', { shift: true });
    p.assert.deepEqual(await lines(p), ['A', '    B', 'C']);
  });
  t.test('Shift+Tab removes only the spaces that exist', async (p) => {
    await open(p, '  A\nB\n      C');
    await select(p, 0, 0, 2, 7);
    await p.key('Tab', { shift: true });
    p.assert.deepEqual(await lines(p), ['A', 'B', '  C']);
  });
  t.test('Shift+Tab on a single line outdents it', async (p) => {
    await open(p, '        PRINT', { line: 0, col: 10 });
    await p.key('Tab', { shift: true });
    p.assert.equal(await p.code(), '    PRINT');
  });
  t.test('Shift+Tab on an unindented line changes nothing', async (p) => {
    await open(p, 'PRINT', { line: 0, col: 2 });
    await p.key('Tab', { shift: true });
    p.assert.equal(await p.code(), 'PRINT');
  });
  t.test('Shift+Tab touches only the selected lines', async (p) => {
    await open(p, '    A\n    B\n    C');
    await select(p, 1, 0, 1, 5);
    await p.key('Tab', { shift: true });
    p.assert.deepEqual(await lines(p), ['    A', 'B', '    C']);
  });

  // ---- Ctrl+/ toggle comment ---------------------------------------------------------------------------------
  t.test('Ctrl+/ comments the current line', async (p) => {
    await open(p, 'PRINT 1\nPRINT 2', { line: 0, col: 3 });
    await p.key('/', { ctrl: true });
    p.assert.deepEqual(await lines(p), ["' PRINT 1", 'PRINT 2']);
  });
  t.test('Ctrl+/ again uncomments the line', async (p) => {
    await open(p, "' PRINT 1", { line: 0, col: 3 });
    await p.key('/', { ctrl: true });
    p.assert.equal(await p.code(), 'PRINT 1');
  });
  t.test('Ctrl+/ twice restores the original line', async (p) => {
    await open(p, 'X = 1', { line: 0, col: 0 });
    await p.key('/', { ctrl: true });
    await p.key('/', { ctrl: true });
    p.assert.equal(await p.code(), 'X = 1');
  });
  t.test('Ctrl+/ keeps indentation and comments after it', async (p) => {
    await open(p, '    PRINT 1', { line: 0, col: 6 });
    await p.key('/', { ctrl: true });
    p.assert.equal(await p.code(), "    ' PRINT 1");
  });
  t.test('Ctrl+/ uncomments a comment without a space after the quote', async (p) => {
    await open(p, "'CLS", { line: 0, col: 1 });
    await p.key('/', { ctrl: true });
    p.assert.equal(await p.code(), 'CLS');
  });
  t.test('Ctrl+/ comments every line of a selection', async (p) => {
    await open(p, 'A = 1\nB = 2\nC = 3\nD = 4');
    await select(p, 1, 0, 2, 3);
    await p.key('/', { ctrl: true });
    p.assert.deepEqual(await lines(p), ['A = 1', "' B = 2", "' C = 3", 'D = 4']);
  });
  t.test('Ctrl+/ uncomments every line when all selected lines are comments', async (p) => {
    await open(p, "' A\n' B\n' C");
    await select(p, 0, 0, 2, 3);
    await p.key('/', { ctrl: true });
    p.assert.deepEqual(await lines(p), ['A', 'B', 'C']);
  });
  t.test('Ctrl+/ on a mixed selection comments all lines', async (p) => {
    await open(p, "' A\nB");
    await select(p, 0, 0, 1, 1);
    await p.key('/', { ctrl: true });
    p.assert.deepEqual(await lines(p), ["' ' A", "' B"]);
  });
  t.test('Ctrl+/ leaves blank lines in a selection alone', async (p) => {
    await open(p, 'A\n\nB');
    await select(p, 0, 0, 2, 1);
    await p.key('/', { ctrl: true });
    p.assert.deepEqual(await lines(p), ["' A", '', "' B"]);
  });
  t.test('Ctrl+/ selection ending at the start of a line does not include that line', async (p) => {
    await open(p, 'A\nB\nC');
    await select(p, 0, 0, 1, 0);
    await p.key('/', { ctrl: true });
    p.assert.deepEqual(await lines(p), ["' A", 'B', 'C']);
  });
  t.test('commented lines are highlighted as comments', async (p) => {
    await open(p, 'PRINT 1', { line: 0, col: 0 });
    await p.key('/', { ctrl: true });
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.children[0].querySelector(".s-com").textContent'), "' PRINT 1");
  });
  t.test('toggle comment can be undone', async (p) => {
    await open(p, 'A\nB');
    await select(p, 0, 0, 1, 1);
    await p.key('/', { ctrl: true });
    p.assert.equal(await p.code(), "' A\n' B");
    await undo(p);
    p.assert.equal(await p.code(), 'A\nB');
  });
  t.test('Edit ▸ Toggle Comment comments the current line', async (p) => {
    await open(p, 'BEEP', { line: 0, col: 0 });
    await p.menu('Edit', 'Toggle Comment');
    p.assert.equal(await p.code(), "' BEEP");
  });

  // ---- Ctrl+D duplicate --------------------------------------------------------------------------------------------
  t.test('Ctrl+D duplicates the current line below it', async (p) => {
    await open(p, 'A = 1\nB = 2', { line: 0, col: 2 });
    await p.key('d', { ctrl: true });
    p.assert.deepEqual(await lines(p), ['A = 1', 'A = 1', 'B = 2']);
  });
  t.test('Ctrl+D moves the caret onto the copy', async (p) => {
    await open(p, 'A = 1\nB = 2', { line: 0, col: 0 });
    await p.key('d', { ctrl: true });
    p.assert.equal((await cur(p)).line, 1);
  });
  t.test('Ctrl+D on the last line', async (p) => {
    await open(p, 'X\nLAST');
    await p.key('d', { ctrl: true });
    p.assert.deepEqual(await lines(p), ['X', 'LAST', 'LAST']);
  });
  t.test('Ctrl+D twice makes three copies', async (p) => {
    await open(p, 'BEEP', { line: 0, col: 0 });
    await p.key('d', { ctrl: true });
    await p.key('d', { ctrl: true });
    p.assert.deepEqual(await lines(p), ['BEEP', 'BEEP', 'BEEP']);
  });
  t.test('Ctrl+D keeps indentation of the copy', async (p) => {
    await open(p, '    PRINT X', { line: 0, col: 0 });
    await p.key('d', { ctrl: true });
    p.assert.deepEqual(await lines(p), ['    PRINT X', '    PRINT X']);
  });
  t.test('Ctrl+D can be undone', async (p) => {
    await open(p, 'ONE\nTWO', { line: 1, col: 0 });
    await p.key('d', { ctrl: true });
    await undo(p);
    p.assert.equal(await p.code(), 'ONE\nTWO');
  });
  t.test('Edit ▸ Duplicate Line duplicates the current line', async (p) => {
    await open(p, 'CLS', { line: 0, col: 0 });
    await p.menu('Edit', 'Duplicate Line');
    p.assert.equal(await p.code(), 'CLS\nCLS');
  });

  // ---- smart Home ---------------------------------------------------------------------------------------------------
  t.test('Home on an indented line goes to the first non-space character', async (p) => {
    await open(p, '    PRINT 1', { line: 0, col: 9 });
    await p.key('Home');
    p.assert.deepEqual(await cur(p), { line: 0, col: 4 });
  });
  t.test('Home a second time goes to column 0', async (p) => {
    await open(p, '    PRINT 1', { line: 0, col: 9 });
    await p.key('Home');
    await p.key('Home');
    p.assert.deepEqual(await cur(p), { line: 0, col: 0 });
  });
  t.test('Home from column 0 goes back to the indentation', async (p) => {
    await open(p, '  X', { line: 0, col: 0 });
    await p.key('Home');
    p.assert.deepEqual(await cur(p), { line: 0, col: 2 });
  });
  t.test('Home on an unindented line goes to column 0', async (p) => {
    await open(p, 'A\nPRINT 1', { line: 1, col: 5 });
    await p.key('Home');
    p.assert.deepEqual(await cur(p), { line: 1, col: 0 });
  });
  t.test('Home then typing inserts at the indentation', async (p) => {
    await open(p, '    PRINT 1', { line: 0, col: 11 });
    await p.key('Home');
    await typeKeys(p, 'Z');
    p.assert.equal(await p.code(), '    ZPRINT 1');
  });

  // ---- undo / redo ----------------------------------------------------------------------------------------------------------
  t.test('Ctrl+Z undoes typing', async (p) => {
    await open(p, 'A');
    await typeKeys(p, 'BC');
    p.assert.equal(await p.code(), 'ABC');
    await undo(p);
    await undo(p);
    p.assert.equal(await p.code(), 'A');
  });
  t.test('Ctrl+Y redoes undone typing', async (p) => {
    await open(p, 'A');
    await typeKeys(p, 'B');
    await undo(p);
    p.assert.equal(await p.code(), 'A');
    await redo(p);
    p.assert.equal(await p.code(), 'AB');
  });
  t.test('undo reverts a Tab indent', async (p) => {
    await open(p, 'X', { line: 0, col: 0 });
    await p.key('Tab');
    await undo(p);
    p.assert.equal(await p.code(), 'X');
  });
  t.test('undo reverts a block indent in one step', async (p) => {
    await open(p, 'A\nB\nC');
    await select(p, 0, 0, 2, 1);
    await p.key('Tab');
    await undo(p);
    p.assert.equal(await p.code(), 'A\nB\nC');
  });
  t.test('undo reverts a Backspace', async (p) => {
    await open(p, 'HELLO');
    await p.key('Backspace');
    p.assert.equal(await p.code(), 'HELL');
    await undo(p);
    p.assert.equal(await p.code(), 'HELLO');
  });
  t.test('undo reverts pasted text', async (p) => {
    await open(p, 'X');
    await p.insertText('\nPRINT "PASTED"');
    p.assert.equal(await p.code(), 'X\nPRINT "PASTED"');
    await undo(p);
    p.assert.equal(await p.code(), 'X');
  });
  t.test('undo then redo after Enter with auto-indent', async (p) => {
    await open(p, 'FOR I = 1 TO 2');
    await p.key('Enter');
    p.assert.equal(await p.code(), 'FOR I = 1 TO 2\n    ');
    await undo(p);
    p.assert.equal(await p.code(), 'FOR I = 1 TO 2');
    await redo(p);
    p.assert.equal(await p.code(), 'FOR I = 1 TO 2\n    ');
  });
  t.test('Edit ▸ Undo and Edit ▸ Redo work', async (p) => {
    await open(p, 'Q');
    await typeKeys(p, 'R');
    await p.menu('Edit', 'Undo');
    p.assert.equal(await p.code(), 'Q');
    await p.menu('Edit', 'Redo');
    p.assert.equal(await p.code(), 'QR');
  });
  t.test('undo updates the gutter line count', async (p) => {
    await open(p, 'A');
    await p.key('Enter');
    await p.key('Enter');
    await rendered(p);
    p.assert.equal((await gutterNums(p)).length, 3);
    await undo(p);
    await undo(p);
    await rendered(p);
    p.assert.equal((await gutterNums(p)).length, 1);
  });

  // ---- gutter -----------------------------------------------------------------------------------------------------------------
  t.test('gutter shows one line number per line', async (p) => {
    await open(p, 'A\nB\nC\nD\nE');
    await rendered(p);
    p.assert.deepEqual(await gutterNums(p), ['1', '2', '3', '4', '5']);
  });
  t.test('gutter grows as lines are added with Enter', async (p) => {
    await open(p, 'A');
    await typeKeys(p, '\nB\nC');
    await rendered(p);
    p.assert.deepEqual(await gutterNums(p), ['1', '2', '3']);
  });
  t.test('gutter shrinks as lines are deleted', async (p) => {
    await open(p, 'A\nB\nC', { line: 2, col: 0 });
    await p.key('Backspace');
    await rendered(p);
    p.assert.deepEqual(await gutterNums(p), ['1', '2']);
    await p.key('Backspace');
    await p.key('Backspace');
    await rendered(p);
    p.assert.deepEqual(await gutterNums(p), ['1']);
  });
  t.test('gutter line numbers line up with text lines', async (p) => {
    await open(p, 'A\nB\nC\nD');
    await rendered(p);
    const r = await p.ev('(() => { const e = RC.app.active.editor; const g = e.inner.children[3].getBoundingClientRect(); const l = e.hl.children[3].getBoundingClientRect(); return [g.top, l.top, g.height, l.height]; })()');
    p.assert.ok(Math.abs(r[0] - r[1]) < 2, JSON.stringify(r));
    p.assert.ok(Math.abs(r[2] - r[3]) < 2, JSON.stringify(r));
  });
  t.test('gutter width is the same for 1 and 999 lines', async (p) => {
    await open(p, 'A');
    await rendered(p);
    const w1 = await p.ev('RC.app.active.editor.gutter.getBoundingClientRect().width');
    await open(p, Array.from({ length: 999 }, (_, i) => 'X = ' + i).join('\n'));
    await rendered(p);
    const w2 = await p.ev('RC.app.active.editor.gutter.getBoundingClientRect().width');
    p.assert.equal(w1, w2);
  });
  t.test('gutter widens when the file reaches 1000 lines', async (p) => {
    await open(p, Array.from({ length: 999 }, (_, i) => 'X = ' + i).join('\n'));
    await rendered(p);
    const w1 = await p.ev('RC.app.active.editor.gutter.getBoundingClientRect().width');
    await p.key('Enter');
    await rendered(p);
    const w2 = await p.ev('RC.app.active.editor.gutter.getBoundingClientRect().width');
    p.assert.ok(w2 > w1, `${w1} -> ${w2}`);
    p.assert.equal((await gutterNums(p)).pop(), '1000');
  });
  t.test('gutter widens again at 10000 lines', async (p) => {
    await open(p, Array.from({ length: 9999 }, () => 'X').join('\n'));
    await rendered(p);
    const w1 = await p.ev('RC.app.active.editor.gutter.getBoundingClientRect().width');
    await open(p, Array.from({ length: 10000 }, () => 'X').join('\n'));
    await rendered(p);
    const w2 = await p.ev('RC.app.active.editor.gutter.getBoundingClientRect().width');
    p.assert.ok(w2 > w1, `${w1} -> ${w2}`);
  }, { timeout: 40000 });
  t.test('gutter scrolls together with the text', async (p) => {
    await open(p, Array.from({ length: 200 }, (_, i) => 'PRINT ' + i).join('\n'), { line: 0, col: 0 });
    const r = await p.rect('.ed:not([style*="none"]) .ed-ta');
    await p.b.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: r.x + 100, y: r.y + 100, deltaX: 0, deltaY: 600 });
    await p.wait('RC.app.active.editor.ta.scrollTop > 100');
    await p.sleep(100);
    const s = await p.ev('(() => { const e = RC.app.active.editor; return [e.ta.scrollTop, e.hl.scrollTop, e.inner.style.transform]; })()');
    p.assert.equal(s[0], s[1]);
    p.assert.equal(s[2], `translateY(${-s[0]}px)`);
  });
  t.test('clicking a gutter number toggles a breakpoint on that line', async (p) => {
    await open(p, 'PRINT 1\nPRINT 2\nPRINT 3', { line: 0, col: 0 });
    await rendered(p);
    const [, y] = await posXY(p, 1, 0);
    const g = await p.ev('(() => { const r = RC.app.active.editor.gutter.getBoundingClientRect(); return r.left + r.width / 2; })()');
    await p.clickAt(g, y);
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.inner.children[1].classList.contains("bp")'), true);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.children[1].classList.contains("bpline")'), true);
    await p.clickAt(g, y);
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.inner.children[1].classList.contains("bp")'), false);
  });

  // ---- current-line highlight -------------------------------------------------------------------------------------------------
  t.test('the caret line has the current-line highlight', async (p) => {
    await open(p, 'A\nB\nC', { line: 1, col: 0 });
    await rendered(p);
    p.assert.deepEqual(await curlines(p), [1]);
  });
  t.test('current-line highlight follows ArrowDown', async (p) => {
    await open(p, 'A\nB\nC', { line: 0, col: 0 });
    await p.key('ArrowDown');
    await p.key('ArrowDown');
    await rendered(p);
    p.assert.deepEqual(await curlines(p), [2]);
  });
  t.test('current-line highlight follows Enter onto a new line', async (p) => {
    await open(p, 'A');
    await p.key('Enter');
    await rendered(p);
    p.assert.deepEqual(await curlines(p), [1]);
  });
  t.test('no current-line highlight when the editor is not focused', async (p) => {
    await open(p, 'A\nB', { line: 1, col: 0 });
    await p.click('#statusbar');
    await p.ev('RC.app.active.editor.render()');
    p.assert.deepEqual(await curlines(p), []);
  });
  t.test('current line has a visible background colour', async (p) => {
    await open(p, 'A\nB', { line: 0, col: 0 });
    await rendered(p);
    const bg = await p.ev('getComputedStyle(RC.app.active.editor.hl.children[0]).backgroundColor');
    const bg2 = await p.ev('getComputedStyle(RC.app.active.editor.hl.children[1]).backgroundColor');
    p.assert.notEqual(bg, bg2);
  });
};
