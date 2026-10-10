// Code editor part D: editor tabs, dirty markers, protected files, session restore,
// large files and CP437 round-tripping.
import { open, caret, cur, lines, rendered, closeOthers, cleanAll, typeKeys, undo, select } from './_editor-helpers.mjs';

const DIR = 'C:\\MYPROGS\\';
const tabNames = (p) => p.ev('[...document.querySelectorAll("#editorTabs .tab")].map((t) => t.childNodes[t.querySelector(".lock") ? 1 : 0].textContent)');
const activeTab = (p) => p.ev('(() => { const t = document.querySelector("#editorTabs .tab.active"); return t ? t.title : null; })()');
const tabSel = (name) => `#editorTabs .tab[title="${DIR.replace(/\\/g, '\\\\')}${name}"]`;

/** Write files to disk (setup) and open them by clicking them in the explorer (real UI). */
async function openViaExplorer(p, files) {
  await p.fn((fs) => { for (const [n, txt] of fs) RC.app.vfs.writeFile('C:\\MYPROGS\\' + n, RC.app.encodeText(txt), { trusted: true }); RC.app.renderExplorer(); }, files);
  await p.sleep(300); // let the explorer's debounced re-render settle before clicking
  for (const [n] of files) await clickExplorer(p, n);
}
/** Click a file in the explorer and wait for it to become the active tab (re-clicks if a re-render ate the click). */
async function clickExplorer(p, name) {
  const cond = `RC.app.active && RC.app.active.name === ${JSON.stringify(name)}`;
  for (let i = 0; i < 3; i++) {
    await p.click('#explorerTree .tree-item', name);
    try { await p.wait(cond, 2500); return; } catch (e) { if (i === 2) throw e; }
  }
}
async function closeAll(p) {
  await p.ev('RC.app.docs.forEach((d) => { d.dirty = false; }); [...RC.app.docs].forEach((d) => RC.app.closeDoc(d))');
  await p.sleep(80);
}
const disk = (p, path) => p.fn((x) => RC.app.decodeText(RC.app.vfs.readFile(x)), path);
const diskBytes = (p, path) => p.fn((x) => [...RC.app.vfs.readFile(x)], path);
async function threeTabs(p) {
  await closeAll(p);
  await openViaExplorer(p, [['TA.BAS', 'PRINT "A"'], ['TB.BAS', 'PRINT "B"'], ['TC.BAS', 'PRINT "C"']]);
}
const BIG = Array.from({ length: 2000 }, (_, i) => (i % 100 === 0 ? `Label${i}:` : `PRINT "Line ${i + 1}"; X * ${i}`)).join('\n');

