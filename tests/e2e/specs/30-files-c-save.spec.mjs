// Saving: Save / Save As / protected originals (save your copy) / closing dirty tabs / autosave.
import * as H from './30-files-helpers.mjs';

const HELLO = 'C:\\MYPROGS\\HELLO.BAS';
const GUESS = 'C:\\SAMPLES\\GUESS.BAS';
const NOAUTO = { settings: { autosave: false } };

async function openSampleEdited(p, path = GUESS, extra = '\nPRINT "MY EDIT"') {
  await p.fn((x) => RC.app.openFile(x), path);
  await H.editActive(p, extra);
}
const lockShown = (p, name) => p.fn((n) => { const t = [...document.querySelectorAll('#editorTabs .tab')].find((x) => x.title.endsWith('\\' + n)); return !!(t && t.querySelector('.lock')); }, name);
const dirtyDot = (p, name) => p.fn((n) => { const t = [...document.querySelectorAll('#editorTabs .tab')].find((x) => x.title.endsWith('\\' + n)); return !!(t && t.querySelector('.dirty')); }, name);
async function tabClose(p, name) {
  const xy = await p.fn((n) => { const t = [...document.querySelectorAll('#editorTabs .tab')].find((x) => x.title.endsWith('\\' + n)); const x = t.querySelector('.x'); const r = x.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; }, name);
  await p.clickAt(xy[0], xy[1]);
  await p.sleep(80);
}

