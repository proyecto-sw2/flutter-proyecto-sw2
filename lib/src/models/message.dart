class Message {
  String id = '';
  final String text;
  final DateTime date;
  final bool isSendByMe;

  Message(this.text, this.date, this.isSendByMe);

  Message.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      text = json['text'],
      date = DateTime.parse(json['date']),
      isSendByMe = json['isSendByMe'] == 1 ? true : false;
}