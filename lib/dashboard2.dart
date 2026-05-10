import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart';
import 'LoginPage.dart';

class Dashboard extends StatefulWidget {
  final String emailNode;

  const Dashboard({required this.emailNode, Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  StreamSubscription<DatabaseEvent>? _subscription;

  String name = '';
  String voltage = '', current = '', power = '', units = '', bill = '';

  double anomalyScore = 0.0;
  double theftScore = 0.0;
  String aiStatus = 'normal';
  String aiReason = '';
  String aiExplanation = '';
  int aiUpdatedAt = 0;

  int _lastHandledAlertTimestamp = 0;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void fetchData() {
    _subscription = _database.child(widget.emailNode).onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      final aiRaw = data['ai_result'];
      final ai = aiRaw is Map
          ? Map<String, dynamic>.from(aiRaw)
          : <String, dynamic>{};

      setState(() {
        name = data['name']?.toString() ?? '';
        voltage = data['voltage']?.toString() ?? '';
        current = data['current']?.toString() ?? '';
        power = data['power']?.toString() ?? '';
        units = data['units']?.toString() ?? '';
        bill = data['bill']?.toString() ?? '';

        anomalyScore = _toDouble(ai['anomaly_score']);
        theftScore = _toDouble(ai['theft_score']);
        aiStatus = ai['status']?.toString() ?? 'normal';
        aiReason = ai['reason']?.toString() ?? '';
        aiExplanation = ai['explanation']?.toString() ?? '';
        aiUpdatedAt = _toInt(ai['updated_at']);
      });

      _handleAiAlert();
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _getTheftLevel(double score) {
    if (score >= 0.70) return 'possible_theft';
    if (score >= 0.45) return 'suspicious';
    return 'normal';
  }

  String _getAnomalyLevel(double score) {
    if (score >= 0.70) return 'strong_anomaly';
    if (score >= 0.50) return 'anomaly';
    if (score > 0.00) return 'minor_deviation';
    return 'normal';
  }

  String _getCombinedLevel() {
    final theftLevel = _getTheftLevel(theftScore);
    final anomalyLevel = _getAnomalyLevel(anomalyScore);

    if (theftLevel == 'possible_theft' || anomalyLevel == 'strong_anomaly') {
      return 'critical';
    }
    if (theftLevel == 'suspicious' || anomalyLevel == 'anomaly') {
      return 'warning';
    }
    if (anomalyLevel == 'minor_deviation') {
      return 'info';
    }
    return 'normal';
  }

  String _buildAlertTitle() {
    final level = _getCombinedLevel();

    if (level == 'critical') {
      if (theftScore >= 0.70) return 'Possible Theft Detected';
      return 'Strong Anomaly Detected';
    }

    if (level == 'warning') {
      if (theftScore >= 0.45) return 'Suspicious Activity Detected';
      return 'Anomaly Detected';
    }

    if (level == 'info') {
      return 'Minor Deviation Detected';
    }

    return 'System Normal';
  }

  String _buildAlertMessage() {
    return 'Theft Score: ${theftScore.toStringAsFixed(2)}\n'
        'Anomaly Score: ${anomalyScore.toStringAsFixed(2)}\n'
        'Status: $aiStatus\n'
        'Reason: ${aiReason.isEmpty ? "N/A" : aiReason}\n'
        'Explanation: ${aiExplanation.isEmpty ? "N/A" : aiExplanation}';
  }

  Future<void> _handleAiAlert() async {
    final level = _getCombinedLevel();

    if (level == 'normal') return;
    if (aiUpdatedAt == 0) return;
    if (_lastHandledAlertTimestamp == aiUpdatedAt) return;

    _lastHandledAlertTimestamp = aiUpdatedAt;

    final title = _buildAlertTitle();
    final message = _buildAlertMessage();

    await _showLocalNotification(title, message);

    if (!mounted) return;

    if (level == 'info' || level == 'warning') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(title),
          backgroundColor:
          level == 'warning' ? Colors.orange.shade700 : Colors.blueGrey,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (level == 'warning' || level == 'critical') {
      _showAlertDialog(title, message, level);
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'ecot_alerts',
      'E-Cot Alerts',
      channelDescription: 'Alerts for anomaly and theft detection',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void _showAlertDialog(String title, String message, String level) {
    if (_dialogShowing || !mounted) return;
    _dialogShowing = true;

    final Color color = level == 'critical' ? Colors.red : Colors.orange;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dialogShowing = false;
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }

  void _openSuggestionsDialog() {
    final DatabaseReference suggestionRef = FirebaseDatabase.instance
        .ref()
        .child(widget.emailNode)
        .child('suggestion')
        .child('action_items');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.tips_and_updates, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Live Suggestions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<DatabaseEvent>(
            stream: suggestionRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Failed to load suggestions.');
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Text('No suggestions available.');
              }

              final rawData = snapshot.data!.snapshot.value;
              List<String> suggestions = [];

              if (rawData is List) {
                suggestions = rawData
                    .where((item) => item != null)
                    .map((item) => item.toString())
                    .where((text) => text.trim().isNotEmpty)
                    .toList();
              } else if (rawData is Map) {
                final map = Map<dynamic, dynamic>.from(rawData);
                final sortedKeys = map.keys.toList()
                  ..sort((a, b) {
                    final aNum = int.tryParse(a.toString()) ?? 0;
                    final bNum = int.tryParse(b.toString()) ?? 0;
                    return aNum.compareTo(bNum);
                  });

                suggestions = sortedKeys
                    .map((key) => map[key]?.toString() ?? '')
                    .where((text) => text.trim().isNotEmpty)
                    .toList();
              }

              if (suggestions.isEmpty) {
                return const Text('No suggestions available.');
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: suggestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final text = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Color _aiStatusColor() {
    final level = _getCombinedLevel();
    switch (level) {
      case 'critical':
        return Colors.red.shade600;
      case 'warning':
        return Colors.orange.shade600;
      case 'info':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  String _aiStatusText() {
    final level = _getCombinedLevel();
    switch (level) {
      case 'critical':
        return 'Critical Alert';
      case 'warning':
        return 'Warning Alert';
      case 'info':
        return 'Minor Deviation';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    tooltip: 'Logout',
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Image.asset('assets/logo.png', width: 90, height: 90),
                        const SizedBox(height: 10),
                        Text(
                          name.isNotEmpty ? "${name}'s Home" : "Loading...",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _aiStatusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _aiStatusColor(), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aiStatusText(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _aiStatusColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Theft Score: ${theftScore.toStringAsFixed(2)}'),
                    Text('Anomaly Score: ${anomalyScore.toStringAsFixed(2)}'),
                    Text('Status: $aiStatus'),
                    if (aiReason.isNotEmpty) Text('Reason: $aiReason'),
                    if (aiExplanation.isNotEmpty) Text(aiExplanation),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openSuggestionsDialog,
                  icon: const Icon(Icons.tips_and_updates_outlined),
                  label: const Text('Suggestions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildSensorCard(
                    'Voltage',
                    voltage,
                    'V',
                    const Icon(Icons.bolt, size: 40, color: Colors.white),
                    Colors.orange.shade400,
                  ),
                  _buildSensorCard(
                    'Current',
                    current,
                    'A',
                    const Icon(Icons.flash_on, size: 40, color: Colors.white),
                    Colors.green.shade400,
                  ),
                  _buildSensorCard(
                    'Power',
                    power,
                    'W',
                    const Icon(Icons.electric_bolt, size: 40, color: Colors.white),
                    Colors.blue.shade400,
                  ),
                  _buildSensorCard(
                    'Units',
                    units,
                    'kWh',
                    const Icon(Icons.countertops, size: 40, color: Colors.white),
                    Colors.purple.shade400,
                  ),
                  _buildSensorCard(
                    'Bill',
                    bill,
                    'Rs',
                    const Text(
                      'Rs',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Colors.red.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(
      String title,
      String value,
      String unit,
      Widget icon,
      Color color,
      ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.isNotEmpty ? '$value $unit' : 'Loading...',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}