import type { ReactNode } from 'react';
import { RefreshControl, ScrollView, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/core/theme';

/**
 * Cream page with safe-area padding. Scrolls by default; pass `onRefresh`
 * for pull-to-refresh.
 */
export function Screen({
  children,
  scroll = true,
  refreshing = false,
  onRefresh,
  contentStyle,
  edges = ['top', 'bottom'],
}: {
  children: ReactNode;
  scroll?: boolean;
  refreshing?: boolean;
  onRefresh?: () => void;
  contentStyle?: StyleProp<ViewStyle>;
  edges?: ('top' | 'bottom')[];
}) {
  return (
    <SafeAreaView style={styles.root} edges={edges}>
      {scroll ? (
        <ScrollView
          contentContainerStyle={[styles.content, contentStyle]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
          refreshControl={
            onRefresh ? (
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Colors.ink} colors={[Colors.ink]} />
            ) : undefined
          }>
          {children}
        </ScrollView>
      ) : (
        <View style={[styles.content, styles.fill, contentStyle]}>{children}</View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.surfaceLight },
  content: { paddingHorizontal: 20, paddingTop: 8, paddingBottom: 30 },
  fill: { flex: 1 },
});
