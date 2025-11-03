import 'package:flutter/material.dart';
import 'package:get_up/models/attendance_day.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'settings_page.dart'; // For the settings button

// --- Capitalization Extension ---
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    if (this == 'onDuty') return 'On Duty'; // Special case
    if (this == 'halfDay') return 'Half Day';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  final Box<AttendanceDay> attendanceBox = Hive.box<AttendanceDay>('attendance');
  final Box _settingsBox = Hive.box('attendance_settings');
  late DateTime _currentMonth;
  late TabController _tabController;

  DateTime _academicStartDate = DateTime.now();
  DateTime? _academicEndDate;

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final now = DateTime.now();
    final String? startDateString = _settingsBox.get('academicStartDate');
    _academicStartDate = startDateString != null
        ? DateTime.parse(startDateString)
        : DateTime(now.year, now.month - 3, 1);

    final String? endDateString = _settingsBox.get('academicEndDate');
    _academicEndDate = endDateString != null
        ? DateTime.parse(endDateString)
        : null;

    setState(() {});
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = isStartDate ? _academicStartDate : (_academicEndDate ?? now);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      if (isStartDate) {
        await _settingsBox.put('academicStartDate', pickedDate.toIso8601String());
        setState(() {
          _academicStartDate = pickedDate;
        });
      } else {
        await _settingsBox.put('academicEndDate', pickedDate.toIso8601String());
        setState(() {
          _academicEndDate = pickedDate;
        });
      }
    }
  }

  void _changeMonth(int increment) {
    final now = DateTime.now();
    if (increment > 0 &&
        (_currentMonth.year == now.year && _currentMonth.month == now.month)) {
      return;
    }

    DateTime twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);
    DateTime newMonth = DateTime(_currentMonth.year, _currentMonth.month + increment, 1);

    if (newMonth.isBefore(twelveMonthsAgo) && increment < 0) {
      setState(() {
        _currentMonth = twelveMonthsAgo;
      });
    } else {
      setState(() {
        _currentMonth = newMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: [
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tracker', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Settings', icon: Icon(Icons.edit_calendar)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackerTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildTrackerTab() {
    return ValueListenableBuilder(
      valueListenable: attendanceBox.listenable(),
      builder: (context, Box<AttendanceDay> box, _) {

        final allDays = box.values.toList().cast<AttendanceDay>();

        final academicEndDate = _academicEndDate ?? DateTime.now();

        final daysInPeriod = allDays.where((d) {
          final date = DateTime.parse(d.dateKey);
          return !date.isBefore(_academicStartDate) && !date.isAfter(academicEndDate);
        }).toList();

        final totalWorkingDays = daysInPeriod.where((d) =>
        d.status == AttendanceStatus.present ||
            d.status == AttendanceStatus.halfDay ||
            d.status == AttendanceStatus.absent ||
            d.status == AttendanceStatus.onDuty
        ).length;

        final daysPresent = daysInPeriod.where((d) => d.status == AttendanceStatus.present).length +
            (daysInPeriod.where((d) => d.status == AttendanceStatus.halfDay).length * 0.5) +
            daysInPeriod.where((d) => d.status == AttendanceStatus.onDuty).length;

        final daysLeave = daysInPeriod.where((d) => d.status == AttendanceStatus.absent).length;

        final percentage = totalWorkingDays == 0 ? 0.0 : (daysPresent / totalWorkingDays) * 100;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildStatsCard(percentage, totalWorkingDays, daysPresent, daysLeave, context),
            const SizedBox(height: 24),
            _buildMonthNavigator(),
            const SizedBox(height: 8),

            // --- 3. CALENDAR HEADER ---
            _buildCalendarHeader(),
            const SizedBox(height: 4),
            // --- END ---

            _buildCalendarGrid(box),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final theme = Theme.of(context);
    final String startDateText = DateFormat.yMMMMd().format(_academicStartDate);
    final String endDateText = _academicEndDate != null ? DateFormat.yMMMMd().format(_academicEndDate!) : 'Today';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Academic Period',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          'Set the start and end dates for calculating your attendance. The end date defaults to today if not set.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Divider(height: 24),
        ListTile(
          title: const Text('Academic Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(startDateText),
          trailing: const Icon(Icons.edit_calendar),
          onTap: () => _pickDate(context, true),
        ),
        ListTile(
          title: const Text('Academic End Date', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(endDateText),
          trailing: const Icon(Icons.edit_calendar),
          onTap: () => _pickDate(context, false),
        ),
        TextButton(
          child: const Text('Set End Date to "Today"'),
          onPressed: () {
            _settingsBox.delete('academicEndDate'); // Delete the key
            _loadSettings(); // Reload settings
          },
        ),
      ],
    );
  }

  Widget _buildStatsCard(double percentage, int totalDays, double presentDays, int leaveDays, BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    color: theme.dividerColor,
                    strokeWidth: 8,
                  ),
                  CircularProgressIndicator(
                    value: percentage / 100,
                    color: percentage >= 75 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Attendance',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Working Days: $totalDays',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    'Days Present: ${presentDays.toStringAsFixed(1)}',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    'Days Leave: $leaveDays',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final now = DateTime.now();
    final bool isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: isCurrentMonth ? null : () => _changeMonth(1),
          color: isCurrentMonth ? Colors.grey : Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  // --- 3. CALENDAR HEADER WIDGET ---
  Widget _buildCalendarHeader() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Monday to Sunday
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            days[index],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(Box<AttendanceDay> box) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    final monthEntries = box.toMap().map((key, value) =>
        MapEntry(key as String, value)
    );

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: daysInMonth + (firstDayWeekday - 1),
      itemBuilder: (context, index) {
        if (index < (firstDayWeekday - 1)) {
          return Container(); // Empty space
        }

        final dayNumber = index - (firstDayWeekday - 1) + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final dateKey = _dateKey(date);

        AttendanceStatus status = AttendanceStatus.none;
        if (monthEntries.containsKey(dateKey)) {
          status = monthEntries[dateKey]!.status;
        }

        return _buildCalendarCell(dayNumber, status, date);
      },
    );
  }

  Widget _buildCalendarCell(int dayNumber, AttendanceStatus status, DateTime date) {

    if (date.isAfter(DateTime.now())) {
      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            dayNumber.toString(),
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    Color cellColor;
    Color textColor = Colors.black87;

    switch (status) {
      case AttendanceStatus.present:
        cellColor = Colors.green.shade400;
        textColor = Colors.white;
        break;
      case AttendanceStatus.halfDay:
        cellColor = Colors.yellow.shade500;
        break;
      case AttendanceStatus.absent:
        cellColor = Colors.red.shade400;
        textColor = Colors.white;
        break;
      case AttendanceStatus.holiday:
        cellColor = Colors.grey.shade400;
        textColor = Colors.white;
        break;
      case AttendanceStatus.onDuty:
        cellColor = Colors.blue.shade400;
        textColor = Colors.white;
        break;
      case AttendanceStatus.none:
        cellColor = Theme.of(context).cardTheme.color!;
        textColor = Theme.of(context).colorScheme.onSurface;
    }

    return InkWell(
      onTap: () => _showStatusPicker(context, date, status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8),
          border: status == AttendanceStatus.none
              ? Border.all(color: Theme.of(context).dividerColor)
              : null,
        ),
        child: Center(
          child: Text(
            dayNumber.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 16.0,
          runSpacing: 8.0,
          children: [
            _buildLegendItem('Present', Colors.green.shade400),
            _buildLegendItem('Half Day', Colors.yellow.shade500),
            _buildLegendItem('Absent', Colors.red.shade400),
            _buildLegendItem('Holiday', Colors.grey.shade400),
            _buildLegendItem('On Duty', Colors.blue.shade400),
            _buildLegendItem('None', Theme.of(context).cardTheme.color!, border: Border.all(color: Theme.of(context).dividerColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color, {Border? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: border
          ),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  // --- 4. STATUS PICKER MODAL (UPDATED) ---
  void _showStatusPicker(BuildContext context, DateTime date, AttendanceStatus currentStatus) {
    final dateKey = _dateKey(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                DateFormat('MMMM d, yyyy').format(date),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...AttendanceStatus.values.map((status) {
              return ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: status == currentStatus
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                // --- THIS IS THE FIX ---
                // Use the new .capitalize() extension
                title: Text(status.name.capitalize()),
                // --- END FIX ---
                onTap: () {
                  final dayEntry = attendanceBox.get(dateKey);
                  if (dayEntry == null) {
                    attendanceBox.put(dateKey, AttendanceDay(dateKey: dateKey, status: status));
                  } else {
                    dayEntry.status = status;
                    dayEntry.save();
                  }
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}