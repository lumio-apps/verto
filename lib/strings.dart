/// All user-visible text in one place.
class S {
  static const String appName = 'Verto';
  static const String tagline = 'Private. Offline. Fast.';

  static const String navTranslate = 'Translate';
  static const String navLanguages = 'Languages';

  static const String inputHint = 'Type or paste text';
  static const String outputEmpty = 'Your translation appears here';
  static const String engineStarting = 'Getting the translator ready...';
  static const String engineFailed = 'The translator could not start.';
  static const String retry = 'Try again';
  static const String copy = 'Copy';
  static const String share = 'Share';
  static const String copied = 'Copied';
  static const String recent = 'Recent';
  static const String swap = 'Swap languages';

  static const String noLanguageTitle = 'Download a language to start';
  static const String noLanguageBody =
      'English is built in. Download one language and you can translate to and from English, without internet.';
  static const String openLanguages = 'Choose a language';
  static const String pickLanguage = 'Choose language';
  static const String getMoreLanguages = 'Get more languages';

  static const String checkingWords = 'Checking every word...';
  static String allCovered(int n) => n == 1 ? 'The word is covered' : 'All $n words covered';
  static String partlyChecked(int checked, int total) => 'Checked $checked of $total words';
  static String wordsToCheck(int n) => n == 1 ? '1 word to check' : '$n words to check';
  static const String tapWordHint = 'Tap a word to see how it translates on its own.';

  static const String wordSheetTitle = 'Check word';
  static const String wordSheetSource = 'Word-by-word translation';
  static const String wordSheetBody =
      'This word may be missing from the translation above.';
  static const String addToTranslation = 'Add to translation';
  static const String keepAsIs = 'Keep as is';

  static const String languagesTitle = 'Languages';
  static const String languagesIntro =
      'Download a language once. It works in both directions with English.';
  static const String englishBuiltIn = 'Built in';
  static const String get = 'Get';
  static const String update = 'Update';
  static const String remove = 'Remove';
  static const String cancel = 'Cancel';
  static const String notPublished = 'Not available yet';
  static const String installed = 'Installed';
  static const String updateAvailable = 'Update available';
  static const String refreshList = 'Refresh list';
  static String removeTitle(String name) => 'Remove $name?';
  static const String removeBody =
      'The language pack is deleted from this phone. Your history and settings stay. You can download it again any time.';

  static const String appUpdateTitle = 'App version';
  static const String checkForUpdate = 'Check for update';
  static const String checking = 'Checking...';
  static const String upToDate = 'You have the latest version';
  static String updateReady(String v) => 'Version $v is ready';
  static const String updateNow = 'Update now';
  static const String updateKeepsData = 'Your history, settings and languages are kept.';
  static const String about = 'About and licenses';
}
