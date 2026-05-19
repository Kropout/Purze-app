// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 1;

  @override
  BudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetModel(
      categoryIndex: fields[0] as int,
      monthlyLimit: fields[1] as double,
      currentSpend: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.categoryIndex)
      ..writeByte(1)
      ..write(obj.monthlyLimit)
      ..writeByte(2)
      ..write(obj.currentSpend);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
