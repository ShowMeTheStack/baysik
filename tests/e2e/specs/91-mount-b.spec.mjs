// Mounted D: drive in read-only and write modes, editor saves, re-mounting and reload.
import { installFakeFS, mountVia } from './90-share-lib.mjs';

const TREE = { 'HELLO.TXT': 'hi there\r\n', 'NUMS.TXT': '1\r\n2\r\n3\r\n', 'SUB/A.TXT': 'inside sub\r\n' };
const fake = (p, path) => p.fn((path) => { const f = window.__fakeFile(path); return f ? (f.kind === 'file' ? f.text() : 'DIR') : null; }, path);
const driveLabel = (p) => p.ev("[...document.querySelectorAll('#explorerTree .tree-item .nm')].map(e => e.innerText).find(t => t.startsWith('D:')) || null");
const waitFake = (p, path, text) => p.wait(`window.__fakeFile(${JSON.stringify(path)}) && window.__fakeFile(${JSON.stringify(path)}).text() === ${JSON.stringify(text)}`, 3000);

async function ensureMount(p, mode, how) {
  const ok = await p.fn((m) => !!(RC.app.vfs.drives.D && window.__fakeRoot && window.__mode === m), mode);
  if (ok) return;
  await p.fresh();
  await installFakeFS(p, 'MyStuff', TREE);
  await mountVia(p, mode, how);
  await p.fn((m) => { window.__mode = m; }, mode);
}
async function runErr(p, prog, code) {
  const st = await p.runProgram(prog);
  p.assert.equal(st, 'error');
  p.assert.match(await p.status(), new RegExp('Runtime error ' + code + (code === 70 ? ': Permission denied' : '')));
  p.assert.equal(await p.modalOpen(), false, 'no permission dialog expected');
}

