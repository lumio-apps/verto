#!/usr/bin/env python3
"""Build Verto language packs from Mozilla's Firefox Translations models.

Usage: python3 tool/build_packs.py OUT_DIR [lang ...]

With no language codes, every language that has an English->X and an X->English
model is built. Models are downloaded, decompressed and written as flat release
assets plus a manifest.json into OUT_DIR. Models are MPL-2.0 (Mozilla).

Sources, in order of preference:
  1. Remote Settings collection "translations-models-v2" (current; zstd files,
     several architectures, release/beta/nightly channels, Android/desktop filters)
  2. Remote Settings collection "translations-models" (old; gzip files)

For every direction one complete model set (model + lex + vocab of the SAME
architecture and version) is chosen. Ranking:
  release before beta (nightly/alpha is never used),
  sets meant for Android (or for every platform) before desktop-only sets,
  architecture: base-memory, base, tiny (quality first, then size),
  newest version.
Packs that use a beta model are marked "beta": true in the manifest.

Set VERTO_NO_BETA=1 to use release models only.
"""
import gzip
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.request

ROOT = "https://firefox.settings.services.mozilla.com/v1/"
COLLECTIONS = ["translations-models-v2", "translations-models"]

# Better quality first. Unknown architectures come last.
ARCH_ORDER = ["base-memory", "base", "tiny"]

ROLE_FILE = {
    "model": "model.bin",
    "lex": "lex.bin",
    "vocab": "vocab.spm",
    "srcvocab": "srcvocab.spm",
    "trgvocab": "trgvocab.spm",
}

# name, native name. Unknown codes fall back to the code itself.
NAMES = {
    "af": ("Afrikaans", "Afrikaans"), "am": ("Amharic", "አማርኛ"), "ar": ("Arabic", "العربية"),
    "az": ("Azerbaijani", "Azərbaycanca"), "be": ("Belarusian", "Беларуская"), "bg": ("Bulgarian", "Български"),
    "bn": ("Bengali", "বাংলা"), "bs": ("Bosnian", "Bosanski"), "ca": ("Catalan", "Català"),
    "ceb": ("Cebuano", "Cebuano"), "ckb": ("Kurdish (Sorani)", "کوردی"), "cs": ("Czech", "Čeština"),
    "cy": ("Welsh", "Cymraeg"), "da": ("Danish", "Dansk"), "de": ("German", "Deutsch"),
    "el": ("Greek", "Ελληνικά"), "eo": ("Esperanto", "Esperanto"), "es": ("Spanish", "Español"),
    "et": ("Estonian", "Eesti"), "eu": ("Basque", "Euskara"), "fa": ("Persian (Farsi)", "فارسی"),
    "fi": ("Finnish", "Suomi"), "fil": ("Filipino", "Filipino"), "fr": ("French", "Français"),
    "fy": ("Frisian", "Frysk"), "ga": ("Irish", "Gaeilge"), "gd": ("Scottish Gaelic", "Gàidhlig"),
    "gl": ("Galician", "Galego"), "gu": ("Gujarati", "ગુજરાતી"), "ha": ("Hausa", "Hausa"),
    "he": ("Hebrew", "עברית"), "hi": ("Hindi", "हिन्दी"), "hr": ("Croatian", "Hrvatski"),
    "hu": ("Hungarian", "Magyar"), "hy": ("Armenian", "Հայերեն"), "id": ("Indonesian", "Bahasa Indonesia"),
    "ig": ("Igbo", "Igbo"), "is": ("Icelandic", "Íslenska"), "it": ("Italian", "Italiano"),
    "ja": ("Japanese", "日本語"), "jv": ("Javanese", "Basa Jawa"), "ka": ("Georgian", "ქართული"),
    "kk": ("Kazakh", "Қазақша"), "km": ("Khmer", "ខ្មែរ"), "kn": ("Kannada", "ಕನ್ನಡ"),
    "ko": ("Korean", "한국어"), "ku": ("Kurdish (Kurmanji)", "Kurdî"), "ky": ("Kyrgyz", "Кыргызча"),
    "la": ("Latin", "Latina"), "lb": ("Luxembourgish", "Lëtzebuergesch"), "lo": ("Lao", "ລາວ"),
    "lt": ("Lithuanian", "Lietuvių"), "lv": ("Latvian", "Latviešu"), "mg": ("Malagasy", "Malagasy"),
    "mk": ("Macedonian", "Македонски"), "ml": ("Malayalam", "മലയാളം"), "mn": ("Mongolian", "Монгол"),
    "mr": ("Marathi", "मराठी"), "ms": ("Malay", "Bahasa Melayu"), "mt": ("Maltese", "Malti"),
    "my": ("Burmese", "မြန်မာ"), "nb": ("Norwegian Bokmål", "Norsk bokmål"), "ne": ("Nepali", "नेपाली"),
    "nl": ("Dutch", "Nederlands"), "nn": ("Norwegian Nynorsk", "Norsk nynorsk"), "no": ("Norwegian", "Norsk"),
    "or": ("Odia", "ଓଡ଼ିଆ"), "pa": ("Punjabi", "ਪੰਜਾਬੀ"), "pl": ("Polish", "Polski"),
    "ps": ("Pashto", "پښتو"), "pt": ("Portuguese", "Português"), "ro": ("Romanian", "Română"),
    "ru": ("Russian", "Русский"), "sd": ("Sindhi", "سنڌي"), "si": ("Sinhala", "සිංහල"),
    "sk": ("Slovak", "Slovenčina"), "sl": ("Slovenian", "Slovenščina"), "so": ("Somali", "Soomaali"),
    "sq": ("Albanian", "Shqip"), "sr": ("Serbian", "Српски"), "sv": ("Swedish", "Svenska"),
    "sw": ("Swahili", "Kiswahili"), "ta": ("Tamil", "தமிழ்"), "te": ("Telugu", "తెలుగు"),
    "tg": ("Tajik", "Тоҷикӣ"), "th": ("Thai", "ไทย"), "tl": ("Tagalog", "Tagalog"),
    "tr": ("Turkish", "Türkçe"), "tt": ("Tatar", "Татарча"), "ug": ("Uyghur", "ئۇيغۇرچە"),
    "uk": ("Ukrainian", "Українська"), "ur": ("Urdu", "اردو"), "uz": ("Uzbek", "Oʻzbekcha"),
    "vi": ("Vietnamese", "Tiếng Việt"), "xh": ("Xhosa", "isiXhosa"), "yi": ("Yiddish", "ייִדיש"),
    "yo": ("Yoruba", "Yorùbá"), "zh": ("Chinese (Simplified)", "简体中文"),
    "zh-Hans": ("Chinese (Simplified)", "简体中文"), "zh-Hant": ("Chinese (Traditional)", "繁體中文"),
    "zu": ("Zulu", "isiZulu"),
}
RTL = {"ar", "fa", "he", "ur", "ps", "sd", "ckb", "ug", "yi", "dv"}


