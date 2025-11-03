import 'package:flutter/material.dart';
import 'package:get_up/models/transaction.dart';
import 'package:get_up/models/debt.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/add_expense_modal.dart';
import '../widgets/add_income_modal.dart';
import '../widgets/add_debt_modal.dart';
import '../widgets/edit_transaction_modal.dart'; // <-- 1. THIS IS THE FIX
import 'settings_page.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> with SingleTickerProviderStateMixin {
  final Box<Transaction> transactionBox = Hive.box<Transaction>('transactions');
  final Box<Debt> debtBox = Hive.box<Debt>('debts');
  final NumberFormat currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');
  late TabController _tabController;

  String _sortOrder = 'date_desc';
  double? _filterAmount;
  String? _filterAccount;
  final _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        _resetFilters();
      }
      setState(() {});
    });
  }

  void _resetFilters() {
    setState(() {
      _sortOrder = 'date_desc';
      _filterAmount = null;
      _filterAccount = null;
      _filterController.clear();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSortDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            showAddIncomeModal(context);
          } else if (_tabController.index == 1) {
            showAddExpenseModal(context);
          } else {
            showAddDebtModal(context);
          }
        },
        label: Text(
            _tabController.index == 0 ? 'Add Income' :
            (_tabController.index == 1 ? 'Add Expense' : 'Add Debt')
        ),
        icon: Icon(
            _tabController.index == 0 ? Icons.add :
            (_tabController.index == 1 ? Icons.remove : Icons.note_add)
        ),
        backgroundColor: _tabController.index == 0 ? Colors.green.shade600 :
        (_tabController.index == 1 ? Colors.red.shade700 : Theme.of(context).colorScheme.primary),
      ),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          final allTransactions = box.values.toList();

          List<Transaction> incomeTransactions = allTransactions.where((tx) => !tx.isExpense).toList();
          List<Transaction> expenseTransactions = allTransactions.where((tx) => tx.isExpense).toList();

          if (_filterAmount != null && _filterAmount! > 0) {
            incomeTransactions = incomeTransactions.where((tx) => tx.amount >= _filterAmount!).toList();
            expenseTransactions = expenseTransactions.where((tx) => tx.amount >= _filterAmount!).toList();
          }
          if (_filterAccount != null) {
            incomeTransactions = incomeTransactions.where((tx) => tx.account == _filterAccount).toList();
            expenseTransactions = expenseTransactions.where((tx) => tx.account == _filterAccount).toList();
          }
          if (_sortOrder == 'date_desc') {
            incomeTransactions.sort((a, b) => b.date.compareTo(a.date));
            expenseTransactions.sort((a, b) => b.date.compareTo(a.date));
          } else if (_sortOrder == 'amount_asc') {
            incomeTransactions.sort((a, b) => a.amount.compareTo(b.amount));
            expenseTransactions.sort((a, b) => a.amount.compareTo(b.amount));
          } else {
            incomeTransactions.sort((a, b) => b.amount.compareTo(a.amount));
            expenseTransactions.sort((a, b) => b.amount.compareTo(a.amount));
          }

          double totalCash = 0;
          double totalBank = 0;
          double totalCoins = 0;
          for (var tx in allTransactions) {
            double amount = tx.isExpense ? -tx.amount : tx.amount;
            if (tx.account == 'Cash') totalCash += amount;
            else if (tx.account == 'Bank/UPI') totalBank += amount;
            else if (tx.account == 'Coins') totalCoins += amount;
          }
          double netWorth = totalCash + totalBank + totalCoins;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildNetWorthCard(netWorth, context),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAccountCard('Bank/UPI', totalBank, Icons.account_balance, Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccountCard('Cash', totalCash, Icons.money, Theme.of(context).colorScheme.secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccountCard('Coins', totalCoins, Icons.generating_tokens, Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Income Log', icon: Icon(Icons.arrow_upward)),
                  Tab(text: 'Expense Log', icon: Icon(Icons.arrow_downward)),
                  Tab(text: 'Debts', icon: Icon(Icons.receipt_long)),
                ],
              ),

              _buildFilterSortControls(),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(
                        incomeTransactions,
                        "No income recorded yet."
                    ),
                    _buildTransactionList(
                        expenseTransactions,
                        "No expenses recorded yet."
                    ),
                    _buildDebtsPage(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final theme = Theme.of(context);
              final colors = theme.colorScheme;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sort & Filter Logs',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'FILTER BY ACCOUNT',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: ['All', 'Bank/UPI', 'Cash', 'Coins'].map((account) {
                          final isSelected = _filterAccount == (account == 'All' ? null : account);
                          return FilterChip(
                            label: Text(account),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _filterAccount = selected ? (account == 'All' ? null : account) : null;
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

                      TextField(
                        controller: _filterController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Filter by amount greater than',
                          prefixText: '₹',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SORT BY',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'date_desc', label: Text('Date'), icon: Icon(Icons.calendar_today)),
                          ButtonSegment(value: 'amount_asc', label: Text('Amount'), icon: Icon(Icons.arrow_upward)),
                          ButtonSegment(value: 'amount_desc', label: Text('Amount'), icon: Icon(Icons.arrow_downward)),
                        ],
                        selected: {_sortOrder},
                        onSelectionChanged: (Set<String> newSelection) {
                          setModalState(() {
                            _sortOrder = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              _resetFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterAmount = double.tryParse(_filterController.text);
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildFilterSortControls() {
    if (_tabController.index == 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    String sortText = "Date (Newest)";
    if (_sortOrder == 'amount_asc') sortText = "Amount (Lowest)";
    if (_sortOrder == 'amount_desc') sortText = "Amount (Highest)";

    String filterText = "";
    if (_filterAccount != null) {
      filterText += " | Acct: $_filterAccount";
    }
    if (_filterAmount != null && _filterAmount! > 0) {
      filterText += " | > ${currencyFormat.format(_filterAmount)}";
    }

    if (filterText.isEmpty && sortText == "Date (Newest)") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text("Sort & Filter"),
            onPressed: () => _showFilterSortDialog(context),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Sorted by: $sortText$filterText",
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
            onPressed: () => _showFilterSortDialog(context),
          ),
        ],
      ),
    );
  }


  Widget _buildNetWorthCard(double amount, BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(String title, double amount, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions, String emptyMessage) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = tx.isExpense;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            onTap: () {
              showEditTransactionModal(context, tx); // This will now work
            },
            onLongPress: () {
              _confirmDeleteDialog(tx);
            },
            leading: Icon(
              isExpense ? Icons.arrow_circle_down : Icons.arrow_circle_up,
              color: isExpense ? Colors.red : Colors.green,
              size: 30,
            ),
            title: Text(
              tx.label ?? (isExpense ? 'Expense' : 'Income'),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
            subtitle: Text(
              // --- THIS IS THE FIX ---
              // Now that build_runner has run, tx.expenseCategory will exist
              '${isExpense ? (tx.expenseCategory ?? 'Other') : tx.account} • ${DateFormat.yMd().format(tx.date)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            // --- END FIX ---
            trailing: Text(
              '${isExpense ? '-' : '+'}${currencyFormat.format(tx.amount)}',
              style: TextStyle(
                color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteDialog(Transaction tx) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${tx.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await tx.delete();
    }
  }

  // --- FULL CODE FOR DEBTS PAGE ---
  Widget _buildDebtsPage() {
    return ValueListenableBuilder(
      valueListenable: debtBox.listenable(),
      builder: (context, Box<Debt> box, _) {
        final allDebts = box.values.toList().cast<Debt>();

        final iOweList = allDebts.where((d) => !d.isOwedToMe).toList();
        final theyOweMeList = allDebts.where((d) => d.isOwedToMe).toList();

        iOweList.sort((a, b) => a.isSettled ? 1 : -1);
        theyOweMeList.sort((a, b) => a.isSettled ? 1 : -1);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            Text(
              'Money I Owe',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (iOweList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text('You don\'t owe anyone anything. Great!', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
              )
            else
              ...iOweList.map((debt) => _buildDebtTile(debt)),

            const Divider(height: 40),

            Text(
              'Money Owed To Me',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (theyOweMeList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No one owes you money.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
              )
            else
              ...theyOweMeList.map((debt) => _buildDebtTile(debt)),
          ],
        );
      },
    );
  }

  // --- FULL CODE FOR DEBT TILE ---
  Widget _buildDebtTile(Debt debt) {
    final theme = Theme.of(context);
    final Color cardColor = debt.isSettled
        ? theme.colorScheme.surfaceContainerHighest
        : (debt.isOwedToMe ? Colors.green[50]! : Colors.red[50]!);

    final Color textColor = debt.isSettled
        ? theme.colorScheme.onSurface.withOpacity(0.5)
        : theme.colorScheme.onSurface;

    final Color darkCardColor = debt.isSettled
        ? theme.colorScheme.surfaceContainerHighest
        : (debt.isOwedToMe ? const Color(0xFF003D1B) : const Color(0xFF4D0000));

    final bool isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isDark ? darkCardColor : cardColor,
      child: ListTile(
        title: Text(
          debt.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 17,
            decoration: debt.isSettled ? TextDecoration.lineThrough : TextDecoration.none,
            color: textColor,
          ),
        ),
        subtitle: Text(
          'Amount: ${currencyFormat.format(debt.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: debt.isSettled ? TextDecoration.lineThrough : TextDecoration.none,
            color: textColor.withOpacity(0.8),
          ),
        ),
        leading: Checkbox(
          value: debt.isSettled,
          activeColor: debt.isOwedToMe ? Colors.green : Colors.red,
          onChanged: (bool? value) {
            debt.isSettled = value ?? false;
            debt.save();
          },
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete "${debt.name}"?'),
                content: const Text('This will permanently remove this debt. This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      debt.delete();
                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}