// File explorer context menus: open/run/main/rename/duplicate/download/delete, folder menu, zip downloads, imports.
import * as H from './30-files-helpers.mjs';

const HELLO = 'C:\\MYPROGS\\HELLO.BAS';
const FILE_ITEMS_BAS = ['Open', 'Run', 'Set as Main Program of Folder', 'Rename…', 'Duplicate', 'Download to Computer', 'Delete'];
const DIR_ITEMS = ['New Program Here…', 'New Folder Here…', 'Import Files Here…', 'Share This Folder as Link…', 'Download Folder (.zip)', 'Rename…', 'Delete Folder'];

async function setupProj(p) {
  await H.writeRaw(p, 'C:\\PROJ\\A.BAS', 'PRINT "AAA"\r\n');
  await H.writeRaw(p, 'C:\\PROJ\\B.BAS', 'PRINT "BBB"\r\n');
  await H.writeRaw(p, 'C:\\PROJ\\README.TXT', 'read me\r\n');
  await p.fn(() => { RC.app.expandedDirs.add('C:\\PROJ'); RC.UI.storage.set('expandedDirs', [...RC.app.expandedDirs]); RC.app.renderExplorer(); });
  await H.waitRow(p, 'C:\\PROJ\\README.TXT');
}

export default (reg) => {
  const t = H.safe(reg);
  t.beforeEach(async (p) => { await p.closeMenus(); });

  // ---- file context menu -----------------------------------------------------------------------------------------
  t.test('right-clicking a .BAS file shows the full file menu', async (p) => {
    await H.rightClickRow(p, HELLO);
    p.assert.deepEqual(await H.menuLabels(p), FILE_ITEMS_BAS);
    p.assert.equal(await p.count('.menu-pop .menu-sep'), 2);
  }, { fresh: true });

  t.test('the context menu opens at the mouse position', async (p) => {
    await H.rightClickRow(p, HELLO);
    const r = await p.rect('.menu-pop');
    const rowRect = await p.fn(() => { const e = [...document.querySelectorAll('#explorerTree .tree-item')].find((x) => x.innerText.trim() === 'HELLO.BAS'); const b = e.getBoundingClientRect(); return { top: b.top, bottom: b.bottom }; });
    p.assert.ok(r.y >= rowRect.top - 2 && r.y <= rowRect.bottom + 2, JSON.stringify({ r, rowRect }));
  });

  t.test('Escape closes the file context menu', async (p) => {
    await H.rightClickRow(p, HELLO);
    await p.key('Escape');
    p.assert.equal(await p.exists('.menu-pop'), false);
  });

  t.test('clicking elsewhere closes the file context menu', async (p) => {
    await H.rightClickRow(p, HELLO);
    await p.click('#statusbar');
    p.assert.equal(await p.exists('.menu-pop'), false);
  });

  t.test('right-clicking a non-.BAS file omits Run and Set as Main', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\NOTES.TXT', 'hi');
    await H.waitRow(p, 'C:\\MYPROGS\\NOTES.TXT');
    await H.rightClickRow(p, 'C:\\MYPROGS\\NOTES.TXT');
    p.assert.deepEqual(await H.menuLabels(p), ['Open', 'Rename…', 'Duplicate', 'Download to Computer', 'Delete']);
  }, { fresh: true });

  t.test('a .BI include file has no Run item', async (p) => {
    await H.expand(p, 'C:\\SAMPLES\\MULTI');
    await H.rightClickRow(p, 'C:\\SAMPLES\\MULTI\\SHAPES.BI');
    const labels = await H.menuLabels(p);
    p.assert.ok(!labels.includes('Run'));
    p.assert.ok(labels.includes('Open'));
  });

  t.test('context menu Open opens the file', async (p) => {
    await H.ctx(p, 'C:\\SAMPLES\\GUESS.BAS', 'Open');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\GUESS.BAS');
  }, { fresh: true });

  t.test('right-clicking does not itself open the file', async (p) => {
    await H.rightClickRow(p, 'C:\\SAMPLES\\COLORS.BAS');
    await p.key('Escape');
    p.assert.equal((await H.tabs(p)).includes('C:\\SAMPLES\\COLORS.BAS'), false);
  });

  t.test('context menu Run opens and runs the program', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\RUNME.BAS', 'PRINT "RAN FROM MENU"\r\n');
    await H.waitRow(p, 'C:\\MYPROGS\\RUNME.BAS');
    await H.ctx(p, 'C:\\MYPROGS\\RUNME.BAS', 'Run');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /RAN FROM MENU/);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\RUNME.BAS');
  }, { fresh: true });

  // ---- main program --------------------------------------------------------------------------------------------------
  t.test('Set as Main Program shows a "main" badge on the file', async (p) => {
    await setupProj(p);
    await H.ctx(p, 'C:\\PROJ\\A.BAS', 'Set as Main Program of Folder');
    const r = await H.row(p, 'C:\\PROJ\\A.BAS');
    p.assert.equal(r.main, true);
    p.assert.equal(r.badge, 'main');
    p.assert.equal((await H.row(p, 'C:\\PROJ\\B.BAS')).main, false);
  }, { fresh: true });

  t.test('the main program is stored per folder in localStorage', async (p) => {
    const m = await p.ev("JSON.parse(localStorage.getItem('baysik.mains'))");
    p.assert.equal(m['C:\\PROJ'], 'C:\\PROJ\\A.BAS');
  });

  t.test('the main file\'s context menu offers Unset Main Program', async (p) => {
    await H.rightClickRow(p, 'C:\\PROJ\\A.BAS');
    const labels = await H.menuLabels(p);
    p.assert.ok(labels.includes('Unset Main Program'));
    p.assert.ok(!labels.includes('Set as Main Program of Folder'));
    await p.key('Escape');
  });

  t.test('running from another file in the folder runs the main program', async (p) => {
    await H.clickRow(p, 'C:\\PROJ\\B.BAS');
    p.assert.equal(await p.activePath(), 'C:\\PROJ\\B.BAS');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /AAA/);
    p.assert.doesNotMatch(await p.screen(), /BBB/);
  });

  t.test('the main badge survives a reload', async (p) => {
    await p.reload();
    p.assert.equal((await H.row(p, 'C:\\PROJ\\A.BAS')).badge, 'main');
  });

  t.test('setting another file as main moves the badge', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\B.BAS', 'Set as Main Program of Folder');
    p.assert.equal((await H.row(p, 'C:\\PROJ\\B.BAS')).badge, 'main');
    p.assert.equal((await H.row(p, 'C:\\PROJ\\A.BAS')).main, false);
  });

  t.test('Unset Main Program removes the badge and the stored entry', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\B.BAS', 'Unset Main Program');
    p.assert.equal((await H.row(p, 'C:\\PROJ\\B.BAS')).main, false);
    const m = await p.ev("JSON.parse(localStorage.getItem('baysik.mains'))");
    p.assert.equal(m['C:\\PROJ'], undefined);
  });

  t.test('without a main program F5 runs the active file', async (p) => {
    await H.clickRow(p, 'C:\\PROJ\\B.BAS');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /BBB/);
  });

  // ---- rename ------------------------------------------------------------------------------------------------------------
  t.test('Rename… opens a prompt pre-filled with the current name', async (p) => {
    await setupProj(p);
    await H.ctx(p, 'C:\\PROJ\\A.BAS', 'Rename…');
    p.assert.equal(await p.waitModal(), 'Rename');
    p.assert.equal(await H.modalInputValue(p), 'A.BAS');
    p.assert.match(await p.modalText(), /New name/);
  }, { fresh: true });

  t.test('renaming a file moves it on disk and in the tree', async (p) => {
    await p.modalInput('ALPHA.BAS');
    await p.modalButton('OK');
    await H.waitRow(p, 'C:\\PROJ\\ALPHA.BAS');
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\A.BAS'), false);
    p.assert.equal(await H.rawText(p, 'C:\\PROJ\\ALPHA.BAS'), 'PRINT "AAA"\r\n');
    p.assert.equal(await H.row(p, 'C:\\PROJ\\A.BAS'), null);
  });

  t.test('renaming an open file updates its tab name and path', async (p) => {
    await H.clickRow(p, 'C:\\PROJ\\B.BAS');
    await H.ctx(p, 'C:\\PROJ\\B.BAS', 'Rename…');
    await H.answerPrompt(p, 'BETA.BAS');
    p.assert.equal(await p.activePath(), 'C:\\PROJ\\BETA.BAS');
    p.assert.ok((await H.tabNames(p)).includes('BETA.BAS'));
    p.assert.ok(!(await H.tabNames(p)).includes('B.BAS'));
  });

  t.test('saving a renamed open file writes to the new name', async (p) => {
    await H.editActive(p, '\nPRINT "MORE"');
    await p.key('s', { ctrl: true });
    p.assert.match(await H.rawText(p, 'C:\\PROJ\\BETA.BAS'), /MORE/);
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\B.BAS'), false);
  });

  t.test('renaming to an existing name fails with a toast and keeps both files', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\ALPHA.BAS', 'Rename…');
    await H.answerPrompt(p, 'README.TXT');
    await p.waitToast(/Rename failed: File already exists/);
    p.assert.equal(await H.rawText(p, 'C:\\PROJ\\README.TXT'), 'read me\r\n');
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\ALPHA.BAS'), true);
  });

  t.test('cancelling Rename leaves the file alone', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\ALPHA.BAS', 'Rename…');
    await p.waitModal();
    await p.modalButton('Cancel');
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\ALPHA.BAS'), true);
  });

  t.test('renaming with an invalid character fails with a toast', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\ALPHA.BAS', 'Rename…');
    await H.answerPrompt(p, 'A<B.BAS');
    await p.waitToast(/Rename failed/);
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\ALPHA.BAS'), true);
  });

  t.test('renaming only the letter case keeps the file', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\ALPHA.BAS', 'Rename…');
    await H.answerPrompt(p, 'Alpha.bas');
    await H.flush(p);
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\ALPHA.BAS'), true);
    p.assert.ok((await H.rows(p)).some((x) => x.name === 'Alpha.bas'));
  });

  t.test('renaming a folder moves everything inside it', async (p) => {
    await setupProj(p);
    await H.ctx(p, 'C:\\PROJ', 'Rename…');
    p.assert.equal(await H.modalInputValue(p), 'PROJ');
    await H.answerPrompt(p, 'PROJ2');
    p.assert.equal(await H.exists(p, 'C:\\PROJ'), false);
    p.assert.equal(await H.rawText(p, 'C:\\PROJ2\\A.BAS'), 'PRINT "AAA"\r\n');
    p.assert.equal(await H.exists(p, 'C:\\PROJ2\\README.TXT'), true);
  }, { fresh: true });

  t.test('renaming a folder updates the paths of files open from it', async (p) => {
    await setupProj(p);
    await H.clickRow(p, 'C:\\PROJ\\A.BAS');
    await H.ctx(p, 'C:\\PROJ', 'Rename…');
    await H.answerPrompt(p, 'MOVED');
    p.assert.equal(await p.activePath(), 'C:\\MOVED\\A.BAS');
  }, { fresh: true });

  // ---- duplicate ----------------------------------------------------------------------------------------------------------
  t.test('Duplicate creates NAME2 with identical bytes', async (p) => {
    await H.ctx(p, HELLO, 'Duplicate');
    await H.waitRow(p, 'C:\\MYPROGS\\HELLO2.BAS');
    p.assert.deepEqual(await H.bytes(p, 'C:\\MYPROGS\\HELLO2.BAS'), await H.bytes(p, HELLO));
  }, { fresh: true });

  t.test('duplicating again creates NAME3', async (p) => {
    await H.ctx(p, HELLO, 'Duplicate');
    await H.waitRow(p, 'C:\\MYPROGS\\HELLO3.BAS');
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\HELLO3.BAS'), true);
  });

  t.test('Duplicate does not open the copy', async (p) => {
    p.assert.ok(!(await H.tabs(p)).some((x) => /HELLO[23]/.test(x)));
    p.assert.equal(await p.activePath(), HELLO);
  });

  t.test('duplicating a file without an extension appends the number', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\NOEXT', 'x');
    await H.waitRow(p, 'C:\\MYPROGS\\NOEXT');
    await H.ctx(p, 'C:\\MYPROGS\\NOEXT', 'Duplicate');
    await H.waitRow(p, 'C:\\MYPROGS\\NOEXT2');
  });

  t.test('duplicating a sample keeps it in the same folder', async (p) => {
    await H.ctx(p, 'C:\\SAMPLES\\GUESS.BAS', 'Duplicate');
    await H.waitRow(p, 'C:\\SAMPLES\\GUESS2.BAS');
    p.assert.equal(await H.readText(p, 'C:\\SAMPLES\\GUESS2.BAS'), await H.readText(p, 'C:\\SAMPLES\\GUESS.BAS'));
  });

  t.test('Duplicate saves into the duplicate the on-disk bytes, not unsaved edits', async (p) => {
    await p.fn(() => { RC.app.settings.autosave = false; });
    await H.clickRow(p, 'C:\\MYPROGS\\NOEXT');
    await H.editActive(p, 'UNSAVED');
    await H.ctx(p, 'C:\\MYPROGS\\NOEXT', 'Duplicate');
    await H.waitRow(p, 'C:\\MYPROGS\\NOEXT3');
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\NOEXT3'), 'x');
  });

  // ---- download single file ----------------------------------------------------------------------------------------------
  t.test('Download to Computer delivers the file with its name and exact bytes', async (p) => {
    await H.armDownloads(p);
    await H.ctx(p, HELLO, 'Download to Computer');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'HELLO.BAS');
    p.assert.deepEqual(d.bytes, await H.bytes(p, HELLO));
    p.assert.equal(d.type, 'application/octet-stream');
  }, { fresh: true });

  t.test('downloaded BASIC files keep CRLF line endings', async (p) => {
    const [d] = await H.downloads(p);
    const s = Buffer.from(d.bytes).toString('latin1');
    p.assert.match(s, /\r\n/);
    p.assert.doesNotMatch(s.replace(/\r\n/g, ''), /\n/);
  });

  t.test('downloading a CP437 file keeps the raw CP437 bytes', async (p) => {
    await H.armDownloads(p);
    await H.writeRaw(p, 'C:\\MYPROGS\\BOX.TXT', '\xc9\xcd\xbb');
    await H.waitRow(p, 'C:\\MYPROGS\\BOX.TXT');
    await H.ctx(p, 'C:\\MYPROGS\\BOX.TXT', 'Download to Computer');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'BOX.TXT');
    p.assert.deepEqual(d.bytes, [0xc9, 0xcd, 0xbb]);
  });

  t.test('File ▸ Download to Computer saves the active file first and downloads it', async (p) => {
    await H.armDownloads(p);
    await H.editActive(p, '\nPRINT "FRESH EDIT"');
    await p.menu('File', 'Download to Computer');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'HELLO.BAS');
    p.assert.match(Buffer.from(d.bytes).toString('latin1'), /FRESH EDIT/);
    p.assert.equal(await H.activeDirty(p), false);
  }, { fresh: { settings: { autosave: false } } });

  // ---- delete -----------------------------------------------------------------------------------------------------------------
  t.test('Delete asks for confirmation naming the file', async (p) => {
    await setupProj(p);
    await H.ctx(p, 'C:\\PROJ\\A.BAS', 'Delete');
    p.assert.equal(await p.waitModal(), 'Delete?');
    const txt = await p.modalText();
    p.assert.match(txt, /Delete C:\\PROJ\\A\.BAS\? This cannot be undone\./);
    p.assert.doesNotMatch(txt, /everything in it/);
    p.assert.deepEqual(await H.modalButtons(p), ['Cancel', 'Delete']);
  }, { fresh: true });

  t.test('Cancel in the delete confirmation keeps the file', async (p) => {
    await p.modalButton('Cancel');
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\A.BAS'), true);
    p.assert.ok(await H.row(p, 'C:\\PROJ\\A.BAS'));
  });

  t.test('Escape in the delete confirmation keeps the file', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\A.BAS', 'Delete');
    await p.waitModal();
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\A.BAS'), true);
  });

  t.test('confirming Delete removes the file from disk and tree', async (p) => {
    await H.ctx(p, 'C:\\PROJ\\A.BAS', 'Delete');
    await p.waitModal();
    await p.modalButton('Delete');
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\A.BAS'), false);
    await H.waitRow(p, 'C:\\PROJ\\A.BAS', false);
  });

  t.test('deleting an open file closes its tab', async (p) => {
    await H.clickRow(p, 'C:\\PROJ\\B.BAS');
    p.assert.ok((await H.tabs(p)).includes('C:\\PROJ\\B.BAS'));
    await H.ctx(p, 'C:\\PROJ\\B.BAS', 'Delete');
    await p.waitModal();
    await p.modalButton('Delete');
    await p.sleep(100);
    p.assert.ok(!(await H.tabs(p)).includes('C:\\PROJ\\B.BAS'));
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('deleting an open file with unsaved edits closes it without an unsaved-changes prompt', async (p) => {
    await H.clickRow(p, 'C:\\PROJ\\README.TXT');
    await H.editActive(p, 'dirty');
    await H.ctx(p, 'C:\\PROJ\\README.TXT', 'Delete');
    await p.waitModal();
    await p.modalButton('Delete');
    await p.sleep(150);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.ok(!(await H.tabs(p)).includes('C:\\PROJ\\README.TXT'));
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\README.TXT'), false);
  });

  t.test('deleting the main program file of a folder removes its badge row', async (p) => {
    await H.writeRaw(p, 'C:\\PROJ\\M.BAS', 'PRINT 1');
    await H.waitRow(p, 'C:\\PROJ\\M.BAS');
    await H.ctx(p, 'C:\\PROJ\\M.BAS', 'Set as Main Program of Folder');
    await H.ctx(p, 'C:\\PROJ\\M.BAS', 'Delete');
    await p.waitModal();
    await p.modalButton('Delete');
    await H.waitRow(p, 'C:\\PROJ\\M.BAS', false);
    p.assert.equal((await H.rows(p)).some((x) => x.main), false);
  });

  // ---- folder context menu --------------------------------------------------------------------------------------------------
  t.test('right-clicking a folder shows the folder menu', async (p) => {
    await H.rightClickRow(p, 'C:\\MYPROGS');
    p.assert.deepEqual(await H.menuLabels(p), DIR_ITEMS);
    await p.key('Escape');
  }, { fresh: true });

  t.test('right-clicking a folder selects it without toggling it', async (p) => {
    await H.rightClickRow(p, 'C:\\SAMPLES');
    await p.key('Escape');
    p.assert.equal(await p.ev('RC.app.selectedPath'), 'C:\\SAMPLES');
    p.assert.equal((await H.row(p, 'C:\\SAMPLES')).expanded, true);
  });

  t.test('the drive root menu has no Rename or Delete', async (p) => {
    await H.rightClickRow(p, 'C:\\');
    p.assert.deepEqual(await H.menuLabels(p), DIR_ITEMS.slice(0, 5));
    p.assert.equal(await p.count('.menu-pop .menu-sep'), 1);
    await p.key('Escape');
  });

  t.test('New Program Here… creates the program in that folder', async (p) => {
    await H.ctx(p, 'C:\\SAMPLES\\MULTI', 'New Program Here…');
    p.assert.equal(await p.waitModal(), 'New Program');
    p.assert.match(await p.modalText(), /Created in C:\\SAMPLES\\MULTI/);
    await H.answerPrompt(p, 'HERE');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\MULTI\\HERE.BAS');
    p.assert.equal(await H.exists(p, 'C:\\SAMPLES\\MULTI\\HERE.BAS'), true);
  }, { fresh: true });

  t.test('New Program Here… on the drive root creates the program at C:\\', async (p) => {
    await H.ctx(p, 'C:\\', 'New Program Here…');
    await p.waitModal();
    p.assert.match(await p.modalText(), /Created in C:\./);
    await H.answerPrompt(p, 'ROOTPROG');
    p.assert.equal(await H.exists(p, 'C:\\ROOTPROG.BAS'), true);
    await H.waitRow(p, 'C:\\ROOTPROG.BAS');
  }, { fresh: true });

  t.test('New Folder Here… creates a sub-folder in that folder', async (p) => {
    await H.ctx(p, 'C:\\SAMPLES', 'New Folder Here…');
    await H.answerPrompt(p, 'EXTRA', 'New Folder');
    p.assert.equal(await H.isDir(p, 'C:\\SAMPLES\\EXTRA'), true);
    p.assert.equal(await H.isDir(p, 'C:\\MYPROGS\\EXTRA'), false);
  }, { fresh: true });

  t.test('New Folder Here… on the drive root creates a top-level folder', async (p) => {
    await H.ctx(p, 'C:\\', 'New Folder Here…');
    await H.answerPrompt(p, 'TOP');
    p.assert.equal(await H.isDir(p, 'C:\\TOP'), true);
    const r = await H.waitRow(p, 'C:\\TOP');
    p.assert.equal(r.depth, 1);
  });

  t.test('Delete Folder asks to delete the folder "and everything in it"', async (p) => {
    await setupProj(p);
    await H.ctx(p, 'C:\\PROJ', 'Delete Folder');
    p.assert.equal(await p.waitModal(), 'Delete?');
    p.assert.match(await p.modalText(), /Delete C:\\PROJ and everything in it\? This cannot be undone\./);
    await p.modalButton('Cancel');
    p.assert.equal(await H.exists(p, 'C:\\PROJ\\A.BAS'), true);
  }, { fresh: true });

  t.test('Delete Folder removes nested folders and files, and closes their tabs', async (p) => {
    await H.writeRaw(p, 'C:\\PROJ\\DEEP\\ER\\Z.BAS', 'PRINT 9');
    await H.clickRow(p, 'C:\\PROJ\\A.BAS');
    await p.fn(() => RC.app.openFile('C:\\PROJ\\DEEP\\ER\\Z.BAS'));
    await H.ctx(p, 'C:\\PROJ', 'Delete Folder');
    await p.waitModal();
    await p.modalButton('Delete');
    await p.sleep(150);
    p.assert.equal(await H.exists(p, 'C:\\PROJ'), false);
    p.assert.equal(await p.ev("RC.app.vfs.walk('C:\\\\').filter(x => x.key.startsWith('\\\\PROJ')).length"), 0);
    p.assert.ok(!(await H.tabs(p)).some((x) => x.startsWith('C:\\PROJ')));
    await H.waitRow(p, 'C:\\PROJ', false);
  });

  t.test('Delete Folder works on an empty folder', async (p) => {
    await H.mkdirs(p, 'C:\\HOLLOW');
    await H.waitRow(p, 'C:\\HOLLOW');
    await H.ctx(p, 'C:\\HOLLOW', 'Delete Folder');
    await p.waitModal();
    await p.modalButton('Delete');
    p.assert.equal(await H.exists(p, 'C:\\HOLLOW'), false);
  });

  t.test('Share This Folder as Link… shares exactly that folder', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\MULTI');
    await H.ctx(p, 'C:\\SAMPLES\\MULTI', 'Share This Folder as Link…');
    p.assert.equal(await p.waitModal(), 'Share Project');
    p.assert.match(await p.modalText(), /Sharing 3 file\(s\) from C:\\SAMPLES\\MULTI/);
    const code = await p.ev("document.querySelector('.modal textarea').value");
    const files = await p.fn(async (c) => Object.keys((await RC.Share.unpack(c)).files).sort(), code);
    p.assert.deepEqual(files, ['MAIN.BAS', 'PART2.BAS', 'SHAPES.BI']);
    await p.modalButton('Close');
  }, { fresh: true });

  t.test('a shared folder includes files of its sub-folders with / separators', async (p) => {
    await H.ctx(p, 'C:\\SAMPLES', 'Share This Folder as Link…');
    await p.waitModal();
    const code = await p.ev("document.querySelector('.modal textarea').value");
    const files = await p.fn(async (c) => Object.keys((await RC.Share.unpack(c)).files), code);
    p.assert.ok(files.includes('MULTI/MAIN.BAS'));
    p.assert.ok(files.includes('GUESS.BAS'));
    await p.modalButton('Close');
  });

  t.test('a folder\'s main program is recorded in the share data', async (p) => {
    await H.expand(p, 'C:\\SAMPLES\\MULTI');
    await H.ctx(p, 'C:\\SAMPLES\\MULTI\\PART2.BAS', 'Set as Main Program of Folder');
    await H.ctx(p, 'C:\\SAMPLES\\MULTI', 'Share This Folder as Link…');
    await p.waitModal();
    const code = await p.ev("document.querySelector('.modal textarea').value");
    const meta = await p.fn(async (c) => (await RC.Share.unpack(c)).meta, code);
    p.assert.equal(meta.main, 'PART2.BAS');
    p.assert.equal(meta.name, 'MULTI');
    await p.modalButton('Close');
  });

  // ---- zip downloads ----------------------------------------------------------------------------------------------------------
  t.test('Download Folder (.zip) produces FOLDER.zip with every file and valid CRCs', async (p) => {
    await H.armDownloads(p);
    await H.ctx(p, 'C:\\SAMPLES\\MULTI', 'Download Folder (.zip)');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'MULTI.zip');
    p.assert.equal(d.type, 'application/zip');
    const z = H.parseZip(d.bytes);
    p.assert.equal(z.count, 3);
    p.assert.deepEqual(z.entries.map((e) => e.name).sort(), ['MAIN.BAS', 'PART2.BAS', 'SHAPES.BI']);
    p.assert.ok(z.entries.every((e) => e.crcOk && e.method === 0 && e.size === e.csize));
  }, { fresh: true });

  t.test('zip entries hold exactly the bytes on the virtual disk', async (p) => {
    const [d] = await H.downloads(p);
    const z = H.parseZip(d.bytes);
    for (const e of z.entries) {
      p.assert.deepEqual(Array.from(e.data), await H.bytes(p, 'C:\\SAMPLES\\MULTI\\' + e.name), e.name);
    }
  });

  t.test('zip of a folder with sub-folders uses relative paths with original letter case', async (p) => {
    await H.armDownloads(p);
    await H.writeRaw(p, 'C:\\Proj\\Top.bas', 'PRINT 1');
    await H.writeRaw(p, 'C:\\Proj\\Lib\\Util.bi', 'REM util');
    await H.waitRow(p, 'C:\\Proj');
    await H.ctx(p, 'C:\\Proj', 'Download Folder (.zip)');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'Proj.zip');
    const z = H.parseZip(d.bytes);
    p.assert.deepEqual(z.entries.map((e) => e.name).sort(), ['Lib/Util.bi', 'Top.bas']);
    p.assert.equal(z.entries.find((e) => e.name === 'Lib/Util.bi').data.toString('latin1'), 'REM util');
  }, { fresh: true });

  t.test('zipping a folder with unsaved edits saves them first', async (p) => {
    await H.armDownloads(p);
    await H.expand(p, 'C:\\Proj');
    await H.clickRow(p, 'C:\\Proj\\Top.bas');
    await H.editActive(p, '\nPRINT "ZIPPED EDIT"');
    await H.ctx(p, 'C:\\Proj', 'Download Folder (.zip)');
    const [d] = await H.waitDownload(p);
    const z = H.parseZip(d.bytes);
    p.assert.match(z.entries.find((e) => e.name === 'Top.bas').data.toString('latin1'), /ZIPPED EDIT/);
    p.assert.equal(await H.activeDirty(p), false);
  });

  t.test('File ▸ Download Project (.zip) zips the active file\'s folder', async (p) => {
    await H.armDownloads(p);
    await p.menu('File', 'Download Project (.zip)');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'MYPROGS.zip');
    p.assert.deepEqual(H.parseZip(d.bytes).entries.map((e) => e.name), ['HELLO.BAS']);
  }, { fresh: true });

  t.test('Download Folder (.zip) on the drive root is named DISK.zip', async (p) => {
    await H.armDownloads(p);
    await H.ctx(p, 'C:\\', 'Download Folder (.zip)');
    const [d] = await H.waitDownload(p);
    p.assert.equal(d.name, 'DISK.zip');
  }, { fresh: true });

  t.test('drive root zip (before any program ran) contains MYPROGS and SAMPLES files', async (p) => {
    await H.armDownloads(p);
    await H.ctx(p, 'C:\\', 'Download Folder (.zip)');
    const [d] = await H.waitDownload(p);
    const names = H.parseZip(d.bytes).entries.map((e) => e.name);
    p.assert.ok(names.includes('MYPROGS/HELLO.BAS'));
    p.assert.ok(names.includes('SAMPLES/MULTI/MAIN.BAS'));
    p.assert.ok(H.parseZip(d.bytes).entries.every((e) => e.crcOk));
  }, { fresh: true });

  t.test('drive root zip still contains the whole disk after a program has run', async (p) => {
    await p.runProgram('PRINT 1');
    await H.armDownloads(p);
    await H.ctx(p, 'C:\\', 'Download Folder (.zip)');
    const [d] = await H.waitDownload(p);
    const names = H.parseZip(d.bytes).entries.map((e) => e.name);
    p.assert.ok(names.includes('SAMPLES/GUESS.BAS'), 'zip entries: ' + names.join(', '));
  }, { fresh: true });

  // ---- importing files ----------------------------------------------------------------------------------------------------------
  t.test('Import button imports a file into the active file\'s folder and opens it', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'IMPORTED.BAS', text: 'PRINT "IMPORTED"\r\n' }]);
    await p.waitToast(/Imported 1 file\(s\) into C:\\MYPROGS/);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\IMPORTED.BAS');
    p.assert.equal(await p.code(), 'PRINT "IMPORTED"\n');
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\IMPORTED.BAS'), 'PRINT "IMPORTED"\r\n');
    await H.waitRow(p, 'C:\\MYPROGS\\IMPORTED.BAS');
  }, { fresh: true });

  t.test('the import file input accepts multiple files', async (p) => {
    p.assert.equal(await p.ev('window.__fileInputs[window.__fileInputs.length - 1].multiple'), true);
  });

  t.test('importing several files writes all of them and opens the last text file', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'ONE.BAS', text: 'PRINT 1' }, { name: 'TWO.TXT', text: 'two' }]);
    await p.waitToast(/Imported 2 file\(s\)/);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\ONE.BAS'), 'PRINT 1');
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\TWO.TXT'), 'two');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\TWO.TXT');
  });

  t.test('an imported binary file is stored byte-for-byte but not opened', async (p) => {
    await H.armFileInput(p);
    const before = await p.activePath();
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'PIC.BIN', bytes: [0, 1, 2, 250, 255] }]);
    await p.waitToast(/Imported 1 file/);
    p.assert.deepEqual(await H.bytes(p, 'C:\\MYPROGS\\PIC.BIN'), [0, 1, 2, 250, 255]);
    p.assert.equal(await p.activePath(), before);
  });

  t.test('importing over an existing file asks to replace it; Cancel keeps the old file', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'ONE.BAS', text: 'PRINT "NEW ONE"' }]);
    p.assert.equal(await p.waitModal(), 'Replace file?');
    p.assert.match(await p.modalText(), /C:\\MYPROGS\\ONE\.BAS exists\. Replace\?/);
    await p.modalButton('Cancel');
    await p.sleep(150);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\ONE.BAS'), 'PRINT 1');
  });

  t.test('confirming Replace on import overwrites the file and refreshes its open tab', async (p) => {
    await p.fn(() => RC.app.openFile('C:\\MYPROGS\\ONE.BAS'));
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'ONE.BAS', text: 'PRINT "NEW ONE"' }]);
    await p.waitModal();
    await p.modalButton('Replace');
    await p.waitToast(/Imported 1 file/);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\ONE.BAS'), 'PRINT "NEW ONE"');
    p.assert.equal(await p.code(), 'PRINT "NEW ONE"');
    p.assert.equal(await H.activeDirty(p), false);
    p.assert.equal((await H.tabs(p)).filter((x) => x === 'C:\\MYPROGS\\ONE.BAS').length, 1);
  });

  t.test('a UTF-8 encoded import is decoded as UTF-8 in the editor', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'UTF.BAS', text: 'PRINT "café ╔═╗ π"\r\n' }]);
    await p.waitToast(/Imported/);
    p.assert.equal(await p.code(), 'PRINT "café ╔═╗ π"\n');
  });

  t.test('a CP437 encoded import is decoded as CP437 in the editor', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    // "caf" + é(0x82) + space + ╔(0xC9) ═(0xCD) ╗(0xBB) + space + π(0xE3)
    await H.feedFiles(p, [{ name: 'DOS.BAS', bytes: [...Buffer.from('PRINT "caf'), 0x82, 0x20, 0xc9, 0xcd, 0xbb, 0x20, 0xe3, ...Buffer.from('"\r\n')] }]);
    await p.waitToast(/Imported/);
    p.assert.equal(await p.code(), 'PRINT "café ╔═╗ π"\n');
  });

  t.test('a CP437 import keeps its raw bytes on the virtual disk', async (p) => {
    const b = await H.bytes(p, 'C:\\MYPROGS\\DOS.BAS');
    p.assert.ok(b.includes(0x82) && b.includes(0xc9));
  });

  t.test('a CP437 import ending in Ctrl+Z (EOF marker) has the marker stripped', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'EOF.BAS', bytes: [...Buffer.from('PRINT 1\r\n'), 0x1a] }]);
    await p.waitToast(/Imported/);
    p.assert.equal(await p.code(), 'PRINT 1\n');
  });

  t.test('a pure ASCII import with LF endings is opened unchanged', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'LF.BAS', text: 'A=1\nPRINT A\n' }]);
    await p.waitToast(/Imported/);
    p.assert.equal(await p.code(), 'A=1\nPRINT A\n');
  });

  t.test('importing then running an imported UTF-8 program prints CP437 text correctly', async (p) => {
    await H.clickRow(p, 'C:\\MYPROGS\\UTF.BAS');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /café ╔═╗ π/);
  });

  t.test('characters not allowed in DOS names are replaced with _ on import', async (p) => {
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'WHAT?.BAS', text: 'PRINT 1' }]);
    await p.waitToast(/Imported/);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\WHAT_.BAS'), true);
  });

  t.test('Import Files Here… imports into that folder', async (p) => {
    await H.armFileInput(p);
    await H.ctx(p, 'C:\\SAMPLES\\MULTI', 'Import Files Here…');
    await H.feedFiles(p, [{ name: 'HERE.BAS', text: 'PRINT "HERE"' }]);
    await p.waitToast(/Imported 1 file\(s\) into C:\\SAMPLES\\MULTI/);
    p.assert.equal(await H.rawText(p, 'C:\\SAMPLES\\MULTI\\HERE.BAS'), 'PRINT "HERE"');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\MULTI\\HERE.BAS');
  }, { fresh: true });

  t.test('Import Files Here… on the drive root imports to C:\\', async (p) => {
    await H.armFileInput(p);
    await H.ctx(p, 'C:\\', 'Import Files Here…');
    await H.feedFiles(p, [{ name: 'ROOT.TXT', text: 'root' }]);
    await p.waitToast(/Imported 1 file/);
    p.assert.equal(await H.rawText(p, 'C:\\ROOT.TXT'), 'root');
    await H.waitRow(p, 'C:\\ROOT.TXT');
  });

  t.test('File ▸ Open from Computer… imports a file', async (p) => {
    await H.armFileInput(p);
    await p.menu('File', 'Open from Computer…');
    await H.feedFiles(p, [{ name: 'MENUIMP.BAS', text: 'PRINT 5' }]);
    await p.waitToast(/Imported 1 file/);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\MENUIMP.BAS');
  }, { fresh: true });

  t.test('Open dialog\'s From Computer… button imports a file', async (p) => {
    await H.armFileInput(p);
    await p.key('o', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Open File');
    await p.modalButton('From Computer…');
    await H.feedFiles(p, [{ name: 'DLGIMP.BAS', text: 'PRINT 6' }]);
    await p.waitToast(/Imported 1 file/);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\DLGIMP.BAS');
  });

  t.test('an import larger than the file size limit shows a "Could not import" toast', async (p) => {
    await p.ev('RC.app.vfs.opts.maxFileSize = 10');
    await H.armFileInput(p);
    await H.headerBtn(p, 'Import files from computer');
    await H.feedFiles(p, [{ name: 'HUGE.TXT', text: 'this is more than ten bytes' }]);
    await p.waitToast(/Could not import HUGE\.TXT: File too large/);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\HUGE.TXT'), false);
  }, { fresh: true });
  t.register();
};
