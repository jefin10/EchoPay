import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';

import { confirmWithBiometrics } from '@/core/biometrics';
import { AppButton, AppDialog, AppText, Entrance, Icon, Screen, ScreenHeader, Tap, toast } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { alpha, Colors, Motion, Type } from '@/core/theme';
import { formatINR } from '@/core/utils/format';
import { getBalance } from '@/features/account/api';
import { useRefreshAccount } from '@/features/account/hooks';
import { createMoneyRequest, createMoneyRequestByUpi, sendByPhone, sendByUpiId } from '@/features/payments/api';
import { SuccessDialog } from '@/features/payments/components/SuccessDialog';
import type { DeviceContact } from '@/features/payments/contacts';
import { processCommand } from '@/features/voice/api';
import { ConfirmSheet } from '@/features/voice/components/ConfirmSheet';
import { ServerStatus } from '@/features/voice/components/ServerStatus';
import { useVoiceServerHealth } from '@/features/voice/hooks';
import { resolveRecipient, type Target } from '@/features/voice/resolve';
import { useSpeech } from '@/features/voice/use-speech';

const SAMPLES = ['Send ₹500 to 9876543210', "What's my balance?", 'Request ₹200 from 9123456789'];

type Pending = {
  mode: 'transfer' | 'request';
  amount?: number;
  target?: Target;
  choices?: { name: string; matches: DeviceContact[] };
};

export default function SpeechScreen() {
  const { phoneNumber, flags } = useSession();
  const online = useVoiceServerHealth().data === true;
  const refreshAccount = useRefreshAccount();

  const [processing, setProcessing] = useState(false);
  const [reply, setReply] = useState<{ text: string; ok: boolean } | null>(null);
  const [pending, setPending] = useState<Pending | null>(null);
  const [executing, setExecuting] = useState(false);
  const [done, setDone] = useState<{ title: string; message: string } | null>(null);
  const [balance, setBalance] = useState<number | null>(null);

  const handleCommand = async (text: string) => {
    if (!online) {
      setReply({ text: 'Voice server is offline. Check that the backend is running.', ok: false });
      return;
    }
    setReply(null);
    setProcessing(true);
    try {
      const outcome = await processCommand(text, phoneNumber ?? '');
      if (!outcome.success) return setReply({ text: outcome.message, ok: false });

      if (outcome.action === 'transfer' || outcome.action === 'request') {
        const resolution = await resolveRecipient(outcome);
        if (resolution.status === 'failed') return setReply({ text: resolution.message, ok: false });
        setPending({
          mode: outcome.action,
          amount: outcome.amount,
          ...(resolution.status === 'resolved'
            ? { target: resolution.target }
            : { choices: { name: resolution.name, matches: resolution.matches } }),
        });
      } else if (outcome.action === 'balance') {
        if (!(await confirmWithBiometrics('Authenticate to view your balance', flags.biometricEnabled))) {
          return setReply({ text: 'Authentication cancelled', ok: false });
        }
        setBalance(await getBalance(phoneNumber ?? ''));
      } else {
        setReply({ text: outcome.message, ok: true });
      }
    } catch (e) {
      setReply({ text: e instanceof Error ? e.message : 'Something went wrong.', ok: false });
    } finally {
      setProcessing(false);
    }
  };

  const speech = useSpeech(handleCommand);

  const execute = async (amount: number, target: Target) => {
    if (!pending) return;
    const verb = pending.mode === 'transfer' ? 'send' : 'request';
    if (!(await confirmWithBiometrics(`Authenticate to ${verb} ${formatINR(amount)}`, flags.biometricEnabled))) {
      return toast('Authentication cancelled', 'error');
    }
    const me = phoneNumber ?? '';
    setExecuting(true);
    const result =
      pending.mode === 'transfer'
        ? target.kind === 'upi'
          ? await sendByUpiId({ senderPhone: me, receiverUpi: target.upiId, amount })
          : await sendByPhone({ senderPhone: me, receiverPhone: target.phone, amount })
        : target.kind === 'upi'
          ? await createMoneyRequestByUpi({ requesterPhone: me, requesteeUpi: target.upiId, amount })
          : await createMoneyRequest({ requesterPhone: me, requesteePhone: target.phone, amount });
    setExecuting(false);
    if (!result.success) return toast(result.message, 'error');

    setPending(null);
    refreshAccount();
    setDone(
      pending.mode === 'transfer'
        ? { title: 'Payment sent', message: `${formatINR(amount)} to ${target.label}` }
        : { title: 'Request sent', message: `Asked ${target.label} for ${formatINR(amount)}` },
    );
  };

  const runSample = (sample: string) => {
    speech.setTranscript(sample);
    handleCommand(sample.replace('₹', ''));
  };

  const showIntro = !speech.listening && !speech.transcript && !processing && !reply;

  return (
    <Screen contentStyle={styles.content}>
      <ScreenHeader title="voice pay" right={<ServerStatus />} />

      <View style={styles.body}>
        {showIntro && (
          <Entrance style={styles.intro}>
            <AppText style={Type.eyebrow()}>voice pay</AppText>
            <AppText style={[Type.heading(30, 800), styles.introTitle]}>{'Just say what\nyou want to do.'}</AppText>
            <View style={styles.samples}>
              {SAMPLES.map((s) => (
                <Tap key={s} onPress={() => runSample(s)} style={styles.sample} accessibilityRole="button">
                  <AppText style={Type.body(13, 600)}>{s}</AppText>
                </Tap>
              ))}
            </View>
          </Entrance>
        )}

        {(speech.listening || speech.transcript) && (
          <Entrance distance={8} style={styles.card}>
            {speech.listening && (
              <View style={styles.listeningRow}>
                <View style={styles.liveDot} />
                <AppText style={Type.eyebrow(Colors.coral)}>listening</AppText>
              </View>
            )}
            <AppText style={Type.heading(20)}>{speech.transcript ? `“${speech.transcript}”` : 'say something...'}</AppText>
          </Entrance>
        )}

        {processing && (
          <View style={styles.processing}>
            <ActivityIndicator color={Colors.ink} />
            <AppText style={Type.body(14, 600, Colors.textSecondary)}>processing...</AppText>
          </View>
        )}

        {(reply || speech.error) && (
          <Entrance distance={8} style={[styles.reply, !(reply?.ok ?? false) && styles.replyError]}>
            <Icon
              name={reply?.ok ? 'assistant' : 'error-outline'}
              size={20}
              color={reply?.ok ? Colors.primary : Colors.coral}
            />
            <AppText style={[Type.body(14, 600), styles.flex]}>{reply?.text ?? speech.error}</AppText>
            <Tap onPress={() => setReply(null)} hitSlop={8} accessibilityLabel="Dismiss">
              <Icon name="close" size={18} color={Colors.textSecondary} />
            </Tap>
          </Entrance>
        )}
      </View>

      <View style={styles.micArea}>
        <MicButton
          listening={speech.listening}
          disabled={processing}
          onPress={() => (speech.listening ? speech.stop() : speech.start())}
        />
        <AppText style={Type.body(13, 600, Colors.textSecondary)}>
          {speech.listening ? 'Tap to stop' : 'Tap to speak'}
        </AppText>
      </View>

      {pending && (
        <ConfirmSheet
          mode={pending.mode}
          initialAmount={pending.amount}
          target={pending.target}
          choices={pending.choices}
          busy={executing}
          onCancel={() => setPending(null)}
          onConfirm={execute}
        />
      )}

      <SuccessDialog
        visible={done != null}
        title={done?.title ?? ''}
        message={done?.message ?? ''}
        onDone={() => setDone(null)}
      />

      <AppDialog visible={balance != null} onClose={() => setBalance(null)}>
        <AppText style={Type.eyebrow()}>available balance</AppText>
        <AppText style={[Type.amount(40), styles.balance]}>{formatINR(balance ?? 0)}</AppText>
        <AppButton label="Done" onPress={() => setBalance(null)} style={styles.stretch} />
      </AppDialog>
    </Screen>
  );
}

