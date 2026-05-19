import 'package:hive/hive.dart';
import '../../domain/entities/category.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String merchant;

  @HiveField(3)
  final int categoryIndex; // index into TransactionCategory.values

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final bool isDebit;

  @HiveField(6)
  final String rawSmsText;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.categoryIndex,
    required this.date,
    required this.isDebit,
    this.rawSmsText = '',
  });

  TransactionCategory get category =>
      TransactionCategory.values[categoryIndex];
}
