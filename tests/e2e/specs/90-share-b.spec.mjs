// Sharing: importing share links/codes (page load with #share=, File ▸ Import Shared Code), validation, round trips.
import { stubClipboard, makeFolder, packCode, rawCode, b64u, folderContext } from './90-share-lib.mjs';

const FILES = { 'MAIN.BAS': 'PRINT "SHARED MAIN"\r\n', 'LIB/HELP.BAS': 'PRINT "HELPER"\r\n', 'DATA.TXT': 'one\r\ntwo\r\n' };
const read = (p, path) => p.fn((path) => (RC.app.vfs.exists(path) ? RC.bytesToStr(RC.app.vfs.readFile(path)) : null), path);
const exists = (p, path) => p.fn((path) => RC.app.vfs.exists(path), path);
const mains = (p) => p.ev("JSON.parse(localStorage.getItem('baysik.mains') || '{}')");

async function loadWithCode(p, code, opts = {}) {
  await p.fresh(Object.assign({ hash: 'share=' + code }, opts));
  return p.waitModal();
}
async function importViaDialog(p, text) {
  await p.menu('File', 'Import Shared Code…');
  await p.waitModal();
  await p.modalInput(text);
  await p.modalButton('Import');
}
async function expectAlert(p, re) {
  await p.wait("(document.querySelector('.modal-back:last-child .modal-head') || {}).innerText === 'Import failed'", 4000);
  const txt = await p.modalText();
  p.assert.match(txt, re);
  await p.modalButton('OK');
}

