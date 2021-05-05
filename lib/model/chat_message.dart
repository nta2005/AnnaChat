class ChatMessage {
  int timeStamp;
  String senderId, name, content, uid, pictureLink;
  bool picture;

  ChatMessage(
      {this.timeStamp,
      this.senderId,
      this.name,
      this.content,
      this.picture,
      this.uid,
      this.pictureLink});

  ChatMessage.fromJson(Map<String, dynamic> json) {
    timeStamp = json['timeStamp'];
    senderId = json['senderId'];
    name = json['name'];
    content = json['content'];
    picture = json['picture'];
    uid = json['uid'];
    pictureLink = json['pictureLink'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['timeStamp'] = timeStamp;
    data['senderId'] = senderId;
    data['name'] = name;
    data['content'] = content;
    data['picture'] = picture;
    data['uid'] = uid;
    data['pictureLink'] = pictureLink;
    return data;
  }
}
