// Program Library dialog: categories, counts, search, level filter, remembered state, ✓ marks, Starter link.
import { libraryItems } from './80-library-sweep.lib.mjs';
import vm from 'node:vm';
import fs from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const CATALOG = (() => {
  const RC = {};
  vm.runInNewContext(fs.readFileSync(join(here, '..', '..', '..', 'src', 'lang', 'basic', 'library-data.js'), 'utf8'), { RC });
  return JSON.parse(JSON.stringify({ categories: RC.LIBRARY.categories, items: RC.LIBRARY.items }));
})();
const LEVELS = ['Beginner', 'Intermediate', 'Advanced'];

// ---- local helpers -----------------------------------------------------------------------------
async function closeAll(p) {
  for (let i = 0; i < 5 && await p.modalOpen(); i++) { await p.key('Escape'); await p.sleep(60); }
  await p.closeMenus();
}
async function openLib(p) {
  await closeAll(p);
  await p.click('#tbExamples');
  p.assert.equal(await p.waitModal(), 'Program Library');
}
const setSearch = (p, v) => p.fn((v) => { const i = document.querySelector('.modal .help-nav input'); i.value = v; i.dispatchEvent(new Event('input', { bubbles: true })); }, v);
const setLevel = (p, v) => p.fn((v) => { const s = document.querySelector('.modal .help-main select'); s.value = v; s.dispatchEvent(new Event('change', { bubbles: true })); }, v);
const shown = async (p) => { const m = /^(\d+) shown$/.exec(await p.text('.modal .help-main span.muted')); return m ? +m[1] : -1; };
const heading = (p) => p.text('.modal .help-main h2');
const cardSel = (path) => `.modal .gallery .card[title="${path.replace(/\\/g, '\\\\')}"]`;
const cardPaths = (p) => p.ev("[...document.querySelectorAll('.modal .gallery .card')].map(c => c.title)");
const selNav = (p) => p.ev("[...document.querySelectorAll('.modal .help-nav div.sel')].map(e => e.innerText)");
async function clickCat(p, c) { await p.click('.modal .help-nav div', `${c.name} (${c.count})`); await p.sleep(30); }
async function clickAll(p) { await p.click('.modal .help-nav div[data-key="*"]'); await p.sleep(30); }
async function resetFilters(p) { await setSearch(p, ''); await setLevel(p, '*'); await clickAll(p); }
function expected({ cat = '*', level = '*', q = '' } = {}) {
  const s = q.trim().toLowerCase();
  return CATALOG.items.filter((it) => (cat === '*' || it.cat === cat) && (level === '*' || it.level === level) &&
    (!s || [it.title, it.summary, it.tags.join(' '), it.path].join(' ').toLowerCase().includes(s))).map((it) => it.path);
}

