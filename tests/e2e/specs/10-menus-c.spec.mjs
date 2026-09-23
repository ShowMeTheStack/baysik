// Menus part C: every File, Edit, View and Run menu item really performs its action.
import { reset, pick, pickSub, prog, caret, pauseLine, activePanel, setting, trapDownloads, startLoop, pausedAtStart, STEPS } from './10-menus-helpers.mjs';

const isMax = (p) => p.ev("document.getElementById('app').classList.contains('screen-max')");
const fileText = (p, path) => p.ev(`RC.app.decodeText(RC.app.vfs.readFile(${JSON.stringify(path)}))`);
const modalVal = (p) => p.ev("(document.querySelector('.modal-back:last-child .modal input[type=text]') || {}).value");

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- File ----------------------------------------------------------------------------------------
  t.test('File ▸ New Program asks for a name (UNTITLED.BAS) and opens the new file', async (p) => {
    await pick(p, 'File', 'New Program');
    p.assert.equal(await p.waitModal(), 'New Program');
    p.assert.equal(await modalVal(p), 'UNTITLED.BAS');
    await p.modalButton('OK');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\MYPROGS\\\\UNTITLED.BAS'", 3000);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\MYPROGS\\\\UNTITLED.BAS')"), true);
    p.assert.match(await p.code(), /PRINT "Hello!"/);
  }, { fresh: true });
  t.test('File ▸ New Program: Cancel creates nothing', async (p) => {
    const n = await p.ev('RC.app.docs.length');
    await pick(p, 'File', 'New Program');
    await p.waitModal();
    await p.modalButton('Cancel');
    p.assert.equal(await p.ev('RC.app.docs.length'), n);
  });
  t.test('File ▸ New Folder… creates the named folder', async (p) => {
    await pick(p, 'File', 'New Folder…');
    p.assert.equal(await p.waitModal(), 'New Folder');
    p.assert.equal(await modalVal(p), 'PROJECT');
    await p.modalInput('MENUDIR');
    await p.modalButton('OK');
    await p.wait("RC.app.vfs.exists('C:\\\\MYPROGS\\\\MENUDIR')", 3000);
  }, { fresh: true });
  t.test('File ▸ Open… shows the Open File list and opening a row opens that file', async (p) => {
    await pick(p, 'File', 'Open…');
    p.assert.equal(await p.waitModal(), 'Open File');
    p.assert.ok(await p.count('.modal .list-row') > 5);
    await p.modalInput('HELLO.BAS');
    await p.wait("document.querySelectorAll('.modal .list-row').length >= 1");
    p.assert.ok((await p.texts('.modal .list-row')).every((x) => /HELLO\.BAS/i.test(x)));
    await p.click('.modal .list-row', 'MYPROGS');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
  });
  t.test('File ▸ Open from Computer… opens a multi-file picker', async (p) => {
    await trapDownloads(p);
    await pick(p, 'File', 'Open from Computer…');
    await p.wait('window.__picks.length === 1', 2000);
    p.assert.equal(await p.ev('window.__picks[0].multiple'), true);
  });
  t.test('File ▸ Save writes the editor text to disk and clears the dirty mark', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\SAVEME.BAS');
    await p.setCode('PRINT "SAVED BY MENU"\n');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    await pick(p, 'File', 'Save');
    await p.wait('RC.app.active.dirty === false', 2000);
    p.assert.match(await fileText(p, 'C:\\MYPROGS\\SAVEME.BAS'), /SAVED BY MENU/);
    p.assert.match(await p.status(), /Saved C:\\MYPROGS\\SAVEME\.BAS/);
    p.assert.equal(await p.count('#editorTabs .tab.active .dirty'), 0);
  });
  t.test('File ▸ Save on an example file asks to save your own copy', async (p) => {
    await p.ev("RC.app.openFile('C:\\\\SAMPLES\\\\FACTORL.BAS')");
    await p.wait("RC.app.active && /FACTORL/.test(RC.app.active.path)");
    await pick(p, 'File', 'Save');
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.match(await modalVal(p), /^C:\\MYPROGS\\FACTORL\d*\.BAS$/);
  });
  t.test('File ▸ Save As… saves under a new name and switches the tab to it', async (p) => {
    await prog(p, 'PRINT "AS"\n', 'C:\\MYPROGS\\ORIG.BAS');
    await pick(p, 'File', 'Save As…');
    p.assert.equal(await p.waitModal(), 'Save As');
    p.assert.equal(await modalVal(p), 'C:\\MYPROGS\\ORIG.BAS');
    await p.modalInput('COPYAS');
    await p.modalButton('OK');
    await p.wait("RC.app.active.path === 'C:\\\\MYPROGS\\\\COPYAS.BAS'", 3000);
    p.assert.match(await fileText(p, 'C:\\MYPROGS\\COPYAS.BAS'), /PRINT "AS"/);
  }, { fresh: true });
  t.test('File ▸ Save All saves every dirty document', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\ALL1.BAS');
    await p.setCode('PRINT "ONE"\n');
    await prog(p, 'PRINT 2\n', 'C:\\MYPROGS\\ALL2.BAS');
    await p.setCode('PRINT "TWO"\n');
    p.assert.equal(await p.ev('RC.app.docs.filter(d => d.dirty).length'), 2);
    await pick(p, 'File', 'Save All');
    await p.wait('RC.app.docs.filter(d => d.dirty).length === 0', 2000);
    p.assert.match(await fileText(p, 'C:\\MYPROGS\\ALL1.BAS'), /ONE/);
    p.assert.match(await fileText(p, 'C:\\MYPROGS\\ALL2.BAS'), /TWO/);
  }, { fresh: true });
  t.test('File ▸ Download to Computer downloads the active file by name', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\DLME.BAS');
    await trapDownloads(p);
    await pick(p, 'File', 'Download to Computer');
    await p.wait('window.__dl.length === 1', 2000);
    p.assert.equal(await p.ev('window.__dl[0]'), 'DLME.BAS');
  });
  t.test('File ▸ Share Project as Link… opens the Share Project dialog with a #share= link', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\SHR.BAS');
    await pick(p, 'File', 'Share Project as Link…');
    p.assert.equal(await p.waitModal(6000), 'Share Project');
    p.assert.match(await p.ev("document.querySelector('.modal input[aria-label=\"Share link\"]').value"), /#share=CPD1\./);
  });
  t.test('File ▸ Import Shared Code… opens the import dialog with a code box', async (p) => {
    await pick(p, 'File', 'Import Shared Code…');
    p.assert.equal(await p.waitModal(), 'Import Shared Project');
    p.assert.equal(await p.count('.modal textarea[aria-label="Share code"]'), 1);
  });
  t.test('File ▸ Download Project (.zip) downloads the active folder as a zip', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\ZIPME.BAS');
    await trapDownloads(p);
    await pick(p, 'File', 'Download Project (.zip)');
    await p.wait('window.__dl.length === 1', 2000);
    p.assert.equal(await p.ev('window.__dl[0]'), 'MYPROGS.zip');
  });
  t.test('File ▸ Mount Computer Folder as D:… mounts the chosen folder as D:', async (p) => {
    await p.ev("window.showDirectoryPicker = async () => ({ name: 'FAKEDIR', entries: async function* () {} })");
    await pick(p, 'File', 'Mount Computer Folder as D:…');
    p.assert.equal(await p.waitModal(), 'Mount a Folder as Drive D:');
    await p.modalButton('Choose Folder…');
    await p.wait('!!RC.app.vfs.drives.D', 3000);
    await p.waitToast(/Mounted "FAKEDIR" as D:/);
    await p.wait("[...document.querySelectorAll('#explorerTree .tree-item .nm')].some(e => /^D: \\(FAKEDIR/.test(e.textContent))", 2000);
  });
  t.test('File ▸ Unmount D: removes the mounted drive from the explorer', async (p) => {
    if (!(await p.ev('!!RC.app.vfs.drives.D'))) await p.ev("RC.app.vfs.mountHandle('D', { name: 'FAKEDIR', entries: async function* () {} }, 'read')");
    await p.wait('!!RC.app.vfs.drives.D');
    await pick(p, 'File', 'Unmount D:');
    await p.wait('!RC.app.vfs.drives.D', 2000);
    p.assert.equal(await p.ev("[...document.querySelectorAll('#explorerTree .tree-item .nm')].some(e => /^D:/.test(e.textContent))"), false);
    p.assert.equal(await p.ev("[...document.querySelectorAll('#explorerTree .tree-item .nm')].some(e => /^C:/.test(e.textContent))"), true);
  });
  t.test('File ▸ Close Tab closes the active tab', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\CLOSEME.BAS');
    const n = await p.ev('RC.app.docs.length');
    await pick(p, 'File', 'Close Tab');
    await p.wait(`RC.app.docs.length === ${n - 1}`, 2000);
    p.assert.equal(await p.ev("!!RC.app.docByPath('C:\\\\MYPROGS\\\\CLOSEME.BAS')"), false);
  });
  t.test('File ▸ Close Tab on a changed file asks to save first', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\DIRTY.BAS');
    await p.setCode('PRINT 2\n');
    await p.ev('RC.app.settings.autosave = false');
    await pick(p, 'File', 'Close Tab');
    p.assert.equal(await p.waitModal(), 'Unsaved changes');
    await p.modalButton("Don't Save");
    await p.wait("!RC.app.docByPath('C:\\\\MYPROGS\\\\DIRTY.BAS')", 2000);
    await p.ev('RC.app.settings.autosave = true');
  });

  // ---- Edit ------------------------------------------------------------------------------------------
  t.test('Edit ▸ Undo reverts the last typing and Edit ▸ Redo restores it', async (p) => {
    await prog(p, 'PRINT 1\n', 'C:\\MYPROGS\\UNDO.BAS');
    await caret(p, 0, 7);
    await p.insertText('23');
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(0)'), 'PRINT 123');
    await pick(p, 'Edit', 'Undo');
    await p.wait("RC.app.active.editor.getLine(0) === 'PRINT 1'", 2000);
    await pick(p, 'Edit', 'Redo');
    await p.wait("RC.app.active.editor.getLine(0) === 'PRINT 123'", 2000);
  });
  t.test('Edit ▸ Find… opens the find bar with the search box focused', async (p) => {
    await prog(p, 'PRINT 1\n');
    await pick(p, 'Edit', 'Find…');
    p.assert.equal(await p.ev("document.getElementById('findbar').hidden"), false);
    p.assert.equal(await p.ev("document.activeElement.getAttribute('aria-label')"), 'Find');
    p.assert.equal(await p.count('#findbar input[aria-label="Replace with"]'), 0);
  });
  t.test('Edit ▸ Replace… opens the find bar with a replace box', async (p) => {
    await prog(p, 'PRINT 1\n');
    await pick(p, 'Edit', 'Replace…');
    p.assert.equal(await p.ev("document.getElementById('findbar').hidden"), false);
    p.assert.equal(await p.count('#findbar input[aria-label="Replace with"]'), 1);
  });
  t.test('Edit ▸ Go to Line… moves the caret to the given line', async (p) => {
    await prog(p, 'a = 1\nb = 2\nc = 3\nd = 4\n');
    await caret(p, 0);
    await pick(p, 'Edit', 'Go to Line…');
    p.assert.equal(await p.waitModal(), 'Go to Line');
    await p.modalInput('3');
    await p.key('Enter');
    await p.wait('RC.app.active.editor.cursor().line === 2', 2000);
  });
  t.test('Edit ▸ Toggle Comment comments the caret line', async (p) => {
    await prog(p, 'PRINT 1\nPRINT 2\n');
    await caret(p, 1);
    await pick(p, 'Edit', 'Toggle Comment');
    p.assert.match(await p.ev('RC.app.active.editor.getLine(1)'), /^'\s?PRINT 2/);
    p.assert.equal(await p.ev('RC.app.active.editor.getLine(0)'), 'PRINT 1');
  });
  t.test('Edit ▸ Duplicate Line duplicates the caret line', async (p) => {
    await prog(p, 'PRINT 1\nPRINT 2\n');
    await caret(p, 0);
    await pick(p, 'Edit', 'Duplicate Line');
    p.assert.deepEqual((await p.code()).split('\n').slice(0, 3), ['PRINT 1', 'PRINT 1', 'PRINT 2']);
  });
  t.test('Edit ▸ Capitalize Keywords uppercases every keyword in the file', async (p) => {
    await prog(p, 'print "hi"\nfor i = 1 to 2\nnext i\n');
    await pick(p, 'Edit', 'Capitalize Keywords');
    const c = await p.code();
    p.assert.match(c, /^PRINT "hi"/);
    p.assert.match(c, /FOR i = 1 TO 2/);
    p.assert.match(c, /NEXT i/);
  });
  t.test('Edit ▸ Renumber Lines (RENUM)… renumbers lines and GOTO targets', async (p) => {
    await prog(p, '10 PRINT 1\n20 GOTO 10\n');
    await pick(p, 'Edit', 'Renumber Lines (RENUM)…');
    p.assert.equal(await p.waitModal(), 'Renumber (RENUM)');
    p.assert.equal(await modalVal(p), '10,,10');
    await p.modalInput('100,,10');
    await p.modalButton('OK');
    await p.wait("/^100 PRINT 1\\n110 GOTO 100/.test(RC.app.active.editor.getValue())", 2000);
  });
  t.test('Edit ▸ Add Line Numbers… numbers every line 10, 20, …', async (p) => {
    await prog(p, 'PRINT 1\nPRINT 2\n');
    await pick(p, 'Edit', 'Add Line Numbers…');
    p.assert.equal(await p.waitModal(), 'Add line numbers');
    await p.modalButton('Add Numbers');
    await p.wait("/^10 PRINT 1\\n20 PRINT 2/.test(RC.app.active.editor.getValue())", 2000);
  });
  t.test('Edit ▸ Add Line Numbers… refuses a program that already has numbers', async (p) => {
    await prog(p, '10 PRINT 1\n');
    await pick(p, 'Edit', 'Add Line Numbers…');
    await p.waitToast(/already has line numbers/);
    p.assert.equal(await p.modalOpen(), false);
  });

  // ---- View ------------------------------------------------------------------------------------------
  t.test('View ▸ Output Screen Full Size toggles the full-size screen on and off', async (p) => {
    await pick(p, 'View', 'Output Screen Full Size');
    p.assert.equal(await isMax(p), true);
    // the full-size screen covers the menubar, so reopen View from the keyboard
    await p.key('v', { alt: true });
    await p.wait("!!document.querySelector('.menu-pop')", 2000);
    await p.key('Enter');
    await p.sleep(80);
    p.assert.equal(await isMax(p), false);
  });
  t.test('View ▸ GW-BASIC Classic Console switches the screen into the console and back', async (p) => {
    await pick(p, 'View', 'GW-BASIC Classic Console');
    p.assert.equal(await p.ev('RC.app.console.active'), true);
    p.assert.equal(await p.ev("document.getElementById('screenTitle').textContent"), 'GW-BASIC Console');
    p.assert.match(await p.screen(), /Bytes free/);
    await pick(p, 'View', 'GW-BASIC Classic Console');
    p.assert.equal(await p.ev('RC.app.console.active'), false);
    p.assert.equal(await p.ev("document.getElementById('screenTitle').textContent"), 'Output');
  });
  t.test('View ▸ Explorer hides and shows the explorer', async (p) => {
    await pick(p, 'View', 'Explorer');
    p.assert.equal(await setting(p, 'showExplorer'), false);
    p.assert.equal(await p.ev("document.getElementById('workspace').classList.contains('no-explorer')"), true);
    p.assert.equal(await p.visible('#explorerTree'), false);
    await pick(p, 'View', 'Explorer');
    p.assert.equal(await setting(p, 'showExplorer'), true);
    p.assert.equal(await p.visible('#explorerTree'), true);
  });
  t.test('View ▸ SUBs and FUNCTIONs… lists the procedures and jumps to one', async (p) => {
    await prog(p, 'CALL Foo\nPRINT Bar%(1)\nSUB Foo\nEND SUB\nFUNCTION Bar% (x)\nEND FUNCTION\n');
    await caret(p, 0);
    await pick(p, 'View', 'SUBs and FUNCTIONs…');
    p.assert.equal(await p.waitModal(), 'SUBs');
    const rows = await p.texts('.modal .list-row');
    p.assert.equal(rows.length, 3);
    p.assert.match(rows[1], /SUB Foo/);
    p.assert.match(rows[2], /FUNCTION Bar%/);
    await p.click('.modal .list-row', 'FUNCTION');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.ev('RC.app.active.editor.cursor().line'), 4);
  });
  for (const [label, id] of [['Immediate', 'immediate'], ['Variables', 'vars'], ['Watch', 'watch'], ['Call Stack', 'stack'],
    ['Breakpoints', 'bps'], ['History / Trace', 'history'], ['Printer', 'printer']]) {
    t.test(`View ▸ ${label} switches the bottom panel to ${id}`, async (p) => {
      await p.panel(id === 'immediate' ? 'printer' : 'immediate');
      await pick(p, 'View', label);
      p.assert.equal(await activePanel(p), id);
      p.assert.equal(await p.count('#bottomBody .bpanel.active'), 1);
      p.assert.equal(await p.ev('RC.app.panels.active'), id);
    });
  }
  t.test('View ▸ Zoom In grows the editor font by one pixel', async (p) => {
    const f = await setting(p, 'fontSize');
    await pick(p, 'View', 'Zoom In');
    p.assert.equal(await setting(p, 'fontSize'), f + 1);
    p.assert.equal(await p.ev("document.documentElement.style.getPropertyValue('--ed-font-size')"), (f + 1) + 'px');
  }, { fresh: true });
  t.test('View ▸ Zoom Out shrinks the editor font by one pixel', async (p) => {
    const f = await setting(p, 'fontSize');
    await pick(p, 'View', 'Zoom Out');
    p.assert.equal(await setting(p, 'fontSize'), f - 1);
    p.assert.equal(await p.ev("document.documentElement.style.getPropertyValue('--ed-font-size')"), (f - 1) + 'px');
  }, { fresh: true });
  t.test('View ▸ Zoom In stops at 28px and Zoom Out at 10px', async (p) => {
    await p.ev('RC.app.settings.fontSize = 28; RC.app.applyTheme()');
    await pick(p, 'View', 'Zoom In');
    p.assert.equal(await setting(p, 'fontSize'), 28);
    await p.ev('RC.app.settings.fontSize = 10; RC.app.applyTheme()');
    await pick(p, 'View', 'Zoom Out');
    p.assert.equal(await setting(p, 'fontSize'), 10);
  }, { fresh: true });

  // ---- Run -------------------------------------------------------------------------------------------------
  t.test('Run ▸ Start runs the program in the editor', async (p) => {
    await prog(p, 'PRINT "MENU START"; 3 * 4\n');
    await pick(p, 'Run', 'Start');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /MENU START 12/);
  });
  t.test('Run ▸ Continue resumes a paused program to the end', async (p) => {
    await pausedAtStart(p);
    await pick(p, 'Run', 'Continue');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /\b6\b/);
  });
  t.test('Run ▸ Restart starts a fresh run of a running program', async (p) => {
    await startLoop(p);
    const n = await p.ev('RC.app.runCount');
    await pick(p, 'Run', 'Restart');
    await p.waitState(['running', 'waiting']);
    p.assert.equal(await p.ev('RC.app.runCount'), n + 1);
  });
  t.test('Run ▸ Restart from idle simply runs the program', async (p) => {
    await prog(p, 'PRINT "AGAIN"\n');
    await pick(p, 'Run', 'Restart');
    await p.waitState('ended');
    p.assert.match(await p.screen(), /AGAIN/);
  });
  t.test('Run ▸ Pause pauses a running program', async (p) => {
    await startLoop(p);
    await pick(p, 'Run', 'Pause');
    await p.waitState('paused');
    p.assert.equal(await p.text('#tbState'), 'Paused');
  });
  t.test('Run ▸ Stop stops a running program', async (p) => {
    await startLoop(p);
    await pick(p, 'Run', 'Stop');
    await p.wait("!['running','waiting','paused'].includes(RC.app.runner.state)", 2000);
    p.assert.match(await p.status(), /Stopped/);
  });
  t.test('Run ▸ Stop stops a paused program', async (p) => {
    await pausedAtStart(p);
    await pick(p, 'Run', 'Stop');
    await p.wait("!['running','waiting','paused'].includes(RC.app.runner.state)", 2000);
  });
  t.test('Run ▸ Run to Cursor pauses at the caret line', async (p) => {
    await prog(p, STEPS);
    await caret(p, 2);
    await pick(p, 'Run', 'Run to Cursor');
    await p.waitState('paused');
    p.assert.equal(await pauseLine(p), 2);
  });
  t.test('Run ▸ Run to Cursor while paused stops at the caret line', async (p) => {
    await pausedAtStart(p);
    await caret(p, 3);
    await pick(p, 'Run', 'Run to Cursor');
    await p.waitState(['paused', 'ended']);
    await p.sleep(100);
    p.assert.equal(await p.state(), 'paused', 'program ran to the end instead of stopping at line 4');
    p.assert.equal(await pauseLine(p), 3);
  });
  t.test('Run ▸ Set Next Statement moves execution to the caret line', async (p) => {
    await pausedAtStart(p);
    p.assert.equal(await pauseLine(p), 0);
    await caret(p, 3);
    await pick(p, 'Run', 'Set Next Statement');
    await p.sleep(100);
    p.assert.equal(await pauseLine(p), 3);
    await p.ev('RC.app.continue()');
    await p.waitState('ended');
    p.assert.doesNotMatch(await p.screen(), /\b6\b/);
  });
  const SPEEDS = [['Full speed', 0], ['Fast PC (≈ 486)', 400000], ['Classic PC (≈ 8 MHz 286)', 25000], ['Original IBM PC (≈ 4.77 MHz)', 4000],
    ['Slow motion (20 statements/s)', 20], ['Step-by-step crawl (3 statements/s)', 3]];
  for (const [label, v] of SPEEDS.slice(1).concat([SPEEDS[0]])) {
    t.test(`Run ▸ Speed ▸ ${label} sets speed ${v} in settings, runner and toolbar`, async (p) => {
      await pickSub(p, 'Run', 'Speed', label);
      p.assert.equal(await setting(p, 'speed'), v);
      p.assert.equal(await p.ev('RC.app.runner.speed'), v);
      p.assert.equal(await p.ev("document.getElementById('tbSpeed').value"), String(v));
      p.assert.equal(await p.ev("JSON.parse(localStorage.getItem('baysik.settings')).speed"), v);
    });
  }
  t.test('Run ▸ Speed applies to a running program (slow motion executes slowly)', async (p) => {
    await pickSub(p, 'Run', 'Speed', 'Step-by-step crawl (3 statements/s)');
    await startLoop(p);
    await p.sleep(700);
    const n = await p.ev('RC.app.runner.vm.statementsExecuted');
    await p.ev('RC.app.stop(); RC.app.setSpeed(0)');
    p.assert.ok(n <= 10, `executed ${n} statements in 0.7s at 3/s`);
  });
  t.test('Run ▸ Output Screen toggles the full-size output screen', async (p) => {
    await pick(p, 'Run', 'Output Screen');
    p.assert.equal(await isMax(p), true);
    await p.key('Escape');
    p.assert.equal(await isMax(p), false);
  });
};