export default (t) => {
  t.beforeEach(async (p) => { await closeOthers(p); await p.ev('RC.app.settings.autosave = false'); });
  t.afterEach(async (p) => { await closeOthers(p); await cleanAll(p); await p.ev('RC.app.settings.autosave = true'); });

  // ---- tabs ----------------------------------------------------------------------------------------------
  t.test('opening three files from the explorer shows three tabs in order', async (p) => {
    await threeTabs(p);
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS', 'TC.BAS']);
  });
  t.test('the most recently opened tab is active and aria-selected', async (p) => {
    p.assert.equal(await activeTab(p), DIR + 'TC.BAS');
    p.assert.equal(await p.attr(tabSel('TC.BAS'), 'aria-selected'), 'true');
    p.assert.equal(await p.attr(tabSel('TA.BAS'), 'aria-selected'), 'false');
    p.assert.equal(await p.count('#editorTabs .tab.active'), 1);
  });
  t.test('clicking a tab switches to that file', async (p) => {
    await p.click(tabSel('TA.BAS'));
    p.assert.equal(await p.activePath(), DIR + 'TA.BAS');
    p.assert.equal(await p.code(), 'PRINT "A"');
    p.assert.equal(await activeTab(p), DIR + 'TA.BAS');
  });
  t.test('clicking a tab focuses its editor', async (p) => {
    await p.click(tabSel('TB.BAS'));
    p.assert.equal(await p.ev('document.activeElement === RC.app.active.editor.ta'), true);
  });
  t.test('only the active tab\'s editor is visible', async (p) => {
    await p.click(tabSel('TC.BAS'));
    const vis = await p.ev('[...document.querySelectorAll("#editors .ed")].filter((e) => e.style.display !== "none").length');
    p.assert.equal(vis, 1);
    p.assert.equal(await p.ev('RC.app.active.editor.root.style.display'), '');
  });
  t.test('tab tooltip is the full file path', async (p) => {
    const titles = await p.ev('[...document.querySelectorAll("#editorTabs .tab")].map((t) => t.title)');
    p.assert.deepEqual(titles, [DIR + 'TA.BAS', DIR + 'TB.BAS', DIR + 'TC.BAS']);
  });
  t.test('each tab has a labelled × close button', async (p) => {
    p.assert.equal(await p.attr(tabSel('TB.BAS') + ' .x', 'aria-label'), 'Close TB.BAS');
    p.assert.equal(await p.text(tabSel('TB.BAS') + ' .x'), '×');
  });
  t.test('status bar shows the active file path', async (p) => {
    await p.click(tabSel('TB.BAS'));
    p.assert.match(await p.status(), /C:\\MYPROGS\\TB\.BAS/);
  });
  t.test('each tab keeps its own caret position', async (p) => {
    await threeTabs(p);
    await p.click(tabSel('TA.BAS'));
    await caret(p, 0, 3);
    await p.click(tabSel('TB.BAS'));
    await caret(p, 0, 7);
    await p.click(tabSel('TA.BAS'));
    p.assert.deepEqual(await cur(p), { line: 0, col: 3 });
    await p.click(tabSel('TB.BAS'));
    p.assert.deepEqual(await cur(p), { line: 0, col: 7 });
  });
  t.test('each tab keeps its own undo history', async (p) => {
    await p.click(tabSel('TA.BAS'));
    await caret(p, 0, 9);
    await typeKeys(p, '1');
    await p.click(tabSel('TB.BAS'));
    await caret(p, 0, 9);
    await typeKeys(p, '2');
    await undo(p);
    p.assert.equal(await p.code(), 'PRINT "B"');
    await p.click(tabSel('TA.BAS'));
    p.assert.equal(await p.code(), 'PRINT "A"1');
  });
  t.test('clicking × closes a clean tab without asking', async (p) => {
    await threeTabs(p);
    await p.click(tabSel('TB.BAS') + ' .x');
    p.assert.equal(await p.modalOpen(), false);
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TC.BAS']);
  });
  t.test('closing the active tab activates the tab to its left', async (p) => {
    await threeTabs(p);
    await p.click(tabSel('TB.BAS'));
    await p.click(tabSel('TB.BAS') + ' .x');
    p.assert.equal(await p.activePath(), DIR + 'TA.BAS');
    p.assert.equal(await activeTab(p), DIR + 'TA.BAS');
  });
  t.test('closing an inactive tab keeps the active tab', async (p) => {
    await threeTabs(p);
    await p.click(tabSel('TA.BAS') + ' .x');
    p.assert.equal(await p.activePath(), DIR + 'TC.BAS');
  });
  t.test('middle-click closes a tab', async (p) => {
    await threeTabs(p);
    const [x, y] = await p.center(tabSel('TA.BAS'));
    await p.clickAt(x, y, { button: 'middle' });
    await p.sleep(60);
    p.assert.deepEqual(await tabNames(p), ['TB.BAS', 'TC.BAS']);
  });
  t.test('Alt+W closes the active tab', async (p) => {
    await threeTabs(p);
    await p.key('w', { alt: true });
    await p.sleep(60);
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS']);
  });
  t.test('File ▸ Close Tab closes the active tab', async (p) => {
    await threeTabs(p);
    await p.menu('File', 'Close Tab');
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS']);
  });
  t.test('opening an already-open file activates its tab instead of duplicating it', async (p) => {
    await threeTabs(p);
    await clickExplorer(p, 'TA.BAS');
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS', 'TC.BAS']);
    p.assert.equal(await p.activePath(), DIR + 'TA.BAS');
  });
  t.test('closing every tab shows the "No open files" hint', async (p) => {
    await threeTabs(p);
    for (const n of ['TA.BAS', 'TB.BAS', 'TC.BAS']) await p.click(tabSel(n) + ' .x');
    p.assert.equal(await p.count('#editorTabs .tab'), 0);
    p.assert.match(await p.text('#editorTabs'), /No open files/);
    p.assert.equal(await p.activePath(), null);
  });

  // ---- dirty marker ---------------------------------------------------------------------------------------
  t.test('typing shows the unsaved-changes dot on the tab', async (p) => {
    await threeTabs(p);
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), false);
    await caret(p, 0, 0);
    await typeKeys(p, 'CLS: ');
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), true);
    p.assert.equal(await p.attr(tabSel('TC.BAS') + ' .dirty', 'title'), 'Unsaved changes');
  });
  t.test('only the edited tab gets a dirty dot', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 0);
    await typeKeys(p, 'X');
    p.assert.equal(await p.count('#editorTabs .tab .dirty'), 1);
    p.assert.equal(await p.exists(tabSel('TA.BAS') + ' .dirty'), false);
  });
  t.test('Ctrl+S saves the file and removes the dot', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 0);
    await typeKeys(p, 'CLS: ');
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), true);
    await p.key('s', { ctrl: true });
    await p.sleep(60);
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), false);
    p.assert.equal(await disk(p, DIR + 'TC.BAS'), 'CLS: PRINT "C"');
    p.assert.match(await p.status(), /Saved C:\\MYPROGS\\TC\.BAS/);
  });
  t.test('undoing back to the saved text removes the dot', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 9);
    await typeKeys(p, 'X');
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), true);
    await undo(p);
    p.assert.equal(await p.code(), 'PRINT "C"');
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), false);
  });
  t.test('closing a dirty tab asks to save', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 9);
    await typeKeys(p, 'Z');
    await p.click(tabSel('TC.BAS') + ' .x');
    p.assert.equal(await p.waitModal(), 'Unsaved changes');
    p.assert.match(await p.modalText(), /Save changes to TC\.BAS\?/);
    p.assert.deepEqual(await p.texts('.modal-back .modal-foot button'), ['Cancel', "Don't Save", 'Save As…', 'Save']);
  });
  async function dirtyClose(p) {
    await threeTabs(p);
    await caret(p, 0, 9);
    await typeKeys(p, 'Z');
    await p.click(tabSel('TC.BAS') + ' .x');
    await p.waitModal();
  }
  t.test('Cancel in the unsaved dialog keeps the tab open and dirty', async (p) => {
    await dirtyClose(p);
    await p.modalButton('Cancel');
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS', 'TC.BAS']);
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), true);
  });
  t.test("Don't Save closes the tab and leaves the file unchanged", async (p) => {
    await dirtyClose(p);
    await p.modalButton("Don't Save");
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS']);
    p.assert.equal(await disk(p, DIR + 'TC.BAS'), 'PRINT "C"');
  });
  t.test('Save in the unsaved dialog writes the file and closes the tab', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 9);
    await typeKeys(p, '!');
    await p.click(tabSel('TC.BAS') + ' .x');
    await p.waitModal();
    await p.fn(() => [...document.querySelectorAll('.modal-back .modal-foot button')].find((b) => b.innerText === 'Save').click());
    await p.waitGone('.modal-back');
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS']);
    p.assert.equal(await disk(p, DIR + 'TC.BAS'), 'PRINT "C"!');
  });
  t.test('middle-click on a dirty tab also asks before closing', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 0);
    await typeKeys(p, 'X');
    const [x, y] = await p.center(tabSel('TC.BAS'));
    await p.clickAt(x, y, { button: 'middle' });
    p.assert.equal(await p.waitModal(), 'Unsaved changes');
    await p.modalButton('Cancel');
  });
  t.test('autosave saves edits after a few seconds and clears the dot', async (p) => {
    await threeTabs(p);
    await caret(p, 0, 0);
    await typeKeys(p, 'CLS: ');
    p.assert.equal(await p.exists(tabSel('TC.BAS') + ' .dirty'), true);
    await p.ev('RC.app.settings.autosave = true');
    await p.wait('!document.querySelector(' + JSON.stringify(tabSel('TC.BAS') + ' .dirty') + ')', 7000);
    p.assert.equal(await disk(p, DIR + 'TC.BAS'), 'CLS: PRINT "C"');
  }, { timeout: 15000 });

  // ---- protected files ---------------------------------------------------------------------------------------
  t.test('an example file tab shows the ◇ marker with an explanation', async (p) => {
    await clickExplorer(p, 'GUESS.BAS');
    const sel = '#editorTabs .tab[title="C:\\\\SAMPLES\\\\GUESS.BAS"]';
    p.assert.equal(await p.text(sel + ' .lock'), '◇');
    p.assert.match(await p.attr(sel + ' .lock', 'title'), /Example\/tutorial file/);
  });
  t.test('user files have no ◇ marker', async (p) => {
    await threeTabs(p);
    await openGuess(p);
    p.assert.equal(await p.exists(tabSel('TA.BAS') + ' .lock'), false);
    p.assert.equal(await p.count('#editorTabs .tab .lock'), 1);
  });
  t.test('an example file shows a status-bar note about saving a copy', async (p) => {
    await openGuess(p);
    p.assert.match(await p.status(), /Example\/tutorial file/);
  });
  async function openGuess(p) { await clickExplorer(p, 'GUESS.BAS'); }
  t.test('Ctrl+S on an example file asks for a name for your own copy', async (p) => {
    await openGuess(p);
    await caret(p, 0, 0);
    await typeKeys(p, "' mine\n");
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.match(await p.ev('document.querySelector(".modal-back input").value'), /^C:\\MYPROGS\\GUESS\d*\.BAS$/);
    await p.modalButton('Cancel');
  });
  t.test('closing an edited example file asks "Keep your changes?" and Discard keeps the original', async (p) => {
    await openGuess(p);
    await caret(p, 0, 0);
    await typeKeys(p, "' mine");
    const orig = await disk(p, 'C:\\SAMPLES\\GUESS.BAS');
    await p.click('#editorTabs .tab[title="C:\\\\SAMPLES\\\\GUESS.BAS"] .x');
    p.assert.equal(await p.waitModal(), 'Keep your changes?');
    p.assert.deepEqual(await p.texts('.modal-back .modal-foot button'), ['Cancel', 'Discard Changes', 'Save As My Copy…']);
    await p.modalButton('Discard Changes');
    p.assert.equal(await p.exists('#editorTabs .tab[title="C:\\\\SAMPLES\\\\GUESS.BAS"]'), false);
    p.assert.equal(await disk(p, 'C:\\SAMPLES\\GUESS.BAS'), orig);
  });

  // ---- session restore ---------------------------------------------------------------------------------------
  t.test('open tabs are restored after a reload', async (p) => {
    await threeTabs(p);
    await cleanAll(p);
    await p.reload();
    p.assert.deepEqual(await tabNames(p), ['TA.BAS', 'TB.BAS', 'TC.BAS']);
  });
  t.test('the active tab is restored after a reload', async (p) => {
    await p.click(tabSel('TB.BAS'));
    await p.reload();
    p.assert.equal(await p.activePath(), DIR + 'TB.BAS');
    p.assert.equal(await activeTab(p), DIR + 'TB.BAS');
    p.assert.equal(await p.code(), 'PRINT "B"');
  });
  t.test('a closed tab is not restored after a reload', async (p) => {
    await p.click(tabSel('TA.BAS') + ' .x');
    await p.reload();
    p.assert.deepEqual(await tabNames(p), ['TB.BAS', 'TC.BAS']);
  });
  t.test('saved edits are shown after a reload', async (p) => {
    await p.click(tabSel('TC.BAS'));
    await caret(p, 0, 9);
    await typeKeys(p, ': BEEP');
    await p.key('s', { ctrl: true });
    await p.reload();
    await p.click(tabSel('TC.BAS'));
    p.assert.equal(await p.code(), 'PRINT "C": BEEP');
  });
  t.test('a file deleted from disk is skipped when restoring', async (p) => {
    await p.ev('RC.app.vfs.unlink("C:\\\\MYPROGS\\\\TB.BAS")');
    await p.reload();
    p.assert.deepEqual(await tabNames(p), ['TC.BAS']);
  });

  // ---- large files -------------------------------------------------------------------------------------------
  t.test('a 2000-line file renders every line and gutter number', async (p) => {
    await open(p, BIG, { line: 0 });
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.children.length'), 2000);
    p.assert.equal(await p.ev('RC.app.active.editor.inner.children.length'), 2000);
    p.assert.equal(await p.ev('RC.app.active.editor.inner.lastElementChild.textContent'), '2000');
  });
  t.test('typing in a 2000-line file stays responsive', async (p) => {
    await open(p, BIG, { line: 1000, col: 0 });
    const t0 = Date.now();
    await typeKeys(p, 'X = 12345: ');
    const ms = Date.now() - t0;
    p.assert.equal((await lines(p))[1000].startsWith('X = 12345: '), true);
    p.assert.ok(ms < 3000, 'typing 11 keys took ' + ms + 'ms');
    const renderMs = await p.ev('(() => { const t = performance.now(); RC.app.active.editor.render(); return performance.now() - t; })()');
    p.assert.ok(renderMs < 300, 'render took ' + renderMs + 'ms');
  });
  t.test('Enter in a 2000-line file adds a gutter line', async (p) => {
    await open(p, BIG, { line: 1500, col: 0 });
    await p.key('Enter');
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.inner.children.length'), 2001);
  });
  t.test('Go to Line 1500 scrolls the line into view', async (p) => {
    await open(p, BIG, { line: 0 });
    await p.key('g', { ctrl: true });
    await p.waitModal();
    await p.wait('document.activeElement && document.activeElement.tagName === "INPUT"');
    await typeKeys(p, '1500');
    await p.key('Enter');
    await p.sleep(100);
    p.assert.equal((await cur(p)).line, 1499);
    const vis = await p.ev('(() => { const e = RC.app.active.editor; const top = 1499 * e.lineHeight; return top >= e.ta.scrollTop && top < e.ta.scrollTop + e.ta.clientHeight; })()');
    p.assert.equal(vis, true);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.scrollTop === RC.app.active.editor.ta.scrollTop'), true);
  });
  t.test('Go to a label near the end of a 2000-line file', async (p) => {
    await open(p, BIG, { line: 0 });
    await p.key('g', { ctrl: true });
    await p.waitModal();
    await p.wait('document.activeElement && document.activeElement.tagName === "INPUT"');
    await typeKeys(p, 'Label1900');
    await p.key('Enter');
    await p.sleep(100);
    p.assert.equal((await cur(p)).line, 1900);
  });
  t.test('find in a 2000-line file counts every match and reveals it', async (p) => {
    await open(p, BIG, { line: 1800, col: 0 });
    await p.key('f', { ctrl: true });
    await typeKeys(p, 'Line 1999"');
    await p.key('Enter');
    p.assert.equal(await p.text('#findbar .info'), '1 of 1');
    p.assert.equal((await cur(p)).line, 1998);
    await p.ev('document.querySelector("#findbar input[aria-label=Find]").select()');
    await typeKeys(p, 'PRINT');
    await p.key('Enter');
    p.assert.match(await p.text('#findbar .info'), / of 1980$/);
    await p.key('Escape');
  });
  t.test('toggle comment on all 2000 lines finishes within 2 seconds', async (p) => {
    await open(p, BIG);
    await select(p, 0, 0, 1999, 5);
    const t0 = Date.now();
    await p.key('/', { ctrl: true });
    const ms = Date.now() - t0;
    const l = await lines(p);
    await open(p, ''); // drop the huge undo history before asserting (keeps failure recovery fast)
    p.assert.ok(l.every((x) => x.startsWith("' ")), 'all commented');
    p.assert.ok(ms < 2000, 'toggling took ' + ms + 'ms');
  });
  t.test('outline of a 2000-line file lists all its labels', async (p) => {
    await open(p, BIG);
    await p.ev('RC.app.renderOutline()');
    p.assert.equal(await p.count('#procList .proc-item'), 21);
  });

  // ---- CP437 characters -----------------------------------------------------------------------------------------
  const CP = 'PRINT "╔═╗║░▒▓☺"';
  t.test('box-drawing and block characters can be typed and are displayed', async (p) => {
    await open(p, '', { path: DIR + 'CP437.BAS' });
    await typeKeys(p, CP);
    p.assert.equal(await p.code(), CP);
    await rendered(p);
    p.assert.equal(await p.ev('RC.app.active.editor.hl.children[0].querySelector(".s-str").textContent'), '"╔═╗║░▒▓☺"');
  });
  t.test('saving writes the characters as CP437 bytes', async (p) => {
    await p.key('s', { ctrl: true });
    await p.sleep(50);
    const b = await diskBytes(p, DIR + 'CP437.BAS');
    p.assert.deepEqual(b.slice(7, 15), [0xC9, 0xCD, 0xBB, 0xBA, 0xB0, 0xB1, 0xB2, 0x01]);
    p.assert.equal(b.length, CP.length);
  });
  t.test('CP437 characters survive closing and reopening the file', async (p) => {
    await p.click(tabSel('CP437.BAS') + ' .x');
    await p.ev('RC.app.renderExplorer()');
    await p.sleep(300);
    await clickExplorer(p, 'CP437.BAS');
    p.assert.equal(await p.code(), CP);
    p.assert.equal(await p.exists(tabSel('CP437.BAS') + ' .dirty'), false);
  });
  t.test('CP437 characters survive a reload', async (p) => {
    await p.reload();
    await p.click(tabSel('CP437.BAS'));
    p.assert.equal(await p.code(), CP);
  });
  t.test('multi-line text with box drawing keeps CRLF line endings on disk and LF in the editor', async (p) => {
    const txt = '\' ┌──┐\n\' │☺ │\n\' └──┘';
    await open(p, '', { path: DIR + 'BOX.BAS' });
    await p.insertText(txt);
    await p.key('s', { ctrl: true });
    const b = await diskBytes(p, DIR + 'BOX.BAS');
    p.assert.equal(b.filter((x) => x === 13).length, 2);
    p.assert.ok(b.includes(0xDA) && b.includes(0xC4) && b.includes(0xBF) && b.includes(0xB3) && b.includes(0xC0) && b.includes(0xD9));
    await p.click(tabSel('BOX.BAS') + ' .x');
    await p.ev('RC.app.openFile("C:\\\\MYPROGS\\\\BOX.BAS")');
    p.assert.equal(await p.code(), txt);
  });
  t.test('a program printing CP437 characters shows them on the output screen', async (p) => {
    await open(p, CP, { path: DIR + 'CP437.BAS' });
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /╔═╗║░▒▓☺/);
  });
  t.test('characters outside CP437 are saved as "?"', async (p) => {
    await open(p, '', { path: DIR + 'EURO.BAS' });
    await typeKeys(p, "' 5€");
    await p.key('s', { ctrl: true });
    p.assert.equal(await disk(p, DIR + 'EURO.BAS'), "' 5?");
  });
  t.test('CP437 text that also looks like UTF-8 (├⌐) round-trips through save and reopen', async (p) => {
    const txt = "' ├⌐ edge";
    await open(p, '', { path: DIR + 'UTF.BAS' });
    await p.insertText(txt);
    await p.key('s', { ctrl: true });
    await p.click(tabSel('UTF.BAS') + ' .x');
    await p.ev('RC.app.openFile("C:\\\\MYPROGS\\\\UTF.BAS")');
    p.assert.equal(await p.code(), txt);
  });
};
