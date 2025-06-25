class ChatMessage {
    List<Msg> messages;

    ChatMessage({
        required this.messages,
    });

    factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messages: List<Msg>.from(json["messages"].map((x) => Msg.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
    };
}

class Msg {
    String content;
    DateTime createdAt;
    int id;
    String type;

    Msg({
        required this.content,
        required this.createdAt,
        required this.id,
        required this.type,
    });

    factory Msg.fromJson(Map<String, dynamic> json) => Msg(
        content: json["content"],
        createdAt: DateTime.parse(json["created_at"]),
        id: json["id"],
        type: json["type"],
    );

    Map<String, dynamic> toJson() => {
        "content": content,
        "created_at": createdAt.toIso8601String(),
        "id": id,
        "type": type,
    };
}
