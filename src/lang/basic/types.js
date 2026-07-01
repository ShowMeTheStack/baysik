// BASIC data types, arrays, records, numeric coercion and number formatting.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const err = B.err;

  const T = {
    INT: { k: 'int', code: 1, size: 2, sfx: '%', name: 'INTEGER' },
    LONG: { k: 'long', code: 2, size: 4, sfx: '&', name: 'LONG' },
    SINGLE: { k: 'single', code: 3, size: 4, sfx: '!', name: 'SINGLE' },
    DOUBLE: { k: 'double', code: 4, size: 8, sfx: '#', name: 'DOUBLE' },
    STRING: { k: 'string', code: 5, size: 4, sfx: '$', name: 'STRING' },
  };
  B.T = T;
  const BY_SFX = { '%': T.INT, '&': T.LONG, '!': T.SINGLE, '#': T.DOUBLE, '$': T.STRING };
  const BY_K = { int: T.INT, long: T.LONG, single: T.SINGLE, double: T.DOUBLE, string: T.STRING };
  B.typeBySfx = (s) => BY_SFX[s];
  B.typeByK = (k) => BY_K[k];
  const fixCache = new Map();
  B.fixStr = function (len) {
    if (!fixCache.has(len)) fixCache.set(len, { k: 'fixstr', code: 5, size: len, len, sfx: '', name: 'STRING * ' + len });
    return fixCache.get(len);
  };
  B.recordType = function (def) {
    if (!def.type) def.type = { k: 'record', code: 6, size: def.size, def, sfx: '', name: def.display || def.name };
    return def.type;
  };
  B.isNum = (t) => t.code <= 4;
  B.isStr = (t) => t.code === 5;
  B.isRec = (t) => t.code === 6;
  B.sameType = (a, b) => a === b || (a.k === 'fixstr' && b.k === 'fixstr' && a.len === b.len) || (a.code === 6 && b.code === 6 && a.def === b.def);
  /** Numeric result type of a binary arithmetic op */
  B.numPromote = (a, b) => (a.code >= b.code ? a : b);

  // ---- numeric coercion -----------------------------------------------------
  /** Banker's rounding as done by CINT/CLNG and integer assignment. */
  function roundEven(v) {
    const f = Math.floor(v);
    const d = v - f;
    if (d > 0.5) return f + 1;
    if (d < 0.5) return f;
    return f % 2 === 0 ? f : f + 1;
  }
  B.roundEven = roundEven;
  const toInt = (v) => {
    if (typeof v !== 'number') err(13);
    v = roundEven(v);
    if (v < -32768 || v > 32767 || v !== v) err(6);
    return v;
  };
  const toLong = (v) => {
    if (typeof v !== 'number') err(13);
    v = roundEven(v);
    if (v < -2147483648 || v > 2147483647 || v !== v) err(6);
    return v;
  };
  const toSingle = (v) => {
    if (typeof v !== 'number') err(13);
    const f = Math.fround(v);
    if (!isFinite(f)) err(6);
    return f === 0 ? 0 : f;
  };
  const toDouble = (v) => {
    if (typeof v !== 'number') err(13);
    if (!isFinite(v)) err(6);
    return v === 0 ? 0 : v;
  };
  B.toInt = toInt; B.toLong = toLong; B.toSingle = toSingle; B.toDouble = toDouble;

  /** Coerce a runtime value to a storage type. */
  B.coerce = function (t, v) {
    switch (t.code) {
      case 1: return toInt(v);
      case 2: return toLong(v);
      case 3: return toSingle(v);
      case 4: return toDouble(v);
      case 5:
        if (typeof v !== 'string') err(13);
        if (t.k === 'fixstr') return padFix(v, t.len);
        return v;
      case 6: return cloneRecord(v);
    }
    return v;
  };
  function padFix(s, n) {
    if (s.length === n) return s;
    if (s.length > n) return s.slice(0, n);
    return s + ' '.repeat(n - s.length);
  }
  B.padFix = padFix;

  /** Result fix-up for arithmetic in a given type code (overflow checks). */
  B.fixNum = function (code, v) {
    switch (code) {
      case 1: if (v < -32768 || v > 32767) err(6); return v;
      case 2: if (v < -2147483648 || v > 2147483647) err(6); return v;
      case 3: { const f = Math.fround(v); if (!isFinite(f)) { if (f !== f) err(5); err(6); } return f; }
      default: if (!isFinite(v)) { if (v !== v) err(5); err(6); } return v;
    }
  };

  /** Default (zero) value for a type */
  B.defaultValue = function (t) {
    switch (t.code) {
      case 5: return t.k === 'fixstr' ? '\0'.repeat(t.len) : '';
      case 6: return makeRecord(t.def);
      default: return 0;
    }
  };

  // ---- records ----------------------------------------------------------------
  function makeRecord(def) {
    const r = Object.create(null);
    for (const f of def.fields) r[f.name] = B.defaultValue(f.type);
    Object.defineProperty(r, '__def', { value: def, enumerable: false });
    return r;
  }
  B.makeRecord = makeRecord;
  function cloneRecord(src) {
    if (!src || typeof src !== 'object') err(13);
    const def = src.__def;
    const r = Object.create(null);
    for (const f of def.fields) {
      const v = src[f.name];
      r[f.name] = f.type.code === 6 ? cloneRecord(v) : v;
    }
    Object.defineProperty(r, '__def', { value: def, enumerable: false });
    return r;
  }
  B.cloneRecord = cloneRecord;

  /** Serialize a value of type t into bytes (little endian, QBasic layout). */
  B.serialize = function (t, v, out, off) {
    const dv = new DataView(out.buffer, out.byteOffset, out.byteLength);
    switch (t.code) {
      case 1: dv.setInt16(off, v, true); return off + 2;
      case 2: dv.setInt32(off, v, true); return off + 4;
      case 3: dv.setFloat32(off, v, true); return off + 4;
      case 4: dv.setFloat64(off, v, true); return off + 8;
      case 5: {
        const n = t.k === 'fixstr' ? t.len : v.length;
        for (let i = 0; i < n; i++) out[off + i] = i < v.length ? v.charCodeAt(i) & 255 : 32;
        return off + n;
      }
      case 6:
        for (const f of t.def.fields) off = B.serialize(f.type, v[f.name], out, off);
        return off;
    }
    return off;
  };
  B.deserialize = function (t, bytes, off) {
    const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    switch (t.code) {
      case 1: return dv.getInt16(off, true);
      case 2: return dv.getInt32(off, true);
      case 3: return dv.getFloat32(off, true);
      case 4: return dv.getFloat64(off, true);
      case 5: return RC.bytesToStr(bytes, off, off + t.len);
      case 6: {
        const r = makeRecord(t.def);
        for (const f of t.def.fields) { r[f.name] = B.deserialize(f.type, bytes, off); off += f.type.size; }
        return r;
      }
    }
  };

  // ---- arrays -------------------------------------------------------------------
  class BArray {
    constructor(type, dims, dynamic) {
      this.type = type;
      this.dims = dims; // [{lo, hi}]
      this.dynamic = !!dynamic;
      let n = 1;
      this.strides = [];
      for (const d of dims) {
        if (d.hi < d.lo) err(9);
        this.strides.push(n);
        n *= d.hi - d.lo + 1;
      }
      if (n > 16 * 1024 * 1024) err(7);
      this.length = n;
      this.data = BArray.alloc(type, n);
    }
    static alloc(type, n) {
      switch (type.code) {
        case 1: return new Int16Array(n);
        case 2: return new Int32Array(n);
        case 3: return new Float32Array(n);
        case 4: return new Float64Array(n);
        default: {
          const a = new Array(n);
          for (let i = 0; i < n; i++) a[i] = B.defaultValue(type);
          return a;
        }
      }
    }
    /** Flat index for subscripts (column-major, like QBasic). */
    index(subs) {
      const dims = this.dims;
      if (subs.length !== dims.length) err(9);
      let off = 0;
      for (let i = 0; i < subs.length; i++) {
        let s = subs[i];
        if (s !== (s | 0)) s = B.roundEven(s);
        const d = dims[i];
        if (s < d.lo || s > d.hi) err(9);
        off += (s - d.lo) * this.strides[i];
      }
      return off;
    }
    clear() {
      if (this.data instanceof Array) for (let i = 0; i < this.length; i++) this.data[i] = B.defaultValue(this.type);
      else this.data.fill(0);
    }
    /** Byte view of the array's storage (numeric arrays only) starting at a flat element index */
    bytes(fromIndex) {
      if (this.data instanceof Array) err(13);
      const bpe = this.data.BYTES_PER_ELEMENT;
      return new Uint8Array(this.data.buffer, this.data.byteOffset + (fromIndex || 0) * bpe, (this.length - (fromIndex || 0)) * bpe);
    }
  }
  B.BArray = BArray;

  /** A reference to a storage location (container + key). Used for BYREF params, SWAP, etc. */
  class Ref {
    constructor(c, k) { this.c = c; this.k = k; }
    get() { return this.c[this.k]; }
    set(v) { this.c[this.k] = v; }
  }
  B.Ref = Ref;

  // ---- number formatting --------------------------------------------------------
  /**
   * Format a number like QBasic's STR$/PRINT (without the leading sign space).
   * code: 1 int, 2 long, 3 single, 4 double
   */
  function fmtNum(v, code) {
    if (code <= 2 || (Number.isInteger(v) && Math.abs(v) < 1e7 && code === 3) || (Number.isInteger(v) && Math.abs(v) < 1e16 && code === 4)) {
      if (Object.is(v, -0)) return '0';
      return String(v);
    }
    const digits = code === 3 ? 7 : 16;
    const expCh = code === 3 ? 'E' : 'D';
    if (v === 0) return '0';
    const neg = v < 0;
    let a = Math.abs(v);
    let s = a.toPrecision(digits); // may be "1.234560e+7" or "0.0001234560"
    let mant, exp;
    const em = /e([+-]\d+)$/.exec(s);
    // Normalize to digit string + decimal exponent
    let ds, e10;
    if (em) {
      e10 = parseInt(em[1], 10);
      ds = s.slice(0, em.index).replace('.', '');
    } else {
      const dot = s.indexOf('.');
      const ip = dot < 0 ? s : s.slice(0, dot);
      const fp = dot < 0 ? '' : s.slice(dot + 1);
      if (ip !== '0') { e10 = ip.length - 1; ds = ip + fp; }
      else {
        const lz = fp.match(/^0*/)[0].length;
        e10 = -lz - 1;
        ds = fp.slice(lz);
      }
    }
    ds = ds.replace(/0+$/, '');
    if (ds === '') return '0';
    const nd = ds.length;
    let out;
    if (e10 >= 0 && e10 < digits) {
      // fixed with integer part
      if (nd <= e10 + 1) out = ds + '0'.repeat(e10 + 1 - nd);
      else out = ds.slice(0, e10 + 1) + '.' + ds.slice(e10 + 1);
    } else if (e10 < 0 && (-e10 - 1) + nd <= digits) {
      out = '.' + '0'.repeat(-e10 - 1) + ds;
    } else {
      mant = nd > 1 ? ds[0] + '.' + ds.slice(1) : ds;
      exp = e10;
      out = mant + expCh + (exp < 0 ? '-' : '+') + String(Math.abs(exp)).padStart(2, '0');
    }
    return neg ? '-' + out : out;
  }
  B.fmtNum = fmtNum;
  /** STR$ format: leading space for non-negative */
  B.strNum = function (v, code) {
    const s = fmtNum(v, code);
    return s[0] === '-' ? s : ' ' + s;
  };
  /** Guess numeric type code for a raw JS number (used for untyped values) */
  B.numCode = function (v) {
    if (Number.isInteger(v)) return v >= -32768 && v <= 32767 ? 1 : v >= -2147483648 && v <= 2147483647 ? 2 : 4;
    return Math.fround(v) === v ? 3 : 4;
  };

  /** Parse a number from text the way VAL / INPUT do. Returns {v, len} (len = chars consumed). */
  B.parseNumber = function (s) {
    let i = 0;
    const n = s.length;
    const skip = () => { while (i < n && (s[i] === ' ' || s[i] === '\t' || s[i] === '\n')) i++; };
    skip();
    if (s[i] === '&') {
      const c = (s[i + 1] || '').toUpperCase();
      let radix = 8, j = i + 1;
      if (c === 'H') { radix = 16; j++; } else if (c === 'O') j++;
      let ds = '';
      while (j < n) {
        const ch = s[j];
        if (ch === ' ') { j++; continue; }
        if ((radix === 16 ? /[0-9a-f]/i : /[0-7]/).test(ch)) { ds += ch; j++; } else break;
      }
      let v = ds ? parseInt(ds, radix) : 0;
      if (v <= 0xffff && v > 0x7fff) v -= 0x10000;
      else if (v > 0x7fffffff && v <= 0xffffffff) v -= 0x100000000;
      return { v, len: j };
    }
    let txt = '';
    if (s[i] === '+' || s[i] === '-') { txt += s[i]; i++; }
    let sawDigit = false;
    // VAL ignores embedded spaces
    while (i < n) {
      const ch = s[i];
      if (ch >= '0' && ch <= '9') { txt += ch; sawDigit = true; i++; }
      else if (ch === ' ' || ch === '\t') i++;
      else break;
    }
    if (s[i] === '.') {
      txt += '.'; i++;
      while (i < n) {
        const ch = s[i];
        if (ch >= '0' && ch <= '9') { txt += ch; sawDigit = true; i++; }
        else if (ch === ' ' || ch === '\t') i++;
        else break;
      }
    }
    if (sawDigit && i < n && 'EeDd'.includes(s[i])) {
      let j = i + 1;
      let et = 'e';
      while (j < n && s[j] === ' ') j++;
      if (s[j] === '+' || s[j] === '-') { et += s[j]; j++; }
      let ed = '';
      while (j < n && ((s[j] >= '0' && s[j] <= '9') || s[j] === ' ')) { if (s[j] !== ' ') ed += s[j]; j++; }
      if (ed) { txt += et + ed; i = j; } else i = j;
    }
    if (s[i] === '#' || s[i] === '!' || s[i] === '%' || s[i] === '&') i++;
    const v = sawDigit ? parseFloat(txt) : 0;
    return { v: isFinite(v) ? v : (v > 0 ? 1.7976931348623157e308 : -1.7976931348623157e308), len: i, ok: sawDigit };
  };
})(RC);
