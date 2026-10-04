// Variable tree widget shared by the Variables panel and the editor hover callout.
// Arrays fold one dimension at a time, records drill down to primitive fields, values edit in place.
(function (RC) {
  'use strict';
  const { h } = RC.UI;
  const B = RC.Basic;
  const PAGE = 100;

  class VarTree {
    /**
     * @param opts {app, fi: () => frameIndex, canEdit: (entry) => bool, onEdited: () => void, state?}
     */
    constructor(opts) {
      this.opts = opts;
      this.state = opts.state || { expanded: new Set(), pages: new Map(), prev: new Map() };
    }
    vm() { return this.opts.app.runner.vm; }

    /** Render sections [{title, entries, keyPrefix}] into el */
    render(el, sections) {
      el.innerHTML = '';
      for (const sec of sections) {
        if (sec.title) el.appendChild(h('div.vsec', sec.title + (sec.entries ? ' (' + sec.entries.length + ')' : '')));
        if (sec.entries && !sec.entries.length && sec.empty !== false) el.appendChild(h('div.empty', { style: { padding: '4px 10px' } }, 'none'));
        for (const e of sec.entries || []) this.row(el, e, 0, sec.keyPrefix + e.name);
      }
    }

    row(el, e, depth, key) {
      const st = this.state;
      const changed = st.prev.has(key) && st.prev.get(key) !== e.text && !e.isGroup;
      st.prev.set(key, e.text);
      const open = st.expanded.has(key);
      const tw = h('span.twisty', { role: e.expandable ? 'button' : null, 'aria-label': e.expandable ? (open ? 'Collapse' : 'Expand') : null }, e.expandable ? (open ? '▾' : '▸') : '');
      const editable = !e.readOnly && !e.isGroup && !e.isArray && e.ref && e.vtype && e.vtype.code <= 5 && this.opts.canEdit(e);
      const nameCell = h('div.vn', { style: { paddingLeft: (6 + depth * 14) + 'px' } }, tw, h('span', e.name),
        e.param ? h('span.vbadge', 'param') : null, e.isRet ? h('span.vbadge', 'result') : null, e.isConst ? h('span.vbadge', 'const') : null);
      const valText = e.isGroup ? '' : e.text;
      const valCell = h('div.vv' + (changed ? '.changed' : '') + (editable ? '.editable' : ''),
        { title: editable ? 'Click to change' : e.readOnly ? 'Read-only' : (e.expandable ? 'Expand to see elements' : '') , tabindex: editable ? '0' : null }, valText);
      const rowEl = h('div.vrow', nameCell, h('div.vt', e.type), valCell);
      const toggle = () => { if (open) st.expanded.delete(key); else st.expanded.add(key); this.refresh(); };
      if (e.expandable) { tw.addEventListener('click', toggle); nameCell.addEventListener('dblclick', toggle); }
      if (editable) {
        const start = () => this.edit(valCell, e);
        valCell.addEventListener('click', start);
        valCell.addEventListener('keydown', (ev) => { if (ev.key === 'Enter') { ev.preventDefault(); start(); } });
      }
      el.appendChild(rowEl);
      if (e.expandable && open) {
        const pk = key + '#page';
        const start = st.pages.get(pk) || 0;
        let kids;
        try { kids = B.Debug.children(e, start, PAGE); } catch (err) { kids = { items: [], total: 0 }; }
        for (const c of kids.items) this.row(el, Object.assign(c, { readOnly: e.readOnly }), depth + 1, key + c.name);
        if (kids.total > PAGE) {
          const nav = h('div.vrow.pager', h('div', { style: { paddingLeft: (20 + depth * 14) + 'px', gridColumn: '1 / -1' } },
            h('button.small-btn', { type: 'button', disabled: start === 0, onclick: () => { st.pages.set(pk, Math.max(0, start - PAGE)); this.refresh(); } }, '◀ prev'),
            ' ', h('span.muted', `${start + 1}–${Math.min(kids.total, start + PAGE)} of ${kids.total}`), ' ',
            h('button.small-btn', { type: 'button', disabled: start + PAGE >= kids.total, onclick: () => { st.pages.set(pk, start + PAGE); this.refresh(); } }, 'next ▶')));
          el.appendChild(nav);
        }
      }
    }

    edit(cell, e) {
      const vm = this.vm();
      if (!vm || cell.querySelector('input')) return;
      const cur = typeof e.value === 'string' ? '"' + RC.fromCP437(e.value, false) + '"' : e.text;
      const inp = h('input', { type: 'text', value: cur, 'aria-label': 'New value for ' + e.name, spellcheck: 'false' });
      cell.innerHTML = '';
      cell.appendChild(inp);
      inp.focus(); inp.select();
      let done = false;
      const commit = (ok) => {
        if (done) return;
        done = true;
        if (ok && inp.value !== cur) {
          try {
            B.Debug.assign(vm, e, inp.value, this.opts.fi());
            RC.UI.toast('Changed ' + e.name, 'ok', 1500);
          } catch (err) { RC.UI.toast('Could not set ' + e.name + ': ' + err.message, 'err'); }
        }
        if (this.opts.onEdited) this.opts.onEdited();
        else this.refresh();
      };
      inp.addEventListener('keydown', (ev) => {
        ev.stopPropagation();
        if (ev.key === 'Enter') commit(true);
        if (ev.key === 'Escape') commit(false);
      });
      inp.addEventListener('blur', () => commit(true));
    }
    refresh() { if (this.opts.refresh) this.opts.refresh(); }
  }

  RC.VarTree = VarTree;
})(RC);