export default (t) => {
  let code;
  t.test('page load with #share=<code> asks "Open shared project?"', async (p) => {
    code = await packCode(p, { name: 'GAME', main: 'MAIN.BAS', lang: 'basic' }, FILES);
    const title = await loadWithCode(p, code);
    p.assert.equal(title, 'Open shared project?');
  });

  t.test('the import confirmation lists the file count and every file', async (p) => {
    const txt = await p.modalText();
    p.assert.match(txt, /contains 3 file\(s\)/);
    for (const n of Object.keys(FILES)) p.assert.ok(txt.includes(n), n);
    p.assert.match(txt, /copied into a new folder on your virtual disk \(C:\)/);
  });

  t.test('the #share hash is removed from the URL straight away', async (p) => {
    p.assert.equal(await p.ev('location.hash'), '');
    p.assert.ok(!(await p.ev('location.href')).includes('share='));
  });

  t.test('the confirmation offers Cancel and Import (primary)', async (p) => {
    p.assert.deepEqual(await p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map(b => b.innerText + (b.classList.contains('primary') ? '*' : ''))"), ['Cancel', 'Import*']);
  });

  t.test('Import copies the files into C:\\SHARED\\<NAME> with exact contents', async (p) => {
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\GAME\\\\MAIN.BAS')");
    for (const [k, v] of Object.entries(FILES)) p.assert.equal(await read(p, 'C:\\SHARED\\GAME\\' + k.replace(/\//g, '\\')), v, k);
  });

  t.test('nested folders from the share are created', async (p) => {
    p.assert.equal(await p.ev("RC.app.vfs.stat('C:\\\\SHARED\\\\GAME\\\\LIB').type"), 'dir');
  });

  t.test('the main program is opened in the editor', async (p) => {
    p.assert.equal(await p.activePath(), 'C:\\SHARED\\GAME\\MAIN.BAS');
    p.assert.match(await p.code(), /PRINT "SHARED MAIN"/);
  });

  t.test('the main program is set as the folder main (badge in explorer)', async (p) => {
    p.assert.equal((await mains(p))['C:\\SHARED\\GAME'], 'C:\\SHARED\\GAME\\MAIN.BAS');
    p.assert.deepEqual(await p.texts('#explorerTree .tree-item.main .nm'), ['MAIN.BAS']);
    p.assert.equal(await p.text('#explorerTree .tree-item.main .badge'), 'main');
  });

  t.test('an "Imported into" toast names the target folder', async (p) => {
    await p.waitToast(/Imported into C:\\SHARED\\GAME/);
  });

  t.test('the explorer expands C:\\SHARED and the imported folder', async (p) => {
    const names = await p.texts('#explorerTree .tree-item .nm');
    for (const n of ['SHARED', 'GAME', 'MAIN.BAS', 'DATA.TXT']) p.assert.ok(names.includes(n), n);
  });

  t.test('importing the same code again goes into GAME2, keeping the first copy', async (p) => {
    await p.ev("RC.app.vfs.writeFile('C:\\\\SHARED\\\\GAME\\\\DATA.TXT', RC.strToBytes('changed'), {trusted: true})");
    await p.ev(`void RC.app.importShare(${JSON.stringify(code)})`);
    await p.waitModal();
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\GAME2\\\\MAIN.BAS')");
    p.assert.equal(await read(p, 'C:\\SHARED\\GAME\\DATA.TXT'), 'changed');
    p.assert.equal(await read(p, 'C:\\SHARED\\GAME2\\DATA.TXT'), FILES['DATA.TXT']);
    p.assert.equal(await p.activePath(), 'C:\\SHARED\\GAME2\\MAIN.BAS');
  });

  t.test('a third import goes into GAME3', async (p) => {
    await p.ev(`void RC.app.importShare(${JSON.stringify(code)})`);
    await p.waitModal();
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\GAME3\\\\MAIN.BAS')");
    await p.waitToast(/Imported into C:\\SHARED\\GAME3/);
  });

  t.test('Cancel on the confirmation imports nothing', async (p) => {
    await loadWithCode(p, code);
    await p.modalButton('Cancel');
    await p.sleep(200);
    p.assert.equal(await exists(p, 'C:\\SHARED'), false);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
  });

  t.test('a share link on a true first run shows the import, not the Welcome dialog', async (p) => {
    const title = await loadWithCode(p, code, { firstRun: true });
    p.assert.equal(title, 'Open shared project?');
    await p.modalButton('Import');
    await p.sleep(900);
    p.assert.notEqual(await p.modalTitle(), 'Welcome!');
    p.assert.equal(await p.activePath(), 'C:\\SHARED\\GAME\\MAIN.BAS');
  });

  t.test('without meta.main the first .BAS file is opened but not set as main', async (p) => {
    const c = await packCode(p, { name: 'NOMAIN' }, { 'README.TXT': 'read me', 'PROG.BAS': 'PRINT 1' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\SHARED\\\\NOMAIN\\\\PROG.BAS'");
    p.assert.equal((await mains(p))['C:\\SHARED\\NOMAIN'], undefined);
  });

  t.test('a share with no .BAS file imports files but opens nothing new', async (p) => {
    const c = await packCode(p, { name: 'TEXTS' }, { 'A.TXT': 'alpha', 'B.TXT': 'beta' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\TEXTS\\\\B.TXT')");
    await p.sleep(100);
    p.assert.equal(await p.activePath(), 'C:\\MYPROGS\\HELLO.BAS');
    p.assert.equal(await read(p, 'C:\\SHARED\\TEXTS\\A.TXT'), 'alpha');
  });

  t.test('project names are sanitised to letters, digits, _ and -', async (p) => {
    const c = await packCode(p, { name: 'My Game! v2.0' }, { 'X.BAS': 'PRINT 1' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\MyGamev20\\\\X.BAS')");
  });

  t.test('long project names are cut to 20 characters', async (p) => {
    const c = await packCode(p, { name: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' }, { 'X.BAS': 'PRINT 1' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\ABCDEFGHIJKLMNOPQRST\\\\X.BAS')");
  });

  t.test('a project without a name is imported as PROJECT', async (p) => {
    const c = await packCode(p, {}, { 'X.BAS': 'PRINT 1' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\PROJECT\\\\X.BAS')");
  });

  t.test('a ../ project name cannot escape C:\\SHARED', async (p) => {
    const c = await packCode(p, { name: '../../MYPROGS' }, { 'HELLO.BAS': 'PRINT "PWNED"' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\MYPROGS\\\\HELLO.BAS')");
    p.assert.doesNotMatch(await read(p, 'C:\\MYPROGS\\HELLO.BAS'), /PWNED/);
  });

  t.test('more than 12 files are listed as the first 12 then …', async (p) => {
    const files = {};
    for (let i = 1; i <= 15; i++) files['F' + String(i).padStart(2, '0') + '.TXT'] = 'x' + i;
    const c = await packCode(p, { name: 'MANY' }, files);
    await loadWithCode(p, c);
    const txt = await p.modalText();
    p.assert.match(txt, /contains 15 file\(s\)/);
    p.assert.ok(txt.includes('F12.TXT'));
    p.assert.ok(!txt.includes('F13.TXT'));
    p.assert.ok(txt.includes('…'));
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\MANY\\\\F15.TXT')");
  });

  t.test('file names are shown escaped (not as HTML) in the confirmation', async (p) => {
    const c = await packCode(p, { name: 'ESC' }, { '<b>BOLD</b>.TXT': 'x' });
    await loadWithCode(p, c);
    p.assert.ok((await p.modalText()).includes('<b>BOLD</b>.TXT'));
    p.assert.equal(await p.count('.modal-back:last-child .modal-body b'), 0);
    await p.modalButton('Cancel');
  });

  t.test('an invalid code in the page hash shows an "Import failed" alert', async (p) => {
    await p.fresh({ hash: 'share=CPD1.zNOTREALLYDEFLATE' });
    await expectAlert(p, /.+/);
    p.assert.equal(await p.ev('location.hash'), '');
    p.assert.equal(await exists(p, 'C:\\SHARED'), false);
  }, { allowExceptions: true });

  // ---- Import Shared Code dialog ----------------------------------------------------------
  t.test('File ▸ Import Shared Code opens a dialog with a code textarea', async (p) => {
    await p.fresh();
    await p.menu('File', 'Import Shared Code…');
    p.assert.equal(await p.waitModal(), 'Import Shared Project');
    p.assert.match(await p.attr('.modal-back:last-child textarea', 'placeholder'), /share code \(CPD1\.…\) or a full share link/);
    p.assert.deepEqual(await p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map(b => b.innerText)"), ['Cancel', 'Import']);
    await p.modalButton('Cancel');
  });

  t.test('pasting a code imports the project', async (p) => {
    const c = await packCode(p, { name: 'PASTED', main: 'MAIN.BAS' }, FILES);
    await importViaDialog(p, c);
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\PASTED\\\\LIB\\\\HELP.BAS')");
    p.assert.equal(await p.activePath(), 'C:\\SHARED\\PASTED\\MAIN.BAS');
  });

  t.test('pasting a full share link imports the project', async (p) => {
    const c = await packCode(p, { name: 'LINKED' }, { 'L.BAS': 'PRINT "L"' });
    await importViaDialog(p, 'https://example.com/baysik/index.html#share=' + c);
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\LINKED\\\\L.BAS')");
    p.assert.equal(await read(p, 'C:\\SHARED\\LINKED\\L.BAS'), 'PRINT "L"');
  });

  t.test('a pasted code with surrounding whitespace and newlines still imports', async (p) => {
    const c = await packCode(p, { name: 'SPACED' }, { 'S.BAS': 'PRINT "S"' });
    await importViaDialog(p, '\n   ' + c + '  \n\n');
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\SPACED\\\\S.BAS')");
  });

  t.test('uncompressed (CPD1.r) codes are accepted', async (p) => {
    const c = rawCode({ v: 1, meta: { name: 'RAW' }, files: { 'R.BAS': b64u('PRINT "RAW"') } });
    await importViaDialog(p, c);
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\RAW\\\\R.BAS')");
    p.assert.equal(await read(p, 'C:\\SHARED\\RAW\\R.BAS'), 'PRINT "RAW"');
  });

  t.test('Cancel in the Import dialog does nothing', async (p) => {
    await p.menu('File', 'Import Shared Code…');
    await p.waitModal();
    await p.modalInput('garbage');
    await p.modalButton('Cancel');
    await p.sleep(200);
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('Import with an empty textarea does nothing', async (p) => {
    await importViaDialog(p, '');
    await p.sleep(200);
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('text that is not a share code is rejected with an alert', async (p) => {
    await importViaDialog(p, 'hello world');
    await expectAlert(p, /This does not look like a Baysik share code\./);
  });

  t.test('a link without a share code is rejected', async (p) => {
    await importViaDialog(p, 'https://example.com/#nothing=here');
    await expectAlert(p, /does not look like a Baysik share code/);
  });

  t.test('a corrupt compressed code is rejected with an alert', async (p) => {
    await importViaDialog(p, 'CPD1.zAAAAAAAAAAAAAAAAAAAAAAA');
    await expectAlert(p, /.+/);
    p.assert.equal(await p.modalOpen(), false);
  }, { allowExceptions: true });

  t.test('a truncated real code is rejected with an alert', async (p) => {
    const c = await packCode(p, { name: 'TRUNC' }, FILES);
    await importViaDialog(p, c.slice(0, Math.floor(c.length / 2)));
    await expectAlert(p, /.+/);
    p.assert.equal(await exists(p, 'C:\\SHARED\\TRUNC'), false);
  }, { allowExceptions: true });

  t.test('a code whose payload is not JSON is rejected', async (p) => {
    await importViaDialog(p, 'CPD1.r' + b64u('this is not json'));
    await expectAlert(p, /JSON|Unexpected/i);
  });

  t.test('an unknown share code version is rejected', async (p) => {
    await importViaDialog(p, rawCode({ v: 2, meta: {}, files: { 'A.BAS': b64u('x') } }));
    await expectAlert(p, /Unsupported share code version\./);
  });

  t.test('a code without files is rejected', async (p) => {
    await importViaDialog(p, rawCode({ v: 1, meta: { name: 'X' } }));
    await expectAlert(p, /Unsupported share code version\./);
  });

  for (const [label, bad] of [
    ['../ parent path', '../EVIL.BAS'],
    ['nested ../.. path', 'A/../../EVIL.BAS'],
    ['backslash ..\\ path', '..\\EVIL.BAS'],
    ['trailing .. segment', 'A/..'],
    ['drive-letter path', 'C:/AUTOEXEC.BAS'],
    ['absolute backslash path', '\\ROOT.BAS'],
  ]) {
    t.test(`path traversal is rejected: ${label}`, async (p) => {
      await importViaDialog(p, rawCode({ v: 1, meta: { name: 'EVIL' }, files: { 'OK.BAS': b64u('PRINT 1'), [bad]: b64u('PRINT "EVIL"') } }));
      await expectAlert(p, new RegExp('Unsafe path in share code: ' + bad.replace(/[.\\/]/g, '\\$&')));
      p.assert.equal(await exists(p, 'C:\\SHARED\\EVIL'), false);
      p.assert.equal(await exists(p, 'C:\\EVIL.BAS'), false);
      p.assert.equal(await exists(p, 'C:\\SHARED\\EVIL.BAS'), false);
    });
  }

  t.test('names that merely contain dots (A..B.BAS) are allowed', async (p) => {
    await importViaDialog(p, rawCode({ v: 1, meta: { name: 'DOTS' }, files: { 'A..B.BAS': b64u('PRINT "DOTS"') } }));
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\DOTS\\\\A..B.BAS')");
  });

  t.test('a leading / path stays inside the import folder', async (p) => {
    await importViaDialog(p, rawCode({ v: 1, meta: { name: 'LEAD' }, files: { '/TOP.TXT': b64u('top') } }));
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\LEAD\\\\TOP.TXT')");
    p.assert.equal(await exists(p, 'C:\\TOP.TXT'), false);
  });

  // ---- round trips ---------------------------------------------------------------------------------
  t.test('round trip: share a folder via Copy Link, open the link fresh, import identical files', async (p) => {
    await p.fresh();
    await makeFolder(p, 'C:\\TRIP', { 'START.BAS': 'PRINT "TRIP"\r\n', 'Sub/Data.txt': 'a,b,c\r\n' });
    await p.ev("RC.app.openFile('C:\\\\TRIP\\\\START.BAS')");
    await stubClipboard(p);
    await p.menu('File', 'Share Project as Link…');
    await p.waitModal();
    await p.modalButton('Copy Link');
    await p.wait('window.__clip.length === 1');
    const link = (await p.ev('window.__clip'))[0];
    const hash = link.slice(link.indexOf('#') + 1);
    p.assert.match(hash, /^share=CPD1\.z/);
    await p.fresh({ hash });
    p.assert.equal(await p.waitModal(), 'Open shared project?');
    p.assert.equal(await p.ev('location.hash'), '');
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\TRIP\\\\Sub\\\\Data.txt')");
    p.assert.equal(await read(p, 'C:\\SHARED\\TRIP\\START.BAS'), 'PRINT "TRIP"\r\n');
    p.assert.equal(await read(p, 'C:\\SHARED\\TRIP\\SUB\\DATA.TXT'), 'a,b,c\r\n');
    p.assert.deepEqual(await p.ev("RC.app.vfs.list('C:\\\\SHARED\\\\TRIP\\\\SUB').map(e => e.name)"), ['Data.txt']);
    p.assert.equal(await p.activePath(), 'C:\\SHARED\\TRIP\\START.BAS');
    p.assert.equal((await mains(p))['C:\\SHARED\\TRIP'], 'C:\\SHARED\\TRIP\\START.BAS');
  });

  t.test('round trip: the imported main program runs', async (p) => {
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /TRIP/);
  });

  t.test('round trip: binary bytes survive share → import exactly', async (p) => {
    await p.ev("RC.app.vfs.mkdir('C:\\\\BINTRIP'); RC.app.vfs.writeFile('C:\\\\BINTRIP\\\\ALL.DAT', Uint8Array.from({length: 256}, (_, i) => i), {trusted: true}); RC.app.renderExplorer()");
    await folderContext(p, 'BINTRIP');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    await p.waitModal();
    const c = await p.ev("document.querySelector('.modal-back:last-child textarea').value");
    await p.closeModals();
    await p.fresh({ hash: 'share=' + c });
    await p.waitModal();
    await p.modalButton('Import');
    await p.wait("RC.app.vfs.exists('C:\\\\SHARED\\\\BINTRIP\\\\ALL.DAT')");
    p.assert.deepEqual(await p.ev("Array.from(RC.app.vfs.readFile('C:\\\\SHARED\\\\BINTRIP\\\\ALL.DAT'))"), Array.from({ length: 256 }, (_, i) => i));
  });

  t.test('round trip: a main program in a subfolder is opened and set as that folder main', async (p) => {
    const c = await packCode(p, { name: 'DEEP', main: 'SRC/GO.BAS' }, { 'SRC/GO.BAS': 'PRINT "GO"', 'README.TXT': 'r' });
    await loadWithCode(p, c);
    await p.modalButton('Import');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\SHARED\\\\DEEP\\\\SRC\\\\GO.BAS'");
    p.assert.equal((await mains(p))['C:\\SHARED\\DEEP\\SRC'], 'C:\\SHARED\\DEEP\\SRC\\GO.BAS');
  });

  t.test('imported files persist across a reload', async (p) => {
    await p.sleep(400);
    await p.reload();
    p.assert.equal(await read(p, 'C:\\SHARED\\DEEP\\SRC\\GO.BAS'), 'PRINT "GO"');
    p.assert.equal(await p.ev('location.hash'), '');
    p.assert.equal(await p.modalOpen(), false);
  });
};
