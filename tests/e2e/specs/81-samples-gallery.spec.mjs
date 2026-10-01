// Starter examples gallery: every card opens the right file and runs without errors.
const INFO_PATHS = [
  ['HELLO.BAS', 'Hello, World'], ['SAMPLES\\GUESS.BAS', 'Guess the Number'], ['SAMPLES\\TIMESTBL.BAS', 'Times Table'],
  ['SAMPLES\\COLORS.BAS', 'Color Chart'], ['SAMPLES\\CLASSIC.BAS', 'GW-BASIC Quiz'], ['SAMPLES\\FACTORL.BAS', 'Factorials & Recursion'],
  ['SAMPLES\\HANOI.BAS', 'Towers of Hanoi'], ['SAMPLES\\SNAKE.BAS', 'Snake'], ['SAMPLES\\SPIRAL.BAS', 'Spirals'],
  ['SAMPLES\\TURTLE.BAS', 'Turtle Drawing'], ['SAMPLES\\SIERPIN.BAS', 'Chaos Game'], ['SAMPLES\\MANDEL.BAS', 'Mandelbrot Set'],
  ['SAMPLES\\PLASMA.BAS', 'Plasma'], ['SAMPLES\\SPRITES.BAS', 'Bouncing Sprites'], ['SAMPLES\\SORTS.BAS', 'Sorting Visualizer'],
  ['SAMPLES\\LIFE.BAS', 'Game of Life'], ['SAMPLES\\CLOCK.BAS', 'Analog Clock'], ['SAMPLES\\MUSIC.BAS', 'Music Box'],
  ['SAMPLES\\MODES.BAS', 'Screen Mode Tour'], ['SAMPLES\\PHONEBK.BAS', 'Phone Book'], ['SAMPLES\\DIARY.BAS', 'Diary'],
  ['SAMPLES\\MULTI\\MAIN.BAS', 'Multi-file Program'],
];
const pathFor = (rel) => (rel.startsWith('SAMPLES\\') ? 'C:\\' + rel : 'C:\\MYPROGS\\' + rel);

async function closeAll(p) {
  for (let i = 0; i < 5 && await p.modalOpen(); i++) { await p.key('Escape'); await p.sleep(60); }
  await p.closeMenus();
}
async function openGallery(p) {
  await closeAll(p);
  await p.menu('Help', 'Starter Examples…');
  p.assert.equal(await p.waitModal(), 'Example Programs');
}
async function closeDocs(p) {
  await p.ev('RC.app.stop()');
  await p.ev(`(() => { const a = RC.app; for (const d of a.docs.slice()) { if (d.dirty) { d.editor.setValue(d.savedText); d.dirty = false; } a.closeDoc(d); } })()`);
  await p.sleep(30);
}
const cardTitles = (p) => p.ev("[...document.querySelectorAll('.modal .gallery .card .t')].map(e => e.textContent)");
async function clickCard(p, title) {
  const idx = (await cardTitles(p)).indexOf(title);
  p.assert.ok(idx >= 0, 'card ' + title);
  await p.click(`.modal .gallery .card:nth-child(${idx + 1})`);
}

