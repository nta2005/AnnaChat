import 'dart:convert';
import 'dart:math';

import 'package:anna_chat/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Widget loadPeople(DatabaseReference peopleRef) {
  return StreamBuilder(
    stream: peopleRef.onValue,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        List<UserModel> userModels = <UserModel>[];
        Map<dynamic, dynamic> values = snapshot.data.snapshot.value;
        values.forEach((key, value) {
          if (key != FirebaseAuth.FirebaseAuth.instance.currentUser.uid) {
            var userModel = UserModel.fromJson(json.decode(json.encode(value)));
            userModel.uid = key;
            userModels.add(userModel);
          }
        });
        return ListView.builder(
          itemCount: userModels.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {},
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors
                          .primaries[Random().nextInt(Colors.primaries.length)],
                      child: Text(
                          '${userModels[index].firstName.substring(0, 1)}',
                          style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      '${userModels[index].firstName} ${userModels[index].lastName}',
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      '${userModels[index].phone}',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  Divider(thickness: 2)
                ],
              ),
            );
          },
        );
      } else
        return Center(child: CircularProgressIndicator());
    },
  );
}

Widget loadChatList(FirebaseDatabase database, DatabaseReference chatListRef) {
  return Center(child: CircularProgressIndicator());
}
