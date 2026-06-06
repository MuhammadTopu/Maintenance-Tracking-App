import 'package:flutter/material.dart';

class PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isValid;

  const PasswordRequirement({
    super.key,
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 18,
          color: isValid ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}