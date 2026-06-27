// Core namespace and shared helpers. Every source file attaches to the global RC object.
/* global globalThis */
var RC = (typeof globalThis !== 'undefined' && globalThis.RC) || {};
if (typeof globalThis !== 'undefined') globalThis.RC = RC;

(function (RC) {
  'use strict';

  // ---- CP437 <-> Unicode -------------------------------------------------
  const CP437 = (
    '\u0000☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼' +
    ' !"#$%&\'()*+,-./0123456789:;<=>?' +
    '@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_' +
    '`abcdefghijklmnopqrstuvwxyz{|}~⌂' +
    'ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒ' +
    'áíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐' +
    '└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀' +
    'αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ '
  );
  const uniToCp = new Map();
  for (let i = 0; i < 256; i++) uniToCp.set(CP437[i], i);
  // A few friendly aliases for characters people paste
  uniToCp.set('β', 0xE1); uniToCp.set('μ', 0xE6); uniToCp.set('Ω', 0xEA);
  uniToCp.set('∑', 0xE4); uniToCp.set('∈', 0xEE); uniToCp.set('ϕ', 0xED);

  RC.CP437 = CP437;
  /** Unicode string -> BASIC byte string (char codes 0..255). Control chars kept as-is. */
  RC.toCP437 = function (s) {
    let out = '';
    for (const ch of s) {
      const c = ch.charCodeAt(0);
      if (c < 128) { out += ch; continue; }
      const m = uniToCp.get(ch);
      out += m !== undefined ? String.fromCharCode(m) : '?';
    }
    return out;
  };
  /** BASIC byte string -> Unicode (for display outside the emulated screen). Keeps \t\r\n. */
  RC.fromCP437 = function (s, keepControls) {
    let out = '';
    for (let i = 0; i < s.length; i++) {
      const c = s.charCodeAt(i) & 255;
      if (c >= 32 && c < 127) out += s[i];
      else if (keepControls !== false && (c === 9 || c === 10 || c === 13)) out += s[i];
      else out += CP437[c];
    }
    return out;
  };
  RC.bytesToStr = function (bytes, start, end) {
    start = start || 0; end = end === undefined ? bytes.length : end;
    let s = '';
    const CH = 8192;
    for (let i = start; i < end; i += CH) {
      s += String.fromCharCode.apply(null, bytes.subarray(i, Math.min(end, i + CH)));
    }
    return s;
  };
  RC.strToBytes = function (s) {
    const a = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i++) a[i] = s.charCodeAt(i) & 255;
    return a;
  };
  /** UTF-8 text -> Uint8Array */
  RC.utf8 = function (s) { return new TextEncoder().encode(s); };
  RC.unutf8 = function (b) { return new TextDecoder().decode(b); };

  RC.clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);
  RC.escapeHtml = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  /** Tiny event emitter mixin */
  RC.Emitter = class {
    constructor() { this._h = {}; }
    on(ev, fn) { (this._h[ev] || (this._h[ev] = [])).push(fn); return () => this.off(ev, fn); }
    off(ev, fn) { const a = this._h[ev]; if (a) { const i = a.indexOf(fn); if (i >= 0) a.splice(i, 1); } }
    emit(ev, ...args) { const a = this._h[ev]; if (a) for (const fn of a.slice()) fn(...args); }
  };

  RC.isBrowser = typeof window !== 'undefined' && typeof document !== 'undefined';
})(RC);
