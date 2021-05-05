import 'package:anna_chat/const/const.dart';
import 'package:anna_chat/model/user_model.dart';
import 'package:anna_chat/ultils/ultils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class RegisterScreen extends StatelessWidget {
  FirebaseApp app;
  User user;
  RegisterScreen({this.app, this.user});

  TextEditingController firstNameController = new TextEditingController();
  TextEditingController lastNameController = new TextEditingController();
  TextEditingController phoneController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('REGISTER'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    keyboardType: TextInputType.name,
                    controller: firstNameController,
                    decoration: InputDecoration(hintText: 'First name'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    keyboardType: TextInputType.name,
                    controller: lastNameController,
                    decoration: InputDecoration(hintText: 'Last name'),
                  ),
                ),
              ],
            ),
            TextField(
              readOnly: true,
              controller: phoneController,
              decoration: InputDecoration(hintText: user.phoneNumber ?? 'Null'),
            ),
            ElevatedButton(
              onPressed: () {
                if (firstNameController == null ||
                    firstNameController.text.isEmpty)
                  showOnlySnackBar(context, 'Please enter firstName');
                else if (lastNameController == null ||
                    lastNameController.text.isEmpty)
                  showOnlySnackBar(context, 'Please enter lastName');
                else {
                  UserModel userModel = new UserModel(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      phone: user.phoneNumber);

                  //Submit on Firebase
                  FirebaseDatabase(app: app)
                      .reference()
                      .child(PEOPLE_REF)
                      .child(user.uid)
                      .set(<String,dynamic>{
                        'firstName':userModel.firstName,
                        'lastName':userModel.lastName,
                        'phone':userModel.phone,
                      })
                      .then((value) {
                    showOnlySnackBar(context, 'Register success');
                    Navigator.pop(context);
                  }).catchError(
                          (e) => showOnlySnackBar(context, e ?? 'Unk error'));
                }
              },
              child: Text(
                'REGISTER',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