def get(url, retries=3):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "verto-pack-builder"})
            with urllib.request.urlopen(req, timeout=180) as r:
                return r.read(), r.headers
        except Exception as e:  # noqa: BLE001
            if attempt == retries - 1:
                raise
            print(f"  retry after error: {e}")
            time.sleep(3)


# ---------------------------------------------------------------- records

def version_key(v):
    """(1, 2, 0) for '1.2', or None for anything that is not plain numbers."""
    parts = str(v).split(".")
    if not parts or not all(p.isdigit() for p in parts):
        return None
    return tuple(int(p) for p in parts)


def base_version_key(v):
    """'1.0b1' -> ((1, 0), 'b'); '2.1' -> ((2, 1), ''); '1.0a3' -> ((1, 0), 'a')."""
    v = str(v)
    for i, ch in enumerate(v):
        if ch.isalpha():
            num, tag = v[:i], ch.lower()
            break
    else:
        num, tag = v, ""
    k = version_key(num.rstrip("."))
    return (k, tag) if k is not None else (None, None)


def channel_of(version, filter_expression):
    """'release', 'beta' or 'nightly' for one record."""
    f = filter_expression or ""
    if "nightly" in f or "'default'" in f:
        return "nightly"
    if "!= 'release'" in f or '!= "release"' in f:
        return "beta"
    _, tag = base_version_key(version)
    if tag == "a":
        return "nightly"
    if tag in ("b", "r"):  # 'rc' counts as beta too
        return "beta"
    return "release"


def platform_of(filter_expression):
    """'any', 'android' or 'desktop'."""
    f = (filter_expression or "").replace('"', "'")
    if "OS != 'Android'" in f:
        return "desktop"
    if "OS == 'Android'" in f:
        return "android"
    return "any"


