import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientDetailsPage extends StatefulWidget {
  final String emailNode;

  PatientDetailsPage({required this.emailNode});

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _database = FirebaseDatabase.instance.ref();

  String name = '', disease = '', age = '', city = '';

  @override
  void initState() {
    super.initState();
    fetchPatientDetails();
  }

  void fetchPatientDetails() {
    _database.child(widget.emailNode).once().then((snapshot) {
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        setState(() {
          name = data['name'] ?? '';
          disease = data['disease'] ?? '';
          age = data['age'] ?? '';
          city = data['city'] ?? '';
        });
      }
    });
  }

  Widget buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.isNotEmpty ? value : 'Loading...'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildInfoTile("Patient Name", name),
            buildInfoTile("Disease", disease),
            buildInfoTile("Age", age),
            buildInfoTile("City", city),
          ],
        ),
      ),
    );
  }
}
