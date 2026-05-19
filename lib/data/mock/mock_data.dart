import '../models/transaction_model.dart';
import '../../domain/entities/category.dart';
import 'package:uuid/uuid.dart';

class MockData {
  static const _uuid = Uuid();

  static List<TransactionModel> getMockTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: _uuid.v4(),
        amount: 349,
        merchant: 'Swiggy',
        categoryIndex: TransactionCategory.food.index,
        date: now.subtract(const Duration(hours: 2)),
        isDebit: true,
        rawSmsText: 'INR 349.00 debited from A/c XX1234 to Swiggy via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 520,
        merchant: 'Zomato',
        categoryIndex: TransactionCategory.food.index,
        date: now.subtract(const Duration(hours: 8)),
        isDebit: true,
        rawSmsText: 'INR 520.00 debited from A/c XX1234 to Zomato via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 2150,
        merchant: 'IRCTC',
        categoryIndex: TransactionCategory.travel.index,
        date: now.subtract(const Duration(days: 1)),
        isDebit: true,
        rawSmsText: 'INR 2150.00 debited from A/c XX1234 to IRCTC eTicket via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 1499,
        merchant: 'Amazon India',
        categoryIndex: TransactionCategory.shopping.index,
        date: now.subtract(const Duration(days: 1, hours: 5)),
        isDebit: true,
        rawSmsText: 'INR 1499.00 debited from A/c XX1234 to Amazon Pay via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 875,
        merchant: 'BigBasket',
        categoryIndex: TransactionCategory.food.index,
        date: now.subtract(const Duration(days: 2)),
        isDebit: true,
        rawSmsText: 'INR 875.00 debited from A/c XX1234 to BigBasket via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 25000,
        merchant: 'Salary Credit',
        categoryIndex: TransactionCategory.other.index,
        date: now.subtract(const Duration(days: 2, hours: 3)),
        isDebit: false,
        rawSmsText: 'INR 25000.00 credited to A/c XX1234 via NEFT',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 499,
        merchant: 'Netflix India',
        categoryIndex: TransactionCategory.entertainment.index,
        date: now.subtract(const Duration(days: 3)),
        isDebit: true,
        rawSmsText: 'INR 499.00 debited from A/c XX1234 to Netflix via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 1200,
        merchant: 'Uber India',
        categoryIndex: TransactionCategory.travel.index,
        date: now.subtract(const Duration(days: 3, hours: 6)),
        isDebit: true,
        rawSmsText: 'INR 1200.00 debited from A/c XX1234 to Uber via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 750,
        merchant: 'Apollo Pharmacy',
        categoryIndex: TransactionCategory.health.index,
        date: now.subtract(const Duration(days: 4)),
        isDebit: true,
        rawSmsText: 'INR 750.00 debited from A/c XX1234 to Apollo Pharmacy via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 2399,
        merchant: 'Flipkart',
        categoryIndex: TransactionCategory.shopping.index,
        date: now.subtract(const Duration(days: 4, hours: 2)),
        isDebit: true,
        rawSmsText: 'INR 2399.00 debited from A/c XX1234 to Flipkart via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 1800,
        merchant: 'Jio Recharge',
        categoryIndex: TransactionCategory.bills.index,
        date: now.subtract(const Duration(days: 5)),
        isDebit: true,
        rawSmsText: 'INR 1800.00 debited from A/c XX1234 to Jio Recharge via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 5000,
        merchant: 'PhonePe Transfer',
        categoryIndex: TransactionCategory.other.index,
        date: now.subtract(const Duration(days: 5, hours: 4)),
        isDebit: false,
        rawSmsText: 'INR 5000.00 credited to A/c XX1234 from PhonePe',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 3500,
        merchant: 'Electricity Bill',
        categoryIndex: TransactionCategory.bills.index,
        date: now.subtract(const Duration(days: 6)),
        isDebit: true,
        rawSmsText: 'INR 3500.00 debited from A/c XX1234 to TATA Power via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 199,
        merchant: 'Chai Point',
        categoryIndex: TransactionCategory.food.index,
        date: now.subtract(const Duration(days: 6, hours: 8)),
        isDebit: true,
        rawSmsText: 'INR 199.00 debited from A/c XX1234 to Chai Point via UPI',
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 899,
        merchant: 'Myntra',
        categoryIndex: TransactionCategory.shopping.index,
        date: now.subtract(const Duration(days: 7)),
        isDebit: true,
        rawSmsText: 'INR 899.00 debited from A/c XX1234 to Myntra via UPI',
      ),
    ];
  }

  static Map<int, double> getDefaultBudgets() {
    return {
      TransactionCategory.food.index: 8000,
      TransactionCategory.travel.index: 5000,
      TransactionCategory.shopping.index: 10000,
      TransactionCategory.bills.index: 8000,
      TransactionCategory.entertainment.index: 3000,
      TransactionCategory.health.index: 5000,
      TransactionCategory.other.index: 10000,
    };
  }
}
