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
