class AppConstants {
  AppConstants._();

  static const String appName = 'Purze';

  // Defaults (user can override in Settings)
  static const String defaultCurrencySymbol = '₹';

  static const String transactionBox = 'transactions';
  static const String budgetBox = 'budgets';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String userNameKey = 'userName';
  static const String userPhoneKey = 'userPhone';
  static const String monthlyBudgetKey = 'monthlyBudget';
  static const String accentColorKey = 'accentColor';
  static const String currencySymbolKey = 'currencySymbol';
  static const String hasOnboardedKey = 'hasOnboarded';
  static const String startingBalanceKey = 'startingBalance';
  static const String lastSmsSyncKey = 'lastSmsSync';

  // Validation limits
  static const int maxNameLength = 20;
  static const int maxMonthlyBudget = 1000000; // ₹10,00,000
}
