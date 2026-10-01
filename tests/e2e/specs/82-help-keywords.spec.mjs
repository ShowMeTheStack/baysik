// Help: EVERY keyword entry renders its name, category, syntax, description and example.
import { KEYWORDS, ensureHelp, navSel } from './82-help-kw.lib.mjs';

export default (t) => {
  t.test(`help data has ${KEYWORDS.length} keyword entries and the page agrees`, async (p) => {
    p.assert.ok(KEYWORDS.length >= 140);
    p.assert.deepEqual(await p.ev('RC.BASIC_HELP.KEYWORDS.map(k => k[0])'), KEYWORDS.map((k) => k[0]));
  });
  for (const [name, cat, syntax, desc, ex] of KEYWORDS) {
    t.test(`keyword ${name} (${cat}) renders name, category, syntax and description`, async (p) => {
      await ensureHelp(p);
      await p.click(navSel(name));
      const r = await p.ev(`(() => {
        const m = document.querySelector('.modal .help-main');
        const ps = [...m.querySelectorAll(':scope > p')];
        return { h2: m.querySelector('h2').textContent, cat: (m.querySelector('p.muted') || {}).textContent,
          syntax: (m.querySelector('.syntax') || {}).textContent, desc: ps[1] ? ps[1].textContent : null,
          tryBtn: !!m.querySelector('button[data-try]'), pre: m.querySelector('pre') ? m.querySelector('pre').textContent : null,
          sel: [...document.querySelectorAll('.modal .help-nav div.sel')].map(e => e.dataset.key) };
      })()`);
      p.assert.equal(r.h2, name);
      p.assert.equal(r.cat, cat);
      p.assert.equal(r.syntax, syntax);
      p.assert.ok(syntax.length > 0 && desc.length > 0);
      p.assert.equal(r.desc, desc);
      p.assert.deepEqual(r.sel, [name]);
      if (ex) {
        p.assert.equal(r.tryBtn, true, 'Try it button');
        p.assert.equal(r.pre, ex);
      } else {
        p.assert.equal(r.tryBtn, false, 'no Try it without example');
        p.assert.equal(r.pre, null);
      }
      // keyword is found by name lookup too
      p.assert.equal(await p.fn((n) => RC.Help.find(n)[0], name), name);
    });
  }
};
