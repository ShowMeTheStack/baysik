// GW-BASIC classic console: direct mode with full-screen editing on the emulated screen.
// Typing a numbered line stores it in the program; anything else runs immediately.
(function (RC) {
  'use strict';
  const B = RC.Basic;

  /** Map compiler messages to the terse GW-BASIC wording */
  function gwMessage(m) {
    if (/^Expected|not valid|^Subprogram not defined|^Label not defined/.test(m)) return 'Syntax error';
    return m;
  }

  class GwConsole {
    constructor(app) {
      this.app = app;
      this.active = false;
      this.insert = false;
      this.cont = []; // row continuation flags (logical lines spanning rows)
      this.auto = null;
      this.docPath = null;
    }
    get d() { return this.app.runner.display; }
    /** Soft-key texts are shared with programs, so KEY n,"..." changes what F1..F10 type */
    get softKeys() { const r = this.runner; return r.softKeys || (r.softKeys = r.makeHost().softKeys); }
    get runner() { return this.app.runner; }

    doc() {
      let d = this.docPath ? this.app.docByPath(this.docPath) : null;
      if (!d) {
        const a = this.app.active;
        if (a && (a.editor.getValue().trim() === '' || B.GW.isNumbered(a.editor.getValue()))) d = a;
        else {
          const vfs = this.app.vfs;
          if (!vfs.exists('C:\\GW')) vfs.mkdir('C:\\GW');
          let p = 'C:\\GW\\PROGRAM.BAS';
          d = this.app.openFile(p, { noFocus: true }) || this.app.docByPath(p);
        }
        this.docPath = d.path;
      }
      return d;
    }
    text() { return this.doc().editor.getValue(); }
    setText(t) {
      const d = this.doc();
      const ed = d.editor;
      const top = ed.ta.scrollTop;
      ed.setValue(t);
      ed.ta.scrollTop = top;
      d.dirty = t !== d.savedText;
      this.app.renderTabs();
    }

    /** Turn the console on or off. Returns a promise (entering may ask which program to use). */
    async toggle(on, opts) {
      opts = opts || {};
      if (on === undefined) on = !this.active;
      if (on === this.active) return;
      const app = this.app;
      const d = this.d;
      if (on) {
        // the console works on the program that is open, so RUN and F5 run what you see;
        // a program without line numbers is used only if you say so
        this.prevPath = app.active ? app.active.path : null;
        this.docPath = null;
        const a = app.active;
        const text = a ? a.editor.getValue() : '';
        if (a && text.trim() !== '' && !B.GW.isNumbered(text) && opts.ask) {
          const r = await RC.UI.modal({
            title: 'GW-BASIC console',
            body: RC.UI.h('div', RC.UI.h('p', a.name + ' has no line numbers.'), RC.UI.h('p', 'The console can still LIST and RUN it, but typing numbered lines and RENUM work best with a numbered program. Which program should the console use?')),
            buttons: [{ label: 'Cancel', value: null }, { label: 'A new program', value: 'new' }, { label: 'Use ' + a.name, value: 'use', primary: true }],
            cancelValue: null,
          });
          if (!r) return;
          if (r === 'use') this.docPath = a.path;
        } else if (a && (text.trim() === '' || B.GW.isNumbered(text))) this.docPath = a.path;
        this.active = true;
        this.runner.stop(true);
        app.activate(this.doc());
        this.cdToProgram();
        d.screen(0, undefined, 0, 0, true);
        d.width(80, 25);
        d.color(7, 0);
        d.cls(0);
        d.setKeyLine(true, this.softKeys);
        this.cont = [];
        this.print('Baysik GW-BASIC compatible console');
        this.print('Type a numbered line to add it to the program; LIST, RUN, NEW, LOAD "x", SAVE "x",');
        this.print('FILES, AUTO, RENUM, EDIT n, CONT and SYSTEM (to leave) work as in GW-BASIC.');
        this.print(String(60300 - this.text().length) + ' Bytes free');
        this.ok();
        app.el('screenTitle').textContent = 'GW-BASIC Console';
        app.el('screen').focus();
        app.setStatus('GW-BASIC console on ' + this.doc().name + '. Click the screen and type; RUN, F2 or the Run button runs it (F1-F10 are the GW-BASIC soft keys here). SYSTEM or the console button leaves.');
      } else {
        this.active = false;
        this.runner.stop(true);
        d.setKeyLine(false);
        this.auto = null;
        app.el('screenTitle').textContent = 'Output';
        // back to the normal screen (unless a program ended with SYSTEM: keep its output)
        if (!opts.keepScreen) app.welcomeScreen();
        const prev = this.prevPath && app.docByPath(this.prevPath);
        if (prev && prev !== app.active) app.activate(prev);
        app.setStatus('Left GW-BASIC console');
      }
      app.updateUI();
    }

    // ---- screen output helpers -------------------------------------------------------------------
    print(s, noNl) {
      const d = this.d;
      d.printString(RC.toCP437(s));
      if (!noNl) d.newline();
      this.cont[d.cursorRow()] = false;
    }
    ok() {
      if (!this.active) return;
      const d = this.d;
      if (d.mode !== 0 && !this.keepMode) { /* GW keeps graphics mode; text prints in mode */ }
      if (d.cursorCol() !== 0) d.newline();
      this.print('Ok');
      if (this.auto) this.autoPrompt();
    }
    err(msg) {
      const d = this.d;
      if (d.cursorCol() !== 0) d.newline();
      this.print(msg);
    }

    // ---- key handling ---------------------------------------------------------------------------------
    keyDown(e) {
      const kb = this.runner.keyboard;
      const scan = RC.Keyboard.SCAN[e.code] || 0;
      if (e.ctrlKey && (e.key === 'c' || e.key === 'C' || e.code === 'Pause' || e.code === 'ScrollLock')) { this.breakKey(); return true; }
      if (e.altKey && !e.ctrlKey) return false; // Alt+letter opens IDE menus
      const k = kb.translate(e, scan);
      if (k === null || k === undefined) return !!scan;
      this.handleKey(k);
      return true;
    }
    paste(text) { for (const ch of RC.toCP437(text.replace(/\r\n?/g, '\n'))) this.handleKey(ch === '\n' ? '\r' : ch); }
    breakKey() {
      if (this.auto) { this.auto = null; this.d.newline(); this.print('Ok'); return; }
      this.d.newline();
      this.ok();
    }
    handleKey(k) {
      const d = this.d;
      const cols = d.textCols();
      const bottom = d.viewBottom;
      if (k.length === 2 && k[0] === '\0') {
        const sc = k.charCodeAt(1);
        switch (sc) {
          case 72: if (d.row > d.viewTop) d.setCursor(d.row - 1, d.col); return; // up
          case 80: if (d.row < bottom) d.setCursor(d.row + 1, d.col); return; // down
          case 75: if (d.col > 0) d.setCursor(d.row, d.col - 1); else if (d.row > d.viewTop) d.setCursor(d.row - 1, cols - 1); return;
          case 77: if (d.col < cols - 1) d.setCursor(d.row, d.col + 1); else if (d.row < bottom) d.setCursor(d.row + 1, 0); return;
          case 71: d.setCursor(d.viewTop, 0); return; // Home
          case 119: d.cls(0); this.cont = []; return; // Ctrl+Home
          case 79: { // End: end of logical line
            const { endRow } = this.logicalBounds(d.row);
            const t = this.rowText(endRow).replace(/\s+$/, '');
            d.setCursor(endRow, Math.min(cols - 1, t.length));
            return;
          }
          case 117: { // Ctrl+End: erase to end of line
            this.eraseFrom(d.row, d.col);
            return;
          }
          case 82: this.insert = !this.insert; return; // Ins
          case 83: this.deleteAt(d.row, d.col); return; // Del
          case 115: this.wordLeft(); return;
          case 116: this.wordRight(); return;
        }
        if (sc >= 59 && sc <= 68) { this.typeText(this.softKeys[sc - 59] || ''); return; }
        return;
      }
      const c = k.charCodeAt(0);
      if (k === '\r') { this.enter(); return; }
      if (k === '\b') {
        if (d.col > 0) { d.setCursor(d.row, d.col - 1); this.deleteAt(d.row, d.col); }
        else if (d.row > d.viewTop && this.cont[d.row]) { d.setCursor(d.row - 1, cols - 1); this.deleteAt(d.row, d.col); }
        return;
      }
      if (k === '\x1b') { // erase logical line
        const { startRow, endRow } = this.logicalBounds(d.row);
        for (let r = startRow; r <= endRow; r++) this.clearRow(r);
        d.setCursor(startRow, 0);
        return;
      }
      if (k === '\t') { const n = 8 - (d.col % 8); for (let i = 0; i < n; i++) this.putChar(32); return; }
      if (c === 12) { d.cls(0); this.cont = []; return; } // Ctrl+L
      if (c === 5) { this.eraseFrom(d.row, d.col); return; } // Ctrl+E
      if (c < 32) return;
      this.putChar(c);
    }
    typeText(s) { for (const ch of s) this.handleKey(ch); }
    putChar(c) {
      const d = this.d;
      const cols = d.textCols();
      const attr = d.textAttr();
      if (this.insert) {
        // shift rest of the row right
        const p = d.pages[d.apage];
        const base = d.row * cols;
        for (let i = cols - 1; i > d.col; i--) { p.chars[base + i] = p.chars[base + i - 1]; p.attrs[base + i] = p.attrs[base + i - 1]; }
      }
      d.setCell(d.apage, d.row, d.col, c, attr);
      if (d.col < cols - 1) d.setCursor(d.row, d.col + 1);
      else {
        // wrap to a continuation row
        if (d.row >= d.viewBottom) { d.scrollUp(); this.cont.shift(); d.setCursor(d.viewBottom, 0); }
        else d.setCursor(d.row + 1, 0);
        this.cont[d.row] = true;
      }
      d.dirty = true;
    }
    deleteAt(r, c) {
      const d = this.d;
      const cols = d.textCols();
      const p = d.pages[d.apage];
      const base = r * cols;
      for (let i = c; i < cols - 1; i++) { p.chars[base + i] = p.chars[base + i + 1]; p.attrs[base + i] = p.attrs[base + i + 1]; }
      p.chars[base + cols - 1] = 32;
      d.dirty = true;
    }
    eraseFrom(r, c) {
      const d = this.d;
      const p = d.pages[d.apage];
      const cols = d.textCols();
      p.chars.fill(32, r * cols + c, (r + 1) * cols);
      d.dirty = true;
    }
    clearRow(r) { this.eraseFrom(r, 0); this.cont[r] = false; }
    wordLeft() {
      const d = this.d;
      const t = this.rowText(d.row);
      let c = d.col - 1;
      while (c > 0 && t[c] === ' ') c--;
      while (c > 0 && t[c - 1] !== ' ') c--;
      d.setCursor(d.row, Math.max(0, c));
    }
    wordRight() {
      const d = this.d;
      const t = this.rowText(d.row);
      let c = d.col;
      while (c < t.length && t[c] !== ' ') c++;
      while (c < t.length && t[c] === ' ') c++;
      d.setCursor(d.row, Math.min(d.textCols() - 1, c));
    }
    rowText(r) {
      const d = this.d;
      const p = d.pages[d.apage];
      const cols = d.textCols();
      return RC.bytesToStr(p.chars, r * cols, (r + 1) * cols);
    }
    logicalBounds(row) {
      let s = row, e = row;
      while (s > 0 && this.cont[s]) s--;
      while (e + 1 < this.d.textRows() && this.cont[e + 1]) e++;
      return { startRow: s, endRow: e };
    }
    readLogicalLine(row) {
      const { startRow, endRow } = this.logicalBounds(row);
      let s = '';
      for (let r = startRow; r <= endRow; r++) s += this.rowText(r);
      return { text: RC.fromCP437(s.replace(/\s+$/, ''), false), endRow };
    }

    enter() {
      const d = this.d;
      const { text, endRow } = this.readLogicalLine(d.row);
      d.setCursor(endRow, 0);
      d.newline();
      this.cont[d.cursorRow()] = false;
      this.processLine(text);
    }

    // ---- command processing ------------------------------------------------------------------------------------
    processLine(raw) {
      let line = raw.replace(/^\s+/, '');
      if (this.auto) {
        const m = /^(\d+)\*?\s?(.*)$/.exec(line);
        if (m && +m[1] === this.auto.n) {
          if (m[2].trim() !== '') this.storeLine(+m[1], m[2]);
          this.auto.n += this.auto.inc;
          this.autoPrompt();
          return;
        }
        if (!line.trim()) { this.auto.n += this.auto.inc; this.autoPrompt(); return; }
        this.auto = null;
      }
      if (!line.trim()) return;
      // Numbered program line
      const m = /^(\d+)(.*)$/.exec(line);
      if (m) {
        const n = +m[1];
        if (n > 65529) { this.err('Syntax error'); this.ok(); return; }
        const rest = m[2].replace(/^ /, '');
        if (rest.trim() === '') {
          const r = B.GW.setLine(this.text(), n, '');
          if (r.missing) { this.err('Undefined line number'); this.ok(); return; }
          this.setText(r.text);
        } else this.storeLine(n, rest);
        return; // GW prints no Ok after storing a line
      }
      try {
        if (this.command(line)) return;
      } catch (e) {
        this.err(e instanceof B.CompileError ? gwMessage(e.message) : (e.message || String(e)));
        this.ok();
        return;
      }
    }
    storeLine(n, rest) {
      const r = B.GW.setLine(this.text(), n, rest);
      this.setText(r.text);
    }
    autoPrompt() {
      const exists = B.GW.lineNumbers(this.text()).includes(this.auto.n);
      this.print(String(this.auto.n) + (exists ? '*' : ' '), true);
    }

    /** Returns true when the command handled printing "Ok" (or will, asynchronously) */
    command(line) {
      const toks = B.lexLine(line, 0, '<direct>', true);
      const t0 = toks[0];
      const kw = t0.t === 'kw' ? t0.v : t0.t === 'id' ? t0.v : '';
      const rest = line.slice(t0.end).trim();
      const parsed = () => {
        const st = B.parse(line, '<direct>', { noLineNumbers: true });
        return st.find((s) => s.k === 'CMD' || s.k === 'RUN') || null;
      };
      const strArg = () => { const m = /^"([^"]*)"?/.exec(rest); if (!m) throw new Error('Syntax error'); return m[1]; };
      switch (kw) {
        case 'LIST': case 'LLIST': {
          const st = parsed();
          const lines = B.GW.list(this.text(), st.range, this.lastLine);
          for (const l of lines) { if (kw === 'LLIST') this.app.printerLine(l); else this.print(l); }
          if (lines.length) this.lastLine = parseInt(lines[lines.length - 1], 10) || this.lastLine;
          this.ok();
          return true;
        }
        case 'NEW': this.setText(''); this.runner.vm = null; this.ok(); return true;
        case 'RUN': {
          const st = parsed();
          if (st && st.file) {
            const name = strArg();
            const path = this.runner.resolveProgramFile(name);
            if (!path) { this.err('File not found'); this.ok(); return true; }
            this.loadFile(path);
          }
          this.runProgram(st && st.line !== undefined ? st.line : null);
          return true;
        }
        case 'CONT': {
          const vm = this.runner.vm;
          if (!vm || vm.state !== 'paused' || (this.runner.startText !== undefined && this.runner.startText !== this.text())) { this.err("Can't continue"); this.ok(); return true; }
          this.app.continue();
          return true;
        }
        case 'LOAD': {
          const name = strArg();
          const path = this.runner.resolveProgramFile(name);
          if (!path) { this.err('File not found'); this.ok(); return true; }
          this.loadFile(path);
          if (/,\s*R\s*$/i.test(rest)) { this.runProgram(); return true; }
          this.ok();
          return true;
        }
        case 'SAVE': {
          const name = strArg();
          const p = this.runner.resolveSaveName(name);
          const d = this.doc();
          if (d.path.toUpperCase() !== p.toUpperCase()) {
            const text = d.editor.getValue();
            this.app.vfs.writeFile(p, this.app.encodeText(text), { trusted: true });
            this.loadFile(p);
          } else this.app.saveDoc(d);
          this.app.renderExplorer();
          this.ok();
          return true;
        }
        case 'MERGE': {
          const name = strArg();
          const path = this.runner.resolveProgramFile(name);
          if (!path) { this.err('File not found'); this.ok(); return true; }
          let t = this.text();
          const add = this.app.decodeText(this.app.vfs.readFile(path));
          for (const l of add.split('\n')) {
            const m = /^\s*(\d+)\s?(.*)$/.exec(l);
            if (m) t = B.GW.setLine(t, +m[1], m[2]).text;
          }
          this.setText(t);
          this.ok();
          return true;
        }
        case 'RENUM': {
          const st = parsed();
          const [a, b, c] = st.args || [];
          const r = B.GW.renum(this.text(), a, b, c);
          this.setText(r.text);
          for (const w of r.warnings) this.print(w);
          this.ok();
          return true;
        }
        case 'DELETE': {
          const st = parsed();
          const r = B.GW.deleteRange(this.text(), st.range, this.lastLine);
          if (!r.found) { this.err('Illegal function call'); this.ok(); return true; }
          this.setText(r.text);
          this.ok();
          return true;
        }
        case 'AUTO': {
          const st = parsed();
          const [a, b] = st.args || [];
          const nums = B.GW.lineNumbers(this.text());
          this.auto = { n: a === '.' ? (this.lastLine || 10) : (a == null ? 10 : a), inc: b == null ? 10 : b };
          void nums;
          this.autoPrompt();
          return true;
        }
        case 'EDIT': {
          const st = parsed();
          const n = st.line === '.' ? this.lastLine : st.line;
          const l = B.GW.list(this.text(), { from: n, to: null, dash: false });
          if (!l.length) { this.err('Undefined line number'); this.ok(); return true; }
          this.print(l[0], true);
          const d = this.d;
          d.setCursor(d.row, 0);
          this.lastLine = n;
          return true;
        }
        case 'SYSTEM': this.toggle(false); return true;
        case 'GOTO': {
          // GOTO n in direct mode starts the program at line n (GW-BASIC)
          const m2 = /^\s*(\d+)\s*$/.exec(rest);
          if (!m2) return this.immediate(line);
          this.runProgram(+m2[1]);
          return true;
        }
        case 'FILES': case 'KILL': case 'NAME': case 'MKDIR': case 'RMDIR': case 'CHDIR':
        default:
          return this.immediate(line);
      }
    }
    /** Make the program's folder the current directory, so LOAD, SAVE, FILES and RUN "x"
     *  work next to it, as they would on a PC where you had changed into that folder */
    cdToProgram() {
      const d = this.docPath && this.app.docByPath(this.docPath);
      if (!d) return;
      const vfs = this.app.vfs;
      try { const drive = d.path[0].toUpperCase(); vfs.setDrive(drive); vfs.chdir(d.path.replace(/\\[^\\]*$/, '') || drive + ':\\'); } catch (e) { /* stay where we are */ }
    }
    /** Another program was brought up in the editor: it becomes the console's program */
    follow(d) {
      this.docPath = d.path;
      this.cdToProgram();
      this.runner.vm = null;
      this.lastLine = 0;
      if (this.d.cursorCol() !== 0) this.d.newline();
      this.print('Program: ' + d.name);
      this.ok();
      this.app.setStatus('GW-BASIC console on ' + d.name + '. RUN, F2 or the Run button runs it.');
    }
    loadFile(path) {
      const d = this.app.openFile(path, { noFocus: true }) || this.app.docByPath(path);
      if (!d) return;
      d.editor.setValue(this.app.decodeText(this.app.vfs.readFile(path)));
      d.savedText = d.editor.getValue();
      d.dirty = false;
      this.docPath = d.path;
      this.app.activate(d);
      this.cdToProgram();
      this.runner.vm = null;
    }
    immediate(line) {
      const r = this.runner;
      r.ensureIdleVm();
      try {
        const ok = r.runImmediate(line, null);
        if (!ok) { this.err('Busy'); this.ok(); }
      } catch (e) {
        if (e instanceof B.CompileError) { this.err(gwMessage(e.message)); this.ok(); }
        else throw e;
      }
      return true;
    }
    runProgram(lineNo) {
      const d = this.doc();
      this.app.saveDoc(d);
      const text = d.editor.getValue();
      try {
        if (lineNo !== null && lineNo !== undefined) {
          const prog = this.runner.compile(d.path, text);
          if (!prog.module.labels.has(String(lineNo))) { this.err('Undefined line number'); this.ok(); return; }
        }
        const vm = this.runner.start(d.path, text, { keepScreen: true });
        if (lineNo !== null && lineNo !== undefined) vm.pc = vm.prog.module.labels.get(String(lineNo));
        this.app.updateUI();
      } catch (e) {
        if (e instanceof B.CompileError) { this.onCompileError(e); this.app.showCompileError(e); }
        else throw e;
      }
    }
    onBreak(st) {
      this.d.newline();
      this.print('Break' + (st && st.lineNo !== null && st.lineNo !== undefined ? ' in ' + st.lineNo : ''));
      this.print('Ok');
      this.app.el('screen').focus();
    }
    onError(info) {
      this.err(info.message + (info.lineNo !== null && info.lineNo !== undefined ? ' in ' + info.lineNo : ''));
      this.ok();
      this.app.el('screen').focus();
    }
    onCompileError(e) {
      if (this._lastCE === e) return;
      this._lastCE = e;
      let lineNo = null;
      if (e.pos) {
        const l = this.text().split('\n')[e.pos.line] || '';
        const m = /^\s*(\d+)/.exec(l);
        if (m) lineNo = m[1];
      }
      this.err((/^Expected|not valid/.test(e.message) ? 'Syntax error' : e.message) + (lineNo ? ' in ' + lineNo : ''));
      if (lineNo) {
        const l = B.GW.list(this.text(), { from: +lineNo, to: null, dash: false })[0];
        this.ok();
        if (l) { this.print(l, true); this.d.setCursor(this.d.row, 0); }
      } else this.ok();
    }
  }

  RC.GwConsole = GwConsole;
})(RC);
