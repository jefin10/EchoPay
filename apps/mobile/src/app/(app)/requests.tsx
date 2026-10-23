import { useState } from 'react';
import { ActivityIndicator, FlatList, RefreshControl, StyleSheet, View } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppText, Icon, ScreenHeader, Tap, toast, type IconName } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { Colors, Type } from '@/core/theme';
import { useRefreshAccount } from '@/features/account/hooks';
import { updateRequestStatus } from '@/features/payments/api';
import { NewRequestSheet } from '@/features/payments/components/NewRequestSheet';
import { RequestCard } from '@/features/payments/components/RequestCard';
import { useMoneyRequests } from '@/features/payments/hooks';

type Tab = 'received' | 'sent';

const EMPTY: Record<Tab, { icon: IconName; text: string }> = {
  received: { icon: 'inbox', text: 'No requests received yet.' },
  sent: { icon: 'send', text: "You haven't sent any requests." },
};

const DONE_MESSAGE = { approved: 'Paid', rejected: 'Request declined', cancelled: 'Request cancelled' } as const;

export default function RequestsScreen() {
  const phoneNumber = useSession((s) => s.phoneNumber) ?? '';
  const requests = useMoneyRequests();
  const refreshAccount = useRefreshAccount();
  const [tab, setTab] = useState<Tab>('received');
  const [busyId, setBusyId] = useState<number | null>(null);
  const [composing, setComposing] = useState(false);
  const insets = useSafeAreaInsets();

  const act = async (requestId: number, status: 'approved' | 'rejected' | 'cancelled') => {
    setBusyId(requestId);
    const result = await updateRequestStatus({ requestId, status, phoneNumber });
    setBusyId(null);
    if (result.success) {
      toast(DONE_MESSAGE[status], 'success');
      refreshAccount();
    } else {
      toast(result.message, 'error');
    }
  };

  const data = requests.data?.[tab] ?? [];

  return (
    <SafeAreaView style={styles.root} edges={['top']}>
      <View style={styles.header}>
        <ScreenHeader title="requests" />
        <View style={styles.tabs}>
          {(['received', 'sent'] as const).map((t) => {
            const selected = t === tab;
            return (
              <Tap
                key={t}
                scale={0.96}
                onPress={() => setTab(t)}
                style={[styles.tab, selected && styles.tabSelected]}
                accessibilityRole="tab"
                accessibilityState={{ selected }}>
                <AppText style={Type.body(14, 700, selected ? Colors.white : Colors.textSecondary)}>
                  {t === 'received' ? 'Received' : 'Sent'}
                </AppText>
              </Tap>
            );
          })}
        </View>
      </View>

      {requests.isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator color={Colors.ink} />
        </View>
      ) : (
        <FlatList
          data={data}
          keyExtractor={(r) => String(r.id)}
          contentContainerStyle={[styles.list, data.length === 0 && styles.grow]}
          ItemSeparatorComponent={() => <View style={styles.gap} />}
          renderItem={({ item }) => (
            <RequestCard
              request={item}
              direction={tab}
              busy={busyId === item.id}
              onAction={(status) => act(item.id, status)}
            />
          )}
          ListEmptyComponent={
            <View style={styles.center}>
              <View style={styles.emptyIcon}>
                <Icon name={requests.isError ? 'error-outline' : EMPTY[tab].icon} size={28} />
              </View>
              <AppText style={[Type.body(14, 500, Colors.textSecondary), styles.emptyText]}>
                {requests.isError ? 'Failed to load requests.' : EMPTY[tab].text}
              </AppText>
            </View>
          }
          refreshControl={
            <RefreshControl
              refreshing={requests.isRefetching}
              onRefresh={() => {
                requests.refetch();
              }}
              tintColor={Colors.ink}
              colors={[Colors.ink]}
            />
          }
        />
      )}

      <Tap
        onPress={() => setComposing(true)}
        style={[styles.fab, { bottom: insets.bottom + 20 }]}
        accessibilityRole="button">
        <Icon name="add" size={20} color={Colors.pop} />
        <AppText style={Type.body(14, 700, Colors.white)}>New request</AppText>
      </Tap>

      <NewRequestSheet
        visible={composing}
        onClose={() => setComposing(false)}
        onSent={() => {
          setComposing(false);
          setTab('sent');
          toast('Money request sent', 'success');
          requests.refetch();
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.surfaceLight },
  header: { paddingHorizontal: 20, paddingTop: 8, gap: 18, marginBottom: 14 },
  tabs: {
    flexDirection: 'row',
    padding: 4,
    borderRadius: 14,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  tab: { flex: 1, alignItems: 'center', paddingVertical: 10, borderRadius: 10 },
  tabSelected: { backgroundColor: Colors.ink },
  list: { paddingHorizontal: 20, paddingBottom: 110 },
  grow: { flexGrow: 1 },
  gap: { height: 12 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  emptyIcon: {
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyText: { marginTop: 18, textAlign: 'center' },
  fab: {
    position: 'absolute',
    right: 20,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderRadius: 18,
    backgroundColor: Colors.ink,
    shadowColor: Colors.ink,
    shadowOpacity: 0.25,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
  },
});
