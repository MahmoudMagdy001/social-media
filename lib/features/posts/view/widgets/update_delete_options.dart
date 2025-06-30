import 'package:flutter/material.dart';

Future<dynamic> showOptions(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      alignment: Alignment.center,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: const Icon(
        Icons.check_circle,
        size: 60,
        color: Colors.green,
      ),
      title: const Text(
        'Success',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'Post deleted successfully.',
        style: TextStyle(
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'OK',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
      ],
    ),
  );
}
