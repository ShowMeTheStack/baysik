// Persistence (IndexedDB), session restore, Options ▸ Disk Usage dialog, quota errors, files written by programs.
import * as H from './30-files-helpers.mjs';

const HELLO = 'C:\\MYPROGS\\HELLO.BAS';
const GUESS = 'C:\\SAMPLES\\GUESS.BAS';

async function openDisk(p) {
  await p.menu('Options', 'Disk Usage & Reset…');
  p.assert.equal(await p.waitModal(), 'Virtual Disk C:');
}

export default (reg) => {
  const t = H.safe(reg);
  t.beforeEach(async (p) => { await p.closeMenus(); });

  // ---- persistence across reload -------------------------------------------------------------------------------------
  t.test('a new program created with the dialog survives a reload', async (p) => {
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'KEEPER');
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\KEEPER.BAS'), true);
    p.assert.equal(await H.readText(p, 'C:\\MYPROGS\\KEEPER.BAS'), '\' KEEPER.BAS\nCLS\nPRINT "Hello!"\n');
    p.assert.ok(await H.row(p, 'C:\\MYPROGS\\KEEPER.BAS'));
  }, { fresh: true });

  t.test('the new file is stored in IndexedDB under its upper-case key', async (p) => {
    const db = await H.idbDump(p);
    p.assert.equal(db['\\MYPROGS\\KEEPER.BAS'], '\' KEEPER.BAS\r\nCLS\r\nPRINT "Hello!"\r\n');
    p.assert.equal(db['\\MYPROGS'], '<dir>');
  });

  t.test('saved edits survive a reload', async (p) => {
    await H.clickRow(p, 'C:\\MYPROGS\\KEEPER.BAS');
    await p.setCode('PRINT "PERSISTED EDIT"');
    await p.key('s', { ctrl: true });
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\KEEPER.BAS'), 'PRINT "PERSISTED EDIT"');
  });

  t.test('a reload right after saving (before the flush timer) still persists the save', async (p) => {
    await p.fn(() => RC.app.openFile('C:\\MYPROGS\\KEEPER.BAS'));
    await p.setCode('PRINT "QUICK"');
    await p.key('s', { ctrl: true });
    await p.reload();
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\KEEPER.BAS'), 'PRINT "QUICK"');
  });

  t.test('a renamed file keeps its new name after reload', async (p) => {
    await H.ctx(p, 'C:\\MYPROGS\\KEEPER.BAS', 'Rename…');
    await H.answerPrompt(p, 'RENAMED.BAS');
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\KEEPER.BAS'), false);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\RENAMED.BAS'), 'PRINT "QUICK"');
  });

  t.test('a deleted file stays deleted after reload', async (p) => {
    await H.ctx(p, 'C:\\MYPROGS\\RENAMED.BAS', 'Delete');
    await p.waitModal();
    await p.modalButton('Delete');
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\RENAMED.BAS'), false);
    p.assert.equal((await H.idbDump(p))['\\MYPROGS\\RENAMED.BAS'], undefined);
  });

  t.test('an empty folder survives a reload', async (p) => {
    await H.headerBtn(p, 'New folder');
    await H.answerPrompt(p, 'EMPTYDIR');
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.isDir(p, 'C:\\MYPROGS\\EMPTYDIR'), true);
  });

  t.test('binary files survive a reload byte-for-byte', async (p) => {
    const data = Array.from({ length: 256 }, (_, i) => i);
    await p.fn((d) => RC.app.vfs.writeFile('C:\\MYPROGS\\ALL.BIN', new Uint8Array(d), { trusted: true }), data);
    await H.flush(p);
    await p.reload();
    p.assert.deepEqual(await H.bytes(p, 'C:\\MYPROGS\\ALL.BIN'), data);
  });

  t.test('many files written at once all persist', async (p) => {
    await p.fn(() => { RC.app.vfs.mkdir('C:\\BULK'); for (let i = 0; i < 60; i++) RC.app.vfs.writeFile('C:\\BULK\\F' + i + '.TXT', RC.strToBytes('file ' + i), { trusted: true }); });
    await H.flush(p);
    await p.reload();
    p.assert.equal(await p.ev("RC.app.vfs.list('C:\\\\BULK').length"), 60);
    p.assert.equal(await H.rawText(p, 'C:\\BULK\\F59.TXT'), 'file 59');
  });

  t.test('a user-modified HELLO.BAS is not reset by the example installer on reload', async (p) => {
    await H.clickRow(p, HELLO);
    await p.setCode('PRINT "MY HELLO"');
    await p.key('s', { ctrl: true });
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.rawText(p, HELLO), 'PRINT "MY HELLO"');
  });

  t.test('a deleted example is reinstalled automatically at the next start', async (p) => {
    await H.ctx(p, GUESS, 'Delete');
    await p.waitModal();
    await p.modalButton('Delete');
    p.assert.equal(await H.exists(p, GUESS), false);
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.exists(p, GUESS), true);
  });

  t.test('autosaved edits survive a reload', async (p) => {
    await H.editActive(p, '\nREM autosave persisted');
    await p.wait('!RC.app.active.dirty', 6000);
    await H.flush(p);
    await p.reload();
    p.assert.match(await H.rawText(p, HELLO), /REM autosave persisted/);
  }, { fresh: true, timeout: 20000 });

  t.test('fresh storage starts with the examples and HELLO.BAS', async (p) => {
    p.assert.equal(await H.exists(p, HELLO), true);
    p.assert.equal(await p.ev("RC.app.vfs.list('C:\\\\SAMPLES').filter(e => e.type === 'file').length"), 20);
    p.assert.equal(await p.ev("RC.app.vfs.list('C:\\\\SAMPLES\\\\MULTI').length"), 3);
  }, { fresh: true });

  // ---- session restore ---------------------------------------------------------------------------------------------------
  t.test('open tabs are restored in order after reload', async (p) => {
    await H.clickRow(p, GUESS);
    await H.clickRow(p, 'C:\\SAMPLES\\COLORS.BAS');
    const before = await H.tabs(p);
    p.assert.deepEqual(before, [HELLO, GUESS, 'C:\\SAMPLES\\COLORS.BAS']);
    await p.reload();
    p.assert.deepEqual(await H.tabs(p), before);
  }, { fresh: true });

  t.test('the active tab is restored after reload', async (p) => {
    await p.click('#editorTabs .tab', 'GUESS.BAS');
    await p.reload();
    p.assert.equal(await p.activePath(), GUESS);
    p.assert.equal((await H.row(p, GUESS)).selected, true);
  });

  t.test('the session is stored in localStorage', async (p) => {
    const s = await p.ev("JSON.parse(localStorage.getItem('baysik.session'))");
    p.assert.deepEqual(s.open, [HELLO, GUESS, 'C:\\SAMPLES\\COLORS.BAS']);
    p.assert.equal(s.active, GUESS);
  });

  t.test('restored tabs show the file content and are clean', async (p) => {
    p.assert.equal(await p.code(), await H.readText(p, GUESS));
    p.assert.equal(await p.ev('RC.app.docs.some(d => d.dirty)'), false);
  });

  t.test('a closed tab is not restored', async (p) => {
    await p.click('#editorTabs .tab', 'COLORS.BAS');
    await p.key('w', { alt: true });
    await p.sleep(60);
    await p.reload();
    p.assert.deepEqual(await H.tabs(p), [HELLO, GUESS]);
  });

  t.test('a session file deleted from the disk is skipped on restore', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\GONE.BAS', 'PRINT 0');
    await p.fn(() => RC.app.openFile('C:\\MYPROGS\\GONE.BAS'));
    await H.flush(p);
    // delete behind the IDE's back so the session still lists it
    await p.ev("RC.app.vfs.unlink('C:\\\\MYPROGS\\\\GONE.BAS')");
    await H.flush(p);
    await p.reload();
    p.assert.ok(!(await H.tabs(p)).includes('C:\\MYPROGS\\GONE.BAS'));
    p.assert.ok((await H.tabs(p)).includes(GUESS));
  });

  t.test('with all tabs closed, HELLO.BAS opens on the next start', async (p) => {
    while ((await H.tabs(p)).length) { await p.key('w', { alt: true }); await p.sleep(60); }
    await p.reload();
    p.assert.deepEqual(await H.tabs(p), [HELLO]);
  });

  t.test('session restore works for files in a nested user folder', async (p) => {
    await H.writeRaw(p, 'C:\\A\\B\\C\\DEEP.BAS', 'PRINT "DEEP"');
    await p.fn(() => RC.app.openFile('C:\\A\\B\\C\\DEEP.BAS'));
    await H.flush(p);
    await p.reload();
    p.assert.equal(await p.activePath(), 'C:\\A\\B\\C\\DEEP.BAS');
    p.assert.equal(await p.code(), 'PRINT "DEEP"');
  }, { fresh: true });

  // ---- Options ▸ Disk Usage --------------------------------------------------------------------------------------------
  t.test('Options ▸ Disk Usage & Reset… opens the Virtual Disk C: dialog', async (p) => {
    await openDisk(p);
    p.assert.deepEqual(await H.modalButtons(p), ['Close', 'Reinstall Examples', 'Erase Everything…']);
    p.assert.match(await p.modalText(), /Files are stored in this browser only/);
  }, { fresh: true });

  t.test('the disk dialog reports the entry count and KB used out of 96 MB', async (p) => {
    const [n, kb] = await p.ev('[RC.app.vfs.drives.C.entries.size, (RC.app.vfs.drives.C.totalSize() / 1024).toFixed(1)]');
    p.assert.ok(await p.modalText().then((s) => s.includes(`${n} files and folders, ${kb} KB used of 96 MB.`)), await p.modalText());
  });

  t.test('Close dismisses the disk dialog without changes', async (p) => {
    const n = await p.ev('RC.app.vfs.drives.C.entries.size');
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.ev('RC.app.vfs.drives.C.entries.size'), n);
  });

  t.test('the disk dialog counts go up after adding a file', async (p) => {
    const n = await p.ev('RC.app.vfs.drives.C.entries.size');
    await p.fn(() => RC.app.vfs.writeFile('C:\\MYPROGS\\K.BIN', new Uint8Array(2048), { trusted: true }));
    const kb = await p.ev('(RC.app.vfs.drives.C.totalSize() / 1024).toFixed(1)');
    await openDisk(p);
    p.assert.ok((await p.modalText()).includes(`${n + 1} files and folders, ${kb} KB used`));
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('Reinstall Examples restores modified and deleted examples', async (p) => {
    const orig = await H.rawText(p, GUESS);
    await H.writeRaw(p, GUESS, 'PRINT "BROKEN"');
    await p.ev("RC.app.vfs.unlink('C:\\\\SAMPLES\\\\LIFE.BAS')");
    await openDisk(p);
    await p.modalButton('Reinstall Examples');
    await p.waitToast(/Examples reinstalled in C:\\SAMPLES/);
    p.assert.equal(await H.rawText(p, GUESS), orig);
    p.assert.equal(await H.exists(p, 'C:\\SAMPLES\\LIFE.BAS'), true);
    await H.waitRow(p, 'C:\\SAMPLES\\LIFE.BAS');
  }, { fresh: true });

  t.test('Reinstall Examples keeps the user\'s own files', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\MINE.BAS', 'PRINT "MINE"');
    await openDisk(p);
    await p.modalButton('Reinstall Examples');
    await p.waitToast(/Examples reinstalled/);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\MINE.BAS'), 'PRINT "MINE"');
  });

  t.test('Reinstall Examples does not overwrite the user\'s edited C:\\MYPROGS\\HELLO.BAS', async (p) => {
    await p.setCode('PRINT "MY OWN HELLO"');
    await p.key('s', { ctrl: true });
    await openDisk(p);
    await p.modalButton('Reinstall Examples');
    await p.waitToast(/Examples reinstalled/);
    p.assert.equal(await H.rawText(p, HELLO), 'PRINT "MY OWN HELLO"');
  }, { fresh: true });

  t.test('Erase Everything… asks for confirmation; Cancel keeps all files', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\MINE.BAS', 'PRINT "MINE"');
    await openDisk(p);
    await p.modalButton('Erase Everything…');
    p.assert.equal(await p.waitModal(), 'Erase disk?');
    p.assert.match(await p.modalText(), /Delete all files on C: and reset settings\? This cannot be undone\./);
    p.assert.deepEqual(await H.modalButtons(p), ['Cancel', 'Erase']);
    await p.modalButton('Cancel');
    await p.sleep(500);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\MINE.BAS'), true);
  }, { fresh: true });

  t.test('Erase wipes user files and settings, then reloads with fresh examples', async (p) => {
    await p.menu('Options', 'Theme', 'Dark');
    await H.ctx(p, 'C:\\SAMPLES\\GUESS.BAS', 'Set as Main Program of Folder');
    await H.flush(p);
    await p.ev('window.__beforeErase = 1');
    await openDisk(p);
    await p.modalButton('Erase Everything…');
    await p.waitModal();
    await p.modalButton('Erase');
    await p.wait('window.__beforeErase === undefined && window.__baysikReady === true', 10000);
    await p.sleep(200);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\MINE.BAS'), false);
    p.assert.equal(await H.exists(p, HELLO), true);
    p.assert.equal(await H.exists(p, GUESS), true);
    p.assert.notEqual(await p.ev('document.documentElement.dataset.theme'), 'dark');
    p.assert.equal(await p.ev("localStorage.getItem('baysik.mains')"), null);
  }, { timeout: 20000 });

  t.test('after Erase, IndexedDB holds no user files', async (p) => {
    await H.flush(p);
    const db = await H.idbDump(p);
    p.assert.equal(db['\\MYPROGS\\MINE.BAS'], undefined);
    p.assert.ok(db['\\MYPROGS\\HELLO.BAS']);
  });

  // ---- errors surfaced as toasts ---------------------------------------------------------------------------------------
  t.test('if IndexedDB cannot be opened, a toast warns that files will not persist', async (p) => {
    const r = await p.b.send('Page.addScriptToEvaluateOnNewDocument', { source: "try { Object.defineProperty(window, 'indexedDB', { value: { open() { throw new Error('blocked by test'); } } }); } catch (e) {}" });
    try {
      await p.reload();
      await p.waitToast(/Could not open browser storage; files will not persist this session/);
      // the IDE still works in memory
      p.assert.equal(await H.exists(p, HELLO), true);
      await H.headerBtn(p, 'New program');
      await H.answerPrompt(p, 'MEMONLY');
      p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\MEMONLY.BAS'), true);
    } finally {
      await p.b.send('Page.removeScriptToEvaluateOnNewDocument', { identifier: r.identifier });
    }
  }, { fresh: true });

  t.test('creating a program when the disk has too many entries explains why ("Too many files")', async (p) => {
    await p.ev('RC.app.vfs.opts.maxEntries = RC.app.vfs.drives.C.entries.size');
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'ONEMORE');
    await p.waitToast(/Could not create file/);
    p.assert.match(await p.lastToast(), /Too many files/);
  }, { fresh: true });

  t.test('creating a program when the disk has too many entries creates nothing', async (p) => {
    await p.ev('RC.app.vfs.opts.maxEntries = RC.app.vfs.drives.C.entries.size');
    await H.headerBtn(p, 'New program');
    await H.answerPrompt(p, 'ONEMORE');
    await p.waitToast(/Could not create file/);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\ONEMORE.BAS'), false);
    p.assert.ok(!(await H.tabs(p)).includes('C:\\MYPROGS\\ONEMORE.BAS'));
  }, { fresh: true });

  t.test('Duplicate beyond the entry limit shows "Copy failed"', async (p) => {
    await p.ev('RC.app.vfs.opts.maxEntries = RC.app.vfs.drives.C.entries.size');
    await H.ctx(p, HELLO, 'Duplicate');
    await p.waitToast(/Copy failed/);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\HELLO2.BAS'), false);
  });

  t.test('Save As of a new name beyond the entry limit fails with a toast and keeps the path', async (p) => {
    await p.ev('RC.app.vfs.opts.maxEntries = RC.app.vfs.drives.C.entries.size');
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'BRANDNEW');
    await p.waitToast(/Could not save BRANDNEW\.BAS/);
    p.assert.equal(await p.activePath(), HELLO);
  });

  t.test('a program that fills the disk stops with a Disk full error', async (p) => {
    await p.newFile('C:\\MYPROGS\\FILL.BAS', 'OPEN "BIG.DAT" FOR OUTPUT AS #1\nFOR I = 1 TO 200\nPRINT #1, STRING$(200, "X")\nNEXT\nCLOSE #1\nPRINT "DONE"');
    await p.ev('RC.app.vfs.opts.maxTotal = RC.app.vfs.drives.C.totalSize() + 1000');
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'error'], 10000);
    p.assert.equal(await p.state(), 'error');
    p.assert.doesNotMatch(await p.screen(), /DONE/);
    p.assert.match(await p.status() + '\n' + await p.screen(), /Disk full/);
  }, { fresh: true });

  // ---- files written by programs ---------------------------------------------------------------------------------------
  t.test('a file written with OPEN … FOR OUTPUT appears in the explorer', async (p) => {
    p.assert.equal(await H.row(p, 'C:\\MYPROGS\\OUT.TXT'), null);
    await p.runProgram('OPEN "OUT.TXT" FOR OUTPUT AS #1\nPRINT #1, "HELLO FILE"\nCLOSE #1\nPRINT "WROTE"');
    p.assert.match(await p.screen(), /WROTE/);
    await H.waitRow(p, 'C:\\MYPROGS\\OUT.TXT');
  }, { fresh: true });

  t.test('the written file has the PRINT # text with CRLF', async (p) => {
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\OUT.TXT'), 'HELLO FILE\r\n');
    p.assert.match((await H.row(p, 'C:\\MYPROGS\\OUT.TXT')).title, /\(12 bytes\)/);
  });

  t.test('clicking the program-written file opens its contents', async (p) => {
    await H.clickRow(p, 'C:\\MYPROGS\\OUT.TXT');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\OUT.TXT');
    p.assert.equal(await p.code(), 'HELLO FILE\n');
  });

  t.test('APPEND adds to the file and the explorer size updates', async (p) => {
    await p.runProgram('OPEN "OUT.TXT" FOR APPEND AS #1\nPRINT #1, "LINE 2"\nCLOSE #1');
    await p.wait(`(() => { const e = [...document.querySelectorAll('#explorerTree .tree-item')].find(x => x.innerText.trim() === 'OUT.TXT'); return e && /\\(20 bytes\\)/.test(e.title); })()`, 3000);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\OUT.TXT'), 'HELLO FILE\r\nLINE 2\r\n');
  });

  t.test('a program-written file survives a reload', async (p) => {
    await H.flush(p);
    await p.reload();
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\OUT.TXT'), 'HELLO FILE\r\nLINE 2\r\n');
  });

  t.test('MKDIR in a program makes the folder appear in the explorer', async (p) => {
    await p.runProgram('MKDIR "DATA"\nOPEN "DATA\\SCORES.TXT" FOR OUTPUT AS #1\nPRINT #1, 100\nCLOSE #1');
    const r = await H.waitRow(p, 'C:\\MYPROGS\\DATA');
    p.assert.equal(r.isDir, true);
    await H.clickRow(p, 'C:\\MYPROGS\\DATA');
    await H.waitRow(p, 'C:\\MYPROGS\\DATA\\SCORES.TXT');
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\DATA\\SCORES.TXT'), ' 100 \r\n');
  });

  t.test('NAME … AS in a program renames the file in the explorer', async (p) => {
    await p.runProgram('NAME "OUT.TXT" AS "LOG.TXT"');
    await H.waitRow(p, 'C:\\MYPROGS\\LOG.TXT');
    await H.waitRow(p, 'C:\\MYPROGS\\OUT.TXT', false);
  });

  t.test('KILL in a program removes the file from the explorer', async (p) => {
    await p.runProgram('KILL "LOG.TXT"');
    await H.waitRow(p, 'C:\\MYPROGS\\LOG.TXT', false);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\LOG.TXT'), false);
  });

  t.test('RMDIR in a program removes an empty folder from the explorer', async (p) => {
    await p.runProgram('KILL "DATA\\SCORES.TXT"\nRMDIR "DATA"');
    await H.waitRow(p, 'C:\\MYPROGS\\DATA', false);
  });

  t.test('a program writes relative files into its own folder', async (p) => {
    await H.mkdirs(p, 'C:\\GAME');
    await H.waitRow(p, 'C:\\GAME');
    await H.expand(p, 'C:\\GAME');
    await p.runProgram('OPEN "SAVE.DAT" FOR OUTPUT AS #1\nPRINT #1, "S"\nCLOSE', { path: 'C:\\GAME\\G.BAS' });
    p.assert.equal(await H.exists(p, 'C:\\GAME\\SAVE.DAT'), true);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\SAVE.DAT'), false);
    await H.waitRow(p, 'C:\\GAME\\SAVE.DAT');
  }, { fresh: true });

  t.test('a program can read back a file imported into the virtual disk', async (p) => {
    await H.armFileInput(p);
    await H.ctx(p, 'C:\\GAME', 'Import Files Here…');
    await H.feedFiles(p, [{ name: 'INPUT.TXT', text: 'from disk\r\n' }]);
    await p.waitToast(/Imported/);
    await p.runProgram('OPEN "INPUT.TXT" FOR INPUT AS #1\nLINE INPUT #1, A$\nCLOSE\nPRINT "GOT:"; A$', { path: 'C:\\GAME\\G.BAS' });
    p.assert.match(await p.screen(), /GOT:from disk/);
  });

  t.test('a binary file written with PUT appears with the right size', async (p) => {
    await p.runProgram('OPEN "REC.DAT" FOR RANDOM AS #1 LEN = 16\nA$ = "RECORD"\nFIELD #1, 16 AS F$\nLSET F$ = A$\nPUT #1, 1\nPUT #1, 2\nCLOSE', { path: 'C:\\GAME\\G.BAS' });
    const r = await H.waitRow(p, 'C:\\GAME\\REC.DAT');
    p.assert.match(r.title, /\(32 bytes\)/);
  });
  t.register();
};
