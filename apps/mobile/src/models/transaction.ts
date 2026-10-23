/**
 * A single ledger entry, normalised from the backend's split
 * `transactions.sent[]` / `transactions.received[]` payload.
 */
export interface TransactionItem {
  type: 'sent' | 'received';
  counterpartyName: string;
  amount: number;
  /** Raw ISO timestamp as returned by the backend (may be empty). */
  timestamp: string;
  status: string;
}

type RawTx = Record<string, unknown>;

const toAmount = (v: unknown) => {
  const n = Number.parseFloat(String(v));
  return Number.isFinite(n) ? n : 0;
};

function fromRaw(json: RawTx, type: TransactionItem['type']): TransactionItem {
  const nameKey = type === 'sent' ? 'receiver__user__upiName' : 'sender__user__upiName';
  return {
    type,
    counterpartyName: json[nameKey] != null ? String(json[nameKey]) : 'Unknown',
    amount: toAmount(json.amount),
    timestamp: json.timestamp != null ? String(json.timestamp) : '',
    status: json.status != null ? String(json.status) : 'completed',
  };
}

/**
 * Parse the full `{ transactions: { sent: [], received: [] } }` payload into a
 * single list sorted newest-first.
 */
export function parseTransactions(data: unknown): TransactionItem[] {
  const tx = (data as { transactions?: unknown } | null)?.transactions;
  if (!tx || typeof tx !== 'object') return [];
  const { sent, received } = tx as { sent?: RawTx[]; received?: RawTx[] };
  const all = [
    ...(Array.isArray(sent) ? sent : []).map((t) => fromRaw(t, 'sent')),
    ...(Array.isArray(received) ? received : []).map((t) => fromRaw(t, 'received')),
  ];
  return all.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
}
