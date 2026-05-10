import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsPage extends StatefulWidget {
  final String emailNode;

  const ReportsPage({required this.emailNode, Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Map<String, dynamic> data = {};
  bool isLoading = true;

  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snapshot = await _database.child(widget.emailNode).get();
    if (!mounted) return;

    if (snapshot.value != null) {
      setState(() {
        data = Map<String, dynamic>.from(snapshot.value as Map);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
    );

    if (result != null) {
      setState(() => selectedRange = result);
    }
  }

  String _safe(dynamic value) => value?.toString() ?? 'N/A';

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    final aiRaw = data['ai_result'];
    final ai = aiRaw is Map ? Map<String, dynamic>.from(aiRaw) : {};

    final suggestionRaw = data['suggestion'];
    final suggestionMap =
    suggestionRaw is Map ? Map<String, dynamic>.from(suggestionRaw) : {};
    final actionItemsRaw = suggestionMap['action_items'];

    List<String> suggestions = [];
    if (actionItemsRaw is List) {
      suggestions = actionItemsRaw
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList();
    } else if (actionItemsRaw is Map) {
      final map = Map<dynamic, dynamic>.from(actionItemsRaw);
      final keys = map.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString()));
      suggestions = keys.map((k) => map[k].toString()).toList();
    }

    final dateText = selectedRange == null
        ? 'All available data'
        : '${DateFormat('dd MMM yyyy').format(selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}';

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Energy Monitoring Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('User: ${_safe(data['name'])}'),
          pw.Text('Email Node: ${widget.emailNode}'),
          pw.Text('Report Range: $dateText'),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now())}'),
          pw.SizedBox(height: 16),

          pw.Text(
            'Current Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(text: 'Voltage: ${_safe(data['voltage'])} V'),
          pw.Bullet(text: 'Current: ${_safe(data['current'])} A'),
          pw.Bullet(text: 'Power: ${_safe(data['power'])} W'),
          pw.Bullet(text: 'Units: ${_safe(data['units'])} kWh'),
          pw.Bullet(text: 'Bill: Rs ${_safe(data['bill'])}'),
          pw.SizedBox(height: 12),

          pw.Text(
            'AI Analysis',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(text: 'Status: ${_safe(ai['status'])}'),
          pw.Bullet(text: 'Anomaly Score: ${_safe(ai['anomaly_score'])}'),
          pw.Bullet(text: 'Theft Score: ${_safe(ai['theft_score'])}'),
          pw.Bullet(text: 'Reason: ${_safe(ai['reason'])}'),
          pw.Bullet(text: 'Explanation: ${_safe(ai['explanation'])}'),
          pw.SizedBox(height: 12),

          pw.Text(
            'Suggestions',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (suggestions.isEmpty)
            pw.Text('No suggestions available.')
          else
            ...suggestions.map((s) => pw.Bullet(text: s)),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'energy_report_${widget.emailNode}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Report Date Range'),
                subtitle: Text(
                  selectedRange == null
                      ? 'All available data'
                      : '${DateFormat('dd MMM yyyy').format(selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}',
                ),
                trailing: ElevatedButton(
                  onPressed: _pickRange,
                  child: const Text('Select'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Name: ${_safe(data['name'])}'),
                    Text('Voltage: ${_safe(data['voltage'])} V'),
                    Text('Current: ${_safe(data['current'])} A'),
                    Text('Power: ${_safe(data['power'])} W'),
                    Text('Units: ${_safe(data['units'])} kWh'),
                    Text('Bill: Rs ${_safe(data['bill'])}'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generatePdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download / Share PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}