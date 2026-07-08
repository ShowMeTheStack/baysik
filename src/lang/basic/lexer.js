// BASIC lexer: GW-BASIC + QBasic superset.
(function (RC) {
  'use strict';
  const B = RC.Basic;

  const KEYWORDS = (
    'ABS ABSOLUTE ACCESS AND ANY APPEND AS ASC ATN AUTO BASE BEEP BINARY BLOAD BSAVE BYVAL CALL CASE CDBL ' +
    'CHAIN CHDIR CHR$ CINT CIRCLE CLEAR CLNG CLOSE CLS COLOR COM COMMAND$ COMMON CONST CONT COS CSNG CSRLIN CVD CVDMBF ' +
    'CVI CVL CVS CVSMBF DATA DATE$ DECLARE DEF DEFDBL DEFINT DEFLNG DEFSNG DEFSTR DELETE DIM DO DOUBLE DRAW EDIT ELSE ELSEIF END ' +
    'ENVIRON ENVIRON$ EOF EQV ERASE ERDEV ERDEV$ ERL ERR ERROR EXIT EXP FIELD FILEATTR FILES FIX FOR FRE FREEFILE FUNCTION ' +
    'GET GOSUB GOTO HEX$ IF IMP INKEY$ INP INPUT INPUT$ INSTR INT INTEGER IOCTL IOCTL$ IS KEY KILL LBOUND LCASE$ LEFT$ LEN LET ' +
    'LINE LIST LLIST LOAD LOC LOCATE LOCK LOF LOG LONG LOOP LPOS LPRINT LSET LTRIM$ MERGE MID$ MKD$ MKDIR MKDMBF$ MKI$ MKL$ MKS$ ' +
    'MKSMBF$ MOD MOTOR NAME NEW NEXT NOT OCT$ OFF ON OPEN OPTION OR OUT OUTPUT PAINT PALETTE PCOPY PEEK PEN PLAY PMAP POINT ' +
    'POKE POS PRESET PRESERVE PRINT PSET PUT RANDOM RANDOMIZE READ REDIM REM RENUM RESET RESTORE RESUME RETURN RIGHT$ RMDIR RND ' +
    'RSET RTRIM$ RUN SADD SAVE SCREEN SEEK SEG SELECT SGN SHARED SHELL SIN SINGLE SLEEP SOUND SPACE$ SPC SQR STATIC STEP ' +
    'STICK STOP STR$ STRIG STRING STRING$ SUB SWAP SYSTEM TAB TAN THEN TIME$ TIMER TO TROFF TRON TYPE UBOUND UCASE$ UEVENT ' +
    'UNLOCK UNTIL USING USR VAL VARPTR VARPTR$ VARSEG VIEW WAIT WEND WHILE WIDTH WINDOW WRITE XOR'
  ).split(' ');
  const KW = new Set(KEYWORDS);
  B.KEYWORDS = KW;

  function isDigit(c) { return c >= '0' && c <= '9'; }
  function isAlpha(c) { return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'); }
  function isAlnum(c) { return isAlpha(c) || isDigit(c); }

  /**
   * Tokenize one source file.
   * @returns {Array<{tokens: Array, line: number, file: string}>}
   * Token: {t, v, line, col, end, ...}
   *   t: 'num' {v, ty}  'str' {v}  'id' {v (upper, incl. suffix), name (as typed), sfx}
   *      'kw' {v}  'op' {v}  'lineno' {v}  'label' {v}  'rem' {v, meta}  'data' {v}  'eol'
   */
  function lex(src, file, opts) {
    file = file || '';
    const lines = src.replace(/\r\n?/g, '\n').split('\n');
    const out = [];
    const noNum = !!(opts && opts.noLineNumbers);
    for (let ln = 0; ln < lines.length; ln++) {
      const s = lines[ln];
      out.push({ tokens: lexLine(s, ln, file, noNum), line: ln, file });
    }
    return out;
  }

  function lexLine(s, ln, file, noLineNumbers) {
    const toks = [];
    let i = 0;
    const n = s.length;
    const tok = (t, v, col, extra) => {
      const o = { t, v, line: ln, col, end: i, file };
      if (extra) Object.assign(o, extra);
      toks.push(o);
      return o;
    };
    const skipWs = () => { while (i < n && (s[i] === ' ' || s[i] === '\t')) i++; };

    skipWs();
    // Leading line number
    if (i < n && isDigit(s[i]) && !noLineNumbers) {
      const st = i;
      while (i < n && isDigit(s[i])) i++;
      // A line number must be followed by whitespace / end / a non-numeric char
      if (i >= n || !(s[i] === '.' || s[i] === 'E' || s[i] === 'e')) {
        tok('lineno', parseInt(s.slice(st, i), 10), st);
      } else i = st;
    } else if (i < n && isAlpha(s[i])) {
      // Possible alphanumeric label "Name:" at start of line
      let j = i;
      while (j < n && (isAlnum(s[j]) || s[j] === '.')) j++;
      const word = s.slice(i, j).toUpperCase();
      let k = j;
      if (s[k] === ':' && !KW.has(word)) {
        const st = i;
        i = k + 1;
        tok('label', word, st, { name: s.slice(st, j) });
      }
    }

    let afterData = false;
    while (true) {
      skipWs();
      if (i >= n) break;
      const c = s[i];
      const st = i;
      if (afterData) {
        // Raw DATA text up to an unquoted ':'
        let inQ = false;
        while (i < n) {
          if (s[i] === '"') inQ = !inQ;
          else if (s[i] === ':' && !inQ) break;
          i++;
        }
        tok('data', s.slice(st, i), st);
        afterData = false;
        continue;
      }
      if (c === "'") {
        i = n;
        const text = s.slice(st + 1);
        tok('rem', text, st, { meta: parseMeta(text) });
        break;
      }
      if (c === '"') {
        i++;
        let j = i;
        while (j < n && s[j] !== '"') j++;
        const v = RC.toCP437(s.slice(i, j));
        i = j < n ? j + 1 : j;
        tok('str', v, st);
        continue;
      }
      if (isDigit(c) || (c === '.' && i + 1 < n && isDigit(s[i + 1]))) {
        lexNumber(st);
        continue;
      }
      if (c === '&') {
        const c2 = (s[i + 1] || '').toUpperCase();
        if (c2 === 'H' || c2 === 'O' || isDigit(c2)) {
          lexRadix(st);
          continue;
        }
      }
      if (isAlpha(c)) {
        let j = i;
        while (j < n && (isAlnum(s[j]) || s[j] === '.')) j++;
        // Trailing '.' belongs to name in QBasic (e.g. "a." is legal) but avoid swallowing ". " member syntax
        let name = s.slice(i, j);
        let sfx = '';
        if (j < n && '%&!#$'.includes(s[j])) {
          sfx = s[j];
          // "&" could start "&H" literal only after an operator, never directly after a name
          j++;
        }
        const up = name.toUpperCase();
        i = j;
        if (KW.has(up + sfx)) {
          const kw = up + sfx;
          if (kw === 'REM') {
            const text = s.slice(i).replace(/^ /, '');
            tok('rem', text, st, { meta: parseMeta(text), isRem: true });
            i = n;
            break;
          }
          tok('kw', kw, st);
          if (kw === 'DATA') afterData = true;
          continue;
        }
        if (sfx && KW.has(up) && sfx !== '$') {
          // e.g. "LEN%" is not valid; treat as keyword + suffix ignored
        }
        tok('id', up + sfx, st, { name: name + sfx, base: up, sfx });
        continue;
      }
      // Operators
      const two = s.substr(i, 2);
      if (two === '<=' || two === '=<') { i += 2; tok('op', '<=', st); continue; }
      if (two === '>=' || two === '=>') { i += 2; tok('op', '>=', st); continue; }
      if (two === '<>' || two === '><') { i += 2; tok('op', '<>', st); continue; }
      if ('+-*/\\^=<>(),;:#.'.includes(c)) { i++; tok('op', c, st); continue; }
      if (c === '?') { i++; tok('kw', 'PRINT', st, { qmark: true }); continue; }
      if (c === '[' ) { i++; tok('op', '(', st); continue; } // GW-BASIC accepts [] for subscripts
      if (c === ']' ) { i++; tok('op', ')', st); continue; }
      // Unknown character
      i++;
      tok('bad', c, st);
    }
    tok('eol', null, n);
    return toks;

    function lexNumber(st) {
      let j = i;
      let sawDot = false, sawExp = false, expD = false;
      while (j < n && isDigit(s[j])) j++;
      if (s[j] === '.') { sawDot = true; j++; while (j < n && isDigit(s[j])) j++; }
      if (j < n && 'EeDd'.includes(s[j])) {
        let k = j + 1;
        if (s[k] === '+' || s[k] === '-') k++;
        if (k < n && isDigit(s[k])) {
          sawExp = true; expD = s[j] === 'D' || s[j] === 'd';
          j = k; while (j < n && isDigit(s[j])) j++;
        } else if (k === j + 1) {
          // "1E" with no digits => GW treats as 1E0; accept
          sawExp = true; expD = s[j] === 'D' || s[j] === 'd'; j = k;
        }
      }
      let text = s.slice(i, j).replace(/[Dd]/, 'E');
      if (/E$/i.test(text)) text += '0';
      let v = parseFloat(text);
      let ty;
      const sfx = j < n && '%&!#'.includes(s[j]) ? s[j] : '';
      if (sfx) j++;
      const digits = s.slice(i, j).replace(/[^0-9]/g, '').replace(/^0+/, '').length;
      if (sfx === '%') ty = 'int';
      else if (sfx === '&') ty = 'long';
      else if (sfx === '!') ty = 'single';
      else if (sfx === '#') ty = 'double';
      else if (expD) ty = 'double';
      else if (!sawDot && !sawExp) {
        if (v <= 32767) ty = 'int';
        else if (v <= 2147483647) ty = 'long';
        else ty = digits > 7 ? 'double' : 'single';
      } else ty = digits > 7 ? 'double' : 'single';
      if (ty === 'single') v = Math.fround(v);
      i = j;
      tok('num', v, st, { ty, text: s.slice(st, j) });
    }

    function lexRadix(st) {
      let j = i + 1;
      let radix = 8;
      const c2 = s[j].toUpperCase();
      if (c2 === 'H') { radix = 16; j++; } else if (c2 === 'O') { j++; }
      const ds = j;
      const valid = radix === 16 ? /[0-9A-Fa-f]/ : /[0-7]/;
      while (j < n && valid.test(s[j])) j++;
      let v = ds === j ? 0 : parseInt(s.slice(ds, j), radix);
      let ty;
      if (s[j] === '&') { j++; ty = 'long'; if (v > 0x7fffffff) v = v - 0x100000000; }
      else if (s[j] === '%') { j++; ty = 'int'; v = v & 0xffff; if (v > 32767) v -= 65536; }
      else if (v <= 0xffff) { ty = 'int'; if (v > 32767) v -= 65536; }
      else { ty = 'long'; if (v > 0x7fffffff) v = v - 0x100000000; }
      i = j;
      tok('num', v, st, { ty, text: s.slice(st, j) });
    }
  }

  function parseMeta(text) {
    // Metacommands: $STATIC, $DYNAMIC, $INCLUDE: 'file'
    const m = /^\s*\$(STATIC|DYNAMIC|INCLUDE)\b\s*(?::\s*'([^']*)'?)?/i.exec(text);
    if (!m) return null;
    return { cmd: m[1].toUpperCase(), arg: m[2] || null };
  }

  B.lex = lex;
  B.lexLine = lexLine;
})(RC);
