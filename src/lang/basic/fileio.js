// BASIC file I/O, devices, PEEK/POKE memory map, I/O ports, BLOAD/BSAVE, DOS commands.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const { WAIT } = B;
  const err = B.err;

  const MODE_ATTR = { I: 1, O: 2, R: 4, A: 8, B: 32 };
  const MODE_NAMES = { INPUT: 'I', OUTPUT: 'O', APPEND: 'A', RANDOM: 'R', BINARY: 'B' };

  function vfsOf(vm) {
    const v = vm.host.vfs;
    if (!v) err(68);
    return v;
  }
  /** Run a VFS operation, mapping VfsError codes to BASIC errors. */
  function fsCall(fn) {
    try { return fn(); } catch (e) {
      if (e instanceof RC.VfsError) err(e.code, e.message || undefined);
      throw e;
    }
  }
  B.fsCall = fsCall;

  class BFile {
    constructor(num, mode, path) {
      this.num = num; this.mode = mode; this.path = path;
      this.buf = new Uint8Array(256); this.len = 0; this.pos = 0;
      this.reclen = 128; this.lastRec = 0; this.eofFlag = false;
      this.fields = null; this.dirty = false;
      this.col = 1; this.width = 255;
      this.device = null;
    }
    setData(bytes) {
      this.buf = new Uint8Array(Math.max(256, bytes.length * 2));
      this.buf.set(bytes);
      this.len = bytes.length;
    }
    ensure(n) {
      if (n <= this.buf.length) return;
      const nb = new Uint8Array(Math.max(n, this.buf.length * 2));
      nb.set(this.buf.subarray(0, this.len));
      this.buf = nb;
    }
    writeBytes(bytes, at) {
      if (at === undefined) at = this.pos;
      this.ensure(at + bytes.length);
      if (at > this.len) this.buf.fill(0, this.len, at);
      this.buf.set(bytes, at);
      this.pos = at + bytes.length;
      if (this.pos > this.len) this.len = this.pos;
      this.dirty = true;
    }
    writeStr(s) {
      const b = RC.strToBytes(s);
      this.writeBytes(b);
      for (let i = 0; i < s.length; i++) {
        const c = s.charCodeAt(i);
        if (c === 13 || c === 10) this.col = 1; else this.col++;
      }
    }
    data() { return this.buf.slice(0, this.len); }
  }
  B.BFile = BFile;

  function getFile(vm, n, modes) {
    n = B.toInt(n);
    if (n < 1 || n > 255) err(52);
    const f = vm.files.get(n);
    if (!f) err(52);
    if (modes && !modes.includes(f.mode)) err(54);
    return f;
  }

  // ---- OPEN / CLOSE ---------------------------------------------------------------------------
  B.fileOpen = function (vm, gw, mode, num, file, len, access) {
    let m;
    if (gw) {
      m = (mode || '').trim().toUpperCase()[0];
      if (!MODE_ATTR[m]) err(54);
    } else m = MODE_NAMES[mode];
    num = B.toInt(num);
    if (num < 1 || num > 255) err(52);
    if (vm.files.has(num)) err(55);
    const f = new BFile(num, m, file);
    if (len !== undefined) {
      len = B.toLong(len);
      if (len < 1 || len > 32767) err(5);
      f.reclen = len;
    }
    const devm = /^\s*(SCRN|CONS|KYBD|LPT[1-3]|COM[1-4]|PRN|CON|NUL)\s*:?(.*)$/i.exec(file);
    if (devm && (file.includes(':') || /^(PRN|CON|NUL)$/i.test(file.trim()))) {
      const dev = devm[1].toUpperCase();
      if (dev.startsWith('COM')) err(68);
      f.device = dev === 'PRN' ? 'LPT1' : dev === 'CON' ? 'CONS' : dev;
      if (f.device === 'KYBD' && m !== 'I') err(54);
      if ((f.device === 'SCRN' || f.device.startsWith('LPT')) && m === 'I') err(54);
      vm.files.set(num, f);
      return;
    }
    const vfs = vfsOf(vm);
    const r = fsCall(() => vfs.resolve(file));
    f.key = r.drive + ':' + r.key;
    f.path = r.display;
    // Lazy-loaded (mounted) files: wait for the data and retry the OPEN
    if (!fsCall(() => vfs.isReady(file))) {
      vm.stack.push(mode, num, file, len);
      vm.pc--;
      const p = vfs.load(file);
      let done = false;
      p.then(() => { done = true; });
      vm.block({ poll: () => done });
      return;
    }
    // Same file already open for writing?
    for (const o of vm.files.values()) {
      if (o.key === f.key && (m !== 'I' || o.mode !== 'I') && !(m === 'R' && o.mode === 'R')) err(55);
    }
    if (m !== 'I') {
      const perm = fsCall(() => vfs.canWrite(file));
      if (perm === 'no') err(70);
      if (perm === 'ask') {
        // The user answered on a previous attempt: the OPEN was re-executed with the answer recorded
        const ans = vm.permAnswers && vm.permAnswers.get(f.key);
        if (ans === false) { vm.permAnswers.delete(f.key); err(70); }
        if (ans === true) { vm.permAnswers.delete(f.key); f.trusted = true; }
        else {
          if (!vm.host.askPermission) err(70);
          vm.stack.push(mode, num, file, len);
          vm.pc--;
          let state = 0;
          vm.host.askPermission('write', r.display).then((ok) => { state = ok ? 1 : 2; }, () => { state = 2; });
          vm.permAnswers = vm.permAnswers || new Map();
          vm.block({ poll: () => {
            if (!state) return false;
            vm.permAnswers.set(f.key, state === 1); // retry the OPEN, which reads the answer
            return true;
          } });
          return;
        }
      }
    }
    const exists = fsCall(() => vfs.exists(file));
    const st = exists ? fsCall(() => vfs.stat(file)) : null;
    if (st && st.type === 'dir') err(75);
    switch (m) {
      case 'I':
        if (!exists) err(53);
        f.setData(fsCall(() => vfs.readFile(file)));
        break;
      case 'O':
        fsCall(() => vfs.writeFile(file, new Uint8Array(0), { trusted: f.trusted }));
        f.dirty = true;
        break;
      case 'A':
        if (exists) f.setData(fsCall(() => vfs.readFile(file)));
        // strip trailing ^Z
        while (f.len && f.buf[f.len - 1] === 26) f.len--;
        f.pos = f.len;
        if (!exists) fsCall(() => vfs.writeFile(file, new Uint8Array(0), { trusted: f.trusted }));
        break;
      case 'R': case 'B':
        if (exists) f.setData(fsCall(() => vfs.readFile(file)));
        else fsCall(() => vfs.writeFile(file, new Uint8Array(0), { trusted: f.trusted }));
        break;
    }
    vm.files.set(num, f);
  };

  B.fileClose = function (vm, n) {
    n = B.toInt(n);
    const f = vm.files.get(n);
    if (!f) return;
    vm.files.delete(n);
    if (f.device) return;
    if (f.mode !== 'I' && f.dirty) {
      const vfs = vfsOf(vm);
      try { vfs.writeFile(f.path, f.data(), { trusted: f.trusted }); } catch (e) {
        if (e instanceof RC.VfsError) err(e.code);
        throw e;
      }
    }
  };
  /** Flush all open files without closing (used before CHAIN/SHELL) */
  B.flushFiles = function (vm) {
    const vfs = vm.host.vfs;
    for (const f of vm.files.values()) {
      if (!f.device && f.mode !== 'I' && f.dirty) { try { vfs.writeFile(f.path, f.data()); f.dirty = false; } catch (e) { /* ignore */ } }
    }
  };

  // ---- PRINT # / WRITE # channels ----------------------------------------------------------------
  class FileChannel {
    constructor(f) { this.f = f; }
    get col() { return this.f.col; }
    get width() { return this.f.width; }
    write(s) { this.f.writeStr(s); }
    newline() { this.f.writeStr('\r\n'); }
    comma() { const next = (Math.floor((this.f.col - 1) / 14) + 1) * 14 + 1; this.write(' '.repeat(next - this.f.col)); }
    tab(n) { n = Math.max(1, B.toInt(n)); if (this.f.col > n) this.newline(); this.write(' '.repeat(Math.max(0, n - this.f.col))); }
    spc(n) { this.write(' '.repeat(Math.max(0, B.toInt(n)))); }
  }
  B.fileOutChannel = function (vm, n) {
    const f = getFile(vm, n);
    if (f.device === 'SCRN' || f.device === 'CONS') return vm.screenOut();
    if (f.device && f.device.startsWith('LPT')) return vm.printerOut();
    if (f.device === 'NUL') return { col: 1, width: 255, write() {}, newline() {}, comma() {}, tab() {}, spc() {} };
    if (f.mode !== 'O' && f.mode !== 'A') err(54);
    return new FileChannel(f);
  };
  B.fileWidth = function (vm, n, w) {
    const f = getFile(vm, n);
    f.width = w;
  };

  // ---- INPUT # / LINE INPUT # ----------------------------------------------------------------------
  function atEof(f) { return f.pos >= f.len || f.buf[f.pos] === 26; }
  B.fileInput = function (vm, n, code) {
    const f = getFile(vm, n, ['I']);
    if (f.device === 'KYBD') err(54);
    const b = f.buf;
    // skip leading whitespace (and line breaks)
    while (!atEof(f) && (b[f.pos] === 32 || b[f.pos] === 13 || b[f.pos] === 10 || b[f.pos] === 9)) f.pos++;
    if (atEof(f)) err(62);
    let s = '';
    if (code === 5) {
      if (b[f.pos] === 34) {
        f.pos++;
        while (!atEof(f) && b[f.pos] !== 34) s += String.fromCharCode(b[f.pos++]);
        if (!atEof(f)) f.pos++;
        // skip to delimiter
        while (!atEof(f) && b[f.pos] !== 44 && b[f.pos] !== 13 && b[f.pos] !== 10) f.pos++;
      } else {
        while (!atEof(f) && b[f.pos] !== 44 && b[f.pos] !== 13 && b[f.pos] !== 10) s += String.fromCharCode(b[f.pos++]);
        s = s.replace(/[ \t]+$/, '');
      }
    } else {
      while (!atEof(f) && b[f.pos] !== 44 && b[f.pos] !== 13 && b[f.pos] !== 10 && b[f.pos] !== 32) s += String.fromCharCode(b[f.pos++]);
      while (!atEof(f) && b[f.pos] === 32) f.pos++;
    }
    // consume one delimiter
    if (!atEof(f)) {
      if (b[f.pos] === 44) f.pos++;
      else if (b[f.pos] === 13) { f.pos++; if (b[f.pos] === 10) f.pos++; }
      else if (b[f.pos] === 10) f.pos++;
    }
    if (code === 5) return s;
    const r = B.parseNumber(s);
    return r.v;
  };
  B.fileLineInput = function (vm, n) {
    const f = getFile(vm, n, ['I']);
    if (atEof(f)) err(62);
    const b = f.buf;
    let s = '';
    while (!atEof(f) && b[f.pos] !== 13 && b[f.pos] !== 10) s += String.fromCharCode(b[f.pos++]);
    if (!atEof(f)) {
      if (b[f.pos] === 13) { f.pos++; if (f.pos < f.len && b[f.pos] === 10) f.pos++; }
      else f.pos++;
    }
    return s;
  };
  B.fileInputChars = function (vm, n, count) {
    const f = getFile(vm, n, ['I', 'B', 'R']);
    if (f.device === 'KYBD') err(54);
    if (f.pos + count > f.len) err(62);
    const s = RC.bytesToStr(f.buf, f.pos, f.pos + count);
    f.pos += count;
    return s;
  };

  // ---- EOF / LOF / LOC / SEEK ------------------------------------------------------------------------
  B.fileEof = function (vm, n) {
    const f = getFile(vm, n);
    if (f.device) return f.device === 'KYBD' ? 0 : -1;
    if (f.mode === 'I') return atEof(f) ? -1 : 0;
    if (f.mode === 'R' || f.mode === 'B') return f.eofFlag ? -1 : 0;
    return -1;
  };
  B.fileLof = function (vm, n) { const f = getFile(vm, n); return f.device ? 0 : f.len; };
  B.fileLoc = function (vm, n) {
    const f = getFile(vm, n);
    if (f.mode === 'R') return f.lastRec;
    if (f.mode === 'B') return f.pos;
    return Math.floor(f.pos / 128) + (f.mode === 'I' && f.pos > 0 ? 1 : 0);
  };
  B.fileSeekPos = function (vm, n) {
    const f = getFile(vm, n);
    if (f.mode === 'R') return f.lastRec + 1;
    return f.pos + 1;
  };
  B.fileSeek = function (vm, n, p) {
    const f = getFile(vm, n);
    p = B.toLong(p);
    if (p < 1) err(63);
    if (f.mode === 'R') { f.lastRec = p - 1; f.pos = (p - 1) * f.reclen; }
    else f.pos = p - 1;
    f.eofFlag = false;
  };
  B.fileAttr = function (vm, n, a) {
    const f = getFile(vm, n);
    a = B.toInt(a);
    if (a === 1) return MODE_ATTR[f.mode];
    if (a === 2) return f.num + 4;
    err(5);
  };

  // ---- FIELD / GET / PUT -----------------------------------------------------------------------------
  B.fileField = function (vm, n, pairs) {
    const f = getFile(vm, n, ['R']);
    let off = 0;
    const fields = [];
    for (let i = 0; i < pairs.length; i += 2) {
      const w = B.toInt(pairs[i]);
      const ref = pairs[i + 1];
      if (w < 0) err(5);
      if (off + w > f.reclen) err(50);
      fields.push({ ref, off, w });
      ref.c[ref.k] = ' '.repeat(w);
      off += w;
    }
    f.fields = (f.fields || []).concat(fields);
  };
  function recBytes(f, recNo) {
    const out = new Uint8Array(f.reclen);
    const start = (recNo - 1) * f.reclen;
    if (start < f.len) out.set(f.buf.subarray(start, Math.min(f.len, start + f.reclen)));
    return out;
  }
  B.fileGet = function (vm, n, rec, ref, t) {
    const f = getFile(vm, n, ['R', 'B']);
    if (f.mode === 'R') {
      let recNo = rec === undefined ? f.lastRec + 1 : Math.floor(rec);
      if (recNo < 1) err(63);
      f.eofFlag = (recNo - 1) * f.reclen >= f.len;
      const bytes = recBytes(f, recNo);
      f.lastRec = recNo;
      f.pos = recNo * f.reclen;
      if (ref) {
        let v;
        if (t.k === 'string') {
          const l = bytes[0] | (bytes[1] << 8);
          v = RC.bytesToStr(bytes, 2, Math.min(2 + l, bytes.length));
        } else {
          if (t.size > f.reclen) err(59);
          v = B.deserialize(t, bytes, 0);
        }
        vm.storeTo(ref.c, ref.k, t, v);
      } else if (f.fields) {
        for (const fd of f.fields) fd.ref.c[fd.ref.k] = RC.bytesToStr(bytes, fd.off, fd.off + fd.w);
      }
      return;
    }
    // BINARY
    if (rec !== undefined) { if (rec < 1) err(63); f.pos = Math.floor(rec) - 1; }
    if (!ref) err(5);
    const cur = ref.c[ref.k];
    const size = t.k === 'string' ? cur.length : t.size;
    const bytes = new Uint8Array(size);
    if (f.pos < f.len) bytes.set(f.buf.subarray(f.pos, Math.min(f.len, f.pos + size)));
    f.eofFlag = f.pos + size > f.len;
    f.pos += size;
    const v = t.k === 'string' ? RC.bytesToStr(bytes) : B.deserialize(t, bytes, 0);
    vm.storeTo(ref.c, ref.k, t, v);
  };
  B.filePut = function (vm, n, rec, v, t) {
    const f = getFile(vm, n, ['R', 'B']);
    if (f.mode === 'R') {
      let recNo = rec === undefined ? f.lastRec + 1 : Math.floor(rec);
      if (recNo < 1) err(63);
      const bytes = new Uint8Array(f.reclen);
      if (v !== undefined) {
        if (t.k === 'string') {
          if (v.length + 2 > f.reclen) err(59);
          bytes[0] = v.length & 255; bytes[1] = v.length >> 8;
          for (let i = 0; i < v.length; i++) bytes[2 + i] = v.charCodeAt(i) & 255;
        } else {
          if (t.size > f.reclen) err(59);
          B.serialize(t, v, bytes, 0);
        }
      } else {
        // from FIELD buffer
        if (f.fields) {
          for (const fd of f.fields) {
            const s = String(fd.ref.c[fd.ref.k]);
            for (let i = 0; i < fd.w; i++) bytes[fd.off + i] = i < s.length ? s.charCodeAt(i) & 255 : 32;
          }
        } else {
          const old = recBytes(f, recNo);
          bytes.set(old);
        }
      }
      f.writeBytes(bytes, (recNo - 1) * f.reclen);
      f.lastRec = recNo;
      return;
    }
    if (rec !== undefined) { if (rec < 1) err(63); f.pos = Math.floor(rec) - 1; }
    if (v === undefined) err(5);
    let bytes;
    if (t.k === 'string' || typeof v === 'string') bytes = RC.strToBytes(t.k === 'fixstr' ? B.padFix(v, t.len) : v);
    else { bytes = new Uint8Array(t.size); B.serialize(t, v, bytes, 0); }
    f.writeBytes(bytes);
  };

  // ---- DOS commands -------------------------------------------------------------------------------------
  B.fsKill = function (vm, spec) {
    const vfs = vfsOf(vm);
    const list = fsCall(() => vfs.glob(spec));
    if (!list.length) err(53);
    for (const p of list) {
      for (const f of vm.files.values()) if (f.path === p) err(55);
      fsCall(() => vfs.unlink(p));
    }
  };
  B.fsName = function (vm, a, b) {
    const vfs = vfsOf(vm);
    if (!fsCall(() => vfs.exists(a))) err(53);
    if (!fsCall(() => vfs.isReady(a))) {
      // a file on a mounted folder that was never read: load its contents before renaming
      vm.stack.push(a, b); vm.pc--;
      let done = false; vfs.load(a).then(() => { done = true; });
      vm.block({ poll: () => done });
      return;
    }
    if (fsCall(() => vfs.exists(b))) err(58);
    fsCall(() => vfs.rename(a, b));
  };
  B.fsMkdir = (vm, p) => fsCall(() => vfsOf(vm).mkdir(p));
  B.fsRmdir = (vm, p) => fsCall(() => vfsOf(vm).rmdir(p));
  B.fsChdir = (vm, p) => fsCall(() => vfsOf(vm).chdir(p));
  B.fsFiles = function (vm, spec) {
    const vfs = vfsOf(vm);
    let dir = '.', pattern = '*.*';
    if (spec !== undefined && spec.trim()) {
      const r = fsCall(() => vfs.resolve(spec, true));
      const st = /[*?]/.test(r.name) ? null : fsCall(() => vfs.stat(spec));
      if (st && st.type === 'dir') { dir = spec; pattern = '*.*'; }
      else { dir = r.drive + ':\\' + r.parts.slice(0, -1).join('\\'); pattern = r.name; }
    }
    const list = fsCall(() => vfs.list(dir, pattern));
    const o = vm.screenOut();
    const r = fsCall(() => vfs.resolve(dir));
    o.write(r.display); o.newline();
    if (!list.length) err(53);
    const cw = 18;
    for (const e of list) {
      let name = e.name.toUpperCase();
      const dot = name.lastIndexOf('.');
      if (dot > 0 && dot >= name.length - 4 && name.length <= 12) name = name.slice(0, dot).padEnd(8) + '.' + name.slice(dot + 1).padEnd(3);
      if (e.type === 'dir') name = (name.padEnd(12) + '<DIR>');
      if (o.col + cw > o.width + 1) o.newline();
      o.write(RC.toCP437(name).padEnd(cw));
    }
    if (o.col > 1) o.newline();
    const free = Math.max(0, vfs.opts.maxTotal - vfs.drives[r.drive].totalSize());
    o.write(' ' + free + ' Bytes free');
    o.newline();
  };

  /** SHELL: a tiny command interpreter for common DOS commands */
  B.shell = function (vm, cmd) {
    const o = vm.screenOut();
    const vfs = vm.host.vfs;
    B.flushFiles(vm);
    if (cmd === undefined || !cmd.trim()) {
      o.write('SHELL to a DOS prompt is not available in the browser.'); o.newline();
      return;
    }
    const m = /^\s*(\S+)\s*(.*)$/.exec(cmd);
    const c = m[1].toUpperCase(), arg = m[2];
    const line = (s) => { o.write(s); o.newline(); };
    try {
      switch (c) {
        case 'DIR': {
          const list = vfs.list(arg && !/[*?]/.test(arg) ? arg : '.', arg && /[*?]/.test(arg) ? arg : undefined);
          line(' Directory of ' + vfs.cwd());
          for (const e of list) line((e.name.toUpperCase()).padEnd(14) + (e.type === 'dir' ? '<DIR>' : String(e.size).padStart(10)));
          line(String(list.length).padStart(9) + ' file(s)');
          return;
        }
        case 'TYPE': {
          const t = vfs.readText(arg.trim());
          for (const l of t.split(/\r?\n/)) line(l);
          return;
        }
        case 'ECHO': line(arg); return;
        case 'CLS': vm.display.cls(0); return;
        case 'VER': line('Baysik DOS emulation 1.0'); return;
        case 'CD': case 'CHDIR': if (arg) vfs.chdir(arg); else line(vfs.cwd()); return;
        case 'MD': case 'MKDIR': vfs.mkdir(arg); return;
        case 'RD': case 'RMDIR': vfs.rmdir(arg); return;
        case 'DEL': case 'ERASE': B.fsKill(vm, arg); return;
        case 'COPY': {
          const [a, b] = arg.split(/\s+/);
          vfs.writeFile(b, vfs.readFile(a).slice());
          line('        1 file(s) copied');
          return;
        }
        case 'REN': case 'RENAME': { const [a, b] = arg.split(/\s+/); vfs.rename(a, b); return; }
        case 'DATE': line('Current date is ' + new Date().toDateString()); return;
        case 'TIME': line('Current time is ' + new Date().toTimeString().slice(0, 8)); return;
      }
    } catch (e) {
      if (e instanceof RC.VfsError || e instanceof B.BasicError) { line('File not found'); return; }
      throw e;
    }
    line('Bad command or file name');
  };

  // ---- memory map (PEEK/POKE/DEF SEG/BLOAD/BSAVE) ----------------------------------------------------------
  function mem(vm) { return vm.memory || (vm.memory = new Uint8Array(0x100000)); }
  function segBytes(vm, seg) {
    const t = vm.segMap && vm.segMap.get(seg);
    if (!t) return null;
    return new Uint8Array(t.buffer, t.byteOffset, t.byteLength);
  }
  B.segFor = function (vm, typed) {
    vm.segMap = vm.segMap || new Map();
    vm.segOf = vm.segOf || new Map();
    let s = vm.segOf.get(typed);
    if (s === undefined) {
      s = 0x6000 + vm.segMap.size * 0x10;
      vm.segMap.set(s, typed); vm.segOf.set(typed, s);
    }
    return s;
  };
  B.memPeek = function (vm, off) {
    if (off < 0) off += 65536;
    if (off < 0 || off > 65535) err(5);
    const sb = segBytes(vm, vm.defSeg);
    if (sb) return off < sb.length ? sb[off] : 0;
    const addr = (vm.defSeg * 16 + off) & 0xFFFFF;
    const v = vm.display.videoPeek(addr);
    if (v !== undefined) return v;
    switch (addr) {
      case 0x417: return vm.kbd ? vm.kbd.flags() : 0;
      case 0x418: return 0;
      case 0x449: return [3, 4, 6, 7, 0, 0, 0, 0xD, 0xE, 0x10, 0xF, 0x11, 0x12, 0x13][[0, 1, 2, 3, 0, 0, 0, 7, 8, 9, 10, 11, 12, 13].indexOf(vm.display.mode)] || 3;
      case 0x44A: return vm.display.cols;
      case 0x484: return vm.display.rows - 1;
      case 0x46C: case 0x46D: case 0x46E: case 0x46F: {
        const d = new Date();
        const ticks = Math.floor(((d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds()) + d.getMilliseconds() / 1000) * 18.2065);
        return (ticks >> ((addr - 0x46C) * 8)) & 255;
      }
    }
    return mem(vm)[addr];
  };
  B.memPoke = function (vm, off, v) {
    if (off < 0) off += 65536;
    if (off < 0 || off > 65535) err(5);
    if (v < 0 || v > 255) err(5);
    const sb = segBytes(vm, vm.defSeg);
    if (sb) { if (off < sb.length) sb[off] = v; return; }
    const addr = (vm.defSeg * 16 + off) & 0xFFFFF;
    if (vm.display.videoPoke(addr, v)) return;
    if (addr === 0x417 && vm.kbd) { vm.kbd.caps = !!(v & 64); vm.kbd.num = !!(v & 32); }
    mem(vm)[addr] = v;
  };
  B.memBsave = function (vm, file, off, len) {
    if (len < 0 || len > 65535 || off < 0) err(5);
    const out = new Uint8Array(len + 7);
    out[0] = 0xFD;
    out[1] = vm.defSeg & 255; out[2] = (vm.defSeg >> 8) & 255;
    out[3] = off & 255; out[4] = (off >> 8) & 255;
    out[5] = len & 255; out[6] = (len >> 8) & 255;
    for (let i = 0; i < len; i++) out[7 + i] = B.memPeek(vm, (off + i) & 0xFFFF);
    const vfs = vfsOf(vm);
    if (fsCall(() => vfs.canWrite(file)) !== 'yes') err(70);
    fsCall(() => vfs.writeFile(file, out));
  };
  B.memBload = function (vm, file, off) {
    const vfs = vfsOf(vm);
    if (!fsCall(() => vfs.isReady(file))) {
      vm.stack.push(file, off); vm.pc--;
      let done = false; vfs.load(file).then(() => { done = true; });
      vm.block({ poll: () => done });
      return;
    }
    const data = fsCall(() => vfs.readFile(file));
    if (data.length < 7 || data[0] !== 0xFD) err(5, 'Not a BSAVE file');
    const len = data[5] | (data[6] << 8);
    let seg = vm.defSeg;
    if (off === undefined) {
      seg = data[1] | (data[2] << 8);
      off = data[3] | (data[4] << 8);
    }
    off = B.toLong(off);
    const saved = vm.defSeg;
    vm.defSeg = seg;
    try {
      for (let i = 0; i < len && 7 + i < data.length; i++) B.memPoke(vm, (off + i) & 0xFFFF, data[7 + i]);
    } finally { vm.defSeg = saved; }
  };

  // ---- I/O ports ---------------------------------------------------------------------------------------------
  B.portIn = function (vm, p) {
    switch (p) {
      case 0x60: return vm.kbd ? vm.kbd.lastScan : 0;
      case 0x61: return vm.port61 || 0;
      case 0x3DA: case 0x3BA: {
        // Vertical retrace at 60 Hz. Each frame's retrace is reported to the program at least once
        // (for ~1.2 ms after it is first seen), so WAIT/INP polling loops never miss frames.
        const t = typeof performance !== 'undefined' ? performance.now() : Date.now();
        const frame = Math.floor(t / (1000 / 60));
        if (vm.retraceFrame !== frame) { vm.retraceFrame = frame; vm.retraceStart = t; }
        const inRetrace = t - vm.retraceStart < 1.2;
        return (inRetrace ? 8 : 0) | (inRetrace || (t % 0.064) < 0.01 ? 1 : 0);
      }
      case 0x3C9: case 0x3C7: return vm.display.dacIn(p);
      case 0x201: return vm.host.gamepad ? vm.host.gamepad.port201() : 0xFF;
    }
    return 0xFF;
  };
  B.portOut = function (vm, p, v) {
    if (v < 0 || v > 255) err(5);
    switch (p) {
      case 0x3C7: case 0x3C8: case 0x3C9: vm.display.dacOut(p, v); return;
      case 0x3D9:
        if (vm.display.mode === 1) { vm.display.color(v & 15, (v >> 5) & 1); }
        return;
      case 0x43: vm.pitLatch = 0; return;
      case 0x42:
        vm.pitDiv = vm.pitLatch === 0 ? (v | ((vm.pitDiv || 0) & 0xFF00)) : (((vm.pitDiv || 0) & 0xFF) | (v << 8));
        vm.pitLatch = vm.pitLatch === 0 ? 1 : 0;
        if ((vm.port61 & 3) === 3 && vm.audio) vm.audio.speaker(1193182 / (vm.pitDiv || 65536));
        return;
      case 0x61:
        vm.port61 = v;
        if (vm.audio) vm.audio.speaker((v & 3) === 3 ? 1193182 / (vm.pitDiv || 65536) : 0);
        return;
    }
  };
})(RC);
