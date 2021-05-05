import 'dart:convert';

import 'package:anna_chat/const/const.dart';
import 'package:anna_chat/model/chat_message.dart';
import 'package:anna_chat/state/state_manager.dart';
import 'package:anna_chat/ultils/ultils.dart';
import 'package:anna_chat/widgets/bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: must_be_immutable
class DetailScreen extends ConsumerWidget {
  DetailScreen({this.app, this.user});
  FirebaseApp app;
  User user;

  DatabaseReference offsetRef, chatRef;
  FirebaseDatabase database;

  TextEditingController textEditingController = new TextEditingController();
  ScrollController scrollController = new ScrollController();

  @override
  Widget build(BuildContext context, watch) {
    var friendUser = watch(chatUser).state;
    return Scaffold(
      appBar: AppBar(centerTitle: true,
      title: Text('${friendUser.firstName} ${friendUser.lastName}')
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                  flex: 8,
                  child: friendUser.uid != null
                      ? FirebaseAnimatedList(
                          controller: scrollController,
                          sort: (DataSnapshot a, DataSnapshot b) =>
                              b.key.compareTo(a.key),
                          reverse: true,
                          query: loadChatContent(context, app),
                          itemBuilder: (BuildContext context,
                              DataSnapshot snapshot,
                              Animation<double> animation,
                              int index) {
                            var chatContent = ChatMessage.fromJson(
                                json.decode(json.encode(snapshot.value)));

                            return SizeTransition(
                              sizeFactor: animation,
                              child: chatContent.picture
                                  ? chatContent.senderId == user.uid
                                      ? bubbleImageFromUser(chatContent)
                                      : bubbleImageFromFriend(chatContent)
                                  : chatContent.senderId == user.uid
                                      ? bubbleTextFromUser(chatContent)
                                      : bubbleTextFromFriend(chatContent),
                            );
                          },
                        )
                      : Center(child: CircularProgressIndicator())),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        decoration:
                            InputDecoration(hintText: 'Enter your message'),
                        controller: textEditingController,
                      ),
                    ),
                    IconButton(onPressed: () {}, icon: Icon(Icons.send))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  loadChatContent(BuildContext context, FirebaseApp app) {
    database = FirebaseDatabase(app: app);
    offsetRef = database.reference().child('.info/serverTimeOffset');
    chatRef = database
        .reference()
        .child(CHAT_REF)
        .child(getRoomId(user.uid, context.read(chatUser).state.uid))
        .child(DETAIL_REF);
    return chatRef;
  }
}
