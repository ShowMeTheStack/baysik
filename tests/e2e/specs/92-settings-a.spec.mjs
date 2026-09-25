// Options: themes, editor font size; Help: About, Keyboard Shortcuts; Options: Disk Usage & Reset.
import { readFileSync } from 'node:fs';

const THEMES = [
  ['qbasic', 'QBasic Blue', { '--bg': '#000080', '--ed-bg': '#0000aa', '--accent': '#55ffff' }],
  ['dark', 'Dark', { '--bg': '#15171c', '--ed-bg': '#16181d', '--accent': '#6cb6ff' }],
  ['light', 'Light', { '--bg': '#eef0f4', '--ed-bg': '#ffffff', '--accent': '#0b62d6' }],
  ['amber', 'Amber Monitor', { '--bg': '#100800', '--ed-bg': '#120900', '--accent': '#ffcc33' }],
];
const cssVar = (p, name) => p.ev(`getComputedStyle(document.documentElement).getPropertyValue(${JSON.stringify(name)}).trim()`);
const hexToRgb = (h) => `rgb(${parseInt(h.slice(1, 3), 16)}, ${parseInt(h.slice(3, 5), 16)}, ${parseInt(h.slice(5, 7), 16)})`;
const stored = (p) => p.ev("JSON.parse(localStorage.getItem('baysik.settings') || '{}')");
const edFont = (p) => p.ev('getComputedStyle(RC.app.active.editor.ta).fontSize');
async function setColorScheme(p, value) {
  await p.b.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value }] });
  await p.sleep(80);
}
async function submenuChecked(p, top, item) {
  await p.click('.menu-btn', top);
  await p.wait("!!document.querySelector('.menu-pop')", 3000);
  await p.hover('.menu-pop .menu-item', item);
  await p.sleep(100);
  const r = await p.ev("(() => { const pops = document.querySelectorAll('.menu-pop'); const sp = pops[pops.length - 1]; return [...sp.querySelectorAll('.menu-item.checked')].map(e => e.children[0].innerText); })()");
  await p.closeMenus();
  return r;
}
async function fontDialog(p, value, button = 'OK') {
  await p.menu('Options', 'Editor Font Size…');
  p.assert.equal(await p.waitModal(), 'Editor Font Size');
  if (value !== null) await p.modalInput(value);
  await p.modalButton(button);
  await p.sleep(80);
}

