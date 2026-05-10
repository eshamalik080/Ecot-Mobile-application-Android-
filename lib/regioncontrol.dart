import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RegionControlPage extends StatefulWidget {
  @override
  _RegionControlPageState createState() => _RegionControlPageState();
}

class _RegionControlPageState extends State<RegionControlPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  String? selectedCountry;
  String? selectedCity;

  bool primaryLoad = false;
  bool sec1 = false;
  bool sec2 = false;
  bool overall = false;

  // Example static data (replace later with API response)
  final Map<String, List<String>> regions = {
    'Pakistan': [
      'Karachi',
      'Lahore',
      'Islamabad',
      'Faisalabad',
      'Rawalpindi',
      'Multan',
      'Hyderabad',
      'Peshawar',
      'Quetta',
      'Sialkot',
      'Gujranwala',
      'Bahawalpur',
      'Sukkur',
      'Sargodha',
      'Mardan',
      'Mingora',
      'Mirpur',
      'Jhang',
      'Dera Ghazi Khan',
      'Sheikhupura',
      'Taxila',
      'Wah Cantt',
      // add as many small/minor cities as needed
    ],
    'Bangladesh': [
      'Dhaka',
      'Chittagong',
      'Khulna',
      'Rajshahi',
      'Sylhet',
      'Barisal',
      'Rangpur',
      'Comilla',
      'Mymensingh',
      'Jessore',
      'Narayanganj',
      'Bogra',
    ],
    'Afghanistan': [
      'Kabul',
      'Kandahar',
      'Herat',
      'Mazar-i-Sharif',
      'Jalalabad',
      'Kunduz',
      'Ghazni',
      'Balkh',
    ],
    'Saudi Arabia': [
      'Riyadh',
      'Jeddah',
      'Mecca',
      'Medina',
      'Dammam',
      'Khobar',
      'Abha',
      'Tabuk',
    ],
    'United Arab Emirates': [
      'Dubai',
      'Abu Dhabi',
      'Sharjah',
      'Ajman',
      'Fujairah',
      'Ras Al Khaimah',
      'Umm Al Quwain',
    ],
    'Turkey': [
      'Istanbul',
      'Ankara',
      'Izmir',
      'Bursa',
      'Adana',
      'Gaziantep',
      'Konya',
      'Antalya',
    ],
    'Indonesia': [
      'Jakarta',
      'Surabaya',
      'Medan',
      'Bandung',
      'Makassar',
      'Semarang',
      'Palembang',
      'Bogor',
    ],
    'Malaysia': [
      'Kuala Lumpur',
      'George Town',
      'Johor Bahru',
      'Shah Alam',
      'Malacca City',
      'Kota Kinabalu',
      'Ipoh',
      'Kuching',
    ],
    'Egypt': [
      'Cairo',
      'Alexandria',
      'Giza',
      'Port Said',
      'Suez',
      'Luxor',
      'Aswan',
      'Mansoura',
    ],
    'Morocco': [
      'Casablanca',
      'Rabat',
      'Marrakech',
      'Fes',
      'Tangier',
      'Agadir',
      'Oujda',
      'Meknes',
    ],
  };

  /// 🔥 Update Firebase for all users in selected Country/City
  void updateSwitchForRegion(String field, bool value) async {
    if (selectedCountry == null || selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select Country & City")),
      );
      return;
    }

    DatabaseEvent event = await dbRef.once();
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> allUsers =
      event.snapshot.value as Map<dynamic, dynamic>;

      allUsers.forEach((key, userData) {
        if (userData["country"] == selectedCountry &&
            userData["city"] == selectedCity) {
          dbRef.child(key).update({field: value});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Updated $field for all users in $selectedCity"),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text("Choose $label"),
            underline: const SizedBox(),
            icon: Icon(icon ?? Icons.arrow_drop_down, color: Colors.orange),
            items: items.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: color ?? Colors.orange, size: 30),
        activeColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Region Control"),
        backgroundColor: Colors.orange.shade600,
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: const [
                  Icon(Icons.map, size: 90, color: Colors.orange),
                  SizedBox(height: 10),
                  Text(
                    "Region Control Panel",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Manage countries, cities and loads regionally.",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Country Dropdown
            _buildDropdown(
              label: "Country",
              value: selectedCountry,
              items: regions.keys.toList(),
              onChanged: (value) {
                setState(() {
                  selectedCountry = value;
                  selectedCity = null;
                });
              },
              icon: Icons.flag,
            ),
            const SizedBox(height: 20),

            // City Dropdown
            _buildDropdown(
              label: "City",
              value: selectedCity,
              items: selectedCountry == null
                  ? []
                  : regions[selectedCountry]!,
              onChanged: (value) => setState(() => selectedCity = value),
              icon: Icons.location_city,
            ),
            const SizedBox(height: 30),

            // Switches inside cards
            _buildSwitchCard(
              title: "Primary Load",
              value: primaryLoad,
              onChanged: (v) {
                setState(() => primaryLoad = v);
                updateSwitchForRegion("load1", v);
              },
              icon: Icons.bolt,
              color: Colors.blue,
            ),
            _buildSwitchCard(
              title: "Secondary Load 1",
              value: sec1,
              onChanged: (v) {
                setState(() => sec1 = v);
                updateSwitchForRegion("load2", v);
              },
              icon: Icons.lightbulb,
              color: Colors.green,
            ),
            _buildSwitchCard(
              title: "Secondary Load 2",
              value: sec2,
              onChanged: (v) {
                setState(() => sec2 = v);
                updateSwitchForRegion("load3", v);
              },
              icon: Icons.light,
              color: Colors.purple,
            ),
            _buildSwitchCard(
              title: "Overall Control",
              value: overall,
              onChanged: (v) {
                setState(() => overall = v);
                updateSwitchForRegion("overall", v);
              },
              icon: Icons.power_settings_new,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
