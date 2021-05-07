import 'dart:convert';
import 'dart:io';

import 'package:anna_chat/const/const.dart';
import 'package:anna_chat/model/chat_info.dart';
import 'package:anna_chat/model/chat_message.dart';
import 'package:anna_chat/screen/camera_screen.dart';
import 'package:anna_chat/state/state_manager.dart';
import 'package:anna_chat/ultils/ultils.dart';
import 'package:anna_chat/widgets/bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

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

    var isShowPicture = watch(isCapture).state;

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
                  flex: isShowPicture ? 2 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isShowPicture
                          ? Container(
                              width: 80,
                              height: 80,
                              child: Stack(
                                children: [
                                  Image.file(
                                      File(context
                                          .read(thumbnailImage)
                                          .state
                                          .path),
                                      fit: BoxFit.fill),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                        onPressed: () {
                                          context.read(isCapture).state = false;
                                        },
                                        icon: Icon(Icons.clear,
                                            color: Colors.black)),
                                  )
                                ],
                              ),
                            )
                          : Container(),
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  showBottomSheetPicture(context);
                                },
                                icon: Icon(Icons.add_a_photo)),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.multiline,
                                expands: true,
                                minLines: null,
                                maxLines: null,
                                decoration: InputDecoration(
                                    hintText: 'Enter your message'),
                                controller: textEditingController,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  offsetRef
                                      .once()
                                      .then((DataSnapshot snapshot) {
                                    var offset = snapshot.value as int;
                                    var estimatedServerTimeInMs =
                                        DateTime.now().millisecondsSinceEpoch +
                                            offset;

                                    submitChat(
                                        context, estimatedServerTimeInMs);
                                  });

                                  //Auto scroll chat layout to end
                                  autoScroll(scrollController);
                                },
                                icon: Icon(Icons.send))
                          ],
                        ),
                      )
                    ],
                  ))
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

  void showBottomSheetPicture(BuildContext context) async {
    // ignore: unused_local_variable
    final result = await showSlidingBottomSheet(context, builder: (context) {
      return SlidingSheetDialog(
        elevation: 8,
        cornerRadius: 16,
        snapSpec: const SnapSpec(
            snap: true,
            snappings: [0.2],
            positioning: SnapPositioning.relativeToAvailableSpace),
        builder: (context, state) {
          return Container(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await navigateCamera(context);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.camera),
                          SizedBox(width: 20),
                          Text(
                            'Camera',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(Icons.photo),
                          SizedBox(width: 20),
                          Text(
                            'Photo',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          );
        },
      );
    });
  }

  navigateCamera(BuildContext context) async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => MyCameraPage()));

    //Set state
    context.read(thumbnailImage).state = result;
    context.read(isCapture).state = true;

    Navigator.pop(context); //Close sliding_sheet
  }
}
