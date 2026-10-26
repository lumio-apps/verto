# Roadmap

- **Armenian (parked).** Mozilla does not publish Armenian models. Idea: ask Mozilla to add it, or convert the OPUS-MT models. OPUS-MT has English-Armenian (BLEU 16.6) and Armenian-English (BLEU 29.5), Apache-2.0, but they must be converted to the Bergamot format first. Once packs exist, add them to the pack list (the app shows any language the list contains).
- Camera / image text translation.
- Verify the word safety net on more language pairs and tune the thresholds in `assets/web/safety.js`.
- Optional silent update check at app start (off by default for privacy).
- Type Hinglish (Roman Hindi) and translate it: needs Roman-to-Devanagari conversion first.
- Select text in any app and choose Translate with Verto.
- Conversation mode, offline phrasebook.
