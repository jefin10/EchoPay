import type { ReactNode } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppText, Entrance } from '@/core/components';
import { Colors, Type } from '@/core/theme';

/**
 * Shared shell for the onboarding screens: eyebrow, big heading, subtitle,
 * body, and a footer pinned to the bottom above the keyboard.
 */
export function AuthLayout({
  top,
  eyebrow,
  title,
  subtitle,
  children,
  footer,
}: {
  top?: ReactNode;
  eyebrow: string;
  title: string;
  subtitle?: ReactNode;
  children?: ReactNode;
  footer: ReactNode;
}) {
  return (
    <SafeAreaView style={styles.root}>
      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <Entrance style={styles.flex}>
            {top}
            <View style={styles.header}>
              <AppText style={Type.eyebrow(Colors.primary)}>{eyebrow}</AppText>
              <AppText style={[Type.heading(38, 800), styles.title]}>{title}</AppText>
              {subtitle ? <AppText style={[Type.body(15, 500, Colors.textSecondary), styles.subtitle]}>{subtitle}</AppText> : null}
            </View>
            {children}
            <View style={styles.spacer} />
            {footer}
          </Entrance>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.surfaceLight },
  flex: { flex: 1 },
  content: { flexGrow: 1, paddingHorizontal: 24, paddingTop: 8, paddingBottom: 24 },
  header: { marginTop: 28, marginBottom: 36, gap: 12 },
  title: { lineHeight: 42 },
  subtitle: { lineHeight: 21, marginTop: 2 },
  spacer: { flex: 1, minHeight: 32 },
});
