// The Baysik IDE application.
(function (RC) {
  'use strict';
  const { h, icon } = RC.UI;
  const B = RC.Basic;
  const store = RC.UI.storage;

  const DEFAULT_SETTINGS = {
    theme: 'qbasic', fontSize: 15, tabSize: 4, autoFormat: true, autoIndent: true,
    speed: 0, crt: false, scaleMode: 'fit', sound: true, volume: 0.5, showExplorer: true,
    autosave: true, explorerW: 210, screenW: 46, bottomH: 230, firstRun: true, lineEnding: 'crlf',
  };
  const SPEEDS = [
    { label: 'Full speed', v: 0 },
    { label: 'Fast PC (≈ 486)', v: 400000 },
    { label: 'Classic PC (≈ 8 MHz 286)', v: 25000 },
    { label: 'Original IBM PC (≈ 4.77 MHz)', v: 4000 },
    { label: 'Slow motion (20 statements/s)', v: 20 },
    { label: 'Step-by-step crawl (3 statements/s)', v: 3 },
  ];

  const LANG = {
    id: 'basic',
    highlightLine: (t) => B.highlightLine(t),
    formatLine: (t) => B.formatLine(t),
    indentAfter: (t) => /^\s*(\d+\s+)?(IF\b.*\bTHEN\s*('.*)?$|ELSE\s*$|ELSEIF\b|FOR\b|DO\b|WHILE\b|SELECT\s+CASE\b|CASE\b|SUB\b|FUNCTION\b|TYPE\b|DEF\s+FN\w+\s*(\(.*\))?\s*$)/i.test(t) && !/\bNEXT\b|\bLOOP\b|\bWEND\b/i.test(t.replace(/^\s*(FOR|DO|WHILE)\b.*?:/i, '')),
    exts: ['.BAS', '.BI', '.BM'],
  };

  class App {
    constructor() {
      this.settings = Object.assign({}, DEFAULT_SETTINGS, store.get('settings', {}));
      this.docs = [];
      this.active = null;
      this.breakpoints = new Map();
      for (const [p, lines] of Object.entries(store.get('breakpoints', {}))) this.breakpoints.set(p, new Map(lines.map((x) => [x.line, { cond: x.cond || null, disabled: !!x.disabled }])));
      this.selFrame = null;
      this.vfs = new RC.VFS();
      this.el = (id) => document.getElementById(id);
    }

    async init() {
      this.applyTheme();
      this.applyLayout();
      try { await this.vfs.persist(); } catch (e) { RC.UI.toast('Could not open browser storage; files will not persist this session.', 'err', 6000); }
      RC.Samples.install(this.vfs);
      this.runner = new RC.Runner(this, this.el('screen'));
      this.runner.audio.setVolume(this.settings.sound ? this.settings.volume * 0.16 : 0);
      this.runner.setSpeed(this.settings.speed);
      this.panels = new RC.Panels(this, this.el('bottomTabs'), this.el('bottomBody'));
      this.callout = new RC.HoverCallout(this);
      this.buildMenus();
      this.buildToolbar();
      this.buildScreenActions();
      this.buildExplorer();
      this.bindRunner();
      this.bindKeys();
      this.bindSplitters();
      this.bindMobile();
      this.bindScreen();
      this.console = new RC.GwConsole(this);
      this.el('drawerScrim').addEventListener('click', () => this.toggleDrawer(false));
      this.el('explorerClose').addEventListener('click', () => this.toggleDrawer(false));
      this.setupTouch();
      // restore session
      const sess = store.get('session', null);
      let opened = false;
      if (sess && sess.open && sess.open.length) {
        for (const p of sess.open) { try { if (this.vfs.exists(p)) { this.openFile(p, { noFocus: true }); opened = true; } } catch (e) { /* ignore */ } }
        if (sess.active) { const d = this.docByPath(sess.active); if (d) this.activate(d); }
      }
      if (!opened) this.openFile('C:\\MYPROGS\\HELLO.BAS');
      this.updateUI();
      this.welcomeScreen();
      // shared link?
      const m = /#share=(CPD1\.[A-Za-z0-9_.-]+)/.exec(location.hash);
      if (m) { history.replaceState(null, '', location.pathname + location.search); setTimeout(() => this.importShare(m[1]), 300); }
      else if (this.settings.firstRun) {
        this.settings.firstRun = false; this.saveSettings();
        setTimeout(() => RC.Tours.offerWelcome(this), 600);
      }
      window.addEventListener('beforeunload', (e) => {
        this.saveSession();
        if (this.docs.some((d) => d.dirty && (this.isProtected(d.path) || !this.settings.autosave))) { e.preventDefault(); e.returnValue = ''; }
      });
      setInterval(() => this.autosaveTick(), 4000);
      window.__baysikReady = true; // signal for automated tests
    }

    // ---- settings / theme / layout ---------------------------------------------------------------
    saveSettings() { store.set('settings', this.settings); }
    applyTheme() {
      document.documentElement.dataset.theme = this.settings.theme;
      document.documentElement.style.setProperty('--ed-font-size', this.settings.fontSize + 'px');
      const crt = this.el('crt');
      if (crt) crt.classList.toggle('on', !!this.settings.crt);
      if (this.docs) for (const d of this.docs) { d.editor._cw = null; d.editor.render(); }
    }
    applyLayout() {
      const s = this.settings;
      const app = this.el('app');
      app.style.setProperty('--explorer-w', s.explorerW + 'px');
      app.style.setProperty('--screen-w', s.screenW + '%');
      app.style.setProperty('--bottom-h', s.bottomH + 'px');
      this.el('workspace').classList.toggle('no-explorer', !s.showExplorer);
    }
    bindSplitters() {
      const app = this.el('app');
      for (const sp of document.querySelectorAll('.splitter')) {
        const kind = sp.dataset.split;
        RC.UI.splitter(sp, (e) => {
          const ws = this.el('workspace').getBoundingClientRect();
          if (kind === 'explorer') this.settings.explorerW = Math.max(120, Math.min(480, e.clientX - ws.left));
          else if (kind === 'screen') this.settings.screenW = Math.max(18, Math.min(75, ((ws.right - e.clientX) / ws.width) * 100));
          else if (kind === 'bottom') this.settings.bottomH = Math.max(60, Math.min(window.innerHeight - 200, window.innerHeight - e.clientY - 24));
          this.applyLayout();
        }, () => { this.saveSettings(); for (const d of this.docs) d.editor.syncScroll(); });
      }
      void app;
    }
    bindMobile() {
      const app = this.el('app');
      app.dataset.mview = 'editor';
      for (const b of this.el('mobileTabs').querySelectorAll('button')) {
        b.addEventListener('click', () => this.setMobileView(b.dataset.view));
      }
    }
    setMobileView(v) {
      const app = this.el('app');
      app.dataset.mview = v;
      for (const b of this.el('mobileTabs').querySelectorAll('button')) b.classList.toggle('active', b.dataset.view === v);
      if (v === 'editor' && this.active) this.active.editor.render();
    }
    isMobile() { return window.matchMedia('(max-width: 820px), (max-height: 480px)').matches; }

    // ---- menus -------------------------------------------------------------------------------------
    menuDefs() {
      const r = this.runner;
      const st = r ? r.state : 'idle';
      const paused = st === 'paused';
      const running = st === 'running' || st === 'waiting';
      const s = this.settings;
      return [
        { label: 'File', hot: 0, items: () => [
          { label: 'New Program', sc: 'Alt+N', action: () => this.newFile() },
          { label: 'New Folder…', action: () => this.newFolder() },
          { label: 'Open…', sc: 'Ctrl+O', action: () => this.openDialog() },
          { label: 'Open from Computer…', action: () => this.importFromComputer() },
          { sep: true },
          { label: 'Save', sc: 'Ctrl+S', action: () => this.save(), disabled: !this.active },
          { label: 'Save As…', sc: 'Ctrl+Shift+S', action: () => this.saveAs(), disabled: !this.active },
          { label: 'Save All', action: () => this.saveAll() },
          { label: 'Download to Computer', action: () => this.downloadActive(), disabled: !this.active },
          { sep: true },
          { label: 'Share Project as Link…', action: () => this.shareDialog() },
          { label: 'Import Shared Code…', action: () => this.importShareDialog() },
          { label: 'Download Project (.zip)', action: () => this.downloadZip() },
          { sep: true },
          { label: 'Mount Computer Folder as D:…', action: () => this.mountDialog() },
          { label: 'Unmount D:', action: () => { this.vfs.unmount('D'); this.renderExplorer(); }, disabled: !this.vfs.drives.D },
          { sep: true },
          { label: 'Close Tab', sc: 'Alt+W', action: () => this.active && this.closeDoc(this.active), disabled: !this.active },
        ] },
        { label: 'Edit', hot: 0, items: () => [
          { label: 'Undo', sc: 'Ctrl+Z', action: () => { this.focusEditor(); document.execCommand('undo'); } },
          { label: 'Redo', sc: 'Ctrl+Y', action: () => { this.focusEditor(); document.execCommand('redo'); } },
          { sep: true },
          { label: 'Find…', sc: 'Ctrl+F', action: () => this.openFind(false) },
          { label: 'Replace…', sc: 'Ctrl+H', action: () => this.openFind(true) },
          { label: 'Go to Line…', sc: 'Ctrl+G', action: () => this.gotoLineDialog() },
          { sep: true },
          { label: 'Toggle Comment', sc: 'Ctrl+/', action: () => this.active && this.active.editor.toggleComment() },
          { label: 'Duplicate Line', sc: 'Ctrl+D', action: () => this.active && this.active.editor.duplicateLine() },
          { label: 'Capitalize Keywords', action: () => this.active && this.active.editor.formatAll() },
          { label: 'Renumber Lines (RENUM)…', action: () => this.renumDialog() },
          { label: 'Add Line Numbers…', action: () => this.addLineNumbers() },
        ] },
        { label: 'View', hot: 0, items: () => [
          { label: 'Output Screen Full Size', sc: 'F4', action: () => this.toggleScreenMax() },
          { label: 'GW-BASIC Classic Console', checked: this.console && this.console.active, action: () => this.console.toggle() },
          { label: 'Explorer', checked: s.showExplorer, action: () => { s.showExplorer = !s.showExplorer; this.saveSettings(); this.applyLayout(); } },
          { label: 'SUBs and FUNCTIONs…', sc: 'F2', action: () => this.subsDialog() },
          { sep: true },
          { label: 'Immediate', action: () => this.panels.show('immediate') },
          { label: 'Variables', action: () => this.panels.show('vars') },
          { label: 'Watch', action: () => this.panels.show('watch') },
          { label: 'Call Stack', action: () => this.panels.show('stack') },
          { label: 'Breakpoints', action: () => this.panels.show('bps') },
          { label: 'History / Trace', action: () => this.panels.show('history') },
          { label: 'Printer', action: () => this.panels.show('printer') },
          { sep: true },
          { label: 'Zoom In', sc: 'Ctrl+=', action: () => this.zoom(1) },
          { label: 'Zoom Out', sc: 'Ctrl+-', action: () => this.zoom(-1) },
        ] },
        { label: 'Run', hot: 0, items: () => [
          { label: paused ? 'Continue' : 'Start', sc: 'F5', action: () => this.runOrContinue() },
          { label: 'Restart', sc: 'Shift+F5', action: () => this.restart() },
          { label: 'Pause', sc: 'Ctrl+Break', action: () => this.runner.pause(), disabled: !running },
          { label: 'Stop', sc: 'Ctrl+F2', action: () => this.stop(), disabled: !(running || paused) },
          { sep: true },
          { label: 'Run to Cursor', sc: 'F7', action: () => this.runToCursor() },
          { label: 'Set Next Statement', action: () => this.setNextStatement(), disabled: !paused },
          { sep: true },
          { label: 'Speed', items: SPEEDS.map((sp) => ({ label: sp.label, checked: s.speed === sp.v, action: () => this.setSpeed(sp.v) })) },
          { label: 'Output Screen', sc: 'F4', action: () => this.toggleScreenMax() },
        ] },
        { label: 'Debug', hot: 0, items: () => [
          { label: 'Step Into', sc: 'F8', action: () => this.step('into') },
          { label: 'Step Over', sc: 'F10', action: () => this.step('over') },
          { label: 'Step Out', sc: 'Shift+F8', action: () => this.step('out'), disabled: !paused },
          { sep: true },
          { label: 'Toggle Breakpoint', sc: 'F9', action: () => this.toggleBreakpointAtCursor() },
          { label: 'Conditional Breakpoint…', action: () => this.conditionalBreakpointDialog() },
          { label: 'Clear All Breakpoints', action: () => this.clearBreakpoints() },
          { sep: true },
          { label: 'Add Watch…', action: () => this.addWatchDialog() },
          { label: 'Animate Execution (Trace)', checked: this.runner && this.runner.animate, action: () => this.setAnimate(!this.runner.animate) },
          { label: 'TRON (print line numbers)', action: () => this.immediate('TRON') },
        ] },
        { label: 'Options', hot: 0, items: () => [
          { label: 'Theme', items: [['qbasic', 'QBasic Blue'], ['dark', 'Dark'], ['light', 'Light'], ['amber', 'Amber Monitor'], ['auto', 'Match System']].map(([v, l]) => ({ label: l, checked: s.theme === v, action: () => { s.theme = v; this.saveSettings(); this.applyTheme(); } })) },
          { label: 'Editor Font Size…', action: () => this.fontSizeDialog() },
          { label: 'Tab Width', items: [2, 4, 8].map((n) => ({ label: n + ' spaces', checked: s.tabSize === n, action: () => { s.tabSize = n; this.saveSettings(); } })) },
          { label: 'Capitalize Keywords As You Type', checked: s.autoFormat, action: () => { s.autoFormat = !s.autoFormat; this.saveSettings(); } },
          { label: 'Auto Indent', checked: s.autoIndent, action: () => { s.autoIndent = !s.autoIndent; this.saveSettings(); } },
          { label: 'Autosave', checked: s.autosave, action: () => { s.autosave = !s.autosave; this.saveSettings(); } },
          { sep: true },
          { label: 'CRT Scanlines', checked: s.crt, action: () => { s.crt = !s.crt; this.saveSettings(); this.applyTheme(); } },
          { label: 'Sound', checked: s.sound, action: () => { s.sound = !s.sound; this.saveSettings(); this.runner.audio.setVolume(s.sound ? s.volume * 0.16 : 0); } },
          { label: 'Volume', items: [0.25, 0.5, 0.75, 1].map((v) => ({ label: Math.round(v * 100) + '%', checked: s.volume === v, action: () => { s.volume = v; s.sound = true; this.saveSettings(); this.runner.audio.setVolume(v * 0.16); } })) },
          { sep: true },
          { label: 'Disk Usage & Reset…', action: () => this.diskDialog() },
        ] },
        { label: 'Help', hot: 0, items: () => [
          { label: 'Language Reference', sc: 'F1', action: () => RC.Help.open(this) },
          { label: 'Keyboard Shortcuts', action: () => this.shortcutsDialog() },
          { label: 'Learn BASIC (Tutorial)…', action: () => RC.Lessons.browse(this) },
          { label: 'Program Library…', action: () => RC.Library.browse(this) },
          { label: 'Starter Examples…', action: () => RC.Samples.gallery(this) },
          { sep: true },
          { label: 'Tour: Welcome to the IDE', action: () => RC.Tours.start(this, 'welcome') },
          { label: 'Tour: Your First Program', action: () => RC.Tours.start(this, 'first') },
          { label: 'Tour: Debugging', action: () => RC.Tours.start(this, 'debug') },
          { label: 'Tour: Graphics & Sound', action: () => RC.Tours.start(this, 'graphics') },
          { label: 'Tour: Files & Sharing', action: () => RC.Tours.start(this, 'files') },
          { label: 'Tour: Classic GW-BASIC Console', action: () => RC.Tours.start(this, 'gw') },
          { sep: true },
          { label: 'About Baysik', action: () => this.aboutDialog() },
        ] },
      ];
    }
    buildMenus() {
      const bar = this.el('menubar');
      bar.innerHTML = '';
      bar.appendChild(h('span.brand', h('span.logo', 'B'), 'Baysik'));
      this.menuButtons = [];
      const defs = this.menuDefs();
      defs.forEach((m, i) => {
        const btn = h('button.menu-btn', { type: 'button', 'aria-haspopup': 'true', 'data-menu': i },
          h('span.hot', m.label[0]), m.label.slice(1));
        btn.addEventListener('click', () => this.openMenu(i));
        btn.addEventListener('mouseenter', () => { if (this.menuOpenIdx !== undefined && this.menuOpenIdx !== i) this.openMenu(i); });
        bar.appendChild(btn);
        this.menuButtons.push(btn);
      });
      bar.appendChild(h('span.spacer'));
      this.projLabel = h('span.proj');
      bar.appendChild(this.projLabel);
    }
    openMenu(i, keyboard) {
      const btn = this.menuButtons[i];
      if (this.menuOpenIdx === i && !keyboard) { RC.UI.closeMenus(); return; }
      const r = btn.getBoundingClientRect();
      const defs = this.menuDefs();
      this.menuButtons.forEach((b) => b.classList.remove('open'));
      btn.classList.add('open');
      this.menuOpenIdx = i;
      RC.UI.showMenu(defs[i].items(), r.left, r.bottom, {
        anchor: btn, keyboard,
        onClose: () => { btn.classList.remove('open'); if (this.menuOpenIdx === i) this.menuOpenIdx = undefined; },
        onArrow: (d) => { const n = (i + d + this.menuButtons.length) % this.menuButtons.length; setTimeout(() => this.openMenu(n, true), 0); },
      });
    }

    // ---- toolbar -----------------------------------------------------------------------------------------
    buildToolbar() {
      const tb = this.el('toolbar');
      const btn = (id, ic, label, title, fn, cls) => {
        const b = h('button.tb-btn' + (cls ? '.' + cls : ''), { type: 'button', title, 'aria-label': title, id }, icon(ic), h('span.lbl', label));
        b.addEventListener('click', fn);
        return b;
      };
      this.tb = {
        run: btn('tbRun', 'run', 'Run', 'Run / Continue (F5)', () => this.runOrContinue(), 'primary'),
        pause: btn('tbPause', 'pause', 'Pause', 'Pause (Ctrl+Break)', () => this.runner.pause()),
        stop: btn('tbStop', 'stop', 'Stop', 'Stop (Ctrl+F2)', () => this.stop()),
        restart: btn('tbRestart', 'restart', '', 'Restart (Shift+F5)', () => this.restart()),
        into: btn('tbInto', 'stepInto', 'Step', 'Step Into (F8)', () => this.step('into')),
        over: btn('tbOver', 'stepOver', 'Over', 'Step Over (F10)', () => this.step('over')),
        out: btn('tbOut', 'stepOut', 'Out', 'Step Out (Shift+F8)', () => this.step('out')),
        bp: btn('tbBp', 'bp', '', 'Toggle Breakpoint (F9)', () => this.toggleBreakpointAtCursor(), 'danger'),
        examples: btn('tbExamples', 'star', 'Library', 'Program library: hundreds of commented example programs', () => RC.Library.browse(this)),
        learn: btn('tbLearn', 'book', 'Learn', 'BASIC tutorial: step-by-step lessons', () => RC.Lessons.browse(this)),
        help: btn('tbHelp', 'help', 'Help', 'Language reference (F1)', () => RC.Help.open(this)),
        tour: btn('tbTour', 'tour', 'Tours', 'Guided tours', () => RC.Tours.menu(this)),
        files: btn('tbFiles', 'folder', 'Files', 'Show files', () => this.toggleDrawer(), 'tb-files'),
      };
      this.speedSel = h('select', { title: 'Execution speed', 'aria-label': 'Execution speed', id: 'tbSpeed' }, SPEEDS.map((sp) => h('option', { value: sp.v }, sp.label)));
      this.speedSel.value = String(this.settings.speed);
      this.speedSel.addEventListener('change', () => this.setSpeed(+this.speedSel.value));
      this.statePill = h('span.state-pill', { id: 'tbState' }, 'Ready');
      tb.append(this.tb.files, this.tb.run, this.tb.pause, this.tb.stop, this.tb.restart, h('span.tb-sep'),
        this.tb.into, this.tb.over, this.tb.out, this.tb.bp, h('span.tb-sep'),
        h('span.tb-group', h('span.tb-label', 'Speed'), this.speedSel), h('span.grow'), this.statePill, h('span.tb-sep'),
        this.tb.learn, this.tb.examples, this.tb.tour, this.tb.help);
    }
    setSpeed(v) {
      this.settings.speed = v;
      this.saveSettings();
      this.runner.setSpeed(v);
      if (this.speedSel) this.speedSel.value = String(v);
    }
    setAnimate(on) {
      this.runner.animate = on;
      if (on && this.settings.speed === 0) this.setSpeed(20);
      if (!on) this.clearExecMarks();
      this.panels.refresh('history');
    }
    buildScreenActions() {
      const a = this.el('screenActions');
      const mk = (ic, title, fn) => h('button.icon-btn', { type: 'button', title, 'aria-label': title, onclick: fn }, icon(ic));
      a.append(
        mk('gw', 'GW-BASIC classic console', () => this.console.toggle()),
        mk('download', 'Save screenshot (PNG)', () => this.screenshot()),
        mk('max', 'Full size output (F4)', () => this.toggleScreenMax()));
    }
    screenshot() {
      const c = this.el('screen');
      c.toBlob((b) => b && RC.UI.download('SCREEN.PNG', b), 'image/png');
    }
    toggleScreenMax() {
      const app = this.el('app');
      app.classList.toggle('screen-max');
      if (app.classList.contains('screen-max')) {
        this.el('screen').focus();
        if (!this.maxBanner) {
          this.maxBanner = h('div.screen-banner', 'Press F4 or Esc (when the program has ended) to return');
          this.el('screenWrap').appendChild(this.maxBanner);
          setTimeout(() => { if (this.maxBanner) { this.maxBanner.remove(); this.maxBanner = null; } }, 2500);
        }
      }
    }

    // ---- status bar ------------------------------------------------------------------------------------------
    setStatus(msg, isErr) {
      this.statusMsg = msg;
      this.statusErr = !!isErr;
      this.updateStatus();
    }
    updateStatus() {
      const sb = this.el('statusbar');
      const d = this.active;
      const cur = d ? d.editor.cursor() : null;
      const vm = this.runner && this.runner.vm;
      sb.innerHTML = '';
      sb.append(...[
        h('span.grow' + (this.statusErr ? '.msg-err' : ''), this.statusMsg || (d ? d.path : '')),
        vm && vm.statementsExecuted ? h('span', vm.statementsExecuted.toLocaleString() + ' stmts') : null,
        h('span', 'SCREEN ' + this.runner.display.mode),
        cur ? h('span', 'Ln ' + (cur.line + 1) + ', Col ' + (cur.col + 1)) : null,
        h('span', 'BASIC')].filter(Boolean));
    }
    updateUI() {
      const st = this.runner.state;
      const running = st === 'running' || st === 'waiting';
      const paused = st === 'paused';
      this.tb.run.disabled = running;
      this.tb.run.querySelector('.lbl').textContent = paused ? 'Continue' : 'Run';
      this.tb.pause.disabled = !running;
      this.tb.stop.disabled = !(running || paused);
      this.tb.out.disabled = !paused;
      const labels = { idle: 'Ready', running: 'Running', waiting: 'Running', paused: 'Paused', ended: 'Ended', error: 'Error', chain: 'Loading', evaldone: 'Ready' };
      this.statePill.textContent = (this.runner.immediate ? 'Immediate ' : '') + (labels[st] || st);
      this.el('app').classList.toggle('running', running || paused);
      this.el('app').classList.toggle('console', !!(this.console && this.console.active));
      this.statePill.className = 'state-pill ' + (running ? 'running' : paused ? 'paused' : st === 'error' ? 'error' : '');
      this.projLabel.textContent = this.active ? this.active.path : '';
      this.updateStatus();
    }

    // ---- documents ------------------------------------------------------------------------------------------------
    decodeText(bytes) {
      // Files are CP437 bytes. Detect UTF-8 (files created elsewhere) and convert.
      let s = RC.bytesToStr(bytes);
      if (/[\x80-\xff]/.test(s)) {
        try {
          const u = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
          return u.replace(/\r\n?/g, '\n');
        } catch (e) { /* not utf-8 */ }
      }
      if (s.endsWith('\x1a')) s = s.replace(/\x1a+$/, '');
      return RC.fromCP437(s).replace(/\r\n?/g, '\n');
    }
    encodeText(text) {
      const t = this.settings.lineEnding === 'crlf' ? text.replace(/\r?\n/g, '\r\n') : text;
      return RC.strToBytes(RC.toCP437(t));
    }
    docByPath(p) {
      if (!p) return null;
      const k = p.toUpperCase();
      return this.docs.find((d) => d.path.toUpperCase() === k) || null;
    }
    openFile(path, opts) {
      opts = opts || {};
      const r = this.vfs.resolve(path);
      let d = this.docByPath(r.display);
      if (!d) {
        let text = '';
        if (this.vfs.exists(path)) {
          if (!this.vfs.isReady(path)) {
            this.vfs.load(path).then(() => this.openFile(path, opts));
            return null;
          }
          text = this.decodeText(this.vfs.readFile(path));
        }
        d = this.createDoc(r.display, text);
      }
      if (!opts.noFocus || !this.active) this.activate(d);
      return d;
    }
    openProgramFile(path) { if (path) this.openFile(path); }
    createDoc(path, text) {
      const editor = new RC.Editor(this.el('editors'), { lang: LANG, settings: this.settings });
      editor.setValue(text);
      const d = { path, editor, dirty: false, savedText: text, name: path.replace(/^.*\\/, '') };
      editor.on('change', () => { d.dirty = editor.getValue() !== d.savedText; this.renderTabs(); this.scheduleOutline(); this.clearErrorMarks(d); });
      editor.on('cursor', () => this.updateStatus());
      editor.on('gutter', (line) => this.toggleBreakpoint(d.path, line));
      editor.on('gutterContext', (line, e) => this.gutterMenu(d, line, e));
      editor.on('bpsShifted', (map) => { this.breakpoints.set(d.path, new Map(map)); this.saveBreakpoints(); });
      editor.on('find', (rep) => this.openFind(rep));
      editor.on('gotoLine', () => this.gotoLineDialog());
      editor.on('help', (line, col) => { const w = B.wordAt(line, col); RC.Help.open(this, w ? w.word : null); });
      editor.on('hover', (pos, x, y) => this.callout.showFor(d, pos, x, y));
      editor.on('hoverOut', () => this.callout.scheduleHide(450));
      editor.on('context', (pos, e) => this.editorContextMenu(d, pos, e));
      editor.on('focus', () => { if (this.console && this.console.active && !this.runner.isActive()) { /* editing alongside console */ } });
      editor.setBreakpoints(this.breakpoints.get(path) || new Map());
      this.docs.push(d);
      return d;
    }
    activate(d) {
      this.active = d;
      this.toggleDrawer(false);
      if (d && this.isProtected(d.path)) this.setStatus('Example/tutorial file — edit and run freely; Save (Ctrl+S) keeps your changes as your own copy');
      else if (d && this.statusMsg && /^Example\/tutorial file/.test(this.statusMsg)) this.setStatus('');
      for (const x of this.docs) x.editor.show(x === d);
      this.renderTabs();
      this.renderOutline();
      this.renderExplorer();
      this.updateUI();
      this.saveSession();
    }
    renderTabs() {
      const tabs = this.el('editorTabs');
      tabs.innerHTML = '';
      for (const d of this.docs) {
        const x = h('span.x', { title: 'Close', role: 'button', 'aria-label': 'Close ' + d.name }, '×');
        const t = h('button.tab' + (d === this.active ? '.active' : ''), { type: 'button', role: 'tab', title: d.path, 'aria-selected': d === this.active ? 'true' : 'false' },
          this.isProtected(d.path) ? h('span.lock', { title: 'Example/tutorial file: Save makes your own copy' }, '◇') : null,
          d.name, d.dirty ? h('span.dirty', { title: 'Unsaved changes' }) : null, x);
        t.addEventListener('click', (e) => { if (e.target === x) { this.closeDoc(d); return; } this.activate(d); d.editor.focus(); });
        t.addEventListener('auxclick', (e) => { if (e.button === 1) this.closeDoc(d); });
        tabs.appendChild(t);
      }
      if (!this.docs.length) tabs.appendChild(h('span.muted', { style: { padding: '6px 10px' } }, 'No open files — use File ▸ New Program or pick a file in the explorer.'));
    }
    /** Example, library and tutorial originals are never overwritten; edits are saved as the user's own copy. */
    isProtected(path) { return /^C:\\(SAMPLES|LIBRARY|LESSONS)\\/i.test(path || ''); }
    async closeDoc(d) {
      if (d.dirty) {
        let r;
        if (this.isProtected(d.path)) {
          r = await RC.UI.modal({
            title: 'Keep your changes?',
            body: h('div', h('p', `You changed ${d.name}, which is an example/tutorial file. The original stays as it is.`), h('p', 'Save your version as your own file?')),
            buttons: [{ label: 'Cancel', value: 'cancel' }, { label: 'Discard Changes', value: 'no' }, { label: 'Save As My Copy…', value: 'copy', primary: true }],
            cancelValue: 'cancel',
          });
          if (r === 'cancel') return;
          if (r === 'copy' && !(await this.saveCopy(d))) return;
        } else {
          r = await RC.UI.modal({
            title: 'Unsaved changes', body: h('p', `Save changes to ${d.name}?`),
            buttons: [{ label: 'Cancel', value: 'cancel' }, { label: "Don't Save", value: 'no' }, { label: 'Save As…', value: 'as' }, { label: 'Save', value: 'yes', primary: true }],
            cancelValue: 'cancel',
          });
          if (r === 'cancel') return;
          if (r === 'yes' && !this.saveDoc(d)) return;
          if (r === 'as' && !(await this.saveAs(d))) return;
        }
      }
      const i = this.docs.indexOf(d);
      this.docs.splice(i, 1);
      d.editor.destroy();
      if (this.active === d) this.active = this.docs[Math.max(0, i - 1)] || null;
      if (this.active) this.activate(this.active); else { this.renderTabs(); this.updateUI(); }
      this.saveSession();
    }
    saveSession() {
      store.set('session', { open: this.docs.map((d) => d.path), active: this.active ? this.active.path : null });
    }
    /** Write a document to its own path. Protected originals are never written (returns false). */
    saveDoc(d) {
      if (this.isProtected(d.path)) return false;
      try {
        const perm = this.vfs.canWrite(d.path);
        this.vfs.writeFile(d.path, this.encodeText(d.editor.getValue()), { trusted: perm !== 'no' });
        d.savedText = d.editor.getValue();
        d.dirty = false;
        this.renderTabs();
        this.renderExplorer();
        return true;
      } catch (e) {
        RC.UI.toast('Could not save ' + d.name + ': ' + (e.message || RC.Basic.ERRORS[e.code] || e.code), 'err');
        return false;
      }
    }
    async save() {
      const d = this.active;
      if (!d) return;
      if (this.isProtected(d.path)) { await this.saveCopy(d); return; }
      if (this.saveDoc(d)) this.setStatus('Saved ' + d.path);
    }
    saveAll() { for (const d of this.docs) if (d.dirty && !this.isProtected(d.path)) this.saveDoc(d); }
    autosaveTick() {
      if (!this.settings.autosave) return;
      for (const d of this.docs) if (d.dirty && d.path[0] === 'C' && !this.isProtected(d.path)) this.saveDoc(d);
    }
    /** Save an example/tutorial file as the user's own copy (asks for a name). */
    async saveCopy(d) {
      const stem = d.name.replace(/\.[^.]*$/, '').toUpperCase().slice(0, 8);
      let n = 1, def;
      do { def = 'C:\\MYPROGS\\' + (n > 1 ? stem.slice(0, 8 - String(n).length) + n : stem) + '.BAS'; n++; } while (this.vfs.exists(def) || this.docByPath(def));
      return this.saveAs(d, { title: 'Save Your Copy', def, hint: 'This is an example or tutorial file, so your changes are saved as a new file of your own. Type a name, or a full path like C:\\GAMES\\MYSNAKE.BAS.' });
    }
    /** Save As: asks for a name; the document then refers to the new file. Returns true if saved. */
    async saveAs(d, opts) {
      d = d || this.active;
      opts = opts || {};
      if (!d) return false;
      const name = await RC.UI.prompt(opts.title || 'Save As', 'File name (e.g. GAME.BAS or C:\\MYPROGS\\GAME.BAS)', opts.def || d.path, { hint: opts.hint });
      if (!name) return false;
      let p = name.trim();
      if (!/\.[^\\.]*$/.test(p)) p += '.BAS';
      if (!/^[A-Za-z]:/.test(p) && !p.startsWith('\\')) p = (this.isProtected(d.path) ? 'C:\\MYPROGS' : d.path.replace(/\\[^\\]*$/, '')) + '\\' + p;
      let r;
      try { r = this.vfs.resolve(p); } catch (e) { RC.UI.toast('Invalid file name', 'err'); return false; }
      if (this.isProtected(r.display)) { RC.UI.toast('Pick a folder outside C:\\SAMPLES, C:\\LIBRARY and C:\\LESSONS (try C:\\MYPROGS)', 'err', 5000); return false; }
      if (this.vfs.exists(r.display) && r.display.toUpperCase() !== d.path.toUpperCase()) {
        if (!(await RC.UI.confirm('Replace file?', `${RC.escapeHtml(r.display)} already exists. Replace it?`, 'Replace'))) return false;
      }
      try {
        const dir = r.display.replace(/\\[^\\]*$/, '');
        if (dir.length > 3 && !this.vfs.exists(dir)) this.vfs.mkdir(dir);
      } catch (e) { /* parent missing: writeFile reports it */ }
      const other = this.docByPath(r.display);
      if (other && other !== d) { other.dirty = false; await this.closeDoc(other); }
      const oldPath = d.path;
      d.path = r.display; d.name = r.name;
      if (!this.saveDoc(d)) { d.path = oldPath; d.name = oldPath.replace(/^.*\\/, ''); return false; }
      // breakpoints follow the document to its new name
      const bps = this.breakpoints.get(oldPath);
      if (bps && bps.size) { this.breakpoints.set(d.path, new Map(bps)); if (this.isProtected(oldPath)) this.breakpoints.delete(oldPath); this.saveBreakpoints(); }
      this.setStatus('Saved as ' + d.path);
      this.activate(d);
      RC.UI.toast('Saved ' + d.path, 'ok');
      return true;
    }
    async newFile() {
      const dir = this.currentDir();
      let n = 1;
      while (this.vfs.exists(dir + '\\UNTITLED' + (n > 1 ? n : '') + '.BAS') || this.docByPath(dir + '\\UNTITLED' + (n > 1 ? n : '') + '.BAS')) n++;
      const def = 'UNTITLED' + (n > 1 ? n : '') + '.BAS';
      const name = await RC.UI.prompt('New Program', 'File name', def, { hint: 'Created in ' + dir + '. You can type a full path like C:\\GAMES\\PONG.BAS' });
      if (!name) return;
      let p = name.trim();
      if (!/\.[^\\.]*$/.test(p)) p += '.BAS';
      if (!/^[A-Za-z]:/.test(p) && !p.startsWith('\\')) p = dir + '\\' + p;
      try {
        const r = this.vfs.resolve(p);
        if (!this.vfs.exists(r.display)) this.vfs.writeFile(r.display, this.encodeText("' " + r.name + '\nCLS\nPRINT "Hello!"\n'), { trusted: true });
        const d = this.openFile(r.display);
        d.editor.setCursor(2, 0);
      } catch (e) { RC.UI.toast('Could not create file: ' + (e.message || e.code), 'err'); }
      this.renderExplorer();
    }
    async newFolder(base) {
      const dir = base || this.currentDir();
      const name = await RC.UI.prompt('New Folder', 'Folder name', 'PROJECT');
      if (!name) return;
      try { this.vfs.mkdir(dir + '\\' + name.trim()); this.expandedDirs.add((dir + '\\' + name.trim()).toUpperCase()); } catch (e) { RC.UI.toast('Could not create folder: ' + (e.message || RC.Basic.ERRORS[e.code]), 'err'); }
      this.renderExplorer();
    }
    currentDir() {
      if (this.selectedPath) {
        try { const st = this.vfs.stat(this.selectedPath); if (st && st.type === 'dir') return this.vfs.resolve(this.selectedPath).display.replace(/\\$/, ''); } catch (e) { /* ignore */ }
      }
      if (this.active) return this.active.path.replace(/\\[^\\]*$/, '');
      return 'C:\\MYPROGS';
    }
    async openDialog() {
      // simple picker listing all BASIC files
      const files = [];
      const walk = (letter) => { for (const x of this.vfs.walk(letter + ':\\')) if (x.entry.type === 'file') files.push(letter + ':\\' + x.key.slice(1).split('\\').map((_, i, arr) => arr[i]).join('\\')); };
      for (const L of Object.keys(this.vfs.drives)) walk(L);
      const list = h('div', { style: { maxHeight: '50vh', overflow: 'auto', fontFamily: 'var(--font-code)' } });
      let chosen = null;
      const filter = h('input', { type: 'text', placeholder: 'Type to filter…', 'aria-label': 'Filter files' });
      const render = () => {
        list.innerHTML = '';
        const q = filter.value.toUpperCase();
        for (const f of files.filter((f) => f.toUpperCase().includes(q)).slice(0, 500)) {
          const disp = this.vfs.resolve(f).display;
          const row = h('div.list-row.clickable', disp);
          row.addEventListener('click', () => { chosen = disp; close(); });
          list.appendChild(row);
        }
      };
      let close = () => {};
      filter.addEventListener('input', render);
      render();
      await RC.UI.modal({ title: 'Open File', body: h('div', filter, list), buttons: [{ label: 'Cancel', value: null }, { label: 'From Computer…', value: 'computer' }], onOpen: (box, c) => { close = () => c(null); } }).then((v) => { if (v === 'computer') this.importFromComputer(); });
      if (chosen) this.openFile(chosen);
    }
    async importFromComputer(dir) {
      const files = await RC.UI.pickFiles('', true);
      if (!files.length) return;
      dir = dir || this.currentDir();
      let last = null;
      for (const f of files) {
        const buf = new Uint8Array(await f.arrayBuffer());
        const p = dir + '\\' + f.name.replace(/[<>:"|?*]/g, '_');
        try {
          if (this.vfs.exists(p) && !(await RC.UI.confirm('Replace file?', `${p} exists. Replace?`, 'Replace'))) continue;
          this.vfs.writeFile(p, buf, { trusted: true });
          last = p;
        } catch (e) { RC.UI.toast('Could not import ' + f.name + ': ' + (e.message || e.code), 'err'); }
      }
      this.renderExplorer();
      if (last && /\.(BAS|BI|BM|TXT)$/i.test(last)) {
        const d = this.docByPath(last);
        if (d) { d.editor.setValue(this.decodeText(this.vfs.readFile(last))); d.savedText = d.editor.getValue(); d.dirty = false; }
        this.openFile(last);
      }
      RC.UI.toast(`Imported ${files.length} file(s) into ${dir}`, 'ok');
    }
    downloadActive() {
      const d = this.active;
      if (!d) return;
      this.saveDoc(d);
      RC.UI.download(d.name, this.vfs.readFile(d.path));
    }
    downloadFile(path) { RC.UI.download(path.replace(/^.*\\/, ''), this.vfs.readFile(path)); }
    mainText() {
      const d = this.console && this.console.active ? this.console.doc() : this.active;
      return d ? d.editor.getValue() : '';
    }
    lineText(path, line) {
      const d = this.docByPath(path);
      if (d) return d.editor.getLine(line);
      try { return this.decodeText(this.vfs.readFile(path)).split('\n')[line] || ''; } catch (e) { return ''; }
    }
    focusEditor() { if (this.active) this.active.editor.focus(); }
    zoom(dir) {
      this.settings.fontSize = Math.max(10, Math.min(28, this.settings.fontSize + dir));
      this.saveSettings();
      this.applyTheme();
    }

    // ---- outline (procedures) ------------------------------------------------------------------------------
    scheduleOutline() { clearTimeout(this._olt); this._olt = setTimeout(() => this.renderOutline(), 400); }
    renderOutline() {
      const el = this.el('procList');
      el.innerHTML = '';
      if (!this.active) return;
      const items = B.outline(this.active.editor.getValue());
      if (!items.length) { el.appendChild(h('div.proc-item.muted', '(main module only)')); return; }
      el.appendChild(h('div.proc-item', { onclick: () => this.active.editor.setCursor(0, 0) }, h('span.k', 'MODULE '), this.active.name));
      for (const it of items) {
        el.appendChild(h('div.proc-item', { title: 'Line ' + (it.line + 1), onclick: () => { this.active.editor.setCursor(it.line, 0); this.setMobileView('editor'); } },
          h('span.k', it.kind === 'label' ? '  ' : it.kind + ' '), it.name));
      }
    }
    async subsDialog() {
      if (!this.active) return;
      const items = B.outline(this.active.editor.getValue()).filter((x) => x.kind !== 'label');
      const list = h('div', { style: { fontFamily: 'var(--font-code)' } });
      let close;
      list.appendChild(h('div.list-row.clickable', { onclick: () => { this.active.editor.setCursor(0, 0); close(); } }, h('b', this.active.name), h('span.muted', ' (main module)')));
      for (const it of items) list.appendChild(h('div.list-row.clickable', { onclick: () => { this.active.editor.setCursor(it.line, 0); close(); } }, '   ' + it.kind + ' ' + it.name));
      await RC.UI.modal({ title: 'SUBs', body: list, buttons: [{ label: 'Close', value: null }], onOpen: (b, c) => { close = () => c(null); } });
    }

    // ---- explorer -------------------------------------------------------------------------------------------
    buildExplorer() {
      this.expandedDirs = new Set(store.get('expandedDirs', ['C:\\', 'C:\\MYPROGS', 'C:\\SAMPLES']).map((s) => s.toUpperCase()));
      const a = this.el('explorerActions');
      const mk = (ic, title, fn) => h('button.icon-btn', { type: 'button', title, 'aria-label': title, onclick: fn }, icon(ic));
      a.append(mk('newFile', 'New program', () => this.newFile()), mk('newFolder', 'New folder', () => this.newFolder()),
        mk('upload', 'Import files from computer', () => this.importFromComputer()), mk('drive', 'Mount a computer folder as D:', () => this.mountDialog()),
        mk('share', 'Share project', () => this.shareDialog()));
      this.vfs.on('change', () => { clearTimeout(this._ext); this._ext = setTimeout(() => this.renderExplorer(), 150); });
      this.vfs.on('mount', () => this.renderExplorer());
      this.renderExplorer();
    }
    renderExplorer() {
      const tree = this.el('explorerTree');
      if (!tree) return;
      tree.innerHTML = '';
      const activeKey = this.active ? this.active.path.toUpperCase() : '';
      const addDir = (path, depth, label) => {
        const key = path.toUpperCase();
        const open = this.expandedDirs.has(key);
        const isDrive = /^[A-Z]:\\?$/.test(key);
        const row = h('div.tree-item' + (this.selectedPath === key ? '.selected' : ''), { style: { paddingLeft: (6 + depth * 12) + 'px' }, role: 'treeitem', 'aria-expanded': open ? 'true' : 'false', tabindex: '0' },
          h('span.tw', open ? '▾' : '▸'), icon(isDrive ? 'drive' : open ? 'folderOpen' : 'folder'), h('span.nm', label));
        row.addEventListener('click', () => {
          this.selectedPath = key;
          if (open) this.expandedDirs.delete(key); else this.expandedDirs.add(key);
          store.set('expandedDirs', [...this.expandedDirs]);
          this.renderExplorer();
        });
        row.addEventListener('contextmenu', (e) => { e.preventDefault(); this.selectedPath = key; this.dirMenu(path, e); });
        tree.appendChild(row);
        if (!open) return;
        let list = [];
        try { list = this.vfs.list(path); } catch (e) { return; }
        for (const e of list) {
          const p = (path.endsWith('\\') ? path : path + '\\') + e.name;
          if (e.type === 'dir') addDir(p, depth + 1, e.name);
          else {
            const pk = p.toUpperCase();
            const isMain = this.mainFor(path) && this.mainFor(path).toUpperCase() === pk;
            const fr = h('div.tree-item' + (pk === activeKey ? '.selected' : '') + (isMain ? '.main' : ''), { style: { paddingLeft: (18 + depth * 12) + 'px' }, title: p + ' (' + e.size + ' bytes)', role: 'treeitem', tabindex: '0' },
              icon('file'), h('span.nm', e.name), isMain ? h('span.badge', 'main') : null);
            fr.addEventListener('click', () => { this.selectedPath = pk; if (/\.(BAS|BI|BM|TXT|DAT|CSV|INI|MD|LOG)$/i.test(e.name) || e.size < 65536) { this.openFile(p); this.setMobileView('editor'); } else this.renderExplorer(); });
            fr.addEventListener('dblclick', () => { if (/\.BAS$/i.test(e.name)) { this.openFile(p); this.run(); } });
            fr.addEventListener('contextmenu', (ev) => { ev.preventDefault(); this.fileMenu(p, ev); });
            fr.addEventListener('keydown', (ev) => { if (ev.key === 'Enter') fr.click(); });
            tree.appendChild(fr);
          }
        }
      };
      for (const L of Object.keys(this.vfs.drives).sort()) {
        const d = this.vfs.drives[L];
        addDir(L + ':\\', 0, L + ': ' + (d.host ? '(' + d.label + ' — your computer' + (d.writable === true ? '' : d.writable === 'ask' ? ', ask before writing' : ', read-only') + ')' : '(virtual disk)'));
      }
    }
    mainFor(dir) {
      const m = store.get('mains', {});
      return m[dir.toUpperCase().replace(/\\$/, '')] || null;
    }
    setMain(path) {
      const m = store.get('mains', {});
      const dir = path.replace(/\\[^\\]*$/, '').toUpperCase();
      if (m[dir] && m[dir].toUpperCase() === path.toUpperCase()) delete m[dir]; else m[dir] = path;
      store.set('mains', m);
      this.renderExplorer();
      this.updateUI();
    }
    fileMenu(p, e) {
      RC.UI.showMenu([
        { label: 'Open', action: () => this.openFile(p) },
        /\.BAS$/i.test(p) ? { label: 'Run', action: () => { this.openFile(p); this.run(); } } : null,
        /\.BAS$/i.test(p) ? { label: this.mainFor(p.replace(/\\[^\\]*$/, '')) && this.mainFor(p.replace(/\\[^\\]*$/, '')).toUpperCase() === p.toUpperCase() ? 'Unset Main Program' : 'Set as Main Program of Folder', action: () => this.setMain(p) } : null,
        { sep: true },
        { label: 'Rename…', action: () => this.renamePath(p) },
        { label: 'Duplicate', action: () => this.duplicatePath(p) },
        { label: 'Download to Computer', action: () => this.downloadFile(p) },
        { sep: true },
        { label: 'Delete', action: () => this.deletePath(p) },
      ], e.clientX, e.clientY);
    }
    dirMenu(p, e) {
      RC.UI.showMenu([
        { label: 'New Program Here…', action: () => { this.selectedPath = p.toUpperCase(); this.newFile(); } },
        { label: 'New Folder Here…', action: () => this.newFolder(p.replace(/\\$/, '')) },
        { label: 'Import Files Here…', action: () => this.importFromComputer(p.replace(/\\$/, '')) },
        { sep: true },
        { label: 'Share This Folder as Link…', action: () => this.shareDialog(p.replace(/\\$/, '')) },
        { label: 'Download Folder (.zip)', action: () => this.downloadZip(p.replace(/\\$/, '')) },
        /^[A-Z]:\\?$/i.test(p) ? null : { sep: true },
        /^[A-Z]:\\?$/i.test(p) ? null : { label: 'Rename…', action: () => this.renamePath(p) },
        /^[A-Z]:\\?$/i.test(p) ? null : { label: 'Delete Folder', action: () => this.deletePath(p) },
      ], e.clientX, e.clientY);
    }
    async renamePath(p) {
      const old = p.replace(/^.*\\/, '');
      const name = await RC.UI.prompt('Rename', 'New name', old);
      if (!name || name === old) return;
      const np = p.replace(/[^\\]*$/, '') + name.trim();
      try {
        this.vfs.rename(p, np);
        const d = this.docByPath(p);
        if (d) { d.path = this.vfs.resolve(np).display; d.name = name.trim(); this.renderTabs(); }
        this.renderExplorer();
      } catch (e) { RC.UI.toast('Rename failed: ' + (e.message || RC.Basic.ERRORS[e.code]), 'err'); }
    }
    duplicatePath(p) {
      let n = 2;
      const base = p.replace(/(\.[^.\\]*)?$/, '');
      const ext = (/\.[^.\\]*$/.exec(p) || [''])[0];
      while (this.vfs.exists(base + n + ext)) n++;
      try { this.vfs.writeFile(base + n + ext, this.vfs.readFile(p).slice(), { trusted: true }); } catch (e) { RC.UI.toast('Copy failed', 'err'); }
    }
    async deletePath(p) {
      const st = this.vfs.stat(p);
      if (!st) return;
      if (!(await RC.UI.confirm('Delete?', `Delete ${RC.escapeHtml(p)}${st.type === 'dir' ? ' and everything in it' : ''}? This cannot be undone.`, 'Delete'))) return;
      try {
        if (st.type === 'dir') {
          const items = this.vfs.walk(p).sort((a, b) => b.key.length - a.key.length);
          const r = this.vfs.resolve(p);
          for (const it of items) {
            const full = r.drive + ':' + it.key;
            if (it.entry.type === 'dir') this.vfs.rmdir(full); else { const d = this.docByPath(this.vfs.resolve(full).display); if (d) { d.dirty = false; this.closeDoc(d); } this.vfs.unlink(full); }
          }
          this.vfs.rmdir(p);
        } else {
          const d = this.docByPath(this.vfs.resolve(p).display);
          if (d) { d.dirty = false; this.closeDoc(d); }
          this.vfs.unlink(p);
        }
      } catch (e) { RC.UI.toast('Delete failed: ' + (e.message || RC.Basic.ERRORS[e.code]), 'err'); }
      this.renderExplorer();
    }

    // ---- sharing / zip -------------------------------------------------------------------------------------
    collectFolder(dir) {
      this.saveAll();
      const r = this.vfs.resolve(dir);
      const files = {};
      for (const it of this.vfs.walk(dir)) {
        if (it.entry.type !== 'file' || !it.entry.data) continue;
        // use original names
        const parts = it.rel.split('\\');
        let cur = r.key === '\\' ? '' : r.key;
        const names = [];
        for (const part of parts) { cur += '\\' + part; const e = this.vfs.drives[r.drive].get(cur); names.push(e ? e.name : part); }
        files[names.join('/')] = it.entry.data;
      }
      return files;
    }
    async shareDialog(dir) {
      dir = dir || (this.active ? this.active.path.replace(/\\[^\\]*$/, '') : this.currentDir());
      const files = this.collectFolder(dir);
      const names = Object.keys(files);
      if (!names.length) { RC.UI.toast('That folder is empty', 'err'); return; }
      const total = names.reduce((n, k) => n + files[k].length, 0);
      if (total > 2 * 1024 * 1024) { RC.UI.toast('Folder is too large to share as a link (2 MB max). Use Download Project instead.', 'err', 6000); return; }
      const main = this.mainFor(dir) || (this.active && this.active.path.toUpperCase().startsWith(dir.toUpperCase()) ? this.active.path : null);
      const meta = { name: dir.replace(/^.*\\/, '') || 'PROJECT', main: main ? main.slice(dir.length + 1).replace(/\\/g, '/') : null, lang: 'basic' };
      const code = await RC.Share.pack(meta, files);
      const link = location.href.replace(/#.*$/, '') + '#share=' + code;
      const ta = h('textarea', { readonly: true, 'aria-label': 'Share code' }, code);
      const linkIn = h('input', { type: 'text', readonly: true, value: link, 'aria-label': 'Share link' });
      const body = h('div',
        h('p', `Sharing ${names.length} file(s) from `, h('b', dir), ` (${(code.length / 1024).toFixed(1)} KB encoded). Anyone who opens the link gets a copy in their own browser — nothing is uploaded anywhere.`),
        h('label', 'Link'), linkIn,
        h('label', 'Or share this code (paste it into File ▸ Import Shared Code)'), ta,
        link.length > 8000 ? h('p.muted', 'This link is long; some chat apps may cut it. Sharing the code text or a .zip works too.') : null);
      const r = await RC.UI.modal({ title: 'Share Project', body, wide: true, buttons: [{ label: 'Close', value: null }, { label: 'Copy Code', value: 'code' }, { label: 'Copy Link', value: 'link', primary: true }] });
      if (r) {
        try { await navigator.clipboard.writeText(r === 'link' ? link : code); RC.UI.toast('Copied to clipboard', 'ok'); } catch (e) { RC.UI.toast('Copy failed; select the text and copy it manually', 'err'); }
      }
    }
    async importShareDialog() {
      const ta = h('textarea', { placeholder: 'Paste a share code (CPD1.…) or a full share link', 'aria-label': 'Share code' });
      const v = await RC.UI.modal({ title: 'Import Shared Project', body: h('div', ta), buttons: [{ label: 'Cancel', value: null }, { label: 'Import', value: () => ta.value, primary: true }] });
      if (v) this.importShare(v);
    }
    async importShare(code) {
      let data;
      try { data = await RC.Share.unpack(code); } catch (e) { RC.UI.alert('Import failed', RC.escapeHtml(e.message)); return; }
      const names = Object.keys(data.files);
      let base = 'C:\\SHARED\\' + (data.meta.name || 'PROJECT').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 20);
      const ok = await RC.UI.confirm('Open shared project?', `<p>This shared project contains ${names.length} file(s):</p><p style="font-family:var(--font-code)">${names.slice(0, 12).map(RC.escapeHtml).join('<br>')}${names.length > 12 ? '<br>…' : ''}</p><p>It will be copied into a new folder on your virtual disk (C:).</p>`, 'Import');
      if (!ok) return;
      try {
        if (!this.vfs.exists('C:\\SHARED')) this.vfs.mkdir('C:\\SHARED');
        let target = base, n = 2;
        while (this.vfs.exists(target)) target = base + n++;
        this.vfs.mkdir(target);
        for (const [rel, bytes] of Object.entries(data.files)) {
          const parts = rel.split(/[\\/]/);
          let cur = target;
          for (let i = 0; i < parts.length - 1; i++) { cur += '\\' + parts[i]; if (!this.vfs.exists(cur)) this.vfs.mkdir(cur); }
          this.vfs.writeFile(target + '\\' + parts.join('\\'), bytes, { trusted: true });
        }
        this.expandedDirs.add('C:\\SHARED'); this.expandedDirs.add(target.toUpperCase());
        const main = data.meta.main ? target + '\\' + data.meta.main.replace(/\//g, '\\') : (names.find((x) => /\.BAS$/i.test(x)) ? target + '\\' + names.find((x) => /\.BAS$/i.test(x)).replace(/\//g, '\\') : null);
        if (main) { this.openFile(main); if (data.meta.main) this.setMain(this.vfs.resolve(main).display); }
        this.renderExplorer();
        RC.UI.toast('Imported into ' + target, 'ok');
      } catch (e) { RC.UI.alert('Import failed', RC.escapeHtml(e.message || RC.Basic.ERRORS[e.code] || String(e))); }
    }
    downloadZip(dir) {
      dir = dir || (this.active ? this.active.path.replace(/\\[^\\]*$/, '') : 'C:\\');
      const files = this.collectFolder(dir);
      const zip = RC.Zip.create(files);
      RC.UI.download((dir.replace(/^.*\\/, '') || 'DISK') + '.zip', zip, 'application/zip');
    }

    // ---- mounting a real folder ---------------------------------------------------------------------------
    async mountDialog() {
      if (!window.showDirectoryPicker) {
        RC.UI.alert('Not supported in this browser', '<p>Mounting a real folder needs the File System Access API (Chrome, Edge, Opera and other Chromium browsers on desktop).</p><p>You can still move files in and out with <b>Import Files</b> and <b>Download</b>.</p>');
        return;
      }
      const sel = h('select', { 'aria-label': 'Permission' },
        h('option', { value: 'read' }, 'Read-only (programs can read files, never write)'),
        h('option', { value: 'ask' }, 'Ask me before a program writes (recommended)'),
        h('option', { value: 'write' }, 'Allow programs to write'));
      sel.value = 'ask';
      const v = await RC.UI.modal({
        title: 'Mount a Folder as Drive D:',
        body: h('div', h('p', 'Pick a folder on your computer. Your BASIC programs will see it as drive D: (for example OPEN "D:\\SCORES.TXT" FOR INPUT AS #1). Programs cannot access anything outside it.'), h('label', 'Permission for programs'), sel,
          h('p.muted', { style: { marginTop: '8px' } }, 'Your browser will also ask for permission. The mount lasts until you reload the page.')),
        buttons: [{ label: 'Cancel', value: null }, { label: 'Choose Folder…', value: () => sel.value, primary: true }],
      });
      if (!v) return;
      try {
        const handle = await window.showDirectoryPicker({ mode: v === 'read' ? 'read' : 'readwrite' });
        await this.vfs.mountHandle('D', handle, v);
        this.expandedDirs.add('D:\\');
        this.renderExplorer();
        RC.UI.toast('Mounted "' + handle.name + '" as D:', 'ok');
      } catch (e) { if (e.name !== 'AbortError') RC.UI.toast('Mount failed: ' + e.message, 'err'); }
    }
    async askWritePermission(path) {
      const r = await RC.UI.modal({
        title: 'Allow file write?',
        body: h('div', h('p', 'Your program wants to write to:'), h('p', h('b', { style: { fontFamily: 'var(--font-code)' } }, path)), h('p.muted', 'This is a folder on your real computer.')),
        buttons: [{ label: 'Deny', value: 'no' }, { label: 'Allow Once', value: 'once' }, { label: 'Always Allow for D:', value: 'always', primary: true }],
        cancelValue: 'no', dismissable: false,
      });
      if (r === 'always') { const d = this.vfs.drives[path[0].toUpperCase()]; if (d) d.writable = true; this.renderExplorer(); return true; }
      if (r === 'once') {
        const d = this.vfs.drives[path[0].toUpperCase()];
        if (d) { d.writable = true; setTimeout(() => { if (d.writable === true) d.writable = 'ask'; }, 0); }
        return true;
      }
      return false;
    }

    // ---- running ---------------------------------------------------------------------------------------------
    runTarget() {
      const d = this.active;
      if (!d) return null;
      const dir = d.path.replace(/\\[^\\]*$/, '');
      const main = this.mainFor(dir);
      if (main) {
        try { if (this.vfs.exists(main) || this.docByPath(main)) return main; } catch (e) { /* ignore */ }
      }
      return d.path;
    }
    runOrContinue() {
      const st = this.runner.state;
      if (st === 'paused') { this.continue(); return; }
      if (st === 'running' || st === 'waiting') return;
      this.run();
    }
    run(opts) {
      if (this.console && this.console.active && !opts) { this.console.runProgram(); return; }
      const path = (opts && opts.path) || this.runTarget();
      if (!path) { RC.UI.toast('Open or create a program first', 'err'); return; }
      const doc = this.docByPath(path);
      this.runCount = (this.runCount || 0) + 1;
      if (this.settings.autosave) this.saveAll();
      const text = doc ? doc.editor.getValue() : this.decodeText(this.vfs.readFile(path));
      this.clearExecMarks();
      for (const d of this.docs) d.editor.setError(null);
      this.selFrame = null;
      try {
        this.runner.start(path, text, opts);
        this.panels.setProblems([]);
        this.setStatus('Running ' + path.replace(/^.*\\/, '') + ' — Ctrl+Break to pause');
        this.focusScreen();
        if (this.isMobile()) this.setMobileView('screen');
      } catch (e) {
        if (e instanceof B.CompileError) this.showCompileError(e);
        else { RC.UI.alert('Internal error', RC.escapeHtml(String(e && e.stack || e))); console.error(e); }
      }
      this.updateUI();
    }
    restart() { this.stop(); this.run(); }
    stop() {
      if (this.console && this.console.active && this.runner.state === 'paused') { /* keep console */ }
      this.runner.stop();
      this.clearExecMarks();
      this.setStatus('Stopped');
      this.updateUI();
      this.panels.refreshAll();
    }
    continue() {
      this.clearExecMarks();
      this.runner.resume();
      this.focusScreen(true);
      this.updateUI();
    }
    step(mode) {
      const st = this.runner.state;
      if (st === 'paused') {
        this.clearExecMarks();
        this.runner.resume(mode);
        this.updateUI();
        return;
      }
      if (st === 'running' || st === 'waiting') return;
      if (mode === 'out') return;
      this.run({ stepInto: true });
    }
    runToCursor() {
      const d = this.active;
      if (!d) return;
      const line = d.editor.cursor().line;
      const st = this.runner.state;
      const set = () => {
        const vm = this.runner.vm;
        const idx = B.Debug.nearestStmt(vm.prog, d.path, line);
        if (idx < 0) { RC.UI.toast('No statement at or after the cursor', 'err'); return false; }
        vm.tempBreak = idx;
        vm.breakpoints.add(idx);
        vm.updateDbgFlag();
        const off = vm.on('pause', () => { off(); this.runner.applyBreakpoints(); });
        return true;
      };
      if (st === 'paused') { if (set()) this.continue(); return; }
      if (st === 'running' || st === 'waiting') return;
      this.run();
      if (this.runner.vm && this.runner.state === 'running') set();
    }
    setNextStatement() {
      const d = this.active;
      const vm = this.runner.vm;
      if (!d || !vm || vm.state !== 'paused') return;
      try {
        B.Debug.setNextStatement(vm, d.path, d.editor.cursor().line);
        this.onPaused('step');
      } catch (e) { RC.UI.toast(e.message, 'err'); }
    }
    focusScreen(onlyIfWaiting) {
      if (this.el('app').dataset.mview === 'editor' && this.isMobile()) return;
      this.el('screen').focus({ preventScroll: true });
    }

    bindRunner() {
      const r = this.runner;
      r.on('state', (st) => { if (st !== 'paused' && st !== 'error') this.callout.hide(); this.updateUI(); });
      r.on('pause', (why) => this.onPaused(why));
      r.on('end', (info) => this.onEnded(info));
      r.on('error', (info, vm) => this.onRuntimeError(info, vm));
      r.on('compileError', (e) => this.showCompileError(e));
      r.on('chained', (path) => { this.setStatus('Running ' + path); this.updateUI(); });
      r.on('animate', () => this.animateTick());
      r.on('immediateDone', () => { this.updateUI(); if (this.console && this.console.active) this.console.ok(); });
    }
    onPaused(why) {
      const vm = this.runner.vm;
      this.selFrame = null;
      const msgs = { breakpoint: 'Paused at breakpoint', step: 'Paused', watch: 'Watchpoint triggered', user: 'Paused', break: 'Break', stop: 'STOP statement' };
      let m = msgs[why] || 'Paused';
      const st = vm.currentStmt();
      if (st && st.lineNo !== null && st.lineNo !== undefined) m += ' in line ' + st.lineNo;
      if (why === 'watch' && vm.lastWatch) m += ': ' + vm.lastWatch.expr;
      this.setStatus(m + ' — F5 continue, F8 step, F10 step over');
      if (this.console && this.console.active && (why === 'break' || why === 'stop')) this.console.onBreak(st);
      this.showExecPosition();
      this.panels.refreshAll();
      if (!this.console || !this.console.active) {
        if (['vars', 'watch', 'stack', 'immediate', 'history'].indexOf(this.panels.active) < 0) this.panels.show('vars');
      }
      this.updateUI();
    }
    showExecPosition() {
      const vm = this.runner.vm;
      this.clearExecMarks();
      if (!vm) return;
      const fi = this.selectedFrameIndex();
      const top = vm.frames.length - 1;
      const pos = vm.framePos(top);
      if (pos && pos.file) {
        const d = this.openFile(pos.file, { noFocus: true }) || this.docByPath(pos.file);
        if (d) { if (fi === top) this.activate(d); d.editor.setExec(pos.line); }
      }
      if (fi !== top) {
        const fp = vm.framePos(fi);
        if (fp && fp.file) {
          const d = this.openFile(fp.file);
          if (d) d.editor.setFrame(fp.line);
        }
      }
    }
    clearExecMarks() { for (const d of this.docs) { d.editor.setExec(null); d.editor.setFrame(null); } }
    clearErrorMarks(d) { if (d.editor.marks.err !== null) d.editor.setError(null); }
    animateTick() {
      const vm = this.runner.vm;
      if (!vm) return;
      const pos = vm.framePos();
      if (!pos || !pos.file) return;
      const d = this.docByPath(pos.file);
      if (d) {
        if (this.active !== d) this.activate(d);
        if (d.editor.marks.exec !== pos.line) d.editor.setExec(pos.line);
      }
      this.panels.refresh('history');
    }
    onEnded(info) {
      this.clearExecMarks();
      if (info.reason === 'stopped') this.setStatus('Program stopped');
      else this.setStatus('Program ended — press F5 to run again' + (this.isMobile() ? '' : ', F4 to view output'));
      this.panels.refreshAll();
      this.updateUI();
      if (this.console && this.console.active && info.reason !== 'immediate') this.console.ok();
      if (info.reason === 'system' && this.console && this.console.active) this.console.toggle(false);
    }
    onRuntimeError(info, vm) {
      this.clearExecMarks();
      const loc = info.lineNo !== null && info.lineNo !== undefined ? ` in line ${info.lineNo}` : '';
      const msg = `${info.message}${loc}`;
      this.setStatus('Runtime error ' + info.code + ': ' + msg, true);
      this.panels.log(`Runtime error ${info.code}: ${msg}` + (info.pos ? `  (${(info.pos.file || '').replace(/^.*\\/, '')}:${info.pos.line + 1})` : ''), 'err', info.pos);
      const hint = RC.Help.errorHint(info.code);
      if (hint) this.panels.log('Hint: ' + hint, 'note');
      if (info.pos && info.pos.file) {
        const d = this.openFile(info.pos.file);
        if (d) d.editor.setError(info.pos.line);
      }
      this.panels.setProblems([{ kind: 'Runtime error ' + info.code, message: msg, pos: info.pos }]);
      this.panels.refreshAll();
      if (this.console && this.console.active) this.console.onError(info);
      else if (this.panels.active !== 'immediate') this.panels.show('immediate');
      RC.UI.toast(h('div', h('b', 'Runtime error: '), info.message, h('div.muted', { style: { fontSize: '12px' } }, 'Variables are kept — inspect them in the Variables panel.')), 'err', 6000);
      this.updateUI();
    }
    showCompileError(e) {
      const pos = e.pos;
      const where = pos ? ` (${(pos.file || '').replace(/^.*\\/, '')}:${pos.line + 1})` : '';
      this.setStatus('Syntax: ' + e.message + where, true);
      this.panels.setProblems([{ kind: 'Syntax error', message: e.message, pos }]);
      this.panels.log('Syntax error: ' + e.message + where, 'err', pos);
      if (pos && pos.file) {
        const d = this.openFile(pos.file);
        if (d) { d.editor.setError(pos.line); d.editor.setCursor(pos.line, pos.col || 0); }
      }
      if (!(this.console && this.console.active)) this.panels.show('problems');
      if (this.console && this.console.active) this.console.onCompileError(e);
      else RC.UI.toast(h('div', h('b', 'Syntax error: '), e.message + where), 'err', 6000);
      this.updateUI();
    }

    // ---- debugging helpers --------------------------------------------------------------------------------
    selectedFrameIndex() {
      const vm = this.runner.vm;
      if (!vm) return 0;
      if (this.selFrame === null || this.selFrame >= vm.frames.length) return vm.frames.length - 1;
      return this.selFrame;
    }
    selectFrame(i) {
      this.selFrame = i;
      this.showExecPosition();
      this.panels.refreshAll();
    }
    immediate(text) {
      const r = this.runner;
      const vm = r.vm;
      this.panels.log('> ' + text, 'in');
      const t = text.trim();
      const isExpr = /^\?\s*[^;,]*$/.test(t) && !/^\?\s*$/.test(t) && !/[:]/.test(t);
      try {
        if (vm && vm.state === 'paused') {
          if (isExpr) {
            const res = B.Debug.evaluate(vm, t.replace(/^\?\s*/, ''), this.selectedFrameIndex());
            this.panels.log(B.Debug.fmtValue(res.value, res.type));
          } else {
            B.Debug.execute(vm, t, this.selectedFrameIndex());
            this.panels.log('OK', 'note');
          }
          this.panels.refreshAll();
          return;
        }
        if (vm && (vm.state === 'running' || vm.state === 'waiting')) { this.panels.log('The program is running — pause it first (Ctrl+Break).', 'err'); return; }
        // Not running: run asynchronously against the last program's variables
        if (isExpr && vm) {
          try {
            const res = B.Debug.evaluate(vm, t.replace(/^\?\s*/, ''), 0);
            this.panels.log(B.Debug.fmtValue(res.value, res.type));
            return;
          } catch (e) { /* fall back to statement mode */ }
        }
        r.ensureIdleVm();
        if (!r.runImmediate(t, () => { this.panels.log('OK', 'note'); this.panels.refreshAll(); })) this.panels.log('Busy', 'err');
        else this.focusScreen();
        this.updateUI();
      } catch (e) {
        this.panels.log(e.message || String(e), 'err');
      }
    }
    hover(d, pos, x, y) {
      const vm = this.runner.vm;
      if (!vm || (vm.state !== 'paused' && vm.state !== 'error')) return;
      const w = B.wordAt(pos.text, pos.col);
      if (!w || w.kind !== 'id') return;
      try {
        const r = B.Debug.evaluate(vm, w.expr, this.selectedFrameIndex());
        d.editor.showTip(w.expr + ' = ' + B.Debug.fmtValue(r.value, r.type), x, y);
      } catch (e) {
        try {
          const r = B.Debug.evaluate(vm, w.word, this.selectedFrameIndex());
          d.editor.showTip(w.word + ' = ' + B.Debug.fmtValue(r.value, r.type), x, y);
        } catch (e2) { /* not evaluable */ }
      }
    }
    syncWatchpoints() {
      const vm = this.runner.vm;
      if (!vm) return;
      vm.watchpoints = this.panels.watches.filter((w) => w.mode && w.mode !== 'none').map((w) => {
        const cond = (v) => {
          try { const r = B.Debug.evaluateCached(v, w.expr); return r.value; } catch (e) { return undefined; }
        };
        return { fn: cond, mode: w.mode, expr: w.expr, last: undefined };
      });
      vm.updateDbgFlag();
    }

    // ---- breakpoints -------------------------------------------------------------------------------------------
    saveBreakpoints() {
      const o = {};
      for (const [p, lines] of this.breakpoints) if (lines.size) o[p] = [...lines].map(([line, b]) => ({ line, cond: b.cond, disabled: b.disabled }));
      store.set('breakpoints', o);
    }
    breakpointCount() { let n = 0; for (const l of this.breakpoints.values()) n += l.size; return n; }
    toggleBreakpoint(path, line) {
      let lines = this.breakpoints.get(path);
      if (!lines) { lines = new Map(); this.breakpoints.set(path, lines); }
      if (lines.has(line)) lines.delete(line); else lines.set(line, { cond: null, disabled: false });
      this.afterBpChange(path);
    }
    updateBreakpoint(path, line, props) {
      const lines = this.breakpoints.get(path);
      if (!lines || !lines.has(line)) return;
      Object.assign(lines.get(line), props);
      this.afterBpChange(path);
    }
    clearBreakpoints() {
      for (const p of this.breakpoints.keys()) { this.breakpoints.set(p, new Map()); this.afterBpChange(p); }
    }
    afterBpChange(path) {
      const d = this.docByPath(path);
      if (d) d.editor.setBreakpoints(this.breakpoints.get(path) || new Map());
      this.saveBreakpoints();
      if (this.runner.vm) this.runner.applyBreakpoints();
      this.panels.refresh('bps');
      this.panels.setCount('bps', this.breakpointCount());
    }
    toggleBreakpointAtCursor() { const d = this.active; if (d) this.toggleBreakpoint(d.path, d.editor.cursor().line); }
    async conditionalBreakpointDialog(line) {
      const d = this.active;
      if (!d) return;
      line = line === undefined ? d.editor.cursor().line : line;
      const cur = (this.breakpoints.get(d.path) || new Map()).get(line);
      const v = await RC.UI.prompt('Conditional Breakpoint', `Stop at line ${line + 1} only when this is true:`, cur && cur.cond ? cur.cond : '', { hint: 'Examples:  i = 10    name$ = "BOB"    score > 100 AND lives = 0' });
      if (v === null) return;
      let lines = this.breakpoints.get(d.path);
      if (!lines) { lines = new Map(); this.breakpoints.set(d.path, lines); }
      lines.set(line, { cond: v.trim() || null, disabled: false });
      this.afterBpChange(d.path);
    }
    gutterMenu(d, line, e) {
      const has = (this.breakpoints.get(d.path) || new Map()).has(line);
      RC.UI.showMenu([
        { label: has ? 'Remove Breakpoint' : 'Add Breakpoint', action: () => this.toggleBreakpoint(d.path, line) },
        { label: 'Conditional Breakpoint…', action: () => this.conditionalBreakpointDialog(line) },
        has ? { label: 'Disable / Enable', action: () => { const b = this.breakpoints.get(d.path).get(line); this.updateBreakpoint(d.path, line, { disabled: !b.disabled }); } } : null,
        { sep: true },
        { label: 'Run to Here', action: () => { d.editor.setCursor(line, 0); this.runToCursor(); } },
        { label: 'Set Next Statement Here', disabled: this.runner.state !== 'paused', action: () => { d.editor.setCursor(line, 0); this.setNextStatement(); } },
      ], e.clientX, e.clientY);
    }
    editorContextMenu(d, pos, e) {
      const w = pos ? B.wordAt(pos.text, pos.col) : null;
      const paused = this.runner.state === 'paused';
      e.preventDefault();
      RC.UI.showMenu([
        w && w.kind === 'id' ? { label: 'Add Watch: ' + w.expr, action: () => { this.panels.addWatch(w.expr); this.panels.show('watch'); } } : null,
        w && w.kind === 'id' && paused ? { label: 'Evaluate ' + w.expr, action: () => this.immediate('? ' + w.expr) } : null,
        w ? { label: 'Help on ' + w.word, action: () => RC.Help.open(this, w.word) } : null,
        w ? { sep: true } : null,
        { label: 'Toggle Breakpoint', sc: 'F9', action: () => this.toggleBreakpoint(d.path, pos ? pos.line : d.editor.cursor().line) },
        { label: 'Run to Cursor', sc: 'F7', action: () => this.runToCursor() },
        { label: 'Set Next Statement', disabled: !paused, action: () => this.setNextStatement() },
        { sep: true },
        { label: 'Cut', action: () => document.execCommand('cut') },
        { label: 'Copy', action: () => document.execCommand('copy') },
        { label: 'Toggle Comment', sc: 'Ctrl+/', action: () => d.editor.toggleComment() },
      ], e.clientX, e.clientY);
    }
    async addWatchDialog() {
      const v = await RC.UI.prompt('Add Watch', 'Expression to watch', '', { hint: 'Any BASIC expression: a variable, an array element, a calculation…' });
      if (v && v.trim()) { this.panels.addWatch(v.trim()); this.panels.show('watch'); }
    }
    printerLine(s) { this.panels.printerLine(s); }
    toast(m, k) { RC.UI.toast(m, k); }

    // ---- find bar / goto -------------------------------------------------------------------------------------
    openFind(replace) {
      const d = this.active;
      if (!d) return;
      const bar = this.el('findbar');
      bar.hidden = false;
      bar.innerHTML = '';
      const sel = d.editor.ta.value.slice(d.editor.ta.selectionStart, d.editor.ta.selectionEnd);
      const q = h('input', { type: 'text', placeholder: 'Find', value: sel && !sel.includes('\n') ? sel : (this.lastFind || ''), 'aria-label': 'Find' });
      const rep = h('input', { type: 'text', placeholder: 'Replace with', 'aria-label': 'Replace with' });
      const mc = h('input', { type: 'checkbox', 'aria-label': 'Match case' });
      const rx = h('input', { type: 'checkbox', 'aria-label': 'Regular expression' });
      const info = h('span.info');
      const opts = () => ({ matchCase: mc.checked, regex: rx.checked });
      const go = (back) => {
        this.lastFind = q.value;
        const ta = d.editor.ta;
        const r = d.editor.find(q.value, opts(), back ? ta.selectionStart : ta.selectionEnd, back);
        info.textContent = !r ? '' : r.count ? `${r.index} of ${r.count}` : 'No matches';
        q.focus();
      };
      q.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); go(e.shiftKey); } if (e.key === 'Escape') close(); });
      rep.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
      const close = () => { bar.hidden = true; d.editor.focus(); };
      bar.append(q, h('button.small-btn', { type: 'button', onclick: () => go(true) }, '↑'), h('button.small-btn', { type: 'button', onclick: () => go(false) }, '↓'),
        h('label', mc, ' Aa'), h('label', rx, ' .*'), info);
      if (replace) {
        bar.append(rep,
          h('button.small-btn', { type: 'button', onclick: () => { const ta = d.editor.ta; if (ta.selectionStart !== ta.selectionEnd) d.editor.insert(rep.value); go(false); } }, 'Replace'),
          h('button.small-btn', { type: 'button', onclick: () => { const n = d.editor.replaceAll(q.value, rep.value, opts()); info.textContent = n + ' replaced'; } }, 'All'));
      }
      bar.append(h('span', { style: { flex: 1 } }), h('button.icon-btn', { type: 'button', title: 'Close', 'aria-label': 'Close find', onclick: close }, icon('x')));
      q.focus(); q.select();
    }
    async gotoLineDialog() {
      const d = this.active;
      if (!d) return;
      const v = await RC.UI.prompt('Go to Line', 'Editor line, or a BASIC line number/label (e.g. 1200 or Main:)', '');
      if (!v) return;
      const t = v.trim();
      const lines = d.editor.lines();
      if (/^\d+$/.test(t)) {
        // prefer a BASIC line number if present
        const idx = lines.findIndex((l) => new RegExp('^\\s*' + t + '\\b').test(l));
        if (idx >= 0) { d.editor.setCursor(idx, 0); return; }
        d.editor.setCursor(Math.min(lines.length, +t) - 1, 0);
        return;
      }
      const lab = t.replace(/:$/, '').toUpperCase();
      const idx = lines.findIndex((l) => l.trim().toUpperCase().startsWith(lab + ':') || new RegExp('^\\s*(SUB|FUNCTION)\\s+' + lab.replace(/[$%&!#]/g, '\\$&') + '\\b', 'i').test(l));
      if (idx >= 0) d.editor.setCursor(idx, 0); else RC.UI.toast('Not found: ' + t, 'err');
    }
    toggleDrawer(open) {
      const app = this.el('app');
      app.classList.toggle('explorer-open', open === undefined ? !app.classList.contains('explorer-open') : open);
    }
    gotoPos(pos) {
      if (!pos) return;
      if (pos.file && !this.docByPath(pos.file)) {
        let ok = false;
        try { ok = this.vfs.exists(pos.file); } catch (e) { ok = false; }
        if (!ok) { RC.UI.toast('That source is not a file on disk (' + pos.file + ')', 'err'); return; }
      }
      const d = pos.file ? this.openFile(pos.file) : this.active;
      if (!d) return;
      d.editor.setCursor(pos.line, pos.col || 0);
      d.editor.flashLine(pos.line);
      this.setMobileView('editor');
    }
    async renumDialog() {
      const d = this.active;
      if (!d) return;
      const v = await RC.UI.prompt('Renumber (RENUM)', 'new start, old start, increment', '10,,10', { hint: 'Like GW-BASIC RENUM: e.g. "100,,10" renumbers all lines from 100 by 10. GOTO/GOSUB/THEN/ELSE/RESTORE/RESUME references are updated.' });
      if (v === null) return;
      const [a, b, c] = v.split(',').map((x) => (x.trim() === '' ? null : parseInt(x, 10)));
      try {
        const r = B.GW.renum(d.editor.getValue(), a, b, c);
        d.editor.ta.focus();
        d.editor.ta.setSelectionRange(0, d.editor.ta.value.length);
        d.editor.insert(r.text);
        if (r.warnings.length) RC.UI.alert('RENUM warnings', r.warnings.map(RC.escapeHtml).join('<br>'));
        else RC.UI.toast('Renumbered', 'ok');
      } catch (e) { RC.UI.toast(e.message, 'err'); }
    }
    async addLineNumbers() {
      const d = this.active;
      if (!d) return;
      const lines = d.editor.lines();
      if (lines.some((l) => /^\s*\d+/.test(l))) { RC.UI.toast('This program already has line numbers', 'err'); return; }
      if (!(await RC.UI.confirm('Add line numbers', 'Number every line 10, 20, 30… (GW-BASIC style)? Labels stay as they are.', 'Add Numbers'))) return;
      let n = 10;
      const out = lines.map((l) => (l.trim() === '' ? l : (n += 10) - 10 + ' ' + l.replace(/^\s+/, '')));
      d.editor.ta.focus();
      d.editor.ta.setSelectionRange(0, d.editor.ta.value.length);
      d.editor.insert(out.join('\n'));
    }
    async fontSizeDialog() {
      const v = await RC.UI.prompt('Editor Font Size', 'Size in pixels (10–28)', String(this.settings.fontSize));
      const n = parseInt(v, 10);
      if (n >= 10 && n <= 28) { this.settings.fontSize = n; this.saveSettings(); this.applyTheme(); }
    }
    async diskDialog() {
      const used = this.vfs.drives.C.totalSize();
      const n = this.vfs.drives.C.entries.size;
      const r = await RC.UI.modal({
        title: 'Virtual Disk C:',
        body: `<p>${n} files and folders, ${(used / 1024).toFixed(1)} KB used of ${(this.vfs.opts.maxTotal / 1048576).toFixed(0)} MB.</p><p>Files are stored in this browser only. Use <b>Download Project</b> or <b>Share</b> to keep copies elsewhere.</p>`,
        buttons: [{ label: 'Close', value: null }, { label: 'Reinstall Examples', value: 'samples' }, { label: 'Erase Everything…', value: 'erase' }],
      });
      if (r === 'samples') { RC.Samples.install(this.vfs, true); this.renderExplorer(); RC.UI.toast('Examples reinstalled in C:\\SAMPLES', 'ok'); }
      if (r === 'erase' && await RC.UI.confirm('Erase disk?', 'Delete <b>all</b> files on C: and reset settings? This cannot be undone.', 'Erase')) {
        for (const k of [...this.vfs.drives.C.entries.keys()]) { const e = this.vfs.drives.C.entries.get(k); this.vfs.drives.C.entries.delete(k); this.vfs.changed(this.vfs.drives.C, k, null, e); }
        try { localStorage.clear(); } catch (e) { /* ignore */ }
        if (this.vfs.flushNow) this.vfs.flushNow();
        setTimeout(() => location.reload(), 400);
      }
    }
    shortcutsDialog() {
      const rows = [
        ['F5', 'Run / Continue'], ['Shift+F5', 'Restart'], ['Ctrl+F2', 'Stop'], ['Ctrl+Break', 'Pause a running program (Ctrl+C on the screen too)'],
        ['F8', 'Step Into'], ['F10', 'Step Over'], ['Shift+F8', 'Step Out'], ['F7', 'Run to Cursor'], ['F9', 'Toggle Breakpoint'],
        ['F4', 'Output screen full size'], ['F2', 'SUBs list'], ['F1', 'Help for word under cursor'],
        ['Ctrl+S', 'Save'], ['Ctrl+O', 'Open'], ['Alt+N', 'New program'], ['Ctrl+F / Ctrl+H', 'Find / Replace'], ['Ctrl+G', 'Go to line'],
        ['Ctrl+/', 'Toggle comment'], ['Ctrl+D', 'Duplicate line'], ['Tab / Shift+Tab', 'Indent / outdent'], ['Alt+letter', 'Open menu'],
        ['Ctrl+= / Ctrl+-', 'Zoom editor'],
      ];
      RC.UI.alert('Keyboard Shortcuts', '<table class="kbd-table">' + rows.map(([k, v]) => `<tr><td><kbd>${k}</kbd></td><td>${v}</td></tr>`).join('') + '</table><p class="muted">While a program is running and the screen has focus, keys go to your program (except Ctrl+Break).</p>');
    }
    aboutDialog() {
      RC.UI.alert('About Baysik', `<p><b>Baysik</b> — a BASIC IDE — — version @@VERSION@@</p>
        <p>A browser IDE for GW-BASIC and QBasic programs: every classic screen mode (text, CGA, EGA, VGA, Hercules), PC speaker sound and music, files on a virtual disk, and a full debugger.</p>
        <p>Runs entirely in your browser; nothing is uploaded. Fonts: IBM PC ROM bitmap fonts (8×8, 8×14, 8×16).</p>
        <p class="muted">GW-BASIC and QBasic are trademarks of Microsoft. Baysik is an independent, compatible re-implementation and contains no Microsoft code.</p>`);
    }
    welcomeScreen() {
      const d = this.runner.display;
      d.screen(0, undefined, 0, 0, true);
      d.color(15, 1); d.cls(0);
      const center = (row, text, fg) => { d.color(fg, 1); d.locate(row, Math.max(1, Math.floor((80 - text.length) / 2) + 1)); d.printString(RC.toCP437(text)); };
      center(9, '╔══════════════════════════════════════════════╗', 11);
      center(10, '║            B   A   Y   S   I   K             ║', 11);
      center(11, '╚══════════════════════════════════════════════╝', 11);
      center(13, 'GW-BASIC + QBasic compatible  •  every screen mode  •  debugger', 7);
      center(16, 'Press F5 to run the program in the editor', 14);
      center(17, 'Learn: step-by-step lessons   Library: hundreds of programs', 15);
      center(19, 'View > GW-BASIC Classic Console for the 1980s experience', 7);
      d.color(7, 0);
      d.locate(25, 1);
    }

    // ---- keyboard ------------------------------------------------------------------------------------------
    bindKeys() {
      const screen = this.el('screen');
      window.addEventListener('keydown', (e) => this.onKey(e), true);
      window.addEventListener('keyup', (e) => { if (this.programHasKeys()) this.runner.keyboard.keyUp(e); }, true);
      screen.addEventListener('paste', (e) => {
        if (!this.programHasKeys() && !(this.console && this.console.active)) return;
        e.preventDefault();
        const t = (e.clipboardData || window.clipboardData).getData('text');
        if (this.console && this.console.active && !this.runner.isActive()) this.console.paste(t);
        else this.runner.keyboard.type(t);
        this.runner.kick();
      });
    }
    programHasKeys() {
      const st = this.runner.state;
      const active = st === 'running' || st === 'waiting';
      return active && (document.activeElement === this.el('screen') || this.el('app').classList.contains('screen-max') || document.activeElement === document.body);
    }
    onKey(e) {
      if (RC.UI.anyModalOpen() || (RC.Tours.active && RC.Tours.active.captureKeys)) return;
      const st = this.runner.state;
      const mod = e.ctrlKey || e.metaKey;
      // Ctrl+Break works everywhere
      if ((e.code === 'Pause' || e.code === 'Cancel') && e.ctrlKey) { e.preventDefault(); this.runner.breakKey(); if (this.console && this.console.active && st !== 'running' && st !== 'waiting') this.console.breakKey(); return; }
      if (e.key === 'c' && e.ctrlKey && document.activeElement === this.el('screen') && (st === 'running' || st === 'waiting')) { e.preventDefault(); this.runner.breakKey(); return; }
      // Program input
      if (this.programHasKeys()) {
        if (e.key === 'F4' && st !== 'waiting' && false) return;
        if (this.runner.keyboard.keyDown(e)) { e.preventDefault(); e.stopPropagation(); this.runner.kick(); }
        return;
      }
      // GW console has the screen
      if (this.console && this.console.active && document.activeElement === this.el('screen') && !(st === 'running' || st === 'waiting')) {
        if (e.key === 'F4' && this.el('app').classList.contains('screen-max')) { e.preventDefault(); this.toggleScreenMax(); return; }
        if (this.console.keyDown(e)) { e.preventDefault(); e.stopPropagation(); }
        return;
      }
      if (e.key === 'Escape' && this.el('app').classList.contains('screen-max')) { e.preventDefault(); this.toggleScreenMax(); return; }
      if (e.altKey && !mod && /^Key[A-Z]$/.test(e.code)) {
        const letter = e.code.slice(3);
        if (letter === 'N') { e.preventDefault(); this.newFile(); return; }
        if (letter === 'W') { e.preventDefault(); if (this.active) this.closeDoc(this.active); return; }
        const i = this.menuDefs().findIndex((m) => m.label[0] === letter);
        if (i >= 0) { e.preventDefault(); this.openMenu(i, true); return; }
      }
      const k = e.key;
      const handled = () => { e.preventDefault(); e.stopPropagation(); };
      if (k === 'F5' && !mod) { handled(); if (e.shiftKey) this.restart(); else this.runOrContinue(); return; }
      if (k === 'F2' && mod) { handled(); this.stop(); return; }
      if (k === 'F2') { handled(); this.subsDialog(); return; }
      if (k === 'F4') { handled(); this.toggleScreenMax(); return; }
      if (k === 'F7') { handled(); this.runToCursor(); return; }
      if (k === 'F8') { handled(); this.step(e.shiftKey ? 'out' : 'into'); return; }
      if (k === 'F10') { handled(); this.step('over'); return; }
      if (k === 'F11') { handled(); this.step(e.shiftKey ? 'out' : 'into'); return; }
      if (k === 'F9') { handled(); this.toggleBreakpointAtCursor(); return; }
      if (k === 'F1' && document.activeElement !== (this.active && this.active.editor.ta)) { handled(); RC.Help.open(this); return; }
      if (mod && (k === 's' || k === 'S')) { handled(); if (e.shiftKey) this.saveAs(); else this.save(); return; }
      if (mod && (k === 'o' || k === 'O')) { handled(); this.openDialog(); return; }
      if (mod && (k === '=' || k === '+')) { handled(); this.zoom(1); return; }
      if (mod && k === '-') { handled(); this.zoom(-1); return; }
    }
    bindScreen() {
      const c = this.el('screen');
      const frame = this.el('screenFrame');
      const hint = this.el('screenHint');
      c.addEventListener('focus', () => { frame.classList.add('focused'); hint.classList.remove('show'); this.runner.audio.resume(); });
      c.addEventListener('blur', () => {
        frame.classList.remove('focused');
        if (this.runner.state === 'running' || this.runner.state === 'waiting') hint.classList.add('show');
      });
      c.addEventListener('mousedown', () => setTimeout(() => c.focus(), 0));
      this.runner.display.on('mode', () => { this.updateStatus(); });
      // Text-mode border colour (COLOR ,,border) is drawn as a band around the screen, like CGA/EGA
      this.runner.display.on('border', (rgb) => { frame.style.boxShadow = rgb && !/^#0+$/.test(rgb) ? `0 0 0 10px ${rgb}, 0 0 30px rgba(0,0,0,.6)` : ''; });
      new ResizeObserver(() => this.fitScreen()).observe(this.el('screenWrap'));
    }
    /** Touch devices: on-screen keypad + soft keyboard bridge for running programs. */
    setupTouch() {
      const app = this.el('app');
      const coarse = window.matchMedia('(pointer: coarse)');
      const apply = () => app.classList.toggle('touch', coarse.matches || ('ontouchstart' in window && navigator.maxTouchPoints > 0));
      apply();
      if (coarse.addEventListener) coarse.addEventListener('change', apply);
      const kb = this.runner.keyboard;
      const target = () => (this.console && this.console.active && !this.runner.isActive() ? 'console' : 'program');
      const sendKey = (key, scan, extended) => {
        if (target() === 'console') { this.console.handleKey(extended ? '\0' + String.fromCharCode(scan) : key); return; }
        kb.lastScan = scan; kb.down.add(scan);
        if (this.runner.vm) { const n = { 72: 11, 75: 12, 77: 13, 80: 14 }[scan]; if (n && this.runner.trapKey(n, 0, scan)) { this.runner.kick(); return; } }
        kb.push(extended ? '\0' + String.fromCharCode(scan) : key);
        this.runner.kick();
      };
      const release = (scan) => { kb.lastScan = scan | 0x80; kb.down.delete(scan); };
      const pad = this.el('keypad');
      const mk = (label, cls, key, scan, ext, aria) => {
        const b = h('button' + (cls ? '.' + cls : ''), { type: 'button', 'aria-label': aria || label }, label);
        let rep = null;
        b.addEventListener('pointerdown', (e) => {
          e.preventDefault(); b.classList.add('down');
          sendKey(key, scan, ext);
          if (ext) rep = setTimeout(function again() { sendKey(key, scan, ext); rep = setTimeout(again, 70); }, 380);
        });
        const up = () => { b.classList.remove('down'); clearTimeout(rep); release(scan); };
        b.addEventListener('pointerup', up); b.addEventListener('pointerleave', up); b.addEventListener('pointercancel', up);
        return b;
      };
      const dpad = h('div.dpad', mk('▲', 'up', '', 72, true, 'Up'), mk('◀', 'left', '', 75, true, 'Left'), mk('▼', 'down', '', 80, true, 'Down'), mk('▶', 'right', '', 77, true, 'Right'));
      const softkb = h('input.softkb', { type: 'text', autocapitalize: 'off', autocomplete: 'off', autocorrect: 'off', spellcheck: 'false', 'aria-label': 'Keyboard for the program' });
      this.el('screenFrame').appendChild(softkb);
      const kbBtn = h('button', { type: 'button', 'aria-label': 'Show keyboard' }, 'ABC');
      kbBtn.addEventListener('click', () => { softkb.value = ''; softkb.focus(); });
      const brk = h('button', { type: 'button', 'aria-label': 'Break (Ctrl+Break)' }, 'Break');
      brk.addEventListener('click', () => { if (target() === 'console') this.console.breakKey(); else this.runner.breakKey(); });
      pad.append(dpad, mk('Space', '', ' ', 57), mk('Enter', '', '\r', 28), mk('Esc', '', '\x1b', 1), kbBtn, brk);
      softkb.addEventListener('input', () => {
        const v = softkb.value;
        softkb.value = '';
        for (const ch of RC.toCP437(v)) sendKey(ch, 0, false);
      });
      softkb.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') { e.preventDefault(); sendKey('\r', 28); }
        else if (e.key === 'Backspace') { e.preventDefault(); sendKey('\b', 14); }
        e.stopPropagation();
      });
      // tapping the screen while a program runs opens the soft keyboard on touch devices
      this.el('screen').addEventListener('pointerup', (e) => {
        if (e.pointerType === 'touch' && (this.runner.state === 'waiting' || this.runner.state === 'running' || (this.console && this.console.active))) { softkb.value = ''; softkb.focus(); }
      });
    }
    fitScreen() {
      const wrap = this.el('screenWrap');
      const frame = this.el('screenFrame');
      const r = wrap.getBoundingClientRect();
      const w = r.width - 20, hh = r.height - 20;
      const ar = 4 / 3;
      let fw = w, fh = w / ar;
      if (fh > hh) { fh = hh; fw = hh * ar; }
      frame.style.width = Math.max(0, Math.floor(fw)) + 'px';
      frame.style.height = Math.max(0, Math.floor(fh)) + 'px';
    }
  }

  RC.App = App;
  RC.LANG_BASIC = LANG;

  if (RC.isBrowser) {
    window.addEventListener('DOMContentLoaded', () => {
      const app = new App();
      RC.app = app;
      app.init().catch((e) => { console.error(e); RC.UI.alert('Startup error', RC.escapeHtml(String(e && e.stack || e))); });
    });
  }
})(RC);
