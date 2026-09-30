import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/simulation/data/saved_inputs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Plain paths (`/simulation`), not `/#/simulation`. Vercel's catch-all
  // rewrite to index.html (vercel.json) exists to support this.
  usePathUrlStrategy();
  _registerFontLicence();
  final saved = SavedInputs(await SharedPreferences.getInstance());
  runApp(SimmoApp(saved: saved));
}

/// The font is bundled as an asset, not a Dart package, so Flutter's licence
/// page would miss it without this.
void _registerFontLicence() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Plus Jakarta Sans'],
      await rootBundle.loadString('assets/fonts/LICENSE-plus-jakarta-sans.txt'),
    );
  });
}
