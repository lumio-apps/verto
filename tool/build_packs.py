#!/usr/bin/env python3
"""Build Verto language packs from Mozilla's Firefox Translations models.

Usage: python3 tool/build_packs.py OUT_DIR [lang ...]

With no language codes, every language that has a complete stable English->X and
X->English model in Mozilla Remote Settings is built. Models are downloaded,
un-gzipped and written as flat release assets plus a manifest.json into OUT_DIR.
Models are MPL-2.0 (Mozilla).
"""
import gzip
import hashlib
import json
import os
import sys
import time
import urllib.request

ROOT = "https://firefox.settings.services.mozilla.com/v1/"
RECORDS = ROOT + "buckets/main/collections/translations-models/records?_limit=2000"
# name, native name. Unknown codes fall back to the code itself.
NAMES = {
    "af": ("Afrikaans", "Afrikaans"), "ar": ("Arabic", "العربية"), "az": ("Azerbaijani", "Azərbaycanca"),
    "be": ("Belarusian", "Беларуская"), "bg": ("Bulgarian", "Български"), "bn": ("Bengali", "বাংলা"),
    "bs": ("Bosnian", "Bosanski"), "ca": ("Catalan", "Català"), "cs": ("Czech", "Čeština"),
    "cy": ("Welsh", "Cymraeg"), "da": ("Danish", "Dansk"), "de": ("German", "Deutsch"),
    "el": ("Greek", "Ελληνικά"), "es": ("Spanish", "Español"), "et": ("Estonian", "Eesti"),
    "eu": ("Basque", "Euskara"), "fa": ("Persian (Farsi)", "فارسی"), "fi": ("Finnish", "Suomi"),
    "fr": ("French", "Français"), "ga": ("Irish", "Gaeilge"), "gl": ("Galician", "Galego"),
    "gu": ("Gujarati", "ગુજરાતી"), "he": ("Hebrew", "עברית"), "hi": ("Hindi", "हिन्दी"),
    "hr": ("Croatian", "Hrvatski"), "hu": ("Hungarian", "Magyar"), "id": ("Indonesian", "Bahasa Indonesia"),
    "is": ("Icelandic", "Íslenska"), "it": ("Italian", "Italiano"), "ja": ("Japanese", "日本語"),
    "ka": ("Georgian", "ქართული"), "kn": ("Kannada", "ಕನ್ನಡ"), "ko": ("Korean", "한국어"),
    "lt": ("Lithuanian", "Lietuvių"), "lv": ("Latvian", "Latviešu"), "mk": ("Macedonian", "Македонски"),
    "mr": ("Marathi", "मराठी"), "ms": ("Malay", "Bahasa Melayu"), "mt": ("Maltese", "Malti"),
    "nb": ("Norwegian Bokmål", "Norsk bokmål"), "nl": ("Dutch", "Nederlands"), "nn": ("Norwegian Nynorsk", "Norsk nynorsk"),
    "pa": ("Punjabi", "ਪੰਜਾਬੀ"), "pl": ("Polish", "Polski"), "pt": ("Portuguese", "Português"),
    "ro": ("Romanian", "Română"), "ru": ("Russian", "Русский"), "sk": ("Slovak", "Slovenčina"),
    "sl": ("Slovenian", "Slovenščina"), "sq": ("Albanian", "Shqip"), "sr": ("Serbian", "Српски"),
    "sv": ("Swedish", "Svenska"), "sw": ("Swahili", "Kiswahili"), "ta": ("Tamil", "தமிழ்"),
    "te": ("Telugu", "తెలుగు"), "th": ("Thai", "ไทย"), "tr": ("Turkish", "Türkçe"),
    "uk": ("Ukrainian", "Українська"), "ur": ("Urdu", "اردو"), "vi": ("Vietnamese", "Tiếng Việt"),
    "zh": ("Chinese (Simplified)", "简体中文"), "zh-Hans": ("Chinese (Simplified)", "简体中文"),
    "zh-Hant": ("Chinese (Traditional)", "繁體中文"),
}
RTL = {"ar", "fa", "he", "ur"}
ROLE_FILE = {
    "model": "model.bin",
    "lex": "lex.bin",
    "vocab": "vocab.spm",
    "srcvocab": "srcvocab.spm",
    "trgvocab": "trgvocab.spm",
}


