// Debug hover callout: shows a variable's value while paused and lets you edit it in place.
// Sticky: moving the mouse from the word into the callout keeps it open.
(function (RC) {
  'use strict';
  const { h } = RC.UI;
  const B = RC.Basic;

  class HoverCallout {
    constructor(app) {
      this.app = app;
      this.el = null;
      this.hideTimer = null;
      this.anchor = null; // {doc, line, col}
      this.state = { expanded: new Set(), pages: new Map(), prev: new Map() };
      document.addEventListener('pointerdown', (e) => { if (this.el && !this.el.contains(e.target)) this.hide(); }, true);
      document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape' || !this.el) return;
        const ae = document.activeElement;
        if (ae && ae.tagName === 'INPUT' && this.el.contains(ae)) return; // the value editor cancels itself
        this.hide();
      }, true);
    }
    isOpen() { return !!this.el; }

    /** Show for the identifier at pos in doc (pos: {line, col, text}) */
    showFor(doc, pos, x, y) {
      const vm = this.app.runner.vm;
      if (!vm || (vm.state !== 'paused' && vm.state !== 'error')) return;
      const w = B.wordAt(pos.text, pos.col);
      if (!w || w.kind !== 'id') return;
      const same = this.anchor && this.anchor.doc === doc && this.anchor.line === pos.line && this.anchor.col === w.col;
      if (same && this.el) { this.cancelHide(); return; }
      const fi = vm.frames.length - 1; // hover always looks at the current (topmost) frame
      const wantArray = /\(/.test(w.expr) || /^\s*\(/.test(pos.text.slice(w.end));
      let entry = null;
      try { entry = B.Debug.hoverEntry(vm, w.word, wantArray, fi); } catch (e) { entry = null; }
      let exprVal = null;
      if (w.expr !== w.word || !entry) {
        try { const r = B.Debug.evaluate(vm, w.expr, fi); exprVal = w.expr + ' = ' + B.Debug.fmtValue(r.value, r.type); } catch (e) { exprVal = null; }
      }
      if (!entry && !exprVal) return;
      this.anchor = { doc, line: pos.line, col: w.col };
      this.render(entry, exprVal, fi, x, y);
    }

    render(entry, exprVal, fi, x, y) {
      this.hide(true);
      const vm = this.app.runner.vm;
      const body = h('div.callout-body');
      const box = h('div.ed-callout', { role: 'dialog', 'aria-label': 'Variable value' });
      if (exprVal) box.appendChild(h('div.callout-expr', exprVal));
      if (entry) box.appendChild(body);
      const deeper = vm.frames.length > 1;
      const note = entry && entry.readOnly ? 'Constants cannot be changed.'
        : entry ? 'Click a value to change it' + (deeper ? ' (current frame). Callers\' frames: Call Stack ▸ Variables.' : '.') : '';
      if (note) box.appendChild(h('div.callout-note', note));
      document.body.appendChild(box);
      this.el = box;
      if (entry) {
        const key = 'H:' + entry.name;
        if (entry.expandable) this.state.expanded.add(key);
        const tree = new RC.VarTree({
          app: this.app, state: this.state, fi: () => fi,
          canEdit: () => vm.frames.length - 1 === fi && vm.state === 'paused',
          refresh: () => draw(),
          onEdited: () => { this.refreshEntry(entry, fi); draw(); this.app.panels.refreshAll(); },
        });
        const draw = () => { tree.render(body, [{ entries: [entry], keyPrefix: 'H:', empty: false }]); this.place(x, y); };
        this.refreshEntry = (e, f) => {
          // re-read the root value (records/arrays are live objects; primitives need a fresh read)
          if (e.ref) { e.value = e.ref.c[e.ref.k]; e.text = B.Debug.fmtValue(e.value, e.isArray ? { code: 7 } : e.vtype); }
          void f;
        };
        draw();
      }
      this.place(x, y);
      box.addEventListener('mouseenter', () => this.cancelHide());
      box.addEventListener('mouseleave', () => this.scheduleHide(500));
    }
    place(x, y) {
      const box = this.el;
      if (!box) return;
      const w = box.offsetWidth, hh = box.offsetHeight;
      let left = Math.min(x + 4, window.innerWidth - w - 8);
      let top = y + 14;
      if (top + hh > window.innerHeight - 8) top = Math.max(8, y - hh - 10);
      box.style.left = Math.max(8, left) + 'px';
      box.style.top = top + 'px';
    }
    scheduleHide(ms) {
      if (!this.el) return;
      if (this.el.contains(document.activeElement) && document.activeElement.tagName === 'INPUT') return;
      clearTimeout(this.hideTimer);
      this.hideTimer = setTimeout(() => this.hide(), ms || 450);
    }
    cancelHide() { clearTimeout(this.hideTimer); }
    hide(keepAnchor) {
      clearTimeout(this.hideTimer);
      if (this.el) { this.el.remove(); this.el = null; }
      if (!keepAnchor) this.anchor = null;
    }
  }

  RC.HoverCallout = HoverCallout;
})(RC);
