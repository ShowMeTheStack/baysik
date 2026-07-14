// Help viewer: keyword reference, topics and error explanations.
(function (RC) {
  'use strict';
  const { h } = RC.UI;
  const esc = RC.escapeHtml;

  const ALIASES = {
    'INPUT$': 'INPUT', 'LINE': 'LINE', 'ELSE': 'IF', 'ELSEIF': 'IF', 'THEN': 'IF', 'TO': 'FOR', 'STEP': 'FOR', 'UNTIL': 'DO', 'IS': 'CASE',
    'CLNG': 'CINT', 'CSNG': 'CINT', 'CDBL': 'CINT', 'COS': 'SIN', 'TAN': 'SIN', 'ATN': 'SIN', 'LOG': 'EXP', 'OR': 'AND', 'XOR': 'AND', 'NOT': 'AND',
    'EQV': 'AND', 'IMP': 'AND', 'MKL$': 'MKI$', 'MKS$': 'MKI$', 'MKD$': 'MKI$', 'CVI': 'MKI$', 'CVL': 'MKI$', 'CVS': 'MKI$', 'CVD': 'MKI$',
    'MKSMBF$': 'MKI$', 'MKDMBF$': 'MKI$', 'CVSMBF': 'MKI$', 'CVDMBF': 'MKI$', 'OUT': 'INP', 'WAIT': 'INP', 'POKE': 'PEEK', 'VARSEG': 'VARPTR',
    'SADD': 'VARPTR', 'VARPTR$': 'VARPTR', 'ERL': 'ERR', 'TROFF': 'TRON', 'STRIG': 'STICK', 'CHDIR': 'MKDIR', 'RMDIR': 'MKDIR', 'BSAVE': 'BLOAD',
    'DEFLNG': 'DEFINT', 'DEFSNG': 'DEFINT', 'DEFDBL': 'DEFINT', 'DEFSTR': 'DEFINT', 'BASE': 'OPTION', 'SAVE': 'LOAD', 'MERGE': 'LOAD',
    'LLIST': 'LIST', 'ENVIRON$': 'ENVIRON', 'UBOUND': 'DIM', 'LBOUND': 'DIM', 'PRESERVE': 'REDIM', 'SEG': 'DEF', 'FN': 'DEF', 'ABSOLUTE': 'CALL',
    'ACCESS': 'OPEN', 'APPEND': 'OPEN', 'OUTPUT': 'OPEN', 'RANDOM': 'OPEN', 'BINARY': 'OPEN', 'AS': 'DIM', 'ANY': 'DECLARE', 'BYVAL': 'DECLARE',
    'RESET': 'CLOSE', 'WEND': 'WHILE', 'LOOP': 'DO', 'NEXT': 'FOR', 'ERDEV': 'ERR', 'IOCTL': 'INP', 'USR': 'CALL', 'SHARED': 'SHARED',
  };

  const Help = RC.Help = {
    find(word) {
      if (!word) return null;
      const K = RC.BASIC_HELP.KEYWORDS;
      const w = word.toUpperCase();
      const direct = K.find((k) => k[0] === w) || K.find((k) => k[0] === ALIASES[w]);
      if (direct) return direct;
      return K.find((k) => k[2].toUpperCase().includes(w)) || null;
    },
    errorHint(code) { return RC.BASIC_HELP.ERROR_HINTS[code] || null; },
    renderEntry(k) {
      const [name, cat, syntax, desc, ex] = k;
      return `<h2>${esc(name)}</h2><p class="muted">${esc(cat)}</p><div class="syntax">${esc(syntax)}</div><p>${esc(desc)}</p>` +
        (ex ? `<p><b>Example</b> <button class="small-btn" data-try="1" type="button">Try it</button></p><pre>${esc(ex)}</pre>` : '');
    },
    open(app, word) {
      const K = RC.BASIC_HELP.KEYWORDS;
      const T = RC.BASIC_HELP.TOPICS;
      const main = h('div.help-main');
      const nav = h('div.help-nav');
      const search = h('input', { type: 'text', placeholder: 'Search keywords…', 'aria-label': 'Search help' });
      let current = null;
      const show = (kind, key) => {
        current = { kind, key };
        if (kind === 'topic') main.innerHTML = `<h2>${esc(key)}</h2>` + T[key];
        else if (kind === 'errors') {
          const E = RC.Basic.ERRORS;
          main.innerHTML = '<h2>Error messages</h2><table>' + Object.keys(E).map((c) => `<tr><td>${c}</td><td><b>${esc(E[c])}</b>${Help.errorHint(+c) ? '<br><span class="muted">' + esc(Help.errorHint(+c)) + '</span>' : ''}</td></tr>`).join('') + '</table>';
        } else {
          const k = K.find((x) => x[0] === key);
          main.innerHTML = Help.renderEntry(k);
          const tryBtn = main.querySelector('[data-try]');
          if (tryBtn) tryBtn.addEventListener('click', () => { closeFn(); Help.tryExample(app, k); });
        }
        for (const el of nav.querySelectorAll('div[data-key]')) el.classList.toggle('sel', el.dataset.key === key);
        main.scrollTop = 0;
      };
      const build = () => {
        nav.innerHTML = '';
        nav.appendChild(search);
        const q = search.value.trim().toUpperCase();
        if (!q) {
          nav.appendChild(h('div.grp', 'Topics'));
          for (const t of Object.keys(T)) nav.appendChild(h('div', { 'data-key': t, onclick: () => show('topic', t) }, t));
          nav.appendChild(h('div', { 'data-key': '__errors', onclick: () => show('errors', '__errors') }, 'Error messages'));
        }
        let lastCat = null;
        const cats = {};
        for (const k of K) (cats[k[1]] = cats[k[1]] || []).push(k);
        for (const cat of Object.keys(cats)) {
          const list = cats[cat].filter((k) => !q || k[0].includes(q) || k[3].toUpperCase().includes(q));
          if (!list.length) continue;
          if (lastCat !== cat) { nav.appendChild(h('div.grp', cat)); lastCat = cat; }
          for (const k of list.sort((a, b) => a[0].localeCompare(b[0]))) nav.appendChild(h('div', { 'data-key': k[0], onclick: () => show('kw', k[0]) }, k[0]));
        }
      };
      search.addEventListener('input', build);
      search.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') { const first = nav.querySelector('div[data-key]'); if (first) first.click(); }
      });
      build();
      const entry = Help.find(word);
      if (entry) show('kw', entry[0]); else show('topic', 'Debugging' in T && !word ? 'Screen modes' : Object.keys(T)[0]);
      if (!word) show('topic', 'Screen modes');
      let closeFn = () => {};
      RC.UI.modal({
        title: 'BASIC Language Reference', wide: true, body: h('div.help', nav, main), selectInput: false,
        buttons: [{ label: 'Close', value: null, primary: true }],
        onOpen: (box, c) => { closeFn = () => c(null); setTimeout(() => search.focus(), 30); },
      });
      void current;
    },
    async tryExample(app, k) {
      const vfs = app.vfs;
      if (!vfs.exists('C:\\MYPROGS')) vfs.mkdir('C:\\MYPROGS');
      const p = 'C:\\MYPROGS\\TRY_' + k[0].replace(/[^A-Z0-9]/gi, '').slice(0, 4) + '.BAS';
      vfs.writeFile(p, app.encodeText("' Example for " + k[0] + ' — press F5 to run\n' + k[4] + '\n'), { trusted: true });
      const d = app.docByPath(p);
      if (d) { d.editor.setValue(app.decodeText(vfs.readFile(p))); d.savedText = d.editor.getValue(); d.dirty = false; }
      app.openFile(p);
      app.setStatus('Example opened — press F5 to run it');
    },
  };
})(RC);
