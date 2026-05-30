import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/models/transaction_model.dart';
import 'data/models/budget_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/app_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for the Liquid Vault dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF03251E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  await Hive.openBox(AppConstants.settingsBox); // Persist settings like theme mode

  // Initialize repository (opens Hive boxes)
  final repo = TransactionRepository();
  await repo.init();

  runApp(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
      ],
      child: const PurzeApp(),
    ),
  );
}

class PurzeApp extends ConsumerWidget {
  const PurzeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Purze',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppEntry(),
    );
  }
}
