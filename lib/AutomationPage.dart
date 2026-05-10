import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AutomationPage extends StatefulWidget {
  final String emailNode;

  const AutomationPage({required this.emailNode, Key? key}) : super(key: key);

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool autoMode = false;
  bool peakSavingMode = false;
  bool allowLoad1 = true;
  bool allowLoad2 = true;
  bool allowLoad3 = true;
  final TextEditingController maxPowerController = TextEditingController();
  final TextEditingController maxBillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAutomationSettings();
  }

  Future<void> _loadAutomationSettings() async {
    final snapshot =
    await _database.child(widget.emailNode).child('automation').get();

    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    setState(() {
      autoMode = data['auto_mode'] ?? false;
      peakSavingMode = data['peak_saving_mode'] ?? false;
      allowLoad1 = data['allow_load1'] ?? true;
      allowLoad2 = data['allow_load2'] ?? true;
      allowLoad3 = data['allow_load3'] ?? true;
      maxPowerController.text = data['max_power']?.toString() ?? '';
      maxBillController.text = data['max_bill']?.toString() ?? '';
    });
  }

  Future<void> _saveAutomationSettings() async {
    await _database.child(widget.emailNode).child('automation').set({
      'auto_mode': autoMode,
      'peak_saving_mode': peakSavingMode,
      'allow_load1': allowLoad1,
      'allow_load2': allowLoad2,
      'allow_load3': allowLoad3,
      'max_power': maxPowerController.text.trim(),
      'max_bill': maxBillController.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Automation settings saved')),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }

  @override
  void dispose() {
    maxPowerController.dispose();
    maxBillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demand Response Automation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _switchTile('Enable Auto Mode', autoMode, (v) => autoMode = v),
          _switchTile('Peak Saving Mode', peakSavingMode, (v) => peakSavingMode = v),
          _switchTile('Allow Load 1 Auto Control', allowLoad1, (v) => allowLoad1 = v),
          _switchTile('Allow Load 2 Auto Control', allowLoad2, (v) => allowLoad2 = v),
          _switchTile('Allow Load 3 Auto Control', allowLoad3, (v) => allowLoad3 = v),
          const SizedBox(height: 16),
          TextField(
            controller: maxPowerController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Power Threshold (W)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: maxBillController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Bill Threshold (Rs)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveAutomationSettings,
            child: const Text('Save Automation Settings'),
          ),
        ],
      ),
    );
  }
}