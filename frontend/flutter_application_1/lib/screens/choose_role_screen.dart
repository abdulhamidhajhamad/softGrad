// lib/screens/choose_role_screen.dart
//
// Placeholder ChooseRoleScreen for PlanMyWedding app.

import 'package:flutter/material.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Role'),
        backgroundColor: const Color(0xFFB14E56),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'ChooseRoleScreen placeholder',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
