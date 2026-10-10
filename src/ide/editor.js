// Code editor: transparent <textarea> over a syntax-highlighted <pre>, with a gutter for
// line numbers, breakpoints and execution markers.
(function (RC) {
  'use strict';
  const { h } = RC.UI;

  class Editor extends RC.Emitter {
    /**
     * @param parent element
     * @param opts {lang: {highlightLine, formatLine, wordAt}, settings}
     */
    constructor(parent, opts) {
      super();
      this.opts = opts || {};
      this.lang = this.opts.lang;
      this.inner = h('div.ed-gutter-inner');
      this.gutter = h('div.ed-gutter', { 'aria-hidden': 'true' }, this.inner);
      this.hl = h('pre.ed-hl', { 'aria-hidden': 'true' });
      this.ta = h('textarea.ed-ta', { spellcheck: 'false', autocapitalize: 'off', autocomplete: 'off', autocorrect: 'off', wrap: 'off', 'aria-label': 'Code editor', 'data-gramm': 'false' });
      this.main = h('div.ed-main', this.hl, this.ta);
      this.root = h('div.ed', this.gutter, this.main);
      parent.appendChild(this.root);
      this.cache = new Map();
      this.marks = { exec: null, frame: null, err: null, bps: new Map(), flash: null };
      this.curLine = 0;
      this.lastLineCount = 1;
      this.renderPending = false;
      this.tip = null;
      this.bind();
      this.setValue('');
    }

    // ---- value -------------------------------------------------------------------------------
    getValue() { return this.ta.value; }
    setValue(text) {
      this.ta.value = text;
      this.lastLineCount = this.lineCount();
      this.render();
      this.dirty = false;
    }
    lineCount() { let n = 1; const v = this.ta.value; for (let i = 0; i < v.length; i++) if (v.charCodeAt(i) === 10) n++; return n; }
    lines() { return this.ta.value.split('\n'); }
    getLine(i) { return this.lines()[i] || ''; }

    // ---- events ---------------------------------------------------------------------------------
    bind() {
      const ta = this.ta;
      ta.addEventListener('input', () => {
        const n = this.lineCount();
        if (n !== this.lastLineCount) this.shiftMarks(this.prevCursorLine === undefined ? this.curLine : this.prevCursorLine, n - this.lastLineCount);
        this.lastLineCount = n;
        this.dirty = true;
        this.scheduleRender();
        this.emit('change');
        this.updateCursor();
      });
      ta.addEventListener('scroll', () => this.syncScroll());
      ta.addEventListener('keydown', (e) => this.onKey(e));
      ta.addEventListener('keyup', () => this.updateCursor());
      ta.addEventListener('mouseup', () => this.updateCursor());
      ta.addEventListener('focus', () => { this.emit('focus'); this.updateCursor(); });
      ta.addEventListener('blur', () => this.formatLine(this.curLine));
      document.addEventListener('selectionchange', () => { if (document.activeElement === ta) this.updateCursor(); });
      this.gutter.addEventListener('mousedown', (e) => {
        e.preventDefault();
        if (e.button !== 0) return; // right-click opens the context menu only
        const line = this.lineAtY(e.clientY);
        if (line >= 0 && line < this.lineCount()) this.emit('gutter', line, e);
      });
      this.gutter.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        const line = this.lineAtY(e.clientY);
        this.emit('gutterContext', line, e);
      });
      ta.addEventListener('contextmenu', (e) => {
        const pos = this.posAt(e.clientX, e.clientY);
        this.emit('context', pos, e);
      });
      // Hover: after the mouse rests ~300ms over a word, emit 'hover'; any movement emits 'hoverOut'
      // so a sticky callout can start its grace-period timer (and cancel it if the mouse enters it).
      let hoverTimer = null;
      ta.addEventListener('mousemove', (e) => {
        clearTimeout(hoverTimer);
        this.hideTip();
        this.emit('hoverOut');
        hoverTimer = setTimeout(() => {
          const pos = this.posAt(e.clientX, e.clientY);
          if (pos) this.emit('hover', pos, e.clientX, e.clientY);
        }, 300);
      });
      ta.addEventListener('mouseleave', () => { clearTimeout(hoverTimer); this.hideTip(); this.emit('hoverOut'); });
      // Touch devices have no hover: a tap on a word acts like hovering it
      ta.addEventListener('pointerup', (e) => {
        if (e.pointerType !== 'touch' && e.pointerType !== 'pen') return;
        if (ta.selectionStart !== ta.selectionEnd) return;
        const pos = this.posAt(e.clientX, e.clientY);
        if (pos) setTimeout(() => this.emit('hover', pos, e.clientX, e.clientY, true), 0);
      });
      this.ro = typeof ResizeObserver !== 'undefined' ? new ResizeObserver(() => this.syncScroll()) : null;
      if (this.ro) this.ro.observe(this.main);
    }

    get lineHeight() {
      const fs = parseFloat(getComputedStyle(this.root).fontSize) || 15;
      return fs * 1.45;
    }
    get charWidth() {
      if (!this._cw || this._cwFont !== this.root.style.fontSize + getComputedStyle(this.root).fontSize) {
        const probe = h('span', { style: { position: 'absolute', visibility: 'hidden', whiteSpace: 'pre', font: 'inherit' } }, 'M'.repeat(50));
        this.hl.appendChild(probe);
        this._cw = probe.getBoundingClientRect().width / 50;
        probe.remove();
        this._cwFont = this.root.style.fontSize + getComputedStyle(this.root).fontSize;
      }
      return this._cw || 9;
    }
    lineAtY(clientY) {
      const r = this.main.getBoundingClientRect();
      return Math.floor((clientY - r.top + this.ta.scrollTop) / this.lineHeight);
    }
    posAt(clientX, clientY) {
      const r = this.ta.getBoundingClientRect();
      const line = Math.floor((clientY - r.top + this.ta.scrollTop) / this.lineHeight);
      const col = Math.floor((clientX - r.left - 8 + this.ta.scrollLeft) / this.charWidth);
      if (line < 0 || line >= this.lineCount() || col < 0) return null;
      const text = this.getLine(line);
      if (col >= text.length) return null;
      return { line, col, text };
    }

    onKey(e) {
      const ta = this.ta;
      const mod = e.ctrlKey || e.metaKey;
      if (e.key === 'Tab' && !mod && !e.altKey) {
        e.preventDefault();
        if (e.shiftKey) this.indentSelection(-1);
        else if (ta.selectionStart !== ta.selectionEnd && this.getValue().slice(ta.selectionStart, ta.selectionEnd).includes('\n')) this.indentSelection(1);
        else this.insert(' '.repeat(this.tabSize()));
        return;
      }
      if (e.key === 'Enter' && !mod && !e.altKey) {
        e.preventDefault();
        const { line } = this.cursor();
        const text = this.getLine(line);
        const indent = /^\s*/.exec(text)[0];
        let extra = '';
        if (this.opts.settings && this.opts.settings.autoIndent !== false && this.lang && this.lang.indentAfter && this.lang.indentAfter(text)) extra = ' '.repeat(this.tabSize());
        this.prevCursorLine = line;
        this.insert('\n' + indent.slice(0, ta.selectionStart - this.lineStart(line)) + extra);
        this.prevCursorLine = undefined;
        this.formatLine(line);
        return;
      }
      if (mod && !e.shiftKey && (e.key === '/' || e.code === 'Slash')) { e.preventDefault(); this.toggleComment(); return; }
      if (mod && (e.key === 'f' || e.key === 'F') && !e.shiftKey) { e.preventDefault(); this.emit('find', false); return; }
      if (mod && (e.key === 'h' || e.key === 'H')) { e.preventDefault(); this.emit('find', true); return; }
      if (mod && (e.key === 'g' || e.key === 'G')) { e.preventDefault(); this.emit('gotoLine'); return; }
      if (mod && (e.key === 'd' || e.key === 'D')) { e.preventDefault(); this.duplicateLine(); return; }
      if (e.key === 'F1') { e.preventDefault(); const c = this.cursor(); this.emit('help', this.getLine(c.line), c.col); return; }
      if (e.key === 'Home' && !e.shiftKey && !mod) {
        // smart home
        const c = this.cursor();
        const text = this.getLine(c.line);
        const ind = /^\s*/.exec(text)[0].length;
        const target = c.col === ind ? 0 : ind;
        e.preventDefault();
        const p = this.lineStart(c.line) + target;
        ta.setSelectionRange(p, p);
        this.updateCursor();
      }
    }
    tabSize() { return (this.opts.settings && this.opts.settings.tabSize) || 4; }

    // ---- editing helpers (undo-friendly) -------------------------------------------------------------
    insert(text) {
      this.ta.focus();
      // execCommand keeps native undo but is very slow for big blocks; large edits use setRangeText
      const big = text.length > 20000 || (this.ta.selectionEnd - this.ta.selectionStart) > 20000;
      if (big || !document.execCommand('insertText', false, text)) {
        const ta = this.ta;
        const s = ta.selectionStart, en = ta.selectionEnd;
        ta.setRangeText(text, s, en, 'end');
        ta.dispatchEvent(new Event('input'));
      }
    }
    replaceRange(start, end, text) {
      const ta = this.ta;
      const ss = ta.selectionStart, se = ta.selectionEnd;
      ta.setSelectionRange(start, end);
      this.insert(text);
      const delta = text.length - (end - start);
      const adj = (p) => (p > end ? p + delta : p > start ? Math.min(p, start + text.length) : p);
      ta.setSelectionRange(adj(ss), adj(se));
    }
    lineStart(line) {
      const v = this.ta.value;
      let p = 0;
      for (let i = 0; i < line; i++) { const n = v.indexOf('\n', p); if (n < 0) return v.length; p = n + 1; }
      return p;
    }
    cursor() {
      const p = this.ta.selectionStart;
      const before = this.ta.value.slice(0, p);
      const line = before.split('\n').length - 1;
      const col = p - (before.lastIndexOf('\n') + 1);
      return { line, col };
    }
    setCursor(line, col, select) {
      const s = this.lineStart(line) + (col || 0);
      const e = select ? s + select : s;
      this.ta.focus({ preventScroll: true });
      this.ta.setSelectionRange(s, e);
      this.revealLine(line);
      this.updateCursor();
    }
    updateCursor() {
      const c = this.cursor();
      if (c.line !== this.curLine) {
        const old = this.curLine;
        this.curLine = c.line;
        if (old < this.lineCount()) this.formatLine(old);
        this.scheduleRender();
      }
      this.emit('cursor', c);
    }
    formatLine(line) {
      if (!this.lang || !this.lang.formatLine || !(this.opts.settings && this.opts.settings.autoFormat)) return;
      const text = this.getLine(line);
      const f = this.lang.formatLine(text);
      if (f !== text && f.length === text.length) {
        const st = this.lineStart(line);
        // replace differing span only, to keep undo granular and caret stable
        let a = 0; while (a < text.length && text[a] === f[a]) a++;
        let b = text.length; while (b > a && text[b - 1] === f[b - 1]) b--;
        const active = document.activeElement === this.ta;
        this.replaceRange(st + a, st + b, f.slice(a, b));
        if (!active) this.ta.blur();
      }
    }
    formatAll() {
      if (!this.lang || !this.lang.formatLine) return;
      const lines = this.lines();
      const out = lines.map((l) => this.lang.formatLine(l));
      if (out.join('\n') !== lines.join('\n')) {
        this.ta.focus();
        this.ta.setSelectionRange(0, this.ta.value.length);
        this.insert(out.join('\n'));
      }
    }
    indentSelection(dir) {
      const ta = this.ta;
      const v = ta.value;
      const s = ta.selectionStart, e = ta.selectionEnd;
      const ls = v.lastIndexOf('\n', s - 1) + 1;
      let le = v.indexOf('\n', e - (e > s && v[e - 1] === '\n' ? 1 : 0));
      if (le < 0) le = v.length;
      const block = v.slice(ls, le);
      const tab = ' '.repeat(this.tabSize());
      const nb = block.split('\n').map((l) => (dir > 0 ? (l.length ? tab + l : l) : l.replace(new RegExp('^ {1,' + this.tabSize() + '}'), ''))).join('\n');
      ta.setSelectionRange(ls, le);
      this.insert(nb);
      ta.setSelectionRange(ls, ls + nb.length);
    }
    toggleComment() {
      const ta = this.ta;
      const v = ta.value;
      const s = ta.selectionStart, e = ta.selectionEnd;
      const ls = v.lastIndexOf('\n', s - 1) + 1;
      let le = v.indexOf('\n', Math.max(s, e - 1));
      if (le < 0) le = v.length;
      const lines = v.slice(ls, le).split('\n');
      const all = lines.every((l) => /^\s*'/.test(l) || !l.trim());
      const nb = lines.map((l) => (!l.trim() ? l : all ? l.replace(/^(\s*)' ?/, '$1') : l.replace(/^(\s*)/, "$1' "))).join('\n');
      ta.setSelectionRange(ls, le);
      this.insert(nb);
      ta.setSelectionRange(ls, ls + nb.length);
    }
    duplicateLine() {
      const c = this.cursor();
      const text = this.getLine(c.line);
      const end = this.lineStart(c.line) + text.length;
      this.ta.setSelectionRange(end, end);
      this.insert('\n' + text);
    }

    // ---- markers ---------------------------------------------------------------------------------------
    shiftMarks(atLine, delta) {
      if (!delta) return;
      const nb = new Map();
      for (const [l, v] of this.marks.bps) {
        if (l > atLine) { const nl = l + delta; if (nl > atLine || delta > 0) nb.set(Math.max(atLine + 1, nl), v); }
        else nb.set(l, v);
      }
      this.marks.bps = nb;
      this.marks.err = null;
      this.emit('bpsShifted', nb);
    }
    setBreakpoints(map) { this.marks.bps = new Map(map); this.scheduleRender(); }
    setExec(line) { this.marks.exec = line; this.scheduleRender(); if (line !== null) this.revealLine(line); }
    setFrame(line) { this.marks.frame = line; this.scheduleRender(); if (line !== null) this.revealLine(line); }
    setError(line) { this.marks.err = line; this.scheduleRender(); if (line !== null) this.revealLine(line); }
    flashLine(line) { this.marks.flash = line; this.scheduleRender(); setTimeout(() => { if (this.marks.flash === line) { this.marks.flash = null; this.scheduleRender(); } }, 1000); }
    revealLine(line) {
      const lh = this.lineHeight;
      const top = line * lh;
      const ta = this.ta;
      const hgt = ta.clientHeight;
      if (top < ta.scrollTop + lh || top > ta.scrollTop + hgt - 3 * lh) ta.scrollTop = Math.max(0, top - hgt / 3);
      this.syncScroll();
    }

    // ---- tooltips ----------------------------------------------------------------------------------------
    showTip(text, x, y) {
      this.hideTip();
      this.tip = h('div.ed-tip', text);
      document.body.appendChild(this.tip);
      const w = this.tip.offsetWidth;
      this.tip.style.left = Math.min(x + 12, window.innerWidth - w - 8) + 'px';
      this.tip.style.top = (y + 16) + 'px';
    }
    hideTip() { if (this.tip) { this.tip.remove(); this.tip = null; } }

    // ---- rendering -----------------------------------------------------------------------------------------
    scheduleRender() {
      if (this.renderPending) return;
      this.renderPending = true;
      requestAnimationFrame(() => { this.renderPending = false; this.render(); });
    }
    render() {
      const lines = this.ta.value.split('\n');
      const hlFn = this.lang && this.lang.highlightLine;
      const m = this.marks;
      const cache = this.cache;
      let html = '';
      let g = '';
      const focused = document.activeElement === this.ta;
      for (let i = 0; i < lines.length; i++) {
        const t = lines[i];
        let hl = cache.get(t);
        if (hl === undefined) {
          hl = hlFn ? hlFn(t) : RC.escapeHtml(t);
          if (cache.size > 20000) cache.clear();
          cache.set(t, hl);
        }
        let cls = 'ed-line';
        let gcls = 'ed-gl';
        const bp = m.bps.get(i);
        if (bp) { cls += ' bpline'; gcls += ' bp' + (bp.cond ? ' cond' : '') + (bp.disabled ? ' disabled' : ''); }
        if (m.exec === i) { cls += ' exec'; gcls += ' exec'; }
        else if (m.frame === i) { cls += ' frame'; gcls += ' frame'; }
        if (m.err === i) { cls += ' errline'; gcls += ' err'; }
        if (m.flash === i) cls += ' flash';
        if (i === this.curLine && focused && m.exec !== i) cls += ' curline';
        html += '<span class="' + cls + '">' + (hl || ' ') + '</span>';
        g += '<div class="' + gcls + '">' + (i + 1) + '</div>';
      }
      this.hl.innerHTML = html;
      this.inner.innerHTML = g;
      const digits = String(lines.length).length;
      this.gutter.style.width = (Math.max(3, digits) * 0.6 + 2.6) + 'em';
      this.syncScroll();
    }
    syncScroll() {
      this.hl.scrollTop = this.ta.scrollTop;
      this.hl.scrollLeft = this.ta.scrollLeft;
      this.inner.style.transform = 'translateY(' + (-this.ta.scrollTop) + 'px)';
    }
    focus() { this.ta.focus(); }
    show(v) { this.root.style.display = v ? '' : 'none'; if (v) { this.render(); } }
    destroy() { if (this.ro) this.ro.disconnect(); this.root.remove(); this.hideTip(); }

    // ---- find / replace ------------------------------------------------------------------------------------
    find(query, opts, fromPos, backwards) {
      if (!query) return null;
      const v = this.ta.value;
      let re;
      try {
        re = new RegExp(opts.regex ? query : query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g' + (opts.matchCase ? '' : 'i'));
      } catch (e) { return null; }
      const matches = [];
      let m;
      while ((m = re.exec(v)) && matches.length < 100000) { matches.push([m.index, m.index + m[0].length]); if (!m[0].length) re.lastIndex++; }
      if (!matches.length) return { count: 0 };
      let idx;
      if (backwards) { idx = -1; for (let i = matches.length - 1; i >= 0; i--) if (matches[i][0] < fromPos) { idx = i; break; } if (idx < 0) idx = matches.length - 1; }
      else { idx = matches.findIndex((x) => x[0] >= fromPos); if (idx < 0) idx = 0; }
      const [s, e] = matches[idx];
      this.ta.focus({ preventScroll: true });
      this.ta.setSelectionRange(s, e);
      const line = v.slice(0, s).split('\n').length - 1;
      this.revealLine(line);
      this.updateCursor();
      return { count: matches.length, index: idx + 1 };
    }
    replaceAll(query, repl, opts) {
      let re;
      try { re = new RegExp(opts.regex ? query : query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g' + (opts.matchCase ? '' : 'i')); } catch (e) { return 0; }
      const v = this.ta.value;
      let n = 0;
      const nv = v.replace(re, (...a) => { n++; return opts.regex ? a[0].replace(new RegExp(re.source, re.flags.replace('g', '')), repl) : repl; });
      if (n) { this.ta.focus(); this.ta.setSelectionRange(0, v.length); this.insert(nv); }
      return n;
    }
  }

  RC.Editor = Editor;
})(RC);
