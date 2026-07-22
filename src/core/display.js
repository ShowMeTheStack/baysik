// Emulated PC display: text mode + CGA/EGA/VGA/Hercules graphics modes, pages, palettes,
// fonts, VIEW/WINDOW coordinate systems and graphics primitives. Rendering to a canvas is
// optional (headless use for tests).
(function (RC) {
  'use strict';
  const err = (c) => { throw new RC.Basic.BasicError(c); };

  // ---- color tables ----------------------------------------------------------------------
  const CGA16 = [0x000000, 0x0000AA, 0x00AA00, 0x00AAAA, 0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA,
    0x555555, 0x5555FF, 0x55FF55, 0x55FFFF, 0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF];
  function ega64(c) {
    const r = ((c >> 2) & 1) * 0xAA + ((c >> 5) & 1) * 0x55;
    const g = ((c >> 1) & 1) * 0xAA + ((c >> 4) & 1) * 0x55;
    const b = (c & 1) * 0xAA + ((c >> 3) & 1) * 0x55;
    return (r << 16) | (g << 8) | b;
  }
  const EGA_DEFAULT = [0, 1, 2, 3, 4, 5, 20, 7, 56, 57, 58, 59, 60, 61, 62, 63];

  /** Default VGA 256-color DAC palette (6-bit components). */
  function vgaDefaultDac() {
    const dac = [];
    for (let i = 0; i < 16; i++) {
      const c = CGA16[i];
      dac.push([((c >> 16) & 255) >> 2, ((c >> 8) & 255) >> 2, (c & 255) >> 2]);
    }
    const greys = [0, 5, 8, 11, 14, 17, 20, 24, 28, 32, 36, 40, 45, 50, 56, 63];
    for (const g of greys) dac.push([g, g, g]);
    const blocks = [[63, 0], [63, 31], [63, 45], [28, 0], [28, 14], [28, 20], [16, 0], [16, 8], [16, 11]];
    for (const [hi, lo] of blocks) {
      const step = (hi - lo) / 4;
      const lv = [lo, Math.round(lo + step), Math.round(lo + 2 * step), Math.round(lo + 3 * step), hi];
      // hue wheel: B, B+R, R, R+G, G, G+B
      const seq = [];
      for (let i = 0; i < 4; i++) seq.push([lv[i], lo, hi]); // blue -> magenta (R up)
      for (let i = 4; i > 0; i--) seq.push([hi, lo, lv[i]]); // magenta -> red (B down)
      for (let i = 0; i < 4; i++) seq.push([hi, lv[i], lo]); // red -> yellow (G up)
      for (let i = 4; i > 0; i--) seq.push([lv[i], hi, lo]); // yellow -> green (R down)
      for (let i = 0; i < 4; i++) seq.push([lo, hi, lv[i]]); // green -> cyan (B up)
      for (let i = 4; i > 0; i--) seq.push([lo, lv[i], hi]); // cyan -> blue (G down)
      for (const c of seq) dac.push(c);
    }
    while (dac.length < 256) dac.push([0, 0, 0]);
    return dac;
  }
  const dac6to8 = (v) => Math.round((v * 255) / 63);

  // ---- mode table ----------------------------------------------------------------------
  // planes: number of bit planes for GET/PUT/tile layout (0 = packed)
  const MODES = {
    0: { text: true, cols: 80, rows: 25, cw: 8, ch: 16, attrs: 16, pages: 8, space: 'ega' },
    1: { w: 320, h: 200, cols: 40, rows: 25, cw: 8, ch: 8, attrs: 4, bpp: 2, pages: 1, space: 'cga4', aspect: 5 / 6 },
    2: { w: 640, h: 200, cols: 80, rows: 25, cw: 8, ch: 8, attrs: 2, bpp: 1, pages: 1, space: 'mono2', aspect: 5 / 12 },
    3: { w: 720, h: 348, cols: 80, rows: 25, cw: 9, ch: 14, attrs: 2, bpp: 1, pages: 2, space: 'herc', aspect: 0.6667 },
    7: { w: 320, h: 200, cols: 40, rows: 25, cw: 8, ch: 8, attrs: 16, planes: 4, pages: 8, space: 'cga16', aspect: 5 / 6 },
    8: { w: 640, h: 200, cols: 80, rows: 25, cw: 8, ch: 8, attrs: 16, planes: 4, pages: 4, space: 'cga16', aspect: 5 / 12 },
    9: { w: 640, h: 350, cols: 80, rows: 25, cw: 8, ch: 14, attrs: 16, planes: 4, pages: 2, space: 'ega', aspect: 0.7292 },
    10: { w: 640, h: 350, cols: 80, rows: 25, cw: 8, ch: 14, attrs: 4, planes: 2, pages: 2, space: 'mono10', aspect: 0.7292 },
    11: { w: 640, h: 480, cols: 80, rows: 30, cw: 8, ch: 16, attrs: 2, bpp: 1, pages: 1, space: 'dac', aspect: 1 },
    12: { w: 640, h: 480, cols: 80, rows: 30, cw: 8, ch: 16, attrs: 16, planes: 4, pages: 1, space: 'dac', aspect: 1 },
    13: { w: 320, h: 200, cols: 40, rows: 25, cw: 8, ch: 8, attrs: 256, bpp: 8, pages: 1, space: 'dac', aspect: 5 / 6 },
  };
  RC.SCREEN_MODES = MODES;
  const MONO10 = [0x000000, 0xAAAAAA, 0xAAAAAA, 0xFFFFFF, 0xFFFFFF, 0x555555, 0xAAAAAA, 0xFFFFFF, 0xFFFFFF];

  class Display extends RC.Emitter {
    constructor(opts) {
      super();
      this.opts = opts || {};
      this.canvas = null;
      this.ctx = null;
      this.dac = vgaDefaultDac();
      this.dacWriteIdx = 0; this.dacReadIdx = 0; this.dacComp = 0;
      this.keyLineOn = false;
      this.softKeys = null;
      this.blinkPhase = false;
      this.screen(0, undefined, 0, 0, true);
    }

    attach(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d', { alpha: false });
      this.resizeCanvas();
      this.dirty = true;
    }

    // ---- mode setup ----------------------------------------------------------------------
    screen(mode, colorSwitch, apage, vpage, force) {
      if (mode === undefined) mode = this.mode;
      if (!MODES[mode]) err(5);
      const changing = force || mode !== this.mode;
      const m = MODES[mode];
      if (changing) {
        this.mode = mode;
        this.m = Object.assign({}, m);
        if (m.text) {
          this.m.cols = this.textWidthPref || 80;
          this.m.rows = 25;
        }
        this.setupGeometry();
        this.resetPalette();
        this.allocPages();
        this.apage = 0; this.vpage = 0;
        this.fg = mode === 0 ? 7 : (m.attrs - 1 > 15 ? 15 : m.attrs - 1);
        this.bg = 0;
        this.border = 0;
        if (mode === 0) this.fg = 7;
        this.cgaPalette = 1;
        this.resetText();
        this.resetGraphicsState();
        this.cursorVisible = false;
        this.colorSwitch = colorSwitch;
        if (this.keyLineOn) { this.viewBottom = this.rows - 2; this.drawKeyLine(); }
        this.emit('mode', mode);
      }
      const np = this.m.pages;
      if (apage !== undefined) { if (apage < 0 || apage >= np) err(5); this.apage = apage; }
      if (vpage !== undefined) { if (vpage < 0 || vpage >= np) err(5); this.vpage = vpage; }
      else if (apage !== undefined && changing) this.vpage = 0;
      this.dirty = true;
    }

    setupGeometry() {
      const m = this.m;
      if (m.text) {
        m.cw = 8;
        m.ch = m.rows === 25 ? 16 : 8;
        m.w = m.cols * 8;
        m.h = m.rows * m.ch;
      }
      this.cols = m.cols; this.rows = m.rows;
      this.W = m.w; this.H = m.h;
      this.font = RC.fonts ? RC.fonts[m.ch === 14 ? 14 : m.ch === 16 ? 16 : 8] : null;
      this.resizeCanvas();
    }

    resizeCanvas() {
      if (!this.canvas) return;
      if (this.canvas.width !== this.W || this.canvas.height !== this.H) {
        this.canvas.width = this.W;
        this.canvas.height = this.H;
        this.image = this.ctx.createImageData(this.W, this.H);
        this.image32 = new Uint32Array(this.image.data.buffer);
      } else if (!this.image) {
        this.image = this.ctx.createImageData(this.W, this.H);
        this.image32 = new Uint32Array(this.image.data.buffer);
      }
      this.emit('resize', this.W, this.H);
    }

    allocPages() {
      const m = this.m;
      this.pages = [];
      for (let i = 0; i < m.pages; i++) {
        const p = { chars: new Uint8Array(this.cols * this.rows).fill(32), attrs: new Uint8Array(this.cols * this.rows).fill(7) };
        if (!m.text) p.pix = new Uint8Array(this.W * this.H);
        this.pages.push(p);
      }
    }

    resetText() {
      this.row = 0; this.col = 0;
      this.viewTop = 0;
      this.viewBottom = this.rows - 1 - (this.keyLineOn ? 1 : 0);
      this.pendingWrap = false;
    }

    resetGraphicsState() {
      this.vx1 = 0; this.vy1 = 0; this.vx2 = this.W - 1; this.vy2 = this.H - 1;
      this.viewScreen = true; this.viewActive = false;
      this.win = null;
      this.lastX = (this.vx2 + 1) / 2; this.lastY = (this.vy2 + 1) / 2;
      this.lastPhysX = Math.floor(this.lastX); this.lastPhysY = Math.floor(this.lastY);
      this.drawAngle = 0; this.drawScale = 4; this.drawTA = 0;
    }

    resetPalette() {
      const m = this.m;
      this.palMap = new Int32Array(Math.min(m.attrs, 256));
      switch (m.space) {
        case 'ega': for (let i = 0; i < 16; i++) this.palMap[i] = EGA_DEFAULT[i]; break;
        case 'cga16': for (let i = 0; i < 16; i++) this.palMap[i] = i; break;
        case 'cga4': this.palMap[0] = 0; break;
        case 'mono2': this.palMap[0] = 0; this.palMap[1] = 15; break;
        case 'herc': this.palMap[0] = 0; this.palMap[1] = 1; break;
        case 'mono10': this.palMap[0] = 0; this.palMap[1] = 3; this.palMap[2] = 6; this.palMap[3] = 8; break;
        case 'dac':
          this.dac = vgaDefaultDac();
          if (this.mode === 11) { this.dac[1] = [63, 63, 63]; }
          if (this.mode === 12 || this.mode === 11) {
            // attrs 0-15 use EGA default colors
            for (let i = 0; i < 16; i++) {
              const c = ega64(EGA_DEFAULT[i]);
              this.dac[i] = [((c >> 16) & 255) >> 2, ((c >> 8) & 255) >> 2, (c & 255) >> 2];
            }
            if (this.mode === 11) this.dac[1] = [63, 63, 63];
          }
          break;
      }
      this.rgb = new Uint32Array(256);
      this.updateRgb();
    }

    /** Recompute attr -> RGBA lookup */
    updateRgb() {
      const m = this.m;
      const rgb = this.rgb;
      const toAbgr = (c) => 0xFF000000 | ((c & 255) << 16) | (c & 0xFF00) | ((c >> 16) & 255);
      for (let a = 0; a < 256; a++) {
        let c = 0;
        switch (m.space) {
          case 'ega': c = ega64(this.palMap[a & 15] & 63); break;
          case 'cga16': c = CGA16[this.palMap[a & 15] & 15]; break;
          case 'cga4': {
            const sets = [[0, 10, 12, 14], [0, 11, 13, 15]];
            if ((a & 3) === 0) c = CGA16[this.palMap[0] & 15];
            else if (this.palOverride && this.palOverride[a & 3] !== undefined) c = CGA16[this.palOverride[a & 3] & 15];
            else c = CGA16[sets[this.cgaPalette & 1][a & 3]];
            break;
          }
          case 'mono2': c = CGA16[this.palMap[a & 1] & 15]; break;
          case 'herc': c = (a & 1) ? 0xCCCCCC : 0; break;
          case 'mono10': c = MONO10[this.palMap[a & 3] % 9]; break;
          case 'dac': {
            const d = this.dac[m.attrs === 2 ? (a & 1) : a & 255];
            c = (dac6to8(d[0]) << 16) | (dac6to8(d[1]) << 8) | dac6to8(d[2]);
            break;
          }
        }
        rgb[a] = toAbgr(c);
      }
      this.dirty = true;
    }

    // ---- palette statements -------------------------------------------------------------
    palette(attr, color) {
      const m = this.m;
      if (attr === undefined) { this.palOverride = null; this.resetPalette(); return; }
      if (attr < 0 || attr >= m.attrs) err(5);
      if (color === undefined) err(5);
      if (color === -1) return;
      switch (m.space) {
        case 'ega': if (color < 0 || color > 63) err(5); this.palMap[attr] = color; break;
        case 'cga16': if (color < 0 || color > 15) err(5); this.palMap[attr] = color; break;
        case 'cga4':
          if (color < 0 || color > 15) err(5);
          if (attr === 0) this.palMap[0] = color; else { this.palOverride = this.palOverride || {}; this.palOverride[attr] = color; }
          break;
        case 'mono2': if (color < 0 || color > 15) err(5); this.palMap[attr] = color; break;
        case 'herc': break;
        case 'mono10': if (color < 0 || color > 8) err(5); this.palMap[attr] = color; break;
        case 'dac': {
          if (color < 0 || color > 0x3F3F3F || (color & 0xC0C0C0)) err(5);
          this.dac[attr] = [color & 63, (color >> 8) & 63, (color >> 16) & 63];
          break;
        }
      }
      this.updateRgb();
    }
    paletteUsing(data, start) {
      const n = this.m.attrs > 16 ? 256 : this.m.attrs;
      if (start + n > data.length) err(5);
      for (let i = 0; i < n; i++) {
        const c = data[start + i];
        if (c !== -1) this.palette(i, c);
      }
    }

    // ---- COLOR ---------------------------------------------------------------------------
    color(a, b, c) {
      const m = this.m;
      const mode = this.mode;
      if (mode === 0) {
        if (a !== undefined) { if (a < 0 || a > 31) err(5); this.fg = a; }
        if (b !== undefined) { if (b < 0 || b > 15) err(5); this.bg = b; }
        if (c !== undefined) { if (c < 0 || c > 15) err(5); this.border = c; }
        return;
      }
      if (mode === 1) {
        if (a !== undefined) { if (a < 0 || a > 255) err(5); this.palMap[0] = a & 15; }
        if (b !== undefined) { this.cgaPalette = b & 1; this.palOverride = null; }
        this.updateRgb();
        return;
      }
      if (mode === 2 || mode === 3) err(5);
      if (mode === 11 || mode === 12 || mode === 13) {
        if (b !== undefined && mode !== 12) err(5);
        if (a !== undefined) { if (a < 0 || a >= m.attrs) err(5); this.fg = a; }
        if (b !== undefined) { if (b < 0 || b >= m.attrs) err(5); this.bg = b; }
        return;
      }
      // 7, 8, 9, 10
      if (a !== undefined) { if (a < 0 || a >= m.attrs) err(5); this.fg = a; }
      if (b !== undefined) {
        const maxc = mode === 9 ? 63 : mode === 10 ? 8 : 15;
        if (b < 0 || b > maxc) err(5);
        this.palMap[0] = b;
        this.updateRgb();
      }
    }

    // ---- WIDTH / VIEW PRINT / LOCATE -------------------------------------------------------
    width(cols, rows) {
      const mode = this.mode;
      if (cols === undefined) cols = this.cols;
      if (rows === undefined) rows = this.rows;
      if (mode === 0) {
        if (cols !== 40 && cols !== 80) err(5);
        if (![25, 43, 50].includes(rows)) err(5);
        this.textWidthPref = cols;
        this.m.cols = cols; this.m.rows = rows;
        this.setupGeometry(); this.allocPages(); this.resetText(); this.dirty = true;
        return;
      }
      if (mode === 1 && cols === 80) { this.screen(2); return; }
      if (mode === 2 && cols === 40) { this.screen(1); return; }
      if (mode === 7 && cols === 80) { this.screen(8); return; }
      if (mode === 8 && cols === 40) { this.screen(7); return; }
      if ((mode === 9 || mode === 10) && (rows === 25 || rows === 43) && cols === 80) {
        this.m.rows = rows; this.m.ch = rows === 43 ? 8 : 14; this.setupGeometry(); this.allocPages(); this.resetText(); this.resetGraphicsState(); this.dirty = true; return;
      }
      if ((mode === 11 || mode === 12) && (rows === 30 || rows === 60) && cols === 80) {
        this.m.rows = rows; this.m.ch = rows === 60 ? 8 : 16; this.setupGeometry(); this.allocPages(); this.resetText(); this.resetGraphicsState(); this.dirty = true; return;
      }
      if (cols === this.cols && rows === this.rows) return;
      err(5);
    }
    viewPrint(top, bottom) {
      const maxRow = this.rows - (this.keyLineOn ? 1 : 0);
      if (top === undefined) { this.viewTop = 0; this.viewBottom = maxRow - 1; }
      else {
        if (top < 1 || bottom > maxRow || top > bottom) err(5);
        this.viewTop = top - 1; this.viewBottom = bottom - 1;
      }
      this.row = this.viewTop; this.col = 0; this.pendingWrap = false;
    }
    locate(r, c, cur, start, stop) {
      if (r !== undefined) {
        if (r < 1 || r > this.rows) err(5);
        this.row = r - 1;
      }
      if (c !== undefined) {
        if (c < 1 || c > this.cols) err(5);
        this.col = c - 1;
      }
      if (r !== undefined || c !== undefined) this.pendingWrap = false;
      if (cur !== undefined) this.cursorVisible = !!cur;
      if (start !== undefined) this.cursorStart = start;
      if (stop !== undefined) this.cursorStop = stop;
      this.dirty = true;
    }
    cursorRow() { return this.row; }
    cursorCol() { return this.pendingWrap ? this.cols : this.col; }
    textCols() { return this.cols; }
    textRows() { return this.rows; }
    setCursor(r, c) {
      this.row = RC.clamp(r, 0, this.rows - 1);
      this.col = RC.clamp(c, 0, this.cols - 1);
      this.pendingWrap = false;
      this.dirty = true;
    }
    setCursorVisible(v, temp) {
      if (temp) this.inputCursor = v; else this.cursorVisible = v;
      this.dirty = true;
    }

    // ---- text output -------------------------------------------------------------------------
    textAttr() {
      if (this.mode === 0) return ((this.fg & 16) << 3) | ((this.bg & 7) << 4) | (this.fg & 15);
      return this.fg;
    }
    printString(s, raw) {
      for (let i = 0; i < s.length; i++) {
        const c = s.charCodeAt(i) & 255;
        if (!raw && c < 32) {
          switch (c) {
            case 7: this.emit('beep'); continue;
            case 9: { // TAB to next multiple of 8
              const target = (Math.floor(this.cursorCol() / 8) + 1) * 8;
              let n = target - this.cursorCol();
              while (n-- > 0) this.putChar(32);
              continue;
            }
            case 10: case 13: this.newline(); continue;
            case 11: this.row = this.viewTop; this.col = 0; this.pendingWrap = false; continue;
            case 12: this.cls(2); continue;
            case 28: if (this.col < this.cols - 1) this.col++; this.pendingWrap = false; continue;
            case 29: if (this.col > 0) this.col--; this.pendingWrap = false; continue;
            case 30: if (this.row > this.viewTop) this.row--; continue;
            case 31: if (this.row < this.viewBottom) this.row++; continue;
          }
        }
        this.putChar(c);
      }
      this.dirty = true;
    }
    putChar(c) {
      if (this.pendingWrap) {
        this.pendingWrap = false;
        this.col = 0;
        this.lineFeed();
      }
      this.setCell(this.apage, this.row, this.col, c, this.textAttr());
      if (this.col >= this.cols - 1) this.pendingWrap = true;
      else this.col++;
    }
    newline() {
      this.pendingWrap = false;
      this.col = 0;
      this.lineFeed();
      this.dirty = true;
    }
    lineFeed() {
      if (this.row >= this.viewBottom) {
        if (this.row === this.viewBottom) this.scrollUp();
        else if (this.row < this.rows - 1) this.row++;
      } else this.row++;
    }
    setCell(page, r, c, ch, attr) {
      const p = this.pages[page];
      const i = r * this.cols + c;
      p.chars[i] = ch;
      p.attrs[i] = attr;
      if (!this.m.text) this.drawGlyph(page, r, c, ch, attr, this.mode === 0 ? 0 : 0);
      this.dirty = true;
    }
    drawGlyph(page, r, c, ch, fgAttr, bgAttr) {
      const m = this.m;
      const pix = this.pages[page].pix;
      const font = this.font;
      const fh = m.ch, cw = m.cw;
      const W = this.W;
      const x0 = c * cw, y0 = r * fh;
      const mask = m.attrs - 1;
      const fgc = fgAttr & mask, bgc = bgAttr & mask;
      const fontH = font.length / 256;
      for (let y = 0; y < fh; y++) {
        const py = y0 + y;
        if (py >= this.H) break;
        const bits = y < fontH ? font[ch * fontH + y] : 0;
        let off = py * W + x0;
        for (let x = 0; x < cw; x++) {
          const on = x < 8 ? (bits >> (7 - x)) & 1 : 0;
          pix[off++] = on ? fgc : bgc;
        }
      }
    }
    scrollUp() {
      const top = this.viewTop, bot = this.viewBottom;
      const p = this.pages[this.apage];
      const cols = this.cols;
      p.chars.copyWithin(top * cols, (top + 1) * cols, (bot + 1) * cols);
      p.attrs.copyWithin(top * cols, (top + 1) * cols, (bot + 1) * cols);
      const blankAttr = this.mode === 0 ? (this.textAttr() & 0x70) | 7 : 0;
      p.chars.fill(32, bot * cols, (bot + 1) * cols);
      p.attrs.fill(this.mode === 0 ? ((this.bg & 7) << 4) | (this.fg & 15) : blankAttr, bot * cols, (bot + 1) * cols);
      if (!this.m.text) {
        const ch = this.m.ch, W = this.W;
        const y0 = top * ch, y1 = (bot + 1) * ch;
        p.pix.copyWithin(y0 * W, (y0 + ch) * W, Math.min(y1, this.H) * W);
        p.pix.fill(0, (y1 - ch) * W, Math.min(y1, this.H) * W);
      }
      this.emit('scroll');
      this.dirty = true;
    }

    cls(n) {
      const p = this.pages[this.apage];
      const cols = this.cols;
      const clearText = (top, bot) => {
        const attr = this.mode === 0 ? ((this.bg & 7) << 4) | (this.fg & 15) : 0;
        p.chars.fill(32, top * cols, (bot + 1) * cols);
        p.attrs.fill(attr, top * cols, (bot + 1) * cols);
        if (!this.m.text) {
          const ch = this.m.ch;
          p.pix.fill(0, top * ch * this.W, Math.min((bot + 1) * ch, this.H) * this.W);
        }
      };
      if (n === undefined) n = this.viewActive ? 1 : (this.viewTop !== 0 || this.viewBottom !== this.rows - 1 - (this.keyLineOn ? 1 : 0) ? 2 : 0);
      if (n === 0) {
        clearText(0, this.rows - 1 - (this.keyLineOn ? 1 : 0));
        if (!this.m.text) p.pix.fill(0, 0, this.keyLineOn ? (this.rows - 1) * this.m.ch * this.W : p.pix.length);
        this.row = this.viewTop; this.col = 0;
      } else if (n === 1) {
        if (!this.m.text) {
          for (let y = this.vy1; y <= this.vy2; y++) p.pix.fill(0, y * this.W + this.vx1, y * this.W + this.vx2 + 1);
        }
        if (!this.viewActive) { clearText(0, this.rows - 1 - (this.keyLineOn ? 1 : 0)); this.row = this.viewTop; this.col = 0; }
      } else if (n === 2) {
        clearText(this.viewTop, this.viewBottom);
        this.row = this.viewTop; this.col = 0;
      } else err(5);
      this.pendingWrap = false;
      if (!this.m.text) {
        this.lastX = this.win ? (this.win.x1 + this.win.x2) / 2 : (this.viewScreen ? (this.vx1 + this.vx2 + 1) / 2 : (this.vx2 - this.vx1 + 1) / 2);
        this.lastY = this.win ? (this.win.y1 + this.win.y2) / 2 : (this.viewScreen ? (this.vy1 + this.vy2 + 1) / 2 : (this.vy2 - this.vy1 + 1) / 2);
      }
      if (this.keyLineOn) this.drawKeyLine();
      this.dirty = true;
    }

    screenFn(r, c, colorFlag) {
      if (r < 1 || r > this.rows || c < 1 || c > this.cols) err(5);
      const p = this.pages[this.apage];
      const i = (r - 1) * this.cols + (c - 1);
      if (colorFlag) return this.m.text ? p.attrs[i] : 0;
      return p.chars[i];
    }

    // ---- KEY ON line ------------------------------------------------------------------------------
    setKeyLine(on, keys) {
      this.keyLineOn = on;
      this.softKeys = keys;
      const maxBottom = this.rows - 1 - (on ? 1 : 0);
      if (this.viewBottom > maxBottom || (!on && this.viewBottom === this.rows - 2)) this.viewBottom = maxBottom;
      if (this.row > this.viewBottom) this.row = this.viewBottom;
      if (on) this.drawKeyLine();
      else {
        const p = this.pages[this.apage];
        const r = this.rows - 1;
        p.chars.fill(32, r * this.cols, (r + 1) * this.cols);
        p.attrs.fill(this.mode === 0 ? 7 : 0, r * this.cols, (r + 1) * this.cols);
        if (!this.m.text) for (let c = 0; c < this.cols; c++) this.drawGlyph(this.apage, r, c, 32, 0, 0);
      }
      this.dirty = true;
    }
    refreshKeyLine(keys) { this.softKeys = keys; if (this.keyLineOn) this.drawKeyLine(); }
    drawKeyLine() {
      const keys = this.softKeys || [];
      const r = this.rows - 1;
      const per = this.cols === 40 ? 5 : 10;
      const cellW = Math.floor(this.cols / per);
      const p = this.pages[this.apage];
      for (let c = 0; c < this.cols; c++) {
        const i = r * this.cols + c;
        p.chars[i] = 32; p.attrs[i] = this.mode === 0 ? 7 : 0;
        if (!this.m.text) this.drawGlyph(this.apage, r, c, 32, 0, 0);
      }
      for (let k = 0; k < per; k++) {
        const label = String((k + 1) % 10);
        let text = (keys[k] || '').replace(/\r/g, '\x1b').slice(0, cellW - 2);
        const x = k * cellW;
        this.putRaw(r, x, label, this.mode === 0 ? 7 : this.m.attrs - 1);
        this.putRaw(r, x + 1, text.replace(/\x1b/g, String.fromCharCode(27)), this.mode === 0 ? 0x70 : this.m.attrs - 1);
      }
    }
    putRaw(r, c, s, attr) {
      for (let i = 0; i < s.length && c + i < this.cols; i++) {
        const p = this.pages[this.apage];
        const idx = r * this.cols + c + i;
        p.chars[idx] = s.charCodeAt(i) & 255; p.attrs[idx] = attr;
        if (!this.m.text) this.drawGlyph(this.apage, r, c + i, s.charCodeAt(i) & 255, attr, 0);
      }
    }

    // ---- coordinate systems ---------------------------------------------------------------------------
    requireGraphics() { if (this.m.text) err(5); }
    /** logical -> physical x,y (floats) */
    toPhysX(x) {
      if (this.win) return this.vx1 + (x - this.win.x1) * this.win.sx;
      return this.viewScreen ? x : this.vx1 + x;
    }
    toPhysY(y) {
      if (this.win) return this.win.inv ? this.vy1 + (this.win.y2 - y) * this.win.sy : this.vy1 + (y - this.win.y1) * this.win.sy;
      return this.viewScreen ? y : this.vy1 + y;
    }
    toLogX(px) {
      if (this.win) return this.win.x1 + (px - this.vx1) / this.win.sx;
      return this.viewScreen ? px : px - this.vx1;
    }
    toLogY(py) {
      if (this.win) return this.win.inv ? this.win.y2 - (py - this.vy1) / this.win.sy : this.win.y1 + (py - this.vy1) / this.win.sy;
      return this.viewScreen ? py : py - this.vy1;
    }
    round(v) { return Math.floor(v + 0.5); }

    view(scr, x1, y1, x2, y2, color, border) {
      this.requireGraphics();
      if (x1 === undefined) {
        this.vx1 = 0; this.vy1 = 0; this.vx2 = this.W - 1; this.vy2 = this.H - 1;
        this.viewScreen = true; this.viewActive = false;
      } else {
        x1 = Math.round(x1); y1 = Math.round(y1); x2 = Math.round(x2); y2 = Math.round(y2);
        if (x1 > x2) [x1, x2] = [x2, x1];
        if (y1 > y2) [y1, y2] = [y2, y1];
        if (x1 < 0 || y1 < 0 || x2 >= this.W || y2 >= this.H) err(5);
        this.vx1 = x1; this.vy1 = y1; this.vx2 = x2; this.vy2 = y2;
        this.viewScreen = !!scr; this.viewActive = true;
        if (color !== undefined) {
          const p = this.pages[this.apage].pix;
          const c = color & (this.m.attrs - 1);
          for (let y = y1; y <= y2; y++) p.fill(c, y * this.W + x1, y * this.W + x2 + 1);
        }
        if (border !== undefined) {
          const c = border & (this.m.attrs - 1);
          const p = this.pages[this.apage].pix;
          const put = (x, y) => { if (x >= 0 && y >= 0 && x < this.W && y < this.H) p[y * this.W + x] = c; };
          for (let x = x1 - 1; x <= x2 + 1; x++) { put(x, y1 - 1); put(x, y2 + 1); }
          for (let y = y1 - 1; y <= y2 + 1; y++) { put(x1 - 1, y); put(x2 + 1, y); }
        }
      }
      if (this.win) this.window(this.win.scr ? 1 : 0, this.win.ox1, this.win.oy1, this.win.ox2, this.win.oy2);
      this.lastX = this.toLogX((this.vx1 + this.vx2 + 1) / 2);
      this.lastY = this.toLogY((this.vy1 + this.vy2 + 1) / 2);
      if (!this.win && !this.viewScreen) { this.lastX = (this.vx2 - this.vx1 + 1) / 2; this.lastY = (this.vy2 - this.vy1 + 1) / 2; }
      this.dirty = true;
    }
    window(scr, x1, y1, x2, y2) {
      this.requireGraphics();
      if (x1 === undefined) { this.win = null; }
      else {
        if (x1 === x2 || y1 === y2) err(5);
        const ox1 = x1, oy1 = y1, ox2 = x2, oy2 = y2;
        if (x1 > x2) [x1, x2] = [x2, x1];
        if (y1 > y2) [y1, y2] = [y2, y1];
        this.win = {
          x1, y1, x2, y2, ox1, oy1, ox2, oy2, scr: !!scr, inv: !scr,
          sx: (this.vx2 - this.vx1) / (x2 - x1), sy: (this.vy2 - this.vy1) / (y2 - y1),
        };
      }
      this.lastX = this.toLogX((this.vx1 + this.vx2 + 1) / 2);
      this.lastY = this.toLogY((this.vy1 + this.vy2 + 1) / 2);
    }
    pmap(c, n) {
      this.requireGraphics();
      switch (n) {
        case 0: return Math.round(this.toPhysX(c) - (this.viewScreen ? 0 : this.vx1));
        case 1: return Math.round(this.toPhysY(c) - (this.viewScreen ? 0 : this.vy1));
        case 2: return this.toLogX(c + (this.viewScreen ? 0 : this.vx1));
        case 3: return this.toLogY(c + (this.viewScreen ? 0 : this.vy1));
      }
      err(5);
    }
    pointFn(n) {
      if (this.m.text) err(5);
      switch (n) {
        case 0: return this.round(this.toPhysX(this.lastX)) - (this.viewScreen ? 0 : this.vx1);
        case 1: return this.round(this.toPhysY(this.lastY)) - (this.viewScreen ? 0 : this.vy1);
        case 2: return this.win ? this.lastX : this.round(this.toPhysX(this.lastX)) - (this.viewScreen ? 0 : this.vx1);
        case 3: return this.win ? this.lastY : this.round(this.toPhysY(this.lastY)) - (this.viewScreen ? 0 : this.vy1);
      }
      err(5);
    }
    point(x, y) {
      this.requireGraphics();
      const px = this.round(this.toPhysX(x)), py = this.round(this.toPhysY(y));
      if (px < this.vx1 || px > this.vx2 || py < this.vy1 || py > this.vy2) return -1;
      return this.pages[this.apage].pix[py * this.W + px];
    }

    // ---- primitives (physical coords) -------------------------------------------------------------------
    plot(x, y, c) {
      if (x < this.vx1 || x > this.vx2 || y < this.vy1 || y > this.vy2) return;
      this.pages[this.apage].pix[y * this.W + x] = c;
    }
    colorArg(color, dflt) {
      const mask = this.m.attrs - 1;
      if (color === undefined) return dflt & mask;
      if (color < 0) err(5);
      return color & mask;
    }

    pset(x, y, color, preset, step) {
      this.requireGraphics();
      if (step) { x += this.lastX; y += this.lastY; }
      this.lastX = x; this.lastY = y;
      const c = this.colorArg(color, preset ? 0 : this.fg);
      this.plot(this.round(this.toPhysX(x)), this.round(this.toPhysY(y)), c);
      this.dirty = true;
    }

    line(spec, x1, y1, x2, y2, color, style) {
      this.requireGraphics();
      if (!spec.has1) { x1 = this.lastX; y1 = this.lastY; }
      else if (spec.step1) { x1 += this.lastX; y1 += this.lastY; }
      if (spec.step2) { x2 += x1; y2 += y1; }
      this.lastX = x2; this.lastY = y2;
      const c = this.colorArg(color, this.fg);
      const px1 = this.round(this.toPhysX(x1)), py1 = this.round(this.toPhysY(y1));
      const px2 = this.round(this.toPhysX(x2)), py2 = this.round(this.toPhysY(y2));
      if (spec.box === 'BF') {
        const xa = Math.max(Math.min(px1, px2), this.vx1), xb = Math.min(Math.max(px1, px2), this.vx2);
        const ya = Math.max(Math.min(py1, py2), this.vy1), yb = Math.min(Math.max(py1, py2), this.vy2);
        const p = this.pages[this.apage].pix;
        for (let y = ya; y <= yb; y++) if (xb >= xa) p.fill(c, y * this.W + xa, y * this.W + xb + 1);
      } else {
        const st = { mask: style === undefined ? 0xFFFF : (style & 0xFFFF), bit: 15 };
        if (spec.box === 'B') {
          this.rawLine(px1, py1, px2, py1, c, st);
          this.rawLine(px2, py1, px2, py2, c, st);
          this.rawLine(px2, py2, px1, py2, c, st);
          this.rawLine(px1, py2, px1, py1, c, st);
        } else this.rawLine(px1, py1, px2, py2, c, st);
      }
      this.dirty = true;
    }
    rawLine(x0, y0, x1, y1, c, st) {
      let dx = Math.abs(x1 - x0), dy = -Math.abs(y1 - y0);
      const sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
      let e = dx + dy;
      const patterned = st && st.mask !== 0xFFFF;
      for (let guard = 0; guard < 100000; guard++) {
        if (patterned) {
          if ((st.mask >> st.bit) & 1) this.plot(x0, y0, c);
          st.bit = (st.bit + 15) % 16;
        } else this.plot(x0, y0, c);
        if (x0 === x1 && y0 === y1) break;
        const e2 = 2 * e;
        if (e2 >= dy) { e += dy; x0 += sx; }
        if (e2 <= dx) { e += dx; y0 += sy; }
      }
    }

    circle(step, x, y, r, color, start, end, aspect) {
      this.requireGraphics();
      if (step) { x += this.lastX; y += this.lastY; }
      this.lastX = x; this.lastY = y;
      const c = this.colorArg(color, this.fg);
      const cx = this.toPhysX(x), cy = this.toPhysY(y);
      if (aspect === undefined) aspect = this.m.aspect;
      // radius is in logical x units; aspect is screen (physical) y/x ratio
      const rr = Math.abs(r) * (this.win ? Math.abs(this.win.sx) : 1);
      let rx, ry;
      if (aspect < 1) { rx = rr; ry = rr * aspect; } else { ry = rr; rx = aspect === 0 ? rr : rr / aspect; }
      const pcx = this.round(cx), pcy = this.round(cy);
      if (start === undefined && end === undefined) {
        this.ellipse(pcx, pcy, Math.round(rx), Math.round(ry), c);
      } else {
        const TWO_PI = Math.PI * 2;
        let a0 = start === undefined ? 0 : start, a1 = end === undefined ? TWO_PI : end;
        const line0 = a0 < 0 || Object.is(a0, -0), line1 = a1 < 0 || Object.is(a1, -0);
        a0 = Math.abs(a0); a1 = Math.abs(a1);
        if (a0 > TWO_PI + 1e-6 || a1 > TWO_PI + 1e-6) err(5);
        if (a1 < a0) a1 += TWO_PI;
        const steps = Math.max(8, Math.ceil((a1 - a0) * Math.max(rx, ry) * 1.5));
        let px = null, py = null;
        for (let i = 0; i <= steps; i++) {
          const a = a0 + ((a1 - a0) * i) / steps;
          const qx = this.round(cx + rx * Math.cos(a)), qy = this.round(cy - ry * Math.sin(a));
          if (px === null) this.plot(qx, qy, c);
          else this.rawLine(px, py, qx, qy, c, null);
          px = qx; py = qy;
        }
        if (line0) this.rawLine(pcx, pcy, this.round(cx + rx * Math.cos(a0)), this.round(cy - ry * Math.sin(a0)), c, null);
        if (line1) this.rawLine(pcx, pcy, this.round(cx + rx * Math.cos(a1)), this.round(cy - ry * Math.sin(a1)), c, null);
      }
      this.dirty = true;
    }
    ellipse(xc, yc, rx, ry, c) {
      if (rx <= 0 && ry <= 0) { this.plot(xc, yc, c); return; }
      if (ry <= 0) { this.rawLine(xc - rx, yc, xc + rx, yc, c, null); return; }
      if (rx <= 0) { this.rawLine(xc, yc - ry, xc, yc + ry, c, null); return; }
      // midpoint ellipse
      let x = 0, y = ry;
      const rx2 = rx * rx, ry2 = ry * ry;
      let px = 0, py = 2 * rx2 * y;
      const pts = (x, y) => { this.plot(xc + x, yc + y, c); this.plot(xc - x, yc + y, c); this.plot(xc + x, yc - y, c); this.plot(xc - x, yc - y, c); };
      let p = ry2 - rx2 * ry + 0.25 * rx2;
      while (px < py) {
        pts(x, y);
        x++; px += 2 * ry2;
        if (p < 0) p += ry2 + px;
        else { y--; py -= 2 * rx2; p += ry2 + px - py; }
      }
      p = ry2 * (x + 0.5) * (x + 0.5) + rx2 * (y - 1) * (y - 1) - rx2 * ry2;
      while (y >= 0) {
        pts(x, y);
        y--; py -= 2 * rx2;
        if (p > 0) p += rx2 - py;
        else { x++; px += 2 * ry2; p += rx2 - py + px; }
      }
    }

    /** Pixel value of a tile pattern at (x,y) */
    tileColor(tile, x, y) {
      const m = this.m;
      if (m.planes) {
        const rowsN = Math.max(1, Math.floor(tile.length / m.planes));
        const r = y % rowsN;
        let c = 0;
        for (let pl = 0; pl < m.planes; pl++) {
          const byte = tile.charCodeAt(r * m.planes + pl) & 255;
          c |= ((byte >> (7 - (x & 7))) & 1) << pl;
        }
        return c;
      }
      const bpp = m.bpp || 1;
      const r = y % tile.length;
      const byte = tile.charCodeAt(r) & 255;
      if (bpp === 8) return byte;
      const ppb = 8 / bpp;
      const shift = (ppb - 1 - (x % ppb)) * bpp;
      return (byte >> shift) & ((1 << bpp) - 1);
    }

    paint(step, x, y, paint, border, bg, tileMode) {
      this.requireGraphics();
      if (step) { x += this.lastX; y += this.lastY; }
      this.lastX = x; this.lastY = y;
      const px = this.round(this.toPhysX(x)), py = this.round(this.toPhysY(y));
      if (px < this.vx1 || px > this.vx2 || py < this.vy1 || py > this.vy2) return;
      let fillC = 0, tile = null;
      if (tileMode) { tile = paint; if (!tile.length || tile.length > 64 * (this.m.planes || 1)) err(5); }
      else fillC = this.colorArg(paint, this.fg);
      const bord = border === undefined ? (tile ? this.fg & (this.m.attrs - 1) : fillC) : this.colorArg(border, 0);
      const W = this.W;
      const pix = this.pages[this.apage].pix;
      if (pix[py * W + px] === bord) return;
      const visited = new Uint8Array(W * this.H);
      const colorAt = (xx, yy) => (tile ? this.tileColor(tile, xx, yy) : fillC);
      const stack = [[px, py]];
      const x1 = this.vx1, x2 = this.vx2, y1 = this.vy1, y2 = this.vy2;
      let guard = 0;
      while (stack.length && guard++ < 4000000) {
        let [sx, sy] = stack.pop();
        let i = sy * W + sx;
        if (visited[i] || pix[i] === bord) continue;
        // move left
        let lx = sx;
        while (lx > x1 && !visited[sy * W + lx - 1] && pix[sy * W + lx - 1] !== bord) lx--;
        let rx = sx;
        while (rx < x2 && !visited[sy * W + rx + 1] && pix[sy * W + rx + 1] !== bord) rx++;
        for (let xx = lx; xx <= rx; xx++) {
          const j = sy * W + xx;
          visited[j] = 1;
          pix[j] = colorAt(xx, sy);
        }
        for (const ny of [sy - 1, sy + 1]) {
          if (ny < y1 || ny > y2) continue;
          let inSpan = false;
          for (let xx = lx; xx <= rx; xx++) {
            const j = ny * W + xx;
            const ok = !visited[j] && pix[j] !== bord;
            if (ok && !inSpan) { stack.push([xx, ny]); inSpan = true; }
            else if (!ok) inSpan = false;
          }
        }
      }
      void bg;
      this.dirty = true;
    }

    // ---- DRAW macro language ------------------------------------------------------------------------------
    draw(s, vm) {
      this.requireGraphics();
      let i = 0;
      const n = s.length;
      const self = this;
      const skipWs = () => { while (i < n && (s[i] === ' ' || s[i] === ';')) i++; };
      const readNum = (allowSign) => {
        skipWs();
        if (s[i] === '=') {
          i++;
          const ptr = s.slice(i, i + 3); i += 3;
          if (s[i] === ';') i++;
          return RC.Basic.varFromPtr(vm, ptr);
        }
        let j = i;
        if (allowSign && (s[j] === '+' || s[j] === '-')) j++;
        while (j < n && s[j] >= '0' && s[j] <= '9') j++;
        if (j === i || (j === i + 1 && (s[i] === '+' || s[i] === '-'))) return null;
        const v = parseInt(s.slice(i, j), 10);
        i = j;
        return v;
      };
      let px = this.toPhysX(this.lastX), py = this.toPhysY(this.lastY);
      let color = this.fg & (this.m.attrs - 1);
      if (this.drawColor !== undefined) color = this.drawColor;
      const moveRel = (dx, dy, noDraw, ret) => {
        // apply rotation (A / TA) and scale
        const sc = this.drawScale / 4;
        dx *= sc; dy *= sc;
        let ang = (this.drawTA || 0) + this.drawAngle * 90;
        if (ang) {
          const rad = (ang * Math.PI) / 180;
          const cos = Math.cos(rad), sin = Math.sin(rad);
          const ndx = dx * cos + dy * sin;
          const ndy = -dx * sin + dy * cos;
          dx = ndx; dy = ndy;
        }
        const nx = px + dx, ny = py + dy;
        if (!noDraw) this.rawLine(this.round(px), this.round(py), this.round(nx), this.round(ny), color, null);
        if (!ret) { px = nx; py = ny; }
      };
      let guard = 0;
      while (i < n && guard++ < 100000) {
        skipWs();
        if (i >= n) break;
        let c = s[i++].toUpperCase();
        let noDraw = false, ret = false;
        while (c === 'B' || c === 'N') {
          if (c === 'B') noDraw = true; else ret = true;
          skipWs();
          c = (s[i++] || '').toUpperCase();
        }
        switch (c) {
          case 'U': case 'D': case 'L': case 'R': case 'E': case 'F': case 'G': case 'H': {
            let d = readNum(false);
            if (d === null) d = 1;
            const v = { U: [0, -1], D: [0, 1], L: [-1, 0], R: [1, 0], E: [1, -1], F: [1, 1], G: [-1, 1], H: [-1, -1] }[c];
            moveRel(v[0] * d, v[1] * d, noDraw, ret);
            break;
          }
          case 'M': {
            skipWs();
            const rel = s[i] === '+' || s[i] === '-';
            const mx = readNum(true);
            skipWs();
            if (s[i] !== ',') err(5);
            i++;
            const my = readNum(true);
            if (mx === null || my === null) err(5);
            if (rel) moveRel(mx, my, noDraw, ret);
            else {
              const nx = this.toPhysX(mx), ny = this.toPhysY(my);
              if (!noDraw) this.rawLine(this.round(px), this.round(py), this.round(nx), this.round(ny), color, null);
              if (!ret) { px = nx; py = ny; }
            }
            break;
          }
          case 'A': { const a = readNum(false); if (a === null || a < 0 || a > 3) err(5); this.drawAngle = a; this.drawTA = 0; break; }
          case 'T': {
            skipWs();
            if ((s[i] || '').toUpperCase() !== 'A') err(5);
            i++;
            const a = readNum(true);
            if (a === null || a < -360 || a > 360) err(5);
            this.drawTA = a; this.drawAngle = 0;
            break;
          }
          case 'C': { const v = readNum(false); if (v === null) err(5); color = v & (this.m.attrs - 1); this.drawColor = color; break; }
          case 'S': { const v = readNum(false); if (v === null || v < 1 || v > 255) err(5); this.drawScale = v; break; }
          case 'P': {
            const pc = readNum(false);
            skipWs();
            if (s[i] !== ',') err(5);
            i++;
            const bc = readNum(false);
            if (pc === null || bc === null) err(5);
            const sx = this.lastX, sy = this.lastY;
            this.lastX = this.toLogX(px); this.lastY = this.toLogY(py);
            this.paint(false, this.lastX, this.lastY, pc, bc, undefined, false);
            this.lastX = sx; this.lastY = sy;
            break;
          }
          case 'X': {
            const ptr = s.slice(i, i + 3); i += 3;
            if (s[i] === ';') i++;
            const sub = RC.Basic.varFromPtr(vm, ptr);
            if (typeof sub !== 'string') err(5);
            this.lastX = this.toLogX(px); this.lastY = this.toLogY(py);
            this.drawColor = color;
            this.draw(sub, vm);
            px = this.toPhysX(this.lastX); py = this.toPhysY(this.lastY);
            color = this.drawColor;
            break;
          }
          default: err(5);
        }
      }
      void self;
      this.lastX = this.toLogX(px); this.lastY = this.toLogY(py);
      this.dirty = true;
    }

    // ---- GET / PUT -----------------------------------------------------------------------------------
    gpLayout(w, h) {
      const m = this.m;
      if (m.planes) {
        const rowBytes = Math.ceil(w / 8);
        return { header: w, rowBytes, planes: m.planes, size: 4 + rowBytes * m.planes * h };
      }
      const bpp = m.bpp;
      const rowBytes = Math.ceil((w * bpp) / 8);
      return { header: w * bpp, rowBytes, planes: 0, bpp, size: 4 + rowBytes * h };
    }
    get(spec, x1, y1, x2, y2, bytes) {
      this.requireGraphics();
      if (spec.step1) { x1 += this.lastX; y1 += this.lastY; }
      if (spec.step2) { x2 += x1; y2 += y1; }
      let px1 = this.round(this.toPhysX(x1)), py1 = this.round(this.toPhysY(y1));
      let px2 = this.round(this.toPhysX(x2)), py2 = this.round(this.toPhysY(y2));
      if (px1 > px2) [px1, px2] = [px2, px1];
      if (py1 > py2) [py1, py2] = [py2, py1];
      if (px1 < this.vx1 || py1 < this.vy1 || px2 > this.vx2 || py2 > this.vy2) err(5);
      const w = px2 - px1 + 1, h = py2 - py1 + 1;
      const L = this.gpLayout(w, h);
      if (bytes.length < L.size) err(5);
      const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
      dv.setInt16(0, L.header, true);
      dv.setInt16(2, h, true);
      const pix = this.pages[this.apage].pix;
      let o = 4;
      for (let y = 0; y < h; y++) {
        const row = (py1 + y) * this.W + px1;
        if (L.planes) {
          for (let pl = 0; pl < L.planes; pl++) {
            for (let b = 0; b < L.rowBytes; b++) {
              let v = 0;
              for (let k = 0; k < 8; k++) {
                const x = b * 8 + k;
                if (x < w) v |= ((pix[row + x] >> pl) & 1) << (7 - k);
              }
              bytes[o++] = v;
            }
          }
        } else if (L.bpp === 8) {
          for (let x = 0; x < w; x++) bytes[o++] = pix[row + x];
        } else {
          const ppb = 8 / L.bpp;
          for (let b = 0; b < L.rowBytes; b++) {
            let v = 0;
            for (let k = 0; k < ppb; k++) {
              const x = b * ppb + k;
              if (x < w) v |= (pix[row + x] & ((1 << L.bpp) - 1)) << ((ppb - 1 - k) * L.bpp);
            }
            bytes[o++] = v;
          }
        }
      }
      this.dirty = true;
    }
    put(spec, x, y, bytes, action) {
      this.requireGraphics();
      action = spec.action || action || 'XOR';
      if (spec.step) { x += this.lastX; y += this.lastY; }
      const px = this.round(this.toPhysX(x)), py = this.round(this.toPhysY(y));
      const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
      if (bytes.length < 4) err(5);
      const header = dv.getInt16(0, true), h = dv.getInt16(2, true);
      const m = this.m;
      const w = m.planes ? header : Math.floor(header / m.bpp);
      if (w <= 0 || h <= 0) err(5);
      const L = this.gpLayout(w, h);
      if (bytes.length < L.size) err(5);
      if (px < this.vx1 || py < this.vy1 || px + w - 1 > this.vx2 || py + h - 1 > this.vy2) err(5);
      const pix = this.pages[this.apage].pix;
      const mask = m.attrs - 1;
      const apply = (i, c) => {
        switch (action) {
          case 'PSET': pix[i] = c; break;
          case 'PRESET': pix[i] = (~c) & mask; break;
          case 'AND': pix[i] &= c; break;
          case 'OR': pix[i] |= c; break;
          default: pix[i] ^= c;
        }
      };
      let o = 4;
      for (let yy = 0; yy < h; yy++) {
        const row = (py + yy) * this.W + px;
        if (L.planes) {
          const base = o;
          for (let xx = 0; xx < w; xx++) {
            let c = 0;
            for (let pl = 0; pl < L.planes; pl++) c |= ((bytes[base + pl * L.rowBytes + (xx >> 3)] >> (7 - (xx & 7))) & 1) << pl;
            apply(row + xx, c);
          }
          o += L.rowBytes * L.planes;
        } else if (L.bpp === 8) {
          for (let xx = 0; xx < w; xx++) apply(row + xx, bytes[o + xx]);
          o += w;
        } else {
          const ppb = 8 / L.bpp;
          for (let xx = 0; xx < w; xx++) {
            const b = bytes[o + Math.floor(xx / ppb)];
            const c = (b >> ((ppb - 1 - (xx % ppb)) * L.bpp)) & ((1 << L.bpp) - 1);
            apply(row + xx, c);
          }
          o += L.rowBytes;
        }
      }
      this.lastX = x; this.lastY = y;
      this.dirty = true;
    }

    pcopy(a, b) {
      const np = this.pages.length;
      if (a < 0 || a >= np || b < 0 || b >= np) err(5);
      const s = this.pages[a], d = this.pages[b];
      d.chars.set(s.chars); d.attrs.set(s.attrs);
      if (s.pix) d.pix.set(s.pix);
      this.dirty = true;
    }

    // ---- video memory (PEEK/POKE) ---------------------------------------------------------------------
    /** Linear address within segment B800/A000/B000 -> byte; returns undefined if not video */
    videoPeek(addr) {
      const m = this.m;
      if (this.mode === 0 && addr >= 0xB8000 && addr < 0xC0000) {
        const pageSize = this.cols === 40 ? 2048 : 4096;
        const off = addr - 0xB8000;
        const page = Math.floor(off / pageSize), po = off % pageSize;
        if (page >= this.pages.length) return 0;
        const cell = po >> 1;
        if (cell >= this.cols * this.rows) return 0;
        return po & 1 ? this.pages[page].attrs[cell] : this.pages[page].chars[cell];
      }
      if (this.mode === 13 && addr >= 0xA0000 && addr < 0xA0000 + 64000) return this.pages[0].pix[addr - 0xA0000];
      if ((this.mode === 1 || this.mode === 2) && addr >= 0xB8000 && addr < 0xBC000) {
        const off = addr - 0xB8000;
        const bank = off >= 0x2000 ? 1 : 0;
        const bo = off & 0x1FFF;
        const y = (Math.floor(bo / 80)) * 2 + bank;
        if (y >= 200) return 0;
        const bx = bo % 80;
        const bpp = m.bpp, ppb = 8 / bpp;
        let v = 0;
        for (let k = 0; k < ppb; k++) v |= (this.pages[0].pix[y * this.W + bx * ppb + k] & ((1 << bpp) - 1)) << ((ppb - 1 - k) * bpp);
        return v;
      }
      return undefined;
    }
    videoPoke(addr, v) {
      const m = this.m;
      if (this.mode === 0 && addr >= 0xB8000 && addr < 0xC0000) {
        const pageSize = this.cols === 40 ? 2048 : 4096;
        const off = addr - 0xB8000;
        const page = Math.floor(off / pageSize), po = off % pageSize;
        if (page >= this.pages.length) return true;
        const cell = po >> 1;
        if (cell >= this.cols * this.rows) return true;
        if (po & 1) this.pages[page].attrs[cell] = v; else this.pages[page].chars[cell] = v;
        this.dirty = true;
        return true;
      }
      if (this.mode === 13 && addr >= 0xA0000 && addr < 0xA0000 + 64000) { this.pages[0].pix[addr - 0xA0000] = v; this.dirty = true; return true; }
      if ((this.mode === 1 || this.mode === 2) && addr >= 0xB8000 && addr < 0xBC000) {
        const off = addr - 0xB8000;
        const bank = off >= 0x2000 ? 1 : 0;
        const bo = off & 0x1FFF;
        const y = (Math.floor(bo / 80)) * 2 + bank;
        if (y >= 200) return true;
        const bx = bo % 80;
        const bpp = m.bpp, ppb = 8 / bpp;
        for (let k = 0; k < ppb; k++) this.pages[0].pix[y * this.W + bx * ppb + k] = (v >> ((ppb - 1 - k) * bpp)) & ((1 << bpp) - 1);
        this.dirty = true;
        return true;
      }
      return false;
    }

    // VGA DAC ports
    dacOut(port, v) {
      if (port === 0x3C8) { this.dacWriteIdx = v & 255; this.dacComp = 0; return; }
      if (port === 0x3C7) { this.dacReadIdx = v & 255; this.dacComp = 0; return; }
      if (port === 0x3C9) {
        const e = this.dac[this.dacWriteIdx];
        e[this.dacComp] = v & 63;
        this.dacComp++;
        if (this.dacComp === 3) { this.dacComp = 0; this.dacWriteIdx = (this.dacWriteIdx + 1) & 255; }
        if (this.m.space === 'dac') this.updateRgb();
      }
    }
    dacIn(port) {
      if (port === 0x3C9) {
        const v = this.dac[this.dacReadIdx][this.dacComp];
        this.dacComp++;
        if (this.dacComp === 3) { this.dacComp = 0; this.dacReadIdx = (this.dacReadIdx + 1) & 255; }
        return v;
      }
      return 0;
    }

    // ---- rendering ----------------------------------------------------------------------------------------
    /** Returns the visible text as an array of strings (for tests / accessibility). */
    textLines(page) {
      const p = this.pages[page === undefined ? this.vpage : page];
      const out = [];
      for (let r = 0; r < this.rows; r++) {
        let s = '';
        for (let c = 0; c < this.cols; c++) s += String.fromCharCode(p.chars[r * this.cols + c]);
        out.push(s);
      }
      return out;
    }

    render(nowMs) {
      if (!this.ctx) return;
      const blink = Math.floor((nowMs || 0) / 267) % 2 === 0; // ~1.9 Hz cursor/text blink
      const showCursor = (this.cursorVisible || this.inputCursor) && this.vpage === this.apage;
      if (!this.dirty && blink === this.blinkPhase && !(showCursor || this.hasBlinkText)) return;
      this.blinkPhase = blink;
      this.dirty = false;
      const img = this.image32;
      const W = this.W;
      const p = this.pages[this.vpage];
      if (this.m.text) {
        const font = this.font, fh = this.m.ch;
        const fontH = font.length / 256;
        const rgb = this.rgb;
        let hasBlink = false;
        for (let r = 0; r < this.rows; r++) {
          for (let c = 0; c < this.cols; c++) {
            const i = r * this.cols + c;
            const ch = p.chars[i], at = p.attrs[i];
            let fg = rgb[at & 15], bg = rgb[(at >> 4) & 7];
            if (at & 0x80) { hasBlink = true; if (!blink) fg = bg; }
            const x0 = c * 8, y0 = r * fh;
            for (let y = 0; y < fh; y++) {
              const bits = font[ch * fontH + (y < fontH ? y : fontH - 1)];
              let o = (y0 + y) * W + x0;
              for (let x = 0; x < 8; x++) img[o++] = (bits >> (7 - x)) & 1 ? fg : bg;
            }
          }
        }
        this.hasBlinkText = hasBlink;
        if (showCursor && blink) {
          const r = this.row, c = Math.min(this.col, this.cols - 1);
          const at = p.attrs[r * this.cols + c];
          const col = rgb[at & 15];
          const startL = this.inputCursor ? fh - 2 : fh - 2;
          for (let y = startL; y < fh; y++) {
            let o = (r * fh + y) * W + c * 8;
            for (let x = 0; x < 8; x++) img[o++] = col;
          }
        }
      } else {
        const pix = p.pix, rgb = this.rgb;
        const n = pix.length;
        for (let i = 0; i < n; i++) img[i] = rgb[pix[i]];
        if (showCursor && blink) {
          const fh = this.m.ch, cw = this.m.cw;
          const r = this.row, c = Math.min(this.col, this.cols - 1);
          const col = rgb[this.fg & (this.m.attrs - 1)] ;
          for (let y = fh - 2; y < fh; y++) {
            let o = (r * fh + y) * W + c * cw;
            if (r * fh + y >= this.H) break;
            for (let x = 0; x < cw; x++) img[o++] = col;
          }
        }
      }
      this.ctx.putImageData(this.image, 0, 0);
    }

    /** Copy of current visible frame as RGBA pixels (for screenshots / tests) */
    snapshotRGB() {
      const saved = this.ctx;
      if (!this.image32) {
        this.image32 = new Uint32Array(this.W * this.H);
      }
      return { w: this.W, h: this.H, saved };
    }

    get borderRgb() {
      if (this.mode !== 0) return '#000';
      const c = CGA16[this.border & 15];
      return '#' + c.toString(16).padStart(6, '0');
    }
  }

  RC.Display = Display;
  RC.CGA16 = CGA16;
  RC.ega64 = ega64;
})(RC);
