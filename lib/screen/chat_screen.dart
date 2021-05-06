import 'dart:convert';

import 'package:anna_chat/const/const.dart';
import 'package:anna_chat/model/chat_info.dart';
import 'package:anna_chat/model/chat_message.dart';
import 'package:anna_chat/state/state_manager.dart';
import 'package:anna_chat/ultils/ultils.dart';
import 'package:anna_chat/widgets/bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(
          centerTitle: true,
          title: Text('${friendUser.firstName} ${friendUser.lastName}')),
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
                    IconButton(
                        onPressed: () {
                          offsetRef.once().then((DataSnapshot snapshot) {
                            var offset = snapshot.value as int;
                            var estimatedServerTimeInMs =
                                DateTime.now().millisecondsSinceEpoch + offset;

                            submitChat(context, estimatedServerTimeInMs);
                          });

                          //Auto scroll chat layout to end
                          autoScroll(scrollController);
                        },
                        icon: Icon(Icons.send))
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

  void submitChat(BuildContext context, int estimatedServerTimeInMs) {
    ChatMessage chatMessage = ChatMessage();
    chatMessage.name = createName(context.read(userLogged).state);
    chatMessage.content = textEditingController.text;
    chatMessage.timeStamp = estimatedServerTimeInMs;
    chatMessage.senderId = user.uid;

    //Image and text
    chatMessage.picture = false;
    submitChatToFirebase(context, chatMessage, estimatedServerTimeInMs);
  }

  void submitChatToFirebase(BuildContext context, ChatMessage chatMessage,
      int estimatedServerTimeInMs) {
    chatRef.once().then((DataSnapshot snapshot) {
      if (snapshot != null)
        //If user already create chat before
        createChat(context, chatMessage, estimatedServerTimeInMs);
    });
  }

  void createChat(BuildContext context, ChatMessage chatMessage,
      int estimatedServerTimeInMs) {
    //Create chat info
    ChatInfo chatInfo = new ChatInfo(
        createId: user.uid,
        friendName: createName(context.read(chatUser).state),
        friendId: context.read(chatUser).state.uid,
        createName: createName(context.read(userLogged).state),
        lastMessage: chatMessage.picture ? '<Image>' : chatMessage.content,
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
        createDate: DateTime.now().millisecondsSinceEpoch);

    //Add on firebase
    database
        .reference()
        .child(CHATLIST_REF)
        .child(user.uid)
        .child(context.read(chatUser).state.uid)
        .set(<String, dynamic>{
      'lastUpdate': chatInfo.lastUpdate,
      'lastMessage': chatInfo.lastMessage,
      'createId': chatInfo.createId,
      'friendId': chatInfo.friendId,
      'createName': chatInfo.createName,
      'friendName': chatInfo.friendName,
      'createDate': chatInfo.createDate,
    }).then((value) {
      //After success copy to Friend chatlist
      database
          .reference()
          .child(CHATLIST_REF)
          .child(context.read(chatUser).state.uid)
          .child(user.uid)
          .set(<String, dynamic>{
        'lastUpdate': chatInfo.lastUpdate,
        'lastMessage': chatInfo.lastMessage,
        'createId': chatInfo.createId,
        'friendId': chatInfo.friendId,
        'createName': chatInfo.createName,
        'friendName': chatInfo.friendName,
        'createDate': chatInfo.createDate,
      }).then((value) {
        //After success, add on Chat Reference
        chatRef.push().set(<String, dynamic>{
          'uid': chatMessage.uid,
          'name': chatMessage.name,
          'content': chatMessage.content,
          'pictureLink': chatMessage.pictureLink,
          'picture': chatMessage.picture,
          'senderId': chatMessage.senderId,
          'timeStamp': chatMessage.timeStamp,
        }).then((value) {
          //Clear text content
          textEditingController.text = '';
          //Auto scroll
          autoScrollReverse(scrollController);
        }).catchError((e) => showOnlySnackBar(context, 'Error submit chatRef'));
      }).catchError((e) =>
              showOnlySnackBar(context, 'Error can\'t submit Friend ChatList'));
    }).catchError((e) =>
            showOnlySnackBar(context, 'Error can\'t submit User ChatList'));
  }
}
