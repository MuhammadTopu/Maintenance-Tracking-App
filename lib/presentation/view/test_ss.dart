import 'package:flutter/material.dart';

class KeyboardTestScreen extends StatelessWidget {
  const KeyboardTestScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: TextField(),
      ),
    ),
  );
}