import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/category_helper.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Dashboard & Summary')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data available for summary.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          final Map<String, double> categoryTotals = {};
          double grandTotal = 0.0;

          // Month-on-month comparison bookkeeping.
          final now = DateTime.now();
          final currentMonthStart = DateTime(now.year, now.month, 1);
          final previousMonthStart = DateTime(now.year, now.month - 1, 1);
          double currentMonthTotal = 0.0;
          double previousMonthTotal = 0.0;
          final Map<String, double> currentMonthByCategory = {};
          final Map<String, double> previousMonthByCategory = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] ?? 'Other';
            final amount = (data['amount'] ?? 0.0).toDouble();
            final date = DateTime.parse(data['date']);

            categoryTotals[category] =
                (categoryTotals[category] ?? 0.0) + amount;
            grandTotal += amount;

            if (!date.isBefore(currentMonthStart)) {
              currentMonthTotal += amount;
              currentMonthByCategory[category] =
                  (currentMonthByCategory[category] ?? 0.0) + amount;
            } else if (!date.isBefore(previousMonthStart) &&
                date.isBefore(currentMonthStart)) {
              previousMonthTotal += amount;
              previousMonthByCategory[category] =
                  (previousMonthByCategory[category] ?? 0.0) + amount;
            }
          }

          // Sort categories by spend, highest first.
          final sortedEntries = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topCategory = sortedEntries.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalCard(
                grandTotal: grandTotal,
                currency: currency,
                expenseCount: docs.length,
              ),
              const SizedBox(height: 20),

              _MonthComparisonCard(
                currentTotal: currentMonthTotal,
                previousTotal: previousMonthTotal,
                currentByCategory: currentMonthByCategory,
                previousByCategory: previousMonthByCategory,
                currency: currency,
              ),
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Spending by Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                categoryInfoFor(topCategory.key).icon,
                                size: 16,
                                color: categoryInfoFor(topCategory.key).color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Top: ${topCategory.key}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DonutChart(entries: sortedEntries, total: grandTotal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Category-wise Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...sortedEntries.map((entry) {
                final percentage = grandTotal > 0
                    ? entry.value / grandTotal
                    : 0.0;
                final info = categoryInfoFor(entry.key);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: info.color.withOpacity(0.15),
                                  child: Icon(
                                    info.icon,
                                    color: info.color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs. ${currency.format(entry.value)}',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: info.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: info.color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              info.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(1)}% of total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double grandTotal;
  final NumberFormat currency;
  final int expenseCount;
  const _TotalCard({
    required this.grandTotal,
    required this.currency,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withOpacity(0.65)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Cumulative Expenses',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs. ${currency.format(grandTotal)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                '$expenseCount entries',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card comparing this calendar month's spending against last month's,
/// both in total and broken down by which categories moved the most.
class _MonthComparisonCard extends StatelessWidget {
  final double currentTotal;
  final double previousTotal;
  final Map<String, double> currentByCategory;
  final Map<String, double> previousByCategory;
  final NumberFormat currency;

  const _MonthComparisonCard({
    required this.currentTotal,
    required this.previousTotal,
    required this.currentByCategory,
    required this.previousByCategory,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentLabel = DateFormat('MMMM').format(now);
    final previousLabel = DateFormat(
      'MMMM',
    ).format(DateTime(now.year, now.month - 1, 1));

    final hasPrevious = previousTotal > 0;
    final diff = currentTotal - previousTotal;
    final isUp = diff > 0;
    final pct = hasPrevious ? (diff / previousTotal) * 100 : null;

    // Which categories changed the most between the two months.
    final allCategories = <String>{
      ...currentByCategory.keys,
      ...previousByCategory.keys,
    };
    final deltas =
        allCategories
            .map((cat) {
              final cur = currentByCategory[cat] ?? 0.0;
              final prev = previousByCategory[cat] ?? 0.0;
              return MapEntry(cat, cur - prev);
            })
            .where((e) => e.value.abs() > 0.001)
            .toList()
          ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final topDeltas = deltas.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Month-on-Month Comparison',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MonthTotalTile(
                    label: previousLabel,
                    amount: previousTotal,
                    currency: currency,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Theme.of(context).hintColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MonthTotalTile(
                    label: currentLabel,
                    amount: currentTotal,
                    currency: currency,
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasPrevious)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (isUp ? Colors.red : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isUp ? Colors.red : Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${isUp ? "Spent" : "Saved"} Rs. ${currency.format(diff.abs())}'
                        ' (${pct!.abs().toStringAsFixed(1)}%) ${isUp ? "more" : "less"} than $previousLabel',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isUp
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'No data from $previousLabel yet to compare against.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).hintColor,
                ),
              ),
            if (topDeltas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Biggest changes by category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 8),
              ...topDeltas.map((entry) {
                final up = entry.value > 0;
                final info = categoryInfoFor(entry.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(info.icon, size: 16, color: info.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Icon(
                        up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: up ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Rs. ${currency.format(entry.value.abs())}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: up
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthTotalTile extends StatelessWidget {
  final String label;
  final double amount;
  final NumberFormat currency;
  final bool highlight;
  const _MonthTotalTile({
    required this.label,
    required this.amount,
    required this.currency,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primary.withOpacity(0.1)
            : Theme.of(context).hintColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${currency.format(amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: highlight ? scheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A lightweight donut chart drawn with CustomPainter — no extra chart
/// package required, keeps the app's dependency footprint minimal.
class _DonutChart extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final double total;
  const _DonutChart({required this.entries, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 180,
      child: CustomPaint(
        painter: _DonutPainter(entries: entries, total: total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entries.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                entries.length == 1 ? 'category' : 'categories',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double total;
  _DonutPainter({required this.entries, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.34;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    for (final entry in entries) {
      final sweep = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = categoryInfoFor(entry.key).color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep - 0.02, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.total != total;
}
