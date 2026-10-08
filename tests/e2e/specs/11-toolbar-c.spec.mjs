// Runtime errors, compile errors, INPUT waiting & screen focus, switching tabs while running,
// responsiveness of long loops and the speed presets' real throttling.

const LOOP = 'DO\n  x = x + 1\nLOOP';
const ERR_PROG = 'PRINT "START"\nz = 0\nq = 10 / z\nPRINT "NOPE"';
const SYN_PROG = 'PRINT "OK"\n\nx = = 2\nPRINT "MORE"';
const msgSeg = (p) => p.ev("(() => { const e = document.querySelector('#statusbar > span'); return { text: e.textContent, err: e.classList.contains('msg-err') }; })()");
const immLines = (p) => p.ev("[...document.querySelectorAll('.imm-log > div')].map(d => ({ text: d.textContent, cls: d.className }))");
const probRows = (p) => p.ev("[...document.querySelectorAll('.bpanel .list-row')].map(r => [...r.children].map(c => c.textContent))");
const probCount = (p) => p.ev("(document.querySelector('#bottomTabs .tab[data-id=problems] .count') || {}).textContent || ''");
const errLine = (p) => p.ev('RC.app.active.editor.marks.err');
const xRate = (p, ms) => p.ev(`new Promise(r => { const vm = RC.app.runner.vm; const X = () => RC.Basic.Debug.evaluate(vm, 'x', 0).value; const a = X(), t = performance.now(); setTimeout(() => r((X() - a) * 1000 / (performance.now() - t)), ${ms}); })`);
const rate = (p, ms) => p.ev(`new Promise(r => { const vm = RC.app.runner.vm; const a = vm.statementsExecuted, t = performance.now(); setTimeout(() => r((vm.statementsExecuted - a) * 1000 / (performance.now() - t)), ${ms}); })`);

async function clickEditor(p) {
  const [x, y] = await p.ev("(() => { const r = RC.app.active.editor.ta.getBoundingClientRect(); return [r.left + r.width / 2, r.top + Math.min(r.height / 2, 60)]; })()");
  await p.clickAt(x, y);
}
async function toRunning(p, prog) {
  await p.runProgram(prog || LOOP, { wait: false });
  await p.waitState('running');
  await p.sleep(60);
}

