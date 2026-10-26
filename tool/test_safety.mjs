// Run with: node tool/test_safety.mjs
import assert from 'node:assert/strict';
import { romanize } from '../assets/web/translit.js';
import { splitSentences, clauses, candidates, glossCovered, norm, createSafety } from '../assets/web/safety.js';

// 1. sentence splitting keeps decimals together
assert.deepEqual(splitSentences('It costs 3.5 dollars. Come here! Why?'), ['It costs 3.5 dollars.', 'Come here!', 'Why?']);
assert.deepEqual(splitSentences('これはペンです。あれは本です。'), ['これはペンです。', 'あれは本です。']);

// 2. long sentences are cut at commas
const long = Array.from({ length: 40 }, (_, i) => `word${i}`);
const sentence = long.slice(0, 20).join(' ') + ', ' + long.slice(20).join(' ');
assert.equal(clauses(sentence, 'en').length, 2);
assert.equal(clauses('short one, really', 'en').length, 1);

// 3. candidates skip function words, keep numbers
assert.deepEqual(candidates('The nearest hospital is 5 km away', 'en'), ['nearest', 'hospital', '5', 'away']);

// 4. gloss coverage
assert.equal(glossCovered('the', norm('anything'), 'en'), true); // nothing meaningful
assert.equal(glossCovered('hospital', norm('The hospital is near'), 'en'), true);
assert.equal(glossCovered('nearest', norm('The hospital is far'), 'en'), false);

// 5. A mock engine that drops "nearest" in long input but not in short input.
const dict = { the: 'वह', nearest: 'निकटतम', hospital: 'अस्पताल', is: 'है', where: 'कहाँ', pharmacy: 'दवाखाना' };
async function mock(from, to, text) {
  const ws = text.toLowerCase().replace(/[?.!]/g, '').split(/\s+/).filter(Boolean);
  const dropNearest = ws.length > 4;
  return ws.filter((w) => !(dropNearest && w === 'nearest')).map((w) => dict[w] ?? w).join(' ');
}
const safety = createSafety(mock);
const r = await safety.check('en', 'hi', 'Where is the nearest hospital?');
assert.equal(r.cancelled, false);
assert.ok(r.translated.includes('निकटतम'), 'retranslation in halves should recover the dropped word: ' + r.translated);
assert.equal(r.missing.length, 0);

// 6. A word the engine never produces is reported
const stubborn = createSafety(async (f, t, text) => {
  const ws = text.toLowerCase().replace(/[?.!]/g, '').split(/\s+/).filter(Boolean);
  const keep = ws.length === 1 ? ws : ws.filter((w) => w !== 'pharmacy'); // dropped only inside sentences
  return keep.map((w) => dict[w] ?? w).join(' ');
});
const r2 = await stubborn.check('en', 'hi', 'Where is the nearest pharmacy?');
assert.deepEqual(r2.missing.map((m) => m.word), ['pharmacy']);
assert.equal(r2.missing[0].gloss, 'दवाखाना');

// 7. numbers must survive
const nums = createSafety(async (f, t, text) => text.replace(/\d+/g, ''));
const r3 = await nums.check('en', 'hi', 'Call 112 now please');
assert.ok(r3.missing.some((m) => m.word === '112'));

// 8. A newer check cancels an older one
const slow = createSafety(async (f, t, text) => { await new Promise((ok) => setTimeout(ok, 5)); return text; });
const a = slow.check('en', 'fr', 'First sentence here. Second sentence there.');
const b = slow.check('en', 'fr', 'Newer text arrives');
assert.equal((await a).cancelled, true);
assert.equal((await b).cancelled, false);

// 9. translateText keeps blank lines
const t = await createSafety(async (f, to, x) => x.toUpperCase()).translateText('en', 'fr', 'one.\n\ntwo.');
assert.equal(t, 'ONE.\n\nTWO.');

// 10. Japanese source is segmented into words
const jp = candidates('私は東京に行きます', 'ja');
assert.ok(jp.length >= 2, 'segmenter should find words: ' + jp.join('|'));

// 11. Chinese is written without spaces
const zh = createSafety(async (f, to, x) => x);
const rz = await zh.translateText('en', 'zh-Hans', 'Hello. World.');
assert.equal(rz, 'Hello.World.');
assert.ok(candidates('我喜欢北京的天气', 'zh-Hans').length >= 2);

// 12. Hinglish (Roman Hindi)
const cases = {
  'कैसे हो आप': 'kaise ho aap',
  'मेरा नाम आदित्य है': 'mera naam aaditya hai',
  'नमस्ते': 'namaste',
  'मैं ठीक हूँ': 'main theek hoon',
  'यह कमरा बहुत अच्छा है': 'yah kamra bahut achchha hai',
  'आप क्या कर रहे हैं?': 'aap kya kar rahe hain?',
  'समझता': 'samajhta',
  'वह बाज़ार में है।': 'vah baazaar mein hai.',
};
for (const [hi, roman] of Object.entries(cases)) assert.equal(romanize(hi, 'hi'), roman, hi);
assert.equal(romanize('hello', 'fr'), null);
assert.equal(romanize('hello, मित्र 2', 'hi'), 'hello, mitra 2');

console.log('safety.js: all tests passed');
