// PC speaker emulation: SOUND, BEEP, PLAY (Music Macro Language), port 61h/42h speaker.
// Timeline is kept in performance.now() milliseconds so it also works headless (no output).
(function (RC) {
  'use strict';
  const now = () => (typeof performance !== 'undefined' ? performance.now() : Date.now());
  const TICK_MS = 1000 / 18.2065;

  class Audio {
    constructor() {
      this.ctx = null;
      this.enabled = true;
      this.volume = 0.08;
      this.notes = []; // {start, end, freq}
      this.endTime = 0;
      this.background = false; // MB / MF
      this.octave = 4; this.length = 4; this.tempo = 120; this.style = 7 / 8;
      this.nodes = [];
      this.speakerOsc = null;
    }
    ensureCtx() {
      if (this.ctx || !this.enabled) return this.ctx;
      const AC = typeof window !== 'undefined' && (window.AudioContext || window.webkitAudioContext);
      if (!AC) return null;
      try {
        this.ctx = new AC();
        this.gain = this.ctx.createGain();
        this.gain.gain.value = this.volume;
        this.gain.connect(this.ctx.destination);
      } catch (e) { this.ctx = null; }
      return this.ctx;
    }
    resume() { const c = this.ensureCtx(); if (c && c.state === 'suspended') c.resume(); }
    setVolume(v) { this.volume = v; if (this.gain) this.gain.gain.value = v; }

    /** Schedule a tone; returns its start time (ms) */
    tone(freq, durMs, gapMs) {
      const t = now();
      const start = Math.max(t, this.endTime);
      const end = start + durMs;
      this.endTime = end + (gapMs || 0);
      this.notes.push({ start, end: this.endTime, freq });
      if (freq > 0 && freq < 20000) this.schedule(freq, start, end);
      return start;
    }
    schedule(freq, startMs, endMs) {
      const ctx = this.ensureCtx();
      if (!ctx) return;
      const base = ctx.currentTime - now() / 1000;
      const s = Math.max(ctx.currentTime, base + startMs / 1000), e = base + endMs / 1000;
      if (e <= s) return;
      const o = ctx.createOscillator();
      o.type = 'square';
      o.frequency.value = freq;
      const g = ctx.createGain();
      g.gain.setValueAtTime(0, s);
      g.gain.linearRampToValueAtTime(1, s + 0.002);
      g.gain.setValueAtTime(1, Math.max(s + 0.002, e - 0.003));
      g.gain.linearRampToValueAtTime(0, e);
      o.connect(g); g.connect(this.gain);
      o.start(s); o.stop(e + 0.01);
      this.nodes.push(o);
      o.onended = () => { const i = this.nodes.indexOf(o); if (i >= 0) this.nodes.splice(i, 1); };
    }
    prune() {
      const t = now();
      while (this.notes.length && this.notes[0].end <= t) this.notes.shift();
    }
    notesQueued() { this.prune(); return this.notes.length; }

    beep() { this.tone(800, 250, 0); }

    /** SOUND freq, duration (clock ticks) */
    sound(freq, ticks) {
      if (ticks === 0) { this.stopAll(); return; }
      this.lastWaitMode = 'sound';
      this.tone(freq >= 32767 ? 0 : freq, ticks * TICK_MS, 0);
    }

    /** Timestamp the program must wait until (0 = continue immediately) */
    waitUntilForeground() {
      this.prune();
      if (this.lastWaitMode === 'sound') {
        // Next SOUND waits for the previous one: allow one note queued ahead
        if (this.notes.length > 1) return this.notes[this.notes.length - 2].end;
        return 0;
      }
      if (!this.background) return this.endTime > now() ? this.endTime : 0;
      if (this.notes.length > 32) return this.notes[this.notes.length - 33].end;
      return 0;
    }

    stopAll() {
      for (const o of this.nodes) { try { o.stop(); } catch (e) { /* ignore */ } }
      this.nodes = [];
      this.notes = [];
      this.endTime = 0;
      this.speaker(0);
    }

    /** Direct PC speaker (port 61h + PIT channel 2) */
    speaker(freq) {
      const ctx = freq ? this.ensureCtx() : this.ctx;
      if (!ctx) return;
      if (!freq) {
        if (this.speakerOsc) { try { this.speakerOsc.stop(); } catch (e) { /* ignore */ } this.speakerOsc = null; }
        return;
      }
      if (!this.speakerOsc) {
        const o = ctx.createOscillator();
        o.type = 'square';
        o.connect(this.gain);
        o.start();
        this.speakerOsc = o;
      }
      this.speakerOsc.frequency.value = freq;
    }

    /** PLAY music macro language */
    play(s, vm) {
      this.lastWaitMode = 'play';
      const B = RC.Basic;
      let i = 0;
      const n = s.length;
      const err = () => B.err(5);
      const num = () => {
        while (s[i] === ' ') i++;
        if (s[i] === '=') {
          i++;
          const ptr = s.slice(i, i + 3); i += 3;
          if (s[i] === ';') i++;
          return Math.round(B.varFromPtr(vm, ptr));
        }
        let j = i;
        while (j < n && s[j] >= '0' && s[j] <= '9') j++;
        if (j === i) return null;
        const v = parseInt(s.slice(i, j), 10);
        i = j;
        return v;
      };
      const dots = () => { let f = 1, add = 0.5; while (s[i] === '.') { f += add; add /= 2; i++; } return f; };
      const noteMs = (len) => (60000 / this.tempo) * (4 / len);
      const playNote = (semis, len, dotf) => {
        const total = noteMs(len) * dotf;
        if (semis === null) { this.tone(0, total, 0); return; }
        // Octave 3 starts at middle C (GW-BASIC/QBasic manuals), so O3 A = 440 Hz
        const freq = 440 * Math.pow(2, (semis - 45) / 12);
        const on = total * this.style;
        this.tone(freq, on, total - on);
      };
      const NOTE = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
      let guard = 0;
      while (i < n && guard++ < 100000) {
        const c = s[i++].toUpperCase();
        if (c === ' ' || c === ';') continue;
        if (NOTE[c] !== undefined) {
          let semi = NOTE[c];
          if (s[i] === '#' || s[i] === '+') { semi++; i++; } else if (s[i] === '-') { semi--; i++; }
          let len = num();
          if (len === null) len = this.length;
          if (len < 1 || len > 64) err();
          const d = dots();
          playNote(this.octave * 12 + semi, len, d);
          continue;
        }
        switch (c) {
          case 'O': { const v = num(); if (v === null || v < 0 || v > 6) err(); this.octave = v; break; }
          case '<': if (this.octave > 0) this.octave--; break;
          case '>': if (this.octave < 6) this.octave++; break;
          case 'L': { const v = num(); if (v === null || v < 1 || v > 64) err(); this.length = v; break; }
          case 'T': { const v = num(); if (v === null || v < 32 || v > 255) err(); this.tempo = v; break; }
          case 'P': { const v = num(); if (v === null || v < 1 || v > 64) err(); const d = dots(); playNote(null, v, d); break; }
          case 'N': {
            const v = num();
            if (v === null || v < 0 || v > 84) err();
            const d = dots();
            if (v === 0) playNote(null, this.length, d); else playNote(v - 1, this.length, d);
            break;
          }
          case 'M': {
            const m = (s[i++] || '').toUpperCase();
            if (m === 'N') this.style = 7 / 8;
            else if (m === 'L') this.style = 1;
            else if (m === 'S') this.style = 3 / 4;
            else if (m === 'F') this.background = false;
            else if (m === 'B') this.background = true;
            else err();
            break;
          }
          case 'X': {
            const ptr = s.slice(i, i + 3); i += 3;
            if (s[i] === ';') i++;
            const sub = B.varFromPtr(vm, ptr);
            if (typeof sub !== 'string') err();
            this.play(sub, vm);
            this.lastWaitMode = 'play';
            break;
          }
          default: err();
        }
      }
    }
  }
  RC.Audio = Audio;
})(RC);
