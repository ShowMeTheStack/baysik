// Run a BASIC program headlessly and save the final screen as PNG.
// usage: node tools/snap.mjs prog.bas out.png [inputText]
import { readFileSync, writeFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';
import { loadRC, runBasic } from '../tests/harness.mjs';

export function screenRGBA(RC, d) {
  // Reproduce Display.render without a canvas
  const W = d.W, H = d.H;
  const out = new Uint8Array(W * H * 4);
  const p = d.pages[d.vpage];
  const put = (i, abgr) => { out[i * 4] = abgr & 255; out[i * 4 + 1] = (abgr >> 8) & 255; out[i * 4 + 2] = (abgr >> 16) & 255; out[i * 4 + 3] = 255; };
  if (d.m.text) {
    const fh = d.m.ch, font = d.font, fontH = font.length / 256;
    for (let r = 0; r < d.rows; r++) for (let c = 0; c < d.cols; c++) {
      const i = r * d.cols + c, ch = p.chars[i], at = p.attrs[i];
      for (let y = 0; y < fh; y++) {
        const bits = font[ch * fontH + Math.min(y, fontH - 1)];
        for (let x = 0; x < 8; x++) put((r * fh + y) * W + c * 8 + x, (bits >> (7 - x)) & 1 ? d.rgb[at & 15] : d.rgb[(at >> 4) & 7]);
      }
    }
  } else for (let i = 0; i < W * H; i++) put(i, d.rgb[p.pix[i]]);
  return { W, H, out };
}
function crc32(buf) {
  let c, crc = 0xffffffff;
  for (let n = 0; n < buf.length; n++) {
    c = (crc ^ buf[n]) & 0xff;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    crc = (crc >>> 8) ^ c;
  }
  return (crc ^ 0xffffffff) >>> 0;
}
export function png(W, H, rgba, scaleY = 1) {
  const rows = [];
  for (let y = 0; y < H; y++) {
    const row = Buffer.alloc(1 + W * 4);
    row[0] = 0;
    Buffer.from(rgba.buffer, rgba.byteOffset + y * W * 4, W * 4).copy(row, 1);
    for (let k = 0; k < scaleY; k++) rows.push(row);
  }
  const raw = Buffer.concat(rows);
  const chunk = (type, data) => {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
    return Buffer.concat([len, td, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H * scaleY, 4); ihdr[8] = 8; ihdr[9] = 6;
  return Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
if (process.argv[1].endsWith('snap.mjs')) {
  const RC = loadRC();
  const r = runBasic(RC, readFileSync(process.argv[2], 'utf8'), { input: process.argv[4] || '', timeLimit: 3000 });
  if (r.compileError) { console.log('COMPILE', r.compileError.message, r.compileError.pos); process.exit(1); }
  if (r.error) console.log('RUNTIME', r.error);
  const { W, H, out } = screenRGBA(RC, r.display);
  const sy = H <= 200 ? 2 : 1;
  writeFileSync(process.argv[3], png(W, H, out, sy));
  console.log('saved', W, 'x', H * sy, 'state', r.state);
}
