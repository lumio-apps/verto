// Roman ("Hinglish") spelling for Hindi text. Best effort: it follows common
// Hinglish habits (kaise, mera, hai), not a strict transliteration standard.

const CONS = {
  'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'n', 'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh',
  'ञ': 'n', 'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n', 'त': 't', 'थ': 'th', 'द': 'd',
  'ध': 'dh', 'न': 'n', 'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm', 'य': 'y', 'र': 'r',
  'ल': 'l', 'व': 'v', 'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h', 'ळ': 'l',
};
const NUKTA = { 'क': 'q', 'ख': 'kh', 'ग': 'g', 'ज': 'z', 'ड': 'r', 'ढ': 'rh', 'फ': 'f' };
const VOWELS = {
  'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo', 'ऋ': 'ri',
  'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au', 'ऑ': 'o',
};
const MATRAS = {
  'ा': 'aa', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo', 'ृ': 'ri',
  'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', 'ॉ': 'o',
};
const VIRAMA = '्';
const NUKTA_MARK = '़';

function syllablesOf(word) {
  const out = [];
  let pending = ''; // consonants joined by virama, waiting for a vowel
  let pendingCount = 0;
  const last = () => out[out.length - 1];
  const chars = Array.from(word);
  for (let i = 0; i < chars.length; i++) {
    const c = chars[i];
    if (CONS[c] !== undefined) {
      let r = CONS[c];
      if (chars[i + 1] === NUKTA_MARK) {
        r = NUKTA[c] ?? r;
        i++;
      }
      pending += r;
      pendingCount++;
      const next = chars[i + 1];
      if (next === VIRAMA) {
        i++; // joins the next consonant
        continue;
      }
      if (next !== undefined && MATRAS[next] !== undefined) {
        out.push({ onset: pending, cluster: pendingCount > 1, vowel: MATRAS[next], kind: 'explicit', coda: '' });
        i++;
      } else {
        out.push({ onset: pending, cluster: pendingCount > 1, vowel: 'a', kind: 'inherent', coda: '' });
      }
      pending = '';
      pendingCount = 0;
    } else if (VOWELS[c] !== undefined) {
      out.push({ onset: '', cluster: false, vowel: VOWELS[c], kind: 'explicit', coda: '' });
    } else if (c === 'ं' || c === 'ँ') {
      if (out.length) last().coda += 'n';
    } else if (c === 'ः') {
      if (out.length) last().coda += 'h';
    } else if (c === VIRAMA && pending) {
      // stray virama
    }
  }
  if (pending) out.push({ onset: pending, cluster: pendingCount > 1, vowel: '', kind: 'none', coda: '' });
  return out;
}

function romanizeWord(word) {
  const syl = syllablesOf(word.normalize('NFD'));
  for (let i = 0; i < syl.length; i++) {
    const s = syl[i];
    if (s.kind !== 'inherent') continue;
    const isLast = i === syl.length - 1;
    if (isLast) {
      if (!s.cluster && !s.coda) s.vowel = '';
      continue;
    }
    const prev = syl[i - 1];
    const next = syl[i + 1];
    const prevKept = i > 0 && prev.vowel !== '';
    const nextExplicit = next.kind === 'explicit' && !next.cluster;
    if (prevKept && nextExplicit && !s.coda) s.vowel = '';
  }
  return syl
    .map((s, i) => {
      let v = s.vowel;
      const isLast = i === syl.length - 1;
      if (isLast && !s.coda) {
        if (v === 'aa') v = 'a';
        else if (v === 'ee') v = 'i';
      }
      let coda = s.coda;
      if (v === 'e' && coda === 'n') {
        v = 'ei';
      }
      return s.onset + v + coda;
    })
    .join('');
}

const DIGITS = { '०': '0', '१': '1', '२': '2', '३': '3', '४': '4', '५': '5', '६': '6', '७': '7', '८': '8', '९': '9' };

/** Roman spelling of `text`, or null when the language has no romanizer. */
export function romanize(text, lang) {
  if (String(lang).split('-')[0] !== 'hi') return null;
  return text
    .replace(/[ऀ-ॣ]+/g, (w) => romanizeWord(w))
    .replace(/[०-९]/g, (d) => DIGITS[d])
    .replace(/[।॥]/g, '.');
}
