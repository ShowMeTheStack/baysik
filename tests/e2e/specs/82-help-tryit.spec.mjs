// Help: every "Try it" example opens C:\MYPROGS\TRY_*.BAS containing the example, and the example compiles.
import { KEYWORDS, ensureHelp, closeAll, navSel, tryPath } from './82-help-kw.lib.mjs';

const WITH_EX = KEYWORDS.filter((k) => k[4]);

export default (t) => {
  t.test(`there are ${WITH_EX.length} keyword examples`, async (p) => {
    p.assert.ok(WITH_EX.length >= 40);
    p.assert.equal(await p.ev('RC.BASIC_HELP.KEYWORDS.filter(k => k[4]).length'), WITH_EX.length);
  });
  for (const [name, , , , ex] of WITH_EX) {
    const path = tryPath(name);
    t.test(`Try it for ${name} opens ${path} with the example, which compiles`, async (p) => {
      await closeAll(p);
      await ensureHelp(p);
      await p.click(navSel(name));
      await p.click('.modal .help-main button[data-try]');
      await p.wait(`!document.querySelector('.modal-back') && RC.app.active && RC.app.active.path === ${JSON.stringify(path)}`, 4000);
      const code = await p.code();
      const lines = code.split('\n');
      p.assert.match(lines[0], new RegExp("^' Example for " + name.replace(/\$/g, '\\$') + ' . press F5 to run$'));
      p.assert.equal(lines.slice(1).join('\n'), ex + '\n', 'example text follows the header');
      p.assert.equal(await p.fn((x) => RC.app.decodeText(RC.app.vfs.readFile(x)), path), code, 'file on disk matches editor');
      const want = code;
      p.assert.equal(await p.ev('RC.app.active.dirty'), false);
      p.assert.match(await p.status(), /Example opened — press F5 to run it/);
      const err = await p.fn((x, src) => { try { RC.app.runner.compile(x, src); return null; } catch (e) { return String(e.message || e); } }, path, want);
      p.assert.equal(err, null, 'compile error: ' + err);
    });
  }
  t.test('Try it header comment uses only characters DOS files can store (no "?" substitution)', async (p) => {
    await closeAll(p);
    await ensureHelp(p);
    await p.click(navSel('IF'));
    await p.click('.modal .help-main button[data-try]');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\MYPROGS\\\\TRY_IF.BAS'");
    p.assert.equal((await p.code()).split('\n')[0], "' Example for IF - press F5 to run");
  });
  t.test('Try it on a keyword whose file already exists replaces its contents (LINE then LINE INPUT share TRY_LINE)', async (p) => {
    const li = KEYWORDS.find((k) => k[0] === 'LINE');
    await closeAll(p);
    await ensureHelp(p);
    await p.click(navSel('LINE'));
    await p.click('.modal .help-main button[data-try]');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\MYPROGS\\\\TRY_LINE.BAS'");
    p.assert.ok((await p.code()).includes(li[4]));
    p.assert.equal(await p.ev("RC.app.docs.filter(d => d.path === 'C:\\\\MYPROGS\\\\TRY_LINE.BAS').length"), 1);
  });
  t.test('a Try it example can be run with F5', async (p) => {
    await closeAll(p);
    await ensureHelp(p);
    await p.click(navSel('FOR'));
    await p.click('.modal .help-main button[data-try]');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\MYPROGS\\\\TRY_FOR.BAS'");
    await p.ev('RC.app.active.editor.focus()');
    await p.key('F5');
    await p.waitState(['ended', 'error']);
    p.assert.equal(await p.state(), 'ended');
    p.assert.match(await p.screen(), /10\s+9\s+8.*1\s*\n?Liftoff!/s);
  });
  t.test('Try it files are ordinary user files (not protected)', async (p) => {
    p.assert.equal(await p.ev("RC.app.isProtected('C:\\\\MYPROGS\\\\TRY_FOR.BAS')"), false);
    p.assert.ok(!(await p.exists('#editorTabs .tab.active .lock')));
  });
};
