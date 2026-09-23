// Shared helpers for the 10-menus-* specs (not a spec file itself).

export const TOPS = ['File', 'Edit', 'View', 'Run', 'Debug', 'Options', 'Help'];
export const HOT = { File: 'f', Edit: 'e', View: 'v', Run: 'r', Debug: 'd', Options: 'o', Help: 'h' };

/** Bring the IDE back to a neutral state between tests without reloading. */
export async function reset(p) {
  for (let i = 0; i < 6 && await p.ev('RC.UI.anyModalOpen()'); i++) { await p.key('Escape'); await p.sleep(60); }
  await p.ev(`(() => {
    RC.UI.closeMenus();
    if (RC.Tours.active) RC.Tours.stop();
    const a = RC.app;
    if (a.runner.isActive()) a.stop();
    if (a.console.active) a.console.toggle(false);
    document.getElementById('app').classList.remove('screen-max');
    const fb = document.getElementById('findbar'); if (fb) fb.hidden = true;
    document.querySelectorAll('.menu-pop').forEach((m) => m.remove());
    if (document.activeElement && document.activeElement.blur) document.activeElement.blur();
  })()`);
  await p.sleep(40);
}

export const popCount = (p) => p.count('.menu-pop');

/** Open a top-level menu by clicking its button. */
export async function openTop(p, label) {
  await p.click('.menu-btn', label);
  await p.wait("document.querySelectorAll('.menu-pop').length >= 1", 3000);
  await p.sleep(20);
}

/** Labels of the n-th open popup, separators as '---'. */
export const structure = (p, idx = 0) => p.fn((i) => {
  const pop = document.querySelectorAll('.menu-pop')[i];
  return pop ? [...pop.children].map((e) => (e.classList.contains('menu-sep') ? '---' : e.children[0].innerText)) : null;
}, idx);

/** Detailed item info of the n-th popup. */
export const details = (p, idx = 0) => p.fn((i) => {
  const pop = document.querySelectorAll('.menu-pop')[i];
  if (!pop) return null;
  return [...pop.querySelectorAll('.menu-item')].map((e) => ({
    label: e.children[0].innerText,
    sc: e.querySelector('.sc') ? e.querySelector('.sc').innerText : '',
    disabled: e.classList.contains('disabled'),
    checked: e.classList.contains('checked'),
    sub: !!e.querySelector('.sub-arrow'),
  }));
}, idx);

export async function item(p, label, idx = 0) {
  const all = await details(p, idx);
  return all ? all.find((x) => x.label === label) : undefined;
}

/** Labels currently checked in popup idx. */
export async function checkedLabels(p, idx = 0) {
  return ((await details(p, idx)) || []).filter((x) => x.checked).map((x) => x.label);
}

/** Center of a menu item with exactly this label in popup idx. */
export async function itemCenter(p, label, idx = 0) {
  const c = await p.fn((l, i) => {
    const pop = document.querySelectorAll('.menu-pop')[i];
    if (!pop) return null;
    const el = [...pop.querySelectorAll('.menu-item')].find((e) => e.children[0].innerText === l);
    if (!el) return null;
    el.scrollIntoView({ block: 'nearest' });
    const r = el.getBoundingClientRect();
    return [r.left + r.width / 2, r.top + r.height / 2];
  }, label, idx);
  if (!c) throw new Error('menu item not found: ' + label + ' (popup ' + idx + ')');
  return c;
}

export async function clickItem(p, label, idx = 0) {
  const [x, y] = await itemCenter(p, label, idx);
  await p.clickAt(x, y);
}

export async function hoverItem(p, label, idx = 0) {
  const [x, y] = await itemCenter(p, label, idx);
  await p.mouse('mouseMoved', x, y);
  await p.sleep(60);
}

/** Click File ▸ item (etc.) and let the deferred action run. */
export async function pick(p, top, label) {
  await openTop(p, top);
  await clickItem(p, label, 0);
  await p.sleep(120);
}

