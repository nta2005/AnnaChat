class UserModel {
  String uid, firstName, lastName, phone;

  UserModel({this.uid, this.firstName, this.lastName, this.phone});

  UserModel.fromJson(Map<String, dynamic> json) {
    //uid = json['uid']; -> Because we always set key from Firebase to uid, so here we can don't bind it
    firstName = json['firstName'];
    lastName = json['lastName'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    //data['uid'] = this.uid;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['phone'] = this.phone;
    return data;
  }
}
