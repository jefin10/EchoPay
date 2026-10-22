import { Redirect } from 'expo-router';

import { selectNeedsUnlock, useSession } from '@/core/storage/session';

/** Entry point and guard anchor: send the user wherever their session allows. */
export default function Index() {
  const isLoggedIn = useSession((s) => s.isLoggedIn);
  const needsUnlock = useSession(selectNeedsUnlock);
  if (!isLoggedIn) return <Redirect href="/phone" />;
  if (needsUnlock) return <Redirect href="/biometric" />;
  return <Redirect href="/home" />;
}
