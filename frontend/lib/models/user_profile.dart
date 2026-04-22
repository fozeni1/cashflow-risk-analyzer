class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
  });

  final int id;
  final String username;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: (json['username'] ?? '').toString(),
    );
  }
}
