import { useQuery } from '@tanstack/react-query';

import { useSession } from '@/core/storage/session';

import { getMoneyRequests } from './api';

/** Money requests sent by and addressed to the current user. */
export function useMoneyRequests() {
  const phone = useSession((s) => s.phoneNumber);
  return useQuery({
    queryKey: ['moneyRequests', phone],
    queryFn: () => getMoneyRequests(phone!),
    enabled: !!phone,
  });
}
