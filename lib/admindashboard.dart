import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'HomePage.dart';
import 'dashboard.dart'; // Import the Dashboard page
import 'SignupPage.dart'; // Import Signup page
import 'regioncontrol.dart'; // Import Region Control page
import 'inventory.dart'; // ✅ Import Inventory page
import 'consumptiondetails.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 50), // Space from top

            // Main content
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardCard(
                    title: "User Data",
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserListPage()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: "Create User",
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: "Region Control",
                    icon: Icons.map,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegionControlPage()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: "Inventory",
                    icon: Icons.inventory,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => InventoryPage()),
                      );
                    },
                  ),

                  _buildDashboardCard(
                    title: "Details",
                    icon: Icons.bar_chart,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConsumptionDetailsPage()),
                      );
                    },
                  ),

                ],
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                        (route) => false, // clear navigation stack
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  minimumSize: const Size(double.infinity, 50), // full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "LOGOUT",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Footer
            Center(
              child: Column(
                children: const [
                  Text(
                    "© Powered by ECon dev",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separate page for showing user list
class UserListPage extends StatelessWidget {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  void _confirmDelete(BuildContext context, String userKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "If you delete user, then it will permanently be removed from the system.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // ✅ First fetch the device_id before deleting
              final userSnapshot = await dbRef.child(userKey).get();
              if (userSnapshot.exists && userSnapshot.value != null) {
                final userData = userSnapshot.value as Map;
                final deviceId = userData["device_id"];

                // Delete user
                await dbRef.child(userKey).remove();

                // Mark device as inactive again
                if (deviceId != null) {
                  await dbRef.child("inventory/$deviceId").update({
                    "status": "inactive",
                  });
                }
              }

              Navigator.pop(context); // Close popup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User deleted and device reset.")),
              );
            },
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          const SizedBox(height: 50),
          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    !snapshot.hasError &&
                    snapshot.data?.snapshot.value != null) {
                  Map<dynamic, dynamic> data =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  List<String> userKeys = data.keys
                      .cast<String>()
                      .where((key) => key.endsWith("@gmail_com"))
                      .toList();

                  if (userKeys.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Gmail users found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: userKeys.length,
                    itemBuilder: (context, index) {
                      String userKey = userKeys[index];
                      Map<dynamic, dynamic> userData =
                      data[userKey] as Map<dynamic, dynamic>;

                      String name = userData["name"] ?? "Unknown";

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _confirmDelete(context, userKey),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.blue),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Dashboard(emailNode: userKey),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          const SizedBox(height: 10),

          // Footer
          Center(
            child: Column(
              children: const [
                Text(
                  "© Powered by ECon dev",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
