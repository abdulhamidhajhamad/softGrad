import 'package:flutter/material.dart';

class VendorProfilePage extends StatelessWidget {
  final String title;

  const VendorProfilePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Vendor Profile Page for $title')),
    );
  }
}
