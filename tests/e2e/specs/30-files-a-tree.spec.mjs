// File explorer: tree rendering, expand/collapse, selection, header buttons, New Program / New Folder dialogs.
import * as H from './30-files-helpers.mjs';

const HELLO = 'C:\\MYPROGS\\HELLO.BAS';

export default (reg) => {
  const t = H.safe(reg);
  t.beforeEach(async (p) => { await p.closeMenus(); });

  // ---- tree rendering ------------------------------------------------------------------------------------
  t.test('first explorer row is the C: drive labelled "(virtual disk)" and expanded', async (p) => {
    const r = await H.rows(p);
    p.assert.equal(r[0].name, 'C: (virtual disk)');
    p.assert.equal(r[0].isDir, true);
    p.assert.equal(r[0].expanded, true);
    p.assert.equal(r[0].tw, '▾');
    p.assert.equal(r[0].pad, 6);
  }, { fresh: true });

  t.test('default expansion shows C:\\, MYPROGS and SAMPLES but keeps SAMPLES\\MULTI collapsed', async (p) => {
    const paths = await H.rowPaths(p);
    p.assert.ok(paths.includes('C:\\MYPROGS'));
    p.assert.ok(paths.includes(HELLO));
    p.assert.ok(paths.includes('C:\\SAMPLES\\GUESS.BAS'));
    const multi = await H.row(p, 'C:\\SAMPLES\\MULTI');
    p.assert.equal(multi.expanded, false);
    p.assert.equal(multi.tw, '▸');
    p.assert.equal(await H.row(p, 'C:\\SAMPLES\\MULTI\\MAIN.BAS'), null);
  });

  t.test('folders are listed before files inside a folder', async (p) => {
    await H.mkdirs(p, 'C:\\MYPROGS\\ZETA');
    await H.writeRaw(p, 'C:\\MYPROGS\\AAA.BAS', 'PRINT 1');
    await H.waitRow(p, 'C:\\MYPROGS\\AAA.BAS');
    const kids = (await H.rows(p)).filter((x) => /^C:\\MYPROGS\\[^\\]+$/.test(x.path)).map((x) => x.name);
    p.assert.deepEqual(kids, ['ZETA', 'AAA.BAS', 'HELLO.BAS']);
  }, { fresh: true });

  t.test('files within a folder are sorted alphabetically', async (p) => {
    const names = (await H.rows(p)).filter((x) => !x.isDir && /^C:\\SAMPLES\\[^\\]+$/.test(x.path)).map((x) => x.name);
    p.assert.ok(names.length >= 20);
    p.assert.deepEqual(names, names.slice().sort((a, b) => a.localeCompare(b)));
  });

  t.test('in SAMPLES the MULTI sub-folder comes before every file', async (p) => {
    const kids = (await H.rows(p)).filter((x) => /^C:\\SAMPLES\\[^\\]+$/.test(x.path));
    p.assert.equal(kids[0].name, 'MULTI');
    p.assert.ok(kids.slice(1).every((x) => !x.isDir));
  });

  t.test('top-level folders under C: are sorted (MYPROGS before SAMPLES)', async (p) => {
    const top = (await H.rows(p)).filter((x) => x.isDir && x.depth === 1).map((x) => x.name);
    p.assert.deepEqual(top, ['MYPROGS', 'SAMPLES']);
  });

  t.test('clicking a collapsed folder expands it and shows its files', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\MULTI');
    const multi = await H.row(p, 'C:\\SAMPLES\\MULTI');
    p.assert.equal(multi.expanded, true);
    p.assert.equal(multi.tw, '▾');
    for (const f of ['MAIN.BAS', 'PART2.BAS', 'SHAPES.BI']) p.assert.ok(await H.row(p, 'C:\\SAMPLES\\MULTI\\' + f), f);
  }, { fresh: true });

  t.test('files in a nested folder are indented further than their parent folder\'s files', async (p) => {
    const a = await H.row(p, 'C:\\SAMPLES\\MULTI\\MAIN.BAS');
    const b = await H.row(p, 'C:\\SAMPLES\\GUESS.BAS');
    p.assert.equal(a.pad - b.pad, 12);
    const folder = await H.row(p, 'C:\\SAMPLES\\MULTI');
    p.assert.ok(a.pad > folder.pad);
  });

  t.test('clicking an expanded folder collapses it and hides its contents', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\MULTI');
    p.assert.equal((await H.row(p, 'C:\\SAMPLES\\MULTI')).expanded, false);
    p.assert.equal(await H.row(p, 'C:\\SAMPLES\\MULTI\\MAIN.BAS'), null);
  });

  t.test('clicking a folder highlights it as selected', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES');
    const r = await H.row(p, 'C:\\SAMPLES');
    p.assert.equal(r.selected, true);
    p.assert.equal((await H.row(p, 'C:\\MYPROGS')).selected, false);
  }, { fresh: true });

  t.test('collapsing the drive row hides every folder', async (p) => {
    await H.clickRow(p, 'C:\\');
    const r = await H.rows(p);
    p.assert.equal(r.length, 1);
    p.assert.equal(r[0].expanded, false);
    await H.clickRow(p, 'C:\\');
    p.assert.ok((await H.rows(p)).length > 5);
  }, { fresh: true });

  t.test('expanded folders are stored in localStorage', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\MULTI');
    const saved = await p.ev("JSON.parse(localStorage.getItem('baysik.expandedDirs'))");
    p.assert.ok(saved.includes('C:\\SAMPLES\\MULTI'));
  }, { fresh: true });

  t.test('an expanded folder stays expanded after reload', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\MULTI');
    await p.reload();
    p.assert.equal((await H.row(p, 'C:\\SAMPLES\\MULTI')).expanded, true);
    p.assert.ok(await H.row(p, 'C:\\SAMPLES\\MULTI\\PART2.BAS'));
  }, { fresh: true });

  t.test('a collapsed folder stays collapsed after reload', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES');
    p.assert.equal((await H.row(p, 'C:\\SAMPLES')).expanded, false);
    await p.reload();
    p.assert.equal((await H.row(p, 'C:\\SAMPLES')).expanded, false);
    p.assert.equal(await H.row(p, 'C:\\SAMPLES\\GUESS.BAS'), null);
  }, { fresh: true });

  t.test('the active document\'s file row is highlighted', async (p) => {
    const r = await H.row(p, HELLO);
    p.assert.equal(r.selected, true);
    p.assert.equal((await H.rows(p)).filter((x) => !x.isDir && x.selected).length, 1);
  }, { fresh: true });

  t.test('opening another file moves the highlight to it', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\GUESS.BAS');
    p.assert.equal((await H.row(p, 'C:\\SAMPLES\\GUESS.BAS')).selected, true);
    p.assert.equal((await H.row(p, HELLO)).selected, false);
  });

  t.test('switching tabs moves the explorer highlight', async (p) => {
    await p.click('#editorTabs .tab', 'HELLO.BAS');
    p.assert.equal((await H.row(p, HELLO)).selected, true);
    p.assert.equal((await H.row(p, 'C:\\SAMPLES\\GUESS.BAS')).selected, false);
  });

  t.test('file rows have a tooltip with full path and byte size', async (p) => {
    const r = await H.row(p, HELLO);
    const size = await p.fn((x) => RC.app.vfs.stat(x).size, HELLO);
    p.assert.equal(r.title, `${HELLO} (${size} bytes)`);
  });

  t.test('clicking a file opens it in a new active tab', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\COLORS.BAS');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\COLORS.BAS');
    p.assert.ok((await H.tabNames(p)).includes('COLORS.BAS'));
    p.assert.equal(await p.code(), await H.readText(p, 'C:\\SAMPLES\\COLORS.BAS'));
  }, { fresh: true });

  t.test('clicking an already open file re-activates its tab without duplicating it', async (p) => {
    await H.clickRow(p, HELLO);
    await H.clickRow(p, 'C:\\SAMPLES\\COLORS.BAS');
    const t2 = await H.tabs(p);
    p.assert.equal(t2.filter((x) => x === 'C:\\SAMPLES\\COLORS.BAS').length, 1);
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\COLORS.BAS');
  });

  t.test('double-clicking a .BAS file opens and runs it', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\DBL.BAS', 'PRINT "DOUBLE CLICKED"\r\n');
    await H.waitRow(p, 'C:\\MYPROGS\\DBL.BAS');
    await H.dblclickRow(p, 'C:\\MYPROGS\\DBL.BAS');
    await p.waitScreen(/DOUBLE CLICKED/);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\DBL.BAS');
  }, { fresh: true });

  t.test('double-clicking a non-.BAS file does not run anything', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\NOTE.TXT', 'PRINT "NOPE"\r\n');
    await H.waitRow(p, 'C:\\MYPROGS\\NOTE.TXT');
    await H.dblclickRow(p, 'C:\\MYPROGS\\NOTE.TXT');
    await p.sleep(200);
    p.assert.equal(await p.state(), 'idle');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\NOTE.TXT');
  }, { fresh: true });

  t.test('pressing Enter on a focused file row opens it', async (p) => {
    await p.fn(() => { const el = [...document.querySelectorAll('#explorerTree .tree-item')].find((e) => e.innerText.trim() === 'TURTLE.BAS'); el.focus(); });
    await p.key('Enter');
    await p.sleep(80);
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\TURTLE.BAS');
  }, { fresh: true });

  t.test('a large non-text file is selected but not opened in an editor', async (p) => {
    await p.ev("RC.app.vfs.writeFile('C:\\\\MYPROGS\\\\BIG.BIN', new Uint8Array(70000), {trusted: true})");
    await H.waitRow(p, 'C:\\MYPROGS\\BIG.BIN');
    const before = await H.tabs(p);
    await H.clickRow(p, 'C:\\MYPROGS\\BIG.BIN');
    p.assert.deepEqual(await H.tabs(p), before);
    p.assert.equal(await p.ev('RC.app.selectedPath'), 'C:\\MYPROGS\\BIG.BIN');
  }, { fresh: true });

  t.test('a small file with an unknown extension still opens', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\SMALL.XYZ', 'hello xyz');
    await H.waitRow(p, 'C:\\MYPROGS\\SMALL.XYZ');
    await H.clickRow(p, 'C:\\MYPROGS\\SMALL.XYZ');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\SMALL.XYZ');
    p.assert.equal(await p.code(), 'hello xyz');
  });

  t.test('a large .TXT file opens despite its size', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\LONG.TXT', 'X'.repeat(70000));
    await H.waitRow(p, 'C:\\MYPROGS\\LONG.TXT');
    await H.clickRow(p, 'C:\\MYPROGS\\LONG.TXT');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\LONG.TXT');
    p.assert.equal((await p.code()).length, 70000);
  });

  t.test('folder and file names keep their original letter case in the tree', async (p) => {
    await H.mkdirs(p, 'C:\\MYPROGS\\Games');
    await H.writeRaw(p, 'C:\\MYPROGS\\Games\\pong.bas', 'PRINT 1');
    await p.fn(() => { RC.app.expandedDirs.add('C:\\MYPROGS\\GAMES'); RC.app.renderExplorer(); });
    const r = await H.rows(p);
    p.assert.ok(r.some((x) => x.name === 'Games' && x.isDir));
    p.assert.ok(r.some((x) => x.name === 'pong.bas' && !x.isDir));
  }, { fresh: true });

  t.test('files written to the disk behind the explorer\'s back appear automatically', async (p) => {
    p.assert.equal(await H.row(p, 'C:\\MYPROGS\\LATER.BAS'), null);
    await H.writeRaw(p, 'C:\\MYPROGS\\LATER.BAS', 'PRINT 2');
    const r = await H.waitRow(p, 'C:\\MYPROGS\\LATER.BAS', true, 2000);
    p.assert.match(r.title, /\(7 bytes\)/);
  }, { fresh: true });

  t.test('files removed from the disk disappear from the explorer automatically', async (p) => {
    await p.ev("RC.app.vfs.unlink('C:\\\\MYPROGS\\\\LATER.BAS')");
    await H.waitRow(p, 'C:\\MYPROGS\\LATER.BAS', false, 2000);
  });

  t.test('View ▸ Explorer hides and shows the explorer pane', async (p) => {
    p.assert.equal(await p.visible('#explorerTree'), true);
    await p.menu('View', 'Explorer');
    p.assert.equal(await p.ev("document.getElementById('workspace').classList.contains('no-explorer')"), true);
    p.assert.equal(await p.visible('#explorerTree'), false);
    await p.menu('View', 'Explorer');
    p.assert.equal(await p.visible('#explorerTree'), true);
  }, { fresh: true });

  // ---- explorer header buttons ------------------------------------------------------------------------------
  t.test('explorer header has the five action buttons in order', async (p) => {
    const titles = await p.ev("[...document.querySelectorAll('#explorerActions button')].map(b => b.title)");
    p.assert.deepEqual(titles, ['New program', 'New folder', 'Import files from computer', 'Mount a computer folder as D:', 'Share project']);
    const labels = await p.ev("[...document.querySelectorAll('#explorerActions button')].map(b => b.getAttribute('aria-label'))");
    p.assert.deepEqual(labels, titles);
  });

  t.test('New program button opens the New Program dialog', async (p) => {
    await H.headerBtn(p, 'New program');
    p.assert.equal(await p.waitModal(), 'New Program');
    p.assert.match(await p.modalText(), /File name/);
    p.assert.deepEqual(await H.modalButtons(p), ['Cancel', 'OK']);
  }, { fresh: true });

  t.test('New Program dialog proposes UNTITLED.BAS and says where it is created', async (p) => {
    p.assert.equal(await H.modalInputValue(p), 'UNTITLED.BAS');
    p.assert.match(await p.modalText(), /Created in C:\\MYPROGS\./);
  });

  t.test('accepting the default creates C:\\MYPROGS\\UNTITLED.BAS with a starter program', async (p) => {
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\UNTITLED.BAS');
    p.assert.equal(await p.code(), '\' UNTITLED.BAS\nCLS\nPRINT "Hello!"\n');
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\UNTITLED.BAS'), '\' UNTITLED.BAS\r\nCLS\r\nPRINT "Hello!"\r\n');
  });

  t.test('the new program\'s cursor is placed on line 3 (the PRINT line)', async (p) => {
    p.assert.deepEqual(await p.ev('(({line}) => line)(RC.app.active.editor.cursor())'), 2);
  });

  t.test('the new program appears highlighted in the explorer and is not dirty', async (p) => {
    const r = await H.waitRow(p, 'C:\\MYPROGS\\UNTITLED.BAS');
    p.assert.equal(r.selected, true);
    p.assert.equal(await H.activeDirty(p), false);
  });

  t.test('the next New Program proposes UNTITLED2.BAS', async (p) => {
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'UNTITLED2.BAS');
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\UNTITLED2.BAS');
  });

  t.test('and the one after proposes UNTITLED3.BAS', async (p) => {
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'UNTITLED3.BAS');
  });

  t.test('New Program adds .BAS to a name without an extension', async (p) => {
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'ROCKET', 'New Program');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\ROCKET.BAS');
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\ROCKET.BAS'), true);
    p.assert.match(await p.code(), /^' ROCKET\.BAS\n/);
  }, { fresh: true });

  t.test('New Program keeps an explicit extension', async (p) => {
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'NOTES.TXT');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\NOTES.TXT');
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\NOTES.BAS'), false);
  });

  t.test('New Program accepts a name typed with the real keyboard and Enter', async (p) => {
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    await p.type('TYPED\n');
    await p.sleep(120);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\TYPED.BAS');
  });

  t.test('New Program accepts a full path into an existing folder', async (p) => {
    await H.mkdirs(p, 'C:\\WORK');
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'C:\\WORK\\JOB.BAS');
    p.assert.equal(await p.activePath(), 'C:\\WORK\\JOB.BAS');
    p.assert.equal(await H.exists(p, 'C:\\WORK\\JOB.BAS'), true);
  });

  t.test('New Program accepts a relative sub-folder path', async (p) => {
    await H.mkdirs(p, 'C:\\MYPROGS\\SUB');
    await p.fn(() => RC.app.openFile('C:\\MYPROGS\\HELLO.BAS'));
    await p.fn(() => { RC.app.selectedPath = null; });
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'SUB\\INNER');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\SUB\\INNER.BAS');
  });

  t.test('New Program with a full path into a new folder (as the hint suggests) creates the folder', async (p) => {
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    p.assert.match(await p.modalText(), /C:\\GAMES\\PONG\.BAS/);
    await H.answerPrompt(p, 'C:\\GAMES\\PONG.BAS');
    p.assert.equal(await H.exists(p, 'C:\\GAMES\\PONG.BAS'), true);
    p.assert.equal(await p.activePath(), 'C:\\GAMES\\PONG.BAS');
  }, { fresh: true });

  t.test('New Program with an existing name opens that file without overwriting it', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\KEEP.BAS', 'PRINT "ORIGINAL"\r\n');
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'KEEP.BAS');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\KEEP.BAS');
    p.assert.equal(await p.code(), 'PRINT "ORIGINAL"\n');
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\KEEP.BAS'), 'PRINT "ORIGINAL"\r\n');
  }, { fresh: true });

  t.test('New Program existing-name match is case-insensitive', async (p) => {
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'keep');
    p.assert.equal(await p.code(), 'PRINT "ORIGINAL"\n');
    p.assert.equal(await p.ev("RC.app.vfs.list('C:\\\\MYPROGS').filter(e => /^keep\\.bas$/i.test(e.name)).length"), 1);
  });

  t.test('Cancel in New Program creates nothing', async (p) => {
    const before = await p.ev("RC.app.vfs.drives.C.entries.size");
    const tabsBefore = await H.tabs(p);
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    await p.modalButton('Cancel');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.ev("RC.app.vfs.drives.C.entries.size"), before);
    p.assert.deepEqual(await H.tabs(p), tabsBefore);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\UNTITLED.BAS'), false);
  }, { fresh: true });

  t.test('Escape in New Program creates nothing', async (p) => {
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    await p.key('Escape');
    await p.sleep(80);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\UNTITLED.BAS'), false);
  });

  t.test('an empty name in New Program creates nothing', async (p) => {
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, '');
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\UNTITLED.BAS'), false);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\.BAS'), false);
  });

  t.test('an invalid name in New Program shows an error toast', async (p) => {
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'BAD|NAME');
    await p.waitToast(/Could not create file/);
    p.assert.equal(await p.activePath(), HELLO);
  });

  t.test('New Program goes into the folder selected in the explorer', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\MULTI');
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    p.assert.match(await p.modalText(), /Created in C:\\SAMPLES\\MULTI/);
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\MULTI\\UNTITLED.BAS');
  }, { fresh: true });

  t.test('with a file selected, New Program goes into the active file\'s folder', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\GUESS.BAS');
    await H.headerBtn(p, 'New program');
    await p.waitModal();
    p.assert.match(await p.modalText(), /Created in C:\\SAMPLES\./);
  }, { fresh: true });

  t.test('Alt+N opens the New Program dialog', async (p) => {
    await p.ev('RC.app.active.editor.focus()');
    await p.key('n', { alt: true });
    p.assert.equal(await p.waitModal(), 'New Program');
  }, { fresh: true });

  t.test('File ▸ New Program opens the New Program dialog', async (p) => {
    await p.menu('File', 'New Program');
    p.assert.equal(await p.waitModal(), 'New Program');
    p.assert.equal(await H.modalInputValue(p), 'UNTITLED.BAS');
  }, { fresh: true });

  // ---- New Folder ---------------------------------------------------------------------------------------------
  t.test('New folder button opens the New Folder dialog proposing PROJECT', async (p) => {
    await H.headerBtn(p, 'New folder');
    p.assert.equal(await p.waitModal(), 'New Folder');
    p.assert.equal(await H.modalInputValue(p), 'PROJECT');
    p.assert.match(await p.modalText(), /Folder name/);
  }, { fresh: true });

  t.test('accepting New Folder creates it next to the active file, expanded in the tree', async (p) => {
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await H.isDir(p, 'C:\\MYPROGS\\PROJECT'), true);
    const r = await H.waitRow(p, 'C:\\MYPROGS\\PROJECT');
    p.assert.equal(r.expanded, true);
    p.assert.equal(r.isDir, true);
  });

  t.test('New Folder with an existing name shows an error toast', async (p) => {
    await H.headerBtn(p, 'New folder');
    await H.answerPrompt(p, 'PROJECT');
    await p.waitToast(/Could not create folder/);
  });

  t.test('New Folder inside the selected folder', async (p) => {
    await H.clickRow(p, 'C:\\MYPROGS\\PROJECT');
    await H.headerBtn(p, 'New folder');
    await H.answerPrompt(p, 'ASSETS');
    p.assert.equal(await H.isDir(p, 'C:\\MYPROGS\\PROJECT\\ASSETS'), true);
    // selecting PROJECT by clicking toggled it closed; expand it again to see the new sub-folder
    p.assert.equal((await H.row(p, 'C:\\MYPROGS\\PROJECT')).expanded, false);
    await H.clickRow(p, 'C:\\MYPROGS\\PROJECT');
    p.assert.ok(await H.waitRow(p, 'C:\\MYPROGS\\PROJECT\\ASSETS'));
  });

  t.test('Cancel in New Folder creates nothing', async (p) => {
    const before = await p.ev("RC.app.vfs.drives.C.entries.size");
    await H.headerBtn(p, 'New folder');
    await p.waitModal();
    await p.modalButton('Cancel');
    p.assert.equal(await p.ev("RC.app.vfs.drives.C.entries.size"), before);
  });

  t.test('New Folder with an invalid name shows an error toast', async (p) => {
    await H.headerBtn(p, 'New folder');
    await H.answerPrompt(p, 'A*B');
    await p.waitToast(/Could not create folder/);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\A*B'), false);
  });

  t.test('File ▸ New Folder… creates a folder', async (p) => {
    await p.menu('File', 'New Folder…');
    await H.answerPrompt(p, 'FROMMENU', 'New Folder');
    p.assert.equal(await H.isDir(p, 'C:\\MYPROGS\\FROMMENU'), true);
  }, { fresh: true });

  t.test('a new empty folder shows an expand arrow and no children', async (p) => {
    const r = await H.row(p, 'C:\\MYPROGS\\FROMMENU');
    p.assert.equal(r.tw, '▾');
    const kids = (await H.rows(p)).filter((x) => x.path.toUpperCase().startsWith('C:\\MYPROGS\\FROMMENU\\'));
    p.assert.equal(kids.length, 0);
  });

  // ---- mount dialog ------------------------------------------------------------------------------------------------
  t.test('Mount button opens the mount dialog with three permission choices, "ask" preselected', async (p) => {
    await H.headerBtn(p, 'Mount a computer folder as D:');
    p.assert.equal(await p.waitModal(), 'Mount a Folder as Drive D:');
    const opts = await p.ev("[...document.querySelectorAll('.modal select option')].map(o => o.value)");
    p.assert.deepEqual(opts, ['read', 'ask', 'write']);
    p.assert.equal(await p.ev("document.querySelector('.modal select').value"), 'ask');
    p.assert.deepEqual(await H.modalButtons(p), ['Cancel', 'Choose Folder…']);
  }, { fresh: true });

  t.test('Cancel in the mount dialog mounts nothing', async (p) => {
    await p.modalButton('Cancel');
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
    p.assert.equal((await H.rows(p)).some((x) => x.path === 'D:\\'), false);
  });

  t.test('without the File System Access API the mount button explains it is unsupported', async (p) => {
    await p.ev('window.__sdp = window.showDirectoryPicker; delete window.showDirectoryPicker; window.showDirectoryPicker = undefined');
    await H.headerBtn(p, 'Mount a computer folder as D:');
    p.assert.equal(await p.waitModal(), 'Not supported in this browser');
    p.assert.match(await p.modalText(), /Import Files/);
    await p.modalButton('OK');
    await p.ev('window.showDirectoryPicker = window.__sdp');
  });

  t.test('mounting a folder (ask mode) shows drive D: with its files in the tree', async (p) => {
    await H.fakePicker(p, 'REALDIR', { 'DATA.TXT': 'line one\r\n', SUB: { 'X.BAS': 'PRINT "X"' } });
    await H.headerBtn(p, 'Mount a computer folder as D:');
    await p.waitModal();
    await p.modalButton('Choose Folder…');
    await p.waitToast(/Mounted "REALDIR" as D:/);
    const d = await H.waitRow(p, 'D:\\');
    p.assert.equal(d.name, 'D: (REALDIR — your computer, ask before writing)');
    p.assert.equal(d.expanded, true);
    p.assert.ok(await H.row(p, 'D:\\DATA.TXT'));
    p.assert.ok(await H.row(p, 'D:\\SUB'));
  }, { fresh: true });

  t.test('clicking a file on the mounted drive loads and opens it', async (p) => {
    await H.clickRow(p, 'D:\\DATA.TXT');
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\DATA.TXT'", 3000);
    p.assert.equal(await p.code(), 'line one\n');
  });

  t.test('the drive rows are sorted C: then D:', async (p) => {
    const drives = (await H.rows(p)).filter((x) => x.depth === 0 && x.isDir).map((x) => x.path);
    p.assert.deepEqual(drives, ['C:\\', 'D:\\']);
  });

  t.test('File ▸ Unmount D: removes the drive from the explorer', async (p) => {
    await p.menu('File', 'Unmount D:');
    await H.waitRow(p, 'D:\\', false);
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
  });

  t.test('a read-only mount is labelled read-only', async (p) => {
    await H.fakePicker(p, 'RO', { 'A.TXT': 'a' });
    await H.headerBtn(p, 'Mount a computer folder as D:');
    await p.waitModal();
    await p.ev("(() => { const s = document.querySelector('.modal select'); s.value = 'read'; s.dispatchEvent(new Event('change')); })()");
    await p.modalButton('Choose Folder…');
    const d = await H.waitRow(p, 'D:\\');
    p.assert.equal(d.name, 'D: (RO — your computer, read-only)');
    p.assert.equal(await p.ev('RC.app.vfs.drives.D.writable'), false);
  }, { fresh: true });

  t.test('a writable mount has no permission suffix in its label', async (p) => {
    await H.fakePicker(p, 'RW', { 'A.TXT': 'a' });
    await H.headerBtn(p, 'Mount a computer folder as D:');
    await p.waitModal();
    await p.ev("document.querySelector('.modal select').value = 'write'");
    await p.modalButton('Choose Folder…');
    const d = await H.waitRow(p, 'D:\\');
    p.assert.equal(d.name, 'D: (RW — your computer)');
  }, { fresh: true });

  t.test('cancelling the browser folder picker shows no error', async (p) => {
    await p.ev("window.showDirectoryPicker = async () => { throw new DOMException('cancelled', 'AbortError'); }");
    await H.headerBtn(p, 'Mount a computer folder as D:');
    await p.waitModal();
    await p.modalButton('Choose Folder…');
    await p.sleep(200);
    p.assert.equal(await p.count('.toast.err'), 0);
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
  }, { fresh: true });

  t.test('a failing folder picker shows a "Mount failed" toast', async (p) => {
    await p.ev("window.showDirectoryPicker = async () => { throw new Error('denied by test'); }");
    await H.headerBtn(p, 'Mount a computer folder as D:');
    await p.waitModal();
    await p.modalButton('Choose Folder…');
    await p.waitToast(/Mount failed: denied by test/);
  }, { fresh: true });

  // ---- share dialog (header button) --------------------------------------------------------------------------------
  t.test('Share button opens Share Project for the active file\'s folder', async (p) => {
    await H.headerBtn(p, 'Share project');
    p.assert.equal(await p.waitModal(), 'Share Project');
    p.assert.match(await p.modalText(), /Sharing 1 file\(s\) from C:\\MYPROGS/);
    const link = await p.ev("document.querySelector('.modal input[aria-label=\"Share link\"]').value");
    p.assert.match(link, /#share=CPD1\./);
    p.assert.deepEqual(await H.modalButtons(p), ['Close', 'Copy Code', 'Copy Link']);
  }, { fresh: true });

  t.test('the share code unpacks to the folder\'s files', async (p) => {
    const code = await p.ev("document.querySelector('.modal textarea[aria-label=\"Share code\"]').value");
    const data = await p.fn(async (c) => { const d = await RC.Share.unpack(c); return { meta: d.meta, files: Object.keys(d.files), hello: RC.bytesToStr(d.files['HELLO.BAS']) }; }, code);
    p.assert.deepEqual(data.files, ['HELLO.BAS']);
    p.assert.equal(data.meta.name, 'MYPROGS');
    p.assert.equal(data.meta.main, 'HELLO.BAS');
    p.assert.equal(data.hello, await H.rawText(p, HELLO));
  });

  t.test('Copy Link puts the share link on the clipboard', async (p) => {
    await H.armClipboard(p);
    const link = await p.ev("document.querySelector('.modal input[aria-label=\"Share link\"]').value");
    await p.modalButton('Copy Link');
    await p.waitToast(/Copied to clipboard/);
    p.assert.equal(await p.ev('window.__clip'), link);
  });

  t.test('Copy Code puts the bare share code on the clipboard', async (p) => {
    await H.armClipboard(p);
    await H.headerBtn(p, 'Share project');
    await p.waitModal();
    const code = await p.ev("document.querySelector('.modal textarea').value");
    await p.modalButton('Copy Code');
    await p.waitToast(/Copied/);
    p.assert.equal(await p.ev('window.__clip'), code);
    p.assert.match(code, /^CPD1\./);
  });

  t.test('a failing clipboard shows a "Copy failed" toast', async (p) => {
    await p.ev("navigator.clipboard.writeText = async () => { throw new Error('no'); }");
    await H.headerBtn(p, 'Share project');
    await p.waitModal();
    await p.modalButton('Copy Link');
    await p.waitToast(/Copy failed/);
  });

  t.test('sharing an empty folder shows "That folder is empty"', async (p) => {
    await H.mkdirs(p, 'C:\\EMPTY');
    await H.waitRow(p, 'C:\\EMPTY');
    await H.ctx(p, 'C:\\EMPTY', 'Share This Folder as Link…');
    await p.waitToast(/That folder is empty/);
    p.assert.equal(await p.modalOpen(), false);
  }, { fresh: true });
  t.register();
};