export default (t) => {
  t.beforeEach(async (p) => {
    if (['running', 'waiting', 'paused'].includes(await p.state())) await p.stopProgram();
  });

  // ---- read-only --------------------------------------------------------------------------------
  t.test('read-only: File ▸ Mount with Read-only asks the picker for a read handle', async (p) => {
    await ensureMount(p, 'read', 'menu');
    p.assert.deepEqual(await p.ev('window.__pickerCalls'), [{ mode: 'read' }]);
  });

  t.test('read-only: the explorer label says read-only', async (p) => {
    await ensureMount(p, 'read');
    p.assert.equal(await driveLabel(p), 'D: (MyStuff — your computer, read-only)');
  });

  t.test('read-only: programs can still read files', async (p) => {
    await ensureMount(p, 'read');
    await p.runProgram('OPEN "D:\\HELLO.TXT" FOR INPUT AS #1\nLINE INPUT #1, A$\nCLOSE\nPRINT "RO:"; A$');
    p.assert.match(await p.screen(), /RO:hi there/);
  });

  t.test('read-only: OPEN FOR OUTPUT fails with Permission denied and writes nothing', async (p) => {
    await ensureMount(p, 'read');
    await runErr(p, 'OPEN "D:\\NEW.TXT" FOR OUTPUT AS #1\nPRINT #1, "x"\nCLOSE', 70);
    p.assert.equal(await fake(p, 'NEW.TXT'), null);
    p.assert.deepEqual(await p.ev('window.__fakeLog'), []);
  });

  t.test('read-only: OPEN FOR OUTPUT on an existing file leaves it untouched', async (p) => {
    await ensureMount(p, 'read');
    await runErr(p, 'OPEN "D:\\HELLO.TXT" FOR OUTPUT AS #1', 70);
    p.assert.equal(await fake(p, 'HELLO.TXT'), 'hi there\r\n');
  });

  t.test('read-only: OPEN FOR APPEND fails with Permission denied', async (p) => {
    await ensureMount(p, 'read');
    await runErr(p, 'OPEN "D:\\NUMS.TXT" FOR APPEND AS #1\nPRINT #1, 4\nCLOSE', 70);
    p.assert.equal(await fake(p, 'NUMS.TXT'), '1\r\n2\r\n3\r\n');
  });

  t.test('read-only: KILL fails with Permission denied and the file stays', async (p) => {
    await ensureMount(p, 'read');
    await runErr(p, 'KILL "D:\\HELLO.TXT"', 70);
    p.assert.equal(await fake(p, 'HELLO.TXT'), 'hi there\r\n');
    p.assert.equal(await p.ev("RC.app.vfs.exists('D:\\\\HELLO.TXT')"), true);
  });

  t.test('read-only: MKDIR fails with Permission denied', async (p) => {
    await ensureMount(p, 'read');
    await runErr(p, 'MKDIR "D:\\NEWDIR"', 70);
    p.assert.equal(await fake(p, 'NEWDIR'), null);
  });

  t.test('read-only: NAME (rename) fails with Permission denied', async (p) => {
    await ensureMount(p, 'read');
    await runErr(p, 'NAME "D:\\HELLO.TXT" AS "D:\\BYE.TXT"', 70);
    p.assert.equal(await fake(p, 'BYE.TXT'), null);
    p.assert.equal(await fake(p, 'HELLO.TXT'), 'hi there\r\n');
  });

  t.test('read-only: saving an edited D: file in the editor fails with a toast', async (p) => {
    await ensureMount(p, 'read');
    await p.ev("RC.app.openFile('D:\\\\HELLO.TXT')");
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\HELLO.TXT'");
    await p.setCode('changed by editor');
    await p.key('s', { ctrl: true });
    await p.waitToast(/Could not save HELLO\.TXT: Permission denied/);
    await p.sleep(200);
    p.assert.equal(await fake(p, 'HELLO.TXT'), 'hi there\r\n');
    await p.ev('RC.app.active.dirty = false; RC.app.closeDoc(RC.app.active)');
  });

  // ---- write mode ---------------------------------------------------------------------------------
  t.test('write: mounting with "Allow programs to write" requests a readwrite handle', async (p) => {
    await ensureMount(p, 'write');
    p.assert.deepEqual(await p.ev('window.__pickerCalls'), [{ mode: 'readwrite' }]);
  });

  t.test('write: the explorer label has no permission suffix', async (p) => {
    await ensureMount(p, 'write');
    p.assert.equal(await driveLabel(p), 'D: (MyStuff — your computer)');
  });

  t.test('write: a program creates a new file in the real folder without asking', async (p) => {
    await ensureMount(p, 'write');
    const st = await p.runProgram('OPEN "D:\\SCORES.TXT" FOR OUTPUT AS #1\nPRINT #1, "ALICE"; 100\nCLOSE\nPRINT "SAVED"');
    p.assert.equal(st, 'ended');
    p.assert.equal(await p.modalOpen(), false);
    await waitFake(p, 'SCORES.TXT', 'ALICE 100 \r\n');
    p.assert.ok((await p.ev('window.__fakeLog')).includes('create SCORES.TXT'));
  });

  t.test('write: overwriting an existing file updates the real file', async (p) => {
    await ensureMount(p, 'write');
    await p.runProgram('OPEN "D:\\HELLO.TXT" FOR OUTPUT AS #1\nPRINT #1, "replaced"\nCLOSE');
    await waitFake(p, 'HELLO.TXT', 'replaced\r\n');
  });

  t.test('write: APPEND adds to the end of a real file', async (p) => {
    await ensureMount(p, 'write');
    await p.runProgram('OPEN "D:\\NUMS.TXT" FOR APPEND AS #1\nPRINT #1, "4"\nCLOSE');
    await waitFake(p, 'NUMS.TXT', '1\r\n2\r\n3\r\n4\r\n');
  });

  t.test('write: writing into a subfolder reaches the real subfolder', async (p) => {
    await ensureMount(p, 'write');
    await p.runProgram('OPEN "D:\\SUB\\B.TXT" FOR OUTPUT AS #1\nWRITE #1, "q", 7\nCLOSE');
    await waitFake(p, 'SUB/B.TXT', '"q",7\r\n');
  });

  t.test('write: MKDIR creates a real folder', async (p) => {
    await ensureMount(p, 'write');
    const st = await p.runProgram('MKDIR "D:\\MADE"\nOPEN "D:\\MADE\\IN.TXT" FOR OUTPUT AS #1\nPRINT #1, "in"\nCLOSE');
    p.assert.equal(st, 'ended');
    await p.wait("window.__fakeFile('MADE') && window.__fakeFile('MADE').kind === 'directory'", 3000);
    await waitFake(p, 'MADE/IN.TXT', 'in\r\n');
  });

  t.test('write: KILL deletes the real file', async (p) => {
    await ensureMount(p, 'write');
    await p.runProgram('OPEN "D:\\GONE.TXT" FOR OUTPUT AS #1\nPRINT #1, "x"\nCLOSE');
    await waitFake(p, 'GONE.TXT', 'x\r\n');
    const st = await p.runProgram('KILL "D:\\GONE.TXT"');
    p.assert.equal(st, 'ended');
    await p.wait("window.__fakeFile('GONE.TXT') === null", 3000);
    p.assert.equal(await p.ev("RC.app.vfs.exists('D:\\\\GONE.TXT')"), false);
  });

  t.test('write: NAME renames a never-read real file keeping its contents', async (p) => {
    await ensureMount(p, 'write');
    const st = await p.runProgram('NAME "D:\\SUB\\A.TXT" AS "D:\\SUB\\RENAMED.TXT"');
    p.assert.equal(st, 'ended');
    await p.wait("window.__fakeFile('SUB/A.TXT') === null", 3000);
    await waitFake(p, 'SUB/RENAMED.TXT', 'inside sub\r\n');
  });

  t.test('write: NAME removes the old real file after renaming', async (p) => {
    await ensureMount(p, 'write');
    await p.runProgram('OPEN "D:\\OLD.TXT" FOR OUTPUT AS #1\nPRINT #1, "old"\nCLOSE');
    await waitFake(p, 'OLD.TXT', 'old\r\n');
    const st = await p.runProgram('NAME "D:\\OLD.TXT" AS "D:\\NEW.TXT"');
    p.assert.equal(st, 'ended');
    await waitFake(p, 'NEW.TXT', 'old\r\n');
    await p.wait("window.__fakeFile('OLD.TXT') === null", 3000);
  });

  t.test('write: the program sees its own written data on D:', async (p) => {
    await ensureMount(p, 'write');
    await p.runProgram('OPEN "D:\\RT.TXT" FOR OUTPUT AS #1\nPRINT #1, "round"\nCLOSE\nOPEN "D:\\RT.TXT" FOR INPUT AS #1\nLINE INPUT #1, A$\nCLOSE\nPRINT "RT="; A$');
    p.assert.match(await p.screen(), /RT=round/);
  });

  t.test('write: saving an edited D: file with Ctrl+S writes it to the real folder', async (p) => {
    await ensureMount(p, 'write');
    await p.ev("RC.app.openFile('D:\\\\NUMS.TXT')");
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\NUMS.TXT'");
    await p.setCode('9\n8\n');
    await p.key('s', { ctrl: true });
    await waitFake(p, 'NUMS.TXT', '9\r\n8\r\n');
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
  });

  // ---- ask mode + editor -----------------------------------------------------------------------------
  t.test('ask: saving a D: file from the editor (user action) writes without a dialog', async (p) => {
    await ensureMount(p, 'ask');
    await p.ev("RC.app.openFile('D:\\\\HELLO.TXT')");
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\HELLO.TXT'");
    await p.setCode('edited in ide');
    await p.key('s', { ctrl: true });
    await waitFake(p, 'HELLO.TXT', 'edited in ide');
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('ask: autosave does not write D: files in the background', async (p) => {
    await ensureMount(p, 'ask');
    await p.ev("RC.app.openFile('D:\\\\NUMS.TXT')");
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\NUMS.TXT'");
    await p.setCode('not yet saved');
    await p.ev('RC.app.autosaveTick()');
    await p.sleep(300);
    p.assert.equal(await fake(p, 'NUMS.TXT'), '1\r\n2\r\n3\r\n');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    await p.ev('RC.app.active.dirty = false; RC.app.closeDoc(RC.app.active)');
  });

  t.test('FILES lists the mounted folder contents', async (p) => {
    await ensureMount(p, 'ask');
    await p.runProgram('FILES "D:\\*.TXT"');
    const s = await p.screen();
    p.assert.match(s, /HELLO\s*\.TXT|HELLO\.TXT/);
    p.assert.match(s, /NUMS\s*\.TXT|NUMS\.TXT/);
  });

  // ---- remount / reload ------------------------------------------------------------------------------
  t.test('mounting another folder replaces the current D:', async (p) => {
    await ensureMount(p, 'ask');
    await installFakeFS(p, 'Other', { 'ONLY.TXT': 'only' });
    await mountVia(p, 'read');
    p.assert.equal(await driveLabel(p), 'D: (Other — your computer, read-only)');
    p.assert.equal(await p.ev("RC.app.vfs.exists('D:\\\\HELLO.TXT')"), false);
    p.assert.equal(await p.ev("RC.app.vfs.exists('D:\\\\ONLY.TXT')"), true);
    await p.fn(() => { window.__mode = 'other'; });
  });

  t.test('the mount does not survive a page reload', async (p) => {
    await ensureMount(p, 'ask');
    await p.reload();
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
    p.assert.equal(await driveLabel(p), null);
  });

  t.test('the explorer Unmount path (File ▸ Unmount D:) also clears an open D: drive selection', async (p) => {
    await ensureMount(p, 'write');
    await p.ev("RC.app.vfs.setDrive('D')");
    await p.menu('File', 'Unmount D:');
    p.assert.equal(await p.ev('RC.app.vfs.curDrive'), 'C');
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
  });
};
