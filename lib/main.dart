import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  // Plain paths (`/simulation`), not `/#/simulation`. Vercel's catch-all
  // rewrite to index.html (vercel.json) exists to support this.
  usePathUrlStrategy();
  _registerFontLicence();
  runApp(const SimmoApp());
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
