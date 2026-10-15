// Menus part A: every top-level menu opens; exact item lists, separators, shortcut labels,
// submenus, checked marks and disabled states reflect the real IDE state.
import { TOPS, HOT, reset, openTop, structure, details, item, checkedLabels, subDetails, prog, pausedAtStart, startLoop, openMenuName } from './10-menus-helpers.mjs';

const EXPECT = {
  File: ['New Program', 'New Folder…', 'Open…', 'Open from Computer…', '---', 'Save', 'Save As…', 'Save All', 'Download to Computer', '---',
    'Share Project as Link…', 'Import Shared Code…', 'Download Project (.zip)', '---', 'Mount Computer Folder as D:…', 'Unmount D:', '---', 'Close Tab'],
  Edit: ['Undo', 'Redo', '---', 'Find…', 'Replace…', 'Go to Line…', '---', 'Toggle Comment', 'Duplicate Line', 'Capitalize Keywords',
    'Renumber Lines (RENUM)…', 'Add Line Numbers…'],
  View: ['Output Screen Full Size', 'GW-BASIC Classic Console', 'Explorer', 'SUBs and FUNCTIONs…', '---', 'Immediate', 'Variables', 'Watch',
    'Call Stack', 'Breakpoints', 'History / Trace', 'Printer', '---', 'Zoom In', 'Zoom Out'],
  Run: ['Start', 'Restart', 'Pause', 'Stop', '---', 'Run to Cursor', 'Set Next Statement', '---', 'Speed', 'Output Screen'],
  Debug: ['Step Into', 'Step Over', 'Step Out', '---', 'Toggle Breakpoint', 'Conditional Breakpoint…', 'Clear All Breakpoints', '---',
    'Add Watch…', 'Animate Execution (Trace)', 'TRON (print line numbers)'],
  Options: ['Theme', 'Editor Font Size…', 'Tab Width', 'Capitalize Keywords As You Type', 'Auto Indent', 'Autosave', '---', 'CRT Scanlines',
    'Sound', 'Volume', '---', 'Disk Usage & Reset…'],
  Help: ['Language Reference', 'Keyboard Shortcuts', 'Learn BASIC (Tutorial)…', 'Program Library…', 'Starter Examples…', '---',
    'Tour: Welcome to the IDE', 'Tour: Your First Program', 'Tour: Debugging', 'Tour: Graphics & Sound', 'Tour: Files & Sharing',
    'Tour: Classic GW-BASIC Console', '---', 'About the Author', 'About Baysik'],
};
const SHORTCUTS = {
  File: { 'New Program': 'Alt+N', 'Open…': 'Ctrl+O', Save: 'Ctrl+S', 'Save As…': 'Ctrl+Shift+S', 'Close Tab': 'Alt+W' },
  Edit: { Undo: 'Ctrl+Z', Redo: 'Ctrl+Y', 'Find…': 'Ctrl+F', 'Replace…': 'Ctrl+H', 'Go to Line…': 'Ctrl+G', 'Toggle Comment': 'Ctrl+/', 'Duplicate Line': 'Ctrl+D' },
  View: { 'Output Screen Full Size': 'F4', 'SUBs and FUNCTIONs…': 'F2', 'Zoom In': 'Ctrl+=', 'Zoom Out': 'Ctrl+-' },
  Run: { Start: 'F5', Restart: 'Shift+F5', Pause: 'Ctrl+Break', Stop: 'Ctrl+F2', 'Run to Cursor': 'F7', 'Output Screen': 'F4' },
  Debug: { 'Step Into': 'F8', 'Step Over': 'F10', 'Step Out': 'Shift+F8', 'Toggle Breakpoint': 'F9' },
  Options: {},
  Help: { 'Language Reference': 'F1' },
};
const SUBMENUS = { File: [], Edit: [], View: [], Run: ['Speed'], Debug: [], Options: ['Theme', 'Tab Width', 'Volume'], Help: [] };

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- menubar ------------------------------------------------------------------------------------
  t.test('menubar shows the seven menu buttons in order with hot-letter spans', async (p) => {
    p.assert.deepEqual(await p.texts('.menu-btn'), TOPS);
    p.assert.deepEqual(await p.texts('.menu-btn .hot'), TOPS.map((x) => x[0]));
    p.assert.equal(await p.count('.menu-btn[aria-haspopup="true"]'), 7);
  });
  t.test('no menu popup is open at start', async (p) => {
    p.assert.equal(await p.count('.menu-pop'), 0);
    p.assert.equal(await openMenuName(p), null);
  });

  // ---- open by click / by Alt+letter -------------------------------------------------------------
  for (const top of TOPS) {
    t.test(`${top} menu opens by click and marks its button open`, async (p) => {
      await openTop(p, top);
      p.assert.equal(await p.count('.menu-pop'), 1);
      p.assert.equal(await openMenuName(p), top);
      p.assert.equal(await p.attr('.menu-pop', 'role'), 'menu');
      p.assert.deepEqual(await structure(p), EXPECT[top]);
      const br = await p.fn((n) => { const b = [...document.querySelectorAll('.menu-btn')].find((x) => x.innerText === n).getBoundingClientRect(); return { l: b.left, b: b.bottom }; }, top);
      const pr = await p.rect('.menu-pop');
      p.assert.ok(Math.abs(pr.x - br.l) < 2, `popup left ${pr.x} vs button ${br.l}`);
      p.assert.ok(Math.abs(pr.y - br.b) < 2, `popup top ${pr.y} vs button bottom ${br.b}`);
    });
    t.test(`${top} menu opens with Alt+${HOT[top].toUpperCase()} and highlights the first item`, async (p) => {
      await p.key(HOT[top], { alt: true });
      await p.wait("!!document.querySelector('.menu-pop')", 2000);
      p.assert.equal(await openMenuName(p), top);
      p.assert.deepEqual(await structure(p), EXPECT[top]);
      p.assert.equal(await p.ev("document.querySelector('.menu-pop .menu-item.active').children[0].innerText"), EXPECT[top][0]);
      p.assert.equal(await p.count('.menu-pop .menu-item.active'), 1);
    });
  }

  // ---- shortcut labels / submenu arrows -------------------------------------------------------------
  for (const top of TOPS) {
    t.test(`${top} menu shows exactly the documented shortcut labels`, async (p) => {
      await openTop(p, top);
      const d = await details(p);
      const got = {};
      for (const x of d) if (x.sc) got[x.label] = x.sc;
      p.assert.deepEqual(got, SHORTCUTS[top]);
    });
    t.test(`${top} menu: submenu arrows only on ${SUBMENUS[top].join(', ') || 'no items'}`, async (p) => {
      await openTop(p, top);
      const d = await details(p);
      p.assert.deepEqual(d.filter((x) => x.sub).map((x) => x.label), SUBMENUS[top]);
      p.assert.equal(await p.count('.menu-pop .menu-item[role="menuitem"]'), d.length);
      p.assert.equal(await p.count('.menu-pop .menu-sep'), EXPECT[top].filter((x) => x === '---').length);
    });
  }

  // ---- submenus --------------------------------------------------------------------------------------
  t.test('Run ▸ Speed submenu lists six speeds with Full speed checked by default', async (p) => {
    const d = await subDetails(p, 'Run', 'Speed');
    p.assert.deepEqual(d.map((x) => x.label), ['Full speed', 'Fast PC (≈ 486)', 'Classic PC (≈ 8 MHz 286)', 'Original IBM PC (≈ 4.77 MHz)',
      'Slow motion (20 statements/s)', 'Step-by-step crawl (3 statements/s)']);
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['Full speed']);
  }, { fresh: true });
  t.test('Speed submenu is placed to the right of its parent item', async (p) => {
    await subDetails(p, 'Run', 'Speed');
    const r = await p.fn(() => { const [a, b] = document.querySelectorAll('.menu-pop'); return [a.getBoundingClientRect().right, b.getBoundingClientRect().left]; });
    p.assert.ok(r[1] >= r[0] - 10, `submenu left ${r[1]} should be near parent right ${r[0]}`);
  });
  t.test('Options ▸ Theme submenu lists five themes with QBasic Blue checked by default', async (p) => {
    const d = await subDetails(p, 'Options', 'Theme');
    p.assert.deepEqual(d.map((x) => x.label), ['QBasic Blue', 'Dark', 'Light', 'Amber Monitor', 'Match System']);
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['QBasic Blue']);
  });
  t.test('Options ▸ Tab Width submenu lists 2/4/8 spaces with 4 checked by default', async (p) => {
    const d = await subDetails(p, 'Options', 'Tab Width');
    p.assert.deepEqual(d.map((x) => x.label), ['2 spaces', '4 spaces', '8 spaces']);
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['4 spaces']);
  });
  t.test('Options ▸ Volume submenu lists 25–100% with 50% checked by default', async (p) => {
    const d = await subDetails(p, 'Options', 'Volume');
    p.assert.deepEqual(d.map((x) => x.label), ['25%', '50%', '75%', '100%']);
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['50%']);
  });
  t.test('submenu checked mark follows the setting (speed changed through the toolbar select)', async (p) => {
    await p.ev("(() => { const s = document.getElementById('tbSpeed'); s.value = '4000'; s.dispatchEvent(new Event('change')); })()");
    const d = await subDetails(p, 'Run', 'Speed');
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['Original IBM PC (≈ 4.77 MHz)']);
  }, { fresh: true });
  t.test('Theme submenu check follows a theme set in settings', async (p) => {
    await p.ev("RC.app.settings.theme = 'amber'; RC.app.applyTheme()");
    const d = await subDetails(p, 'Options', 'Theme');
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['Amber Monitor']);
  }, { fresh: true });
  t.test('Tab Width and Volume checks follow non-default settings', async (p) => {
    await p.ev('RC.app.settings.tabSize = 8; RC.app.settings.volume = 1');
    let d = await subDetails(p, 'Options', 'Tab Width');
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['8 spaces']);
    await reset(p);
    d = await subDetails(p, 'Options', 'Volume');
    p.assert.deepEqual(d.filter((x) => x.checked).map((x) => x.label), ['100%']);
  }, { fresh: true });

  // ---- checked marks on top-level items ------------------------------------------------------------
  t.test('Options checkmarks reflect default settings (keywords, indent, autosave, sound on; CRT off)', async (p) => {
    await openTop(p, 'Options');
    p.assert.deepEqual(await checkedLabels(p), ['Capitalize Keywords As You Type', 'Auto Indent', 'Autosave', 'Sound']);
  }, { fresh: true });
  t.test('Options checkmarks reflect changed settings', async (p) => {
    await p.ev('Object.assign(RC.app.settings, { autoFormat: false, autoIndent: false, autosave: false, sound: false, crt: true })');
    await openTop(p, 'Options');
    p.assert.deepEqual(await checkedLabels(p), ['CRT Scanlines']);
  }, { fresh: true });
  t.test('View ▸ Explorer is checked while the explorer is shown and unchecked when hidden', async (p) => {
    await openTop(p, 'View');
    p.assert.equal((await item(p, 'Explorer')).checked, true);
    await reset(p);
    await p.ev('RC.app.settings.showExplorer = false; RC.app.applyLayout()');
    await openTop(p, 'View');
    p.assert.equal((await item(p, 'Explorer')).checked, false);
  }, { fresh: true });
  t.test('View ▸ GW-BASIC Classic Console is checked only while the console is active', async (p) => {
    await openTop(p, 'View');
    p.assert.equal((await item(p, 'GW-BASIC Classic Console')).checked, false);
    await reset(p);
    await p.ev('RC.app.console.toggle(true)');
    await openTop(p, 'View');
    p.assert.equal((await item(p, 'GW-BASIC Classic Console')).checked, true);
    await p.ev('RC.app.console.toggle(false)');
  });
  t.test('Debug ▸ Animate Execution is checked only while animation is on', async (p) => {
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Animate Execution (Trace)')).checked, false);
    await reset(p);
    await p.ev('RC.app.runner.animate = true');
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Animate Execution (Trace)')).checked, true);
    await p.ev('RC.app.setAnimate(false)');
  });
  t.test('only items with a checked state ever show a check (File/Edit/Help have none)', async (p) => {
    for (const top of ['File', 'Edit', 'Help', 'Run']) {
      await reset(p);
      await openTop(p, top);
      p.assert.deepEqual(await checkedLabels(p), [], top);
    }
  });

  // ---- disabled states ------------------------------------------------------------------------------------
  t.test('File menu with a tab open: Save/Save As/Download/Close Tab enabled, Unmount D: disabled', async (p) => {
    await openTop(p, 'File');
    const d = await details(p);
    p.assert.deepEqual(d.filter((x) => x.disabled).map((x) => x.label), ['Unmount D:']);
  }, { fresh: true });
  t.test('File menu with no tab: Save, Save As, Download and Close Tab are disabled', async (p) => {
    await p.ev('(async () => { while (RC.app.docs.length) await RC.app.closeDoc(RC.app.docs[0]); })()');
    await p.wait('RC.app.docs.length === 0 && RC.app.active === null');
    await openTop(p, 'File');
    const d = await details(p);
    p.assert.deepEqual(d.filter((x) => x.disabled).map((x) => x.label), ['Save', 'Save As…', 'Download to Computer', 'Unmount D:', 'Close Tab']);
  }, { fresh: true });
  t.test('File ▸ Unmount D: becomes enabled once a D: drive is mounted', async (p) => {
    await p.ev("RC.app.vfs.mountHandle('D', { name: 'FAKE', entries: async function* () {} }, 'read')");
    await p.wait('!!RC.app.vfs.drives.D');
    await openTop(p, 'File');
    p.assert.equal((await item(p, 'Unmount D:')).disabled, false);
    await p.ev("RC.app.vfs.unmount('D')");
  });
  t.test('Run menu when idle: Pause, Stop and Set Next Statement disabled; label is Start', async (p) => {
    await openTop(p, 'Run');
    const d = await details(p);
    p.assert.deepEqual(d.filter((x) => x.disabled).map((x) => x.label), ['Pause', 'Stop', 'Set Next Statement']);
    p.assert.equal(d[0].label, 'Start');
  });
  t.test('Run menu while running: Pause and Stop enabled, Set Next Statement disabled', async (p) => {
    await startLoop(p);
    await openTop(p, 'Run');
    const d = await details(p);
    p.assert.deepEqual(d.filter((x) => x.disabled).map((x) => x.label), ['Set Next Statement']);
    p.assert.equal(d[0].label, 'Start');
  });
  t.test('Run menu while paused: first item reads Continue; Pause disabled; Stop and Set Next enabled', async (p) => {
    await pausedAtStart(p);
    await openTop(p, 'Run');
    const d = await details(p);
    p.assert.equal(d[0].label, 'Continue');
    p.assert.equal(d[0].sc, 'F5');
    p.assert.deepEqual(d.filter((x) => x.disabled).map((x) => x.label), ['Pause']);
  });
  t.test('Run menu after the program ended: back to Start with Stop disabled', async (p) => {
    await p.runProgram('PRINT 1');
    await openTop(p, 'Run');
    const d = await details(p);
    p.assert.equal(d[0].label, 'Start');
    p.assert.deepEqual(d.filter((x) => x.disabled).map((x) => x.label), ['Pause', 'Stop', 'Set Next Statement']);
  });
  t.test('Debug ▸ Step Out is disabled unless paused', async (p) => {
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Step Out')).disabled, true);
    p.assert.deepEqual((await details(p)).filter((x) => x.disabled).map((x) => x.label), ['Step Out']);
    await reset(p);
    await pausedAtStart(p);
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Step Out')).disabled, false);
  });
  t.test('Debug ▸ Step Out stays disabled while running (not paused)', async (p) => {
    await startLoop(p);
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Step Out')).disabled, true);
  });
  t.test('View, Edit, Options and Help menus have no disabled items', async (p) => {
    for (const top of ['View', 'Edit', 'Options', 'Help']) {
      await reset(p);
      await openTop(p, top);
      p.assert.deepEqual((await details(p)).filter((x) => x.disabled).map((x) => x.label), [], top);
    }
  });
  t.test('a menu reflects state at the moment it is opened (reopening after pausing updates it)', async (p) => {
    await prog(p, 'a = 1\nb = 2\n');
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Step Out')).disabled, true);
    await reset(p);
    await p.ev("RC.app.step('into')");
    await p.waitState('paused');
    await openTop(p, 'Debug');
    p.assert.equal((await item(p, 'Step Out')).disabled, false);
  });
};
