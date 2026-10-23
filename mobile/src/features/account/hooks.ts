import { useQuery, useQueryClient } from '@tanstack/react-query';

import { useSession } from '@/core/storage/session';
import type { UserProfile } from '@/models/user-profile';

import { getBalance, getProfile, getTransactions } from './api';

export const accountKeys = {
  balance: (phone: string | null) => ['balance', phone] as const,
  transactions: (phone: string | null) => ['transactions', phone] as const,
  profile: (phone: string | null) => ['profile', phone] as const,
};

/** Current user's balance. */
export function useBalance() {
  const phone = useSession((s) => s.phoneNumber);
  return useQuery({
    queryKey: accountKeys.balance(phone),
    queryFn: () => getBalance(phone!),
    enabled: !!phone,
  });
}

/** Current user's transaction history, newest first. */
export function useTransactions() {
  const phone = useSession((s) => s.phoneNumber);
  return useQuery({
    queryKey: accountKeys.transactions(phone),
    queryFn: () => getTransactions(phone!),
    enabled: !!phone,
  });
}

/**
 * Current user's profile. Falls back to the locally stored identity so the
 * UI has something to show even if the network call fails.
 */
export function useProfile() {
  const { phoneNumber, userName, upiId } = useSession();
  const local: UserProfile = { phoneNumber: phoneNumber ?? '', userName: userName ?? '', upiId: upiId ?? '' };
  return useQuery({
    queryKey: accountKeys.profile(phoneNumber),
    queryFn: async (): Promise<UserProfile> => {
      if (!phoneNumber) return local;
      try {
        const remote = await getProfile(phoneNumber);
        return {
          phoneNumber,
          userName: remote.userName || local.userName,
          upiId: remote.upiId || local.upiId,
        };
      } catch {
        return local;
      }
    },
    placeholderData: local,
  });
}

/** Refetch everything money-related, e.g. after a transfer or request change. */
export function useRefreshAccount() {
  const client = useQueryClient();
  return () =>
    Promise.all([
      client.invalidateQueries({ queryKey: ['balance'] }),
      client.invalidateQueries({ queryKey: ['transactions'] }),
      client.invalidateQueries({ queryKey: ['moneyRequests'] }),
    ]);
}
