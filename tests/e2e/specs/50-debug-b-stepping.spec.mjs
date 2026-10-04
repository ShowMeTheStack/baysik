// Debugger: stepping (into/over/out), Run to Cursor, Set Next Statement, exec marker, Call Stack panel.
import { PATH, reset, load, lineOf, debug, pausedLine, execMark, gutterIndex, gutterClasses, lineClasses, cursorTo, mark, varRows, varVal, stackRows } from './50-debug-helpers.mjs';

const PSTEP = [
  'a = 1',               // 0
  'CALL Inc(a)',         // 1
  'b = Twice(a)',        // 2
  'PRINT a; b',          // 3
  'END',                 // 4
  'SUB Inc (v)',         // 5
  '  v = v + 1',         // 6
  'END SUB',             // 7
  'FUNCTION Twice (n)',  // 8
  '  Twice = n * 2',     // 9
  'END FUNCTION',        // 10
].join('\n');

const PFACT = [
  'DECLARE FUNCTION Fact# (n%)',      // 0
  'PRINT Fact#(4)',                   // 1
  'FUNCTION Fact# (n%)',              // 2
  '  IF n% <= 1 THEN',                // 3
  '    Fact# = 1',                    // 4
  '  ELSE',                           // 5
  '    Fact# = n% * Fact#(n% - 1)',   // 6
  '  END IF',                         // 7
  'END FUNCTION',                     // 8
].join('\n');

const P1 = ['x = 1', 'y = 2', 'z = x + y', 'PRINT "Z="; z', 'FOR i = 1 TO 5', '  s = s + i', 'NEXT i', 'PRINT "S="; s'].join('\n');

const PGOSUB = ['x = 1', 'GOSUB Sub1', 'PRINT "back"; x', 'END', 'Sub1:', '  x = x + 1', '  GOSUB Sub2', '  RETURN', 'Sub2:', '  x = x * 10', '  RETURN'].join('\n');

const ev = (p, e) => p.fn((x) => RC.Basic.Debug.evaluate(RC.app.runner.vm, x, RC.app.runner.vm.frames.length - 1).value, e);
const depth = (p) => p.ev('RC.app.runner.vm.frames.length');