def normalize(record, collection):
    """Common shape for v1 and v2 records, or None when unusable."""
    src = record.get("sourceLanguage") or record.get("fromLang")
    dst = record.get("targetLanguage") or record.get("toLang")
    ftype = record.get("fileType")
    att = record.get("attachment") or {}
    if not src or not dst or ftype not in ROLE_FILE or not att.get("location"):
        return None
    version = str(record.get("version", ""))
    k, _ = base_version_key(version)
    if k is None:
        return None
    return {
        "src": src,
        "dst": dst,
        "type": ftype,
        "version": version,
        "vkey": k,
        "arch": record.get("architecture") or "legacy",
        "variant": record.get("variant") or "",
        "channel": channel_of(version, record.get("filter_expression")),
        "platform": platform_of(record.get("filter_expression")),
        "collection": collection,
        "location": att["location"],
        "hash": att.get("hash"),
        "decompressedHash": record.get("decompressedHash"),
    }


def load_records(collection):
    records = []
    url = f"{ROOT}buckets/main/collections/{collection}/records?_limit=2000"
    while url:
        body, headers = get(url)
        records += json.loads(body)["data"]
        url = headers.get("Next-Page")
    return records


# ---------------------------------------------------------------- choosing

def complete(files):
    """files: fileType -> record. Returns the usable subset or None."""
    if "model" not in files or "lex" not in files:
        return None
    out = {"model": files["model"], "lex": files["lex"]}
    if "vocab" in files:
        out["vocab"] = files["vocab"]
    elif "srcvocab" in files and "trgvocab" in files:
        out["srcvocab"] = files["srcvocab"]
        out["trgvocab"] = files["trgvocab"]
    else:
        return None
    return out


def rank(group):
    """Sort key; smaller is better."""
    channel = {"release": 0, "beta": 1}[group["channel"]]
    platform = {"android": 0, "any": 0, "desktop": 1}[group["platform"]]
    arch = ARCH_ORDER.index(group["arch"]) if group["arch"] in ARCH_ORDER else len(ARCH_ORDER)
    collection = COLLECTIONS.index(group["collection"])
    # newest version first -> negate
    version = tuple(-x for x in group["vkey"])
    return (channel, platform, collection, arch, version)


def pick(records, src, dst, allow_beta=True):
    """Best complete model set for one direction, or None.

    Returns {"files": {fileType: record}, "arch", "version", "channel", "collection"}.
    All files of a set share collection, architecture, variant, version, channel and platform.
    """
    groups = {}
    for r in records:
        if r["src"] != src or r["dst"] != dst:
            continue
        if r["channel"] == "nightly" or (r["channel"] == "beta" and not allow_beta):
            continue
        key = (r["collection"], r["arch"], r["variant"], r["version"], r["channel"], r["platform"])
        g = groups.setdefault(key, {
            "collection": r["collection"], "arch": r["arch"], "variant": r["variant"],
            "version": r["version"], "vkey": r["vkey"], "channel": r["channel"],
            "platform": r["platform"], "files": {},
        })
        g["files"][r["type"]] = r
    usable = []
    for g in groups.values():
        files = complete(g["files"])
        if files:
            g["files"] = files
            usable.append(g)
    if not usable:
        return None
    usable.sort(key=rank)
    return usable[0]


def languages(records):
    """Every X that appears with English, and the reason it may be unusable."""
    codes = set()
    for r in records:
        if r["src"] == "en" and r["dst"] != "en":
            codes.add(r["dst"])
        elif r["dst"] == "en" and r["src"] != "en":
            codes.add(r["src"])
    return sorted(codes)


# ---------------------------------------------------------------- files

def sha256(b):
    return hashlib.sha256(b).hexdigest()


def decompress(raw):
    if raw[:2] == b"\x1f\x8b":
        return gzip.decompress(raw)
    if raw[:4] == b"\x28\xb5\x2f\xfd":
        try:
            import zstandard  # type: ignore

            return zstandard.ZstdDecompressor().decompressobj().decompress(raw)
        except ImportError:
            if not shutil.which("zstd"):
                raise SystemExit("zstd file found but neither the zstandard module nor the zstd tool is installed")
            return subprocess.run(["zstd", "-d", "-c"], input=raw, stdout=subprocess.PIPE, check=True).stdout
    return raw


