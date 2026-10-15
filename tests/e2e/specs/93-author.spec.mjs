// Help > About the Author: where to find it and what it shows.
export default function (t) {
  t.test('Help > About the Author opens the author page', async (p) => {
    await p.menu('Help', 'About the Author');
    p.assert.equal(await p.waitModal(), 'About the Author');
    const text = await p.modalText();
    p.assert.match(text, /Jyotiprakash Mishra/);
    p.assert.match(text, /Education/i);
    p.assert.match(text, /Other things I made/i);
    await p.key('Escape');
  });
  t.test('the photo is embedded in the page, greyscale and shown with scanlines', async (p) => {
    await p.ev('void RC.authorDialog()');
    await p.waitModal();
    const img = await p.ev("(() => { const i = document.querySelector('.author-photo img'); return { src: i.src.slice(0, 22), ok: i.complete && i.naturalWidth === 128, alt: i.alt }; })()");
    p.assert.equal(img.src, 'data:image/png;base64,');
    p.assert.ok(img.ok);
    p.assert.match(img.alt, /Jyotiprakash Mishra/);
    const grey = await p.ev("(() => { const i = document.querySelector('.author-photo img'); const c = document.createElement('canvas'); c.width = i.naturalWidth; c.height = i.naturalHeight; const x = c.getContext('2d'); x.drawImage(i, 0, 0); const d = x.getImageData(0, 0, c.width, c.height).data; for (let k = 0; k < d.length; k += 4) if (d[k] !== d[k + 1] || d[k] !== d[k + 2]) return false; return true; })()");
    p.assert.equal(grey, true, 'every pixel is grey');
    p.assert.match(await p.ev("getComputedStyle(document.querySelector('.author-photo'), '::after').backgroundImage"), /repeating-linear-gradient/);
    await p.key('Escape');
  });
  t.test('links open in a new tab and include the other tools', async (p) => {
    await p.ev('void RC.authorDialog()');
    await p.waitModal();
    const links = await p.ev("[...document.querySelectorAll('.author a')].map(a => [a.textContent, a.getAttribute('href'), a.target])");
    for (const [, href, target] of links) { p.assert.ok(/^(https:|mailto:)/.test(href), href); p.assert.equal(target, '_blank'); }
    const hrefs = links.map((l) => l[1]);
    for (const u of ['https://xv6.jyotiprakash.org', 'https://lohgo.jyotiprakash.org', 'https://github.com/ShowMeTheStack', 'mailto:mail@jyotiprakash.org']) p.assert.ok(hrefs.includes(u), u);
    await p.key('Escape');
  });
  t.test('About Baysik links to the author page', async (p) => {
    await p.ev('void RC.app.aboutDialog()');
    await p.waitModal();
    await p.click('#aboutAuthorLink');
    await p.wait("document.querySelectorAll('.modal-back').length === 1 && document.querySelector('.modal-head').textContent === 'About the Author'", 3000);
    await p.key('Escape');
  });
  t.test('the start screen credits the author on one line near the bottom', async (p) => {
    await p.fresh();
    p.assert.match(await p.screen(), /Made by Jyotiprakash Mishra {2}- {2}Help > About the Author/);
  });
  t.test('on a phone the author page fits the screen', async (p) => {
    await p.fresh({ width: 390, height: 844, mobile: true, touch: true });
    await p.ev('void RC.authorDialog()');
    await p.waitModal();
    p.assert.ok(await p.noHScroll());
    const r = await p.rect('.modal');
    p.assert.ok(r.x >= 0 && r.right <= 390, JSON.stringify(r));
    await p.key('Escape');
  });
}
