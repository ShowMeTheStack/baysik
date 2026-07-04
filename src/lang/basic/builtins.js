// BASIC builtin functions and statements.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const { T, O, WAIT } = B;
  const err = B.err;

  const F = B.BUILTIN_FNS = {};
  const S = B.SYS_STMTS = {};

  const sameNum = (ts) => (ts[0] && ts[0].code <= 4 ? ts[0] : T.SINGLE);
  const fltOf = (ts) => (ts[0] && ts[0].code === 4 ? T.DOUBLE : T.SINGLE);
  const toI = (v) => B.toInt(v);
  const toL = (v) => B.toLong(v);

  function def(name, args, ret, impl, min, max) {
    F[name] = { args, ret, impl, min: min === undefined ? args.length : min, max: max === undefined ? args.length : max };
  }
  const noArg = (name, ret, impl) => { F[name] = { args: '', ret, impl, min: 0, max: 0, noArgs: true }; };

  // ---- math ---------------------------------------------------------------------------
  def('ABS', 'n', sameNum, (vm, x) => (x < 0 ? -x : x));
  def('SGN', 'n', 'int', (vm, x) => (x > 0 ? 1 : x < 0 ? -1 : 0));
  def('INT', 'n', sameNum, (vm, x) => Math.floor(x));
  def('FIX', 'n', sameNum, (vm, x) => Math.trunc(x));
  def('CINT', 'n', 'int', (vm, x) => B.toInt(x));
  def('CLNG', 'n', 'long', (vm, x) => B.toLong(x));
  def('CSNG', 'n', 'single', (vm, x) => B.toSingle(x));
  def('CDBL', 'n', 'double', (vm, x) => x);
  def('SQR', 'n', fltOf, (vm, x) => { if (x < 0) err(5); return Math.sqrt(x); });
  def('SIN', 'n', fltOf, (vm, x) => Math.sin(x));
  def('COS', 'n', fltOf, (vm, x) => Math.cos(x));
  def('TAN', 'n', fltOf, (vm, x) => Math.tan(x));
  def('ATN', 'n', fltOf, (vm, x) => Math.atan(x));
  def('EXP', 'n', fltOf, (vm, x) => { const r = Math.exp(x); if (!isFinite(r)) err(6); return r; });
  def('LOG', 'n', fltOf, (vm, x) => { if (x <= 0) err(5); return Math.log(x); });
  def('RND', 'n', 'single', (vm, n) => vm.rng.rnd(n), 0, 1);
  noArg('TIMER', 'single', (vm) => {
    const d = new Date(Date.now() + vm.dateOffset);
    const secs = d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds() + d.getMilliseconds() / 1000;
    // 18.2 Hz tick resolution like the PC timer
    return Math.fround(Math.floor(secs * 18.2065) / 18.2065);
  });

  // ---- strings ------------------------------------------------------------------------
  def('ASC', 's', 'int', (vm, s) => { if (!s.length) err(5); return s.charCodeAt(0); });
  def('CHR$', 'n', 'string', (vm, n) => { n = toI(n); if (n < 0 || n > 255) err(5); return String.fromCharCode(n); });
  def('LEFT$', 'sn', 'string', (vm, s, n) => { n = toL(n); if (n < 0) err(5); return s.slice(0, n); });
  def('RIGHT$', 'sn', 'string', (vm, s, n) => { n = toL(n); if (n < 0) err(5); return n === 0 ? '' : s.slice(-n); });
  def('MID$', 'snn', 'string', (vm, s, st, n) => {
    st = toL(st);
    if (st < 1 || (n !== undefined && toL(n) < 0)) err(5);
    if (n === undefined) return s.slice(st - 1);
    return s.substr(st - 1, toL(n));
  }, 2, 3);
  def('LCASE$', 's', 'string', (vm, s) => s.replace(/[A-Z]+/g, (m) => m.toLowerCase()));
  def('UCASE$', 's', 'string', (vm, s) => s.replace(/[a-z]+/g, (m) => m.toUpperCase()));
  def('LTRIM$', 's', 'string', (vm, s) => s.replace(/^ +/, ''));
  def('RTRIM$', 's', 'string', (vm, s) => s.replace(/ +$/, ''));
  def('SPACE$', 'n', 'string', (vm, n) => { n = toL(n); if (n < 0 || n > 32767) err(5); return ' '.repeat(n); });
  def('STR$', 'n', 'string', (vm, n) => B.strNum(n, vm.argCodes ? vm.argCodes[0] : B.numCode(n)));
  def('VAL', 's', 'double', (vm, s) => {
    const r = B.parseNumber(s);
    if (Math.abs(r.v) > 1.7976931348623157e308) err(6);
    return r.v;
  });
  def('HEX$', 'n', 'string', (vm, n) => radix(vm, n, 16));
  def('OCT$', 'n', 'string', (vm, n) => radix(vm, n, 8));
  function radix(vm, n, r) {
    n = toL(n);
    const code = vm.argCodes ? vm.argCodes[0] : 1;
    if (n < 0) n = (code === 1 || (n >= -32768 && code !== 2)) ? n & 0xffff : n >>> 0;
    return n.toString(r).toUpperCase();
  }
  F.STRING$ = {
    args: 'n?', min: 2, max: 2, ret: 'string',
    impl: (vm, n, x) => {
      n = toL(n);
      if (n < 0 || n > 32767) err(5);
      let ch;
      if (typeof x === 'string') { if (!x.length) err(5); ch = x[0]; }
      else { x = toI(x); if (x < 0 || x > 255) err(5); ch = String.fromCharCode(x); }
      return ch.repeat(n);
    },
  };
  F.INSTR = {
    ret: 'int',
    compile(e) {
      const a = e.args;
      if (a.length < 2 || a.length > 3) this.error('Argument-count mismatch', e.pos, 37);
      if (a.length === 3) this.coerce(this.expr(a[0]), T.LONG, a[0].pos); else this.emit(O.CONST, 1);
      const off = a.length - 2;
      for (let i = off; i < a.length; i++) { const t = this.expr(a[i]); if (!B.isStr(t)) this.error('Type mismatch', a[i].pos, 13); }
      this.emit(O.CALLB, (vm, st, s, p) => {
        if (st < 1 || st > 32767) err(5);
        if (st > s.length) return 0;
        if (p === '') return st;
        return s.indexOf(p, st - 1) + 1;
      }, 3, 'INSTR', 1);
      return T.INT;
    },
  };
  F.LEN = {
    ret: 'int',
    compile(e) {
      if (e.args.length !== 1) this.error('Argument-count mismatch', e.pos, 37);
      const a = e.args[0];
      if (a.k === 'var' || a.k === 'index' || a.k === 'member') {
        const lt = this.tryLvalueType(a);
        if (lt && !B.isStr(lt)) { this.emit(O.CONST, lt.size); return T.INT; }
        if (lt && lt.k === 'fixstr') { this.emit(O.CONST, lt.len); return T.INT; }
      }
      const t = this.expr(a);
      if (!B.isStr(t)) {
        if (B.isNum(t)) { this.emit(O.POP); this.emit(O.CONST, t.size); return T.INT; }
        this.error('Type mismatch', a.pos, 13);
      }
      this.emit(O.CALLB, (vm, s) => s.length, 1, 'LEN', 1);
      return T.INT;
    },
  };

  // ---- binary conversions --------------------------------------------------------------
  const dv8 = new DataView(new ArrayBuffer(8));
  const bytesStr = (n) => { let s = ''; for (let i = 0; i < n; i++) s += String.fromCharCode(dv8.getUint8(i)); return s; };
  const strBytes = (s, n) => { if (s.length < n) err(5); for (let i = 0; i < n; i++) dv8.setUint8(i, s.charCodeAt(i) & 255); };
  def('MKI$', 'n', 'string', (vm, n) => { dv8.setInt16(0, toI(n), true); return bytesStr(2); });
  def('MKL$', 'n', 'string', (vm, n) => { dv8.setInt32(0, toL(n), true); return bytesStr(4); });
  def('MKS$', 'n', 'string', (vm, n) => { dv8.setFloat32(0, n, true); return bytesStr(4); });
  def('MKD$', 'n', 'string', (vm, n) => { dv8.setFloat64(0, n, true); return bytesStr(8); });
  def('CVI', 's', 'int', (vm, s) => { strBytes(s, 2); return dv8.getInt16(0, true); });
  def('CVL', 's', 'long', (vm, s) => { strBytes(s, 4); return dv8.getInt32(0, true); });
  def('CVS', 's', 'single', (vm, s) => { strBytes(s, 4); return dv8.getFloat32(0, true); });
  def('CVD', 's', 'double', (vm, s) => { strBytes(s, 8); return dv8.getFloat64(0, true); });
  // Microsoft Binary Format (used by GW-BASIC files)
  def('MKSMBF$', 'n', 'string', (vm, n) => {
    dv8.setFloat32(0, n, true);
    const bits = dv8.getUint32(0, true);
    const sign = bits >>> 31, exp = (bits >>> 23) & 255, man = bits & 0x7fffff;
    let out = [0, 0, 0, 0];
    if (exp !== 0) {
      const mexp = exp + 2;
      if (mexp > 255) err(6);
      out = [man & 255, (man >>> 8) & 255, ((man >>> 16) & 0x7f) | (sign << 7), mexp];
    }
    return String.fromCharCode(...out);
  });
  def('CVSMBF', 's', 'single', (vm, s) => {
    if (s.length < 4) err(5);
    const b = [0, 1, 2, 3].map((i) => s.charCodeAt(i) & 255);
    if (b[3] === 0) return 0;
    const sign = b[2] >>> 7, exp = b[3] - 2;
    if (exp <= 0) return 0;
    const man = b[0] | (b[1] << 8) | ((b[2] & 0x7f) << 16);
    dv8.setUint32(0, ((sign << 31) | (exp << 23) | man) >>> 0, true);
    return dv8.getFloat32(0, true);
  });
  def('MKDMBF$', 'n', 'string', (vm, n) => {
    dv8.setFloat64(0, n, true);
    const bits = dv8.getBigUint64(0, true);
    const sign = Number(bits >> 63n), exp = Number((bits >> 52n) & 0x7ffn);
    let man = bits & 0xfffffffffffffn;
    const out = new Array(8).fill(0);
    if (exp !== 0) {
      const mexp = exp - 1023 + 129;
      if (mexp > 255) err(6);
      if (mexp > 0) {
        man = man << 3n; // 55-bit mantissa
        for (let i = 0; i < 7; i++) out[i] = Number((man >> BigInt(i * 8)) & 0xffn);
        out[6] = (out[6] & 0x7f) | (sign << 7);
        out[7] = mexp;
      }
    }
    return String.fromCharCode(...out);
  });
  def('CVDMBF', 's', 'double', (vm, s) => {
    if (s.length < 8) err(5);
    const b = []; for (let i = 0; i < 8; i++) b.push(s.charCodeAt(i) & 255);
    if (b[7] === 0) return 0;
    const sign = BigInt(b[6] >>> 7);
    const exp = BigInt(b[7] - 129 + 1023);
    let man = 0n;
    for (let i = 0; i < 7; i++) man |= BigInt(i === 6 ? b[i] & 0x7f : b[i]) << BigInt(i * 8);
    man >>= 3n;
    dv8.setBigUint64(0, (sign << 63n) | (exp << 52n) | man, true);
    return dv8.getFloat64(0, true);
  });

  // ---- system / misc ---------------------------------------------------------------------
  noArg('DATE$', 'string', (vm) => {
    const d = new Date(Date.now() + vm.dateOffset);
    const p = (n) => String(n).padStart(2, '0');
    return `${p(d.getMonth() + 1)}-${p(d.getDate())}-${d.getFullYear()}`;
  });
  noArg('TIME$', 'string', (vm) => {
    const d = new Date(Date.now() + vm.dateOffset);
    const p = (n) => String(n).padStart(2, '0');
    return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
  });
  noArg('ERR', 'int', (vm) => vm.err);
  noArg('ERL', 'long', (vm) => vm.erl);
  noArg('ERDEV', 'int', () => 0);
  noArg('ERDEV$', 'string', () => '');
  noArg('COMMAND$', 'string', (vm) => vm.host.commandLine || '');
  noArg('CSRLIN', 'int', (vm) => vm.display.cursorRow() + 1);
  noArg('FREEFILE', 'int', (vm) => { for (let i = 1; i < 256; i++) if (!vm.files.has(i)) return i; err(67); });
  noArg('INKEY$', 'string', (vm) => (vm.kbd ? vm.kbd.get() : ''));
  def('POS', 'n', 'int', (vm) => vm.display.cursorCol() + 1);
  def('LPOS', 'n', 'int', (vm) => (vm._printerOut ? vm._printerOut.col : 1));
  def('FRE', '?', 'long', (vm, x) => (typeof x === 'string' ? 58000 : x === -1 ? 320000 : x === -2 ? 2048 : 58000));
  def('ENVIRON$', '?', 'string', (vm, x) => {
    const env = vm.host.environ || (vm.host.environ = { PATH: 'C:\\', COMSPEC: 'C:\\COMMAND.COM', PROMPT: '$P$G' });
    const keys = Object.keys(env);
    if (typeof x === 'string') return env[x.toUpperCase()] || '';
    x = toI(x);
    if (x < 1 || x > 255) err(5);
    const k = keys[x - 1];
    return k ? k + '=' + env[k] : '';
  });
  def('PEEK', 'n', 'int', (vm, a) => B.memPeek(vm, toL(a)));
  def('INP', 'n', 'int', (vm, p) => B.portIn(vm, toL(p)));
  def('USR', 'n', 'single', () => err(73), 1, 1);
  def('IOCTL$', 'n', 'string', () => err(5));
  def('EOF', 'n', 'int', (vm, n) => B.fileEof(vm, n));
  def('LOF', 'n', 'long', (vm, n) => B.fileLof(vm, n));
  def('LOC', 'n', 'long', (vm, n) => B.fileLoc(vm, n));
  def('SEEK', 'n', 'long', (vm, n) => B.fileSeekPos(vm, n));
  def('FILEATTR', 'nn', 'long', (vm, n, a) => B.fileAttr(vm, n, a));
  F['INPUT$'] = {
    args: 'nn', min: 1, max: 2, ret: 'string',
    impl: (vm, n, f) => {
      n = toI(n);
      if (n < 1 || n > 32767) err(5);
      if (f !== undefined) return B.fileInputChars(vm, f, n);
      // wait for n keys (no echo)
      let got = '';
      return vm.block({
        interruptible: false,
        poll: () => {
          while (got.length < n) {
            const k = vm.kbd ? vm.kbd.get() : '';
            if (!k) return false;
            got += k[0] === '\0' && k.length === 2 ? k : k; // extended keys count as 2 chars
          }
          vm.stack.push(got.slice(0, n));
          return true;
        },
      });
    },
  };

  // Graphics functions
  F.POINT = {
    args: 'nn', min: 1, max: 2, ret: 'single',
    impl: (vm, x, y) => (y === undefined ? vm.display.pointFn(toI(x)) : vm.display.point(x, y)),
  };
  def('PMAP', 'nn', 'single', (vm, c, n) => vm.display.pmap(c, toI(n)));
  F.SCREEN = {
    args: 'nnn', min: 2, max: 3, ret: 'int',
    impl: (vm, r, c, z) => vm.display.screenFn(toI(r), toI(c), z !== undefined && z !== 0),
  };
  def('PEN', 'n', 'int', (vm, n) => (vm.host.pen ? vm.host.pen.read(toI(n)) : 0));
  def('STICK', 'n', 'int', (vm, n) => (vm.host.gamepad ? vm.host.gamepad.stick(toI(n)) : 0));
  def('STRIG', 'n', 'int', (vm, n) => (vm.host.gamepad ? vm.host.gamepad.strig(toI(n)) : 0));
  def('PLAY', 'n', 'int', (vm) => (vm.audio ? vm.audio.notesQueued() : 0));

  // Array bounds
  function boundsCompile(isUpper) {
    return function (e) {
      const a = e.args;
      if (a.length < 1 || a.length > 2) this.error('Argument-count mismatch', e.pos, 37);
      const v = this.lookupVar(a[0], true, false);
      if (!v) this.error('Array not defined', a[0].pos, 38);
      this.emit(O.REF, v.area, v.slot);
      if (a.length === 2) this.coerce(this.expr(a[1]), T.INT, a[1].pos); else this.emit(O.CONST, 1);
      this.emit(O.CALLB, (vm, ref, d) => {
        const arr = ref.c[ref.k];
        if (!arr) err(9);
        if (d < 1 || d > arr.dims.length) err(9);
        return isUpper ? arr.dims[d - 1].hi : arr.dims[d - 1].lo;
      }, 2, isUpper ? 'UBOUND' : 'LBOUND', 1);
      return T.INT;
    };
  }
  F.LBOUND = { compile: boundsCompile(false) };
  F.UBOUND = { compile: boundsCompile(true) };

  // VARPTR & friends: emulate addresses with a registry so VARPTR$ works with DRAW/PLAY
  function addrCompile(kind) {
    return function (e) {
      if (e.args.length !== 1) this.error('Argument-count mismatch', e.pos, 37);
      const a = e.args[0];
      if (!(a.k === 'var' || a.k === 'index' || a.k === 'member')) this.error('Variable required', a.pos, 40);
      const t = this.ref(a);
      this.emit(O.CALLB, (vm, ref) => B.varAddress(vm, ref, t, kind), 1, kind, kind === 'VARPTR$' ? 5 : 2);
      return kind === 'VARPTR$' ? T.STRING : T.LONG;
    };
  }
  F.VARPTR = { compile: addrCompile('VARPTR') };
  F.VARSEG = { compile: addrCompile('VARSEG') };
  F.SADD = { compile: addrCompile('SADD') };
  F['VARPTR$'] = { compile: addrCompile('VARPTR$') };

  B.varAddress = function (vm, ref, t, kind) {
    // Array elements live in typed arrays: give them a real (virtual) segment so that
    // DEF SEG = VARSEG(a(0)): BLOAD "x", VARPTR(a(0)) and PEEK/POKE work on array memory.
    if (ArrayBuffer.isView(ref.c) && kind !== 'VARPTR$') {
      const seg = B.segFor(vm, ref.c);
      if (kind === 'VARSEG') return seg;
      return ref.k * ref.c.BYTES_PER_ELEMENT;
    }
    const reg = vm.varRegistry || (vm.varRegistry = { list: [], map: new Map() });
    let byC = reg.map.get(ref.c);
    if (!byC) { byC = new Map(); reg.map.set(ref.c, byC); }
    let id = byC.get(ref.k);
    if (id === undefined) { id = reg.list.length + 1; reg.list.push({ ref, type: t }); byC.set(ref.k, id); }
    if (kind === 'VARSEG') return 0x1000;
    if (kind === 'VARPTR$') {
      const tb = t.code === 1 ? 2 : t.code === 2 ? 20 : t.code === 3 ? 4 : t.code === 4 ? 8 : 3;
      return String.fromCharCode(tb, id & 255, (id >> 8) & 255);
    }
    return (id * 8) & 0xffff;
  };
  /** Resolve a VARPTR$ string (3 bytes) back to a value */
  B.varFromPtr = function (vm, s) {
    if (!vm.varRegistry || s.length < 3) err(5);
    const id = s.charCodeAt(1) | (s.charCodeAt(2) << 8);
    const e = vm.varRegistry.list[id - 1];
    if (!e) err(5);
    return e.ref.c[e.ref.k];
  };

  // ---- statements (SYS) --------------------------------------------------------------------
  function sys(name, args, impl) { S[name] = { args, impl }; }
  const opt = (v, d) => (v === undefined ? d : v);

  sys('CLS', 'n', (vm, n) => vm.display.cls(n === undefined ? undefined : toI(n)));
  sys('COLOR', 'nnn', (vm, a, b, c) => vm.display.color(a === undefined ? undefined : toL(a), b === undefined ? undefined : toL(b), c === undefined ? undefined : toL(c)));
  sys('SCREEN', 'nnnnn', (vm, m, cs, ap, vp, er) => {
    vm.display.screen(m === undefined ? undefined : toI(m), cs === undefined ? undefined : toI(cs), ap === undefined ? undefined : toI(ap), vp === undefined ? undefined : toI(vp));
  });
  sys('LOCATE', 'nnnnn', (vm, r, c, cur, st, sp) => vm.display.locate(
    r === undefined ? undefined : toI(r), c === undefined ? undefined : toI(c), cur === undefined ? undefined : toI(cur),
    st === undefined ? undefined : toI(st), sp === undefined ? undefined : toI(sp)));
  sys('WIDTH', 'nn', (vm, c, r) => vm.display.width(c === undefined ? undefined : toI(c), r === undefined ? undefined : toI(r)));
  sys('WIDTHF', 'nn', (vm, f, w) => B.fileWidth(vm, f, toI(w)));
  sys('WIDTHLPT', 'n', (vm, w) => { vm.printerOut().width = toI(w); });
  sys('WIDTHDEV', 'sn', (vm, dev, w) => {
    const d = dev.toUpperCase();
    if (d.startsWith('SCRN')) vm.display.width(toI(w));
    else if (d.startsWith('LPT')) vm.printerOut().width = toI(w);
  });
  sys('VIEWPRINT', 'nn', (vm, a, b) => vm.display.viewPrint(a === undefined ? undefined : toI(a), b === undefined ? undefined : toI(b)));
  sys('VIEW', 'nnnnnnn', (vm, scr, x1, y1, x2, y2, color, border) => vm.display.view(scr, x1, y1, x2, y2, color, border));
  sys('WINDOW', 'nnnnn', (vm, scr, x1, y1, x2, y2) => vm.display.window(scr, x1, y1, x2, y2));
  sys('DRAW', 's', (vm, s) => vm.display.draw(s, vm));
  sys('PALETTE', 'nn', (vm, a, c) => vm.display.palette(a === undefined ? undefined : toL(a), c === undefined ? undefined : toL(c)));
  sys('PCOPY', 'nn', (vm, a, b) => vm.display.pcopy(toI(a), toI(b)));
  sys('BEEP', '', (vm) => {
    if (vm.audio) vm.audio.beep();
  });
  sys('SOUND', 'nn', (vm, f, d) => {
    if (f === undefined || d === undefined) err(5);
    if (!vm.audio) return;
    if (d < 0 || d > 65535) err(5);
    if ((f < 37 || f > 32767) && !(f === 0 && d === 0)) err(5);
    vm.audio.sound(f, d);
    const until = vm.audio.waitUntilForeground();
    if (until > 0) waitTime(vm, until);
  });
  sys('PLAY', 's', (vm, s) => {
    if (!vm.audio) return;
    vm.audio.play(s, vm);
    const until = vm.audio.waitUntilForeground();
    if (until > 0) waitTime(vm, until);
  });
  function waitTime(vm, untilMs) {
    vm.block({
      interruptible: true,
      poll: () => (typeof performance !== 'undefined' ? performance.now() : Date.now()) >= untilMs,
    });
  }
  B.waitTime = waitTime;
  sys('SLEEP', 'n', (vm, n) => {
    const t0 = typeof performance !== 'undefined' ? performance.now() : Date.now();
    const secs = n === undefined ? 0 : toL(n);
    const p = {
      interruptible: true,
      startCount: vm.kbd ? vm.kbd.pressCount : 0,
      poll: () => {
        if (p.interrupted) return true;
        if (vm.kbd && vm.kbd.pressCount !== p.startCount) return true;
        if (secs > 0) return (typeof performance !== 'undefined' ? performance.now() : Date.now()) - t0 >= secs * 1000;
        return false;
      },
    };
    vm.block(p);
  });
  sys('RANDOMIZE', 'n', (vm, n) => {
    if (n !== undefined) { vm.rng.randomize(n); return; }
    // Prompt like GW-BASIC/QBasic
    const o = vm.screenOut();
    const ask = () => {
      o.write('Random-number seed (-32768 to 32767)? ');
      const ed = new B.LineEditor(vm, false);
      vm.block({
        poll: () => {
          const line = ed.poll();
          if (line === null) return false;
          const vals = B.parseInputLine(line, [T.INT]);
          if (!vals) { o.write('Redo from start'); o.newline(); ask(); return false; }
          vm.rng.randomize(vals[0]);
          return true;
        },
        cancel: () => ed.cancel(),
      });
    };
    ask();
  });
  sys('KEYDISP', 'n', (vm, on) => vm.display.setKeyLine(!!on, vm.softKeys()));
  sys('KEYLIST', '', (vm) => {
    const keys = vm.softKeys();
    for (let i = 1; i <= 10; i++) { vm.printText('F' + i + ' ' + RC.fromCP437(keys[i - 1] || '').replace(/\r/g, '←')); vm.screenOut().newline(); }
  });
  sys('KEYSET', 'ns', (vm, n, s) => {
    n = toI(n);
    const keys = vm.softKeys();
    if (n >= 1 && n <= 10) { keys[n - 1] = s.slice(0, 15); vm.display.refreshKeyLine(keys); return; }
    if (n === 30 || n === 31) { keys[n - 20] = s.slice(0, 15); return; }
    if (n >= 15 && n <= 25) {
      // user-defined trap key: CHR$(shiftflags) + CHR$(scancode)
      if (s.length < 2) err(5);
      vm.userKeys = vm.userKeys || {};
      vm.userKeys[n] = { flags: s.charCodeAt(0), scan: s.charCodeAt(1) };
      return;
    }
    err(5);
  });
  sys('SEEK', 'nn', (vm, f, p) => B.fileSeek(vm, f, p));
  sys('KILL', 's', (vm, f) => B.fsKill(vm, f));
  sys('NAME', 'ss', (vm, a, b) => B.fsName(vm, a, b));
  sys('MKDIR', 's', (vm, p) => B.fsMkdir(vm, p));
  sys('RMDIR', 's', (vm, p) => B.fsRmdir(vm, p));
  sys('CHDIR', 's', (vm, p) => B.fsChdir(vm, p));
  sys('FILES', 's', (vm, spec) => B.fsFiles(vm, spec));
  sys('POKE', 'nn', (vm, a, v) => B.memPoke(vm, toL(a), toI(v)));
  sys('OUT', 'nn', (vm, p, v) => B.portOut(vm, toL(p), toI(v)));
  sys('WAIT', 'nnn', (vm, p, and, xor) => {
    p = toL(p); and = toI(and); xor = xor === undefined ? 0 : toI(xor);
    const check = () => ((B.portIn(vm, p) ^ xor) & and) !== 0;
    if (check()) return;
    vm.block({ poll: check });
  });
  sys('BLOAD', 'sn', (vm, f, off) => B.memBload(vm, f, off));
  sys('BSAVE', 'snn', (vm, f, off, len) => B.memBsave(vm, f, toL(off), toL(len)));
  sys('SHELL', 's', (vm, cmd) => B.shell(vm, cmd));
  sys('ENVIRON', 's', (vm, s) => {
    const m = /^([^=\s]+)\s*[=\s]\s*(.*)$/.exec(s);
    if (!m) err(5);
    const env = vm.host.environ || (vm.host.environ = { PATH: 'C:\\', COMSPEC: 'C:\\COMMAND.COM', PROMPT: '$P$G' });
    if (m[2] === '' || m[2] === ';') delete env[m[1].toUpperCase()]; else env[m[1].toUpperCase()] = m[2];
  });
  sys('SETDATE', 's', (vm, s) => {
    const m = /^(\d{1,2})[-/](\d{1,2})[-/](\d{2}|\d{4})$/.exec(s.trim());
    if (!m) err(5);
    let y = +m[3]; if (y < 100) y += 1900;
    const cur = new Date(Date.now() + vm.dateOffset);
    const d = new Date(y, +m[1] - 1, +m[2], cur.getHours(), cur.getMinutes(), cur.getSeconds());
    vm.dateOffset = d.getTime() - Date.now();
  });
  sys('SETTIME', 's', (vm, s) => {
    const m = /^(\d{1,2})(?::(\d{1,2}))?(?::(\d{1,2}))?$/.exec(s.trim());
    if (!m) err(5);
    const cur = new Date(Date.now() + vm.dateOffset);
    const d = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate(), +m[1], +(m[2] || 0), +(m[3] || 0));
    vm.dateOffset = d.getTime() - Date.now();
  });
  sys('TRON', '', (vm) => { vm.tron = true; vm.lastTron = null; vm.updateDbgFlag(); });
  sys('TROFF', '', (vm) => { vm.tron = false; vm.updateDbgFlag(); });
  sys('IOCTL', '', () => err(5));
  sys('ABSOLUTE', '', () => err(73, 'CALL ABSOLUTE (machine code) is not supported'));
  sys('NOP', 'nnn', () => {});
  sys('DEFSEG', 'n', (vm, seg) => {
    if (seg === undefined) { vm.defSeg = 0x1000; return; } // DGROUP
    seg = B.toLong(seg);
    if (seg < 0) seg += 65536;
    if (seg < 0 || seg > 65535) err(5);
    vm.defSeg = seg;
  });

  B.VM.prototype.softKeys = function () {
    if (!this.host.softKeys) {
      this.host.softKeys = ['LIST', 'RUN\r', 'LOAD"', 'SAVE"', 'CONT\r', ',"LPT1:"\r', 'TRON\r', 'TROFF\r', 'KEY', 'SCREEN 0,0,0\r', '', ''];
    }
    return this.host.softKeys;
  };

  // CALLB passes argument type codes for STR$/HEX$/OCT$
  const origBuiltin = B.Compiler.prototype.builtinCall;
  B.Compiler.prototype.builtinCall = function (e) {
    const spec = B.BUILTIN_FNS[e.fn];
    if (spec && !spec.compile) {
      const startLen = this.code.length;
      const rt = origBuiltin.call(this, e);
      const ins = this.code[this.code.length - 1];
      if (ins.op === O.CALLB) {
        // record argument type codes
        ins.e = e.args.map((a) => (a && a._t ? a._t.code : undefined));
      }
      void startLen;
      return rt;
    }
    return origBuiltin.call(this, e);
  };
  // Remember static type of expressions for CALLB arg codes
  const origExpr = B.Compiler.prototype.expr;
  B.Compiler.prototype.expr = function (e) {
    const t = origExpr.call(this, e);
    if (e && typeof e === 'object') e._t = t;
    return t;
  };
})(RC);
