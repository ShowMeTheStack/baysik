// BASIC virtual machine: executes compiled bytecode with explicit frames so the debugger can
// pause anywhere, inspect/modify any frame, and step.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const { O, BasicError, T } = B;
  const err = B.err;
  const WAIT = B.WAIT = Symbol('wait');

  const now = () => (typeof performance !== 'undefined' ? performance.now() : Date.now());

  // Frame kinds
  const FK_NORMAL = 0, FK_EVENT = 1, FK_ERROR = 2;

  class Frame {
    constructor(proc, L, retPc, kind, isFunc) {
      this.proc = proc;
      this.L = L;
      this.retPc = retPc;
      this.kind = kind || FK_NORMAL;
      this.isFunc = !!isFunc;
      this.gosub = [];
      this.fors = [];
      this.stmt = -1;
      this.sp = 0;
      this.event = null;
    }
  }
  B.Frame = Frame;

  class VM extends RC.Emitter {
    /**
     * @param prog compiled program (B.compileProgram)
     * @param host {display, keyboard, audio, fs, printer, sourceProvider, ...}
     */
    constructor(prog, host) {
      super();
      this.prog = prog;
      this.code = prog.code;
      this.host = host || {};
      this.display = this.host.display;
      this.kbd = this.host.keyboard;
      this.audio = this.host.audio;
      this.state = 'idle'; // idle | running | paused | waiting | ended | error
      this.pc = 0;
      this.stack = [];
      this.frames = [];
      this.G = [];
      this.pending = null;
      this.inputVals = [];
      this.dataPtr = 0;
      this.out = null; // current print channel
      this.using = null;
      this.files = new Map();
      this.errHandler = -1; // pc of ON ERROR handler, -1 none, -2 resume next
      this.err = 0; this.erl = 0; this.errStmt = -1;
      this.inErrHandler = null;
      this.tron = false; this.lastTron = null;
      this.events = { TIMER: { state: 'OFF', pc: -1, interval: 0, next: 0, fired: false, busy: false }, KEY: {}, PLAY: { state: 'OFF', pc: -1, n: 0, fired: false, busy: false }, STRIG: {}, PEN: { state: 'OFF', pc: -1, fired: false, busy: false } };
      this.evPending = false;
      // debugging
      this.breakpoints = new Set(); // statement indices
      this.condBreaks = new Map(); // stmt idx -> compiled condition fn
      this.stepMode = null; // 'into' | 'over' | 'out'
      this.stepDepth = 0;
      this.skipBreak = false;
      this.dbg = false; // any debug feature active (fast path flag)
      this.watchpoints = []; // {fn, last}
      this.history = []; // recent statement indices (ring)
      this.historyMax = 200;
      this.recordHistory = true;
      this.throttle = 0; // statements per second (0 = unlimited)
      this.stmtBudget = Infinity;
      this.defSeg = 0;
      this.rng = new B.Rnd();
      this.memory = null;
      this.optionBase = 0;
      this.startTime = now();
      this.dateOffset = 0;
      this.keyDisplay = false;
      this.statementsExecuted = 0;
      this.init();
    }

    init() {
      const prog = this.prog;
      this.G = new Array(prog.ngl);
      for (let i = 0; i < prog.ngl; i++) this.G[i] = this.initValue(prog.globalTypes[i]);
      for (const p of prog.procs) {
        p.statics = new Array(p.nstatic || 0);
        for (let i = 0; i < (p.nstatic || 0); i++) p.statics[i] = this.initValue(p.staticTypes[i]);
      }
      const mainFrame = new Frame(prog.main, [], -1, FK_NORMAL, false);
      this.frames = [mainFrame];
      this.frame = mainFrame;
      this.pc = 0;
      this.stack.length = 0;
      this.dataPtr = 0;
    }
    initValue(t) {
      if (!t) return 0;
      if (t.code === 7 || t.code === 8) return null; // array / ref
      return B.defaultValue(t);
    }

    // ---- control API (used by IDE) --------------------------------------------------
    start() {
      this.state = 'running';
      this.startTime = now();
      this.emit('state', this.state);
    }
    pause(reason) {
      if (this.state === 'running' || this.state === 'waiting') {
        if (this.state === 'waiting') this.pausedWhileWaiting = true;
        this.state = 'paused';
        this.pauseReason = reason || 'pause';
        this.emit('pause', this.pauseReason);
        this.emit('state', this.state);
      }
    }
    resume(stepMode) {
      if (this.state !== 'paused') return;
      this.stepMode = stepMode || null;
      this.stepDepth = this.frames.length;
      this.skipBreak = true;
      this.updateDbgFlag();
      if (this.pausedWhileWaiting && this.pending) { this.state = 'waiting'; this.pausedWhileWaiting = false; }
      else this.state = 'running';
      this.emit('state', this.state);
    }
    stop() {
      if (this.state === 'ended') return;
      this.closeAllFiles();
      this.state = 'ended';
      this.endReason = 'stopped';
      if (this.pending && this.pending.cancel) this.pending.cancel();
      this.pending = null;
      if (this.audio) this.audio.stopAll();
      this.emit('end', { reason: 'stopped' });
      this.emit('state', this.state);
    }
    updateDbgFlag() {
      this.dbg = this.breakpoints.size > 0 || this.condBreaks.size > 0 || !!this.stepMode || this.watchpoints.length > 0 ||
        this.tron || this.evPending || this.throttle > 0 || this.recordHistory || !!this.traceHook;
    }
    setBreakpoints(set) { this.breakpoints = set; this.updateDbgFlag(); }

    /** Run for up to `budget` ms. Returns when budget expires or state changes. */
    tick(budget) {
      if (this.state === 'waiting') {
        this.pollTimers();
        if (this.pending && this.pending.poll(this)) {
          this.pending = null;
          if (this.state === 'waiting') this.state = 'running';
        } else return;
      }
      if (this.state !== 'running') return;
      this.exec(budget || 12);
    }

    block(pending) {
      this.pending = pending;
      this.state = 'waiting';
      return WAIT;
    }

    // ---- stack helpers -------------------------------------------------------------------
    push(v) { this.stack.push(v); }
    pop() { return this.stack.pop(); }
    popN(n) {
      const s = this.stack;
      return n ? s.splice(s.length - n, n) : [];
    }

    // storage access
    cont(area, slot) {
      switch (area) {
        case 0: return this.G;
        case 1: return this.frame.L;
        case 2: return this.frame.proc.statics;
        case 3: return this.frame.L[slot].c;
      }
    }
    key(area, slot) { return area === 3 ? this.frame.L[slot].k : slot; }
    load(area, slot) {
      switch (area) {
        case 0: return this.G[slot];
        case 1: return this.frame.L[slot];
        case 2: return this.frame.proc.statics[slot];
        case 3: { const r = this.frame.L[slot]; return r.c[r.k]; }
      }
    }
    storeTo(c, k, type, v) {
      if (type.code === 6) {
        const dst = c[k];
        if (dst && typeof dst === 'object') { copyRecordInto(dst, v); return; }
        c[k] = B.cloneRecord(v);
        return;
      }
      c[k] = B.coerce(type, v);
    }
    getArray(area, slot, ndims, type) {
      const c = this.cont(area, slot), k = this.key(area, slot);
      let a = c[k];
      if (!a) {
        // implicit array: subscripts up to 10
        const dims = [];
        for (let i = 0; i < ndims; i++) dims.push({ lo: this.prog.compiler.optionBase || 0, hi: 10 });
        a = c[k] = new B.BArray(type, dims, false);
      }
      return a;
    }

    // ---- main loop -------------------------------------------------------------------------
    exec(budget) {
      const code = this.code;
      const stack = this.stack;
      const deadline = now() + budget;
      let count = 0;
      try {
        while (this.state === 'running') {
          const ins = code[this.pc++];
          switch (ins.op) {
            case O.NOP: break;
            case O.CONST: stack.push(ins.a); break;
            case O.POP: stack.pop(); break;
            case O.DUP: stack.push(stack[stack.length - 1]); break;
            case O.LD: {
              const a = ins.a;
              stack.push(a === 0 ? this.G[ins.b] : a === 1 ? this.frame.L[ins.b] : this.load(a, ins.b));
              break;
            }
            case O.ST: {
              const v = stack.pop();
              const t = ins.c;
              if (ins.a === 0 && t.code <= 5 && t.k !== 'fixstr') this.G[ins.b] = t.code === 5 ? v : B.coerce(t, v);
              else this.storeTo(this.cont(ins.a, ins.b), this.key(ins.a, ins.b), t, v);
              break;
            }
            case O.REF: {
              if (ins.a === 3) stack.push(this.frame.L[ins.b]);
              else stack.push(new B.Ref(this.cont(ins.a, ins.b), ins.b));
              break;
            }
            case O.ARRLD: {
              const subs = this.popN(ins.c);
              const arr = this.getArray(ins.a, ins.b, ins.c, ins.d);
              stack.push(arr.data[arr.index(subs)]);
              break;
            }
            case O.ARRST: {
              const v = stack.pop();
              const subs = this.popN(ins.c);
              const arr = this.getArray(ins.a, ins.b, ins.c, ins.d);
              const i = arr.index(subs);
              if (ins.d.code === 6) copyRecordInto(arr.data[i], v);
              else arr.data[i] = B.coerce(ins.d, v);
              break;
            }
            case O.ARRREF: {
              const subs = this.popN(ins.c);
              const arr = this.getArray(ins.a, ins.b, ins.c, ins.d);
              stack.push(new B.Ref(arr.data, arr.index(subs)));
              break;
            }
            case O.FLD: { const o = stack.pop(); stack.push(o[ins.a]); break; }
            case O.FLDST: {
              const v = stack.pop(); const o = stack.pop();
              this.storeTo(o, ins.a, ins.b, v);
              break;
            }
            case O.FLDREF: { const o = stack.pop(); stack.push(new B.Ref(o, ins.a)); break; }
            case O.DEREF: { const r = stack.pop(); stack.push(r.c[r.k]); break; }
            case O.STREF: { const v = stack.pop(); const r = stack.pop(); this.storeTo(r.c, r.k, ins.a, v); break; }
            case O.MKREF: { const v = stack.pop(); stack.push(new B.Ref([v], 0)); break; }

            // arithmetic
            case O.ADD: { const b = stack.pop(); const a = stack.pop(); stack.push(B.fixNum(ins.a, a + b)); break; }
            case O.SUB: { const b = stack.pop(); const a = stack.pop(); stack.push(B.fixNum(ins.a, a - b)); break; }
            case O.MUL: { const b = stack.pop(); const a = stack.pop(); stack.push(B.fixNum(ins.a, a * b)); break; }
            case O.DIV: {
              const b = stack.pop(); const a = stack.pop();
              if (b === 0) err(11);
              stack.push(B.fixNum(ins.a, a / b));
              break;
            }
            case O.IDIV: {
              const conv = ins.a === 1 ? B.toInt : B.toLong;
              const b = conv(stack.pop()); const a = conv(stack.pop());
              if (b === 0) err(11);
              stack.push(B.fixNum(ins.a, Math.trunc(a / b)));
              break;
            }
            case O.MOD: {
              const conv = ins.a === 1 ? B.toInt : B.toLong;
              const b = conv(stack.pop()); const a = conv(stack.pop());
              if (b === 0) err(11);
              const r = a % b;
              stack.push(r === 0 ? 0 : r);
              break;
            }
            case O.POW: {
              const b = stack.pop(); const a = stack.pop();
              if (a === 0 && b < 0) err(11);
              if (a < 0 && b !== Math.trunc(b)) err(5);
              stack.push(B.fixNum(ins.a, Math.pow(a, b)));
              break;
            }
            case O.NEG: { const a = stack.pop(); stack.push(B.fixNum(ins.a, a === 0 ? 0 : -a)); break; }
            case O.CAT: { const b = stack.pop(); const a = stack.pop(); stack.push(a + b); break; }
            case O.EQ: { const b = stack.pop(); const a = stack.pop(); stack.push(a === b ? -1 : 0); break; }
            case O.NE: { const b = stack.pop(); const a = stack.pop(); stack.push(a !== b ? -1 : 0); break; }
            case O.LT: { const b = stack.pop(); const a = stack.pop(); stack.push(a < b ? -1 : 0); break; }
            case O.GT: { const b = stack.pop(); const a = stack.pop(); stack.push(a > b ? -1 : 0); break; }
            case O.LE: { const b = stack.pop(); const a = stack.pop(); stack.push(a <= b ? -1 : 0); break; }
            case O.GE: { const b = stack.pop(); const a = stack.pop(); stack.push(a >= b ? -1 : 0); break; }
            case O.AND: { const b = B.toLong(stack.pop()); const a = B.toLong(stack.pop()); stack.push(a & b); break; }
            case O.OR: { const b = B.toLong(stack.pop()); const a = B.toLong(stack.pop()); stack.push(a | b); break; }
            case O.XOR: { const b = B.toLong(stack.pop()); const a = B.toLong(stack.pop()); stack.push(a ^ b); break; }
            case O.EQV: { const b = B.toLong(stack.pop()); const a = B.toLong(stack.pop()); stack.push(~(a ^ b)); break; }
            case O.IMP: { const b = B.toLong(stack.pop()); const a = B.toLong(stack.pop()); stack.push(~a | b); break; }
            case O.NOT: { const a = B.toLong(stack.pop()); stack.push(~a); break; }
            case O.CVT: {
              const v = stack.pop();
              stack.push(ins.a === 1 ? B.toInt(v) : ins.a === 2 ? B.toLong(v) : ins.a === 3 ? B.toSingle(v) : B.toDouble(v));
              break;
            }

            // control flow
            case O.JMP: this.pc = ins.a; break;
            case O.JF: if (stack.pop() === 0) this.pc = ins.a; break;
            case O.JT: if (stack.pop() !== 0) this.pc = ins.a; break;
            case O.STMT: {
              const f = this.frame;
              f.stmt = ins.a;
              f.sp = stack.length;
              this.statementsExecuted++;
              if (this.dbg && this.onStmt(ins.a)) return;
              break;
            }
            case O.GOSUB: {
              const g = this.frame.gosub;
              if (g.length > 20000) err(28);
              g.push(this.pc);
              this.pc = ins.a;
              break;
            }
            case O.RETURN: {
              const f = this.frame;
              if (!f.gosub.length) {
                if (f.kind === FK_EVENT) { this.returnFromEvent(ins.a); break; }
                err(3);
              }
              const r = f.gosub.pop();
              this.pc = ins.a >= 0 ? ins.a : r;
              break;
            }
            case O.ONGO: {
              const n = B.toInt(stack.pop());
              if (n < 0 || n > 255) err(5);
              if (n >= 1 && n <= ins.a.length) {
                if (ins.b) { this.frame.gosub.push(this.pc); }
                this.pc = ins.a[n - 1];
              }
              break;
            }
            case O.FOR: this.opFor(ins); break;
            case O.NEXT: this.opNext(ins); break;
            case O.EXITFOR: this.frame.fors.pop(); this.pc = ins.a; break;
            case O.CALL: this.opCall(ins); break;
            case O.RET: this.opRet(); break;
            case O.CALLB: {
              const args = this.popN(ins.b);
              this.argCodes = ins.e;
              const v = ins.a(this, ...args);
              if (v !== WAIT) stack.push(v);
              break;
            }
            case O.SYS: {
              const args = this.popN(ins.b);
              const spec = B.SYS_STMTS[ins.a];
              spec.impl(this, ...args);
              break;
            }
            case O.END: this.opEnd(ins.a); break;
            case O.STOP:
              this.pauseReason = 'stop';
              this.state = 'paused';
              this.stoppedByStop = true;
              this.emit('pause', 'stop');
              this.emit('state', this.state);
              break;

            // printing
            case O.PRCH: this.opPrch(ins.a); break;
            case O.PRVAL: this.printVal(stack.pop(), ins.a); break;
            case O.PRCOMMA: this.out.comma(); break;
            case O.PRTAB: this.out.tab(stack.pop()); break;
            case O.PRSPC: this.out.spc(stack.pop()); break;
            case O.PREND: this.opPrend(ins.a); break;
            case O.PRUSING: this.using = new B.PrintUsing(stack.pop()); break;
            case O.PRUVAL: this.out.write(this.using.next(stack.pop())); break;
            case O.WRITE: this.opWrite(stack.pop(), ins.a, ins.b); break;
            case O.INPUT: this.opInput(ins.a); break;
            case O.LINEINPUT: this.opLineInput(ins.a); break;
            case O.INPUTVAL: stack.push(this.inputVals[ins.a]); break;
            case O.FINPUT: { const n = stack.pop(); stack.push(B.fileInput(this, n, ins.a)); break; }
            case O.FLINEINPUT: { const n = stack.pop(); stack.push(B.fileLineInput(this, n)); break; }
            case O.READ: stack.push(this.opRead(ins.a)); break;
            case O.RESTORE: this.dataPtr = ins.a; break;

            case O.DIM: this.opDim(ins); break;
            case O.ERASE: {
              const c = this.cont(ins.a, ins.b), k = this.key(ins.a, ins.b);
              const arr = c[k];
              if (arr) {
                if (arr.dynamic) c[k] = null;
                else { arr.clear(); arr.erased = true; }
              }
              break;
            }
            case O.SWAP: {
              const rb = stack.pop(), ra = stack.pop();
              const va = ra.c[ra.k], vb = rb.c[rb.k];
              if (ins.a.code === 6) {
                const tmp = B.cloneRecord(va);
                copyRecordInto(va, vb); copyRecordInto(vb, tmp);
              } else {
                ra.c[ra.k] = B.coerce(ins.a, vb);
                rb.c[rb.k] = B.coerce(ins.b, va);
              }
              break;
            }
            case O.MIDSET: {
              const v = stack.pop(); let len = stack.pop(); const start = stack.pop(); const r = stack.pop();
              const s = r.c[r.k];
              if (start < 1 || start > s.length || (len !== undefined && len < 0)) err(5);
              let n = v.length;
              if (len !== undefined && len < n) n = len;
              if (n > s.length - start + 1) n = s.length - start + 1;
              r.c[r.k] = s.slice(0, start - 1) + v.slice(0, n) + s.slice(start - 1 + n);
              break;
            }
            case O.LRSET: {
              const v = stack.pop(); const r = stack.pop();
              const cur = r.c[r.k];
              if (typeof cur === 'object' && cur) {
                // LSET record = record (byte copy)
                const src = v;
                const bytes = new Uint8Array(Math.max(cur.__def.size, src.__def.size));
                bytes.fill(32);
                B.serialize(B.recordType(src.__def), src, bytes, 0);
                const nv = B.deserialize(B.recordType(cur.__def), bytes, 0);
                copyRecordInto(cur, nv);
                break;
              }
              const n = cur.length;
              let s = v.length > n ? v.slice(0, n) : v;
              s = ins.a ? ' '.repeat(n - s.length) + s : s + ' '.repeat(n - s.length);
              r.c[r.k] = s;
              if (r.onSet) r.onSet(s);
              break;
            }

            // errors/events
            case O.ONERROR: {
              if (ins.a === -1 && this.inErrHandler) {
                // ON ERROR GOTO 0 inside handler: stop with the original error
                const e = new BasicError(this.err);
                this.inErrHandler = null;
                this.errHandler = -1;
                this.fatal(e);
                return;
              }
              this.errHandler = ins.a;
              break;
            }
            case O.RESUME: this.opResume(ins); break;
            case O.ERROR: {
              const n = B.toInt(stack.pop());
              if (n < 1 || n > 255) err(5);
              throw new BasicError(n);
            }
            case O.ONEVENT: { const arg = stack.pop(); this.setEventHandler(ins.a, arg, ins.b); break; }
            case O.EVENTCTL: { const arg = stack.pop(); this.setEventState(ins.a, arg, ins.b); break; }

            // files
            case O.OPEN: {
              const len = stack.pop(), file = stack.pop(), num = stack.pop(), mode = stack.pop();
              B.fileOpen(this, ins.a, mode, num, file, len, ins.b);
              break;
            }
            case O.CLOSE: {
              const nums = this.popN(ins.a);
              if (!nums.length) this.closeAllFiles();
              else for (const n of nums) B.fileClose(this, n);
              break;
            }
            case O.FIELD: {
              const pairs = this.popN(ins.a * 2);
              const n = stack.pop();
              B.fileField(this, n, pairs);
              break;
            }
            case O.FGET: { const r = stack.pop(); const rec = stack.pop(); const n = stack.pop(); B.fileGet(this, n, rec, r, ins.a); break; }
            case O.FPUT: { const v = stack.pop(); const rec = stack.pop(); const n = stack.pop(); B.filePut(this, n, rec, v, ins.a); break; }

            // graphics
            case O.GPOINT: {
              const color = stack.pop(), y = stack.pop(), x = stack.pop();
              this.gfx().pset(x, y, color, !!ins.a, !!ins.b);
              break;
            }
            case O.GLINE: {
              const style = stack.pop(), color = stack.pop(), y2 = stack.pop(), x2 = stack.pop(), y1 = stack.pop(), x1 = stack.pop();
              this.gfx().line(ins.a, x1, y1, x2, y2, color, style);
              break;
            }
            case O.GCIRCLE: {
              const aspect = stack.pop(), end = stack.pop(), start = stack.pop(), color = stack.pop(), r = stack.pop(), y = stack.pop(), x = stack.pop();
              this.gfx().circle(!!ins.a, x, y, r, color, start, end, aspect);
              break;
            }
            case O.GPAINT: {
              const bg = stack.pop(), border = stack.pop(), paint = stack.pop(), y = stack.pop(), x = stack.pop();
              this.gfx().paint(!!ins.a, x, y, paint, border, bg, !!ins.b);
              break;
            }
            case O.GGET: {
              const subs = this.popN(ins.a); const ref = stack.pop();
              const y2 = stack.pop(), x2 = stack.pop(), y1 = stack.pop(), x1 = stack.pop();
              this.gfx().get(ins.b, x1, y1, x2, y2, this.arrayBytes(ref, subs));
              break;
            }
            case O.GPUT: {
              const subs = this.popN(ins.a); const ref = stack.pop();
              const y = stack.pop(), x = stack.pop();
              this.gfx().put(ins.b, x, y, this.arrayBytes(ref, subs));
              break;
            }
            case O.PALUSING: {
              const subs = this.popN(ins.a); const ref = stack.pop();
              const arr = ref.c[ref.k];
              if (!arr) err(5);
              const start = subs.length ? arr.index(subs) : 0;
              this.display.paletteUsing(arr.data, start);
              break;
            }

            case O.CHAIN: { const line = stack.pop(); const file = stack.pop(); this.requestChain('chain', file, line, ins.a); return; }
            case O.RUN: { const file = stack.pop(); this.requestChain('run', file, ins.a, {}); return; }
            case O.CMD: { const file = stack.pop(); this.requestCommand(ins.a, file); break; }
            case O.CLEAR: this.opClear(); break;
            case O.EVALEND: this.state = 'evaldone'; return;
            default:
              throw new Error('Bad opcode ' + ins.op);
          }
          if ((++count & 1023) === 0) {
            if (now() > deadline) break;
            this.pollTimers();
          }
        }
      } catch (e) {
        this.handleError(e);
      }
    }

    gfx() { return this.display; }

    arrayBytes(ref, subs) {
      let arr = ref.c[ref.k];
      if (!arr) {
        // GET into an undimensioned array: QBasic requires DIM; auto-create a 0..10 array
        err(5);
      }
      const start = subs.length ? arr.index(subs) : 0;
      return arr.bytes(start);
    }

    // ---- statement hook (debugger, events, tracing) ------------------------------------------
    onStmt(idx) {
      if (this.evPending && !this.inEventDispatch) {
        if (this.dispatchEvents()) return false;
      }
      const st = this.prog.stmts[idx];
      if (this.recordHistory && !st.noStep) {
        const h = this.history;
        if (h.length >= this.historyMax * 2) h.splice(0, h.length - this.historyMax);
        h.push(idx);
      }
      if (this.tron && st.lineNo !== null && (st.lineStart || st.lineNo !== this.lastTron)) {
        this.lastTron = st.lineNo;
        this.printText('[' + st.lineNo + ']');
      }
      if (this.traceHook) this.traceHook(idx);
      if (this.skipBreak) { this.skipBreak = false; }
      else if (!st.noStep) {
        let brk = null;
        if (this.stepMode) {
          const d = this.frames.length;
          if (this.stepMode === 'into' || (this.stepMode === 'over' && d <= this.stepDepth) || (this.stepMode === 'out' && d < this.stepDepth)) brk = 'step';
        }
        if (!brk && this.breakpoints.has(idx)) {
          const cond = this.condBreaks.get(idx);
          if (!cond || this.safeEval(cond)) brk = 'breakpoint';
        }
        if (!brk && this.watchpoints.length) {
          for (const w of this.watchpoints) {
            const v = this.safeEval(w.fn);
            if (w.mode === 'true' ? v : (w.last !== undefined && v !== w.last)) { brk = 'watch'; this.lastWatch = w; }
            w.last = v;
            if (brk) break;
          }
        }
        if (brk) {
          this.pc--; // re-execute STMT on resume
          this.stepMode = null;
          this.state = 'paused';
          this.pauseReason = brk;
          this.updateDbgFlag();
          this.emit('pause', brk);
          this.emit('state', this.state);
          return true;
        }
      }
      if (this.throttle > 0) {
        if (--this.stmtBudget <= 0) {
          this.pc--;
          this.skipBreak = true;
          this.throttleYield = true;
          return true;
        }
      }
      return false;
    }
    safeEval(fn) {
      try { return fn(this); } catch (e) { return undefined; }
    }

    // ---- events (ON TIMER/KEY/PLAY/STRIG/PEN) ---------------------------------------------------
    setEventHandler(ev, arg, pc) {
      const e = this.eventSlot(ev, arg);
      e.pc = pc;
      if (ev === 'TIMER') {
        if (arg <= 0 || arg > 86400) err(5);
        e.interval = arg;
        e.next = now() + arg * 1000;
      }
      if (ev === 'PLAY') e.n = arg;
    }
    eventSlot(ev, arg) {
      if (ev === 'KEY' || ev === 'STRIG') {
        const m = this.events[ev];
        if (!m[arg]) m[arg] = { state: 'OFF', pc: -1, fired: false, busy: false };
        return m[arg];
      }
      return this.events[ev] || (this.events[ev] = { state: 'OFF', pc: -1, fired: false, busy: false });
    }
    setEventState(ev, arg, mode) {
      if (ev === 'COM' || ev === 'UEVENT') return;
      if ((ev === 'KEY' || ev === 'STRIG') && (arg === 0 || arg === -1)) {
        const all = ev === 'KEY' ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 30, 31] : [0, 2, 4, 6];
        for (const k of all) this.setEventState(ev, k, mode);
        if (ev === 'STRIG' && this.host.gamepad) this.host.gamepad.enabled = mode !== 'OFF';
        return;
      }
      const e = this.eventSlot(ev, arg);
      e.state = mode;
      if (mode === 'OFF') e.fired = false;
      if (ev === 'TIMER' && mode === 'ON') e.next = now() + e.interval * 1000;
      if (mode === 'ON' && e.fired) { this.evPending = true; this.updateDbgFlag(); }
      this.anyEvents = true;
    }
    /** Called by host when a trappable key is pressed. Returns true if trapped (key consumed). */
    keyEvent(n) {
      const e = this.events.KEY[n];
      if (!e || e.state === 'OFF' || e.pc < 0) return false;
      e.fired = true;
      if (e.state === 'ON') { this.evPending = true; this.updateDbgFlag(); }
      return true;
    }
    fireEvent(ev, arg) {
      const e = arg === undefined ? this.events[ev] : this.eventSlot(ev, arg);
      if (!e || e.state === 'OFF' || e.pc < 0) return;
      e.fired = true;
      if (e.state === 'ON') { this.evPending = true; this.updateDbgFlag(); }
    }
    pollTimers() {
      const t = this.events.TIMER;
      if (t.state !== 'OFF' && t.pc >= 0 && t.interval > 0) {
        const n = now();
        if (n >= t.next) {
          t.next = n + t.interval * 1000;
          t.fired = true;
          if (t.state === 'ON') { this.evPending = true; this.updateDbgFlag(); }
        }
      }
      const p = this.events.PLAY;
      if (p.state !== 'OFF' && p.pc >= 0 && this.audio) {
        const q = this.audio.notesQueued();
        if (p.lastQueued !== undefined && p.lastQueued >= p.n && q < p.n) {
          p.fired = true;
          if (p.state === 'ON') { this.evPending = true; this.updateDbgFlag(); }
        }
        p.lastQueued = q;
      }
      if (this.evPending && this.state === 'waiting' && this.pending && this.pending.interruptible) {
        // SLEEP ends when an event is trapped
        this.pending.interrupted = true;
      }
    }
    dispatchEvents() {
      const pick = () => {
        const tryE = (e) => e && e.fired && e.state === 'ON' && !e.busy && e.pc >= 0 ? e : null;
        let e = tryE(this.events.TIMER);
        if (e) return e;
        for (const k in this.events.KEY) { e = tryE(this.events.KEY[k]); if (e) return e; }
        e = tryE(this.events.PLAY); if (e) return e;
        for (const k in this.events.STRIG) { e = tryE(this.events.STRIG[k]); if (e) return e; }
        e = tryE(this.events.PEN); if (e) return e;
        return null;
      };
      const e = pick();
      if (!e) {
        this.evPending = false;
        this.updateDbgFlag();
        return false;
      }
      e.fired = false;
      e.busy = true;
      const f = new Frame(this.prog.main, [], this.pc - 0, FK_EVENT, false);
      f.event = e;
      f.retPc = this.pc;
      // The STMT op already executed; on return we continue with the statement itself
      this.frames.push(f);
      this.frame = f;
      this.pc = e.pc;
      // re-check pending
      this.evPending = false;
      this.updateDbgFlag();
      return true;
    }
    returnFromEvent(target) {
      const f = this.frames.pop();
      this.frame = this.frames[this.frames.length - 1];
      f.event.busy = false;
      if (f.event.fired && f.event.state === 'ON') { this.evPending = true; this.updateDbgFlag(); }
      this.pc = target >= 0 ? target : f.retPc;
      // anything still pending?
      this.evPending = true;
      this.updateDbgFlag();
    }

    // ---- ops ------------------------------------------------------------------------------------------
    opFor(ins) {
      const stack = this.stack;
      const step = stack.pop(), limit = stack.pop(), start = stack.pop();
      const c = this.cont(ins.a, ins.b), k = this.key(ins.a, ins.b);
      c[k] = start;
      const fors = this.frame.fors;
      // Re-entering the same FOR statement (e.g. after GOTO out of the loop) replaces its old record.
      // Loops are identified by statement, not variable, so a GOSUB routine that runs its own
      // FOR i does not destroy the caller's FOR i loop (QBasic behaviour).
      for (let i = fors.length - 1; i >= 0; i--) {
        if (fors[i].ins === ins) { fors.length = i; break; }
      }
      if (fors.length > 1000) fors.splice(0, fors.length - 1000);
      const rec = { c, k, limit, step, code: ins.c.code, body: this.pc, name: ins.varName, ins };
      if (step >= 0 ? start > limit : start < limit) {
        this.pc = ins.d;
        return;
      }
      fors.push(rec);
    }
    opNext(ins) {
      const fors = this.frame.fors;
      let rec;
      if (ins.a < 0) {
        rec = fors[fors.length - 1];
        if (!rec) err(1);
      } else {
        const c = this.cont(ins.a, ins.b), k = this.key(ins.a, ins.b);
        let i = fors.length - 1;
        for (; i >= 0; i--) if (fors[i].c === c && fors[i].k === k) break;
        if (i < 0) err(1);
        fors.length = i + 1;
        rec = fors[i];
      }
      const v = B.fixNum(rec.code, rec.c[rec.k] + rec.step);
      rec.c[rec.k] = rec.code === 3 ? Math.fround(v) : v;
      if (rec.step >= 0 ? v <= rec.limit : v >= rec.limit) this.pc = rec.body;
      else fors.pop();
    }
    opCall(ins) {
      const proc = this.prog.procs[ins.a];
      const args = this.popN(ins.b);
      if (this.frames.length > 4000) err(28);
      const L = new Array(proc.nlocals);
      const types = proc.localTypes;
      for (let i = 0; i < proc.nlocals; i++) L[i] = this.initValue(types[i]);
      for (let i = 0; i < args.length; i++) L[proc.paramSlots[i]] = args[i];
      const f = new Frame(proc, L, this.pc, FK_NORMAL, !!ins.c);
      this.frames.push(f);
      this.frame = f;
      this.pc = proc.entry;
    }
    opRet() {
      const f = this.frames.pop();
      if (!this.frames.length) { this.frames.push(f); this.opEnd(0); return; }
      this.frame = this.frames[this.frames.length - 1];
      this.pc = f.retPc;
      if (f.isFunc) this.stack.push(f.L[f.proc.retSlot]);
    }
    opEnd(system) {
      if (this.inErrHandler && !system) {
        // falling off the end inside an error handler
      }
      this.closeAllFiles();
      this.state = 'ended';
      this.endReason = system ? 'system' : 'end';
      if (this.audio && !system) { /* let music finish */ }
      this.emit('end', { reason: this.endReason });
      this.emit('state', this.state);
    }
    opClear() {
      this.closeAllFiles();
      const prog = this.prog;
      for (let i = 0; i < prog.ngl; i++) this.G[i] = this.initValue(prog.globalTypes[i]);
      this.dataPtr = 0;
      this.errHandler = -1;
      for (const k in this.events.KEY) this.events.KEY[k].state = 'OFF';
      this.events.TIMER.state = 'OFF';
    }
    opDim(ins) {
      const n = ins.d;
      const vals = this.popN(n * 2);
      const dims = [];
      for (let i = 0; i < n; i++) {
        const lo = vals[i * 2], hi = vals[i * 2 + 1];
        if (hi < lo) err(9);
        dims.push({ lo, hi });
      }
      const c = this.cont(ins.a, ins.b), k = this.key(ins.a, ins.b);
      const opts = ins.e;
      const old = c[k];
      if (old && !opts.redim && !old.erased) err(10, 'Array already dimensioned');
      const arr = new B.BArray(ins.c, dims, opts.dynamic);
      if (opts.preserve && old) {
        // copy overlapping region element by element
        const idx = new Array(n).fill(0);
        const rec = (d) => {
          if (d < 0) {
            try {
              const si = old.index(idx), di = arr.index(idx);
              arr.data[di] = old.data[si];
            } catch (e) { /* outside */ }
            return;
          }
          const lo = Math.max(dims[d].lo, old.dims[d] ? old.dims[d].lo : 0);
          const hi = Math.min(dims[d].hi, old.dims[d] ? old.dims[d].hi : -1);
          for (let v = lo; v <= hi; v++) { idx[d] = v; rec(d - 1); }
        };
        if (old.dims.length === n) rec(n - 1);
      }
      c[k] = arr;
    }
    opRead(code) {
      const d = this.prog.data;
      if (this.dataPtr >= d.length) err(4);
      const item = d[this.dataPtr++];
      if (code === 5) return item.v;
      if (item.quoted) err(2, 'DATA');
      const s = item.v.trim();
      if (s === '') return 0;
      const r = B.parseNumber(s);
      if (r.len < s.length) err(2, 'DATA');
      return r.v;
    }

    // ---- printing -----------------------------------------------------------------------------------
    opPrch(mode) {
      if (mode === 0) this.out = this.screenOut();
      else if (mode === 2) this.out = this.printerOut();
      else this.out = B.fileOutChannel(this, this.stack.pop());
    }
    screenOut() {
      if (!this._screenOut) this._screenOut = new ScreenChannel(this);
      return this._screenOut;
    }
    printerOut() {
      if (!this._printerOut) this._printerOut = new PrinterChannel(this);
      return this._printerOut;
    }
    printVal(v, code) {
      if (typeof v === 'string') { this.out.write(v); return; }
      const s = B.fmtNum(v, code);
      const t = (s[0] === '-' ? s : ' ' + s) + ' ';
      // numbers don't split across lines
      if (this.out.col + t.length > this.out.width + 1 && this.out.col > 1) this.out.newline();
      this.out.write(t);
    }
    opPrend(nl) {
      if (this.using) {
        this.out.write(this.using.finish());
        this.using = null;
      }
      if (nl) this.out.newline();
      if (this.out.flush) this.out.flush();
      this.out = null;
    }
    opWrite(v, code, last) {
      let s;
      if (typeof v === 'string') s = '"' + v + '"';
      else s = B.fmtNum(v, code);
      this.out.write(s);
      if (last) { this.out.newline(); if (this.out.flush) this.out.flush(); this.out = null; }
      else this.out.write(',');
    }
    printText(s) {
      const o = this.screenOut();
      o.write(s);
    }

    // ---- INPUT ------------------------------------------------------------------------------------------
    opInput(spec) {
      const o = this.screenOut();
      const prompt = (spec.prompt !== null ? spec.prompt : '') + (spec.qmark ? '? ' : '');
      const doPrompt = () => {
        o.write(prompt);
        const ed = new B.LineEditor(this, spec.noNewline);
        this.block({
          interruptible: false,
          poll: () => {
            const line = ed.poll();
            if (line === null) return false;
            const vals = parseInputLine(line, spec.types);
            if (!vals) {
              o.write('Redo from start');
              o.newline();
              doPrompt();
              return false;
            }
            this.inputVals = vals;
            return true;
          },
          cancel: () => ed.cancel(),
        });
      };
      doPrompt();
    }
    opLineInput(spec) {
      const o = this.screenOut();
      if (spec.prompt !== null) o.write(spec.prompt);
      const ed = new B.LineEditor(this, spec.noNewline);
      this.block({
        poll: () => {
          const line = ed.poll();
          if (line === null) return false;
          this.inputVals = [line];
          return true;
        },
        cancel: () => ed.cancel(),
      });
    }

    // ---- errors ------------------------------------------------------------------------------------------
    handleError(e) {
      if (!(e instanceof BasicError)) {
        if (e && e.code !== undefined && e instanceof B.CompileError) { this.fatal(e); return; }
        // Internal JS error: report as error 51
        // eslint-disable-next-line no-console
        if (typeof console !== 'undefined') console.error(e);
        e = Object.assign(new BasicError(51, e && e.message), { internal: e });
      }
      const f = this.frame;
      const stmt = this.prog.stmts[f.stmt];
      this.err = e.code;
      this.erl = stmt && stmt.lineNo !== null ? stmt.lineNo : 0;
      this.lastError = e;
      if (this.errHandler === -2) {
        // ON ERROR RESUME NEXT
        this.stack.length = f.sp;
        this.pc = stmt ? stmt.endPc : this.pc;
        return;
      }
      if (this.errHandler >= 0 && !this.inErrHandler) {
        this.inErrHandler = { frameIndex: this.frames.length - 1, stmt: f.stmt, sp: f.sp };
        const ef = new Frame(this.prog.main, [], this.pc, FK_ERROR, false);
        this.frames.push(ef);
        this.frame = ef;
        this.pc = this.errHandler;
        return;
      }
      this.fatal(e);
    }
    fatal(e) {
      this.state = 'error';
      this.closeAllFiles();
      const f = this.frame;
      let stmtIdx = f.stmt;
      // In an error handler, report the original location
      if (this.inErrHandler && f.kind === FK_ERROR) stmtIdx = this.inErrHandler.stmt;
      const stmt = this.prog.stmts[stmtIdx];
      this.errorInfo = { code: e.code, message: e.message, stmt: stmtIdx, pos: stmt ? stmt.pos : null, lineNo: stmt ? stmt.lineNo : null };
      if (this.audio) this.audio.stopAll();
      this.emit('error', this.errorInfo);
      this.emit('state', this.state);
    }
    opResume(ins) {
      const h = this.inErrHandler;
      if (!h) err(20);
      // pop frames back to the frame that raised the error
      while (this.frames.length - 1 > h.frameIndex) this.frames.pop();
      this.frame = this.frames[this.frames.length - 1];
      this.inErrHandler = null;
      const stmt = this.prog.stmts[h.stmt];
      this.stack.length = h.sp;
      this.err = 0;
      if (ins.a === 0) this.pc = stmt.pc;
      else if (ins.a === 1) this.pc = stmt.endPc;
      else {
        // RESUME line: unwind to module level
        while (this.frames.length > 1 && this.frame.kind !== FK_NORMAL) this.frames.pop();
        this.frame = this.frames[this.frames.length - 1];
        this.pc = ins.b;
      }
    }

    // ---- files ---------------------------------------------------------------------------------------------
    closeAllFiles() {
      for (const n of Array.from(this.files.keys())) {
        try { B.fileClose(this, n); } catch (e) { /* ignore */ }
      }
    }

    // ---- CHAIN / RUN / commands ------------------------------------------------------------------------------
    requestChain(kind, file, line, opts) {
      this.state = 'chain';
      this.chainRequest = { kind, file, line, opts };
      this.emit('chain', this.chainRequest);
      this.emit('state', this.state);
    }
    requestCommand(st, file) {
      if (this.host.command) {
        const r = this.host.command(this, st, file);
        if (r === WAIT) return;
      } else err(73);
    }

    // ---- debugger helpers --------------------------------------------------------------------------------------
    /** Source position of the statement currently executing in frame i (default: top). */
    framePos(i) {
      const f = i === undefined ? this.frame : this.frames[i];
      const st = this.prog.stmts[f.stmt];
      return st ? st.pos : null;
    }
    currentStmt() { return this.prog.stmts[this.frame.stmt] || null; }

    /** Describe frames for the call stack panel (innermost first). */
    callStack() {
      const out = [];
      for (let i = this.frames.length - 1; i >= 0; i--) {
        const f = this.frames[i];
        const st = this.prog.stmts[f.stmt];
        let name = f.kind === FK_EVENT ? 'Event handler' : f.kind === FK_ERROR ? 'Error handler' : (f.proc.kind === 'module' ? 'Main module' : (f.proc.kind === 'def' ? 'DEF ' : f.proc.kind === 'sub' ? 'SUB ' : 'FUNCTION ') + (f.proc.display || f.proc.name));
        out.push({ index: i, name, pos: st ? st.pos : null, lineNo: st ? st.lineNo : null, frame: f });
      }
      return out;
    }
  }

  function copyRecordInto(dst, src) {
    if (!src || typeof src !== 'object' || src.__def !== dst.__def) err(13);
    for (const f of dst.__def.fields) {
      if (f.type.code === 6) copyRecordInto(dst[f.name], src[f.name]);
      else dst[f.name] = src[f.name];
    }
  }
  B.copyRecordInto = copyRecordInto;

  /** Parse a line typed at an INPUT prompt into values; returns null when "Redo from start" */
  function parseInputLine(line, types) {
    const vals = [];
    let i = 0;
    const n = line.length;
    for (let vi = 0; vi < types.length; vi++) {
      const t = types[vi];
      while (i < n && line[i] === ' ') i++;
      if (B.isStr(t)) {
        let s;
        if (line[i] === '"') {
          const j = line.indexOf('"', i + 1);
          if (j < 0) { s = line.slice(i + 1); i = n; }
          else {
            s = line.slice(i + 1, j);
            i = j + 1;
            while (i < n && line[i] === ' ') i++;
            if (i < n && line[i] !== ',') return null;
          }
        } else {
          let j = line.indexOf(',', i);
          if (j < 0) j = n;
          s = line.slice(i, j).replace(/\s+$/, '');
          i = j;
        }
        vals.push(s);
      } else {
        let j = line.indexOf(',', i);
        if (j < 0) j = n;
        const field = line.slice(i, j).trim();
        i = j;
        if (field === '') vals.push(0);
        else {
          const r = B.parseNumber(field);
          if (!r.ok && !/^&/.test(field)) return null;
          if (r.len < field.length) return null;
          try { vals.push(B.coerce(t, r.v)); } catch (e) { return null; }
        }
      }
      if (vi < types.length - 1) {
        if (line[i] !== ',') return null;
        i++;
      }
    }
    while (i < n && line[i] === ' ') i++;
    if (i < n) return null; // too many values
    return vals;
  }
  B.parseInputLine = parseInputLine;

  // ---- output channels -------------------------------------------------------------------------------------------
  class ScreenChannel {
    constructor(vm) { this.vm = vm; }
    get d() { return this.vm.display; }
    get col() { return this.d.cursorCol() + 1; }
    get width() { return this.d.textCols(); }
    write(s) { this.d.printString(s); }
    newline() { this.d.newline(); }
    comma() {
      const d = this.d;
      const col = d.cursorCol();
      const w = d.textCols();
      const next = (Math.floor(col / 14) + 1) * 14;
      if (next >= w - 13 || next >= w) { d.newline(); return; }
      d.printString(' '.repeat(next - col));
    }
    tab(n) {
      const d = this.d;
      const w = d.textCols();
      n = B.toInt(n);
      if (n < 1) n = 1;
      n = ((n - 1) % w) + 1;
      const col = d.cursorCol() + 1;
      if (col > n) { d.newline(); d.printString(' '.repeat(n - 1)); }
      else d.printString(' '.repeat(n - col));
    }
    spc(n) {
      n = B.toInt(n);
      if (n < 0) n = 0;
      const w = this.d.textCols();
      n = n % w;
      this.d.printString(' '.repeat(n));
    }
  }
  B.ScreenChannel = ScreenChannel;

  class PrinterChannel {
    constructor(vm) { this.vm = vm; this.col = 1; this.width = 80; this.buf = ''; }
    write(s) {
      for (const ch of s) {
        if (ch === '\r' || ch === '\n') { this.newline(); continue; }
        this.buf += ch;
        this.col++;
        if (this.width < 255 && this.col > this.width) this.newline();
      }
    }
    newline() {
      const p = this.vm.host.printer;
      if (p) p.printLine(RC.fromCP437(this.buf, false));
      this.buf = '';
      this.col = 1;
    }
    comma() { const next = (Math.floor((this.col - 1) / 14) + 1) * 14; if (next >= this.width - 13) this.newline(); else this.write(' '.repeat(next - this.col + 1)); }
    tab(n) { n = Math.max(1, B.toInt(n)); if (this.col > n) this.newline(); this.write(' '.repeat(Math.max(0, n - this.col))); }
    spc(n) { this.write(' '.repeat(Math.max(0, B.toInt(n)) % this.width)); }
    flush() { const p = this.vm.host.printer; if (p && p.flushPartial && this.buf) p.flushPartial(RC.fromCP437(this.buf, false)); }
  }
  B.PrinterChannel = PrinterChannel;

  // ---- line editor for INPUT / LINE INPUT on the emulated screen --------------------------------------------------
  class LineEditor {
    constructor(vm, noNewline) {
      this.vm = vm;
      this.d = vm.display;
      this.kbd = vm.kbd;
      this.noNewline = noNewline;
      this.text = '';
      this.pos = 0;
      this.startRow = this.d.cursorRow();
      this.startCol = this.d.cursorCol();
      this.d.setCursorVisible(true, true);
      this.done = false;
    }
    cancel() { this.d.setCursorVisible(false, true); }
    poll() {
      if (this.done) return this.text;
      for (let guard = 0; guard < 256; guard++) {
        const k = this.kbd ? this.kbd.get() : '';
        if (!k) return null;
        if (k === '\r') {
          this.done = true;
          this.d.setCursorVisible(false, true);
          this.moveTo(this.text.length);
          if (!this.noNewline) this.d.newline();
          return this.text;
        }
        this.handleKey(k);
      }
      return null;
    }
    handleKey(k) {
      const d = this.d;
      if (k === '\b') {
        if (this.pos > 0) {
          this.text = this.text.slice(0, this.pos - 1) + this.text.slice(this.pos);
          this.pos--;
          this.redraw(1);
        }
        return;
      }
      if (k === '\x1b') { // ESC clears the line
        const old = this.text.length;
        this.text = ''; this.pos = 0;
        this.redraw(old);
        return;
      }
      if (k.length === 2 && k[0] === '\0') {
        const sc = k.charCodeAt(1);
        if (sc === 75 && this.pos > 0) { this.pos--; this.moveTo(this.pos); }
        else if (sc === 77 && this.pos < this.text.length) { this.pos++; this.moveTo(this.pos); }
        else if (sc === 71) { this.pos = 0; this.moveTo(0); }
        else if (sc === 79) { this.pos = this.text.length; this.moveTo(this.pos); }
        else if (sc === 83 && this.pos < this.text.length) { // Del
          this.text = this.text.slice(0, this.pos) + this.text.slice(this.pos + 1);
          this.redraw(1);
        }
        return;
      }
      const c = k.charCodeAt(0);
      if (c < 32 && c !== 9) return;
      if (this.text.length >= 255) { if (this.vm.audio) this.vm.audio.beep(); return; }
      this.text = this.text.slice(0, this.pos) + k + this.text.slice(this.pos);
      this.pos++;
      this.redraw(0);
    }
    // Redraw text from the start position; `extra` trailing chars to blank
    redraw(extra) {
      const d = this.d;
      d.setCursor(this.startRow, this.startCol);
      d.printString(this.text + ' '.repeat(extra || 0), true);
      // adjust startRow if screen scrolled
      const totalLen = this.startCol + this.text.length + (extra || 0);
      const w = d.textCols();
      const endRow = this.startRow + Math.floor(totalLen / w);
      const curRow = d.cursorRow();
      const rowsDown = Math.floor(totalLen / w);
      const expectRow = this.startRow + rowsDown;
      if (d.cursorRow() < expectRow && totalLen % w !== 0) this.startRow -= expectRow - curRow;
      this.moveTo(this.pos);
      void endRow;
    }
    moveTo(p) {
      const d = this.d;
      const w = d.textCols();
      const abs = this.startCol + p;
      d.setCursor(this.startRow + Math.floor(abs / w), abs % w);
    }
  }
  B.LineEditor = LineEditor;

  // ---- RND (QBasic-compatible 24-bit LCG) -------------------------------------------------------------------------
  class Rnd {
    constructor() { this.seed = 0x50000; this.last = 0; this.next(); this.seed = 0x50000; }
    next() {
      this.seed = (this.seed * 0xFD43FD + 0xC39EC3) % 0x1000000;
      // keep exact integer arithmetic (product fits in 2^53)
      this.last = this.seed / 0x1000000;
      return this.last;
    }
    rnd(n) {
      if (n === undefined || n > 0) return Math.fround(this.next());
      if (n === 0) return Math.fround(this.last);
      // negative: reseed from the bytes of the single-precision value
      const buf = new DataView(new ArrayBuffer(4));
      buf.setFloat32(0, n, true);
      const bits = buf.getUint32(0, true);
      this.seed = (bits + (bits >>> 24)) & 0xFFFFFF;
      return Math.fround(this.next());
    }
    randomize(n) {
      const buf = new DataView(new ArrayBuffer(8));
      buf.setFloat64(0, n, true);
      const hi = buf.getUint32(4, true);
      const x = ((hi & 0xFFFF) ^ (hi >>> 16)) & 0xFFFF;
      this.seed = (this.seed & 0xFF) | (x << 8);
    }
  }
  B.Rnd = Rnd;

  // Performance: a switch whose labels are property reads (case O.ADD:) is evaluated label by label.
  // Re-create exec() once with numeric literal labels so V8 compiles a jump table (~25x faster dispatch).
  (function specializeExec() {
    const src = VM.prototype.exec.toString();
    const body = src.slice(src.indexOf('{') + 1, src.lastIndexOf('}'));
    let missing = null;
    const fixed = body.replace(/case O\.([A-Z]+):/g, (m, n) => {
      if (O[n] === undefined) missing = n;
      return 'case ' + O[n] + ' /* ' + n + ' */:';
    });
    if (missing) throw new Error('unknown opcode ' + missing);
    try {
      // eslint-disable-next-line no-new-func
      VM.prototype.exec = new Function('B', 'O', 'WAIT', 'err', 'now', 'copyRecordInto', 'BasicError', 'FK_EVENT',
        'return function exec(budget) {' + fixed + '};')(B, O, WAIT, err, now, copyRecordInto, BasicError, FK_EVENT);
    } catch (e) { /* CSP without eval: keep the generic version */ }
  })();

  B.VM = VM;
  B.FK = { NORMAL: FK_NORMAL, EVENT: FK_EVENT, ERROR: FK_ERROR };
})(RC);
