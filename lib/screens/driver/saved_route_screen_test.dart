import 'package:flutter/material.dart';
import '../../system/routing/app_routes.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final List<Map<String, dynamic>> savedTemplates = [
    {
      'id': '1',
      'name': 'Morning Commute',
      'start': 'Salt Lake Sector V',
      'end': 'Park Street Metro',
      'seats': 3,
    },
    {
      'id': '2',
      'name': 'Weekend Trip',
      'start': 'Kolkata Airport',
      'end': 'Digha Beach',
      'seats': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Saved Routes',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: savedTemplates.length,
        itemBuilder: (context, index) {
          final item = savedTemplates[index];
          return Container(
            // FIX: Use .only(bottom: 16) instead of .bottom(16)
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('From: ${item['start']}'),
                  Text('To: ${item['end']}'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Use template logic
                Navigator.pop(context, item);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () {
          // Navigates to Create Route Screen using your Router
          Navigator.pushNamed(context, AppRoutes.createDriverRoute);
        },
        label: const Text('Add New Route'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}