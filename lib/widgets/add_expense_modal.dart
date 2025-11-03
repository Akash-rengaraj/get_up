import 'package:flutter/material.dart';
import 'package:get_up/models/transaction.dart';
import 'package:hive_flutter/hive_flutter.dart';

void showAddExpenseModal(BuildContext context) {
  final transactionBox = Hive.box<Transaction>('transactions');
  final titleController = TextEditingController(); // This is the "why"
  final amountController = TextEditingController();

  String selectedAccount = 'Cash'; // Default account
  String selectedCategory = 'Food'; // Default category

  final List<Map<String, dynamic>> accounts = [
    {'name': 'Cash', 'icon': Icons.money},
    {'name': 'Bank/UPI', 'icon': Icons.account_balance},
    {'name': 'Coins', 'icon': Icons.generating_tokens},
  ];

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.fastfood},
    {'name': 'Transport', 'icon': Icons.directions_bus},
    {'name': 'Bills', 'icon': Icons.receipt},
    {'name': 'Other', 'icon': Icons.category},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {

          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final textTheme = theme.textTheme;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Add Expense',
                      style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Title & Amount Fields ---
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Why? (e.g., Coffee)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12))
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12))
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Account Picker ---
                  Text(
                      ' FROM ACCOUNT',
                      style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: accounts.map((account) {
                      final isSelected = selectedAccount == account['name'];
                      return FilterChip(
                        label: Text(account['name']),
                        avatar: Icon(account['icon'], color: isSelected ? colors.onPrimary : colors.primary),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setModalState(() {
                            selectedAccount = account['name'];
                          });
                        },
                        selectedColor: colors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? colors.onPrimary : colors.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- Category Picker ---
                  Text(
                      ' CATEGORY',
                      style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category['name'];
                      return FilterChip(
                        label: Text(category['name']),
                        avatar: Icon(category['icon'], color: isSelected ? Colors.white : colors.onSurfaceVariant),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setModalState(() {
                            selectedCategory = category['name'];
                          });
                        },
                        selectedColor: Colors.red.shade400,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : colors.onSurface,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.remove_circle),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          // --- THIS IS THE FIX ---
                          final newEntry = Transaction(
                            label: titleController.text, // This is the "why"
                            amount: double.tryParse(amountController.text) ?? 0.0,
                            date: DateTime.now(),
                            account: selectedAccount,
                            isExpense: true,
                            expenseCategory: selectedCategory, // This field is now correctly saved
                          );
                          // --- END FIX ---
                          transactionBox.add(newEntry);
                          Navigator.pop(context); // Close the modal
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}