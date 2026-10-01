// Shared page-side helpers for the 90-share / 91-mount / 92-settings specs (not a spec itself).

/** Stub navigator.clipboard.writeText; captured text goes to window.__clip (array). */
export async function stubClipboard(p, fail = false) {
  await p.fn((fail) => {
    window.__clip = [];
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: (t) => (fail ? Promise.reject(new Error('denied')) : (window.__clip.push(t), Promise.resolve())) },
    });
  }, fail);
}

/** Capture downloads: blobs made by URL.createObjectURL and anchor clicks with a download attr. */
export async function captureDownloads(p) {
  await p.ev(`(() => {
    if (window.__dlHooked) { window.__downloads = []; return; }
    window.__dlHooked = true;
    window.__downloads = [];
    const blobs = new Map();
    const orig = URL.createObjectURL.bind(URL);
    URL.createObjectURL = (b) => { const u = orig(b); blobs.set(u, b); return u; };
    const click = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = function () {
      if (this.hasAttribute('download') && blobs.has(this.href)) {
        window.__downloads.push({ name: this.getAttribute('download'), blob: blobs.get(this.href) });
        return;
      }
      return click.call(this);
    };
  })()`);
}
/** Returns [{name, type, bytes: number[]}] of captured downloads */
export async function downloads(p) {
  await p.wait('window.__downloads && window.__downloads.length > 0', 4000);
  return p.ev(`Promise.all(window.__downloads.map(async (d) => ({ name: d.name, type: d.blob.type, bytes: Array.from(new Uint8Array(await d.blob.arrayBuffer())) })))`);
}

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; }
  return t;
})();
export function crc32(b) { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = CRC_TABLE[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }

/** Parse a stored ZIP via its central directory. Returns {count, entries:[{name, crc, size, csize, method, flags, data, localName, localCrc}]} */
export function parseZip(bytes) {
  const u = Uint8Array.from(bytes);
  const dv = new DataView(u.buffer);
  let eocd = -1;
  for (let i = u.length - 22; i >= 0; i--) if (dv.getUint32(i, true) === 0x06054b50) { eocd = i; break; }
  if (eocd < 0) throw new Error('no EOCD');
  const count = dv.getUint16(eocd + 10, true);
  const cdSize = dv.getUint32(eocd + 12, true);
  const cdOff = dv.getUint32(eocd + 16, true);
  const dec = new TextDecoder();
  const entries = [];
  let o = cdOff;
  for (let i = 0; i < count; i++) {
    if (dv.getUint32(o, true) !== 0x02014b50) throw new Error('bad central header at ' + o);
    const flags = dv.getUint16(o + 8, true);
    const method = dv.getUint16(o + 10, true);
    const crc = dv.getUint32(o + 16, true);
    const csize = dv.getUint32(o + 20, true);
    const size = dv.getUint32(o + 24, true);
    const nlen = dv.getUint16(o + 28, true);
    const xlen = dv.getUint16(o + 30, true);
    const clen = dv.getUint16(o + 32, true);
    const loff = dv.getUint32(o + 42, true);
    const name = dec.decode(u.subarray(o + 46, o + 46 + nlen));
    if (dv.getUint32(loff, true) !== 0x04034b50) throw new Error('bad local header for ' + name);
    const lnlen = dv.getUint16(loff + 26, true);
    const lxlen = dv.getUint16(loff + 28, true);
    const localName = dec.decode(u.subarray(loff + 30, loff + 30 + lnlen));
    const localCrc = dv.getUint32(loff + 14, true);
    const data = u.subarray(loff + 30 + lnlen + lxlen, loff + 30 + lnlen + lxlen + csize);
    entries.push({ name, crc, size, csize, method, flags, data: Array.from(data), localName, localCrc });
    o += 46 + nlen + xlen + clen;
  }
  return { count, cdSize, cdOff, cdEnd: o, eocd, entries };
}

/** Create a folder of files on C: (paths relative to dir, '/' separated). files: {rel: text} */
export async function makeFolder(p, dir, files) {
  await p.fn((dir, files) => {
    const v = RC.app.vfs;
    const mk = (path) => { const parts = path.split('\\'); let cur = parts[0]; for (let i = 1; i < parts.length; i++) { cur += '\\' + parts[i]; if (!v.exists(cur)) v.mkdir(cur); } };
    mk(dir);
    for (const [rel, text] of Object.entries(files)) {
      const full = dir + '\\' + rel.replace(/\//g, '\\');
      mk(full.replace(/\\[^\\]*$/, ''));
      v.writeFile(full, RC.strToBytes(text), { trusted: true });
    }
    RC.app.renderExplorer();
  }, dir, files);
}

/** Expand an explorer path (e.g. 'C:\\GAMES') so its row is rendered */
export async function expand(p, path) {
  await p.fn((path) => {
    const parts = path.toUpperCase().split('\\');
    let cur = parts[0];
    RC.app.expandedDirs.add(cur + '\\');
    for (let i = 1; i < parts.length; i++) { cur += '\\' + parts[i]; RC.app.expandedDirs.add(cur); }
    RC.app.renderExplorer();
  }, path);
}

/** Right-click a folder row in the explorer by its label text (exact match on .nm) */
export async function folderContext(p, label) {
  // the explorer re-renders ~150ms after any disk change, which can replace the row between
  // marking it and clicking it; let it settle, then retry a few times
  await p.sleep(200);
  for (let attempt = 0; attempt < 4; attempt++) {
    const ok = await p.fn((label) => {
      const row = [...document.querySelectorAll('#explorerTree .tree-item')].find((r) => r.querySelector('.nm') && r.querySelector('.nm').innerText === label);
      if (!row) return false;
      row.setAttribute('data-e2e-target', '1');
      return true;
    }, label);
    if (!ok) throw new Error('folder row not found: ' + label);
    try {
      await p.rightClick('[data-e2e-target="1"]');
      await p.ev("document.querySelectorAll('[data-e2e-target]').forEach(e => e.removeAttribute('data-e2e-target'))");
      await p.wait("!!document.querySelector('.menu-pop')", 3000);
      return;
    } catch (e) {
      if (attempt === 3) throw e;
      await p.sleep(200);
    }
  }
}

/** Build a share code in the page from {name, main} + {rel: text} via RC.Share.pack */
export function packCode(p, meta, files) {
  return p.fn((meta, files) => {
    const f = {};
    for (const [k, v] of Object.entries(files)) f[k] = RC.strToBytes(v);
    return RC.Share.pack(meta, f);
  }, meta, files);
}

/** Build a raw (uncompressed, 'r') share code from an arbitrary object, in node */
export function rawCode(obj) {
  return 'CPD1.r' + Buffer.from(JSON.stringify(obj)).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
export const b64u = (s) => Buffer.from(s).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

/** Install a fake in-memory FileSystemDirectoryHandle tree as window.__fakeRoot and stub showDirectoryPicker.
 *  tree: {name, files: {path: text}} ('/' separated, nested dirs created) */
export async function installFakeFS(p, name, files) {
  await p.fn((name, files) => {
    class FakeFile {
      constructor(name, text) { this.kind = 'file'; this.name = name; this.data = new TextEncoder().encode(text || ''); this.mtime = 1700000000000; this.writes = 0; }
      async getFile() { return new File([this.data], this.name, { lastModified: this.mtime }); }
      async createWritable() {
        const self = this; const chunks = [];
        return {
          async write(d) { chunks.push(d instanceof Uint8Array ? d.slice() : new Uint8Array(await new Blob([d]).arrayBuffer())); },
          async close() {
            const n = chunks.reduce((a, c) => a + c.length, 0); const out = new Uint8Array(n); let o = 0;
            for (const c of chunks) { out.set(c, o); o += c.length; }
            self.data = out; self.mtime = Date.now(); self.writes++;
            window.__fakeLog.push('write ' + self.name + ' ' + n);
          },
        };
      }
      text() { return new TextDecoder().decode(this.data); }
      isSameEntry(o) { return Promise.resolve(o === this); }
    }
    class FakeDir {
      constructor(name) { this.kind = 'directory'; this.name = name; this.children = new Map(); }
      async *entries() { for (const [k, v] of [...this.children]) yield [k, v]; }
      async *values() { for (const v of [...this.children.values()]) yield v; }
      async *keys() { for (const k of [...this.children.keys()]) yield k; }
      async getDirectoryHandle(n, o) {
        let c = this.children.get(n);
        if (c && c.kind !== 'directory') throw new DOMException('type mismatch', 'TypeMismatchError');
        if (!c) { if (!o || !o.create) throw new DOMException('not found', 'NotFoundError'); c = new FakeDir(n); this.children.set(n, c); window.__fakeLog.push('mkdir ' + n); }
        return c;
      }
      async getFileHandle(n, o) {
        let c = this.children.get(n);
        if (c && c.kind !== 'file') throw new DOMException('type mismatch', 'TypeMismatchError');
        if (!c) { if (!o || !o.create) throw new DOMException('not found', 'NotFoundError'); c = new FakeFile(n, ''); this.children.set(n, c); window.__fakeLog.push('create ' + n); }
        return c;
      }
      async removeEntry(n) { if (!this.children.has(n)) throw new DOMException('not found', 'NotFoundError'); this.children.delete(n); window.__fakeLog.push('remove ' + n); }
      async queryPermission() { return 'granted'; }
      async requestPermission() { return 'granted'; }
    }
    const root = new FakeDir(name);
    for (const [path, text] of Object.entries(files)) {
      const parts = path.split('/');
      let d = root;
      for (let i = 0; i < parts.length - 1; i++) { if (!d.children.has(parts[i])) d.children.set(parts[i], new FakeDir(parts[i])); d = d.children.get(parts[i]); }
      d.children.set(parts[parts.length - 1], new FakeFile(parts[parts.length - 1], text));
    }
    window.__fakeRoot = root;
    window.__fakeLog = [];
    window.__pickerCalls = [];
    window.__fakeFile = (path) => { let d = root; const parts = path.split('/'); for (const x of parts) { d = d && d.children ? d.children.get(x) : null; } return d || null; };
    window.showDirectoryPicker = async (opts) => { window.__pickerCalls.push(opts || null); return root; };
  }, name, files);
}

/** Open the mount dialog (via the explorer button), choose the permission mode and pick the folder */
export async function mountVia(p, mode, how = 'button') {
  if (how === 'menu') await p.menu('File', 'Mount Computer Folder as D:…');
  else await p.click('#explorerActions button[title="Mount a computer folder as D:"]');
  await p.waitModal();
  await p.fn((m) => { const s = document.querySelector('.modal-back:last-child select'); s.value = m; s.dispatchEvent(new Event('change', { bubbles: true })); }, mode);
  await p.modalButton('Choose Folder…');
  await p.wait('!!RC.app.vfs.drives.D', 4000);
  await p.sleep(100);
}
