// Debugger: editor hover callout (values while paused, sticky behaviour, editing, arrays/records, touch).
import { PATH, reset, load, lineOf, debug, charPoint, hoverWord, mark, varRows, varVal, stackRows } from './50-debug-helpers.mjs';

const C = '.ed-callout';
const ev = (p, e, fi) => p.fn((x, f) => { const vm = RC.app.runner.vm; return RC.Basic.Debug.evaluate(vm, x, f === null ? vm.frames.length - 1 : f).value; }, e, fi === undefined ? null : fi);
const open = () => `!!document.querySelector('${C}')`;
const calloutText = (p) => p.ev(`(document.querySelector('${C}') || {}).innerText || ''`);
const exprText = (p) => p.ev(`(document.querySelector('${C} .callout-expr') || {}).innerText || ''`);
const noteText = (p) => p.ev(`(document.querySelector('${C} .callout-note') || {}).innerText || ''`);

async function moveAway(p) {
  // a point in the explorer/toolbar area, outside the editor text and the callout
  const r = await p.rect('#toolbar');
  await p.mouse('mouseMoved', r.x + 5, r.bottom - 3);
}
async function moveIntoCallout(p) {
  const r = await p.rect(C);
  // walk from the word to the callout in small steps (the callout sits just under the word)
  const steps = 4;
  const [x0, y0] = [r.x + 10, r.y - 8];
  for (let i = 0; i <= steps; i++) await p.mouse('mouseMoved', x0, y0 + (i * (r.h / 2 + 8)) / steps);
  await p.sleep(30);
}
async function calloutEdit(p, name, text, key = 'Enter') {
  const sel = await mark(p, `() => [...document.querySelectorAll('${C} .vrow')].find(r => r.querySelector('.vn > span:not(.twisty):not(.vbadge)')?.innerText === ${JSON.stringify(name)})?.querySelector('.vv')`, 'cv');
  await p.click(sel);
  await p.wait(`!!document.querySelector('${C} .vv input')`, 2000);
  await p.fn((c, t) => { document.querySelector(c + ' .vv input').value = t; }, C, text);
  await p.key(key);
  await p.sleep(60);
}
async function calloutToggle(p, name) {
  const sel = await mark(p, `() => [...document.querySelectorAll('${C} .vrow')].find(r => r.querySelector('.vn > span:not(.twisty):not(.vbadge)')?.innerText === ${JSON.stringify(name)})?.querySelector('.twisty')`, 'ct');
  await p.click(sel);
  await p.sleep(40);
}

const PMAIN = [
  'CONST LIMIT = 10',        // 0
  'DIM a(5)',                // 1
  'FOR i = 0 TO 5: a(i) = i * 11: NEXT', // 2
  'i = 3',                   // 3
  'msg$ = "hello"',          // 4
  'total = 42',              // 5
  'PRINT a(i); msg$; total; LIMIT', // 6
].join('\n');

const PTYPES = [
  'TYPE Pt', '  x AS INTEGER', '  y AS INTEGER', 'END TYPE',
  'TYPE Person', '  nm AS STRING * 4', '  age AS INTEGER', '  home AS Pt', 'END TYPE',
  'DIM who AS Person',                // 9
  'who.nm = "Bo": who.age = 42',      // 10
  'who.home.x = 3: who.home.y = 4',   // 11
  'DIM big(299)',                     // 12
  'FOR k = 0 TO 299: big(k) = k: NEXT', // 13
  'PRINT who.age; big(5)',            // 14
].join('\n');

