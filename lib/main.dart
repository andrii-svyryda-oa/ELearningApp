import 'package:e_learning_app/core/services/local_storage_service.dart';
import 'package:e_learning_app/core/theme/app_theme.dart';
import 'package:e_learning_app/core/theme/theme_provider.dart';
import 'package:e_learning_app/core/utils/locale_provider.dart';
import 'package:e_learning_app/core/utils/router.dart';
import 'package:e_learning_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  await LocalStorageService.init();

  runApp(const ProviderScope(child: ELearningApp()));
}

class ELearningApp extends ConsumerWidget {
  const ELearningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'E-Learning App',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization configuration
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('uk'), // Ukrainian
      ],

      // Router configuration
      routerConfig: router,
    );
  }
}
