// Mounting a computer folder as D: (File System Access API) with a fake in-memory directory handle.
import { installFakeFS, mountVia } from './90-share-lib.mjs';

const TREE = { 'HELLO.TXT': 'hi there\r\n', 'NUMS.TXT': '1\r\n2\r\n3\r\n', 'SUB/A.TXT': 'inside sub\r\n', 'SUB/PROG.BAS': 'PRINT "FROM D DRIVE"; 6 * 7\r\n', '.hidden': 'secret' };
const fake = (p, path) => p.fn((path) => { const f = window.__fakeFile(path); return f ? (f.kind === 'file' ? f.text() : 'DIR') : null; }, path);
const driveLabel = (p) => p.ev("[...document.querySelectorAll('#explorerTree .tree-item .nm')].map(e => e.innerText).find(t => t.startsWith('D:')) || null");

async function freshMount(p, mode, how) {
  await p.fresh();
  await installFakeFS(p, 'MyStuff', TREE);
  await mountVia(p, mode, how);
}
async function ensureMount(p, mode) {
  const ok = await p.ev('!!(RC.app.vfs.drives.D && window.__fakeRoot)');
  if (!ok) { await freshMount(p, mode); return; }
  await p.fn((m) => { RC.app.vfs.drives.D.writable = m === 'write' ? true : m === 'ask' ? 'ask' : false; RC.app.renderExplorer(); }, mode);
}
const READ_PROG = 'OPEN "D:\\HELLO.TXT" FOR INPUT AS #1\nLINE INPUT #1, A$\nCLOSE #1\nPRINT "GOT:"; A$';
const WRITE_PROG = (path, text) => `OPEN "${path}" FOR OUTPUT AS #1\nPRINT #1, "${text}"\nCLOSE #1\nPRINT "WROTE OK"`;

async function runExpectError(p, prog, code) {
  const st = await p.runProgram(prog);
  p.assert.equal(st, 'error');
  p.assert.match(await p.status(), new RegExp('Runtime error ' + code));
}

