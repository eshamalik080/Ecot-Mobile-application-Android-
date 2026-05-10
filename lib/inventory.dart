import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref().child("inventory");

  String? selectedType;
  DateTime? selectedDate;
  String? productId;

  // Generate next product ID
  Future<String> _generateProductId() async {
    DataSnapshot snapshot = await dbRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      return "ECO-00001"; // First ID
    }

    Map data = snapshot.value as Map;
    List<String> keys = data.keys.cast<String>().toList();

    keys.sort();
    String lastKey = keys.last;

    int lastNum = int.parse(lastKey.split("-")[1]);
    int nextNum = lastNum + 1;

    return "ECO-${nextNum.toString().padLeft(5, "0")}";
  }

  // Save device
  void _saveDevice() async {
    if (selectedDate == null || selectedType == null || productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    await dbRef.child(productId!).set({
      "manufactured_date": DateFormat("yyyy-MM-dd").format(selectedDate!),
      "type": selectedType,
      "status": "inactive", // default status
    });

    Navigator.pop(context);
  }

  // Delete device only if inactive
  void _deleteDevice(String id, Map data) async {
    if (data["status"] == "active") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Active devices cannot be deleted")),
      );
      return;
    }

    await dbRef.child(id).remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Device $id deleted")),
    );
  }

  // Show popup
  void _showCreateDeviceDialog() async {
    String newId = await _generateProductId();
    setState(() {
      productId = newId;
      selectedDate = null;
      selectedType = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Create Device"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: productId,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Product ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Manufactured Date",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat("yyyy-MM-dd").format(selectedDate!)
                            : "Select Date",
                        style: TextStyle(
                          color: selectedDate != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedType,
                    items: ["Domestic", "Industrial"]
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedType = val;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _saveDevice,
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Widget for each device card
  Widget _buildDeviceCard(String id, Map data) {
    bool isActive = data["status"] == "active";

    return Container(
      margin: const EdgeInsets.all(8),
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // status circle (top-left)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // delete button (top-right)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(Icons.delete,
                  color: isActive ? Colors.grey : Colors.red),
              onPressed: isActive
                  ? null
                  : () {
                _deleteDevice(id, data);
              },
            ),
          ),

          // Device content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Type: ${data['type']}"),
                const SizedBox(height: 4),
                Text("Date: ${data['manufactured_date']}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Inventory"),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showCreateDeviceDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: dbRef.onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data.snapshot.value == null) {
            return const Center(
              child: Text("No devices yet",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          Map data = snapshot.data.snapshot.value as Map;
          List<Widget> cards = [];

          data.forEach((key, value) {
            cards.add(_buildDeviceCard(key, value));
          });

          return GridView.count(
            crossAxisCount: 2,
            children: cards,
          );
        },
      ),
    );
  }
}
