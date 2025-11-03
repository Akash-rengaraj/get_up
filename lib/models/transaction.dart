import 'package:hive/hive.dart';

part 'transaction.g.dart'; // This will be generated

@HiveType(typeId: 1)
class Transaction extends HiveObject {

  @HiveField(0)
  double amount; // Always a positive number

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String account; // "Cash", "Bank/UPI", "Coins"

  @HiveField(3)
  bool isExpense; // true = expense, false = income

  @HiveField(4)
  String? label; // For expenses: "Coffee". For income: "Income"

  @HiveField(5)
  String? expenseCategory; // "Food", "Bills", etc. Null for income.

  Transaction({
    required this.amount,
    required this.date,
    required this.account,
    required this.isExpense,
    this.label,
    this.expenseCategory,
  });
}