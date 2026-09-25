// Options: tab width, capitalize keywords, auto indent, autosave, CRT scanlines, sound and volume.
const stored = (p) => p.ev("JSON.parse(localStorage.getItem('baysik.settings') || '{}')");
async function optionsChecked(p) {
  await p.click('.menu-btn', 'Options');
  const items = await p.menuItems();
  await p.closeMenus();
  return Object.fromEntries(items.map((x) => [x.label, x.checked]));
}
async function subChecked(p, item) {
  await p.click('.menu-btn', 'Options');
  await p.hover('.menu-pop .menu-item', item);
  await p.sleep(100);
  const r = await p.ev("(() => { const pops = document.querySelectorAll('.menu-pop'); return [...pops[pops.length - 1].querySelectorAll('.menu-item.checked')].map(e => e.children[0].innerText); })()");
  await p.closeMenus();
  return r;
}
async function freshEditor(p, text = '') {
  await p.newFile('C:\\MYPROGS\\OPT.BAS', text);
  await p.ev('RC.app.active.editor.setCursor(0, 0)');
  await p.sleep(40);
}
async function typeAtEnd(p, text) {
  await p.ev('(() => { const e = RC.app.active.editor; e.ta.focus(); e.ta.setSelectionRange(e.ta.value.length, e.ta.value.length); e.updateCursor(); })()');
  await p.type(text);
}
const gain = (p) => p.ev('(() => { const a = RC.app.runner.audio; a.ensureCtx(); return a.gain ? a.gain.gain.value : null; })()');
const near = (p, a, b) => p.assert.ok(Math.abs(a - b) < 1e-6, `${a} ≈ ${b}`);

