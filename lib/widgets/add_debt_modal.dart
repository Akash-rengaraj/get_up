import 'package:flutter/material.dart';
import 'package:get_up/models/debt.dart';
import 'package:hive_flutter/hive_flutter.dart';

void showAddDebtModal(BuildContext context) {
  final debtBox = Hive.box<Debt>('debts');
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  bool isOwedToMe = false;

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
                      'Add New Debt / IOU',
                      style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Type Picker ---
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false, // I Owe
                        label: Text('I Owe'),
                        icon: Icon(Icons.arrow_circle_up, color: Colors.red),
                      ),
                      ButtonSegment(
                        value: true, // They Owe Me
                        label: Text('They Owe Me'),
                        icon: Icon(Icons.arrow_circle_down, color: Colors.green),
                      ),
                    ],
                    selected: {isOwedToMe},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setModalState(() {
                        isOwedToMe = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Name & Amount Fields ---
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: nameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: isOwedToMe ? 'Who owes me?' : 'Who do I owe?',
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
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Entry'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          final newDebt = Debt(
                            name: nameController.text,
                            amount: double.tryParse(amountController.text) ?? 0.0,
                            createdAt: DateTime.now(),
                            isOwedToMe: isOwedToMe,
                            isSettled: false,
                          );
                          debtBox.add(newDebt);
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