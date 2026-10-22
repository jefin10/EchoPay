import { act, fireEvent } from 'expo-router/testing-library';

import { queryClient } from '@/core/query-client';
import { useSession } from '@/core/storage/session';

type Element = Parameters<typeof fireEvent.press>[0];

// Await each interaction so async state updates settle before asserting.
export const type = (el: Element, text: string) => act(async () => fireEvent.changeText(el, text));
export const press = (el: Element) => act(async () => fireEvent.press(el));

/** Route fetch calls by URL substring → JSON body (or [body, status]). */
export function mockBackend(routes: Record<string, unknown | [unknown, number]>) {
  const fetchMock = jest.fn((url: string) => {
    const key = Object.keys(routes).find((k) => url.includes(k));
    if (!key) return Promise.reject(new Error(`Unmocked request: ${url}`));
    const value = routes[key];
    const [body, status] = Array.isArray(value) && typeof value[1] === 'number' ? value : [value, 200];
    return Promise.resolve({ status, text: () => Promise.resolve(JSON.stringify(body)) });
  });
  globalThis.fetch = fetchMock as unknown as typeof fetch;
  return fetchMock;
}

/** Logged-in, unlocked session with a clean query cache. */
export function signIn(phoneNumber = '+919876543210', userName = 'Ravi', upiId = 'ravi@upi') {
  queryClient.clear();
  useSession.getState().clear();
  useSession.getState().saveSession({ phoneNumber, userName, upiId });
  useSession.getState().setUnlocked(true);
}
