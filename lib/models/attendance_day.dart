import 'package:hive/hive.dart';

part 'debt.g.dart'; // This will be generated

@HiveType(typeId: 2) // Task is 0, Transaction is 1
class Debt extends HiveObject {

  @HiveField(0)
  String name; // Who?

  @HiveField(1)
  double amount; // How much?

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  bool isOwedToMe; // true = They owe me, false = I owe them

  @HiveField(4)
  bool isSettled; // The checkbox

  Debt({
    required this.name,
    required this.amount,
    required this.createdAt,
    required this.isOwedToMe,
    this.isSettled = false,
  });
}
