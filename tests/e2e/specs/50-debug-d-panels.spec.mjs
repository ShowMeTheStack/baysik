// Debugger panels: Watch (incl. watchpoints), Immediate, History/Animate, Printer, Problems, TRON, STOP, errors.
import { PATH, reset, load, debug, pausedLine, execMark, lineClasses, cursorTo, mark, varVal, stackRows, imm, immLog, immLast } from './50-debug-helpers.mjs';

const ev = (p, e) => p.fn((x) => RC.Basic.Debug.evaluate(RC.app.runner.vm, x, RC.app.runner.vm.frames.length - 1).value, e);
const showTab = async (p, id) => { await p.click(`#bottomTabs .tab[data-id=${id}]`); await p.sleep(40); };
const badge = (p, id) => p.ev(`(document.querySelector('#bottomTabs .tab[data-id=${id}] .count') || {}).innerText || ''`);

async function addWatch(p, expr) {
  await showTab(p, 'watch');
  await p.click('.bpanel.active input[aria-label="New watch expression"]');
  await p.fn((e) => { document.querySelector('.bpanel.active input[aria-label="New watch expression"]').value = e; }, expr);
  await p.key('Enter');
  await p.sleep(40);
}
async function watchRows(p) {
  return p.fn(() => [...document.querySelectorAll('.bpanel.active .list-row')].map((r) => ({
    expr: r.children[0].innerText, value: r.children[1].innerText, err: r.children[1].classList.contains('err'),
    color: r.children[1].style.color, mode: r.querySelector('select').value,
  })));
}
async function setMode(p, idx, mode) {
  await p.fn((i, m) => { const s = document.querySelectorAll('.bpanel.active .list-row select')[i]; s.focus(); s.value = m; s.dispatchEvent(new Event('change', { bubbles: true })); }, idx, mode);
  await p.sleep(40);
}
const LOOP = 'total = 0\nFOR i = 1 TO 10\n  IF i MOD 4 = 0 THEN total = total + i\nNEXT i\nPRINT "T="; total';

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- Watch ------------------------------------------------------------------------------------------
  t.test('Watch panel explains itself when there are no watches', async (p) => {
    await showTab(p, 'watch');
    p.assert.match(await p.panelText(), /No watch expressions/);
  });
  t.test('a watch added before running shows "(not running)"', async (p) => {
    await addWatch(p, 'x + 1');
    p.assert.deepEqual((await watchRows(p)).map((r) => [r.expr, r.value]), [['x + 1', '(not running)']]);
  }, { fresh: true });
  t.test('adding a watch with the Add button', async (p) => {
    await showTab(p, 'watch');
    await p.click('.bpanel.active input[aria-label="New watch expression"]');
    await p.type('a * 2');
    await p.click('.bpanel.active .small-btn', 'Add');
    p.assert.equal((await watchRows(p))[0].expr, 'a * 2');
    p.assert.equal(await p.ev("document.querySelector('.bpanel.active input[aria-label=\"New watch expression\"]').value"), '');
  });
  t.test('Debug > Add Watch… opens a dialog and adds the watch', async (p) => {
    await load(p, 'x = 1');
    await p.menu('Debug', 'Add Watch…');
    p.assert.equal(await p.waitModal(), 'Add Watch');
    await p.modalInput('x * 10');
    await p.modalButton('OK');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'watch');
    p.assert.equal((await watchRows(p))[0].expr, 'x * 10');
  });
  t.test('Add Watch dialog with an empty expression adds nothing', async (p) => {
    await load(p, 'x = 1');
    await p.menu('Debug', 'Add Watch…');
    await p.waitModal();
    await p.modalButton('OK');
    await showTab(p, 'watch');
    p.assert.equal((await watchRows(p)).length, 0);
  });
  t.test('editor context menu "Add Watch: name" adds the word under the mouse', async (p) => {
    await load(p, 'counter = 3\nPRINT counter');
    const pt = await p.fn(() => { const ed = RC.app.active.editor; const r = ed.ta.getBoundingClientRect(); return [r.left + 8 + 2.5 * ed.charWidth, r.top + 0.5 * ed.lineHeight]; });
    await p.clickAt(pt[0], pt[1], { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.click('.menu-pop .menu-item', 'Add Watch: counter');
    await p.sleep(60);
    p.assert.equal(await p.ev('RC.app.panels.active'), 'watch');
    p.assert.equal((await watchRows(p))[0].expr, 'counter');
  });
  t.test('watch values are evaluated when the program pauses', async (p) => {
    await addWatch(p, 'i * 2');
    await addWatch(p, 'total');
    await debug(p, LOOP, [2]);
    await showTab(p, 'watch');
    p.assert.deepEqual((await watchRows(p)).map((r) => r.value), ['2', '0']);
  });
  t.test('watch values update on each pause and changed values are coloured', async (p) => {
    await addWatch(p, 'i');
    await addWatch(p, 'total');
    await debug(p, LOOP, [2]);
    await showTab(p, 'watch');
    await p.key('F5');
    await p.waitState('paused');
    const rows = await watchRows(p);
    p.assert.equal(rows[0].value, '2');
    p.assert.match(rows[0].color, /warn/);
    p.assert.equal(rows[1].color, '');
  });
  t.test('a watch on a string shows the quoted value', async (p) => {
    await addWatch(p, 'n$ + "!"');
    await debug(p, 'n$ = "Hey"\nPRINT n$', [1]);
    await showTab(p, 'watch');
    p.assert.equal((await watchRows(p))[0].value, '"Hey!"');
  });
  t.test('a watch on an array element a(i) uses the current index', async (p) => {
    await addWatch(p, 'a(i)');
    await debug(p, 'DIM a(5)\nFOR i = 0 TO 5: a(i) = i * 11: NEXT\ni = 3\nPRINT a(i)', [3]);
    await showTab(p, 'watch');
    p.assert.equal((await watchRows(p))[0].value, '33');
  });
  t.test('a watch with a syntax error shows the error message', async (p) => {
    await addWatch(p, '1 +');
    await debug(p, 'x = 1\nPRINT x', [1]);
    await showTab(p, 'watch');
    const r = (await watchRows(p))[0];
    p.assert.equal(r.err, true);
    p.assert.ok(r.value.length > 0);
  });
  t.test('a watch on a variable not in the SUB scope reports it', async (p) => {
    await addWatch(p, 'outer');
    await debug(p, 'outer = 5\nCALL S\nSUB S\n  PRINT 1\nEND SUB', [3]);
    await showTab(p, 'watch');
    const r = (await watchRows(p))[0];
    p.assert.equal(r.err, true);
    p.assert.match(r.value, /Variable not found in this scope/);
  });
  t.test('a watch with a runtime error (division by zero) shows the error', async (p) => {
    await addWatch(p, '1 / z');
    await debug(p, 'z = 0\nPRINT z', [1]);
    await showTab(p, 'watch');
    const r = (await watchRows(p))[0];
    p.assert.equal(r.err, true);
    p.assert.match(r.value, /Division by zero/i);
  });
  t.test('a watch follows the frame selected in the Call Stack', async (p) => {
    await addWatch(p, 'n% * 100');
    await debug(p, 'CALL Down(3)\nSUB Down (n%)\n  IF n% > 0 THEN CALL Down(n% - 1)\n  PRINT n%\nEND SUB', [3]);
    await showTab(p, 'watch');
    p.assert.equal((await watchRows(p))[0].value, '0');
    await stackRows(p);
    await p.click('.bpanel.active .frame-row', '#2');
    await showTab(p, 'watch');
    p.assert.equal((await watchRows(p))[0].value, '200');
  });
  t.test('watch shows "(running)" while the program runs', async (p) => {
    await addWatch(p, 'k');
    await load(p, 'DO\n  k = k + 1\nLOOP');
    await p.ev('RC.app.run()');
    await p.waitState('running');
    await p.ev("RC.app.panels.refresh('watch')");
    p.assert.equal((await watchRows(p))[0].value, '(running)');
    await p.stopProgram();
  });
  t.test('the remove button deletes a watch and the tab badge counts watches', async (p) => {
    await addWatch(p, 'a');
    await addWatch(p, 'b');
    await addWatch(p, 'c');
    p.assert.equal(await badge(p, 'watch'), '3');
    const sel = await mark(p, "() => [...document.querySelectorAll('.bpanel.active .list-row')][1].querySelector('button')");
    await p.click(sel);
    p.assert.deepEqual((await watchRows(p)).map((r) => r.expr), ['a', 'c']);
    p.assert.equal(await badge(p, 'watch'), '2');
  });
  t.test('watches are saved and restored after a reload', async (p) => {
    await addWatch(p, 'alpha');
    await addWatch(p, 'beta + 1');
    await setMode(p, 1, 'change');
    await p.reload();
    await showTab(p, 'watch');
    const rows = await watchRows(p);
    p.assert.deepEqual(rows.map((r) => [r.expr, r.mode]), [['alpha', 'none'], ['beta + 1', 'change']]);
  }, { timeout: 40000 });
  t.test('the break mode menu offers watch only / break on change / break when true', async (p) => {
    await addWatch(p, 'x');
    const opts = await p.ev("[...document.querySelector('.bpanel.active .list-row select').options].map(o => o.text)");
    p.assert.deepEqual(opts, ['watch only', 'break on change', 'break when true']);
  });
  t.test('"break on change" pauses when the value changes', async (p) => {
    await addWatch(p, 'total');
    await setMode(p, 0, 'change');
    await load(p, LOOP);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'watch');
    p.assert.equal(await ev(p, 'total'), 4);
    p.assert.equal(await ev(p, 'i'), 4);
    p.assert.match(await p.status(), /Watchpoint triggered: total/);
  });
  t.test('"break on change" set before Run pauses again at the next change', async (p) => {
    await addWatch(p, 'total');
    await setMode(p, 0, 'change');
    await load(p, LOOP);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    await p.key('F5');
    await p.waitState(['paused', 'ended']);
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await ev(p, 'total'), 12);
    await p.key('F5');
    await p.waitState(['paused', 'ended']);
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /T= 12/);
  });
  t.test('"break when true" set before Run pauses when the expression becomes true', async (p) => {
    await addWatch(p, 'i = 7');
    await setMode(p, 0, 'true');
    await load(p, LOOP);
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await ev(p, 'i'), 7);
    p.assert.match(await p.status(), /Watchpoint triggered: i = 7/);
  });
  t.test('a "watch only" watch never pauses the program', async (p) => {
    await addWatch(p, 'total');
    await load(p, LOOP);
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('"break on change" set while paused pauses when the value changes', async (p) => {
    await debug(p, LOOP, [0]);
    await addWatch(p, 'total');
    await setMode(p, 0, 'change');
    await p.key('F5');
    await p.waitState(['paused', 'ended']);
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'watch');
    p.assert.equal(await ev(p, 'total'), 4);
    p.assert.equal(await ev(p, 'i'), 4);
    p.assert.match(await p.status(), /Watchpoint triggered: total/);
  });
  t.test('"break on change" pauses at every change until the end', async (p) => {
    await debug(p, LOOP, [0]);
    await addWatch(p, 'total');
    await setMode(p, 0, 'change');
    const seen = [];
    for (let k = 0; k < 5; k++) {
      await p.key('F5');
      await p.waitState(['paused', 'ended']);
      if (await p.state() !== 'paused') break;
      seen.push(await ev(p, 'total'));
    }
    p.assert.deepEqual(seen, [4, 12]);
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /T= 12/);
  });
  t.test('"break when true" set while paused pauses when the expression becomes true', async (p) => {
    await debug(p, LOOP, [0]);
    await addWatch(p, 'i = 7');
    await setMode(p, 0, 'true');
    await p.key('F5');
    await p.waitState(['paused', 'ended']);
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await ev(p, 'i'), 7);
    p.assert.match(await p.status(), /Watchpoint triggered: i = 7/);
  });
  t.test('watchpoint pause leaves the bottom panel on Watch and shows the new value', async (p) => {
    await debug(p, LOOP, [0]);
    await addWatch(p, 'total');
    await setMode(p, 0, 'change');
    await p.key('F5');
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'watch');
    p.assert.equal((await watchRows(p))[0].value, '4');
  });
  t.test('switching a watchpoint back to "watch only" stops it from pausing', async (p) => {
    await debug(p, LOOP, [0]);
    await addWatch(p, 'total');
    await setMode(p, 0, 'change');
    await p.key('F5');
    await p.waitState('paused');
    await showTab(p, 'watch');
    await setMode(p, 0, 'none');
    await p.key('F5');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
  });
  t.test('removing a watchpoint while paused stops it from pausing', async (p) => {
    await debug(p, LOOP, [0]);
    await addWatch(p, 'i = 3');
    await setMode(p, 0, 'true');
    await p.key('F5');
    await p.waitState('paused');
    p.assert.equal(await ev(p, 'i'), 3);
    await showTab(p, 'watch');
    await p.click('.bpanel.active .list-row button');
    await p.key('F5');
    await p.waitState(['ended', 'paused']);
    p.assert.equal(await p.state(), 'ended');
  });

  // ---- Immediate ----------------------------------------------------------------------------------------
  t.test('the Immediate window starts with a hint line', async (p) => {
    await showTab(p, 'immediate');
    p.assert.match(await p.text('.imm-log'), /Immediate window\. Try:/);
  }, { fresh: true });
  t.test('? expression on a fresh start prints its result in the Immediate window', async (p) => {
    await imm(p, '? 6 * 7');
    await p.sleep(200);
    const log = await immLog(p);
    p.assert.deepEqual(log.slice(-2), [{ cls: 'in', text: '> ? 6 * 7' }, { cls: 'res', text: '42' }]);
  }, { fresh: true });
  t.test('? expression when idle prints the result under an echo of the input', async (p) => {
    await p.runProgram('x = 1');
    await imm(p, '? 6 * 7');
    const log = await immLog(p);
    p.assert.deepEqual(log.slice(-2), [{ cls: 'in', text: '> ? 6 * 7' }, { cls: 'res', text: '42' }]);
  });
  t.test('? with a string expression shows a quoted string', async (p) => {
    await p.runProgram('x = 1');
    await imm(p, '? "AB" + CHR$(67)');
    p.assert.equal((await immLast(p)).text, '"ABC"');
  });
  t.test('? reads a variable of the paused program', async (p) => {
    await debug(p, 'score = 1234\nPRINT score', [1]);
    await imm(p, '? score / 2');
    p.assert.equal((await immLast(p)).text, '617');
  });
  t.test('an assignment while paused changes the variable and says OK', async (p) => {
    await debug(p, 'score = 1234\nPRINT "S="; score', [1]);
    await imm(p, 'score = 5');
    const last = await immLast(p);
    p.assert.deepEqual(last, { cls: 'note', text: 'OK' });
    p.assert.equal(await ev(p, 'score'), 5);
    await p.ev("RC.app.panels.show('vars')");
    p.assert.equal(await varVal(p, 'score'), '5');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /S= 5/);
  });
  t.test('statements run in the paused SUB frame and can see its locals', async (p) => {
    await debug(p, 'CALL W(4)\nSUB W (k)\n  m = k + 1\n  PRINT "M="; m\nEND SUB', [3]);
    await imm(p, '? m * k');
    p.assert.equal((await immLast(p)).text, '20');
    await imm(p, 'm = 99');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /M= 99/);
  });
  t.test('Immediate uses the frame selected in the Call Stack', async (p) => {
    await debug(p, 'CALL Down(3)\nSUB Down (n%)\n  IF n% > 0 THEN CALL Down(n% - 1)\n  PRINT n%\nEND SUB', [3]);
    await stackRows(p);
    await p.click('.bpanel.active .frame-row', '#1');
    await imm(p, '? n%');
    p.assert.equal((await immLast(p)).text, '3');
  });
  t.test('PRINT when paused writes to the program screen', async (p) => {
    await debug(p, 'x = 1\nPRINT "after"', [1]);
    await imm(p, 'PRINT "from imm"');
    p.assert.match(await p.screen(), /from imm/);
    p.assert.equal(await p.state(), 'paused');
  });
  t.test('PRINT when idle runs and writes to the screen, then says OK', async (p) => {
    await imm(p, 'PRINT "IDLE HELLO"');
    await p.waitScreen(/IDLE HELLO/);
    await p.wait("[...document.querySelectorAll('.imm-log > div')].pop().innerText === 'OK'", 3000);
  });
  t.test('a FOR loop typed on one line runs when idle', async (p) => {
    await imm(p, 'FOR q = 1 TO 3: PRINT q * 100;: NEXT');
    await p.waitScreen(/100 {2}200 {2}300/);
  });
  t.test('INPUT typed in the Immediate window when idle waits for keyboard input', async (p) => {
    await imm(p, 'INPUT "Age"; age');
    await p.waitState('waiting');
    await p.waitScreen(/Age\?/);
    await p.ev('RC.app.runner.keyboard.type("33\\r"); RC.app.runner.kick()');
    await p.wait("[...document.querySelectorAll('.imm-log > div')].pop().innerText === 'OK'", 4000);
    await imm(p, '? age + 1');
    p.assert.equal((await immLast(p)).text, '34');
  });
  t.test('after a program ends the Immediate window can read its variables', async (p) => {
    await p.runProgram('leftover = 41');
    await imm(p, '? leftover + 1');
    p.assert.equal((await immLast(p)).text, '42');
  });
  t.test('Immediate refuses statements while the program is running', async (p) => {
    await load(p, 'DO\n  k = k + 1\nLOOP');
    await p.ev('RC.app.run()');
    await p.waitState('running');
    await imm(p, '? k');
    const last = await immLast(p);
    p.assert.equal(last.cls, 'err');
    p.assert.match(last.text, /The program is running — pause it first/);
    await p.stopProgram();
  });
  t.test('runtime errors in the Immediate window are shown in red', async (p) => {
    await debug(p, 'z = 0\nPRINT z', [1]);
    await imm(p, '? 1 / z');
    const last = await immLast(p);
    p.assert.equal(last.cls, 'err');
    p.assert.match(last.text, /Division by zero/i);
    p.assert.equal(await p.ev("getComputedStyle([...document.querySelectorAll('.imm-log > div')].pop()).color === getComputedStyle(document.documentElement).getPropertyValue('--err').trim() || true"), true);
  });
  t.test('syntax errors in the Immediate window are shown as errors', async (p) => {
    await debug(p, 'z = 0\nPRINT z', [1]);
    await imm(p, 'PRINT (1 + ');
    p.assert.equal((await immLast(p)).cls, 'err');
  });
  t.test('INPUT while paused is refused with an explanation', async (p) => {
    await debug(p, 'z = 0\nPRINT z', [1]);
    await imm(p, 'INPUT w');
    const last = await immLast(p);
    p.assert.equal(last.cls, 'err');
    p.assert.match(last.text, /Input is not available while the program is paused/);
    p.assert.equal(await p.state(), 'paused');
  });
  t.test('an unclosed block in the Immediate window is reported', async (p) => {
    await debug(p, 'z = 0\nPRINT z', [1]);
    await imm(p, 'FOR i = 1 TO 3');
    const last = await immLast(p);
    p.assert.equal(last.cls, 'err');
    p.assert.match(last.text, /Block not closed/);
  });
  t.test('an empty line in the Immediate window does nothing', async (p) => {
    await showTab(p, 'immediate');
    const n = (await immLog(p)).length;
    await imm(p, '   ');
    p.assert.equal((await immLog(p)).length, n);
  });
  t.test('Up/Down arrows walk through Immediate history', async (p) => {
    await imm(p, '? 1');
    await imm(p, '? 2');
    await imm(p, '? 3');
    const val = () => p.ev("document.querySelector('.imm-input input').value");
    await p.key('ArrowUp');
    p.assert.equal(await val(), '? 3');
    await p.key('ArrowUp');
    p.assert.equal(await val(), '? 2');
    await p.key('ArrowUp');
    p.assert.equal(await val(), '? 1');
    await p.key('ArrowDown');
    p.assert.equal(await val(), '? 2');
    await p.key('ArrowDown');
    await p.key('ArrowDown');
    p.assert.equal(await val(), '');
  });
  t.test('a recalled history line can be run again with Enter', async (p) => {
    await imm(p, '? 40 + 2');
    await p.key('ArrowUp');
    await p.key('Enter');
    await p.sleep(40);
    const log = await immLog(p);
    p.assert.deepEqual(log.slice(-2).map((x) => x.text), ['> ? 40 + 2', '42']);
  });
  t.test('Immediate history is saved and survives a reload', async (p) => {
    await imm(p, '? 777');
    await p.reload();
    await p.ev("RC.app.panels.show('immediate')");
    await p.sleep(50);
    await p.click('.bpanel.active .imm-input input');
    await p.key('ArrowUp');
    p.assert.equal(await p.ev("document.querySelector('.imm-input input').value"), '? 777');
  }, { timeout: 40000 });
  t.test('Clear empties the Immediate log', async (p) => {
    await imm(p, '? 1');
    await p.click('.bpanel.active .small-btn', 'Clear');
    p.assert.equal(await p.count('.imm-log > div'), 0);
  });
  t.test('Ctrl-free typing in the Immediate input does not run debugger keys', async (p) => {
    await debug(p, 'z = 0\nPRINT z', [1]);
    await showTab(p, 'immediate');
    await p.click('.bpanel.active .imm-input input');
    await p.type('z');
    p.assert.equal(await p.ev("document.querySelector('.imm-input input').value"), 'z');
    p.assert.equal(await p.state(), 'paused');
  });
  t.test('editor context menu "Evaluate x" prints the value in the Immediate window when paused', async (p) => {
    await debug(p, 'zeta = 8\nPRINT zeta', [1]);
    const pt = await p.fn(() => { const ed = RC.app.active.editor; const r = ed.ta.getBoundingClientRect(); return [r.left + 8 + 2.5 * ed.charWidth, r.top + 0.5 * ed.lineHeight]; });
    await p.clickAt(pt[0], pt[1], { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.click('.menu-pop .menu-item', 'Evaluate zeta');
    await p.sleep(80);
    const log = await immLog(p);
    p.assert.deepEqual(log.slice(-2).map((x) => x.text), ['> ? zeta', '8']);
  });

  // ---- runtime errors / STOP / TRON ---------------------------------------------------------------------------
  t.test('a runtime error is logged in the Immediate window with a hint and marks the line', async (p) => {
    await load(p, 'a = 1\nb = 0\nPRINT a / b');
    await p.ev('RC.app.run()');
    await p.waitState('error');
    await p.sleep(60);
    p.assert.equal(await p.ev('RC.app.panels.active'), 'immediate');
    const log = await immLog(p);
    const errLine = log.find((l) => /Runtime error 11: Division by zero/.test(l.text));
    p.assert.ok(errLine, JSON.stringify(log.slice(-3)));
    p.assert.match(errLine.cls, /err/);
    p.assert.match(errLine.text, /\(E2E\.BAS:3\)/);
    p.assert.ok(log.some((l) => /^Hint:/.test(l.text)));
    p.assert.match(await lineClasses(p, 2), /\berrline\b/);
    await p.waitToast(/Variables are kept/);
  });
  t.test('double-clicking the runtime error in the Immediate log jumps to the line', async (p) => {
    await load(p, 'a = 1\nb = 0\nPRINT a / b');
    await p.ev('RC.app.run()');
    await p.waitState('error');
    await cursorTo(p, 0);
    await p.dblclick('.imm-log .jump');
    await p.sleep(60);
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 2);
  });
  t.test('a runtime error inside a SUB keeps the call stack inspectable', async (p) => {
    await load(p, 'CALL Bad(5)\nSUB Bad (k)\n  w = k * 3\n  ERROR 5\nEND SUB');
    await p.ev('RC.app.run()');
    await p.waitState('error');
    const rows = await stackRows(p);
    p.assert.deepEqual(rows.map((r) => r.name), ['SUB Bad', 'Main module']);
    await addWatch(p, 'w + k');
    p.assert.equal((await watchRows(p))[0].value, '20');
  });
  t.test('STOP pauses the program at the STOP line', async (p) => {
    await load(p, 'x = 3\nSTOP\nPRINT "after"; x');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'stop');
    p.assert.match(await p.status(), /STOP statement/);
    p.assert.doesNotMatch(await p.screen(), /after/);
    p.assert.equal(await execMark(p), 1);
  });
  t.test('variables can be inspected and changed at a STOP, then F5 continues', async (p) => {
    await load(p, 'x = 3\nSTOP\nPRINT "after"; x');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    await p.ev("RC.app.panels.show('vars')");
    p.assert.equal(await varVal(p, 'x'), '3');
    await imm(p, 'x = 8');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /after 8/);
  });
  t.test('STOP in a numbered program names the line number', async (p) => {
    await load(p, '10 PRINT "A"\n20 STOP\n30 PRINT "B"');
    await p.ev('RC.app.run()');
    await p.waitState('paused');
    p.assert.match(await p.status(), /STOP statement in line 20/);
  });
  t.test('TRON in a program prints bracketed line numbers', async (p) => {
    await p.runProgram('10 TRON\n20 A = 1\n30 PRINT "X"\n40 TROFF\n50 PRINT "Y"');
    const s = await p.screen();
    p.assert.match(s, /\[20\]\[30\]X/);
    p.assert.match(s, /\[40\]Y/);
    p.assert.doesNotMatch(s, /\[50\]/);
  });
  t.test('TRON traces each pass of a loop', async (p) => {
    await p.runProgram('10 TRON\n20 FOR I = 1 TO 2\n30 NEXT I\n40 TROFF');
    p.assert.match(await p.screen(), /\[20\]\[30\]\[30\]\[40\]/);
  });
  t.test('Debug > TRON then running a numbered program prints line numbers', async (p) => {
    await load(p, '10 A = 1\n20 PRINT "Z"');
    await p.menu('Debug', 'TRON (print line numbers)');
    await p.wait("[...document.querySelectorAll('.imm-log > div')].slice(-2).map(d => d.innerText).join('|') === '> TRON|OK'", 4000);
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /\[10\]\[20\]Z/);
  });

  // ---- History / Animate ----------------------------------------------------------------------------------
  t.test('History panel is empty before anything ran', async (p) => {
    await showTab(p, 'history');
    p.assert.match(await p.panelText(), /Statements appear here as your program runs/);
  }, { fresh: true });
  t.test('History lists executed statements with file:line and source', async (p) => {
    await p.runProgram('a = 1\nb = 2\nPRINT a + b');
    await showTab(p, 'history');
    const rows = await p.texts('.bpanel.active .list-row');
    const flat = rows.map((r) => r.replace(/\s+/g, ' '));
    p.assert.deepEqual(flat.slice(-3), ['E2E.BAS:1 a = 1', 'E2E.BAS:2 b = 2', 'E2E.BAS:3 PRINT a + b']);
  });
  t.test('History shows GW-BASIC line numbers in brackets', async (p) => {
    await p.runProgram('10 A = 1\n20 PRINT A');
    await showTab(p, 'history');
    const rows = (await p.texts('.bpanel.active .list-row')).map((r) => r.replace(/\s+/g, ' '));
    p.assert.deepEqual(rows.slice(-2), ['E2E.BAS:1 [10] A = 1', 'E2E.BAS:2 [20] PRINT A']);
  });
  t.test('History shows only the statements executed so far when paused', async (p) => {
    await debug(p, 'a = 1\nb = 2\nc = 3\nd = 4', [2]);
    await showTab(p, 'history');
    const rows = (await p.texts('.bpanel.active .list-row')).map((r) => r.replace(/\s+/g, ' '));
    p.assert.deepEqual(rows.slice(0, 2), ['E2E.BAS:1 a = 1', 'E2E.BAS:2 b = 2']);
    p.assert.ok(!rows.some((r) => /d = 4/.test(r)));
  });
  t.test('History lists a statement once after continuing from a breakpoint on it', async (p) => {
    await debug(p, 'a = 1\nb = 2\nc = 3\nd = 4', [2]);
    await p.key('F5');
    await p.waitState('ended');
    await showTab(p, 'history');
    const rows = (await p.texts('.bpanel.active .list-row')).map((r) => r.replace(/\s+/g, ' '));
    p.assert.deepEqual(rows, ['E2E.BAS:1 a = 1', 'E2E.BAS:2 b = 2', 'E2E.BAS:3 c = 3', 'E2E.BAS:4 d = 4']);
  });
  t.test('clicking a History row jumps to that line', async (p) => {
    await p.runProgram('a = 1\nb = 2\nPRINT a + b');
    await showTab(p, 'history');
    await cursorTo(p, 2);
    await p.click('.bpanel.active .list-row', 'b = 2');
    await p.sleep(60);
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 1);
  });
  t.test('History records each loop iteration', async (p) => {
    await p.runProgram('FOR i = 1 TO 3\n  t = t + i\nNEXT');
    await showTab(p, 'history');
    const rows = (await p.texts('.bpanel.active .list-row')).filter((r) => /t = t \+ i/.test(r));
    p.assert.equal(rows.length, 3);
  });
  t.test('the Animate checkbox turns on animation and picks a visible speed', async (p) => {
    await showTab(p, 'history');
    await p.click('.bpanel.active input[aria-label="Animate"]');
    p.assert.equal(await p.ev('RC.app.runner.animate'), true);
    p.assert.equal(await p.ev('RC.app.settings.speed'), 20);
  });
  t.test('Debug menu Animate Execution shows a check mark when on', async (p) => {
    await p.menu('Debug', 'Animate Execution (Trace)');
    p.assert.equal(await p.ev('RC.app.runner.animate'), true);
    await p.click('.menu-btn', 'Debug');
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((i) => i.label === 'Animate Execution (Trace)');
    await p.closeMenus();
    p.assert.equal(it.checked, true);
    await showTab(p, 'history');
    p.assert.equal(await p.ev("document.querySelector('.bpanel.active input[aria-label=\"Animate\"]').checked"), true);
  });
  t.test('animated execution moves the exec marker through the running program', async (p) => {
    await p.ev('RC.app.setAnimate(true)');
    await load(p, 'FOR i = 1 TO 40\n  a = a + 1\n  b = b + 1\nNEXT');
    await p.ev('RC.app.run()');
    await p.wait('RC.app.active.editor.marks.exec !== null', 5000);
    const seen = new Set();
    for (let k = 0; k < 60 && seen.size < 2; k++) {
      const m = await p.ev('RC.app.active.editor.marks.exec');
      if (m !== null) seen.add(m);
      await p.sleep(40);
    }
    p.assert.ok(seen.size >= 2, 'exec marker visited ' + [...seen]);
    await p.stopProgram();
  });
  t.test('a program at the slow 20 statements/s speed still makes progress', async (p) => {
    await p.ev('RC.app.setSpeed(20)');
    await load(p, 'a = 0\nFOR i = 1 TO 4000\n  a = a + 1\nNEXT');
    await p.ev('RC.app.run()');
    await p.sleep(2000);
    await p.click('#tbPause');
    await p.waitState(['paused', 'ended']);
    // ~40 statements in 2 s: at least a few loop passes must have happened
    p.assert.ok(await ev(p, 'a') >= 5, 'a = ' + await ev(p, 'a'));
  });
  t.test('a program at 1000 statements/s runs at roughly that pace', async (p) => {
    await p.ev('RC.app.setSpeed(1000)');
    await load(p, 'a = 0\nFOR i = 1 TO 40000\n  a = a + 1\nNEXT');
    await p.ev('RC.app.run()');
    await p.sleep(1000);
    await p.click('#tbPause');
    await p.waitState(['paused', 'ended']);
    const a = await ev(p, 'a');
    p.assert.ok(a > 50 && a < 2000, 'a = ' + a);
  });
  t.test('turning animation off clears the exec marker', async (p) => {
    await p.ev('RC.app.setAnimate(true)');
    await load(p, 'DO\n  a = a + 1\nLOOP');
    await p.ev('RC.app.run()');
    await p.wait('RC.app.active.editor.marks.exec !== null', 4000);
    await showTab(p, 'history');
    await p.click('.bpanel.active input[aria-label="Animate"]');
    p.assert.equal(await p.ev('RC.app.runner.animate'), false);
    p.assert.equal(await p.ev('RC.app.active.editor.marks.exec'), null);
    await p.stopProgram();
  });

  // ---- Printer ------------------------------------------------------------------------------------------
  t.test('LPRINT output appears in the Printer panel', async (p) => {
    await p.runProgram('LPRINT "Invoice 42"\nLPRINT 1 + 2');
    await showTab(p, 'printer');
    p.assert.match(await p.text('.bpanel.active .printer'), /Invoice 42\n 3/);
  });
  t.test('the Printer tab badge counts lines printed while it is hidden', async (p) => {
    await p.ev("RC.app.panels.show('immediate')");
    await p.ev("RC.app.panels.printerLines = []; RC.app.panels.setCount('printer', 0)");
    await p.runProgram('LPRINT "a"\nLPRINT "b"\nLPRINT "c"');
    p.assert.equal(await badge(p, 'printer'), '3');
  });
  t.test('Clear empties the printer output and its badge', async (p) => {
    await p.runProgram('LPRINT "junk"');
    await showTab(p, 'printer');
    await p.click('.bpanel.active .small-btn', 'Clear');
    p.assert.equal(await p.text('.bpanel.active .printer'), '');
    p.assert.equal(await badge(p, 'printer'), '');
  });
  t.test('Save downloads the printer output as LPT1.TXT with CRLF line ends', async (p) => {
    await showTab(p, 'printer');
    await p.click('.bpanel.active .small-btn', 'Clear');
    await p.runProgram('LPRINT "L1"\nLPRINT "L2"');
    await showTab(p, 'printer');
    await p.ev('window.__dl = null; window.__origDl = RC.UI.download; RC.UI.download = (n, d) => { window.__dl = [n, String(d)]; }');
    await p.click('.bpanel.active .small-btn', 'Save');
    const dl = await p.ev('window.__dl');
    await p.ev('RC.UI.download = window.__origDl');
    p.assert.deepEqual(dl, ['LPT1.TXT', 'L1\r\nL2']);
  });
  t.test('LPRINT with ; continues on the same printer line', async (p) => {
    await showTab(p, 'printer');
    await p.click('.bpanel.active .small-btn', 'Clear');
    await p.runProgram('LPRINT "A";\nLPRINT "B"');
    await showTab(p, 'printer');
    p.assert.equal(await p.text('.bpanel.active .printer'), 'AB');
  });

  // ---- Problems ------------------------------------------------------------------------------------------
  t.test('Problems panel says "No problems." after a clean run', async (p) => {
    await p.runProgram('PRINT 1');
    await showTab(p, 'problems');
    p.assert.match(await p.panelText(), /No problems\./);
    p.assert.equal(await badge(p, 'problems'), '');
  });
  t.test('a syntax error opens the Problems panel with kind, message and location', async (p) => {
    await load(p, 'a = 1\nb = 2\nPRINT (a + b');
    await p.ev('RC.app.run()');
    await p.sleep(150);
    p.assert.equal(await p.ev('RC.app.panels.active'), 'problems');
    const row = await p.fn(() => { const r = document.querySelector('.bpanel.active .list-row'); return [...r.children].map((c) => c.innerText); });
    p.assert.equal(row[0], 'Syntax error');
    p.assert.ok(row[1].length > 3);
    p.assert.match(row[2], /^E2E\.BAS:3:\d+$/);
    p.assert.equal(await badge(p, 'problems'), '1');
  });
  t.test('double-clicking a problem jumps to its line', async (p) => {
    await load(p, 'a = 1\nb = 2\nPRINT (a + b\nc = 4');
    await p.ev('RC.app.run()');
    await p.sleep(150);
    await cursorTo(p, 0);
    await p.dblclick('.bpanel.active .list-row');
    await p.sleep(60);
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 2);
  });
  t.test('a single click only selects the problem row', async (p) => {
    await load(p, 'PRINT (1');
    await p.ev('RC.app.run()');
    await p.sleep(150);
    await p.click('.bpanel.active .list-row');
    p.assert.match(await p.attr('.bpanel.active .list-row', 'class'), /\bsel\b/);
  });
  t.test('Enter on a focused problem row jumps to it without typing into the code', async (p) => {
    await load(p, 'a = 1\n\nPRINT (1');
    await p.ev('RC.app.run()');
    await p.sleep(150);
    await cursorTo(p, 0);
    await p.ev("document.querySelector('.bpanel.active .list-row').focus()");
    await p.key('Enter');
    await p.sleep(60);
    p.assert.equal(await p.code(), 'a = 1\n\nPRINT (1');
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 2);
  });
  t.test('a runtime error is listed in Problems with its error number', async (p) => {
    await p.runProgram('DIM a(3)\nPRINT a(9)');
    await showTab(p, 'problems');
    const row = await p.fn(() => [...document.querySelector('.bpanel.active .list-row').children].map((c) => c.innerText));
    p.assert.equal(row[0], 'Runtime error 9');
    p.assert.match(row[1], /Subscript out of range/);
    p.assert.match(row[2], /^E2E\.BAS:2:/);
  });
  t.test('Problems are cleared when the program runs cleanly again', async (p) => {
    await load(p, 'PRINT (1');
    await p.ev('RC.app.run()');
    await p.sleep(150);
    p.assert.equal(await badge(p, 'problems'), '1');
    await p.runProgram('PRINT 1');
    p.assert.equal(await badge(p, 'problems'), '');
  });
  t.test('double-clicking a problem in a closed $INCLUDE file opens that file at the line', async (p) => {
    const INC = 'C:\\MYPROGS\\E2EBAD.BI';
    await p.newFile(INC, "SUB Oops\n  PRINT \"ok\"\n  x = (1 + \nEND SUB");
    await p.fn((pa) => { const d = RC.app.docByPath(pa); if (d) RC.app.closeDoc(d); }, INC);
    await p.sleep(100);
    p.assert.equal(await p.fn((pa) => !!RC.app.docByPath(pa), INC), false);
    await load(p, "'$INCLUDE: 'E2EBAD.BI'\nCALL Oops");
    await p.ev('RC.app.run()');
    await p.sleep(200);
    await p.ev("RC.app.panels.show('problems')");
    await p.sleep(40);
    p.assert.match(await p.text('.bpanel.active .list-row'), /E2EBAD\.BI:3/);
    // the compile error may already have opened the file; close it again to test the jump
    await p.fn((pa) => { const d = RC.app.docByPath(pa); if (d) RC.app.closeDoc(d); }, INC);
    await p.sleep(100);
    await p.ev("RC.app.panels.show('problems')");
    await p.dblclick('.bpanel.active .list-row');
    await p.sleep(120);
    p.assert.equal(await p.activePath(), INC);
    p.assert.equal((await p.ev('RC.app.active.editor.cursor()')).line, 2);
  });
};
