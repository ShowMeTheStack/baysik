// Toolbar: structure, labels/aria, enabled state per run state, state pill, Files drawer, speed select,
// Learn / Library / Tours / Help, breakpoint and restart buttons.

const IDS = ['tbFiles', 'tbRun', 'tbPause', 'tbStop', 'tbRestart', 'tbInto', 'tbOver', 'tbOut', 'tbBp', 'tbLearn', 'tbExamples', 'tbTour', 'tbHelp'];
const BUTTONS = [
  { id: 'tbFiles', title: 'Show files', label: 'Files', cls: 'tb-files' },
  { id: 'tbRun', title: 'Run / Continue (F5)', label: 'Run', cls: 'primary' },
  { id: 'tbPause', title: 'Pause (Ctrl+Break)', label: 'Pause' },
  { id: 'tbStop', title: 'Stop (Ctrl+F2)', label: 'Stop' },
  { id: 'tbRestart', title: 'Restart (Shift+F5)', label: '' },
  { id: 'tbInto', title: 'Step Into (F8)', label: 'Step' },
  { id: 'tbOver', title: 'Step Over (F10)', label: 'Over' },
  { id: 'tbOut', title: 'Step Out (Shift+F8)', label: 'Out' },
  { id: 'tbBp', title: 'Toggle Breakpoint (F9)', label: '', cls: 'danger' },
  { id: 'tbLearn', title: 'BASIC tutorial: step-by-step lessons', label: 'Learn' },
  { id: 'tbExamples', title: 'Program library: hundreds of commented example programs', label: 'Library' },
  { id: 'tbTour', title: 'Guided tours', label: 'Tours' },
  { id: 'tbHelp', title: 'Language reference (F1)', label: 'Help' },
];
const SPEEDS = [
  ['0', 'Full speed'],
  ['400000', 'Fast PC (≈ 486)'],
  ['25000', 'Classic PC (≈ 8 MHz 286)'],
  ['4000', 'Original IBM PC (≈ 4.77 MHz)'],
  ['20', 'Slow motion (20 statements/s)'],
  ['3', 'Step-by-step crawl (3 statements/s)'],
];
const LOOP = 'DO\n  x = x + 1\nLOOP';

const disabled = (p) => p.ev(`Object.fromEntries(${JSON.stringify(IDS)}.map(id => [id, document.getElementById(id).disabled]))`);
const runLbl = (p) => p.text('#tbRun .lbl');
const pill = (p) => p.ev("({ text: document.getElementById('tbState').textContent, cls: document.getElementById('tbState').className.trim() })");

async function toRunning(p, prog) {
  await p.runProgram(prog || LOOP, { wait: false });
  await p.waitState('running');
  await p.sleep(60);
}
async function toWaiting(p) {
  await p.runProgram('INPUT "Value"; v\nPRINT v * 2', { wait: false });
  await p.waitState('waiting');
  await p.sleep(60);
}
async function toPaused(p) {
  const st = await p.runProgram('a = 1\nSTOP\nPRINT "AFTER"');
  p.assert.equal(st, 'paused');
  await p.sleep(30);
}
async function toEnded(p) {
  const st = await p.runProgram('PRINT "DONE"');
  p.assert.equal(st, 'ended');
  await p.sleep(30);
}
async function toError(p) {
  const st = await p.runProgram('a = 1\nb = a / 0');
  p.assert.equal(st, 'error');
  await p.sleep(30);
}
const alwaysOn = (d, p) => {
  for (const id of ['tbFiles', 'tbRestart', 'tbInto', 'tbOver', 'tbBp', 'tbLearn', 'tbExamples', 'tbTour', 'tbHelp']) p.assert.equal(d[id], false, id + ' should be enabled');
};
const setSelect = (p, v) => p.fn((v) => { const s = document.getElementById('tbSpeed'); s.focus(); s.value = v; s.dispatchEvent(new Event('change', { bubbles: true })); }, v);

