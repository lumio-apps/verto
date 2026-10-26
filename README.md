# Verto

Private, offline translator for Android. English is built in. Download any of the other languages once and translate to and from English with no internet. No account, no ads, no tracking.

**Languages:** every language Mozilla publishes with both directions to English (Hindi, Spanish, French, German, Russian, Japanese, Arabic, Persian and more). The pack builder finds them itself, and the app lists whatever the pack list contains. Armenian is not available (see [ROADMAP](ROADMAP.md)).
One language pack gives both directions (English to X and X to English). X to Y without English is not offered.

## How it works

- **Engine:** [Bergamot translator](https://github.com/browsermt/bergamot-translator) (the engine behind Firefox Translations), as WebAssembly. It runs inside a hidden WebView and is fed by a tiny web server that listens only on `127.0.0.1` inside the app. Nothing you type leaves the phone.
- **Models:** Mozilla's Firefox Translations models (MPL-2.0). They are not stored in git. The "Build language packs" workflow copies them to a GitHub release called `packs`, and the app downloads from there (with resume, size and SHA-256 checks).
- **Updates:** *Languages* tab shows pack updates and an app update check (GitHub Releases). Updating a pack or the app never deletes your history or settings.
- **Word safety net:** text is translated sentence by sentence; afterwards each meaningful word is translated on its own and looked for in the result. Words that seem to be missing are highlighted; tap one to see its translation and add it. This is a best-effort check, not a guarantee.

## Build and release

1. `pubspec.yaml` `version:` must match the tag you push (tag `v1.1.0` needs `version: 1.1.0+3`).
2. Push the tag. `.github/workflows/release.yml` fetches the engine, runs analyze and tests, builds the APK, signs it and creates the release.

Repository secrets needed by the release workflow:

| Secret | Meaning |
| --- | --- |
| `KEYSTORE_BASE64` | the release keystore file, base64 encoded |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |

Language packs: Actions > **Build language packs** > Run workflow. Run it before the first release so the app has something to download.

Local development: `dart run tool/fetch_engine.dart` downloads the engine into `assets/engine/`. `node tool/test_safety.mjs` tests the word safety net.

## Layout

- `lib/core` engine bridge, local server, packs, downloads, updates
- `lib/ui` screens
- `assets/web` page and scripts that run inside the WebView (`bridge.js`, `safety.js`)
- `tool/` engine fetcher, pack builder, JS tests

## Licenses

Bergamot translator and the Mozilla models are MPL-2.0. See *Languages > About and licenses* in the app. Add your own LICENSE file for Verto's code.
