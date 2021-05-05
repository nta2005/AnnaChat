import 'dart:async';

import 'package:anna_chat/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

String createName(UserModel user) {
  return '${user.firstName} ${user.lastName}';
}

void autoScroll(ScrollController scrollController) {
  Timer(Duration(milliseconds: 100), () {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
  });
}

void autoScrollReverse(ScrollController scrollController) {
  Timer(Duration(milliseconds: 100), () {
    scrollController.animateTo(0,
        duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
  });
}
