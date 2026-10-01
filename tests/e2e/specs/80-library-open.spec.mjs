// Program Library: opening programs (install to C:\LIBRARY, tab, cursor, explorer, status) and protection.
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
const cardSel = (path) => `.modal .gallery .card[title="${path.replace(/\\/g, '\\\\')}"]`;
const target = (path) => 'C:\\LIBRARY\\' + path;
/** Open a library program by clicking its card in the dialog (category selected, search cleared). */
async function openViaDialog(p, it) {
  await openLib(p);
  await setSearch(p, '');
  await setLevel(p, '*');
  const c = CATALOG.categories.find((x) => x.id === it.cat);
  await p.click('.modal .help-nav div', `${c.name} (${c.count})`);
  await p.click(cardSel(it.path));
  await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(target(it.path))}`, 8000);
  await p.sleep(50);
}
/** Close every open doc without prompting (test cleanup). */
async function closeDocs(p) {
  await p.ev('RC.app.stop()');
  await p.ev(`(() => { const a = RC.app; for (const d of a.docs.slice()) { if (d.dirty) { d.editor.setValue(d.savedText); d.dirty = false; } a.closeDoc(d); } })()`);
  await p.sleep(30);
}
const item = (path) => CATALOG.items.find((i) => i.path === path);
const diskText = (p, path) => p.fn((x) => RC.app.vfs.exists(x) ? RC.app.decodeText(RC.app.vfs.readFile(x)) : null, path);
const explorerRow = (p, name) => p.fn((n) => { const r = [...document.querySelectorAll('#explorerTree .tree-item')].find((e) => e.querySelector('.nm') && e.querySelector('.nm').textContent === n); return r ? { cls: r.className, exp: r.getAttribute('aria-expanded'), title: r.title } : null; }, name);

export default (t) => {
  const HANG = item('GAMES\\HANGMAN.BAS');

  t.test('clicking a card closes the dialog and opens the program as the active tab', async (p) => {
    await openViaDialog(p, HANG);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.activePath(), 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS');
    p.assert.equal(await p.text('#editorTabs .tab.active').then((s) => s.replace(/[◇×\s]/g, '')), 'HANGMAN.BAS');
  }, { fresh: true });
  t.test('the program is installed on C: under C:\\LIBRARY\\<CAT>\\FILE.BAS', async (p) => {
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\LIBRARY')"));
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\LIBRARY\\\\GAMES')"));
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS')"));
    const names = await p.ev("RC.app.vfs.list('C:\\\\LIBRARY\\\\GAMES').map(e => e.name)");
    p.assert.deepEqual(names, ['HANGMAN.BAS'], 'only the chosen program is installed');
  });
  t.test('installed file text equals the library source (CRLF line endings on disk)', async (p) => {
    await openViaDialog(p, HANG);
    const r = await p.ev(`RC.Library.load().then(t => {
      const src = t['GAMES\\\\HANGMAN.BAS'].replace(/\\r?\\n/g, '\\n').replace(/\\n+$/, '');
      const bytes = RC.app.vfs.readFile('C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS');
      const disk = RC.app.decodeText(bytes).replace(/\\n+$/, '');
      const ed = RC.app.active.editor.getValue().replace(/\\n+$/, '');
      let i = 0; while (i < src.length && src[i] === disk[i]) i++;
      return { crlf: Array.from(bytes).some((b, k) => b === 13 && bytes[k + 1] === 10), diskSame: disk === src, edSame: ed === src, at: i, ctx: JSON.stringify([src.slice(i - 5, i + 10), disk.slice(i - 5, i + 10)]) };
    })`);
    p.assert.equal(r.crlf, true, 'CRLF on disk');
    p.assert.equal(r.diskSame, true, 'disk text differs at ' + r.at + ' ' + r.ctx);
  });
  t.test('editor content equals the library source', async (p) => {
    await openViaDialog(p, HANG);
    const src = await p.ev("RC.Library.load().then(t => t['GAMES\\\\HANGMAN.BAS'])");
    p.assert.equal((await p.code()).replace(/\n+$/, ''), src.replace(/\r?\n/g, '\n').replace(/\n+$/, ''));
  });
  t.test('the cursor is at line 1, column 1', async (p) => {
    await openViaDialog(p, HANG);
    p.assert.deepEqual(await p.ev('(() => { const c = RC.app.active.editor.cursor(); return [c.line, c.col]; })()'), [0, 0]);
    p.assert.match(await p.status(), /Ln 1, Col 1/);
  });
  t.test('the top of the file shows the TITLE header with the catalog title', async (p) => {
    await openViaDialog(p, HANG);
    const lines = (await p.code()).split('\n');
    p.assert.match(lines[0], /^' =+$/);
    p.assert.equal(lines[1], "' TITLE:    " + HANG.title);
    p.assert.match(lines.slice(0, 8).join('\n'), new RegExp("' LEVEL:\\s+" + HANG.level));
  });
  t.test('status bar says Opened C:\\LIBRARY\\… — read the comments at the top, then press F5', async (p) => {
    await openViaDialog(p, HANG);
    p.assert.match(await p.status(), /Opened C:\\LIBRARY\\GAMES\\HANGMAN\.BAS — read the comments at the top, then press F5/);
  });
  t.test('explorer expands C:\\LIBRARY and the category folder and highlights the file', async (p) => {
    await openViaDialog(p, HANG);
    p.assert.equal((await explorerRow(p, 'LIBRARY')).exp, 'true');
    p.assert.equal((await explorerRow(p, 'GAMES')).exp, 'true');
    const f = await explorerRow(p, 'HANGMAN.BAS');
    p.assert.ok(f, 'file row visible');
    p.assert.match(f.cls, /selected/);
    p.assert.match(f.title, /^C:\\LIBRARY\\GAMES\\HANGMAN\.BAS \(\d+ bytes\)$/);
  });
  t.test('the tab shows the ◇ protected marker and the full path as tooltip', async (p) => {
    await openViaDialog(p, HANG);
    p.assert.ok(await p.exists('#editorTabs .tab.active .lock'));
    p.assert.equal(await p.attr('#editorTabs .tab.active .lock', 'title'), 'Example/tutorial file: Save makes your own copy');
    p.assert.equal(await p.attr('#editorTabs .tab.active', 'title'), 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS');
  });
  t.test('library paths are protected', async (p) => {
    p.assert.equal(await p.ev("RC.app.isProtected('C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS')"), true);
    p.assert.equal(await p.ev("RC.app.isProtected('c:\\\\library\\\\x.bas')"), true);
    p.assert.equal(await p.ev("RC.app.isProtected('C:\\\\MYPROGS\\\\HANGMAN.BAS')"), false);
  });
  t.test('the opened program is not marked dirty', async (p) => {
    await openViaDialog(p, HANG);
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
    p.assert.ok(!(await p.exists('#editorTabs .tab.active .dirty')));
  });
  t.test('F5 runs the opened library program', async (p) => {
    await openViaDialog(p, HANG);
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await p.waitState(['running', 'waiting']);
    await p.sleep(200);
    p.assert.notEqual(await p.state(), 'error');
    p.assert.match(await p.status(), /Running HANGMAN\.BAS/);
    await p.stopProgram();
  });
  t.test('switching back to a library tab shows the protected-file status hint', async (p) => {
    await p.newFile('C:\\MYPROGS\\OTHER.BAS', 'PRINT 1');
    await p.click('#editorTabs .tab', 'HANGMAN.BAS');
    await p.sleep(80);
    p.assert.match(await p.status(), /Example\/tutorial file — edit and run freely; Save \(Ctrl\+S\) keeps your changes as your own copy/);
  });
  t.test('opening the same program again reuses its tab', async (p) => {
    const n = await p.count('#editorTabs .tab');
    await openViaDialog(p, HANG);
    p.assert.equal(await p.count('#editorTabs .tab'), n);
    p.assert.equal(await p.activePath(), 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS');
  });
  t.test('opening a program from a second category adds its own folder and tab', async (p) => {
    const it = item('MATH\\PRIMES.BAS') || CATALOG.items.find((i) => i.cat === 'MATH');
    await openViaDialog(p, it);
    p.assert.ok(await p.ev(`RC.app.vfs.exists(${JSON.stringify(target(it.path))})`));
    p.assert.equal((await explorerRow(p, 'MATH')).exp, 'true');
    p.assert.ok(await p.ev("RC.app.docs.some(d => d.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS')"));
    const libDirs = await p.ev("RC.app.vfs.list('C:\\\\LIBRARY').map(e => e.name).sort()");
    p.assert.deepEqual(libDirs, ['GAMES', 'MATH']);
  });
  t.test('installed library files survive a page reload', async (p) => {
    await p.reload();
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS')"));
  });
  t.test('clicking the installed file in the explorer reopens it', async (p) => {
    await closeDocs(p);
    await p.ev("RC.app.expandedDirs.add('C:\\\\LIBRARY'); RC.app.expandedDirs.add('C:\\\\LIBRARY\\\\GAMES'); RC.app.renderExplorer()");
    await p.click('#explorerTree .tree-item', 'HANGMAN.BAS');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS'");
    p.assert.match(await p.code(), /TITLE:\s+Hangman/);
  });

  // ---- protection: Save makes a copy -------------------------------------------------------------------
  t.test('Ctrl+S on an edited library program asks to Save Your Copy in C:\\MYPROGS', async (p) => {
    await openViaDialog(p, HANG);
    await p.ev('RC.app.active.editor.focus()');
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.insertText("' my change\n");
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.equal(await p.ev("document.querySelector('.modal input').value"), 'C:\\MYPROGS\\HANGMAN.BAS');
    p.assert.match(await p.modalText(), /your changes are saved as a new file of your own/);
    await p.modalButton('OK');
    await p.wait("RC.app.active.path === 'C:\\\\MYPROGS\\\\HANGMAN.BAS'");
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
    p.assert.match(await diskText(p, 'C:\\MYPROGS\\HANGMAN.BAS'), /^' my change\n' =+/);
    await p.waitToast(/Saved C:\\MYPROGS\\HANGMAN\.BAS/);
  }, { fresh: true });
  t.test('the library original is unchanged after saving a copy', async (p) => {
    const orig = await diskText(p, 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS');
    p.assert.ok(!orig.includes('my change'));
    p.assert.match(orig, /^' =+\n' TITLE:\s+Hangman/);
  });
  t.test('the saved copy is no longer protected (no ◇ on its tab)', async (p) => {
    p.assert.ok(!(await p.exists('#editorTabs .tab.active .lock')));
    p.assert.equal(await p.ev('RC.app.isProtected(RC.app.active.path)'), false);
  });
  t.test('a second copy gets a numbered default name (HANGMAN2.BAS)', async (p) => {
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\HANGMAN.BAS')");
    await p.wait("RC.app.active.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS'");
    await p.ev('RC.app.active.editor.focus()');
    await p.insertText('x');
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.equal(await p.ev("document.querySelector('.modal input').value"), 'C:\\MYPROGS\\HANGMAN2.BAS');
    await p.modalButton('Cancel');
  });
  t.test('cancelling Save Your Copy keeps the library doc dirty at its original path', async (p) => {
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.activePath(), 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    p.assert.ok(!(await diskText(p, 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS')).startsWith('x'));
  });
  t.test('saving a copy into C:\\LIBRARY is refused', async (p) => {
    await p.key('s', { ctrl: true });
    await p.waitModal();
    await p.modalInput('C:\\LIBRARY\\GAMES\\MINE.BAS');
    await p.modalButton('OK');
    await p.waitToast(/Pick a folder outside C:\\SAMPLES, C:\\LIBRARY and C:\\LESSONS/);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\LIBRARY\\\\GAMES\\\\MINE.BAS')"), false);
    p.assert.equal(await p.activePath(), 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS');
  });
  t.test('a relative name in Save Your Copy goes to C:\\MYPROGS', async (p) => {
    await p.key('s', { ctrl: true });
    await p.waitModal();
    await p.modalInput('HANGX');
    await p.modalButton('OK');
    await p.wait("RC.app.active.path === 'C:\\\\MYPROGS\\\\HANGX.BAS'");
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\MYPROGS\\\\HANGX.BAS')"));
  });
  t.test('closing an edited library tab offers Cancel / Discard Changes / Save As My Copy…', async (p) => {
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\HANGMAN.BAS')");
    await p.wait("RC.app.active.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS'");
    await p.ev('RC.app.active.editor.focus()');
    await p.insertText('zz');
    await p.click('#editorTabs .tab.active .x');
    p.assert.equal(await p.waitModal(), 'Keep your changes?');
    p.assert.deepEqual(await p.texts('.modal-back:last-child .modal-foot button'), ['Cancel', 'Discard Changes', 'Save As My Copy…']);
    p.assert.match(await p.modalText(), /You changed HANGMAN\.BAS, which is an example\/tutorial file\. The original stays as it is\./);
    await p.modalButton('Discard Changes');
    await p.sleep(80);
    p.assert.equal(await p.ev("RC.app.docs.some(d => d.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS')"), false);
    p.assert.ok(!(await diskText(p, 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS')).includes('zz'));
  });
  t.test('autosave never writes an edited library file', async (p) => {
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\HANGMAN.BAS')");
    await p.wait("RC.app.active.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS'");
    await p.ev('RC.app.active.editor.focus()');
    await p.insertText('AUTOSAVE_MARK ');
    await p.ev('RC.app.settings.autosave = true; RC.app.autosaveTick(); RC.app.saveAll()');
    p.assert.ok(!(await diskText(p, 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS')).includes('AUTOSAVE_MARK'));
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
    await closeDocs(p);
  });
  t.test('running an edited library program uses the editor text (not the disk copy)', async (p) => {
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\HANGMAN.BAS')");
    await p.wait("RC.app.active.path === 'C:\\\\LIBRARY\\\\GAMES\\\\HANGMAN.BAS'");
    await p.setCode('PRINT "EDITED LIB"');
    await p.ev('RC.app.run()');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /EDITED LIB/);
    p.assert.ok(!(await diskText(p, 'C:\\LIBRARY\\GAMES\\HANGMAN.BAS')).includes('EDITED LIB'));
    await closeDocs(p);
  });

  // ---- API behaviour ----------------------------------------------------------------------------------------
  t.test('Library.open with run=true starts the program right away', async (p) => {
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\HILO.BAS', true)");
    await p.waitState(['running', 'waiting', 'ended']);
    p.assert.equal(await p.activePath(), 'C:\\LIBRARY\\GAMES\\HILO.BAS');
    await p.sleep(200);
    p.assert.notEqual(await p.state(), 'error');
    await p.stopProgram();
  });
  t.test('opening an unknown library path shows a "Could not open program" toast', async (p) => {
    const before = await p.activePath();
    await p.ev("RC.Library.open(RC.app, 'GAMES\\\\NOPE.BAS')");
    await p.waitToast(/Could not open program/);
    p.assert.equal(await p.activePath(), before);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\LIBRARY\\\\GAMES\\\\NOPE.BAS')"), false);
  });
  t.test('library texts decompress to exactly the catalog programs', async (p) => {
    const keys = await p.ev('RC.Library.load().then(t => Object.keys(t).sort())');
    p.assert.deepEqual(keys, CATALOG.items.map((i) => i.path).sort());
  });

  // ---- one program per category via the dialog -------------------------------------------------------------
  for (const c of CATALOG.categories) {
    const it = CATALOG.items.find((i) => i.cat === c.id);
    t.test(`open from dialog (${c.id}): ${it.path} installs, opens at line 1 with its TITLE and expands ${c.id}`, async (p) => {
      await closeDocs(p);
      await openViaDialog(p, it);
      p.assert.ok(await p.ev(`RC.app.vfs.exists(${JSON.stringify(target(it.path))})`));
      p.assert.deepEqual(await p.ev('(() => { const c = RC.app.active.editor.cursor(); return [c.line, c.col]; })()'), [0, 0]);
      const head = (await p.code()).split('\n').slice(0, 10).join('\n');
      p.assert.equal(/TITLE:\s*(.+)/.exec(head)[1].trim(), it.title);
      p.assert.equal(/CATEGORY:\s*(.+)/.exec(head)[1].trim(), c.name);
      p.assert.match(await p.status(), new RegExp('Opened ' + target(it.path).replace(/\\/g, '\\\\').replace('.', '\\.')));
      p.assert.equal((await explorerRow(p, c.id)).exp, 'true');
      p.assert.match((await explorerRow(p, it.path.split('\\')[1])).cls, /selected/);
    });
  }

  // ---- header metadata of every program matches the catalog ------------------------------------------------
  for (const c of CATALOG.categories) {
    t.test(`every ${c.id} program header matches its catalog title, level, category and summary`, async (p) => {
      const bad = await p.fn((cat, catName) => RC.Library.load().then((texts) => RC.LIBRARY.items.filter((it) => it.cat === cat).map((it) => {
        const head = texts[it.path].split(/\r?\n/).slice(0, 12).join('\n');
        const g = (re) => { const m = re.exec(head); return m ? m[1].trim() : null; };
        const ok = g(/TITLE:\s*(.+)/) === it.title && g(/LEVEL:\s*(\S+)/) === it.level && g(/CATEGORY:\s*(.+)/) === catName &&
          it.summary.startsWith(g(/SUMMARY:\s*(.+)/) || '\u0000');
        return ok ? null : it.path;
      }).filter(Boolean)), c.id, c.name);
      p.assert.deepEqual(bad, []);
    });
  }
};
