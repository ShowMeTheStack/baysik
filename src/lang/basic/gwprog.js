// GW-BASIC style program manipulation: numbered line insert/replace/delete, LIST ranges, RENUM.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const GW = B.GW = {};

  function splitLines(text) { return text.replace(/\r\n?/g, '\n').split('\n'); }
  function lineNum(s) { const m = /^\s*(\d+)/.exec(s); return m ? parseInt(m[1], 10) : null; }

  /** Insert / replace / delete (empty content) a numbered line, keeping numeric order. */
  GW.setLine = function (text, num, content) {
    const lines = text === '' ? [] : splitLines(text);
    if (lines.length && lines[lines.length - 1] === '') lines.pop();
    const idx = lines.findIndex((l) => lineNum(l) === num);
    const newLine = content.trim() === '' ? null : num + ' ' + content.replace(/^\s+/, '');
    if (idx >= 0) {
      if (newLine === null) lines.splice(idx, 1); else lines[idx] = newLine;
    } else if (newLine !== null) {
      let at = lines.length;
      for (let i = 0; i < lines.length; i++) {
        const n = lineNum(lines[i]);
        if (n !== null && n > num) { at = i; break; }
      }
      lines.splice(at, 0, newLine);
    } else return { text, missing: true };
    return { text: lines.join('\n') + (lines.length ? '\n' : '') };
  };

  /** Resolve a range spec {from, to, dash} against the program; returns [lo, hi] line numbers */
  GW.rangeBounds = function (range, cur) {
    if (!range) return [0, 65535];
    let { from, to, dash } = range;
    if (from === '.') from = cur || 0;
    if (to === '.') to = cur || 0;
    if (from === null && !dash) return [0, 65535];
    if (!dash) return [from, from];
    return [from === null ? 0 : from, to === null ? 65535 : to];
  };
  GW.list = function (text, range, cur) {
    const [lo, hi] = GW.rangeBounds(range, cur);
    return splitLines(text).filter((l) => {
      const n = lineNum(l);
      if (n === null) return lo === 0 && hi === 65535 && l.trim() !== '';
      return n >= lo && n <= hi;
    });
  };
  GW.deleteRange = function (text, range, cur) {
    const [lo, hi] = GW.rangeBounds(range, cur);
    let found = false;
    const out = splitLines(text).filter((l) => {
      const n = lineNum(l);
      if (n !== null && n >= lo && n <= hi) { found = true; return false; }
      return true;
    });
    return { text: out.join('\n'), found };
  };
  GW.lineNumbers = function (text) {
    return splitLines(text).map(lineNum).filter((n) => n !== null);
  };
  GW.isNumbered = function (text) {
    const lines = splitLines(text).filter((l) => l.trim() !== '');
    return lines.length > 0 && lines.every((l) => lineNum(l) !== null);
  };

  /**
   * RENUM [new][,[old][,inc]] — renumbers lines >= old starting at `new`, step `inc`, and updates
   * GOTO/GOSUB/THEN/ELSE/RESTORE/RESUME/RUN/ON...GOTO/ERL references.
   * Returns {text, warnings}
   */
  GW.renum = function (text, newStart, oldStart, inc) {
    newStart = newStart == null ? 10 : newStart;
    inc = inc == null ? 10 : inc;
    const lines = splitLines(text);
    const nums = lines.map(lineNum);
    oldStart = oldStart == null ? (nums.find((n) => n !== null) ?? 0) : oldStart;
    const map = new Map();
    let next = newStart;
    let prevKept = -1;
    for (const n of nums) {
      if (n === null) continue;
      if (n < oldStart) { prevKept = n; continue; }
      map.set(n, next);
      next += inc;
    }
    if (next - inc > 65529) throw new Error('Illegal function call (line numbers would exceed 65529)');
    // check overlap with untouched lower lines
    for (const v of map.values()) if (v <= prevKept) throw new Error('Illegal function call (renumbering would reorder lines)');
    const warnings = [];
    const REF_KW = new Set(['GOTO', 'GOSUB', 'THEN', 'ELSE', 'RESTORE', 'RESUME', 'RUN', 'LIST', 'LLIST', 'DELETE', 'EDIT']);
    const out = lines.map((line, li) => {
      if (nums[li] === null) return line;
      const toks = B.lexLine(line, li, '');
      const edits = []; // [start, end, replacement]
      const ln = toks[0];
      if (ln.t === 'lineno' && map.has(ln.v)) edits.push([ln.col, ln.end, String(map.get(ln.v))]);
      let inRefList = false;
      for (let i = 1; i < toks.length; i++) {
        const t = toks[i];
        if (t.t === 'kw' && REF_KW.has(t.v)) { inRefList = true; continue; }
        if (t.t === 'kw' && t.v === 'ERL') {
          // ERL = n  /  ERL <> n ...
          const op = toks[i + 1], num = toks[i + 2];
          if (op && op.t === 'op' && num && num.t === 'num' && map.has(num.v)) edits.push([num.col, num.end, String(map.get(num.v))]);
          continue;
        }
        if (inRefList && t.t === 'num') {
          if (Number.isInteger(t.v) && t.v >= 0) {
            if (map.has(t.v)) edits.push([t.col, t.end, String(map.get(t.v))]);
            else if (!nums.includes(t.v)) warnings.push(`Undefined line ${t.v} in ${map.get(nums[li]) ?? nums[li]}`);
          }
          continue;
        }
        if (inRefList && t.t === 'op' && (t.v === ',' || t.v === '-')) continue;
        inRefList = false;
      }
      edits.sort((a, b) => b[0] - a[0]);
      let s = line;
      for (const [a, b, r] of edits) s = s.slice(0, a) + r + s.slice(b);
      return s;
    });
    // re-sort numbered lines (stable for unnumbered ones kept relative)
    return { text: out.join('\n'), warnings, map };
  };

  /** Next AUTO line number after `n` */
  GW.nextAuto = function (text, start, inc) {
    return start;
  };
})(RC);
