# Roadmap

- **Armenian.** Mozilla does not publish Armenian models. OPUS-MT has English-Armenian (BLEU 16.6) and Armenian-English (BLEU 29.5), Apache-2.0, but they must be converted to the Bergamot format first. Add `hy` to `LANGS` in `tool/build_packs.py` once packs exist.
- Dark theme.
- Camera / image text translation.
- Verify the word safety net on more language pairs and tune the thresholds in `assets/web/safety.js`.
- Optional silent update check at app start (off by default for privacy).