function MicButton({ listening, disabled, onPress }: { listening: boolean; disabled: boolean; onPress: () => void }) {
  const reduce = useReducedMotion();
  const glow = useSharedValue(0);
  useEffect(() => {
    if (listening && !reduce) glow.set(withRepeat(withTiming(1, { duration: 1200, easing: Motion.out }), -1, false));
    else glow.set(withTiming(0, { duration: Motion.fast }));
  }, [listening, reduce, glow]);
  const ring = useAnimatedStyle(() => ({
    opacity: 0.35 * (1 - glow.get()),
    transform: [{ scale: 1 + glow.get() * 0.6 }],
  }));

  return (
    <View style={styles.micWrap}>
      <Animated.View style={[styles.micRing, ring]} />
      <Tap
        scale={0.94}
        onPress={onPress}
        disabled={disabled}
        style={[styles.mic, listening && styles.micActive, disabled && styles.micDisabled]}
        accessibilityRole="button"
        accessibilityLabel={listening ? 'Stop listening' : 'Start listening'}>
        <Icon name={listening ? 'stop' : 'mic'} size={36} color={listening ? Colors.white : Colors.pop} />
      </Tap>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { flexGrow: 1 },
  flex: { flex: 1 },
  body: { flex: 1, marginTop: 24, gap: 16 },
  intro: { gap: 10 },
  introTitle: { lineHeight: 34 },
  samples: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 10 },
  sample: {
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 40,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  card: {
    padding: 20,
    gap: 10,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  listeningRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  liveDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: Colors.coral },
  processing: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingHorizontal: 4 },
  reply: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    padding: 16,
    borderRadius: 16,
    backgroundColor: Colors.primaryLight,
  },
  replyError: { backgroundColor: alpha(Colors.coral, 0.08) },
  micArea: { alignItems: 'center', gap: 14, paddingTop: 24 },
  micWrap: { width: 120, height: 120, alignItems: 'center', justifyContent: 'center' },
  micRing: { position: 'absolute', width: 96, height: 96, borderRadius: 48, backgroundColor: Colors.coral },
  mic: {
    width: 96,
    height: 96,
    borderRadius: 34,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
  },
  micActive: { backgroundColor: Colors.coral },
  micDisabled: { opacity: 0.5 },
  balance: { marginTop: 10 },
  stretch: { alignSelf: 'stretch', marginTop: 22 },
});
