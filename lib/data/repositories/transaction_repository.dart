import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../../core/constants/app_constants.dart';

class TransactionRepository {
  late Box<TransactionModel> _transactionBox;
  late Box<BudgetModel> _budgetBox;

  Future<void> init() async {
    _transactionBox = await Hive.openBox<TransactionModel>(AppConstants.transactionBox);
    _budgetBox = await Hive.openBox<BudgetModel>(AppConstants.budgetBox);

    // Intentionally do not seed any data; a fresh install should start empty.
  }

  List<TransactionModel> getAllTransactions() {
    final list = _transactionBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<TransactionModel> getTransactionsByCategory(int categoryIndex) {
    return getAllTransactions()
        .where((t) => t.categoryIndex == categoryIndex)
        .toList();
  }

  List<TransactionModel> getTransactionsForMonth(DateTime month) {
    return getAllTransactions().where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  // ─── Budgets ───

  List<BudgetModel> getAllBudgets() {
    return _budgetBox.values.toList();
  }

  BudgetModel? getBudget(int categoryIndex) {
    return _budgetBox.get(categoryIndex);
  }

  Future<void> updateBudgetLimit(int categoryIndex, double limit) async {
    final budget = _budgetBox.get(categoryIndex);
    if (budget != null) {
      budget.monthlyLimit = limit;
      await budget.save();
    } else {
      final newBudget = BudgetModel(
        categoryIndex: categoryIndex,
        monthlyLimit: limit,
      );
      await _budgetBox.put(categoryIndex, newBudget);
    }
  }

  double getTotalSpentThisMonth() {
    final now = DateTime.now();
    return getAllTransactions()
        .where((t) =>
            t.isDebit &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalBudget() {
    return getAllBudgets().fold(0.0, (sum, b) => sum + b.monthlyLimit);
  }

  Map<int, double> getSpendingByCategory() {
    final now = DateTime.now();
    final transactions = getAllTransactions().where((t) =>
        t.isDebit &&
        t.date.year == now.year &&
        t.date.month == now.month);

    final map = <int, double>{};
    for (final t in transactions) {
      map[t.categoryIndex] = (map[t.categoryIndex] ?? 0) + t.amount;
    }
    return map;
  }

  Map<int, double> getWeeklySpending() {
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final transactions = getAllTransactions()
        .where((t) => t.isDebit && t.date.isAfter(fourWeeksAgo));

    final weeklyMap = <int, double>{};
    for (final t in transactions) {
      final weekIndex = (now.difference(t.date).inDays / 7).floor();
      weeklyMap[weekIndex] = (weeklyMap[weekIndex] ?? 0) + t.amount;
    }
    return weeklyMap;
  }

  Future<void> clearAllData() async {
    await _transactionBox.clear();
    await _budgetBox.clear();
  }
}
