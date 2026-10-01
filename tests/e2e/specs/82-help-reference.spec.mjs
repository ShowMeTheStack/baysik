// Help viewer: opening (F1/toolbar/menu), topics, error messages, search, F1 on words, aliases.
import vm from 'node:vm';
import fs from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const HELP = (() => {
  const RC = {};
  vm.runInNewContext(fs.readFileSync(join(here, '..', '..', '..', 'src', 'lang', 'basic', 'helpdata.js'), 'utf8'), { RC });
  return JSON.parse(JSON.stringify({ K: RC.BASIC_HELP.KEYWORDS, topics: Object.keys(RC.BASIC_HELP.TOPICS), hints: RC.BASIC_HELP.ERROR_HINTS }));
})();
// Copy of help.js ALIASES (private to the module): word -> entry it should open when no direct entry exists.
const ALIASES = {
  'INPUT$': 'INPUT', 'ELSE': 'IF', 'ELSEIF': 'IF', 'THEN': 'IF', 'TO': 'FOR', 'STEP': 'FOR', 'UNTIL': 'DO', 'IS': 'CASE',
  'CLNG': 'CINT', 'CSNG': 'CINT', 'CDBL': 'CINT', 'COS': 'SIN', 'TAN': 'SIN', 'ATN': 'SIN', 'LOG': 'EXP', 'OR': 'AND', 'XOR': 'AND', 'NOT': 'AND',
  'EQV': 'AND', 'IMP': 'AND', 'MKL$': 'MKI$', 'MKS$': 'MKI$', 'MKD$': 'MKI$', 'CVI': 'MKI$', 'CVL': 'MKI$', 'CVS': 'MKI$', 'CVD': 'MKI$',
  'MKSMBF$': 'MKI$', 'MKDMBF$': 'MKI$', 'CVSMBF': 'MKI$', 'CVDMBF': 'MKI$', 'OUT': 'INP', 'WAIT': 'INP', 'POKE': 'PEEK', 'VARSEG': 'VARPTR',
  'SADD': 'VARPTR', 'VARPTR$': 'VARPTR', 'ERL': 'ERR', 'TROFF': 'TRON', 'STRIG': 'STICK', 'CHDIR': 'MKDIR', 'RMDIR': 'MKDIR', 'BSAVE': 'BLOAD',
  'DEFLNG': 'DEFINT', 'DEFSNG': 'DEFINT', 'DEFDBL': 'DEFINT', 'DEFSTR': 'DEFINT', 'BASE': 'OPTION', 'SAVE': 'LOAD', 'MERGE': 'LOAD',
  'LLIST': 'LIST', 'ENVIRON$': 'ENVIRON', 'UBOUND': 'DIM', 'LBOUND': 'DIM', 'PRESERVE': 'REDIM', 'SEG': 'DEF', 'FN': 'DEF', 'ABSOLUTE': 'CALL',
  'ACCESS': 'OPEN', 'APPEND': 'OPEN', 'OUTPUT': 'OPEN', 'RANDOM': 'OPEN', 'BINARY': 'OPEN', 'AS': 'DIM', 'ANY': 'DECLARE', 'BYVAL': 'DECLARE',
  'RESET': 'CLOSE', 'ERDEV': 'ERR', 'IOCTL': 'INP', 'USR': 'CALL',
};
const names = new Set(HELP.K.map((k) => k[0]));

async function closeAll(p) {
  for (let i = 0; i < 5 && await p.modalOpen(); i++) { await p.key('Escape'); await p.sleep(60); }
  await p.closeMenus();
}
async function openHelp(p) {
  await closeAll(p);
  await p.click('#tbHelp');
  p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
}
const h2 = (p) => p.text('.modal .help-main h2');
const navKeys = (p) => p.ev("[...document.querySelectorAll('.modal .help-nav div[data-key]')].map(e => e.dataset.key)");
const setSearch = (p, v) => p.fn((v) => { const i = document.querySelector('.modal .help-nav input'); i.value = v; i.dispatchEvent(new Event('input', { bubbles: true })); }, v);
/** Open a scratch file with `text`, put the cursor at (line, col) in the editor and press F1 there. */
async function f1At(p, text, line, col) {
  await closeAll(p);
  await p.newFile('C:\\MYPROGS\\F1TEST.BAS', text);
  await p.ev(`RC.app.active.editor.focus(); RC.app.active.editor.setCursor(${line}, ${col})`);
  await p.key('F1');
  p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
}
/** Expected nav keys for a search string (mirrors the documented filter: name or description contains it). */
function expectedSearch(q) {
  const Q = q.trim().toUpperCase();
  const cats = {};
  for (const k of HELP.K) (cats[k[1]] = cats[k[1]] || []).push(k);
  const out = [];
  for (const c of Object.keys(cats)) {
    out.push(...cats[c].filter((k) => !Q || k[0].includes(Q) || k[3].toUpperCase().includes(Q)).map((k) => k[0]).sort((a, b) => a.localeCompare(b)));
  }
  return out;
}

