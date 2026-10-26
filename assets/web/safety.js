// Verto "word safety net".
//
// The translation engine can silently skip a word. This module cannot make that
// impossible, but it reduces it and tells the user when it may have happened:
//   1. Text is translated sentence by sentence (long sentences clause by clause),
//      so the engine never has to digest a huge block at once.
//   2. After the translation is shown, every meaningful source word is translated
//      on its own and looked for in the result. Words that cannot be found are
//      reported, and the sentence is retried in smaller pieces.
//
// Pure logic only: the engine is injected as `rawTranslate(from, to, text)`.

const STOP_EN = new Set([
  'this', 'that', 'these', 'those', 'with', 'from', 'were', 'been', 'they', 'them',
  'your', 'their', 'does', 'will', 'would', 'should', 'could', 'have', 'then', 'than',
  'what', 'when', 'where', 'which', 'while', 'there', 'here', 'into', 'onto', 'also',
  'very', 'just', 'some', 'such', 'only', 'about', 'because', 'being', 'each', 'both',
  'the', 'and', 'for', 'are', 'was', 'not', 'but', 'you', 'all', 'can', 'her', 'his',
  'our', 'out', 'has', 'had', 'its', 'who', 'how', 'any', 'may', 'too', 'per', 'via',
]);

// Languages written without spaces between words.
const NO_SPACE = new Set(['ja', 'zh', 'th']);
const baseLang = (lang) => String(lang).split('-')[0];
const isNoSpace = (lang) => NO_SPACE.has(baseLang(lang));

export const joinerFor = (lang) => (isNoSpace(lang) ? '' : ' ');

const segmenters = new Map();
function segmenter(lang) {
  if (typeof Intl === 'undefined' || !Intl.Segmenter) return null;
  if (!segmenters.has(lang)) {
    try {
      segmenters.set(lang, new Intl.Segmenter(lang, { granularity: 'word' }));
    } catch (_) {
      segmenters.set(lang, null);
    }
  }
  return segmenters.get(lang);
}

/** Words of a text (no punctuation, no spaces). */
export function wordsOf(text, lang) {
  const seg = segmenter(lang);
  if (seg) {
    const out = [];
    for (const s of seg.segment(text)) {
      if (s.isWordLike) out.push(s.segment);
    }
    return out;
  }
  return text.split(/[^\p{L}\p{M}\p{N}'’-]+/u).filter(Boolean);
}

export const wordCount = (text, lang) => wordsOf(text, lang).length;

/** Lower case, drop accents and Arabic marks, unify digits. */
export function norm(s) {
  return s
    .normalize('NFD')
    .replace(/[̀-ًͯ-ٟـ]/g, '')
    .normalize('NFC')
    .toLowerCase()
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x660))
    .replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x6f0))
    .replace(/[०-९]/g, (d) => String(d.charCodeAt(0) - 0x966));
}

/** Split one line into sentences. Decimal points and abbreviations stay intact. */
export function splitSentences(line) {
  const out = [];
  let cur = '';
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    cur += c;
    const strong = '。！？'.includes(c);
    const soft = '.!?।؟'.includes(c) && (i + 1 === line.length || /\s/.test(line[i + 1]));
    if (strong || soft) {
      out.push(cur);
      cur = '';
    }
  }
  if (cur.trim()) out.push(cur);
  return out.map((s) => s.trim()).filter(Boolean);
}

/** Long sentences are cut at commas so each piece stays small. */
export function clauses(sentence, lang, limit = 28) {
  if (wordCount(sentence, lang) <= limit) return [sentence];
  const raw = sentence.split(/(?<=[,;:،؛、，；：])\s*/u).filter((x) => x.trim());
  const out = [];
  for (const p of raw) {
    if (out.length && wordCount(out[out.length - 1], lang) < 6) {
      out[out.length - 1] += joinerFor(lang) + p;
    } else {
      out.push(p);
    }
  }
  return out.length ? out : [sentence];
}

function splitHalf(text, lang) {
  let tokens;
  if (isNoSpace(lang)) {
    const seg = segmenter(lang);
    tokens = seg ? Array.from(seg.segment(text), (s) => s.segment) : Array.from(text);
  } else {
    tokens = text.split(/\s+/).filter(Boolean);
  }
  const mid = tokens.length >> 1;
  const j = joinerFor(lang);
  return [tokens.slice(0, mid).join(j), tokens.slice(mid).join(j)].filter((p) => p.trim());
}

