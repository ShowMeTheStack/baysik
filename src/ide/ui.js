// Small UI toolkit: element builder, icons, dialogs, toasts, menus, splitters.
(function (RC) {
  'use strict';
  const UI = RC.UI = {};

  /** h('div.cls#id', {attr}, ...children) */
  UI.h = function (sel, attrs, ...kids) {
    const m = /^([a-z0-9-]+)?((?:[.#][\w-]+)*)$/i.exec(sel) || [];
    const el = document.createElement(m[1] || 'div');
    (m[2] || '').replace(/([.#])([\w-]+)/g, (_, k, v) => { if (k === '.') el.classList.add(v); else el.id = v; });
    if (attrs && (typeof attrs !== 'object' || attrs instanceof Node || Array.isArray(attrs))) { kids.unshift(attrs); attrs = null; }
    if (attrs) {
      for (const [k, v] of Object.entries(attrs)) {
        if (v === undefined || v === null || v === false) continue;
        if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
        else if (k === 'style' && typeof v === 'object') Object.assign(el.style, v);
        else if (k === 'html') el.innerHTML = v;
        else if (k === 'text') el.textContent = v;
        else if (k === 'dataset') Object.assign(el.dataset, v);
        else if (v === true) el.setAttribute(k, '');
        else el.setAttribute(k, v);
      }
    }
    const add = (k) => {
      if (k === null || k === undefined || k === false) return;
      if (Array.isArray(k)) { k.forEach(add); return; }
      el.appendChild(k instanceof Node ? k : document.createTextNode(String(k)));
    };
    kids.forEach(add);
    return el;
  };
  const h = UI.h;

  // ---- icons (simple stroke SVGs) -----------------------------------------------------------
  const P = {
    run: '<path d="M5 3l11 7-11 7z" fill="currentColor" stroke="none"/>',
    pause: '<rect x="4" y="3" width="4" height="14" fill="currentColor" stroke="none"/><rect x="12" y="3" width="4" height="14" fill="currentColor" stroke="none"/>',
    stop: '<rect x="4" y="4" width="12" height="12" fill="currentColor" stroke="none"/>',
    restart: '<path d="M4 10a6 6 0 1 0 2-4.5"/><path d="M3 3v4h4"/>',
    stepInto: '<path d="M10 3v9"/><path d="M6 8l4 4 4-4"/><circle cx="10" cy="16" r="1.6" fill="currentColor"/>',
    stepOver: '<path d="M3 11a7 7 0 0 1 13-3"/><path d="M17 4v4h-4"/><circle cx="10" cy="16" r="1.6" fill="currentColor"/>',
    stepOut: '<path d="M10 14V4"/><path d="M6 8l4-4 4 4"/><circle cx="10" cy="17" r="1.6" fill="currentColor"/>',
    bp: '<circle cx="10" cy="10" r="5" fill="currentColor" stroke="none"/>',
    file: '<path d="M5 2h7l4 4v12H5z"/><path d="M12 2v4h4"/>',
    folder: '<path d="M2 5h6l2 2h8v10H2z"/>',
    folderOpen: '<path d="M2 5h6l2 2h8v2H5l-3 8z"/><path d="M5 9h14l-3 8H2z"/>',
    newFile: '<path d="M5 2h7l4 4v12H5z"/><path d="M10 9v6M7 12h6"/>',
    newFolder: '<path d="M2 5h6l2 2h8v10H2z"/><path d="M10 10v5M7.5 12.5h5"/>',
    upload: '<path d="M10 14V3"/><path d="M6 7l4-4 4 4"/><path d="M3 14v3h14v-3"/>',
    download: '<path d="M10 3v11"/><path d="M6 10l4 4 4-4"/><path d="M3 14v3h14v-3"/>',
    share: '<circle cx="15" cy="4" r="2"/><circle cx="5" cy="10" r="2"/><circle cx="15" cy="16" r="2"/><path d="M7 9l6-4M7 11l6 4"/>',
    save: '<path d="M3 3h11l3 3v11H3z"/><path d="M6 3v5h7V3M6 17v-6h8v6"/>',
    trash: '<path d="M4 6h12M8 6V3h4v3M6 6l1 11h6l1-11"/>',
    refresh: '<path d="M16 10a6 6 0 1 1-2-4.5"/><path d="M17 3v4h-4"/>',
    max: '<path d="M3 8V3h5M12 3h5v5M17 12v5h-5M8 17H3v-5"/>',
    min: '<path d="M8 3v5H3M17 8h-5V3M12 17v-5h5M3 12h5v5"/>',
    help: '<circle cx="10" cy="10" r="8"/><path d="M7.5 7.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7v.5"/><circle cx="10" cy="15" r=".8" fill="currentColor"/>',
    drive: '<rect x="2" y="6" width="16" height="8" rx="1"/><circle cx="14" cy="10" r="1" fill="currentColor"/>',
    link: '<path d="M8 12l4-4"/><path d="M9 5l2-2a3 3 0 0 1 4 4l-2 2"/><path d="M11 15l-2 2a3 3 0 0 1-4-4l2-2"/>',
    plus: '<path d="M10 4v12M4 10h12"/>',
    x: '<path d="M5 5l10 10M15 5L5 15"/>',
    edit: '<path d="M4 16l1-4 8-8 3 3-8 8z"/>',
    star: '<path d="M10 2l2.4 5 5.6.6-4.2 3.8 1.2 5.6L10 14.3 5 17l1.2-5.6L2 7.6 7.6 7z"/>',
    tour: '<path d="M10 2a6 6 0 0 1 6 6c0 4-6 10-6 10S4 12 4 8a6 6 0 0 1 6-6z"/><circle cx="10" cy="8" r="2"/>',
    book: '<path d="M3 4h5a2 2 0 0 1 2 2v11a2 2 0 0 0-2-2H3zM17 4h-5a2 2 0 0 0-2 2v11a2 2 0 0 1 2-2h5z"/>',
    cog: '<circle cx="10" cy="10" r="3"/><path d="M10 1v3M10 16v3M1 10h3M16 10h3M3.6 3.6l2.1 2.1M14.3 14.3l2.1 2.1M3.6 16.4l2.1-2.1M14.3 5.7l2.1-2.1"/>',
    screen: '<rect x="2" y="3" width="16" height="11" rx="1"/><path d="M7 17h6M10 14v3"/>',
    gw: '<rect x="2" y="3" width="16" height="14"/><path d="M5 8l3 2-3 2M10 13h4"/>',
    cursor: '<path d="M5 3v14l4-4 3 6 2-1-3-6h6z"/>',
    eye: '<path d="M1 10s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6z"/><circle cx="10" cy="10" r="2.5"/>',
  };
  UI.icon = function (name) {
    const s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    s.setAttribute('viewBox', '0 0 20 20');
    s.setAttribute('fill', 'none');
    s.setAttribute('stroke', 'currentColor');
    s.setAttribute('stroke-width', '1.6');
    s.setAttribute('stroke-linecap', 'round');
    s.setAttribute('stroke-linejoin', 'round');
    s.setAttribute('aria-hidden', 'true');
    s.innerHTML = P[name] || '';
    return s;
  };

  // ---- toasts ---------------------------------------------------------------------------------
  let toastBox = null;
  UI.toast = function (msg, kind, ms) {
    if (!toastBox) { toastBox = h('div.toasts', { role: 'status', 'aria-live': 'polite' }); document.body.appendChild(toastBox); }
    const t = h('div.toast' + (kind ? '.' + kind : ''), msg);
    toastBox.appendChild(t);
    setTimeout(() => t.remove(), ms || 3500);
    return t;
  };

  // ---- modal dialogs ----------------------------------------------------------------------------
  const openModals = [];
  UI.modal = function (opts) {
    return new Promise((resolve) => {
      const prevFocus = document.activeElement;
      const back = h('div.modal-back', { role: 'presentation' });
      const box = h('div.modal' + (opts.wide ? '.wide' : ''), { role: 'dialog', 'aria-modal': 'true', 'aria-label': opts.title || 'Dialog' });
      const head = h('div.modal-head', opts.title || '');
      const body = h('div.modal-body');
      if (typeof opts.body === 'string') body.innerHTML = opts.body;
      else if (opts.body) body.appendChild(opts.body);
      const foot = h('div.modal-foot');
      let done = false;
      const close = (v) => {
        if (done) return;
        done = true;
        back.remove();
        openModals.splice(openModals.indexOf(close), 1);
        document.removeEventListener('keydown', onKey, true);
        if (prevFocus && prevFocus.focus) try { prevFocus.focus(); } catch (e) { /* ignore */ }
        resolve(v);
      };
      for (const b of opts.buttons || [{ label: 'OK', value: true, primary: true }]) {
        const btn = h('button.btn' + (b.primary ? '.primary' : ''), { type: 'button' }, b.label);
        btn.addEventListener('click', () => {
          const v = typeof b.value === 'function' ? b.value() : b.value;
          if (v === undefined && b.keepOpen) return;
          close(v);
        });
        foot.appendChild(btn);
      }
      box.append(head, body, foot);
      back.appendChild(box);
      back.addEventListener('mousedown', (e) => { if (e.target === back && opts.dismissable !== false) close(opts.cancelValue); });
      const onKey = (e) => {
        if (openModals[openModals.length - 1] !== close) return;
        if (e.key === 'Tab') {
          // keep keyboard focus inside the dialog (aria-modal)
          const f = [...box.querySelectorAll('button, input, select, textarea, a[href], [tabindex]:not([tabindex="-1"])')].filter((x) => !x.disabled && x.offsetParent !== null);
          if (f.length) {
            const i = f.indexOf(document.activeElement);
            const n = e.shiftKey ? (i <= 0 ? f.length - 1 : i - 1) : (i < 0 || i === f.length - 1 ? 0 : i + 1);
            e.preventDefault(); e.stopPropagation();
            f[n].focus();
            return;
          }
        }
        if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); close(opts.cancelValue); return; }
        if (e.key === 'Enter' && opts.enterValue !== undefined && !(e.target instanceof HTMLTextAreaElement)) {
          e.preventDefault(); e.stopPropagation();
          const v = typeof opts.enterValue === 'function' ? opts.enterValue() : opts.enterValue;
          if (v !== undefined) close(v);
          return;
        }
        // Other keys reach the focused control inside the dialog, but never the IDE/editor behind it
        if (!box.contains(e.target)) { e.stopPropagation(); }
      };
      document.addEventListener('keydown', onKey, true);
      openModals.push(close);
      document.getElementById('overlay-root').appendChild(back);
      const f = box.querySelector('input,textarea,select') || foot.querySelector('.primary') || foot.querySelector('button');
      if (f) setTimeout(() => { f.focus(); if (f.select && opts.selectInput !== false) f.select(); }, 20);
      if (opts.onOpen) opts.onOpen(box, close);
    });
  };
  UI.anyModalOpen = () => openModals.length > 0;
  UI.alert = (title, msg) => UI.modal({ title, body: msg instanceof Node ? msg : h('div', { html: msg }), buttons: [{ label: 'OK', value: true, primary: true }], enterValue: true });
  UI.confirm = (title, msg, okLabel, cancelLabel) => UI.modal({
    title, body: msg instanceof Node ? msg : h('div', { html: msg }),
    buttons: [{ label: cancelLabel || 'Cancel', value: false }, { label: okLabel || 'OK', value: true, primary: true }],
    enterValue: true, cancelValue: false,
  });
  UI.prompt = function (title, label, value, opts) {
    const input = h('input', { type: 'text', value: value || '', spellcheck: 'false', 'aria-label': label });
    const body = h('div', h('label', label), input, opts && opts.hint ? h('p.muted', { style: { marginTop: '6px' } }, opts.hint) : null);
    return UI.modal({
      title, body,
      buttons: [{ label: 'Cancel', value: null }, { label: (opts && opts.ok) || 'OK', value: () => input.value, primary: true }],
      enterValue: () => input.value, cancelValue: null,
    });
  };

  // ---- dropdown menus ----------------------------------------------------------------------------
  let openMenu = null;
  UI.closeMenus = function () { if (openMenu) { openMenu.close(); openMenu = null; } };
  /**
   * items: [{label, sc, action, checked, disabled, sep, items(submenu)}]
   */
  UI.showMenu = function (items, x, y, opts) {
    UI.closeMenus();
    const pop = h('div.menu-pop', { role: 'menu' });
    let subOpen = null;
    let sub = null; // keyboard state of the open submenu: {els, idx}
    const els = [];
    const closeSub = () => { if (subOpen) { subOpen.remove(); subOpen = null; } sub = null; };
    for (const it of items) {
      if (!it) continue;
      if (it.sep) { pop.appendChild(h('div.menu-sep')); continue; }
      const el = h('div.menu-item' + (it.disabled ? '.disabled' : '') + (it.checked ? '.checked' : ''), { role: 'menuitem', tabindex: '-1', 'aria-haspopup': it.items ? 'true' : null },
        h('span', it.label), it.items ? h('span.sub-arrow', '▸') : (it.sc ? h('span.sc', it.sc) : null));
      const openSub = (keyboard) => {
        closeSub();
        const r = el.getBoundingClientRect();
        const sp = h('div.menu-pop', { role: 'menu' });
        const subEls = [];
        for (const s2 of it.items) {
          if (!s2) continue;
          if (s2.sep) { sp.appendChild(h('div.menu-sep')); continue; }
          const se = h('div.menu-item' + (s2.disabled ? '.disabled' : '') + (s2.checked ? '.checked' : ''), { role: 'menuitem' }, h('span', s2.label), s2.sc ? h('span.sc', s2.sc) : null);
          se.addEventListener('click', (e) => { e.stopPropagation(); UI.closeMenus(); if (s2.action) setTimeout(() => s2.action(), 0); });
          sp.appendChild(se);
          if (!s2.disabled) subEls.push(se);
        }
        document.body.appendChild(sp);
        const sw = sp.offsetWidth;
        sp.style.left = Math.min(r.right - 2, window.innerWidth - sw - 4) + 'px';
        sp.style.top = Math.min(r.top - 4, window.innerHeight - sp.offsetHeight - 4) + 'px';
        subOpen = sp;
        sub = { els: subEls, idx: -1 };
        if (keyboard) focusSub(0);
      };
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        if (it.items) { openSub(false); return; }
        UI.closeMenus();
        if (it.action) setTimeout(() => it.action(), 0);
      });
      el.addEventListener('mouseenter', () => { if (it.items) openSub(false); else closeSub(); });
      els.push({ el, it, openSub });
      pop.appendChild(el);
    }
    document.body.appendChild(pop);
    const w = pop.offsetWidth, hh = pop.offsetHeight;
    pop.style.left = Math.max(2, Math.min(x, window.innerWidth - w - 4)) + 'px';
    pop.style.top = Math.max(2, Math.min(y, window.innerHeight - hh - 4)) + 'px';
    let idx = -1;
    const focusIdx = (i) => {
      const live = els.filter((e) => !e.it.disabled);
      if (!live.length) return;
      idx = (i + live.length) % live.length;
      els.forEach((e) => e.el.classList.remove('active'));
      live[idx].el.classList.add('active');
      live[idx].el.scrollIntoView({ block: 'nearest' });
    };
    function focusSub(i) {
      if (!sub || !sub.els.length) return;
      sub.idx = (i + sub.els.length) % sub.els.length;
      sub.els.forEach((e) => e.classList.remove('active'));
      sub.els[sub.idx].classList.add('active');
    }
    const onKey = (e) => {
      const live = els.filter((x) => !x.it.disabled);
      if (sub && sub.idx >= 0) {
        // keyboard is inside a submenu
        if (e.key === 'ArrowDown') { e.preventDefault(); focusSub(sub.idx + 1); }
        else if (e.key === 'ArrowUp') { e.preventDefault(); focusSub(sub.idx - 1); }
        else if (e.key === 'Enter') { e.preventDefault(); sub.els[sub.idx].click(); }
        else if (e.key === 'ArrowLeft' || e.key === 'Escape') { e.preventDefault(); closeSub(); }
        else if (e.key === 'ArrowRight') { e.preventDefault(); if (opts && opts.onArrow) opts.onArrow(1); }
        else return;
        e.stopPropagation();
        return;
      }
      const cur = idx >= 0 ? live[idx] : null;
      if (e.key === 'Escape') { e.preventDefault(); UI.closeMenus(); if (opts && opts.onEscape) opts.onEscape(); }
      else if (e.key === 'ArrowDown') { e.preventDefault(); closeSub(); focusIdx(idx < 0 ? 0 : idx + 1); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); closeSub(); focusIdx(idx < 0 ? live.length - 1 : idx - 1); }
      else if (e.key === 'Enter' && cur) { e.preventDefault(); if (cur.it.items) cur.openSub(true); else cur.el.click(); }
      else if (e.key === 'ArrowRight' && cur && cur.it.items) { e.preventDefault(); cur.openSub(true); }
      else if ((e.key === 'ArrowRight' || e.key === 'ArrowLeft') && opts && opts.onArrow) { e.preventDefault(); opts.onArrow(e.key === 'ArrowRight' ? 1 : -1); }
      else return;
      e.stopPropagation();
    };
    const onDown = (e) => { if (!pop.contains(e.target) && !(subOpen && subOpen.contains(e.target)) && !(opts && opts.anchor && opts.anchor.contains(e.target))) UI.closeMenus(); };
    document.addEventListener('keydown', onKey, true);
    setTimeout(() => document.addEventListener('mousedown', onDown, true), 0);
    if (opts && opts.keyboard) focusIdx(0);
    openMenu = {
      close() {
        pop.remove(); if (subOpen) subOpen.remove();
        document.removeEventListener('keydown', onKey, true);
        document.removeEventListener('mousedown', onDown, true);
        if (opts && opts.onClose) opts.onClose();
      },
    };
    return openMenu;
  };

  // ---- splitters ------------------------------------------------------------------------------------
  UI.splitter = function (el, onMove, onEnd) {
    el.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      el.setPointerCapture(e.pointerId);
      el.classList.add('dragging');
      document.body.classList.add('resizing');
      const move = (ev) => onMove(ev);
      const up = () => {
        el.classList.remove('dragging');
        document.body.classList.remove('resizing');
        el.removeEventListener('pointermove', move);
        el.removeEventListener('pointerup', up);
        if (onEnd) onEnd();
      };
      el.addEventListener('pointermove', move);
      el.addEventListener('pointerup', up);
    });
  };

  // ---- downloads / file picking ---------------------------------------------------------------------
  UI.download = function (name, data, type) {
    const blob = data instanceof Blob ? data : new Blob([data], { type: type || 'application/octet-stream' });
    const url = URL.createObjectURL(blob);
    const a = h('a', { href: url, download: name });
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 5000);
  };
  UI.pickFiles = function (accept, multiple) {
    return new Promise((resolve) => {
      const inp = h('input', { type: 'file', accept: accept || '', multiple: !!multiple, style: { display: 'none' } });
      inp.addEventListener('change', () => { resolve(Array.from(inp.files || [])); inp.remove(); });
      document.body.appendChild(inp);
      inp.click();
    });
  };

  UI.storage = {
    get(k, d) { try { const v = localStorage.getItem('baysik.' + k); return v === null ? d : JSON.parse(v); } catch (e) { return d; } },
    set(k, v) { try { localStorage.setItem('baysik.' + k, JSON.stringify(v)); } catch (e) { /* ignore */ } },
  };
})(RC);