export default (t) => {
  t.beforeEach(async (p) => {
    if (['running', 'waiting', 'paused'].includes(await p.state())) await p.stopProgram();
  });
  // ---- unsupported browser --------------------------------------------------------------------
  t.test('File ▸ Mount without showDirectoryPicker shows "Not supported in this browser"', async (p) => {
    await p.ev('window.showDirectoryPicker = undefined');
    await p.menu('File', 'Mount Computer Folder as D:…');
    p.assert.equal(await p.waitModal(), 'Not supported in this browser');
    p.assert.match(await p.modalText(), /File System Access API/);
    p.assert.match(await p.modalText(), /Import Files/);
    await p.modalButton('OK');
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
  });

  t.test('explorer Mount button without showDirectoryPicker also shows "Not supported"', async (p) => {
    await p.click('#explorerActions button[title="Mount a computer folder as D:"]');
    p.assert.equal(await p.waitModal(), 'Not supported in this browser');
    await p.modalButton('OK');
  });

  t.test('Unmount D: is disabled when nothing is mounted', async (p) => {
    await p.click('.menu-btn', 'File');
    const it = (await p.menuItems()).find((x) => x.label === 'Unmount D:');
    p.assert.equal(it.disabled, true);
    await p.closeMenus();
  });

  // ---- mount dialog -------------------------------------------------------------------------------
  t.test('mount dialog explains D: and offers three permission modes (ask by default)', async (p) => {
    await p.fresh();
    await installFakeFS(p, 'MyStuff', TREE);
    await p.click('#explorerActions button[title="Mount a computer folder as D:"]');
    p.assert.equal(await p.waitModal(), 'Mount a Folder as Drive D:');
    p.assert.match(await p.modalText(), /OPEN "D:\\SCORES\.TXT" FOR INPUT AS #1/);
    const opts = await p.ev("[...document.querySelectorAll('.modal-back:last-child select option')].map(o => o.value + '|' + o.innerText)");
    p.assert.deepEqual(opts.map((o) => o.split('|')[0]), ['read', 'ask', 'write']);
    p.assert.match(opts[1], /recommended/);
    p.assert.equal(await p.ev("document.querySelector('.modal-back:last-child select').value"), 'ask');
  });

  t.test('Cancel in the mount dialog never opens the folder picker', async (p) => {
    await p.modalButton('Cancel');
    await p.sleep(100);
    p.assert.equal(await p.ev('window.__pickerCalls.length'), 0);
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
  });

  t.test('a cancelled folder picker (AbortError) mounts nothing and shows no error', async (p) => {
    await p.ev("window.showDirectoryPicker = async () => { throw new DOMException('The user aborted a request.', 'AbortError'); }");
    await p.click('#explorerActions button[title="Mount a computer folder as D:"]');
    await p.waitModal();
    await p.modalButton('Choose Folder…');
    await p.sleep(200);
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
    p.assert.equal(await p.count('.toast.err'), 0);
  });

  t.test('a failing folder picker shows a "Mount failed" toast', async (p) => {
    await p.ev("window.showDirectoryPicker = async () => { throw new DOMException('Blocked by policy', 'SecurityError'); }");
    await p.click('#explorerActions button[title="Mount a computer folder as D:"]');
    await p.waitModal();
    await p.modalButton('Choose Folder…');
    await p.waitToast(/Mount failed: Blocked by policy/);
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
  });

  // ---- ask mode (default) ---------------------------------------------------------------------------
  t.test('mounting in ask mode requests a readwrite handle', async (p) => {
    await freshMount(p, 'ask');
    p.assert.deepEqual(await p.ev('window.__pickerCalls'), [{ mode: 'readwrite' }]);
  });

  t.test('mounting shows a "Mounted … as D:" toast', async (p) => {
    await p.waitToast(/Mounted "MyStuff" as D:/);
  });

  t.test('D: appears in the explorer with the folder label and ask permission text', async (p) => {
    p.assert.equal(await driveLabel(p), 'D: (MyStuff — your computer, ask before writing)');
  });

  t.test('D: is expanded showing folders first, then files', async (p) => {
    const names = await p.texts('#explorerTree .tree-item .nm');
    const i = names.indexOf('D: (MyStuff — your computer, ask before writing)');
    p.assert.deepEqual(names.slice(i + 1), ['SUB', 'HELLO.TXT', 'NUMS.TXT']);
  });

  t.test('dot-files in the mounted folder are hidden', async (p) => {
    p.assert.equal(await p.ev("RC.app.vfs.exists('D:\\\\.hidden')"), false);
    p.assert.ok(!(await p.texts('#explorerTree .tree-item .nm')).includes('.hidden'));
  });

  t.test('mounted file sizes are known before the files are read', async (p) => {
    p.assert.equal(await p.ev("RC.app.vfs.stat('D:\\\\HELLO.TXT').size"), 10);
    p.assert.equal(await p.ev("RC.app.vfs.stat('D:\\\\SUB').type"), 'dir');
  });

  t.test('Unmount D: is enabled once a folder is mounted', async (p) => {
    await p.click('.menu-btn', 'File');
    p.assert.equal((await p.menuItems()).find((x) => x.label === 'Unmount D:').disabled, false);
    await p.closeMenus();
  });

  t.test('a program reads a text file from D:', async (p) => {
    const st = await p.runProgram(READ_PROG);
    p.assert.equal(st, 'ended');
    p.assert.match(await p.screen(), /GOT:hi there/);
  });

  t.test('a program reads every line of a D: file until EOF', async (p) => {
    await p.runProgram('OPEN "D:\\NUMS.TXT" FOR INPUT AS #1\nT = 0\nDO WHILE NOT EOF(1)\nINPUT #1, N\nT = T + N\nLOOP\nCLOSE #1\nPRINT "TOTAL"; T');
    p.assert.match(await p.screen(), /TOTAL 6/);
  });

  t.test('a program reads a file from a D: subfolder', async (p) => {
    await p.runProgram('OPEN "D:\\SUB\\A.TXT" FOR INPUT AS #1\nLINE INPUT #1, A$\nCLOSE\nPRINT "[" + A$ + "]"');
    p.assert.match(await p.screen(), /\[inside sub\]/);
  });

  t.test('reading in ask mode does not prompt for permission', async (p) => {
    await p.runProgram(READ_PROG);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.state(), 'ended');
  });

  t.test('opening a missing D: file for input gives "File not found"', async (p) => {
    await runExpectError(p, 'OPEN "D:\\NOPE.TXT" FOR INPUT AS #1', 53);
  });

  t.test('clicking a D: file in the explorer opens it in the editor', async (p) => {
    await p.click('#explorerTree .tree-item .nm', 'HELLO.TXT');
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\HELLO.TXT'");
    p.assert.equal(await p.code(), 'hi there\n');
  });

  t.test('a .BAS program stored on D: can be opened and run', async (p) => {
    await p.click('#explorerTree .tree-item .nm', 'SUB');
    await p.click('#explorerTree .tree-item .nm', 'PROG.BAS');
    await p.wait("RC.app.active && RC.app.active.path === 'D:\\\\SUB\\\\PROG.BAS'");
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /FROM D DRIVE 42/);
  });

  // Each ask-mode test starts its own write so a failure cannot cascade.
  const askWrite = async (p, path, text) => {
    await ensureMount(p, 'ask');
    await p.runProgram(WRITE_PROG(path, text), { wait: false });
    return p.waitModal();
  };

  t.test('ask mode: a write shows the "Allow file write?" dialog with the path', async (p) => {
    p.assert.equal(await askWrite(p, 'D:\\OUT.TXT', 'asked'), 'Allow file write?');
    p.assert.match(await p.modalText(), /Your program wants to write to:\s+D:\\OUT\.TXT/);
    p.assert.match(await p.modalText(), /folder on your real computer/);
    await p.modalButton('Always Allow for D:');
  });

  t.test('ask mode: the dialog offers Deny, Allow Once and Always Allow for D:', async (p) => {
    await askWrite(p, 'D:\\OUT.TXT', 'asked');
    p.assert.deepEqual(await p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map(b => b.innerText + (b.classList.contains('primary') ? '*' : ''))"), ['Deny', 'Allow Once', 'Always Allow for D:*']);
    await p.modalButton('Always Allow for D:');
  });

  t.test('ask mode: the program waits while the dialog is open', async (p) => {
    await askWrite(p, 'D:\\OUT.TXT', 'asked');
    await p.sleep(200);
    p.assert.equal(await p.state(), 'waiting');
    p.assert.doesNotMatch(await p.screen(), /WROTE OK/);
    await p.modalButton('Always Allow for D:');
    await p.waitState(['ended', 'error']);
  });

  t.test('ask mode: clicking outside the dialog does not dismiss it', async (p) => {
    await askWrite(p, 'D:\\OUT.TXT', 'asked');
    await p.clickAt(5, 5);
    p.assert.equal(await p.modalTitle(), 'Allow file write?');
    await p.modalButton('Always Allow for D:');
  });

  t.test('ask mode: Deny stops the program with "Permission denied" and writes nothing', async (p) => {
    await askWrite(p, 'D:\\DENIED.TXT', 'denied');
    await p.modalButton('Deny');
    await p.waitState(['error', 'ended'], 3000).catch(() => {});
    p.assert.equal(await p.state(), 'error');
    p.assert.match(await p.status(), /Runtime error 70: Permission denied/);
    p.assert.equal(await fake(p, 'DENIED.TXT'), null);
  });

  t.test('ask mode: Deny never writes the file to the real folder', async (p) => {
    await askWrite(p, 'D:\\DENIED2.TXT', 'denied');
    await p.modalButton('Deny');
    await p.sleep(400);
    p.assert.equal(await fake(p, 'DENIED2.TXT'), null);
    p.assert.equal(await p.ev("RC.app.vfs.exists('D:\\\\DENIED2.TXT')"), false);
    p.assert.doesNotMatch(await p.screen(), /WROTE OK/);
  }, { allowExceptions: true });

  t.test('ask mode: Escape in the write dialog counts as Deny', async (p) => {
    await askWrite(p, 'D:\\ESC.TXT', 'esc');
    await p.key('Escape');
    await p.waitGone('.modal-back');
    await p.waitState(['error', 'ended'], 3000).catch(() => {});
    p.assert.match(await p.status(), /Runtime error 70/);
    p.assert.equal(await fake(p, 'ESC.TXT'), null);
  });

  t.test('ask mode: Allow Once lets this write finish and reach the real folder', async (p) => {
    await askWrite(p, 'D:\\ONCE.TXT', 'once');
    await p.modalButton('Allow Once');
    await p.sleep(600);
    const again = (await p.modalTitle()) === 'Allow file write?';
    if (again) await p.modalButton('Always Allow for D:');
    await p.waitState(['ended', 'error']);
    p.assert.equal(again, false, 'Allow Once asked again for the same write');
    p.assert.match(await p.screen(), /WROTE OK/);
    await p.wait("window.__fakeFile('ONCE.TXT') && window.__fakeFile('ONCE.TXT').text() === 'once\\r\\n'", 3000);
  });

  t.test('ask mode: Always Allow lets the write finish and the data reaches the real folder', async (p) => {
    await askWrite(p, 'D:\\OUT.TXT', 'always');
    await p.modalButton('Always Allow for D:');
    await p.waitState(['ended', 'error']);
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /WROTE OK/);
    await p.wait("window.__fakeFile('OUT.TXT') && window.__fakeFile('OUT.TXT').text() === 'always\\r\\n'", 3000);
  });

  t.test('ask mode: after Always Allow the explorer label drops the ask text', async (p) => {
    await askWrite(p, 'D:\\OUT.TXT', 'always');
    await p.modalButton('Always Allow for D:');
    await p.waitState(['ended', 'error']);
    p.assert.equal(await driveLabel(p), 'D: (MyStuff — your computer)');
    p.assert.equal(await p.ev('RC.app.vfs.drives.D.writable'), true);
  });

  t.test('ask mode: after Always Allow later writes do not prompt', async (p) => {
    const st = await p.runProgram(WRITE_PROG('D:\\SUB\\LATER.TXT', 'later'));
    p.assert.equal(st, 'ended');
    p.assert.equal(await p.modalOpen(), false);
    await p.wait("window.__fakeFile('SUB/LATER.TXT') && window.__fakeFile('SUB/LATER.TXT').text() === 'later\\r\\n'", 3000);
  });

  t.test('written D: files can be read back by a program', async (p) => {
    await p.runProgram('OPEN "D:\\OUT.TXT" FOR INPUT AS #1\nLINE INPUT #1, A$\nCLOSE\nPRINT "BACK:"; A$');
    p.assert.match(await p.screen(), /BACK:always/);
  });

  t.test('File ▸ Unmount D: removes the drive from the explorer and the disk', async (p) => {
    await p.menu('File', 'Unmount D:');
    await p.sleep(100);
    p.assert.equal(await p.ev('!!RC.app.vfs.drives.D'), false);
    p.assert.equal(await driveLabel(p), null);
    await p.click('.menu-btn', 'File');
    p.assert.equal((await p.menuItems()).find((x) => x.label === 'Unmount D:').disabled, true);
    await p.closeMenus();
  });

  t.test('after unmounting, programs get "Device unavailable" for D:', async (p) => {
    await runExpectError(p, READ_PROG, 68);
  });
};
