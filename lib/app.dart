import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/simulation/data/saved_inputs.dart';
import 'features/simulation/ui/dashboard_page.dart';

class SimmoApp extends StatelessWidget {
  const SimmoApp({super.key, this.saved, this.sharedFragment = ''});

  final SavedInputs? saved;

  /// Fragment of the opening URL (a shared simulation).
  final String sharedFragment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simmo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // French only for now: Material widgets (date pickers, number
      // separators) follow the French conventions.
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: DashboardPage(saved: saved, sharedFragment: sharedFragment),
    );
  }
}
