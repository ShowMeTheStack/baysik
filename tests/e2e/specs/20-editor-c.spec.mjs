// Code editor part C: find/replace bar, Go to Line, F1 help, editor context menu,
// procedures outline, F2 SUBs dialog, zoom.
import { open, caret, select, cur, lines, closeOthers, cleanAll, typeKeys, undo, selText, posXY, clickChar } from './_editor-helpers.mjs';

const FIND_TEXT = 'PRINT 1\nprint 2\nPRINT 3\nX = 1';
const info = (p) => p.text('#findbar .info');
const findOpen = (p) => p.ev('!document.getElementById("findbar").hidden');
async function openFind(p, text, query, replace) {
  await open(p, text, { line: 0, col: 0 });
  await p.key(replace ? 'h' : 'f', { ctrl: true });
  await p.wait('document.activeElement && document.activeElement.getAttribute("aria-label") === "Find"');
  if (query !== undefined) {
    await p.ev('document.querySelector("#findbar input[aria-label=Find]").select()');
    await typeKeys(p, query);
  }
}
async function gotoLine(p, value) {
  await p.key('g', { ctrl: true });
  p.assert.equal(await p.waitModal(), 'Go to Line');
  await p.wait('document.activeElement && document.activeElement.tagName === "INPUT"');
  await typeKeys(p, value);
  await p.key('Enter');
  await p.sleep(80);
}
const helpHeading = (p) => p.text('.help-main h2');
const procItems = (p) => p.texts('#procList .proc-item');
async function ctxMenu(p, line, col) {
  await clickChar(p, line, col);
  await clickChar(p, line, col, { button: 'right' });
  await p.wait("!!document.querySelector('.menu-pop')", 2000);
  return (await p.menuItems()).map((x) => x.label);
}
const edFont = (p) => p.ev('parseFloat(getComputedStyle(RC.app.active.editor.root).fontSize)');

