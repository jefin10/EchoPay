import { getJson, postJson, withQuery } from '@/core/api/client';
import { Endpoints } from '@/core/api/endpoints';
import { parseTransactions, type TransactionItem } from '@/models/transaction';
import { profileFromJson, type UserProfile } from '@/models/user-profile';

/** Read-side account data: profile, balance and transaction history. */

export async function getProfile(phoneNumber: string): Promise<UserProfile> {
  const json = await getJson<Record<string, unknown>>(
    withQuery(Endpoints.getProfile, { phoneNumber }),
  );
  return profileFromJson(json ?? {}, phoneNumber);
}

export async function getBalance(phoneNumber: string): Promise<number> {
  const json = await getJson<Record<string, unknown>>(
    withQuery(Endpoints.getBalance, { phoneNumber }),
  );
  const n = Number.parseFloat(String(json?.balance ?? json?.amount));
  return Number.isFinite(n) ? n : 0;
}

export async function getTransactions(phoneNumber: string): Promise<TransactionItem[]> {
  const json = await postJson(Endpoints.getTransactions, { phoneNumber });
  return parseTransactions(json);
}
