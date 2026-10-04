// Debugger: Variables panel (sections, filter, editing, arrays, records, paging, changed highlight, frames).
import { PATH, reset, load, debug, pausedLine, cursorTo, mark, varRows, varVal, rowSel, editVar, toggleRow, vsecTitles, stackRows } from './50-debug-helpers.mjs';

const ev = (p, e, fi) => p.fn((x, f) => { const vm = RC.app.runner.vm; return RC.Basic.Debug.evaluate(vm, x, f === null ? vm.frames.length - 1 : f).value; }, e, fi === undefined ? null : fi);
const showVars = async (p) => { await p.click('#bottomTabs .tab[data-id=vars]'); await p.sleep(40); };
const step = async (p, k = 'F8', mods = {}) => { await p.key(k, mods); await p.waitState(['paused', 'ended', 'error']); await p.sleep(40); };

const PSUB = [
  'CONST LIMIT = 10',              // 0
  'CONST TITLE$ = "Demo"',         // 1
  'total = 5',                     // 2
  'name$ = "Ann"',                 // 3
  'CALL Work(3, "x")',             // 4
  'PRINT total',                   // 5
  'SUB Work (k, tag$)',            // 6
  '  CONST INNER = 7',             // 7
  '  DIM lc AS INTEGER',           // 8
  '  lc = k * 2',                  // 9
  '  PRINT lc; tag$',              // 10
  'END SUB',                       // 11
].join('\n');

const PTYPES = [
  'TYPE Pt',                        // 0
  '  x AS INTEGER',                 // 1
  '  y AS INTEGER',                 // 2
  'END TYPE',                       // 3
  'TYPE Person',                    // 4
  '  nm AS STRING * 6',             // 5
  '  age AS INTEGER',               // 6
  '  home AS Pt',                   // 7
  'END TYPE',                       // 8
  'DIM who AS Person',              // 9
  'DIM crowd(1 TO 3) AS Person',    // 10
  'who.nm = "Bob"',                 // 11
  'who.age = 42',                   // 12
  'who.home.x = 3: who.home.y = 4', // 13
  'crowd(2).nm = "Cy"',             // 14
  'DIM tp AS Pt: tp.y = 9: crowd(2).home = tp', // 15
  'PRINT who.age',                  // 16
].join('\n');

const PARR = [
  'DIM v(5) AS INTEGER',            // 0
  'DIM g(1 TO 2, 0 TO 3)',          // 1
  'DIM c(1, 1, 2) AS LONG',         // 2
  'DIM big(249)',                   // 3
  'DIM s$(2)',                      // 4
  'FOR i = 0 TO 5: v(i) = i * i: NEXT',  // 5
  'g(2, 3) = 7.5',                  // 6
  'c(1, 0, 2) = 99',                // 7
  'FOR i = 0 TO 249: big(i) = i + 1000: NEXT', // 8
  's$(1) = "mid"',                  // 9
  'PRINT "ready"',                  // 10
].join('\n');