export default (t) => {
  // ---- opening ------------------------------------------------------------------------------------------
  t.test('toolbar Help button opens the BASIC Language Reference', async (p) => {
    await openHelp(p);
    p.assert.ok(await p.visible('.modal .help-nav'));
    p.assert.ok(await p.visible('.modal .help-main'));
  });
  t.test('toolbar Help opens on the Screen modes topic', async (p) => {
    await openHelp(p);
    p.assert.equal(await h2(p), 'Screen modes');
    p.assert.deepEqual(await p.texts('.modal .help-nav div.sel'), ['Screen modes']);
  });
  t.test('F1 outside the editor opens the reference', async (p) => {
    await closeAll(p);
    await p.ev('document.activeElement && document.activeElement.blur()');
    await p.key('F1');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    p.assert.equal(await h2(p), 'Screen modes');
  });
  t.test('F1 in the editor on an empty line opens the Screen modes page', async (p) => {
    await f1At(p, 'PRINT 1\n\nPRINT 2', 1, 0);
    p.assert.equal(await h2(p), 'Screen modes');
  });
  t.test('Help ▸ Language Reference opens the reference', async (p) => {
    await closeAll(p);
    await p.menu('Help', 'Language Reference');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
  });
  t.test('the search box gets focus when the reference opens', async (p) => {
    await openHelp(p);
    await p.sleep(80);
    p.assert.equal(await p.ev("document.activeElement && document.activeElement.getAttribute('aria-label')"), 'Search help');
    p.assert.equal(await p.attr('.modal .help-nav input', 'placeholder'), 'Search keywords…');
  });
  t.test('Close button closes the reference', async (p) => {
    await openHelp(p);
    p.assert.deepEqual(await p.texts('.modal-back:last-child .modal-foot button'), ['Close']);
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('Escape closes the reference', async (p) => {
    await openHelp(p);
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
  });

  // ---- nav structure -----------------------------------------------------------------------------------------
  t.test('nav starts with Topics, every topic, then Error messages', async (p) => {
    await openHelp(p);
    const items = await p.ev("[...document.querySelectorAll('.modal .help-nav > div')].map(e => e.className.includes('grp') ? '#' + e.textContent : e.textContent)");
    p.assert.equal(items[0], '#Topics');
    p.assert.deepEqual(items.slice(1, 1 + HELP.topics.length), HELP.topics);
    p.assert.equal(items[1 + HELP.topics.length], 'Error messages');
  });
  t.test('nav has one group per keyword category, in data order', async (p) => {
    await openHelp(p);
    const grps = await p.ev("[...document.querySelectorAll('.modal .help-nav .grp')].map(e => e.textContent)");
    p.assert.deepEqual(grps, ['Topics', ...[...new Set(HELP.K.map((k) => k[1]))]]);
  });
  t.test('nav lists every keyword exactly once, alphabetically within its category', async (p) => {
    await openHelp(p);
    const keys = (await navKeys(p)).filter((k) => !HELP.topics.includes(k) && k !== '__errors');
    p.assert.deepEqual(keys, expectedSearch(''));
    p.assert.equal(keys.length, HELP.K.length);
    p.assert.equal(new Set(keys).size, keys.length);
  });
  t.test('keyword names in the help data are unique', async (p) => {
    p.assert.equal(names.size, HELP.K.length);
    p.assert.equal(await p.ev('RC.BASIC_HELP.KEYWORDS.length'), HELP.K.length);
  });

  // ---- topics ----------------------------------------------------------------------------------------------------
  for (const topic of HELP.topics) {
    t.test(`topic page "${topic}" renders its content`, async (p) => {
      await openHelp(p);
      await p.click(`.modal .help-nav div[data-key="${topic}"]`);
      p.assert.equal(await h2(p), topic);
      const r = await p.fn((topic) => {
        const d = document.createElement('div');
        d.innerHTML = RC.BASIC_HELP.TOPICS[topic];
        const main = document.querySelector('.modal .help-main');
        return { want: d.textContent.trim(), got: main.textContent.slice(main.querySelector('h2').textContent.length).trim() };
      }, topic);
      p.assert.ok(r.want.length > 50);
      p.assert.equal(r.got, r.want);
      p.assert.deepEqual(await p.texts('.modal .help-nav div.sel'), [topic]);
    });
  }
  t.test('Screen modes topic has a table row for every mode', async (p) => {
    await openHelp(p);
    await p.click('.modal .help-nav div[data-key="Screen modes"]');
    const modes = await p.ev("[...document.querySelectorAll('.modal .help-main table tr td:first-child')].map(e => e.textContent)");
    p.assert.deepEqual(modes, ['0', '1', '2', '3', '7', '8', '9', '10', '11', '12', '13']);
  });

  // ---- error messages ---------------------------------------------------------------------------------------------
  t.test('Error messages page lists every error code with its message', async (p) => {
    await openHelp(p);
    await p.click('.modal .help-nav div[data-key="__errors"]');
    p.assert.equal(await h2(p), 'Error messages');
    const rows = await p.ev("[...document.querySelectorAll('.modal .help-main table tr')].map(r => [r.cells[0].textContent, r.cells[1].querySelector('b').textContent])");
    const E = await p.ev('RC.Basic.ERRORS');
    p.assert.deepEqual(rows, Object.keys(E).map((c) => [c, E[c]]));
    p.assert.ok(rows.length >= 50);
    p.assert.deepEqual(await p.texts('.modal .help-nav div.sel'), ['Error messages']);
  });
  t.test('every error hint refers to a real error code', async (p) => {
    const E = await p.ev('RC.Basic.ERRORS');
    for (const c of Object.keys(HELP.hints)) p.assert.ok(E[c], 'hint for unknown code ' + c);
  });
  t.test('Error messages page shows hints exactly for the codes that have one', async (p) => {
    await openHelp(p);
    await p.click('.modal .help-nav div[data-key="__errors"]');
    const withHint = await p.ev("[...document.querySelectorAll('.modal .help-main table tr')].filter(r => r.querySelector('.muted')).map(r => r.cells[0].textContent)");
    p.assert.deepEqual(withHint.sort(), Object.keys(HELP.hints).sort());
  });
  for (const code of Object.keys(HELP.hints)) {
    t.test(`error ${code} row shows its hint`, async (p) => {
      if (!(await p.modalOpen()) || (await h2(p)) !== 'Error messages') {
        await openHelp(p);
        await p.click('.modal .help-nav div[data-key="__errors"]');
      }
      const hint = await p.fn((c) => { const r = [...document.querySelectorAll('.modal .help-main table tr')].find((x) => x.cells[0].textContent === c); return r && r.querySelector('.muted') ? r.querySelector('.muted').textContent : null; }, code);
      p.assert.equal(hint, HELP.hints[code]);
      p.assert.equal(await p.fn((c) => RC.Help.errorHint(+c), code), HELP.hints[code]);
    });
  }
  t.test('codes without a hint have no hint line and errorHint returns null', async (p) => {
    const E = await p.ev('RC.Basic.ERRORS');
    const none = Object.keys(E).filter((c) => !HELP.hints[c]);
    p.assert.ok(none.length > 0);
    for (const c of none) p.assert.equal(await p.fn((c) => RC.Help.errorHint(+c), c), null);
  });

  // ---- search ---------------------------------------------------------------------------------------------------------
  t.test('search filters the nav to matching keywords and hides topics', async (p) => {
    await openHelp(p);
    await setSearch(p, 'CIRCLE');
    const keys = await navKeys(p);
    p.assert.deepEqual(keys, expectedSearch('CIRCLE'));
    p.assert.ok(keys.includes('CIRCLE'));
    p.assert.ok(!keys.includes('Screen modes') && !keys.includes('__errors'));
    p.assert.ok(!(await p.texts('.modal .help-nav .grp')).includes('Topics'));
  });
  t.test('search is case-insensitive', async (p) => {
    await openHelp(p);
    await setSearch(p, 'circle');
    p.assert.deepEqual(await navKeys(p), expectedSearch('CIRCLE'));
  });
  t.test('search matches words in descriptions, not only names', async (p) => {
    await openHelp(p);
    await setSearch(p, 'palette');
    const keys = await navKeys(p);
    p.assert.deepEqual(keys, expectedSearch('palette'));
    p.assert.ok(keys.some((k) => !k.includes('PALETTE')), 'some match via description');
  });
  t.test('search shows only category headings that have matches', async (p) => {
    await openHelp(p);
    await setSearch(p, 'LEFT$');
    const grps = await p.texts('.modal .help-nav .grp');
    const want = [...new Set(HELP.K.filter((k) => expectedSearch('LEFT$').includes(k[0])).map((k) => k[1]))];
    p.assert.deepEqual(grps.map((g) => g.toLowerCase()), want.map((g) => g.toLowerCase()));
  });
  t.test('search with no matches leaves an empty nav (only the search box)', async (p) => {
    await openHelp(p);
    await setSearch(p, 'qqzzxx');
    p.assert.deepEqual(await navKeys(p), []);
    p.assert.equal(await p.count('.modal .help-nav input'), 1);
  });
  t.test('Enter in the search box opens the first match', async (p) => {
    await openHelp(p);
    await setSearch(p, 'CIRCLE');
    await p.ev("document.querySelector('.modal .help-nav input').focus()");
    await p.key('Enter');
    await p.sleep(60);
    const first = expectedSearch('CIRCLE')[0];
    p.assert.equal(await h2(p), first);
    p.assert.equal(await p.modalOpen(), true, 'Enter does not close the dialog');
  });
  t.test('Enter on an exact keyword search opens that keyword', async (p) => {
    await openHelp(p);
    await setSearch(p, 'RANDOMIZE');
    await p.ev("document.querySelector('.modal .help-nav input').focus()");
    await p.key('Enter');
    await p.sleep(60);
    p.assert.equal(await h2(p), expectedSearch('RANDOMIZE')[0]);
    p.assert.ok(expectedSearch('RANDOMIZE').includes('RANDOMIZE'));
  });
  t.test('Enter with no matches keeps the current page', async (p) => {
    await openHelp(p);
    await setSearch(p, 'qqzzxx');
    await p.ev("document.querySelector('.modal .help-nav input').focus()");
    await p.key('Enter');
    await p.sleep(60);
    p.assert.equal(await h2(p), 'Screen modes');
  });
  t.test('clearing the search restores topics and all keywords', async (p) => {
    await openHelp(p);
    await setSearch(p, 'CIRCLE');
    await setSearch(p, '');
    const keys = await navKeys(p);
    p.assert.equal(keys.length, HELP.topics.length + 1 + HELP.K.length);
  });
  t.test('a keyword clicked from search results is highlighted in the nav', async (p) => {
    await openHelp(p);
    await setSearch(p, 'SOUND');
    await p.click('.modal .help-nav div[data-key="SOUND"]');
    p.assert.equal(await h2(p), 'SOUND');
    p.assert.deepEqual(await p.texts('.modal .help-nav div.sel'), ['SOUND']);
  });
  t.test('typing a multi-letter help search with the keyboard keeps focus in the search box', async (p) => {
    await openHelp(p);
    await p.click('.modal .help-nav input');
    await p.type('circ');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), 'circ');
    p.assert.equal(await p.ev("document.activeElement === document.querySelector('.modal .help-nav input')"), true);
    p.assert.deepEqual(await navKeys(p), expectedSearch('circ'));
  });

  // ---- F1 on words in the editor ----------------------------------------------------------------------------------
  const F1_CASES = [
    ['CIRCLE (160, 100), 50', 2, 'CIRCLE'], ['PRINT "hi"', 1, 'PRINT'], ['FOR i = 1 TO 10', 0, 'FOR'], ['x$ = LEFT$("abc", 2)', 7, 'LEFT$'],
    ['SCREEN 13', 3, 'SCREEN'], ['RANDOMIZE TIMER', 2, 'RANDOMIZE'], ['RANDOMIZE TIMER', 12, 'TIMER'], ['  SELECT CASE x', 4, 'SELECT'],
    ['OPEN "A.TXT" FOR OUTPUT AS #1', 0, 'OPEN'], ['k$ = INKEY$', 7, 'INKEY$'], ['SOUND 440, 18', 1, 'SOUND'], ['GOSUB Sub1', 2, 'GOSUB'],
  ];
  for (const [line, col, want] of F1_CASES) {
    t.test(`F1 on "${line.trim().slice(Math.max(0, col - (line.length - line.trimStart().length)), 40)}" at col ${col} opens ${want}`, async (p) => {
      await f1At(p, "' test\n" + line + '\nEND', 1, col);
      p.assert.equal(await h2(p), want);
      p.assert.deepEqual(await p.texts('.modal .help-nav div.sel'), [want]);
    });
  }
  t.test('F1 on a keyword in the middle of a line works with the cursor on its last letter', async (p) => {
    await f1At(p, 'x = 1: PSET (1, 1), 4', 0, 10);
    p.assert.equal(await h2(p), 'PSET');
  });
  t.test('F1 on LOOP opens the LOOP entry, which explains it ends a DO loop', async (p) => {
    await f1At(p, 'DO\n  x = x + 1\nLOOP UNTIL x > 3', 2, 1);
    p.assert.equal(await h2(p), 'LOOP');
    p.assert.match(await p.text('.modal .help-main'), /DO loop/);
  });
  t.test('F1 on UNTIL (alias) opens DO', async (p) => {
    await f1At(p, 'DO\n  x = x + 1\nLOOP UNTIL x > 3', 2, 6);
    p.assert.equal(await h2(p), 'DO');
  });
  t.test('F1 on ELSE (alias) opens IF', async (p) => {
    await f1At(p, 'IF x THEN\n PRINT 1\nELSE\n PRINT 2\nEND IF', 2, 1);
    p.assert.equal(await h2(p), 'IF');
  });
  t.test('F1 on COS (alias) opens SIN', async (p) => {
    await f1At(p, 'y = COS(1)', 0, 5);
    p.assert.equal(await h2(p), 'SIN');
  });
  t.test('F1 on CLNG (alias) opens CINT', async (p) => {
    await f1At(p, 'y& = CLNG(1.5)', 0, 6);
    p.assert.equal(await h2(p), 'CINT');
  });
  t.test('F1 on POKE (alias) opens PEEK', async (p) => {
    await f1At(p, 'POKE 0, 1', 0, 1);
    p.assert.equal(await h2(p), 'PEEK');
  });
  t.test('F1 on UBOUND (alias) opens DIM', async (p) => {
    await f1At(p, 'n = UBOUND(a)', 0, 6);
    p.assert.equal(await h2(p), 'DIM');
  });
  t.test('F1 on an unknown word with no match opens the Screen modes topic', async (p) => {
    await f1At(p, 'zzqxw = 1', 0, 1);
    p.assert.equal(await h2(p), 'Screen modes');
  });
  t.test('F1 on a one-letter variable does not open an unrelated keyword page', async (p) => {
    await f1At(p, 'i = 1', 0, 0);
    const shown = await h2(p);
    p.assert.equal(shown, 'Screen modes', `F1 on variable "i" opened "${shown}"`);
  });
  t.test('editor context menu offers "Help on WORD" which opens that entry', async (p) => {
    await closeAll(p);
    await p.newFile('C:\\MYPROGS\\F1TEST.BAS', 'CIRCLE (10, 10), 5');
    await p.ev("RC.app.editorContextMenu(RC.app.active, { text: 'CIRCLE (10, 10), 5', col: 2, line: 0 }, { preventDefault() {}, clientX: 300, clientY: 300 })");
    await p.wait("!!document.querySelector('.menu-pop')", 3000);
    await p.click('.menu-pop .menu-item', 'Help on CIRCLE');
    p.assert.equal(await p.waitModal(), 'BASIC Language Reference');
    p.assert.equal(await h2(p), 'CIRCLE');
  });

  // ---- alias resolution for every alias -----------------------------------------------------------------------
  for (const [alias, target] of Object.entries(ALIASES)) {
    const want = names.has(alias) ? alias : target;
    t.test(`Help.find("${alias}") resolves to ${want}${names.has(alias) ? ' (own entry)' : ' (alias)'}`, async (p) => {
      p.assert.ok(names.has(target), 'alias target exists: ' + target);
      const got = await p.fn((w) => { const e = RC.Help.find(w); return e && e[0]; }, alias);
      p.assert.equal(got, want);
      const lower = await p.fn((w) => { const e = RC.Help.find(w.toLowerCase()); return e && e[0]; }, alias);
      p.assert.equal(lower, want, 'lower-case lookup');
    });
  }
  t.test('Help.find returns null for empty input', async (p) => {
    p.assert.equal(await p.ev("RC.Help.find('')"), null);
    p.assert.equal(await p.ev('RC.Help.find(null)'), null);
  });
  t.test('Help.open with an alias shows the target page', async (p) => {
    await closeAll(p);
    await p.ev("RC.Help.open(RC.app, 'WEND')");
    await p.waitModal();
    p.assert.equal(await h2(p), 'WEND');
    await closeAll(p);
    await p.ev("RC.Help.open(RC.app, 'xor')");
    await p.waitModal();
    p.assert.equal(await h2(p), 'AND');
    await closeAll(p);
  });
};
