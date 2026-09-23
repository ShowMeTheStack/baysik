// Menus part B: keyboard navigation inside menus and mouse interaction (outside click, hover-switch,
// toggling, submenus, disabled items).
import { reset, openTop, structure, clickItem, hoverItem, itemCenter, activeLabel, openMenuName, popCount, prog, setting } from './10-menus-helpers.mjs';

const alt = (p, l) => p.key(l, { alt: true });
const waitPop = (p) => p.wait("!!document.querySelector('.menu-pop')", 2000);

export default (t) => {
  t.beforeEach(async (p) => { await reset(p); });

  // ---- arrows inside a menu ------------------------------------------------------------------------
  t.test('ArrowDown moves the highlight to the next item', async (p) => {
    await alt(p, 'h'); await waitPop(p);
    p.assert.equal(await activeLabel(p), 'Language Reference');
    await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Keyboard Shortcuts');
    await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Learn BASIC (Tutorial)…');
  });
  t.test('ArrowDown skips separators (Starter Examples → first tour)', async (p) => {
    await alt(p, 'h'); await waitPop(p);
    for (let i = 0; i < 5; i++) await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Tour: Welcome to the IDE');
  });
  t.test('ArrowDown wraps from the last item to the first', async (p) => {
    await alt(p, 'h'); await waitPop(p);
    await p.key('ArrowUp');
    p.assert.equal(await activeLabel(p), 'About Baysik');
    await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Language Reference');
  });
  t.test('ArrowUp from the first item wraps to the last item', async (p) => {
    await alt(p, 'v'); await waitPop(p);
    await p.key('ArrowUp');
    p.assert.equal(await activeLabel(p), 'Zoom Out');
    await p.key('ArrowUp');
    p.assert.equal(await activeLabel(p), 'Zoom In');
  });
  t.test('full ArrowDown cycle visits every enabled item once and returns to the start', async (p) => {
    await alt(p, 'e'); await waitPop(p);
    const seen = [await activeLabel(p)];
    for (let i = 0; i < 10; i++) { await p.key('ArrowDown', { after: 10 }); seen.push(await activeLabel(p)); }
    p.assert.deepEqual(seen, ['Undo', 'Redo', 'Find…', 'Replace…', 'Go to Line…', 'Toggle Comment', 'Duplicate Line', 'Capitalize Keywords',
      'Renumber Lines (RENUM)…', 'Add Line Numbers…', 'Undo']);
  });
  t.test('ArrowDown skips disabled items (Run menu when idle)', async (p) => {
    await alt(p, 'r'); await waitPop(p);
    const seen = [await activeLabel(p)];
    for (let i = 0; i < 5; i++) { await p.key('ArrowDown', { after: 10 }); seen.push(await activeLabel(p)); }
    p.assert.deepEqual(seen, ['Start', 'Restart', 'Run to Cursor', 'Speed', 'Output Screen', 'Start']);
  });
  t.test('ArrowUp skips disabled Unmount D: in the File menu', async (p) => {
    await alt(p, 'f'); await waitPop(p);
    await p.key('ArrowUp');
    p.assert.equal(await activeLabel(p), 'Close Tab');
    await p.key('ArrowUp');
    p.assert.equal(await activeLabel(p), 'Mount Computer Folder as D:…');
  });
  t.test('only one item is highlighted at a time', async (p) => {
    await alt(p, 'o'); await waitPop(p);
    for (let i = 0; i < 4; i++) await p.key('ArrowDown');
    p.assert.equal(await p.count('.menu-pop .menu-item.active'), 1);
    p.assert.equal(await activeLabel(p), 'Auto Indent');
  });
  t.test('ArrowDown in a mouse-opened menu highlights the first item', async (p) => {
    await openTop(p, 'Help');
    p.assert.equal(await activeLabel(p), null);
    await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Language Reference');
  });
  t.test('ArrowUp in a mouse-opened menu highlights the last item', async (p) => {
    await openTop(p, 'Help');
    await p.key('ArrowUp');
    p.assert.equal(await activeLabel(p), 'About Baysik');
  });
  t.test('arrow keys in an open menu do not move the editor caret', async (p) => {
    await prog(p, 'PRINT 1\nPRINT 2\nPRINT 3\n');
    await p.ev('RC.app.active.editor.focus(); RC.app.active.editor.setCursor(0, 0)');
    await alt(p, 'h'); await waitPop(p);
    await p.key('ArrowDown'); await p.key('ArrowDown');
    p.assert.equal(await p.ev('RC.app.active.editor.cursor().line'), 0);
  });

  // ---- Enter / Escape ------------------------------------------------------------------------------------
  t.test('Enter activates the highlighted item (Help ▸ Keyboard Shortcuts)', async (p) => {
    await alt(p, 'h'); await waitPop(p);
    await p.key('ArrowDown');
    await p.key('Enter');
    p.assert.equal(await p.waitModal(), 'Keyboard Shortcuts');
    p.assert.equal(await p.count('.menu-pop'), 0);
  });
  t.test('Enter right after Alt+letter activates the first item (View ▸ Output Screen Full Size)', async (p) => {
    await alt(p, 'v'); await waitPop(p);
    await p.key('Enter');
    await p.wait("document.getElementById('app').classList.contains('screen-max')", 2000);
    p.assert.equal(await p.count('.menu-pop'), 0);
  });
  t.test('Enter on a toggle item flips it (Options ▸ Auto Indent)', async (p) => {
    const before = await setting(p, 'autoIndent');
    await alt(p, 'o'); await waitPop(p);
    for (let i = 0; i < 4; i++) await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Auto Indent');
    await p.key('Enter');
    await p.wait(`RC.app.settings.autoIndent === ${!before}`, 2000);
    await p.ev('RC.app.settings.autoIndent = true; RC.app.saveSettings()');
  });
  t.test('Enter with nothing highlighted (mouse-opened menu) does not activate anything', async (p) => {
    await prog(p, 'PRINT 1\n');
    await openTop(p, 'View');
    const code = await p.code();
    await p.key('Enter');
    await p.sleep(100);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.code(), code);
  });
  t.test('Escape closes a keyboard-opened menu and clears the open button', async (p) => {
    await alt(p, 'd'); await waitPop(p);
    await p.key('Escape');
    p.assert.equal(await popCount(p), 0);
    p.assert.equal(await openMenuName(p), null);
    p.assert.equal(await p.ev('RC.app.menuOpenIdx'), undefined);
  });
  t.test('Escape closes a mouse-opened menu', async (p) => {
    await openTop(p, 'Options');
    await p.key('Escape');
    p.assert.equal(await popCount(p), 0);
    p.assert.equal(await openMenuName(p), null);
  });
  t.test('Escape closes a menu together with its open submenu', async (p) => {
    await openTop(p, 'Run');
    await hoverItem(p, 'Speed');
    await p.wait("document.querySelectorAll('.menu-pop').length === 2", 2000);
    await p.key('Escape');
    p.assert.equal(await popCount(p), 0);
  });
  t.test('Escape in a menu does not change any setting or open a dialog', async (p) => {
    const s = JSON.stringify(await p.ev('RC.app.settings'));
    await alt(p, 'o'); await waitPop(p);
    await p.key('Escape');
    p.assert.equal(JSON.stringify(await p.ev('RC.app.settings')), s);
    p.assert.equal(await p.modalOpen(), false);
  });

  // ---- left / right between menus -------------------------------------------------------------------------
  t.test('ArrowRight moves to the next menu with its first item highlighted', async (p) => {
    await alt(p, 'f'); await waitPop(p);
    await p.key('ArrowRight');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'Edit'", 2000);
    p.assert.equal(await activeLabel(p), 'Undo');
    p.assert.equal(await popCount(p), 1);
  });
  t.test('ArrowLeft moves to the previous menu', async (p) => {
    await alt(p, 'r'); await waitPop(p);
    await p.key('ArrowLeft');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'View'", 2000);
    p.assert.deepEqual((await structure(p)).slice(0, 2), ['Output Screen Full Size', 'GW-BASIC Classic Console']);
  });
  t.test('ArrowLeft on File wraps to Help', async (p) => {
    await alt(p, 'f'); await waitPop(p);
    await p.key('ArrowLeft');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'Help'", 2000);
    p.assert.equal(await activeLabel(p), 'Language Reference');
  });
  t.test('ArrowRight on Help wraps to File', async (p) => {
    await alt(p, 'h'); await waitPop(p);
    await p.key('ArrowRight');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'File'", 2000);
    p.assert.equal(await activeLabel(p), 'New Program');
  });
  t.test('ArrowRight seven times walks through every menu and back to the start', async (p) => {
    await alt(p, 'f'); await waitPop(p);
    const seen = ['File'];
    for (let i = 0; i < 7; i++) {
      await p.key('ArrowRight'); await p.sleep(30);
      // Options opens with "Theme ▸" highlighted: like Windows, ArrowRight first opens that submenu,
      // and ArrowRight inside the submenu continues to the next menu.
      if (await openMenuName(p) === 'Options' && await p.count('.menu-pop') > 1) { await p.key('ArrowRight'); await p.sleep(30); }
      seen.push(await openMenuName(p));
    }
    p.assert.deepEqual(seen, ['File', 'Edit', 'View', 'Run', 'Debug', 'Options', 'Help', 'File']);
    p.assert.equal(await popCount(p), 1);
  });
  t.test('ArrowRight works in a mouse-opened menu too', async (p) => {
    await openTop(p, 'Debug');
    await p.key('ArrowRight');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'Options'", 2000);
    p.assert.equal(await activeLabel(p), 'Theme');
  });
  t.test('after ArrowRight, ArrowDown and Enter act in the new menu', async (p) => {
    await alt(p, 'e'); await waitPop(p);
    await p.key('ArrowRight');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'View'", 2000);
    for (let i = 0; i < 5; i++) await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Variables');
    await p.key('Enter');
    await p.wait("document.querySelector('#bottomTabs .tab.active').dataset.id === 'vars'", 2000);
  });
  t.test('Alt+letter while another menu is open switches menus', async (p) => {
    await alt(p, 'f'); await waitPop(p);
    await alt(p, 'h');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'Help'", 2000);
    p.assert.equal(await popCount(p), 1);
    p.assert.equal(await p.count('.menu-btn.open'), 1);
  });
  t.test('pressing the same Alt+letter again keeps exactly one popup open', async (p) => {
    await alt(p, 'o'); await waitPop(p);
    await alt(p, 'o');
    await p.sleep(50);
    p.assert.equal(await popCount(p), 1);
    p.assert.equal((await structure(p))[0], 'Theme');
  });
  t.test('pressing the same Alt+letter again keeps the menu button marked open', async (p) => {
    await alt(p, 'o'); await waitPop(p);
    await alt(p, 'o');
    await p.sleep(50);
    p.assert.equal(await openMenuName(p), 'Options');
    p.assert.equal(await p.ev('RC.app.menuOpenIdx'), 5);
  });
  t.test('Alt with a letter that is not a menu (Alt+Q) opens nothing', async (p) => {
    await alt(p, 'q');
    await p.sleep(80);
    p.assert.equal(await popCount(p), 0);
  });
  t.test('Alt+letter works while the editor has focus and does not type the letter', async (p) => {
    await prog(p, 'PRINT 1\n');
    await p.ev('RC.app.active.editor.focus()');
    const code = await p.code();
    await alt(p, 'r'); await waitPop(p);
    p.assert.equal(await openMenuName(p), 'Run');
    p.assert.equal(await p.code(), code);
  });
  t.test('keyboard: a submenu (Run ▸ Speed) can be entered and an entry chosen with the keyboard', async (p) => {
    await p.ev('RC.app.setSpeed(0)');
    await alt(p, 'r'); await waitPop(p);
    await p.key('ArrowDown'); await p.key('ArrowDown'); await p.key('ArrowDown');
    p.assert.equal(await activeLabel(p), 'Speed');
    await p.key('ArrowRight'); // conventional: opens the submenu
    await p.key('ArrowDown');
    await p.key('Enter');
    await p.sleep(100);
    const sp = await setting(p, 'speed');
    await p.ev('RC.app.setSpeed(0)');
    p.assert.equal(sp, 400000, 'expected Fast PC (second speed) to be chosen via keyboard');
  });

  // ---- mouse ---------------------------------------------------------------------------------------------
  t.test('clicking outside the menu (on the editor) closes it', async (p) => {
    await openTop(p, 'File');
    await p.click('#editors');
    await p.sleep(50);
    p.assert.equal(await popCount(p), 0);
    p.assert.equal(await openMenuName(p), null);
  });
  t.test('clicking outside (on the status bar) closes the menu without running any action', async (p) => {
    await openTop(p, 'View');
    await p.click('#statusbar');
    await p.sleep(50);
    p.assert.equal(await popCount(p), 0);
    p.assert.equal(await p.modalOpen(), false);
    p.assert.equal(await p.ev("document.getElementById('app').classList.contains('screen-max')"), false);
  });
  t.test('clicking the open menu\'s own button closes it', async (p) => {
    await openTop(p, 'Edit');
    await p.click('.menu-btn', 'Edit');
    await p.sleep(50);
    p.assert.equal(await popCount(p), 0);
    p.assert.equal(await openMenuName(p), null);
  });
  t.test('clicking the button a third time opens the menu again', async (p) => {
    await openTop(p, 'Edit');
    await p.click('.menu-btn', 'Edit');
    await p.click('.menu-btn', 'Edit');
    await p.wait("!!document.querySelector('.menu-pop')", 2000);
    p.assert.equal(await openMenuName(p), 'Edit');
  });
  t.test('clicking another menu button while one is open switches to it', async (p) => {
    await openTop(p, 'File');
    await p.click('.menu-btn', 'Debug');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'Debug'", 2000);
    p.assert.equal(await popCount(p), 1);
    p.assert.equal((await structure(p))[0], 'Step Into');
  });
  t.test('hovering another menu button while a menu is open switches menus', async (p) => {
    await openTop(p, 'File');
    await p.hover('.menu-btn', 'View');
    await p.wait("(document.querySelector('.menu-btn.open') || {}).innerText === 'View'", 2000);
    p.assert.equal(await popCount(p), 1);
    p.assert.equal((await structure(p))[0], 'Output Screen Full Size');
  });
  t.test('hovering across the menubar visits each menu in turn', async (p) => {
    await openTop(p, 'File');
    for (const m of ['Edit', 'View', 'Run', 'Debug', 'Options', 'Help']) {
      await p.hover('.menu-btn', m);
      await p.wait(`(document.querySelector('.menu-btn.open') || {}).innerText === ${JSON.stringify(m)}`, 2000);
    }
    p.assert.equal(await p.count('.menu-btn.open'), 1);
  });
  t.test('hovering menu buttons with no menu open does not open one', async (p) => {
    await p.hover('.menu-btn', 'Run');
    await p.hover('.menu-btn', 'Help');
    await p.sleep(60);
    p.assert.equal(await popCount(p), 0);
  });
  t.test('hovering a submenu parent opens its submenu; hovering a plain item closes it', async (p) => {
    await openTop(p, 'Options');
    await hoverItem(p, 'Theme');
    await p.wait("document.querySelectorAll('.menu-pop').length === 2", 2000);
    await hoverItem(p, 'Editor Font Size…');
    await p.wait("document.querySelectorAll('.menu-pop').length === 1", 2000);
  });
  t.test('hovering from one submenu parent to another replaces the submenu', async (p) => {
    await openTop(p, 'Options');
    await hoverItem(p, 'Theme');
    await p.wait("document.querySelectorAll('.menu-pop').length === 2", 2000);
    await hoverItem(p, 'Tab Width');
    await p.wait("document.querySelectorAll('.menu-pop').length === 2 && document.querySelectorAll('.menu-pop')[1].innerText.includes('2 spaces')", 2000);
    p.assert.equal(await popCount(p), 2);
  });
  t.test('clicking a submenu parent opens the submenu and keeps the menu open', async (p) => {
    await openTop(p, 'Options');
    await clickItem(p, 'Volume');
    await p.wait("document.querySelectorAll('.menu-pop').length === 2", 2000);
    p.assert.equal(await openMenuName(p), 'Options');
  });
  t.test('clicking a separator does not close the menu', async (p) => {
    await openTop(p, 'File');
    const c = await p.fn(() => { const r = document.querySelector('.menu-pop .menu-sep').getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]; });
    await p.clickAt(c[0], c[1]);
    p.assert.equal(await popCount(p), 1);
  });
  t.test('clicking a disabled item (Run ▸ Stop when idle) does nothing and leaves the menu open', async (p) => {
    await openTop(p, 'Run');
    await clickItem(p, 'Stop');
    await p.sleep(80);
    p.assert.equal(await popCount(p), 1);
    p.assert.equal(await p.ev('RC.app.statusMsg === "Stopped"'), false);
  });
  t.test('clicking disabled File ▸ Unmount D: leaves the menu open', async (p) => {
    await openTop(p, 'File');
    await clickItem(p, 'Unmount D:');
    await p.sleep(80);
    p.assert.equal(await popCount(p), 1);
  });
  t.test('clicking an enabled item closes the menu and clears the open button', async (p) => {
    await openTop(p, 'View');
    await clickItem(p, 'Watch');
    await p.sleep(80);
    p.assert.equal(await popCount(p), 0);
    p.assert.equal(await openMenuName(p), null);
    p.assert.equal(await p.ev('RC.app.menuOpenIdx'), undefined);
  });
  t.test('hovering an item highlights it (mouse hover style follows the pointer)', async (p) => {
    await openTop(p, 'Help');
    await hoverItem(p, 'About Baysik');
    p.assert.equal(await p.ev("document.querySelector('.menu-pop .menu-item:hover').children[0].innerText"), 'About Baysik');
  });
  t.test('after closing by an outside click, hovering a menu button no longer opens a menu', async (p) => {
    await openTop(p, 'File');
    await p.click('#statusbar');
    await p.hover('.menu-btn', 'Edit');
    await p.sleep(60);
    p.assert.equal(await popCount(p), 0);
  });
  t.test('menu popup stays inside the viewport for the rightmost menu', async (p) => {
    await openTop(p, 'Help');
    const r = await p.rect('.menu-pop');
    const w = await p.ev('innerWidth');
    p.assert.ok(r.right <= w, `popup right ${r.right} <= ${w}`);
    p.assert.ok(r.bottom <= await p.ev('innerHeight'));
  });
  t.test('menu items are role=menuitem and have the item centers inside the popup', async (p) => {
    await openTop(p, 'Debug');
    const [x, y] = await itemCenter(p, 'TRON (print line numbers)');
    const r = await p.rect('.menu-pop');
    p.assert.ok(x > r.x && x < r.right && y > r.y && y < r.bottom);
    p.assert.equal(await p.count('.menu-pop [role="menuitem"]'), 9);
  });
};
