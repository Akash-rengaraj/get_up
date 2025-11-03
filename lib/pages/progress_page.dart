import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'settings_page.dart';

// ... (Helper functions and classes are unchanged, hidden for brevity) ...
bool isSameMonthYear(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return date1.year == date2.year && date1.month == date2.month;
}
class MonthlyCategoryProgress {
  final int month;
  final int year;
  int completedStudies;
  int totalStudies;
  int completedPersonal;
  int totalPersonal;
  MonthlyCategoryProgress({
    required this.month,
    required this.year,
    this.completedStudies = 0,
    this.totalStudies = 0,
    this.completedPersonal = 0,
    this.totalPersonal = 0,
  });
  double get studiesCompletionPercentage => totalStudies == 0 ? 0.0 : (completedStudies / totalStudies) * 100;
  double get personalCompletionPercentage => totalPersonal == 0 ? 0.0 : (completedPersonal / totalPersonal) * 100;
  String get monthName {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }
}
class DailyProgress {
  final int day;
  int completedStudies;
  int completedPersonal;
  DailyProgress({
    required this.day,
    this.completedStudies = 0,
    this.completedPersonal = 0,
  });
}


class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final Box<Task> taskBox = Hive.box<Task>('tasks');
  String _selectedFilter = 'Studies & Personal Care';
  late DateTime _currentMonth;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
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
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {

          final allHabits = box.values.where((task) => task.isHabit).toList().cast<Task>();

          List<Task> overallFilteredHabits;
          if (_selectedFilter == 'Studies') {
            overallFilteredHabits = allHabits.where((t) => t.category == 'Studies').toList();
          } else if (_selectedFilter == 'Personal Care') {
            overallFilteredHabits = allHabits.where((t) => t.category == 'Personal Care').toList();
          } else {
            overallFilteredHabits = allHabits;
          }

          final completedOnce = overallFilteredHabits.where((t) => t.completionHistory.isNotEmpty).length;
          final notStarted = overallFilteredHabits.length - completedOnce;
          final overallTotal = overallFilteredHabits.length;

          Map<String, MonthlyCategoryProgress> monthlyCategoryData = {};
          final now = DateTime.now();

          for (int i = 0; i < 6; i++) {
            final monthDate = DateTime(now.year, now.month - i, 1);
            final monthKey = '${monthDate.year}-${monthDate.month}';
            monthlyCategoryData[monthKey] = MonthlyCategoryProgress(month: monthDate.month, year: monthDate.year);
          }

          for (var habit in allHabits) {
            final createdAtMonthKey = '${habit.createdAt.year}-${habit.createdAt.month}';
            if (monthlyCategoryData.containsKey(createdAtMonthKey)) {
              if (habit.category == 'Studies') {
                monthlyCategoryData[createdAtMonthKey]!.totalStudies++;
              } else if (habit.category == 'Personal Care') {
                monthlyCategoryData[createdAtMonthKey]!.totalPersonal++;
              }
            }

            for (var completionDate in habit.completionHistory) {
              final completionMonthKey = '${completionDate.year}-${completionDate.month}';
              if (monthlyCategoryData.containsKey(completionMonthKey)) {
                if (habit.category == 'Studies') {
                  monthlyCategoryData[completionMonthKey]!.completedStudies++;
                } else if (habit.category == 'Personal Care') {
                  monthlyCategoryData[completionMonthKey]!.completedPersonal++;
                }
              }
            }
          }

          List<MonthlyCategoryProgress> sortedMonthlyCategoryProgress = monthlyCategoryData.values.toList()
            ..sort((a, b) {
              if (a.year != b.year) return a.year.compareTo(b.year);
              return a.month.compareTo(b.month);
            });

          Map<int, DailyProgress> dailyData = {};
          final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

          for (int i = 1; i <= daysInMonth; i++) {
            dailyData[i] = DailyProgress(day: i);
          }

          for (var habit in allHabits) {
            for (var completionDate in habit.completionHistory) {
              if (isSameMonthYear(completionDate, _currentMonth)) {

                final day = completionDate.day;

                if (dailyData.containsKey(day)) {
                  if (habit.category == 'Studies') {
                    dailyData[day]!.completedStudies++;
                  } else if (habit.category == 'Personal Care') {
                    dailyData[day]!.completedPersonal++;
                  }
                }
              }
            }
          }

          List<DailyProgress> sortedDailyProgress = dailyData.values.toList()
            ..sort((a, b) => a.day.compareTo(b.day));


          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Studies & Personal Care',
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: 'Personal Care',
                      label: Text('Personal'),
                    ),
                    ButtonSegment(
                      value: 'Studies',
                      label: Text('Studies'),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildChartCard(
                      context,
                      title: 'Overall Habits ($_selectedFilter)',
                      height: 250,
                      child: _buildPieChart(
                        completed: completedOnce,
                        pending: notStarted,
                        total: overallTotal,
                        completedColor: Colors.teal,
                        pendingColor: Colors.teal.shade100,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildChartCard(
                      context,
                      title: 'Monthly Completion Rate (All Categories)',
                      height: 300,
                      child: _buildMonthlyLineChart(sortedMonthlyCategoryProgress),
                    ),
                    const SizedBox(height: 24),

                    _buildChartCard(
                      context,
                      title: 'Daily Habits Completed in ${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                      height: 300,
                      child: _buildDailyBarChart(sortedDailyProgress, daysInMonth),
                    ),
                    const SizedBox(height: 24),

                    _buildChartCard(
                      context,
                      title: 'Daily Completion Timeline',
                      height: 300,
                      child: _buildDailyLineChart(sortedDailyProgress, daysInMonth),
                    ),

                    const SizedBox(height: 12),
                    _buildMonthNavigation(sortedMonthlyCategoryProgress, now),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required double height, required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart({
    required int completed,
    required int pending,
    required int total,
    required Color completedColor,
    required Color pendingColor,
  }) {
    if (total == 0) {
      return Center(
        child: Text(
          'No habits found for this filter.',
          // --- THEME FIX ---
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: completed.toDouble(),
                title: total > 0 ? '${((completed / total) * 100).toStringAsFixed(0)}%' : '0%',
                color: completedColor,
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                titlePositionPercentageOffset: 0.55,
              ),
              PieChartSectionData(
                value: pending.toDouble(),
                title: total > 0 ? '${((pending / total) * 100).toStringAsFixed(0)}%' : '0%',
                color: pendingColor,
                radius: 60,
                titleStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  // --- THEME FIX ---
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                titlePositionPercentageOffset: 0.55,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(color: completedColor, text: 'Started'),
              _buildLegendItem(color: pendingColor, text: 'Not Started'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyLineChart(List<MonthlyCategoryProgress> monthlyProgress) {
    if (monthlyProgress.every((m) => m.totalStudies + m.totalPersonal == 0)) {
      return Center(
        child: Text(
          'No habit data for the last 6 months.',
          // --- THEME FIX ---
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ... (rest of the chart logic is fine, it uses primary colors) ...
    List<FlSpot> studiesSpots = [];
    List<FlSpot> personalSpots = [];
    List<String> bottomTitles = [];

    for (int i = 0; i < monthlyProgress.length; i++) {
      final data = monthlyProgress[i];
      studiesSpots.add(FlSpot(i.toDouble(), data.studiesCompletionPercentage));
      personalSpots.add(FlSpot(i.toDouble(), data.personalCompletionPercentage));
      bottomTitles.add(data.monthName);
    }

    return Stack(
      children: [
        LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 25,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 0.5),
              getDrawingVerticalLine: (value) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 0.5),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < bottomTitles.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(bottomTitles[value.toInt()], style: const TextStyle(fontSize: 12)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 25,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()}%', style: const TextStyle(fontSize: 12));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            minX: 0,
            maxX: (monthlyProgress.length - 1).toDouble(),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: studiesSpots,
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: personalSpots,
                isCurved: true,
                color: Colors.pinkAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(color: Colors.blueAccent, text: 'Studies'),
              _buildLegendItem(color: Colors.pinkAccent, text: 'Personal Care'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBarChart(List<DailyProgress> dailyProgress, int daysInMonth) {
    if (dailyProgress.every((d) => d.completedStudies + d.completedPersonal == 0)) {
      return Center(
        child: Text(
          'No habits completed this month.',
          // --- THEME FIX ---
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    double maxCompletedInADay = 0;
    for (var data in dailyProgress) {
      if (data.completedStudies > maxCompletedInADay) maxCompletedInADay = data.completedStudies.toDouble();
      if (data.completedPersonal > maxCompletedInADay) maxCompletedInADay = data.completedPersonal.toDouble();
    }
    if (maxCompletedInADay == 0) maxCompletedInADay = 1.0;
    else maxCompletedInADay = maxCompletedInADay * 1.2;

    final double titleInterval = (daysInMonth / 7).ceilToDouble();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < dailyProgress.length; i++) {
      final data = dailyProgress[i];
      barGroups.add(
        BarChartGroupData(
          x: data.day, // Day of the month
          barRods: [
            BarChartRodData(
              toY: data.completedStudies.toDouble(),
              color: Colors.blue.shade300,
              width: 5,
              borderRadius: BorderRadius.zero,
            ),
            BarChartRodData(
              toY: data.completedPersonal.toDouble(),
              color: Colors.pink.shade300,
              width: 5,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() == 1 || value.toInt() % titleInterval.toInt() == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 25,
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
              reservedSize: 30,
              interval: (maxCompletedInADay / 4).ceilToDouble() == 0 ? 1 : (maxCompletedInADay / 4).ceilToDouble(),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor,
            strokeWidth: 0.5,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        maxY: maxCompletedInADay,
        minY: 0,
      ),
    );
  }

  Widget _buildDailyLineChart(List<DailyProgress> dailyProgress, int daysInMonth) {
    if (dailyProgress.every((d) => d.completedStudies + d.completedPersonal == 0)) {
      return Center(
        child: Text(
          'No habits completed this month.',
          // --- THEME FIX ---
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }
    // ... (rest of chart logic is fine) ...
    double maxCompletedInADay = 0;
    for (var data in dailyProgress) {
      if (data.completedStudies > maxCompletedInADay) maxCompletedInADay = data.completedStudies.toDouble();
      if (data.completedPersonal > maxCompletedInADay) maxCompletedInADay = data.completedPersonal.toDouble();
    }
    if (maxCompletedInADay == 0) maxCompletedInADay = 1.0;
    else maxCompletedInADay = maxCompletedInADay * 1.2;

    final double titleInterval = (daysInMonth / 7).ceilToDouble();

    List<FlSpot> studiesSpots = [];
    List<FlSpot> personalSpots = [];
    for (var data in dailyProgress) {
      studiesSpots.add(FlSpot(data.day.toDouble(), data.completedStudies.toDouble()));
      personalSpots.add(FlSpot(data.day.toDouble(), data.completedPersonal.toDouble()));
    }

    return Stack(
      children: [
        LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 0.5),
              getDrawingVerticalLine: (value) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 0.5),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() == 1 || value.toInt() % titleInterval.toInt() == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 12));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            minX: 1,
            maxX: daysInMonth.toDouble(),
            minY: 0,
            maxY: maxCompletedInADay,
            lineBarsData: [
              LineChartBarData(
                spots: studiesSpots,
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blueAccent.withOpacity(0.3)
                ),
              ),
              LineChartBarData(
                spots: personalSpots,
                isCurved: true,
                color: Colors.pinkAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                    show: true,
                    color: Colors.pinkAccent.withOpacity(0.3)
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(color: Colors.blueAccent, text: 'Studies'),
              _buildLegendItem(color: Colors.pinkAccent, text: 'Personal Care'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(List<MonthlyCategoryProgress> months, DateTime now) {
    final reversedMonths = months.reversed.toList();

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: reversedMonths.map((monthData) {
            final monthDate = DateTime(monthData.year, monthData.month);

            if (monthDate.isAfter(now)) {
              return const SizedBox.shrink();
            }

            final isSelected = isSameMonthYear(monthDate, _currentMonth);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text('${_monthNames[monthData.month - 1]} ${monthData.year}'),
                selected: isSelected,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  // --- THEME FIX ---
                  color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _currentMonth = monthDate;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}