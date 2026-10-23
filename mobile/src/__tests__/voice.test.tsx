import { act, renderRouter, screen } from 'expo-router/testing-library';

import { resolveRecipient } from '@/features/voice/resolve';

import { mockBackend, press, signIn } from './test-utils';

// Fake speech engine: tests push recognition events through `mockSpeech.emit`.
const mockSpeech = {
  listeners: {} as Record<string, ((e: unknown) => void)[]>,
  emit(name: string, event: unknown = {}) {
    (this.listeners[name] ?? []).forEach((l) => l(event));
  },
};
jest.mock('expo-speech-recognition', () => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { useEffect, useRef } = require('react');
  return {
    ExpoSpeechRecognitionModule: {
      requestPermissionsAsync: jest.fn().mockResolvedValue({ granted: true }),
      start: jest.fn(() => mockSpeech.emit('start')),
      stop: jest.fn(() => mockSpeech.emit('end')),
    },
    useSpeechRecognitionEvent: (name: string, listener: (e: unknown) => void) => {
      const ref = useRef(listener);
      ref.current = listener;
      useEffect(() => {
        const fn = (e: unknown) => ref.current(e);
        (mockSpeech.listeners[name] ??= []).push(fn);
        return () => {
          mockSpeech.listeners[name] = mockSpeech.listeners[name]!.filter((l) => l !== fn);
        };
      }, [name]);
    },
  };
});

jest.mock('expo-local-authentication', () => ({
  hasHardwareAsync: jest.fn().mockResolvedValue(false),
  isEnrolledAsync: jest.fn().mockResolvedValue(false),
  authenticateAsync: jest.fn(),
}));

jest.mock('expo-contacts', () => ({
  requestPermissionsAsync: jest.fn().mockResolvedValue({ granted: true }),
  ContactField: { FULL_NAME: 'fullName', PHONES: 'phones' },
  ContactsSortOrder: { GivenName: 'givenName' },
  Contact: {
    getAllDetails: jest.fn().mockResolvedValue([
      { id: '1', fullName: 'Mom', phones: [{ number: '91234 56789' }] },
      { id: '2', fullName: 'Ravi Kumar', phones: [{ number: '90000 00001' }] },
      { id: '3', fullName: 'Ravi Shankar', phones: [{ number: '90000 00002' }] },
    ]),
  },
}));

const intent = (body: object) => ({ health: { status: 'healthy' }, voice_command: body });

async function say(text: string) {
  await press(await screen.findByLabelText('Start listening'));
  await act(async () => mockSpeech.emit('result', { isFinal: true, results: [{ transcript: text }] }));
}

const bodyOf = (fetchMock: jest.Mock, path: string) =>
  JSON.parse(fetchMock.mock.calls.find(([url]) => url.includes(path))![1].body);

beforeEach(() => signIn());

it('sends money to a spoken phone number after confirmation', async () => {
  const fetchMock = mockBackend({
    ...intent({
      predicted_intent: 'transfer_money',
      action: 'transfer_money',
      confidence_percentage: 97,
      entities: { amount: 500, phone_number: '+919876543210', recipient_name: 'Send' },
    }),
    sendMoneyPhone: { status: 'success' },
    getBalance: { balance: '1' },
    getTransactions: { transactions: {} },
  });
  await renderRouter('./src/app', { initialUrl: '/speech' });
  await screen.findByText('Online');

  await say('send 500 to 9876543210');

  expect(await screen.findByText('+919876543210')).toBeOnTheScreen();
  expect(screen.getByDisplayValue('500')).toBeOnTheScreen();
  await press(screen.getByText('Confirm'));

  expect(await screen.findByText('Payment sent')).toBeOnTheScreen();
  expect(bodyOf(fetchMock, 'voice_command')).toEqual({ text: 'send 500 to 9876543210', userPhone: '+919876543210' });
  expect(bodyOf(fetchMock, 'sendMoneyPhone')).toEqual({
    senderPhone: '+919876543210',
    receiverPhone: '+919876543210',
    amount: 500,
  });
});

it('resolves a spoken name through contacts for a request', async () => {
  const fetchMock = mockBackend({
    ...intent({
      predicted_intent: 'request_money',
      action: 'request_money',
      confidence_percentage: 91,
      entities: { amount: 300, recipient_name: 'Mom' },
    }),
    createMoneyRequest: { status: 'success', requestId: 3 },
    getBalance: { balance: '1' },
    getTransactions: { transactions: {} },
  });
  await renderRouter('./src/app', { initialUrl: '/speech' });
  await screen.findByText('Online');

  await say('request 300 from mom');
  await press(await screen.findByText('Send request'));

  expect(await screen.findByText('Request sent')).toBeOnTheScreen();
  expect(bodyOf(fetchMock, 'createMoneyRequest')).toMatchObject({ requesteePhone: '+919123456789', amount: 300 });
});

it('shows the balance for a balance question', async () => {
  mockBackend({
    ...intent({ predicted_intent: 'check_balance', action: 'check_balance', confidence_percentage: 95 }),
    getBalance: { balance: '4321.00' },
  });
  await renderRouter('./src/app', { initialUrl: '/speech' });
  await screen.findByText('Online');
  await say("what's my balance");
  expect(await screen.findByText('₹4,321.00')).toBeOnTheScreen();
});

it('falls back to the chatbot for small talk', async () => {
  mockBackend({
    ...intent({ predicted_intent: 'check_balance', confidence_percentage: 40, route_to_rasa: true }),
    webhook: [{ recipient_id: 'x', text: 'Hello. Welcome to the voice enabled UPI app.' }],
  });
  await renderRouter('./src/app', { initialUrl: '/speech' });
  await screen.findByText('Online');
  await say('hello');
  expect(await screen.findByText('Hello. Welcome to the voice enabled UPI app.')).toBeOnTheScreen();
});

describe('resolveRecipient', () => {
  const loader = async () => ({
    granted: true as const,
    contacts: [
      { id: '1', name: 'Ravi Kumar', phone: '90000 00001' },
      { id: '2', name: 'Ravi Shankar', phone: '90000 00002' },
      { id: '3', name: 'Anu', phone: null },
    ],
  });

  it('asks the user to choose between matching contacts', async () => {
    const r = await resolveRecipient({ recipient: 'Ravi', recipientKind: 'name' }, loader);
    expect(r.status).toBe('choose');
  });

  it('fails clearly when nobody matches', async () => {
    expect(await resolveRecipient({ recipient: 'Anu', recipientKind: 'name' }, loader)).toEqual({
      status: 'failed',
      message: 'No contact named "Anu". Try saying their number.',
    });
  });

  it('passes UPI IDs and phones straight through', async () => {
    expect(await resolveRecipient({ recipient: 'a@upi', recipientKind: 'upi' }, loader)).toMatchObject({
      status: 'resolved',
      target: { kind: 'upi', upiId: 'a@upi' },
    });
    expect(await resolveRecipient({ recipient: '9876543210', recipientKind: 'phone' }, loader)).toMatchObject({
      target: { kind: 'phone', phone: '+919876543210' },
    });
  });
});
