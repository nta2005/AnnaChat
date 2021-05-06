import 'package:anna_chat/const/const.dart';
import 'package:anna_chat/model/user_model.dart';
import 'package:anna_chat/screen/chat_screen.dart';
import 'package:anna_chat/screen/register_screen.dart';
import 'package:anna_chat/ultils/ultils.dart';
import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:firebase_auth_ui/providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:page_transition/page_transition.dart';

import 'firebase_ultils/firebase_ultils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp(app: app)));
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  FirebaseApp app;
  MyApp({this.app});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/register':
            return PageTransition(
                child: RegisterScreen(
                    app: app,
                    user:
                        FirebaseAuth.FirebaseAuth.instance.currentUser ?? null),
                type: PageTransitionType.fade,
                settings: settings);
            break;

          case '/detail':
            return PageTransition(
                child: DetailScreen(
                    app: app,
                    user:
                        FirebaseAuth.FirebaseAuth.instance.currentUser ?? null),
                type: PageTransitionType.fade,
                settings: settings);
            break;

          default:
            return null;
        }
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.app}) : super(key: key);

  final FirebaseApp app;
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  DatabaseReference peopleRef, chatListRef;
  FirebaseDatabase database;

  bool isUserInit = false;

  UserModel userLogged;

  final List<Tab> tabs = <Tab>[
    Tab(
      icon: Icon(Icons.chat),
      text: 'Chat',
    ),
    Tab(
      icon: Icon(Icons.people),
      text: 'Friend',
    )
  ];

  TabController tabController;
  @override
  void initState() {
    super.initState();

    tabController = TabController(length: tabs.length, vsync: this);

    database = FirebaseDatabase(app: widget.app);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      processLogin(context);
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text(widget.title),
        bottom: new TabBar(
          isScrollable: false,
          unselectedLabelColor: Colors.black45,
          labelColor: Colors.white,
          tabs: tabs,
          controller: tabController,
        ),
      ),
      body: isUserInit
          ? TabBarView(
              controller: tabController,
              children: tabs.map((Tab tab) {
                if (tab.text == 'Chat')
                  return loadChatList(database, chatListRef);
                else
                  return loadPeople(database,peopleRef);
              }).toList())
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  void processLogin(BuildContext context) async {
    var user = FirebaseAuth.FirebaseAuth.instance.currentUser;
    if (user == null) //if not login
    {
      FirebaseAuthUi.instance()
          .launchAuth([AuthProvider.phone()]).then((fbUser) async {
        //refresh state
        await checkLoginState(context);
      }).catchError((e) {
        if (e is PlatformException) {
          if (e.code == FirebaseAuthUi.kUserCancelledError)
            showOnlySnackBar(context, 'User cancelled login');
          else
            showOnlySnackBar(context, '${e.message ?? 'Unk error'}');
        }
      });
    } else //already login
      await checkLoginState(context);
  }

  Future<FirebaseAuth.User> checkLoginState(BuildContext context) async {
    if (FirebaseAuth.FirebaseAuth.instance.currentUser != null) {
      //Already login, get token
      FirebaseAuth.FirebaseAuth.instance.currentUser
          .getIdToken()
          .then((token) async {
        peopleRef = database.reference().child(PEOPLE_REF);
        chatListRef = database
            .reference()
            .child(CHATLIST_REF)
            .child(FirebaseAuth.FirebaseAuth.instance.currentUser.uid);

        //Load information
        peopleRef
            .child(FirebaseAuth.FirebaseAuth.instance.currentUser.uid)
            .once()
            .then((snapshot) {
          if (snapshot != null && snapshot.value != null) {
            setState(() {
              
              isUserInit = true;
            });
          } else {
            setState(() {
              isUserInit = true;
            });
            Navigator.pushNamed(context, '/register');
          }
        });
      });
    }
    return FirebaseAuth.FirebaseAuth.instance.currentUser;
  }
}
