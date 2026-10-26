class User {
  final int id;
  final int accountTypeId;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isVerified;

  User({
    required this.id,
    required this.accountTypeId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      accountTypeId: json['account_type_id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      isVerified: json['is_verified'] == 1,
    );
  }
}