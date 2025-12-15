import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/routing/app_router.dart';
import 'package:incontext/core/theme/app_theme.dart';
import 'package:incontext/core/widgets/globals.dart';
import 'package:incontext/features/l10n/l10n.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(routerProvider);

    return Globals(
      child: MaterialApp.router(
        title: 'InContext',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        onGenerateTitle: L10n.onGenerateTitle,
      ),
    );
  }
}
