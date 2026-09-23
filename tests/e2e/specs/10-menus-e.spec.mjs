// Menus part E: global keyboard shortcuts do what the menus say, and nothing in states where
// they should not act.
import { reset, prog, caret, pauseLine, setting, startLoop, pausedAtStart, STEPS, SUBPROG, LOOP } from './10-menus-helpers.mjs';

const isMax = (p) => p.ev("document.getElementById('app').classList.contains('screen-max')");
const focusEditor = (p) => p.ev('RC.app.active.editor.focus()');
const focusScreen = (p) => p.ev("document.getElementById('screen').focus()");
const bpLines = (p) => p.ev("(() => { const m = RC.app.breakpoints.get(RC.app.active.path); return m ? [...m.keys()].sort((a, b) => a - b) : []; })()");
const running = (p) => p.ev("['running', 'waiting'].includes(RC.app.runner.state)");
const closeAll = (p) => p.ev('(async () => { RC.app.settings.autosave = true; for (const d of RC.app.docs) d.dirty = false; while (RC.app.docs.length) await RC.app.closeDoc(RC.app.docs[0]); })()');

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- F1 / F2 / F4 ---------------------------------------------------------------------------------
  t.test('F1 outside the editor opens the Language Reference', async (p) => {
    await p.key('F1');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
  });
  t.test('F1 in the editor opens help for the keyword under the caret', async (p) => {
    await prog(p, 'CLS\nPRINT "x"\n');
    await caret(p, 1, 2);
    await p.key('F1');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    await p.wait("/^PRINT\\b/.test((document.querySelector('.help-main h2') || {}).innerText || '')", 2000);
  });
  t.test('F2 opens the SUBs list for the active program', async (p) => {
    await prog(p, SUBPROG);
    await p.key('F2');
    p.assert.equal(await p.waitModal(), 'SUBs');
    p.assert.match(await p.modalText(), /SUB Foo/);
  });
  t.test('F2 with no open file does nothing', async (p) => {
    await closeAll(p);
    await p.key('F2');
    await p.sleep(100);
    p.assert.equal(await p.modalOpen(), false);
  }, { fresh: true });
  t.test('F4 toggles the full-size output screen on and off', async (p) => {
    await p.key('F4');
    p.assert.equal(await isMax(p), true);
    p.assert.equal(await p.ev("document.activeElement.id"), 'screen');
    await p.key('F4');
    p.assert.equal(await isMax(p), false);
  });
  t.test('Escape leaves the full-size screen when no program is running', async (p) => {
    await p.key('F4');
    p.assert.equal(await isMax(p), true);
    await p.key('Escape');
    p.assert.equal(await isMax(p), false);
  });

  // ---- F5 / Shift+F5 / Ctrl+F2 / Ctrl+Break ----------------------------------------------------------
  t.test('F5 runs the program in the editor', async (p) => {
    await prog(p, 'PRINT "F5 RUN"; 2 + 3\n');
    await focusEditor(p);
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /F5 RUN 5/);
  });
  t.test('F5 works from the Immediate input too', async (p) => {
    await prog(p, 'PRINT "FROM IMM"\n');
    await p.panel('immediate');
    await p.ev("document.querySelector('.imm-input input').focus()");
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /FROM IMM/);
  });
  t.test('F5 continues a paused program', async (p) => {
    await pausedAtStart(p);
    await focusEditor(p);
    await p.key('F5');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\b6\b/);
  });
  t.test('F5 while a program is running does nothing (no restart) with the editor focused', async (p) => {
    await startLoop(p);
    const n = await p.ev('RC.app.runCount');
    await focusEditor(p);
    await p.key('F5');
    await p.sleep(100);
    p.assert.equal(await p.ev('RC.app.runCount'), n);
    p.assert.equal(await running(p), true);
  });
  t.test('F5 while a program is running with the screen focused goes to the program, not the IDE', async (p) => {
    await startLoop(p);
    const n = await p.ev('RC.app.runCount');
    await focusScreen(p);
    await p.key('F5');
    await p.sleep(100);
    p.assert.equal(await p.ev('RC.app.runCount'), n);
    p.assert.equal(await running(p), true);
  });
  t.test('F5 with no open file shows a toast and runs nothing', async (p) => {
    await closeAll(p);
    await p.key('F5');
    await p.waitToast(/Open or create a program first/);
    p.assert.equal(await p.ev('RC.app.runner.vm ? RC.app.runner.state : "idle"'), 'idle');
  }, { fresh: true });
  t.test('Shift+F5 restarts a running program', async (p) => {
    await startLoop(p);
    const n = await p.ev('RC.app.runCount');
    await focusEditor(p);
    await p.key('F5', { shift: true });
    await p.waitState(['running', 'waiting']);
    p.assert.equal(await p.ev('RC.app.runCount'), n + 1);
  });
  t.test('Shift+F5 restarts a paused program from the top', async (p) => {
    await pausedAtStart(p);
    await p.ev("RC.app.step('into')");
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.framePos(0).line === 1");
    await focusEditor(p);
    await p.key('F5', { shift: true });
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\b6\b/);
  });
  t.test('Ctrl+F2 stops a running program (editor focused)', async (p) => {
    await startLoop(p);
    await focusEditor(p);
    await p.key('F2', { ctrl: true });
    await p.wait("!['running','waiting','paused'].includes(RC.app.runner.state)", 2000);
    p.assert.match(await p.status(), /Stopped/);
    p.assert.equal(await p.modalOpen(), false, 'Ctrl+F2 must not open the SUBs list');
  });
  t.test('Ctrl+F2 stops a paused program', async (p) => {
    await pausedAtStart(p);
    await focusEditor(p);
    await p.key('F2', { ctrl: true });
    await p.wait("!['running','waiting','paused'].includes(RC.app.runner.state)", 2000);
  });
  t.test('Ctrl+F2 when idle does not open the SUBs list', async (p) => {
    await prog(p, SUBPROG);
    await focusEditor(p);
    await p.key('F2', { ctrl: true });
    await p.sleep(100);
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('Ctrl+Break pauses a running program with the screen focused', async (p) => {
    await startLoop(p);
    await focusScreen(p);
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused');
  });
  t.test('Ctrl+Break pauses a running program with the editor focused', async (p) => {
    await startLoop(p);
    await focusEditor(p);
    await p.key('Pause', { ctrl: true });
    await p.waitState('paused');
    p.assert.equal(await p.text('#tbState'), 'Paused');
  });
  t.test('Ctrl+C on the output screen pauses a running program', async (p) => {
    await startLoop(p);
    await focusScreen(p);
    await p.key('c', { ctrl: true });
    await p.waitState('paused');
  });
  t.test('Ctrl+Break when nothing is running changes nothing', async (p) => {
    await p.runProgram('PRINT 1');
    await p.key('Pause', { ctrl: true });
    await p.sleep(80);
    p.assert.equal(await p.state(), 'ended');
  });

  // ---- F7 / F8 / F9 / F10 / F11 ------------------------------------------------------------------------
  t.test('F7 runs to the caret line', async (p) => {
    await prog(p, STEPS);
    await caret(p, 2);
    await p.key('F7');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 2);
  });
  t.test('F7 while paused continues to the caret line', async (p) => {
    await pausedAtStart(p);
    await caret(p, 3);
    await p.key('F7');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.framePos(RC.app.runner.vm.frames.length - 1).line === 3", 3000);
  });
  t.test('F7 while running does nothing', async (p) => {
    await startLoop(p);
    const n = await p.ev('RC.app.runCount');
    await caret(p, 1);
    await p.key('F7');
    await p.sleep(100);
    p.assert.equal(await running(p), true);
    p.assert.equal(await p.ev('RC.app.runCount'), n);
  });
  t.test('F8 from idle starts the program paused at the first statement', async (p) => {
    await prog(p, STEPS);
    await focusEditor(p);
    await p.key('F8');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 0);
  });
  t.test('F8 while paused steps one statement', async (p) => {
    await pausedAtStart(p);
    await focusEditor(p);
    await p.key('F8');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.framePos(0).line === 1", 3000);
    await p.key('F8');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.framePos(0).line === 2", 3000);
  });
  t.test('F8 steps into a SUB', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await focusEditor(p);
    await p.key('F8');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 2", 3000);
  });
  t.test('Shift+F8 steps out of a SUB', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await p.ev("RC.app.step('into')");
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 2", 3000);
    await focusEditor(p);
    await p.key('F8', { shift: true });
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 1", 3000);
  });
  t.test('Shift+F8 when idle does nothing (does not start a run)', async (p) => {
    await prog(p, STEPS);
    const n = await p.ev('RC.app.runCount || 0');
    await focusEditor(p);
    await p.key('F8', { shift: true });
    await p.sleep(100);
    p.assert.equal(await p.ev('RC.app.runCount || 0'), n);
    p.assert.notEqual(await p.state(), 'paused');
  });
  t.test('F10 steps over a SUB call', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await focusEditor(p);
    await p.key('F10');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 1 && RC.app.runner.vm.framePos(0).line === 1", 3000);
  });
  t.test('F10 from idle starts the program paused at the first statement', async (p) => {
    await prog(p, STEPS);
    await focusEditor(p);
    await p.key('F10');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 0);
  });
  t.test('F11 steps into like F8', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await focusEditor(p);
    await p.key('F11');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 2", 3000);
  });
  t.test('Shift+F11 steps out like Shift+F8', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await p.ev("RC.app.step('into')");
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 2", 3000);
    await focusEditor(p);
    await p.key('F11', { shift: true });
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 1", 3000);
  });
  t.test('step keys while running do nothing', async (p) => {
    await startLoop(p);
    await focusEditor(p);
    await p.key('F8');
    await p.key('F10');
    await p.sleep(100);
    p.assert.equal(await running(p), true);
  });
  t.test('F9 toggles a breakpoint at the caret line', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\F9.BAS');
    await caret(p, 1);
    await p.key('F9');
    p.assert.deepEqual(await bpLines(p), [1]);
    await p.wait("[...RC.app.active.editor.inner.querySelectorAll('.ed-gl.bp')].map(e => e.textContent).join() === '2'", 2000);
    await p.key('F9');
    p.assert.deepEqual(await bpLines(p), []);
    await p.wait("RC.app.active.editor.inner.querySelectorAll('.ed-gl.bp').length === 0", 2000);
  });
  t.test('F9 then F5 stops at the breakpoint', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\F9B.BAS');
    await caret(p, 2);
    await p.key('F9');
    await p.key('F5');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 2);
    await p.ev('RC.app.stop(); RC.app.clearBreakpoints()');
  });

  // ---- file shortcuts ---------------------------------------------------------------------------------------
  t.test('Ctrl+S saves the active file', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\CTRLS.BAS');
    await p.setCode('PRINT "CTRL S"\n');
    await p.key('s', { ctrl: true });
    await p.wait('RC.app.active.dirty === false', 2000);
    p.assert.match(await p.ev("RC.app.decodeText(RC.app.vfs.readFile('C:\\\\MYPROGS\\\\CTRLS.BAS'))"), /CTRL S/);
    p.assert.equal(await p.code(), 'PRINT "CTRL S"\n');
  });
  t.test('Ctrl+S on an example file asks to save your own copy', async (p) => {
    await p.ev("RC.app.openFile('C:\\\\SAMPLES\\\\FACTORL.BAS')");
    await p.wait("RC.app.active && /FACTORL/.test(RC.app.active.path)");
    await focusEditor(p);
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
  });
  t.test('Ctrl+Shift+S opens Save As', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\CSS.BAS');
    await focusEditor(p);
    await p.key('s', { ctrl: true, shift: true });
    p.assert.equal(await p.waitModal(), 'Save As');
    p.assert.equal(await p.ev("document.querySelector('.modal input').value"), 'C:\\MYPROGS\\CSS.BAS');
  });
  t.test('Ctrl+S and Ctrl+Shift+S with no open file do nothing', async (p) => {
    await closeAll(p);
    await p.key('s', { ctrl: true });
    await p.key('s', { ctrl: true, shift: true });
    await p.sleep(100);
    p.assert.equal(await p.modalOpen(), false);
  }, { fresh: true });
  t.test('Ctrl+O opens the Open File dialog', async (p) => {
    await p.key('o', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Open File');
  });
  t.test('Alt+N starts a new program', async (p) => {
    await p.key('n', { alt: true });
    p.assert.equal(await p.waitModal(), 'New Program');
    p.assert.match(await p.ev("document.querySelector('.modal input').value"), /^UNTITLED\d*\.BAS$/);
    p.assert.equal(await p.count('.menu-pop'), 0);
  });
  t.test('Alt+W closes the active tab', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\ALTW.BAS');
    const n = await p.ev('RC.app.docs.length');
    await p.key('w', { alt: true });
    await p.wait(`RC.app.docs.length === ${n - 1}`, 2000);
    p.assert.notEqual(await p.activePath(), 'C:\\MYPROGS\\ALTW.BAS');
  });
  t.test('Alt+W on a changed file asks before closing', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\ALTW2.BAS');
    await p.setCode('PRINT 9\n');
    await p.ev('RC.app.settings.autosave = false');
    await p.key('w', { alt: true });
    p.assert.equal(await p.waitModal(), 'Unsaved changes');
    await p.modalButton('Cancel');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\ALTW2.BAS');
    await p.ev('RC.app.settings.autosave = true');
  });
  t.test('Alt+W with no open tabs does nothing', async (p) => {
    await closeAll(p);
    await p.key('w', { alt: true });
    await p.sleep(80);
    p.assert.equal(await p.ev('RC.app.docs.length'), 0);
    p.assert.equal(await p.modalOpen(), false);
  }, { fresh: true });

  // ---- zoom --------------------------------------------------------------------------------------------
  t.test('Ctrl+= zooms in and Ctrl+- zooms out', async (p) => {
    const f = await setting(p, 'fontSize');
    await p.key('=', { ctrl: true });
    p.assert.equal(await setting(p, 'fontSize'), f + 1);
    await p.key('-', { ctrl: true });
    await p.key('-', { ctrl: true });
    p.assert.equal(await setting(p, 'fontSize'), f - 1);
    p.assert.equal(await p.ev("document.documentElement.style.getPropertyValue('--ed-font-size')"), (f - 1) + 'px');
  }, { fresh: true });
  t.test('Ctrl++ also zooms in', async (p) => {
    const f = await setting(p, 'fontSize');
    await p.key('+', { ctrl: true });
    p.assert.equal(await setting(p, 'fontSize'), f + 1);
  }, { fresh: true });
  t.test('zoom shortcuts work while the editor has focus', async (p) => {
    await prog(p, 'PRINT 1\n');
    await focusEditor(p);
    const f = await setting(p, 'fontSize');
    const code = await p.code();
    await p.key('=', { ctrl: true });
    p.assert.equal(await setting(p, 'fontSize'), f + 1);
    p.assert.equal(await p.code(), code);
  }, { fresh: true });

  // ---- shortcuts are inert while a dialog is open ------------------------------------------------------
  t.test('F5 does nothing while a dialog is open', async (p) => {
    await prog(p, 'PRINT "NO"\n');
    const n = await p.ev('RC.app.runCount || 0');
    await p.ev('RC.app.aboutDialog()');
    await p.waitModal();
    await p.key('F5');
    await p.sleep(100);
    p.assert.equal(await p.ev('RC.app.runCount || 0'), n);
  });
  t.test('Alt+letter does not open a menu while a dialog is open', async (p) => {
    await p.ev('RC.app.aboutDialog()');
    await p.waitModal();
    await p.key('f', { alt: true });
    await p.sleep(80);
    p.assert.equal(await p.count('.menu-pop'), 0);
  });
  t.test('Ctrl+S does not save while a dialog is open', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\MODS.BAS');
    await p.setCode('PRINT 2\n');
    await p.ev('RC.app.settings.autosave = false; RC.app.shortcutsDialog()');
    await p.waitModal();
    await p.key('s', { ctrl: true });
    await p.sleep(80);
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    await p.key('Escape');
    await p.ev('RC.app.settings.autosave = true');
  });
  t.test('F4 and F9 do nothing while a dialog is open', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\MODF.BAS');
    await p.ev('RC.app.active.editor.setCursor(1, 0); RC.app.aboutDialog()');
    await p.waitModal();
    await p.key('F4');
    await p.key('F9');
    await p.sleep(80);
    p.assert.equal(await isMax(p), false);
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('shortcuts work again after the dialog is closed with Escape', async (p) => {
    await p.ev('RC.app.aboutDialog()');
    await p.waitModal();
    await p.key('Escape');
    await p.waitGone('.modal-back');
    await p.key('F4');
    p.assert.equal(await isMax(p), true);
  });

  // ---- shortcut and menu agree ---------------------------------------------------------------------------
  t.test('Alt+R then Enter (Start) runs the program like F5', async (p) => {
    await prog(p, 'PRINT "ALT R"\n');
    await p.key('r', { alt: true });
    await p.wait("!!document.querySelector('.menu-pop')", 2000);
    await p.key('Enter');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /ALT R/);
  });
  t.test('Alt+D, Enter (Step Into) pauses on the first statement like F8', async (p) => {
    await prog(p, LOOP);
    await p.key('d', { alt: true });
    await p.wait("!!document.querySelector('.menu-pop')", 2000);
    await p.key('Enter');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 0);
  });
};
