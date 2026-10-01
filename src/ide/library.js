// Program Library: ~500 commented programs in 20 categories, decompressed on demand.
(function (RC) {
  'use strict';
  const { h } = RC.UI;
  let texts = null;

  async function load() {
    if (texts) return texts;
    const L = RC.LIBRARY;
    const bin = atob(L.blob);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    const res = new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('deflate-raw')));
    texts = JSON.parse(await res.text());
    return texts;
  }

  const Library = RC.Library = {
    load,
    /** Install one program (and any .BI files of its category it may include) into C:\LIBRARY\<CAT>\ */
    async install(app, path) {
      const t = await load();
      const cat = path.split('\\')[0];
      const vfs = app.vfs;
      for (const dir of ['C:\\LIBRARY', 'C:\\LIBRARY\\' + cat]) if (!vfs.exists(dir)) vfs.mkdir(dir);
      const target = 'C:\\LIBRARY\\' + path;
      const write = (p, text) => vfs.writeFile(p, RC.strToBytes(RC.toCP437(text.replace(/\r?\n/g, '\r\n'))), { trusted: true });
      if (!vfs.exists(target)) write(target, t[path]);
      for (const k of Object.keys(t)) if (k.startsWith(cat + '\\') && /\.BI$/i.test(k) && !vfs.exists('C:\\LIBRARY\\' + k)) write('C:\\LIBRARY\\' + k, t[k]);
      return target;
    },
    async open(app, path, run) {
      try {
        const p = await Library.install(app, path);
        const d = app.openFile(p);
        app.expandedDirs.add('C:\\LIBRARY'); app.expandedDirs.add(('C:\\LIBRARY\\' + path.split('\\')[0]).toUpperCase());
        app.renderExplorer();
        app.setStatus('Opened ' + p + ' — read the comments at the top, then press F5');
        if (d) d.editor.setCursor(0, 0);
        if (app.isMobile()) app.setMobileView('editor');
        if (run) app.run();
      } catch (e) { RC.UI.toast('Could not open program: ' + e.message, 'err'); }
    },
    async browse(app, initialCat) {
      const L = RC.LIBRARY;
      if (!L || !L.items.length) { RC.Samples.gallery(app); return; }
      const state = RC.UI.storage.get('libState', { cat: '*', level: '*', q: '' });
      if (initialCat) state.cat = initialCat;
      const nav = h('div.help-nav');
      const main = h('div.help-main');
      const search = h('input', { type: 'text', placeholder: `Search ${L.items.length} programs…`, value: state.q, 'aria-label': 'Search programs' });
      const level = h('select', { 'aria-label': 'Level' }, ['*', 'Beginner', 'Intermediate', 'Advanced'].map((l) => h('option', { value: l }, l === '*' ? 'All levels' : l)));
      level.value = state.level;
      let closeFn = () => {};
      const opened = new Set(RC.UI.storage.get('libOpened', []));
      nav.appendChild(search);
      const renderNav = () => {
        // rebuild everything except the search box, so it keeps focus while typing
        while (nav.lastChild && nav.lastChild !== search) nav.removeChild(nav.lastChild);
        const all = h('div', { 'data-key': '*', class: state.cat === '*' ? 'sel' : '' }, `All programs (${L.items.length})`);
        all.addEventListener('click', () => { state.cat = '*'; render(); });
        nav.appendChild(all);
        const st = h('div', { class: state.cat === 'starter' ? 'sel' : '' }, 'Starter examples');
        st.addEventListener('click', () => { closeFn(); RC.Samples.gallery(app); });
        nav.appendChild(st);
        nav.appendChild(h('div.grp', 'Categories'));
        for (const c of L.categories) {
          const el = h('div', { class: state.cat === c.id ? 'sel' : '' }, `${c.name} (${c.count})`);
          el.addEventListener('click', () => { state.cat = c.id; render(); });
          nav.appendChild(el);
        }
      };
      const render = () => {
        state.q = search.value; state.level = level.value;
        RC.UI.storage.set('libState', state);
        renderNav();
        const q = state.q.trim().toLowerCase();
        const list = L.items.filter((it) => (state.cat === '*' || it.cat === state.cat) &&
          (state.level === '*' || it.level.toLowerCase().startsWith(state.level.toLowerCase())) &&
          (!q || (it.title + ' ' + it.summary + ' ' + it.tags.join(' ') + ' ' + it.path).toLowerCase().includes(q)));
        main.innerHTML = '';
        const catName = state.cat === '*' ? 'All programs' : (L.categories.find((c) => c.id === state.cat) || {}).name;
        main.appendChild(h('div', { style: { display: 'flex', gap: '8px', alignItems: 'center', margin: '6px 0 10px' } }, h('h2', { style: { margin: 0, flex: 1 } }, catName), h('span.muted', list.length + ' shown'), level));
        const grid = h('div.gallery');
        for (const it of list) {
          const card = h('button.card', { type: 'button', title: it.path },
            h('span.t', (opened.has(it.path) ? '✓ ' : '') + it.title),
            h('span.d', it.summary),
            h('span.tags', h('span', it.level), ...it.tags.slice(0, 4).map((t) => h('span', t))));
          card.addEventListener('click', () => { opened.add(it.path); RC.UI.storage.set('libOpened', [...opened]); closeFn(); Library.open(app, it.path); });
          grid.appendChild(card);
        }
        if (!list.length) grid.appendChild(h('p.muted', 'No programs match.'));
        main.appendChild(grid);
      };
      search.addEventListener('input', render);
      level.addEventListener('change', render);
      render();
      // start decompressing in the background so opening is instant
      load().catch(() => {});
      await RC.UI.modal({
        title: 'Program Library', wide: true, selectInput: false,
        body: h('div', h('p.muted', { style: { marginTop: 0 } }, 'Every program is hand-written and explains itself in comments at the top. Pick one to copy it to C:\\LIBRARY and open it.'), h('div.help', nav, main)),
        buttons: [{ label: 'Close', value: null }],
        onOpen: (b, c) => { closeFn = () => c(null); },
      });
    },
  };
})(RC);