def get(url, retries=3):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "verto-pack-builder"})
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read(), r.headers
        except Exception as e:  # noqa: BLE001
            if attempt == retries - 1:
                raise
            print(f"  retry after error: {e}")
            time.sleep(3)


def version_key(v):
    parts = v.split(".")
    if not all(p.isdigit() for p in parts):
        return None  # skip alpha/beta/dev versions
    return tuple(int(p) for p in parts)


def load_records():
    records, url = [], RECORDS
    while url:
        body, headers = get(url)
        records += json.loads(body)["data"]
        url = headers.get("Next-Page")
    return records


def pick(records, src, dst):
    """Newest stable version of every file type for one direction."""
    best = {}
    for r in records:
        if r.get("fromLang") != src or r.get("toLang") != dst:
            continue
        if r.get("fileType") not in ROLE_FILE:
            continue
        k = version_key(r.get("version", ""))
        if k is None:
            continue
        cur = best.get(r["fileType"])
        if cur is None or k > cur[0]:
            best[r["fileType"]] = (k, r)
    chosen = {t: v[1] for t, v in best.items()}
    if "model" not in chosen or "lex" not in chosen:
        return None
    if "vocab" not in chosen and not ("srcvocab" in chosen and "trgvocab" in chosen):
        return None
    if "vocab" in chosen:
        chosen.pop("srcvocab", None)
        chosen.pop("trgvocab", None)
    chosen.pop("qualityModel", None)
    return chosen


def sha256(b):
    return hashlib.sha256(b).hexdigest()


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)

    base_url = json.loads(get(ROOT)[0])["capabilities"]["attachments"]["base_url"]
    records = load_records()
    print(f"{len(records)} model records")

    wanted = sys.argv[2:]
    if not wanted:
        # every X that has stable models in BOTH directions with English
        pairs = {(r.get("fromLang"), r.get("toLang")) for r in records}
        candidates = sorted({a if b == "en" else b for a, b in pairs if "en" in (a, b) and a != b})
        wanted = [c for c in candidates if pick(records, "en", c) and pick(records, c, "en")]
        print("Languages found:", " ".join(wanted))

    previous = {}
    repo = os.environ.get("GITHUB_REPOSITORY")
    if repo:
        try:
            body, _ = get(f"https://github.com/{repo}/releases/download/packs/manifest.json", retries=1)
            previous = json.loads(body).get("packs", {})
        except Exception:  # noqa: BLE001
            print("No previous manifest (first run)")

    packs = dict(previous)
    built = 0
    for code in wanted:
        print(f"== {code}")
        files, ok = [], True
        for src, dst in (("en", code), (code, "en")):
            chosen = pick(records, src, dst)
            if chosen is None:
                print(f"  SKIPPED {code}: no complete stable model for {src}->{dst}")
                ok = False
                break
            direction = f"{src}-{dst}"
            for role, rec in sorted(chosen.items()):
                att = rec["attachment"]
                raw, _ = get(base_url + att["location"])
                if sha256(raw) != att["hash"]:
                    raise SystemExit(f"Hash mismatch for {att['location']}")
                data = gzip.decompress(raw) if raw[:2] == b"\x1f\x8b" else raw
                name = f"{direction}.{ROLE_FILE[role]}"
                with open(os.path.join(out, name), "wb") as f:
                    f.write(data)
                files.append({
                    "name": name,
                    "path": f"{direction}/{ROLE_FILE[role]}",
                    "size": len(data),
                    "sha256": sha256(data),
                })
                print(f"  {name}: {len(data) / 1e6:.1f} MB (model v{rec['version']})")
        if not ok:
            for f in files:
                p = os.path.join(out, f["name"])
                if os.path.exists(p):
                    os.remove(p)
            continue
        old = previous.get(code)
        same = old is not None and sorted((f["path"], f["sha256"]) for f in old["files"]) == \
            sorted((f["path"], f["sha256"]) for f in files)
        version = old["version"] if same else (old["version"] + 1 if old else 1)
        name, native = NAMES.get(code, (code, ""))
        packs[code] = {
            "version": version,
            "name": name,
            "native": native,
            "rtl": code.split("-")[0] in RTL,
            "files": files,
        }
        built += 1

    if built == 0:
        raise SystemExit("No pack was built.")
    with open(os.path.join(out, "manifest.json"), "w") as f:
        json.dump({"schema": 1, "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "packs": packs}, f, indent=1)
    print(f"Built {built} pack(s).")


if __name__ == "__main__":
    main()
