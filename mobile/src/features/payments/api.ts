import { ApiException, getJson, postJson, withQuery } from '@/core/api/client';
import { Endpoints } from '@/core/api/endpoints';
import { parseMoneyRequests, type MoneyRequests, type MoneyRequestStatus } from '@/models/money-request';
import { transferFailure, transferSuccess, type TransferResult } from '@/models/transfer-result';

/** Write-side money movement plus the recipient lookups used by the pay flows. */

type Json = Record<string, unknown>;

export interface Recipient {
  upiName: string;
  upiId?: string;
  phoneNumber?: string;
}

export function sendByPhone(args: {
  senderPhone: string;
  receiverPhone: string;
  amount: number;
}): Promise<TransferResult> {
  return send(Endpoints.sendMoneyPhone, { ...args });
}

export function sendByUpiId(args: {
  senderPhone: string;
  receiverUpi: string;
  amount: number;
}): Promise<TransferResult> {
  return send(Endpoints.sendMoneyId, { ...args });
}

export function createMoneyRequest(args: {
  requesterPhone: string;
  requesteePhone: string;
  amount: number;
  message?: string;
}): Promise<TransferResult> {
  return send(
    Endpoints.createRequest,
    { ...args, message: args.message || `Payment request for ₹${args.amount}` },
    'Request sent successfully',
  );
}

export function createMoneyRequestByUpi(args: {
  requesterPhone: string;
  requesteeUpi: string;
  amount: number;
  message?: string;
}): Promise<TransferResult> {
  return send(
    Endpoints.createRequestByUpi,
    { ...args, message: args.message || `Payment request for ₹${args.amount}` },
    'Request sent successfully',
  );
}

/** The matched user, or null if nobody has that number. */
export async function searchByPhone(phoneNumber: string): Promise<Recipient | null> {
  const json = await search(withQuery(Endpoints.searchByPhone, { phoneNumber }));
  return json ? { upiName: String(json.upiName ?? ''), upiId: json.upiId as string, phoneNumber } : null;
}

/** The matched user, or null if nobody has that UPI ID. */
export async function searchByUpiId(upiId: string): Promise<Recipient | null> {
  const json = await search(withQuery(Endpoints.searchByUpi, { upiId }));
  return json
    ? { upiName: String(json.upiName ?? ''), upiId, phoneNumber: json.phoneNumber as string }
    : null;
}

/** Whether `phoneNumber` is registered with an account. */
export async function hasAccount(phoneNumber: string): Promise<boolean> {
  const json = await search(withQuery(Endpoints.checkAccount, { phoneNumber }));
  return json?.hasAccount === true || json?.exists === true;
}

export async function getMoneyRequests(phoneNumber: string): Promise<MoneyRequests> {
  const json = await getJson(withQuery(Endpoints.getRequests, { phoneNumber }));
  return parseMoneyRequests(json);
}

export function updateRequestStatus(args: {
  requestId: number;
  status: Exclude<MoneyRequestStatus, 'pending'>;
  phoneNumber: string;
}): Promise<TransferResult> {
  return send(Endpoints.updateRequest, { ...args }, 'Request updated');
}

async function search(url: string): Promise<Json | null> {
  try {
    return await getJson<Json>(url);
  } catch (e) {
    if (e instanceof ApiException) return null;
    throw e;
  }
}

async function send(url: string, body: Json, successMessage = 'Transfer successful'): Promise<TransferResult> {
  try {
    const json = await postJson<Json>(url, body, {
      acceptedStatuses: (c) => c === 200 || c === 201,
    });
    return transferSuccess(String(json?.message ?? successMessage), json ?? undefined);
  } catch (e) {
    if (e instanceof ApiException) return transferFailure(e.message);
    throw e;
  }
}