export default (t) => {
  t.beforeEach(async (p) => { await closeOthers(p); });
  t.afterEach(async (p) => { await closeOthers(p); await cleanAll(p); });

  // ---- find ------------------------------------------------------------------------------------------
  t.test('Ctrl+F opens the find bar with focus in the Find box', async (p) => {
    await openFind(p, FIND_TEXT);
    p.assert.equal(await findOpen(p), true);
    p.assert.equal(await p.visible('#findbar input[aria-label="Find"]'), true);
  });
  t.test('Ctrl+F find bar has no replace box', async (p) => {
    await openFind(p, FIND_TEXT);
    p.assert.equal(await p.exists('#findbar input[aria-label="Replace with"]'), false);
  });
  t.test('Enter finds the first match and shows "1 of 3"', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.key('Enter');
    p.assert.equal(await info(p), '1 of 3');
    p.assert.equal(await selText(p), 'PRINT');
    p.assert.equal((await cur(p)).line, 0);
  });
  t.test('Enter again moves to the next match', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.key('Enter');
    await p.key('Enter');
    p.assert.equal(await info(p), '2 of 3');
    p.assert.equal((await selText(p)).toLowerCase(), 'print');
    p.assert.equal((await cur(p)).line, 1);
  });
  t.test('find wraps around after the last match', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    for (let i = 0; i < 4; i++) await p.key('Enter');
    p.assert.equal(await info(p), '1 of 3');
    p.assert.equal((await cur(p)).line, 0);
  });
  t.test('Shift+Enter finds the previous match', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.key('Enter');
    await p.key('Enter');
    await p.key('Enter', { shift: true });
    p.assert.equal(await info(p), '1 of 3');
  });
  t.test('Shift+Enter from the first match wraps to the last', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.key('Enter');
    await p.key('Enter', { shift: true });
    p.assert.equal(await info(p), '3 of 3');
    p.assert.equal((await cur(p)).line, 2);
  });
  t.test('the ↓ and ↑ buttons find next and previous', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.click('#findbar button', '↓');
    p.assert.equal(await info(p), '1 of 3');
    await p.click('#findbar button', '↓');
    p.assert.equal(await info(p), '2 of 3');
    await p.click('#findbar button', '↑');
    p.assert.equal(await info(p), '1 of 3');
  });
  t.test('find starts from the caret position', async (p) => {
    await open(p, FIND_TEXT, { line: 1, col: 3 });
    await p.key('f', { ctrl: true });
    await typeKeys(p, 'print');
    await p.key('Enter');
    p.assert.equal(await info(p), '3 of 3');
  });
  t.test('find is case-insensitive by default', async (p) => {
    await openFind(p, FIND_TEXT, 'PrInT');
    await p.key('Enter');
    p.assert.match(await info(p), / of 3$/);
  });
  t.test('Match case limits matches to the exact case', async (p) => {
    await openFind(p, FIND_TEXT, 'PRINT');
    await p.click('#findbar input[aria-label="Match case"]');
    await p.click('#findbar button', '↓');
    p.assert.match(await info(p), / of 2$/);
  });
  t.test('Match case with lowercase query finds only the lowercase line', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.click('#findbar input[aria-label="Match case"]');
    await p.click('#findbar button', '↓');
    p.assert.equal(await info(p), '1 of 1');
    p.assert.equal((await cur(p)).line, 1);
  });
  t.test('Regular expression mode matches patterns', async (p) => {
    await openFind(p, FIND_TEXT, 'PRINT [13]');
    await p.click('#findbar input[aria-label="Regular expression"]');
    await p.click('#findbar button', '↓');
    p.assert.match(await info(p), / of 2$/);
    p.assert.equal(await selText(p), 'PRINT 1');
  });
  t.test('without regex mode, regex characters are literal', async (p) => {
    await openFind(p, 'A.B\nAXB', 'A.B');
    await p.key('Enter');
    p.assert.equal(await info(p), '1 of 1');
    p.assert.equal(await selText(p), 'A.B');
  });
  t.test('a query with no matches shows "No matches"', async (p) => {
    await openFind(p, FIND_TEXT, 'GOSUB');
    await p.key('Enter');
    p.assert.equal(await info(p), 'No matches');
  });
  t.test('an invalid regular expression does not throw or move the caret', async (p) => {
    await openFind(p, FIND_TEXT, '(');
    await p.click('#findbar input[aria-label="Regular expression"]');
    await p.click('#findbar button', '↓');
    p.assert.equal(await info(p), '');
    p.assert.deepEqual(await cur(p), { line: 0, col: 0 });
  });
  t.test('selected text pre-fills the Find box', async (p) => {
    await open(p, 'PRINT score\nscore = 1');
    await select(p, 0, 6, 0, 11);
    await p.key('f', { ctrl: true });
    p.assert.equal(await p.ev('document.querySelector("#findbar input[aria-label=Find]").value'), 'score');
  });
  t.test('the last search is remembered when reopening', async (p) => {
    await openFind(p, FIND_TEXT, 'X = 1');
    await p.key('Enter');
    await p.key('Escape');
    await caret(p, 0, 0);
    await p.key('f', { ctrl: true });
    p.assert.equal(await p.ev('document.querySelector("#findbar input[aria-label=Find]").value'), 'X = 1');
  });
  t.test('Escape closes the find bar and returns focus to the editor', async (p) => {
    await openFind(p, FIND_TEXT, 'print');
    await p.key('Escape');
    p.assert.equal(await findOpen(p), false);
    p.assert.equal(await p.ev('document.activeElement === RC.app.active.editor.ta'), true);
  });
  t.test('the close button closes the find bar', async (p) => {
    await openFind(p, FIND_TEXT);
    await p.click('#findbar [aria-label="Close find"]');
    p.assert.equal(await findOpen(p), false);
  });
  t.test('Edit ▸ Find… opens the find bar', async (p) => {
    await open(p, FIND_TEXT);
    await p.menu('Edit', 'Find…');
    p.assert.equal(await findOpen(p), true);
  });
  t.test('typing after a find replaces the found text', async (p) => {
    await openFind(p, 'A = 1\nB = 1', 'B');
    await p.key('Enter');
    await p.key('Escape');
    await typeKeys(p, 'C');
    p.assert.equal(await p.code(), 'A = 1\nC = 1');
  });

  // ---- replace -----------------------------------------------------------------------------------------
  t.test('Ctrl+H opens the find bar with Replace and All buttons', async (p) => {
    await openFind(p, FIND_TEXT, undefined, true);
    p.assert.equal(await p.exists('#findbar input[aria-label="Replace with"]'), true);
    const btns = await p.texts('#findbar button');
    p.assert.ok(btns.includes('Replace') && btns.includes('All'), JSON.stringify(btns));
  });
  t.test('Replace replaces the current match and moves to the next', async (p) => {
    await openFind(p, 'X = 1\nX = 2\nX = 3', 'X', true);
    await p.key('Enter');
    await p.ev('(() => { const r = document.querySelector("#findbar input[aria-label=\'Replace with\']"); r.focus(); })()');
    await typeKeys(p, 'Y');
    await p.click('#findbar button', 'Replace');
    p.assert.deepEqual(await lines(p), ['Y = 1', 'X = 2', 'X = 3']);
    p.assert.equal(await info(p), '1 of 2');
    p.assert.equal((await cur(p)).line, 1);
  });
  t.test('Replace with nothing selected only finds the first match', async (p) => {
    await openFind(p, 'X = 1\nX = 2', 'X', true);
    await p.ev('document.querySelector("#findbar input[aria-label=\'Replace with\']").value = "Z"');
    await p.click('#findbar button', 'Replace');
    p.assert.equal(await p.code(), 'X = 1\nX = 2');
    p.assert.equal(await info(p), '1 of 2');
  });
  t.test('All replaces every match and reports the count', async (p) => {
    await openFind(p, 'X = 1\nX = 2\nPRINT X', 'X', true);
    await p.ev('document.querySelector("#findbar input[aria-label=\'Replace with\']").focus()');
    await typeKeys(p, 'Total');
    await p.click('#findbar button', 'All');
    p.assert.equal(await p.code(), 'Total = 1\nTotal = 2\nPRINT Total');
    p.assert.equal(await info(p), '3 replaced');
  });
  t.test('All is case-insensitive unless Match case is on', async (p) => {
    await openFind(p, 'abc\nABC', 'abc', true);
    await p.ev('document.querySelector("#findbar input[aria-label=\'Replace with\']").value = "xyz"');
    await p.click('#findbar input[aria-label="Match case"]');
    await p.click('#findbar button', 'All');
    p.assert.equal(await p.code(), 'xyz\nABC');
    p.assert.equal(await info(p), '1 replaced');
  });
  t.test('All with regex supports $1 group references', async (p) => {
    await openFind(p, 'A = 10\nB = 200', '(\\d+)', true);
    await p.ev('document.querySelector("#findbar input[aria-label=\'Replace with\']").value = "($1)"');
    await p.click('#findbar input[aria-label="Regular expression"]');
    await p.click('#findbar button', 'All');
    p.assert.equal(await p.code(), 'A = (10)\nB = (200)');
  });
  t.test('All with no matches reports 0 replaced and leaves text', async (p) => {
    await openFind(p, 'A = 1', 'ZZZ', true);
    await p.click('#findbar button', 'All');
    p.assert.equal(await info(p), '0 replaced');
    p.assert.equal(await p.code(), 'A = 1');
  });
  t.test('Replace All can be undone in one step', async (p) => {
    await openFind(p, 'X\nX\nX', 'X', true);
    await p.ev('document.querySelector("#findbar input[aria-label=\'Replace with\']").value = "Y"');
    await p.click('#findbar button', 'All');
    p.assert.equal(await p.code(), 'Y\nY\nY');
    await p.ev('RC.app.active.editor.focus()');
    await undo(p);
    p.assert.equal(await p.code(), 'X\nX\nX');
  });
  t.test('Replace All marks the document dirty', async (p) => {
    await openFind(p, 'X = 1', 'X', true);
    await p.ev('document.querySelector("#findbar input[aria-label=\'Replace with\']").value = "Y"');
    await p.click('#findbar button', 'All');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    p.assert.equal(await p.exists('#editorTabs .tab.active .dirty'), true);
  });
  t.test('Edit ▸ Replace… opens the replace bar', async (p) => {
    await open(p, FIND_TEXT);
    await p.menu('Edit', 'Replace…');
    p.assert.equal(await p.exists('#findbar input[aria-label="Replace with"]'), true);
  });

  // ---- go to line -----------------------------------------------------------------------------------------
  const GOTO_TEXT = 'CLS\nPRINT "A"\n10 PRINT "TEN"\n20 GOTO 40\n40 Main:\nEND\nSUB DrawBox\nEND SUB\nFUNCTION Area (R)\nEND FUNCTION\nMyLabel: PRINT';
  t.test('Ctrl+G opens the Go to Line dialog', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await p.key('g', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Go to Line');
    p.assert.match(await p.modalText(), /Editor line, or a BASIC line number\/label/);
  });
  t.test('Go to Line with an editor line number moves the caret there', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, '6');
    p.assert.deepEqual(await cur(p), { line: 5, col: 0 });
    p.assert.match(await p.status(), /Ln 6, Col 1/);
  });
  t.test('Go to Line prefers a BASIC line number', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, '20');
    p.assert.deepEqual(await cur(p), { line: 3, col: 0 });
  });
  t.test('Go to Line with BASIC line 10', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, '10');
    p.assert.equal((await cur(p)).line, 2);
  });
  t.test('Go to Line beyond the end goes to the last line', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, '999');
    p.assert.equal((await cur(p)).line, 10);
  });
  t.test('Go to Line accepts a label name', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, 'MyLabel');
    p.assert.equal((await cur(p)).line, 10);
  });
  t.test('Go to Line accepts a label with a trailing colon, any case', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, 'mylabel:');
    p.assert.equal((await cur(p)).line, 10);
  });
  t.test('Go to Line accepts a SUB name', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, 'DrawBox');
    p.assert.equal((await cur(p)).line, 6);
  });
  t.test('Go to Line accepts a FUNCTION name', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await gotoLine(p, 'area');
    p.assert.equal((await cur(p)).line, 8);
  });
  t.test('Go to Line with an unknown name shows a "Not found" toast', async (p) => {
    await open(p, GOTO_TEXT, { line: 1 });
    await gotoLine(p, 'Nowhere');
    await p.waitToast(/Not found: Nowhere/);
    p.assert.equal((await cur(p)).line, 1);
  });
  t.test('Escape cancels Go to Line without moving', async (p) => {
    await open(p, GOTO_TEXT, { line: 2, col: 1 });
    await p.key('g', { ctrl: true });
    await p.waitModal();
    await typeKeys(p, '7');
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.deepEqual(await cur(p), { line: 2, col: 1 });
  });
  t.test('Edit ▸ Go to Line… opens the dialog', async (p) => {
    await open(p, GOTO_TEXT, { line: 0 });
    await p.menu('Edit', 'Go to Line…');
    p.assert.equal(await p.waitModal(), 'Go to Line');
  });

  // ---- F1 help ---------------------------------------------------------------------------------------------
  t.test('F1 on a keyword opens help for it', async (p) => {
    await open(p, 'PRINT "HI"', { line: 0, col: 2 });
    await p.key('F1');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    p.assert.equal(await helpHeading(p), 'PRINT');
  });
  t.test('F1 on a builtin function opens its entry', async (p) => {
    await open(p, 'N = LEN(A$)', { line: 0, col: 5 });
    await p.key('F1');
    await p.waitModal();
    p.assert.equal(await helpHeading(p), 'LEN');
  });
  t.test('F1 on STEP (an alias) opens the FOR entry', async (p) => {
    await open(p, 'FOR I = 1 TO 9 STEP 2', { line: 0, col: 16 });
    await p.key('F1');
    await p.waitModal();
    p.assert.equal(await helpHeading(p), 'FOR');
  });
  t.test('F1 at the end of a word still finds it', async (p) => {
    await open(p, 'LOCATE 1, 1', { line: 0, col: 5 });
    await p.key('F1');
    await p.waitModal();
    p.assert.equal(await helpHeading(p), 'LOCATE');
  });
  t.test('F1 highlights the keyword in the help navigation', async (p) => {
    await open(p, 'CLS', { line: 0, col: 0 });
    await p.key('F1');
    await p.waitModal();
    p.assert.equal(await p.text('.help-nav .sel'), 'CLS');
  });
  t.test('F1 outside the editor opens the reference on a topic', async (p) => {
    await open(p, 'PRINT', { line: 0, col: 0 });
    await p.click('#statusbar');
    await p.key('F1');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    p.assert.equal(await helpHeading(p), 'Screen modes');
  });
  t.test('Escape closes help and focus returns to the editor', async (p) => {
    await open(p, 'PRINT', { line: 0, col: 1 });
    await p.key('F1');
    await p.waitModal();
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.ev('document.activeElement === RC.app.active.editor.ta'), true);
  });

  // ---- editor context menu ----------------------------------------------------------------------------------
  t.test('context menu on an identifier offers Add Watch, Help and debugging items', async (p) => {
    await open(p, 'score = 10\nPRINT score', { line: 0 });
    const items = await ctxMenu(p, 0, 2);
    p.assert.deepEqual(items, ['Add Watch: score', 'Help on SCORE', 'Toggle Breakpoint', 'Run to Cursor', 'Set Next Statement', 'Cut', 'Copy', 'Toggle Comment']);
  });
  t.test('context menu on a keyword has Help but no Add Watch', async (p) => {
    await open(p, 'PRINT score', { line: 0 });
    const items = await ctxMenu(p, 0, 1);
    p.assert.equal(items[0], 'Help on PRINT');
    p.assert.ok(!items.some((x) => x.startsWith('Add Watch')));
  });
  t.test('context menu past the end of a line has no word items', async (p) => {
    await open(p, 'CLS\nX = 1', { line: 0 });
    const items = await ctxMenu(p, 0, 20);
    p.assert.equal(items[0], 'Toggle Breakpoint');
    p.assert.ok(!items.some((x) => x.startsWith('Help on')));
  });
  t.test('context menu Add Watch uses the full array element expression', async (p) => {
    await open(p, 'DIM a(10)\nPRINT a(i + 1)', { line: 0 });
    const items = await ctxMenu(p, 1, 6);
    p.assert.equal(items[0], 'Add Watch: a(i + 1)');
  });
  t.test('Set Next Statement is disabled when not paused', async (p) => {
    await open(p, 'X = 1', { line: 0 });
    await ctxMenu(p, 0, 0);
    const it = (await p.menuItems()).find((x) => x.label === 'Set Next Statement');
    p.assert.equal(it.disabled, true);
  });
  t.test('context menu shortcuts are shown', async (p) => {
    await open(p, 'X = 1', { line: 0 });
    await ctxMenu(p, 0, 0);
    const m = Object.fromEntries((await p.menuItems()).map((x) => [x.label, x.sc]));
    p.assert.equal(m['Toggle Breakpoint'], 'F9');
    p.assert.equal(m['Run to Cursor'], 'F7');
    p.assert.equal(m['Toggle Comment'], 'Ctrl+/');
  });
  t.test('Escape closes the context menu', async (p) => {
    await open(p, 'X = 1', { line: 0 });
    await ctxMenu(p, 0, 0);
    await p.key('Escape');
    p.assert.equal(await p.exists('.menu-pop'), false);
  });
  t.test('context menu Add Watch adds a watch and shows the Watch panel', async (p) => {
    await open(p, 'lives = 3', { line: 0 });
    await ctxMenu(p, 0, 1);
    await p.click('.menu-pop .menu-item', 'Add Watch: lives');
    await p.wait('RC.app.panels.watches.some((w) => w.expr === "lives")');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'watch');
    p.assert.match(await p.panelText(), /lives/);
  });
  t.test('context menu Help on opens the help entry', async (p) => {
    await open(p, 'CLS', { line: 0 });
    await ctxMenu(p, 0, 1);
    await p.click('.menu-pop .menu-item', 'Help on CLS');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    p.assert.equal(await helpHeading(p), 'CLS');
  });
  t.test('context menu Toggle Breakpoint sets and clears a breakpoint on that line', async (p) => {
    await open(p, 'PRINT 1\nPRINT 2\nPRINT 3', { line: 0 });
    await ctxMenu(p, 2, 1);
    await p.click('.menu-pop .menu-item', 'Toggle Breakpoint');
    await p.wait('RC.app.breakpoints.get(RC.app.active.path).has(2)');
    await p.wait('RC.app.active.editor.inner.children[2].classList.contains("bp")');
    await ctxMenu(p, 2, 1);
    await p.click('.menu-pop .menu-item', 'Toggle Breakpoint');
    await p.wait('!RC.app.breakpoints.get(RC.app.active.path).has(2)');
  });
  t.test('context menu Run to Cursor runs and pauses at the clicked line', async (p) => {
    await open(p, 'X = 1\nX = X + 1\nPRINT "AT"; X\nEND', { line: 0 });
    await ctxMenu(p, 2, 1);
    await p.click('.menu-pop .menu-item', 'Run to Cursor');
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.exec'), 2);
    await p.stopProgram();
  });
  t.test('context menu Toggle Comment comments the caret line', async (p) => {
    await open(p, 'A = 1\nB = 2', { line: 0 });
    await ctxMenu(p, 1, 0);
    await p.click('.menu-pop .menu-item', 'Toggle Comment');
    await p.sleep(50);
    p.assert.deepEqual(await lines(p), ['A = 1', "' B = 2"]);
  });

  // ---- outline -------------------------------------------------------------------------------------------------
  const PROG = 'DECLARE SUB DrawBox ()\nCLS\nStart:\nDEF FNsq (X) = X * X\nEND\nSUB DrawBox\nEND SUB\nFUNCTION Area (R)\nEND FUNCTION';
  t.test('outline shows "(main module only)" for code without procedures', async (p) => {
    await open(p, 'PRINT 1');
    await p.ev('RC.app.renderOutline()');
    p.assert.deepEqual(await procItems(p), ['(main module only)']);
  });
  t.test('outline lists the module, labels, DEF FN, SUBs and FUNCTIONs in order', async (p) => {
    await open(p, PROG);
    await p.ev('RC.app.renderOutline()');
    const items = (await procItems(p)).map((s) => s.trim().replace(/\s+/g, ' '));
    p.assert.deepEqual(items, ['MODULE ED.BAS', 'Start', 'DEF FNsq', 'SUB DrawBox', 'FUNCTION Area']);
  });
  t.test('outline items show their line number as a tooltip', async (p) => {
    await open(p, PROG);
    await p.ev('RC.app.renderOutline()');
    const titles = await p.ev('[...document.querySelectorAll("#procList .proc-item")].map((e) => e.title)');
    p.assert.deepEqual(titles.slice(1), ['Line 3', 'Line 4', 'Line 6', 'Line 8']);
  });
  t.test('outline updates as you type a new SUB', async (p) => {
    await open(p, 'CLS\n');
    await p.ev('RC.app.renderOutline()');
    await typeKeys(p, 'SUB Explode\n');
    await p.wait('[...document.querySelectorAll("#procList .proc-item")].some((e) => /SUB\\s+Explode/.test(e.innerText))', 3000);
  });
  t.test('outline updates as you type a label', async (p) => {
    await open(p, 'CLS\n');
    await typeKeys(p, 'GameLoop:\n');
    await p.wait('[...document.querySelectorAll("#procList .proc-item")].some((e) => e.innerText.trim() === "GameLoop")', 3000);
  });
  t.test('outline drops a procedure when it is deleted', async (p) => {
    await open(p, 'FUNCTION Gone\nEND FUNCTION', { line: 0, col: 0 });
    await p.ev('RC.app.renderOutline()');
    p.assert.ok((await procItems(p)).some((x) => x.includes('Gone')));
    await p.key('/', { ctrl: true });
    await p.wait('[...document.querySelectorAll("#procList .proc-item")].every((e) => !e.innerText.includes("Gone"))', 3000);
  });
  t.test('outline ignores keywords followed by a colon', async (p) => {
    await open(p, 'CLS: PRINT\nEND:');
    await p.ev('RC.app.renderOutline()');
    p.assert.deepEqual(await procItems(p), ['(main module only)']);
  });
  t.test('clicking an outline SUB moves the caret to its line', async (p) => {
    await open(p, PROG, { line: 0 });
    await p.ev('RC.app.renderOutline()');
    await p.click('#procList .proc-item', 'DrawBox');
    p.assert.deepEqual(await cur(p), { line: 5, col: 0 });
    p.assert.equal(await p.ev('document.activeElement === RC.app.active.editor.ta'), true);
  });
  t.test('clicking an outline label moves the caret to it', async (p) => {
    await open(p, PROG, { line: 8 });
    await p.ev('RC.app.renderOutline()');
    await p.click('#procList .proc-item', 'Start');
    p.assert.equal((await cur(p)).line, 2);
  });
  t.test('clicking the MODULE entry goes to the top', async (p) => {
    await open(p, PROG, { line: 7 });
    await p.ev('RC.app.renderOutline()');
    await p.click('#procList .proc-item', 'MODULE');
    p.assert.deepEqual(await cur(p), { line: 0, col: 0 });
  });
  t.test('outline follows the active tab', async (p) => {
    await open(p, 'SUB InFileOne\nEND SUB', { path: 'C:\\MYPROGS\\OUT1.BAS' });
    await open(p, 'SUB InFileTwo\nEND SUB', { path: 'C:\\MYPROGS\\OUT2.BAS' });
    await p.ev('RC.app.renderOutline()');
    p.assert.ok((await procItems(p)).some((x) => x.includes('InFileTwo')));
    await p.click('#editorTabs .tab', 'OUT1.BAS');
    p.assert.ok((await procItems(p)).some((x) => x.includes('InFileOne')));
    p.assert.ok(!(await procItems(p)).some((x) => x.includes('InFileTwo')));
    await p.ev('RC.app.docs.filter((d) => /OUT\\d/.test(d.name)).forEach((d) => RC.app.closeDoc(d))');
  });

  // ---- F2 SUBs dialog ------------------------------------------------------------------------------------------------
  t.test('F2 opens the SUBs dialog listing the module and procedures', async (p) => {
    await open(p, PROG, { line: 0 });
    await p.key('F2');
    p.assert.equal(await p.waitModal(), 'SUBs');
    const rows = await p.texts('.modal-back .list-row');
    p.assert.equal(rows[0].replace(/\s+/g, ' ').trim(), 'ED.BAS (main module)');
    p.assert.deepEqual(rows.slice(1).map((s) => s.trim()), ['DEF FNsq', 'SUB DrawBox', 'FUNCTION Area']);
  });
  t.test('F2 SUBs dialog does not list labels', async (p) => {
    await open(p, PROG, { line: 0 });
    await p.key('F2');
    await p.waitModal();
    p.assert.ok(!(await p.texts('.modal-back .list-row')).some((x) => x.includes('Start')));
  });
  t.test('clicking a procedure in the SUBs dialog jumps there and closes it', async (p) => {
    await open(p, PROG, { line: 0 });
    await p.key('F2');
    await p.waitModal();
    await p.click('.modal-back .list-row', 'FUNCTION Area');
    await p.waitGone('.modal-back');
    p.assert.deepEqual(await cur(p), { line: 7, col: 0 });
  });
  t.test('clicking the main module in the SUBs dialog goes to the top', async (p) => {
    await open(p, PROG, { line: 6 });
    await p.key('F2');
    await p.waitModal();
    await p.click('.modal-back .list-row', 'main module');
    await p.waitGone('.modal-back');
    p.assert.deepEqual(await cur(p), { line: 0, col: 0 });
  });
  t.test('the SUBs dialog Close button closes it', async (p) => {
    await open(p, PROG, { line: 3 });
    await p.key('F2');
    await p.waitModal();
    await p.modalButton('Close');
    await p.waitGone('.modal-back');
    p.assert.equal((await cur(p)).line, 3);
  });
  t.test('View ▸ SUBs and FUNCTIONs… opens the SUBs dialog', async (p) => {
    await open(p, PROG);
    await p.menu('View', 'SUBs and FUNCTIONs…');
    p.assert.equal(await p.waitModal(), 'SUBs');
  });

  // ---- zoom -------------------------------------------------------------------------------------------------------
  t.test('Ctrl+= zooms the editor in by one pixel', async (p) => {
    await open(p, 'PRINT');
    const a = await edFont(p);
    await p.key('=', { ctrl: true });
    p.assert.equal(await edFont(p), a + 1);
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), a + 1);
  });
  t.test('Ctrl+- zooms the editor out', async (p) => {
    const a = await edFont(p);
    await p.key('-', { ctrl: true });
    await p.key('-', { ctrl: true });
    p.assert.equal(await edFont(p), a - 2);
  });
  t.test('zoom scales the line height and gutter rows', async (p) => {
    await open(p, 'A\nB');
    const h1 = await p.ev('RC.app.active.editor.inner.children[0].getBoundingClientRect().height');
    await p.key('=', { ctrl: true });
    await p.key('=', { ctrl: true });
    await p.key('=', { ctrl: true });
    await p.sleep(50);
    const h2 = await p.ev('RC.app.active.editor.inner.children[0].getBoundingClientRect().height');
    const l2 = await p.ev('RC.app.active.editor.hl.children[1].getBoundingClientRect().height');
    p.assert.ok(h2 > h1 + 3, `${h1} -> ${h2}`);
    p.assert.ok(Math.abs(h2 - l2) < 1.5, `${h2} vs ${l2}`);
  });
  t.test('zoom level persists across reload', async (p) => {
    const before = await p.ev('RC.app.settings.fontSize');
    await cleanAll(p);
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), before);
    p.assert.equal(await edFont(p), before);
  });
  t.test('View ▸ Zoom In and Zoom Out change the size', async (p) => {
    const a = await p.ev('RC.app.settings.fontSize');
    await p.menu('View', 'Zoom In');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), a + 1);
    await p.menu('View', 'Zoom Out');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), a);
  });
  t.test('Options ▸ Editor Font Size… sets an exact size', async (p) => {
    await p.menu('Options', 'Editor Font Size…');
    p.assert.equal(await p.waitModal(), 'Editor Font Size');
    await p.modalInput('20');
    await p.modalButton('OK');
    p.assert.equal(await edFont(p), 20);
  });
  t.test('zoom in stops at 28px', async (p) => {
    await p.menu('Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('27');
    await p.modalButton('OK');
    await p.key('=', { ctrl: true });
    await p.key('=', { ctrl: true });
    await p.key('=', { ctrl: true });
    p.assert.equal(await edFont(p), 28);
  });
  t.test('zoom out stops at 10px', async (p) => {
    await p.menu('Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('11');
    await p.modalButton('OK');
    await p.key('-', { ctrl: true });
    await p.key('-', { ctrl: true });
    p.assert.equal(await edFont(p), 10);
  });
  t.test('an out-of-range font size is ignored', async (p) => {
    const a = await edFont(p);
    await p.menu('Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('99');
    await p.modalButton('OK');
    p.assert.equal(await edFont(p), a);
    await p.menu('Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('15');
    await p.modalButton('OK');
    p.assert.equal(await edFont(p), 15);
  });
  t.test('clicking text still lands on the right character after zooming', async (p) => {
    await p.key('=', { ctrl: true });
    await p.key('=', { ctrl: true });
    await p.key('=', { ctrl: true });
    await open(p, 'AAAAAAAAAA\nBBBBBBBBBB\nCCCCCCCCCC', { line: 0, col: 0 });
    const [x, y] = await posXY(p, 2, 6);
    await p.clickAt(x - 2, y);
    const c = await cur(p);
    p.assert.equal(c.line, 2);
    p.assert.ok(c.col === 6 || c.col === 7, 'col ' + c.col);
    await p.key('-', { ctrl: true });
    await p.key('-', { ctrl: true });
    await p.key('-', { ctrl: true });
  });
};