const PFACT = ['DECLARE FUNCTION Fact# (n%)', 'PRINT Fact#(4)', 'FUNCTION Fact# (n%)', '  IF n% <= 1 THEN', '    Fact# = 1', '  ELSE', '    Fact# = n% * Fact#(n% - 1)', '  END IF', 'END FUNCTION'].join('\n');

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- empty states --------------------------------------------------------------------------------
  t.test('Variables panel explains how to use it before any run', async (p) => {
    await showVars(p);
    p.assert.match(await p.panelText(), /Run your program and pause it/);
    p.assert.equal(await p.count('.bpanel.active .vrow'), 0);
  }, { fresh: true });
  t.test('Variables panel says the program is running while it runs', async (p) => {
    await load(p, 'DO\n  x = x + 1\nLOOP');
    await showVars(p);
    await p.ev('RC.app.run()');
    await p.waitState('running');
    await p.ev('RC.app.panels.refresh()');
    p.assert.match(await p.panelText(), /Program is running\. Pause/);
    await p.stopProgram();
  });
  t.test('Pause button pauses a running loop and shows its variables', async (p) => {
    await load(p, 'DO\n  x = x + 1\nLOOP');
    await p.ev('RC.app.run()');
    await p.waitState('running');
    await p.sleep(100);
    await p.click('#tbPause');
    await p.waitState('paused');
    await showVars(p);
    p.assert.ok(+(await varVal(p, 'x')) > 0);
  });

  // ---- sections ------------------------------------------------------------------------------------
  t.test('main module shows Module-level and Constants sections with scope label', async (p) => {
    await debug(p, PSUB, [4]);
    await showVars(p);
    const titles = await vsecTitles(p);
    p.assert.equal(titles.length, 2);
    p.assert.match(titles[0], /module-level \(global\) \(2\)/i);
    p.assert.match(titles[1], /constants \(read-only\) \(2\)/i);
    p.assert.match(await p.text('.bpanel.active .bpanel-tools'), /Frame #0: Main module \(current\)/);
  });
  t.test('inside a SUB the Locals section comes first and is named after the SUB', async (p) => {
    await debug(p, PSUB, [10]);
    await showVars(p);
    const titles = await vsecTitles(p);
    p.assert.match(titles[0], /locals — sub work \(3\)/i);
    p.assert.match(titles[1], /module-level/i);
    p.assert.match(titles[2], /constants/i);
    p.assert.match(await p.text('.bpanel.active .bpanel-tools'), /Frame #1: SUB Work \(current\)/);
  });
  t.test('SUB parameters carry a "param" badge and show their values', async (p) => {
    await debug(p, PSUB, [10]);
    await showVars(p);
    const rows = await varRows(p);
    const k = rows.find((r) => r.name === 'k');
    const tag = rows.find((r) => r.name === 'tag$');
    p.assert.deepEqual(k.badges, ['param']);
    p.assert.equal(k.value, '3');
    p.assert.equal(tag.value, '"x"');
    p.assert.equal(tag.type, 'STRING');
    const loc = rows.find((r) => r.name === 'lc');
    p.assert.deepEqual(loc.badges, []);
    p.assert.equal(loc.type, 'INTEGER');
    p.assert.equal(loc.value, '6');
  });
  t.test('module globals are listed sorted with type and value', async (p) => {
    await debug(p, PSUB, [5]);
    await showVars(p);
    const rows = await varRows(p);
    const g = rows.filter((r) => r.name === 'name$' || r.name === 'total');
    p.assert.deepEqual(g.map((r) => [r.name, r.type, r.value]), [['name$', 'STRING', '"Ann"'], ['total', 'SINGLE', '5']]);
  });
  t.test('constants show a const badge, CONST type and are not editable', async (p) => {
    await debug(p, PSUB, [4]);
    await showVars(p);
    const rows = await varRows(p);
    const c = rows.find((r) => r.name === 'LIMIT');
    p.assert.deepEqual(c.badges, ['const']);
    p.assert.match(c.type, /^CONST /);
    p.assert.equal(c.value, '10');
    p.assert.equal(c.editable, false);
    const sel = await rowSel(p, 'LIMIT');
    await p.click(sel);
    p.assert.equal(await p.count('.bpanel.active .vv input'), 0);
    p.assert.equal(await p.attr(sel, 'title'), 'Read-only');
  });
  t.test('local CONST inside a SUB is listed with the constants', async (p) => {
    await debug(p, PSUB, [10]);
    await showVars(p);
    const names = (await varRows(p)).map((r) => r.name);
    p.assert.ok(names.includes('INNER'));
    p.assert.ok(names.includes('TITLE$'));
  });
  t.test('a section with no entries shows "none"', async (p) => {
    await debug(p, 'CALL Q\nSUB Q\n  PRINT "q"\nEND SUB', [2]);
    await showVars(p);
    p.assert.match(await p.panelText(), /Locals — SUB Q \(0\)\s*none/i);
  });
  t.test('module-level variables can be inspected from inside a SUB (SHARED)', async (p) => {
    await debug(p, 'DIM SHARED cnt\ncnt = 4\nCALL Q\nSUB Q\n  cnt = cnt + 1\nEND SUB', [4]);
    await showVars(p);
    p.assert.equal(await varVal(p, 'cnt'), '4');
  });

  // ---- filter -----------------------------------------------------------------------------------------
  t.test('the filter box narrows the list by name (case-insensitive)', async (p) => {
    await debug(p, 'alpha = 1\nbeta = 2\nalps = 3\nPRINT 0', [3]);
    await showVars(p);
    await p.click('.bpanel.active input[aria-label="Filter variables"]');
    await p.type('AL');
    const names = (await varRows(p)).map((r) => r.name);
    p.assert.deepEqual(names, ['alpha', 'alps']);
  });
  t.test('clearing the filter shows every variable again', async (p) => {
    await debug(p, 'alpha = 1\nbeta = 2\nalps = 3\nPRINT 0', [3]);
    await showVars(p);
    await p.click('.bpanel.active input[aria-label="Filter variables"]');
    await p.type('beta');
    p.assert.deepEqual((await varRows(p)).map((r) => r.name), ['beta']);
    await p.key('Backspace'); await p.key('Backspace'); await p.key('Backspace'); await p.key('Backspace');
    p.assert.deepEqual((await varRows(p)).map((r) => r.name), ['alpha', 'alps', 'beta']);
  });
  t.test('filter with no match shows section counts of zero', async (p) => {
    await debug(p, 'alpha = 1\nPRINT 0', [1]);
    await showVars(p);
    await p.click('.bpanel.active input[aria-label="Filter variables"]');
    await p.type('zzz');
    p.assert.equal(await p.count('.bpanel.active .vrow'), 0);
    p.assert.match((await vsecTitles(p))[0], /\(0\)/);
  });
  t.test('typing in the filter box does not trigger debugger shortcuts', async (p) => {
    await debug(p, 'alpha = 1\nPRINT 0', [1]);
    await showVars(p);
    await p.click('.bpanel.active input[aria-label="Filter variables"]');
    await p.type('a');
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await p.ev("document.querySelector('.bpanel.active input[aria-label=\"Filter variables\"]').value"), 'a');
  });

  // ---- editing values -----------------------------------------------------------------------------------
  t.test('clicking a value opens an inline editor with the current value selected', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    const sel = await rowSel(p, 'x');
    await p.click(sel);
    p.assert.equal(await p.ev("document.querySelector('.bpanel.active .vv input').value"), '12');
    p.assert.equal(await p.ev("document.activeElement === document.querySelector('.bpanel.active .vv input')"), true);
    p.assert.equal(await p.ev("(() => { const i = document.querySelector('.bpanel.active .vv input'); return i.selectionStart === 0 && i.selectionEnd === 2; })()"), true);
    await p.key('Escape');
  });
  t.test('Enter commits a new numeric value and the program uses it', async (p) => {
    await debug(p, 'x = 12\nPRINT "X="; x', [1]);
    await showVars(p);
    await editVar(p, 'x', '99');
    p.assert.equal(await ev(p, 'x'), 99);
    p.assert.equal(await varVal(p, 'x'), '99');
    await p.waitToast(/Changed x/);
    await step(p, 'F5');
    p.assert.match(await p.screen(), /X= 99/);
  });
  t.test('Escape cancels the edit and keeps the old value', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    await editVar(p, 'x', '55', { key: 'Escape' });
    p.assert.equal(await ev(p, 'x'), 12);
    p.assert.equal(await varVal(p, 'x'), '12');
    p.assert.equal(await p.count('.bpanel.active .vv input'), 0);
  });
  t.test('Escape in the value editor does not stop or resume the program', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    await editVar(p, 'x', '55', { key: 'Escape' });
    p.assert.equal(await p.state(), 'paused');
  });
  t.test('an expression can be typed as the new value', async (p) => {
    await debug(p, 'x = 12\ny = 3\nPRINT x', [2]);
    await showVars(p);
    await editVar(p, 'x', 'y * 7 + 1');
    p.assert.equal(await ev(p, 'x'), 22);
  });
  t.test('a string variable accepts a quoted string', async (p) => {
    await debug(p, 'n$ = "abc"\nPRINT n$', [1]);
    await showVars(p);
    const sel = await rowSel(p, 'n$');
    await p.click(sel);
    p.assert.equal(await p.ev("document.querySelector('.bpanel.active .vv input').value"), '"abc"');
    await p.fn(() => { document.querySelector('.bpanel.active .vv input').value = '"Hello there"'; });
    await p.key('Enter');
    await p.sleep(50);
    p.assert.equal(await ev(p, 'n$'), 'Hello there');
    p.assert.equal(await varVal(p, 'n$'), '"Hello there"');
  });
  t.test('a string variable accepts plain unquoted text', async (p) => {
    await debug(p, 'n$ = "abc"\nPRINT n$', [1]);
    await showVars(p);
    await editVar(p, 'n$', 'plain words');
    p.assert.equal(await ev(p, 'n$'), 'plain words');
  });
  t.test('typing text into a numeric variable shows a type error toast and keeps the value', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    await editVar(p, 'x', '"oops"');
    await p.waitToast(/Could not set x: Type mismatch/);
    p.assert.equal(await ev(p, 'x'), 12);
  });
  t.test('a syntax error in the new value shows an error toast', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    await editVar(p, 'x', '3 +* 4');
    await p.waitToast(/Could not set x/);
    p.assert.equal(await ev(p, 'x'), 12);
  });
  t.test('INTEGER overflow is rejected with an Overflow toast', async (p) => {
    await debug(p, 'n% = 5\nPRINT n%', [1]);
    await showVars(p);
    await editVar(p, 'n%', '40000');
    await p.waitToast(/Could not set n%: Overflow/);
    p.assert.equal(await ev(p, 'n%'), 5);
  });
  t.test('INTEGER accepts the boundary value 32767 and -32768', async (p) => {
    await debug(p, 'n% = 5\nPRINT n%', [1]);
    await showVars(p);
    await editVar(p, 'n%', '32767');
    p.assert.equal(await ev(p, 'n%'), 32767);
    await editVar(p, 'n%', '-32768');
    p.assert.equal(await ev(p, 'n%'), -32768);
  });
  t.test('INTEGER rounds a fractional value like QBasic', async (p) => {
    await debug(p, 'n% = 5\nPRINT n%', [1]);
    await showVars(p);
    await editVar(p, 'n%', '2.6');
    p.assert.equal(await ev(p, 'n%'), 3);
  });
  t.test('LONG overflow is rejected', async (p) => {
    await debug(p, 'n& = 5\nPRINT n&', [1]);
    await showVars(p);
    await editVar(p, 'n&', '3000000000');
    await p.waitToast(/Overflow/);
    p.assert.equal(await ev(p, 'n&'), 5);
  });
  t.test('a fixed-length string is padded with spaces to its length', async (p) => {
    await debug(p, 'DIM f AS STRING * 5\nf = "ABCDE"\nPRINT "["; f; "]"', [2]);
    await showVars(p);
    await editVar(p, 'f', '"AB"');
    p.assert.equal(await ev(p, 'f'), 'AB   ');
    p.assert.equal(await varVal(p, 'f'), '"AB   "');
    await step(p, 'F5');
    p.assert.match(await p.screen(), /\[AB {3}\]/);
  });
  t.test('a fixed-length string is truncated to its length', async (p) => {
    await debug(p, 'DIM f AS STRING * 3\nf = "A"\nPRINT f', [2]);
    await showVars(p);
    await editVar(p, 'f', '"WXYZ"');
    p.assert.equal(await ev(p, 'f'), 'WXY');
  });
  t.test('clicking away (blur) commits the edit', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    const sel = await rowSel(p, 'x');
    await p.click(sel);
    await p.fn(() => { document.querySelector('.bpanel.active .vv input').value = '41'; });
    await p.click('.bpanel.active .vsec');
    await p.sleep(60);
    p.assert.equal(await ev(p, 'x'), 41);
  });
  t.test('pressing Enter on a focused value cell starts editing (keyboard access)', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    const sel = await rowSel(p, 'x');
    await p.ev(`document.querySelector('${sel}').focus()`);
    await p.key('Enter');
    p.assert.equal(await p.count('.bpanel.active .vv input'), 1);
    await p.key('Escape');
  });
  t.test('editable values have the editable style and a "Click to change" tooltip', async (p) => {
    await debug(p, 'x = 12\nPRINT x', [1]);
    await showVars(p);
    const sel = await rowSel(p, 'x');
    p.assert.equal(await p.attr(sel, 'title'), 'Click to change');
    p.assert.equal((await varRows(p)).find((r) => r.name === 'x').editable, true);
  });
  t.test('editing a SUB local changes it in the running SUB', async (p) => {
    await debug(p, PSUB, [10]);
    await showVars(p);
    await editVar(p, 'lc', '123');
    await step(p, 'F8');
    p.assert.match(await p.screen(), /123 x/);
  });
  t.test('editing a BYREF parameter changes the caller variable too', async (p) => {
    await debug(p, 'a = 1\nCALL Inc(a)\nPRINT "A="; a\nSUB Inc (v)\n  v = v + 1\nEND SUB', [4]);
    await showVars(p);
    await editVar(p, 'v', '50');
    await step(p, 'F5');
    p.assert.match(await p.screen(), /A= 51/);
  });

  // ---- recursion frames ---------------------------------------------------------------------------------
  t.test('editing n% in an OUTER recursive frame changes only that frame', async (p) => {
    await debug(p, PFACT, [4]);
    await stackRows(p);
    await p.click('.bpanel.active .frame-row', '#2');
    await showVars(p);
    p.assert.match(await p.text('.bpanel.active .bpanel-tools'), /caller — editable here/);
    await editVar(p, 'n%', '10');
    p.assert.equal(await ev(p, 'n%', 2), 10);
    p.assert.equal(await ev(p, 'n%', 4), 1);
    p.assert.equal(await ev(p, 'n%', 3), 2);
    p.assert.equal(await ev(p, 'n%', 1), 4);
  });
  t.test('a value edited in an outer recursive frame is used when that frame resumes', async (p) => {
    await debug(p, 'CALL Down(3)\nSUB Down (n%)\n  IF n% > 0 THEN CALL Down(n% - 1)\n  PRINT "N"; n%\nEND SUB', [3]);
    await stackRows(p);
    await p.click('.bpanel.active .frame-row', '#2');
    await showVars(p);
    p.assert.equal(await varVal(p, 'n%'), '2');
    await editVar(p, 'n%', '20');
    await p.ev('RC.app.clearBreakpoints()');
    await step(p, 'F5');
    p.assert.match(await p.screen(), /N 0\s*\nN 1\s*\nN 20\s*\nN 3/);
  });
  t.test('the Variables panel stays on the selected outer frame after an edit', async (p) => {
    await debug(p, PFACT, [4]);
    await stackRows(p);
    await p.click('.bpanel.active .frame-row', '#3');
    await showVars(p);
    await editVar(p, 'n%', '8');
    p.assert.match(await p.text('.bpanel.active .bpanel-tools'), /Frame #3/);
    p.assert.equal(await varVal(p, 'n%'), '8');
  });

  // ---- changed highlight -----------------------------------------------------------------------------------
  t.test('a value that changed since the last pause is highlighted', async (p) => {
    await debug(p, 'a = 1\nb = 2\na = 5\nPRINT a', [2]);
    await showVars(p);
    await step(p, 'F8');
    const rows = await varRows(p);
    p.assert.equal(rows.find((r) => r.name === 'a').changed, true);
    p.assert.equal(rows.find((r) => r.name === 'b').changed, false);
  });
  t.test('the change highlight goes away after a step that does not change it', async (p) => {
    await debug(p, 'a = 1\nb = 2\na = 5\nc = 3\nPRINT a', [2]);
    await showVars(p);
    await step(p, 'F8');
    await step(p, 'F8');
    const rows = await varRows(p);
    p.assert.equal(rows.find((r) => r.name === 'a').changed, false);
    p.assert.equal(rows.find((r) => r.name === 'c').changed, true);
  });
  t.test('values update on every step', async (p) => {
    await debug(p, 'FOR i = 1 TO 3\n  t = t + i\nNEXT', [1]);
    await showVars(p);
    const seen = [];
    for (let k = 0; k < 3; k++) { seen.push(await varVal(p, 't')); await step(p, 'F5'); }
    p.assert.deepEqual(seen, ['0', '1', '3']);
  });

  // ---- arrays -------------------------------------------------------------------------------------------------
  t.test('an array shows its bounds and a fold arrow', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    const rows = await varRows(p);
    const v = rows.find((r) => r.name === 'v');
    p.assert.equal(v.value, '(0 TO 5)');
    p.assert.equal(v.type, 'INTEGER()');
    p.assert.equal(v.twisty, '▸');
    p.assert.equal(rows.find((r) => r.name === 'g').value, '(1 TO 2, 0 TO 3)');
    p.assert.equal(rows.find((r) => r.name === 'c').value, '(0 TO 1, 0 TO 1, 0 TO 2)');
  });
  t.test('an array row value is not editable (only its elements are)', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    p.assert.equal((await varRows(p)).find((r) => r.name === 'v').editable, false);
  });
  t.test('clicking an array row and entering a number does not replace the array', async (p) => {
    await debug(p, 'DIM v(5) AS INTEGER\nv(1) = 3\nPRINT "V1="; v(1)', [2]);
    await showVars(p);
    const sel = await rowSel(p, 'v');
    await p.click(sel);
    if (await p.count('.bpanel.active .vv input')) {
      await p.fn(() => { document.querySelector('.bpanel.active .vv input').value = '5'; });
      await p.key('Enter');
      await p.sleep(60);
    }
    p.assert.equal((await varRows(p)).find((r) => r.name === 'v').value, '(0 TO 5)');
    await step(p, 'F5');
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /V1= 3/);
  }, { allowExceptions: true });
  t.test('expanding a 1-D array lists every element with its value', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'v');
    const rows = await varRows(p);
    const els = rows.filter((r) => /^\(\d\)$/.test(r.name));
    p.assert.deepEqual(els.map((r) => r.name + '=' + r.value), ['(0)=0', '(1)=1', '(2)=4', '(3)=9', '(4)=16', '(5)=25']);
    p.assert.equal(rows.find((r) => r.name === 'v').twisty, '▾');
  });
  t.test('collapsing an array hides its elements again', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'v');
    await toggleRow(p, 'v');
    p.assert.equal((await varRows(p)).filter((r) => /^\(\d\)$/.test(r.name)).length, 0);
  });
  t.test('double-clicking an array name toggles it open', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    const sel = await rowSel(p, 'v', '.vn');
    await p.dblclick(sel);
    p.assert.ok((await varRows(p)).some((r) => r.name === '(5)'));
  });
  t.test('a 2-D array folds one dimension at a time', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'g');
    let rows = await varRows(p);
    const groups = rows.filter((r) => r.name.startsWith('(') && r.name.includes('…'));
    p.assert.deepEqual(groups.map((r) => r.name), ['(1, …)', '(2, …)']);
    p.assert.match(groups[0].type, /SINGLE row/);
    p.assert.equal(groups[0].value, '');
    await toggleRow(p, '(2, …)');
    rows = await varRows(p);
    const cells = rows.filter((r) => /^\(2, \d\)$/.test(r.name));
    p.assert.deepEqual(cells.map((r) => r.name + '=' + r.value), ['(2, 0)=0', '(2, 1)=0', '(2, 2)=0', '(2, 3)=7.5']);
  });
  t.test('a 3-D array folds through three levels down to a value', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'c');
    await toggleRow(p, '(1, …, …)');
    let rows = await varRows(p);
    p.assert.deepEqual(rows.filter((r) => /^\(1, \d, …\)$/.test(r.name)).map((r) => r.name), ['(1, 0, …)', '(1, 1, …)']);
    await toggleRow(p, '(1, 0, …)');
    rows = await varRows(p);
    p.assert.deepEqual(rows.filter((r) => /^\(1, 0, \d\)$/.test(r.name)).map((r) => r.name + '=' + r.value), ['(1, 0, 0)=0', '(1, 0, 1)=0', '(1, 0, 2)=99']);
  });
  t.test('a large array is paged 100 elements at a time with prev/next', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'big');
    let rows = await varRows(p);
    let els = rows.filter((r) => /^\(\d+\)$/.test(r.name));
    p.assert.equal(els.length, 100);
    p.assert.equal(els[0].name + '=' + els[0].value, '(0)=1000');
    p.assert.match(await p.text('.bpanel.active .vrow.pager'), /1–100 of 250/);
    p.assert.equal(await p.ev("[...document.querySelectorAll('.bpanel.active .vrow.pager button')].map(b => b.disabled).join()"), 'true,false');
    await p.click('.bpanel.active .vrow.pager button', 'next');
    await p.sleep(40);
    els = (await varRows(p)).filter((r) => /^\(\d+\)$/.test(r.name));
    p.assert.equal(els[0].name + '=' + els[0].value, '(100)=1100');
    p.assert.match(await p.text('.bpanel.active .vrow.pager'), /101–200 of 250/);
    await p.click('.bpanel.active .vrow.pager button', 'next');
    await p.sleep(40);
    els = (await varRows(p)).filter((r) => /^\(\d+\)$/.test(r.name));
    p.assert.equal(els.length, 50);
    p.assert.equal(els[49].name + '=' + els[49].value, '(249)=1249');
    p.assert.match(await p.text('.bpanel.active .vrow.pager'), /201–250 of 250/);
    p.assert.equal(await p.ev("[...document.querySelectorAll('.bpanel.active .vrow.pager button')].map(b => b.disabled).join()"), 'false,true');
    await p.click('.bpanel.active .vrow.pager button', 'prev');
    await p.sleep(40);
    p.assert.match(await p.text('.bpanel.active .vrow.pager'), /101–200 of 250/);
  });
  t.test('a small array has no pager', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'v');
    p.assert.equal(await p.count('.bpanel.active .vrow.pager'), 0);
  });
  t.test('expanded arrays stay expanded after the next step', async (p) => {
    await debug(p, PARR, [9]);
    await showVars(p);
    await toggleRow(p, 's$');
    await step(p, 'F8');
    const rows = await varRows(p);
    p.assert.equal(rows.find((r) => r.name === '(1)').value, '"mid"');
    p.assert.equal(rows.find((r) => r.name === '(1)').changed, true);
  });
  t.test('editing an array element by click changes the element', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'v');
    await editVar(p, '(3)', '-7');
    p.assert.equal(await ev(p, 'v(3)'), -7);
    p.assert.equal(await varVal(p, '(3)'), '-7');
  });
  t.test('editing an INTEGER array element rejects overflow', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'v');
    await editVar(p, '(2)', '99999');
    await p.waitToast(/Overflow/);
    p.assert.equal(await ev(p, 'v(2)'), 4);
  });
  t.test('editing a string array element', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 's$');
    await editVar(p, '(2)', '"end"');
    p.assert.equal(await ev(p, 's$(2)'), 'end');
  });
  t.test('editing a 2-D array cell', async (p) => {
    await debug(p, PARR, [10]);
    await showVars(p);
    await toggleRow(p, 'g');
    await toggleRow(p, '(1, …)');
    await editVar(p, '(1, 2)', '3.25');
    p.assert.equal(await ev(p, 'g(1, 2)'), 3.25);
  });
  t.test('a dynamic array that is not dimensioned yet is shown as such and cannot unfold', async (p) => {
    await debug(p, "' $DYNAMIC\nDIM d(0)\nERASE d\nPRINT 1\nREDIM d(3)\nPRINT 2", [3]);
    await showVars(p);
    const r = (await varRows(p)).find((x) => x.name === 'd');
    p.assert.ok(r);
    p.assert.match(r.value, /not dimensioned|erased/);
  });

  // ---- records ------------------------------------------------------------------------------------------------
  t.test('a record variable shows its fields inline and a fold arrow', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    const r = (await varRows(p)).find((x) => x.name === 'who');
    p.assert.equal(r.type, 'Person');
    p.assert.equal(r.twisty, '▸');
    p.assert.match(r.value, /nm: "Bob {3}", age: 42, home: \{x: 3, y: 4\}/);
    p.assert.equal(r.editable, false);
  });
  t.test('expanding a record lists its fields', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    await toggleRow(p, 'who');
    const rows = await varRows(p);
    p.assert.equal(rows.find((r) => r.name === '.nm').value, '"Bob   "');
    p.assert.equal(rows.find((r) => r.name === '.age').value, '42');
    p.assert.equal(rows.find((r) => r.name === '.home').twisty, '▸');
  });
  t.test('a nested record drills down to its fields', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    await toggleRow(p, 'who');
    await toggleRow(p, '.home');
    const rows = await varRows(p);
    p.assert.equal(rows.find((r) => r.name === '.x').value, '3');
    p.assert.equal(rows.find((r) => r.name === '.y').value, '4');
    p.assert.equal(rows.find((r) => r.name === '.y').type, 'INTEGER');
  });
  t.test('editing a record field changes the field', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    await toggleRow(p, 'who');
    await editVar(p, '.age', '43');
    p.assert.equal(await ev(p, 'who.age'), 43);
    await step(p, 'F5');
    p.assert.match(await p.screen(), /43/);
  });
  t.test('editing a fixed-length string field pads it', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    await toggleRow(p, 'who');
    await editVar(p, '.nm', '"Al"');
    p.assert.equal(await ev(p, 'who.nm'), 'Al    ');
  });
  t.test('editing a nested record field', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    await toggleRow(p, 'who');
    await toggleRow(p, '.home');
    await editVar(p, '.x', '-2');
    p.assert.equal(await ev(p, 'who.home.x'), -2);
  });
  t.test('an array of records unfolds to records that unfold to fields', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    const top = (await varRows(p)).find((r) => r.name === 'crowd');
    p.assert.equal(top.value, '(1 TO 3)');
    p.assert.equal(top.type, 'Person()');
    await toggleRow(p, 'crowd');
    const rows = await varRows(p);
    const el = rows.find((r) => r.name === '(2)');
    p.assert.equal(el.twisty, '▸');
    p.assert.match(el.value, /nm: "Cy {4}"/);
    await toggleRow(p, '(2)');
    await toggleRow(p, '.home', '.bpanel.active', 0);
    const r2 = await varRows(p);
    p.assert.equal(r2.find((r) => r.name === '.nm').value, '"Cy    "');
    p.assert.equal(r2.find((r) => r.name === '.y').value, '9');
  });
  t.test('editing a field of a record inside an array', async (p) => {
    await debug(p, PTYPES, [16]);
    await showVars(p);
    await toggleRow(p, 'crowd');
    await toggleRow(p, '(3)');
    await editVar(p, '.age', '7');
    p.assert.equal(await ev(p, 'crowd(3).age'), 7);
    p.assert.equal(await ev(p, 'crowd(2).age'), 0);
  });

  // ---- variables after errors / end --------------------------------------------------------------------------
  t.test('after a runtime error the variables are still inspectable', async (p) => {
    await load(p, 'q = 41\nr = q + 1\nPRINT 1 / 0\nPRINT "never"');
    await p.ev('RC.app.run()');
    await p.waitState('error');
    await showVars(p);
    p.assert.equal(await varVal(p, 'q'), '41');
    p.assert.equal(await varVal(p, 'r'), '42');
  });
  t.test('after a runtime error inside a SUB the SUB locals are inspectable', async (p) => {
    await load(p, 'CALL Bad(5)\nSUB Bad (k)\n  w = k * 3\n  ERROR 5\nEND SUB');
    await p.ev('RC.app.run()');
    await p.waitState('error');
    await showVars(p);
    p.assert.match((await vsecTitles(p))[0], /locals — sub bad/i);
    p.assert.equal(await varVal(p, 'w'), '15');
    p.assert.equal(await varVal(p, 'k'), '5');
  });
  t.test('after the program ends the final values remain visible', async (p) => {
    await load(p, 'fin = 77\nPRINT fin');
    await p.ev('RC.app.run()');
    await p.waitState('ended');
    await showVars(p);
    p.assert.equal(await varVal(p, 'fin'), '77');
  });
};
