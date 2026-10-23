import { useLocalSearchParams } from 'expo-router';

import { PayScreen } from '@/features/payments/components/PayScreen';

/** Optional params come from a scanned UPI QR: upi (pa), amount (am), name (pn). */
export default function PayToUpiScreen() {
  const { upi, amount, name } = useLocalSearchParams<{ upi?: string; amount?: string; name?: string }>();
  return <PayScreen mode="upi" initialTarget={upi} initialAmount={amount} initialName={name} />;
}
