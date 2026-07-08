// BASIC parser. Produces a flat list of statements; block structure (IF/DO/SELECT/SUB...)
// is represented by marker statements and matched by the compiler. This keeps GW-BASIC's
// unstructured control flow (GOTO anywhere, NEXT inside IF, ...) working naturally.
(function (RC) {
  'use strict';
  const B = RC.Basic;
  const CompileError = B.CompileError;

  const TYPE_KW = { INTEGER: 'int', LONG: 'long', SINGLE: 'single', DOUBLE: 'double', STRING: 'string', ANY: 'any' };

  class Parser {
    constructor(lines, file) {
      this.lines = lines; // from lexer
      this.file = file || '';
      this.toks = null;
      this.p = 0;
      this.out = [];
      this.lineInfo = null;
    }

    // ---- token helpers ------------------------------------------------------
    get tok() { return this.toks[this.p]; }
    peek(o) { return this.toks[Math.min(this.p + (o || 0), this.toks.length - 1)]; }
    next() { return this.toks[this.p++]; }
    isOp(v, o) { const t = this.peek(o); return t.t === 'op' && t.v === v; }
    isKw(v, o) { const t = this.peek(o); return t.t === 'kw' && t.v === v; }
    acceptOp(v) { if (this.isOp(v)) { this.p++; return true; } return false; }
    acceptKw(v) { if (this.isKw(v)) { this.p++; return true; } return false; }
    expectOp(v) { if (!this.acceptOp(v)) this.fail(`Expected: ${v}`); }
    expectKw(v) { if (!this.acceptKw(v)) this.fail(`Expected: ${v}`); }
    atEnd() { const t = this.tok; return t.t === 'eol' || t.t === 'rem' || (t.t === 'op' && t.v === ':'); }
    atStmtEnd() { return this.atEnd() || this.isKw('ELSE'); }
    pos(t) { t = t || this.tok; return { file: this.file, line: t.line, col: t.col, end: t.end }; }
    fail(msg, t) {
      t = t || this.tok;
      let m = msg;
      if (/^Expected/.test(msg)) {
        const seen = t.t === 'eol' ? 'end-of-statement' : t.t === 'str' ? 'string' : String(t.v);
        m = `${msg}${seen ? ' (found ' + seen + ')' : ''}`;
      }
      throw new CompileError(m, this.pos(t));
    }

    // ---- program -------------------------------------------------------------
    parseProgram() {
      for (const L of this.lines) {
        this.toks = L.tokens;
        this.p = 0;
        this.lineInfo = L;
        this.parseLine();
      }
      return this.out;
    }

    emit(st) { this.out.push(st); return st; }

    parseLine() {
      const t0 = this.tok;
      let lineNo = null;
      if (t0.t === 'lineno') {
        lineNo = t0.v;
        this.p++;
        this.emit({ k: 'LINENO', v: lineNo, pos: this.pos(t0) });
      } else if (t0.t === 'label') {
        this.p++;
        this.emit({ k: 'LABEL', v: t0.v, name: t0.name, pos: this.pos(t0) });
      }
      // statements separated by ':'
      while (true) {
        const t = this.tok;
        if (t.t === 'eol') break;
        if (t.t === 'rem') {
          this.emit({ k: 'REM', text: t.v, meta: t.meta, pos: this.pos(t), noStep: true });
          this.p++;
          continue;
        }
        if (this.acceptOp(':')) continue;
        const st = this.parseStatement(false);
        if (st) this.out.push(st);
        if (!this.atEnd()) this.fail('Expected: end-of-statement');
      }
    }

    // Parses a statement list for single-line IF (THEN/ELSE parts)
    parseInlineList() {
      const list = [];
      while (true) {
        if (this.tok.t === 'eol' || this.isKw('ELSE')) break;
        if (this.tok.t === 'rem') {
          list.push({ k: 'REM', text: this.tok.v, meta: null, pos: this.pos(), noStep: true });
          this.p++;
          break;
        }
        if (this.acceptOp(':')) continue;
        const st = this.parseStatement(true);
        if (st) list.push(st);
        if (!this.atStmtEnd()) this.fail('Expected: end-of-statement');
      }
      return list;
    }

    parseStatement(inline) {
      const t = this.tok;
      const start = this.pos(t);
      let st;
      if (t.t === 'kw') {
        const fn = this['st_' + t.v.replace('$', '_S')];
        if (!fn) this.fail(`${t.v} is not valid here`);
        this.p++;
        st = fn.call(this, t, inline);
      } else if (t.t === 'id') {
        st = this.parseAssignOrCall();
      } else if (t.t === 'num' && inline) {
        // IF x THEN 100 handled by IF; a bare number elsewhere is invalid
        this.fail('Expected: statement');
      } else if (t.t === 'op' && t.v === '.' ) {
        this.fail('Expected: statement');
      } else {
        this.fail('Expected: statement');
      }
      if (st) {
        if (!st.pos) st.pos = start;
        const last = this.toks[Math.max(0, this.p - 1)];
        st.pos = { file: this.file, line: start.line, col: start.col, end: Math.max(start.end, last.end) };
      }
      return st;
    }

    // ---- expressions ---------------------------------------------------------
    parseExpr() { return this.parseImp(); }
    binLeft(sub, ops, kw) {
      let l = sub.call(this);
      while (true) {
        const t = this.tok;
        const v = t.v;
        if ((kw ? t.t === 'kw' : t.t === 'op') && ops.includes(v)) {
          this.p++;
          const r = sub.call(this);
          l = { k: 'bin', op: v, l, r, pos: this.pos(t) };
        } else return l;
      }
    }
    parseImp() { return this.binLeft(this.parseEqv, ['IMP'], true); }
    parseEqv() { return this.binLeft(this.parseXor, ['EQV'], true); }
    parseXor() { return this.binLeft(this.parseOr, ['XOR'], true); }
    parseOr() { return this.binLeft(this.parseAnd, ['OR'], true); }
    parseAnd() { return this.binLeft(this.parseNot, ['AND'], true); }
    parseNot() {
      if (this.isKw('NOT')) {
        const t = this.next();
        return { k: 'un', op: 'NOT', e: this.parseNot(), pos: this.pos(t) };
      }
      return this.parseRel();
    }
    parseRel() { return this.binLeft(this.parseAdd, ['=', '<>', '<', '>', '<=', '>=']); }
    parseAdd() { return this.binLeft(this.parseMod, ['+', '-']); }
    parseMod() { return this.binLeft(this.parseIDiv, ['MOD'], true); }
    parseIDiv() { return this.binLeft(this.parseMul, ['\\']); }
    parseMul() { return this.binLeft(this.parseNeg, ['*', '/']); }
    parseNeg() {
      if (this.isOp('-')) {
        const t = this.next();
        return { k: 'un', op: '-', e: this.parseNeg(), pos: this.pos(t) };
      }
      if (this.isOp('+')) { this.next(); return this.parseNeg(); }
      return this.parsePow();
    }
    parsePow() {
      let l = this.parseAtom();
      while (this.isOp('^')) {
        const t = this.next();
        // exponent may be negated: 2^-1
        let r;
        if (this.isOp('-')) { const m = this.next(); r = { k: 'un', op: '-', e: this.parsePowOperand(), pos: this.pos(m) }; }
        else if (this.isOp('+')) { this.next(); r = this.parsePowOperand(); }
        else r = this.parseAtom();
        l = { k: 'bin', op: '^', l, r, pos: this.pos(t) };
      }
      return l;
    }
    parsePowOperand() {
      if (this.isOp('-')) { const m = this.next(); return { k: 'un', op: '-', e: this.parsePowOperand(), pos: this.pos(m) }; }
      return this.parseAtom();
    }
    parseAtom() {
      const t = this.tok;
      if (t.t === 'num') { this.p++; return { k: 'num', v: t.v, ty: t.ty, pos: this.pos(t) }; }
      if (t.t === 'str') { this.p++; return { k: 'str', v: t.v, pos: this.pos(t) }; }
      if (t.t === 'op' && t.v === '(') {
        this.p++;
        const e = this.parseExpr();
        this.expectOp(')');
        return { k: 'paren', e, pos: this.pos(t) };
      }
      if (t.t === 'id') return this.parseRef(true);
      if (t.t === 'kw') return this.parseBuiltinFn();
      this.fail('Expected: expression');
    }

    // Variable / array element / function call / record member chain
    parseRef(inExpr) {
      const t = this.next();
      let node;
      if (t.base.startsWith('FN') && t.base.length > 2 && !t.base.includes('.')) {
        node = { k: 'fn', name: t.v, base: t.base, sfx: t.sfx, args: [], pos: this.pos(t) };
        if (this.isOp('(')) node.args = this.parseArgList();
        return node;
      }
      if (t.v === 'FN' && this.tok.t === 'id') {
        // GW-BASIC "FN A(x)" with a space
        const t2 = this.next();
        node = { k: 'fn', name: 'FN' + t2.v, base: 'FN' + t2.base, sfx: t2.sfx, args: [], pos: this.pos(t) };
        if (this.isOp('(')) node.args = this.parseArgList();
        return node;
      }
      node = { k: 'var', name: t.v, base: t.base, sfx: t.sfx, display: t.name, pos: this.pos(t) };
      if (this.isOp('(')) {
        const args = this.parseArgList(true);
        node = { k: 'index', name: t.v, base: t.base, sfx: t.sfx, display: t.name, args, pos: this.pos(t) };
      }
      while (this.isOp('.') && this.peek(1).t === 'id') {
        this.p++;
        const f = this.next();
        node = { k: 'member', obj: node, field: f.v, pos: this.pos(f) };
        if (this.isOp('(')) this.fail('Expected: end-of-statement');
      }
      return node;
    }

    parseArgList(allowEmptyArray) {
      this.expectOp('(');
      const args = [];
      if (this.acceptOp(')')) { if (allowEmptyArray) args.emptyParens = true; return args; }
      do {
        args.push(this.parseExpr());
      } while (this.acceptOp(','));
      this.expectOp(')');
      return args;
    }

    // Builtin function in an expression
    parseBuiltinFn() {
      const t = this.next();
      const name = t.v;
      const pos = this.pos(t);
      const mk = (args, extra) => Object.assign({ k: 'call', fn: name, args, pos }, extra || {});
      switch (name) {
        // No-argument functions
        case 'INKEY$': case 'CSRLIN': case 'TIMER': case 'DATE$': case 'TIME$': case 'ERR': case 'ERL':
        case 'FREEFILE': case 'COMMAND$': case 'ERDEV': case 'ERDEV$':
          return mk([]);
        case 'RND':
          if (this.isOp('(')) return mk(this.parseArgList());
          return mk([]);
        case 'USR': {
          // USR[n](x)
          if (this.tok.t === 'num') this.p++;
          return mk(this.parseArgList());
        }
        case 'INPUT$': {
          this.expectOp('(');
          const n = this.parseExpr();
          const args = [n];
          if (this.acceptOp(',')) { this.acceptOp('#'); args.push(this.parseExpr()); }
          this.expectOp(')');
          return mk(args);
        }
        case 'LBOUND': case 'UBOUND': {
          this.expectOp('(');
          const a = this.next();
          if (a.t !== 'id') this.fail('Expected: array name', a);
          const args = [{ k: 'arrayname', name: a.v, base: a.base, sfx: a.sfx, pos: this.pos(a) }];
          if (this.acceptOp('(')) this.expectOp(')');
          if (this.acceptOp(',')) args.push(this.parseExpr());
          this.expectOp(')');
          return mk(args);
        }
        case 'VARPTR': case 'VARSEG': case 'SADD': case 'VARPTR$': {
          this.expectOp('(');
          const e = this.parseExpr();
          this.expectOp(')');
          return mk([e]);
        }
        case 'EOF': case 'LOC': case 'LOF': case 'FILEATTR': case 'SEEK': {
          this.expectOp('(');
          const args = [];
          this.acceptOp('#');
          args.push(this.parseExpr());
          while (this.acceptOp(',')) args.push(this.parseExpr());
          this.expectOp(')');
          return mk(args);
        }
        case 'PEN': case 'STICK': case 'STRIG': case 'PLAY': case 'FRE': case 'POS': case 'LPOS': case 'IOCTL$':
        case 'ENVIRON$': case 'INP': case 'PEEK': case 'POINT': case 'PMAP': case 'SCREEN':
          return mk(this.parseArgList());
        case 'STRING': case 'INTEGER': case 'LONG': case 'SINGLE': case 'DOUBLE':
          this.fail('Expected: expression', t);
        // eslint-disable-next-line no-fallthrough
        default:
          if (B.BUILTIN_FNS && B.BUILTIN_FNS[name]) {
            const spec = B.BUILTIN_FNS[name];
            if (spec.noArgs) return mk([]);
            return mk(this.parseArgList());
          }
          this.p--;
          this.fail('Expected: expression');
      }
    }

    // ---- statements -----------------------------------------------------------
    parseAssignOrCall() {
      const save = this.p;
      const t = this.tok;
      if (t.v === 'ENDIF') { this.p++; return { k: 'ENDIF' }; } // friendly alias
      let target;
      try {
        target = this.parseRef(false);
      } catch (e) { target = null; }
      if (target && this.isOp('=')) {
        this.p++;
        if (target.k === 'fn') {
          if (target.args.length) this.fail('Expected: statement');
          target = { k: 'var', name: target.name, base: target.base, sfx: target.sfx, display: target.name, pos: target.pos };
        }
        const e = this.parseExpr();
        return { k: 'LET', target, e };
      }
      // Implicit SUB call: Name [arg, arg...]
      this.p = save;
      const nt = this.next();
      if (nt.t !== 'id') this.fail('Expected: statement');
      const args = [];
      if (!this.atStmtEnd()) {
        do args.push(this.parseCallArg()); while (this.acceptOp(','));
      }
      return { k: 'CALL', name: nt.v, base: nt.base, sfx: nt.sfx, args, implicit: true, pos: this.pos(nt) };
    }

    parseCallArg() {
      // Array passed as "name()"
      if (this.tok.t === 'id' && this.isOp('(', 1) && this.isOp(')', 2)) {
        const t = this.next(); this.p += 2;
        return { k: 'arrayname', name: t.v, base: t.base, sfx: t.sfx, pos: this.pos(t) };
      }
      return this.parseExpr();
    }

    parseLvalue() {
      if (this.tok.t !== 'id') this.fail('Expected: variable');
      const r = this.parseRef(false);
      if (r.k === 'fn') this.fail('Expected: variable');
      return r;
    }

    parseTarget() {
      // line number or label
      const t = this.tok;
      if (t.t === 'num') { this.p++; return { lineNo: t.v, pos: this.pos(t) }; }
      if (t.t === 'id') { this.p++; return { label: t.v, pos: this.pos(t) }; }
      this.fail('Expected: line number or label');
    }

    parseType() {
      const t = this.next();
      if (t.t === 'kw' && TYPE_KW[t.v]) {
        const base = TYPE_KW[t.v];
        if (base === 'string' && this.acceptOp('*')) {
          const n = this.tok;
          if (n.t === 'num') { this.p++; return { k: 'fixstr', len: n.v }; }
          if (n.t === 'id') { this.p++; return { k: 'fixstr', constName: n.v }; }
          this.fail('Expected: string length');
        }
        return { k: base };
      }
      if (t.t === 'id') return { k: 'user', name: t.v };
      this.fail('Expected: type', t);
    }

    // DIM / REDIM / STATIC / SHARED / COMMON variable lists
    parseDimList(allowBounds) {
      const vars = [];
      do {
        const t = this.next();
        if (t.t !== 'id') this.fail('Expected: variable name', t);
        const v = { name: t.v, base: t.base, sfx: t.sfx, display: t.name, pos: this.pos(t), dims: null, type: null };
        if (this.isOp('(')) {
          this.p++;
          v.dims = [];
          if (!this.isOp(')')) {
            do {
              if (!allowBounds) { this.parseExpr(); v.dims.push(null); continue; }
              const a = this.parseExpr();
              if (this.acceptKw('TO')) v.dims.push({ lo: a, hi: this.parseExpr() });
              else v.dims.push({ lo: null, hi: a });
            } while (this.acceptOp(','));
          }
          this.expectOp(')');
        }
        if (this.acceptKw('AS')) v.type = this.parseType();
        vars.push(v);
      } while (this.acceptOp(','));
      return vars;
    }

    parseParams() {
      const params = [];
      if (!this.acceptOp('(')) return params;
      if (this.acceptOp(')')) return params;
      do {
        let byval = this.acceptKw('BYVAL');
        const t = this.next();
        if (t.t !== 'id') this.fail('Expected: parameter name', t);
        const prm = { name: t.v, base: t.base, sfx: t.sfx, display: t.name, isArray: false, type: null, byval, pos: this.pos(t) };
        if (this.acceptOp('(')) {
          // optional dimension count (ignored) in DECLARE
          if (this.tok.t === 'num') this.p++;
          this.expectOp(')');
          prm.isArray = true;
        }
        if (this.acceptKw('AS')) prm.type = this.parseType();
        params.push(prm);
      } while (this.acceptOp(','));
      this.expectOp(')');
      return params;
    }

    // Optional args list with possible empty slots:  a, , c
    parseOptArgs(max) {
      const args = [];
      if (this.atStmtEnd()) return args;
      while (true) {
        if (this.isOp(',')) { args.push(null); this.p++; if (this.atStmtEnd()) { args.push(null); break; } continue; }
        args.push(this.parseExpr());
        if (!this.acceptOp(',')) break;
        if (this.atStmtEnd()) { args.push(null); break; }
      }
      if (max && args.length > max) this.fail('Argument-count mismatch');
      return args;
    }

    parseCoord() {
      // [STEP] (x, y)
      const step = this.acceptKw('STEP');
      this.expectOp('(');
      const x = this.parseExpr();
      this.expectOp(',');
      const y = this.parseExpr();
      this.expectOp(')');
      return { step, x, y };
    }

    parseFileNum() {
      // [#]n
      this.acceptOp('#');
      return this.parseExpr();
    }

    // ---- individual statements ----
    st_REM() { return null; }
    st_LET() {
      const target = this.parseLvalue();
      this.expectOp('=');
      return { k: 'LET', target, e: this.parseExpr() };
    }
    st_MID_S() {
      // MID$(var$, start[, len]) = expr
      this.expectOp('(');
      const target = this.parseLvalue();
      this.expectOp(',');
      const start = this.parseExpr();
      let len = null;
      if (this.acceptOp(',')) len = this.parseExpr();
      this.expectOp(')');
      this.expectOp('=');
      return { k: 'MIDSET', target, start, len, e: this.parseExpr() };
    }

    parsePrintItems() {
      const items = [];
      while (!this.atStmtEnd()) {
        if (this.acceptOp(';')) { items.push({ k: 'semi' }); continue; }
        if (this.acceptOp(',')) { items.push({ k: 'comma' }); continue; }
        if (this.isKw('TAB') || this.isKw('SPC')) {
          const kw = this.next().v;
          this.expectOp('(');
          const e = this.parseExpr();
          this.expectOp(')');
          items.push({ k: kw === 'TAB' ? 'tab' : 'spc', e });
          continue;
        }
        if (this.isKw('USING')) this.fail('USING must come first');
        items.push({ k: 'expr', e: this.parseExpr() });
      }
      return items;
    }
    st_PRINT(t) {
      let file = null, using = null;
      if (this.acceptOp('#')) {
        file = this.parseExpr();
        if (!this.acceptOp(',')) { if (!this.atStmtEnd()) this.expectOp(','); }
      }
      if (this.acceptKw('USING')) {
        using = this.parseExpr();
        this.expectOp(';');
      }
      return { k: 'PRINT', file, using, items: this.parsePrintItems() };
    }
    st_LPRINT() {
      let using = null;
      if (this.acceptKw('USING')) { using = this.parseExpr(); this.expectOp(';'); }
      return { k: 'PRINT', lpt: true, file: null, using, items: this.parsePrintItems() };
    }
    st_WRITE() {
      let file = null;
      if (this.acceptOp('#')) { file = this.parseExpr(); if (!this.atStmtEnd()) this.expectOp(','); }
      const items = [];
      while (!this.atStmtEnd()) {
        items.push(this.parseExpr());
        if (!this.acceptOp(',') && !this.acceptOp(';')) break;
      }
      return { k: 'WRITE', file, items };
    }
    st_INPUT() {
      if (this.acceptOp('#')) {
        const file = this.parseExpr();
        this.expectOp(',');
        const vars = [];
        do vars.push(this.parseLvalue()); while (this.acceptOp(','));
        return { k: 'INPUTF', file, vars };
      }
      const noNewline = this.acceptOp(';');
      let prompt = null, qmark = true;
      if (this.tok.t === 'str') {
        prompt = this.next().v;
        if (this.acceptOp(',')) qmark = false;
        else this.expectOp(';');
      }
      const vars = [];
      do vars.push(this.parseLvalue()); while (this.acceptOp(','));
      return { k: 'INPUT', prompt, qmark, noNewline, vars };
    }
    st_LINE(t, inline) {
      if (this.acceptKw('INPUT')) {
        if (this.acceptOp('#')) {
          const file = this.parseExpr();
          this.expectOp(',');
          return { k: 'LINEINPUTF', file, target: this.parseLvalue() };
        }
        const noNewline = this.acceptOp(';');
        let prompt = null;
        if (this.tok.t === 'str') {
          prompt = this.next().v;
          if (!this.acceptOp(';')) this.expectOp(',');
        }
        return { k: 'LINEINPUT', prompt, noNewline, target: this.parseLvalue() };
      }
      // LINE [[STEP](x1,y1)]-[STEP](x2,y2)[,[color][,[B|BF][,style]]]
      let p1 = null;
      if (!this.isOp('-')) p1 = this.parseCoord();
      this.expectOp('-');
      const p2 = this.parseCoord();
      let color = null, box = null, style = null;
      if (this.acceptOp(',')) {
        if (!this.isOp(',') && !this.atStmtEnd()) color = this.parseExpr();
        if (this.acceptOp(',')) {
          if (this.tok.t === 'id' && (this.tok.v === 'B' || this.tok.v === 'BF')) { box = this.next().v; }
          if (this.acceptOp(',')) style = this.parseExpr();
        }
      }
      return { k: 'GLINE', p1, p2, color, box, style };
    }
    st_DIM(t) { const shared = this.acceptKw('SHARED'); return { k: 'DIM', shared, vars: this.parseDimList(true) }; }
    st_REDIM() {
      const preserve = this.acceptKw('PRESERVE');
      const shared = this.acceptKw('SHARED');
      return { k: 'DIM', redim: true, preserve, shared, vars: this.parseDimList(true) };
    }
    st_STATIC() { return { k: 'STATICVARS', vars: this.parseDimList(false) }; }
    st_SHARED() { return { k: 'SHAREDVARS', vars: this.parseDimList(false) }; }
    st_COMMON() {
      const shared = this.acceptKw('SHARED');
      if (this.acceptOp('/')) { this.next(); this.expectOp('/'); }
      return { k: 'COMMON', shared, vars: this.parseDimList(false) };
    }
    st_ERASE() {
      const names = [];
      do {
        const t = this.next();
        if (t.t !== 'id') this.fail('Expected: array name', t);
        names.push({ k: 'arrayname', name: t.v, base: t.base, sfx: t.sfx, pos: this.pos(t) });
        if (this.acceptOp('(')) this.expectOp(')');
      } while (this.acceptOp(','));
      return { k: 'ERASE', names };
    }
    st_CONST() {
      const items = [];
      do {
        const t = this.next();
        if (t.t !== 'id') this.fail('Expected: identifier', t);
        this.expectOp('=');
        items.push({ name: t.v, base: t.base, sfx: t.sfx, display: t.name, e: this.parseExpr(), pos: this.pos(t) });
      } while (this.acceptOp(','));
      return { k: 'CONST', items };
    }
    defType(ty) {
      const ranges = [];
      do {
        const a = this.next();
        if (a.t !== 'id' || a.base.length !== 1) this.fail('Expected: letter range', a);
        let b = a;
        if (this.acceptOp('-')) { b = this.next(); if (b.t !== 'id' || b.base.length !== 1) this.fail('Expected: letter', b); }
        ranges.push([a.base, b.base]);
      } while (this.acceptOp(','));
      return { k: 'DEFTYPE', ty, ranges };
    }
    st_DEFINT() { return this.defType('int'); }
    st_DEFLNG() { return this.defType('long'); }
    st_DEFSNG() { return this.defType('single'); }
    st_DEFDBL() { return this.defType('double'); }
    st_DEFSTR() { return this.defType('string'); }
    st_OPTION() {
      this.expectKw('BASE');
      const n = this.next();
      if (n.t !== 'num' || (n.v !== 0 && n.v !== 1)) this.fail('Expected: 0 or 1', n);
      return { k: 'OPTIONBASE', v: n.v };
    }
    st_DECLARE() {
      const kind = this.next();
      if (kind.t !== 'kw' || (kind.v !== 'SUB' && kind.v !== 'FUNCTION')) this.fail('Expected: SUB or FUNCTION', kind);
      const n = this.next();
      if (n.t !== 'id') this.fail('Expected: name', n);
      if (this.tok.t === 'id' && this.tok.v === 'CDECL') this.p++;
      if (this.tok.t === 'id' && this.tok.v === 'ALIAS') { this.p++; this.p++; }
      const params = this.parseParams();
      return { k: 'DECLARE', kind: kind.v, name: n.v, params };
    }
    st_SUB() {
      const n = this.next();
      if (n.t !== 'id') this.fail('Expected: name', n);
      const params = this.parseParams();
      const isStatic = this.acceptKw('STATIC');
      return { k: 'SUB', name: n.v, base: n.base, sfx: n.sfx, display: n.name, params, isStatic };
    }
    st_FUNCTION() {
      const n = this.next();
      if (n.t !== 'id') this.fail('Expected: name', n);
      const params = this.parseParams();
      const isStatic = this.acceptKw('STATIC');
      return { k: 'FUNCTION', name: n.v, base: n.base, sfx: n.sfx, display: n.name, params, isStatic };
    }
    st_TYPE() {
      const n = this.next();
      if (n.t !== 'id') this.fail('Expected: type name', n);
      // TYPE body: consume following lines until END TYPE
      const fields = [];
      const startPos = this.pos(n);
      if (!this.atEnd()) this.fail('Expected: end-of-statement');
      let li = this.lines.indexOf(this.lineInfo);
      while (true) {
        li++;
        if (li >= this.lines.length) throw new CompileError('TYPE without END TYPE', startPos);
        const L = this.lines[li];
        this.lineInfo = L;
        this.toks = L.tokens;
        this.p = 0;
        if (this.tok.t === 'eol' || this.tok.t === 'rem') continue;
        if (this.isKw('END') && this.isKw('TYPE', 1)) {
          this.p += 2;
          L.consumed = true;
          break;
        }
        const f = this.next();
        if (f.t !== 'id') this.fail('Expected: field name', f);
        this.expectKw('AS');
        const ty = this.parseType();
        fields.push({ name: f.v, display: f.name, type: ty, pos: this.pos(f) });
        if (this.tok.t !== 'eol' && this.tok.t !== 'rem') this.fail('Expected: end-of-statement');
        L.consumed = true;
      }
      // Remaining lines are processed by parseProgram, which skips consumed lines.
      return { k: 'TYPE', name: n.v, display: n.name, fields };
    }
    st_DEF(t) {
      if (this.acceptKw('SEG')) {
        let e = null;
        if (this.acceptOp('=')) e = this.parseExpr();
        return { k: 'DEFSEG', e };
      }
      if (this.tok.t === 'kw' && this.tok.v === 'USR') {
        // DEF USR[n] = addr : accepted and ignored
        this.p++;
        if (this.tok.t === 'num') this.p++;
        this.expectOp('=');
        this.parseExpr();
        return { k: 'NOP' };
      }
      let n = this.next();
      if (n.t === 'id' && n.v === 'FN' && this.tok.t === 'id') {
        const n2 = this.next();
        n = Object.assign({}, n2, { v: 'FN' + n2.v, base: 'FN' + n2.base, name: 'FN' + n2.name });
      }
      if (n.t !== 'id' || !n.base.startsWith('FN')) this.fail('Expected: FNname', n);
      const params = this.parseParams();
      if (this.acceptOp('=')) {
        return { k: 'DEFFN', name: n.v, base: n.base, sfx: n.sfx, display: n.name, params, e: this.parseExpr(), single: true };
      }
      return { k: 'DEFFN', name: n.v, base: n.base, sfx: n.sfx, display: n.name, params, single: false };
    }
    st_END() {
      const t = this.tok;
      if (t.t === 'kw') {
        const map = { IF: 'ENDIF', SELECT: 'ENDSELECT', SUB: 'ENDSUB', FUNCTION: 'ENDFUNCTION', DEF: 'ENDDEF', TYPE: 'ENDTYPE' };
        if (map[t.v]) { this.p++; return { k: map[t.v] }; }
      }
      return { k: 'END' };
    }
    st_EXIT() {
      const t = this.next();
      if (t.t !== 'kw' || !['FOR', 'DO', 'SUB', 'FUNCTION', 'DEF'].includes(t.v)) this.fail('Expected: FOR, DO, SUB, FUNCTION or DEF', t);
      return { k: 'EXIT', what: t.v };
    }
    st_IF(t, inline) {
      const cond = this.parseExpr();
      if (this.acceptKw('GOTO')) {
        const tgt = this.parseTarget();
        const thenList = [{ k: 'GOTO', target: tgt, pos: tgt.pos }];
        let elseList = null;
        if (this.acceptKw('ELSE')) elseList = this.parseElsePart();
        return { k: 'IF1', cond, then: thenList, else: elseList };
      }
      this.expectKw('THEN');
      // Block IF: nothing (or a comment) after THEN
      if (!inline && (this.tok.t === 'eol' || this.tok.t === 'rem')) {
        return { k: 'IFBLOCK', cond };
      }
      let thenList;
      if (this.tok.t === 'num') {
        const n = this.next();
        thenList = [{ k: 'GOTO', target: { lineNo: n.v, pos: this.pos(n) }, pos: this.pos(n) }];
      } else thenList = this.parseInlineList();
      let elseList = null;
      if (this.acceptKw('ELSE')) elseList = this.parseElsePart();
      return { k: 'IF1', cond, then: thenList, else: elseList };
    }
    parseElsePart() {
      if (this.tok.t === 'num') {
        const n = this.next();
        return [{ k: 'GOTO', target: { lineNo: n.v, pos: this.pos(n) }, pos: this.pos(n) }];
      }
      return this.parseInlineList();
    }
    st_ELSEIF() {
      const cond = this.parseExpr();
      this.expectKw('THEN');
      return { k: 'ELSEIF', cond };
    }
    st_ELSE(t, inline) {
      if (inline) this.fail('ELSE without IF');
      return { k: 'ELSE' };
    }
    st_SELECT() {
      this.expectKw('CASE');
      return { k: 'SELECT', e: this.parseExpr() };
    }
    st_CASE() {
      if (this.acceptKw('ELSE')) return { k: 'CASE', isElse: true, tests: [] };
      const tests = [];
      do {
        if (this.acceptKw('IS')) {
          const op = this.next();
          if (op.t !== 'op' || !['=', '<>', '<', '>', '<=', '>='].includes(op.v)) this.fail('Expected: relational operator', op);
          tests.push({ k: 'is', op: op.v, e: this.parseExpr() });
        } else if (this.tok.t === 'op' && ['<', '>', '<=', '>=', '<>', '='].includes(this.tok.v)) {
          // QBasic accepts "CASE < 5" as shorthand for IS
          const op = this.next();
          tests.push({ k: 'is', op: op.v, e: this.parseExpr() });
        } else {
          const a = this.parseExpr();
          if (this.acceptKw('TO')) tests.push({ k: 'range', a, b: this.parseExpr() });
          else tests.push({ k: 'eq', e: a });
        }
      } while (this.acceptOp(','));
      return { k: 'CASE', isElse: false, tests };
    }
    st_DO() {
      let cond = null, until = false;
      if (this.acceptKw('WHILE')) cond = this.parseExpr();
      else if (this.acceptKw('UNTIL')) { cond = this.parseExpr(); until = true; }
      return { k: 'DO', cond, until };
    }
    st_LOOP() {
      let cond = null, until = false;
      if (this.acceptKw('WHILE')) cond = this.parseExpr();
      else if (this.acceptKw('UNTIL')) { cond = this.parseExpr(); until = true; }
      return { k: 'LOOP', cond, until };
    }
    st_WHILE() { return { k: 'WHILE', cond: this.parseExpr() }; }
    st_WEND() { return { k: 'WEND' }; }
    st_FOR() {
      const v = this.parseLvalue();
      this.expectOp('=');
      const from = this.parseExpr();
      this.expectKw('TO');
      const to = this.parseExpr();
      let step = null;
      if (this.acceptKw('STEP')) step = this.parseExpr();
      return { k: 'FOR', v, from, to, step };
    }
    st_NEXT() {
      const vars = [];
      if (!this.atStmtEnd()) {
        do vars.push(this.parseLvalue()); while (this.acceptOp(','));
      }
      return { k: 'NEXT', vars };
    }
    st_GOTO() { return { k: 'GOTO', target: this.parseTarget() }; }
    st_GOSUB() { return { k: 'GOSUB', target: this.parseTarget() }; }
    st_RETURN() {
      if (!this.atStmtEnd()) return { k: 'RETURN', target: this.parseTarget() };
      return { k: 'RETURN', target: null };
    }
    st_ON(t) {
      // ON ERROR GOTO / ON event GOSUB / ON expr GOTO|GOSUB
      if (this.acceptKw('ERROR')) {
        if (this.acceptKw('RESUME')) { this.expectKw('NEXT'); return { k: 'ONERROR', resumeNext: true }; }
        this.expectKw('GOTO');
        const tgt = this.parseTarget();
        return { k: 'ONERROR', target: tgt.lineNo === 0 ? null : tgt };
      }
      const ev = this.tok;
      if (ev.t === 'kw' && ['TIMER', 'KEY', 'PLAY', 'STRIG', 'PEN', 'COM', 'UEVENT'].includes(ev.v) &&
        (ev.v === 'PEN' || ev.v === 'UEVENT' || this.isOp('(', 1))) {
        this.p++;
        let arg = null;
        if (this.acceptOp('(')) { arg = this.parseExpr(); this.expectOp(')'); }
        this.expectKw('GOSUB');
        const tgt = this.parseTarget();
        return { k: 'ONEVENT', ev: ev.v, arg, target: tgt.lineNo === 0 ? null : tgt };
      }
      const e = this.parseExpr();
      let gosub;
      if (this.acceptKw('GOTO')) gosub = false;
      else if (this.acceptKw('GOSUB')) gosub = true;
      else this.fail('Expected: GOTO or GOSUB');
      const targets = [];
      do targets.push(this.parseTarget()); while (this.acceptOp(','));
      return { k: 'ONGO', e, gosub, targets };
    }
    eventCtl(ev) {
      let arg = null;
      if (this.acceptOp('(')) { arg = this.parseExpr(); this.expectOp(')'); }
      const t = this.next();
      if (t.t !== 'kw' || !['ON', 'OFF', 'STOP'].includes(t.v)) this.fail('Expected: ON, OFF or STOP', t);
      return { k: 'EVENTCTL', ev, arg, mode: t.v };
    }
    st_TIMER() { return this.eventCtl('TIMER'); }
    st_PLAY(t) {
      if (this.isKw('ON') || this.isKw('OFF') || this.isKw('STOP')) return this.eventCtl('PLAY');
      return { k: 'SYS', name: 'PLAY', args: [this.parseExpr()] };
    }
    st_STRIG() { return this.eventCtl('STRIG'); }
    st_PEN() { return this.eventCtl('PEN'); }
    st_COM() { return this.eventCtl('COM'); }
    st_UEVENT() { return this.eventCtl('UEVENT'); }
    st_KEY() {
      if (this.isOp('(')) return this.eventCtl('KEY');
      if (this.acceptKw('ON')) return { k: 'SYS', name: 'KEYDISP', args: [{ k: 'num', v: 1, ty: 'int' }] };
      if (this.acceptKw('OFF')) return { k: 'SYS', name: 'KEYDISP', args: [{ k: 'num', v: 0, ty: 'int' }] };
      if (this.acceptKw('LIST')) return { k: 'SYS', name: 'KEYLIST', args: [] };
      const n = this.parseExpr();
      this.expectOp(',');
      return { k: 'SYS', name: 'KEYSET', args: [n, this.parseExpr()] };
    }
    st_RESUME() {
      if (this.acceptKw('NEXT')) return { k: 'RESUME', next: true };
      if (this.atStmtEnd()) return { k: 'RESUME' };
      const tgt = this.parseTarget();
      if (tgt.lineNo === 0) return { k: 'RESUME' };
      return { k: 'RESUME', target: tgt };
    }
    st_ERROR() { return { k: 'ERROR', e: this.parseExpr() }; }
    st_STOP() { return { k: 'STOP' }; }
    st_SYSTEM() { return { k: 'END', system: true }; }
    st_CALL() {
      const n = this.next();
      if (n.t === 'kw' && n.v === 'ABSOLUTE') {
        if (this.isOp('(')) this.parseArgList();
        return { k: 'SYS', name: 'ABSOLUTE', args: [] };
      }
      if (n.t !== 'id') this.fail('Expected: SUB name', n);
      let args = [];
      if (this.acceptOp('(')) {
        if (!this.isOp(')')) {
          do args.push(this.parseCallArg()); while (this.acceptOp(','));
        }
        this.expectOp(')');
      }
      return { k: 'CALL', name: n.v, base: n.base, sfx: n.sfx, args };
    }
    st_SWAP() {
      const a = this.parseLvalue();
      this.expectOp(',');
      return { k: 'SWAP', a, b: this.parseLvalue() };
    }
    st_READ() {
      const vars = [];
      do vars.push(this.parseLvalue()); while (this.acceptOp(','));
      return { k: 'READ', vars };
    }
    st_DATA(t) {
      const d = this.tok;
      let raw = '';
      if (d.t === 'data') { raw = d.v; this.p++; }
      return { k: 'DATA', items: parseDataItems(raw) };
    }
    st_RESTORE() {
      if (this.atStmtEnd()) return { k: 'RESTORE', target: null };
      return { k: 'RESTORE', target: this.parseTarget() };
    }
    st_RANDOMIZE() {
      if (this.atStmtEnd()) return { k: 'SYS', name: 'RANDOMIZE', args: [] };
      return { k: 'SYS', name: 'RANDOMIZE', args: [this.parseExpr()] };
    }
    st_CLS() { return { k: 'SYS', name: 'CLS', args: this.parseOptArgs(1) }; }
    st_COLOR() { return { k: 'SYS', name: 'COLOR', args: this.parseOptArgs(3) }; }
    st_SCREEN() { return { k: 'SYS', name: 'SCREEN', args: this.parseOptArgs(5) }; }
    st_LOCATE() { return { k: 'SYS', name: 'LOCATE', args: this.parseOptArgs(5) }; }
    st_WIDTH() {
      if (this.acceptOp('#')) {
        const f = this.parseExpr(); this.expectOp(',');
        return { k: 'SYS', name: 'WIDTHF', args: [f, this.parseExpr()] };
      }
      if (this.acceptKw('LPRINT')) return { k: 'SYS', name: 'WIDTHLPT', args: [this.parseExpr()] };
      if (this.tok.t === 'str') {
        const dev = this.parseExpr(); this.expectOp(',');
        return { k: 'SYS', name: 'WIDTHDEV', args: [dev, this.parseExpr()] };
      }
      return { k: 'SYS', name: 'WIDTH', args: this.parseOptArgs(2) };
    }
    st_VIEW() {
      if (this.acceptKw('PRINT')) {
        if (this.atStmtEnd()) return { k: 'SYS', name: 'VIEWPRINT', args: [] };
        const a = this.parseExpr();
        this.expectKw('TO');
        return { k: 'SYS', name: 'VIEWPRINT', args: [a, this.parseExpr()] };
      }
      if (this.atStmtEnd()) return { k: 'SYS', name: 'VIEW', args: [] };
      const screen = this.acceptKw('SCREEN');
      const p1 = this.parseCoord();
      this.expectOp('-');
      const p2 = this.parseCoord();
      let color = null, border = null;
      if (this.acceptOp(',')) {
        if (!this.isOp(',') && !this.atStmtEnd()) color = this.parseExpr();
        if (this.acceptOp(',')) border = this.parseExpr();
      }
      return { k: 'SYS', name: 'VIEW', args: [{ k: 'num', v: screen ? 1 : 0, ty: 'int' }, p1.x, p1.y, p2.x, p2.y, color, border] };
    }
    st_WINDOW() {
      if (this.atStmtEnd()) return { k: 'SYS', name: 'WINDOW', args: [] };
      const screen = this.acceptKw('SCREEN');
      const p1 = this.parseCoord();
      this.expectOp('-');
      const p2 = this.parseCoord();
      return { k: 'SYS', name: 'WINDOW', args: [{ k: 'num', v: screen ? 1 : 0, ty: 'int' }, p1.x, p1.y, p2.x, p2.y] };
    }
    st_PSET() { return this.psetLike('PSET'); }
    st_PRESET() { return this.psetLike('PRESET'); }
    psetLike(name) {
      const c = this.parseCoord();
      let color = null;
      if (this.acceptOp(',')) color = this.parseExpr();
      return { k: 'GPOINT', name, p: c, color };
    }
    st_CIRCLE() {
      const c = this.parseCoord();
      this.expectOp(',');
      const r = this.parseExpr();
      let rest = [];
      if (this.acceptOp(',')) rest = this.parseOptArgs(4);
      return { k: 'GCIRCLE', p: c, r, color: rest[0] || null, start: rest[1] || null, end: rest[2] || null, aspect: rest[3] || null };
    }
    st_PAINT() {
      const c = this.parseCoord();
      let rest = [];
      if (this.acceptOp(',')) rest = this.parseOptArgs(3);
      return { k: 'GPAINT', p: c, paint: rest[0] || null, border: rest[1] || null, bg: rest[2] || null };
    }
    st_DRAW() { return { k: 'SYS', name: 'DRAW', args: [this.parseExpr()] }; }
    st_GET() {
      if (this.isOp('#') || (!this.isOp('(') && !this.isKw('STEP'))) {
        const f = this.parseFileNum();
        let rec = null, v = null;
        if (this.acceptOp(',')) {
          if (!this.isOp(',') && !this.atStmtEnd()) rec = this.parseExpr();
          if (this.acceptOp(',')) v = this.parseLvalue();
        }
        return { k: 'FGET', file: f, rec, v };
      }
      const p1 = this.parseCoord();
      this.expectOp('-');
      const p2 = this.parseCoord();
      this.expectOp(',');
      const arr = this.parseGfxArray();
      return { k: 'GGET', p1, p2, arr };
    }
    st_PUT() {
      if (this.isOp('#') || (!this.isOp('(') && !this.isKw('STEP'))) {
        const f = this.parseFileNum();
        let rec = null, v = null;
        if (this.acceptOp(',')) {
          if (!this.isOp(',') && !this.atStmtEnd()) rec = this.parseExpr();
          if (this.acceptOp(',')) v = this.parseExpr();
        }
        return { k: 'FPUT', file: f, rec, v };
      }
      const p = this.parseCoord();
      this.expectOp(',');
      const arr = this.parseGfxArray();
      let action = 'XOR';
      if (this.acceptOp(',')) {
        const a = this.next();
        const v = a.v;
        if (!['PSET', 'PRESET', 'AND', 'OR', 'XOR'].includes(v)) this.fail('Expected: PSET, PRESET, AND, OR or XOR', a);
        action = v;
      }
      return { k: 'GPUT', p, arr, action };
    }
    parseGfxArray() {
      const t = this.next();
      if (t.t !== 'id') this.fail('Expected: array name', t);
      const node = { k: 'arrayname', name: t.v, base: t.base, sfx: t.sfx, pos: this.pos(t), index: null };
      if (this.isOp('(')) {
        const args = this.parseArgList(true);
        if (args.length) node.index = args;
      }
      return node;
    }
    st_PALETTE() {
      if (this.acceptKw('USING')) return { k: 'PALUSING', arr: this.parseGfxArray() };
      return { k: 'SYS', name: 'PALETTE', args: this.parseOptArgs(2) };
    }
    st_PCOPY() { return { k: 'SYS', name: 'PCOPY', args: this.parseOptArgs(2) }; }
    st_BEEP() { return { k: 'SYS', name: 'BEEP', args: [] }; }
    st_SOUND() { return { k: 'SYS', name: 'SOUND', args: this.parseOptArgs(2) }; }
    st_SLEEP() { return { k: 'SYS', name: 'SLEEP', args: this.parseOptArgs(1) }; }
    st_OPEN() {
      const a = this.parseExpr();
      if (this.acceptOp(',')) {
        // GW form: OPEN mode$, [#]n, file$[, reclen]
        this.acceptOp('#');
        const n = this.parseExpr();
        this.expectOp(',');
        const f = this.parseExpr();
        let len = null;
        if (this.acceptOp(',')) len = this.parseExpr();
        return { k: 'OPEN', gw: true, mode: a, num: n, file: f, len };
      }
      let mode = 'RANDOM', access = null, lock = null;
      if (this.acceptKw('FOR')) {
        const m = this.next();
        if (!['INPUT', 'OUTPUT', 'APPEND', 'RANDOM', 'BINARY'].includes(m.v)) this.fail('Expected: INPUT, OUTPUT, APPEND, RANDOM or BINARY', m);
        mode = m.v;
      }
      if (this.acceptKw('ACCESS')) {
        const parts = [];
        while (this.isKw('READ') || this.isKw('WRITE')) parts.push(this.next().v);
        access = parts.join(' ');
      }
      if (this.isKw('LOCK') || (this.tok.t === 'id' && this.tok.v === 'SHARED') || this.isKw('SHARED')) {
        if (this.acceptKw('SHARED')) lock = 'SHARED';
        else {
          this.next();
          const parts = [];
          while (this.isKw('READ') || this.isKw('WRITE')) parts.push(this.next().v);
          lock = 'LOCK ' + parts.join(' ');
        }
      }
      this.expectKw('AS');
      this.acceptOp('#');
      const n = this.parseExpr();
      let len = null;
      if (this.acceptKw('LEN')) { this.expectOp('='); len = this.parseExpr(); }
      return { k: 'OPEN', gw: false, mode, access, lock, num: n, file: a, len };
    }
    st_CLOSE() {
      const nums = [];
      while (!this.atStmtEnd()) {
        this.acceptOp('#');
        nums.push(this.parseExpr());
        if (!this.acceptOp(',')) break;
      }
      return { k: 'CLOSE', nums };
    }
    st_RESET() { return { k: 'CLOSE', nums: [] }; }
    st_FIELD() {
      const f = this.parseFileNum();
      const fields = [];
      while (this.acceptOp(',')) {
        const w = this.parseExpr();
        this.expectKw('AS');
        fields.push({ w, v: this.parseLvalue() });
      }
      return { k: 'FIELD', file: f, fields };
    }
    st_LSET() { const t = this.parseLvalue(); this.expectOp('='); return { k: 'LRSET', right: false, target: t, e: this.parseExpr() }; }
    st_RSET() { const t = this.parseLvalue(); this.expectOp('='); return { k: 'LRSET', right: true, target: t, e: this.parseExpr() }; }
    st_SEEK() {
      const f = this.parseFileNum();
      this.expectOp(',');
      return { k: 'SYS', name: 'SEEK', args: [f, this.parseExpr()] };
    }
    st_LOCK() { return this.lockStmt('LOCK'); }
    st_UNLOCK() { return this.lockStmt('UNLOCK'); }
    lockStmt(name) {
      const f = this.parseFileNum();
      const args = [f];
      if (this.acceptOp(',')) {
        if (!this.isKw('TO')) args.push(this.parseExpr());
        if (this.acceptKw('TO')) args.push(this.parseExpr());
      }
      return { k: 'SYS', name: 'NOP', args };
    }
    st_KILL() { return { k: 'SYS', name: 'KILL', args: [this.parseExpr()] }; }
    st_NAME() {
      const a = this.parseExpr();
      this.expectKw('AS');
      return { k: 'SYS', name: 'NAME', args: [a, this.parseExpr()] };
    }
    st_MKDIR() { return { k: 'SYS', name: 'MKDIR', args: [this.parseExpr()] }; }
    st_RMDIR() { return { k: 'SYS', name: 'RMDIR', args: [this.parseExpr()] }; }
    st_CHDIR() { return { k: 'SYS', name: 'CHDIR', args: [this.parseExpr()] }; }
    st_FILES() { return { k: 'SYS', name: 'FILES', args: this.atStmtEnd() ? [] : [this.parseExpr()] }; }
    st_POKE() { const a = this.parseExpr(); this.expectOp(','); return { k: 'SYS', name: 'POKE', args: [a, this.parseExpr()] }; }
    st_OUT() { const a = this.parseExpr(); this.expectOp(','); return { k: 'SYS', name: 'OUT', args: [a, this.parseExpr()] }; }
    st_WAIT() { return { k: 'SYS', name: 'WAIT', args: this.parseOptArgs(3) }; }
    st_BLOAD() { return { k: 'SYS', name: 'BLOAD', args: this.parseOptArgs(2) }; }
    st_BSAVE() { return { k: 'SYS', name: 'BSAVE', args: this.parseOptArgs(3) }; }
    st_CLEAR() { this.parseOptArgs(3); return { k: 'CLEAR' }; }
    st_CHAIN() {
      const merge = this.acceptKw('MERGE');
      const file = this.parseExpr();
      let line = null, all = false, del = null;
      if (this.acceptOp(',')) {
        if (!this.isOp(',') && !this.atStmtEnd()) line = this.parseExpr();
        if (this.acceptOp(',')) {
          if (this.acceptKw('ALL')) all = true;
          else if (this.tok.t === 'id' && this.tok.v === 'ALL') { this.p++; all = true; }
          if (this.acceptOp(',')) { this.acceptKw('DELETE'); del = this.parseLineRange(); }
        }
      }
      return { k: 'CHAIN', merge, file, line, all, del };
    }
    st_RUN() {
      if (this.atStmtEnd()) return { k: 'RUN' };
      if (this.tok.t === 'num') { const n = this.next(); return { k: 'RUN', line: n.v }; }
      const f = this.parseExpr();
      if (this.acceptOp(',')) this.next(); // ,R
      return { k: 'RUN', file: f };
    }
    st_SHELL() { return { k: 'SYS', name: 'SHELL', args: this.atStmtEnd() ? [] : [this.parseExpr()] }; }
    st_ENVIRON() { return { k: 'SYS', name: 'ENVIRON', args: [this.parseExpr()] }; }
    st_DATE_S() { this.expectOp('='); return { k: 'SYS', name: 'SETDATE', args: [this.parseExpr()] }; }
    st_TIME_S() { this.expectOp('='); return { k: 'SYS', name: 'SETTIME', args: [this.parseExpr()] }; }
    st_TRON() { return { k: 'SYS', name: 'TRON', args: [] }; }
    st_TROFF() { return { k: 'SYS', name: 'TROFF', args: [] }; }
    st_MOTOR() { this.parseOptArgs(1); return { k: 'NOP' }; }
    st_IOCTL() { this.parseFileNum(); this.expectOp(','); this.parseExpr(); return { k: 'SYS', name: 'IOCTL', args: [] }; }
    // GW-BASIC program/direct-mode commands
    parseLineRange() {
      let from = null, to = null, dash = false;
      if (this.tok.t === 'num') from = this.next().v;
      else if (this.isOp('.')) { this.p++; from = '.'; }
      if (this.acceptOp('-')) {
        dash = true;
        if (this.tok.t === 'num') to = this.next().v;
        else if (this.isOp('.')) { this.p++; to = '.'; }
      }
      return { from, to, dash };
    }
    st_LIST() {
      const r = this.parseLineRange();
      let file = null;
      if (this.acceptOp(',')) file = this.parseExpr();
      return { k: 'CMD', cmd: 'LIST', range: r, file };
    }
    st_LLIST() { return { k: 'CMD', cmd: 'LLIST', range: this.parseLineRange() }; }
    st_DELETE() { return { k: 'CMD', cmd: 'DELETE', range: this.parseLineRange() }; }
    st_NEW() { return { k: 'CMD', cmd: 'NEW' }; }
    st_CONT() { return { k: 'CMD', cmd: 'CONT' }; }
    st_LOAD() {
      const f = this.parseExpr();
      let run = false;
      if (this.acceptOp(',')) { this.next(); run = true; }
      return { k: 'CMD', cmd: 'LOAD', file: f, run };
    }
    st_SAVE() {
      const f = this.parseExpr();
      let opt = null;
      if (this.acceptOp(',')) opt = this.next().v;
      return { k: 'CMD', cmd: 'SAVE', file: f, opt };
    }
    st_MERGE() { return { k: 'CMD', cmd: 'MERGE', file: this.parseExpr() }; }
    st_RENUM() {
      const args = [];
      for (let i = 0; i < 3; i++) {
        if (this.tok.t === 'num') args.push(this.next().v); else args.push(null);
        if (!this.acceptOp(',')) break;
      }
      return { k: 'CMD', cmd: 'RENUM', args };
    }
    st_AUTO() {
      const args = [];
      for (let i = 0; i < 2; i++) {
        if (this.tok.t === 'num') args.push(this.next().v); else if (this.isOp('.')) { this.p++; args.push('.'); } else args.push(null);
        if (!this.acceptOp(',')) break;
      }
      return { k: 'CMD', cmd: 'AUTO', args };
    }
    st_EDIT() {
      let n = null;
      if (this.tok.t === 'num') n = this.next().v; else if (this.acceptOp('.')) n = '.';
      return { k: 'CMD', cmd: 'EDIT', line: n };
    }
  }

  /** Split raw DATA text into items: {v: string, quoted: bool} */
  function parseDataItems(raw) {
    const items = [];
    let i = 0;
    const n = raw.length;
    while (true) {
      while (i < n && (raw[i] === ' ' || raw[i] === '\t')) i++;
      if (i < n && raw[i] === '"') {
        let j = i + 1;
        while (j < n && raw[j] !== '"') j++;
        items.push({ v: RC.toCP437(raw.slice(i + 1, j)), quoted: true });
        i = j + 1;
        while (i < n && raw[i] !== ',') i++;
      } else {
        let j = i;
        while (j < n && raw[j] !== ',') j++;
        items.push({ v: RC.toCP437(raw.slice(i, j).replace(/\s+$/, '')), quoted: false });
        i = j;
      }
      if (i < n && raw[i] === ',') { i++; continue; }
      break;
    }
    return items;
  }
  B.parseDataItems = parseDataItems;

  B.Parser = Parser;

  /** Parse an entire source text. Returns flat statement list. Throws CompileError. */
  B.parse = function (src, file, opts) {
    const lines = B.lex(src, file, opts);
    const p = new Parser(lines, file);
    // parseProgram must skip lines consumed by TYPE blocks
    const out = p.out;
    for (let li = 0; li < lines.length; li++) {
      const L = lines[li];
      if (L.consumed) continue;
      p.toks = L.tokens; p.p = 0; p.lineInfo = L;
      p.parseLine();
    }
    return out;
  };

  /** Parse a single immediate-mode line (no line number handling beyond what the lexer does). */
  B.parseLine = function (text, file) {
    return B.parse(text, file || '<immediate>');
  };
})(RC);
