/// One language Verto can translate. English is always the other side.
class Language {
  const Language({
    required this.code,
    required this.name,
    required this.native,
    this.rtl = false,
  });

  final String code;
  final String name;
  final String native;
  final bool rtl;
}

const Language kEnglish = Language(code: 'en', name: 'English', native: 'English');

/// Every language that pairs with English, in the order shown in the app.
const List<Language> kForeignLanguages = <Language>[
  Language(code: 'hi', name: 'Hindi', native: 'हिन्दी'),
  Language(code: 'es', name: 'Spanish', native: 'Español'),
  Language(code: 'fr', name: 'French', native: 'Français'),
  Language(code: 'de', name: 'German', native: 'Deutsch'),
  Language(code: 'ru', name: 'Russian', native: 'Русский'),
  Language(code: 'ja', name: 'Japanese', native: '日本語'),
  Language(code: 'ar', name: 'Arabic', native: 'العربية', rtl: true),
  Language(code: 'fa', name: 'Persian (Farsi)', native: 'فارسی', rtl: true),
];

Language? languageByCode(String code) {
  if (code == kEnglish.code) return kEnglish;
  for (final l in kForeignLanguages) {
    if (l.code == code) return l;
  }
  return null;
}

/// "52 MB" style size text.
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  final mb = bytes / (1024 * 1024);
  return mb < 100 ? '${mb.toStringAsFixed(0)} MB' : '${(mb / 1024).toStringAsFixed(2)} GB';
}
