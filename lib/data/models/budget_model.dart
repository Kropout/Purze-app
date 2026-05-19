import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final int categoryIndex;

  @HiveField(1)
  double monthlyLimit;

  @HiveField(2)
  double currentSpend;

  BudgetModel({
    required this.categoryIndex,
    required this.monthlyLimit,
    this.currentSpend = 0,
  });
}