export default (t) => {
  t.beforeEach(async (p) => { await p.closeMenus(); });

  // ---- themes -------------------------------------------------------------------------------------
  t.test('default theme is QBasic Blue (data-theme="qbasic")', async (p) => {
    p.assert.equal(await p.attr('html', 'data-theme'), 'qbasic');
    p.assert.equal(await cssVar(p, '--bg'), '#000080');
    p.assert.deepEqual(await submenuChecked(p, 'Options', 'Theme'), ['QBasic Blue']);
  });

  t.test('Theme submenu lists all five themes', async (p) => {
    await p.click('.menu-btn', 'Options');
    await p.hover('.menu-pop .menu-item', 'Theme');
    await p.sleep(100);
    const labels = await p.ev("(() => { const pops = document.querySelectorAll('.menu-pop'); return [...pops[pops.length - 1].querySelectorAll('.menu-item')].map(e => e.children[0].innerText); })()");
    p.assert.deepEqual(labels, ['QBasic Blue', 'Dark', 'Light', 'Amber Monitor', 'Match System']);
    await p.closeMenus();
  });

  for (const [id, label, vars] of [...THEMES.slice(1), THEMES[0]]) {
    t.test(`Theme ▸ ${label} sets data-theme="${id}" and its CSS colours`, async (p) => {
      await p.menu('Options', 'Theme', label);
      p.assert.equal(await p.attr('html', 'data-theme'), id);
      for (const [k, v] of Object.entries(vars)) p.assert.equal(await cssVar(p, k), v, k);
      p.assert.equal(await p.ev('getComputedStyle(document.body).backgroundColor'), hexToRgb(vars['--bg']));
      p.assert.equal(await p.ev('RC.app.settings.theme'), id);
      p.assert.equal((await stored(p)).theme, id);
    });
    t.test(`Theme ▸ ${label} is check-marked in the menu`, async (p) => {
      p.assert.deepEqual(await submenuChecked(p, 'Options', 'Theme'), [label]);
    });
    t.test(`Theme ${label} persists across a reload`, async (p) => {
      await p.reload();
      p.assert.equal(await p.attr('html', 'data-theme'), id);
      p.assert.equal(await cssVar(p, '--bg'), vars['--bg']);
    });
  }

  t.test('the four fixed themes all have different --bg and --ed-bg colours', async (p) => {
    const bgs = new Set(), eds = new Set();
    for (const [id] of THEMES) {
      await p.fn((id) => { document.documentElement.dataset.theme = id; }, id);
      bgs.add(await cssVar(p, '--bg'));
      eds.add(await cssVar(p, '--ed-bg'));
    }
    await p.ev('RC.app.applyTheme()');
    p.assert.equal(bgs.size, 4);
    p.assert.equal(eds.size, 4);
  });

  t.test('the editor background follows the theme --ed-bg', async (p) => {
    await p.menu('Options', 'Theme', 'Light');
    const light = await p.ev("getComputedStyle(document.querySelector('.ed') || RC.app.active.editor.ta).backgroundColor");
    await p.menu('Options', 'Theme', 'Amber Monitor');
    const amber = await p.ev("getComputedStyle(document.querySelector('.ed') || RC.app.active.editor.ta).backgroundColor");
    p.assert.notEqual(light, amber);
  });

  t.test('Theme ▸ Match System with a light system uses the light colours', async (p) => {
    await setColorScheme(p, 'light');
    await p.menu('Options', 'Theme', 'Match System');
    p.assert.equal(await p.attr('html', 'data-theme'), 'auto');
    p.assert.equal(await cssVar(p, '--bg'), '#eef0f4');
    p.assert.equal(await cssVar(p, '--ed-bg'), '#fff');
    p.assert.equal((await stored(p)).theme, 'auto');
  });

  t.test('Theme Match System persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.attr('html', 'data-theme'), 'auto');
    p.assert.deepEqual(await submenuChecked(p, 'Options', 'Theme'), ['Match System']);
  });

  t.test('Theme ▸ Match System with a dark system uses the Dark theme colours', async (p) => {
    await setColorScheme(p, 'dark');
    p.assert.equal(await p.attr('html', 'data-theme'), 'auto');
    p.assert.equal(await cssVar(p, '--bg'), '#15171c');
  });

  t.test('Match System follows a live system colour-scheme change', async (p) => {
    await setColorScheme(p, 'light');
    await p.menu('Options', 'Theme', 'Match System');
    const a = await cssVar(p, '--bg');
    await setColorScheme(p, 'dark');
    const b = await cssVar(p, '--bg');
    p.assert.equal(a, '#eef0f4');
    p.assert.notEqual(a, b);
    await setColorScheme(p, '');
    await p.menu('Options', 'Theme', 'QBasic Blue');
  });

  // ---- editor font size ---------------------------------------------------------------------------
  t.test('Editor Font Size dialog shows the current size and the 10–28 range', async (p) => {
    await p.menu('Options', 'Editor Font Size…');
    p.assert.equal(await p.waitModal(), 'Editor Font Size');
    p.assert.match(await p.modalText(), /Size in pixels \(10–28\)/);
    p.assert.equal(await p.ev("document.querySelector('.modal-back:last-child input').value"), '15');
    await p.modalButton('Cancel');
  });

  t.test('font size 20 is applied to the editor and the --ed-font-size variable', async (p) => {
    await fontDialog(p, '20');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 20);
    p.assert.equal(await p.ev("document.documentElement.style.getPropertyValue('--ed-font-size')"), '20px');
    p.assert.equal(await edFont(p), '20px');
    p.assert.equal((await stored(p)).fontSize, 20);
  });

  t.test('font size persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 20);
    p.assert.equal(await edFont(p), '20px');
  });

  t.test('font size 10 (minimum) is accepted', async (p) => {
    await fontDialog(p, '10');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 10);
    p.assert.equal(await edFont(p), '10px');
  });

  t.test('font size 28 (maximum) is accepted', async (p) => {
    await fontDialog(p, '28');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 28);
    p.assert.equal(await edFont(p), '28px');
  });

  for (const bad of ['9', '29', '0', '-5', '100', 'abc', '']) {
    t.test(`font size "${bad}" is rejected and the size is unchanged`, async (p) => {
      await fontDialog(p, '16');
      await fontDialog(p, bad);
      p.assert.equal(await p.ev('RC.app.settings.fontSize'), 16);
      p.assert.equal(await edFont(p), '16px');
      p.assert.equal((await stored(p)).fontSize, 16);
    });
  }

  t.test('Cancel in the font size dialog keeps the size', async (p) => {
    await fontDialog(p, '22', 'Cancel');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 16);
  });

  t.test('Enter in the font size dialog applies the value', async (p) => {
    await p.menu('Options', 'Editor Font Size…');
    await p.waitModal();
    await p.modalInput('18');
    await p.key('Enter');
    await p.waitGone('.modal-back');
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 18);
  });

  t.test('Ctrl+= zooms the editor font in by 1px', async (p) => {
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.key('=', { ctrl: true });
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 19);
    p.assert.equal(await edFont(p), '19px');
  });

  t.test('Ctrl+- zooms the editor font out by 1px', async (p) => {
    await p.key('-', { ctrl: true });
    await p.key('-', { ctrl: true });
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 17);
  });

  t.test('zooming in stops at 28px', async (p) => {
    for (let i = 0; i < 14; i++) await p.key('=', { ctrl: true, after: 5 });
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 28);
  });

  t.test('zooming out stops at 10px', async (p) => {
    for (let i = 0; i < 22; i++) await p.key('-', { ctrl: true, after: 5 });
    p.assert.equal(await p.ev('RC.app.settings.fontSize'), 10);
    p.assert.equal(await edFont(p), '10px');
    await fontDialog(p, '15');
  });

  // ---- About -----------------------------------------------------------------------------------------
  t.test('Help ▸ About Baysik shows the version from package.json', async (p) => {
    const version = JSON.parse(readFileSync(new URL('../../../package.json', import.meta.url), 'utf8')).version;
    await p.menu('Help', 'About Baysik');
    p.assert.equal(await p.waitModal(), 'About Baysik');
    const txt = await p.modalText();
    p.assert.ok(txt.includes('version ' + version), txt);
    p.assert.doesNotMatch(txt, /@@VERSION@@/);
  });

  t.test('About describes the IDE, privacy and trademarks', async (p) => {
    const txt = await p.modalText();
    p.assert.match(txt, /GW-BASIC and QBasic programs/);
    p.assert.match(txt, /Runs entirely in your browser; nothing is uploaded/);
    p.assert.match(txt, /trademarks of Microsoft/);
    p.assert.match(txt, /GNU General Public License/);
    p.assert.match(txt, /Based on "Baysik" by Jyotiprakash Mishra/);
  });

  t.test('About closes with OK', async (p) => {
    await p.modalButton('OK');
    p.assert.equal(await p.modalOpen(), false);
  });

  // ---- Keyboard shortcuts -----------------------------------------------------------------------------
  const SHORTCUTS = [
    ['F5', 'Run / Continue'], ['Shift+F5', 'Restart'], ['Ctrl+F2', 'Stop'], ['Ctrl+Break', 'Pause a running program (Ctrl+C on the screen too)'],
    ['F8', 'Step Into'], ['F10', 'Step Over'], ['Shift+F8', 'Step Out'], ['F7', 'Run to Cursor'], ['F9', 'Toggle Breakpoint'],
    ['F4', 'Output screen full size'], ['F2', 'SUBs list'], ['F1', 'Help for word under cursor'],
    ['Ctrl+S', 'Save'], ['Ctrl+O', 'Open'], ['Alt+N', 'New program'], ['Ctrl+F / Ctrl+H', 'Find / Replace'], ['Ctrl+G', 'Go to line'],
    ['Ctrl+/', 'Toggle comment'], ['Ctrl+D', 'Duplicate line'], ['Tab / Shift+Tab', 'Indent / outdent'], ['Alt+letter', 'Open menu'],
    ['Ctrl+= / Ctrl+-', 'Zoom editor'],
  ];
  t.test('Help ▸ Keyboard Shortcuts lists every shortcut with its action', async (p) => {
    await p.menu('Help', 'Keyboard Shortcuts');
    p.assert.equal(await p.waitModal(), 'Keyboard Shortcuts');
    const rows = await p.ev("[...document.querySelectorAll('.modal-back:last-child .kbd-table tr')].map(r => [r.querySelector('kbd').innerText, r.children[1].innerText])");
    p.assert.deepEqual(rows, SHORTCUTS);
  });

  t.test('Keyboard Shortcuts notes that keys go to a running program', async (p) => {
    p.assert.match(await p.modalText(), /keys go to your program \(except Ctrl\+Break\)/);
    await p.modalButton('OK');
  });

  t.test('every menu shortcut for Run/Debug appears in the Keyboard Shortcuts list', async (p) => {
    const listed = SHORTCUTS.map((s) => s[0]).join(' ');
    for (const top of ['Run', 'Debug']) {
      await p.click('.menu-btn', top);
      const scs = (await p.menuItems()).map((x) => x.sc).filter(Boolean);
      await p.closeMenus();
      for (const sc of scs) p.assert.ok(listed.includes(sc), top + ': ' + sc);
    }
  });

  // ---- Disk usage -----------------------------------------------------------------------------------------
  t.test('Options ▸ Disk Usage shows entry count and KB used of 96 MB', async (p) => {
    await p.menu('Options', 'Disk Usage & Reset…');
    p.assert.equal(await p.waitModal(), 'Virtual Disk C:');
    const [n, kb] = await p.ev("[RC.app.vfs.drives.C.entries.size, (RC.app.vfs.drives.C.totalSize() / 1024).toFixed(1)]");
    p.assert.ok((await p.modalText()).includes(`${n} files and folders, ${kb} KB used of 96 MB.`), await p.modalText());
    p.assert.deepEqual(await p.ev("[...document.querySelectorAll('.modal-back:last-child .modal-foot button')].map(b => b.innerText)"), ['Close', 'Reinstall Examples', 'Erase Everything…']);
    await p.modalButton('Close');
  });

  t.test('Disk Usage numbers grow when a file is added', async (p) => {
    await p.ev("RC.app.vfs.writeFile('C:\\\\MYPROGS\\\\BIG.DAT', new Uint8Array(20480), {trusted: true})");
    await p.menu('Options', 'Disk Usage & Reset…');
    await p.waitModal();
    const [n, kb] = await p.ev("[RC.app.vfs.drives.C.entries.size, (RC.app.vfs.drives.C.totalSize() / 1024).toFixed(1)]");
    p.assert.ok((await p.modalText()).includes(`${n} files and folders, ${kb} KB used`));
    p.assert.ok(Number(kb) >= 20);
    await p.modalButton('Close');
  });

  t.test('Reinstall Examples restores a deleted sample program', async (p) => {
    await p.ev("RC.app.vfs.unlink('C:\\\\SAMPLES\\\\GUESS.BAS')");
    await p.menu('Options', 'Disk Usage & Reset…');
    await p.waitModal();
    await p.modalButton('Reinstall Examples');
    await p.waitToast(/Examples reinstalled in C:\\SAMPLES/);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\SAMPLES\\\\GUESS.BAS')"), true);
  });

  t.test('Erase Everything asks for confirmation; Cancel keeps the files', async (p) => {
    await p.menu('Options', 'Disk Usage & Reset…');
    await p.waitModal();
    await p.modalButton('Erase Everything…');
    p.assert.equal(await p.waitModal(), 'Erase disk?');
    p.assert.match(await p.modalText(), /Delete all files on C: and reset settings\? This cannot be undone\./);
    await p.modalButton('Cancel');
    await p.sleep(500);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\MYPROGS\\\\BIG.DAT')"), true);
  });

  t.test('Erase Everything deletes user files and resets settings after a reload', async (p) => {
    await p.menu('Options', 'Theme', 'Amber Monitor');
    await p.ev("RC.app.vfs.writeFile('C:\\\\MYPROGS\\\\MINE.BAS', RC.strToBytes('PRINT 1'), {trusted: true}); window.__beforeErase = 1");
    await p.menu('Options', 'Disk Usage & Reset…');
    await p.waitModal();
    await p.modalButton('Erase Everything…');
    await p.waitModal();
    await p.modalButton('Erase');
    await p.wait('!window.__beforeErase && window.__baysikReady === true', 10000);
    await p.sleep(300);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\MYPROGS\\\\MINE.BAS')"), false);
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\MYPROGS\\\\BIG.DAT')"), false);
    p.assert.equal(await p.attr('html', 'data-theme'), 'qbasic');
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\MYPROGS\\\\HELLO.BAS')"), true);
  });
};