export default (t) => {
  t.beforeEach(async (p) => { await p.closeMenus(); });

  // ---- tab width -----------------------------------------------------------------------------------
  t.test('Tab Width defaults to 4 spaces and Tab inserts 4 spaces', async (p) => {
    p.assert.deepEqual(await subChecked(p, 'Tab Width'), ['4 spaces']);
    await freshEditor(p, 'X');
    await p.key('Tab');
    p.assert.equal(await p.code(), '    X');
  });

  for (const n of [2, 8, 4]) {
    t.test(`Tab Width ▸ ${n} spaces makes Tab insert ${n} spaces`, async (p) => {
      await p.menu('Options', 'Tab Width', n + ' spaces');
      p.assert.equal(await p.ev('RC.app.settings.tabSize'), n);
      p.assert.equal((await stored(p)).tabSize, n);
      await freshEditor(p, 'X');
      await p.key('Tab');
      p.assert.equal(await p.code(), ' '.repeat(n) + 'X');
      p.assert.deepEqual(await subChecked(p, 'Tab Width'), [n + ' spaces']);
    });
  }

  t.test('Tab Width persists across a reload', async (p) => {
    await p.menu('Options', 'Tab Width', '8 spaces');
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.tabSize'), 8);
    await freshEditor(p, 'Y');
    await p.key('Tab');
    p.assert.equal(await p.code(), '        Y');
  });

  t.test('Shift+Tab outdents by the tab width', async (p) => {
    await freshEditor(p, '        Z');
    await p.key('Tab', { shift: true });
    p.assert.equal(await p.code(), 'Z');
    await p.menu('Options', 'Tab Width', '4 spaces');
  });

  // ---- capitalize keywords -------------------------------------------------------------------------------
  t.test('Capitalize Keywords As You Type is on by default and capitalizes on Enter', async (p) => {
    p.assert.equal((await optionsChecked(p))['Capitalize Keywords As You Type'], true);
    await freshEditor(p, '');
    await typeAtEnd(p, 'print "hi"\n');
    p.assert.equal((await p.code()).split('\n')[0], 'PRINT "hi"');
  });

  t.test('turning Capitalize Keywords off leaves typed keywords as typed', async (p) => {
    await p.menu('Options', 'Capitalize Keywords As You Type');
    p.assert.equal(await p.ev('RC.app.settings.autoFormat'), false);
    p.assert.equal((await stored(p)).autoFormat, false);
    await freshEditor(p, '');
    await typeAtEnd(p, 'print "hi"\n');
    p.assert.equal((await p.code()).split('\n')[0], 'print "hi"');
    p.assert.equal((await optionsChecked(p))['Capitalize Keywords As You Type'], false);
  });

  t.test('Capitalize Keywords off persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.autoFormat'), false);
    await freshEditor(p, '');
    await typeAtEnd(p, 'for i = 1 to 2\n');
    p.assert.match((await p.code()).split('\n')[0], /^for i = 1 to 2$/);
  });

  t.test('Edit ▸ Capitalize Keywords still formats the whole file when the option is off', async (p) => {
    await freshEditor(p, 'print "a"\ncls\nend');
    await p.menu('Edit', 'Capitalize Keywords');
    p.assert.equal(await p.code(), 'PRINT "a"\nCLS\nEND');
  });

  t.test('turning Capitalize Keywords back on capitalizes again', async (p) => {
    await p.menu('Options', 'Capitalize Keywords As You Type');
    p.assert.equal(await p.ev('RC.app.settings.autoFormat'), true);
    await freshEditor(p, '');
    await typeAtEnd(p, 'cls\n');
    p.assert.equal((await p.code()).split('\n')[0], 'CLS');
  });

  // ---- auto indent ---------------------------------------------------------------------------------------
  t.test('Auto Indent (default on) indents the line after FOR by the tab width', async (p) => {
    p.assert.equal((await optionsChecked(p))['Auto Indent'], true);
    await freshEditor(p, '');
    await typeAtEnd(p, 'FOR I = 1 TO 3\n');
    p.assert.equal(await p.code(), 'FOR I = 1 TO 3\n    ');
  });

  t.test('Auto Indent uses the current tab width (2)', async (p) => {
    await p.menu('Options', 'Tab Width', '2 spaces');
    await freshEditor(p, '');
    await typeAtEnd(p, 'DO\n');
    p.assert.equal(await p.code(), 'DO\n  ');
    await p.menu('Options', 'Tab Width', '4 spaces');
  });

  t.test('turning Auto Indent off keeps only the existing indentation', async (p) => {
    await p.menu('Options', 'Auto Indent');
    p.assert.equal(await p.ev('RC.app.settings.autoIndent'), false);
    p.assert.equal((await stored(p)).autoIndent, false);
    await freshEditor(p, '');
    await typeAtEnd(p, 'FOR I = 1 TO 3\n');
    p.assert.equal(await p.code(), 'FOR I = 1 TO 3\n');
    p.assert.equal((await optionsChecked(p))['Auto Indent'], false);
  });

  t.test('with Auto Indent off, Enter still keeps the current line indent', async (p) => {
    await freshEditor(p, '');
    await typeAtEnd(p, '  PRINT 1\n');
    p.assert.equal(await p.code(), '  PRINT 1\n  ');
  });

  t.test('Auto Indent off persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.autoIndent'), false);
    await freshEditor(p, '');
    await typeAtEnd(p, 'WHILE X\n');
    p.assert.equal(await p.code(), 'WHILE X\n');
    await p.menu('Options', 'Auto Indent');
    p.assert.equal(await p.ev('RC.app.settings.autoIndent'), true);
  });

  // ---- autosave -----------------------------------------------------------------------------------------
  t.test('Autosave on (default): running saves the edited program to disk', async (p) => {
    p.assert.equal((await optionsChecked(p))['Autosave'], true);
    await p.newFile('C:\\MYPROGS\\AUTO.BAS', 'PRINT "OLD"');
    await p.setCode('PRINT "NEW"');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.equal(await p.ev("RC.app.vfs.readText('C:\\\\MYPROGS\\\\AUTO.BAS')"), 'PRINT "NEW"');
    p.assert.equal(await p.ev('RC.app.active.dirty'), false);
  });

  t.test('Autosave on: the periodic autosave writes edits', async (p) => {
    await p.setCode('PRINT "TICK"');
    await p.ev('RC.app.autosaveTick()');
    p.assert.equal(await p.ev("RC.app.vfs.readText('C:\\\\MYPROGS\\\\AUTO.BAS')"), 'PRINT "TICK"');
  });

  t.test('Autosave off: running uses the edited code but does not save it', async (p) => {
    await p.menu('Options', 'Autosave');
    p.assert.equal(await p.ev('RC.app.settings.autosave'), false);
    p.assert.equal((await stored(p)).autosave, false);
    await p.setCode('PRINT "UNSAVED RUN"');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.match(await p.screen(), /UNSAVED RUN/);
    p.assert.equal(await p.ev("RC.app.vfs.readText('C:\\\\MYPROGS\\\\AUTO.BAS')"), 'PRINT "TICK"');
    p.assert.equal(await p.ev('RC.app.active.dirty'), true);
  });

  t.test('Autosave off: the periodic autosave does nothing', async (p) => {
    await p.ev('RC.app.autosaveTick()');
    await p.sleep(4300);
    p.assert.equal(await p.ev("RC.app.vfs.readText('C:\\\\MYPROGS\\\\AUTO.BAS')"), 'PRINT "TICK"');
    p.assert.equal((await optionsChecked(p))['Autosave'], false);
  });

  t.test('Autosave off: Ctrl+S still saves', async (p) => {
    await p.ev('RC.app.active.editor.setCursor(0, 0)');
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.ev("RC.app.vfs.readText('C:\\\\MYPROGS\\\\AUTO.BAS')"), 'PRINT "UNSAVED RUN"');
  });

  t.test('Autosave off persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.autosave'), false);
    p.assert.equal((await optionsChecked(p))['Autosave'], false);
    await p.menu('Options', 'Autosave');
    p.assert.equal(await p.ev('RC.app.settings.autosave'), true);
  });

  // ---- CRT scanlines ---------------------------------------------------------------------------------------
  t.test('CRT Scanlines is off by default (overlay hidden)', async (p) => {
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), false);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('crt')).display"), 'none');
  });

  t.test('Options ▸ CRT Scanlines shows the scanline overlay', async (p) => {
    await p.menu('Options', 'CRT Scanlines');
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), true);
    p.assert.equal(await p.ev("getComputedStyle(document.getElementById('crt')).display"), 'block');
    p.assert.match(await p.ev("getComputedStyle(document.getElementById('crt')).backgroundImage"), /repeating-linear-gradient/);
    p.assert.equal((await stored(p)).crt, true);
    p.assert.equal((await optionsChecked(p))['CRT Scanlines'], true);
  });

  t.test('CRT Scanlines persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), true);
  });

  t.test('turning CRT Scanlines off hides the overlay', async (p) => {
    await p.menu('Options', 'CRT Scanlines');
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), false);
    p.assert.equal((await stored(p)).crt, false);
  });

  // ---- sound & volume ----------------------------------------------------------------------------------------
  t.test('Sound is on by default at 50% volume (gain 0.08)', async (p) => {
    const o = await optionsChecked(p);
    p.assert.equal(o['Sound'], true);
    near(p, await p.ev('RC.app.runner.audio.volume'), 0.08);
    near(p, await gain(p), Math.fround(0.08));
    p.assert.deepEqual(await subChecked(p, 'Volume'), ['50%']);
  });

  t.test('Options ▸ Sound off sets the audio gain to 0', async (p) => {
    await p.menu('Options', 'Sound');
    p.assert.equal(await p.ev('RC.app.settings.sound'), false);
    p.assert.equal(await p.ev('RC.app.runner.audio.volume'), 0);
    p.assert.equal(await gain(p), 0);
    p.assert.equal((await stored(p)).sound, false);
    p.assert.equal((await optionsChecked(p))['Sound'], false);
  });

  t.test('Sound off persists across a reload (gain stays 0)', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.sound'), false);
    p.assert.equal(await p.ev('RC.app.runner.audio.volume'), 0);
    p.assert.equal(await gain(p), 0);
  });

  t.test('Options ▸ Sound on restores the gain for the chosen volume', async (p) => {
    await p.menu('Options', 'Sound');
    p.assert.equal(await p.ev('RC.app.settings.sound'), true);
    near(p, await gain(p), Math.fround(0.08));
  });

  for (const [label, v] of [['25%', 0.25], ['75%', 0.75], ['100%', 1], ['50%', 0.5]]) {
    t.test(`Volume ▸ ${label} sets the audio gain to ${(v * 0.16).toFixed(2)}`, async (p) => {
      await p.menu('Options', 'Volume', label);
      p.assert.equal(await p.ev('RC.app.settings.volume'), v);
      p.assert.equal((await stored(p)).volume, v);
      near(p, await p.ev('RC.app.runner.audio.volume'), v * 0.16);
      near(p, await gain(p), Math.fround(v * 0.16));
      p.assert.deepEqual(await subChecked(p, 'Volume'), [label]);
    });
  }

  t.test('choosing a Volume while sound is off turns sound back on', async (p) => {
    await p.menu('Options', 'Sound');
    p.assert.equal(await gain(p), 0);
    await p.menu('Options', 'Volume', '75%');
    p.assert.equal(await p.ev('RC.app.settings.sound'), true);
    near(p, await gain(p), Math.fround(0.12));
    p.assert.equal((await optionsChecked(p))['Sound'], true);
  });

  t.test('Volume persists across a reload', async (p) => {
    await p.reload();
    p.assert.equal(await p.ev('RC.app.settings.volume'), 0.75);
    near(p, await p.ev('RC.app.runner.audio.volume'), 0.12);
    near(p, await gain(p), Math.fround(0.12));
  });

  t.test('all Options settings survive a reload together', async (p) => {
    await p.menu('Options', 'Theme', 'Dark');
    await p.menu('Options', 'Tab Width', '2 spaces');
    await p.menu('Options', 'CRT Scanlines');
    await p.menu('Options', 'Volume', '25%');
    await p.reload();
    const s = await p.ev('RC.app.settings');
    p.assert.equal(s.theme, 'dark');
    p.assert.equal(s.tabSize, 2);
    p.assert.equal(s.crt, true);
    p.assert.equal(s.volume, 0.25);
    p.assert.equal(await p.attr('html', 'data-theme'), 'dark');
    p.assert.equal(await p.ev("document.getElementById('crt').classList.contains('on')"), true);
  });
};
