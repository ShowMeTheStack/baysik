// Runner: owns the emulated machine (display, keyboard, audio, devices) and drives the VM.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const now = () => performance.now();

  class Gamepad {
    constructor() { this.latch = {}; this.enabled = true; }
    pad(i) { const g = navigator.getGamepads ? navigator.getGamepads() : []; return (g && g[i]) || null; }
    stick(n) {
      if (n < 0 || n > 3) B.err(5);
      const p = this.pad(n >> 1);
      if (!p) return 100;
      const v = p.axes[(n & 1)] || 0;
      return Math.round(1 + (v + 1) * 99.5);
    }
    button(pi, bi) { const p = this.pad(pi); return !!(p && p.buttons[bi] && p.buttons[bi].pressed); }
    strig(n) {
      if (n < 0 || n > 7) B.err(5);
      const pi = n >= 4 ? (n >= 6 ? 1 : 0) : (n >= 2 ? 1 : 0);
      const bi = n >= 4 ? 1 : 0;
      const down = this.button(pi, bi);
      if (n % 2 === 1) return down ? -1 : 0;
      const k = pi + ':' + bi;
      const was = this.latch[k];
      this.latch[k] = false;
      return was || down ? -1 : 0;
    }
    poll(vm) {
      for (let pi = 0; pi < 2; pi++) for (let bi = 0; bi < 2; bi++) {
        const k = pi + ':' + bi;
        const d = this.button(pi, bi);
        if (d && !this['prev' + k]) {
          this.latch[k] = true;
          const n = [[0, 4], [2, 6]][pi][bi];
          if (vm) vm.fireEvent('STRIG', n);
        }
        this['prev' + k] = d;
      }
    }
    port201() {
      let v = 0xF0;
      if (this.button(0, 0)) v &= ~0x10;
      if (this.button(0, 1)) v &= ~0x20;
      if (this.button(1, 0)) v &= ~0x40;
      if (this.button(1, 1)) v &= ~0x80;
      return v;
    }
  }

  class Pen {
    constructor(display, canvas) {
      this.d = display; this.down = false; this.wasDown = false;
      this.x = 0; this.y = 0; this.px = 0; this.py = 0; this.enabled = true;
      const pos = (e) => {
        const r = canvas.getBoundingClientRect();
        this.x = Math.floor(((e.clientX - r.left) / r.width) * display.W);
        this.y = Math.floor(((e.clientY - r.top) / r.height) * display.H);
      };
      canvas.addEventListener('pointerdown', (e) => { pos(e); this.down = true; this.wasDown = true; this.px = this.x; this.py = this.y; if (this.onPress) this.onPress(); });
      canvas.addEventListener('pointermove', (e) => pos(e));
      window.addEventListener('pointerup', () => { this.down = false; });
    }
    read(n) {
      const d = this.d;
      const row = (y) => Math.floor(y / d.m.ch) + 1, col = (x) => Math.floor(x / d.m.cw) + 1;
      switch (n) {
        case 0: { const w = this.wasDown; this.wasDown = false; return w ? -1 : 0; }
        case 1: return this.px;
        case 2: return this.py;
        case 3: return this.down ? -1 : 0;
        case 4: return this.x;
        case 5: return this.y;
        case 6: return row(this.py);
        case 7: return col(this.px);
        case 8: return row(this.y);
        case 9: return col(this.x);
      }
      B.err(5);
    }
  }

  class Runner extends RC.Emitter {
    constructor(app, canvas) {
      super();
      this.app = app;
      this.canvas = canvas;
      this.display = new RC.Display();
      this.display.attach(canvas);
      this.keyboard = new RC.Keyboard();
      this.audio = new RC.Audio();
      this.gamepad = new Gamepad();
      this.pen = new Pen(this.display, canvas);
      this.vm = null;
      this.prog = null;
      this.speed = 0; // statements/second, 0 = unlimited
      this.animate = false;
      this.mainPath = null;
      this.display.on('beep', () => this.audio.beep());
      this.keyboard.onBreak = () => this.breakKey();
      this.keyboard.trap = (n, flags, scan) => this.trapKey(n, flags, scan);
      this.keyboard.onOverflow = null; // BIOS beeps on a full buffer; too noisy for INP(&H60) games
      this.pen.onPress = () => { if (this.vm) this.vm.fireEvent('PEN'); };
      const ch = new MessageChannel();
      ch.port1.onmessage = () => { this.scheduled = false; this.loop(); };
      this.port = ch.port2;
      this.renderLoop = this.renderLoop.bind(this);
      requestAnimationFrame(this.renderLoop);
    }

    // ---- host for the VM -----------------------------------------------------------------------
    makeHost() {
      const app = this.app;
      return {
        display: this.display,
        keyboard: this.keyboard,
        audio: this.audio,
        vfs: app.vfs,
        gamepad: this.gamepad,
        pen: this.pen,
        printer: { printLine: (s) => app.printerLine(s), flushPartial: () => {} },
        askPermission: (op, path) => app.askWritePermission(path),
        command: (vm, st, file) => this.programCommand(vm, st, file),
        softKeys: this.softKeys || (this.softKeys = ['LIST ', 'RUN\r', 'LOAD"', 'SAVE"', 'CONT\r', ',"LPT1:"\r', 'TRON\r', 'TROFF\r', 'KEY ', 'SCREEN 0,0,0\r', '', '']),
        commandLine: '',
      };
    }

    renderLoop(t) {
      requestAnimationFrame(this.renderLoop);
      this.display.render(t);
      if (this.vm && (this.vm.state === 'running' || this.vm.state === 'waiting')) {
        this.gamepad.poll(this.vm);
        if (this.animate && this.vm.state === 'running') this.emit('animate');
      }
    }

    // ---- compile & run ---------------------------------------------------------------------------
    /**
     * Compile a program. files: main path; reads $INCLUDE relative to its folder.
     * Throws CompileError (with pos.file = VFS path).
     */
    compile(mainPath, text) {
      const vfs = this.app.vfs;
      const dir = mainPath.replace(/\\[^\\]*$/, '');
      const readInclude = (name) => {
        const candidates = [name, dir + '\\' + name];
        for (const c of candidates) {
          try {
            const r = vfs.resolve(c);
            const doc = this.app.docByPath(r.display);
            if (doc) return { text: doc.editor.getValue(), name: r.display };
            if (vfs.exists(c)) return { text: this.app.decodeText(vfs.readFile(c)), name: r.display };
          } catch (e) { /* next */ }
        }
        return null;
      };
      return compileWithIncludes(mainPath, text, readInclude);
    }

    start(mainPath, text, opts) {
      opts = opts || {};
      this.restarting = true;
      try { this.stop(true); } finally { this.restarting = false; }
      const prog = this.compile(mainPath, text);
      this.prog = prog;
      this.mainPath = mainPath;
      const vm = new B.VM(prog, this.makeHost());
      this.attachVm(vm);
      // working directory = program folder
      try { this.app.vfs.chdir(mainPath.replace(/\\[^\\]*$/, '') || 'C:\\'); this.app.vfs.setDrive(mainPath[0]); } catch (e) { /* ignore */ }
      if (!opts.keepScreen) { this.display.screen(0, undefined, 0, 0, true); this.display.width(80, 25); this.display.cls(0); this.display.setKeyLine(false); }
      this.keyboard.clear();
      this.audio.resume();
      this.applyBreakpoints();
      if (opts.stepInto) { vm.stepMode = 'into'; vm.stepDepth = 1; }
      if (this.tronDefault) { vm.tron = true; }
      this.startText = text;
      vm.updateDbgFlag();
      vm.start();
      this.kick();
      return vm;
    }

    attachVm(vm) {
      this.vm = vm;
      vm.throttle = this.speed;
      vm.recordHistory = true;
      vm.on('state', (s) => this.emit('state', s, vm));
      vm.on('pause', (why) => { this.emit('pause', why, vm); });
      vm.on('end', (info) => { this.cleanupImmediate(vm); this.emit('end', info, vm); });
      vm.on('error', (info) => {
        const im = this.immediate;
        if (im && im.saved && vm === this.vm) {
          // an error in a direct statement during a break: report it, keep the break state
          this.immediate = null;
          this.restoreBreak(vm, im);
          this.emit('immediateError', info, vm);
          return;
        }
        this.cleanupImmediate(vm);
        this.emit('error', info, vm);
      });
      vm.on('chain', (req) => this.doChain(req));
      this.emit('vm', vm);
    }

    kick() {
      if (!this.scheduled) { this.scheduled = true; this.port.postMessage(0); }
    }
    loop() {
      const vm = this.vm;
      if (!vm) return;
      if (vm.state === 'running' || vm.state === 'waiting') {
        if (this.speed > 0) {
          const t = now();
          const dt = Math.min(100, t - (this.lastBudgetT || t));
          this.lastBudgetT = t;
          this.budgetAcc = (this.budgetAcc || 0) + (this.speed * dt) / 1000;
          vm.stmtBudget = Math.floor(this.budgetAcc);
          this.budgetAcc -= vm.stmtBudget;
          vm.throttle = this.speed;
          vm.updateDbgFlag();
        } else { vm.stmtBudget = Infinity; vm.throttle = 0; }
        if (vm.state === 'waiting' || vm.stmtBudget > 0) vm.tick(10);
        if (vm.throttleYield) vm.throttleYield = false;
        if (vm.state === 'evaldone') { this.finishImmediate(); return; }
        if (vm.state === 'running' && (this.speed === 0 || vm.stmtBudget > 0)) this.kick();
        else if (vm.state === 'running' || vm.state === 'waiting') setTimeout(() => this.kick(), this.speed > 0 ? 8 : 4);
      }
    }

    setSpeed(sps) {
      this.speed = sps;
      this.budgetAcc = 0;
      this.lastBudgetT = now();
      if (this.vm) { this.vm.throttle = sps; this.vm.updateDbgFlag(); }
    }

    // ---- control --------------------------------------------------------------------------------------
    get state() { return this.vm ? this.vm.state : 'idle'; }
    isActive() { const s = this.state; return s === 'running' || s === 'waiting' || s === 'paused'; }
    pause() { if (this.vm && (this.vm.state === 'running' || this.vm.state === 'waiting')) { this.vm.pause('user'); } }
    resume(mode) {
      const vm = this.vm;
      if (!vm || vm.state !== 'paused') return;
      this.applyBreakpoints();
      vm.resume(mode);
      this.audio.resume();
      this.kick();
    }
    stop(silent) {
      if (!this.vm) return;
      const vm = this.vm;
      if (vm.state !== 'ended' && vm.state !== 'error' && vm.state !== 'idle') vm.stop();
      this.audio.stopAll();
      if (!silent) this.emit('stopped');
    }
    breakKey() {
      if (this.vm && (this.vm.state === 'running' || this.vm.state === 'waiting')) {
        this.vm.pause('break');
      }
    }
    trapKey(n, flags, scan) {
      const vm = this.vm;
      if (!vm || (vm.state !== 'running' && vm.state !== 'waiting')) return false;
      if (n > 0) return vm.keyEvent(n);
      if (vm.userKeys) {
        for (const k in vm.userKeys) {
          const u = vm.userKeys[k];
          if (u.scan === scan && ((u.flags & 0x0F) === 0 || (u.flags & 0x0F & flags) === (u.flags & 0x0F))) {
            if (vm.keyEvent(+k)) return true;
          }
        }
      }
      return false;
    }

    // ---- breakpoints ------------------------------------------------------------------------------------
    applyBreakpoints() {
      const vm = this.vm;
      if (!vm || !vm.prog) return;
      const set = new Set();
      vm.condBreaks = new Map();
      const all = this.app.breakpoints; // Map(pathKey -> Map(line -> {cond, disabled}))
      for (const [path, lines] of all) {
        for (const [line, bp] of lines) {
          if (bp.disabled) continue;
          const idx = B.Debug.stmtAtLine(vm.prog, path, line);
          if (idx < 0) continue;
          set.add(idx);
          if (bp.cond) vm.condBreaks.set(idx, B.Debug.makeCondition(bp.cond));
        }
      }
      if (vm.tempBreak !== undefined && vm.tempBreak !== null) set.add(vm.tempBreak);
      vm.setBreakpoints(set);
    }

    // ---- CHAIN / RUN "file" ------------------------------------------------------------------------------------
    resolveProgramFile(name) {
      const vfs = this.app.vfs;
      let n = name.trim();
      const tries = [n];
      if (!/\.[^\\.]*$/.test(n)) tries.push(n + '.BAS');
      for (const t of tries) { try { if (vfs.exists(t)) return vfs.resolve(t).display; } catch (e) { /* next */ } }
      return null;
    }
    doChain(req) {
      const old = this.vm;
      let path = null;
      try {
        if (req.file === undefined || req.file === null) {
          // RUN with no file: restart current program
          path = this.mainPath;
        } else {
          path = this.resolveProgramFile(req.file);
          if (!path) throw new B.BasicError(53);
        }
        const doc = this.app.docByPath(path);
        const text = doc ? doc.editor.getValue() : this.app.decodeText(this.app.vfs.readFile(path));
        const prog = this.compile(path, text);
        const vm = new B.VM(prog, old.host);
        if (req.kind === 'chain') {
          // keep open files, pass COMMON variables
          vm.files = old.files;
          if (req.opts && req.opts.all) {
            const byKey = new Map(old.prog.globalSyms.map((s) => [s.key, s]));
            for (const s of prog.globalSyms) {
              const o = byKey.get(s.key);
              if (o && B.sameType(o.type, s.type) && !!o.isArray === !!s.isArray) vm.G[s.slot] = old.G[o.slot];
            }
          } else {
            const n = Math.min(old.prog.commons.length, prog.commons.length);
            for (let i = 0; i < n; i++) {
              const a = old.prog.commons[i], b = prog.commons[i];
              if (!!a.isArray !== !!b.isArray || B.isStr(a.type) !== B.isStr(b.type)) throw new B.BasicError(13);
              vm.G[b.slot] = a.isArray ? old.G[a.slot] : B.coerce(b.type, old.G[a.slot]);
            }
          }
          vm.rng = old.rng;
          vm.dateOffset = old.dateOffset;
        } else {
          old.closeAllFiles();
        }
        this.prog = prog;
        this.mainPath = path;
        this.attachVm(vm);
        this.applyBreakpoints();
        if (req.line !== undefined && req.line !== null) {
          const key = String(req.line);
          const pc = prog.module.labels.get(key);
          if (pc === undefined) throw new B.BasicError(8);
          vm.pc = pc;
        }
        vm.start();
        this.emit('chained', path, vm);
        this.kick();
      } catch (e) {
        old.state = 'error';
        if (e instanceof B.CompileError) { this.emit('compileError', e); return; }
        const info = { code: e.code || 51, message: e.message, stmt: old.frame.stmt, pos: old.currentStmt() ? old.currentStmt().pos : null };
        old.errorInfo = info;
        this.emit('error', info, old);
      }
    }

    /** GW-BASIC program commands executed from inside a running program */
    programCommand(vm, st, file) {
      const app = this.app;
      const out = vm.screenOut();
      switch (st.cmd) {
        case 'LIST': case 'LLIST': {
          const text = app.mainText();
          const lines = B.GW.list(text, st.range);
          for (const l of lines) {
            if (st.cmd === 'LLIST') app.printerLine(l);
            else { out.write(RC.toCP437(l)); out.newline(); }
          }
          return;
        }
        case 'SAVE': {
          const p = this.resolveSaveName(file);
          app.vfs.writeFile(p, RC.strToBytes(RC.toCP437(app.mainText().replace(/\n/g, '\r\n'))));
          return;
        }
        case 'LOAD':
          if (st.run) { vm.requestChain('run', file, null, {}); return B.WAIT; }
          vm.opEnd(0);
          setTimeout(() => app.openProgramFile(this.resolveProgramFile(file)), 0);
          return B.WAIT;
        case 'NEW':
          vm.opEnd(0);
          return B.WAIT;
        default:
          B.err(73, st.cmd + ' is only available in the GW-BASIC console');
      }
    }
    resolveSaveName(name) {
      let n = name.trim();
      if (!/\.[^\\.]*$/.test(n)) n += '.BAS';
      return this.app.vfs.resolve(n).display;
    }

    // ---- immediate mode while no program is running ---------------------------------------------------------
    /**
     * Execute immediate-mode statements asynchronously (INPUT, loops and graphics all work).
     * Uses the last program's variables if available (like QBasic/GW-BASIC).
     */
    runImmediate(text, onDone) {
      let vm = this.vm;
      if (!vm || vm.state === 'running' || vm.state === 'waiting') return false;
      if (vm.state === 'paused') {
        // Break state (GW-BASIC "Break in NN"): run the statement on top of the paused program
        // asynchronously (so INPUT, loops and graphics work), then return to the same break state.
        const top = vm.frames[vm.frames.length - 1];
        const snip = B.Debug.compileSnippet(vm, text, top, 'stmt');
        const saved = { pc: vm.pc, frames: vm.frames, frame: vm.frame, sp: vm.stack.length, dbg: vm.dbg, skipBreak: vm.skipBreak, pauseReason: vm.pauseReason };
        const ef = new B.Frame(top.proc, top.L, -1, 3, false);
        ef.fors = top.fors; ef.stmt = top.stmt;
        vm.frames = vm.frames.concat([ef]);
        vm.frame = ef;
        vm.pc = snip.startPc;
        vm.pending = null;
        vm.dbg = false;
        this.immediate = { snip, onDone, saved };
        vm.state = 'running';
        this.emit('state', 'running', vm);
        this.kick();
        return true;
      }
      const snip = B.Debug.compileSnippet(vm, text, vm.frames[0], 'stmt');
      vm.frames = [vm.frames[0]];
      vm.frame = vm.frames[0];
      vm.frame.gosub = [];
      vm.stack.length = 0;
      vm.pc = snip.startPc;
      vm.pending = null;
      vm.errorInfo = null;
      vm.inErrHandler = null;
      vm.dbg = false;
      vm.recordHistory = false;
      this.immediate = { snip, onDone, prevState: vm.state };
      vm.state = 'running';
      this.emit('state', 'running', vm);
      this.kick();
      return true;
    }
    cleanupImmediate(vm) {
      const im = this.immediate;
      if (!im || vm !== this.vm) return;
      this.immediate = null;
      vm.prog.code.length = im.snip.startPc;
      vm.prog.stmts.length = im.snip.stmtsLen;
      vm.recordHistory = true;
    }
    /** Put a paused program back into its break state after a direct statement ran on top of it */
    restoreBreak(vm, im) {
      const s = im.saved;
      vm.prog.code.length = im.snip.startPc;
      vm.prog.stmts.length = im.snip.stmtsLen;
      Object.assign(vm, { pc: s.pc, frames: s.frames, frame: s.frame, dbg: s.dbg, skipBreak: s.skipBreak, pauseReason: s.pauseReason, pending: null, errorInfo: null });
      vm.stack.length = s.sp;
      vm.state = 'paused';
      this.tronDefault = !!vm.tron;
      this.emit('state', 'paused', vm);
    }
    finishImmediate() {
      const vm = this.vm;
      const im = this.immediate;
      this.immediate = null;
      if (im && im.saved) {
        this.restoreBreak(vm, im);
        this.emit('immediateDone', vm);
        if (im.onDone) im.onDone(null);
        return;
      }
      if (im) {
        vm.prog.code.length = im.snip.startPc;
        vm.prog.stmts.length = im.snip.stmtsLen;
      }
      this.tronDefault = !!vm.tron;
      vm.state = 'ended';
      vm.endReason = 'immediate';
      vm.recordHistory = true;
      this.emit('state', 'ended', vm);
      this.emit('immediateDone', vm);
      if (im && im.onDone) im.onDone(null);
    }
    /** Make sure there is an (idle) VM to run immediate statements against */
    ensureIdleVm() {
      if (this.vm) return this.vm;
      const prog = B.compileProgram([{ name: '<immediate>', text: '' }]);
      const vm = new B.VM(prog, this.makeHost());
      vm.state = 'ended';
      this.prog = prog;
      this.attachVm(vm);
      return vm;
    }
  }

  /** Compile with $INCLUDE support where includes are resolved to VFS paths */
  function compileWithIncludes(mainPath, text, readInclude) {
    return B.compileProgram([{ name: mainPath, text }], {
      readIncludeEx: readInclude,
      readInclude: (n) => { const r = readInclude(n); return r ? r.text : null; },
    });
  }

  RC.Runner = Runner;
})(RC);
