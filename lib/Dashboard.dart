import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart';
import 'LoginPage.dart';
import 'ReportsPage.dart';
import 'BillingAnalysisPage.dart';
import 'AutomationPage.dart';
import 'UtilityIntegrationPage.dart';

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
  bool load1 = false, load2 = false, load3 = false, overall = false;

  double anomalyScore = 0.0;
  double theftScore = 0.0;
  String aiStatus = 'normal';
  String aiReason = '';
  String aiExplanation = '';
  String alertLevel = 'normal';
  String tariffInfo = '';
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

      final suggestionRaw = data['suggestion'];
      final suggestion = suggestionRaw is Map
          ? Map<String, dynamic>.from(suggestionRaw)
          : <String, dynamic>{};

      final tariffRaw = suggestion['tariff'];
      String parsedTariffInfo = '';

      if (tariffRaw is Map) {
        final tariffMap = Map<String, dynamic>.from(tariffRaw);
        parsedTariffInfo = tariffMap.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
      } else {
        parsedTariffInfo = tariffRaw?.toString() ?? '';
      }

      setState(() {
        name = data['name']?.toString() ?? '';
        voltage = data['voltage']?.toString() ?? '';
        current = data['current']?.toString() ?? '';
        power = data['power']?.toString() ?? '';
        units = data['units']?.toString() ?? '';
        bill = data['bill']?.toString() ?? '';

        load1 = data['load1'] == true;
        load2 = data['load2'] == true;
        load3 = data['load3'] == true;
        overall = data['overall'] == true;

        anomalyScore = _toDouble(suggestion['anomaly_score']);
        theftScore = _toDouble(suggestion['theft_score']);
        aiStatus = suggestion['status']?.toString() ?? 'normal';
        aiReason = suggestion['reason']?.toString() ?? '';
        aiExplanation = suggestion['suggestion']?.toString() ?? '';
        alertLevel = suggestion['alert_level']?.toString() ?? 'normal';
        tariffInfo = parsedTariffInfo;
        aiUpdatedAt = _toInt(suggestion['updated_at']);
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

  String _normalizeLevel(String value) {
    final level = value.toLowerCase().trim();

    if (level == 'critical' ||
        level == 'danger' ||
        level == 'possible_theft') {
      return 'critical';
    }
    if (level == 'warning' ||
        level == 'anomaly' ||
        level == 'suspicious') {
      return 'warning';
    }
    if (level == 'info' || level == 'minor_deviation') {
      return 'info';
    }
    return 'normal';
  }

  String _getCombinedLevel() {
    return _normalizeLevel(alertLevel);
  }

  String _buildAlertTitle() {
    final level = _getCombinedLevel();

    if (level == 'critical') {
      if (aiStatus.toLowerCase().contains('theft') || theftScore >= 0.70) {
        return 'Possible Theft Detected';
      }
      return 'Critical Energy Alert';
    }

    if (level == 'warning') {
      if (aiStatus.toLowerCase().contains('anomaly')) {
        return 'Anomaly Detected';
      }
      if (aiStatus.toLowerCase().contains('theft') || theftScore >= 0.45) {
        return 'Suspicious Activity Detected';
      }
      return 'Warning Alert';
    }

    if (level == 'info') {
      return 'Minor Deviation Detected';
    }

    return 'System Normal';
  }

  String _buildAlertMessage() {
    return 'Theft Score: ${theftScore.toStringAsFixed(2)}\n'
        'Anomaly Score: ${anomalyScore.toStringAsFixed(2)}\n'
        'Alert Level: ${alertLevel.isEmpty ? "normal" : alertLevel}\n'
        'Status: $aiStatus\n'
        'Reason: ${aiReason.isEmpty ? "N/A" : aiReason}\n'
        'Suggestion: ${aiExplanation.isEmpty ? "N/A" : aiExplanation}';
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
    const androidNotificationDetails = AndroidNotificationDetails(
      'ecot_alerts',
      'E-Cot Alerts',
      channelDescription: 'Alerts for anomaly and theft detection',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
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

    final color = level == 'critical' ? Colors.red : Colors.orange;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final suggestionRef = FirebaseDatabase.instance
        .ref()
        .child(widget.emailNode)
        .child('suggestion');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              if (rawData is! Map) {
                return const Text('No suggestions available.');
              }

              final suggestionData = Map<String, dynamic>.from(rawData);

              final popupAlertLevel =
                  suggestionData['alert_level']?.toString() ?? 'normal';
              final popupStatus = suggestionData['status']?.toString() ?? '';
              final popupReason = suggestionData['reason']?.toString() ?? '';
              final popupSummary =
                  suggestionData['suggestion']?.toString() ?? '';
              final popupAnomaly =
              _toDouble(suggestionData['anomaly_score']).toStringAsFixed(2);
              final popupTheft =
              _toDouble(suggestionData['theft_score']).toStringAsFixed(2);

              final popupTariffRaw = suggestionData['tariff'];
              String popupTariff = '';

              if (popupTariffRaw is Map) {
                final tariffMap = Map<String, dynamic>.from(popupTariffRaw);
                popupTariff = tariffMap.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n');
              } else {
                popupTariff = popupTariffRaw?.toString() ?? '';
              }

              List<String> suggestions = [];
              final actionItemsRaw = suggestionData['action_items'];

              if (actionItemsRaw is List) {
                suggestions = actionItemsRaw
                    .where((item) => item != null)
                    .map((item) => item.toString())
                    .where((text) => text.trim().isNotEmpty)
                    .toList();
              } else if (actionItemsRaw is Map) {
                final map = Map<dynamic, dynamic>.from(actionItemsRaw);
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

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogInfoRow('Alert Level', popupAlertLevel),
                    _dialogInfoRow('Status', popupStatus),
                    _dialogInfoRow('Anomaly Score', popupAnomaly),
                    _dialogInfoRow('Theft Score', popupTheft),
                    if (popupReason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Reason',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(popupReason),
                    ],
                    if (popupSummary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Suggestion Summary',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(popupSummary),
                    ],
                    if (popupTariff.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Tariff',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(popupTariff),
                    ],
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Action Items',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...suggestions.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}. ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(child: Text(entry.value)),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      const SizedBox(height: 10),
                      const Text('No action items available.'),
                    ],
                  ],
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

  Widget _dialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value.isEmpty ? 'N/A' : value),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLoad(String key, bool value) async {
    await _database.child(widget.emailNode).update({key: value});
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Color _aiStatusColor() {
    switch (_getCombinedLevel()) {
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
    switch (_getCombinedLevel()) {
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
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
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
                    Text('Alert Level: ${alertLevel.isEmpty ? "normal" : alertLevel}'),
                    Text('Theft Score: ${theftScore.toStringAsFixed(2)}'),
                    Text('Anomaly Score: ${anomalyScore.toStringAsFixed(2)}'),
                    Text('Status: $aiStatus'),
                    if (aiReason.isNotEmpty) Text('Reason: $aiReason'),
                    if (aiExplanation.isNotEmpty) Text(aiExplanation),
                    if (tariffInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        tariffInfo,
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _navButton(
                    'Suggestions',
                    Icons.tips_and_updates_outlined,
                    _openSuggestionsDialog,
                  ),
                  _navButton(
                    'Reports',
                    Icons.picture_as_pdf_outlined,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportsPage(emailNode: widget.emailNode),
                        ),
                      );
                    },
                  ),
                  _navButton(
                    'Billing',
                    Icons.bar_chart,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillingAnalysisPage(
                            emailNode: widget.emailNode,
                          ),
                        ),
                      );
                    },
                  ),
                  _navButton(
                    'Automation',
                    Icons.settings_remote,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AutomationPage(emailNode: widget.emailNode),
                        ),
                      );
                    },
                  ),
                  _navButton(
                    'Utility',
                    Icons.business,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UtilityIntegrationPage(
                            emailNode: widget.emailNode,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

              const SizedBox(height: 30),

              Column(
                children: [
                  _buildSwitchTile('Primary Load', load1, (val) {
                    setState(() => load1 = val);
                    _updateLoad('load1', val);
                  }),
                  const SizedBox(height: 10),
                  _buildSwitchTile('Secondary Load 1', load2, (val) {
                    setState(() => load2 = val);
                    _updateLoad('load2', val);
                  }),
                  const SizedBox(height: 10),
                  _buildSwitchTile('Secondary Load 2', load3, (val) {
                    setState(() => load3 = val);
                    _updateLoad('load3', val);
                  }),
                  const SizedBox(height: 10),
                  _buildSwitchTile('Full Meter Control', overall, (val) {
                    setState(() => overall = val);
                    _updateLoad('overall', val);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSwitchTile(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Colors.green.shade300 : Colors.red.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}