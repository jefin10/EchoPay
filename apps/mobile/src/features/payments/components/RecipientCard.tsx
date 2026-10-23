import { StyleSheet, View } from 'react-native';

import { AppText, Avatar, Chip } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';

/** Found recipient: initials, name, handle and a verified badge. */
export function RecipientCard({ name, subtitle, verified = true }: { name: string; subtitle?: string; verified?: boolean }) {
  return (
    <View style={styles.card}>
      <Avatar name={name || '?'} size={48} />
      <View style={styles.flex}>
        <AppText style={Type.heading(16)} numberOfLines={1}>
          {name || 'Unknown user'}
        </AppText>
        {subtitle ? (
          <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.sub]} numberOfLines={1}>
            {subtitle}
          </AppText>
        ) : null}
      </View>
      {verified && <Chip label="verified" icon="verified" background={alpha(Colors.mint, 0.12)} color={Colors.mint} />}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    padding: 16,
    borderRadius: 18,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  flex: { flex: 1 },
  sub: { marginTop: 2 },
});
