// Shared helpers for the 20-editor-* specs (not a spec file itself).

export const ED = 'C:\\MYPROGS\\ED.BAS';

/** Open (or reset) a scratch file with `text`, focus its editor, caret at (line, col) (default: end). */
export async function open(p, text, opts = {}) {
  const path = opts.path || ED;
  await p.newFile(path, text);
  await p.fn((t) => {
    const d = RC.app.active;
    d.editor.setValue(t); d.savedText = t; d.dirty = false; RC.app.renderTabs();
  }, text);
  if (opts.line !== undefined) await caret(p, opts.line, opts.col || 0);
  else await p.fn(() => { const e = RC.app.active.editor; e.focus(); e.ta.setSelectionRange(e.ta.value.length, e.ta.value.length); e.updateCursor(); });
  await p.sleep(30);
}

/** Place the caret (setup helper). */
export async function caret(p, line, col = 0) {
  await p.fn((l, c) => RC.app.active.editor.setCursor(l, c), line, col);
  await p.sleep(20);
}

/** Select from (l1,c1) to (l2,c2). */
export async function select(p, l1, c1, l2, c2) {
  await p.fn((a, b, c, d) => { const e = RC.app.active.editor; e.focus(); e.ta.setSelectionRange(e.lineStart(a) + b, e.lineStart(c) + d); e.updateCursor(); }, l1, c1, l2, c2);
  await p.sleep(20);
}

export const cur = (p) => p.ev('RC.app.active.editor.cursor()');
export const selText = (p) => p.ev('(() => { const t = RC.app.active.editor.ta; return t.value.slice(t.selectionStart, t.selectionEnd); })()');
export const lines = async (p) => (await p.code()).split('\n');
export const rendered = (p) => p.wait('!RC.app.active.editor.renderPending', 2000);

/** [[class, text], ...] for highlighted spans on a rendered editor line, plus plain text segments as ['', text]. */
export async function spans(p, line) {
  await rendered(p);
  await p.sleep(20);
  return p.fn((l) => {
    const el = RC.app.active.editor.hl.children[l];
    if (!el) return null;
    return [...el.childNodes].map((n) => [n.nodeType === 1 ? n.className : '', n.textContent]);
  }, line);
}
/** Text of all spans with a given class on a line */
export async function cls(p, line, c) {
  const s = await spans(p, line);
  return s.filter((x) => x[0] === c).map((x) => x[1]);
}

/** Real keystroke that triggers a browser editing command (Ctrl+Z / Ctrl+Y). */
export async function cmdKey(p, key, command) {
  const vk = key.toUpperCase().charCodeAt(0);
  await p.b.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', windowsVirtualKeyCode: vk, key, code: 'Key' + key.toUpperCase(), modifiers: 2, commands: [command] });
  await p.b.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: vk, key, code: 'Key' + key.toUpperCase(), modifiers: 2 });
  await p.sleep(40);
}
export const undo = (p) => cmdKey(p, 'z', 'undo');
export const redo = (p) => cmdKey(p, 'y', 'redo');

/** Screen coordinates of a character cell in the active editor. */
export async function posXY(p, line, col) {
  return p.fn((l, c) => {
    const e = RC.app.active.editor;
    const r = e.ta.getBoundingClientRect();
    return [r.left + 8 + (c + 0.5) * e.charWidth - e.ta.scrollLeft, r.top + (l + 0.5) * e.lineHeight - e.ta.scrollTop];
  }, line, col);
}
export async function clickChar(p, line, col, opts = {}) {
  const [x, y] = await posXY(p, line, col);
  await p.clickAt(x, y, opts);
}

/** Mark every open document clean so no beforeunload prompt can block a reload. */
export async function cleanAll(p) {
  await p.ev('RC.app.docs.forEach((d) => { d.savedText = d.editor.getValue(); d.dirty = false; }); RC.app.renderTabs()');
}

/** Close menus, the find bar and any modal (via Escape so the modal stack stays consistent). */
export async function closeOthers(p) {
  // Never let an "unsaved changes" beforeunload prompt block a reload or a fresh page: documents are
  // marked clean just before the app's own beforeunload handler runs (session saving is unaffected).
  await p.ev('if (!window.__e2eNoUnloadPrompt) { window.__e2eNoUnloadPrompt = true; addEventListener("beforeunload", () => { try { RC.app.docs.forEach((d) => { d.dirty = false; }); } catch (e) {} }, true); }');
  await p.ev('(() => { RC.UI.closeMenus(); const f = document.getElementById("findbar"); if (f) f.hidden = true; })()');
  for (let i = 0; i < 5 && await p.ev('RC.UI.anyModalOpen()'); i++) { await p.key('Escape'); await p.sleep(40); }
}

// US-layout key info for punctuation: char -> [code, vk, shift]
const PUNCT = {
  ' ': ['Space', 32, 0], '!': ['Digit1', 49, 1], '@': ['Digit2', 50, 1], '#': ['Digit3', 51, 1], '$': ['Digit4', 52, 1], '%': ['Digit5', 53, 1],
  '^': ['Digit6', 54, 1], '&': ['Digit7', 55, 1], '*': ['Digit8', 56, 1], '(': ['Digit9', 57, 1], ')': ['Digit0', 48, 1],
  '-': ['Minus', 189, 0], '_': ['Minus', 189, 1], '=': ['Equal', 187, 0], '+': ['Equal', 187, 1], '[': ['BracketLeft', 219, 0], '{': ['BracketLeft', 219, 1],
  ']': ['BracketRight', 221, 0], '}': ['BracketRight', 221, 1], '\\': ['Backslash', 220, 0], '|': ['Backslash', 220, 1], ';': ['Semicolon', 186, 0],
  ':': ['Semicolon', 186, 1], "'": ['Quote', 222, 0], '"': ['Quote', 222, 1], ',': ['Comma', 188, 0], '<': ['Comma', 188, 1], '.': ['Period', 190, 0],
  '>': ['Period', 190, 1], '/': ['Slash', 191, 0], '?': ['Slash', 191, 1], '`': ['Backquote', 192, 0], '~': ['Backquote', 192, 1],
};
/** Type text with real, correctly-coded key events ('\n' = Enter). Works for any character. */
export async function typeKeys(p, text) {
  for (const ch of text) {
    if (ch === '\n') { await p.key('Enter', { after: 5 }); continue; }
    let code = '', vk = 0, shift = 0;
    if (/^[a-z]$/.test(ch)) { code = 'Key' + ch.toUpperCase(); vk = ch.toUpperCase().charCodeAt(0); }
    else if (/^[A-Z]$/.test(ch)) { code = 'Key' + ch; vk = ch.charCodeAt(0); shift = 1; }
    else if (/^[0-9]$/.test(ch)) { code = 'Digit' + ch; vk = ch.charCodeAt(0); }
    else if (PUNCT[ch]) [code, vk, shift] = PUNCT[ch];
    const modifiers = shift ? 8 : 0;
    await p.b.send('Input.dispatchKeyEvent', { type: 'keyDown', windowsVirtualKeyCode: vk, key: ch, code, text: ch, unmodifiedText: ch, modifiers });
    await p.b.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: vk, key: ch, code, modifiers });
    await p.sleep(4);
  }
  await p.sleep(40);
}
