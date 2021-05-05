import 'package:flutter/material.dart';

void showOnlySnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$message'),
    ),
  );
}

String getRoomId(String a, String b) {
  if (a.compareTo(b) > 0)
    return a + b;
  else
    return b + a;
}
