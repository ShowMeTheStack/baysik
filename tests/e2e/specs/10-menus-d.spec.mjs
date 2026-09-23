// Menus part D: Debug, Options and Help menu actions, and persistence of menu-chosen settings.
import { reset, pick, pickSub, openTop, subDetails, item, checkedLabels, prog, caret, pauseLine, activePanel, setting, pausedAtStart, SUBPROG, STEPS } from './10-menus-helpers.mjs';

const bpLines = (p) => p.ev("(() => { const m = RC.app.breakpoints.get(RC.app.active.path); return m ? [...m.keys()].sort((a, b) => a - b) : []; })()");
const theme = (p) => p.ev('document.documentElement.dataset.theme');
const bodyBg = (p) => p.ev('getComputedStyle(document.body).backgroundColor');

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- Debug -------------------------------------------------------------------------------------------
  t.test('Debug ▸ Step Into from idle starts the program paused on its first statement', async (p) => {
    await prog(p, STEPS);
    await pick(p, 'Debug', 'Step Into');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 0);
  });
  t.test('Debug ▸ Step Into while paused advances one statement', async (p) => {
    await pausedAtStart(p);
    await pick(p, 'Debug', 'Step Into');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.framePos(RC.app.runner.vm.frames.length - 1).line === 1", 3000);
  });
  t.test('Debug ▸ Step Into enters a SUB', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await pick(p, 'Debug', 'Step Into');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 2", 3000);
    p.assert.equal(await pauseLine(p), 4);
  });
  t.test('Debug ▸ Step Over runs a SUB call as one step', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await pick(p, 'Debug', 'Step Over');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.framePos(RC.app.runner.vm.frames.length - 1).line === 1", 3000);
    p.assert.equal(await p.ev('RC.app.runner.vm.frames.length'), 1);
  });
  t.test('Debug ▸ Step Out returns from a SUB to the caller', async (p) => {
    await pausedAtStart(p, SUBPROG);
    await p.ev("RC.app.step('into')");
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 2", 3000);
    await pick(p, 'Debug', 'Step Out');
    await p.wait("RC.app.runner.state === 'paused' && RC.app.runner.vm.frames.length === 1", 3000);
    p.assert.ok((await pauseLine(p)) <= 2);
  });
  t.test('Debug ▸ Toggle Breakpoint adds then removes a breakpoint at the caret line', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\BPT.BAS');
    await caret(p, 2);
    await pick(p, 'Debug', 'Toggle Breakpoint');
    p.assert.deepEqual(await bpLines(p), [2]);
    p.assert.ok(await p.count('#bottomTabs .tab[data-id="bps"] .count') === 1);
    await caret(p, 2);
    await pick(p, 'Debug', 'Toggle Breakpoint');
    p.assert.deepEqual(await bpLines(p), []);
  });
  t.test('a breakpoint set from the Debug menu pauses the run there', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\BPT2.BAS');
    await caret(p, 3);
    await pick(p, 'Debug', 'Toggle Breakpoint');
    await pick(p, 'Run', 'Start');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 3);
    await p.ev('RC.app.stop(); RC.app.clearBreakpoints()');
  });
  t.test('Debug ▸ Conditional Breakpoint… stores the condition for the caret line', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\BPC.BAS');
    await caret(p, 1);
    await pick(p, 'Debug', 'Conditional Breakpoint…');
    p.assert.equal(await p.waitModal(), 'Conditional Breakpoint');
    p.assert.match(await p.modalText(), /Stop at line 2 only when this is true/);
    await p.modalInput('a = 1');
    await p.modalButton('OK');
    p.assert.equal(await p.ev("RC.app.breakpoints.get(RC.app.active.path).get(1).cond"), 'a = 1');
    await p.ev('RC.app.clearBreakpoints()');
  });
  t.test('Debug ▸ Clear All Breakpoints removes breakpoints in every file', async (p) => {
    await prog(p, STEPS, 'C:\\MYPROGS\\BPA.BAS');
    await p.ev('RC.app.toggleBreakpoint(RC.app.active.path, 0); RC.app.toggleBreakpoint(RC.app.active.path, 2); RC.app.toggleBreakpoint("C:\\\\MYPROGS\\\\HELLO.BAS", 1)');
    p.assert.equal(await p.ev('RC.app.breakpointCount()'), 3);
    await pick(p, 'Debug', 'Clear All Breakpoints');
    p.assert.equal(await p.ev('RC.app.breakpointCount()'), 0);
    p.assert.equal(await p.count('#bottomTabs .tab[data-id="bps"] .count'), 0);
  });
  t.test('Debug ▸ Add Watch… adds the expression and shows the Watch panel', async (p) => {
    await pick(p, 'Debug', 'Add Watch…');
    p.assert.equal(await p.waitModal(), 'Add Watch');
    await p.modalInput('menuW + 1');
    await p.modalButton('OK');
    p.assert.equal(await activePanel(p), 'watch');
    p.assert.equal(await p.ev("RC.app.panels.watches.some(w => (w.expr || w) === 'menuW + 1')"), true);
    p.assert.match(await p.panelText(), /menuW \+ 1/);
  });
  t.test('Debug ▸ Add Watch… with an empty expression adds nothing', async (p) => {
    const n = await p.ev('RC.app.panels.watches.length');
    await pick(p, 'Debug', 'Add Watch…');
    await p.waitModal();
    await p.modalButton('OK');
    p.assert.equal(await p.ev('RC.app.panels.watches.length'), n);
  });
  t.test('Debug ▸ Animate Execution turns tracing on (switching to slow motion) and off again', async (p) => {
    await p.ev('RC.app.setSpeed(0)');
    await pick(p, 'Debug', 'Animate Execution (Trace)');
    p.assert.equal(await p.ev('RC.app.runner.animate'), true);
    p.assert.equal(await setting(p, 'speed'), 20);
    p.assert.equal(await p.ev("document.getElementById('tbSpeed').value"), '20');
    await pick(p, 'Debug', 'Animate Execution (Trace)');
    p.assert.equal(await p.ev('RC.app.runner.animate'), false);
    await p.ev('RC.app.setSpeed(0)');
  });
  t.test('Debug ▸ TRON runs TRON in the Immediate window', async (p) => {
    await p.panel('immediate');
    await pick(p, 'Debug', 'TRON (print line numbers)');
    await p.wait("/> TRON/.test(document.querySelector('.imm-log').innerText)", 3000);
    await p.ev("RC.app.immediate('TROFF')");
  });

  // ---- Options -----------------------------------------------------------------------------------------
  for (const [label, v] of [['Dark', 'dark'], ['Light', 'light'], ['Amber Monitor', 'amber'], ['Match System', 'auto'], ['QBasic Blue', 'qbasic']]) {
    t.test(`Options ▸ Theme ▸ ${label} applies data-theme="${v}" and saves it`, async (p) => {
      await pickSub(p, 'Options', 'Theme', label);
      p.assert.equal(await theme(p), v);
      p.assert.equal(await setting(p, 'theme'), v);
      p.assert.equal(await p.ev("JSON.parse(localStorage.getItem('baysik.settings')).theme"), v);
      const d = await subDetails(p, 'Options', 'Theme');
      p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), [label]);
    });
  }
  t.test('Dark and Light themes really change the page colors', async (p) => {
    await pickSub(p, 'Options', 'Theme', 'Dark');
    const dark = await bodyBg(p);
    await pickSub(p, 'Options', 'Theme', 'Light');
    const light = await bodyBg(p);
    p.assert.notEqual(dark, light);
    await pickSub(p, 'Options', 'Theme', 'QBasic Blue');
  });
  t.test('Options ▸ Editor Font Size… sets the editor font size', async (p) => {
    await pick(p, 'Options', 'Editor Font Size…');
    p.assert.equal(await p.waitModal(), 'Editor Font Size');
    p.assert.equal(await p.ev("document.querySelector('.modal input').value"), String(await setting(p, 'fontSize')));
    await p.modalInput('21');
    await p.modalButton('OK');
    p.assert.equal(await setting(p, 'fontSize'), 21);
    p.assert.equal(await p.ev("document.documentElement.style.getPropertyValue('--ed-font-size')"), '21px');
  }, { fresh: true });
  t.test('Options ▸ Editor Font Size… ignores an out-of-range size', async (p) => {
    const f = await setting(p, 'fontSize');
    await pick(p, 'Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('40');
    await p.modalButton('OK');
    p.assert.equal(await setting(p, 'fontSize'), f);
  });
  for (const n of [2, 8, 4]) {
    t.test(`Options ▸ Tab Width ▸ ${n} spaces makes Tab insert ${n} spaces`, async (p) => {
      await pickSub(p, 'Options', 'Tab Width', n + ' spaces');
      p.assert.equal(await setting(p, 'tabSize'), n);
      await prog(p, 'x\n');
      await caret(p, 0, 0);
      await p.key('Tab');
      p.assert.equal(await p.ev('RC.app.active.editor.getLine(0)'), ' '.repeat(n) + 'x');
    });
  }
  t.test('Options ▸ Capitalize Keywords As You Type off keeps typed keywords lowercase', async (p) => {
    await pick(p, 'Options', 'Capitalize Keywords As You Type');
    p.assert.equal(await setting(p, 'autoFormat'), false);
    await prog(p, '');
    await caret(p, 0, 0);
    await p.type('print 1\n');
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(0)'), 'print 1');
    await pick(p, 'Options', 'Capitalize Keywords As You Type');
    p.assert.equal(await setting(p, 'autoFormat'), true);
    await caret(p, 1, 0);
    await p.type('print 2\n');
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(1)'), 'PRINT 2');
  }, { fresh: true });
  t.test('Options ▸ Auto Indent off stops indenting after FOR', async (p) => {
    await prog(p, '');
    await caret(p, 0, 0);
    await p.type('FOR i = 1 TO 2\n');
    p.assert.match(await p.ev('RC.app.active.editor.getLine(1)'), /^ {4}$/);
    await pick(p, 'Options', 'Auto Indent');
    p.assert.equal(await setting(p, 'autoIndent'), false);
    await prog(p, '', 'C:\\MYPROGS\\IND2.BAS');
    await caret(p, 0, 0);
    await p.type('FOR i = 1 TO 2\n');
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(1)'), '');
  }, { fresh: true });
  t.test('Options ▸ Autosave off stops the periodic autosave', async (p) => {
    await pick(p, 'Options', 'Autosave');
    p.assert.equal(await setting(p, 'autosave'), false);
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\AUTOS.BAS');
    await p.setCode('PRINT 2\n');
    await p.ev('RC.app.autosaveTick()');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    await pick(p, 'Options', 'Autosave');
    p.assert.equal(await setting(p, 'autosave'), true);
    await p.ev('RC.app.autosaveTick()');
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
  }, { fresh: true });
  t.test('Options ▸ CRT Scanlines turns the scanline overlay on and off', async (p) => {
    await pick(p, 'Options', 'CRT Scanlines');
    p.assert.equal(await setting(p, 'crt'), true);
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), true);
    p.assert.equal(await p.visible('#crt'), true);
    await pick(p, 'Options', 'CRT Scanlines');
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), false);
  }, { fresh: true });
  t.test('Options ▸ Sound mutes and unmutes the audio', async (p) => {
    await pick(p, 'Options', 'Sound');
    p.assert.equal(await setting(p, 'sound'), false);
    p.assert.equal(await p.ev('RC.app.runner.audio.volume'), 0);
    await pick(p, 'Options', 'Sound');
    p.assert.equal(await setting(p, 'sound'), true);
    p.assert.ok(Math.abs(await p.ev('RC.app.runner.audio.volume') - 0.5 * 0.16) < 1e-9);
  }, { fresh: true });
  for (const [label, v] of [['25%', 0.25], ['75%', 0.75], ['100%', 1], ['50%', 0.5]]) {
    t.test(`Options ▸ Volume ▸ ${label} sets the volume and audio gain`, async (p) => {
      await pickSub(p, 'Options', 'Volume', label);
      p.assert.equal(await setting(p, 'volume'), v);
      p.assert.ok(Math.abs(await p.ev('RC.app.runner.audio.volume') - v * 0.16) < 1e-9);
    });
  }
  t.test('choosing a Volume while muted turns Sound back on', async (p) => {
    await pick(p, 'Options', 'Sound');
    p.assert.equal(await setting(p, 'sound'), false);
    await pickSub(p, 'Options', 'Volume', '75%');
    p.assert.equal(await setting(p, 'sound'), true);
    await openTop(p, 'Options');
    p.assert.equal((await item(p, 'Sound')).checked, true);
  }, { fresh: true });
  t.test('Options ▸ Disk Usage & Reset… shows the C: usage dialog', async (p) => {
    await pick(p, 'Options', 'Disk Usage & Reset…');
    p.assert.equal(await p.waitModal(), 'Virtual Disk C:');
    p.assert.match(await p.modalText(), /files and folders, [\d.]+ KB used of \d+ MB/);
    p.assert.deepEqual(await p.texts('.modal-foot button'), ['Close', 'Reinstall Examples', 'Erase Everything…']);
  });

  // ---- Help --------------------------------------------------------------------------------------------
  t.test('Help ▸ Language Reference opens the BASIC reference', async (p) => {
    await pick(p, 'Help', 'Language Reference');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    p.assert.equal(await p.count('.modal .help-nav'), 1);
  });
  t.test('Help ▸ Keyboard Shortcuts lists the shortcuts', async (p) => {
    await pick(p, 'Help', 'Keyboard Shortcuts');
    p.assert.equal(await p.waitModal(), 'Keyboard Shortcuts');
    const keys = await p.texts('.modal .kbd-table kbd');
    for (const k of ['F5', 'Shift+F5', 'Ctrl+F2', 'Ctrl+Break', 'F8', 'F10', 'Shift+F8', 'F7', 'F9', 'F4', 'F2', 'F1', 'Ctrl+S', 'Ctrl+O', 'Alt+N']) p.assert.ok(keys.includes(k), k);
  });
  t.test('Help ▸ Learn BASIC (Tutorial)… opens the lesson list', async (p) => {
    await pick(p, 'Help', 'Learn BASIC (Tutorial)…');
    p.assert.equal(await p.waitModal(), 'Learn BASIC — Tutorial');
    p.assert.ok(await p.count('.modal .list-row') >= 1);
  });
  t.test('Help ▸ Program Library… opens the program library', async (p) => {
    await pick(p, 'Help', 'Program Library…');
    const title = await p.waitModal();
    p.assert.equal(title, (await p.ev('!!(RC.LIBRARY && RC.LIBRARY.items && RC.LIBRARY.items.length)')) ? 'Program Library' : 'Example Programs');
  });
  t.test('Help ▸ Starter Examples… opens the example gallery', async (p) => {
    await pick(p, 'Help', 'Starter Examples…');
    p.assert.equal(await p.waitModal(), 'Example Programs');
  });
  for (const [label, id] of [['Welcome to the IDE', 'welcome'], ['Your First Program', 'first'], ['Debugging', 'debug'], ['Graphics & Sound', 'graphics'],
    ['Files & Sharing', 'files'], ['Classic GW-BASIC Console', 'gw']]) {
    t.test(`Help ▸ Tour: ${label} starts the ${id} tour at step 1`, async (p) => {
      await pick(p, 'Help', 'Tour: ' + label);
      await p.wait('!!RC.Tours.active', 2000);
      p.assert.equal(await p.ev('RC.Tours.active.id'), id);
      const first = await p.ev(`RC.Tours.TOURS[${JSON.stringify(id)}].steps[0].title`);
      await p.wait(`(document.querySelector('.tour-pop h3') || {}).innerText === ${JSON.stringify(first)}`, 2000);
      p.assert.match(await p.text('.tour-pop .count'), /^1 \/ \d+$/);
      await p.ev('RC.Tours.stop()');
    });
  }
  t.test('Help ▸ About Baysik shows the About dialog', async (p) => {
    await pick(p, 'Help', 'About Baysik');
    p.assert.equal(await p.waitModal(), 'About Baysik');
    p.assert.match(await p.modalText(), /BASIC programming studio/);
  });

  // ---- persistence across reload -----------------------------------------------------------------------
  t.test('theme chosen from the menu persists across reload', async (p) => {
    await pickSub(p, 'Options', 'Theme', 'Amber Monitor');
    await p.reload();
    p.assert.equal(await theme(p), 'amber');
    const d = await subDetails(p, 'Options', 'Theme');
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['Amber Monitor']);
  }, { fresh: true });
  t.test('speed chosen from the menu persists across reload (settings, runner and toolbar)', async (p) => {
    await pickSub(p, 'Run', 'Speed', 'Classic PC (≈ 8 MHz 286)');
    await p.reload();
    p.assert.equal(await setting(p, 'speed'), 25000);
    p.assert.equal(await p.ev('RC.app.runner.speed'), 25000);
    p.assert.equal(await p.ev("document.getElementById('tbSpeed').value"), '25000');
  }, { fresh: true });
  t.test('tab width, keyword capitalisation, indent and autosave choices persist across reload', async (p) => {
    await pickSub(p, 'Options', 'Tab Width', '2 spaces');
    await pick(p, 'Options', 'Capitalize Keywords As You Type');
    await pick(p, 'Options', 'Auto Indent');
    await pick(p, 'Options', 'Autosave');
    await p.reload();
    const s = await p.ev('RC.app.settings');
    p.assert.equal(s.tabSize, 2);
    p.assert.equal(s.autoFormat, false);
    p.assert.equal(s.autoIndent, false);
    p.assert.equal(s.autosave, false);
    await openTop(p, 'Options');
    p.assert.deepEqual(await checkedLabels(p), ['Sound']);
  }, { fresh: true });
  t.test('CRT, sound and volume choices persist across reload', async (p) => {
    await pick(p, 'Options', 'CRT Scanlines');
    await pickSub(p, 'Options', 'Volume', '25%');
    await pick(p, 'Options', 'Sound');
    await p.reload();
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), true);
    p.assert.equal(await setting(p, 'sound'), false);
    p.assert.equal(await setting(p, 'volume'), 0.25);
    p.assert.equal(await p.ev('RC.app.runner.audio.volume'), 0);
  }, { fresh: true });
  t.test('hidden explorer persists across reload', async (p) => {
    await pick(p, 'View', 'Explorer');
    await p.reload();
    p.assert.equal(await p.ev("document.getElementById('workspace').classList.contains('no-explorer')"), true);
    await openTop(p, 'View');
    p.assert.equal((await item(p, 'Explorer')).checked, false);
  }, { fresh: true });
  t.test('zoom level from the menu persists across reload', async (p) => {
    const f = await setting(p, 'fontSize');
    await pick(p, 'View', 'Zoom In');
    await pick(p, 'View', 'Zoom In');
    await p.reload();
    p.assert.equal(await setting(p, 'fontSize'), f + 2);
    p.assert.equal(await p.ev("document.documentElement.style.getPropertyValue('--ed-font-size')"), (f + 2) + 'px');
  }, { fresh: true });
  t.test('bottom panel chosen from the View menu persists across reload', async (p) => {
    await pick(p, 'View', 'Call Stack');
    await p.reload();
    p.assert.equal(await activePanel(p), 'stack');
  }, { fresh: true });
  t.test('font size from the dialog persists across reload', async (p) => {
    await pick(p, 'Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('12');
    await p.modalButton('OK');
    await p.reload();
    p.assert.equal(await setting(p, 'fontSize'), 12);
  }, { fresh: true });
};