export default (t0) => {
  // tests listed in CONT continue the previous test's program; all others start from a clean state
  const CONT = [];
  const cleanup = async (p) => {
    // headless windows have no OS focus; emulate it so focus/blur events fire like in a real browser
    await p.b.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
    await p.closeModals();
    await p.closeMenus();
    if (await p.ev('RC.app.runner.isActive()')) await p.stopProgram();
    if (await p.ev('RC.app.settings.speed') !== 0) await p.ev('RC.app.setSpeed(0)');
  };
  const t = { test: (name, fn, opts) => t0.test(name, async (p) => { if (!CONT.some((c) => name.startsWith(c))) await cleanup(p); return fn(p); }, opts) };

  // ---- runtime error -----------------------------------------------------------------------------------
  t.test('runtime error: state error and output before the error is shown', async (p) => {
    p.assert.equal(await p.runProgram(ERR_PROG), 'error');
    p.assert.match(await p.screen(), /START/);
    p.assert.doesNotMatch(await p.screen(), /NOPE/);
  });
  t.test('runtime error: status bar shows "Runtime error 11: Division by zero" in error style', async (p) => {
    const m = await msgSeg(p);
    p.assert.equal(m.text, 'Runtime error 11: Division by zero');
    p.assert.equal(m.err, true);
    p.assert.equal(await p.ev("getComputedStyle(document.querySelector('#statusbar .msg-err')).fontWeight"), '600');
  });
  t.test('runtime error: Problems tab shows a count of 1', async (p) => {
    p.assert.equal(await probCount(p), '1');
  });
  t.test('runtime error: Immediate panel is shown with the error and a hint', async (p) => {
    p.assert.equal(await p.ev('RC.app.panels.active'), 'immediate');
    const lines = await immLines(p);
    const e = lines.find((l) => /^Runtime error 11: Division by zero/.test(l.text));
    p.assert.ok(e, JSON.stringify(lines));
    p.assert.match(e.text, /\(E2E\.BAS:3\)$/);
    p.assert.match(e.cls, /\berr\b/);
    p.assert.match(e.cls, /\bjump\b/);
    const hint = lines.find((l) => /^Hint: /.test(l.text));
    p.assert.ok(hint && /\bnote\b/.test(hint.cls), 'hint line logged');
  });
  t.test('runtime error: editor marks the error line (line 3)', async (p) => {
    await p.sleep(50);
    p.assert.equal(await errLine(p), 2);
    p.assert.equal(await p.ev("[...RC.app.active.editor.hl.children].findIndex(l => l.classList.contains('errline'))"), 2);
    p.assert.equal(await p.ev("[...RC.app.active.editor.inner.children].findIndex(g => g.classList.contains('err'))"), 2);
  });
  t.test('runtime error: an error toast is shown', async (p) => {
    await p.runProgram(ERR_PROG);
    await p.waitToast(/Runtime error: Division by zero/);
    p.assert.match(await p.lastToast(), /Variables are kept/);
    p.assert.equal(await p.ev("document.querySelector('.toast:last-child').classList.contains('err')"), true);
  });
  t.test('runtime error: Problems panel row has kind, message and location', async (p) => {
    await p.panel('problems');
    const rows = await probRows(p);
    p.assert.equal(rows.length, 1);
    p.assert.deepEqual(rows[0], ['Runtime error 11', 'Division by zero', 'E2E.BAS:3:1']);
  });
  t.test('double-clicking the Problems row moves the cursor to the error line', async (p) => {
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.dblclick('.bpanel .list-row');
    p.assert.equal(await p.ev('RC.app.active.editor.cursor().line'), 2);
    p.assert.match(await p.status(), /Ln 3, Col 1\b/);
  });
  t.test('double-clicking the Immediate error entry goes to the error line', async (p) => {
    await p.panel('immediate');
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.dblclick('.imm-log .jump', 'Division by zero');
    p.assert.equal(await p.ev('RC.app.active.editor.cursor().line'), 2);
  });
  t.test('runtime error in a numbered line reports "in line 30"', async (p) => {
    await p.runProgram('10 Z = 0\n20 PRINT "A"\n30 Q = 1 / Z');
    p.assert.equal((await msgSeg(p)).text, 'Runtime error 11: Division by zero in line 30');
  });
  t.test('runtime error inside a SUB points at the SUB line', async (p) => {
    await p.runProgram('DECLARE SUB Bad ()\nBad\nSUB Bad\n  DIM a(5)\n  a(9) = 1\nEND SUB');
    p.assert.equal(await p.state(), 'error');
    p.assert.match((await msgSeg(p)).text, /^Runtime error 9: Subscript out of range/);
    p.assert.equal(await errLine(p), 4);
  });
  t.test('runtime error in a file that is not active opens and marks that file', async (p) => {
    await p.newFile('C:\\MYPROGS\\E2E.BAS', 't = TIMER\nDO WHILE TIMER - t < 1.5\nLOOP\nERROR 5');
    await p.ev('RC.app.run()');
    await p.waitState('running');
    await p.click('#editorTabs .tab', 'HELLO.BAS');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
    p.assert.equal(await p.state(), 'running');
    await p.waitState('error', 5000);
    await p.sleep(50);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\E2E.BAS');
    p.assert.equal(await errLine(p), 3);
    p.assert.match((await msgSeg(p)).text, /^Runtime error 5: Illegal function call/);
  });
  t.test('an error handled by ON ERROR does not produce error state', async (p) => {
    await p.runProgram('ON ERROR GOTO h\nq = 1 / 0\nPRINT "AFTER"\nEND\nh:\nPRINT "HANDLED"; ERR\nRESUME NEXT');
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /HANDLED 11[\s\S]*AFTER/);
    p.assert.equal((await msgSeg(p)).err, false);
    p.assert.equal(await probCount(p), '');
  });
  t.test('rerun after a runtime error clears the error line, problems and error status', async (p) => {
    await p.runProgram(ERR_PROG);
    p.assert.equal(await errLine(p), 2);
    await p.setCode('PRINT "FIXED"');
    await p.click('#tbRun');
    await p.waitState('ended');
    p.assert.equal(await errLine(p), null);
    p.assert.equal(await probCount(p), '');
    p.assert.equal((await msgSeg(p)).err, false);
    p.assert.equal(await p.text('#tbState'), 'Ended');
    await p.panel('problems');
    p.assert.match(await p.panelText(), /No problems\./);
  });

  // ---- compile error -------------------------------------------------------------------------------------
  t.test('compile error: Problems panel is shown automatically', async (p) => {
    await p.panel('immediate');
    await p.runProgram(SYN_PROG, { wait: false });
    await p.sleep(100);
    p.assert.equal(await p.ev('RC.app.panels.active'), 'problems');
  });
  t.test('compile error: Problems row has "Syntax error", message and file:line:col', async (p) => {
    const rows = await probRows(p);
    p.assert.equal(rows.length, 1);
    p.assert.equal(rows[0][0], 'Syntax error');
    p.assert.match(rows[0][1], /Expected: expression/);
    p.assert.equal(rows[0][2], 'E2E.BAS:3:5');
    p.assert.equal(await probCount(p), '1');
  });
  t.test('compile error: cursor is placed at the error line and column', async (p) => {
    p.assert.deepEqual(await p.ev('RC.app.active.editor.cursor()'), { line: 2, col: 4 });
    p.assert.match(await p.status(), /Ln 3, Col 5/);
  });
  t.test('compile error: editor marks the error line', async (p) => {
    p.assert.equal(await errLine(p), 2);
  });
  t.test('compile error: status bar shows "Syntax: …" with the location, error-styled', async (p) => {
    const m = await msgSeg(p);
    p.assert.match(m.text, /^Syntax: Expected: expression.* \(E2E\.BAS:3\)$/);
    p.assert.equal(m.err, true);
  });
  t.test('compile error: Immediate log gets a "Syntax error:" entry', async (p) => {
    const lines = await immLines(p);
    p.assert.ok(lines.some((l) => /^Syntax error: .*\(E2E\.BAS:3\)$/.test(l.text) && /\berr\b/.test(l.cls)), JSON.stringify(lines.slice(-3)));
  });
  t.test('compile error: a "Syntax error:" toast is shown', async (p) => {
    await p.runProgram(SYN_PROG, { wait: false });
    await p.waitToast(/Syntax error: Expected: expression/);
  });
  t.test('compile error: nothing from the program runs', async (p) => {
    await p.runProgram('PRINT "SHOULDNOT"\nIF THEN', { wait: false });
    await p.sleep(150);
    p.assert.doesNotMatch(await p.screen(), /SHOULDNOT/);
  });
  t.test('fixing a compile error and running again clears markers and problems', async (p) => {
    await p.runProgram(SYN_PROG, { wait: false });
    await p.sleep(80);
    p.assert.equal(await errLine(p), 2);
    await p.setCode('PRINT "OK"\n\nx = 2\nPRINT "MORE"');
    await p.key('F5');
    await p.waitState('ended');
    p.assert.equal(await errLine(p), null);
    p.assert.equal(await probCount(p), '');
    p.assert.equal((await msgSeg(p)).err, false);
    p.assert.match(await p.screen(), /OK[\s\S]*MORE/);
  });
  t.test('compile error in an $INCLUDE file opens that file at the error', async (p) => {
    await p.newFile('C:\\MYPROGS\\INC.BI', "x = 1\ny = = 3\n");
    await p.runProgram("'$INCLUDE: 'INC.BI'\nPRINT x", { wait: false });
    await p.sleep(150);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\INC.BI');
    p.assert.equal(await errLine(p), 1);
    p.assert.match((await msgSeg(p)).text, /\(INC\.BI:2\)$/);
  });

  // ---- INPUT ----------------------------------------------------------------------------------------------
  const INPUT_PROG = 'INPUT "Your name"; n$\nPRINT "Hello, "; n$';
  const focusInfo = (p) => p.ev("(document.activeElement && (document.activeElement.id || document.activeElement.className)) + ' hasFocus=' + document.hasFocus() + ' state=' + RC.app.runner.state");
  t.test('INPUT: program waits with the prompt and the screen gets focus', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    await p.waitScreen(/Your name\?/);
    p.assert.equal(await p.focusedId(), 'screen');
    p.assert.equal(await p.ev("document.getElementById('screenFrame').classList.contains('focused')"), true);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), false, 'hint hidden while focused');
  });
  t.test('INPUT: clicking the editor blurs the screen and shows the click-to-type hint', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    await clickEditor(p);
    await p.wait("document.activeElement === RC.app.active.editor.ta", 3000);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), true);
    p.assert.equal(await p.text('#screenHint'), 'Click the screen to type into your program');
    p.assert.equal(await p.ev("document.getElementById('screenFrame').classList.contains('focused')"), false);
  });
  t.test('INPUT: typing in the editor does not feed the program', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    await clickEditor(p);
    await p.wait("document.activeElement === RC.app.active.editor.ta", 3000);
    const before = await p.code();
    await p.type('Q');
    p.assert.equal(await p.state(), 'waiting');
    p.assert.doesNotMatch(await p.screen(), /Your name\? Q/);
    p.assert.notEqual(await p.code(), before);
  });
  t.test('INPUT: clicking the screen after the editor focuses it again and hides the hint', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    await clickEditor(p);
    await p.wait("document.activeElement === RC.app.active.editor.ta", 3000);
    await p.sleep(200);
    await p.ev("window.__fl = []; for (const ev of ['focusin', 'focusout', 'mousedown', 'mouseup', 'click']) document.addEventListener(ev, e => __fl.push(ev + ':' + (e.target.id || e.target.className || e.target.tagName) + (e.relatedTarget ? '>' + (e.relatedTarget.id || e.relatedTarget.className || e.relatedTarget.tagName) : '') + '@' + Math.round(performance.now())), true); 0");
    await p.click('#screen');
    try { await p.wait("document.activeElement === document.getElementById('screen')", 3000); } catch (e) { throw new Error('screen not focused after click: ' + await focusInfo(p) + ' ' + JSON.stringify(await p.ev('__fl'))); }
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), false);
    p.assert.equal(await p.ev("document.getElementById('screenFrame').classList.contains('focused')"), true);
  });
  t.test('INPUT: typed keys go to the program and Enter completes it', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    p.assert.equal(await p.focusedId(), 'screen');
    await p.type('Ada\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /Your name\? Ada\nHello, Ada/);
  });
  t.test('hint is not shown when the screen loses focus after the program ended', async (p) => {
    await p.ev("document.getElementById('screen').focus()");
    await clickEditor(p);
    await p.sleep(80);
    p.assert.equal(await p.ev("document.getElementById('screenHint').classList.contains('show')"), false);
  });
  t.test('Stop while waiting for INPUT ends the program', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    await p.click('#tbStop');
    p.assert.equal(await p.state(), 'ended');
    p.assert.doesNotMatch(await p.screen(), /Hello/);
  });
  t.test('Pause while waiting for INPUT, then Continue returns to waiting', async (p) => {
    await p.runProgram(INPUT_PROG, { wait: false });
    await p.waitState('waiting');
    await p.click('#tbPause');
    await p.waitState('paused');
    p.assert.equal(await p.text('#tbRun .lbl'), 'Continue');
    await p.click('#tbRun');
    await p.waitState('waiting');
    await p.click('#screen');
    await p.wait("document.activeElement === document.getElementById('screen')", 3000);
    await p.type('Bo\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /Hello, Bo/);
  });
  t.test('INPUT of a number: program continues with the value', async (p) => {
    await p.runProgram('INPUT n\nPRINT n * 3', { wait: false });
    await p.waitState('waiting');
    await p.type('14\n');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /^ 42\s*$/m);
  });

  // ---- tabs while running ------------------------------------------------------------------------------
  t.test('the program keeps running while switching editor tabs', async (p) => {
    await toRunning(p);
    await p.click('#editorTabs .tab', 'HELLO.BAS');
    const a = await p.ev('RC.app.runner.vm.statementsExecuted');
    await p.sleep(150);
    p.assert.equal(await p.state(), 'running');
    p.assert.ok(await p.ev('RC.app.runner.vm.statementsExecuted') > a);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
    p.assert.equal(await p.text('#tbState'), 'Running');
  });
  t.test('opening another file while running keeps the program running', async (p) => {
    await toRunning(p);
    await p.newFile('C:\\MYPROGS\\SIDE.BAS', 'PRINT "SIDE"');
    await p.sleep(100);
    p.assert.equal(await p.state(), 'running');
    p.assert.equal(await p.ev('RC.app.runner.mainPath'), 'C:\\MYPROGS\\E2E.BAS');
  });
  t.test('switching bottom panels while running keeps the program running', async (p) => {
    await toRunning(p);
    for (const id of ['vars', 'watch', 'stack', 'bps', 'history', 'printer', 'problems', 'immediate']) await p.click(`#bottomTabs .tab[data-id=${id}]`);
    p.assert.equal(await p.state(), 'running');
  });
  t.test('pausing after switching tabs brings the running file back with the exec line', async (p) => {
    await toRunning(p);
    await p.click('#editorTabs .tab', 'HELLO.BAS');
    await p.click('#tbPause');
    await p.waitState('paused');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\E2E.BAS');
    p.assert.notEqual(await p.ev('RC.app.active.editor.marks.exec'), null);
  });
  t.test('Run with another tab active runs that file', async (p) => {
    await p.newFile('C:\\MYPROGS\\SIDE.BAS', 'PRINT "SIDE RAN"');
    await p.click('#tbRun');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /SIDE RAN/);
    p.assert.equal(await p.ev('RC.app.runner.mainPath'), 'C:\\MYPROGS\\SIDE.BAS');
  });

  // ---- responsiveness ----------------------------------------------------------------------------------
  t.test('a tight infinite loop keeps the page responsive', async (p) => {
    await toRunning(p);
    const lat = [];
    for (let i = 0; i < 5; i++) { const t0 = Date.now(); await p.ev('1 + 1'); lat.push(Date.now() - t0); }
    p.assert.ok(Math.max(...lat) < 400, 'eval latencies ' + lat.join(','));
    p.assert.equal(await p.state(), 'running');
  });
  t.test('a very long FOR loop can be paused with the Pause button promptly', async (p) => {
    await toRunning(p, 'FOR i& = 1 TO 2000000000\n  s# = s# + i&\nNEXT');
    await p.sleep(200);
    const t0 = Date.now();
    await p.click('#tbPause');
    await p.waitState('paused', 2000);
    p.assert.ok(Date.now() - t0 < 1500, 'paused in ' + (Date.now() - t0) + 'ms');
    const i = await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i&', 0).value");
    p.assert.ok(i > 1 && i < 2000000000, 'loop counter ' + i);
    // Continue resumes from where it was
    const i1 = await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i&', 0).value");
    await p.click('#tbRun');
    await p.sleep(150);
    await p.click('#tbPause');
    await p.waitState('paused');
    const i2 = await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'i&', 0).value");
    p.assert.ok(i2 > i1, `${i2} > ${i1}`);
  });
  t.test('a GOTO loop in a numbered program can be stopped with Ctrl+F2', async (p) => {
    await toRunning(p, '10 A = A + 1\n20 GOTO 10');
    await p.ev('RC.app.active.editor.ta.focus()');
    await p.key('F2', { ctrl: true });
    await p.waitState('ended', 2000);
  });
  t.test('a busy PRINT loop is responsive and pausable', async (p) => {
    await toRunning(p, 'DO\n  PRINT i;\n  i = i + 1\nLOOP');
    const t0 = Date.now();
    await p.click('#tbPause');
    await p.waitState('paused', 2000);
    p.assert.ok(Date.now() - t0 < 1500);
  });

  // ---- speed presets -----------------------------------------------------------------------------------------
  // The loop body "x = x + 1" + "LOOP" is two statements per iteration, so x advances at speed / 2 per second.
  // Progress is measured through the program's own variable, not just the VM's statement counter.
  const pick = (p, v) => p.fn((v) => { const s = document.getElementById('tbSpeed'); s.value = v; s.dispatchEvent(new Event('change')); }, String(v));
  t.test('Full speed: the loop advances millions of iterations per second', async (p) => {
    await pick(p, 0);
    await toRunning(p);
    const r = await xRate(p, 500);
    p.assert.ok(r > 500000, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('"Fast PC (≈ 486)": about 400000 statements/s (x ≈ 200000/s)', async (p) => {
    await pick(p, 400000);
    await toRunning(p);
    await p.sleep(200);
    const r = await xRate(p, 1000);
    p.assert.ok(r >= 100000 && r <= 230000, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('"Classic PC (≈ 8 MHz 286)": about 25000 statements/s (x ≈ 12500/s)', async (p) => {
    await pick(p, 25000);
    await toRunning(p);
    await p.sleep(200);
    const r = await xRate(p, 1000);
    p.assert.ok(r >= 8000 && r <= 14500, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('"Original IBM PC (≈ 4.77 MHz)": about 4000 statements/s (x ≈ 2000/s)', async (p) => {
    await pick(p, 4000);
    await toRunning(p);
    await p.sleep(200);
    const r = await xRate(p, 1000);
    p.assert.ok(r >= 1300 && r <= 2400, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('"Original IBM PC": the status-bar statement counter also grows at about 4000/s', async (p) => {
    await pick(p, 4000);
    await toRunning(p);
    await p.sleep(200);
    const r = await rate(p, 1000);
    p.assert.ok(r >= 2600 && r <= 4800, 'stmt rate ' + r);
  }, { timeout: 15000 });
  t.test('"Slow motion (20 statements/s)": the program really advances about 10 loop iterations per second', async (p) => {
    await pick(p, 20);
    await toRunning(p);
    await p.sleep(300);
    const r = await xRate(p, 2000);
    p.assert.ok(r >= 6 && r <= 14, 'x rate ' + r + ' (statement counter rate ' + (await rate(p, 500)) + ')');
  }, { timeout: 15000 });
  t.test('"Step-by-step crawl (3 statements/s)": the program advances about 1.5 loop iterations per second', async (p) => {
    await pick(p, 3);
    await toRunning(p);
    await p.sleep(300);
    const r = await xRate(p, 3000);
    p.assert.ok(r >= 0.6 && r <= 2.5, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('slow motion throttles the statement counter to about 20 statements per second', async (p) => {
    await pick(p, 20);
    await toRunning(p);
    await p.sleep(300);
    const r = await rate(p, 2000);
    p.assert.ok(r >= 12 && r <= 30, 'stmt rate ' + r);
  }, { timeout: 15000 });
  t.test('slow motion makes PRINT output appear gradually', async (p) => {
    await pick(p, 20);
    await p.runProgram('FOR i = 1 TO 40\n  PRINT i\nNEXT\nPRINT "ALLDONE"', { wait: false });
    await p.sleep(1000);
    p.assert.equal(await p.state(), 'running');
    const s = await p.screen();
    p.assert.match(s, /^ 1$/m);
    p.assert.doesNotMatch(s, /ALLDONE/);
    p.assert.doesNotMatch(s, /^ 30$/m);
  }, { timeout: 15000 });
  t.test('a throttled run completes a short program in the expected time', async (p) => {
    await pick(p, 4000);
    const t0 = Date.now();
    await p.runProgram('FOR i = 1 TO 1000\n  s = s + i\nNEXT\nPRINT s', { timeout: 8000 });
    const ms = Date.now() - t0;
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /500500/);
    p.assert.ok(ms >= 250 && ms < 3000, 'took ' + ms + 'ms for ~2000 statements at 4000/s');
  }, { timeout: 15000 });
  t.test('switching from a slow preset to full speed mid-run speeds it up', async (p) => {
    await pick(p, 4000);
    await toRunning(p);
    const slow = await xRate(p, 600);
    await pick(p, 0);
    const fast = await xRate(p, 400);
    p.assert.ok(slow < 3000 && fast > 100000, `slow ${slow}, fast ${fast}`);
  }, { timeout: 15000 });
  t.test('switching from full speed to a slow preset mid-run slows it down', async (p) => {
    await pick(p, 0);
    await toRunning(p);
    await pick(p, 4000);
    await p.sleep(150);
    const r = await xRate(p, 800);
    p.assert.ok(r >= 1300 && r <= 2400, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('throttle still applies after pause and continue', async (p) => {
    await pick(p, 4000);
    await toRunning(p);
    await p.click('#tbPause');
    await p.waitState('paused');
    await p.click('#tbRun');
    await p.sleep(200);
    const r = await xRate(p, 1000);
    p.assert.ok(r >= 1300 && r <= 2400, 'x rate ' + r);
  }, { timeout: 15000 });
  t.test('at the slowest speed the Pause button still works immediately', async (p) => {
    await pick(p, 3);
    await toRunning(p);
    await p.click('#tbPause');
    await p.waitState('paused', 1000);
    p.assert.equal(await p.text('#tbState'), 'Paused');
  });
  t.test('at a throttled speed Stop ends the program immediately', async (p) => {
    await pick(p, 4000);
    await toRunning(p);
    await p.click('#tbStop');
    p.assert.equal(await p.state(), 'ended');
    const x1 = await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'x', 0).value");
    await p.sleep(200);
    p.assert.equal(await p.ev("RC.Basic.Debug.evaluate(RC.app.runner.vm, 'x', 0).value"), x1);
  });
};
