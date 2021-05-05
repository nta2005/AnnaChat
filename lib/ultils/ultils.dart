import 'package:flutter/material.dart';

void showOnlySnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$message'),
    ),
  );
}
