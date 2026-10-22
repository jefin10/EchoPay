import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppButton, AppText, Icon, IconButton, Screen, Sheet, Stagger, Tap, type IconName } from '@/core/components';
import { Colors, Type } from '@/core/theme';
import { ServerStatus } from '@/features/voice/components/ServerStatus';

const EXAMPLES = ['Send ₹500 to 9876543210', "What's my balance?", 'Request ₹300 from Mom'];

const PLAYBOOK: { icon: IconName; title: string; example: string }[] = [
  { icon: 'send', title: 'Send money', example: '"Send 500 to 98765 43210"' },
  { icon: 'account-balance-wallet', title: 'Check balance', example: '"What\'s my balance?"' },
  { icon: 'call-received', title: 'Request money', example: '"Request 300 from Mom"' },
  { icon: 'chat-bubble-outline', title: 'Just chat', example: '"Hello, how are you?"' },
];

export default function VoiceTab() {
  const [helpOpen, setHelpOpen] = useState(false);
  const openSpeech = () => router.push('/speech');

  return (
    <Screen edges={['top']}>
      <Stagger>
        <View style={styles.header}>
          <AppText style={[Type.heading(22), styles.flex]}>voice</AppText>
          <ServerStatus />
          <IconButton icon="help-outline" accessibilityLabel="What can I say?" onPress={() => setHelpOpen(true)} />
        </View>

        <View style={styles.hero}>
          <AppText style={[Type.heading(40, 800), styles.heroTitle]}>{'speak it.\nwe pay it.'}</AppText>
          <AppText style={Type.body(15, 500, Colors.textSecondary)}>
            Say a name or number and an amount, and we will line it up.
          </AppText>
        </View>

        <Tap scale={0.96} onPress={openSpeech} style={styles.bigMic} accessibilityRole="button" accessibilityLabel="Tap to speak">
          <View style={styles.micCircle}>
            <Icon name="mic" size={40} color={Colors.pop} />
          </View>
          <AppText style={Type.eyebrow(Colors.white)}>tap to speak</AppText>
        </Tap>

        <View style={styles.examples}>
          {EXAMPLES.map((e) => (
            <View key={e} style={styles.example}>
              <Icon name="graphic-eq" size={18} color={Colors.primary} />
              <AppText style={Type.body(14, 600)}>“{e}”</AppText>
            </View>
          ))}
        </View>

        <AppButton label="Start voice command" icon="mic" onPress={openSpeech} />
      </Stagger>

      <Sheet visible={helpOpen} onClose={() => setHelpOpen(false)}>
        <AppText style={Type.eyebrow()}>voice playbook</AppText>
        <AppText style={[Type.heading(22), styles.sheetTitle]}>Things you can say</AppText>
        {PLAYBOOK.map((p) => (
          <View key={p.title} style={styles.helpRow}>
            <View style={styles.helpIcon}>
              <Icon name={p.icon} size={18} />
            </View>
            <View style={styles.flex}>
              <AppText style={Type.body(15, 700)}>{p.title}</AppText>
              <AppText style={Type.body(13, 500, Colors.textSecondary)}>{p.example}</AppText>
            </View>
          </View>
        ))}
        <AppButton label="Got it" onPress={() => setHelpOpen(false)} style={styles.gotIt} />
      </Sheet>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  hero: { marginTop: 32, gap: 12 },
  heroTitle: { lineHeight: 44 },
  bigMic: {
    marginTop: 28,
    alignItems: 'center',
    gap: 16,
    paddingVertical: 28,
    borderRadius: 28,
    backgroundColor: Colors.ink,
  },
  micCircle: {
    width: 88,
    height: 88,
    borderRadius: 30,
    backgroundColor: 'rgba(255,255,255,0.08)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  examples: { marginTop: 24, marginBottom: 24, gap: 10 },
  example: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 14,
    borderRadius: 16,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  sheetTitle: { marginTop: 6, marginBottom: 10 },
  helpRow: { flexDirection: 'row', alignItems: 'center', gap: 14, paddingVertical: 10 },
  helpIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: Colors.surfaceDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  gotIt: { marginTop: 16 },
});