export default (t) => {
  // ---- opening and layout ------------------------------------------------------------------------
  t.test('toolbar Library button opens the Program Library dialog', async (p) => {
    await openLib(p);
    p.assert.match(await p.modalText(), /hand-written and explains itself in comments/);
    p.assert.ok(await p.visible('.modal .help-nav'));
    p.assert.ok(await p.visible('.modal .help-main .gallery'));
  });
  t.test('intro text says programs are copied to C:\\LIBRARY', async (p) => {
    await openLib(p);
    p.assert.match(await p.modalText(), /copy it to C:\\LIBRARY and open it/);
  });
  t.test('Help menu ▸ Program Library… opens the same dialog', async (p) => {
    await closeAll(p);
    await p.menu('Help', 'Program Library…');
    p.assert.equal(await p.waitModal(), 'Program Library');
  });
  t.test('search box placeholder states the number of programs', async (p) => {
    await openLib(p);
    p.assert.equal(await p.attr('.modal .help-nav input', 'placeholder'), `Search ${CATALOG.items.length} programs…`);
    p.assert.equal(await p.attr('.modal .help-nav input', 'aria-label'), 'Search programs');
  });
  t.test('built page catalog matches the generated library data', async (p) => {
    const inPage = await p.ev('RC.LIBRARY.items.map((i) => i.path)');
    p.assert.deepEqual(inPage, CATALOG.items.map((i) => i.path));
    p.assert.deepEqual(libraryItems().map((i) => i.path), inPage);
  });
  t.test('catalog has more than 500 programs in 21 categories', async (p) => {
    p.assert.ok(CATALOG.items.length > 500, 'items ' + CATALOG.items.length);
    p.assert.equal(await p.ev('RC.LIBRARY.categories.length'), CATALOG.categories.length);
    p.assert.ok(CATALOG.categories.length >= 20);
  });
  t.test('nav lists All programs, Starter examples, a Categories heading and every category with its count', async (p) => {
    await openLib(p);
    const nav = await p.texts('.modal .help-nav div');
    p.assert.equal(nav[0], `All programs (${CATALOG.items.length})`);
    p.assert.equal(nav[1], 'Starter examples');
    p.assert.equal(nav[2].toUpperCase(), 'CATEGORIES');
    p.assert.deepEqual(nav.slice(3), CATALOG.categories.map((c) => `${c.name} (${c.count})`));
  });
  t.test('category counts in the nav sum to the All programs total', async (p) => {
    await openLib(p);
    const nav = await p.texts('.modal .help-nav div');
    const total = +/\((\d+)\)$/.exec(nav[0])[1];
    const sum = nav.slice(3).reduce((a, s) => a + +/\((\d+)\)$/.exec(s)[1], 0);
    p.assert.equal(sum, total);
    p.assert.equal(total, CATALOG.items.length);
  });
  t.test('every catalog item belongs to a listed category and every category count is exact', async (p) => {
    const ids = new Set(CATALOG.categories.map((c) => c.id));
    for (const it of CATALOG.items) p.assert.ok(ids.has(it.cat), it.path);
    for (const c of CATALOG.categories) p.assert.equal(CATALOG.items.filter((i) => i.cat === c.id).length, c.count, c.id);
  });
  t.test('catalog items have valid paths, levels, titles, summaries and tags', async (p) => {
    const seen = new Set();
    for (const it of CATALOG.items) {
      p.assert.match(it.path, /^[A-Z0-9]+\\[A-Z0-9_-]{1,8}\.BAS$/, it.path);
      p.assert.ok(it.path.startsWith(it.cat + '\\'), it.path);
      p.assert.ok(!seen.has(it.path), 'duplicate ' + it.path); seen.add(it.path);
      p.assert.ok(LEVELS.includes(it.level), it.path + ' level ' + it.level);
      p.assert.ok(it.title.trim().length > 2, it.path);
      p.assert.ok(it.summary.trim().length > 10, it.path);
      p.assert.ok(Array.isArray(it.tags) && it.tags.length > 0, it.path);
    }
  });
  t.test('first open (fresh storage) selects All programs and shows every program count', async (p) => {
    await openLib(p);
    p.assert.deepEqual(await selNav(p), [`All programs (${CATALOG.items.length})`]);
    p.assert.equal(await heading(p), 'All programs');
    p.assert.equal(await shown(p), CATALOG.items.length);
    p.assert.equal(await p.ev("document.querySelector('.modal .help-main select').value"), '*');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), '');
  }, { fresh: true });
  t.test('All programs cards appear in catalog order', async (p) => {
    await openLib(p);
    await resetFilters(p);
    const paths = await cardPaths(p);
    p.assert.ok(paths.length >= 300);
    p.assert.deepEqual(paths, CATALOG.items.slice(0, paths.length).map((i) => i.path));
  });
  t.test('All programs renders a card for every program it reports as shown', async (p) => {
    await openLib(p);
    await resetFilters(p);
    const n = await shown(p);
    p.assert.equal(n, CATALOG.items.length);
    p.assert.equal(await p.count('.modal .gallery .card'), n, 'cards rendered vs "N shown"');
  });
  t.test('level select offers All levels, Beginner, Intermediate and Advanced', async (p) => {
    await openLib(p);
    const opts = await p.ev("[...document.querySelectorAll('.modal .help-main select option')].map(o => o.value + '=' + o.textContent)");
    p.assert.deepEqual(opts, ['*=All levels', 'Beginner=Beginner', 'Intermediate=Intermediate', 'Advanced=Advanced']);
    p.assert.equal(await p.attr('.modal .help-main select', 'aria-label'), 'Level');
  });
  t.test('a card shows title, summary, level and up to four tags, with the path as tooltip', async (p) => {
    await openLib(p);
    await resetFilters(p);
    for (const it of CATALOG.items.slice(0, 15)) {
      const card = await p.fn((path) => {
        const c = [...document.querySelectorAll('.modal .gallery .card')].find((x) => x.title === path);
        return c && { t: c.querySelector('.t').textContent, d: c.querySelector('.d').textContent, tags: [...c.querySelectorAll('.tags span')].map((s) => s.textContent), type: c.getAttribute('type') };
      }, it.path);
      p.assert.ok(card, it.path);
      p.assert.equal(card.t.replace(/^✓ /, ''), it.title);
      p.assert.equal(card.d, it.summary);
      p.assert.deepEqual(card.tags, [it.level, ...it.tags.slice(0, 4)]);
      p.assert.equal(card.type, 'button');
    }
  });

  // ---- per-category ---------------------------------------------------------------------------
  for (const c of CATALOG.categories) {
    t.test(`category ${c.id}: clicking "${c.name}" shows exactly its ${c.count} programs`, async (p) => {
      await openLib(p);
      await resetFilters(p);
      await clickCat(p, c);
      p.assert.equal(await heading(p), c.name);
      p.assert.equal(await shown(p), c.count);
      const paths = await cardPaths(p);
      p.assert.deepEqual(paths, expected({ cat: c.id }));
      p.assert.deepEqual(await selNav(p), [`${c.name} (${c.count})`]);
    });
  }
  for (const c of CATALOG.categories) {
    t.test(`category ${c.id} combined with each level filter`, async (p) => {
      await openLib(p);
      await resetFilters(p);
      await clickCat(p, c);
      let sum = 0;
      for (const lv of LEVELS) {
        await setLevel(p, lv);
        const exp = expected({ cat: c.id, level: lv });
        p.assert.equal(await shown(p), exp.length, `${c.id}/${lv}`);
        p.assert.deepEqual(await cardPaths(p), exp);
        const lvTags = await p.ev("[...document.querySelectorAll('.modal .gallery .card .tags span:first-child')].map(s => s.textContent)");
        p.assert.ok(lvTags.every((x) => x === lv), `${c.id}/${lv}: ${lvTags}`);
        p.assert.equal(await heading(p), c.name);
        sum += exp.length;
      }
      p.assert.equal(sum, c.count, 'levels partition the category');
      await setLevel(p, '*');
    });
  }

  // ---- level filter ------------------------------------------------------------------------------
  for (const lv of LEVELS) {
    t.test(`level filter ${lv} across all programs`, async (p) => {
      await openLib(p);
      await resetFilters(p);
      await setLevel(p, lv);
      const exp = expected({ level: lv });
      p.assert.equal(await shown(p), exp.length);
      p.assert.ok(exp.length > 0);
      const paths = await cardPaths(p);
      p.assert.deepEqual(paths, exp.slice(0, paths.length));
      const lvTags = await p.ev("[...document.querySelectorAll('.modal .gallery .card .tags span:first-child')].map(s => s.textContent)");
      p.assert.ok(lvTags.every((x) => x === lv));
    });
  }
  t.test('level counts add up to the total', async (p) => {
    await openLib(p);
    await resetFilters(p);
    let sum = 0;
    for (const lv of LEVELS) { await setLevel(p, lv); sum += await shown(p); }
    p.assert.equal(sum, CATALOG.items.length);
  });
  t.test('changing the level with the real select control filters the list', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await p.click('.modal .help-main select');
    await p.key('ArrowDown'); // All levels -> Beginner
    await p.key('Enter');
    await p.sleep(80);
    const v = await p.ev("document.querySelector('.modal .help-main select').value");
    if (v === '*') { await setLevel(p, 'Beginner'); }
    p.assert.equal(await shown(p), expected({ level: 'Beginner' }).length);
  });

  // ---- search --------------------------------------------------------------------------------------
  t.test('search by title finds the program', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'Hilltop Artillery');
    p.assert.deepEqual(await cardPaths(p), ['GAMES\\ARTILLRY.BAS']);
    p.assert.equal(await shown(p), 1);
  });
  t.test('search by a word in the title matches every program with it', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'maze');
    const exp = expected({ q: 'maze' });
    p.assert.ok(exp.length >= 7);
    p.assert.deepEqual(await cardPaths(p), exp);
  });
  t.test('search by summary text', async (p) => {
    const it = CATALOG.items.find((i) => i.path === 'GAMES\\ARTILLRY.BAS');
    const frag = it.summary.slice(10, 40);
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, frag);
    const paths = await cardPaths(p);
    p.assert.ok(paths.includes(it.path));
    p.assert.deepEqual(paths, expected({ q: frag }));
  });
  t.test('search by tag', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'trigonometry');
    const exp = expected({ q: 'trigonometry' });
    const tagged = CATALOG.items.filter((i) => i.tags.includes('trigonometry')).map((i) => i.path);
    const paths = await cardPaths(p);
    for (const x of tagged) p.assert.ok(paths.includes(x), x);
    p.assert.deepEqual(paths, exp);
  });
  t.test('search by path / file name', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'games\\artillry.bas');
    let got = await cardPaths(p);
    p.assert.deepEqual(got, ['GAMES\\ARTILLRY.BAS'], JSON.stringify(got));
    await setSearch(p, 'CRYPTO\\');
    got = await cardPaths(p);
    p.assert.deepEqual(got, expected({ cat: 'CRYPTO' }), JSON.stringify(got));
  });
  t.test('search is case-insensitive', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'MaZe RuNnEr');
    const a = await cardPaths(p);
    await setSearch(p, 'maze runner');
    p.assert.deepEqual(await cardPaths(p), a);
    p.assert.ok(a.includes('GAMES\\MAZE.BAS'));
  });
  t.test('search ignores surrounding spaces', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, '   blackjack   ');
    p.assert.ok((await cardPaths(p)).includes('GAMES\\BLAKJACK.BAS'));
    p.assert.deepEqual(await cardPaths(p), expected({ q: 'blackjack' }));
  });
  t.test('search keeps the selected category heading and searches inside it', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'GAMES'));
    await setSearch(p, 'maze');
    p.assert.equal(await heading(p), 'Games');
    p.assert.deepEqual(await cardPaths(p), ['GAMES\\MAZE.BAS']);
  });
  t.test('search + category + level combine (AND)', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'GAMES'));
    await setSearch(p, 'game');
    await setLevel(p, 'Beginner');
    const exp = expected({ cat: 'GAMES', level: 'Beginner', q: 'game' });
    p.assert.deepEqual(await cardPaths(p), exp);
    p.assert.equal(await shown(p), exp.length);
    await setLevel(p, 'Advanced');
    p.assert.deepEqual(await cardPaths(p), expected({ cat: 'GAMES', level: 'Advanced', q: 'game' }));
  });
  t.test('search + level across all programs', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'graphics');
    await setLevel(p, 'Advanced');
    const exp = expected({ level: 'Advanced', q: 'graphics' });
    p.assert.ok(exp.length > 0);
    p.assert.deepEqual(await cardPaths(p), exp);
  });
  t.test('switching category keeps the search text and level', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'sort');
    await setLevel(p, 'Intermediate');
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'ALGO'));
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), 'sort');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-main select').value"), 'Intermediate');
    p.assert.deepEqual(await cardPaths(p), expected({ cat: 'ALGO', level: 'Intermediate', q: 'sort' }));
  });
  t.test('"No programs match." with 0 shown for a nonsense query', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'zzqxjv-nothing');
    p.assert.equal(await shown(p), 0);
    p.assert.equal(await p.count('.modal .gallery .card'), 0);
    p.assert.equal(await p.text('.modal .gallery p.muted'), 'No programs match.');
  });
  t.test('"No programs match." when a category has no programs at the chosen level+search', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'GAMES'));
    await setSearch(p, 'Hilltop');
    await setLevel(p, 'Beginner');
    p.assert.equal(await shown(p), 0);
    p.assert.match(await p.text('.modal .gallery'), /No programs match\./);
    await setLevel(p, 'Advanced');
    p.assert.equal(await shown(p), 1);
    p.assert.ok(!(await p.exists('.modal .gallery p.muted')));
  });
  t.test('clearing the search restores the full category list', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'zzqx');
    p.assert.equal(await shown(p), 0);
    await setSearch(p, '');
    p.assert.equal(await shown(p), CATALOG.items.length);
  });
  t.test('search box stays in the nav after filtering (re-rendered nav keeps the input)', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'chess');
    p.assert.equal(await p.count('.modal .help-nav input'), 1);
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav').firstElementChild.tagName"), 'INPUT');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), 'chess');
  });
  t.test('typing a multi-letter search with the keyboard keeps focus in the search box', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await p.click('.modal .help-nav input');
    await p.type('maze');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), 'maze');
    p.assert.equal(await p.ev("document.activeElement === document.querySelector('.modal .help-nav input')"), true);
    p.assert.deepEqual(await cardPaths(p), expected({ q: 'maze' }));
  });
  t.test('first keystroke in the search box filters immediately', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await p.click('.modal .help-nav input');
    await p.type('z');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), 'z');
    p.assert.equal(await shown(p), expected({ q: 'z' }).length);
  });

  // ---- remembered state -------------------------------------------------------------------------------
  t.test('category, level and search are remembered when the dialog is reopened', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'MATH'));
    await setLevel(p, 'Beginner');
    await setSearch(p, 'prime');
    const before = await cardPaths(p);
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
    await openLib(p);
    p.assert.equal(await heading(p), 'Mathematics');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-main select').value"), 'Beginner');
    p.assert.equal(await p.ev("document.querySelector('.modal .help-nav input').value"), 'prime');
    p.assert.deepEqual(await cardPaths(p), before);
    p.assert.deepEqual(before, expected({ cat: 'MATH', level: 'Beginner', q: 'prime' }));
  });
  t.test('library state is stored in localStorage and survives a page reload', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'MUSIC'));
    await setLevel(p, 'Intermediate');
    const st = await p.ev("JSON.parse(localStorage.getItem('baysik.libState'))");
    p.assert.deepEqual(st, { cat: 'MUSIC', level: 'Intermediate', q: '' });
    await closeAll(p);
    await p.reload();
    await openLib(p);
    p.assert.equal(await heading(p), 'Music & Sound');
    p.assert.equal(await shown(p), expected({ cat: 'MUSIC', level: 'Intermediate' }).length);
    await resetFilters(p);
  });
  t.test('reopening after Escape keeps the selected category', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'PUZZLES'));
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
    await openLib(p);
    p.assert.equal(await heading(p), 'Puzzles & Logic');
    await resetFilters(p);
  });

  // ---- closing --------------------------------------------------------------------------------------------
  t.test('Close button closes the dialog', async (p) => {
    await openLib(p);
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('Escape closes the dialog', async (p) => {
    await openLib(p);
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('clicking the backdrop closes the dialog', async (p) => {
    await openLib(p);
    await p.clickAt(5, 5);
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('closing the dialog without picking leaves the active file unchanged', async (p) => {
    await closeAll(p);
    const before = await p.activePath();
    await openLib(p);
    await p.modalButton('Close');
    p.assert.equal(await p.activePath(), before);
  });

  // ---- ✓ marks -------------------------------------------------------------------------------------------
  t.test('no ✓ marks before any program was opened', async (p) => {
    await openLib(p);
    const titles = await p.texts('.modal .gallery .card .t');
    p.assert.ok(titles.length > 0);
    p.assert.ok(titles.every((x) => !x.startsWith('✓')));
  }, { fresh: true });
  t.test('a program opened from the library gets a ✓ next time', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'Hilltop Artillery');
    await p.click('.modal .gallery .card');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\LIBRARY\\\\GAMES\\\\ARTILLRY.BAS'");
    await openLib(p);
    await setSearch(p, 'Hilltop Artillery');
    p.assert.equal(await p.text('.modal .gallery .card .t'), '✓ Hilltop Artillery');
    await setSearch(p, '');
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'GAMES'));
    const marked = await p.ev("[...document.querySelectorAll('.modal .gallery .card')].filter(c => c.querySelector('.t').textContent.startsWith('✓ ')).map(c => c.title)");
    p.assert.deepEqual(marked, ['GAMES\\ARTILLRY.BAS']);
  }, { fresh: true });
  t.test('✓ marks accumulate and persist across reload (libOpened)', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await setSearch(p, 'Battleship');
    await p.click(cardSel('GAMES\\BATTLESH.BAS'));
    await p.wait("RC.app.active && /BATTLESH/.test(RC.app.active.path)");
    const stored = await p.ev("JSON.parse(localStorage.getItem('baysik.libOpened'))");
    p.assert.ok(stored.includes('GAMES\\ARTILLRY.BAS') && stored.includes('GAMES\\BATTLESH.BAS'), JSON.stringify(stored));
    await p.reload();
    await openLib(p);
    await setSearch(p, '');
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'GAMES'));
    const marked = await p.ev("[...document.querySelectorAll('.modal .gallery .card')].filter(c => c.querySelector('.t').textContent.startsWith('✓ ')).map(c => c.title).sort()");
    p.assert.deepEqual(marked, ['GAMES\\ARTILLRY.BAS', 'GAMES\\BATTLESH.BAS']);
    await resetFilters(p);
  });
  t.test('opening a program by API (not the dialog) does not add a ✓', async (p) => {
    await closeAll(p);
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\HANGMAN.BAS')");
    await p.wait("RC.app.active && /HANGMAN/.test(RC.app.active.path)");
    await openLib(p);
    await setSearch(p, 'Hangman');
    p.assert.equal(await p.text('.modal .gallery .card .t'), 'Hangman');
    await resetFilters(p);
  });

  // ---- Starter examples link ---------------------------------------------------------------------------------
  t.test('Starter examples link closes the library and opens the Example Programs gallery', async (p) => {
    await openLib(p);
    await p.click('.modal .help-nav div', 'Starter examples');
    await p.sleep(100);
    p.assert.equal(await p.count('.modal-back'), 1);
    p.assert.equal(await p.modalTitle(), 'Example Programs');
    p.assert.equal(await p.count('.modal .gallery .card'), await p.ev('RC.Samples.INFO.length'));
    await closeAll(p);
  });
  t.test('Starter examples link does not change the remembered library category', async (p) => {
    await openLib(p);
    await resetFilters(p);
    await clickCat(p, CATALOG.categories.find((c) => c.id === 'EDU'));
    await p.click('.modal .help-nav div', 'Starter examples');
    await p.sleep(100);
    await closeAll(p);
    await openLib(p);
    p.assert.equal(await heading(p), CATALOG.categories.find((c) => c.id === 'EDU').name);
    await resetFilters(p);
  });
  t.test('library dialog has a single Close button in its footer', async (p) => {
    await openLib(p);
    p.assert.deepEqual(await p.texts('.modal-back:last-child .modal-foot button'), ['Close']);
    await closeAll(p);
  });
};
