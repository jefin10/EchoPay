import { Asset, requestPermissionsAsync } from 'expo-media-library';
import * as Sharing from 'expo-sharing';
import { useRef, useState, type ComponentRef } from 'react';
import { StyleSheet, View } from 'react-native';
import QRCode from 'react-native-qrcode-svg';
import { captureRef } from 'react-native-view-shot';

import { AppButton, AppText, Avatar, Entrance, IconButton, Screen, ScreenHeader, Tap, toast } from '@/core/components';
import { Colors, Type } from '@/core/theme';
import { useProfile } from '@/features/account/hooks';
import { buildUpiUri } from '@/features/payments/upi-qr';
import { useCopyUpi } from '@/features/profile/use-copy-upi';

const STEPS = [
  'Show this QR to anyone who wants to pay you',
  'They scan it with any UPI app',
  'Money is received instantly',
];

export default function MyQrScreen() {
  const profile = useProfile();
  const name = profile.data?.userName || 'User';
  const upiId = profile.data?.upiId ?? '';
  const card = useRef<ComponentRef<typeof View>>(null);
  const [saving, setSaving] = useState(false);

  const capture = () => captureRef(card, { format: 'png', quality: 1, result: 'tmpfile' });

  const share = async () => {
    try {
      if (!(await Sharing.isAvailableAsync())) return toast('Sharing is not available on this device', 'error');
      await Sharing.shareAsync(await capture(), { mimeType: 'image/png', dialogTitle: 'Share my EchoPay QR' });
    } catch {
      toast('Could not share the QR code', 'error');
    }
  };

  const save = async () => {
    setSaving(true);
    try {
      const { granted } = await requestPermissionsAsync(true);
      if (!granted) return toast('Allow photo access to save the QR', 'error');
      await Asset.create(await capture());
      toast('Saved to your photos', 'success');
    } catch {
      toast('Could not save the QR code', 'error');
    } finally {
      setSaving(false);
    }
  };

  const copy = useCopyUpi(upiId);

  return (
    <Screen>
      <Entrance>
        <ScreenHeader title="my qr" right={<IconButton icon="share" accessibilityLabel="Share QR" onPress={share} />} />

        <View ref={card} collapsable={false} style={styles.card}>
          <View style={styles.person}>
            <Avatar name={name} size={48} background={Colors.ink} color={Colors.pop} />
            <View style={styles.flex}>
              <AppText style={Type.heading(17)} numberOfLines={1}>
                {name}
              </AppText>
              <Tap onPress={upiId ? copy : undefined} accessibilityLabel="Copy UPI ID" style={styles.upiRow}>
                <AppText style={Type.body(13, 600, Colors.textSecondary)}>{upiId || '—'}</AppText>
              </Tap>
            </View>
          </View>
          <View style={styles.qr}>
            {upiId ? (
              <QRCode value={buildUpiUri({ upiId, name })} size={220} color={Colors.ink} backgroundColor={Colors.surface} />
            ) : (
              <View style={styles.qrPlaceholder} />
            )}
          </View>
          <AppText style={[Type.eyebrow(), styles.centered]}>scan to pay me</AppText>
        </View>

        <View style={styles.steps}>
          <AppText style={Type.eyebrow()}>how it works</AppText>
          {STEPS.map((text, i) => (
            <View key={text} style={styles.step}>
              <View style={styles.stepNum}>
                <AppText style={Type.body(12, 800, Colors.pop)}>{i + 1}</AppText>
              </View>
              <AppText style={[Type.body(14, 600), styles.flex]}>{text}</AppText>
            </View>
          ))}
        </View>

        <View style={styles.actions}>
          <AppButton label="Share QR" icon="share" onPress={share} disabled={!upiId} />
          <AppButton label="Save to gallery" icon="download" outline loading={saving} onPress={save} disabled={!upiId} />
        </View>
      </Entrance>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  card: {
    marginTop: 24,
    padding: 22,
    gap: 20,
    borderRadius: 28,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  person: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  upiRow: { marginTop: 2, alignSelf: 'flex-start' },
  qr: { alignItems: 'center', padding: 12 },
  qrPlaceholder: { width: 220, height: 220, borderRadius: 12, backgroundColor: Colors.surfaceDim },
  centered: { textAlign: 'center' },
  steps: { marginTop: 22, gap: 12 },
  step: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  stepNum: {
    width: 28,
    height: 28,
    borderRadius: 9,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actions: { marginTop: 26, gap: 12 },
});
