import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/core/routing/app_router.dart';
import 'package:connexa/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

/// Root Material 3 application widget for Connexa.
class ConnexaApp extends ConsumerWidget {
  const ConnexaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Connexa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
