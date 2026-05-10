import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ConsumptionDetailsPage extends StatelessWidget {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  ConsumptionDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Consumption Details"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text("No data found",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          Map<dynamic, dynamic> data =
          snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Extract users data
          List<Map<String, dynamic>> userList = [];
          data.forEach((key, value) {
            if (key.toString().contains("@gmail_com")) {
              Map<dynamic, dynamic> userData = value;
              userList.add({
                "name": userData["name"] ?? "Unknown",
                "power": userData["power"] ?? "0",
                "units": userData["units"] ?? "0",
                "current": userData["current"] ?? "0",
                "bill": userData["bill"] ?? "0",
              });
            }
          });

          if (userList.isEmpty) {
            return const Center(
              child: Text("No users found",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // horizontal scroll for all
              child: Column(
                children: [
                  // Table Header
                  Container(
                    width: 650, // enough width to fit all columns
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                            flex: 3,
                            child: Text("Name",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text("Power (W)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text("Units (kWh)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text("Current (A)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text("Bill (Rs.)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Table Body
                  SizedBox(
                    width: 650,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: ListView.builder(
                      itemCount: userList.length,
                      itemBuilder: (context, index) {
                        final user = userList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(user["name"])),
                                Expanded(
                                    flex: 2,
                                    child: Text(user["power"].toString())),
                                Expanded(
                                    flex: 2,
                                    child: Text(user["units"].toString())),
                                Expanded(
                                    flex: 2,
                                    child: Text(user["current"].toString())),
                                Expanded(
                                    flex: 2,
                                    child: Text(user["bill"].toString())),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
