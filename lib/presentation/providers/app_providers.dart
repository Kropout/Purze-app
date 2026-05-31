import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_model.dart';
import '../../domain/entities/category.dart';

// ─── Repository Provider ───
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// ─── Onboarding ───
final hasOnboardedProvider = StateNotifierProvider<HasOnboardedNotifier, bool>((ref) {
  return HasOnboardedNotifier();
});

class HasOnboardedNotifier extends StateNotifier<bool> {
  HasOnboardedNotifier() : super(_readInitial());

  static bool _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return box.get(AppConstants.hasOnboardedKey, defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  Future<void> complete() async {
    state = true;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.hasOnboardedKey, true);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = false;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.hasOnboardedKey, false);
    } catch (_) {}
  }
}

// ─── User Profile ───
final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  return UserNameNotifier();
});

class UserNameNotifier extends StateNotifier<String> {
  UserNameNotifier() : super(_readInitial());

  static String _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return (box.get(AppConstants.userNameKey) as String?)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> setName(String value) async {
    final name = value.trim();
    state = name;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.userNameKey, name);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = '';
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.delete(AppConstants.userNameKey);
    } catch (_) {}
  }
}

final userPhoneProvider = StateNotifierProvider<UserPhoneNotifier, String>((ref) {
  return UserPhoneNotifier();
});

class UserPhoneNotifier extends StateNotifier<String> {
  UserPhoneNotifier() : super(_readInitial());

  static String _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return (box.get(AppConstants.userPhoneKey) as String?)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> setPhone(String value) async {
    final phone = value.trim();
    state = phone;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.userPhoneKey, phone);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = '';
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.delete(AppConstants.userPhoneKey);
    } catch (_) {}
  }
}

final accentColorValueProvider = StateNotifierProvider<AccentColorNotifier, int>((ref) {
  return AccentColorNotifier();
});

final accentColorProvider = Provider<Color>((ref) {
  return Color(ref.watch(accentColorValueProvider));
});

class AccentColorNotifier extends StateNotifier<int> {
  AccentColorNotifier() : super(_readInitial());

  static int _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return box.get(
        AppConstants.accentColorKey,
        defaultValue: AppColors.primary.toARGB32(),
      ) as int;
    } catch (_) {
      return AppColors.primary.toARGB32();
    }
  }

  Future<void> setAccentColorValue(int value) async {
    state = value;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.accentColorKey, value);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = AppColors.primary.toARGB32();
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.delete(AppConstants.accentColorKey);
    } catch (_) {}
  }
}

final currencySymbolProvider = StateNotifierProvider<CurrencySymbolNotifier, String>((ref) {
  return CurrencySymbolNotifier();
});

class CurrencySymbolNotifier extends StateNotifier<String> {
  CurrencySymbolNotifier() : super(_readInitial());

  static String _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return (box.get(AppConstants.currencySymbolKey) as String?)?.trim() ?? AppConstants.defaultCurrencySymbol;
    } catch (_) {
      return AppConstants.defaultCurrencySymbol;
    }
  }

  Future<void> setSymbol(String symbol) async {
    final sanitized = symbol.trim().isEmpty ? AppConstants.defaultCurrencySymbol : symbol.trim();
    state = sanitized;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.currencySymbolKey, sanitized);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = AppConstants.defaultCurrencySymbol;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.delete(AppConstants.currencySymbolKey);
    } catch (_) {}
  }
}

// ─── Monthly Budget (overall) ───
final monthlyBudgetProvider = StateNotifierProvider<MonthlyBudgetNotifier, double>((ref) {
  return MonthlyBudgetNotifier();
});

class MonthlyBudgetNotifier extends StateNotifier<double> {
  MonthlyBudgetNotifier() : super(_readInitial());

  static double _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final val = box.get(AppConstants.monthlyBudgetKey, defaultValue: 0);
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setBudget(double value) async {
    final double base = value.isFinite ? value : 0.0;
    final double sanitized = base.clamp(0.0, AppConstants.maxMonthlyBudget.toDouble());
    state = sanitized;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.monthlyBudgetKey, sanitized);
    } catch (_) {}
  }
}

