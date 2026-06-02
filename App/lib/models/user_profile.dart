/// The signed-in user's identity as returned by `getProfile` / persisted
/// locally.
class UserProfile {
  const UserProfile({
    required this.phoneNumber,
    this.userName = '',
    this.upiId = '',
  });

  final String phoneNumber;
  final String userName;
  final String upiId;

  factory UserProfile.fromJson(Map<String, dynamic> json, {String phoneNumber = ''}) {
    return UserProfile(
      phoneNumber: json['phoneNumber']?.toString() ?? phoneNumber,
      userName: json['upiName']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
    );
  }

  UserProfile copyWith({String? phoneNumber, String? userName, String? upiId}) {
    return UserProfile(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userName: userName ?? this.userName,
      upiId: upiId ?? this.upiId,
    );
  }
}
