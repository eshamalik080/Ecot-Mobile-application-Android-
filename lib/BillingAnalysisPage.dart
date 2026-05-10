import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class BillingAnalysisPage extends StatefulWidget {
  final String emailNode;

  const BillingAnalysisPage({required this.emailNode, Key? key}) : super(key: key);

  @override
  State<BillingAnalysisPage> createState() => _BillingAnalysisPageState();
}

class _BillingAnalysisPageState extends State<BillingAnalysisPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<_BillPoint> points = [];
  bool isLoading = true;
  double totalBill = 0;
  double totalUnits = 0;

  @override
  void initState() {
    super.initState();
    _loadBillingHistory();
  }

  Future<void> _loadBillingHistory() async {
    final snapshot = await _database
        .child(widget.emailNode)
        .child('billing_history')
        .get();

    if (!mounted) return;

    final loaded = <_BillPoint>[];

    if (snapshot.value != null) {
      final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final keys = map.keys.map((e) => e.toString()).toList()..sort();

      for (final key in keys) {
        final item = Map<dynamic, dynamic>.from(map[key]);
        final bill = (item['bill'] as num?)?.toDouble() ?? 0.0;
        final units = (item['units'] as num?)?.toDouble() ?? 0.0;
        loaded.add(_BillPoint(label: key, bill: bill, units: units));
      }
    }

    setState(() {
      points = loaded;
      totalBill = loaded.fold(0, (sum, e) => sum + e.bill);
      totalUnits = loaded.fold(0, (sum, e) => sum + e.units);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final avgBill = points.isEmpty ? 0 : totalBill / points.length;
    final avgUnits = points.isEmpty ? 0 : totalUnits / points.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Billing Analysis')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : points.isEmpty
          ? const Center(child: Text('No billing history found.'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryCard('Total Bill', 'Rs ${totalBill.toStringAsFixed(0)}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard('Total Units', '${totalUnits.toStringAsFixed(1)} kWh'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryCard('Avg Bill', 'Rs ${avgBill.toStringAsFixed(0)}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard('Avg Units', '${avgUnits.toStringAsFixed(1)} kWh'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Billing Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[i].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      spots: List.generate(
                        points.length,
                            (index) => FlSpot(index.toDouble(), points[index].bill),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillPoint {
  final String label;
  final double bill;
  final double units;

  _BillPoint({
    required this.label,
    required this.bill,
    required this.units,
  });
}