/** Choose top ▸ parent ▸ sub through a hover-opened submenu. */
export async function pickSub(p, top, parent, sub) {
  await openTop(p, top);
  await hoverItem(p, parent, 0);
  await p.wait("document.querySelectorAll('.menu-pop').length === 2", 3000);
  await clickItem(p, sub, 1);
  await p.sleep(120);
}

/** Open top ▸ parent submenu and return its details (menu left open). */
export async function subDetails(p, top, parent) {
  await openTop(p, top);
  await hoverItem(p, parent, 0);
  await p.wait("document.querySelectorAll('.menu-pop').length === 2", 3000);
  return details(p, 1);
}

/** Label of the keyboard-highlighted item in the main popup. */
export const activeLabel = (p) => p.ev("(() => { const e = document.querySelector('.menu-pop .menu-item.active'); return e ? e.children[0].innerText : null; })()");
export const openMenuName = (p) => p.ev("(() => { const b = document.querySelector('.menu-btn.open'); return b ? b.innerText : null; })()");

export const settings = (p) => p.ev('RC.app.settings');
export const setting = (p, k) => p.ev(`RC.app.settings[${JSON.stringify(k)}]`);
export const activePanel = (p) => p.ev("(document.querySelector('#bottomTabs .tab.active') || {dataset:{}}).dataset.id || null");

/** Make a program file and open it in the editor (not dirty). */
export async function prog(p, text, path = 'C:\\MYPROGS\\MENUT.BAS') {
  await p.newFile(path, text);
  await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(path)}`, 3000);
}

/** Put the caret on a 0-based editor line and focus the editor. */
export async function caret(p, line, col = 0) {
  await p.fn((l, c) => { const e = RC.app.active.editor; e.focus(); e.setCursor(l, c); }, line, col);
  await p.sleep(30);
}

export const pauseLine = (p) => p.ev('(() => { const vm = RC.app.runner.vm; if (!vm) return null; const pos = vm.framePos(vm.frames.length - 1); return pos ? pos.line : null; })()');

/** Wait for a modal and return its title. */
export const modal = (p, ms) => p.waitModal(ms);

/** Close every modal through its real Escape handling. */
export async function escModals(p) {
  for (let i = 0; i < 6 && await p.ev('RC.UI.anyModalOpen()'); i++) { await p.key('Escape'); await p.sleep(60); }
}

/** Record anchor downloads and file-picker clicks instead of performing them. */
export async function trapDownloads(p) {
  await p.ev(`(() => {
    window.__dl = []; window.__picks = [];
    if (!window.__origAClick) {
      window.__origAClick = HTMLAnchorElement.prototype.click;
      HTMLAnchorElement.prototype.click = function () { if (this.hasAttribute('download')) { window.__dl.push(this.getAttribute('download')); return; } return window.__origAClick.call(this); };
      window.__origIClick = HTMLInputElement.prototype.click;
      HTMLInputElement.prototype.click = function () { if (this.type === 'file') { window.__picks.push({ multiple: this.multiple }); return; } return window.__origIClick.call(this); };
    }
  })()`);
}

export const LOOP = 'DO\n    x = x + 1\nLOOP\n';
export const STEPS = 'a = 1\nb = 2\nc = 3\nPRINT a + b + c\n';
export const SUBPROG = 'CALL Foo\nPRINT "DONE"\nEND\nSUB Foo\n    q = 1\n    r = 2\nEND SUB\n';

/** Start an endless loop program from the menu-independent API and wait until it runs. */
export async function startLoop(p) {
  await prog(p, LOOP, 'C:\\MYPROGS\\LOOP.BAS');
  await p.ev('RC.app.run()');
  await p.waitState(['running', 'waiting']);
}

/** Open STEPS and pause on its first statement. */
export async function pausedAtStart(p, text = STEPS) {
  await prog(p, text);
  await p.ev("RC.app.step('into')");
  await p.waitState('paused');
}
