import 'package:flutter/material.dart';
import 'package:get_up/models/transaction.dart';
import 'package:hive_flutter/hive_flutter.dart';

void showAddIncomeModal(BuildContext context) {
  final transactionBox = Hive.box<Transaction>('transactions');
  final amountController = TextEditingController();

  String selectedAccount = 'Bank/UPI'; // Default account

  final List<Map<String, dynamic>> accounts = [
    {'name': 'Bank/UPI', 'icon': Icons.account_balance},
    {'name': 'Cash', 'icon': Icons.money},
    {'name': 'Coins', 'icon': Icons.generating_tokens},
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
                      'Add Income',
                      style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                      ' AMOUNT',
                      style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                      ' TO ACCOUNT',
                      style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: accounts.map((account) {
                      final isSelected = selectedAccount == account['name'];
                      return FilterChip(
                        label: Text(account['name']),
                        // --- THEME FIX ---
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
                        // --- END FIX ---
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Add Money'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      onPressed: () {
                        if (amountController.text.isNotEmpty) {
                          final newEntry = Transaction(
                            amount: double.tryParse(amountController.text) ?? 0.0,
                            date: DateTime.now(),
                            account: selectedAccount,
                            isExpense: false,
                            label: "Income",
                          );
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