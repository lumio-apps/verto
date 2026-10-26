# Roadmap

Done in v1.1.0 (v1.1.1 fixes the storage texts): dark theme, history and favourites, read aloud, big text, clipboard offer, storage screen, Hinglish output, searchable language lists.

## Next (planned for v1.2.0)

- Select text in any app and choose **Translate with Verto** (share sheet and text selection menu).
- **Detect language** automatically when text is pasted.
- **App lock** (fingerprint or PIN) to protect history.
- **Backup and restore** of history and favourites as a file, no cloud.

## Later

- Conversation mode (two people, split screen).
- Offline phrasebook (travel, doctor, directions, emergency) plus your own favourites.
- Quick settings tile and home-screen widget.
- Install packs from a file (phone to phone, no internet).
- Fast and high-quality pack choice per language.
- Translate a .txt file and save the result.
- Roman-letter pronunciation for more languages than Hindi (Russian, Arabic, Persian, Japanese).
- App interface in other languages.
- Optional silent update check at app start (off by default for privacy).
- Type Hinglish (Roman Hindi) and translate it: needs Roman-to-Devanagari conversion first.
- Verify the word safety net on more language pairs and tune the thresholds in `assets/web/safety.js`.

## Parked or hard

- **Armenian.** Mozilla does not publish Armenian models. Idea: ask Mozilla to add it, or convert the OPUS-MT models. OPUS-MT has English-Armenian (BLEU 16.6) and Armenian-English (BLEU 29.5), Apache-2.0, but they must be converted to the Bergamot format first. Once packs exist, add them to the pack list (the app shows any language the list contains).
- Camera / image text translation: the easy engines are Google's (against the privacy goal), Tesseract is heavy.
- Speech to text: the phone's recogniser usually talks to Google servers.
