import * as Clipboard from 'expo-clipboard';

import { toast } from '@/core/components';

export function useCopyUpi(upiId: string) {
  return async () => {
    if (!upiId) return;
    await Clipboard.setStringAsync(upiId);
    toast('UPI ID copied', 'success');
  };
}
