class ChatInfo {
  String friendName, friendId, createId, lastMessage, createName;
  int lastUpdate, createDate;

  ChatInfo(
      {this.friendName,
      this.friendId,
      this.createId,
      this.lastMessage,
      this.createName,
      this.lastUpdate,
      this.createDate});

  ChatInfo.fromJson(Map<String, dynamic> json) {
    friendId = json['friendId'];
    friendName = json['friendName'];
    createId = json['createId'];
    lastMessage = json['lastMessage'];
    createName = json['createName'];
    lastUpdate = json['lastUpdate'];
    createDate = json['createDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['friendName'] = friendName;
    data['friendId'] = friendId;
    data['createId'] = createId;
    data['lastMessage'] = lastMessage;
    data['createName'] = createName;
    data['lastUpdate'] = lastUpdate;
    data['createDate'] = createDate;
    return data;
  }
}