export default (t) => {
  t.beforeEach(async (p) => {
    await p.closeModals();
    await p.closeMenus();
    await p.ev('RC.Tours.active && RC.Tours.stop()');
    if (await p.ev('RC.app.runner.isActive()')) await p.stopProgram();
    if (await p.ev('RC.app.settings.speed') !== 0) await p.ev('RC.app.setSpeed(0)');
  });

  // ---- structure ------------------------------------------------------------------------------------
  t.test('toolbar has role=toolbar and aria-label "Run and debug"', async (p) => {
    p.assert.equal(await p.attr('#toolbar', 'role'), 'toolbar');
    p.assert.equal(await p.attr('#toolbar', 'aria-label'), 'Run and debug');
  });
  t.test('toolbar contains its controls in the documented order', async (p) => {
    const order = await p.ev("[...document.querySelectorAll('#toolbar > button, #toolbar select, #toolbar .state-pill')].map(e => e.id)");
    p.assert.deepEqual(order, ['tbFiles', 'tbRun', 'tbPause', 'tbStop', 'tbRestart', 'tbInto', 'tbOver', 'tbOut', 'tbBp', 'tbSpeed', 'tbState', 'tbLearn', 'tbExamples', 'tbTour', 'tbHelp']);
  });
  t.test('toolbar has three separators and a Speed label', async (p) => {
    p.assert.equal(await p.count('#toolbar .tb-sep'), 3);
    p.assert.equal(await p.text('#toolbar .tb-label'), 'Speed');
  });
  for (const b of BUTTONS) {
    t.test(`button ${b.id}: title, aria-label, visible label and type`, async (p) => {
      p.assert.equal(await p.attr('#' + b.id, 'title'), b.title);
      p.assert.equal(await p.attr('#' + b.id, 'aria-label'), b.title);
      p.assert.equal(await p.attr('#' + b.id, 'type'), 'button');
      p.assert.equal(await p.ev(`document.querySelector('#${b.id} .lbl').textContent`), b.label);
      p.assert.equal(await p.exists(`#${b.id} svg`), true, 'has an icon');
      if (b.cls) p.assert.equal(await p.ev(`document.getElementById('${b.id}').classList.contains('${b.cls}')`), true);
    });
  }
  t.test('speed select has title and aria-label "Execution speed"', async (p) => {
    p.assert.equal(await p.attr('#tbSpeed', 'title'), 'Execution speed');
    p.assert.equal(await p.attr('#tbSpeed', 'aria-label'), 'Execution speed');
  });
  t.test('speed select lists all six presets in order with their values', async (p) => {
    const opts = await p.ev("[...document.querySelectorAll('#tbSpeed option')].map(o => [o.value, o.textContent])");
    p.assert.deepEqual(opts, SPEEDS);
  });
  t.test('speed select defaults to Full speed', async (p) => {
    p.assert.equal(await p.ev("document.getElementById('tbSpeed').value"), '0');
    p.assert.equal(await p.ev('RC.app.runner.speed'), 0);
  });

  // ---- idle -------------------------------------------------------------------------------------------
  t.test('idle: state pill says Ready with no state class', async (p) => {
    p.assert.equal(await p.state(), 'idle');
    p.assert.deepEqual(await pill(p), { text: 'Ready', cls: 'state-pill' });
  }, { fresh: true });
  t.test('idle: Run enabled, Pause/Stop/Out disabled, others enabled', async (p) => {
    const d = await disabled(p);
    p.assert.equal(d.tbRun, false);
    p.assert.equal(d.tbPause, true);
    p.assert.equal(d.tbStop, true);
    p.assert.equal(d.tbOut, true);
    alwaysOn(d, p);
    p.assert.equal(await runLbl(p), 'Run');
  }, { fresh: true });
  t.test('idle: app does not carry the running class', async (p) => {
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('running')"), false);
  }, { fresh: true });
  t.test('idle: clicking the disabled Pause and Stop buttons changes nothing', async (p) => {
    const before = await p.status();
    await p.click('#tbPause');
    await p.click('#tbStop');
    p.assert.equal(await p.state(), 'idle');
    p.assert.equal(await p.status(), before);
  }, { fresh: true });
  t.test('idle: clicking the disabled Step Out button does not start a program', async (p) => {
    await p.click('#tbOut');
    await p.sleep(100);
    p.assert.equal(await p.state(), 'idle');
  }, { fresh: true });

  // ---- running -----------------------------------------------------------------------------------------
  t.test('running: Run disabled, Pause and Stop enabled, Out disabled', async (p) => {
    await toRunning(p);
    const d = await disabled(p);
    p.assert.equal(d.tbRun, true);
    p.assert.equal(d.tbPause, false);
    p.assert.equal(d.tbStop, false);
    p.assert.equal(d.tbOut, true);
    alwaysOn(d, p);
  });
  t.test('running: pill says Running with class running', async (p) => {
    await toRunning(p);
    p.assert.deepEqual(await pill(p), { text: 'Running', cls: 'state-pill running' });
  });
  t.test('running: app gets the running class', async (p) => {
    await toRunning(p);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('running')"), true);
  });
  t.test('running: Run label stays "Run"', async (p) => {
    await toRunning(p);
    p.assert.equal(await runLbl(p), 'Run');
  });
  t.test('running: clicking the disabled Run button does not restart the program', async (p) => {
    await toRunning(p);
    await p.ev('window.__vm1 = RC.app.runner.vm; 0');
    await p.click('#tbRun');
    await p.sleep(80);
    p.assert.equal(await p.ev('RC.app.runner.vm === window.__vm1'), true);
    p.assert.equal(await p.state(), 'running');
  });
  t.test('running: Step buttons do nothing while running', async (p) => {
    await toRunning(p);
    await p.click('#tbInto');
    await p.click('#tbOver');
    await p.sleep(80);
    p.assert.equal(await p.state(), 'running');
  });

  // ---- waiting for INPUT -----------------------------------------------------------------------------
  t.test('waiting for INPUT: buttons match the running state', async (p) => {
    await toWaiting(p);
    const d = await disabled(p);
    p.assert.equal(d.tbRun, true);
    p.assert.equal(d.tbPause, false);
    p.assert.equal(d.tbStop, false);
    p.assert.equal(d.tbOut, true);
    alwaysOn(d, p);
  });
  t.test('waiting for INPUT: pill still says Running', async (p) => {
    await toWaiting(p);
    p.assert.deepEqual(await pill(p), { text: 'Running', cls: 'state-pill running' });
  });

  // ---- paused -------------------------------------------------------------------------------------------
  t.test('paused: Run becomes Continue and is enabled; Pause disabled; Stop and Out enabled', async (p) => {
    await toPaused(p);
    const d = await disabled(p);
    p.assert.equal(d.tbRun, false);
    p.assert.equal(await runLbl(p), 'Continue');
    p.assert.equal(d.tbPause, true);
    p.assert.equal(d.tbStop, false);
    p.assert.equal(d.tbOut, false);
    alwaysOn(d, p);
  });
  t.test('paused: pill says Paused with class paused', async (p) => {
    await toPaused(p);
    p.assert.deepEqual(await pill(p), { text: 'Paused', cls: 'state-pill paused' });
  });
  t.test('paused: app keeps the running class', async (p) => {
    await toPaused(p);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('running')"), true);
  });
  t.test('paused: clicking Continue resumes and the label goes back to Run', async (p) => {
    await toPaused(p);
    await p.click('#tbRun');
    await p.waitState('ended');
    p.assert.equal(await runLbl(p), 'Run');
    p.assert.match(await p.screen(), /AFTER/);
  });

  // ---- ended ----------------------------------------------------------------------------------------------
  t.test('ended: Run enabled with label Run; Pause, Stop and Out disabled', async (p) => {
    await toEnded(p);
    const d = await disabled(p);
    p.assert.equal(d.tbRun, false);
    p.assert.equal(await runLbl(p), 'Run');
    p.assert.equal(d.tbPause, true);
    p.assert.equal(d.tbStop, true);
    p.assert.equal(d.tbOut, true);
    alwaysOn(d, p);
  });
  t.test('ended: pill says Ended with no state class', async (p) => {
    await toEnded(p);
    p.assert.deepEqual(await pill(p), { text: 'Ended', cls: 'state-pill' });
  });
  t.test('ended: app loses the running class', async (p) => {
    await toRunning(p);
    await p.click('#tbStop');
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('running')"), false);
  });
  t.test('ended: clicking disabled Stop leaves the end status alone', async (p) => {
    await toEnded(p);
    const before = await p.status();
    await p.click('#tbStop');
    p.assert.equal(await p.status(), before);
    p.assert.doesNotMatch(await p.status(), /Stopped/);
  });

  // ---- error ------------------------------------------------------------------------------------------------
  t.test('runtime error: pill says Error with class error', async (p) => {
    await toError(p);
    p.assert.deepEqual(await pill(p), { text: 'Error', cls: 'state-pill error' });
  });
  t.test('runtime error: Run enabled; Pause, Stop and Out disabled', async (p) => {
    await toError(p);
    const d = await disabled(p);
    p.assert.equal(d.tbRun, false);
    p.assert.equal(await runLbl(p), 'Run');
    p.assert.equal(d.tbPause, true);
    p.assert.equal(d.tbStop, true);
    p.assert.equal(d.tbOut, true);
    alwaysOn(d, p);
  });
  t.test('runtime error: app is not in running mode', async (p) => {
    await toError(p);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('running')"), false);
  });

  // ---- compile error ------------------------------------------------------------------------------------------
  t.test('compile error: Run enabled, Pause and Stop disabled, pill is not Running/Paused', async (p) => {
    await toEnded(p);
    await p.runProgram('PRINT 1\nFOR = 3', { wait: false });
    await p.sleep(100);
    const d = await disabled(p);
    p.assert.equal(d.tbRun, false);
    p.assert.equal(d.tbPause, true);
    p.assert.equal(d.tbStop, true);
    const pl = await pill(p);
    p.assert.ok(!/Running|Paused/.test(pl.text), pl.text);
  });
  t.test('compile error while a program runs stops the running program', async (p) => {
    await toRunning(p);
    await p.ev('window.__vm1 = RC.app.runner.vm; 0');
    await p.setCode('PRINT (');
    await p.click('#tbRestart');
    await p.sleep(100);
    p.assert.equal(await p.ev("window.__vm1.state"), 'ended');
    p.assert.notEqual(await p.state(), 'running');
    p.assert.match(await p.status(), /^Syntax:/);
  });

  // ---- immediate-mode pill ----------------------------------------------------------------------------------
  t.test('a long Immediate statement shows the pill "Immediate Running"', async (p) => {
    await toEnded(p);
    await p.ev("RC.app.immediate('FOR i = 1 TO 2000000000: NEXT')");
    await p.wait("document.getElementById('tbState').textContent === 'Immediate Running'", 3000);
    p.assert.equal(await p.ev("document.getElementById('tbState').className.trim()"), 'state-pill running');
    await p.click('#tbStop');
    await p.wait("!/Immediate/.test(document.getElementById('tbState').textContent)", 3000);
  });

  // ---- Files drawer button ----------------------------------------------------------------------------------
  t.test('Files button is hidden at desktop width (1400px)', async (p) => {
    p.assert.equal(await p.visible('#tbFiles'), false);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('tbFiles')).display"), 'none');
    p.assert.equal(await p.visible('#explorer'), true);
  }, { fresh: true });
  t.test('Files button is visible at tablet width (1000px) and the explorer is off-canvas', async (p) => {
    await p.viewport(1000, 800);
    p.assert.equal(await p.visible('#tbFiles'), true);
    const r = await p.rect('#explorer');
    p.assert.ok(r.right <= 1, 'explorer translated off screen, right=' + r.right);
  }, { fresh: { width: 1000, height: 800 } });
  t.test('tablet width: only the Run button keeps its text label', async (p) => {
    const shown = await p.ev("[...document.querySelectorAll('#toolbar .tb-btn')].filter(b => getComputedStyle(b).display !== 'none').map(b => [b.id, getComputedStyle(b.querySelector('.lbl')).display])");
    for (const [id, disp] of shown) p.assert.equal(disp !== 'none', id === 'tbRun', id + ' label display ' + disp);
  }, { fresh: { width: 1000, height: 800 } });
  t.test('Files button opens the explorer drawer with a scrim', async (p) => {
    await p.click('#tbFiles');
    await p.sleep(300);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('explorer-open')"), true);
    p.assert.equal(await p.visible('#drawerScrim'), true);
    const r = await p.rect('#explorer');
    p.assert.ok(r.x >= -1 && r.w > 100, JSON.stringify(r));
  }, { fresh: { width: 1000, height: 800 } });
  t.test('clicking the scrim closes the drawer', async (p) => {
    await p.click('#tbFiles');
    await p.sleep(300);
    const r = await p.rect('#explorer');
    await p.clickAt(r.right + 100, 400);
    await p.sleep(300);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('explorer-open')"), false);
    p.assert.equal(await p.visible('#drawerScrim'), false);
  }, { fresh: { width: 1000, height: 800 } });
  t.test('the drawer close button (✕) closes the drawer', async (p) => {
    await p.click('#tbFiles');
    await p.sleep(300);
    p.assert.equal(await p.visible('#explorerClose'), true);
    p.assert.equal(await p.attr('#explorerClose', 'aria-label'), 'Close files');
    await p.click('#explorerClose');
    await p.sleep(300);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('explorer-open')"), false);
  }, { fresh: { width: 1000, height: 800 } });
  t.test('Files button toggles the drawer via toggleDrawer when clicked twice', async (p) => {
    const open = "document.getElementById('app').classList.contains('explorer-open')";
    await p.wait("getComputedStyle(document.getElementById('tbFiles')).display !== 'none'");
    await p.click('#tbFiles');
    await p.wait(open, 2000);
    await p.ev('RC.app.toggleDrawer()');
    await p.wait('!' + open, 2000);
    await p.sleep(250);
    await p.click('#tbFiles');
    await p.wait(open, 2000);
  }, { fresh: { width: 1000, height: 800 } });
  t.test('Files button is visible at 1199px and hidden at 1200px', async (p) => {
    await p.viewport(1199, 800);
    p.assert.equal(await p.visible('#tbFiles'), true);
    await p.viewport(1200, 800);
    p.assert.equal(await p.visible('#tbFiles'), false);
    await p.viewport(1400, 900);
  });
  t.test('Files button is visible at 821px and hidden at 820px (phone layout)', async (p) => {
    await p.viewport(821, 800);
    p.assert.equal(await p.visible('#tbFiles'), true);
    await p.viewport(820, 800);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('tbFiles')).display"), 'none');
    await p.viewport(1400, 900);
  });
  t.test('phone width (600px): Files button hidden, mobile tabs shown, labels and state pill hidden', async (p) => {
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('tbFiles')).display"), 'none');
    p.assert.equal(await p.visible('#mobileTabs'), true);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('tbState')).display"), 'none');
    p.assert.equal(await p.ev("getComputedStyle(document.querySelector('#tbRun .lbl')).display"), 'none');
    p.assert.equal(await p.visible('#tbRun'), true);
  }, { fresh: { width: 600, height: 900, mobile: true, touch: true } });
  t.test('phone width: toolbar does not cause horizontal page scroll', async (p) => {
    p.assert.equal(await p.noHScroll(), true);
  }, { fresh: { width: 390, height: 844, mobile: true, touch: true } });

  // ---- Speed select ----------------------------------------------------------------------------------------
  for (const [v, label] of SPEEDS) {
    t.test(`speed select "${label}" sets runner speed ${v} and saves the setting`, async (p) => {
      if (v === '0') await p.ev('RC.app.setSpeed(20)');
      await setSelect(p, v);
      p.assert.equal(await p.ev('RC.app.runner.speed'), +v);
      p.assert.equal(await p.ev('RC.app.settings.speed'), +v);
      p.assert.equal(await p.ev("JSON.parse(localStorage.getItem('baysik.settings')).speed"), +v);
      p.assert.equal(await p.ev("document.getElementById('tbSpeed').selectedOptions[0].textContent"), label);
    });
  }
  t.test('speed change during a run applies to the live VM throttle', async (p) => {
    await toRunning(p);
    await setSelect(p, '4000');
    p.assert.equal(await p.ev('RC.app.runner.vm.throttle'), 4000);
    await setSelect(p, '0');
    await p.sleep(50);
    p.assert.equal(await p.ev('RC.app.runner.vm.throttle'), 0);
  });
  t.test('speed setting survives a reload', async (p) => {
    await setSelect(p, '25000');
    await p.reload();
    p.assert.equal(await p.ev("document.getElementById('tbSpeed').value"), '25000');
    p.assert.equal(await p.ev('RC.app.runner.speed'), 25000);
    await p.ev('RC.app.setSpeed(0)');
  });
  t.test('Run > Speed submenu checks the option selected in the toolbar', async (p) => {
    await setSelect(p, '4000');
    await p.click('.menu-btn', 'Run');
    await p.hover('.menu-pop .menu-item', 'Speed');
    await p.sleep(150);
    if (await p.count('.menu-pop') < 2) await p.click('.menu-pop .menu-item', 'Speed');
    const items = await p.ev("[...document.querySelectorAll('.menu-pop:last-of-type .menu-item')].map(e => [e.innerText.trim(), e.classList.contains('checked')])");
    p.assert.equal(items.length, 6);
    p.assert.deepEqual(items.filter((x) => x[1]).map((x) => x[0]), ['Original IBM PC (≈ 4.77 MHz)']);
    await p.closeMenus();
  });
  t.test('choosing a speed from the Run menu updates the toolbar select', async (p) => {
    await p.menu('Run', 'Speed', 'Slow motion (20 statements/s)');
    p.assert.equal(await p.ev("document.getElementById('tbSpeed').value"), '20');
    p.assert.equal(await p.ev('RC.app.runner.speed'), 20);
  });

  // ---- Learn / Library / Tours / Help -------------------------------------------------------------------------
  t.test('Learn opens the tutorial browser', async (p) => {
    await p.click('#tbLearn');
    p.assert.equal(await p.waitModal(), 'Learn BASIC — Tutorial');
  });
  t.test('Library opens the program library', async (p) => {
    await p.click('#tbExamples');
    p.assert.equal(await p.waitModal(), 'Program Library');
    p.assert.ok(await p.count('.modal-back .card') > 5, 'library shows program cards');
  });
  t.test('Help opens the language reference', async (p) => {
    await p.click('#tbHelp');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
  });
  t.test('Tours opens a menu below the Tours button listing the lessons entry and tours', async (p) => {
    await p.click('#tbTour');
    await p.wait("!!document.querySelector('.menu-pop')", 2000);
    const items = await p.texts('.menu-pop .menu-item');
    p.assert.equal(items[0].trim(), 'Learn BASIC — all lessons…');
    p.assert.ok(items.slice(1).length >= 2 && items.slice(1).every((s) => s.startsWith('Tour: ')), JSON.stringify(items));
    p.assert.ok(items.some((s) => /Welcome to the IDE/.test(s)));
    const b = await p.rect('#tbTour');
    const m = await p.rect('.menu-pop');
    p.assert.ok(Math.abs(m.y - b.bottom) < 6, `menu top ${m.y} vs button bottom ${b.bottom}`);
    await p.closeMenus();
  });
  t.test('Tours menu "Learn BASIC — all lessons…" opens the tutorial', async (p) => {
    await p.click('#tbTour');
    await p.click('.menu-pop .menu-item', 'Learn BASIC');
    p.assert.equal(await p.waitModal(), 'Learn BASIC — Tutorial');
  });
  t.test('Tours menu starts the "Welcome to the IDE" tour', async (p) => {
    await p.click('#tbTour');
    await p.click('.menu-pop .menu-item', 'Welcome to the IDE');
    await p.wait('!!RC.Tours.active', 3000);
    p.assert.match(await p.ev('document.body.innerText'), /Welcome to Baysik!/);
    await p.ev('RC.Tours.stop()');
  });
  t.test('Learn / Library / Help open while a program is running and it keeps running', async (p) => {
    await toRunning(p);
    for (const id of ['#tbLearn', '#tbExamples', '#tbHelp']) {
      await p.click(id);
      await p.waitModal();
      await p.closeModals();
    }
    const a = await p.ev('RC.app.runner.vm.statementsExecuted');
    await p.sleep(100);
    p.assert.equal(await p.state(), 'running');
    p.assert.ok(await p.ev('RC.app.runner.vm.statementsExecuted') > a);
  });

  // ---- Breakpoint button ---------------------------------------------------------------------------------------
  t.test('Breakpoint button toggles a breakpoint on the cursor line', async (p) => {
    await p.newFile('C:\\MYPROGS\\BP.BAS', 'PRINT 1\nPRINT 2\nPRINT 3');
    await p.ev('RC.app.active.editor.setCursor(1, 0)');
    await p.click('#tbBp');
    p.assert.equal(await p.ev("RC.app.breakpoints.get('C:\\\\MYPROGS\\\\BP.BAS').has(1)"), true);
    await p.sleep(50);
    p.assert.equal(await p.ev("[...RC.app.active.editor.inner.children].findIndex(g => g.classList.contains('bp'))"), 1);
  });
  t.test('Breakpoint button shows the count on the Breakpoints tab', async (p) => {
    p.assert.equal(await p.text('#bottomTabs .tab[data-id=bps] .count'), '1');
  });
  t.test('Run with a toolbar breakpoint pauses there with status "Paused at breakpoint"', async (p) => {
    await p.click('#tbRun');
    await p.waitState('paused');
    p.assert.match(await p.status(), /^Paused at breakpoint/);
    p.assert.match(await p.screen(), /^ 1\s*$/m);
    p.assert.doesNotMatch(await p.screen(), / 2/);
    p.assert.equal(await p.ev('RC.app.active.editor.marks.exec'), 1);
  });
  t.test('Breakpoint button pressed again removes the breakpoint', async (p) => {
    await p.ev("RC.app.openFile('C:\\\\MYPROGS\\\\BP.BAS'); RC.app.active.editor.setCursor(1, 0)");
    await p.click('#tbBp');
    p.assert.equal(await p.ev("(RC.app.breakpoints.get('C:\\\\MYPROGS\\\\BP.BAS') || new Map()).size"), 0);
    p.assert.equal(await p.exists('#bottomTabs .tab[data-id=bps] .count'), false);
    await p.click('#tbRun');
    await p.waitState('ended');
  });

  // ---- Restart -------------------------------------------------------------------------------------------------
  t.test('Restart while running starts a fresh run of the program', async (p) => {
    await toRunning(p);
    await p.ev('window.__vm1 = RC.app.runner.vm; 0');
    await p.sleep(100);
    await p.click('#tbRestart');
    await p.sleep(30);
    p.assert.equal(await p.ev('RC.app.runner.vm !== window.__vm1'), true);
    p.assert.equal(await p.ev('window.__vm1.state'), 'ended');
    p.assert.equal(await p.state(), 'running');
  });
  t.test('Restart while idle/ended runs the program', async (p) => {
    await p.newFile('C:\\MYPROGS\\E2E.BAS', 'PRINT "RESTARTED"');
    await p.click('#tbRestart');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /RESTARTED/);
  });
  t.test('Restart while paused starts over from the beginning', async (p) => {
    await p.runProgram('PRINT "BEGIN"\nSTOP\nPRINT "END"');
    p.assert.equal(await p.state(), 'paused');
    await p.click('#tbRestart');
    await p.waitState('paused');
    const scr = await p.screen();
    p.assert.equal((scr.match(/BEGIN/g) || []).length, 1, 'screen was cleared and BEGIN printed once');
    p.assert.doesNotMatch(scr, /END/);
  });
  t.test('Restart clears the screen (new run starts with CLS)', async (p) => {
    await p.runProgram('PRINT "FIRSTRUN"');
    await p.setCode('PRINT "SECONDRUN"');
    await p.click('#tbRestart');
    await p.waitState('ended');
    const scr = await p.screen();
    p.assert.match(scr, /SECONDRUN/);
    p.assert.doesNotMatch(scr, /FIRSTRUN/);
  });
};
