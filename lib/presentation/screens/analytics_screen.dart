import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final spending = ref.watch(spendingByCategoryForMonthProvider(selectedMonth));
    final weeklySpending = ref.watch(weeklySpendingForMonthProvider(selectedMonth));
    final monthlyTrend = ref.watch(monthlyTrendProvider(selectedMonth));
    final topMerchants = ref.watch(topMerchantsProvider(selectedMonth));
    final nonEssential = ref.watch(nonEssentialSpendingProvider(selectedMonth));
    final biggestExpense = ref.watch(biggestExpenseProvider(selectedMonth));
    final essentialSplit = ref.watch(essentialSplitProvider(selectedMonth));

    final totalSpent = monthlyTrend.isNotEmpty ? monthlyTrend.last : 0.0;
    final currency = ref.watch(currencySymbolProvider);
    final formatter = NumberFormat('#,##,###', 'en_IN');

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),

            // Month Selector
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(selectedMonthProvider.notifier).state = DateTime(
                      selectedMonth.year,
                      selectedMonth.month - 1,
                    );
                  },
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.onSurface),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(selectedMonthProvider.notifier).state = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Donut Chart ───
            GlassCard(
              showGlow: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Spending by Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: spending.isEmpty
                        ? Center(
                            child: Text(
                              'No spending data',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.outline),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 60,
                                  sections: _buildDonutSections(spending),
                                  pieTouchData: PieTouchData(enabled: false),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$currency${formatter.format(totalSpent)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    'Total Spent',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppColors.outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: spending.entries.map((entry) {
                      final category =
                          TransactionCategory.values[entry.key];
                      final total = spending.values.fold(0.0, (a, b) => a + b);
                      final pct = total == 0 ? 0.0 : (entry.value / total * 100);
                      return _buildLegendItem(
                        context,
                        '${category.label} (${pct.toStringAsFixed(0)}%)',
                        category.color,
                        '$currency${formatter.format(entry.value)}',
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Weekly Bar Chart ───
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Spending',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last 4 weeks',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (_getMaxWeekly(weeklySpending) <= 0 ? 1000 : _getMaxWeekly(weeklySpending)) * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox.shrink();
                                return Text(
                                  '$currency${(value / 1000).toStringAsFixed(0)}k',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.outline),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final labels = [
                                  'This Week',
                                  'Last Week',
                                  '2W',
                                  '3W'
                                ];
                                final idx = value.toInt();
                                if (idx >= 0 && idx < labels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      labels[idx],
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.outline,
                                            fontSize: 10,
                                          ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppColors.outlineVariant.withValues(alpha: 0.15),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(weeklySpending),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Monthly Trend ───
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Trend', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: monthlyTrend.isEmpty
                        ? Center(child: Text('No data', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline)))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                                  final idx = v.toInt();
                                  final now = selectedMonth;
                                  final labelMonth = DateTime(now.year, now.month - 5 + idx, 1);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(DateFormat('MMM').format(labelMonth), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline)),
                                  );
                                }, reservedSize: 28)),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                                  if (v == 0) return const SizedBox.shrink();
                                  return Text('${(v/1000).toStringAsFixed(0)}k', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.outline));
                                }, reservedSize: 40)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(monthlyTrend.length, (i) => FlSpot(i.toDouble(), monthlyTrend[i])),
                                  isCurved: true,
                                  gradient: const LinearGradient(colors: [AppColors.primaryContainer, AppColors.primary]),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                              minY: 0,
                              maxY: (monthlyTrend.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1000, double.infinity),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Top merchants ───
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top merchants', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (topMerchants.isEmpty)
                    Center(child: Text('No spending this month', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.outline)))
                  else
                    Column(
                      children: topMerchants.map((e) => ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        title: Text(e.key, style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Text('$currency${formatter.format(e.value)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Smart Insights ───
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Insights', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Builder(builder: (ctx) {
                    final budget = ref.watch(monthlyBudgetProvider);
                    final remain = budget - totalSpent;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (budget > 0 && totalSpent > budget)
                          Text("⚠️ You've exceeded your monthly budget by $currency${formatter.format((totalSpent - budget).abs())}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent)),
                        if (budget > 0 && totalSpent <= budget)
                          Text("✅ You're on track — $currency${formatter.format(remain)} remaining for the month", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.greenAccent)),

                        const SizedBox(height: 8),
                        Text(
                          biggestExpense == null ? 'No expenses this month' : 'Your biggest expense this month was ${biggestExpense.key} — $currency${formatter.format(biggestExpense.value)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('You spent $currency${formatter.format(nonEssential)} on non-essentials this month', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Builder(builder: (ctx2) {
                          final essential = essentialSplit['essential'] ?? 0.0;
                          final nonE = essentialSplit['nonEssential'] ?? 0.0;
                          final total = essential + nonE;
                          final essPct = total == 0 ? 0 : (essential / total * 100).round();
                          final nonPct = total == 0 ? 0 : (nonE / total * 100).round();
                          return Row(children: [
                            Expanded(child: Text('Essential: $essPct%', style: Theme.of(context).textTheme.bodyMedium)),
                            Expanded(child: Text('Non-essential: $nonPct%', style: Theme.of(context).textTheme.bodyMedium)),
                          ]);
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDonutSections(Map<int, double> spending) {
    return spending.entries.map((entry) {
      final category = TransactionCategory.values[entry.key];
      return PieChartSectionData(
        value: entry.value,
        showTitle: false,
        color: category.color,
        radius: 32,
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(Map<int, double> weeklySpending) {
    return List.generate(4, (index) {
      final value = weeklySpending[index] ?? 0;
      final isCurrentWeek = index == 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: isCurrentWeek
                ? const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.primaryContainer, AppColors.primary],
                  )
                : LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.surfaceContainerHigh,
                      AppColors.surfaceBright,
                    ],
                  ),
          ),
        ],
      );
    });
  }

  double _getMaxWeekly(Map<int, double> weeklySpending) {
    if (weeklySpending.isEmpty) return 10000;
    return weeklySpending.values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildLegendItem(
      BuildContext context, String label, Color color, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $amount',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
