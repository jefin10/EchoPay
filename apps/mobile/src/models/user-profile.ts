/** The signed-in user's identity, as returned by `getProfile` or stored locally. */
export interface UserProfile {
  phoneNumber: string;
  userName: string;
  upiId: string;
}

export function profileFromJson(json: Record<string, unknown>, phoneNumber = ''): UserProfile {
  return {
    phoneNumber: json.phoneNumber != null ? String(json.phoneNumber) : phoneNumber,
    userName: json.upiName != null ? String(json.upiName) : '',
    upiId: json.upiId != null ? String(json.upiId) : '',
  };
}
