// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FixedExpenseAdapter extends TypeAdapter<FixedExpense> {
  @override
  final int typeId = 2;

  @override
  FixedExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FixedExpense(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      dayOfMonth: fields[3] as int,
      category: fields[4] as String,
      description: fields[5] as String?,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FixedExpense obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dayOfMonth)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
