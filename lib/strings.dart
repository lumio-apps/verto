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
  static const String beta = 'Beta';
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

  static const String navHistory = 'History';

  // Result actions
  static const String favorite = 'Save to favourites';
  static const String unfavorite = 'Remove from favourites';
  static const String speak = 'Read aloud';
  static const String stopSpeaking = 'Stop';
  static const String bigText = 'Show in big text';
  static const String paste = 'Paste';
  static const String romanToggle = 'Roman';
  static const String romanOn = 'Showing Roman letters (Hinglish)';

  // Clipboard
  static const String clipboardTitle = 'Translate copied text?';
  static const String clipboardAction = 'Translate';
  static const String clipboardDismiss = 'Not now';

  // Language picker and list
  static const String searchLanguages = 'Search languages';
  static const String noMatch = 'No language found';
  static const String sectionInstalled = 'Installed';
  static const String sectionAvailable = 'Available to download';

  // History
  static const String historyTitle = 'History';
  static const String searchHistory = 'Search history';
  static const String all = 'All';
  static const String favourites = 'Favourites';
  static const String historyEmpty = 'Nothing here yet';
  static const String favouritesEmpty = 'Tap the star on a translation to keep it here';
  static const String saveHistory = 'Save history on this phone';
  static const String saveHistoryHint = 'Stored only on this phone. Favourites are kept even when this is off.';
  static const String clearHistory = 'Clear history';
  static const String clearEverything = 'Clear everything, including favourites';
  static const String clearHistoryBody = 'All saved translations are deleted, except favourites.';
  static const String clearEverythingBody = 'All saved translations and favourites are deleted.';
  static const String delete = 'Delete';
  static String downloadFirst(String name) => 'Download $name first';

  // Storage and settings
  static const String storageTitle = 'Storage';
  static String packsUsed(String size, int count) => 'Language packs: $size ($count)';
  static const String removeAll = 'Remove all';
  static const String removeAllTitle = 'Remove all language packs?';
  static const String removeAllBody =
      'All downloaded languages are deleted from this phone. Your history and settings stay.';
  static String updateFiles(String size) => 'Downloaded update files: $size';
  static const String clear = 'Clear';
  static const String settingsTitle = 'Settings';
  static const String clipboardSetting = 'Offer to translate copied text';
  static const String clipboardSettingHint = 'Checked only when you open Verto. Nothing is sent anywhere.';
}
