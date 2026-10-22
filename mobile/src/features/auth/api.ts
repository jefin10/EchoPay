import { ApiException, getJson, postJson, withQuery } from '@/core/api/client';
import { Endpoints } from '@/core/api/endpoints';
import type { UserProfile } from '@/models/user-profile';

export interface OtpVerification {
  isNewUser: boolean;
  /** Canonical phone number as stored by the backend. */
  phoneNumber: string;
  /** Present for returning users; null for new users who still need a name. */
  profile: UserProfile | null;
}

type Json = Record<string, unknown>;

/** Requests an OTP for `phoneNumber`. Throws ApiException on failure. */
export async function sendOtp(phoneNumber: string): Promise<void> {
  const json = await getJson<Json>(withQuery(Endpoints.sendOtp, { phone: phoneNumber }));
  if (json?.status !== 'success') {
    throw new ApiException(String(json?.message ?? 'Failed to send OTP'));
  }
}

/** Verifies `otp` for `phoneNumber`. Throws ApiException on failure. */
export async function verifyOtp(phoneNumber: string, otp: string): Promise<OtpVerification> {
  const json = await getJson<Json>(withQuery(Endpoints.verifyOtp, { phone: phoneNumber, otp }));
  if (json?.status !== 'success') {
    throw new ApiException(String(json?.message ?? 'Invalid OTP'));
  }
  const isNewUser = json.isNewUser === true;
  const canonical = json.phoneNumber ? String(json.phoneNumber) : phoneNumber;
  return {
    isNewUser,
    phoneNumber: canonical,
    profile: isNewUser
      ? null
      : {
          phoneNumber: canonical,
          userName: String(json.upiName ?? ''),
          upiId: String(json.upiId ?? ''),
        },
  };
}

/** Creates an account for a new user. Throws ApiException on failure. */
export async function signUp(args: { phoneNumber: string; upiName: string }): Promise<UserProfile> {
  const json = await postJson<Json>(Endpoints.signUp, {
    upiName: args.upiName,
    phoneNumber: args.phoneNumber,
  });
  if (json?.status !== 'success') {
    throw new ApiException(String(json?.error ?? 'Failed to create account'));
  }
  return {
    phoneNumber: String(json.phoneNumber ?? args.phoneNumber),
    userName: String(json.upiName ?? args.upiName),
    upiId: String(json.upiId ?? ''),
  };
}
