// Sharing: the Share Project dialog (File menu, explorer button, folder context menu) and .zip downloads.
import { stubClipboard, captureDownloads, downloads, parseZip, crc32, makeFolder, expand, folderContext } from './90-share-lib.mjs';

const PROJ = { 'MAIN.BAS': 'PRINT "MAIN PROGRAM"\r\n', 'UTIL.BAS': 'SUB Hello\r\nPRINT "HI"\r\nEND SUB\r\n', 'DATA/SCORES.TXT': '100,200,300\r\n' };

async function shareDialogInfo(p) {
  await p.wait("!!document.querySelector('.modal-back:last-child input[aria-label=\"Share link\"]')", 5000);
  await p.sleep(40);
  return p.ev(`(() => {
    const m = document.querySelector('.modal-back:last-child');
    const link = m.querySelector('input[aria-label="Share link"]');
    const ta = m.querySelector('textarea[aria-label="Share code"]');
    return { title: m.querySelector('.modal-head').innerText, text: m.querySelector('.modal-body').innerText, link: link.value, code: ta.value,
      linkRO: link.readOnly, codeRO: ta.readOnly, buttons: [...m.querySelectorAll('.modal-foot button')].map(b => b.innerText + (b.classList.contains('primary') ? '*' : '')),
      longNote: [...m.querySelectorAll('p.muted')].some(x => /link is long/.test(x.innerText)) };
  })()`);
}
const unpack = (p, code) => p.fn(async (code) => {
  const r = await RC.Share.unpack(code);
  const files = {};
  for (const [k, v] of Object.entries(r.files)) files[k] = RC.bytesToStr(v);
  return { meta: r.meta, files };
}, code);
const base = (p) => p.ev("location.href.replace(/#.*$/, '')");
const zipText = (e) => Buffer.from(e.data).toString('latin1');

async function setup(p) {
  await p.fn(() => { localStorage.removeItem('baysik.mains'); });
  await makeFolder(p, 'C:\\PROJ', PROJ);
  await p.ev("RC.app.openFile('C:\\\\PROJ\\\\MAIN.BAS')");
  await expand(p, 'C:\\PROJ\\DATA');
  await stubClipboard(p);
  await captureDownloads(p);
}

