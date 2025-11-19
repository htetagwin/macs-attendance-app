class UserModel {
  final String uid;
  final String? email;
  final String? name;
  final String? role;

  UserModel({
    required this.uid,
    this.email,
    this.name,
    this.role,
  });
}