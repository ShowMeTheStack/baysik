// Syntax highlighting and keyword formatting for BASIC, built on the real lexer so the editor
// always agrees with the compiler.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const esc = RC.escapeHtml;

  /** Highlight one source line → HTML */
  B.highlightLine = function (text) {
    if (!text) return '';
    let toks;
    try { toks = B.lexLine(text, 0, ''); } catch (e) { return esc(text); }
    let out = '';
    let pos = 0;
    for (const t of toks) {
      if (t.t === 'eol') break;
      if (t.col > pos) out += esc(text.slice(pos, t.col));
      const raw = text.slice(t.col, t.end);
      let cls = '';
      switch (t.t) {
        case 'kw': cls = B.BUILTIN_FNS[t.v] && !B.SYS_STMTS[t.v] && !STATEMENT_KW.has(t.v) ? 's-fn' : 's-kw'; break;
        case 'num': cls = 's-num'; break;
        case 'str': cls = 's-str'; break;
        case 'rem': cls = t.meta ? 's-meta' : 's-com'; break;
        case 'data': cls = 's-data'; break;
        case 'lineno': cls = 's-ln'; break;
        case 'label': cls = 's-lbl'; break;
        case 'op': cls = 's-op'; break;
        case 'bad': cls = 's-bad'; break;
        case 'id': cls = t.base.startsWith('FN') && t.base.length > 2 ? 's-fn' : ''; break;
      }
      out += cls ? `<span class="${cls}">${esc(raw)}</span>` : esc(raw);
      pos = t.end;
    }
    if (pos < text.length) out += esc(text.slice(pos));
    return out;
  };
  // Keywords that are statements even though a function of the same name exists
  const STATEMENT_KW = new Set(['SCREEN', 'PLAY', 'TIMER', 'PEN', 'STRIG', 'SEEK', 'MID$', 'DATE$', 'TIME$', 'ERROR', 'INPUT', 'LINE']);

  /** Uppercase keywords on a line (QBasic-style auto-format). Returns new text (same length). */
  B.formatLine = function (text) {
    let toks;
    try { toks = B.lexLine(text, 0, ''); } catch (e) { return text; }
    let s = text;
    for (const t of toks) {
      if (t.t === 'kw' && !t.qmark) {
        const raw = s.slice(t.col, t.end);
        if (raw.length === t.v.length && raw !== t.v) s = s.slice(0, t.col) + t.v + s.slice(t.end);
      }
    }
    return s;
  };

  /** Identifier (or keyword) at a column, for hover / F1 help */
  B.wordAt = function (text, col) {
    let toks;
    try { toks = B.lexLine(text, 0, ''); } catch (e) { return null; }
    for (let i = 0; i < toks.length; i++) {
      const t = toks[i];
      if (t.t === 'eol') break;
      if (col >= t.col && col < t.end) {
        if (t.t === 'id') {
          // include array subscript / record member chains for hover evaluation
          let expr = text.slice(t.col, t.end);
          let j = i + 1;
          if (toks[j] && toks[j].t === 'op' && toks[j].v === '(') {
            let depth = 0, k = j;
            for (; k < toks.length; k++) {
              if (toks[k].t === 'op' && toks[k].v === '(') depth++;
              if (toks[k].t === 'op' && toks[k].v === ')') { depth--; if (depth === 0) break; }
              if (toks[k].t === 'eol') break;
            }
            if (depth === 0 && k < toks.length) { expr = text.slice(t.col, toks[k].end); j = k + 1; }
          }
          while (toks[j] && toks[j].t === 'op' && toks[j].v === '.' && toks[j + 1] && toks[j + 1].t === 'id') {
            expr = text.slice(t.col, toks[j + 1].end); j += 2;
          }
          return { kind: 'id', word: t.v, expr, col: t.col, end: t.end };
        }
        if (t.t === 'kw') return { kind: 'kw', word: t.v, col: t.col, end: t.end };
        return null;
      }
    }
    return null;
  };

  /** Outline: SUB/FUNCTION/DEF FN and labels for the procedure navigator */
  B.outline = function (text) {
    const out = [];
    const lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const L = lines[i];
      let m = /^\s*(SUB|FUNCTION)\s+([A-Za-z][\w.]*[%&!#$]?)/i.exec(L);
      if (m) { out.push({ kind: m[1].toUpperCase(), name: m[2], line: i }); continue; }
      m = /^\s*DEF\s*(FN\s*[A-Za-z][\w.]*[%&!#$]?)/i.exec(L);
      if (m) { out.push({ kind: 'DEF', name: m[1].replace(/\s+/g, ''), line: i }); continue; }
      m = /^\s*([A-Za-z][\w.]*):/.exec(L);
      if (m && !B.KEYWORDS.has(m[1].toUpperCase())) out.push({ kind: 'label', name: m[1], line: i });
    }
    return out;
  };
})(RC);
