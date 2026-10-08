// Status bar contents and the run state machine: pause/continue/stop/restart, stepping, run to cursor,
// set next statement, STOP / END / SYSTEM, keyboard shortcuts.

const LOOP = 'DO\n  x = x + 1\nLOOP';
const segs = (p) => p.ev("[...document.getElementById('statusbar').children].map(e => e.textContent)");
const msgSeg = (p) => p.ev("(() => { const e = document.querySelector('#statusbar > span'); return { text: e.textContent, err: e.classList.contains('msg-err'), grow: e.classList.contains('grow') }; })()");
const exec = (p) => p.ev('RC.app.active.editor.marks.exec');
const runLbl = (p) => p.text('#tbRun .lbl');

async function toRunning(p, prog) {
  await p.runProgram(prog || LOOP, { wait: false });
  await p.waitState('running');
  await p.sleep(60);
}
async function focusEditor(p) {
  await p.ev('RC.app.active.editor.ta.focus()');
  await p.sleep(30);
}
async function openCode(p, text, path) {
  await p.newFile(path || 'C:\\MYPROGS\\E2E.BAS', text);
  await focusEditor(p);
}

export default (t0) => {
  // tests listed in CONT continue the previous test's program; all others start from a clean state
  const CONT = ["Step again executes", "stepping past the last", "Step Out from inside", "after stepping, Continue", "Run to Cursor while paused", "Continue after STOP"];
  const cleanup = async (p) => {
    await p.closeModals();
    await p.closeMenus();
    if (await p.ev('RC.app.runner.isActive()')) await p.stopProgram();
    if (await p.ev('RC.app.settings.speed') !== 0) await p.ev('RC.app.setSpeed(0)');
  };
  const t = { test: (name, fn, opts) => t0.test(name, async (p) => { if (!CONT.some((c) => name.startsWith(c))) await cleanup(p); return fn(p); }, opts) };

  // ---- status bar -------------------------------------------------------------------------------------
  t.test('status bar has role=status', async (p) => {
    p.assert.equal(await p.attr('#statusbar', 'role'), 'status');
  });
  t.test('fresh start: status shows the active file path, SCREEN 0, Ln/Col and BASIC', async (p) => {
    const s = await segs(p);
    p.assert.equal(s[0], 'C:\\MYPROGS\\HELLO.BAS');
    p.assert.equal(s.length, 4, 'no statement count before any run: ' + JSON.stringify(s));
    p.assert.equal(s[1], 'SCREEN 0');
    p.assert.match(s[2], /^Ln \d+, Col \d+$/);
    p.assert.equal(s[3], 'BASIC');
  }, { fresh: true });
  t.test('status message follows the active file before anything has run', async (p) => {
    await p.newFile('C:\\MYPROGS\\OTHER.BAS', 'PRINT 1');
    p.assert.equal((await segs(p))[0], 'C:\\MYPROGS\\OTHER.BAS');
    await p.click('#editorTabs .tab', 'HELLO.BAS');
    await p.sleep(50);
    p.assert.equal((await segs(p))[0], 'C:\\MYPROGS\\HELLO.BAS');
  }, { fresh: true });
  t.test('message span is the growing one and not error-styled initially', async (p) => {
    const m = await msgSeg(p);
    p.assert.equal(m.grow, true);
    p.assert.equal(m.err, false);
  });
  t.test('Ln/Col follow setCursor', async (p) => {
    await openCode(p, 'PRINT "ABC"\nPRINT "DEFGH"\nPRINT 3');
    await p.ev('RC.app.active.editor.setCursor(1, 4)');
    p.assert.equal((await segs(p)).find((x) => x.startsWith('Ln')), 'Ln 2, Col 5');
  });
  t.test('Ln/Col follow arrow keys in the editor', async (p) => {
    await openCode(p, 'PRINT "ABC"\nPRINT "DEFGH"\nPRINT 3');
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.key('ArrowDown');
    await p.key('ArrowDown');
    await p.key('ArrowRight');
    await p.key('ArrowRight');
    p.assert.match(await p.status(), /Ln 3, Col 3/);
    await p.key('ArrowUp');
    p.assert.match(await p.status(), /Ln 2, Col 3/);
  });
  t.test('Ln/Col follow End and Home keys', async (p) => {
    await openCode(p, 'PRINT "ABC"\nPRINT "DEFGH"');
    await p.ev('RC.app.active.editor.setCursor(1, 0)');
    await p.key('End');
    p.assert.match(await p.status(), /Ln 2, Col 14/);
    await p.key('Home');
    p.assert.match(await p.status(), /Ln 2, Col 1\b/);
  });
  t.test('Ln/Col update while typing', async (p) => {
    await openCode(p, '');
    await p.type('x = 1\ny');
    p.assert.match(await p.status(), /Ln 2, Col 2/);
  });
  t.test('Ln/Col update when clicking into the editor text', async (p) => {
    await openCode(p, 'PRINT 1\nPRINT 2\nPRINT 3\nPRINT 4');
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    const pos = await p.ev("(() => { const l = RC.app.active.editor.hl.children[2]; const r = l.getBoundingClientRect(); return [r.left + 2, r.top + r.height / 2]; })()");
    await p.clickAt(pos[0], pos[1]);
    p.assert.match(await p.status(), /Ln 3, Col 1\b/);
  });
  t.test('statement count appears after a run and equals the VM count, locale formatted', async (p) => {
    await p.runProgram('FOR i = 1 TO 1500\n  x = x + 1\nNEXT');
    const n = await p.ev('RC.app.runner.vm.statementsExecuted');
    p.assert.ok(n > 1500, String(n));
    const s = await segs(p);
    p.assert.equal(s[1], (await p.ev(`(${n}).toLocaleString()`)) + ' stmts');
    p.assert.match(s[1], /^\d{1,3}(,\d{3})+ stmts$/);
  });
  t.test('SCREEN segment follows SCREEN 13 / 12 / 1 / 9', async (p) => {
    for (const m of [13, 12, 1, 9]) {
      await p.runProgram(`SCREEN ${m}\nPSET (1, 1), 1`);
      p.assert.equal(await p.state(), 'ended');
      p.assert.ok((await segs(p)).includes('SCREEN ' + m), `SCREEN ${m}: ` + JSON.stringify(await segs(p)));
    }
  });
  t.test('SCREEN segment updates while the program is still running', async (p) => {
    await toRunning(p, 'SCREEN 7\nDO\nLOOP');
    p.assert.ok((await segs(p)).includes('SCREEN 7'));
  });
  t.test('a new run resets the SCREEN segment to 0', async (p) => {
    await p.runProgram('SCREEN 13');
    p.assert.ok((await segs(p)).includes('SCREEN 13'));
    await p.runProgram('PRINT 1');
    p.assert.ok((await segs(p)).includes('SCREEN 0'));
  });
  t.test('running: status says "Running E2E.BAS — Ctrl+Break to pause"', async (p) => {
    await toRunning(p);
    p.assert.equal((await msgSeg(p)).text, 'Running E2E.BAS — Ctrl+Break to pause');
  });
  t.test('ended: status says "Program ended — press F5 to run again, F4 to view output"', async (p) => {
    await p.runProgram('PRINT 1');
    p.assert.equal((await msgSeg(p)).text, 'Program ended — press F5 to run again, F4 to view output');
  });
  t.test('stopped: status says "Stopped"', async (p) => {
    await toRunning(p);
    await p.click('#tbStop');
    p.assert.equal((await msgSeg(p)).text, 'Stopped');
    p.assert.equal((await msgSeg(p)).err, false);
  });
  t.test('paused by user: status says "Paused — F5 continue, F8 step, F10 step over"', async (p) => {
    await toRunning(p);
    await p.click('#tbPause');
    await p.waitState('paused');
    p.assert.equal((await msgSeg(p)).text, 'Paused — F5 continue, F8 step, F10 step over');
  });
  t.test('Ctrl+Break: status starts with "Break"', async (p) => {
    await toRunning(p);
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'break');
    p.assert.match((await msgSeg(p)).text, /^Break — F5 continue/);
  });
  t.test('Ctrl+Break in a line-numbered program reports the line', async (p) => {
    await toRunning(p, '10 X = X + 1\n20 GOTO 10');
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused');
    p.assert.match((await msgSeg(p)).text, /^Break in line (10|20) — F5 continue/);
  });
  t.test('STOP: status says "STOP statement"', async (p) => {
    await p.runProgram('PRINT 1\nSTOP\nPRINT 2');
    p.assert.equal((await msgSeg(p)).text, 'STOP statement — F5 continue, F8 step, F10 step over');
  });
  t.test('STOP in a numbered line: status includes "in line 20"', async (p) => {
    await p.runProgram('10 PRINT 1\n20 STOP\n30 PRINT 2');
    p.assert.match((await msgSeg(p)).text, /^STOP statement in line 20 — /);
  });
  t.test('status bar statement count refreshes on pause', async (p) => {
    await toRunning(p);
    await p.sleep(150);
    await p.click('#tbPause');
    await p.waitState('paused');
    const n = await p.ev('RC.app.runner.vm.statementsExecuted');
    p.assert.ok((await segs(p)).includes(n.toLocaleString('en-US') + ' stmts') || (await segs(p)).includes((await p.ev(`(${n}).toLocaleString()`)) + ' stmts'));
  });

  // ---- run / pause / continue / end ------------------------------------------------------------------------
  t.test('run → pause → continue → end using toolbar buttons (and the Immediate window)', async (p) => {
    await toRunning(p, 'DO WHILE done = 0\nLOOP\nPRINT "FINISHED"');
    await p.click('#tbPause');
    await p.waitState('paused');
    p.assert.equal(await runLbl(p), 'Continue');
    p.assert.ok(await exec(p) !== null, 'exec line shown when paused');
    await p.panel('immediate');
    await p.click('.imm-input input');
    await p.type('done = 1\n');
    await p.click('#tbRun');
    await p.waitState('ended', 5000);
    p.assert.equal(await exec(p), null, 'exec mark cleared');
    p.assert.match(await p.screen(), /FINISHED/);
    p.assert.equal(await runLbl(p), 'Run');
  });
  t.test('Continue clears the exec mark and the program keeps running', async (p) => {
    await toRunning(p);
    await p.click('#tbPause');
    await p.waitState('paused');
    await p.click('#tbRun');
    p.assert.equal(await p.state(), 'running');
    p.assert.equal(await exec(p), null);
    p.assert.equal(await p.text('#tbState'), 'Running');
  });
  t.test('pausing switches from Problems to the Variables panel', async (p) => {
    await p.panel('problems');
    await toRunning(p, 'n = 42\nDO\nLOOP');
    await p.click('#tbPause');
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.panels.active'), 'vars');
    p.assert.match(await p.panelText(), /\bN\b|\bn\b/);
  });
  t.test('pausing marks the current line in the editor (.exec)', async (p) => {
    await toRunning(p);
    await p.click('#tbPause');
    await p.waitState('paused');
    await p.sleep(50);
    p.assert.ok(await p.count('.ed-line.exec') >= 1);
    p.assert.ok([0, 1, 2].includes(await exec(p)));
  });
  t.test('F5 on a paused program continues it', async (p) => {
    await p.runProgram('PRINT "ONE"\nSTOP\nPRINT "TWO"');
    p.assert.equal(await p.state(), 'paused');
    await focusEditor(p);
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /TWO/);
  });
  t.test('F5 continues even while the output screen has focus', async (p) => {
    await p.runProgram('PRINT "ONE"\nSTOP\nPRINT "TWO"');
    await p.ev("document.getElementById('screen').focus()");
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /TWO/);
  });
  t.test('F5 when idle/ended runs the active program', async (p) => {
    await openCode(p, 'PRINT "F5RUN"');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /F5RUN/);
  });
  t.test('F5 while running (editor focused) is ignored', async (p) => {
    await toRunning(p);
    await p.ev('window.__vm1 = RC.app.runner.vm; 0');
    await focusEditor(p);
    await p.key('F5');
    p.assert.equal(await p.ev('RC.app.runner.vm === window.__vm1'), true);
    p.assert.equal(await p.state(), 'running');
  });
  t.test('Shift+F5 restarts the program', async (p) => {
    await toRunning(p);
    await p.ev('window.__vm1 = RC.app.runner.vm; 0');
    await focusEditor(p);
    await p.key('F5', { shift: true });
    await p.sleep(50);
    p.assert.equal(await p.ev('RC.app.runner.vm !== window.__vm1'), true);
    p.assert.equal(await p.state(), 'running');
  });
  t.test('Ctrl+F2 stops a running program', async (p) => {
    await toRunning(p);
    await focusEditor(p);
    await p.key('F2', { ctrl: true });
    await p.waitState('ended');
    p.assert.equal(await p.ev('RC.app.runner.vm.endReason'), 'stopped');
    p.assert.equal((await msgSeg(p)).text, 'Stopped');
  });
  t.test('Ctrl+C on the focused output screen pauses a running program', async (p) => {
    await toRunning(p);
    p.assert.equal(await p.focusedId(), 'screen');
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'break');
  });
  t.test('run → stop: state ended with reason "stopped", no exec mark', async (p) => {
    await toRunning(p);
    await p.click('#tbPause');
    await p.waitState('paused');
    await p.click('#tbStop');
    p.assert.equal(await p.state(), 'ended');
    p.assert.equal(await p.ev('RC.app.runner.vm.endReason'), 'stopped');
    p.assert.equal(await exec(p), null);
    p.assert.equal(await runLbl(p), 'Run');
  });
  t.test('stopping does not print anything more to the screen', async (p) => {
    await toRunning(p, 'PRINT "START"\nDO\nLOOP\nPRINT "NEVER"');
    await p.click('#tbStop');
    await p.sleep(100);
    p.assert.doesNotMatch(await p.screen(), /NEVER/);
  });
  t.test('after stopping, Run starts the program again from the top', async (p) => {
    await toRunning(p, 'PRINT "TOP"\nDO\nLOOP');
    await p.click('#tbStop');
    await p.click('#tbRun');
    await p.waitState('running');
    p.assert.equal(await p.ev('RC.app.runner.vm.statementsExecuted > 0'), true);
    p.assert.equal((await p.screen()).match(/TOP/g).length, 1);
  });

  // ---- stepping --------------------------------------------------------------------------------------------
  const STEP_PROG = "' comment line\n\nPRINT \"S1\"\nPRINT \"S2\"\nPRINT \"S3\"";
  t.test('Step from idle starts paused at the first statement (skipping comments/blank lines)', async (p) => {
    await openCode(p, STEP_PROG);
    await p.click('#tbInto');
    await p.waitState('paused');
    p.assert.equal(await exec(p), 2);
    p.assert.doesNotMatch(await p.screen(), /S1/);
    p.assert.equal(await runLbl(p), 'Continue');
    p.assert.match((await msgSeg(p)).text, /^Paused — /);
  });
  t.test('Step again executes one statement and advances the exec line', async (p) => {
    await p.click('#tbInto');
    await p.wait('RC.app.runner.state === "paused" && RC.app.active.editor.marks.exec === 3');
    p.assert.match(await p.screen(), /S1/);
    p.assert.doesNotMatch(await p.screen(), /S2/);
  });
  t.test('stepping past the last statement ends the program', async (p) => {
    await p.click('#tbInto');
    await p.wait('RC.app.active.editor.marks.exec === 4');
    await p.click('#tbInto');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /S3/);
    p.assert.equal(await exec(p), null);
  });
  t.test('F8 from idle starts paused at the first statement', async (p) => {
    await openCode(p, STEP_PROG);
    await p.key('F8');
    await p.waitState('paused');
    p.assert.equal(await exec(p), 2);
  });
  t.test('Over from idle also starts paused at the first statement', async (p) => {
    await openCode(p, STEP_PROG);
    await p.click('#tbOver');
    await p.waitState('paused');
    p.assert.equal(await exec(p), 2);
  });
  const SUB_PROG = 'DECLARE SUB Hello ()\nPRINT "A"\nHello\nPRINT "C"\n\nSUB Hello\n  PRINT "B1"\n  PRINT "B2"\nEND SUB';
  t.test('Step Over a SUB call runs the whole SUB and stops on the next line', async (p) => {
    await openCode(p, SUB_PROG);
    await p.click('#tbInto');
    await p.waitState('paused');
    await p.click('#tbOver'); // PRINT "A"
    await p.wait('RC.app.active.editor.marks.exec === 2');
    await p.click('#tbOver'); // Hello
    await p.wait('RC.app.active.editor.marks.exec === 3');
    p.assert.match(await p.screen(), /B1\s*\n\s*B2/);
    p.assert.equal(await p.state(), 'paused');
  });
  t.test('Step Into a SUB call stops on the first line inside the SUB', async (p) => {
    await openCode(p, SUB_PROG);
    await p.key('F8');
    await p.waitState('paused');
    await p.key('F8');
    await p.wait('RC.app.active.editor.marks.exec === 2');
    await p.key('F8');
    await p.wait('RC.app.active.editor.marks.exec === 6');
    p.assert.doesNotMatch(await p.screen(), /B1/);
    p.assert.equal(await p.ev('RC.app.runner.vm.frames.length'), 2);
  });
  t.test('Step Out from inside a SUB finishes it and returns to the caller', async (p) => {
    await p.click('#tbOut');
    await p.wait('RC.app.runner.state === "paused" && RC.app.active.editor.marks.exec === 3', 4000);
    p.assert.match(await p.screen(), /B2/);
    p.assert.doesNotMatch(await p.screen(), /C\s*$/m);
    p.assert.equal(await p.ev('RC.app.runner.vm.frames.length'), 1);
  });
  t.test('Shift+F8 (step out) does nothing when no program is paused', async (p) => {
    await p.runProgram('PRINT 1');
    await focusEditor(p);
    await p.ev('window.__vm2 = RC.app.runner.vm; 0');
    await p.key('F8', { shift: true });
    await p.sleep(100);
    p.assert.equal(await p.state(), 'ended');
    p.assert.equal(await p.ev('RC.app.runner.vm === window.__vm2'), true);
  });
  t.test('F10 steps over while paused', async (p) => {
    await openCode(p, SUB_PROG);
    await p.key('F10');
    await p.waitState('paused');
    await p.key('F10');
    await p.wait('RC.app.active.editor.marks.exec === 2');
    await p.key('F10');
    await p.wait('RC.app.active.editor.marks.exec === 3');
    p.assert.match(await p.screen(), /B2/);
  });
  t.test('after stepping, Continue runs to the end', async (p) => {
    await p.click('#tbRun');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /^C\s*$/m);
  });

  // ---- run to cursor ----------------------------------------------------------------------------------------
  t.test('Run to Cursor (F7) from idle pauses at the cursor line', async (p) => {
    await openCode(p, 'PRINT "L1"\nPRINT "L2"\nPRINT "L3"\nPRINT "L4"');
    await p.ev('RC.app.active.editor.setCursor(2, 0)');
    await p.key('F7');
    await p.waitState('paused');
    p.assert.equal(await exec(p), 2);
    const s = await p.screen();
    p.assert.match(s, /L2/);
    p.assert.doesNotMatch(s, /L3/);
  });
  t.test('Run to Cursor while paused continues to the new cursor line', async (p) => {
    await p.ev('RC.app.active.editor.setCursor(3, 0)');
    await p.key('F7');
    await p.wait('RC.app.runner.state === "paused" && RC.app.active.editor.marks.exec === 3');
    p.assert.match(await p.screen(), /L3/);
    p.assert.doesNotMatch(await p.screen(), /L4/);
  });
  t.test('Run to Cursor breakpoint is temporary (a loop does not stop there again)', async (p) => {
    await openCode(p, 'FOR i = 1 TO 3\n  PRINT "I"; i\nNEXT\nPRINT "DONE"');
    await p.ev('RC.app.active.editor.setCursor(1, 0)');
    await p.menu('Run', 'Run to Cursor');
    await p.waitState('paused');
    p.assert.equal(await exec(p), 1);
    await p.click('#tbRun');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /I 3[\s\S]*DONE/);
  });
  t.test('Run to Cursor below the last statement shows a toast and runs to the end', async (p) => {
    await openCode(p, 'PRINT "ONLY"\n\n\n');
    await p.ev('RC.app.active.editor.setCursor(3, 0)');
    await p.key('F7');
    await p.waitToast(/No statement at or after the cursor/);
    await p.waitState('ended');
    p.assert.match(await p.screen(), /ONLY/);
  });

  // ---- set next statement -------------------------------------------------------------------------------------
  t.test('Set Next Statement is disabled in the Run menu unless paused', async (p) => {
    await p.runProgram('PRINT 1');
    await p.click('.menu-btn', 'Run');
    const it = (await p.menuItems()).find((m) => m.label === 'Set Next Statement');
    p.assert.equal(it.disabled, true);
    await p.closeMenus();
  });
  t.test('Set Next Statement skips ahead: lines in between are not executed', async (p) => {
    await openCode(p, 'PRINT "A"\nPRINT "B"\nPRINT "C"\nPRINT "D"');
    await p.key('F8');
    await p.waitState('paused');
    await p.ev('RC.app.active.editor.setCursor(3, 0)');
    await p.click('.menu-btn', 'Run');
    const it = (await p.menuItems()).find((m) => m.label === 'Set Next Statement');
    p.assert.equal(it.disabled, false);
    await p.click('.menu-pop .menu-item', 'Set Next Statement');
    await p.sleep(100);
    p.assert.equal(await exec(p), 3);
    await p.click('#tbRun');
    await p.waitState('ended');
    const s = await p.screen();
    p.assert.match(s, /^D\s*$/m);
    p.assert.doesNotMatch(s, /^[ABC]\s*$/m);
  });
  t.test('Set Next Statement backwards re-executes lines', async (p) => {
    await openCode(p, 'n = n + 1\nPRINT "N="; n\nSTOP\nPRINT "END"');
    await p.key('F5');
    await p.waitState('paused');
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.ev('RC.app.setNextStatement()');
    p.assert.equal(await exec(p), 0);
    await p.key('F5');
    await p.wait('RC.app.runner.state === "paused" && /N= 2/.test(RC.app.runner.display.textLines().join("\\n"))');
    p.assert.match(await p.screen(), /N= 1[\s\S]*N= 2/);
  });
  t.test('Set Next Statement into a SUB from the module is refused with a toast', async (p) => {
    await openCode(p, 'DECLARE SUB S ()\nPRINT 1\nSTOP\nPRINT 2\nSUB S\n  PRINT "IN"\nEND SUB');
    await p.key('F5');
    await p.waitState('paused');
    await p.ev('RC.app.active.editor.setCursor(5, 0)');
    await p.ev('RC.app.setNextStatement()');
    await p.waitToast(/Can only move within the current module/);
    p.assert.equal(await exec(p), 2);
  });

  // ---- STOP / END / SYSTEM ------------------------------------------------------------------------------------
  t.test('STOP pauses with reason "stop" and marks the STOP line', async (p) => {
    await p.runProgram('PRINT "X"\nSTOP\nPRINT "Y"');
    p.assert.equal(await p.state(), 'paused');
    p.assert.equal(await p.ev('RC.app.runner.vm.pauseReason'), 'stop');
    p.assert.equal(await exec(p), 1);
  });
  t.test('Continue after STOP runs the remaining statements', async (p) => {
    await p.click('#tbRun');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /X\s*\nY/);
  });
  t.test('END ends the program; statements after END do not run', async (p) => {
    await p.runProgram('PRINT "BEFORE"\nEND\nPRINT "AFTER"');
    p.assert.equal(await p.state(), 'ended');
    p.assert.equal(await p.ev('RC.app.runner.vm.endReason'), 'end');
    p.assert.doesNotMatch(await p.screen(), /AFTER/);
    p.assert.equal((await msgSeg(p)).text, 'Program ended — press F5 to run again, F4 to view output');
  });
  t.test('SYSTEM ends the program with reason "system"', async (p) => {
    await p.runProgram('PRINT "BEFORE"\nSYSTEM\nPRINT "AFTER"');
    p.assert.equal(await p.state(), 'ended');
    p.assert.equal(await p.ev('RC.app.runner.vm.endReason'), 'system');
    p.assert.doesNotMatch(await p.screen(), /AFTER/);
    p.assert.match((await msgSeg(p)).text, /^Program ended/);
    p.assert.equal(await p.text('#tbState'), 'Ended');
  });
  t.test('falling off the end of the program ends normally', async (p) => {
    await p.runProgram('PRINT "LAST"');
    p.assert.equal(await p.ev('RC.app.runner.vm.endReason'), 'end');
    p.assert.equal(await p.text('#tbState'), 'Ended');
  });
  t.test('END inside a SUB ends the whole program', async (p) => {
    await p.runProgram('DECLARE SUB Q ()\nQ\nPRINT "AFTER"\nSUB Q\n  PRINT "INQ"\n  END\nEND SUB');
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /INQ/);
    p.assert.doesNotMatch(await p.screen(), /AFTER/);
  });
};
