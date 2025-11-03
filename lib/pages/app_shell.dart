import 'package:flutter/material.dart';
import 'today_page.dart';
import 'progress_page.dart';
import 'money_page.dart';
import 'attendance_page.dart';
import '../widgets/add_task_modal.dart'; // Import the "Add Task" modal

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // We remove 'static const' so the pages can rebuild if needed
  final List<Widget> _pages = <Widget>[
    const TodayPage(),
    const ProgressPage(),
    const MoneyPage(),
    const AttendancePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),

      // --- FAB IS BACK ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // The "Add Task" button is back in the middle
          showAddTaskModal(context, initialCategory: 'Todo');
        },
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BOTTOM APP BAR ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.calendar_today_outlined, 'Today', 0),
            _buildNavItem(Icons.bar_chart_outlined, 'Progress', 1),
            const SizedBox(width: 40), // Spacer for FAB
            _buildNavItem(Icons.attach_money_outlined, 'Money', 2),
            _buildNavItem(Icons.event_available_outlined, 'Attendance', 3),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a navigation item
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}