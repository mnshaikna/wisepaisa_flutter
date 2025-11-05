import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense_model.dart';
import '../utils/utils.dart';

enum ChartType { donut, bar }

enum SpendFilter { expense, income }

class ExpenseChartScreen extends StatefulWidget {
  final List<dynamic> expenses;

  const ExpenseChartScreen({super.key, required this.expenses});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  ChartType selectedChart = ChartType.bar;
  SpendFilter selectedFilter = SpendFilter.expense;

  final List<Color> chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  _onChartSelected(ChartType type) => setState(() => selectedChart = type);

  _onFilterSelected(SpendFilter filter) =>
      setState(() => selectedFilter = filter);

  // Filter and group data
  Map<String, double> getGroupedData() {
    final filtered =
        widget.expenses.where((exp) {
          final model = ExpenseModel.fromJson(exp);
          return model.expenseSpendType.toLowerCase() ==
              (selectedFilter == SpendFilter.expense ? 'expense' : 'income');
        }).toList();

    final Map<String, double> grouped = {};
    for (var exp in filtered) {
      final model = ExpenseModel.fromJson(exp);
      grouped[model.expenseCategory] =
          (grouped[model.expenseCategory] ?? 0) + model.expenseAmount;
    }
    return grouped;
  }

  // Legend widget
  Widget buildLegend(Map<String, double> groupedData) {
    final total = groupedData.values.fold(0.0, (a, b) => a + b);
    int index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          groupedData.entries.map((entry) {
            final color = chartColors[index % chartColors.length];
            index++;
            final percent = (entry.value / total) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.key, overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    "${formatCurrency(entry.value, context)} (${percent.toStringAsFixed(1)}%)",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // Donut Chart
  Widget buildDonutChart(Map<String, double> groupedData) {
    final total = groupedData.values.fold(0.0, (a, b) => a + b);
    int index = 0;
    final sections =
        groupedData.entries.map((entry) {
          final color = chartColors[index % chartColors.length];
          index++;
          final percent = (entry.value / total) * 100;
          return PieChartSectionData(
            value: entry.value,
            color: color,
            radius: MediaQuery.of(context).size.width / 3,
            title: "${percent.toStringAsFixed(1)}%",
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(enabled: true),
            ),
          ),
        ),
        const SizedBox(height: 16),
        buildLegend(groupedData),
      ],
    );
  }

  // Top control (single row)
  Widget buildTopControls() {
    return SizedBox(
      height: 40.0,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Income/Expense
          ChoiceChip(
            label: const Text('Expense'),
            selected: selectedFilter == SpendFilter.expense,
            onSelected: (_) => _onFilterSelected(SpendFilter.expense),
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.grey[300],
            labelStyle: TextStyle(
              color:
                  selectedFilter == SpendFilter.expense
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Income'),
            selected: selectedFilter == SpendFilter.income,
            onSelected: (_) => _onFilterSelected(SpendFilter.income),
            selectedColor: Colors.green,
            backgroundColor: Colors.grey[300],
            labelStyle: TextStyle(
              color:
                  selectedFilter == SpendFilter.income
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 25.0),
            height: 25.0,
            width: 2.0,
            color: Colors.grey,
          ),
          // Chart type
          ChoiceChip(
            label: const Text('Donut'),
            selected: selectedChart == ChartType.donut,
            onSelected: (_) => _onChartSelected(ChartType.donut),
            selectedColor: Colors.orangeAccent,
            backgroundColor: Colors.grey[300],
            labelStyle: TextStyle(
              color:
                  selectedChart == ChartType.donut
                      ? Colors.white
                      : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Bar'),
            selected: selectedChart == ChartType.bar,
            onSelected: (_) => _onChartSelected(ChartType.bar),
            selectedColor: Colors.deepPurpleAccent,
            backgroundColor: Colors.grey[300],
            labelStyle: TextStyle(
              color:
                  selectedChart == ChartType.bar ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = getGroupedData();

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Chart'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment:
              groupedData.isEmpty
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 12),
            buildTopControls(),
            const SizedBox(height: 16),
            SizedBox(
              height:
                  groupedData.isEmpty
                      ? MediaQuery.of(context).size.height * 0.75
                      : MediaQuery.of(context).size.height,
              child: AnimatedSwitcher(
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                duration: const Duration(milliseconds: 500),
                child:
                    groupedData.isEmpty
                        ? noDataWidget(
                          'No data available',
                          'Add some ${selectedFilter == SpendFilter.income ? 'income' : 'expense'} to view your chart insights.',
                          context,
                        )
                        : selectedChart == ChartType.donut
                        ? buildDonutChart(groupedData)
                        : ExpenseVerticalBarChart(
                          groupedData: groupedData,
                          chartColors: chartColors,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vertical Bar Chart with amounts inside
class ExpenseVerticalBarChart extends StatelessWidget {
  final Map<String, double> groupedData;
  final List<Color> chartColors;

  const ExpenseVerticalBarChart({
    super.key,
    required this.groupedData,
    required this.chartColors,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries =
        groupedData.entries.toList()
          /*..sort((a, b) => b.value.compareTo(a.value))*/;
    final maxValue = sortedEntries
        .map((e) => e.value)
        .fold(0.0, (a, b) => a > b ? a : b);

    final barGroups = List.generate(sortedEntries.length, (index) {
      final entry = sortedEntries[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: chartColors[index % chartColors.length],
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });

    return SizedBox(
      height: MediaQuery.of(context).size.height / 1.25,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.start,
          maxY: maxValue,
          gridData: FlGridData(show: true, drawHorizontalLine: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget:
                    (value, meta) =>
                        value == 0
                            ? const SizedBox.shrink()
                            : Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
              ),
            ),
            rightTitles: AxisTitles(),
            topTitles: AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: MediaQuery.of(context).size.height / 5,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedEntries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        sortedEntries[index].key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = sortedEntries[group.x.toInt()];
                return BarTooltipItem(
                  '${entry.key}\n${formatCurrency(entry.value, context)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
