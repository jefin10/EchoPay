import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/transaction_item.dart';
import '../../../models/user_profile.dart';

/// Read-side account data: profile, balance and transaction history.
/// Shared by the home, balance and history features.
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<UserProfile> getProfile(String phoneNumber) async {
    final json = await _api.getJson(
      Uri.parse('$GET_PROFILE_URL?phoneNumber=$phoneNumber'),
    );
    return UserProfile.fromJson(
      Map<String, dynamic>.from(json as Map),
      phoneNumber: phoneNumber,
    );
  }

  Future<double> getBalance(String phoneNumber) async {
    final json = await _api.getJson(
      Uri.parse('$GET_BALANCE_URL?phoneNumber=$phoneNumber'),
    ) as Map;
    final raw = json['balance'] ?? json['amount'];
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  Future<List<TransactionItem>> getTransactions(String phoneNumber) async {
    final json = await _api.postJson(
      Uri.parse(GET_TRANSACTIONS_URL),
      {'phoneNumber': phoneNumber},
    ) as Map;
    return TransactionItem.parseAll(Map<String, dynamic>.from(json));
  }
}
