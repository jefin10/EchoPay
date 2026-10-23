import { Endpoints } from '@/core/api/endpoints';
import { pickEntities, processCommand } from '@/features/voice/api';

const fetchMock = jest.fn();
globalThis.fetch = fetchMock as unknown as typeof fetch;

const respond = (body: unknown, status = 200) =>
  Promise.resolve({ status, text: () => Promise.resolve(JSON.stringify(body)) });

beforeEach(() => fetchMock.mockReset());

describe('pickEntities', () => {
  it('prefers phone over the bogus name the regex extracts', () => {
    expect(
      pickEntities({ amount: 500, phone_number: '+919876543210', recipient_name: 'Send' }),
    ).toEqual({ amount: 500, recipient: '+919876543210', recipientKind: 'phone' });
  });

  it('prefers UPI ID over name', () => {
    expect(pickEntities({ amount: 500, upi_id: 'ravi@upi', recipient_name: 'Ravi' })).toMatchObject({
      recipient: 'ravi@upi',
      recipientKind: 'upi',
    });
  });

  it('falls back to name', () => {
    expect(pickEntities({ amount: 200, recipient_name: 'Mom' })).toMatchObject({
      recipient: 'Mom',
      recipientKind: 'name',
    });
  });

  it('drops an amount that is really the phone number', () => {
    expect(pickEntities({ amount: 9876543210, phone_number: '+919876543210' })).toEqual({
      recipient: '+919876543210',
      recipientKind: 'phone',
    });
  });
});

describe('processCommand', () => {
  it('routes low-confidence input to Rasa with a per-user sender', async () => {
    fetchMock
      .mockReturnValueOnce(respond({ predicted_intent: 'check_balance', confidence_percentage: 45, route_to_rasa: true }))
      .mockReturnValueOnce(respond([{ text: 'Hello. Welcome!' }]));

    const outcome = await processCommand('hi there', '+919876543210');

    expect(outcome).toMatchObject({ action: 'chat', message: 'Hello. Welcome!', source: 'rasa', confidence: 45 });
    const [url, init] = fetchMock.mock.calls[1];
    expect(url).toBe(Endpoints.rasaChat);
    expect(JSON.parse(init.body)).toEqual({ sender: '+919876543210', message: 'hi there' });
  });

  it('maps a confident transfer to a transfer action', async () => {
    fetchMock.mockReturnValueOnce(
      respond({
        predicted_intent: 'transfer_money',
        action: 'transfer_money',
        confidence_percentage: 98,
        assistant_message: 'Ready to send ₹500.0 to Send',
        entities: { amount: 500, phone_number: '+919876543210', recipient_name: 'Send' },
      }),
    );

    const outcome = await processCommand('send 500 to 9876543210');

    expect(outcome).toMatchObject({
      success: true,
      action: 'transfer',
      amount: 500,
      recipient: '+919876543210',
      recipientKind: 'phone',
    });
  });

  it('maps balance checks', async () => {
    fetchMock.mockReturnValueOnce(
      respond({ predicted_intent: 'check_balance', action: 'check_balance', confidence_percentage: 91 }),
    );
    expect(await processCommand('my balance')).toMatchObject({ action: 'balance' });
  });

  it('surfaces server errors', async () => {
    fetchMock.mockReturnValueOnce(respond({ error: 'No text provided' }, 400));
    expect(await processCommand('')).toMatchObject({ success: false, action: 'none', message: 'No text provided' });
  });

  it('surfaces network failures', async () => {
    fetchMock.mockRejectedValueOnce(new Error('connection refused'));
    expect(await processCommand('hi')).toMatchObject({
      success: false,
      message: 'Network error: connection refused',
    });
  });
});
