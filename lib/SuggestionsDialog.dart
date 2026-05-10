import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SuggestionsDialog extends StatelessWidget {
  final String emailNode;

  const SuggestionsDialog({super.key, required this.emailNode});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference suggestionRef = FirebaseDatabase.instance
        .ref()
        .child(emailNode)
        .child('suggestion')
        .child('action_items');

    return AlertDialog(
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
                  .toList();
            } else if (rawData is Map) {
              final map = Map<dynamic, dynamic>.from(rawData);
              final sortedKeys = map.keys.toList()..sort((a, b) {
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}