import { useQuery } from '@tanstack/react-query';

import { checkServerHealth } from './api';

/** Whether the intent server is reachable (drives the online/offline chip). */
export function useVoiceServerHealth() {
  return useQuery({
    queryKey: ['voiceServerHealth'],
    queryFn: checkServerHealth,
    staleTime: 30_000,
  });
}
