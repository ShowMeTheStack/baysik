// Debugger: breakpoints (gutter, F9, toolbar, menus, conditions, enable/disable, Breakpoints panel, persistence).
import { PATH, reset, load, lineOf, debug, pausedLine, gutterClasses, lineClasses, bpLines, bpOf, clickGutter, gutterPoint, cursorTo, mark, varVal } from './50-debug-helpers.mjs';

const P1 = [
  'x = 1',              // 0
  'y = 2',              // 1
  'z = x + y',          // 2
  'PRINT "Z="; z',      // 3
  'FOR i = 1 TO 5',     // 4
  '  s = s + i',        // 5
  'NEXT i',             // 6
  'PRINT "S="; s',      // 7
].join('\n');

const PSUB = [
  'CALL Greet("A")',          // 0
  'CALL Greet("B")',          // 1
  'PRINT "DONE"',             // 2
  'SUB Greet (n$)',           // 3
  '  PRINT "HI "; n$',        // 4
  'END SUB',                  // 5
].join('\n');

const P2PATH = 'C:\\MYPROGS\\E2EB.BAS';

async function bpRows(p) {
  await p.ev("RC.app.panels.show('bps')");
  return p.fn(() => [...document.querySelectorAll('.bpanel.active .list-row')].map((r) => ({
    enabled: r.querySelector('input[type=checkbox]').checked,
    loc: r.querySelector('.clickable').innerText,
    text: r.querySelector('.grow').innerText,
    cond: r.querySelector('input[type=text]').value,
  })));
}
const badge = (p) => p.ev("(document.querySelector('#bottomTabs .tab[data-id=bps] .count') || {}).innerText || ''");

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- gutter clicks ------------------------------------------------------------------------
  t.test('clicking a gutter line number adds a breakpoint on that line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 2);
    p.assert.deepEqual(await bpLines(p), [2]);
  });
  t.test('gutter breakpoint draws a red dot class on the gutter and tints the code line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    p.assert.match(await gutterClasses(p, 3), /\bbp\b/);
    p.assert.match(await lineClasses(p, 3), /\bbpline\b/);
    p.assert.doesNotMatch(await gutterClasses(p, 2), /\bbp\b/);
  });
  t.test('clicking the same gutter line again removes the breakpoint', async (p) => {
    await load(p, P1);
    await clickGutter(p, 2);
    await clickGutter(p, 2);
    p.assert.deepEqual(await bpLines(p), []);
    p.assert.doesNotMatch(await gutterClasses(p, 2), /\bbp\b/);
  });
  t.test('several gutter clicks give several breakpoints', async (p) => {
    await load(p, P1);
    await clickGutter(p, 0);
    await clickGutter(p, 5);
    await clickGutter(p, 7);
    p.assert.deepEqual(await bpLines(p), [0, 5, 7]);
  });
  t.test('a gutter-click breakpoint pauses the run before the line executes', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 3);
    p.assert.doesNotMatch(await p.screen(), /Z=/);
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'breakpoint');
  });
  t.test('clicking the gutter does not move the editor cursor', async (p) => {
    await load(p, P1);
    await cursorTo(p, 1, 2);
    await clickGutter(p, 6);
    p.assert.deepEqual(await p.ev('RC.app.active.editor.cursor()'), { line: 1, col: 2 });
  });
  t.test('clicking the gutter below the last line adds nothing', async (p) => {
    await load(p, 'x = 1\nPRINT x');
    const [x, y] = await gutterPoint(p, 1);
    await p.clickAt(x, y + 200);
    p.assert.deepEqual(await bpLines(p), []);
  });

  // ---- F9 / toolbar / menus ----------------------------------------------------------------
  t.test('F9 toggles a breakpoint on the cursor line', async (p) => {
    await load(p, P1);
    await cursorTo(p, 4, 3);
    await p.key('F9');
    p.assert.deepEqual(await bpLines(p), [4]);
    p.assert.match(await gutterClasses(p, 4), /\bbp\b/);
  });
  t.test('pressing F9 twice removes the breakpoint again', async (p) => {
    await load(p, P1);
    await cursorTo(p, 4);
    await p.key('F9');
    await p.key('F9');
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('toolbar breakpoint button toggles at the cursor line', async (p) => {
    await load(p, P1);
    await cursorTo(p, 6);
    await p.click('#tbBp');
    p.assert.deepEqual(await bpLines(p), [6]);
    await cursorTo(p, 6);
    await p.click('#tbBp');
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('Debug > Toggle Breakpoint menu item toggles at the cursor line', async (p) => {
    await load(p, P1);
    await cursorTo(p, 2);
    await p.menu('Debug', 'Toggle Breakpoint');
    p.assert.deepEqual(await bpLines(p), [2]);
  });
  t.test('Debug menu lists F9 as the Toggle Breakpoint shortcut', async (p) => {
    await load(p, P1);
    await p.click('.menu-btn', 'Debug');
    await p.wait("!!document.querySelector('.menu-pop')");
    const items = await p.menuItems();
    await p.closeMenus();
    const it = items.find((i) => i.label === 'Toggle Breakpoint');
    p.assert.equal(it.sc, 'F9');
    p.assert.ok(items.some((i) => i.label === 'Conditional Breakpoint…'));
    p.assert.ok(items.some((i) => i.label === 'Clear All Breakpoints'));
  });
  t.test('gutter context menu offers Add Breakpoint on a line without one', async (p) => {
    await load(p, P1);
    const [x, y] = await gutterPoint(p, 5);
    await p.clickAt(x, y, { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    const labels = (await p.menuItems()).map((i) => i.label);
    p.assert.ok(labels.includes('Add Breakpoint'));
    p.assert.ok(!labels.includes('Disable / Enable'));
    await p.click('.menu-pop .menu-item', 'Add Breakpoint');
    await p.sleep(60);
    p.assert.deepEqual(await bpLines(p), [5]);
  });
  t.test('gutter context menu offers Remove and Disable/Enable on a breakpoint line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 5);
    const [x, y] = await gutterPoint(p, 5);
    await p.clickAt(x, y, { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    const labels = (await p.menuItems()).map((i) => i.label);
    p.assert.ok(labels.includes('Remove Breakpoint'));
    p.assert.ok(labels.includes('Disable / Enable'));
    await p.click('.menu-pop .menu-item', 'Remove Breakpoint');
    await p.sleep(60);
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('gutter context menu Disable / Enable disables then re-enables', async (p) => {
    await load(p, P1);
    await clickGutter(p, 5);
    for (const want of [true, false]) {
      const [x, y] = await gutterPoint(p, 5);
      await p.clickAt(x, y, { button: 'right' });
      await p.wait("!!document.querySelector('.menu-pop')");
      await p.click('.menu-pop .menu-item', 'Disable / Enable');
      await p.sleep(60);
      p.assert.equal((await bpOf(p, 5)).disabled, want);
      p.assert.equal(/\bdisabled\b/.test(await gutterClasses(p, 5)), want);
    }
  });
  t.test('right-clicking the gutter only opens the menu and does not toggle a breakpoint', async (p) => {
    await load(p, P1);
    const [x, y] = await gutterPoint(p, 4);
    await p.clickAt(x, y, { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.closeMenus();
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('gutter context menu: Set Next Statement Here is disabled when not paused', async (p) => {
    await load(p, P1);
    const [x, y] = await gutterPoint(p, 2);
    await p.clickAt(x, y, { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((i) => i.label === 'Set Next Statement Here');
    await p.closeMenus();
    p.assert.equal(it.disabled, true);
  });
  t.test('editor text context menu Toggle Breakpoint uses the clicked line', async (p) => {
    await load(p, P1);
    await cursorTo(p, 0);
    const pt = await p.fn(() => { const ed = RC.app.active.editor; const r = ed.ta.getBoundingClientRect(); return [r.left + 20, r.top + 6.5 * ed.lineHeight]; });
    await p.clickAt(pt[0], pt[1], { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.click('.menu-pop .menu-item', 'Toggle Breakpoint');
    await p.sleep(60);
    p.assert.deepEqual(await bpLines(p), [6]);
  });

  // ---- conditional breakpoints ------------------------------------------------------------------
  t.test('Conditional Breakpoint dialog opens with the line number in its text', async (p) => {
    await load(p, P1);
    await cursorTo(p, 5);
    await p.menu('Debug', 'Conditional Breakpoint…');
    p.assert.equal(await p.waitModal(), 'Conditional Breakpoint');
    p.assert.match(await p.modalText(), /Stop at line 6 only when this is true/);
    await p.modalButton('Cancel');
  });
  t.test('conditional breakpoint gets a square (cond) gutter marker', async (p) => {
    await load(p, P1);
    await cursorTo(p, 5);
    await p.menu('Debug', 'Conditional Breakpoint…');
    await p.waitModal();
    await p.modalInput('i = 3');
    await p.modalButton('OK');
    p.assert.deepEqual(await bpOf(p, 5), { cond: 'i = 3', disabled: false });
    p.assert.match(await gutterClasses(p, 5), /\bbp\b.*\bcond\b/);
  });
  t.test('conditional breakpoint stops only when the condition is true', async (p) => {
    await load(p, P1);
    await cursorTo(p, 5);
    await p.menu('Debug', 'Conditional Breakpoint…');
    await p.waitModal();
    await p.modalInput('i = 3');
    await p.key('Enter');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 5);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i').value"), 3);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 's').value"), 3);
  });
  t.test('continuing from a conditional breakpoint stops at the next true occurrence', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 5); RC.app.updateBreakpoint(pa, 5, { cond: 'i MOD 2 = 0' }); }, PATH);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i').value"), 2);
    await p.key('F5');
    await p.waitState('paused');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i').value"), 4);
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /S= 15/);
  });
  t.test('conditional breakpoint that is never true lets the program finish', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 5); RC.app.updateBreakpoint(pa, 5, { cond: 'i > 100' }); }, PATH);
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /S= 15/);
  });
  t.test('conditional breakpoint on a string comparison', async (p) => {
    await load(p, 'FOR k = 1 TO 3\n  READ n$\n  PRINT n$\nNEXT\nDATA ANN, BOB, CY');
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 2); RC.app.updateBreakpoint(pa, 2, { cond: 'n$ = "BOB"' }); }, PATH);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'n$').value"), 'BOB');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'k').value"), 2);
  }, { timeout: 20000 });
  t.test('conditional breakpoint inside a SUB can test the SUB parameter', async (p) => {
    await load(p, PSUB);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 4); RC.app.updateBreakpoint(pa, 4, { cond: 'n$ = "B"' }); }, PATH);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.match(await p.screen(), /HI A/);
    p.assert.doesNotMatch(await p.screen(), /HI B/);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'n$').value"), 'B');
  });
  t.test('conditional breakpoint dialog Cancel adds no breakpoint', async (p) => {
    await load(p, P1);
    await cursorTo(p, 2);
    await p.menu('Debug', 'Conditional Breakpoint…');
    await p.waitModal();
    await p.modalInput('x = 1');
    await p.modalButton('Cancel');
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('conditional breakpoint dialog Escape adds no breakpoint', async (p) => {
    await load(p, P1);
    await cursorTo(p, 2);
    await p.menu('Debug', 'Conditional Breakpoint…');
    await p.waitModal();
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('conditional breakpoint dialog is prefilled with the existing condition', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 5); RC.app.updateBreakpoint(pa, 5, { cond: 's > 6' }); }, PATH);
    await cursorTo(p, 5);
    await p.menu('Debug', 'Conditional Breakpoint…');
    await p.waitModal();
    p.assert.equal(await p.ev("document.querySelector('.modal-back:last-child .modal input').value"), 's > 6');
    await p.modalInput('s > 9');
    await p.modalButton('OK');
    p.assert.equal((await bpOf(p, 5)).cond, 's > 9');
  });
  t.test('an empty condition makes a plain breakpoint', async (p) => {
    await load(p, P1);
    await cursorTo(p, 5);
    await p.menu('Debug', 'Conditional Breakpoint…');
    await p.waitModal();
    await p.modalInput('   ');
    await p.modalButton('OK');
    p.assert.deepEqual(await bpOf(p, 5), { cond: null, disabled: false });
    p.assert.doesNotMatch(await gutterClasses(p, 5), /\bcond\b/);
  });
  t.test('gutter context menu Conditional Breakpoint… sets a condition on that line', async (p) => {
    await load(p, P1);
    const [x, y] = await gutterPoint(p, 5);
    await p.clickAt(x, y, { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.click('.menu-pop .menu-item', 'Conditional Breakpoint…');
    p.assert.match(await p.waitModal(), /Conditional Breakpoint/);
    await p.modalInput('i = 5');
    await p.modalButton('OK');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i').value"), 5);
  });

  // ---- disable / enable -------------------------------------------------------------------------------
  t.test('a disabled breakpoint does not stop the program', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 3); RC.app.updateBreakpoint(pa, 3, { disabled: true }); }, PATH);
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('a disabled breakpoint draws a hollow (disabled) marker', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 3); RC.app.updateBreakpoint(pa, 3, { disabled: true }); }, PATH);
    p.assert.match(await gutterClasses(p, 3), /\bbp\b.*\bdisabled\b/);
  });
  t.test('re-enabling a disabled breakpoint makes it stop again', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 3); RC.app.updateBreakpoint(pa, 3, { disabled: true }); RC.app.updateBreakpoint(pa, 3, { disabled: false }); }, PATH);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 3);
  });

  // ---- breakpoints while paused ---------------------------------------------------------------------------
  t.test('breakpoint added while paused takes effect on Continue', async (p) => {
    await debug(p, P1, [0]);
    await clickGutter(p, 7);
    await p.key('F5');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 7);
    p.assert.match(await p.screen(), /Z= 3/);
  });
  t.test('breakpoint removed while paused no longer stops', async (p) => {
    await debug(p, P1, [0, 7]);
    await clickGutter(p, 7);
    await p.key('F5');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('breakpoint inside a loop stops on every iteration', async (p) => {
    await debug(p, P1, [5]);
    const seen = [];
    for (let k = 0; k < 5; k++) {
      seen.push(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i').value"));
      await p.key('F5');
      await p.waitState(['paused', 'ended']);
    }
    p.assert.deepEqual(seen, [1, 2, 3, 4, 5]);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('breakpoint in a SUB stops on every call', async (p) => {
    await debug(p, PSUB, [4]);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'n$').value"), 'A');
    await p.key('F5');
    await p.waitState('paused');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'n$').value"), 'B');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /DONE/);
  });
  t.test('breakpoint on a line with several statements stops before the first one', async (p) => {
    await debug(p, 'a = 1\nb = 2: c = 3: PRINT "X"\nPRINT "END"', [1]);
    p.assert.equal(await pausedLine(p), 1);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'b').value"), 0);
  });
  t.test('breakpoint on a comment line is not hit (program runs to the end)', async (p) => {
    await load(p, "x = 1\n' just a comment\nPRINT \"OK\"");
    await clickGutter(p, 1);
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
    p.assert.deepEqual(await bpLines(p), [1]);
  });
  t.test('status bar says "Paused at breakpoint" and the toolbar shows Continue', async (p) => {
    await debug(p, P1, [2]);
    p.assert.match(await p.status(), /Paused at breakpoint/);
    p.assert.equal(await p.text('#tbRun .lbl'), 'Continue');
    p.assert.equal(await p.text('#tbState'), 'Paused');
    p.assert.equal(await p.ev("document.getElementById('tbOut').disabled"), false);
  });
  t.test('pause at a breakpoint in a numbered program names the line number', async (p) => {
    await debug(p, '10 A = 1\n20 B = 2\n30 PRINT A + B', [1]);
    p.assert.match(await p.status(), /Paused at breakpoint in line 20/);
  });
  t.test('hitting a breakpoint while the Breakpoints panel is shown switches to Variables', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await p.click('#bottomTabs .tab[data-id=bps]');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    await p.sleep(50);
    p.assert.equal(await p.ev('RC.app.panels.active'), 'vars');
    p.assert.equal(await varVal(p, 'z'), '3');
  });
  t.test('hitting a breakpoint keeps the Watch panel if it is shown', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await p.click('#bottomTabs .tab[data-id=watch]');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'watch');
  });
  t.test('Stop while paused at a breakpoint ends the program', async (p) => {
    await debug(p, P1, [3]);
    await p.click('#tbStop');
    await p.waitState('ended');
    p.assert.doesNotMatch(await p.screen(), /Z=/);
    p.assert.equal(await p.ev('RC.app.active.editor.marks.exec'), null);
  });

  // ---- Breakpoints panel -------------------------------------------------------------------------------------
  t.test('Breakpoints panel shows "No breakpoints yet." when empty', async (p) => {
    await load(p, P1);
    await p.click('#bottomTabs .tab[data-id=bps]');
    p.assert.match(await p.panelText(), /No breakpoints yet\./);
  });
  t.test('Breakpoints panel lists file:line and the source text, sorted by line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 5);
    await clickGutter(p, 2);
    const rows = await bpRows(p);
    p.assert.equal(rows.length, 2);
    p.assert.equal(rows[0].loc, 'E2E.BAS:3');
    p.assert.equal(rows[0].text, 'z = x + y');
    p.assert.equal(rows[1].loc, 'E2E.BAS:6');
    p.assert.equal(rows[1].text, 's = s + i');
    p.assert.ok(rows.every((r) => r.enabled && r.cond === ''));
  });
  t.test('Breakpoints tab badge counts breakpoints and disappears at zero', async (p) => {
    await load(p, P1);
    p.assert.equal(await badge(p), '');
    await clickGutter(p, 1);
    await clickGutter(p, 2);
    await clickGutter(p, 3);
    p.assert.equal(await badge(p), '3');
    await clickGutter(p, 2);
    p.assert.equal(await badge(p), '2');
    await p.ev('RC.app.clearBreakpoints()');
    p.assert.equal(await badge(p), '');
  });
  t.test('unticking Enabled in the panel disables the breakpoint', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await bpRows(p);
    await p.click('.bpanel.active .list-row input[type=checkbox]');
    p.assert.equal((await bpOf(p, 3)).disabled, true);
    p.assert.match(await gutterClasses(p, 3), /\bdisabled\b/);
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('ticking Enabled again re-enables the breakpoint', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await bpRows(p);
    await p.click('.bpanel.active .list-row input[type=checkbox]');
    await p.click('.bpanel.active .list-row input[type=checkbox]');
    p.assert.equal((await bpOf(p, 3)).disabled, false);
    p.assert.equal((await bpRows(p))[0].enabled, true);
  });
  t.test('typing a condition in the panel row sets the condition (Enter commits)', async (p) => {
    await load(p, P1);
    await clickGutter(p, 5);
    await bpRows(p);
    await p.click('.bpanel.active .list-row input[type=text]');
    await p.type('i = 4');
    await p.key('Enter');
    await p.sleep(60);
    p.assert.equal((await bpOf(p, 5)).cond, 'i = 4');
    p.assert.match(await gutterClasses(p, 5), /\bcond\b/);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i').value"), 4);
  });
  t.test('typing in the panel condition box does not trigger editor shortcuts (F9 stays local)', async (p) => {
    await load(p, P1);
    await clickGutter(p, 5);
    await bpRows(p);
    await p.click('.bpanel.active .list-row input[type=text]');
    await p.type('x');
    p.assert.equal(await p.ev("document.querySelector('.bpanel.active .list-row input[type=text]').value"), 'x');
    p.assert.deepEqual(await bpLines(p), [5]);
  });
  t.test('clearing the condition in the panel makes it unconditional', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 5); RC.app.updateBreakpoint(pa, 5, { cond: 'i = 2' }); }, PATH);
    const rows = await bpRows(p);
    p.assert.equal(rows[0].cond, 'i = 2');
    await p.click('.bpanel.active .list-row input[type=text]');
    await p.fn(() => { const i = document.querySelector('.bpanel.active .list-row input[type=text]'); i.select(); });
    await p.key('Delete');
    await p.key('Enter');
    await p.sleep(60);
    p.assert.equal((await bpOf(p, 5)).cond, null);
  });
  t.test('clicking a breakpoint location in the panel jumps the cursor to that line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 6);
    await cursorTo(p, 0);
    await bpRows(p);
    await p.click('.bpanel.active .list-row .clickable');
    await p.sleep(60);
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 6);
  });
  t.test('clicking a breakpoint in another file opens that file at the line', async (p) => {
    await load(p, 'PRINT 1\nPRINT 2\nPRINT 3', P2PATH);
    await clickGutter(p, 2);
    await load(p, P1);
    p.assert.equal(await p.activePath(), PATH);
    await bpRows(p);
    await p.click('.bpanel.active .list-row .clickable', 'E2EB.BAS:3');
    await p.sleep(80);
    p.assert.equal(await p.activePath(), P2PATH);
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 2);
  });
  t.test('the remove (x) button in the panel deletes only that breakpoint', async (p) => {
    await load(p, P1);
    await clickGutter(p, 1);
    await clickGutter(p, 4);
    await bpRows(p);
    const sel = await mark(p, "() => [...document.querySelectorAll('.bpanel.active .list-row')].find(r => r.innerText.includes('E2E.BAS:5')).querySelector('button')");
    await p.click(sel);
    p.assert.deepEqual(await bpLines(p), [1]);
    p.assert.equal((await bpRows(p)).length, 1);
    p.assert.doesNotMatch(await gutterClasses(p, 4), /\bbp\b/);
  });
  t.test('Remove all clears every breakpoint in every file', async (p) => {
    await load(p, 'PRINT 1\nPRINT 2', P2PATH);
    await clickGutter(p, 0);
    await load(p, P1);
    await clickGutter(p, 2);
    await clickGutter(p, 3);
    p.assert.equal((await bpRows(p)).length, 3);
    await p.click('.bpanel.active .small-btn', 'Remove all');
    p.assert.deepEqual(await bpLines(p), []);
    p.assert.deepEqual(await bpLines(p, P2PATH), []);
    p.assert.match(await p.panelText(), /No breakpoints yet/);
    p.assert.equal(await badge(p), '');
  });
  t.test('Debug > Clear All Breakpoints removes the gutter markers', async (p) => {
    await load(p, P1);
    await clickGutter(p, 2);
    await clickGutter(p, 5);
    await p.menu('Debug', 'Clear All Breakpoints');
    p.assert.deepEqual(await bpLines(p), []);
    p.assert.doesNotMatch(await gutterClasses(p, 2), /\bbp\b/);
    p.assert.doesNotMatch(await gutterClasses(p, 5), /\bbp\b/);
  });
  t.test('the panel row text follows edits to the source line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 0);
    await cursorTo(p, 0, 5);
    await p.type('0');
    p.assert.equal((await bpRows(p))[0].text, 'x = 10');
  });

  // ---- persistence and line shifting ----------------------------------------------------------------
  t.test('breakpoints are saved to storage with condition and disabled flag', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 2); RC.app.toggleBreakpoint(pa, 5); RC.app.updateBreakpoint(pa, 5, { cond: 'i = 2' }); RC.app.updateBreakpoint(pa, 2, { disabled: true }); }, PATH);
    const saved = await p.fn(() => RC.UI.storage.get('breakpoints', {}));
    const list = saved[PATH].sort((a, b) => a.line - b.line);
    p.assert.deepEqual(list, [{ line: 2, cond: null, disabled: true }, { line: 5, cond: 'i = 2', disabled: false }]);
  });
  t.test('breakpoints survive a page reload (lines, condition, disabled)', async (p) => {
    await load(p, P1);
    await p.fn((pa) => { RC.app.toggleBreakpoint(pa, 2); RC.app.toggleBreakpoint(pa, 5); RC.app.updateBreakpoint(pa, 5, { cond: 'i = 2' }); RC.app.updateBreakpoint(pa, 2, { disabled: true }); }, PATH);
    await p.sleep(300);
    await p.reload();
    p.assert.deepEqual(await bpLines(p), [2, 5]);
    p.assert.deepEqual(await bpOf(p, 5), { cond: 'i = 2', disabled: false });
    p.assert.equal((await bpOf(p, 2)).disabled, true);
    await p.ev("RC.app.panels.show('bps')");
    p.assert.equal(await badge(p), '2');
  }, { timeout: 40000 });
  t.test('after a reload the restored breakpoint still pauses the program', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await p.sleep(300);
    await p.reload();
    await p.fn((pa) => RC.app.openFile(pa), PATH);
    await p.sleep(100);
    p.assert.match(await gutterClasses(p, 3), /\bbp\b/);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 3);
  }, { timeout: 40000 });
  t.test('inserting a line above a breakpoint moves it down', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await cursorTo(p, 0, 0);
    await p.key('Enter');
    await p.sleep(60);
    p.assert.deepEqual(await bpLines(p), [4]);
    p.assert.match(await gutterClasses(p, 4), /\bbp\b/);
    p.assert.doesNotMatch(await gutterClasses(p, 3), /\bbp\b/);
  });
  t.test('pasting several lines above a breakpoint moves it by that many lines', async (p) => {
    await load(p, P1);
    await clickGutter(p, 5);
    await cursorTo(p, 1, 0);
    await p.insertText('a1 = 1\na2 = 2\na3 = 3\n');
    await p.sleep(60);
    p.assert.deepEqual(await bpLines(p), [8]);
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(8)'), '  s = s + i');
  });
  t.test('deleting a line above a breakpoint moves it up', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await cursorTo(p, 1, 0);
    await p.key('Backspace');
    await p.sleep(60);
    p.assert.deepEqual(await bpLines(p), [2]);
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(2)'), 'PRINT "Z="; z');
  });
  t.test('editing lines below a breakpoint leaves it in place', async (p) => {
    await load(p, P1);
    await clickGutter(p, 2);
    await cursorTo(p, 6, 6);
    await p.key('Enter');
    await p.type('PRINT 9');
    p.assert.deepEqual(await bpLines(p), [2]);
  });
  t.test('a moved breakpoint is persisted at its new line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await cursorTo(p, 0, 0);
    await p.key('Enter');
    await p.sleep(60);
    const saved = await p.fn(() => RC.UI.storage.get('breakpoints', {}));
    p.assert.deepEqual(saved[PATH].map((b) => b.line), [4]);
  });
  t.test('a moved breakpoint pauses on the same statement at its new line', async (p) => {
    await load(p, P1);
    await clickGutter(p, 3);
    await cursorTo(p, 0, 0);
    await p.key('Enter');
    await p.sleep(60);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 4);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'z').value"), 3);
  });
  t.test('breakpoints are per-file: same line in another file is independent', async (p) => {
    await load(p, 'PRINT 1\nPRINT 2\nPRINT 3', P2PATH);
    await clickGutter(p, 1);
    await load(p, P1);
    p.assert.deepEqual(await bpLines(p), []);
    p.assert.doesNotMatch(await gutterClasses(p, 1), /\bbp\b/);
    p.assert.deepEqual(await bpLines(p, P2PATH), [1]);
  });
};