// ─── All Transactions ───
final allTransactionsProvider = NotifierProvider<TransactionListNotifier, List<TransactionModel>>(() {
  return TransactionListNotifier();
});

class TransactionListNotifier extends Notifier<List<TransactionModel>> {
  late TransactionRepository _repo;

  @override
  List<TransactionModel> build() {
    _repo = ref.watch(transactionRepositoryProvider);
    return _repo.getAllTransactions();
  }

  void refresh() {
    state = _repo.getAllTransactions();
  }

  Future<void> add(TransactionModel transaction) async {
    await _repo.addTransaction(transaction);
    refresh();
  }

  Future<void> remove(String id) async {
    await _repo.deleteTransaction(id);
    refresh();
  }
}

// ─── Filtered Transactions ───
final selectedCategoryFilterProvider = StateProvider<TransactionCategory?>((ref) => null);

final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final all = ref.watch(allTransactionsProvider);
  final filter = ref.watch(selectedCategoryFilterProvider);
  if (filter == null) return all;
  return all.where((t) => t.categoryIndex == filter.index).toList();
});

// ─── Search ───
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchedTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final filtered = ref.watch(filteredTransactionsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return filtered;
  return filtered.where((t) =>
      t.merchant.toLowerCase().contains(query) ||
      t.amount.toString().contains(query)).toList();
});

// ─── Budgets ───
final allBudgetsProvider = NotifierProvider<BudgetListNotifier, List<BudgetModel>>(() {
  return BudgetListNotifier();
});

class BudgetListNotifier extends Notifier<List<BudgetModel>> {
  late TransactionRepository _repo;

  @override
  List<BudgetModel> build() {
    _repo = ref.watch(transactionRepositoryProvider);
    return _repo.getAllBudgets();
  }

  void refresh() {
    state = _repo.getAllBudgets();
  }

  Future<void> updateLimit(int categoryIndex, double limit) async {
    await _repo.updateBudgetLimit(categoryIndex, limit);
    refresh();
  }
}

// ─── Analytics ───
final totalSpentProvider = Provider<double>((ref) {
  // Recompute when transactions change.
  ref.watch(allTransactionsProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTotalSpentThisMonth();
});

final totalBudgetProvider = Provider<double>((ref) {
  // Overall monthly budget is stored in Hive settings.
  return ref.watch(monthlyBudgetProvider);
});

final spendingByCategoryProvider = Provider<Map<int, double>>((ref) {
  // Recompute when transactions change.
  ref.watch(allTransactionsProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getSpendingByCategory();
});

final weeklySpendingProvider = Provider<Map<int, double>>((ref) {
  // Recompute when transactions change.
  ref.watch(allTransactionsProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getWeeklySpending();
});

// ─── Navigation ───
final selectedTabProvider = StateProvider<int>((ref) => 0);

// ─── Starting Balance (for estimated available balance) ───
final startingBalanceProvider = StateNotifierProvider<StartingBalanceNotifier, double>((ref) {
  return StartingBalanceNotifier();
});

class StartingBalanceNotifier extends StateNotifier<double> {
  StartingBalanceNotifier() : super(_readInitial());

  static double _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final val = box.get(AppConstants.startingBalanceKey, defaultValue: 0);
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> setStartingBalance(double value) async {
    final double sanitized = value.isFinite ? value : 0.0;
    state = sanitized;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.startingBalanceKey, sanitized);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = 0.0;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.delete(AppConstants.startingBalanceKey);
    } catch (_) {}
  }
}


// ─── Estimated Balance ───
final estimatedBalanceProvider = Provider<double>((ref) {
  final starting = ref.watch(startingBalanceProvider);
  final all = ref.watch(allTransactionsProvider);
  final credits = all.where((t) => !t.isDebit).fold(0.0, (sum, t) => sum + t.amount);
  final debits = all.where((t) => t.isDebit).fold(0.0, (sum, t) => sum + t.amount);
  return starting + credits - debits;
});

// ─── Selected Month for Analytics ───
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ─── Theme Mode Provider ───
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final isDark = box.get('isDarkMode', defaultValue: true) as bool;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      state = ThemeMode.dark;
    }
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put('isDarkMode', !isDark);
    } catch (_) {}
  }
}

