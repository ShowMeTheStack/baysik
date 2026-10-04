// Bottom debug panels.
(function (RC) {
  'use strict';
  const { h, icon } = RC.UI;
  const B = RC.Basic;

  class Panels {
    constructor(app, tabsEl, bodyEl) {
      this.app = app;
      this.tabsEl = tabsEl;
      this.bodyEl = bodyEl;
      this.panels = {};
      this.order = [];
      this.expanded = new Set();
      this.prevValues = new Map();
      this.watches = RC.UI.storage.get('watches', []);
      this.immHistory = RC.UI.storage.get('immHistory', []);
      this.immPos = this.immHistory.length;
      this.add('immediate', 'Immediate', () => this.buildImmediate());
      this.add('vars', 'Variables', () => this.buildVars());
      this.add('watch', 'Watch', () => this.buildWatch());
      this.add('stack', 'Call Stack', () => this.buildStack());
      this.add('bps', 'Breakpoints', () => this.buildBps());
      this.add('history', 'History', () => this.buildHistory());
      this.add('printer', 'Printer', () => this.buildPrinter());
      this.add('problems', 'Problems', () => this.buildProblems());
      this.show(RC.UI.storage.get('bottomTab', 'immediate'));
    }

    add(id, label, build) {
      const tab = h('button.tab', { role: 'tab', type: 'button', 'data-id': id }, label);
      tab.addEventListener('click', () => this.show(id));
      const el = h('div.bpanel', { role: 'tabpanel' });
      this.tabsEl.appendChild(tab);
      this.bodyEl.appendChild(el);
      this.panels[id] = { tab, el, build, label, built: false };
      this.order.push(id);
    }
    show(id) {
      if (!this.panels[id]) id = 'immediate';
      for (const k of this.order) {
        const p = this.panels[k];
        p.tab.classList.toggle('active', k === id);
        p.tab.setAttribute('aria-selected', k === id ? 'true' : 'false');
        p.el.classList.toggle('active', k === id);
      }
      this.active = id;
      RC.UI.storage.set('bottomTab', id);
      const p = this.panels[id];
      if (!p.built) { p.built = true; p.build(); }
      this.refresh(id);
      if (id === 'immediate' && this.immInput) setTimeout(() => this.immInput.focus(), 0);
    }
    setCount(id, n) {
      const p = this.panels[id];
      let c = p.tab.querySelector('.count');
      if (!n) { if (c) c.remove(); return; }
      if (!c) { c = h('span.count'); p.tab.appendChild(c); }
      c.textContent = n;
    }
    refresh(id) {
      id = id || this.active;
      const fn = { vars: 'refreshVars', watch: 'refreshWatch', stack: 'refreshStack', bps: 'refreshBps', history: 'refreshHistory', problems: 'refreshProblems' }[id];
      if (fn && this.panels[id].built) this[fn]();
    }
    refreshAll() {
      for (const id of this.order) if (this.panels[id].built) this.refresh(id);
      this.setCount('bps', this.app.breakpointCount());
    }
    vm() { return this.app.runner.vm; }
    inspectable() { const vm = this.vm(); return vm && (vm.state === 'paused' || vm.state === 'error' || vm.state === 'ended') && vm.frames && vm.frames.length; }

    // ---- Immediate ----------------------------------------------------------------------------------
    buildImmediate() {
      const p = this.panels.immediate;
      this.immLog = h('div.imm-log', { 'aria-live': 'polite' });
      this.immInput = h('input', { type: 'text', spellcheck: 'false', autocomplete: 'off', placeholder: 'Type a BASIC statement or ? expression and press Enter  (e.g.  ? 2+2   PRINT x   x = 5)', 'aria-label': 'Immediate statement' });
      const tools = h('div.bpanel-tools',
        h('span.muted', 'Runs statements in the selected stack frame when paused, otherwise in the main module.'),
        h('span.grow'),
        h('button.small-btn', { type: 'button', onclick: () => { this.immLog.innerHTML = ''; } }, 'Clear'));
      p.el.append(tools, this.immLog, h('div.imm-input', h('span', '>'), this.immInput));
      this.immInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          const t = this.immInput.value;
          if (!t.trim()) return;
          this.immInput.value = '';
          this.immHistory.push(t);
          if (this.immHistory.length > 100) this.immHistory.shift();
          RC.UI.storage.set('immHistory', this.immHistory);
          this.immPos = this.immHistory.length;
          this.app.immediate(t);
        } else if (e.key === 'ArrowUp') {
          if (this.immPos > 0) { this.immPos--; this.immInput.value = this.immHistory[this.immPos]; }
          e.preventDefault();
        } else if (e.key === 'ArrowDown') {
          if (this.immPos < this.immHistory.length) { this.immPos++; this.immInput.value = this.immHistory[this.immPos] || ''; }
          e.preventDefault();
        }
      });
      this.log('Immediate window. Try:  ? 6 * 7   or   PRINT "Hi"   or   ? SQR(2)', 'note');
    }
    log(text, cls, pos) {
      if (!this.immLog) { this.panels.immediate.built = true; this.buildImmediate(); }
      const el = h('div.' + (cls || 'res'), text);
      if (pos) {
        el.classList.add('jump');
        el.title = 'Double-click to go to ' + (pos.file || '').replace(/^.*\\/, '') + ' line ' + (pos.line + 1);
        el.addEventListener('dblclick', () => this.app.gotoPos(pos));
      }
      this.immLog.appendChild(el);
      while (this.immLog.childNodes.length > 500) this.immLog.firstChild.remove();
      this.immLog.scrollTop = this.immLog.scrollHeight;
    }

    // ---- Variables ---------------------------------------------------------------------------------
    buildVars() {
      const p = this.panels.vars;
      this.varsFilter = h('input', { type: 'text', placeholder: 'Filter…', style: { height: '24px', background: 'var(--input)', border: '1px solid var(--border)', padding: '0 6px' }, 'aria-label': 'Filter variables' });
      this.varsFilter.addEventListener('input', () => this.refreshVars());
      this.varsScope = h('span.muted');
      p.el.append(h('div.bpanel-tools', this.varsScope, h('span.grow'), this.varsFilter), this.varsBody = h('div.bpanel-body'));
    }
    refreshVars() {
      const body = this.varsBody;
      if (!body) return;
      const vm = this.vm();
      if (!this.inspectable()) {
        body.innerHTML = '';
        body.appendChild(h('div.empty', vm && (vm.state === 'running' || vm.state === 'waiting') ? 'Program is running. Pause (Ctrl+Break) or hit a breakpoint to inspect variables.' : 'Run your program and pause it (or set a breakpoint) to see variables here. Click a value to change it; arrays and records unfold with ▸.'));
        this.varsScope.textContent = '';
        return;
      }
      const fi = this.app.selectedFrameIndex();
      let vars, consts;
      try { vars = B.Debug.variables(vm, fi); consts = B.Debug.constants(vm, fi); } catch (e) { body.innerHTML = ''; body.appendChild(h('div.empty', 'Variables unavailable: ' + e.message)); return; }
      const filter = (this.varsFilter.value || '').toUpperCase();
      const f = (list) => list.filter((v) => !filter || v.name.toUpperCase().includes(filter));
      const top = fi === vm.frames.length - 1;
      this.varsScope.textContent = 'Frame #' + fi + ': ' + (vars.scopeName || 'Main module') + (top ? ' (current)' : ' (caller — editable here)');
      if (!this.varTree) {
        this.varTree = new RC.VarTree({ app: this.app, fi: () => this.app.selectedFrameIndex(), canEdit: () => true, refresh: () => this.refreshVars(), onEdited: () => this.refreshAll() });
      }
      const sections = [];
      if (vars.scopeName) sections.push({ title: 'Locals — ' + vars.scopeName, entries: f(vars.locals), keyPrefix: 'L' + fi + ':' + vars.scopeName + ':' });
      sections.push({ title: 'Module-level (global)', entries: f(vars.globals), keyPrefix: 'G:' });
      if (consts.length) sections.push({ title: 'Constants (read-only)', entries: f(consts), keyPrefix: 'C:' });
      const scroll = body.scrollTop;
      this.varTree.render(body, sections);
      body.scrollTop = scroll;
    }

    // ---- Watch ---------------------------------------------------------------------------------------
    buildWatch() {
      const p = this.panels.watch;
      this.watchInput = h('input', { type: 'text', placeholder: 'Add watch expression (e.g.  x * 2,  name$,  a(i))', style: { flex: 1, height: '24px', background: 'var(--input)', border: '1px solid var(--border)', padding: '0 6px', fontFamily: 'var(--font-code)' }, 'aria-label': 'New watch expression' });
      this.watchInput.addEventListener('keydown', (e) => { if (e.key === 'Enter' && this.watchInput.value.trim()) { this.addWatch(this.watchInput.value.trim()); this.watchInput.value = ''; } e.stopPropagation(); });
      p.el.append(h('div.bpanel-tools', this.watchInput, h('button.small-btn', { type: 'button', onclick: () => { if (this.watchInput.value.trim()) { this.addWatch(this.watchInput.value.trim()); this.watchInput.value = ''; } } }, 'Add')),
        this.watchBody = h('div.bpanel-body'));
    }
    addWatch(expr, mode) {
      this.watches.push({ expr, mode: mode || 'none' });
      this.saveWatches();
      if (!this.panels.watch.built) { this.panels.watch.built = true; this.buildWatch(); }
      this.refreshWatch();
      this.app.syncWatchpoints();
    }
    saveWatches() { RC.UI.storage.set('watches', this.watches); this.setCount('watch', this.watches.length); }
    refreshWatch() {
      const body = this.watchBody;
      if (!body) return;
      body.innerHTML = '';
      if (!this.watches.length) { body.appendChild(h('div.empty', 'No watch expressions. Add one above — it is evaluated whenever the program pauses. Choose "break on change" to stop when its value changes.')); return; }
      const vm = this.vm();
      const can = this.inspectable();
      this.watches.forEach((w, i) => {
        let val = '', cls = '';
        if (can) {
          try {
            const r = B.Debug.evaluate(vm, w.expr, this.app.selectedFrameIndex());
            val = B.Debug.fmtValue(r.value, r.type);
          } catch (e) { val = e.message; cls = 'err'; }
        } else val = vm && (vm.state === 'running' || vm.state === 'waiting') ? '(running)' : '(not running)';
        const key = 'W:' + w.expr;
        const changed = this.prevValues.has(key) && this.prevValues.get(key) !== val && !cls;
        this.prevValues.set(key, val);
        const modeSel = h('select', { title: 'Break mode', style: { height: '22px', background: 'var(--input)', border: '1px solid var(--border)' }, 'aria-label': 'Watch break mode' },
          h('option', { value: 'none' }, 'watch only'), h('option', { value: 'change' }, 'break on change'), h('option', { value: 'true' }, 'break when true'));
        modeSel.value = w.mode || 'none';
        modeSel.addEventListener('change', () => { w.mode = modeSel.value; this.saveWatches(); this.app.syncWatchpoints(); });
        body.appendChild(h('div.list-row',
          h('span', { style: { minWidth: '30%', fontWeight: 600 } }, w.expr),
          h('span.grow' + (cls ? '.err' : ''), { style: { color: changed ? 'var(--warn)' : '' } }, val),
          modeSel,
          h('button.icon-btn', { type: 'button', title: 'Remove watch', 'aria-label': 'Remove watch', onclick: () => { this.watches.splice(i, 1); this.saveWatches(); this.refreshWatch(); this.app.syncWatchpoints(); } }, icon('x'))));
      });
    }

    // ---- Call stack ---------------------------------------------------------------------------------
    buildStack() {
      const p = this.panels.stack;
      p.el.append(h('div.bpanel-tools', h('span.muted', 'Innermost call first. Click a frame to inspect its variables and see where it was called from.')), this.stackBody = h('div.bpanel-body'));
    }
    refreshStack() {
      const body = this.stackBody;
      if (!body) return;
      body.innerHTML = '';
      const vm = this.vm();
      if (!this.inspectable()) { body.appendChild(h('div.empty', 'The call stack appears when the program is paused. Try the HANOI or FACTORIAL examples to watch recursion grow the stack!')); return; }
      const cs = vm.callStack();
      const sel = this.app.selectedFrameIndex();
      cs.forEach((c, i) => {
        const pos = c.pos;
        const loc = pos ? (pos.file ? pos.file.replace(/^.*\\/, '') : '') + ':' + (pos.line + 1) + (c.lineNo !== null && c.lineNo !== undefined ? '  [line ' + c.lineNo + ']' : '') : '';
        const row = h('div.frame-row' + (c.index === sel ? '.sel' : ''), h('span.depth', '#' + c.index), h('span', c.name), h('span.loc', loc));
        row.addEventListener('click', () => this.app.selectFrame(c.index));
        body.appendChild(row);
        const f = c.frame;
        if (f.gosub && f.gosub.length) {
          const st = f.gosub.map((pc) => { const s = this.stmtForPc(vm, pc); return s && s.pos ? (s.lineNo !== null ? s.lineNo : 'line ' + (s.pos.line + 1)) : '?'; });
          body.appendChild(h('div.frame-sub', 'GOSUB returns → ' + st.reverse().join(' ← ')));
        }
        if (f.fors && f.fors.length) {
          body.appendChild(h('div.frame-sub', 'FOR loops: ' + f.fors.map((r) => (r.name || 'var') + ' = ' + B.Debug.fmtValue(r.c[r.k], { code: r.code }) + ' TO ' + B.Debug.fmtValue(r.limit, { code: r.code }) + (r.step !== 1 ? ' STEP ' + r.step : '')).join(';  ')));
        }
      });
    }
    stmtForPc(vm, pc) {
      // statement whose code range contains pc
      const st = vm.prog.stmts;
      let best = null;
      for (const s of st) if (s.pc <= pc && pc <= s.endPc && (!best || s.pc >= best.pc)) best = s;
      return best;
    }

    // ---- Breakpoints --------------------------------------------------------------------------------
    buildBps() {
      const p = this.panels.bps;
      p.el.append(h('div.bpanel-tools', h('span.muted', 'Click the editor gutter (or press F9) to toggle a breakpoint. Add a condition to stop only when it is true.'), h('span.grow'),
        h('button.small-btn', { type: 'button', onclick: () => this.app.clearBreakpoints() }, 'Remove all')), this.bpsBody = h('div.bpanel-body'));
    }
    refreshBps() {
      const body = this.bpsBody;
      if (!body) return;
      body.innerHTML = '';
      const all = this.app.breakpoints;
      let n = 0;
      for (const [path, lines] of all) {
        for (const [line, bp] of [...lines.entries()].sort((a, b) => a[0] - b[0])) {
          n++;
          const en = h('input', { type: 'checkbox', checked: !bp.disabled, title: 'Enabled', 'aria-label': 'Enabled' });
          en.addEventListener('change', () => this.app.updateBreakpoint(path, line, { disabled: !en.checked }));
          const cond = h('input', { type: 'text', value: bp.cond || '', placeholder: 'condition (optional), e.g.  i = 50', 'aria-label': 'Condition' });
          cond.addEventListener('change', () => this.app.updateBreakpoint(path, line, { cond: cond.value.trim() || null }));
          cond.addEventListener('keydown', (e) => e.stopPropagation());
          const text = this.app.lineText(path, line);
          body.appendChild(h('div.list-row', en,
            h('span.clickable', { style: { cursor: 'pointer', minWidth: '140px' }, onclick: () => this.app.gotoPos({ file: path, line }) }, path.replace(/^.*\\/, '') + ':' + (line + 1)),
            h('span.grow.muted', text.trim()), cond,
            h('button.icon-btn', { type: 'button', title: 'Remove', 'aria-label': 'Remove breakpoint', onclick: () => this.app.toggleBreakpoint(path, line) }, icon('x'))));
        }
      }
      if (!n) body.appendChild(h('div.empty', 'No breakpoints yet.'));
      this.setCount('bps', n);
    }

    // ---- History ----------------------------------------------------------------------------------------
    buildHistory() {
      const p = this.panels.history;
      this.animChk = h('input', { type: 'checkbox', checked: this.app.runner.animate, 'aria-label': 'Animate' });
      this.animChk.addEventListener('change', () => this.app.setAnimate(this.animChk.checked));
      p.el.append(h('div.bpanel-tools', h('label', { style: { display: 'flex', gap: '4px', alignItems: 'center' } }, this.animChk, 'Animate execution (trace)'), h('span.grow'),
        h('span.muted', 'Last statements executed (newest last). Click to jump.')), this.histBody = h('div.bpanel-body'));
    }
    refreshHistory() {
      const body = this.histBody;
      if (!body) return;
      if (this.animChk) this.animChk.checked = this.app.runner.animate;
      body.innerHTML = '';
      const vm = this.vm();
      if (!vm || !vm.history.length) { body.appendChild(h('div.empty', 'Statements appear here as your program runs.')); return; }
      const list = vm.history.slice(-200);
      for (const idx of list) {
        const st = vm.prog.stmts[idx];
        if (!st || !st.pos) continue;
        const pos = st.pos;
        const text = this.app.lineText(pos.file, pos.line).slice(pos.col, pos.end) || this.app.lineText(pos.file, pos.line);
        body.appendChild(h('div.list-row.clickable', { onclick: () => this.app.gotoPos(pos) },
          h('span.muted', { style: { minWidth: '110px' } }, (pos.file || '').replace(/^.*\\/, '') + ':' + (pos.line + 1) + (st.lineNo !== null ? ' [' + st.lineNo + ']' : '')),
          h('span.grow', text.trim())));
      }
      body.scrollTop = body.scrollHeight;
    }

    // ---- Printer ------------------------------------------------------------------------------------------
    buildPrinter() {
      const p = this.panels.printer;
      this.printerEl = h('div.printer', { 'aria-label': 'Printer output (LPRINT)' });
      p.el.append(h('div.bpanel-tools', h('span.muted', 'LPRINT / LLIST output (LPT1:)'), h('span.grow'),
        h('button.small-btn', { type: 'button', onclick: () => RC.UI.download('LPT1.TXT', this.printerText()) }, 'Save'),
        h('button.small-btn', { type: 'button', onclick: () => { this.printerLines = []; this.printerEl.textContent = ''; this.setCount('printer', 0); } }, 'Clear')),
      h('div.bpanel-body', this.printerEl));
      this.printerEl.textContent = (this.printerLines || []).join('\n');
    }
    printerLine(s) {
      this.printerLines = this.printerLines || [];
      this.printerLines.push(s);
      if (this.printerLines.length > 5000) this.printerLines.shift();
      if (this.printerEl) this.printerEl.textContent = this.printerLines.join('\n');
      if (this.active !== 'printer') this.setCount('printer', this.printerLines.length);
    }
    printerText() { return (this.printerLines || []).join('\r\n'); }

    // ---- Problems ------------------------------------------------------------------------------------------
    buildProblems() {
      const p = this.panels.problems;
      p.el.append(this.probBody = h('div.bpanel-body'));
    }
    setProblems(list) { this.problems = list; this.setCount('problems', list.length); this.refreshProblems(); }
    refreshProblems() {
      const body = this.probBody;
      if (!body) return;
      body.innerHTML = '';
      const list = this.problems || [];
      if (!list.length) { body.appendChild(h('div.empty', 'No problems.')); return; }
      body.appendChild(h('div.bpanel-tools', h('span.muted', 'Double-click a problem to open the file at that line (tap twice on touch screens).')));
      for (const pr of list) {
        const row = h('div.list-row.clickable', { tabindex: '0', title: 'Double-click to go to the error' },
          h('span.err', pr.kind || 'Error'),
          h('span.grow', pr.message),
          h('span.muted', pr.pos ? (pr.pos.file || '').replace(/^.*\\/, '') + ':' + (pr.pos.line + 1) + ':' + ((pr.pos.col || 0) + 1) : ''));
        const go = () => pr.pos && this.app.gotoPos(pr.pos);
        row.addEventListener('click', () => { body.querySelectorAll('.list-row').forEach((r) => r.classList.remove('sel')); row.classList.add('sel'); });
        row.addEventListener('dblclick', go);
        row.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); go(); } });
        body.appendChild(row);
      }
    }
  }

  RC.Panels = Panels;
})(RC);
