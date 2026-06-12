import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_registry.dart';
import 'data/models/transaction_model.dart';
import 'data/models/budget_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/services/mock_sms_provider.dart';
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

  if (kIsWeb) {
    final mockTransactions = await MockSmsProvider.getMockTransactions();
    for (final tx in mockTransactions) {
      await repo.addTransaction(tx);
    }
  }

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
    final themeId = ref.watch(appThemeIdProvider);

    return MaterialApp(
      title: 'Purze',
      debugShowCheckedModeBanner: false,
      theme: ThemeRegistry.themeFor(themeId, brightness: Brightness.light),
      darkTheme: ThemeRegistry.themeFor(themeId, brightness: Brightness.dark),
      themeMode: themeMode,
      home: const AppEntry(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            gestureSettings: const DeviceGestureSettings(touchSlop: 4.0),
          ),
          child: child!,
        );
      },
    );
  }
}


