import { useMemo, useState } from 'react';
import { ActivityIndicator, FlatList, RefreshControl, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppText, Icon, IconButton, ScreenHeader, Tap, type IconName } from '@/core/components';
import { Colors, Type } from '@/core/theme';
import { TransactionCard } from '@/features/account/components/TransactionRow';
import { useTransactions } from '@/features/account/hooks';
import type { TransactionItem } from '@/models/transaction';

const FILTERS = ['All', 'Sent', 'Received', 'Failed'] as const;
type Filter = (typeof FILTERS)[number];

const matches = (tx: TransactionItem, filter: Filter) =>
  filter === 'All' ||
  (filter === 'Sent' && tx.type === 'sent') ||
  (filter === 'Received' && tx.type === 'received') ||
  (filter === 'Failed' && tx.status === 'failed');

export default function HistoryScreen() {
  const [filter, setFilter] = useState<Filter>('All');
  const [searching, setSearching] = useState(false);
  const [query, setQuery] = useState('');
  const transactions = useTransactions();

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return (transactions.data ?? []).filter(
      (tx) => matches(tx, filter) && (!q || tx.counterpartyName.toLowerCase().includes(q)),
    );
  }, [transactions.data, filter, query]);

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.header}>
        <ScreenHeader
          title="history"
          right={
            <IconButton
              icon={searching ? 'close' : 'search'}
              accessibilityLabel={searching ? 'Close search' : 'Search'}
              onPress={() => {
                setSearching((s) => !s);
                setQuery('');
              }}
            />
          }
        />
        {searching && (
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="Search by name"
            placeholderTextColor={Colors.textMuted}
            autoFocus
            style={[Type.body(15, 600), styles.search]}
          />
        )}
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters} style={styles.filterStrip}>
        {FILTERS.map((f) => {
          const selected = f === filter;
          return (
            <Tap
              key={f}
              scale={0.94}
              onPress={() => setFilter(f)}
              style={[styles.filter, selected && styles.filterSelected]}
              accessibilityRole="tab"
              accessibilityState={{ selected }}>
              <AppText style={Type.body(13, 700, selected ? Colors.white : Colors.ink)}>{f}</AppText>
            </Tap>
          );
        })}
      </ScrollView>

      {transactions.isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator color={Colors.ink} />
        </View>
      ) : transactions.isError ? (
        <EmptyState icon="error-outline" message="Failed to fetch transactions." />
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(tx, i) => `${tx.timestamp}-${i}`}
          renderItem={({ item }) => <TransactionCard tx={item} />}
          ItemSeparatorComponent={() => <View style={styles.gap} />}
          contentContainerStyle={[styles.list, filtered.length === 0 && styles.grow]}
          ListEmptyComponent={
            <EmptyState icon="receipt-long" message="Nothing here yet — your transactions will land here." />
          }
          refreshControl={
            <RefreshControl
              refreshing={transactions.isRefetching}
              onRefresh={() => {
                transactions.refetch();
              }}
              tintColor={Colors.ink}
              colors={[Colors.ink]}
            />
          }
        />
      )}
    </SafeAreaView>
  );
}

function EmptyState({ icon, message }: { icon: IconName; message: string }) {
  return (
    <View style={styles.center}>
      <View style={styles.emptyIcon}>
        <Icon name={icon} size={28} />
      </View>
      <AppText style={[Type.body(14, 500, Colors.textSecondary), styles.emptyText]}>{message}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.surfaceLight },
  header: { paddingHorizontal: 20, paddingTop: 8, gap: 14 },
  search: {
    backgroundColor: Colors.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  filterStrip: { flexGrow: 0, marginVertical: 14 },
  filters: { paddingHorizontal: 20, gap: 8 },
  filter: {
    paddingHorizontal: 18,
    paddingVertical: 9,
    borderRadius: 40,
    borderWidth: 1.5,
    borderColor: Colors.border,
    backgroundColor: Colors.surface,
  },
  filterSelected: { backgroundColor: Colors.ink, borderColor: Colors.ink },
  list: { paddingHorizontal: 20, paddingTop: 4, paddingBottom: 24 },
  grow: { flexGrow: 1 },
  gap: { height: 10 },
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
  emptyText: { marginTop: 18, textAlign: 'center', lineHeight: 21 },
});
