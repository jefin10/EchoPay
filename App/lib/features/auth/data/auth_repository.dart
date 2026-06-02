import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/user_profile.dart';

/// Result of a successful OTP verification.
class OtpVerification {
  const OtpVerification({required this.isNewUser, this.profile});

  final bool isNewUser;

  /// Populated for returning users; null for new users (who still need to
  /// pick a name).
  final UserProfile? profile;
}

/// Phone/OTP authentication and account creation. Replaces the inline
/// `http` calls that lived in the auth pages.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Requests an OTP for [phoneNumber]. Throws [ApiException] on failure.
  Future<void> sendOtp(String phoneNumber) async {
    final json = await _api.getJson(
      Uri.parse(SEND_OTP_URL).replace(queryParameters: {'phone': phoneNumber}),
    ) as Map;
    if (json['status'] != 'success') {
      throw ApiException(json['message']?.toString() ?? 'Failed to send OTP');
    }
  }

  /// Verifies [otp] for [phoneNumber]. Throws [ApiException] on failure.
  Future<OtpVerification> verifyOtp(String phoneNumber, String otp) async {
    final json = await _api.getJson(
      Uri.parse(VERIFY_OTP_URL)
          .replace(queryParameters: {'phone': phoneNumber, 'otp': otp}),
    ) as Map;
    if (json['status'] != 'success') {
      throw ApiException(json['message']?.toString() ?? 'Invalid OTP');
    }
    final isNewUser = json['isNewUser'] == true;
    return OtpVerification(
      isNewUser: isNewUser,
      profile: isNewUser
          ? null
          : UserProfile(
              phoneNumber: phoneNumber,
              userName: json['upiName']?.toString() ?? '',
              upiId: json['upiId']?.toString() ?? '',
            ),
    );
  }

  /// Creates an account for a new user. Throws [ApiException] on failure.
  Future<UserProfile> signUp({
    required String phoneNumber,
    required String upiName,
  }) async {
    final json = await _api.postJson(
      Uri.parse(SIGNUP_URL),
      {'upiName': upiName, 'phoneNumber': phoneNumber},
    ) as Map;
    if (json['status'] != 'success') {
      throw ApiException(json['error']?.toString() ?? 'Failed to create account');
    }
    return UserProfile(
      phoneNumber: phoneNumber,
      userName: json['upiName']?.toString() ?? upiName,
      upiId: json['upiId']?.toString() ?? '',
    );
  }
}
