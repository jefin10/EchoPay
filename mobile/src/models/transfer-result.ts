/** Outcome of a money-movement call. `message` is user-presentable either way. */
export interface TransferResult {
  success: boolean;
  message: string;
  data?: Record<string, unknown>;
}

export const transferSuccess = (message: string, data?: Record<string, unknown>): TransferResult => ({
  success: true,
  message,
  data,
});

export const transferFailure = (message: string): TransferResult => ({ success: false, message });
