import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/transaction_item.dart';
import '../../../models/user_profile.dart';
import '../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);

/// Current user's balance. Auto-loads from the session phone number and can be
/// refreshed (e.g. pull-to-refresh, after a transfer).
final balanceProvider =
    AsyncNotifierProvider<BalanceNotifier, double>(BalanceNotifier.new);

class BalanceNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() => _fetch();

  Future<double> _fetch() {
    final phone = ref.read(sessionStoreProvider).phoneNumber;
    if (phone == null) return Future.value(0.0);
    return ref.read(accountRepositoryProvider).getBalance(phone);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Current user's transaction history (newest first).
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionItem>>(
        TransactionsNotifier.new);

class TransactionsNotifier extends AsyncNotifier<List<TransactionItem>> {
  @override
  Future<List<TransactionItem>> build() => _fetch();

  Future<List<TransactionItem>> _fetch() {
    final phone = ref.read(sessionStoreProvider).phoneNumber;
    if (phone == null) return Future.value(const []);
    return ref.read(accountRepositoryProvider).getTransactions(phone);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Current user's profile. Falls back to locally-stored identity so the UI
/// has something to show even if the network profile call fails.
final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => _fetch();

  Future<UserProfile> _fetch() async {
    final session = ref.read(sessionStoreProvider);
    final local = UserProfile(
      phoneNumber: session.phoneNumber ?? '',
      userName: session.userName ?? '',
      upiId: session.upiId ?? '',
    );
    final phone = session.phoneNumber;
    if (phone == null) return local;
    try {
      final remote = await ref.read(accountRepositoryProvider).getProfile(phone);
      return UserProfile(
        phoneNumber: phone,
        userName: remote.userName.isNotEmpty ? remote.userName : local.userName,
        upiId: remote.upiId.isNotEmpty ? remote.upiId : local.upiId,
      );
    } catch (_) {
      return local;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
