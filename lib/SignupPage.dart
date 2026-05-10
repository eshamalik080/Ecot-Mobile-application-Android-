import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admindashboard.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();

  bool _isPasswordVisible = false;

  String? selectedCountry;
  String? selectedCity;
  String? selectedDevice;

  List<String> deviceIds = []; // store device IDs from inventory

  // Example country & city data
  final Map<String, List<String>> countriesWithCities = {
    'Pakistan': ['Karachi', 'Lahore', 'Islamabad', 'Faisalabad', 'Rawalpindi'],
    'Bangladesh': ['Dhaka', 'Chittagong', 'Khulna'],
    'Afghanistan': ['Kabul', 'Kandahar', 'Herat'],
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Mecca'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
    'Turkey': ['Istanbul', 'Ankara', 'Izmir'],
    'Indonesia': ['Jakarta', 'Surabaya', 'Medan'],
    'Malaysia': ['Kuala Lumpur', 'George Town', 'Johor Bahru'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza'],
    'Morocco': ['Casablanca', 'Rabat', 'Marrakech'],
  };

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  // Fetch devices from inventory node
  // Fetch devices from inventory node (only inactive/false devices)
  void _fetchDevices() async {
    final snapshot = await _database.child("inventory").get();
    if (snapshot.exists && snapshot.value != null) {
      Map data = snapshot.value as Map;

      setState(() {
        deviceIds = data.entries
            .where((entry) =>
        entry.value is Map &&
            ((entry.value["status"] ?? "inactive") == "inactive" ||
                (entry.value["status"] ?? "false") == "false"))
            .map((entry) => entry.key.toString())
            .toList();
      });
    }
  }


  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Registering..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void _signUp(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        selectedCountry == null ||
        selectedCity == null ||
        selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    _showLoadingDialog();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final sanitizedEmail = email.replaceAll('.', '_');

      // Save user data with selected location & device
      await _database.child(sanitizedEmail).set({
        'name': name,
        'email': email,
        'voltage': '',
        'current': '',
        'power': '',
        'units': '',
        'bill': '',
        'load1': false,
        'load2': false,
        'load3': false,
        'overall': false,
        'country': selectedCountry,
        'city': selectedCity,
        'device_id': selectedDevice,
      });

      // 🔥 Mark selected device as active in inventory
      await _database.child("inventory/$selectedDevice").update({
        'status': 'active',
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.pop(context); // Back to login or dashboard
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign up failed: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: screenHeight * 0.4,
              decoration: const BoxDecoration(
                color: Color(0xFF056BB2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(150),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 40),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminDashboardPage()),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: ColorFiltered(
                      colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 40,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Create User",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Create a new user",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Form
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTextField(_nameController, "Name", Icons.person),
                  const SizedBox(height: 10),
                  _buildTextField(_emailController, "Email", Icons.email,
                      inputType: TextInputType.emailAddress),
                  const SizedBox(height: 10),

                  // Country Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCountry,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.flag, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: "Select Country",
                    ),
                    items: countriesWithCities.keys.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCountry = value;
                        selectedCity = null; // reset city
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // City Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      prefixIcon:
                      const Icon(Icons.location_city, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: "Select City",
                    ),
                    items: selectedCountry == null
                        ? []
                        : countriesWithCities[selectedCountry]!
                        .map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Device Dropdown (from inventory)
                  DropdownButtonFormField<String>(
                    value: selectedDevice,
                    decoration: InputDecoration(
                      prefixIcon:
                      const Icon(Icons.devices_other, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: "Select Device",
                    ),
                    items: deviceIds
                        .map((id) => DropdownMenuItem(
                      value: id,
                      child: Text(id),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDevice = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // Password Field (moved last)
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () => _signUp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4F84),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