async function stepTo(p, key, mods = {}) {
  await p.key(key, mods);
  await p.waitState(['paused', 'ended', 'error', 'waiting']);
  await p.sleep(30);
}
async function selectFrame(p, depthLabel) {
  await stackRows(p);
  await p.click('.bpanel.active .frame-row', depthLabel);
  await p.sleep(60);
}

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- starting with a step --------------------------------------------------------------------------
  t.test('F8 when idle starts the program paused on the first statement', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await pausedLine(p), 0);
    p.assert.equal(await ev(p, 'a'), 0);
  });
  t.test('toolbar Step button when idle starts paused on the first statement', async (p) => {
    await load(p, PSTEP);
    await p.click('#tbInto');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 0);
  });
  t.test('Debug > Step Into when idle starts paused on the first statement', async (p) => {
    await load(p, '\' comment first\n\nq = 5\nPRINT q');
    await p.menu('Debug', 'Step Into');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 2);
  });
  t.test('F10 when idle also starts paused on the first statement', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F10');
    p.assert.equal(await pausedLine(p), 0);
  });
  t.test('Step Out (Shift+F8) when idle does not start the program', async (p) => {
    await load(p, PSTEP);
    await p.key('F8', { shift: true });
    await p.sleep(150);
    p.assert.notEqual(await p.state(), 'paused');
    p.assert.notEqual(await p.state(), 'running');
  });
  t.test('Step Out toolbar button and menu item are disabled unless paused', async (p) => {
    await load(p, PSTEP);
    p.assert.equal(await p.ev("document.getElementById('tbOut').disabled"), true);
    await p.click('.menu-btn', 'Debug');
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((i) => i.label === 'Step Out');
    await p.closeMenus();
    p.assert.equal(it.disabled, true);
    p.assert.equal(it.sc, 'Shift+F8');
  });

  // ---- exec marker -----------------------------------------------------------------------------------------
  t.test('the paused line gets the exec arrow in the gutter and an exec highlight', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    p.assert.equal(await execMark(p), 0);
    p.assert.match(await gutterClasses(p, 0), /\bexec\b/);
    p.assert.match(await lineClasses(p, 0), /\bexec\b/);
  });
  t.test('exec arrow follows each step and only one line is marked', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    for (let k = 0; k < 4; k++) {
      await stepTo(p, 'F8');
      const line = await pausedLine(p);
      p.assert.equal(await gutterIndex(p, 'exec'), line);
      p.assert.equal(await p.fn(() => RC.app.active.editor.inner.querySelectorAll('.exec').length), 1);
    }
  });
  t.test('exec marker is cleared when the program runs to the end', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.equal(await execMark(p), null);
    p.assert.equal(await gutterIndex(p, 'exec'), -1);
  });
  t.test('exec marker is cleared while the program is running after Continue', async (p) => {
    await debug(p, 'x = 1\nDO\n  x = x + 1\nLOOP UNTIL x > 1E9', [0]);
    await p.key('F5');
    await p.waitState('running');
    p.assert.equal(await execMark(p), null);
    await p.stopProgram();
  });

  // ---- step into ------------------------------------------------------------------------------------
  t.test('F8 steps into SUBs and FUNCTIONs line by line', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    const seq = [await pausedLine(p)];
    for (let k = 0; k < 12; k++) {
      await stepTo(p, 'F8');
      if (await p.state() !== 'paused') { seq.push(await p.state()); break; }
      seq.push(await pausedLine(p));
    }
    p.assert.deepEqual(seq, [0, 1, 6, 7, 2, 9, 10, 3, 4, 'ended']);
    p.assert.match(await p.screen(), /2 {2}4/);
  });
  t.test('F11 is an alias for Step Into', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    await stepTo(p, 'F11');
    await stepTo(p, 'F11');
    p.assert.equal(await pausedLine(p), 6);
    p.assert.equal(await depth(p), 2);
  });
  t.test('toolbar Step button steps into a SUB call', async (p) => {
    await debug(p, PSTEP, [1]);
    await p.click('#tbInto');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 6);
  });
  t.test('stepping one statement at a time only prints after the PRINT executes', async (p) => {
    await load(p, 'PRINT "ONE"\nPRINT "TWO"\nPRINT "THREE"');
    await stepTo(p, 'F8');
    p.assert.doesNotMatch(await p.screen(), /ONE/);
    await stepTo(p, 'F8');
    p.assert.match(await p.screen(), /ONE/);
    p.assert.doesNotMatch(await p.screen(), /TWO/);
    await stepTo(p, 'F8');
    p.assert.match(await p.screen(), /TWO/);
    p.assert.doesNotMatch(await p.screen(), /THREE/);
  });
  t.test('stepping through colon-separated statements executes one statement per step', async (p) => {
    await load(p, 'a = 1: b = 2: c = 3\nPRINT a + b + c');
    await stepTo(p, 'F8');
    await stepTo(p, 'F8');
    p.assert.equal(await pausedLine(p), 0);
    p.assert.deepEqual([await ev(p, 'a'), await ev(p, 'b'), await ev(p, 'c')], [1, 0, 0]);
    await stepTo(p, 'F8');
    p.assert.deepEqual([await ev(p, 'a'), await ev(p, 'b'), await ev(p, 'c')], [1, 2, 0]);
  });
  t.test('stepping a FOR loop revisits the loop body each iteration', async (p) => {
    await load(p, 'FOR i = 1 TO 3\n  PRINT "I"; i\nNEXT i\nPRINT "END"');
    await stepTo(p, 'F8');
    let bodyVisits = 0;
    for (let k = 0; k < 20 && await p.state() === 'paused'; k++) {
      if (await pausedLine(p) === 1) bodyVisits++;
      await stepTo(p, 'F8');
    }
    p.assert.equal(bodyVisits, 3);
    p.assert.match(await p.screen(), /I 3\s*\nEND/);
  });
  t.test('step into a GOSUB jumps to the subroutine label body', async (p) => {
    await debug(p, PGOSUB, [1]);
    await stepTo(p, 'F8');
    p.assert.equal(await pausedLine(p), 5);
    await stepTo(p, 'F8');
    await stepTo(p, 'F8');
    p.assert.equal(await pausedLine(p), 9);
  });
  t.test('stepping past RETURN goes back to the statement after the GOSUB', async (p) => {
    await debug(p, PGOSUB, [10]);
    await stepTo(p, 'F8');
    p.assert.equal(await pausedLine(p), 7);
    await stepTo(p, 'F8');
    p.assert.equal(await pausedLine(p), 2);
    p.assert.equal(await ev(p, 'x'), 20);
  });
  t.test('step into recursion adds one frame per call', async (p) => {
    await debug(p, PFACT, [6]);
    const d0 = await depth(p);
    await stepTo(p, 'F8');
    p.assert.equal(await depth(p), d0 + 1);
    p.assert.equal(await pausedLine(p), 3);
    p.assert.equal(await ev(p, 'n%'), 3);
  });
  t.test('stepping into a SUB from an $INCLUDE file opens that file with the exec marker', async (p) => {
    await p.newFile('C:\\MYPROGS\\E2ELIB.BI', "SUB Hello\n  PRINT \"HELLO FROM LIB\"\nEND SUB");
    await debug(p, "'$INCLUDE: 'E2ELIB.BI'\nCALL Hello\nPRINT \"MAIN\"", [1]);
    await stepTo(p, 'F8');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\E2ELIB.BI');
    p.assert.equal(await execMark(p), 1);
    await stepTo(p, 'F8');
    await stepTo(p, 'F8');
    p.assert.equal(await p.activePath(), PATH);
    p.assert.equal(await execMark(p), 2);
  });

  // ---- step over ------------------------------------------------------------------------------------------
  t.test('F10 steps over SUB and FUNCTION calls', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    const seq = [await pausedLine(p)];
    for (let k = 0; k < 10; k++) {
      await stepTo(p, 'F10');
      if (await p.state() !== 'paused') { seq.push(await p.state()); break; }
      seq.push(await pausedLine(p));
    }
    p.assert.deepEqual(seq, [0, 1, 2, 3, 4, 'ended']);
  });
  t.test('step over a CALL still runs the SUB (its effect is visible)', async (p) => {
    await debug(p, PSTEP, [1]);
    await stepTo(p, 'F10');
    p.assert.equal(await pausedLine(p), 2);
    p.assert.equal(await ev(p, 'a'), 2);
    await stepTo(p, 'F10');
    p.assert.equal(await ev(p, 'b'), 4);
  });
  t.test('toolbar Over button steps over a call', async (p) => {
    await debug(p, PSTEP, [1]);
    await p.click('#tbOver');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 2);
  });
  t.test('Debug > Step Over menu item steps over a call', async (p) => {
    await debug(p, PSTEP, [2]);
    await p.menu('Debug', 'Step Over');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 3);
  });
  t.test('step over stops at a breakpoint inside the called SUB', async (p) => {
    await debug(p, PSTEP, [1, 6]);
    await stepTo(p, 'F10');
    p.assert.equal(await pausedLine(p), 6);
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'breakpoint');
  });
  t.test('step over a recursive call returns at the same depth', async (p) => {
    await debug(p, PFACT, [6]);
    await p.ev('RC.app.clearBreakpoints()');
    const d0 = await depth(p);
    await stepTo(p, 'F10');
    p.assert.equal(await depth(p), d0);
    p.assert.equal(await pausedLine(p), 7);
    await p.ev("RC.app.panels.show('vars')");
    p.assert.equal(await varVal(p, 'Fact# (result)'), '24');
  });
  t.test('step over in the main loop body stays in the loop', async (p) => {
    await debug(p, P1, [5]);
    await stepTo(p, 'F10');
    p.assert.equal(await pausedLine(p), 6);
    await stepTo(p, 'F10');
    p.assert.equal(await pausedLine(p), 5);
    p.assert.equal(await ev(p, 'i'), 2);
  });

  // ---- step out ------------------------------------------------------------------------------------------
  t.test('Shift+F8 steps out of a SUB back to the caller', async (p) => {
    await debug(p, PSTEP, [6]);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal(await pausedLine(p), 2);
    p.assert.equal(await depth(p), 1);
    p.assert.equal(await ev(p, 'a'), 2);
  });
  t.test('step out of a FUNCTION finishes the calling statement', async (p) => {
    await debug(p, PSTEP, [9]);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal(await pausedLine(p), 3);
    p.assert.equal(await ev(p, 'b'), 4);
  });
  t.test('toolbar Out button steps out', async (p) => {
    await debug(p, PSTEP, [6]);
    p.assert.equal(await p.ev("document.getElementById('tbOut').disabled"), false);
    await p.click('#tbOut');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 2);
  });
  t.test('Shift+F11 also steps out', async (p) => {
    await debug(p, PSTEP, [6]);
    await stepTo(p, 'F11', { shift: true });
    p.assert.equal(await pausedLine(p), 2);
  });
  t.test('step out of one recursion level pops exactly one frame', async (p) => {
    await debug(p, PFACT, [4]);
    p.assert.equal(await depth(p), 5);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal(await depth(p), 4);
    p.assert.equal(await ev(p, 'n%'), 2);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal(await depth(p), 3);
    p.assert.equal(await ev(p, 'n%'), 3);
  });
  t.test('step out from the main module runs to the end', async (p) => {
    await debug(p, P1, [2]);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /S= 15/);
  });
  t.test('step out stops early at a breakpoint further down the SUB', async (p) => {
    await debug(p, 'CALL Work\nPRINT "OUT"\nSUB Work\n  a = 1\n  b = 2\n  c = 3\nEND SUB', [3, 5]);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal(await pausedLine(p), 5);
  });

  // ---- continue / input -------------------------------------------------------------------------------------
  t.test('F5 continues from a step to the end of the program', async (p) => {
    await load(p, PSTEP);
    await stepTo(p, 'F8');
    await stepTo(p, 'F5');
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.status(), /Program ended/);
  });
  t.test('Run > Continue menu label appears while paused and continues', async (p) => {
    await debug(p, PSTEP, [2]);
    await p.click('.menu-btn', 'Run');
    await p.wait("!!document.querySelector('.menu-pop')");
    const labels = (await p.menuItems()).map((i) => i.label);
    p.assert.ok(labels.includes('Continue'));
    await p.click('.menu-pop .menu-item', 'Continue');
    await p.waitState('ended');
  });
  t.test('stepping over an INPUT waits for input, then pauses on the next line', async (p) => {
    await load(p, 'INPUT "Name"; n$\nPRINT "Hi "; n$');
    await stepTo(p, 'F8');
    await p.key('F10');
    await p.waitState('waiting');
    await p.ev('RC.app.runner.keyboard.type("ZED\\r"); RC.app.runner.kick()');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 1);
    p.assert.equal(await ev(p, 'n$'), 'ZED');
  });
  t.test('Restart (Shift+F5) while paused starts over and stops at the first breakpoint again', async (p) => {
    await debug(p, P1, [3]);
    await stepTo(p, 'F8');
    p.assert.match(await p.screen(), /Z= 3/);
    await p.key('F5', { shift: true });
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 3);
    p.assert.doesNotMatch(await p.screen(), /Z=/);
  });

  // ---- Run to Cursor -------------------------------------------------------------------------------------------
  t.test('F7 when idle runs to the cursor line', async (p) => {
    await load(p, P1);
    await cursorTo(p, 6);
    await stepTo(p, 'F7');
    p.assert.equal(await pausedLine(p), 6);
    p.assert.equal(await ev(p, 'i'), 1);
  });
  t.test('F7 while paused continues to the cursor line', async (p) => {
    await debug(p, P1, [0]);
    await cursorTo(p, 7);
    await stepTo(p, 'F7');
    p.assert.equal(await pausedLine(p), 7);
    p.assert.equal(await ev(p, 's'), 15);
  });
  t.test('run to cursor into a SUB body', async (p) => {
    await load(p, PSTEP);
    await cursorTo(p, 9);
    await stepTo(p, 'F7');
    p.assert.equal(await pausedLine(p), 9);
    p.assert.equal(await depth(p), 2);
  });
  t.test('run to cursor on a blank line stops at the next statement', async (p) => {
    await load(p, 'a = 1\n\nb = 2\nPRINT a + b');
    await cursorTo(p, 1);
    await stepTo(p, 'F7');
    p.assert.equal(await pausedLine(p), 2);
  });
  t.test('run to cursor is a one-shot stop (does not stop there again)', async (p) => {
    await load(p, P1);
    await cursorTo(p, 5);
    await stepTo(p, 'F7');
    p.assert.equal(await ev(p, 'i'), 1);
    await stepTo(p, 'F5');
    p.assert.equal(await p.state(), 'ended');
    p.assert.deepEqual(await p.fn((pa) => [...(RC.app.breakpoints.get(pa) || new Map()).keys()], PATH), []);
  });
  t.test('run to cursor stops earlier at a real breakpoint on the way', async (p) => {
    await load(p, P1);
    await p.fn((pa) => RC.app.toggleBreakpoint(pa, 2), PATH);
    await cursorTo(p, 7);
    await stepTo(p, 'F7');
    p.assert.equal(await pausedLine(p), 2);
  });
  t.test('run to cursor past the last statement shows a toast and stays paused', async (p) => {
    await debug(p, 'a = 1\nb = 2\n\n', [0]);
    await cursorTo(p, 3);
    await p.key('F7');
    await p.waitToast(/No statement at or after the cursor/);
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await pausedLine(p), 0);
  });
  t.test('Run > Run to Cursor menu item works', async (p) => {
    await load(p, P1);
    await cursorTo(p, 3);
    await p.menu('Run', 'Run to Cursor');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 3);
  });
  t.test('editor context menu Run to Cursor runs to the cursor line', async (p) => {
    await load(p, P1);
    await cursorTo(p, 4);
    const pt = await p.fn(() => { const ed = RC.app.active.editor; const r = ed.ta.getBoundingClientRect(); return [r.left + 30, r.top + 4.5 * ed.lineHeight]; });
    await p.clickAt(pt[0], pt[1], { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    await p.click('.menu-pop .menu-item', 'Run to Cursor');
    await p.waitState('paused');
    p.assert.equal(await pausedLine(p), 4);
  });

  // ---- Set Next Statement ---------------------------------------------------------------------------------
  t.test('Run > Set Next Statement is disabled when not paused', async (p) => {
    await load(p, P1);
    await p.click('.menu-btn', 'Run');
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((i) => i.label === 'Set Next Statement');
    await p.closeMenus();
    p.assert.equal(it.disabled, true);
  });
  t.test('Set Next Statement forward skips the lines in between', async (p) => {
    await debug(p, P1, [1]);
    await cursorTo(p, 3);
    await p.menu('Run', 'Set Next Statement');
    p.assert.equal(await pausedLine(p), 3);
    p.assert.equal(await execMark(p), 3);
    await stepTo(p, 'F8');
    p.assert.match(await p.screen(), /Z= 0/);
    p.assert.equal(await ev(p, 'y'), 0);
  });
  t.test('Set Next Statement backward re-executes a line', async (p) => {
    await debug(p, 'c = 0\nc = c + 1\nPRINT "C="; c', [2]);
    p.assert.equal(await ev(p, 'c'), 1);
    await cursorTo(p, 1);
    await p.menu('Run', 'Set Next Statement');
    await stepTo(p, 'F8');
    p.assert.equal(await ev(p, 'c'), 2);
    await stepTo(p, 'F5');
    p.assert.match(await p.screen(), /C= 2/);
  });
  t.test('Set Next Statement into another procedure is refused with a toast', async (p) => {
    await debug(p, PSTEP, [0]);
    await cursorTo(p, 9);
    await p.menu('Run', 'Set Next Statement');
    await p.waitToast(/Can only move within the current module/);
    p.assert.equal(await pausedLine(p), 0);
  });
  t.test('Set Next Statement on a comment line is refused', async (p) => {
    await debug(p, "a = 1\n' note\nb = 2", [0]);
    await cursorTo(p, 1);
    await p.menu('Run', 'Set Next Statement');
    await p.waitToast(/No statement on that line/);
    p.assert.equal(await pausedLine(p), 0);
  });
  t.test('Set Next Statement within a SUB moves inside that SUB', async (p) => {
    await debug(p, 'CALL W\nSUB W\n  a = 1\n  a = a + 10\n  PRINT "A="; a\nEND SUB', [2]);
    await cursorTo(p, 4);
    await p.menu('Run', 'Set Next Statement');
    p.assert.equal(await pausedLine(p), 4);
    await stepTo(p, 'F8');
    p.assert.match(await p.screen(), /A= 0/);
  });
  t.test('editor context menu Set Next Statement works while paused', async (p) => {
    await debug(p, P1, [0]);
    await cursorTo(p, 2);
    const pt = await p.fn(() => { const ed = RC.app.active.editor; const r = ed.ta.getBoundingClientRect(); return [r.left + 30, r.top + 2.5 * ed.lineHeight]; });
    await p.clickAt(pt[0], pt[1], { button: 'right' });
    await p.wait("!!document.querySelector('.menu-pop')");
    const it = (await p.menuItems()).find((i) => i.label === 'Set Next Statement');
    p.assert.equal(it.disabled, false);
    await p.click('.menu-pop .menu-item', 'Set Next Statement');
    await p.sleep(80);
    p.assert.equal(await pausedLine(p), 2);
  });

  // ---- Call Stack panel ------------------------------------------------------------------------------------
  t.test('Call Stack shows a hint when nothing is paused', async (p) => {
    await load(p, P1);
    await p.click('#bottomTabs .tab[data-id=stack]');
    p.assert.match(await p.panelText(), /call stack appears when the program is paused/i);
  }, { fresh: true });
  t.test('Call Stack in the main module has one Main module frame with file:line', async (p) => {
    await debug(p, P1, [3]);
    const rows = await stackRows(p);
    p.assert.deepEqual(rows, [{ depth: '#0', name: 'Main module', loc: 'E2E.BAS:4', sel: true }]);
  });
  t.test('Call Stack inside a SUB lists the SUB frame first, then the caller', async (p) => {
    await debug(p, PSTEP, [6]);
    const rows = await stackRows(p);
    p.assert.equal(rows.length, 2);
    p.assert.deepEqual(rows[0], { depth: '#1', name: 'SUB Inc', loc: 'E2E.BAS:7', sel: true });
    p.assert.deepEqual(rows[1], { depth: '#0', name: 'Main module', loc: 'E2E.BAS:2', sel: false });
  });
  t.test('Call Stack names a FUNCTION frame', async (p) => {
    await debug(p, PSTEP, [9]);
    const rows = await stackRows(p);
    p.assert.equal(rows[0].name, 'FUNCTION Twice');
    p.assert.equal(rows[1].loc, 'E2E.BAS:3');
  });
  t.test('Call Stack shows one frame for every recursion level', async (p) => {
    await debug(p, PFACT, [4]);
    const rows = await stackRows(p);
    p.assert.deepEqual(rows.map((r) => r.depth), ['#4', '#3', '#2', '#1', '#0']);
    p.assert.deepEqual(rows.map((r) => r.name), ['FUNCTION Fact#', 'FUNCTION Fact#', 'FUNCTION Fact#', 'FUNCTION Fact#', 'Main module']);
    p.assert.equal(rows[0].loc, 'E2E.BAS:5');
    p.assert.ok(rows.slice(1, 4).every((r) => r.loc === 'E2E.BAS:7'));
    p.assert.equal(rows[4].loc, 'E2E.BAS:2');
  });
  t.test('Call Stack grows and shrinks as you step into and out of calls', async (p) => {
    await debug(p, PSTEP, [1]);
    p.assert.equal((await stackRows(p)).length, 1);
    await stepTo(p, 'F8');
    p.assert.equal((await stackRows(p)).length, 2);
    await stepTo(p, 'F8', { shift: true });
    p.assert.equal((await stackRows(p)).length, 1);
  });
  t.test('Call Stack tab is kept when pausing again', async (p) => {
    await debug(p, PSTEP, [1]);
    await p.click('#bottomTabs .tab[data-id=stack]');
    await stepTo(p, 'F8');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'stack');
  });
  t.test('clicking a caller frame highlights it and marks its line in the editor', async (p) => {
    await debug(p, PFACT, [4]);
    await selectFrame(p, '#2');
    const rows = await stackRows(p);
    p.assert.deepEqual(rows.map((r) => r.sel), [false, false, true, false, false]);
    p.assert.equal(await p.ev('RC.app.active.editor.marks.frame'), 6);
    p.assert.match(await gutterClasses(p, 6), /\bframe\b/);
    p.assert.equal(await execMark(p), 4);
  });
  t.test('selecting a caller frame switches the Variables panel to that frame', async (p) => {
    await debug(p, PFACT, [4]);
    await selectFrame(p, '#2');
    await p.click('#bottomTabs .tab[data-id=vars]');
    p.assert.equal(await varVal(p, 'n%'), '3');
    p.assert.match(await p.text('.bpanel.active .bpanel-tools'), /Frame #2: FUNCTION Fact# \(caller — editable here\)/);
  });
  t.test('selecting each recursion frame shows its own n% value', async (p) => {
    await debug(p, PFACT, [4]);
    const got = [];
    for (const d of ['#4', '#3', '#2', '#1']) {
      await selectFrame(p, d);
      await p.ev("RC.app.panels.show('vars')");
      got.push(await varVal(p, 'n%'));
    }
    p.assert.deepEqual(got, ['1', '2', '3', '4']);
  });
  t.test('selecting the Main module frame shows only module-level sections', async (p) => {
    await debug(p, PFACT, [4]);
    await selectFrame(p, 'Main module');
    await p.ev("RC.app.panels.show('vars')");
    const titles = await p.texts('.bpanel.active .vsec');
    p.assert.ok(!titles.some((s) => /locals/i.test(s)));
    p.assert.ok(titles.some((s) => /module-level/i.test(s)));
    p.assert.equal(await p.ev('RC.app.active.editor.marks.frame'), 1);
  });
  t.test('clicking the top frame again removes the caller frame marker', async (p) => {
    await debug(p, PFACT, [4]);
    await selectFrame(p, '#1');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.frame'), 6);
    await selectFrame(p, '#4');
    p.assert.equal(await p.ev('RC.app.active.editor.marks.frame'), null);
    p.assert.equal(await gutterIndex(p, 'frame'), -1);
  });
  t.test('frame selection resets to the top frame on the next step', async (p) => {
    await debug(p, PFACT, [4]);
    await selectFrame(p, '#1');
    await stepTo(p, 'F8');
    const rows = await stackRows(p);
    p.assert.equal(rows[0].sel, true);
    p.assert.equal(await p.ev('RC.app.selectedFrameIndex()'), await depth(p) - 1);
  });
  t.test('Call Stack lists pending GOSUB return points (innermost first)', async (p) => {
    await debug(p, PGOSUB, [9]);
    await stackRows(p);
    const sub = await p.texts('.bpanel.active .frame-sub');
    p.assert.deepEqual(sub, ['GOSUB returns → line 8 ← line 3']);
  });
  t.test('Call Stack shows GOSUB return line numbers in numbered programs', async (p) => {
    await debug(p, '10 GOSUB 100\n20 END\n100 PRINT "X"\n110 RETURN', [2]);
    const rows = await stackRows(p);
    p.assert.match(rows[0].loc, /^E2E\.BAS:3\s+\[line 100\]$/);
    p.assert.deepEqual(await p.texts('.bpanel.active .frame-sub'), ['GOSUB returns → 20']);
  });
  t.test('Call Stack shows no GOSUB list after the subroutine returns', async (p) => {
    await debug(p, PGOSUB, [2]);
    await stackRows(p);
    p.assert.equal(await p.count('.bpanel.active .frame-sub'), 0);
  });
  t.test('Call Stack lists active FOR loops with counter, limit and STEP', async (p) => {
    await debug(p, 'FOR i = 1 TO 3\n  FOR j = 10 TO 1 STEP -2\n    PRINT i; j\n  NEXT\nNEXT', [2]);
    await stackRows(p);
    p.assert.deepEqual((await p.texts('.bpanel.active .frame-sub')).map((x) => x.replace(/\s+/g, ' ')), ['FOR loops: i = 1 TO 3; j = 10 TO 1 STEP -2']);
  });
  t.test('FOR loop list in the Call Stack updates as the loop advances', async (p) => {
    await debug(p, 'FOR i = 1 TO 3\n  FOR j = 10 TO 1 STEP -2\n    PRINT i; j\n  NEXT\nNEXT', [2]);
    await stepTo(p, 'F5');
    await stackRows(p);
    p.assert.match((await p.texts('.bpanel.active .frame-sub'))[0], /j = 8 TO 1 STEP -2/);
  });
  t.test('FOR loops inside a SUB appear under the SUB frame', async (p) => {
    await debug(p, 'CALL L\nSUB L\n  FOR k = 1 TO 4\n    PRINT k\n  NEXT\nEND SUB', [3]);
    await stackRows(p);
    const html = await p.panelText();
    p.assert.match(html, /SUB L[\s\S]*FOR loops: k = 1 TO 4[\s\S]*Main module/);
  });
  t.test('Call Stack shows the included file name for a SUB from $INCLUDE', async (p) => {
    await p.newFile('C:\\MYPROGS\\E2ELIB.BI', "SUB Hello\n  PRINT \"HELLO FROM LIB\"\nEND SUB");
    await debug(p, "'$INCLUDE: 'E2ELIB.BI'\nCALL Hello", [1]);
    await stepTo(p, 'F8');
    const rows = await stackRows(p);
    p.assert.equal(rows[0].loc, 'E2ELIB.BI:2');
    p.assert.equal(rows[1].loc, 'E2E.BAS:2');
  });
  t.test('selecting the caller frame in another file shows that file with the frame marker', async (p) => {
    await p.newFile('C:\\MYPROGS\\E2ELIB.BI', "SUB Hello\n  PRINT \"HELLO FROM LIB\"\nEND SUB");
    await debug(p, "'$INCLUDE: 'E2ELIB.BI'\nCALL Hello", [1]);
    await stepTo(p, 'F8');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\E2ELIB.BI');
    await selectFrame(p, 'Main module');
    p.assert.equal(await p.activePath(), PATH);
    p.assert.equal(await p.ev('RC.app.active.editor.marks.frame'), 1);
  });
};
