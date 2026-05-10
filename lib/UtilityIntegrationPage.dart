import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UtilityIntegrationPage extends StatefulWidget {
  final String emailNode;

  const UtilityIntegrationPage({
    Key? key,
    required this.emailNode,
  }) : super(key: key);

  @override
  State<UtilityIntegrationPage> createState() => _UtilityIntegrationPageState();
}

class _UtilityIntegrationPageState extends State<UtilityIntegrationPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final TextEditingController _utilityCompanyController =
  TextEditingController();
  final TextEditingController _providerCodeController = TextEditingController();
  final TextEditingController _meterNumberController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  final TextEditingController _baseTariffController = TextEditingController();
  final TextEditingController _peakTariffController = TextEditingController();
  final TextEditingController _offPeakTariffController =
  TextEditingController();
  final TextEditingController _monthlyLimitController = TextEditingController();
  final TextEditingController _peakStartController = TextEditingController();
  final TextEditingController _peakEndController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _demandResponseEnabled = false;
  bool _utilityAlertsEnabled = true;
  bool _autoDisconnectOnPeak = false;
  bool _allowRemoteUtilityCommand = false;

  String _selectedBillingCycle = 'Monthly';
  String _selectedTariffType = 'Residential';

  final List<String> _billingCycles = [
    'Monthly',
    'Bi-Monthly',
    'Quarterly',
  ];

  final List<String> _tariffTypes = [
    'Residential',
    'Commercial',
    'Industrial',
    'Time Of Use',
  ];

  @override
  void initState() {
    super.initState();
    _loadUtilityData();
  }

  @override
  void dispose() {
    _utilityCompanyController.dispose();
    _providerCodeController.dispose();
    _meterNumberController.dispose();
    _accountNumberController.dispose();
    _customerNameController.dispose();
    _regionController.dispose();
    _baseTariffController.dispose();
    _peakTariffController.dispose();
    _offPeakTariffController.dispose();
    _monthlyLimitController.dispose();
    _peakStartController.dispose();
    _peakEndController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUtilityData() async {
    try {
      final snapshot = await _database
          .child(widget.emailNode)
          .child('utility_integration')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        _utilityCompanyController.text =
            data['utility_company']?.toString() ?? '';
        _providerCodeController.text = data['provider_code']?.toString() ?? '';
        _meterNumberController.text = data['meter_number']?.toString() ?? '';
        _accountNumberController.text =
            data['account_number']?.toString() ?? '';
        _customerNameController.text =
            data['customer_name']?.toString() ?? '';
        _regionController.text = data['region']?.toString() ?? '';

        _baseTariffController.text = data['base_tariff']?.toString() ?? '';
        _peakTariffController.text = data['peak_tariff']?.toString() ?? '';
        _offPeakTariffController.text =
            data['off_peak_tariff']?.toString() ?? '';
        _monthlyLimitController.text =
            data['monthly_limit_kwh']?.toString() ?? '';
        _peakStartController.text = data['peak_start']?.toString() ?? '';
        _peakEndController.text = data['peak_end']?.toString() ?? '';
        _notesController.text = data['notes']?.toString() ?? '';

        _demandResponseEnabled = data['demand_response_enabled'] == true;
        _utilityAlertsEnabled = data['utility_alerts_enabled'] != false;
        _autoDisconnectOnPeak = data['auto_disconnect_on_peak'] == true;
        _allowRemoteUtilityCommand =
            data['allow_remote_utility_command'] == true;

        final billingCycle = data['billing_cycle']?.toString() ?? 'Monthly';
        final tariffType = data['tariff_type']?.toString() ?? 'Residential';

        if (_billingCycles.contains(billingCycle)) {
          _selectedBillingCycle = billingCycle;
        }

        if (_tariffTypes.contains(tariffType)) {
          _selectedTariffType = tariffType;
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load utility data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUtilityData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _database.child(widget.emailNode).child('utility_integration').set({
        'utility_company': _utilityCompanyController.text.trim(),
        'provider_code': _providerCodeController.text.trim(),
        'meter_number': _meterNumberController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'customer_name': _customerNameController.text.trim(),
        'region': _regionController.text.trim(),
        'billing_cycle': _selectedBillingCycle,
        'tariff_type': _selectedTariffType,
        'base_tariff': _parseDouble(_baseTariffController.text),
        'peak_tariff': _parseDouble(_peakTariffController.text),
        'off_peak_tariff': _parseDouble(_offPeakTariffController.text),
        'monthly_limit_kwh': _parseDouble(_monthlyLimitController.text),
        'peak_start': _peakStartController.text.trim(),
        'peak_end': _peakEndController.text.trim(),
        'demand_response_enabled': _demandResponseEnabled,
        'utility_alerts_enabled': _utilityAlertsEnabled,
        'auto_disconnect_on_peak': _autoDisconnectOnPeak,
        'allow_remote_utility_command': _allowRemoteUtilityCommand,
        'notes': _notesController.text.trim(),
        'updated_at': ServerValue.timestamp,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utility settings saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save utility settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueGrey.shade700),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.blue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Utility Integration'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey.shade800,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionCard(
                title: 'Utility Provider',
                icon: Icons.business,
                children: [
                  _buildTextField(
                    controller: _utilityCompanyController,
                    label: 'Utility Company Name',
                    hint: 'e.g. IESCO, K-Electric, LESCO',
                  ),
                  _buildTextField(
                    controller: _providerCodeController,
                    label: 'Provider Code',
                    hint: 'Optional internal provider code',
                  ),
                  _buildTextField(
                    controller: _customerNameController,
                    label: 'Customer Name',
                    hint: 'Name registered with utility company',
                  ),
                  _buildTextField(
                    controller: _regionController,
                    label: 'Region / City',
                    hint: 'e.g. Rawalpindi',
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Meter & Account',
                icon: Icons.electric_meter,
                children: [
                  _buildTextField(
                    controller: _meterNumberController,
                    label: 'Meter Number',
                    hint: 'Enter utility meter number',
                  ),
                  _buildTextField(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    hint: 'Enter billing account number',
                  ),
                  _buildDropdown(
                    title: 'Billing Cycle',
                    value: _selectedBillingCycle,
                    items: _billingCycles,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedBillingCycle = value;
                      });
                    },
                  ),
                  _buildDropdown(
                    title: 'Tariff Type',
                    value: _selectedTariffType,
                    items: _tariffTypes,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedTariffType = value;
                      });
                    },
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Tariff Settings',
                icon: Icons.currency_exchange,
                children: [
                  _buildTextField(
                    controller: _baseTariffController,
                    label: 'Base Tariff (per kWh)',
                    hint: 'e.g. 35',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _buildTextField(
                    controller: _peakTariffController,
                    label: 'Peak Tariff (per kWh)',
                    hint: 'e.g. 45',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _buildTextField(
                    controller: _offPeakTariffController,
                    label: 'Off-Peak Tariff (per kWh)',
                    hint: 'e.g. 28',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _buildTextField(
                    controller: _monthlyLimitController,
                    label: 'Monthly Limit (kWh)',
                    hint: 'Optional monthly target',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Peak Hours & Demand Response',
                icon: Icons.schedule,
                children: [
                  _buildTextField(
                    controller: _peakStartController,
                    label: 'Peak Start Time',
                    hint: 'e.g. 18:00',
                  ),
                  _buildTextField(
                    controller: _peakEndController,
                    label: 'Peak End Time',
                    hint: 'e.g. 22:00',
                  ),
                  _buildSwitchTile(
                    title: 'Enable Demand Response',
                    subtitle:
                    'Allow the system to optimize loads during peak demand.',
                    value: _demandResponseEnabled,
                    onChanged: (value) {
                      setState(() {
                        _demandResponseEnabled = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  _buildSwitchTile(
                    title: 'Auto Disconnect On Peak',
                    subtitle:
                    'Automatically reduce non-critical loads during peak tariff hours.',
                    value: _autoDisconnectOnPeak,
                    onChanged: (value) {
                      setState(() {
                        _autoDisconnectOnPeak = value;
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                  _buildSwitchTile(
                    title: 'Allow Remote Utility Command',
                    subtitle:
                    'Reserve for future backend/API integration with utility provider.',
                    value: _allowRemoteUtilityCommand,
                    onChanged: (value) {
                      setState(() {
                        _allowRemoteUtilityCommand = value;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  _buildSwitchTile(
                    title: 'Enable Utility Alerts',
                    subtitle:
                    'Receive tariff updates, warnings, and demand-response alerts.',
                    value: _utilityAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _utilityAlertsEnabled = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              _buildSectionCard(
                title: 'Additional Notes',
                icon: Icons.notes,
                children: [
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Store tariff notes, slab details, or internal remarks',
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveUtilityData,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}