// ─── PIN & Biometric Auth ───

final pinAuthProvider = Provider<PinAuth>((ref) {
  return PinAuth(ref: ref);
});

class LockTimeoutNotifier extends StateNotifier<int> {
  LockTimeoutNotifier() : super(_readInitial());

  static int _readInitial() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return box.get(AppConstants.lockTimeoutKey, defaultValue: 5) as int;
    } catch (_) {
      return 5;
    }
  }

  Future<void> setTimeoutMinutes(int minutes) async {
    state = minutes;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(AppConstants.lockTimeoutKey, minutes);
    } catch (_) {}
  }
}

final lockTimeoutProvider = StateNotifierProvider<LockTimeoutNotifier, int>((ref) {
  return LockTimeoutNotifier();
});

class PinAuth {
  final Ref ref;
  PinAuth({required this.ref});

  Box get _box => Hive.box(AppConstants.settingsBox);

  bool isPinSet() {
    final s = _box.get(AppConstants.pinHashKey) as String?;
    return s != null && s.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _box.put(AppConstants.pinHashKey, hash);
    await _box.put(AppConstants.failedAttemptsKey, 0);
    await _box.delete(AppConstants.lockUntilKey);
    await _box.flush();
  }

  Future<bool> verifyPin(String pin) async {
    final stored = (_box.get(AppConstants.pinHashKey) as String?)?.trim();
    if (stored == null || stored.isEmpty) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    if (hash == stored) {
      await _box.put(AppConstants.failedAttemptsKey, 0);
      await _box.delete(AppConstants.lockUntilKey);
      await _box.flush();
      return true;
    }

    final attempts = (_box.get(AppConstants.failedAttemptsKey, defaultValue: 0) as int) + 1;
    await _box.put(AppConstants.failedAttemptsKey, attempts);
    if (attempts >= 5) {
      final lockUntil = DateTime.now().add(const Duration(seconds: 30));
      await _box.put(AppConstants.lockUntilKey, lockUntil.toIso8601String());
      await _box.put(AppConstants.failedAttemptsKey, 0);
    }
    await _box.flush();
    return false;
  }

  bool isLocked() {
    final s = _box.get(AppConstants.lockUntilKey) as String?;
    if (s == null) return false;
    try {
      final until = DateTime.parse(s);
      return DateTime.now().isBefore(until);
    } catch (_) {
      return false;
    }
  }

  int lockedSecondsRemaining() {
    final s = _box.get(AppConstants.lockUntilKey) as String?;
    if (s == null) return 0;
    try {
      final until = DateTime.parse(s);
      final diff = until.difference(DateTime.now());
      return diff.isNegative ? 0 : diff.inSeconds;
    } catch (_) {
      return 0;
    }
  }

  bool isBiometricEnabled() {
    return _box.get(AppConstants.biometricEnabledKey, defaultValue: false) as bool;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _box.put(AppConstants.biometricEnabledKey, enabled);
    await _box.flush();
  }

  Future<void> clearPin() async {
    await _box.delete(AppConstants.pinHashKey);
    await _box.delete(AppConstants.failedAttemptsKey);
    await _box.delete(AppConstants.lockUntilKey);
    await _box.delete(AppConstants.biometricEnabledKey);
    await _box.flush();
  }

  Future<void> updateLastActive() async {
    try {
      await _box.put(AppConstants.lastActiveKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  DateTime? getLastActive() {
    try {
      final s = _box.get(AppConstants.lastActiveKey) as String?;
      if (s == null) return null;
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
