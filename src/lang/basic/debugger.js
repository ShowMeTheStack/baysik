// Debugger support: evaluate expressions / execute statements in the context of any stack
// frame, enumerate and modify variables, describe values for display.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const { O, T, CompileError, BasicError } = B;

  const VMp = B.VM.prototype;
  const origHandleError = VMp.handleError;
  VMp.handleError = function (e) {
    if (this.evalMode) {
      this.evalError = e;
      this.state = 'evalerror';
      return;
    }
    return origHandleError.call(this, e);
  };

  const Debug = B.Debug = {};

  /** Storage read/write relative to a specific frame */
  function slotRef(vm, frame, area, slot) {
    switch (area) {
      case 0: return new B.Ref(vm.G, slot);
      case 1: return new B.Ref(frame.L, slot);
      case 2: return new B.Ref(frame.proc.statics, slot);
      case 3: return frame.L[slot];
    }
    return null;
  }
  Debug.slotRef = slotRef;

  /**
   * Compile a snippet in the scope of a frame's procedure.
   * mode: 'expr' | 'stmt'
   */
  function compileSnippet(vm, text, frame, mode) {
    const prog = vm.prog;
    const c = prog.compiler;
    const proc = frame ? frame.proc : prog.main;
    const scope = proc.kind === 'module' ? prog.module : proc.scope;
    const saved = {
      scope: c.scope, curProc: c.curProc, ctl: c.ctl, labelRefs: c.labelRefs, defTable: c.defTable,
      curLineNo: c.curLineNo, inIf1: c.inIf1, noCreate: c.noCreate, stmtsLen: c.stmts.length,
    };
    const startPc = c.code.length;
    c.scope = scope;
    c.curProc = proc.kind === 'module' ? prog.main : proc;
    c.defTable = (proc.defTable || c.initialDefTable || c.defTable).slice();
    c.noCreate = proc.kind !== 'module' && proc.kind !== 'def';
    c.ctl = []; c.labelRefs = []; c.inIf1 = 0;
    let type = null;
    try {
      if (mode === 'expr') {
        const lines = B.lex(text, '<watch>', { noLineNumbers: true });
        const p = new B.Parser(lines, '<watch>');
        p.toks = lines[0].tokens; p.p = 0; p.lineInfo = lines[0];
        const e = p.parseExpr();
        if (p.tok.t !== 'eol') p.fail('Expected: end of expression');
        type = c.expr(e);
      } else {
        const stmts = B.parse(text, '<immediate>', { noLineNumbers: true });
        for (const st of stmts) {
          if (st.k === 'SUB' || st.k === 'FUNCTION' || st.k === 'DEFFN' || st.k === 'TYPE') throw new CompileError('Not allowed in immediate mode', st.pos);
          if (st.k === 'LINENO') throw new CompileError('Line numbers are not allowed here', st.pos);
          c.statement(st, false);
        }
        if (c.ctl.length) throw new CompileError('Block not closed (use a single line in immediate mode)', null);
        for (const r of c.labelRefs) {
          const pc = scope.labels.get(r.key);
          if (pc === undefined) throw new CompileError('Label not defined: ' + r.key, r.pos, 8);
          r.ins[r.field] = pc;
        }
      }
      c.emit(O.EVALEND);
    } catch (e) {
      c.code.length = startPc;
      c.stmts.length = saved.stmtsLen;
      throw e;
    } finally {
      Object.assign(c, { scope: saved.scope, curProc: saved.curProc, ctl: saved.ctl, labelRefs: saved.labelRefs, defTable: saved.defTable, curLineNo: saved.curLineNo, inIf1: saved.inIf1, noCreate: saved.noCreate });
    }
    // New module-level variables created by the snippet
    while (vm.G.length < prog.ngl) vm.G.push(vm.initValue(prog.globalTypes[vm.G.length]));
    prog.ngl = c.ngl;
    while (vm.G.length < c.ngl) vm.G.push(vm.initValue(c.globalTypes[vm.G.length]));
    return { startPc, type, stmtsLen: saved.stmtsLen };
  }
  Debug.compileSnippet = compileSnippet;

  // Prevent implicit variable creation inside procedures during debugger evaluation
  const origLookup = B.Compiler.prototype.lookupVar;
  B.Compiler.prototype.lookupVar = function (node, isArray, create, scope) {
    if (this.noCreate && create) {
      const v = origLookup.call(this, node, isArray, false, scope);
      if (v) return v;
      // allow implicit arrays? no: report clearly
      throw new CompileError(`Variable not found in this scope: ${node.display || node.name}`, node.pos);
    }
    return origLookup.call(this, node, isArray, create, scope);
  };

  /**
   * Synchronously run a compiled snippet on top of the given frame.
   * Returns {value} or throws {message}.
   */
  function runSnippet(vm, snip, frameIndex, wantValue, opts) {
    opts = opts || {};
    const prog = vm.prog;
    const saved = {
      pc: vm.pc, frames: vm.frames, frame: vm.frame, stackLen: vm.stack.length, state: vm.state, dbg: vm.dbg,
      pending: vm.pending, out: vm.out, using: vm.using, errHandler: vm.errHandler, inErr: vm.inErrHandler,
      recordHistory: vm.recordHistory, inputVals: vm.inputVals, evPending: vm.evPending,
    };
    const fi = frameIndex === undefined ? vm.frames.length - 1 : frameIndex;
    const target = vm.frames[fi];
    const ef = new B.Frame(target.proc, target.L, -1, 3, false);
    ef.gosub = []; ef.fors = target.fors; ef.stmt = target.stmt;
    vm.frames = vm.frames.slice(0, fi + 1).concat([ef]);
    vm.frame = ef;
    vm.pc = snip.startPc;
    vm.state = 'running';
    vm.dbg = false;
    vm.evalMode = true;
    vm.evalError = null;
    vm.errHandler = -1;
    vm.inErrHandler = null;
    vm.pending = null;
    let result;
    try {
      const deadline = Date.now() + (opts.timeout || 1500);
      while (vm.state === 'running') {
        vm.exec(20);
        if (Date.now() > deadline && vm.state === 'running') { vm.evalError = new Error('Evaluation took too long (infinite loop?)'); break; }
      }
      if (vm.state === 'waiting') vm.evalError = new Error('Input is not available while the program is paused');
      if (!vm.evalError && vm.state !== 'evaldone' && vm.state !== 'ended') vm.evalError = new Error('Evaluation stopped (' + vm.state + ')');
      if (!vm.evalError && wantValue) result = vm.stack.pop();
    } finally {
      vm.evalMode = false;
      const ended = vm.state === 'ended';
      Object.assign(vm, {
        pc: saved.pc, frames: saved.frames, frame: saved.frame, state: saved.state, dbg: saved.dbg, pending: saved.pending,
        out: saved.out, using: saved.using, errHandler: saved.errHandler, inErrHandler: saved.inErr, recordHistory: saved.recordHistory,
        inputVals: saved.inputVals, evPending: saved.evPending,
      });
      vm.stack.length = saved.stackLen;
      prog.code.length = snip.startPc;
      prog.stmts.length = snip.stmtsLen;
      if (ended && opts.allowEnd) vm.state = 'ended';
    }
    if (vm.evalError) {
      const e = vm.evalError;
      vm.evalError = null;
      throw e;
    }
    return result;
  }

  /** Evaluate an expression in frame `fi`. Returns {value, type}. */
  Debug.evaluate = function (vm, text, fi) {
    const frame = vm.frames[fi === undefined ? vm.frames.length - 1 : fi];
    const snip = compileSnippet(vm, text, frame, 'expr');
    const value = runSnippet(vm, snip, fi, true);
    return { value, type: snip.type };
  };
  /** Execute statements (immediate window) in frame `fi`. */
  Debug.execute = function (vm, text, fi) {
    const frame = vm.frames[fi === undefined ? vm.frames.length - 1 : fi];
    const snip = compileSnippet(vm, text, frame, 'stmt');
    runSnippet(vm, snip, fi, false, { allowEnd: false });
  };
  /** Build a fast predicate for conditional breakpoints / watchpoints (evaluated in the current frame). */
  Debug.makeCondition = function (text) {
    return (vm) => {
      const r = Debug.evaluateCached(vm, text);
      return typeof r.value === 'number' ? r.value !== 0 : r.value;
    };
  };
  /**
   * Evaluate in the current (top) frame, reusing compiled code between calls. Used for
   * conditional breakpoints and watchpoints, which run on every statement.
   */
  Debug.evaluateCached = function (vm, text) {
    const prog = vm.prog;
    const frame = vm.frame;
    const cache = vm._evalCache || (vm._evalCache = new Map());
    const key = text + '\u0000' + (frame.proc.index === undefined ? -1 : frame.proc.index);
    let c = cache.get(key);
    if (c && c.error) throw c.error;
    if (!c || c.startPc !== prog.code.length) {
      let snip;
      try { snip = compileSnippet(vm, text, frame, 'expr'); } catch (e) { cache.set(key, { error: e }); throw e; }
      c = { startPc: snip.startPc, stmtsLen: snip.stmtsLen, ins: prog.code.slice(snip.startPc), stmts: prog.stmts.slice(snip.stmtsLen), type: snip.type };
      cache.set(key, c);
    } else {
      for (const i of c.ins) prog.code.push(i);
      for (const s of c.stmts) prog.stmts.push(s);
    }
    const value = runSnippet(vm, { startPc: c.startPc, stmtsLen: c.stmtsLen }, undefined, true);
    return { value, type: c.type };
  };

  // ---- variables view ------------------------------------------------------------------------
  function typeName(t) {
    if (!t) return '';
    if (t.code === 7) return typeName(t.elem) + '()';
    return t.name || t.k;
  }
  Debug.typeName = typeName;

  /** Short display text for a value of a given type */
  function fmtValue(v, t) {
    if (v === null || v === undefined) return t && t.code === 7 ? '(not dimensioned)' : '?';
    if (v instanceof B.BArray) return '(' + v.dims.map((d) => d.lo + ' TO ' + d.hi).join(', ') + ')' + (v.erased ? ' erased' : '');
    if (typeof v === 'string') return '"' + RC.fromCP437(v, false).replace(/\u0000/g, '·') + '"';
    if (typeof v === 'number') return B.fmtNum(v, t && t.code <= 4 ? t.code : B.numCode(v));
    if (typeof v === 'object' && v.__def) return '{' + v.__def.fields.map((f) => f.display + ': ' + fmtValue(v[f.name], f.type)).join(', ') + '}';
    return String(v);
  }
  Debug.fmtValue = fmtValue;

  function symEntry(vm, frame, s) {
    const ref = slotRef(vm, frame, s.area, s.slot);
    let value = ref ? ref.c[ref.k] : undefined;
    const isArray = !!s.isArray;
    return {
      name: s.display || s.key,
      type: isArray ? typeName({ code: 7, elem: s.type }) : typeName(s.type),
      vtype: s.type,
      isArray,
      param: !!s.param,
      isRet: !!s.isRet,
      ref,
      value,
      text: fmtValue(value, isArray ? { code: 7 } : s.type),
      expandable: isArray ? !!value : (s.type && s.type.code === 6),
    };
  }

  /**
   * Variables visible from frame fi: {locals: [...], statics: [...], globals: [...]}
   */
  Debug.variables = function (vm, fi) {
    const frame = vm.frames[fi === undefined ? vm.frames.length - 1 : fi];
    const prog = vm.prog;
    const out = { scopeName: '', locals: [], globals: [] };
    const proc = frame.proc;
    if (proc.kind !== 'module' && frame.kind === 0) {
      out.scopeName = (proc.kind === 'def' ? 'DEF ' : proc.kind === 'sub' ? 'SUB ' : 'FUNCTION ') + (proc.display || proc.name);
      for (const s of proc.symbols || []) out.locals.push(symEntry(vm, frame, s));
    }
    const seen = new Set();
    for (const s of prog.globalSyms) {
      if (seen.has(s)) continue;
      seen.add(s);
      if (s.key && s.key.startsWith('~')) continue;
      out.globals.push(symEntry(vm, frame, s));
    }
    out.globals.sort((a, b) => a.name.localeCompare(b.name));
    return out;
  };

  /** Children of an expandable entry (array elements page / record fields) */
  Debug.children = function (entry, start, count) {
    const v = entry.value;
    const out = [];
    if (v instanceof B.BArray) {
      start = start || 0; count = count || 100;
      const n = v.length;
      for (let i = start; i < Math.min(n, start + count); i++) {
        // flat index -> subscripts (column-major)
        const subs = [];
        let r = i;
        for (let d = 0; d < v.dims.length; d++) {
          const ext = v.dims[d].hi - v.dims[d].lo + 1;
          subs.push(v.dims[d].lo + (r % ext));
          r = Math.floor(r / ext);
        }
        const ref = new B.Ref(v.data, i);
        const val = v.data[i];
        out.push({ name: '(' + subs.join(', ') + ')', type: typeName(v.type), vtype: v.type, ref, value: val, text: fmtValue(val, v.type), expandable: v.type.code === 6 });
      }
      return { items: out, total: n };
    }
    if (v && typeof v === 'object' && v.__def) {
      for (const f of v.__def.fields) {
        const ref = new B.Ref(v, f.name);
        out.push({ name: '.' + (f.display || f.name), type: typeName(f.type), vtype: f.type, ref, value: v[f.name], text: fmtValue(v[f.name], f.type), expandable: f.type.code === 6 });
      }
      return { items: out, total: out.length };
    }
    return { items: [], total: 0 };
  };

  /**
   * Assign a new value (given as BASIC expression text) to a storage ref of type t.
   * String variables accept plain text if it isn't a valid expression.
   */
  Debug.assign = function (vm, entry, text, fi) {
    const t = entry.vtype;
    if (!t || t.code === 7 || t.code === 6) throw new Error('Edit individual elements/fields instead');
    let value;
    try {
      const r = Debug.evaluate(vm, text, fi);
      value = r.value;
      if (B.isStr(t) && typeof value !== 'string') throw new Error('Type mismatch');
      if (B.isNum(t) && typeof value !== 'number') throw new Error('Type mismatch');
    } catch (e) {
      if (B.isStr(t)) value = RC.toCP437(text.replace(/^"(.*)"$/, '$1'));
      else throw e;
    }
    try { vm.storeTo(entry.ref.c, entry.ref.k, t, value); } catch (e) {
      if (e instanceof BasicError) throw new Error(e.message);
      throw e;
    }
    return entry.ref.c[entry.ref.k];
  };

  /** Find the statement index for a source line (first statement on that line). */
  Debug.stmtAtLine = function (prog, file, line) {
    let best = -1;
    for (let i = 0; i < prog.stmts.length; i++) {
      const s = prog.stmts[i];
      if (!s.pos || s.noStep) continue;
      if ((s.pos.file || '') === (file || '') && s.pos.line === line) { best = i; break; }
    }
    return best;
  };
  /** Next executable line at or after `line` (for placing breakpoints on blank lines) */
  Debug.nearestStmt = function (prog, file, line) {
    let best = -1, bestLine = Infinity;
    for (let i = 0; i < prog.stmts.length; i++) {
      const s = prog.stmts[i];
      if (!s.pos || s.noStep || (s.pos.file || '') !== (file || '')) continue;
      if (s.pos.line >= line && s.pos.line < bestLine) { best = i; bestLine = s.pos.line; }
    }
    return best;
  };

  /** Move execution to the statement at `line` within the current procedure ("Set Next Statement"). */
  Debug.setNextStatement = function (vm, file, line) {
    const idx = Debug.stmtAtLine(vm.prog, file, line);
    if (idx < 0) throw new Error('No statement on that line');
    const st = vm.prog.stmts[idx];
    if (st.proc !== vm.frame.proc) throw new Error('Can only move within the current ' + (vm.frame.proc.kind === 'module' ? 'module' : 'procedure'));
    vm.pc = st.pc;
    vm.frame.stmt = idx;
    vm.stack.length = vm.frame.sp;
    vm.skipBreak = true;
    return idx;
  };
})(RC);
