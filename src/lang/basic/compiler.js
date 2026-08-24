// BASIC compiler: flat statement list -> bytecode for the VM (runtime.js).
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const { T, CompileError } = B;

  // ---- opcodes --------------------------------------------------------------------
  const OPS = [
    'NOP', 'CONST', 'POP', 'DUP',
    'LD', 'ST', 'REF', 'ARRLD', 'ARRST', 'ARRREF', 'ARROBJ',
    'FLD', 'FLDST', 'FLDREF', 'DEREF', 'STREF', 'MKREF',
    'ADD', 'SUB', 'MUL', 'DIV', 'IDIV', 'MOD', 'POW', 'NEG', 'CAT',
    'EQ', 'NE', 'LT', 'GT', 'LE', 'GE',
    'AND', 'OR', 'XOR', 'EQV', 'IMP', 'NOT', 'CVT',
    'JMP', 'JF', 'JT', 'STMT', 'GOSUB', 'RETURN', 'ONGO',
    'FOR', 'NEXT', 'EXITFOR',
    'CALL', 'RET', 'CALLB', 'SYS', 'END', 'STOP',
    'PRCH', 'PRVAL', 'PRCOMMA', 'PRTAB', 'PRSPC', 'PREND', 'PRUSING', 'PRUVAL',
    'WRITE', 'INPUT', 'INPUTVAL', 'LINEINPUT', 'FINPUT', 'FLINEINPUT', 'READ', 'RESTORE',
    'DIM', 'ERASE', 'SWAP', 'MIDSET', 'LRSET',
    'ONERROR', 'RESUME', 'ERROR', 'ONEVENT', 'EVENTCTL',
    'OPEN', 'CLOSE', 'FIELD', 'FGET', 'FPUT',
    'GPOINT', 'GLINE', 'GCIRCLE', 'GPAINT', 'GGET', 'GPUT', 'PALUSING',
    'CHAIN', 'RUN', 'CMD', 'CLEAR', 'DEFFN', 'EVALEND',
  ];
  const O = {};
  OPS.forEach((n, i) => { O[n] = i; });
  B.O = O;
  B.OPNAMES = OPS;

  // Storage areas
  const A_G = 0, A_L = 1, A_S = 2, A_P = 3;
  B.AREAS = { G: A_G, L: A_L, S: A_S, P: A_P };

  class Scope {
    constructor(kind, name, parent) {
      this.kind = kind; // 'module' | 'sub' | 'function' | 'def'
      this.name = name;
      this.parent = parent; // module scope for procs
      this.vars = new Map(); // key -> VarInfo (scalars)
      this.arrays = new Map(); // key -> VarInfo (arrays)
      this.asVars = new Map(); // BASE -> VarInfo (declared AS)
      this.asArrays = new Map();
      this.consts = new Map(); // key or BASE -> {value, type}
      this.shared = new Set(); // keys of module vars visible in this proc (SHARED stmt)
      this.sharedArrays = new Set();
      this.labels = new Map();
      this.isStatic = false;
      this.nslots = 0; // locals
      this.slotTypes = [];
      this.symbols = []; // VarInfo list for debugger
      this.staticVars = new Set();
    }
  }

  class Compiler {
    constructor(opts) {
      this.opts = opts || {};
      this.code = [];
      this.stmts = []; // statement table
      this.procs = []; // ProcInfo list
      this.procByBase = new Map(); // BASE -> ProcInfo (SUB/FUNCTION)
      this.fnByName = new Map(); // DEF FN name key -> ProcInfo
      this.types = new Map(); // user TYPE name -> def
      this.data = []; // DATA items
      this.labelData = new Map(); // 'scope:label' -> data index
      this.globalTypes = []; // slot types for globals
      this.globalSyms = [];
      this.ngl = 0;
      this.module = new Scope('module', '', null);
      this.sharedGlobals = new Map(); // key -> VarInfo  (DIM SHARED / COMMON SHARED)
      this.sharedGlobalArrays = new Map();
      this.sharedAs = new Map(); this.sharedAsArrays = new Map();
      this.commons = [];
      this.defTable = new Array(26).fill(T.SINGLE);
      this.optionBase = 0;
      this.dynamicDefault = false;
      this.fixups = [];
    }

    error(msg, pos, code) { throw new CompileError(msg, pos, code); }

    // ---- entry ---------------------------------------------------------------------
    /**
     * @param files Array<{name, stmts}> where stmts from B.parse; first is the main module
     */
    compile(stmts) {
      // Pass 1: TYPEs, procedure headers, DATA, label data positions, DEFtype snapshots
      this.prepass(stmts);
      // Pass 2: partition into module code + procedure bodies
      const main = [];
      const bodies = new Map();
      let cur = null;
      for (const st of stmts) {
        if (st.k === 'SUB' || st.k === 'FUNCTION') {
          if (cur) this.error(`${st.k} not allowed inside ${cur.kind === 'function' ? 'FUNCTION' : 'SUB'}`, st.pos);
          cur = st.proc;
          bodies.set(cur, []);
          continue;
        }
        if (st.k === 'ENDSUB' || st.k === 'ENDFUNCTION') {
          if (!cur) this.error(`END ${st.k.slice(3)} without ${st.k.slice(3)}`, st.pos);
          if ((st.k === 'ENDSUB') !== (cur.kind === 'sub')) this.error('Expected: END ' + (cur.kind === 'sub' ? 'SUB' : 'FUNCTION'), st.pos);
          bodies.get(cur).endPos = st.pos;
          cur = null;
          continue;
        }
        if (st.k === 'DEFFN' && !st.single) {
          if (cur && cur.kind === 'def') this.error('DEF FN not allowed here', st.pos);
          const outer = cur;
          cur = st.proc; cur.outerProc = outer;
          bodies.set(cur, []);
          continue;
        }
        if (st.k === 'ENDDEF') {
          if (!cur || cur.kind !== 'def') this.error('END DEF without DEF', st.pos);
          bodies.get(cur).endPos = st.pos;
          cur = cur.outerProc || null;
          continue;
        }
        if (cur) bodies.get(cur).push(st); else main.push(st);
      }
      if (cur) this.error(`${cur.kind === 'def' ? 'DEF' : cur.kind === 'sub' ? 'SUB' : 'FUNCTION'} without END ${cur.kind === 'def' ? 'DEF' : cur.kind.toUpperCase()}`, cur.pos);

      // Module code
      this.mainProc = { kind: 'module', name: '(module)', display: 'Main', scope: this.module, entry: 0, params: [], pos: null };
      this.scope = this.module;
      this.curProc = this.mainProc;
      this.defTable = this.initialDefTable.slice();
      this.optionBase = 0;
      this.compileBody(main);
      this.emit(O.END, 0);
      // Procedures
      for (const proc of this.procs) {
        const body = bodies.get(proc) || [];
        if (proc.kind === 'def' && proc.single) continue;
        this.compileProc(proc, body);
      }
      for (const proc of this.procs) {
        if (proc.kind === 'def' && proc.single) this.compileSingleDef(proc);
        if (proc.kind !== 'def' && !bodies.has(proc) && proc.declaredOnly) {
          // DECLAREd but never defined: calls fail at compile time (handled in call)
        }
      }
      this.resolveFixups();
      return {
        code: this.code,
        stmts: this.stmts,
        procs: this.procs,
        main: this.mainProc,
        data: this.data,
        labelData: this.labelData,
        globalTypes: this.globalTypes,
        globalSyms: this.globalSyms,
        ngl: this.ngl,
        module: this.module,
        types: this.types,
        commons: this.commons,
        compiler: this,
      };
    }

    // ---- pass 1 ----------------------------------------------------------------------
    prepass(stmts) {
      const defTable = this.defTable.slice();
      this.initialDefTable = this.defTable.slice();
      let curProcName = '';
      let lastLine = null;
      const walk = (list, inProc) => {
        for (const st of list) {
          switch (st.k) {
            case 'TYPE': this.defineType(st); break;
            case 'DEFTYPE':
              for (const [a, b] of st.ranges) for (let c = a.charCodeAt(0); c <= b.charCodeAt(0); c++) defTable[c - 65] = B.typeByK(st.ty);
              break;
            case 'SUB': case 'FUNCTION': {
              if (this.procByBase.has(st.base) && !this.procByBase.get(st.base).declaredOnly) this.error('Duplicate definition', st.pos, 10);
              const proc = this.makeProc(st, defTable);
              st.proc = proc;
              curProcName = st.base;
              break;
            }
            case 'ENDSUB': case 'ENDFUNCTION': curProcName = ''; break;
            case 'DEFFN': {
              const proc = this.makeDefFn(st, defTable);
              st.proc = proc;
              break;
            }
            case 'DECLARE': {
              if (!this.procByBase.has(st.name.replace(/[%&!#$]$/, ''))) {
                // Remember signature; will be replaced by actual definition
              }
              break;
            }
            case 'DATA':
              st.dataIndex = this.data.length;
              for (const it of st.items) this.data.push({ v: it.v, quoted: it.quoted, stmt: st });
              break;
            case 'LINENO': case 'LABEL': {
              const key = (curProcName || '') + ':' + st.v;
              if (!this.labelData.has(key)) this.labelData.set(key, this.data.length);
              if (!this.labelData.has('*:' + st.v)) this.labelData.set('*:' + st.v, this.data.length);
              lastLine = st.v;
              break;
            }
            case 'IF1':
              walk(st.then, inProc);
              if (st.else) walk(st.else, inProc);
              break;
            case 'REM':
              if (st.meta && st.meta.cmd === 'DYNAMIC') this.dynamicDefault = true;
              break;
          }
        }
      };
      walk(stmts, false);
    }

    defineType(st) {
      if (this.types.has(st.name)) this.error('Duplicate definition', st.pos, 10);
      const def = { name: st.name, display: st.display, fields: [], size: 0 };
      const seen = new Set();
      for (const f of st.fields) {
        if (seen.has(f.name)) this.error('Duplicate definition', f.pos, 10);
        seen.add(f.name);
        const ty = this.resolveTypeSpec(f.type, f.pos);
        if (ty.k === 'string') this.error('Fixed-length string required in TYPE (use STRING * n)', f.pos);
        def.fields.push({ name: f.name.replace(/[%&!#$]$/, ''), display: f.display, type: ty, offset: def.size });
        def.size += ty.size;
      }
      this.types.set(st.name, def);
      B.recordType(def);
    }

    resolveTypeSpec(spec, pos) {
      if (!spec) return null;
      if (spec.k === 'fixstr') {
        let len = spec.len;
        if (spec.constName) {
          const c = this.module.consts.get(spec.constName) || this.module.consts.get(spec.constName.replace(/[%&!#$]$/, ''));
          if (!c) this.error('Expected: constant', pos);
          len = c.value;
        }
        if (!(len >= 1 && len <= 32767)) this.error('Illegal number', pos);
        return B.fixStr(Math.floor(len));
      }
      if (spec.k === 'user') {
        const def = this.types.get(spec.name);
        if (!def) this.error(`Type not defined: ${spec.name}`, pos);
        return B.recordType(def);
      }
      if (spec.k === 'any') return { k: 'any', code: 0, size: 0 };
      return B.typeByK(spec.k);
    }

    typeOfName(base, sfx, defTable) {
      if (sfx) return B.typeBySfx(sfx);
      const c = base.charCodeAt(0) - 65;
      return (defTable || this.defTable)[c >= 0 && c < 26 ? c : 18] || T.SINGLE;
    }

    makeProc(st, defTable) {
      const kind = st.k === 'SUB' ? 'sub' : 'function';
      const proc = {
        kind, name: st.name, base: st.base, display: st.display, pos: st.pos, isStatic: st.isStatic,
        params: [], defTable: defTable.slice(), entry: -1, index: this.procs.length,
      };
      if (kind === 'function') proc.retType = this.typeOfName(st.base, st.sfx, defTable);
      for (const p of st.params) {
        let ty = p.type ? this.resolveTypeSpec(p.type, p.pos) : this.typeOfName(p.base, p.sfx, defTable);
        if (p.type && p.sfx && !B.sameType(ty, B.typeBySfx(p.sfx))) this.error('Duplicate definition', p.pos, 10);
        proc.params.push({ name: p.name, base: p.base, sfx: p.sfx, display: p.display, type: ty, isArray: p.isArray, asDecl: !!p.type, byval: p.byval, pos: p.pos });
      }
      this.procs.push(proc);
      this.procByBase.set(st.base, proc);
      return proc;
    }

    makeDefFn(st, defTable) {
      const key = st.base + (st.sfx || '');
      const retType = this.typeOfName(st.base, st.sfx, defTable);
      const proc = {
        kind: 'def', name: st.name, base: st.base, display: st.display, pos: st.pos, single: st.single, expr: st.e,
        params: [], defTable: defTable.slice(), entry: -1, index: this.procs.length, retType,
      };
      for (const p of st.params) {
        const ty = p.type ? this.resolveTypeSpec(p.type, p.pos) : this.typeOfName(p.base, p.sfx, defTable);
        proc.params.push({ name: p.name, base: p.base, sfx: p.sfx, display: p.display, type: ty, isArray: false, asDecl: !!p.type, pos: p.pos });
      }
      this.procs.push(proc);
      this.fnByName.set(this.fnKey(st.base, st.sfx, defTable), proc);
      return proc;
    }
    fnKey(base, sfx, defTable) {
      return base + this.typeOfName(base, sfx, defTable).sfx;
    }

    // ---- emission helpers ----------------------------------------------------------------
    emit(op, a, b, c, d, e) {
      const ins = { op, a, b, c, d, e };
      this.code.push(ins);
      return ins;
    }
    get pc() { return this.code.length; }

    // ---- variables -------------------------------------------------------------------------
    allocSlot(scope, type, sym) {
      if (scope.kind === 'module') {
        const slot = this.ngl++;
        this.globalTypes[slot] = type;
        if (sym) this.globalSyms.push(sym);
        return { area: A_G, slot };
      }
      if (scope.isStatic || (sym && scope.staticVars.has(sym.key))) {
        const proc = scope.proc;
        const slot = proc.nstatic++;
        proc.staticTypes[slot] = type;
        if (sym) scope.symbols.push(sym);
        return { area: A_S, slot };
      }
      const slot = scope.nslots++;
      scope.slotTypes[slot] = type;
      if (sym) scope.symbols.push(sym);
      return { area: A_L, slot };
    }

    newVar(scope, key, base, type, isArray, display, asDecl) {
      const info = { key, base, type, isArray, display: display || key, asDecl: !!asDecl, area: 0, slot: 0, scope: scope.kind };
      const loc = this.allocSlot(scope, isArray ? { k: 'array', code: 7, elem: type } : type, info);
      info.area = loc.area; info.slot = loc.slot;
      if (isArray) {
        scope.arrays.set(key, info);
        if (asDecl) scope.asArrays.set(base, info);
      } else {
        scope.vars.set(key, info);
        if (asDecl) scope.asVars.set(base, info);
      }
      return info;
    }

    /**
     * Find (or implicitly create) a variable.
     * @param node {name, base, sfx}
     * @param isArray
     * @param create allow implicit creation
     */
    lookupVar(node, isArray, create, scope) {
      scope = scope || this.scope;
      const base = node.base, sfx = node.sfx;
      const module = this.module;
      const asMap = isArray ? 'asArrays' : 'asVars';
      const map = isArray ? 'arrays' : 'vars';
      const tryScope = (sc, sharedOnly) => {
        // Declared AS?
        const asv = sc[asMap].get(base);
        if (asv) {
          if (sfx && !B.sameType(asv.type, B.typeBySfx(sfx))) this.error('Duplicate definition', node.pos, 10);
          return asv;
        }
        return null;
      };
      // 1. local scope
      let v = tryScope(scope);
      if (v) return v;
      const defTable = this.defTable;
      const key = base + this.typeOfName(base, sfx, defTable).sfx;
      v = scope[map].get(key);
      if (v) return v;
      if (scope.kind !== 'module') {
        // DEF FN: everything not a param is module-level
        if (scope.kind === 'def') {
          return this.lookupVar(node, isArray, create, module);
        }
        // SHARED statement within this proc
        if ((isArray ? scope.sharedArrays : scope.shared).has(key) || (isArray ? scope.sharedArrays : scope.shared).has(base + '@')) {
          return this.lookupVar(node, isArray, true, module);
        }
        // DIM SHARED / COMMON SHARED at module level
        const sasv = (isArray ? this.sharedAsArrays : this.sharedAs).get(base);
        if (sasv) {
          if (sfx && !B.sameType(sasv.type, B.typeBySfx(sfx))) this.error('Duplicate definition', node.pos, 10);
          return sasv;
        }
        const sg = (isArray ? this.sharedGlobalArrays : this.sharedGlobals).get(key);
        if (sg) return sg;
      }
      if (!create) return null;
      const type = this.typeOfName(base, sfx, defTable);
      return this.newVar(scope, key, base, type, isArray, (node.display || node.name), false);
    }

    constClash(base) {
      for (const sc of [this.scope, this.module]) {
        if (!sc) continue;
        for (const k of sc.consts.keys()) if (k.replace(/[%&!#$*]$/, '') === base) return true;
      }
      return false;
    }
    lookupConst(node) {
      const find = (sc) => {
        if (!sc) return null;
        let c = sc.consts.get(node.base + (node.sfx || ''));
        if (!c && !node.sfx) c = sc.consts.get(node.base + '*');
        if (!c && node.sfx) {
          const c2 = sc.consts.get(node.base + '*');
          if (c2 && c2.type.sfx === node.sfx) c = c2;
        }
        return c;
      };
      return find(this.scope) || (this.scope !== this.module ? find(this.module) : null);
    }

    // ---- body compilation ------------------------------------------------------------------
    compileProc(proc, body) {
      const scope = new Scope(proc.kind, proc.name, this.module);
      scope.proc = proc;
      scope.isStatic = !!proc.isStatic;
      proc.scope = scope;
      proc.nstatic = 0;
      proc.staticTypes = [];
      this.scope = scope;
      this.curProc = proc;
      this.defTable = proc.defTable.slice();
      // Return value slot
      if (proc.kind === 'function' || proc.kind === 'def') {
        const loc = { area: A_L, slot: scope.nslots++ };
        scope.slotTypes[loc.slot] = proc.retType;
        proc.retSlot = loc.slot;
        scope.symbols.push({ key: '=' + proc.name, display: (proc.display || proc.name) + ' (result)', type: proc.retType, area: A_L, slot: loc.slot, isRet: true });
      }
      // Parameters
      proc.paramSlots = [];
      for (const p of proc.params) {
        if (this.constClash(p.base)) this.error('Duplicate definition (a CONST has this name)', p.pos, 10);
        const slot = scope.nslots++;
        const isRef = proc.kind !== 'def';
        scope.slotTypes[slot] = isRef ? { k: 'ref', code: 8 } : p.type;
        const key = p.isArray ? p.base + (p.asDecl ? '@' : p.type.sfx) : p.base + (p.asDecl ? '@' : p.type.sfx);
        const info = { key, base: p.base, type: p.type, isArray: p.isArray, display: p.display, asDecl: p.asDecl, area: isRef ? A_P : A_L, slot, param: true };
        if (p.isArray) { scope.arrays.set(p.base + p.type.sfx, info); if (p.asDecl) scope.asArrays.set(p.base, info); }
        else { scope.vars.set(p.base + (p.type.sfx || '@'), info); if (p.asDecl) scope.asVars.set(p.base, info); }
        scope.symbols.push(info);
        proc.paramSlots.push(slot);
      }
      proc.entry = this.pc;
      this.compileBody(body);
      // Implicit return at end
      const endStmt = this.addStmt({ k: 'END' + proc.kind.toUpperCase(), pos: body.endPos || proc.pos }, false);
      this.emit(O.STMT, endStmt);
      this.stmts[endStmt].pc = this.pc - 1;
      this.emit(O.RET);
      this.stmts[endStmt].endPc = this.pc;
      proc.nlocals = scope.nslots;
      proc.localTypes = scope.slotTypes;
      proc.symbols = scope.symbols;
    }

    compileSingleDef(proc) {
      const scope = new Scope('def', proc.name, this.module);
      scope.proc = proc;
      proc.scope = scope;
      proc.nstatic = 0; proc.staticTypes = [];
      this.scope = scope;
      this.curProc = proc;
      this.defTable = proc.defTable.slice();
      proc.retSlot = scope.nslots++;
      scope.slotTypes[proc.retSlot] = proc.retType;
      proc.paramSlots = [];
      for (const p of proc.params) {
        const slot = scope.nslots++;
        scope.slotTypes[slot] = p.type;
        const info = { key: p.base + p.type.sfx, base: p.base, type: p.type, isArray: false, display: p.display, area: A_L, slot, param: true };
        scope.vars.set(info.key, info);
        if (p.asDecl) scope.asVars.set(p.base, info);
        scope.symbols.push(info);
        proc.paramSlots.push(slot);
      }
      proc.entry = this.pc;
      const t = this.expr(proc.expr);
      this.coerce(t, proc.retType, proc.expr.pos);
      this.emit(O.ST, A_L, proc.retSlot, proc.retType);
      this.emit(O.RET);
      proc.nlocals = scope.nslots;
      proc.localTypes = scope.slotTypes;
      proc.symbols = scope.symbols;
    }

    addStmt(st, step) {
      const idx = this.stmts.length;
      this.stmts.push({
        pos: st.pos || null, kind: st.k, lineNo: this.curLineNo, proc: this.curProc, pc: this.pc, endPc: this.pc, noStep: !!st.noStep,
        lineStart: !!this.atLineStart,
      });
      this.atLineStart = false;
      return idx;
    }

    compileBody(list) {
      this.ctl = [];
      this.selectTemps = 0;
      this.curLineNo = null;
      this.labelRefs = [];
      const scope = this.scope;
      for (const st of list) this.statement(st, false);
      // GW-BASIC leniency: a FOR whose only NEXT sits inside a single-line IF
      while (this.ctl.length) {
        const c = this.ctl[this.ctl.length - 1];
        if (c.kind !== 'for' || !c.innerExit) break;
        this.ctl.pop();
        c.ins.d = c.innerExit;
        for (const e of c.exitFix) e.a = c.innerExit;
      }
      // Unclosed blocks
      if (this.ctl.length) {
        const c = this.ctl[this.ctl.length - 1];
        const msgs = { if: 'Block IF without END IF', do: 'DO without LOOP', for: 'FOR without NEXT', while: 'WHILE without WEND', select: 'SELECT without END SELECT' };
        this.error(msgs[c.kind] || 'Unterminated block', c.pos, c.kind === 'for' ? 26 : c.kind === 'while' ? 29 : 2);
      }
      // Resolve label references for this scope
      for (const r of this.labelRefs) {
        const pc = scope.labels.get(r.key);
        if (pc === undefined) this.error(`Label not defined: ${r.key}`, r.pos, 8);
        r.ins[r.field] = pc;
      }
    }

    labelRef(target, ins, field) {
      const key = target.lineNo !== undefined ? String(target.lineNo) : target.label;
      this.labelRefs.push({ key, ins, field, pos: target.pos });
    }
    labelArrRef(target, arr, idx, ins) {
      const key = target.lineNo !== undefined ? String(target.lineNo) : target.label;
      this.labelRefs.push({ key, ins: arr, field: idx, pos: target.pos });
    }

    resolveFixups() { /* label fixups are resolved per body */ }

    // ---- statements ---------------------------------------------------------------------------
    statement(st, nested) {
      switch (st.k) {
        case 'LINENO': case 'LABEL': {
          const key = String(st.v);
          if (this.scope.labels.has(key)) this.error('Duplicate label', st.pos, 33);
          this.scope.labels.set(key, this.pc);
          if (st.k === 'LINENO') { this.curLineNo = st.v; this.atLineStart = true; }
          return;
        }
        case 'REM':
          if (st.meta) {
            if (st.meta.cmd === 'DYNAMIC') this.dynamicMode = true;
            if (st.meta.cmd === 'STATIC') this.dynamicMode = false;
          }
          return;
        case 'TYPE': case 'DECLARE': case 'NOP': return;
        case 'DEFTYPE':
          for (const [a, b] of st.ranges) for (let c = a.charCodeAt(0); c <= b.charCodeAt(0); c++) this.defTable[c - 65] = B.typeByK(st.ty);
          return;
        case 'DEFFN': return; // bodies compiled separately
        case 'CONST': this.stConst(st); return;
      }
      const idx = this.addStmt(st);
      this.emit(O.STMT, idx);
      const handler = this['s_' + st.k];
      if (!handler) this.error(`Unsupported statement ${st.k}`, st.pos);
      handler.call(this, st, idx);
      this.stmts[idx].endPc = this.pc;
    }

    // Control stack helpers
    pushCtl(c) { this.ctl.push(c); return c; }
    topCtl(kind) {
      for (let i = this.ctl.length - 1; i >= 0; i--) if (this.ctl[i].kind === kind) return this.ctl[i];
      return null;
    }

    s_LET(st) { this.store(st.target, () => this.expr(st.e), st.e.pos); }

    s_IF1(st) {
      const t = this.expr(st.cond);
      this.condCheck(t, st.cond.pos);
      const jf = this.emit(O.JF, 0);
      this.inIf1 = (this.inIf1 || 0) + 1;
      for (const s of st.then) this.statement(s, true);
      if (st.else) {
        const jend = this.emit(O.JMP, 0);
        jf.a = this.pc;
        for (const s of st.else) this.statement(s, true);
        jend.a = this.pc;
      } else jf.a = this.pc;
      this.inIf1--;
    }
    condCheck(t, pos) { if (!B.isNum(t)) this.error('Type mismatch', pos, 13); }

    s_IFBLOCK(st) {
      const t = this.expr(st.cond);
      this.condCheck(t, st.cond.pos);
      const jf = this.emit(O.JF, 0);
      this.pushCtl({ kind: 'if', jf, ends: [], pos: st.pos, hasElse: false });
    }
    s_ELSEIF(st) {
      const c = this.ctl[this.ctl.length - 1];
      if (!c || c.kind !== 'if') this.error('ELSEIF without IF', st.pos);
      if (c.hasElse) this.error('ELSEIF after ELSE', st.pos);
      c.ends.push(this.emit(O.JMP, 0));
      c.jf.a = this.pc;
      const t = this.expr(st.cond);
      this.condCheck(t, st.cond.pos);
      c.jf = this.emit(O.JF, 0);
    }
    s_ELSE(st) {
      const c = this.ctl[this.ctl.length - 1];
      if (!c || c.kind !== 'if') this.error('ELSE without IF', st.pos);
      if (c.hasElse) this.error('ELSE without IF', st.pos);
      c.hasElse = true;
      c.ends.push(this.emit(O.JMP, 0));
      c.jf.a = this.pc;
      c.jf = null;
    }
    s_ENDIF(st) {
      const c = this.ctl[this.ctl.length - 1];
      if (!c || c.kind !== 'if') this.error('END IF without block IF', st.pos);
      this.ctl.pop();
      if (c.jf) c.jf.a = this.pc;
      for (const j of c.ends) j.a = this.pc;
    }

    s_SELECT(st) {
      const t = this.expr(st.e);
      const tmp = this.tempSlot(B.isStr(t) ? T.STRING : t);
      this.emit(O.ST, tmp.area, tmp.slot, B.isStr(t) ? T.STRING : t);
      this.pushCtl({ kind: 'select', tmp, type: B.isStr(t) ? T.STRING : t, next: null, ends: [], pos: st.pos, cases: 0, hasElse: false });
    }
    tempSlot(type) {
      const n = '~t' + (this.tempCounter = (this.tempCounter || 0) + 1);
      return this.allocSlot(this.scope, type, null);
    }
    s_CASE(st) {
      const c = this.ctl[this.ctl.length - 1];
      if (!c || c.kind !== 'select') this.error('CASE without SELECT', st.pos);
      if (c.cases > 0) c.ends.push(this.emit(O.JMP, 0));
      if (c.next) c.next.a = this.pc;
      c.cases++;
      if (st.isElse) { c.next = null; c.hasElse = true; return; }
      const bodyJumps = [];
      for (const test of st.tests) {
        const cmp = (op, e) => {
          this.emit(O.LD, c.tmp.area, c.tmp.slot);
          const t = this.expr(e);
          if (B.isStr(t) !== B.isStr(c.type)) this.error('Type mismatch', e.pos, 13);
          this.emit(O[{ '=': 'EQ', '<>': 'NE', '<': 'LT', '>': 'GT', '<=': 'LE', '>=': 'GE' }[op]]);
        };
        if (test.k === 'eq') cmp('=', test.e);
        else if (test.k === 'is') cmp(test.op, test.e);
        else {
          cmp('>=', test.a);
          const jf = this.emit(O.JF, 0);
          cmp('<=', test.b);
          bodyJumps.push(this.emit(O.JT, 0));
          jf.a = this.pc;
          continue;
        }
        bodyJumps.push(this.emit(O.JT, 0));
      }
      c.next = this.emit(O.JMP, 0);
      for (const j of bodyJumps) j.a = this.pc;
    }
    s_ENDSELECT(st) {
      const c = this.ctl[this.ctl.length - 1];
      if (!c || c.kind !== 'select') this.error('END SELECT without SELECT CASE', st.pos);
      this.ctl.pop();
      if (c.next) c.next.a = this.pc;
      for (const j of c.ends) j.a = this.pc;
    }

    s_DO(st) {
      const top = st.cond ? this.pc - 1 : this.pc;
      const c = this.pushCtl({ kind: 'do', top, exits: [], pos: st.pos });
      if (st.cond) {
        const t = this.expr(st.cond);
        this.condCheck(t, st.cond.pos);
        c.exits.push(this.emit(st.until ? O.JT : O.JF, 0));
      }
    }
    s_LOOP(st) {
      const c = this.ctl[this.ctl.length - 1];
      if (!c || c.kind !== 'do') this.error('LOOP without DO', st.pos);
      if (st.cond) {
        const t = this.expr(st.cond);
        this.condCheck(t, st.cond.pos);
        this.emit(st.until ? O.JF : O.JT, c.top);
      } else this.emit(O.JMP, c.top);
      this.ctl.pop();
      for (const j of c.exits) j.a = this.pc;
    }

    s_WHILE(st) {
      const top = this.pc - 1; // include STMT so stepping shows WHILE each iteration
      const t = this.expr(st.cond);
      this.condCheck(t, st.cond.pos);
      const jf = this.emit(O.JF, 0);
      this.pushCtl({ kind: 'while', top, jf, pos: st.pos });
    }
    s_WEND(st) {
      let c = null;
      for (let i = this.ctl.length - 1; i >= 0; i--) if (this.ctl[i].kind === 'while') { c = this.ctl[i]; break; }
      if (!c) this.error('WEND without WHILE', st.pos, 30);
      this.emit(O.JMP, c.top);
      if (!this.inIf1) {
        // pop (and anything above, GW leniency)
        while (this.ctl.length && this.ctl[this.ctl.length - 1] !== c) this.ctl.pop();
        this.ctl.pop();
        c.jf.a = this.pc;
      } else if (!c.jfSet) {
        c.pendingInner = c.pendingInner || [];
      }
    }

    s_FOR(st) {
      const v = this.resolveScalarTarget(st.v);
      if (!B.isNum(v.type)) this.error('Type mismatch', st.v.pos, 13);
      this.coerce(this.expr(st.from), v.type, st.from.pos);
      this.coerce(this.expr(st.to), v.type, st.to.pos);
      if (st.step) this.coerce(this.expr(st.step), v.type, st.step.pos);
      else this.emit(O.CONST, 1);
      const ins = this.emit(O.FOR, v.area, v.slot, v.type, 0);
      ins.varName = v.display;
      this.pushCtl({ kind: 'for', ins, v, pos: st.pos, exitFix: [], ifDepth: this.inIf1 || 0 });
    }
    s_NEXT(st) {
      const vars = st.vars.length ? st.vars : [null];
      for (let i = 0; i < vars.length; i++) {
        let v = null;
        if (vars[i]) v = this.resolveScalarTarget(vars[i]);
        // find lexical FOR
        let c = null, ci = -1;
        for (let j = this.ctl.length - 1; j >= 0; j--) {
          const x = this.ctl[j];
          if (x.kind === 'for' && (!v || (x.v.area === v.area && x.v.slot === v.slot))) { c = x; ci = j; break; }
          if (x.kind !== 'for' && !this.inIf1) break; // don't cross other blocks
        }
        const ins = this.emit(O.NEXT, v ? v.area : -1, v ? v.slot : -1, v ? v.type : null);
        if (i < vars.length - 1) {
          // a following NEXT var in the same statement: mark a new statement boundary
        }
        if (c) {
          if (!this.inIf1 || c.ifDepth === this.inIf1) {
            this.ctl.splice(ci);
            c.ins.d = this.pc;
            for (const e of c.exitFix) e.a = this.pc;
            c.closed = true;
          } else if (!c.innerExit) {
            c.innerExit = this.pc;
          }
        }
      }
    }
    s_EXIT(st) {
      const what = st.what;
      if (what === 'FOR') {
        const c = this.topCtl('for');
        if (!c) this.error('EXIT FOR not within FOR...NEXT', st.pos);
        const ins = this.emit(O.EXITFOR, 0);
        c.exitFix.push(ins);
      } else if (what === 'DO') {
        const c = this.topCtl('do');
        if (!c) this.error('EXIT DO not within DO...LOOP', st.pos);
        c.exits.push(this.emit(O.JMP, 0));
      } else if (what === 'SUB' || what === 'FUNCTION' || what === 'DEF') {
        const k = this.curProc.kind;
        if ((what === 'SUB' && k !== 'sub') || (what === 'FUNCTION' && k !== 'function') || (what === 'DEF' && k !== 'def'))
          this.error(`EXIT ${what} not within ${what}`, st.pos);
        this.emit(O.RET);
      }
    }

    s_GOTO(st) { const ins = this.emit(O.JMP, 0); this.labelRef(st.target, ins, 'a'); }
    s_GOSUB(st) { const ins = this.emit(O.GOSUB, 0); this.labelRef(st.target, ins, 'a'); }
    s_RETURN(st) {
      const ins = this.emit(O.RETURN, -1);
      if (st.target) this.labelRef(st.target, ins, 'a');
    }
    s_ONGO(st) {
      const t = this.expr(st.e);
      this.coerce(t, T.INT, st.e.pos);
      const targets = st.targets.map(() => 0);
      this.emit(O.ONGO, targets, st.gosub ? 1 : 0);
      st.targets.forEach((tg, i) => this.labelArrRef(tg, targets, i));
    }
    s_END(st) { this.emit(O.END, st.system ? 1 : 0); }
    s_STOP() { this.emit(O.STOP); }
    s_ENDSUB(st) { this.error('END SUB without SUB', st.pos); }
    s_ENDFUNCTION(st) { this.error('END FUNCTION without FUNCTION', st.pos); }
    s_ENDDEF(st) { this.error('END DEF without DEF', st.pos); }
    s_ENDTYPE(st) { this.error('END TYPE without TYPE', st.pos); }
    s_SUB(st) { this.error('SUB not allowed here', st.pos); }

    s_CALL(st) {
      const proc = this.procByBase.get(st.base);
      if (!proc || proc.kind !== 'sub') {
        if (proc && proc.kind === 'function') this.error('Expected: SUB (found FUNCTION)', st.pos);
        this.error(`Subprogram not defined: ${st.name}`, st.pos, 35);
      }
      this.callArgs(proc, st.args, st.pos);
      this.emit(O.CALL, proc.index, st.args.length, 0);
    }

    // Push arguments for a SUB/FUNCTION call
    callArgs(proc, args, pos) {
      if (args.length !== proc.params.length) this.error('Argument-count mismatch', pos, 37);
      for (let i = 0; i < args.length; i++) {
        const a = args[i], p = proc.params[i];
        if (p.isArray) {
          const node = a.k === 'arrayname' || a.k === 'var' || (a.k === 'index' && a.args.length === 0) ? a : null;
          if (!node) this.error('Parameter type mismatch (array expected)', a.pos);
          const v = this.lookupVar(node, true, true);
          if (!B.sameType(v.type, p.type) && p.type.k !== 'any') this.error('Parameter type mismatch', a.pos);
          this.emit(O.REF, v.area, v.slot);
          continue;
        }
        if (a.k === 'arrayname') this.error('Parameter type mismatch', a.pos);
        if (proc.kind === 'def' || p.byval) {
          this.coerce(this.expr(a), p.type, a.pos);
          if (proc.kind !== 'def') this.emit(O.MKREF);
          continue;
        }
        // By reference if a simple lvalue of exactly the same type
        if (a.k === 'var' || a.k === 'index' || a.k === 'member') {
          const lt = this.tryLvalueType(a);
          if (lt) {
            if (B.sameType(lt, p.type) || (p.type.k === 'any')) {
              this.ref(a);
              continue;
            }
            if (B.isRec(lt) || B.isRec(p.type)) this.error('Parameter type mismatch', a.pos);
            if (lt.k !== 'fixstr' && p.type.k !== 'string') this.error('Parameter type mismatch', a.pos);
          }
        }
        const t = this.expr(a);
        if (B.isRec(p.type)) this.error('Parameter type mismatch', a.pos);
        this.coerce(t, p.type.k === 'any' ? t : p.type, a.pos);
        this.emit(O.MKREF);
      }
    }

    // Returns the type of an lvalue node without emitting code (null if not an lvalue var)
    tryLvalueType(node) {
      if (node.k === 'var') {
        if (this.lookupConst(node)) return null;
        const pr = this.procByBase.get(node.base);
        if (pr && pr.kind === 'function') return null;
        const r = this.resolveDotted(node, false);
        if (r) return r.type;
        const v = this.lookupVar(node, false, true);
        return v.type;
      }
      if (node.k === 'index') {
        const arr = this.lookupVar(node, true, false);
        if (arr) return arr.type;
        const pr = this.procByBase.get(node.base);
        if (pr && pr.kind === 'function') return null;
        return this.lookupVar(node, true, true).type;
      }
      if (node.k === 'member') {
        const ot = this.tryLvalueType(node.obj);
        if (!ot || !B.isRec(ot)) return null;
        const f = ot.def.fields.find((x) => x.name === node.field.replace(/[%&!#$]$/, ''));
        return f ? f.type : null;
      }
      return null;
    }

    s_SWAP(st) {
      const ta = this.ref(st.a);
      const tb = this.ref(st.b);
      if (!B.sameType(ta, tb) && !(B.isStr(ta) && B.isStr(tb))) this.error('Type mismatch', st.b.pos, 13);
      this.emit(O.SWAP, ta, tb);
    }

    s_DIM(st) {
      const scope = this.scope;
      if (st.shared && scope !== this.module) this.error('DIM SHARED only allowed at module level', st.pos);
      const target = st.shared ? this.module : scope;
      for (const v of st.vars) {
        if (this.constClash(v.base)) this.error('Duplicate definition (a CONST has this name)', v.pos, 10);
        const isArray = v.dims !== null;
        const type = v.type ? this.resolveTypeSpec(v.type, v.pos) : this.typeOfName(v.base, v.sfx);
        if (v.type && v.sfx && !B.sameType(type, B.typeBySfx(v.sfx))) this.error('Duplicate definition', v.pos, 10);
        const map = isArray ? target.arrays : target.vars;
        const asMap = isArray ? target.asArrays : target.asVars;
        let info = null;
        if (v.type) {
          info = asMap.get(v.base) || null;
          if (info && !B.sameType(info.type, type)) this.error('Duplicate definition', v.pos, 10);
          if (!info) {
            for (const x of map.values()) if (x.base === v.base && !x.asDecl && !x.param) this.error('Duplicate definition', v.pos, 10);
            info = this.newVar(target, v.base + '@', v.base, type, isArray, v.display, true);
          } else if (!isArray && !st.redim) this.error('Duplicate definition', v.pos, 10);
        } else {
          info = asMap.get(v.base) || null;
          if (info) {
            if (v.sfx && !B.sameType(info.type, B.typeBySfx(v.sfx))) this.error('Duplicate definition', v.pos, 10);
          } else {
            const key = v.base + type.sfx;
            info = map.get(key) || this.newVar(target, key, v.base, type, isArray, v.display, false);
          }
        }
        if (st.shared) {
          const key = v.base + (v.type ? '@' : type.sfx);
          if (isArray) { this.sharedGlobalArrays.set(key, info); if (v.type) this.sharedAsArrays.set(v.base, info); }
          else { this.sharedGlobals.set(key, info); if (v.type) this.sharedAs.set(v.base, info); }
        }
        if (!isArray) {
          if (st.redim) this.error('Array required', v.pos);
          continue;
        }
        if (v.dims.length === 0) continue; // DIM a() declares a dynamic array without allocating
        const isConst = v.dims.every((d) => (!d.lo || this.isConstExpr(d.lo)) && this.isConstExpr(d.hi));
        for (const d of v.dims) {
          if (d.lo) this.coerce(this.expr(d.lo), T.LONG, d.lo.pos); else this.emit(O.CONST, this.optionBase);
          this.coerce(this.expr(d.hi), T.LONG, d.hi.pos);
        }
        const dynamic = !!st.redim || !isConst || !!this.dynamicMode || scope.kind !== 'module';
        this.emit(O.DIM, info.area, info.slot, info.type, v.dims.length, { redim: !!st.redim, preserve: !!st.preserve, dynamic, name: v.display });
      }
    }
    isConstExpr(e) {
      if (!e) return true;
      if (e.k === 'num') return true;
      if (e.k === 'un') return this.isConstExpr(e.e);
      if (e.k === 'paren') return this.isConstExpr(e.e);
      if (e.k === 'bin') return this.isConstExpr(e.l) && this.isConstExpr(e.r);
      if (e.k === 'var') return !!this.lookupConst(e);
      return false;
    }

    s_STATICVARS(st) {
      const scope = this.scope;
      if (scope.kind === 'module') this.error('STATIC only allowed in SUB/FUNCTION', st.pos);
      for (const v of st.vars) {
        let type = v.type ? this.resolveTypeSpec(v.type, v.pos) : this.typeOfName(v.base, v.sfx);
        const isArray = v.dims !== null;
        const key = v.base + (v.type ? '@' : type.sfx);
        scope.staticVars.add(key);
        const map = isArray ? scope.arrays : scope.vars;
        if (map.get(v.base + type.sfx) || (v.type && (isArray ? scope.asArrays : scope.asVars).get(v.base))) {
          continue; // already static or declared
        }
        const info = { key, base: v.base, type, isArray, display: v.display, asDecl: !!v.type };
        const proc = scope.proc;
        const slot = proc.nstatic++;
        proc.staticTypes[slot] = isArray ? { k: 'array', code: 7, elem: type } : type;
        info.area = A_S; info.slot = slot;
        map.set(v.base + type.sfx, info);
        if (v.type) (isArray ? scope.asArrays : scope.asVars).set(v.base, info);
        scope.symbols.push(info);
      }
    }
    s_SHAREDVARS(st) {
      const scope = this.scope;
      if (scope.kind === 'module') this.error('SHARED only allowed in SUB/FUNCTION', st.pos);
      for (const v of st.vars) {
        const isArray = v.dims !== null;
        let type = v.type ? this.resolveTypeSpec(v.type, v.pos) : this.typeOfName(v.base, v.sfx);
        // Make sure the module variable exists
        const saved = this.scope;
        this.scope = this.module;
        let info;
        if (v.type) {
          info = (isArray ? this.module.asArrays : this.module.asVars).get(v.base);
          if (!info) info = this.newVar(this.module, v.base + '@', v.base, type, isArray, v.display, true);
        } else info = this.lookupVar(v, isArray, true, this.module);
        this.scope = saved;
        const map = isArray ? scope.arrays : scope.vars;
        map.set(v.base + (v.type ? '@' : type.sfx), info);
        if (v.type) (isArray ? scope.asArrays : scope.asVars).set(v.base, info);
        else map.set(v.base + type.sfx, info);
      }
    }
    s_COMMON(st) {
      for (const v of st.vars) {
        const isArray = v.dims !== null;
        let type = v.type ? this.resolveTypeSpec(v.type, v.pos) : this.typeOfName(v.base, v.sfx);
        let info;
        if (v.type) {
          info = (isArray ? this.module.asArrays : this.module.asVars).get(v.base);
          if (!info) info = this.newVar(this.module, v.base + '@', v.base, type, isArray, v.display, true);
        } else info = this.lookupVar(v, isArray, true, this.module);
        this.commons.push(info);
        if (st.shared) {
          if (isArray) { this.sharedGlobalArrays.set(v.base + type.sfx, info); if (v.type) this.sharedAsArrays.set(v.base, info); }
          else { this.sharedGlobals.set(v.base + type.sfx, info); if (v.type) this.sharedAs.set(v.base, info); }
        }
      }
    }
    s_ERASE(st) {
      for (const n of st.names) {
        const v = this.lookupVar(n, true, false);
        if (!v) this.error('Array not defined', n.pos, 38);
        this.emit(O.ERASE, v.area, v.slot);
      }
    }
    s_OPTIONBASE(st) { this.optionBase = st.v; }

    stConst(st) {
      for (const it of st.items) {
        const val = this.constEval(it.e);
        let type = val.type;
        if (it.sfx) {
          const t2 = B.typeBySfx(it.sfx);
          if (B.isStr(t2) !== B.isStr(type)) this.error('Type mismatch', it.pos, 13);
          type = t2;
        }
        const v = B.isNum(type) ? B.coerce(type, val.value) : val.value;
        const key = it.base + (it.sfx || '*');
        this.scope.consts.set(key, { value: v, type, display: it.display });
      }
    }

    constEval(e) {
      const self = this;
      function ev(e) {
        switch (e.k) {
          case 'num': return { value: e.v, type: B.typeByK(e.ty) };
          case 'str': return { value: e.v, type: T.STRING };
          case 'paren': return ev(e.e);
          case 'var': {
            const c = self.lookupConst(e);
            if (!c) self.error('Invalid constant', e.pos);
            return { value: c.value, type: c.type };
          }
          case 'un': {
            const a = ev(e.e);
            if (!B.isNum(a.type)) self.error('Type mismatch', e.pos, 13);
            if (e.op === '-') return { value: -a.value, type: a.type };
            return { value: ~B.toLong(a.value), type: a.type.code <= 1 ? T.INT : T.LONG };
          }
          case 'bin': {
            const a = ev(e.l), b = ev(e.r);
            if (B.isStr(a.type) || B.isStr(b.type)) {
              if (!B.isStr(a.type) || !B.isStr(b.type)) self.error('Type mismatch', e.pos, 13);
              if (e.op === '+') return { value: a.value + b.value, type: T.STRING };
              const r = cmp(e.op, a.value, b.value);
              if (r === undefined) self.error('Type mismatch', e.pos, 13);
              return { value: r, type: T.INT };
            }
            const pt = B.numPromote(a.type, b.type);
            const x = a.value, y = b.value;
            switch (e.op) {
              case '+': return { value: x + y, type: pt };
              case '-': return { value: x - y, type: pt };
              case '*': return { value: x * y, type: pt };
              case '/': return { value: x / y, type: pt.code === 4 ? T.DOUBLE : T.SINGLE };
              case '^': return { value: Math.pow(x, y), type: pt.code === 4 ? T.DOUBLE : T.SINGLE };
              case '\\': return { value: Math.trunc(B.roundEven(x) / B.roundEven(y)), type: pt.code <= 1 ? T.INT : T.LONG };
              case 'MOD': return { value: B.roundEven(x) % B.roundEven(y), type: pt.code <= 1 ? T.INT : T.LONG };
              case 'AND': return { value: B.toLong(x) & B.toLong(y), type: pt.code <= 1 ? T.INT : T.LONG };
              case 'OR': return { value: B.toLong(x) | B.toLong(y), type: pt.code <= 1 ? T.INT : T.LONG };
              case 'XOR': return { value: B.toLong(x) ^ B.toLong(y), type: pt.code <= 1 ? T.INT : T.LONG };
              default: {
                const r = cmp(e.op, x, y);
                if (r === undefined) self.error('Invalid constant', e.pos);
                return { value: r, type: T.INT };
              }
            }
          }
        }
        self.error('Invalid constant', e.pos);
      }
      function cmp(op, x, y) {
        switch (op) {
          case '=': return x === y ? -1 : 0;
          case '<>': return x !== y ? -1 : 0;
          case '<': return x < y ? -1 : 0;
          case '>': return x > y ? -1 : 0;
          case '<=': return x <= y ? -1 : 0;
          case '>=': return x >= y ? -1 : 0;
        }
        return undefined;
      }
      try { return ev(e); } catch (ex) {
        if (ex instanceof CompileError) throw ex;
        if (ex instanceof B.BasicError) this.error(ex.message, e.pos, ex.code);
        throw ex;
      }
    }

    // ---- PRINT / WRITE / INPUT --------------------------------------------------------------
    s_PRINT(st) {
      if (st.lpt) this.emit(O.PRCH, 2);
      else if (st.file) { this.coerce(this.expr(st.file), T.INT, st.file.pos); this.emit(O.PRCH, 1); }
      else this.emit(O.PRCH, 0);
      if (st.using) {
        const t = this.expr(st.using);
        if (!B.isStr(t)) this.error('Type mismatch', st.using.pos, 13);
        this.emit(O.PRUSING);
      }
      let last = null;
      for (const it of st.items) {
        last = it.k;
        switch (it.k) {
          case 'expr': {
            const t = this.expr(it.e);
            if (B.isRec(t)) this.error('Type mismatch', it.e.pos, 13);
            this.emit(st.using ? O.PRUVAL : O.PRVAL, t.code);
            break;
          }
          case 'comma': if (!st.using) this.emit(O.PRCOMMA); break;
          case 'semi': break;
          case 'tab': this.coerce(this.expr(it.e), T.INT, it.e.pos); this.emit(O.PRTAB); break;
          case 'spc': this.coerce(this.expr(it.e), T.INT, it.e.pos); this.emit(O.PRSPC); break;
        }
      }
      this.emit(O.PREND, last === 'semi' || last === 'comma' ? 0 : 1);
    }
    s_WRITE(st) {
      if (st.file) { this.coerce(this.expr(st.file), T.INT, st.file.pos); this.emit(O.PRCH, 1); }
      else this.emit(O.PRCH, 0);
      st.items.forEach((e, i) => {
        const t = this.expr(e);
        this.emit(O.WRITE, t.code, i === st.items.length - 1 ? 1 : 0);
      });
      if (!st.items.length) this.emit(O.PREND, 1);
    }
    s_INPUT(st) {
      const types = st.vars.map((v) => this.tryLvalueType(v) || T.SINGLE);
      for (let i = 0; i < types.length; i++) if (B.isRec(types[i])) this.error('Type mismatch', st.vars[i].pos, 13);
      this.emit(O.INPUT, { prompt: st.prompt, qmark: st.qmark, noNewline: st.noNewline, types });
      st.vars.forEach((v, i) => this.store(v, () => { this.emit(O.INPUTVAL, i); return types[i]; }, v.pos));
    }
    s_LINEINPUT(st) {
      const t = this.tryLvalueType(st.target);
      if (!t || !B.isStr(t)) this.error('Type mismatch', st.target.pos, 13);
      this.emit(O.LINEINPUT, { prompt: st.prompt, noNewline: st.noNewline });
      this.store(st.target, () => { this.emit(O.INPUTVAL, 0); return T.STRING; }, st.target.pos);
    }
    s_INPUTF(st) {
      for (const v of st.vars) {
        const t = this.tryLvalueType(v);
        if (!t || B.isRec(t)) this.error('Type mismatch', v.pos, 13);
        this.store(v, () => {
          this.coerce(this.expr(st.file), T.INT, st.file.pos);
          this.emit(O.FINPUT, t.code);
          return B.isStr(t) ? T.STRING : T.DOUBLE;
        }, v.pos);
      }
    }
    s_LINEINPUTF(st) {
      const t = this.tryLvalueType(st.target);
      if (!t || !B.isStr(t)) this.error('Type mismatch', st.target.pos, 13);
      this.store(st.target, () => {
        this.coerce(this.expr(st.file), T.INT, st.file.pos);
        this.emit(O.FLINEINPUT);
        return T.STRING;
      }, st.target.pos);
    }
    s_READ(st) {
      for (const v of st.vars) {
        const t = this.tryLvalueType(v);
        if (!t || B.isRec(t)) this.error('Type mismatch', v.pos, 13);
        this.store(v, () => { this.emit(O.READ, t.code); return B.isStr(t) ? T.STRING : T.DOUBLE; }, v.pos);
      }
    }
    s_DATA() { /* collected in prepass */ }
    s_RESTORE(st) {
      if (!st.target) { this.emit(O.RESTORE, 0); return; }
      const key = st.target.lineNo !== undefined ? String(st.target.lineNo) : st.target.label;
      let idx = this.labelData.get((this.curProc.kind === 'module' ? '' : this.curProc.base) + ':' + key);
      if (idx === undefined) idx = this.labelData.get(':' + key);
      if (idx === undefined) idx = this.labelData.get('*:' + key);
      if (idx === undefined) this.error(`Label not defined: ${key}`, st.target.pos, 8);
      this.emit(O.RESTORE, idx);
    }

    s_MIDSET(st) {
      const t = this.ref(st.target);
      if (!B.isStr(t)) this.error('Type mismatch', st.target.pos, 13);
      this.coerce(this.expr(st.start), T.LONG, st.start.pos);
      if (st.len) this.coerce(this.expr(st.len), T.LONG, st.len.pos); else this.emit(O.CONST, undefined);
      const te = this.expr(st.e);
      if (!B.isStr(te)) this.error('Type mismatch', st.e.pos, 13);
      this.emit(O.MIDSET);
    }
    s_LRSET(st) {
      const t = this.ref(st.target);
      const te = this.expr(st.e);
      if (B.isRec(t)) {
        if (!B.isRec(te)) this.error('Type mismatch', st.e.pos, 13);
      } else if (!B.isStr(t) || !B.isStr(te)) this.error('Type mismatch', st.e.pos, 13);
      this.emit(O.LRSET, st.right ? 1 : 0);
    }

    // ---- errors and events ----------------------------------------------------------------
    s_ONERROR(st) {
      if (st.resumeNext) { this.emit(O.ONERROR, -2); return; }
      const ins = this.emit(O.ONERROR, -1);
      if (st.target) this.moduleLabelRef(st.target, ins, 'a');
    }
    moduleLabelRef(target, ins, field) {
      // Error/event handlers live at module level. Resolve after module compile.
      const key = target.lineNo !== undefined ? String(target.lineNo) : target.label;
      if (this.scope === this.module) this.labelRef(target, ins, field);
      else {
        const pc = this.module.labels.get(key);
        if (pc === undefined) this.error(`Label not defined: ${key}`, target.pos, 8);
        ins[field] = pc;
      }
    }
    s_RESUME(st) {
      if (st.next) { this.emit(O.RESUME, 1, 0); return; }
      if (st.target) { const ins = this.emit(O.RESUME, 2, 0); this.labelRef(st.target, ins, 'b'); return; }
      this.emit(O.RESUME, 0, 0);
    }
    s_ERROR(st) { this.coerce(this.expr(st.e), T.INT, st.e.pos); this.emit(O.ERROR); }
    s_ONEVENT(st) {
      if (st.arg) this.coerce(this.expr(st.arg), T.INT, st.arg.pos); else this.emit(O.CONST, 0);
      const ins = this.emit(O.ONEVENT, st.ev, -1);
      if (st.target) this.moduleLabelRef(st.target, ins, 'b');
    }
    s_EVENTCTL(st) {
      if (st.arg) this.coerce(this.expr(st.arg), T.INT, st.arg.pos); else this.emit(O.CONST, st.ev === 'STRIG' || st.ev === 'KEY' ? -1 : 0);
      this.emit(O.EVENTCTL, st.ev, st.mode);
    }

    // ---- files --------------------------------------------------------------------------------
    s_OPEN(st) {
      if (st.gw) {
        const tm = this.expr(st.mode); if (!B.isStr(tm)) this.error('Type mismatch', st.mode.pos, 13);
      } else this.emit(O.CONST, st.mode);
      this.coerce(this.expr(st.num), T.INT, st.num.pos);
      const tf = this.expr(st.file); if (!B.isStr(tf)) this.error('Type mismatch', st.file.pos, 13);
      if (st.len) this.coerce(this.expr(st.len), T.LONG, st.len.pos); else this.emit(O.CONST, undefined);
      this.emit(O.OPEN, st.gw ? 1 : 0, st.access || null);
    }
    s_CLOSE(st) {
      for (const n of st.nums) this.coerce(this.expr(n), T.INT, n.pos);
      this.emit(O.CLOSE, st.nums.length);
    }
    s_FIELD(st) {
      this.coerce(this.expr(st.file), T.INT, st.file.pos);
      for (const f of st.fields) {
        this.coerce(this.expr(f.w), T.INT, f.w.pos);
        const t = this.ref(f.v);
        if (!B.isStr(t) || t.k === 'fixstr') this.error('Type mismatch', f.v.pos, 13);
      }
      this.emit(O.FIELD, st.fields.length);
    }
    s_FGET(st) {
      this.coerce(this.expr(st.file), T.INT, st.file.pos);
      if (st.rec) this.coerce(this.expr(st.rec), T.DOUBLE, st.rec.pos); else this.emit(O.CONST, undefined);
      let t = null;
      if (st.v) t = this.ref(st.v); else this.emit(O.CONST, undefined);
      this.emit(O.FGET, t);
    }
    s_FPUT(st) {
      this.coerce(this.expr(st.file), T.INT, st.file.pos);
      if (st.rec) this.coerce(this.expr(st.rec), T.DOUBLE, st.rec.pos); else this.emit(O.CONST, undefined);
      let t = null;
      if (st.v) { t = this.expr(st.v); } else this.emit(O.CONST, undefined);
      this.emit(O.FPUT, t);
    }

    // ---- graphics -----------------------------------------------------------------------------
    num(e, t) { if (e) this.coerce(this.expr(e), t || T.SINGLE, e.pos); else this.emit(O.CONST, undefined); }
    s_GPOINT(st) {
      this.num(st.p.x); this.num(st.p.y); this.num(st.color, T.LONG);
      this.emit(O.GPOINT, st.name === 'PRESET' ? 1 : 0, st.p.step ? 1 : 0);
    }
    s_GLINE(st) {
      if (st.p1) { this.num(st.p1.x); this.num(st.p1.y); } else { this.emit(O.CONST, undefined); this.emit(O.CONST, undefined); }
      this.num(st.p2.x); this.num(st.p2.y);
      this.num(st.color, T.LONG);
      this.num(st.style, T.LONG);
      this.emit(O.GLINE, { step1: st.p1 ? st.p1.step : false, step2: st.p2.step, has1: !!st.p1, box: st.box });
    }
    s_GCIRCLE(st) {
      this.num(st.p.x); this.num(st.p.y); this.num(st.r); this.num(st.color, T.LONG);
      this.num(st.start); this.num(st.end); this.num(st.aspect);
      this.emit(O.GCIRCLE, st.p.step ? 1 : 0);
    }
    s_GPAINT(st) {
      this.num(st.p.x); this.num(st.p.y);
      let tileStr = false;
      if (st.paint) {
        const t = this.expr(st.paint);
        tileStr = B.isStr(t);
        if (!tileStr) this.coerce(t, T.LONG, st.paint.pos);
      } else this.emit(O.CONST, undefined);
      this.num(st.border, T.LONG);
      if (st.bg) { const t = this.expr(st.bg); if (!B.isStr(t)) this.error('Type mismatch', st.bg.pos, 13); } else this.emit(O.CONST, undefined);
      this.emit(O.GPAINT, st.p.step ? 1 : 0, tileStr ? 1 : 0);
    }
    gfxArray(node) {
      const v = this.lookupVar(node, true, true);
      if (!B.isNum(v.type)) this.error('Type mismatch', node.pos, 13);
      this.emit(O.REF, v.area, v.slot);
      if (node.index) {
        for (const e of node.index) this.coerce(this.expr(e), T.LONG, e.pos);
      }
      return node.index ? node.index.length : 0;
    }
    s_GGET(st) {
      this.num(st.p1.x); this.num(st.p1.y); this.num(st.p2.x); this.num(st.p2.y);
      const n = this.gfxArray(st.arr);
      this.emit(O.GGET, n, { step1: st.p1.step, step2: st.p2.step });
    }
    s_GPUT(st) {
      this.num(st.p.x); this.num(st.p.y);
      const n = this.gfxArray(st.arr);
      this.emit(O.GPUT, n, { step: st.p.step, action: st.action });
    }
    s_PALUSING(st) {
      const n = this.gfxArray(st.arr);
      this.emit(O.PALUSING, n);
    }

    // Generic builtin statement with positional args
    s_SYS(st) {
      const spec = B.SYS_STMTS[st.name];
      if (!spec) this.error(`Unsupported statement: ${st.name}`, st.pos);
      const types = spec.args || '';
      for (let i = 0; i < st.args.length; i++) {
        const a = st.args[i];
        if (!a) { this.emit(O.CONST, undefined); continue; }
        const want = types[i] || 'n';
        const t = this.expr(a);
        if (want === 's' && !B.isStr(t)) this.error('Type mismatch', a.pos, 13);
        if (want === 'n' && !B.isNum(t)) this.error('Type mismatch', a.pos, 13);
      }
      this.emit(O.SYS, st.name, st.args.length);
    }
    s_CLEAR() { this.emit(O.CLEAR); }
    s_DEFSEG(st) {
      if (st.e) this.coerce(this.expr(st.e), T.LONG, st.e.pos); else this.emit(O.CONST, undefined);
      this.emit(O.SYS, 'DEFSEG', 1);
    }
    s_NOP() {}
    s_CHAIN(st) {
      const t = this.expr(st.file); if (!B.isStr(t)) this.error('Type mismatch', st.file.pos, 13);
      if (st.line) this.coerce(this.expr(st.line), T.LONG, st.line.pos); else this.emit(O.CONST, undefined);
      this.emit(O.CHAIN, { merge: st.merge, all: st.all, del: st.del });
    }
    s_RUN(st) {
      if (st.file) { const t = this.expr(st.file); if (!B.isStr(t)) this.error('Type mismatch', st.file.pos, 13); }
      else this.emit(O.CONST, undefined);
      this.emit(O.RUN, st.line !== undefined ? st.line : null);
    }
    s_CMD(st) {
      if (st.file) { const t = this.expr(st.file); if (!B.isStr(t)) this.error('Type mismatch', st.file.pos, 13); }
      else this.emit(O.CONST, undefined);
      this.emit(O.CMD, st);
    }

    // ---- lvalues ---------------------------------------------------------------------------------
    // Resolve "a.b.c" where a is a record variable. Returns {type} after emitting load of object
    // when emit=true, or just the type when emit=false. Returns null if not a record path.
    resolveDotted(node, emit, mode) {
      if (!node.base.includes('.')) return null;
      const parts = node.base.split('.');
      // Variable without suffix whose base is the first part
      const head = { base: parts[0], sfx: '', name: parts[0], pos: node.pos };
      let v = null;
      // Prefer an existing record variable
      v = this.lookupVar(head, false, false);
      if (!v || !B.isRec(v.type)) return null;
      let type = v.type;
      const fieldPath = [];
      for (let i = 1; i < parts.length; i++) {
        let fname = parts[i];
        const isLast = i === parts.length - 1;
        if (isLast && node.sfx) fname = fname; // suffix on last field name
        const f = type.def.fields.find((x) => x.name === fname);
        if (!f) this.error(`Element not defined: ${fname}`, node.pos);
        fieldPath.push(f);
        type = f.type;
      }
      if (node.sfx && !B.sameType(type, B.typeBySfx(node.sfx))) this.error('Type mismatch', node.pos, 13);
      if (emit) {
        this.emit(O.LD, v.area, v.slot);
        for (let i = 0; i < fieldPath.length - 1; i++) this.emit(O.FLD, fieldPath[i].name);
        return { type, field: fieldPath[fieldPath.length - 1], v };
      }
      return { type, field: fieldPath[fieldPath.length - 1], v };
    }

    // For FOR loop variables and NEXT: must be simple scalar numeric variables
    resolveScalarTarget(node) {
      if (node.k !== 'var') this.error('Expected: simple variable', node.pos);
      const v = this.lookupVar(node, false, true);
      return v;
    }

    /** Emit a store: target <- value (valueFn emits code and returns its type) */
    store(target, valueFn, pos) {
      if (target.k === 'var') {
        // Function return value assignment
        const proc = this.curProc;
        if ((proc.kind === 'function' || proc.kind === 'def') && target.base === proc.base) {
          const t = valueFn();
          this.coerce(t, proc.retType, pos);
          this.emit(O.ST, A_L, proc.retSlot, proc.retType);
          return;
        }
        if (this.lookupConst(target)) this.error('Duplicate definition (cannot assign to CONST)', target.pos, 10);
        const pr = this.procByBase.get(target.base);
        if (pr && pr.kind === 'function') this.error('Duplicate definition', target.pos, 10);
        const d = this.resolveDotted(target, true);
        if (d) {
          const t = valueFn();
          this.coerce(t, d.type, pos);
          this.emit(O.FLDST, d.field.name, d.type);
          return;
        }
        const v = this.lookupVar(target, false, true);
        const t = valueFn();
        this.coerce(t, v.type, pos);
        this.emit(O.ST, v.area, v.slot, v.type);
        return;
      }
      if (target.k === 'index') {
        const v = this.arrayFor(target);
        for (const e of target.args) this.coerce(this.expr(e), T.LONG, e.pos);
        const t = valueFn();
        this.coerce(t, v.type, pos);
        this.emit(O.ARRST, v.area, v.slot, target.args.length, v.type);
        return;
      }
      if (target.k === 'member') {
        const ot = this.lvalObj(target.obj);
        const f = this.fieldOf(ot, target);
        const t = valueFn();
        this.coerce(t, f.type, pos);
        this.emit(O.FLDST, f.name, f.type);
        return;
      }
      this.error('Expected: variable', target.pos);
    }

    arrayFor(node) {
      const pr = this.procByBase.get(node.base);
      const v = this.lookupVar(node, true, false);
      if (!v && pr && pr.kind === 'function') this.error('Expected: variable (found FUNCTION)', node.pos);
      return v || this.lookupVar(node, true, true);
    }
    fieldOf(ot, node) {
      if (!B.isRec(ot)) this.error('Expected: record variable', node.pos);
      const name = node.field.replace(/[%&!#$]$/, '');
      const f = ot.def.fields.find((x) => x.name === name);
      if (!f) this.error(`Element not defined: ${name}`, node.pos);
      return f;
    }
    // Emit code that pushes the record object for an lvalue; returns its type
    lvalObj(node) {
      if (node.k === 'var') {
        const d = this.resolveDotted(node, true);
        if (d) { this.emit(O.FLD, d.field.name); return d.type; }
        const v = this.lookupVar(node, false, true);
        this.emit(O.LD, v.area, v.slot);
        return v.type;
      }
      if (node.k === 'index') {
        const v = this.arrayFor(node);
        for (const e of node.args) this.coerce(this.expr(e), T.LONG, e.pos);
        this.emit(O.ARRLD, v.area, v.slot, node.args.length, v.type);
        return v.type;
      }
      if (node.k === 'member') {
        const ot = this.lvalObj(node.obj);
        const f = this.fieldOf(ot, node);
        this.emit(O.FLD, f.name);
        return f.type;
      }
      this.error('Expected: variable', node.pos);
    }

    /** Emit code pushing a Ref to an lvalue; returns its type */
    ref(node) {
      if (node.k === 'var') {
        const d = this.resolveDotted(node, true);
        if (d) { this.emit(O.FLDREF, d.field.name); return d.type; }
        if (this.lookupConst(node)) this.error('Variable required', node.pos, 40);
        const proc = this.curProc;
        if ((proc.kind === 'function') && node.base === proc.base) {
          this.emit(O.REF, A_L, proc.retSlot);
          return proc.retType;
        }
        const v = this.lookupVar(node, false, true);
        this.emit(O.REF, v.area, v.slot);
        return v.type;
      }
      if (node.k === 'index') {
        const v = this.arrayFor(node);
        for (const e of node.args) this.coerce(this.expr(e), T.LONG, e.pos);
        this.emit(O.ARRREF, v.area, v.slot, node.args.length, v.type);
        return v.type;
      }
      if (node.k === 'member') {
        const ot = this.lvalObj(node.obj);
        const f = this.fieldOf(ot, node);
        this.emit(O.FLDREF, f.name);
        return f.type;
      }
      this.error('Variable required', node.pos, 40);
    }

    coerce(from, to, pos) {
      if (!to || to.k === 'any') return;
      if (B.isRec(to) || B.isRec(from)) {
        if (!B.sameType(from, to)) this.error('Type mismatch', pos, 13);
        return;
      }
      if (B.isStr(to) !== B.isStr(from)) this.error('Type mismatch', pos, 13);
      if (B.isNum(to) && from.code !== to.code) this.emit(O.CVT, to.code);
    }

    // ---- expressions ---------------------------------------------------------------------------------
    /** Compile expression, return its static type */
    expr(e) {
      switch (e.k) {
        case 'num': this.emit(O.CONST, e.v); return B.typeByK(e.ty);
        case 'str': this.emit(O.CONST, e.v); return T.STRING;
        case 'paren': return this.expr(e.e);
        case 'un': {
          const t = this.expr(e.e);
          if (!B.isNum(t)) this.error('Type mismatch', e.pos, 13);
          if (e.op === '-') { this.emit(O.NEG, t.code); return t; }
          const it = t.code <= 1 ? T.INT : T.LONG;
          if (t.code !== it.code) this.emit(O.CVT, it.code);
          this.emit(O.NOT);
          return it;
        }
        case 'bin': return this.binary(e);
        case 'var': return this.varExpr(e);
        case 'index': return this.indexExpr(e);
        case 'member': {
          const ot = this.lvalObj(e.obj);
          const f = this.fieldOf(ot, e);
          this.emit(O.FLD, f.name);
          return f.type;
        }
        case 'fn': return this.fnCall(e);
        case 'call': return this.builtinCall(e);
        case 'arrayname': this.error('Expected: expression', e.pos);
      }
      this.error('Expected: expression', e.pos);
    }

    binary(e) {
      const op = e.op;
      const tl = this.expr(e.l);
      if (op === 'AND' || op === 'OR' || op === 'XOR' || op === 'EQV' || op === 'IMP') {
        // INTEGER values are valid LONGs, so only non-integer operands need converting.
        if (!B.isNum(tl)) this.error('Type mismatch', e.pos, 13);
        if (tl.code > 2) this.emit(O.CVT, 2);
        const tr = this.expr(e.r);
        if (!B.isNum(tr)) this.error('Type mismatch', e.pos, 13);
        if (tr.code > 2) this.emit(O.CVT, 2);
        const it = tl.code <= 1 && tr.code <= 1 ? T.INT : T.LONG;
        this.emit(O[op], it.code);
        return it;
      }
      const tr = this.expr(e.r);
      const ls = B.isStr(tl), rs = B.isStr(tr);
      if (B.isRec(tl) || B.isRec(tr)) this.error('Type mismatch', e.pos, 13);
      if (ls !== rs) this.error('Type mismatch', e.pos, 13);
      switch (op) {
        case '=': this.emit(O.EQ); return T.INT;
        case '<>': this.emit(O.NE); return T.INT;
        case '<': this.emit(O.LT); return T.INT;
        case '>': this.emit(O.GT); return T.INT;
        case '<=': this.emit(O.LE); return T.INT;
        case '>=': this.emit(O.GE); return T.INT;
      }
      if (ls) {
        if (op !== '+') this.error('Type mismatch', e.pos, 13);
        this.emit(O.CAT);
        return T.STRING;
      }
      const pt = B.numPromote(tl, tr);
      switch (op) {
        case '+': this.emit(O.ADD, pt.code); return pt;
        case '-': this.emit(O.SUB, pt.code); return pt;
        case '*': this.emit(O.MUL, pt.code); return pt;
        case '/': { const rt = pt.code === 4 ? T.DOUBLE : T.SINGLE; this.emit(O.DIV, rt.code); return rt; }
        case '^': { const rt = pt.code === 4 ? T.DOUBLE : T.SINGLE; this.emit(O.POW, rt.code); return rt; }
        case '\\': { const rt = pt.code <= 1 ? T.INT : T.LONG; this.emit(O.IDIV, rt.code); return rt; }
        case 'MOD': { const rt = pt.code <= 1 ? T.INT : T.LONG; this.emit(O.MOD, rt.code); return rt; }
      }
      this.error('Syntax error', e.pos);
    }
    varExpr(e) {
      const c = this.lookupConst(e);
      if (c) { this.emit(O.CONST, c.value); return c.type; }
      const pr = this.procByBase.get(e.base);
      if (pr && pr.kind === 'function') {
        if (e.sfx && pr.retType.sfx !== e.sfx) this.error('Type mismatch', e.pos, 13);
        this.callArgs(pr, [], e.pos);
        this.emit(O.CALL, pr.index, 0, 1);
        return pr.retType;
      }
      const d = this.resolveDotted(e, true);
      if (d) { this.emit(O.FLD, d.field.name); return d.type; }
      const v = this.lookupVar(e, false, true);
      this.emit(O.LD, v.area, v.slot);
      return v.type;
    }

    indexExpr(e) {
      const arr = this.lookupVar(e, true, false);
      const pr = this.procByBase.get(e.base);
      if (!arr && pr && pr.kind === 'function') {
        if (e.sfx && pr.retType.sfx !== e.sfx) this.error('Type mismatch', e.pos, 13);
        this.callArgs(pr, e.args, e.pos);
        this.emit(O.CALL, pr.index, e.args.length, 1);
        return pr.retType;
      }
      if (pr && pr.kind === 'sub') this.error('Expected: expression (found SUB)', e.pos);
      const v = arr || this.lookupVar(e, true, true);
      if (e.args.length === 0) this.error('Expected: expression', e.pos);
      for (const a of e.args) this.coerce(this.expr(a), T.LONG, a.pos);
      this.emit(O.ARRLD, v.area, v.slot, e.args.length, v.type);
      return v.type;
    }

    fnCall(e) {
      const key = this.fnKey(e.base, e.sfx, this.defTable);
      let proc = this.fnByName.get(key);
      if (!proc) {
        // try any FN with same base
        for (const [k, p] of this.fnByName) if (p.base === e.base && (!e.sfx || p.retType.sfx === e.sfx)) { proc = p; break; }
      }
      if (!proc) this.error(`Function not defined: ${e.name}`, e.pos, 18);
      if (e.args.length !== proc.params.length) this.error('Argument-count mismatch', e.pos, 37);
      for (let i = 0; i < e.args.length; i++) this.coerce(this.expr(e.args[i]), proc.params[i].type, e.args[i].pos);
      this.emit(O.CALL, proc.index, e.args.length, 1);
      return proc.retType;
    }

    builtinCall(e) {
      const spec = B.BUILTIN_FNS[e.fn];
      if (!spec) this.error(`Function not available: ${e.fn}`, e.pos);
      if (spec.compile) return spec.compile.call(this, e);
      const n = e.args.length;
      if (n < (spec.min || 0) || n > (spec.max === undefined ? (spec.min || 0) : spec.max)) this.error('Argument-count mismatch', e.pos, 37);
      const argTypes = [];
      for (let i = 0; i < n; i++) {
        const want = (spec.args || '')[i] || 'n';
        const t = this.expr(e.args[i]);
        if (want === 's' && !B.isStr(t)) this.error('Type mismatch', e.args[i].pos, 13);
        if (want === 'n' && !B.isNum(t)) this.error('Type mismatch', e.args[i].pos, 13);
        argTypes.push(t);
      }
      let rt = spec.ret;
      if (typeof rt === 'function') rt = rt(argTypes);
      else rt = B.typeByK(rt);
      this.emit(O.CALLB, spec.impl, n, e.fn, rt.code);
      return rt;
    }
  }

  B.Compiler = Compiler;
  B.Scope = Scope;

  /**
   * Compile one or more source files into a program.
   * @param files [{name, text}] main first. $INCLUDE resolved via opts.readInclude(name) -> text
   */
  B.compileProgram = function (files, opts) {
    opts = opts || {};
    let all = [];
    const seen = new Set();
    const expand = (name, text, depth) => {
      if (depth > 16) throw new CompileError('Too many nested $INCLUDE files', null);
      const stmts = B.parse(text, name);
      for (const st of stmts) {
        if (st.k === 'REM' && st.meta && st.meta.cmd === 'INCLUDE') {
          const inc = st.meta.arg;
          if (!inc) throw new CompileError('Expected: \'$INCLUDE: \'filename\'', st.pos);
          let t = null, incName = inc.toUpperCase();
          if (opts.readIncludeEx) { const r = opts.readIncludeEx(inc); if (r) { t = r.text; incName = r.name; } }
          else if (opts.readInclude) t = opts.readInclude(inc);
          if (t === null || t === undefined) throw new CompileError(`File not found: ${inc}`, st.pos, 53);
          if (seen.has(incName)) throw new CompileError(`File included twice: ${inc}`, st.pos);
          seen.add(incName);
          all.push(st);
          expand(incName, t, depth + 1);
          continue;
        }
        all.push(st);
      }
    };
    expand(files[0].name, files[0].text, 0);
    const c = new Compiler(opts);
    const prog = c.compile(all);
    prog.files = files.map((f) => f.name);
    return prog;
  };
})(RC);
