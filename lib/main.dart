import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(<String>['Bergamot Translator'],
        'Bergamot Translator (the translation engine, WebAssembly build) is licensed under the '
        'Mozilla Public License 2.0. https://github.com/browsermt/bergamot-translator');
    yield const LicenseEntryWithLineBreaks(<String>['Firefox Translations models'],
        'The language models are published by Mozilla (Firefox Translations) and are licensed under the '
        'Mozilla Public License 2.0. https://github.com/mozilla/firefox-translations-models');
  });
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const VertoApp());
}
