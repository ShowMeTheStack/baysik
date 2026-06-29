// PC keyboard emulation: BIOS-style key buffer, extended scan codes, port 60h, shift flags.
(function (RC) {
  'use strict';

  // DOM `code` -> PC set-1 scan code
  const SCAN = {
    Escape: 1, Digit1: 2, Digit2: 3, Digit3: 4, Digit4: 5, Digit5: 6, Digit6: 7, Digit7: 8, Digit8: 9, Digit9: 10, Digit0: 11,
    Minus: 12, Equal: 13, Backspace: 14, Tab: 15, KeyQ: 16, KeyW: 17, KeyE: 18, KeyR: 19, KeyT: 20, KeyY: 21, KeyU: 22,
    KeyI: 23, KeyO: 24, KeyP: 25, BracketLeft: 26, BracketRight: 27, Enter: 28, ControlLeft: 29, ControlRight: 29,
    KeyA: 30, KeyS: 31, KeyD: 32, KeyF: 33, KeyG: 34, KeyH: 35, KeyJ: 36, KeyK: 37, KeyL: 38, Semicolon: 39, Quote: 40,
    Backquote: 41, ShiftLeft: 42, Backslash: 43, KeyZ: 44, KeyX: 45, KeyC: 46, KeyV: 47, KeyB: 48, KeyN: 49, KeyM: 50,
    Comma: 51, Period: 52, Slash: 53, ShiftRight: 54, NumpadMultiply: 55, AltLeft: 56, AltRight: 56, Space: 57, CapsLock: 58,
    F1: 59, F2: 60, F3: 61, F4: 62, F5: 63, F6: 64, F7: 65, F8: 66, F9: 67, F10: 68, NumLock: 69, ScrollLock: 70,
    Home: 71, Numpad7: 71, ArrowUp: 72, Numpad8: 72, PageUp: 73, Numpad9: 73, NumpadSubtract: 74, ArrowLeft: 75, Numpad4: 75,
    Numpad5: 76, ArrowRight: 77, Numpad6: 77, NumpadAdd: 78, End: 79, Numpad1: 79, ArrowDown: 80, Numpad2: 80,
    PageDown: 81, Numpad3: 81, Insert: 82, Numpad0: 82, Delete: 83, NumpadDecimal: 83, F11: 87, F12: 88, NumpadEnter: 28,
    NumpadDivide: 53,
  };
  const EXT_PLAIN = { Home: 71, ArrowUp: 72, PageUp: 73, ArrowLeft: 75, ArrowRight: 77, End: 79, ArrowDown: 80, PageDown: 81, Insert: 82, Delete: 83 };
  const CTRL_EXT = { ArrowLeft: 115, ArrowRight: 116, End: 117, PageDown: 118, Home: 119, PageUp: 132, ArrowUp: 141, ArrowDown: 145, Insert: 146, Delete: 147 };

  class Keyboard {
    constructor() {
      this.buf = [];
      this.max = 16;
      this.pressCount = 0;
      this.lastScan = 0;
      this.down = new Set();
      this.shift = false; this.ctrl = false; this.alt = false;
      this.caps = false; this.num = false; this.scroll = false; this.insert = false;
      this.trap = null; // (keyNumber, flags, scan) => bool consumed
      this.onBreak = null;
      this.onKey = null;
    }
    clear() { this.buf.length = 0; }
    push(k) {
      if (this.buf.length >= this.max) { if (this.onOverflow) this.onOverflow(); return; }
      this.buf.push(k);
      this.pressCount++;
    }
    /** Next key (INKEY$ format) or '' */
    get() { return this.buf.length ? this.buf.shift() : ''; }
    peek() { return this.buf.length ? this.buf[0] : ''; }
    /** Type a string as keystrokes (paste / tests). "\n" becomes Enter. */
    type(text) {
      for (const ch of RC.toCP437(text.replace(/\r\n?/g, '\n'))) {
        if (ch === '\n') { this.buf.push('\r'); this.pressCount++; }
        else { this.buf.push(ch); this.pressCount++; }
      }
    }
    flags() {
      // BIOS 0:417h keyboard flag byte
      return (this.shift ? 3 : 0) | (this.ctrl ? 4 : 0) | (this.alt ? 8 : 0) | (this.scroll ? 16 : 0) |
        (this.num ? 32 : 0) | (this.caps ? 64 : 0) | (this.insert ? 128 : 0);
    }

    /** Translate a DOM keydown. Returns true if the event was consumed. */
    keyDown(e) {
      const code = e.code;
      const scan = SCAN[code] || 0;
      this.shift = e.shiftKey; this.ctrl = e.ctrlKey; this.alt = e.altKey;
      if (e.getModifierState) {
        this.caps = e.getModifierState('CapsLock');
        this.num = e.getModifierState('NumLock');
        this.scroll = e.getModifierState('ScrollLock');
      }
      if (scan) { this.lastScan = scan; this.down.add(scan); }
      if (code === 'Insert') this.insert = !this.insert;
      if ((code === 'Pause' || code === 'Cancel') && e.ctrlKey) { if (this.onBreak) this.onBreak(); return true; }
      if (code === 'ScrollLock' && e.ctrlKey) { if (this.onBreak) this.onBreak(); return true; }

      // Event trapping (KEY(n))
      if (this.trap) {
        let n = 0;
        if (scan >= 59 && scan <= 68 && !e.shiftKey && !e.ctrlKey && !e.altKey) n = scan - 58;
        else if (code === 'ArrowUp') n = 11;
        else if (code === 'ArrowLeft') n = 12;
        else if (code === 'ArrowRight') n = 13;
        else if (code === 'ArrowDown') n = 14;
        else if (code === 'F11') n = 30;
        else if (code === 'F12') n = 31;
        if (n && this.trap(n, this.flags(), scan)) return true;
        if (scan && this.trap(-1, this.flags(), scan)) return true;
      }

      const k = this.translate(e, scan);
      if (k === null) return !!scan;
      this.push(k);
      if (this.onKey) this.onKey(k);
      return true;
    }
    keyUp(e) {
      const scan = SCAN[e.code] || 0;
      this.shift = e.shiftKey; this.ctrl = e.ctrlKey; this.alt = e.altKey;
      if (scan) { this.lastScan = scan | 0x80; this.down.delete(scan); }
    }

    translate(e, scan) {
      const code = e.code, key = e.key;
      const ext = (n) => '\0' + String.fromCharCode(n);
      if (scan >= 59 && scan <= 68) {
        const i = scan - 59;
        if (e.altKey) return ext(104 + i);
        if (e.ctrlKey) return ext(94 + i);
        if (e.shiftKey) return ext(84 + i);
        return ext(59 + i);
      }
      if (code === 'F11') return ext(e.altKey ? 139 : e.ctrlKey ? 137 : e.shiftKey ? 135 : 133);
      if (code === 'F12') return ext(e.altKey ? 140 : e.ctrlKey ? 138 : e.shiftKey ? 136 : 134);
      if (EXT_PLAIN[code] !== undefined && !(code.startsWith('Numpad') && this.num)) {
        if (e.ctrlKey && CTRL_EXT[code]) return ext(CTRL_EXT[code]);
        return ext(EXT_PLAIN[code]);
      }
      if (code === 'Tab' && e.shiftKey) return ext(15);
      if (e.altKey && !e.ctrlKey) {
        if (scan >= 16 && scan <= 50 && /^Key/.test(code)) return ext(scan);
        if (/^Digit/.test(code)) return ext(scan + 118);
        return null;
      }
      switch (key) {
        case 'Enter': return '\r';
        case 'Backspace': return e.ctrlKey ? '\x7f' : '\b';
        case 'Tab': return '\t';
        case 'Escape': return '\x1b';
      }
      if (e.ctrlKey && key.length === 1) {
        const c = key.toUpperCase().charCodeAt(0);
        if (c >= 64 && c <= 95) return String.fromCharCode(c - 64);
        return null;
      }
      if (key.length === 1) return RC.toCP437(key);
      return null;
    }
  }
  Keyboard.SCAN = SCAN;
  RC.Keyboard = Keyboard;
})(RC);
