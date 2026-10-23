// Verto engine bridge. Runs inside a hidden WebView.
// Dart calls window.vertoCall(id, method, argsJson); the answer is posted back
// through the "Verto" JavaScript channel.

const post = (obj) => {
  try {
    Verto.postMessage(JSON.stringify(obj));
  } catch (_) {
    /* channel missing (opened in a normal browser) */
  }
};

const state = { packs: {}, translator: null, Backing: null, Batch: null };
const cache = new Map();
let safety = null;

function makeBacking(TranslatorBacking) {
  // NOTE: the base constructor may call these methods, so never rely on
  // instance fields set after super(); everything lives in `state`.
  return class VertoBacking extends TranslatorBacking {
    async loadModelRegistery() {
      const out = [];
      for (const code of Object.keys(state.packs)) {
        out.push({ from: 'en', to: code }, { from: code, to: 'en' });
      }
      return out;
    }

    async loadTranslationModel({ from, to }) {
      const code = from === 'en' ? to : from;
      const pack = state.packs[code];
      if (!pack) throw new Error('Language pack not installed: ' + code);
      const dir = `${from}-${to}`;
      const has = (name) => pack.files.includes(`${dir}/${name}`);
      const get = async (name) => {
        const r = await fetch(`packs/${code}/${dir}/${name}`);
        if (!r.ok) throw new Error(`Missing ${dir}/${name} (HTTP ${r.status})`);
        return r.arrayBuffer();
      };
      const model = await get('model.bin');
      const shortlist = await get('lex.bin');
      const vocabs = has('vocab.spm')
        ? [await get('vocab.spm')]
        : [await get('srcvocab.spm'), await get('trgvocab.spm')];
      return { model, shortlist, vocabs, config: {} };
    }
  };
}

function resetTranslator() {
  cache.clear();
  if (safety) safety.reset();
  if (state.translator) {
    try {
      state.translator.delete();
    } catch (_) {
      /* ignore */
    }
    state.translator = null;
  }
}

function ensureTranslator() {
  if (!state.translator) {
    const Backing = makeBacking(state.Backing);
    state.translator = new state.Batch({ workers: 1 }, new Backing({}));
  }
  return state.translator;
}

async function rawTranslate(from, to, text) {
  if (!text.trim()) return '';
  const key = `${from}|${to}|${text}`;
  if (cache.has(key)) return cache.get(key);
  const res = await ensureTranslator().translate({ from, to, text, html: false });
  const out = res.target.text;
  if (cache.size > 800) cache.clear();
  cache.set(key, out);
  return out;
}

const handlers = {
  async ping() {
    return 'pong';
  },
  async setPacks({ packs }) {
    state.packs = packs;
    resetTranslator();
    return true;
  },
  async translate({ from, to, text }) {
    return { text: await safety.translateText(from, to, text) };
  },
  async check({ from, to, text }) {
    return safety.check(from, to, text);
  },
  async gloss({ from, to, word }) {
    return { gloss: await safety.gloss(from, to, word) };
  },
};

window.vertoCall = async (id, method, argsJson) => {
  try {
    const fn = handlers[method];
    if (!fn) throw new Error('Unknown method ' + method);
    const result = await fn(JSON.parse(argsJson));
    post({ t: 'reply', id, ok: true, result });
  } catch (e) {
    post({ t: 'reply', id, ok: false, error: String((e && e.message) || e) });
  }
};

(async () => {
  try {
    const mod = await import('./engine/translator.js');
    if (!mod.TranslatorBacking || !mod.BatchTranslator) {
      throw new Error('translator.js does not export TranslatorBacking / BatchTranslator');
    }
    state.Backing = mod.TranslatorBacking;
    state.Batch = mod.BatchTranslator;
    const { createSafety } = await import('./safety.js');
    safety = createSafety(rawTranslate);
    post({ t: 'ready' });
  } catch (e) {
    post({ t: 'fatal', error: String((e && e.stack) || e) });
  }
})();