const PREC = 'CALL Down(3)\nSUB Down (n%)\n  IF n% > 0 THEN CALL Down(n% - 1)\n  PRINT "N"; n%\nEND SUB';

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); await p.mouse('mouseMoved', 1, 1); });

  // ---- when it appears ----------------------------------------------------------------------------------
  t.test('no callout when hovering a variable while no program is running', async (p) => {
    await load(p, PMAIN);
    await hoverWord(p, 5, 'total', { expectNone: true });
    p.assert.equal(await p.ev(open()), false);
  });
  t.test('no callout after the program has ended', async (p) => {
    await p.runProgram(PMAIN);
    await hoverWord(p, 5, 'total', { expectNone: true });
    p.assert.equal(await p.ev(open()), false);
  });
  t.test('no callout while the program is running', async (p) => {
    await load(p, 'DO\n  spin = spin + 1\nLOOP');
    await p.ev('RC.app.run()');
    await p.waitState('running');
    await p.ev('RC.app.active.editor.ta.blur()');
    await hoverWord(p, 1, 'spin', { expectNone: true });
    p.assert.equal(await p.ev(open()), false);
    await p.stopProgram();
  });
  t.test('hovering a variable while paused shows a callout with its name, type and value', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    const rows = await varRows(p, C);
    p.assert.equal(rows.length, 1);
    p.assert.deepEqual([rows[0].name, rows[0].type, rows[0].value], ['total', 'SINGLE', '42']);
    p.assert.equal(await p.attr(C, 'role'), 'dialog');
  });
  t.test('the callout appears near the mouse inside the window', async (p) => {
    await debug(p, PMAIN, [6]);
    const [x, y] = await hoverWord(p, 5, 'total');
    const r = await p.rect(C);
    p.assert.ok(r.y > y && r.y < y + 40, `callout top ${r.y} vs mouse ${y}`);
    p.assert.ok(r.x >= 8 && r.right <= 1400);
  });
  t.test('a string variable shows its quoted value', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 4, 'msg$');
    p.assert.equal((await varRows(p, C))[0].value, '"hello"');
  });
  t.test('hovering a keyword shows no callout', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 6, 'PRINT', { expectNone: true, offset: 2 });
    p.assert.equal(await p.ev(open()), false);
  });
  t.test('hovering a SUB name shows no callout and creates no variable', async (p) => {
    await debug(p, 'a = 5\nCALL Inc(a)\nPRINT a\nSUB Inc (v)\n  v = v + 1\nEND SUB', [1]);
    await hoverWord(p, 1, 'Inc', { expectNone: true, offset: 1 });
    p.assert.equal(await p.ev(open()), false);
    await p.ev("RC.app.panels.show('vars')");
    p.assert.deepEqual((await varRows(p)).map((r) => r.name), ['a']);
  });
  t.test('the callout works in the variable on the line being executed and elsewhere', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 6, 'total');
    p.assert.equal((await varRows(p, C))[0].value, '42');
  });

  // ---- sticky behaviour / closing ---------------------------------------------------------------------------
  t.test('moving the mouse from the word into the callout keeps it open', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    await p.sleep(900);
    p.assert.equal(await p.ev(open()), true);
  });
  t.test('moving the mouse away from the word closes the callout after a short delay', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    const [x, y] = await charPoint(p, 1, 0);
    await p.mouse('mouseMoved', x + 200, y + 400);
    await p.wait(`!document.querySelector('${C}')`, 2000);
  });
  t.test('leaving the callout closes it', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    await p.sleep(100);
    await moveAway(p);
    await p.wait(`!document.querySelector('${C}')`, 2000);
  });
  t.test('Escape closes the callout', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await p.key('Escape');
    p.assert.equal(await p.ev(open()), false);
    p.assert.equal(await p.state(), 'paused');
  });
  t.test('clicking outside the callout closes it', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    const r = await p.rect('#bottomTabs');
    await p.clickAt(r.x + r.w - 20, r.y + r.h / 2);
    p.assert.equal(await p.ev(open()), false);
  });
  t.test('clicking inside the callout does not close it', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    await p.click(C + ' .callout-note');
    await p.sleep(300);
    p.assert.equal(await p.ev(open()), true);
  });
  t.test('hovering another variable replaces the callout', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await hoverWord(p, 4, 'msg$');
    await p.wait(`(document.querySelector('${C} .vn > span:not(.twisty)') || {}).innerText === 'msg$'`, 3000);
    p.assert.equal(await p.count(C), 1);
    p.assert.equal((await varRows(p, C))[0].name, 'msg$');
  });
  t.test('continuing the program closes the callout', async (p) => {
    await debug(p, 'DO\n  w = w + 1\nLOOP UNTIL w > 3\nPRINT w', [1]);
    await hoverWord(p, 1, 'w');
    await p.ev('RC.app.continue()');
    await p.waitState(['paused', 'ended']);
    await p.wait(`!document.querySelector('${C}')`, 2000);
  });

  // ---- editing in the callout ---------------------------------------------------------------------------------
  t.test('the callout says a value can be clicked to change it', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    p.assert.equal(await noteText(p), 'Click a value to change it.');
    p.assert.equal((await varRows(p, C))[0].editable, true);
  });
  t.test('editing a value in the callout changes the variable', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    await calloutEdit(p, 'total', '7 * 6 + 1');
    p.assert.equal(await ev(p, 'total'), 43);
    p.assert.equal((await varRows(p, C))[0].value, '43');
    await p.waitToast(/Changed total/);
  });
  t.test('a callout edit also refreshes the Variables panel', async (p) => {
    await debug(p, PMAIN, [6]);
    await p.ev("RC.app.panels.show('vars')");
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    await calloutEdit(p, 'total', '100');
    p.assert.equal(await varVal(p, 'total'), '100');
  });
  t.test('the program continues with a value edited in the callout', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 4, 'msg$');
    await moveIntoCallout(p);
    await calloutEdit(p, 'msg$', '"bye"');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /33 bye 42 +10/);
  });
  t.test('the callout stays open while its value editor has focus', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    const sel = await mark(p, `() => document.querySelector('${C} .vv')`, 'cv');
    await p.click(sel);
    await moveAway(p);
    await p.sleep(900);
    p.assert.equal(await p.ev(open()), true);
    p.assert.equal(await p.count(C + ' .vv input'), 1);
  });
  t.test('Escape while editing in the callout cancels the change', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 5, 'total');
    await moveIntoCallout(p);
    await calloutEdit(p, 'total', '999', 'Escape');
    p.assert.equal(await ev(p, 'total'), 42);
  });
  t.test('an invalid value typed in the callout shows an error toast', async (p) => {
    await debug(p, 'n% = 1\nPRINT n%', [1]);
    await hoverWord(p, 0, 'n%');
    await moveIntoCallout(p);
    await calloutEdit(p, 'n%', '70000');
    await p.waitToast(/Could not set n%: Overflow/);
    p.assert.equal(await ev(p, 'n%'), 1);
  });
  t.test('constants in the callout are read-only', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 0, 'LIMIT');
    const r = (await varRows(p, C))[0];
    p.assert.equal(r.value, '10');
    p.assert.equal(r.editable, false);
    p.assert.deepEqual(r.badges, ['const']);
    p.assert.equal(await noteText(p), 'Constants cannot be changed.');
    const sel = await mark(p, `() => document.querySelector('${C} .vv')`, 'cv');
    await p.click(sel);
    p.assert.equal(await p.count(C + ' .vv input'), 0);
  });
  t.test('inside a SUB the callout notes that callers are edited from the Call Stack', async (p) => {
    await debug(p, PREC, [3]);
    await hoverWord(p, 3, 'n%');
    p.assert.match(await noteText(p), /current frame\)\. Callers' frames: Call Stack ▸ Variables/);
  });
  t.test('the callout always shows the current (top) frame even when a caller frame is selected', async (p) => {
    await debug(p, PREC, [3]);
    await stackRows(p);
    await p.click('.bpanel.active .frame-row', '#2');
    await hoverWord(p, 3, 'n%');
    p.assert.equal((await varRows(p, C))[0].value, '0');
  });
  t.test('editing in the callout changes only the top recursion frame', async (p) => {
    await debug(p, PREC, [3]);
    await hoverWord(p, 3, 'n%');
    await moveIntoCallout(p);
    await calloutEdit(p, 'n%', '9');
    p.assert.equal(await ev(p, 'n%', 4), 9);
    p.assert.equal(await ev(p, 'n%', 3), 1);
    p.assert.equal(await ev(p, 'n%', 1), 3);
  });
  t.test('after a runtime error the callout shows values but does not allow editing', async (p) => {
    await load(p, 'q = 7\nPRINT 1 / 0');
    await p.ev('RC.app.run()');
    await p.waitState('error');
    await hoverWord(p, 0, 'q');
    const r = (await varRows(p, C))[0];
    p.assert.equal(r.value, '7');
    p.assert.equal(r.editable, false);
  });

  // ---- arrays / records / expressions -----------------------------------------------------------------------
  t.test('hovering a(i) shows the evaluated element value', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 6, 'a(i)');
    p.assert.equal(await exprText(p), 'a(i) = 33');
  });
  t.test('hovering an array shows it unfolded with its elements', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 6, 'a(i)');
    const rows = await varRows(p, C);
    p.assert.equal(rows[0].name, 'a');
    p.assert.equal(rows[0].value, '(0 TO 5)');
    p.assert.equal(rows[0].twisty, '▾');
    p.assert.deepEqual(rows.slice(1).map((r) => r.name + '=' + r.value), ['(0)=0', '(1)=11', '(2)=22', '(3)=33', '(4)=44', '(5)=55']);
  });
  t.test('an array element can be edited in the callout', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 6, 'a(i)');
    await moveIntoCallout(p);
    await calloutEdit(p, '(3)', '-1');
    p.assert.equal(await ev(p, 'a(3)'), -1);
    p.assert.equal((await varRows(p, C)).find((r) => r.name === '(3)').value, '-1');
  });
  t.test('the array can be folded inside the callout', async (p) => {
    await debug(p, PMAIN, [6]);
    await hoverWord(p, 6, 'a(i)');
    await moveIntoCallout(p);
    await calloutToggle(p, 'a');
    p.assert.equal((await varRows(p, C)).length, 1);
  });
  t.test('a large array in the callout is paged', async (p) => {
    await debug(p, PTYPES, [14]);
    await hoverWord(p, 14, 'big');
    p.assert.match(await p.text(C + ' .vrow.pager'), /1–100 of 300/);
    await moveIntoCallout(p);
    await p.click(C + ' .vrow.pager button', 'next');
    await p.sleep(40);
    p.assert.match(await p.text(C + ' .vrow.pager'), /101–200 of 300/);
    p.assert.equal((await varRows(p, C)).find((r) => r.name === '(150)').value, '150');
  });
  t.test('hovering a record field expression shows the field value and the record unfolded', async (p) => {
    await debug(p, PTYPES, [14]);
    await hoverWord(p, 14, 'who');
    p.assert.equal(await exprText(p), 'who.age = 42');
    const rows = await varRows(p, C);
    p.assert.equal(rows[0].name, 'who');
    p.assert.equal(rows[0].twisty, '▾');
    p.assert.ok(rows.some((r) => r.name === '.nm' && r.value === '"Bo  "'));
    p.assert.ok(rows.some((r) => r.name === '.age' && r.value === '42'));
  });
  t.test('a nested record unfolds inside the callout', async (p) => {
    await debug(p, PTYPES, [14]);
    await hoverWord(p, 14, 'who');
    await moveIntoCallout(p);
    await calloutToggle(p, '.home');
    const rows = await varRows(p, C);
    p.assert.equal(rows.find((r) => r.name === '.x').value, '3');
    p.assert.equal(rows.find((r) => r.name === '.y').value, '4');
  });
  t.test('a record field can be edited in the callout', async (p) => {
    await debug(p, PTYPES, [14]);
    await hoverWord(p, 14, 'who');
    await moveIntoCallout(p);
    await calloutEdit(p, '.age', '50');
    p.assert.equal(await ev(p, 'who.age'), 50);
  });
  t.test('a numeric expression like a(i + 1) is evaluated', async (p) => {
    await debug(p, PMAIN.replace('PRINT a(i);', 'PRINT a(i + 1);'), [6]);
    await hoverWord(p, 6, 'a(i + 1)');
    p.assert.equal(await exprText(p), 'a(i + 1) = 44');
  });

  // ---- touch ---------------------------------------------------------------------------------------------------
  t.test('tapping a variable on a touch screen opens the callout', async (p) => {
    await debug(p, PMAIN, [6]);
    const col = await p.fn(() => RC.app.active.editor.getLine(5).indexOf('total'));
    const [x, y] = await charPoint(p, 5, col + 1);
    await p.b.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
    await p.b.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await p.wait(open(), 3000);
    p.assert.equal((await varRows(p, C))[0].name, 'total');
  }, { fresh: { touch: true } });
};
