// Project sharing: pack a folder into a compressed, URL-safe string (and back).
(function (RC) {
  'use strict';
  const Share = RC.Share = {};
  const PREFIX = 'CPD1.';

  const b64url = (bytes) => {
    let s = '';
    for (let i = 0; i < bytes.length; i += 8192) s += String.fromCharCode.apply(null, bytes.subarray(i, i + 8192));
    return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  };
  const unb64url = (str) => {
    const s = atob(str.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((str.length + 3) % 4));
    const out = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i);
    return out;
  };
  async function pipe(bytes, stream) {
    const res = new Response(new Blob([bytes]).stream().pipeThrough(stream));
    return new Uint8Array(await res.arrayBuffer());
  }
  const canCompress = typeof CompressionStream !== 'undefined';

  /** files: {relPath: Uint8Array}; meta: {name, main, lang} */
  Share.pack = async function (meta, files) {
    const enc = {};
    for (const [k, v] of Object.entries(files)) enc[k] = b64url(v);
    const json = JSON.stringify({ v: 1, meta, files: enc });
    const raw = new TextEncoder().encode(json);
    if (canCompress) return PREFIX + 'z' + b64url(await pipe(raw, new CompressionStream('deflate-raw')));
    return PREFIX + 'r' + b64url(raw);
  };
  Share.unpack = async function (str) {
    str = String(str).trim();
    const m = /(?:#share=|^)(CPD1\.[zr][A-Za-z0-9_-]+)/.exec(str);
    if (!m) throw new Error('This does not look like a Baysik share code.');
    const body = m[1].slice(PREFIX.length);
    let raw = unb64url(body.slice(1));
    if (body[0] === 'z') {
      if (!canCompress) throw new Error('This browser cannot decompress share codes.');
      raw = await pipe(raw, new DecompressionStream('deflate-raw'));
    }
    const obj = JSON.parse(new TextDecoder().decode(raw));
    if (!obj || obj.v !== 1 || !obj.files) throw new Error('Unsupported share code version.');
    const files = {};
    for (const [k, v] of Object.entries(obj.files)) {
      if (/(^|[\\/])\.\.([\\/]|$)/.test(k) || /^[A-Za-z]:/.test(k) || k.startsWith('\\')) throw new Error('Unsafe path in share code: ' + k);
      files[k] = unb64url(v);
    }
    return { meta: obj.meta || {}, files };
  };
})(RC);
