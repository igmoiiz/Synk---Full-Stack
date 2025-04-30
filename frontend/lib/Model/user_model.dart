class User {
  String? id;
  String? name;
  String? email;
  String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? json['_id'] ?? "",
    name: json['name'] ?? "",
    email: json['email'] ?? "",
    profilePicture: json['profile_picture'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'profile_picture': profilePicture,
  };
}
