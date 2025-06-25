class User {
  int? id;
  String? name;
  String? email;
  String? dispositivo;

  User({this.id, this.name, this.email, this.dispositivo});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    dispositivo: json["dispositivo"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "dispositivo": dispositivo,
  };
}
