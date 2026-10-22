import { parseMoneyRequests } from '@/models/money-request';
import { parseTransactions } from '@/models/transaction';

describe('parseTransactions', () => {
  it('merges sent and received, newest first', () => {
    const items = parseTransactions({
      transactions: {
        sent: [
          { receiver__user__upiName: 'ravi', amount: '250.00', timestamp: '2026-10-20T10:00:00Z', status: 'completed' },
        ],
        received: [
          { sender__user__upiName: 'anu', amount: '100.50', timestamp: '2026-10-21T09:00:00Z', status: 'completed' },
          { sender__user__upiName: 'mom', amount: 'oops', timestamp: '2026-10-19T09:00:00Z' },
        ],
      },
    });
    expect(items.map((t) => t.counterpartyName)).toEqual(['anu', 'ravi', 'mom']);
    expect(items[0]).toMatchObject({ type: 'received', amount: 100.5 });
    expect(items[1]).toMatchObject({ type: 'sent', amount: 250 });
    expect(items[2]).toMatchObject({ amount: 0, status: 'completed' });
  });

  it('tolerates malformed payloads', () => {
    expect(parseTransactions(null)).toEqual([]);
    expect(parseTransactions({ transactions: 'nope' })).toEqual([]);
    expect(parseTransactions({ transactions: {} })).toEqual([]);
  });
});

describe('parseMoneyRequests', () => {
  it('maps the counterparty for each side', () => {
    const { sent, received } = parseMoneyRequests({
      sentRequests: [
        {
          id: 1,
          requestee__user__upiName: 'ravi',
          requestee__user__phoneNumber: '+919876543210',
          amount: '300.00',
          message: 'dinner',
          status: 'pending',
          created_at: '2026-10-20T10:00:00Z',
        },
      ],
      receivedRequests: [
        { id: 2, requester__user__upiName: 'anu', requester__user__phoneNumber: '+919123456789', amount: '50', status: 'approved' },
      ],
    });
    expect(sent[0]).toMatchObject({ id: 1, counterpartyName: 'ravi', amount: 300, message: 'dinner' });
    expect(received[0]).toMatchObject({ id: 2, counterpartyName: 'anu', status: 'approved', message: '' });
  });
});