export default (t) => {
  t.beforeEach(async (p) => { await p.closeModals(); await p.closeMenus(); await setup(p); });

  t.test('File menu lists Share, Import Shared Code and Download Project (.zip), all enabled', async (p) => {
    await p.click('.menu-btn', 'File');
    const items = await p.menuItems();
    for (const l of ['Share Project as Link…', 'Import Shared Code…', 'Download Project (.zip)']) {
      const it = items.find((x) => x.label === l);
      p.assert.ok(it, l);
      p.assert.equal(it.disabled, false);
    }
    await p.closeMenus();
  });

  t.test('File ▸ Share Project as Link opens the Share Project dialog', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.equal(info.title, 'Share Project');
  });

  t.test('share dialog reports the file count and folder of the active program', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.match(info.text, /Sharing 3 file\(s\) from C:\\PROJ/);
    p.assert.match(info.text, /nothing is uploaded anywhere/);
  });

  t.test('share dialog shows the encoded size in KB of the code', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.ok(info.text.includes('(' + (info.code.length / 1024).toFixed(1) + ' KB encoded)'), info.text);
  });

  t.test('link field is the page URL plus #share=<code>', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.equal(info.link, (await base(p)) + '#share=' + info.code);
  });

  t.test('link and code fields are read-only', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.equal(info.linkRO, true);
    p.assert.equal(info.codeRO, true);
  });

  t.test('share code is a compressed, URL-safe CPD1.z code', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.match(info.code, /^CPD1\.z[A-Za-z0-9_-]+$/);
  });

  t.test('share code decodes to the folder files with exact contents', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    const r = await unpack(p, info.code);
    p.assert.deepEqual(Object.keys(r.files).sort(), ['DATA/SCORES.TXT', 'MAIN.BAS', 'UTIL.BAS']);
    for (const [k, v] of Object.entries(PROJ)) p.assert.equal(r.files[k], v);
  });

  t.test('share metadata names the folder, the main program and the language', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    p.assert.deepEqual(r.meta, { name: 'PROJ', main: 'MAIN.BAS', lang: 'basic' });
  });

  t.test('share dialog buttons are Close, Copy Code and Copy Link (primary)', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    p.assert.deepEqual((await shareDialogInfo(p)).buttons, ['Close', 'Copy Code', 'Copy Link*']);
  });

  t.test('Copy Link copies the full link to the clipboard and confirms', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    await p.modalButton('Copy Link');
    await p.waitToast(/Copied to clipboard/);
    p.assert.deepEqual(await p.ev('window.__clip'), [info.link]);
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('Copy Code copies only the code to the clipboard', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    await p.modalButton('Copy Code');
    await p.waitToast(/Copied to clipboard/);
    p.assert.deepEqual(await p.ev('window.__clip'), [info.code]);
  });

  t.test('Close button closes the share dialog without copying', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    await shareDialogInfo(p);
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.deepEqual(await p.ev('window.__clip'), []);
  });

  t.test('Escape closes the share dialog without copying', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    await shareDialogInfo(p);
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.deepEqual(await p.ev('window.__clip'), []);
  });

  t.test('a failing clipboard shows a "Copy failed" toast', async (p) => {
    await stubClipboard(p, true);
    await p.menu('File', 'Share Project as Link…');
    await shareDialogInfo(p);
    await p.modalButton('Copy Link');
    await p.waitToast(/Copy failed; select the text and copy it manually/);
  });

  t.test('explorer Share button shares the active program folder', async (p) => {
    await p.click('#explorerActions button[title="Share project"]');
    const info = await shareDialogInfo(p);
    p.assert.match(info.text, /Sharing 3 file\(s\) from C:\\PROJ/);
  });

  t.test('folder context menu offers Share This Folder and Download Folder (.zip)', async (p) => {
    await folderContext(p, 'PROJ');
    const labels = (await p.menuItems()).map((x) => x.label);
    p.assert.ok(labels.includes('Share This Folder as Link…'));
    p.assert.ok(labels.includes('Download Folder (.zip)'));
    await p.closeMenus();
  });

  t.test('folder context menu shares just that subfolder', async (p) => {
    await folderContext(p, 'DATA');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const info = await shareDialogInfo(p);
    p.assert.match(info.text, /Sharing 1 file\(s\) from C:\\PROJ\\DATA/);
    const r = await unpack(p, info.code);
    p.assert.deepEqual(Object.keys(r.files), ['SCORES.TXT']);
    p.assert.equal(r.meta.name, 'DATA');
    p.assert.equal(r.meta.main, null);
  });

  t.test('sharing the C: drive root includes every file on the disk', async (p) => {
    await folderContext(p, 'C: (virtual disk)');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const info = await shareDialogInfo(p);
    const n = await p.ev("RC.app.vfs.walk('C:\\\\').filter(x => x.entry.type === 'file').length");
    p.assert.ok(info.text.includes(`Sharing ${n} file(s)`), info.text);
    const r = await unpack(p, info.code);
    p.assert.equal(Object.keys(r.files).length, n);
    p.assert.ok(r.files['PROJ/MAIN.BAS']);
  });

  t.test('unsaved editor changes are saved and included in the share', async (p) => {
    await p.setCode('PRINT "EDITED"');
    await p.menu('File', 'Share Project as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    p.assert.match(r.files['MAIN.BAS'], /PRINT "EDITED"/);
    p.assert.match(await p.ev("RC.app.vfs.readText('C:\\\\PROJ\\\\MAIN.BAS')"), /EDITED/);
  });

  t.test('a folder main program is shared as main even when another file is active', async (p) => {
    await p.ev("RC.app.setMain('C:\\\\PROJ\\\\MAIN.BAS'); RC.app.openFile('C:\\\\PROJ\\\\UTIL.BAS')");
    await p.menu('File', 'Share Project as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    p.assert.equal(r.meta.main, 'MAIN.BAS');
  });

  t.test('without a folder main, the active program is shared as main', async (p) => {
    await p.ev("RC.app.openFile('C:\\\\PROJ\\\\UTIL.BAS')");
    await p.menu('File', 'Share Project as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    p.assert.equal(r.meta.main, 'UTIL.BAS');
  });

  t.test('an active program in a subfolder is shared as main with a / path', async (p) => {
    await makeFolder(p, 'C:\\PROJ\\LIB', { 'X.BAS': 'PRINT 1' });
    await p.ev("RC.app.openFile('C:\\\\PROJ\\\\LIB\\\\X.BAS')");
    await folderContext(p, 'PROJ');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    p.assert.equal(r.meta.main, 'LIB/X.BAS');
    p.assert.ok(r.files['LIB/X.BAS']);
    await p.ev("RC.app.closeDoc(RC.app.docByPath('C:\\\\PROJ\\\\LIB\\\\X.BAS')); RC.app.vfs.unlink('C:\\\\PROJ\\\\LIB\\\\X.BAS'); RC.app.vfs.rmdir('C:\\\\PROJ\\\\LIB')");
  });

  t.test('sharing a folder whose name prefixes the active file folder does not mis-detect main', async (p) => {
    await makeFolder(p, 'C:\\PROJ2', { 'OTHER.BAS': 'PRINT 2' });
    await p.ev("RC.app.openFile('C:\\\\PROJ2\\\\OTHER.BAS')");
    await folderContext(p, 'PROJ');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    // C:\PROJ2\OTHER.BAS is not inside C:\PROJ, so it must not become the shared main
    p.assert.equal(r.meta.main, null);
  });

  t.test('sharing an empty folder shows "That folder is empty" and no dialog', async (p) => {
    await p.ev("if (!RC.app.vfs.exists('C:\\\\EMPTY')) RC.app.vfs.mkdir('C:\\\\EMPTY'); RC.app.renderExplorer()");
    await folderContext(p, 'EMPTY');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    await p.waitToast(/That folder is empty/);
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('a folder containing only empty subfolders counts as empty', async (p) => {
    await p.ev("if (!RC.app.vfs.exists('C:\\\\EMPTY2')) { RC.app.vfs.mkdir('C:\\\\EMPTY2'); RC.app.vfs.mkdir('C:\\\\EMPTY2\\\\SUB'); } RC.app.renderExplorer()");
    await folderContext(p, 'EMPTY2');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    await p.waitToast(/That folder is empty/);
    p.assert.equal(await p.modalOpen(), false);
  });

  t.test('a folder over 2 MB is refused with a size-limit message', async (p) => {
    await p.ev("RC.app.vfs.mkdir('C:\\\\BIG'); RC.app.vfs.writeFile('C:\\\\BIG\\\\HUGE.DAT', new Uint8Array(2 * 1024 * 1024 + 1), {trusted: true}); RC.app.renderExplorer()");
    await folderContext(p, 'BIG');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    await p.waitToast(/too large to share as a link \(2 MB max\)\. Use Download Project instead/);
    p.assert.equal(await p.modalOpen(), false);
    await p.ev("RC.app.vfs.unlink('C:\\\\BIG\\\\HUGE.DAT'); RC.app.vfs.rmdir('C:\\\\BIG')");
  });

  t.test('a folder of exactly 2 MB is still shareable', async (p) => {
    await p.ev("RC.app.vfs.mkdir('C:\\\\BIG'); RC.app.vfs.writeFile('C:\\\\BIG\\\\HUGE.DAT', new Uint8Array(2 * 1024 * 1024), {trusted: true}); RC.app.renderExplorer()");
    await folderContext(p, 'BIG');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const info = await shareDialogInfo(p);
    p.assert.match(info.text, /Sharing 1 file\(s\) from C:\\BIG/);
    await p.closeModals();
    await p.ev("RC.app.vfs.unlink('C:\\\\BIG\\\\HUGE.DAT'); RC.app.vfs.rmdir('C:\\\\BIG')");
  });

  t.test('a long link (over 8000 chars) shows the "link is long" note', async (p) => {
    await p.ev(`(() => { RC.app.vfs.mkdir('C:\\\\RND'); const b = new Uint8Array(9000); let x = 12345; for (let i = 0; i < b.length; i++) { x = (x * 1103515245 + 12345) >>> 0; b[i] = x >>> 24; } RC.app.vfs.writeFile('C:\\\\RND\\\\NOISE.DAT', b, {trusted: true}); RC.app.renderExplorer(); })()`);
    await folderContext(p, 'RND');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const info = await shareDialogInfo(p);
    p.assert.ok(info.link.length > 8000);
    p.assert.equal(info.longNote, true);
    await p.closeModals();
    await p.ev("RC.app.vfs.unlink('C:\\\\RND\\\\NOISE.DAT'); RC.app.vfs.rmdir('C:\\\\RND')");
  });

  t.test('a short link does not show the "link is long" note', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const info = await shareDialogInfo(p);
    p.assert.ok(info.link.length < 8000);
    p.assert.equal(info.longNote, false);
  });

  t.test('original file-name case is preserved in the share', async (p) => {
    await makeFolder(p, 'C:\\CASE', { 'MixedCase.bas': 'PRINT 3', 'sub/Lower.txt': 'x' });
    await folderContext(p, 'CASE');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const r = await unpack(p, (await shareDialogInfo(p)).code);
    p.assert.deepEqual(Object.keys(r.files).sort(), ['MixedCase.bas', 'sub/Lower.txt']);
  });

  t.test('binary file bytes survive packing exactly', async (p) => {
    await p.ev("RC.app.vfs.mkdir('C:\\\\BIN'); RC.app.vfs.writeFile('C:\\\\BIN\\\\ALL.DAT', Uint8Array.from({length: 256}, (_, i) => i), {trusted: true}); RC.app.renderExplorer()");
    await folderContext(p, 'BIN');
    await p.click('.menu-pop .menu-item', 'Share This Folder as Link…');
    const code = (await shareDialogInfo(p)).code;
    const bytes = await p.fn(async (c) => Array.from((await RC.Share.unpack(c)).files['ALL.DAT']), code);
    p.assert.deepEqual(bytes, Array.from({ length: 256 }, (_, i) => i));
  });

  t.test('sharing the same folder twice gives the same code', async (p) => {
    await p.menu('File', 'Share Project as Link…');
    const a = (await shareDialogInfo(p)).code;
    await p.closeModals();
    await p.menu('File', 'Share Project as Link…');
    const b = (await shareDialogInfo(p)).code;
    p.assert.equal(a, b);
  });

  // ---- zip downloads -----------------------------------------------------------------------
  t.test('File ▸ Download Project (.zip) downloads FOLDER.zip as application/zip', async (p) => {
    await p.menu('File', 'Download Project (.zip)');
    const d = await downloads(p);
    p.assert.equal(d.length, 1);
    p.assert.equal(d[0].name, 'PROJ.zip');
    p.assert.equal(d[0].type, 'application/zip');
  });

  t.test('zip central directory lists exactly the folder files with / separators', async (p) => {
    await p.menu('File', 'Download Project (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    p.assert.equal(z.count, 3);
    p.assert.deepEqual(z.entries.map((e) => e.name).sort(), ['DATA/SCORES.TXT', 'MAIN.BAS', 'UTIL.BAS']);
  });

  t.test('zip entry CRC-32 values match the stored data', async (p) => {
    await p.menu('File', 'Download Project (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    for (const e of z.entries) {
      p.assert.equal(e.crc, crc32(Uint8Array.from(e.data)), e.name);
      p.assert.equal(e.localCrc, e.crc, e.name);
    }
  });

  t.test('zip entries contain the exact file contents', async (p) => {
    await p.menu('File', 'Download Project (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    for (const e of z.entries) p.assert.equal(zipText(e), PROJ[e.name], e.name);
  });

  t.test('zip entries are stored uncompressed with UTF-8 names and matching sizes', async (p) => {
    await p.menu('File', 'Download Project (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    for (const e of z.entries) {
      p.assert.equal(e.method, 0);
      p.assert.equal(e.flags & 0x0800, 0x0800);
      p.assert.equal(e.size, e.csize);
      p.assert.equal(e.size, Buffer.byteLength(PROJ[e.name], 'latin1'));
      p.assert.equal(e.localName, e.name);
    }
  });

  t.test('zip end-of-central-directory record is consistent', async (p) => {
    await p.menu('File', 'Download Project (.zip)');
    const bytes = (await downloads(p))[0].bytes;
    const z = parseZip(bytes);
    p.assert.equal(z.cdEnd, z.eocd);
    p.assert.equal(z.cdEnd - z.cdOff, z.cdSize);
    p.assert.equal(z.eocd + 22, bytes.length);
  });

  t.test('folder context menu Download Folder (.zip) zips just that folder', async (p) => {
    await folderContext(p, 'DATA');
    await p.click('.menu-pop .menu-item', 'Download Folder (.zip)');
    const d = await downloads(p);
    p.assert.equal(d[0].name, 'DATA.zip');
    const z = parseZip(d[0].bytes);
    p.assert.deepEqual(z.entries.map((e) => e.name), ['SCORES.TXT']);
    p.assert.equal(zipText(z.entries[0]), PROJ['DATA/SCORES.TXT']);
  });

  t.test('zip of the C: drive root contains every file on the disk', async (p) => {
    await folderContext(p, 'C: (virtual disk)');
    await p.click('.menu-pop .menu-item', 'Download Folder (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    const n = await p.ev("RC.app.vfs.walk('C:\\\\').filter(x => x.entry.type === 'file').length");
    p.assert.equal(z.count, n);
    p.assert.ok(z.entries.some((e) => e.name === 'PROJ/MAIN.BAS'));
    p.assert.ok(z.entries.some((e) => e.name === 'MYPROGS/HELLO.BAS'));
  });

  t.test('zip of the C: drive root gets a valid file name (DISK.zip, no colon)', async (p) => {
    await folderContext(p, 'C: (virtual disk)');
    await p.click('.menu-pop .menu-item', 'Download Folder (.zip)');
    const d = await downloads(p);
    p.assert.equal(d[0].name, 'DISK.zip');
  });

  t.test('zip keeps binary file bytes exactly', async (p) => {
    await p.ev("if (!RC.app.vfs.exists('C:\\\\BIN')) RC.app.vfs.mkdir('C:\\\\BIN'); RC.app.vfs.writeFile('C:\\\\BIN\\\\ALL.DAT', Uint8Array.from({length: 256}, (_, i) => 255 - i), {trusted: true}); RC.app.renderExplorer()");
    await folderContext(p, 'BIN');
    await p.click('.menu-pop .menu-item', 'Download Folder (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    p.assert.deepEqual(z.entries[0].data, Array.from({ length: 256 }, (_, i) => 255 - i));
    p.assert.equal(z.entries[0].crc, crc32(Uint8Array.from({ length: 256 }, (_, i) => 255 - i)));
  });

  t.test('zip includes unsaved editor changes', async (p) => {
    await p.setCode('PRINT "ZIPPED EDIT"');
    await p.menu('File', 'Download Project (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    p.assert.match(zipText(z.entries.find((e) => e.name === 'MAIN.BAS')), /ZIPPED EDIT/);
  });

  t.test('zip of an empty folder is a valid empty archive', async (p) => {
    await p.ev("if (!RC.app.vfs.exists('C:\\\\EMPTY')) RC.app.vfs.mkdir('C:\\\\EMPTY'); RC.app.renderExplorer()");
    await folderContext(p, 'EMPTY');
    await p.click('.menu-pop .menu-item', 'Download Folder (.zip)');
    const d = await downloads(p);
    p.assert.equal(d[0].name, 'EMPTY.zip');
    const z = parseZip(d[0].bytes);
    p.assert.equal(z.count, 0);
    p.assert.equal(d[0].bytes.length, 22);
  });

  t.test('zip preserves original file-name case', async (p) => {
    await makeFolder(p, 'C:\\CASE', { 'MixedCase.bas': 'PRINT 3', 'sub/Lower.txt': 'x' });
    await folderContext(p, 'CASE');
    await p.click('.menu-pop .menu-item', 'Download Folder (.zip)');
    const z = parseZip((await downloads(p))[0].bytes);
    p.assert.deepEqual(z.entries.map((e) => e.name).sort(), ['MixedCase.bas', 'sub/Lower.txt']);
  });
};
