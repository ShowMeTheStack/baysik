// PRINT USING formatter (QBasic / GW-BASIC semantics).
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const err = B.err;

  class PrintUsing {
    constructor(fmt) {
      if (fmt.length === 0) err(5);
      this.fmt = fmt;
      this.pos = 0;
      this.anyField = false;
    }

    /** Try to parse a field starting at i; returns field descriptor or null. */
    fieldAt(i) {
      const f = this.fmt;
      const c = f[i];
      if (c === '!') return { kind: 's1', start: i, end: i + 1 };
      if (c === '&') return { kind: 'sall', start: i, end: i + 1 };
      if (c === '\\') {
        let j = i + 1;
        while (j < f.length && f[j] === ' ') j++;
        if (f[j] === '\\') return { kind: 'sn', n: j - i + 1, start: i, end: j + 1 };
        return null;
      }
      // numeric
      let j = i;
      const fd = { kind: 'num', start: i, plusLead: false, asterisk: false, dollar: false, intPos: 0, comma: false, point: false, dec: 0, exp: 0, trail: '' };
      if (f[j] === '+') { fd.plusLead = true; j++; }
      if (f.startsWith('**$', j)) { fd.asterisk = true; fd.dollar = true; fd.intPos += 2; j += 3; }
      else if (f.startsWith('**', j)) { fd.asterisk = true; fd.intPos += 2; j += 2; }
      else if (f.startsWith('$$', j)) { fd.dollar = true; fd.intPos += 1; j += 2; }
      let digits = 0;
      while (j < f.length && (f[j] === '#' || (f[j] === ',' && (digits > 0 || fd.intPos > 0)))) {
        if (f[j] === ',') fd.comma = true;
        fd.intPos++;
        if (f[j] === '#') digits++;
        j++;
      }
      if (f[j] === '.' && (digits > 0 || fd.intPos > 0 || f[j + 1] === '#')) {
        fd.point = true;
        j++;
        while (j < f.length && f[j] === '#') { fd.dec++; j++; }
      }
      if (!(digits > 0 || fd.intPos > 0 || fd.dec > 0)) return null;
      if (f.startsWith('^^^^^', j)) { fd.exp = 5; j += 5; }
      else if (f.startsWith('^^^^', j)) { fd.exp = 4; j += 4; }
      if (f[j] === '+' && !fd.plusLead) { fd.trail = '+'; j++; }
      else if (f[j] === '-') { fd.trail = '-'; j++; }
      fd.end = j;
      return fd;
    }

    /** Literal text from current position up to the next field (handles '_' escape). */
    literalToField() {
      let out = '';
      const f = this.fmt;
      while (this.pos < f.length) {
        const c = f[this.pos];
        if (c === '_') {
          if (this.pos + 1 < f.length) out += f[this.pos + 1];
          this.pos += 2;
          continue;
        }
        if (this.fieldAt(this.pos)) break;
        out += c;
        this.pos++;
      }
      return out;
    }

    next(v) {
      let out = '';
      let wrapped = false;
      while (true) {
        out += this.literalToField();
        if (this.pos >= this.fmt.length) {
          if (wrapped || !this.hasAnyField()) err(5);
          this.pos = 0;
          wrapped = true;
          continue;
        }
        break;
      }
      const fd = this.fieldAt(this.pos);
      this.pos = fd.end;
      this.anyField = true;
      if (fd.kind === 'num') {
        if (typeof v !== 'number') err(13);
        out += formatNumber(fd, v);
      } else {
        if (typeof v !== 'string') err(13);
        if (fd.kind === 's1') out += v.length ? v[0] : ' ';
        else if (fd.kind === 'sall') out += v;
        else out += (v + ' '.repeat(fd.n)).slice(0, fd.n);
      }
      return out;
    }

    hasAnyField() {
      for (let i = 0; i < this.fmt.length; i++) {
        if (this.fmt[i] === '_') { i++; continue; }
        if (this.fieldAt(i)) return true;
      }
      return false;
    }

    /** Trailing literal text after the last value (up to next field or end) */
    finish() {
      if (!this.anyField) return this.literalToField();
      if (this.pos >= this.fmt.length) return '';
      return this.literalToField();
    }
  }

  function formatNumber(fd, v) {
    const width = fd.end - fd.start;
    const neg = v < 0;
    let a = Math.abs(v);
    let core;
    if (fd.exp) {
      const signPos = fd.plusLead || fd.trail ? 0 : 1;
      const intSig = Math.max(0, fd.intPos - signPos - (fd.dollar ? 1 : 0));
      let e = 0, m = 0;
      if (a !== 0) {
        e = Math.floor(Math.log10(a)) - (intSig - 1);
        m = a / Math.pow(10, e);
        let r = Number(m.toFixed(fd.dec));
        if (r >= Math.pow(10, Math.max(intSig, 0)) && intSig > 0) { e++; m = a / Math.pow(10, e); r = Number(m.toFixed(fd.dec)); }
        if (intSig === 0) {
          e = Math.floor(Math.log10(a)) + 1;
          m = a / Math.pow(10, e);
        }
      }
      let ms = m.toFixed(fd.dec);
      if (intSig === 0) ms = ms.replace(/^0/, '');
      if (!fd.point) ms = ms.replace(/\.$/, '');
      const ed = fd.exp === 5 ? 3 : 2;
      const es = 'E' + (e < 0 ? '-' : '+') + String(Math.abs(e)).padStart(ed, '0');
      core = (fd.dollar ? '$' : '') + ms + es;
    } else {
      let s = a.toFixed(fd.dec);
      if (Number(s) === 0 && neg) { /* -0.00 prints as -0.00 in QBasic? keep sign */ }
      let [ip, dp] = s.split('.');
      if (fd.comma) ip = ip.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
      // available int positions
      const intRoom = fd.intPos + (fd.plusLead ? 0 : 0);
      core = ip + (fd.point ? '.' + (dp || '') : '');
      const signLen = (neg && !fd.plusLead && !fd.trail) ? 1 : 0;
      if (ip === '0' && fd.point && (ip.length + signLen + (fd.dollar ? 1 : 0)) > intRoom) core = '.' + (dp || '');
      core = (fd.dollar ? '$' : '') + core;
    }
    // sign handling
    if (fd.plusLead) core = (neg ? '-' : '+') + core;
    else if (!fd.trail && neg) core = '-' + core;
    if (fd.trail === '+') core += neg ? '-' : '+';
    else if (fd.trail === '-') core += neg ? '-' : ' ';
    if (core.length > width) return '%' + core;
    const pad = width - core.length;
    if (fd.asterisk) return '*'.repeat(pad) + core;
    return ' '.repeat(pad) + core;
  }

  B.PrintUsing = PrintUsing;
  B.formatUsingNumber = formatNumber;
})(RC);
