// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      merchant: fields[2] as String,
      categoryIndex: fields[3] as int,
      date: fields[4] as DateTime,
      isDebit: fields[5] as bool,
      rawSmsText: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.merchant)
      ..writeByte(3)
      ..write(obj.categoryIndex)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.isDebit)
      ..writeByte(6)
      ..write(obj.rawSmsText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
