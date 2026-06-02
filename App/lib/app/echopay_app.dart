import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/core_providers.dart';
import 'routes.dart';
import 'theme.dart';

/// Root widget. The initial route is decided synchronously from the persisted
/// session (no `setState`/`FutureBuilder` flash on launch) because
/// `SharedPreferences` is loaded before `runApp` and exposed via
/// [sessionStoreProvider].
class EchoPayApp extends ConsumerWidget {
  const EchoPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(sessionStoreProvider).isLoggedIn;
    return MaterialApp(
      title: 'EchoPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: isLoggedIn ? AppRoutes.biometric : AppRoutes.phone,
      routes: AppRoutes.all,
    );
  }
}
