// Virtual file system with DOS-style drives and paths.
//  C:  persistent virtual disk (IndexedDB in the browser, memory when headless)
//  D:  (optional) a real folder mounted via the File System Access API, with explicit
//      user permission for reads and writes.
(function (RC) {
  'use strict';

  class VfsError extends Error {
    constructor(code, msg) { super(msg || ''); this.code = code; }
  }
  RC.VfsError = VfsError;
  const fail = (code, msg) => { throw new VfsError(code, msg); };

  const BAD_CHARS = /[<>:"|?*\x00-\x1f]/;

  /** Match a DOS wildcard pattern (case-insensitive) */
  function wildMatch(pattern, name) {
    const re = new RegExp('^' + pattern.toUpperCase().replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\?/g, '.') + '$');
    if (re.test(name.toUpperCase())) return true;
    // DOS: "*.*" matches names without extension, "NAME.*" matches "NAME"
    if (/\.\*$/.test(pattern) && !name.includes('.')) return wildMatch(pattern.slice(0, -2), name);
    return false;
  }
  RC.wildMatch = wildMatch;

  class MemDrive {
    constructor(letter, label) {
      this.letter = letter;
      this.label = label || '';
      this.entries = new Map(); // KEY -> {name, type:'file'|'dir', data, mtime}
      this.writable = true;
      this.readable = true;
    }
    get(key) { return this.entries.get(key); }
    totalSize() { let n = 0; for (const e of this.entries.values()) if (e.data) n += e.data.length; return n; }
  }

  class VFS extends RC.Emitter {
    constructor(opts) {
      super();
      this.opts = Object.assign({ maxFileSize: 8 * 1024 * 1024, maxTotal: 96 * 1024 * 1024, maxEntries: 5000 }, opts || {});
      this.drives = { C: new MemDrive('C', 'COMPENDIUM') };
      this.cwds = { C: '\\' };
      this.curDrive = 'C';
      this.permissionHandler = null; // async (op, path) => boolean
    }

    // ---- path handling -------------------------------------------------------------------
    /** Resolve to {drive, key, parts, name, parentKey} */
    resolve(path) {
      if (typeof path !== 'string') fail(64);
      let p = path.trim();
      if (!p) fail(64);
      let drive = this.curDrive;
      const dm = /^([A-Za-z]):/.exec(p);
      if (dm) { drive = dm[1].toUpperCase(); p = p.slice(2); }
      if (!this.drives[drive]) fail(68, 'Drive ' + drive + ': not available');
      p = p.replace(/\//g, '\\');
      let parts;
      if (p.startsWith('\\')) parts = [];
      else parts = (this.cwds[drive] || '\\').split('\\').filter(Boolean);
      for (const seg of p.split('\\')) {
        if (!seg || seg === '.') continue;
        if (seg === '..') { if (parts.length) parts.pop(); continue; }
        if (BAD_CHARS.test(seg) || seg.length > 64) fail(64);
        parts.push(seg.replace(/[ .]+$/, '') || seg);
      }
      const key = '\\' + parts.map((s) => s.toUpperCase()).join('\\');
      const parentKey = '\\' + parts.slice(0, -1).map((s) => s.toUpperCase()).join('\\');
      return { drive, key, parts, name: parts[parts.length - 1] || '', parentKey, display: drive + ':' + '\\' + parts.join('\\') };
    }
    drive(letter) { return this.drives[letter]; }
    isDir(drv, key) { return key === '\\' || (drv.get(key) && drv.get(key).type === 'dir'); }

    // ---- queries -----------------------------------------------------------------------------
    exists(path) {
      try {
        const r = this.resolve(path);
        const d = this.drives[r.drive];
        return r.key === '\\' || d.entries.has(r.key);
      } catch (e) { return false; }
    }
    stat(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (r.key === '\\') return { type: 'dir', size: 0, mtime: 0, name: '' };
      const e = d.get(r.key);
      if (!e) return null;
      return { type: e.type, size: e.data ? e.data.length : (e.size || 0), mtime: e.mtime, name: e.name };
    }
    /** Is the file content available synchronously? (mounted drives load lazily) */
    isReady(path) {
      const r = this.resolve(path);
      const e = this.drives[r.drive].get(r.key);
      return !e || e.type !== 'file' || !!e.data;
    }
    /** Load a lazily-mounted file. Returns a promise. */
    load(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      const e = d.get(r.key);
      if (!e || e.data || !e.handle) return Promise.resolve();
      if (!e.loading) {
        e.loading = e.handle.getFile().then((f) => f.arrayBuffer()).then((ab) => {
          e.data = new Uint8Array(ab);
          e.loading = null;
        }).catch(() => { e.data = new Uint8Array(0); e.loading = null; e.error = true; });
      }
      return e.loading;
    }

    readFile(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (!d.readable) fail(70);
      const e = d.get(r.key);
      if (!e) {
        if (!this.isDir(d, r.parentKey)) fail(76);
        fail(53);
      }
      if (e.type === 'dir') fail(75);
      if (!e.data) fail(57, 'not loaded');
      return e.data;
    }
    readText(path) { return RC.bytesToStr(this.readFile(path)); }

    /** Check write permission: 'yes' | 'no' | 'ask' */
    canWrite(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (d.writable === true) return 'yes';
      if (d.writable === 'ask') return 'ask';
      return 'no';
    }

    writeFile(path, data, opts) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (!opts || !opts.trusted) { if (d.writable !== true) fail(70); }
      if (!r.name) fail(64);
      if (!this.isDir(d, r.parentKey)) fail(76);
      const existing = d.get(r.key);
      if (existing && existing.type === 'dir') fail(75);
      if (existing && existing.readOnly) fail(70);
      if (data.length > this.opts.maxFileSize) fail(61, 'File too large');
      const total = d.totalSize() - (existing && existing.data ? existing.data.length : 0) + data.length;
      if (total > this.opts.maxTotal) fail(61);
      if (!existing && d.entries.size >= this.opts.maxEntries) fail(67);
      const e = existing || { name: r.name, type: 'file' };
      e.data = data instanceof Uint8Array ? data : RC.strToBytes(String(data));
      e.mtime = Date.now();
      if (!existing) d.entries.set(r.key, e);
      this.changed(d, r.key, e);
      return e;
    }
    writeText(path, s, opts) { return this.writeFile(path, RC.strToBytes(s), opts); }

    unlink(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (d.writable !== true) fail(70);
      const e = d.get(r.key);
      if (!e) fail(53);
      if (e.type === 'dir') fail(75);
      d.entries.delete(r.key);
      this.changed(d, r.key, null, e);
    }
    mkdir(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (d.writable !== true) fail(70);
      if (!r.name) fail(75);
      if (d.entries.has(r.key)) fail(75);
      if (!this.isDir(d, r.parentKey)) fail(76);
      const e = { name: r.name, type: 'dir', mtime: Date.now() };
      d.entries.set(r.key, e);
      this.changed(d, r.key, e);
    }
    rmdir(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (d.writable !== true) fail(70);
      const e = d.get(r.key);
      if (!e || e.type !== 'dir') fail(76);
      const prefix = r.key + '\\';
      for (const k of d.entries.keys()) if (k.startsWith(prefix)) fail(75, 'Directory not empty');
      if ((this.cwds[r.drive] || '\\').toUpperCase() === r.key) fail(75);
      d.entries.delete(r.key);
      this.changed(d, r.key, null, e);
    }
    rename(from, to) {
      const a = this.resolve(from), b = this.resolve(to);
      if (a.drive !== b.drive) fail(74);
      const d = this.drives[a.drive];
      if (d.writable !== true) fail(70);
      const e = d.get(a.key);
      if (!e) fail(53);
      if (d.entries.has(b.key) && a.key !== b.key) fail(58);
      if (!this.isDir(d, b.parentKey)) fail(76);
      const moves = [[a.key, b.key]];
      if (e.type === 'dir') {
        const prefix = a.key + '\\';
        for (const k of d.entries.keys()) if (k.startsWith(prefix)) moves.push([k, b.key + k.slice(a.key.length)]);
      }
      for (const [k1, k2] of moves) {
        const x = d.entries.get(k1);
        d.entries.delete(k1);
        if (k1 === a.key) x.name = b.name;
        d.entries.set(k2, x);
        this.changed(d, k1, null, x);
        this.changed(d, k2, x);
      }
    }
    chdir(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      if (!this.isDir(d, r.key)) fail(76);
      this.cwds[r.drive] = r.key === '\\' ? '\\' : '\\' + r.parts.join('\\');
    }
    cwd(drive) { drive = drive || this.curDrive; return drive + ':' + (this.cwds[drive] || '\\'); }
    setDrive(letter) { if (!this.drives[letter]) fail(68); this.curDrive = letter; }

    /** List a directory. Returns [{name, type, size, mtime, path}] */
    list(path, pattern) {
      const r = this.resolve(path || '.');
      const d = this.drives[r.drive];
      if (!this.isDir(d, r.key)) fail(76);
      const prefix = r.key === '\\' ? '\\' : r.key + '\\';
      const out = [];
      for (const [k, e] of d.entries) {
        if (!k.startsWith(prefix)) continue;
        const rest = k.slice(prefix.length);
        if (!rest || rest.includes('\\')) continue;
        if (pattern && !wildMatch(pattern, e.name)) continue;
        out.push({ name: e.name, type: e.type, size: e.data ? e.data.length : (e.size || 0), mtime: e.mtime, path: r.drive + ':' + prefix + e.name, readOnly: !!e.readOnly });
      }
      out.sort((x, y) => (x.type === y.type ? x.name.localeCompare(y.name) : x.type === 'dir' ? -1 : 1));
      return out;
    }
    /** Expand a file spec with wildcards ("*.BAS", "DATA\\*.*") */
    glob(spec) {
      const r = this.resolve(spec);
      const name = r.name;
      if (!/[*?]/.test(name)) return this.exists(spec) ? [r.display] : [];
      const dir = r.drive + ':' + '\\' + r.parts.slice(0, -1).join('\\');
      return this.list(dir, name).filter((e) => e.type === 'file').map((e) => e.path);
    }
    /** Walk all entries of a drive under a directory (recursive) */
    walk(path) {
      const r = this.resolve(path);
      const d = this.drives[r.drive];
      const prefix = r.key === '\\' ? '\\' : r.key + '\\';
      const out = [];
      for (const [k, e] of d.entries) if (k.startsWith(prefix)) out.push({ key: k, rel: k.slice(prefix.length), entry: e });
      return out;
    }

    changed(d, key, e, old) {
      this.emit('change', { drive: d.letter, key, entry: e, old });
      if (d.onChange) d.onChange(key, e, old);
    }

    // ---- persistence (browser) --------------------------------------------------------------
    /** Attach IndexedDB persistence to drive C. Resolves when loaded. */
    async persist(dbName) {
      if (typeof indexedDB === 'undefined') return;
      const d = this.drives.C;
      const db = await new Promise((res, rej) => {
        const rq = indexedDB.open(dbName || 'compendium-vfs', 1);
        rq.onupgradeneeded = () => rq.result.createObjectStore('entries');
        rq.onsuccess = () => res(rq.result);
        rq.onerror = () => rej(rq.error);
      });
      this.db = db;
      await new Promise((res) => {
        const tx = db.transaction('entries', 'readonly');
        const st = tx.objectStore('entries');
        const rq = st.openCursor();
        rq.onsuccess = () => {
          const c = rq.result;
          if (!c) { res(); return; }
          const v = c.value;
          d.entries.set(c.key, { name: v.name, type: v.type, data: v.data ? new Uint8Array(v.data) : undefined, mtime: v.mtime });
          c.continue();
        };
        rq.onerror = () => res();
      });
      const pending = new Map();
      let timer = null;
      d.onChange = (key, e) => {
        pending.set(key, e);
        if (!timer) timer = setTimeout(flush, 250);
      };
      const flush = () => {
        timer = null;
        const tx = db.transaction('entries', 'readwrite');
        const st = tx.objectStore('entries');
        for (const [k, e] of pending) {
          if (e) st.put({ name: e.name, type: e.type, data: e.data ? e.data.slice().buffer : null, mtime: e.mtime }, k);
          else st.delete(k);
        }
        pending.clear();
      };
      this.flushNow = flush;
      if (typeof window !== 'undefined') window.addEventListener('beforeunload', () => { if (pending.size) flush(); });
    }

    // ---- File System Access API mount -------------------------------------------------------
    /** Mount a real directory handle as a drive letter. mode: 'read' | 'ask' | 'write' */
    async mountHandle(letter, handle, mode) {
      const d = new MemDrive(letter, handle.name);
      d.handle = handle;
      d.host = true;
      d.writable = mode === 'write' ? true : mode === 'ask' ? 'ask' : false;
      let count = 0;
      const scan = async (dirHandle, prefix, depth) => {
        if (depth > 6) return;
        for await (const [name, h] of dirHandle.entries()) {
          if (++count > this.opts.maxEntries) return;
          if (name.startsWith('.')) continue;
          const key = prefix + '\\' + name.toUpperCase();
          if (h.kind === 'directory') {
            d.entries.set(key, { name, type: 'dir', mtime: 0, handle: h });
            await scan(h, key, depth + 1);
          } else {
            let size = 0, mtime = 0;
            try { const f = await h.getFile(); size = f.size; mtime = f.lastModified; } catch (e) { /* ignore */ }
            d.entries.set(key, { name, type: 'file', size, mtime, handle: h, parentHandle: dirHandle });
          }
        }
      };
      await scan(handle, '', 0);
      this.drives[letter] = d;
      this.cwds[letter] = '\\';
      // write-through for host drives
      d.onChange = (key, e, old) => this.hostWrite(d, key, e, old);
      this.emit('mount', letter);
      return d;
    }
    unmount(letter) {
      if (letter === 'C') return;
      delete this.drives[letter];
      delete this.cwds[letter];
      if (this.curDrive === letter) this.curDrive = 'C';
      this.emit('mount', letter);
    }
    async hostWrite(d, key, e, old) {
      try {
        const parts = key.split('\\').filter(Boolean);
        let dir = d.handle;
        for (let i = 0; i < parts.length - 1; i++) {
          const pe = d.entries.get('\\' + parts.slice(0, i + 1).join('\\'));
          dir = await dir.getDirectoryHandle(pe ? pe.name : parts[i], { create: true });
        }
        const last = parts[parts.length - 1];
        if (!e) {
          // deleted: find original name
          const name = old ? old.name : last;
          try { await dir.removeEntry(name, { recursive: false }); } catch (x) { /* ignore */ }
          return;
        }
        if (e.type === 'dir') { e.handle = await dir.getDirectoryHandle(e.name, { create: true }); return; }
        const fh = e.handle && e.handle.kind === 'file' && e.handle.name === e.name ? e.handle : await dir.getFileHandle(e.name, { create: true });
        e.handle = fh;
        const w = await fh.createWritable();
        await w.write(e.data);
        await w.close();
      } catch (x) {
        this.emit('hostError', { key, error: x });
      }
    }
  }

  RC.VFS = VFS;
  RC.MemDrive = MemDrive;
})(RC);