def fetch(base_url, rec):
    raw, _ = get(base_url + rec["location"])
    if rec["hash"] and sha256(raw) != rec["hash"]:
        raise RuntimeError(f"hash mismatch for {rec['location']}")
    data = decompress(raw)
    if rec["decompressedHash"] and sha256(data) != rec["decompressedHash"]:
        raise RuntimeError(f"decompressed hash mismatch for {rec['location']}")
    return data


# ---------------------------------------------------------------- main

def summary(lines):
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    allow_beta = os.environ.get("VERTO_NO_BETA", "") != "1"

    base_url = json.loads(get(ROOT)[0])["capabilities"]["attachments"]["base_url"]
    records = []
    for collection in COLLECTIONS:
        try:
            raw = load_records(collection)
        except Exception as e:  # noqa: BLE001
            print(f"Collection {collection} not readable: {e}")
            continue
        usable = [n for n in (normalize(r, collection) for r in raw) if n]
        print(f"{collection}: {len(raw)} records, {len(usable)} usable")
        records += usable
    if not records:
        raise SystemExit("No model records found.")

    wanted = sys.argv[2:]
    one_way = []
    if not wanted:
        for code in languages(records):
            there = pick(records, "en", code, allow_beta)
            back = pick(records, code, "en", allow_beta)
            if there and back:
                wanted.append(code)
            else:
                one_way.append(f"{code} ({'en->' + code if there else code + '->en' if back else 'beta/nightly only'})")
        print("Languages found:", " ".join(wanted))
        print(f"Total: {len(wanted)}")
        if one_way:
            print("Not usable (missing a direction or only nightly):", ", ".join(one_way))

    previous = {}
    repo = os.environ.get("GITHUB_REPOSITORY")
    if repo:
        try:
            body, _ = get(f"https://github.com/{repo}/releases/download/packs/manifest.json", retries=1)
            previous = json.loads(body).get("packs", {})
        except Exception:  # noqa: BLE001
            print("No previous manifest (first run)")

    packs = dict(previous)
    built, failed, table = 0, [], []
    for code in wanted:
        print(f"== {code}")
        files, info, ok = [], [], True
        written = []
        for src, dst in (("en", code), (code, "en")):
            chosen = pick(records, src, dst, allow_beta)
            if chosen is None:
                print(f"  SKIPPED {code}: no complete model for {src}->{dst}")
                ok = False
                break
            direction = f"{src}-{dst}"
            info.append(f"{direction} {chosen['arch']} v{chosen['version']} {chosen['channel']}")
            try:
                for role, rec in sorted(chosen["files"].items()):
                    data = fetch(base_url, rec)
                    name = f"{direction}.{ROLE_FILE[role]}"
                    with open(os.path.join(out, name), "wb") as f:
                        f.write(data)
                    written.append(name)
                    files.append({
                        "name": name,
                        "path": f"{direction}/{ROLE_FILE[role]}",
                        "size": len(data),
                        "sha256": sha256(data),
                    })
                    print(f"  {name}: {len(data) / 1e6:.1f} MB ({chosen['arch']} v{chosen['version']}, {chosen['channel']})")
            except Exception as e:  # noqa: BLE001
                print(f"  FAILED {code}: {e}")
                failed.append(code)
                ok = False
                break
            if chosen["channel"] == "beta":
                info.append("beta")
        if not ok:
            for n in written:
                p = os.path.join(out, n)
                if os.path.exists(p):
                    os.remove(p)
            continue
        beta = "beta" in info
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
            "beta": beta,
            "files": files,
        }
        size = sum(f["size"] for f in files)
        table.append(f"| {code} | {name} | {size / 1e6:.0f} MB | {'; '.join(i for i in info if i != 'beta')} |")
        built += 1

    if built == 0:
        raise SystemExit("No pack was built.")
    with open(os.path.join(out, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"schema": 1, "generated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "packs": packs},
                  f, indent=1, ensure_ascii=False)
    print(f"Built {built} pack(s). Manifest lists {len(packs)} language(s).")
    if failed:
        print("Failed:", " ".join(failed))

    summary([
        f"## Language packs: {built} built, {len(packs)} in the app list",
        "",
        "| Code | Language | Size | Models |",
        "| --- | --- | --- | --- |",
        *table,
        "",
        f"Failed: {' '.join(failed) or 'none'}",
        f"Not usable: {', '.join(one_way) or 'none'}",
    ])


if __name__ == "__main__":
    main()