export default (reg) => {
  const t = H.safe(reg);
  t.beforeEach(async (p) => { await p.closeMenus(); });

  // ---- Save (own files) ------------------------------------------------------------------------------------------
  t.test('editing an own file marks its tab dirty', async (p) => {
    await H.editActive(p, '\nPRINT "SAVED BY CTRL+S"');
    p.assert.equal(await H.activeDirty(p), true);
    p.assert.equal(await dirtyDot(p, 'HELLO.BAS'), true);
  }, { fresh: NOAUTO });

  t.test('Ctrl+S writes the editor text to disk with CRLF line endings', async (p) => {
    const text = await p.code();
    await p.key('s', { ctrl: true });
    p.assert.equal(await H.rawText(p, HELLO), text.replace(/\n/g, '\r\n'));
  });

  t.test('after Ctrl+S the tab is clean and the status bar says Saved', async (p) => {
    p.assert.equal(await H.activeDirty(p), false);
    p.assert.equal(await dirtyDot(p, 'HELLO.BAS'), false);
    p.assert.match(await p.status(), /Saved C:\\MYPROGS\\HELLO\.BAS/);
  });

  t.test('Ctrl+S on an own file opens no dialog', async (p) => {
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('File ▸ Save writes the file', async (p) => {
    await H.editActive(p, '\nPRINT "VIA MENU"');
    await p.menu('File', 'Save');
    p.assert.match(await H.rawText(p, HELLO), /VIA MENU/);
    p.assert.equal(await H.activeDirty(p), false);
  });

  t.test('Save encodes non-ASCII text as CP437 bytes', async (p) => {
    await p.setCode('PRINT "é╔π"');
    await p.key('s', { ctrl: true });
    const b = await H.bytes(p, HELLO);
    p.assert.deepEqual(b.slice(7, 10), [0x82, 0xc9, 0xe3]);
    p.assert.equal(await H.readText(p, HELLO), 'PRINT "é╔π"');
  });

  t.test('Save turns characters CP437 cannot represent into ?', async (p) => {
    await p.setCode('PRINT "€"');
    await p.key('s', { ctrl: true });
    p.assert.equal(await H.rawText(p, HELLO), 'PRINT "?"');
  });

  t.test('undoing back to the saved text clears the dirty flag', async (p) => {
    await p.setCode('PRINT 1');
    await p.key('s', { ctrl: true });
    await H.editActive(p, 'X');
    p.assert.equal(await H.activeDirty(p), true);
    await p.ev("(() => { const e = RC.app.active.editor; e.ta.setSelectionRange(e.ta.value.length - 1, e.ta.value.length); e.insert(''); })()");
    await p.sleep(60);
    p.assert.equal(await H.activeDirty(p), false);
  });

  t.test('with the LF line-ending setting, Save writes LF only', async (p) => {
    await p.setCode('A=1\nPRINT A\n');
    await p.key('s', { ctrl: true });
    p.assert.equal(await H.rawText(p, HELLO), 'A=1\nPRINT A\n');
  }, { fresh: { settings: { autosave: false, lineEnding: 'lf' } } });

  t.test('File ▸ Save All saves every dirty own file but not protected ones', async (p) => {
    const orig = await H.rawText(p, GUESS);
    await H.writeRaw(p, 'C:\\MYPROGS\\TWO.BAS', 'PRINT 2');
    await H.editActive(p, '\nREM one');
    await p.fn(() => RC.app.openFile('C:\\MYPROGS\\TWO.BAS'));
    await H.editActive(p, '\nREM two');
    await openSampleEdited(p);
    await p.menu('File', 'Save All');
    p.assert.match(await H.rawText(p, HELLO), /REM one/);
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\TWO.BAS'), /REM two/);
    p.assert.equal(await H.rawText(p, GUESS), orig);
    p.assert.equal(await H.isDirty(p, GUESS), true);
    p.assert.equal(await p.modalOpen(), false);
  }, { fresh: NOAUTO });

  // ---- protected originals ---------------------------------------------------------------------------------------
  t.test('a sample file\'s tab shows the ◇ example marker', async (p) => {
    await p.fn((x) => RC.app.openFile(x), GUESS);
    p.assert.equal(await lockShown(p, 'GUESS.BAS'), true);
    p.assert.equal(await lockShown(p, 'HELLO.BAS'), false);
  }, { fresh: NOAUTO });

  t.test('the status bar explains that Save makes your own copy', async (p) => {
    p.assert.match(await p.status(), /Example\/tutorial file .* Save \(Ctrl\+S\) keeps your changes as your own copy/);
  });

  t.test('switching to an own file clears the example status message', async (p) => {
    await p.click('#editorTabs .tab', 'HELLO.BAS');
    p.assert.doesNotMatch(await p.status(), /Example\/tutorial/);
  });

  t.test('Ctrl+S on an edited sample asks for a copy name in C:\\MYPROGS', async (p) => {
    await openSampleEdited(p);
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\GUESS.BAS');
    p.assert.match(await p.modalText(), /saved as a new file of your own/);
  });

  t.test('accepting the copy name writes the edited text to the copy', async (p) => {
    const orig = await H.rawText(p, GUESS);
    const text = await p.code();
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await H.readText(p, 'C:\\MYPROGS\\GUESS.BAS'), text);
    p.assert.equal(await H.rawText(p, GUESS), orig);
    p.assert.doesNotMatch(orig, /MY EDIT/);
  });

  t.test('after saving a copy the tab refers to the copy and is clean', async (p) => {
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\GUESS.BAS');
    p.assert.equal(await H.activeDirty(p), false);
    p.assert.ok(!(await H.tabs(p)).includes(GUESS));
    p.assert.equal(await lockShown(p, 'GUESS.BAS'), false);
  });

  t.test('saving a copy shows a toast and status with the new path', async (p) => {
    await p.waitToast(/Saved C:\\MYPROGS\\GUESS\.BAS/);
    p.assert.match(await p.status(), /Saved as C:\\MYPROGS\\GUESS\.BAS/);
  });

  t.test('the copy appears highlighted in the explorer', async (p) => {
    const r = await H.waitRow(p, 'C:\\MYPROGS\\GUESS.BAS');
    p.assert.equal(r.selected, true);
  });

  t.test('Ctrl+S on the copy now saves in place without asking', async (p) => {
    await H.editActive(p, '\nREM second');
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.modalOpen(), false);
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\GUESS.BAS'), /REM second/);
  });

  t.test('saving the same sample again proposes a unique name (GUESS2.BAS)', async (p) => {
    await openSampleEdited(p);
    await p.key('s', { ctrl: true });
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\GUESS2.BAS');
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\GUESS2.BAS'), true);
  });

  t.test('and a third time GUESS3.BAS', async (p) => {
    await openSampleEdited(p);
    await p.key('s', { ctrl: true });
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\GUESS3.BAS');
    await p.modalButton('Cancel');
  });

  t.test('cancelling the copy dialog saves nothing and keeps the sample dirty', async (p) => {
    p.assert.equal(await p.activePath(), GUESS);
    p.assert.equal(await H.activeDirty(p), true);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\GUESS3.BAS'), false);
  });

  t.test('an 8-letter sample name gets a number squeezed into 8 characters', async (p) => {
    await openSampleEdited(p, 'C:\\SAMPLES\\TIMESTBL.BAS');
    await p.key('s', { ctrl: true });
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\TIMESTBL.BAS');
    await p.modalButton('OK');
    await p.sleep(100);
    await openSampleEdited(p, 'C:\\SAMPLES\\TIMESTBL.BAS');
    await p.key('s', { ctrl: true });
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\TIMESTB2.BAS');
    await p.modalButton('Cancel');
  }, { fresh: NOAUTO });

  t.test('a bare name in the copy dialog is saved in C:\\MYPROGS with .BAS added', async (p) => {
    await openSampleEdited(p, 'C:\\SAMPLES\\COLORS.BAS');
    await p.key('s', { ctrl: true });
    await H.answerPrompt(p, 'MINE', 'Save Your Copy');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\MINE.BAS');
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\MINE.BAS'), /MY EDIT/);
  }, { fresh: NOAUTO });

  t.test('a full path into a new folder creates the folder (as the hint suggests)', async (p) => {
    await openSampleEdited(p, 'C:\\SAMPLES\\SNAKE.BAS');
    await p.key('s', { ctrl: true });
    await p.waitModal();
    p.assert.match(await p.modalText(), /C:\\GAMES\\MYSNAKE\.BAS/);
    await H.answerPrompt(p, 'C:\\GAMES\\MYSNAKE.BAS');
    p.assert.equal(await H.isDir(p, 'C:\\GAMES'), true);
    p.assert.equal(await p.activePath(), 'C:\\GAMES\\MYSNAKE.BAS');
    p.assert.match(await H.rawText(p, 'C:\\GAMES\\MYSNAKE.BAS'), /MY EDIT/);
  });

  t.test('saving a copy into a protected folder is refused with a toast', async (p) => {
    await openSampleEdited(p, 'C:\\SAMPLES\\LIFE.BAS');
    await p.key('s', { ctrl: true });
    await H.answerPrompt(p, 'C:\\SAMPLES\\LIFE2.BAS');
    await p.waitToast(/Pick a folder outside C:\\SAMPLES, C:\\LIBRARY and C:\\LESSONS/);
    p.assert.equal(await H.exists(p, 'C:\\SAMPLES\\LIFE2.BAS'), false);
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\LIFE.BAS');
    p.assert.equal(await H.activeDirty(p), true);
  });

  t.test('protection is case-insensitive (c:\\samples\\…)', async (p) => {
    await p.key('s', { ctrl: true });
    await H.answerPrompt(p, 'c:\\samples\\life3.bas');
    await p.waitToast(/Pick a folder outside/);
    p.assert.equal(await H.exists(p, 'C:\\SAMPLES\\LIFE3.BAS'), false);
  });

  t.test('C:\\LIBRARY and C:\\LESSONS are refused as copy targets too', async (p) => {
    for (const target of ['C:\\LIBRARY\\X.BAS', 'C:\\LESSONS\\X.BAS']) {
      await p.key('s', { ctrl: true });
      await H.answerPrompt(p, target);
      await p.waitToast(/Pick a folder outside/);
      p.assert.equal(await H.exists(p, target), false, target);
    }
  });

  t.test('copy names that already exist ask to replace; Cancel saves nothing', async (p) => {
    await H.writeRaw(p, 'C:\\MYPROGS\\TAKEN.BAS', 'PRINT "TAKEN"');
    await p.key('s', { ctrl: true });
    await H.answerPrompt(p, 'TAKEN');
    p.assert.equal(await p.waitModal(), 'Replace file?');
    p.assert.match(await p.modalText(), /C:\\MYPROGS\\TAKEN\.BAS already exists\. Replace it\?/);
    await p.modalButton('Cancel');
    await p.sleep(80);
    p.assert.equal(await H.rawText(p, 'C:\\MYPROGS\\TAKEN.BAS'), 'PRINT "TAKEN"');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\LIFE.BAS');
  });

  t.test('confirming Replace overwrites the existing file with the copy', async (p) => {
    await p.key('s', { ctrl: true });
    await H.answerPrompt(p, 'TAKEN');
    await p.waitModal();
    await p.modalButton('Replace');
    await p.sleep(100);
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\TAKEN.BAS'), /MY EDIT/);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\TAKEN.BAS');
  });

  t.test('breakpoints move with the document to the saved copy', async (p) => {
    await p.fn((x) => RC.app.openFile(x), 'C:\\SAMPLES\\FACTORL.BAS');
    await p.fn((x) => { RC.app.toggleBreakpoint(x, 3); RC.app.toggleBreakpoint(x, 5); }, 'C:\\SAMPLES\\FACTORL.BAS');
    await H.editActive(p, '\nREM x');
    await p.key('s', { ctrl: true });
    await H.answerPrompt(p, 'FACTCOPY');
    const bp = await p.ev("(() => { const o = {}; for (const [k, v] of RC.app.breakpoints) o[k] = [...v.keys()]; return o; })()");
    p.assert.deepEqual((bp['C:\\MYPROGS\\FACTCOPY.BAS'] || []).sort(), [3, 5], JSON.stringify(bp));
    p.assert.ok(!bp['C:\\SAMPLES\\FACTORL.BAS'] || bp['C:\\SAMPLES\\FACTORL.BAS'].length === 0);
    const saved = await p.ev("JSON.parse(localStorage.getItem('baysik.breakpoints'))");
    p.assert.deepEqual(saved['C:\\MYPROGS\\FACTCOPY.BAS'].map((x) => x.line).sort(), [3, 5]);
    p.assert.equal(saved['C:\\SAMPLES\\FACTORL.BAS'], undefined);
  }, { fresh: NOAUTO });

  t.test('a copy of a sample still has its breakpoint markers in the editor', async (p) => {
    const marks = await p.ev('[...RC.app.active.editor.marks.bps.keys()].sort()');
    p.assert.deepEqual(marks, [3, 5]);
  });

  t.test('files in C:\\LIBRARY are protected: Save asks for a copy', async (p) => {
    const path = await p.fn(async () => { const t = await RC.Library.load(); const k = Object.keys(t).find((x) => /\.BAS$/i.test(x)); return RC.Library.install(RC.app, k); });
    await p.fn((x) => RC.app.openFile(x), path);
    p.assert.match(path, /^C:\\LIBRARY\\/);
    p.assert.equal(await lockShown(p, path.replace(/^.*\\/, '')), true);
    const orig = await H.rawText(p, path);
    await H.editActive(p, '\nREM lib edit');
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    const stem = path.replace(/^.*\\/, '').replace(/\.[^.]*$/, '').toUpperCase().slice(0, 8);
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\' + stem + '.BAS');
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await H.rawText(p, path), orig);
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\' + stem + '.BAS'), /REM lib edit/);
  }, { fresh: NOAUTO });

  t.test('files in C:\\LESSONS are protected: Save asks for a copy', async (p) => {
    await p.newFile('C:\\LESSONS\\LESSON1.BAS', 'PRINT "LESSON"');
    await H.editActive(p, '\nREM mine');
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\LESSON1.BAS');
    await p.modalButton('OK');
    await p.sleep(100);
    p.assert.equal(await H.rawText(p, 'C:\\LESSONS\\LESSON1.BAS'), 'PRINT "LESSON"');
  });

  t.test('running an edited sample does not overwrite the original', async (p) => {
    const orig = await H.rawText(p, 'C:\\SAMPLES\\TIMESTBL.BAS');
    await openSampleEdited(p, 'C:\\SAMPLES\\TIMESTBL.BAS', '\nEND');
    await p.key('F5');
    await p.waitState(['ended', 'error', 'waiting', 'running']);
    await p.stopProgram();
    p.assert.equal(await H.rawText(p, 'C:\\SAMPLES\\TIMESTBL.BAS'), orig);
    p.assert.equal(await H.activeDirty(p), true);
  }, { fresh: {} });

  // ---- Save As (own files) -------------------------------------------------------------------------------------------
  t.test('Ctrl+Shift+S opens Save As pre-filled with the current path', async (p) => {
    await p.key('s', { ctrl: true, shift: true });
    p.assert.equal(await p.waitModal(), 'Save As');
    p.assert.equal(await H.modalInputValue(p), HELLO);
    p.assert.match(await p.modalText(), /File name \(e\.g\. GAME\.BAS or C:\\MYPROGS\\GAME\.BAS\)/);
    await p.modalButton('Cancel');
  }, { fresh: NOAUTO });

  t.test('File ▸ Save As… opens the Save As dialog', async (p) => {
    await p.menu('File', 'Save As…');
    p.assert.equal(await p.waitModal(), 'Save As');
    await p.modalButton('Cancel');
  });

  t.test('Save As with a new name writes a new file and retargets the tab', async (p) => {
    const origDisk = await H.rawText(p, HELLO);
    await H.editActive(p, '\nREM as-edit');
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'C:\\MYPROGS\\HELLO2.BAS');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO2.BAS');
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\HELLO2.BAS'), /REM as-edit/);
    p.assert.equal(await H.rawText(p, HELLO), origDisk);
    p.assert.ok((await H.tabNames(p)).includes('HELLO2.BAS'));
    p.assert.ok(!(await H.tabs(p)).includes(HELLO));
    await p.waitToast(/Saved C:\\MYPROGS\\HELLO2\.BAS/);
  });

  t.test('Save As with a bare name saves next to the current file and adds .BAS', async (p) => {
    await H.mkdirs(p, 'C:\\WORK');
    await p.newFile('C:\\WORK\\A.BAS', 'PRINT "A"');
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'B');
    p.assert.equal(await p.activePath(), 'C:\\WORK\\B.BAS');
    p.assert.equal(await H.rawText(p, 'C:\\WORK\\B.BAS'), 'PRINT "A"');
  });

  t.test('Save As keeps an explicit non-.BAS extension', async (p) => {
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'NOTES.TXT');
    p.assert.equal(await p.activePath(), 'C:\\WORK\\NOTES.TXT');
  });

  t.test('Save As onto the same path saves without a replace prompt', async (p) => {
    await H.editActive(p, '\nREM same');
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'C:\\WORK\\NOTES.TXT');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.match(await H.rawText(p, 'C:\\WORK\\NOTES.TXT'), /REM same/);
  });

  t.test('Save As onto an existing file asks to replace it; Cancel leaves everything', async (p) => {
    await H.writeRaw(p, 'C:\\WORK\\OLD.BAS', 'PRINT "OLD"');
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'OLD.BAS');
    p.assert.equal(await p.waitModal(), 'Replace file?');
    await p.modalButton('Cancel');
    await p.sleep(80);
    p.assert.equal(await H.rawText(p, 'C:\\WORK\\OLD.BAS'), 'PRINT "OLD"');
    p.assert.equal(await p.activePath(), 'C:\\WORK\\NOTES.TXT');
  });

  t.test('Save As replacing a file that is open in another tab closes that tab', async (p) => {
    await p.fn(() => RC.app.openFile('C:\\WORK\\OLD.BAS'));
    await H.editActive(p, '\nREM old dirty');
    await p.fn(() => RC.app.openFile('C:\\WORK\\NOTES.TXT'));
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'OLD.BAS');
    await p.waitModal();
    await p.modalButton('Replace');
    await p.sleep(150);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal((await H.tabs(p)).filter((x) => x === 'C:\\WORK\\OLD.BAS').length, 1);
    p.assert.equal(await p.activePath(), 'C:\\WORK\\OLD.BAS');
    p.assert.match(await H.rawText(p, 'C:\\WORK\\OLD.BAS'), /REM same/);
  });

  t.test('Save As with an invalid name shows "Invalid file name"', async (p) => {
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'A|B.BAS');
    await p.waitToast(/Invalid file name/);
    p.assert.equal(await p.activePath(), 'C:\\WORK\\OLD.BAS');
  });

  t.test('Save As into a protected folder is refused', async (p) => {
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'C:\\SAMPLES\\MINE.BAS');
    await p.waitToast(/Pick a folder outside/);
    p.assert.equal(await H.exists(p, 'C:\\SAMPLES\\MINE.BAS'), false);
    p.assert.equal(await p.activePath(), 'C:\\WORK\\OLD.BAS');
  });

  t.test('Save As into a missing nested folder fails and keeps the old path', async (p) => {
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'C:\\NOPE\\DEEPER\\X.BAS');
    await p.waitToast(/Could not save X\.BAS/);
    p.assert.equal(await p.activePath(), 'C:\\WORK\\OLD.BAS');
    p.assert.ok((await H.tabNames(p)).includes('OLD.BAS'));
    p.assert.equal(await H.exists(p, 'C:\\NOPE\\DEEPER\\X.BAS'), false);
  });

  t.test('Save As into a single missing folder creates it', async (p) => {
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'C:\\NEWDIR\\X.BAS');
    p.assert.equal(await H.isDir(p, 'C:\\NEWDIR'), true);
    p.assert.equal(await p.activePath(), 'C:\\NEWDIR\\X.BAS');
  });

  t.test('cancelling Save As changes nothing', async (p) => {
    await H.editActive(p, '\nREM pending');
    await p.key('s', { ctrl: true, shift: true });
    await p.waitModal();
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.activePath(), 'C:\\NEWDIR\\X.BAS');
    p.assert.equal(await H.activeDirty(p), true);
  });

  t.test('Save As of an own file copies its breakpoints and keeps the originals', async (p) => {
    await p.fn(() => RC.app.toggleBreakpoint('C:\\NEWDIR\\X.BAS', 1));
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'Y.BAS');
    const bp = await p.ev("(() => { const o = {}; for (const [k, v] of RC.app.breakpoints) o[k] = [...v.keys()]; return o; })()");
    p.assert.deepEqual(bp['C:\\NEWDIR\\Y.BAS'], [1]);
    p.assert.deepEqual(bp['C:\\NEWDIR\\X.BAS'], [1]);
  });

  t.test('Save As result shows in the explorer as the highlighted file', async (p) => {
    await p.fn(() => { RC.app.expandedDirs.add('C:\\NEWDIR'); RC.app.renderExplorer(); });
    const r = await H.waitRow(p, 'C:\\NEWDIR\\Y.BAS');
    p.assert.equal(r.selected, true);
  });

  t.test('Save As on a sample with a bare name saves into C:\\MYPROGS', async (p) => {
    await openSampleEdited(p, 'C:\\SAMPLES\\HANOI.BAS');
    await p.key('s', { ctrl: true, shift: true });
    await p.waitModal();
    p.assert.equal(await H.modalInputValue(p), 'C:\\SAMPLES\\HANOI.BAS');
    await H.answerPrompt(p, 'MYHANOI');
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\MYHANOI.BAS');
  }, { fresh: NOAUTO });

  t.test('Save As on a sample keeping its own path is refused', async (p) => {
    await openSampleEdited(p, 'C:\\SAMPLES\\HANOI.BAS');
    await p.key('s', { ctrl: true, shift: true });
    await H.answerPrompt(p, 'C:\\SAMPLES\\HANOI.BAS');
    await p.waitToast(/Pick a folder outside/);
    p.assert.equal(await H.activeDirty(p), true);
  });

  t.test('a save that exceeds the size limit shows a toast and keeps the tab dirty', async (p) => {
    await p.ev('RC.app.vfs.opts.maxFileSize = 20');
    await p.setCode('PRINT "THIS LINE IS DEFINITELY LONGER THAN TWENTY BYTES"');
    await p.key('s', { ctrl: true });
    await p.waitToast(/Could not save HELLO\.BAS: File too large/);
    p.assert.equal(await H.activeDirty(p), true);
  }, { fresh: NOAUTO });

  t.test('a save that would exceed the disk quota shows "Disk full"', async (p) => {
    await p.ev('RC.app.vfs.opts.maxFileSize = 8e6; RC.app.vfs.opts.maxTotal = RC.app.vfs.drives.C.totalSize() + 5');
    await p.setCode('REM ' + 'X'.repeat(1000));
    await p.key('s', { ctrl: true });
    await p.waitToast(/Could not save HELLO\.BAS: Disk full/);
    p.assert.equal(await H.activeDirty(p), true);
  });

  // ---- closing dirty tabs --------------------------------------------------------------------------------------------
  t.test('closing a dirty own file shows the Unsaved changes dialog with four buttons', async (p) => {
    await H.editActive(p, '\nREM unsaved');
    await tabClose(p, 'HELLO.BAS');
    p.assert.equal(await p.waitModal(), 'Unsaved changes');
    p.assert.match(await p.modalText(), /Save changes to HELLO\.BAS\?/);
    p.assert.deepEqual(await H.modalButtons(p), ['Cancel', "Don't Save", 'Save As…', 'Save']);
  }, { fresh: NOAUTO });

  t.test('Cancel keeps the tab open and dirty', async (p) => {
    await p.modalButton('Cancel');
    p.assert.ok((await H.tabs(p)).includes(HELLO));
    p.assert.equal(await H.isDirty(p, HELLO), true);
  });

  t.test('Escape in the Unsaved changes dialog keeps the tab', async (p) => {
    await tabClose(p, 'HELLO.BAS');
    await p.waitModal();
    await p.key('Escape');
    await p.sleep(60);
    p.assert.ok((await H.tabs(p)).includes(HELLO));
  });

  t.test("Don't Save closes the tab and leaves the disk untouched", async (p) => {
    const disk = await H.rawText(p, HELLO);
    await tabClose(p, 'HELLO.BAS');
    await p.waitModal();
    await p.modalButton("Don't Save");
    p.assert.ok(!(await H.tabs(p)).includes(HELLO));
    p.assert.equal(await H.rawText(p, HELLO), disk);
    p.assert.doesNotMatch(disk, /REM unsaved/);
  });

  t.test('closing the last tab shows the "No open files" hint', async (p) => {
    p.assert.equal((await H.tabs(p)).length, 0);
    p.assert.match(await p.text('#editorTabs'), /No open files/);
    p.assert.equal(await p.activePath(), null);
  });

  t.test('Save in the Unsaved changes dialog writes the file and closes the tab', async (p) => {
    await H.clickRow(p, HELLO);
    await H.editActive(p, '\nREM keep me');
    await tabClose(p, 'HELLO.BAS');
    await p.waitModal();
    await H.button(p, 'Save');
    await p.sleep(80);
    p.assert.ok(!(await H.tabs(p)).includes(HELLO));
    p.assert.match(await H.rawText(p, HELLO), /REM keep me/);
  });

  t.test('Save As… in the Unsaved changes dialog saves under a new name and closes', async (p) => {
    const disk = await H.rawText(p, HELLO);
    await H.clickRow(p, HELLO);
    await H.editActive(p, '\nREM another');
    await tabClose(p, 'HELLO.BAS');
    await p.waitModal();
    await p.modalButton('Save As…');
    p.assert.equal(await p.waitModal(), 'Save As');
    await H.answerPrompt(p, 'OTHER.BAS');
    await p.sleep(100);
    p.assert.equal((await H.tabs(p)).length, 0);
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\OTHER.BAS'), /REM another/);
    p.assert.equal(await H.rawText(p, HELLO), disk);
  });

  t.test('Save As… then Cancel in the name prompt keeps the tab open', async (p) => {
    await H.clickRow(p, HELLO);
    await H.editActive(p, '\nREM still');
    await tabClose(p, 'HELLO.BAS');
    await p.waitModal();
    await p.modalButton('Save As…');
    await p.waitModal();
    await p.modalButton('Cancel');
    await p.sleep(80);
    p.assert.ok((await H.tabs(p)).includes(HELLO));
    p.assert.equal(await H.isDirty(p, HELLO), true);
  });

  t.test('Save failing (disk full) in the close dialog keeps the tab open', async (p) => {
    await p.ev('RC.app.vfs.opts.maxTotal = RC.app.vfs.drives.C.totalSize() + 2');
    await H.editActive(p, '\nREM far too long for the tiny quota');
    await tabClose(p, 'HELLO.BAS');
    await p.waitModal();
    await H.button(p, 'Save');
    await p.waitToast(/Could not save/);
    p.assert.ok((await H.tabs(p)).includes(HELLO));
    await p.ev('RC.app.vfs.opts.maxTotal = 96 * 1024 * 1024');
  });

  t.test('closing a dirty sample shows the Keep your changes? dialog', async (p) => {
    await openSampleEdited(p);
    await tabClose(p, 'GUESS.BAS');
    p.assert.equal(await p.waitModal(), 'Keep your changes?');
    p.assert.match(await p.modalText(), /You changed GUESS\.BAS, which is an example\/tutorial file\. The original stays as it is\./);
    p.assert.deepEqual(await H.modalButtons(p), ['Cancel', 'Discard Changes', 'Save As My Copy…']);
  }, { fresh: NOAUTO });

  t.test('Cancel in Keep your changes? keeps the sample tab dirty', async (p) => {
    await p.modalButton('Cancel');
    p.assert.ok((await H.tabs(p)).includes(GUESS));
    p.assert.equal(await H.isDirty(p, GUESS), true);
  });

  t.test('Discard Changes closes the sample and leaves the original as it was', async (p) => {
    const orig = await H.rawText(p, GUESS);
    await tabClose(p, 'GUESS.BAS');
    await p.waitModal();
    await p.modalButton('Discard Changes');
    p.assert.ok(!(await H.tabs(p)).includes(GUESS));
    p.assert.equal(await H.rawText(p, GUESS), orig);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\GUESS.BAS'), false);
  });

  t.test('reopening a discarded sample shows the original text', async (p) => {
    await H.clickRow(p, GUESS);
    p.assert.doesNotMatch(await p.code(), /MY EDIT/);
    p.assert.equal(await H.activeDirty(p), false);
  });

  t.test('Save As My Copy… saves a copy and closes the tab', async (p) => {
    await H.editActive(p, '\nPRINT "MY EDIT"');
    await tabClose(p, 'GUESS.BAS');
    await p.waitModal();
    await p.modalButton('Save As My Copy…');
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.equal(await H.modalInputValue(p), 'C:\\MYPROGS\\GUESS.BAS');
    await p.modalButton('OK');
    await p.sleep(120);
    p.assert.ok(!(await H.tabs(p)).some((x) => /GUESS\.BAS$/.test(x)));
    p.assert.match(await H.rawText(p, 'C:\\MYPROGS\\GUESS.BAS'), /MY EDIT/);
  });

  t.test('Save As My Copy… then Cancel keeps the sample tab open', async (p) => {
    await openSampleEdited(p);
    await tabClose(p, 'GUESS.BAS');
    await p.waitModal();
    await p.modalButton('Save As My Copy…');
    await p.waitModal();
    await p.modalButton('Cancel');
    await p.sleep(80);
    p.assert.ok((await H.tabs(p)).includes(GUESS));
    p.assert.equal(await H.isDirty(p, GUESS), true);
  });

  t.test('closing a clean tab asks nothing', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\COLORS.BAS');
    await tabClose(p, 'COLORS.BAS');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.ok(!(await H.tabs(p)).includes('C:\\SAMPLES\\COLORS.BAS'));
  });

  t.test('closing the active tab activates the tab before it', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\COLORS.BAS');
    await H.clickRow(p, 'C:\\SAMPLES\\CLOCK.BAS');
    const list = await H.tabs(p);
    const i = list.indexOf('C:\\SAMPLES\\CLOCK.BAS');
    await tabClose(p, 'CLOCK.BAS');
    p.assert.equal(await p.activePath(), list[i - 1]);
  });

  t.test('closing a background tab keeps the active tab', async (p) => {
    const active = await p.activePath();
    await H.clickRow(p, 'C:\\SAMPLES\\LIFE.BAS');
    await p.click('#editorTabs .tab', 'COLORS.BAS');
    await tabClose(p, 'LIFE.BAS');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\COLORS.BAS');
    void active;
  });

  t.test('Alt+W closes the active tab', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\SPIRAL.BAS');
    await p.key('w', { alt: true });
    await p.sleep(60);
    p.assert.ok(!(await H.tabs(p)).includes('C:\\SAMPLES\\SPIRAL.BAS'));
  });

  t.test('File ▸ Close Tab closes the active tab', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\SPIRAL.BAS');
    await p.menu('File', 'Close Tab');
    p.assert.ok(!(await H.tabs(p)).includes('C:\\SAMPLES\\SPIRAL.BAS'));
  });

  t.test('middle-clicking a tab closes it', async (p) => {
    await H.clickRow(p, 'C:\\SAMPLES\\SPIRAL.BAS');
    const [x, y] = await p.center('#editorTabs .tab', 'SPIRAL.BAS');
    await p.clickAt(x, y, { button: 'middle' });
    await p.sleep(60);
    p.assert.ok(!(await H.tabs(p)).includes('C:\\SAMPLES\\SPIRAL.BAS'));
  });

  t.test('Alt+W on a dirty own file shows the Unsaved changes dialog', async (p) => {
    await H.clickRow(p, HELLO);
    await H.editActive(p, '\nREM w');
    await p.key('w', { alt: true });
    p.assert.equal(await p.waitModal(), 'Unsaved changes');
    await p.modalButton("Don't Save");
  });

  // ---- autosave ----------------------------------------------------------------------------------------------------------
  t.test('autosave writes a dirty own file within a few seconds', async (p) => {
    await H.editActive(p, '\nREM autosaved');
    p.assert.equal(await H.activeDirty(p), true);
    await p.wait('!RC.app.active.dirty', 6000);
    p.assert.match(await H.rawText(p, HELLO), /REM autosaved/);
    p.assert.equal(await dirtyDot(p, 'HELLO.BAS'), false);
  }, { fresh: true, timeout: 15000 });

  t.test('autosave never writes protected example files', async (p) => {
    const orig = await H.rawText(p, GUESS);
    await openSampleEdited(p);
    await p.sleep(5000);
    p.assert.equal(await H.activeDirty(p), true);
    p.assert.equal(await H.rawText(p, GUESS), orig);
    p.assert.equal(await H.exists(p, 'C:\\MYPROGS\\GUESS.BAS'), false);
  }, { timeout: 15000 });

  t.test('with autosave off, dirty files stay unsaved', async (p) => {
    const orig = await H.rawText(p, HELLO);
    await H.editActive(p, '\nREM not autosaved');
    await p.sleep(5000);
    p.assert.equal(await H.activeDirty(p), true);
    p.assert.equal(await H.rawText(p, HELLO), orig);
  }, { fresh: NOAUTO, timeout: 15000 });

  t.test('Options ▸ Autosave toggles the setting and its check mark', async (p) => {
    await p.click('.menu-btn', 'Options');
    await p.wait("!!document.querySelector('.menu-pop')");
    const before = (await p.menuItems()).find((x) => x.label === 'Autosave');
    p.assert.equal(before.checked, false);
    await H.clickMenuItem(p, 'Autosave');
    p.assert.equal(await p.ev("JSON.parse(localStorage.getItem('baysik.settings')).autosave"), true);
    await p.click('.menu-btn', 'Options');
    await p.wait("!!document.querySelector('.menu-pop')");
    p.assert.equal((await p.menuItems()).find((x) => x.label === 'Autosave').checked, true);
    await p.closeMenus();
  });

  t.test('turning autosave back on saves the pending edits', async (p) => {
    await p.wait('!RC.app.active.dirty', 6000);
    p.assert.match(await H.rawText(p, HELLO), /REM not autosaved/);
  }, { timeout: 10000 });

  t.test('running a program with autosave on saves dirty own files first', async (p) => {
    await p.setCode('PRINT "RUN SAVES"');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.equal(await H.rawText(p, HELLO), 'PRINT "RUN SAVES"');
  }, { fresh: true });

  t.test('running a program with autosave off does not save', async (p) => {
    const orig = await H.rawText(p, HELLO);
    await p.setCode('PRINT "RUN ONLY"');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /RUN ONLY/);
    p.assert.equal(await H.rawText(p, HELLO), orig);
    p.assert.equal(await H.activeDirty(p), true);
  }, { fresh: NOAUTO });

  t.test('autosave does not write files on a mounted D: drive', async (p) => {
    await H.fakePicker(p, 'HOST', { 'H.BAS': 'PRINT "HOST"' });
    await H.headerBtn(p, 'Mount a computer folder as D:');
    await p.waitModal();
    await p.ev("document.querySelector('.modal select').value = 'write'");
    await p.modalButton('Choose Folder…');
    await H.waitRow(p, 'D:\\H.BAS');
    await H.clickRow(p, 'D:\\H.BAS');
    await p.wait("RC.app.active.path === 'D:\\\\H.BAS'", 3000);
    await H.editActive(p, '\nREM host edit');
    await p.sleep(5000);
    p.assert.equal(await H.activeDirty(p), true);
    p.assert.equal(await p.ev("Object.keys(window.__hostWrites).length"), 0);
  }, { fresh: true, timeout: 15000 });

  t.test('Ctrl+S on a mounted D: file writes through to the real folder', async (p) => {
    await p.key('s', { ctrl: true });
    await p.wait("window.__hostWrites['/H.BAS'] !== undefined", 3000);
    p.assert.match(await p.ev("window.__hostWrites['/H.BAS']"), /REM host edit/);
    p.assert.equal(await H.activeDirty(p), false);
  });
  t.register();
};
