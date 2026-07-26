class AppUser {
  final String id;
  final String phoneNumber;
  final String? fullName;
  final String? profileImageUrl;

  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.fullName,
    this.profileImageUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'profile_image_url': profileImageUrl,
      };
}
