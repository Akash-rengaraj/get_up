import 'package:flutter/material.dart';
import 'package:get_up/models/transaction.dart';

// This is the new, reusable modal widget for editing
void showEditTransactionModal(BuildContext context, Transaction transaction) {
  final titleController = TextEditingController(text: transaction.label);
  final amountController = TextEditingController(text: transaction.amount.toString());

  String selectedAccount = transaction.account;
  String selectedCategory = transaction.expenseCategory ?? 'Food';
  bool isExpense = transaction.isExpense;

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
                      isExpense ? 'Edit Expense' : 'Edit Income',
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
                          decoration: InputDecoration(
                            labelText: isExpense ? 'Why? (e.g., Coffee)' : 'Note (e.g., Income)',
                            border: const OutlineInputBorder(
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
                      ' ACCOUNT',
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

                  // --- Category Picker (Only show for expenses) ---
                  if (isExpense) ...[
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
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          // Update the existing transaction
                          transaction.label = titleController.text;
                          transaction.amount = double.tryParse(amountController.text) ?? 0.0;
                          transaction.account = selectedAccount;
                          transaction.expenseCategory = isExpense ? selectedCategory : null;

                          transaction.save(); // Save the changes
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