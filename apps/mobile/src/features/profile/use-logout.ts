import { queryClient } from '@/core/query-client';
import { useSession } from '@/core/storage/session';

/** Wipe the session and cached data; the root guards then show onboarding. */
export function useLogout() {
  const clear = useSession((s) => s.clear);
  return () => {
    queryClient.clear();
    clear();
  };
}
