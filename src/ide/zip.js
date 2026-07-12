// Minimal ZIP writer (stored, no compression) for project downloads.
(function (RC) {
  'use strict';
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; table[n] = c >>> 0; }
  function crc32(b) { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = table[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
  RC.Zip = {
    /** files: {path: Uint8Array} -> Uint8Array zip */
    create(files) {
      const enc = new TextEncoder();
      const parts = [], central = [];
      let off = 0;
      const d = new Date();
      const dosTime = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1);
      const dosDate = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
      for (const [name, data] of Object.entries(files)) {
        const nb = enc.encode(name);
        const crc = crc32(data);
        const lh = new DataView(new ArrayBuffer(30));
        lh.setUint32(0, 0x04034b50, true); lh.setUint16(4, 20, true); lh.setUint16(6, 0x0800, true); lh.setUint16(8, 0, true);
        lh.setUint16(10, dosTime, true); lh.setUint16(12, dosDate, true); lh.setUint32(14, crc, true);
        lh.setUint32(18, data.length, true); lh.setUint32(22, data.length, true); lh.setUint16(26, nb.length, true); lh.setUint16(28, 0, true);
        parts.push(new Uint8Array(lh.buffer), nb, data);
        const ch = new DataView(new ArrayBuffer(46));
        ch.setUint32(0, 0x02014b50, true); ch.setUint16(4, 20, true); ch.setUint16(6, 20, true); ch.setUint16(8, 0x0800, true); ch.setUint16(10, 0, true);
        ch.setUint16(12, dosTime, true); ch.setUint16(14, dosDate, true); ch.setUint32(16, crc, true);
        ch.setUint32(20, data.length, true); ch.setUint32(24, data.length, true); ch.setUint16(28, nb.length, true);
        ch.setUint32(42, off, true);
        central.push(new Uint8Array(ch.buffer), nb);
        off += 30 + nb.length + data.length;
      }
      const cdSize = central.reduce((n, p) => n + p.length, 0);
      const end = new DataView(new ArrayBuffer(22));
      const count = Object.keys(files).length;
      end.setUint32(0, 0x06054b50, true); end.setUint16(8, count, true); end.setUint16(10, count, true);
      end.setUint32(12, cdSize, true); end.setUint32(16, off, true);
      const all = [...parts, ...central, new Uint8Array(end.buffer)];
      const out = new Uint8Array(all.reduce((n, p) => n + p.length, 0));
      let p = 0;
      for (const a of all) { out.set(a, p); p += a.length; }
      return out;
    },
    crc32,
  };
})(RC);
