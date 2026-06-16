class User {
  final int userID;
  final String email;
  final String password;
  final String name;
  final String role;
  final String phone;
  final String department;
  final bool is_blocked;

  User({
    required this.userID,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.phone,
    required this.department,
    required this.is_blocked,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? json['userid'] ?? 0,
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? '',
      is_blocked: json['is_blocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'phone': phone,
      'department': department,
      'is_blocked': is_blocked,
    };
  }
}