export default (t) => {
  t.test('Help ▸ Starter Examples… opens the Example Programs gallery', async (p) => {
    await openGallery(p);
    p.assert.match(await p.modalText(), /Pick one to open it, then press F5/);
    p.assert.match(await p.modalText(), /originals live in C:\\SAMPLES/);
  });
  t.test('the library Starter examples link opens the same gallery', async (p) => {
    await closeAll(p);
    await p.click('#tbExamples');
    await p.waitModal();
    await p.click('.modal .help-nav div', 'Starter examples');
    p.assert.equal(await p.waitModal(), 'Example Programs');
    p.assert.equal(await p.count('.modal-back'), 1);
  });
  t.test('gallery shows one card per example in the documented order', async (p) => {
    await openGallery(p);
    p.assert.deepEqual(await cardTitles(p), INFO_PATHS.map((x) => x[1]));
    p.assert.equal(await p.ev('RC.Samples.INFO.length'), INFO_PATHS.length);
  });
  t.test('every card shows its description and tags from Samples.INFO', async (p) => {
    await openGallery(p);
    const cards = await p.ev("[...document.querySelectorAll('.modal .gallery .card')].map(c => ({ t: c.querySelector('.t').textContent, d: c.querySelector('.d').textContent, tags: [...c.querySelectorAll('.tags span')].map(s => s.textContent) }))");
    const info = await p.ev('RC.Samples.INFO');
    p.assert.equal(cards.length, info.length);
    info.forEach(([, title, desc, tags], i) => {
      p.assert.equal(cards[i].t, title);
      p.assert.equal(cards[i].d, desc);
      p.assert.deepEqual(cards[i].tags, tags);
      p.assert.ok(desc.length > 10);
    });
  });
  t.test('gallery Close button closes it', async (p) => {
    await openGallery(p);
    p.assert.deepEqual(await p.texts('.modal-back:last-child .modal-foot button'), ['Close']);
    await p.modalButton('Close');
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('gallery closes with Escape', async (p) => {
    await openGallery(p);
    await p.key('Escape');
    await p.sleep(60);
    p.assert.equal(await p.modalOpen(), false);
  });
  t.test('every sample file is installed on C: at start-up', async (p) => {
    const missing = await p.ev("Object.keys(RC.SAMPLE_FILES).map(r => RC.Samples.pathFor(r)).filter(x => !RC.app.vfs.exists(x))");
    p.assert.deepEqual(missing, []);
  });
  t.test('every gallery card refers to an existing sample file', async (p) => {
    const keys = await p.ev('Object.keys(RC.SAMPLE_FILES)');
    for (const [rel] of INFO_PATHS) p.assert.ok(keys.includes(rel), rel);
  });
  t.test('Samples.pathFor maps SAMPLES\\ to C:\\SAMPLES and others to C:\\MYPROGS', async (p) => {
    p.assert.equal(await p.ev("RC.Samples.pathFor('SAMPLES\\\\GUESS.BAS')"), 'C:\\SAMPLES\\GUESS.BAS');
    p.assert.equal(await p.ev("RC.Samples.pathFor('HELLO.BAS')"), 'C:\\MYPROGS\\HELLO.BAS');
  });

  for (const [rel, title] of INFO_PATHS) {
    const path = pathFor(rel);
    t.test(`card "${title}" opens ${path} and runs without errors`, async (p) => {
      await closeDocs(p);
      await openGallery(p);
      await clickCard(p, title);
      await p.wait(`RC.app.active && RC.app.active.path === ${JSON.stringify(path)}`, 5000);
      p.assert.equal(await p.modalOpen(), false);
      p.assert.match(await p.status(), new RegExp('Opened ' + path.replace(/\\/g, '\\\\').replace(/\./g, '\\.') + ' — press F5 to run'));
      const expected = await p.fn((r) => RC.SAMPLE_FILES[r].replace(/\r?\n/g, '\n').replace(/\n+$/, ''), rel);
      p.assert.equal((await p.code()).replace(/\n+$/, ''), expected, 'editor shows the sample source');
      p.assert.equal(await p.ev('!!RC.app.active.dirty'), false);
      p.assert.equal(await p.exists('#editorTabs .tab.active .lock'), rel.startsWith('SAMPLES\\'), 'protected marker only for C:\\SAMPLES');
      await p.ev('RC.app.active.editor.focus()');
      await p.key('F5');
      await p.sleep(150);
      for (const k of ['5', 'Enter', 'y', 'ArrowRight', ' ', 'Enter']) if (await p.ev('RC.app.programHasKeys()')) await p.key(k, { after: 25 });
      await p.sleep(250);
      const res = await p.fn(() => ({ state: RC.app.runner.state, status: document.getElementById('statusbar').innerText, problems: RC.app.panels.problems.length }));
      await p.stopProgram();
      p.assert.equal(res.problems, 0, res.status);
      p.assert.doesNotMatch(res.status, /^(Syntax|Runtime error)/);
      p.assert.notEqual(res.state, 'error', res.status);
      p.assert.notEqual(res.state, 'idle', 'program started');
    }, { timeout: 20000 });
  }

  t.test('a deleted sample is reinstalled when its card is clicked', async (p) => {
    await closeDocs(p);
    await p.ev("RC.app.vfs.unlink ? RC.app.vfs.unlink('C:\\\\SAMPLES\\\\SPIRAL.BAS') : RC.app.vfs.remove('C:\\\\SAMPLES\\\\SPIRAL.BAS')");
    p.assert.equal(await p.ev("RC.app.vfs.exists('C:\\\\SAMPLES\\\\SPIRAL.BAS')"), false);
    await openGallery(p);
    await clickCard(p, 'Spirals');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\SAMPLES\\\\SPIRAL.BAS'");
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\SAMPLES\\\\SPIRAL.BAS')"));
    p.assert.match(await p.code(), /SCREEN 12|LINE/);
  });
  t.test('a sample opened from the gallery is protected: Ctrl+S offers Save Your Copy', async (p) => {
    await closeDocs(p);
    await openGallery(p);
    await clickCard(p, 'Guess the Number');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\SAMPLES\\\\GUESS.BAS'");
    await p.ev('RC.app.active.editor.focus()');
    await p.insertText("' mine\n");
    await p.key('s', { ctrl: true });
    p.assert.equal(await p.waitModal(), 'Save Your Copy');
    p.assert.equal(await p.ev("document.querySelector('.modal input').value"), 'C:\\MYPROGS\\GUESS.BAS');
    await p.modalButton('Cancel');
    p.assert.equal(await p.activePath(), 'C:\\SAMPLES\\GUESS.BAS');
    await closeDocs(p);
  });
  t.test('HELLO.BAS card opens the user copy in C:\\MYPROGS which is not protected', async (p) => {
    await closeDocs(p);
    await openGallery(p);
    await clickCard(p, 'Hello, World');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\MYPROGS\\\\HELLO.BAS'");
    p.assert.equal(await p.ev('RC.app.isProtected(RC.app.active.path)'), false);
    p.assert.ok(!(await p.exists('#editorTabs .tab.active .lock')));
  });
  t.test('opening a card while its file is already open switches to that tab', async (p) => {
    await closeDocs(p);
    await openGallery(p);
    await clickCard(p, 'Snake');
    await p.wait("RC.app.active && /SNAKE/.test(RC.app.active.path)");
    await openGallery(p);
    await clickCard(p, 'Music Box');
    await p.wait("RC.app.active && /MUSIC/.test(RC.app.active.path)");
    await openGallery(p);
    await clickCard(p, 'Snake');
    await p.wait("RC.app.active && /SNAKE/.test(RC.app.active.path)");
    p.assert.equal(await p.ev("RC.app.docs.filter(d => d.path === 'C:\\\\SAMPLES\\\\SNAKE.BAS').length"), 1);
    p.assert.equal(await p.count('#editorTabs .tab'), 2);
  });
  t.test('Multi-file example runs and CHAINs without errors (PART2.BAS and SHAPES.BI present)', async (p) => {
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\SAMPLES\\\\MULTI\\\\PART2.BAS')"));
    p.assert.ok(await p.ev("RC.app.vfs.exists('C:\\\\SAMPLES\\\\MULTI\\\\SHAPES.BI')"));
    await closeDocs(p);
    await openGallery(p);
    await clickCard(p, 'Multi-file Program');
    await p.wait("RC.app.active && RC.app.active.path === 'C:\\\\SAMPLES\\\\MULTI\\\\MAIN.BAS'");
    await p.ev('RC.app.run()');
    for (let i = 0; i < 30; i++) {
      const st = await p.state();
      if (st === 'ended' || st === 'error') break;
      if (st === 'waiting') await p.ev("RC.app.runner.keyboard.type('x\\r'); RC.app.runner.kick()");
      await p.sleep(100);
    }
    p.assert.notEqual(await p.state(), 'error', await p.status());
    await p.stopProgram();
  }, { timeout: 20000 });
};