function worthChecking(w, lang) {
  if (/\p{N}/u.test(w)) return true;
  if (baseLang(lang) === 'ja') return !/^[぀-ゟ]{1,2}$/.test(w);
  if (isNoSpace(lang)) return Array.from(w).length >= 2;
  const len = Array.from(w).length;
  const latinLike = /^[\p{Script=Latin}\p{Script=Cyrillic}'’-]+$/u.test(w);
  if (len < (latinLike ? 4 : 3)) return false;
  if (baseLang(lang) === 'en' && STOP_EN.has(w.toLowerCase())) return false;
  return true;
}

/** Unique source words that deserve a check. */
export function candidates(sentence, lang) {
  const seen = new Set();
  const out = [];
  for (const w of wordsOf(sentence, lang)) {
    const k = norm(w);
    if (seen.has(k) || !worthChecking(w, lang)) continue;
    seen.add(k);
    out.push(w);
  }
  return out;
}

function keepGlossToken(t, lang) {
  if (baseLang(lang) === 'ja') return !/^[぀-ゟ]$/.test(t);
  if (isNoSpace(lang)) return Array.from(t).length >= 2;
  if (baseLang(lang) === 'en') return t.length >= 3 && !STOP_EN.has(t);
  return t.length >= 3;
}

function tokenHit(t, target, lang) {
  if (isNoSpace(lang)) return target.includes(t);
  const chars = Array.from(t);
  const stem = chars.length > 5 ? chars.slice(0, chars.length - 2).join('') : t;
  return target.includes(stem);
}

/** Does the one-word translation `gloss` appear in the normalised `target`? */
export function glossCovered(gloss, targetNorm, toLang) {
  const toks = wordsOf(gloss, toLang).map(norm).filter((t) => keepGlossToken(t, toLang));
  if (toks.length === 0) return true; // nothing meaningful to look for
  return toks.some((t) => tokenHit(t, targetNorm, toLang));
}

export function createSafety(rawTranslate, options = {}) {
  const maxChecks = options.maxChecks ?? 40;
  const glossCache = new Map();
  let epoch = 0;

  async function translateSentence(from, to, sentence) {
    const outs = [];
    for (const piece of clauses(sentence, from)) outs.push(await rawTranslate(from, to, piece));
    return outs.join(joinerFor(to));
  }

  async function translateText(from, to, text) {
    const lines = text.split('\n');
    const outLines = [];
    for (const line of lines) {
      if (!line.trim()) {
        outLines.push('');
        continue;
      }
      const outs = [];
      for (const s of splitSentences(line)) outs.push(await translateSentence(from, to, s));
      outLines.push(outs.join(joinerFor(to)));
    }
    return outLines.join('\n');
  }

  async function gloss(from, to, word) {
    const key = `${from}|${to}|${word}`;
    if (!glossCache.has(key)) glossCache.set(key, (await rawTranslate(from, to, word)).trim());
    return glossCache.get(key);
  }

  function reset() {
    glossCache.clear();
    epoch++;
  }

  /**
   * Translate and verify. Returns { translated, total, checked, missing:[{word,gloss}] }
   * or { cancelled: true } when a newer check started meanwhile.
   */
  async function check(from, to, text) {
    const my = ++epoch;
    const lines = text.split('\n');
    const outLines = [];
    const missing = [];
    const missingSeen = new Set();
    const counted = new Set();
    const checkedSet = new Set();

    async function findMissing(sentence, cands, out) {
      const target = norm(out);
      const found = [];
      for (const w of cands) {
        const k = norm(w);
        if (/\p{N}/u.test(w)) {
          checkedSet.add(k);
          if (!target.includes(k)) found.push({ word: w, gloss: w });
          continue;
        }
        const cached = glossCache.has(`${from}|${to}|${w}`);
        if (!cached && checkedSet.size >= maxChecks && !checkedSet.has(k)) continue;
        const g = await gloss(from, to, w);
        if (my !== epoch) return null;
        checkedSet.add(k);
        if (!glossCovered(g, target, to)) found.push({ word: w, gloss: g });
      }
      return found;
    }

    for (const line of lines) {
      if (!line.trim()) {
        outLines.push('');
        continue;
      }
      const outs = [];
      for (const s of splitSentences(line)) {
        let out = await translateSentence(from, to, s);
        if (my !== epoch) return { cancelled: true };
        const cands = candidates(s, from);
        for (const w of cands) counted.add(norm(w));
        let miss = await findMissing(s, cands, out);
        if (miss === null) return { cancelled: true };
        if (miss.length > 0 && wordCount(s, from) > 3) {
          const parts = splitHalf(s, from);
          const pouts = [];
          for (const p of parts) pouts.push(await rawTranslate(from, to, p));
          if (my !== epoch) return { cancelled: true };
          const out2 = pouts.join(joinerFor(to));
          const miss2 = await findMissing(s, cands, out2);
          if (miss2 === null) return { cancelled: true };
          if (miss2.length < miss.length) {
            out = out2;
            miss = miss2;
          }
        }
        for (const m of miss) {
          const k = norm(m.word);
          if (!missingSeen.has(k)) {
            missingSeen.add(k);
            missing.push(m);
          }
        }
        outs.push(out);
      }
      outLines.push(outs.join(joinerFor(to)));
    }
    return {
      cancelled: false,
      translated: outLines.join('\n'),
      total: counted.size,
      checked: checkedSet.size,
      missing,
    };
  }

  return { translateText, check, gloss, reset };
}
