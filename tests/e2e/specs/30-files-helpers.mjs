// Shared helpers for the 30-files-* specs (explorer, virtual disk, saving, persistence).
// Not a spec file itself (no .spec.mjs suffix), so the runner never executes it directly.
import { mkdtempSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

/** All explorer rows with their full DOS path (computed from indentation). */
export function rows(p) {
  return p.ev(`(() => {
    const out = [];
    const stack = [];
    for (const el of document.querySelectorAll('#explorerTree .tree-item')) {
      const pad = parseInt(el.style.paddingLeft, 10) || 0;
      const isDir = el.hasAttribute('aria-expanded');
      const name = (el.querySelector('.nm') || {}).innerText || '';
      let depth, path;
      if (isDir) {
        depth = Math.round((pad - 6) / 12);
        path = depth === 0 ? name.slice(0, 2) + '\\\\' : stack[depth - 1].replace(/\\\\$/, '') + '\\\\' + name;
        stack[depth] = path; stack.length = depth + 1;
      } else {
        depth = Math.round((pad - 18) / 12);
        path = (el.getAttribute('title') || '').replace(/ \\(\\d+ bytes\\)$/, '');
      }
      out.push({ name, path, depth, isDir, pad, expanded: isDir ? el.getAttribute('aria-expanded') === 'true' : null,
        selected: el.classList.contains('selected'), main: el.classList.contains('main'),
        badge: (el.querySelector('.badge') || {}).innerText || '', tw: (el.querySelector('.tw') || {}).innerText || '',
        title: el.getAttribute('title') || '' });
    }
    return out;
  })()`);
}
export async function row(p, path) {
  const r = await rows(p);
  return r.find((x) => x.path.toUpperCase() === path.toUpperCase()) || null;
}
export async function rowPaths(p) { return (await rows(p)).map((x) => x.path); }

/** Wait until the explorer shows (or no longer shows) a row for path. */
export async function waitRow(p, path, present = true, ms = 4000) {
  const t0 = Date.now();
  for (;;) {
    const r = await row(p, path);
    if (!!r === present) return r;
    if (Date.now() - t0 > ms) throw new Error(`explorer row ${path} ${present ? 'did not appear' : 'did not disappear'}`);
    await p.sleep(50);
  }
}

async function rowCenter(p, path) {
  const all = await rows(p);
  const i = all.findIndex((x) => x.path.toUpperCase() === path.toUpperCase());
  if (i < 0) throw new Error('no explorer row for ' + path + '; rows: ' + all.map((x) => x.path).join(', '));
  return p.ev(`(() => { const e = document.querySelectorAll('#explorerTree .tree-item')[${i}]; e.scrollIntoView({ block: 'nearest' }); const r = e.getBoundingClientRect(); return [r.left + Math.min(60, r.width / 2), r.top + r.height / 2]; })()`);
}
export async function clickRow(p, path) { const [x, y] = await rowCenter(p, path); await p.clickAt(x, y); await p.sleep(40); }
export async function dblclickRow(p, path) { const [x, y] = await rowCenter(p, path); await p.clickAt(x, y, { double: true }); await p.sleep(40); }
export async function rightClickRow(p, path) {
  const [x, y] = await rowCenter(p, path);
  await p.clickAt(x, y, { button: 'right' });
  await p.wait("!!document.querySelector('.menu-pop')", 2000);
}
/** Labels of the open context menu (separators excluded). */
export function menuLabels(p) { return p.ev("[...document.querySelectorAll('.menu-pop .menu-item')].map(e => e.children[0].innerText)"); }
export async function clickMenuItem(p, label) {
  const xy = await p.ev(`(() => { const e = [...document.querySelectorAll('.menu-pop .menu-item')].find(e => e.children[0].innerText === ${JSON.stringify(label)}); if (!e) return null; const r = e.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; })()`);
  if (!xy) throw new Error('menu item not found: ' + label + ' in ' + JSON.stringify(await menuLabels(p)));
  await p.clickAt(xy[0], xy[1]);
  await p.sleep(60);
}
/** Expand a folder row by clicking it (only if it is collapsed). */
export async function expand(p, path) {
  const r = await row(p, path);
  if (r && !r.expanded) await clickRow(p, path);
}
/** Right-click a row and choose a context menu item. */
export async function ctx(p, path, label) { await rightClickRow(p, path); await clickMenuItem(p, label); }

/** Click an explorer header button by its title. */
export async function headerBtn(p, title) {
  await p.click(`#explorerActions button[title=${JSON.stringify(title)}]`);
  await p.sleep(60);
}

/** Close any open menus and dialogs the proper way (Escape resolves the dialog promise). */
export async function cleanup(p) {
  await p.closeMenus();
  for (let i = 0; i < 6 && await p.modalOpen(); i++) { await p.key('Escape'); await p.sleep(60); }
  if (await p.modalOpen()) await p.closeModals();
}

/** Answer the current prompt dialog: set the text and press OK. */
export async function answerPrompt(p, value, title) {
  const t = await p.waitModal();
  if (title) p.assert.equal(t, title);
  await p.modalInput(value);
  await p.modalButton('OK');
  await p.sleep(80);
}
/** Click a dialog button whose label matches exactly (p.modalButton matches substrings: "Save" would hit "Don't Save"). */
export async function button(p, label) {
  const xy = await p.ev(`(() => { const b = [...document.querySelectorAll('.modal-back:last-child .modal-foot button')].find(x => x.innerText.trim() === ${JSON.stringify(label)}); if (!b) return null; const r = b.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; })()`);
  if (!xy) throw new Error('dialog button not found: ' + label);
  await p.clickAt(xy[0], xy[1]);
  await p.sleep(100);
}
export function modalInputValue(p) { return p.ev("(document.querySelector('.modal-back:last-child .modal input[type=text]') || {}).value"); }
export function modalButtons(p) { return p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map(b => b.innerText)"); }

// ---- virtual disk access -----------------------------------------------------------------------------
export const exists = (p, path) => p.fn((x) => RC.app.vfs.exists(x), path);
export const isDir = (p, path) => p.fn((x) => { const s = RC.app.vfs.stat(x); return !!s && s.type === 'dir'; }, path);
/** Raw bytes of a file as a JS array */
export const bytes = (p, path) => p.fn((x) => Array.from(RC.app.vfs.readFile(x)), path);
/** File content as decoded by the IDE (CP437/UTF-8 → Unicode, CRLF → LF) */
export const readText = (p, path) => p.fn((x) => RC.app.decodeText(RC.app.vfs.readFile(x)), path);
/** Raw byte string (no decoding) */
export const rawText = (p, path) => p.fn((x) => RC.bytesToStr(RC.app.vfs.readFile(x)), path);
export const writeRaw = (p, path, text) => p.fn((x, t) => {
  const v = RC.app.vfs; const parts = x.split('\\'); let cur = parts[0];
  for (let i = 1; i < parts.length - 1; i++) { cur += '\\' + parts[i]; if (!v.exists(cur)) v.mkdir(cur); }
  v.writeFile(x, RC.strToBytes(t), { trusted: true });
}, path, text);
export const mkdirs = (p, path) => p.fn((x) => {
  const v = RC.app.vfs; const parts = x.split('\\'); let cur = parts[0];
  for (let i = 1; i < parts.length; i++) { cur += '\\' + parts[i]; if (!v.exists(cur)) v.mkdir(cur); }
}, path);
export const tabs = (p) => p.ev("RC.app.docs.map(d => d.path)");
export const tabNames = (p) => p.ev("[...document.querySelectorAll('#editorTabs .tab')].map(t => t.innerText.replace(/×/g, '').replace(/◇/g, '').trim())");
export const isDirty = (p, path) => p.fn((x) => { const d = RC.app.docByPath(x); return d ? d.dirty : null; }, path || null).then((v) => v);
export const activeDirty = (p) => p.ev('RC.app.active ? RC.app.active.dirty : null');
/** Make the active doc dirty by appending text through the editor. */
export async function editActive(p, extra = "\nPRINT \"EDITED\"") {
  // place the caret like a user would (setCursor keeps the editor's line tracking in sync), then type
  await p.ev(`(() => { const e = RC.app.active.editor; const n = e.lineCount() - 1; e.setCursor(n, e.getLine(n).length); e.insert(${JSON.stringify(extra)}); })()`);
  await p.sleep(60);
}
/** Wait for the IndexedDB flush (250ms debounce) to complete */
export async function flush(p) { await p.sleep(450); }
/** Read everything stored in IndexedDB as {KEY: text|'<dir>'} */
export const idbDump = (p) => p.ev(`new Promise((res) => { const rq = indexedDB.open('baysik-vfs', 1); rq.onsuccess = () => { const db = rq.result; const out = {}; const tx = db.transaction('entries', 'readonly'); const c = tx.objectStore('entries').openCursor(); c.onsuccess = () => { const cur = c.result; if (!cur) { db.close(); res(out); return; } out[cur.key] = cur.value.type === 'dir' ? '<dir>' : RC.bytesToStr(new Uint8Array(cur.value.data)); cur.continue(); }; }; rq.onerror = () => res(null); })`);

// ---- downloads ---------------------------------------------------------------------------------------------
/** Intercept downloads (anchor clicks with a download attribute) and keep their Blobs in window.__dl */
export async function armDownloads(p) {
  await p.ev(`(() => {
    window.__dl = [];
    if (window.__dlArmed) return;
    window.__dlArmed = true;
    window.__blobs = new Map();
    const orig = URL.createObjectURL.bind(URL);
    URL.createObjectURL = (b) => { const u = orig(b); window.__blobs.set(u, b); return u; };
    const click = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = function () {
      if (this.hasAttribute('download')) { window.__dl.push({ name: this.getAttribute('download'), blob: window.__blobs.get(this.href) }); return; }
      return click.call(this);
    };
  })()`);
}
/** Captured downloads: [{name, type, bytes: number[]}] */
export function downloads(p) {
  return p.ev(`Promise.all((window.__dl || []).map(async (d) => ({ name: d.name, type: d.blob ? d.blob.type : null, bytes: d.blob ? Array.from(new Uint8Array(await d.blob.arrayBuffer())) : null })))`);
}
export async function waitDownload(p, n = 1, ms = 3000) { await p.wait(`(window.__dl || []).length >= ${n}`, ms); return downloads(p); }

const CRC = new Uint32Array(256);
for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; CRC[n] = c >>> 0; }
export function crc32(b) { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = CRC[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }

/** Parse a ZIP via its central directory → {entries: [{name, crc, size, data, crcOk}], count} */
export function parseZip(arr) {
  const b = Buffer.from(arr);
  let eocd = -1;
  for (let i = b.length - 22; i >= 0; i--) if (b.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  if (eocd < 0) throw new Error('no end-of-central-directory record');
  const count = b.readUInt16LE(eocd + 10);
  const cdSize = b.readUInt32LE(eocd + 12);
  const cdOff = b.readUInt32LE(eocd + 16);
  const entries = [];
  let o = cdOff;
  for (let i = 0; i < count; i++) {
    if (b.readUInt32LE(o) !== 0x02014b50) throw new Error('bad central directory signature at ' + o);
    const method = b.readUInt16LE(o + 10);
    const crc = b.readUInt32LE(o + 16);
    const csize = b.readUInt32LE(o + 20);
    const size = b.readUInt32LE(o + 24);
    const nlen = b.readUInt16LE(o + 28), xlen = b.readUInt16LE(o + 30), clen = b.readUInt16LE(o + 32);
    const lho = b.readUInt32LE(o + 42);
    const name = b.slice(o + 46, o + 46 + nlen).toString('utf8');
    if (b.readUInt32LE(lho) !== 0x04034b50) throw new Error('bad local header for ' + name);
    const lnl = b.readUInt16LE(lho + 26), lxl = b.readUInt16LE(lho + 28);
    const data = b.slice(lho + 30 + lnl + lxl, lho + 30 + lnl + lxl + csize);
    entries.push({ name, crc, size, csize, method, data, crcOk: crc32(data) === crc });
    o += 46 + nlen + xlen + clen;
  }
  return { count, cdSize, cdOff, entries, eocd };
}

// ---- file input (imports) --------------------------------------------------------------------------------
/** Stop file inputs from opening a native chooser; remember them in window.__fileInputs instead. */
export async function armFileInput(p) {
  await p.ev(`(() => {
    window.__fileInputs = [];
    if (window.__fiArmed) return;
    window.__fiArmed = true;
    const click = HTMLInputElement.prototype.click;
    HTMLInputElement.prototype.click = function () { if (this.type === 'file') { window.__fileInputs.push(this); return; } return click.call(this); };
  })()`);
}
/**
 * Feed real files (written to a temp folder) into the most recent file input via CDP DOM.setFileInputFiles.
 * files: [{name, text?|bytes?}] (text is written as UTF-8)
 */
export async function feedFiles(p, files) {
  await p.wait('(window.__fileInputs || []).length > 0', 3000);
  const dir = mkdtempSync(join(tmpdir(), 'baysik-imp-'));
  const paths = files.map((f) => {
    const fp = join(dir, f.name);
    writeFileSync(fp, f.bytes ? Buffer.from(f.bytes) : Buffer.from(f.text || '', 'utf8'));
    return fp;
  });
  const r = await p.b.send('Runtime.evaluate', { expression: 'window.__fileInputs[window.__fileInputs.length - 1]', returnByValue: false });
  await p.b.send('DOM.setFileInputFiles', { files: paths, objectId: r.result.objectId });
  await p.sleep(250);
}

// ---- clipboard ------------------------------------------------------------------------------------------------
export async function armClipboard(p) {
  await p.ev("window.__clip = null; navigator.clipboard.writeText = async (t) => { window.__clip = t; }");
}

// ---- fake mounted folder (File System Access API) ---------------------------------------------------------------
/** Install a fake window.showDirectoryPicker that returns an in-memory folder; writes land in window.__hostWrites */
export async function fakePicker(p, name, files) {
  await p.fn((name, files) => {
    window.__hostWrites = {};
    const mkFile = (n, text, path) => ({
      kind: 'file', name: n,
      async getFile() { return new File([text], n, { lastModified: 1 }); },
      async createWritable() { const chunks = []; return { async write(d) { chunks.push(d); }, async close() { window.__hostWrites[path] = RC.bytesToStr(chunks[0] instanceof Uint8Array ? chunks[0] : new Uint8Array(0)); } }; },
    });
    const mkDir = (n, tree, path) => {
      const kids = Object.entries(tree).map(([k, v]) => (typeof v === 'string' ? mkFile(k, v, path + '/' + k) : mkDir(k, v, path + '/' + k)));
      return {
        kind: 'directory', name: n,
        async *entries() { for (const c of kids) yield [c.name, c]; },
        async getDirectoryHandle(x) { return kids.find((c) => c.name === x) || mkDir(x, {}, path + '/' + x); },
        async getFileHandle(x) { let f = kids.find((c) => c.name === x); if (!f) { f = mkFile(x, '', path + '/' + x); kids.push(f); } return f; },
        async removeEntry(x) { window.__hostWrites[path + '/' + x] = null; },
      };
    };
    window.showDirectoryPicker = async () => mkDir(name, files, '');
  }, name, files);
}

// ---- unload safety ------------------------------------------------------------------------------------------------
/** Mark every open document clean so a following reload/navigation is not blocked by the beforeunload prompt. */
export async function defuse(p) {
  // Also stop the session from being re-saved during unload: under load the unload can land after the runner
  // has cleared storage for the next fresh test, which would leak this test's open tabs into it.
  await p.ev(`(() => { if (!(window.RC && RC.app && RC.app.docs)) return; RC.app.docs.forEach(d => { d.dirty = false; });
    RC.app.saveSession = () => {}; if (RC.app.vfs.flushNow) RC.app.vfs.flushNow(); })()`).catch(() => {});
}
/**
 * Wraps the spec registry: tests are buffered and registered by register(). When a test fails (the runner then
 * reloads the page) or the next test starts fresh, dirty documents are defused first, because the IDE's
 * beforeunload prompt for unsaved work would otherwise block the navigation forever in headless Chrome.
 */
export function safe(t) {
  const list = [];
  return {
    beforeEach: (f) => t.beforeEach(f),
    afterEach: (f) => t.afterEach(f),
    test: (name, fn, opts) => { list.push({ name, fn, opts }); },
    register() {
      list.forEach((x, i) => {
        const nextFresh = i + 1 < list.length && !!(list[i + 1].opts && list[i + 1].opts.fresh);
        t.test(x.name, async (p) => {
          let ok = false;
          try { await x.fn(p); ok = true; } finally { if (!ok || nextFresh) await defuse(p); }
        }, x.opts);
      });
    },
  };
}
