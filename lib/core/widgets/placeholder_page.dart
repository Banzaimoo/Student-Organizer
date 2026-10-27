import 'package:flutter/material.dart';

/// Temporary page used until a feature owner replaces it.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(subtitle ?? 'Segera hadir')),
    );
  }
}
