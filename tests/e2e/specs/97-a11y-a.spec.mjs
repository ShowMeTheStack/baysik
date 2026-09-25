// Accessibility: accessible names, landmarks, dialog semantics and focus handling, keyboard
// navigation of menus, tab order, live regions and prefers-reduced-motion.
import { box } from './95-responsive-helpers.mjs';

const DESK = { width: 1400, height: 900 };

const accName = (p, sel) => p.ev(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; return (e.getAttribute('aria-label') || e.getAttribute('title') || e.innerText || '').trim(); })()`);
const focusInfo = (p) => p.ev("(() => { const a = document.activeElement; if (!a) return null; return { tag: a.tagName, id: a.id, cls: a.className && a.className.baseVal === undefined ? a.className : '', label: a.getAttribute('aria-label') || '', inModal: !!a.closest('.modal'), menu: a.classList.contains('menu-btn'), tb: a.classList.contains('tb-btn'), ed: a.classList.contains('ed-ta') }; })()");
async function focusEditor(p) {
  await p.ev('RC.app.active.editor.focus()');
  await p.sleep(30);
  p.assert.equal(await p.ev("document.activeElement.classList.contains('ed-ta')"), true);
}
async function ensureDesk(p) {
  const ok = await p.ev(`innerWidth === 1400 && innerHeight === 900 && !document.querySelector('.modal-back') && !document.querySelector('.menu-pop')`);
  if (!ok) await p.fresh(DESK);
}

const TOOLBAR = [
  ['tbRun', 'Run / Continue (F5)'], ['tbPause', 'Pause (Ctrl+Break)'], ['tbStop', 'Stop (Ctrl+F2)'], ['tbRestart', 'Restart (Shift+F5)'],
  ['tbInto', 'Step Into (F8)'], ['tbOver', 'Step Over (F10)'], ['tbOut', 'Step Out (Shift+F8)'], ['tbBp', 'Toggle Breakpoint (F9)'],
  ['tbExamples', null], ['tbLearn', null], ['tbHelp', 'Language reference (F1)'], ['tbTour', 'Guided tours'], ['tbFiles', 'Show files'],
];

export default (t) => {
  // ---------------------------------------------------------------- accessible names
  for (const [id, label] of TOOLBAR) {
    t.test(`toolbar button #${id} has an accessible name${label ? ' "' + label + '"' : ''}`, async (p) => {
      await ensureDesk(p);
      const al = await p.attr('#' + id, 'aria-label');
      const ti = await p.attr('#' + id, 'title');
      p.assert.ok((al && al.trim()) || (ti && ti.trim()), 'no aria-label or title');
      if (label) p.assert.equal(al || ti, label);
      p.assert.equal(await p.attr('#' + id + ' svg', 'aria-hidden'), 'true', 'icon should be hidden from assistive tech');
    });
  }

  t.test('icon-only toolbar buttons (Restart, Breakpoint) are labelled even without visible text', async (p) => {
    await ensureDesk(p);
    for (const id of ['tbRestart', 'tbBp']) {
      p.assert.equal((await p.text('#' + id)).trim(), '');
      p.assert.ok((await accName(p, '#' + id)).length > 3);
    }
  });

  t.test('toolbar buttons keep their accessible names when labels are hidden on phones', async (p) => {
    await p.viewport(390, 844);
    for (const [id] of TOOLBAR.slice(0, 8)) p.assert.ok((await p.attr('#' + id, 'aria-label')).length > 3, id);
    p.assert.equal(await p.ev("getComputedStyle(document.querySelector('#tbInto .lbl')).display"), 'none');
    await p.viewport(1400, 900);
  });

  t.test('speed selector has an accessible name', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.attr('#tbSpeed', 'aria-label'), 'Execution speed');
  });

  for (const label of ['New program', 'New folder', 'Import files from computer', 'Mount a computer folder as D:', 'Share project']) {
    t.test(`explorer action "${label}" is a labelled button`, async (p) => {
      await ensureDesk(p);
      const sel = `#explorerActions button[aria-label="${label}"]`;
      p.assert.ok(await p.exists(sel));
      p.assert.equal(await p.attr(sel, 'title'), label);
      p.assert.equal(await p.attr(sel, 'type'), 'button');
      p.assert.ok(await p.visible(sel));
    });
  }

  for (const label of ['GW-BASIC classic console', 'Save screenshot (PNG)', 'Full size output (F4)']) {
    t.test(`screen action "${label}" is a labelled button`, async (p) => {
      await ensureDesk(p);
      const sel = `#screenActions button[aria-label="${label}"]`;
      p.assert.ok(await p.exists(sel));
      p.assert.equal(await p.attr(sel, 'title'), label);
      p.assert.ok(await p.visible(sel));
    });
  }

  t.test('every icon button in the IDE has an accessible name', async (p) => {
    await ensureDesk(p);
    const missing = await p.ev("[...document.querySelectorAll('button.icon-btn, button.tb-btn, #keypad button')].filter(b => !((b.getAttribute('aria-label') || b.getAttribute('title') || b.innerText || '').trim())).map(b => b.outerHTML.slice(0, 80))");
    p.assert.deepEqual(missing, []);
    p.assert.ok(await p.count('button.icon-btn') >= 9);
  });

  t.test('drawer close button and editor tab close buttons are labelled', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.attr('#explorerClose', 'aria-label'), 'Close files');
    const n = await p.ev("[...document.querySelectorAll('#editorTabs .tab .x')].filter(x => x.getAttribute('role') === 'button' && /^Close /.test(x.getAttribute('aria-label'))).length");
    p.assert.equal(n, await p.count('#editorTabs .tab'));
  });

  t.test('keypad buttons all have accessible names', async (p) => {
    const labels = await p.ev("[...document.querySelectorAll('#keypad button')].map(b => b.getAttribute('aria-label'))");
    p.assert.deepEqual(labels, ['Up', 'Left', 'Down', 'Right', 'Space', 'Enter', 'Esc', 'Show keyboard', 'Break (Ctrl+Break)']);
    p.assert.equal(await p.attr('.softkb', 'aria-label'), 'Keyboard for the program');
  }, { fresh: { width: 390, height: 844, mobile: true, touch: true } });

  // ---------------------------------------------------------------- landmarks & roles
  t.test('page declares a language and a responsive viewport', async (p) => {
    p.assert.equal(await p.ev('document.documentElement.lang'), 'en');
    p.assert.match(await p.ev("document.querySelector('meta[name=viewport]').content"), /width=device-width/);
    p.assert.match(await p.ev('document.title'), /Baysik/);
  }, { fresh: DESK });

  t.test('menubar, toolbar and view tabs have roles and labels', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.attr('#menubar', 'role'), 'menubar');
    p.assert.equal(await p.attr('#menubar', 'aria-label'), 'Main menu');
    p.assert.equal(await p.attr('#toolbar', 'role'), 'toolbar');
    p.assert.equal(await p.attr('#toolbar', 'aria-label'), 'Run and debug');
    p.assert.equal(await p.ev("document.getElementById('mobileTabs').tagName"), 'NAV');
    p.assert.equal(await p.attr('#mobileTabs', 'aria-label'), 'Views');
  });

  t.test('panes are labelled regions (Files, Editor, Output screen, Debug panels)', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.attr('#explorer', 'aria-label'), 'Files');
    p.assert.equal(await p.attr('#editorArea', 'aria-label'), 'Editor');
    p.assert.equal(await p.attr('#screenArea', 'aria-label'), 'Output screen');
    p.assert.equal(await p.attr('#bottom', 'aria-label'), 'Debug panels');
    p.assert.equal(await p.ev("document.getElementById('workspace').tagName"), 'MAIN');
  });

  t.test('editor text area and output canvas are focusable and labelled', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.ev("document.querySelector('.ed:not([style*=\"none\"]) .ed-ta, .ed-ta').getAttribute('aria-label')"), 'Code editor');
    p.assert.equal(await p.attr('#screen', 'tabindex'), '0');
    p.assert.match(await p.attr('#screen', 'aria-label'), /output screen/i);
    p.assert.equal(await p.attr('.ed-gutter', 'aria-hidden'), 'true', 'line-number gutter hidden from AT');
    p.assert.equal(await p.attr('.ed-hl', 'aria-hidden'), 'true', 'highlight mirror hidden from AT');
  });

  t.test('editor tabs are a tablist with aria-selected on the active tab only', async (p) => {
    await ensureDesk(p);
    await p.newFile('C:\\MYPROGS\\A11Y.BAS', 'PRINT 1');
    p.assert.equal(await p.attr('#editorTabs', 'role'), 'tablist');
    const sel = await p.ev("[...document.querySelectorAll('#editorTabs .tab')].map(t => [t.getAttribute('role'), t.getAttribute('aria-selected'), t.classList.contains('active')])");
    p.assert.ok(sel.length >= 2);
    for (const [role, aria, active] of sel) { p.assert.equal(role, 'tab'); p.assert.equal(aria, active ? 'true' : 'false'); }
  });

  t.test('debug panel tabs expose the selected tab with aria-selected', async (p) => {
    await ensureDesk(p);
    await p.click('#bottomTabs .tab', 'Watch');
    p.assert.equal(await p.attr('#bottomTabs', 'role'), 'tablist');
    const sel = await p.ev("[...document.querySelectorAll('#bottomTabs .tab')].map(t => [t.innerText, t.getAttribute('aria-selected')])");
    const on = sel.filter(([, a]) => a === 'true').map(([n]) => n);
    p.assert.deepEqual(on.length === 1 && /Watch/.test(on[0]), true, 'aria-selected: ' + JSON.stringify(sel));
  });

  t.test('mobile view tabs mark the current view for assistive tech', async (p) => {
    await p.click('#mobileTabs button', 'Screen');
    const st = await p.ev("(() => { const b = document.querySelector('#mobileTabs button[data-view=screen]'); return b.getAttribute('aria-selected') || b.getAttribute('aria-pressed') || b.getAttribute('aria-current'); })()");
    p.assert.ok(st === 'true' || st === 'page', 'active view tab has no aria-selected/aria-pressed/aria-current');
  }, { fresh: { width: 390, height: 844 } });

  t.test('file tree items are keyboard focusable tree items', async (p) => {
    await ensureDesk(p);
    const items = await p.ev("[...document.querySelectorAll('#explorerTree .tree-item')].slice(0, 10).map(e => [e.getAttribute('role'), e.getAttribute('tabindex')])");
    p.assert.ok(items.length > 2);
    for (const [r, ti] of items) { p.assert.equal(r, 'treeitem'); p.assert.equal(ti, '0'); }
  });

  t.test('file tree items are owned by an element with role=tree', async (p) => {
    await ensureDesk(p);
    p.assert.ok(await p.ev("!!document.querySelector('#explorerTree .tree-item').closest('[role=tree], [role=group]')"), 'treeitems need a tree/group container');
  });

  t.test('menus use menu/menuitem roles and menu buttons announce a popup', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.ev("[...document.querySelectorAll('#menubar .menu-btn')].every(b => b.getAttribute('aria-haspopup') === 'true' && b.type === 'button')"), true);
    await p.click('.menu-btn', 'File');
    await p.wait("!!document.querySelector('.menu-pop')");
    p.assert.equal(await p.attr('.menu-pop', 'role'), 'menu');
    p.assert.equal(await p.ev("[...document.querySelectorAll('.menu-pop .menu-item')].every(i => i.getAttribute('role') === 'menuitem')"), true);
    await p.closeMenus();
  });

  t.test('menu buttons reflect open/closed state with aria-expanded', async (p) => {
    await ensureDesk(p);
    await p.click('.menu-btn', 'Edit');
    await p.wait("!!document.querySelector('.menu-pop')");
    const open = await p.attr('#menubar .menu-btn[data-menu="1"]', 'aria-expanded');
    await p.closeMenus();
    const closed = await p.attr('#menubar .menu-btn[data-menu="1"]', 'aria-expanded');
    p.assert.equal(open, 'true');
    p.assert.equal(closed, 'false');
  });

  // ---------------------------------------------------------------- dialogs
  const DIALOGS = [
    ['About Baysik', async (p) => p.menu('Help', 'About Baysik')],
    ['Keyboard Shortcuts', async (p) => p.menu('Help', 'Keyboard Shortcuts')],
    ['Go to Line', async (p) => p.menu('Edit', 'Go to Line…')],
    ['Open File', async (p) => p.menu('File', 'Open…')],
    ['New Program', async (p) => p.click('#explorerActions button[aria-label="New program"]')],
    ['BASIC Language Reference', async (p) => p.click('#tbHelp')],
    ['Program Library', async (p) => p.click('#tbExamples')],
    ['Learn', async (p) => p.click('#tbLearn')],
  ];
  for (const [title, open] of DIALOGS) {
    t.test(`dialog "${title}" has role=dialog, aria-modal and an accessible name`, async (p) => {
      await ensureDesk(p);
      await open(p);
      const head = await p.waitModal();
      p.assert.ok(head.length > 0);
      if (title !== 'Program Library' && title !== 'Learn') p.assert.match(head, new RegExp(title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
      const m = '.modal-back:last-child .modal';
      p.assert.equal(await p.attr(m, 'role'), 'dialog');
      p.assert.equal(await p.attr(m, 'aria-modal'), 'true');
      p.assert.equal((await p.attr(m, 'aria-label')).trim(), head.trim());
      p.assert.ok((await focusInfo(p)).inModal, 'focus moved into the dialog');
      await p.key('Escape');
      await p.waitGone('.modal-back');
    });
  }

  t.test('Escape closes the Open dialog and returns focus to the editor', async (p) => {
    await ensureDesk(p);
    await focusEditor(p);
    await p.key('o', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Open File');
    p.assert.ok((await focusInfo(p)).inModal);
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.equal((await focusInfo(p)).ed, true, 'focus back in the code editor');
  });

  t.test('Escape closes the SUBs dialog (F2) and returns focus to the editor', async (p) => {
    await ensureDesk(p);
    await focusEditor(p);
    await p.key('F2');
    p.assert.equal(await p.waitModal(), 'SUBs');
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.equal((await focusInfo(p)).ed, true);
  });

  t.test('Escape closes the Save As prompt (Ctrl+Shift+S) and returns focus to the editor', async (p) => {
    await ensureDesk(p);
    await p.newFile('C:\\MYPROGS\\SAVEAS.BAS', 'PRINT 2');
    await focusEditor(p);
    await p.key('s', { ctrl: true, shift: true });
    await p.waitModal();
    p.assert.equal(await p.ev("document.activeElement.tagName"), 'INPUT', 'name field focused');
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.equal((await focusInfo(p)).ed, true);
  });

  t.test('keyboard-activated Help button: Enter opens, Escape closes and focus returns to the button', async (p) => {
    await ensureDesk(p);
    await p.ev("document.getElementById('tbHelp').focus()");
    await p.key('Enter');
    p.assert.match(await p.waitModal(), /Language Reference/);
    await p.key('Escape');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.focusedId(), 'tbHelp');
  });

  t.test('Enter confirms a prompt dialog and Escape on a confirm returns the cancel value', async (p) => {
    await ensureDesk(p);
    await p.newFile('C:\\MYPROGS\\GOTO.BAS', 'PRINT 1\nPRINT 2\nPRINT 3\nPRINT 4');
    await p.menu('Edit', 'Go to Line…');
    await p.waitModal();
    await p.type('3\n');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.ev('RC.app.active.editor.cursor().line'), 2);
    const v = p.ev("RC.UI.confirm('Sure?', 'Really?').then(v => (window.__cv = v))");
    void v;
    await p.waitModal();
    await p.key('Escape');
    await p.wait('window.__cv === false');
  });

  t.test('stacked dialogs: Escape closes only the top one', async (p) => {
    await ensureDesk(p);
    await p.ev("RC.UI.alert('First', 'one'); setTimeout(() => RC.UI.alert('Second', 'two'), 50)");
    await p.wait("document.querySelectorAll('.modal-back').length === 2");
    await p.key('Escape');
    await p.wait("document.querySelectorAll('.modal-back').length === 1");
    p.assert.equal(await p.modalTitle(), 'First');
    await p.key('Escape');
    await p.waitGone('.modal-back');
  });

  t.test('Tab keeps keyboard focus inside an open modal dialog', async (p) => {
    await ensureDesk(p);
    await p.menu('Help', 'About Baysik');
    await p.waitModal();
    let escaped = null;
    for (let i = 0; i < 6; i++) {
      await p.key('Tab');
      const f = await focusInfo(p);
      if (!f.inModal) { escaped = f; break; }
    }
    await p.closeModals();
    p.assert.equal(escaped, null, 'focus left the aria-modal dialog: ' + JSON.stringify(escaped));
  });

  t.test('debug callout is exposed as a labelled dialog', async (p) => {
    await ensureDesk(p);
    await p.runProgram('HP% = 77\nSTOP\nPRINT HP%');
    await p.ev("(() => { const d = RC.app.active; RC.app.callout.showFor(d, { line: 0, col: 1, text: d.editor.getLine(0) }, 300, 300); })()");
    await p.wait("!!document.querySelector('.ed-callout')");
    p.assert.equal(await p.attr('.ed-callout', 'role'), 'dialog');
    p.assert.equal(await p.attr('.ed-callout', 'aria-label'), 'Variable value');
    p.assert.match(await p.text('.ed-callout'), /77/);
    await p.key('Escape');
    await p.waitGone('.ed-callout');
    await p.stopProgram();
  });

  // ---------------------------------------------------------------- keyboard navigation
  t.test('Tab order reaches the menus, then the toolbar, then the code editor', async (p) => {
    await ensureDesk(p);
    await p.ev('document.activeElement && document.activeElement.blur()');
    let firstMenu = -1, firstTb = -1, firstEd = -1;
    for (let i = 0; i < 200 && firstEd < 0; i++) {
      await p.key('Tab', { after: 5 });
      const f = await focusInfo(p);
      if (f.menu && firstMenu < 0) firstMenu = i;
      if (f.tb && firstTb < 0) firstTb = i;
      if (f.ed) firstEd = i;
    }
    p.assert.ok(firstMenu >= 0, 'menus not reachable by Tab');
    p.assert.ok(firstTb > firstMenu, 'toolbar should follow the menus');
    p.assert.ok(firstEd > firstTb, 'editor should follow the toolbar');
  });

  t.test('Shift+Tab moves focus backwards from the toolbar into the menus', async (p) => {
    await ensureDesk(p);
    await p.ev("document.getElementById('tbRun').focus()");
    await p.key('Tab', { shift: true });
    p.assert.equal((await focusInfo(p)).menu, true);
  });

  t.test('focused toolbar button shows a visible focus ring after keyboard navigation', async (p) => {
    await ensureDesk(p);
    await p.ev("document.querySelector('#menubar .menu-btn[data-menu=\"6\"]').focus()");
    await p.key('Tab');
    const f = await focusInfo(p);
    p.assert.equal(f.tb, true);
    const os = await p.ev("[getComputedStyle(document.activeElement).outlineStyle, parseFloat(getComputedStyle(document.activeElement).outlineWidth)]");
    p.assert.equal(os[0], 'solid');
    p.assert.ok(os[1] >= 2);
  });

  t.test('Alt+F opens the File menu with the first item highlighted', async (p) => {
    await ensureDesk(p);
    await focusEditor(p);
    await p.key('f', { alt: true });
    await p.wait("!!document.querySelector('.menu-pop')");
    p.assert.equal(await p.text('.menu-pop .menu-item.active span'), 'New Program');
    p.assert.ok(await p.ev("document.querySelector('#menubar .menu-btn[data-menu=\"0\"]').classList.contains('open')"));
  });

  t.test('ArrowDown/ArrowUp move the highlight and wrap around', async (p) => {
    await p.key('ArrowDown');
    p.assert.equal(await p.text('.menu-pop .menu-item.active span'), 'New Folder…');
    await p.key('ArrowUp');
    await p.key('ArrowUp');
    const items = await p.ev("[...document.querySelectorAll('.menu-pop .menu-item:not(.disabled) > span:first-child')].map(s => s.innerText)");
    p.assert.equal(await p.text('.menu-pop .menu-item.active span'), items[items.length - 1]);
    p.assert.equal(await p.count('.menu-pop .menu-item.active'), 1);
  });

  t.test('ArrowRight / ArrowLeft move between menus in the menubar', async (p) => {
    await p.key('ArrowRight');
    await p.wait("document.querySelector('#menubar .menu-btn[data-menu=\"1\"]').classList.contains('open')");
    p.assert.equal(await p.text('.menu-pop .menu-item.active span'), 'Undo');
    await p.key('ArrowLeft');
    await p.wait("document.querySelector('#menubar .menu-btn[data-menu=\"0\"]').classList.contains('open')");
    await p.key('ArrowLeft');
    await p.wait("document.querySelector('#menubar .menu-btn[data-menu=\"6\"]').classList.contains('open')", 2000);
    p.assert.equal(await p.count('.menu-pop'), 1);
  });

  t.test('Escape closes the keyboard-opened menu', async (p) => {
    await p.key('Escape');
    await p.waitGone('.menu-pop');
    p.assert.equal(await p.count('#menubar .menu-btn.open'), 0);
  });

  t.test('Enter on a highlighted menu item runs it (Alt+H, Down, Enter → Keyboard Shortcuts)', async (p) => {
    await ensureDesk(p);
    await focusEditor(p);
    await p.key('h', { alt: true });
    await p.wait("!!document.querySelector('.menu-pop')");
    const items = await p.ev("[...document.querySelectorAll('.menu-pop .menu-item:not(.disabled) > span:first-child')].map(s => s.innerText)");
    const idx = items.indexOf('Keyboard Shortcuts');
    p.assert.ok(idx >= 0);
    for (let i = 0; i < idx; i++) await p.key('ArrowDown');
    await p.key('Enter');
    p.assert.equal(await p.waitModal(), 'Keyboard Shortcuts');
    p.assert.equal(await p.exists('.menu-pop'), false);
    await p.key('Escape');
    await p.waitGone('.modal-back');
  });

  t.test('keyboard menu navigation skips disabled items', async (p) => {
    await ensureDesk(p);
    await focusEditor(p);
    await p.key('r', { alt: true });
    await p.wait("!!document.querySelector('.menu-pop')");
    const seen = new Set();
    for (let i = 0; i < 15; i++) {
      p.assert.equal(await p.ev("!!document.querySelector('.menu-pop .menu-item.active.disabled')"), false);
      seen.add(await p.text('.menu-pop .menu-item.active span'));
      await p.key('ArrowDown');
    }
    p.assert.equal(seen.has('Pause'), false, 'Pause is disabled while idle');
    p.assert.ok(seen.size >= 2);
    await p.key('Escape');
  });

  // ---------------------------------------------------------------- live regions
  t.test('status bar is a polite live region that announces run state', async (p) => {
    await ensureDesk(p);
    p.assert.equal(await p.attr('#statusbar', 'role'), 'status');
    await p.runProgram('PRINT 1');
    p.assert.match(await p.status(), /Program ended/);
  });

  t.test('Immediate window output is an aria-live log', async (p) => {
    await ensureDesk(p);
    await p.panel('immediate');
    p.assert.equal(await p.attr('.imm-log', 'aria-live'), 'polite');
  });

  t.test('guided tour popup is a dialog that announces each step', async (p) => {
    await ensureDesk(p);
    await p.ev("RC.Tours.start(RC.app, 'welcome')");
    await p.wait("!!document.querySelector('.tour-pop')");
    p.assert.equal(await p.attr('.tour-pop', 'role'), 'dialog');
    p.assert.equal(await p.attr('.tour-pop', 'aria-live'), 'polite');
    p.assert.ok(await p.ev("(() => { const r = document.querySelector('.tour-pop').getBoundingClientRect(); return r.left >= 0 && r.right <= innerWidth && r.bottom <= innerHeight; })()"));
    await p.ev('RC.Tours.stop()');
    await p.waitGone('.tour-pop');
  });

  t.test('guided tour popup fits a 360px wide phone', async (p) => {
    await p.ev("RC.Tours.start(RC.app, 'welcome')");
    await p.wait("!!document.querySelector('.tour-pop')");
    const r = await box(p, '.tour-pop');
    p.assert.ok(r.x >= 0 && r.right <= 360 && r.bottom <= 640, JSON.stringify(r));
    await p.ev('RC.Tours.stop()');
  }, { fresh: { width: 360, height: 640 } });

  t.test('toast notifications are announced through a live region', async (p) => {
    await ensureDesk(p);
    await p.ev("RC.UI.toast('Saved test', 'ok')");
    await p.waitToast(/Saved test/);
    const live = await p.ev("(() => { const t = document.querySelector('.toast'); const c = t.closest('[aria-live], [role=status], [role=alert], [role=log]'); return c ? (c.getAttribute('aria-live') || c.getAttribute('role')) : null; })()");
    p.assert.ok(live, 'toast container has no aria-live/role=status');
  });

  // ---------------------------------------------------------------- reduced motion
  t.test('without reduced motion the tablet drawer slides (transition on transform)', async (p) => {
    const d = await p.ev("getComputedStyle(document.getElementById('explorer')).transitionDuration");
    p.assert.equal(d, '0.2s');
  }, { fresh: { width: 1024, height: 768 } });

  t.test('prefers-reduced-motion: drawer, toasts and hints have no animation', async (p) => {
    await p.b.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    try {
      p.assert.equal(await p.ev("matchMedia('(prefers-reduced-motion: reduce)').matches"), true);
      p.assert.equal(await p.ev("getComputedStyle(document.getElementById('explorer')).transitionDuration"), '0s');
      p.assert.equal(await p.ev("getComputedStyle(document.getElementById('screenHint')).transitionDuration"), '0s');
      await p.ev("RC.UI.toast('motion test')");
      await p.waitToast(/motion test/);
      p.assert.equal(await p.ev("getComputedStyle([...document.querySelectorAll('.toast')].pop()).animationName"), 'none');
      // the drawer opens instantly
      await p.click('#tbFiles');
      p.assert.ok((await box(p, '#explorer')).x >= -1, 'drawer should be open immediately without sliding');
      await p.click('#explorerClose');
      p.assert.ok((await box(p, '#explorer')).right <= 0);
    } finally {
      await p.b.send('Emulation.setEmulatedMedia', { features: [] });
    }
  }, { fresh: { width: 1024, height: 768 } });

  t.test('prefers-reduced-motion: editor line flash animation is disabled', async (p) => {
    await p.b.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
    try {
      await p.newFile('C:\\MYPROGS\\FLASH.BAS', 'PRINT 1\nPRINT 2');
      await p.ev('RC.app.active.editor.flashLine(1)');
      await p.wait("!!document.querySelector('.ed-line.flash')", 2000);
      p.assert.equal(await p.ev("getComputedStyle(document.querySelector('.ed-line.flash')).animationName"), 'none');
    } finally {
      await p.b.send('Emulation.setEmulatedMedia', { features: [] });
    }
    await p.ev('RC.app.active.editor.flashLine(0)');
    await p.wait("!!document.querySelector('.ed-line.flash')", 2000);
    p.assert.equal(await p.ev("getComputedStyle(document.querySelector('.ed-line.flash')).animationName"), 'flash', 'animation back once the preference is cleared');
  }, { fresh: DESK });
};
