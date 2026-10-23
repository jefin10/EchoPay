export type MoneyRequestStatus = 'pending' | 'approved' | 'rejected' | 'cancelled';

/** A money request seen from the current user's side. */
export interface MoneyRequest {
  id: number;
  /** The other party: requestee for sent requests, requester for received ones. */
  counterpartyName: string;
  counterpartyPhone: string;
  amount: number;
  message: string;
  status: MoneyRequestStatus;
  createdAt: string;
}

export interface MoneyRequests {
  sent: MoneyRequest[];
  received: MoneyRequest[];
}

type Raw = Record<string, unknown>;

function fromRaw(json: Raw, side: 'requester' | 'requestee'): MoneyRequest {
  const amount = Number.parseFloat(String(json.amount));
  return {
    id: Number(json.id),
    counterpartyName: String(json[`${side}__user__upiName`] ?? 'Unknown'),
    counterpartyPhone: String(json[`${side}__user__phoneNumber`] ?? ''),
    amount: Number.isFinite(amount) ? amount : 0,
    message: json.message != null ? String(json.message) : '',
    status: (json.status as MoneyRequestStatus) ?? 'pending',
    createdAt: json.created_at != null ? String(json.created_at) : '',
  };
}

/** Parse `getMoneyRequests` → sent requests show the requestee, received show the requester. */
export function parseMoneyRequests(data: unknown): MoneyRequests {
  const d = (data ?? {}) as { sentRequests?: Raw[]; receivedRequests?: Raw[] };
  return {
    sent: (d.sentRequests ?? []).map((r) => fromRaw(r, 'requestee')),
    received: (d.receivedRequests ?? []).map((r) => fromRaw(r, 'requester')),
  };
}
