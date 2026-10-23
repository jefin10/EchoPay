import { CameraView, scanFromURLAsync, useCameraPermissions, type BarcodeScanningResult } from 'expo-camera';
import * as ImagePicker from 'expo-image-picker';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Linking, StyleSheet, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton, AppText, Icon, IconButton, Tap, toast, type IconName } from '@/core/components';
import { alpha, Colors, Motion, Type } from '@/core/theme';
import { parseUpiQr, type UpiQr } from '@/features/payments/upi-qr';

const FRAME = 260;

export default function QrScannerScreen() {
  const [permission, requestPermission] = useCameraPermissions();
  const [torch, setTorch] = useState(false);
  const [scanned, setScanned] = useState<{ raw: string; upi: UpiQr | null } | null>(null);

  useEffect(() => {
    if (permission && !permission.granted && permission.canAskAgain) requestPermission();
  }, [permission, requestPermission]);

  const handle = (raw: string) => setScanned({ raw, upi: parseUpiQr(raw) });

  const onBarcode = ({ data }: BarcodeScanningResult) => {
    if (!scanned && data) handle(data);
  };

  const pickFromGallery = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 1 });
    if (result.canceled || !result.assets[0]) return;
    try {
      const [code] = await scanFromURLAsync(result.assets[0].uri, ['qr']);
      if (code?.data) handle(code.data);
      else toast('No QR code found in that image', 'error');
    } catch {
      toast('Could not read that image', 'error');
    }
  };

  const proceed = () => {
    if (!scanned?.upi) return;
    const { upiId, name, amount } = scanned.upi;
    router.replace({ pathname: '/pay/upi', params: { upi: upiId, name: name ?? '', amount: amount ?? '' } });
  };

  return (
    <View style={styles.root}>
      {permission?.granted ? (
        <CameraView
          style={StyleSheet.absoluteFill}
          facing="back"
          enableTorch={torch}
          barcodeScannerSettings={{ barcodeTypes: ['qr'] }}
          onBarcodeScanned={scanned ? undefined : onBarcode}
        />
      ) : (
        <View style={[StyleSheet.absoluteFill, styles.noCamera]}>
          <Icon name="photo-camera" size={36} color={alpha(Colors.white, 0.6)} />
          <AppText style={[Type.body(14, 600, alpha(Colors.white, 0.8)), styles.center]}>
            {permission && !permission.canAskAgain
              ? 'Camera access is off. Enable it in settings to scan QR codes.'
              : 'Camera permission is needed to scan QR codes.'}
          </AppText>
          <AppButton
            label={permission && !permission.canAskAgain ? 'Open settings' : 'Allow camera'}
            background={Colors.pop}
            foreground={Colors.ink}
            onPress={() => (permission && !permission.canAskAgain ? Linking.openSettings() : requestPermission())}
            style={styles.permissionButton}
          />
        </View>
      )}

      <SafeAreaView style={styles.overlay} pointerEvents="box-none">
        <View style={styles.topBar}>
          <IconButton icon="arrow-back" accessibilityLabel="Back" dark onPress={() => router.back()} />
          <AppText style={[Type.heading(20, 700, Colors.white), styles.flex]}>scan & pay</AppText>
          <IconButton
            icon={torch ? 'flash-on' : 'flash-off'}
            accessibilityLabel={torch ? 'Turn torch off' : 'Turn torch on'}
            dark
            onPress={() => setTorch((t) => !t)}
          />
        </View>

        {permission?.granted && !scanned && <ScanFrame />}
        <View style={styles.flex} />

        <View style={styles.panel}>
          {scanned ? (
            <View style={styles.result}>
              <View style={styles.resultHead}>
                <Icon name="check-circle" size={20} color={Colors.mint} />
                <AppText style={Type.eyebrow(Colors.ink)}>qr scanned</AppText>
              </View>
              {scanned.upi ? (
                <>
                  <Row label="UPI ID" value={scanned.upi.upiId} />
                  {scanned.upi.name && <Row label="Name" value={scanned.upi.name} />}
                  {scanned.upi.amount && <Row label="Amount" value={`₹${scanned.upi.amount}`} />}
                  <AppButton label="Proceed to pay" icon="arrow-forward" onPress={proceed} />
                </>
              ) : (
                <AppText style={Type.body(13, 500, Colors.textSecondary)} numberOfLines={3}>
                  Not a UPI payment code: {scanned.raw}
                </AppText>
              )}
            </View>
          ) : (
            <View style={styles.prompt}>
              <View style={styles.promptIcon}>
                <Icon name="qr-code-2" size={28} color={Colors.pop} />
              </View>
              <AppText style={Type.heading(17)}>Point camera at a QR</AppText>
              <AppText style={Type.body(13, 500, Colors.textSecondary)}>Any UPI QR code works.</AppText>
            </View>
          )}
          <View style={styles.actions}>
            <Action icon="photo-library" label="Gallery" onPress={pickFromGallery} />
            <Action icon="qr-code" label="My QR" onPress={() => router.push('/my-qr')} />
            <Action icon="refresh" label="Rescan" onPress={() => setScanned(null)} />
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
}

function ScanFrame() {
  const reduce = useReducedMotion();
  const y = useSharedValue(0);
  useEffect(() => {
    if (!reduce) y.set(withRepeat(withTiming(1, { duration: 1800, easing: Motion.inOut }), -1, true));
  }, [reduce, y]);
  const line = useAnimatedStyle(() => ({ transform: [{ translateY: 10 + y.get() * (FRAME - 26) }] }));
  return (
    <View style={styles.frameWrap} pointerEvents="none">
      <View style={styles.frame}>
        <Animated.View style={[styles.scanLine, line]} />
      </View>
    </View>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.row}>
      <AppText style={[Type.body(12, 600, Colors.textSecondary), styles.rowLabel]}>{label}</AppText>
      <AppText style={[Type.body(14, 700), styles.flex]} numberOfLines={1}>
        {value}
      </AppText>
    </View>
  );
}

function Action({ icon, label, onPress }: { icon: IconName; label: string; onPress: () => void }) {
  return (
    <Tap onPress={onPress} style={styles.action} accessibilityRole="button">
      <Icon name={icon} size={20} />
      <AppText style={[Type.body(12, 700), styles.actionLabel]}>{label}</AppText>
    </Tap>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.backgroundDark },
  overlay: { flex: 1 },
  flex: { flex: 1 },
  center: { textAlign: 'center' },
  noCamera: { alignItems: 'center', justifyContent: 'center', gap: 14, padding: 40, paddingBottom: 240 },
  permissionButton: { alignSelf: 'stretch', marginTop: 8 },
  topBar: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: 20, paddingTop: 8 },
  frameWrap: { alignItems: 'center', marginTop: 48 },
  frame: { width: FRAME, height: FRAME, borderRadius: 24, borderWidth: 3, borderColor: Colors.pop },
  scanLine: { position: 'absolute', left: 10, right: 10, height: 2, backgroundColor: Colors.pop },
  panel: {
    marginHorizontal: 16,
    marginBottom: 16,
    padding: 20,
    gap: 16,
    borderRadius: 28,
    backgroundColor: Colors.surfaceLight,
  },
  result: { gap: 12 },
  resultHead: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  rowLabel: { width: 70 },
  prompt: { alignItems: 'center', gap: 4 },
  promptIcon: {
    width: 56,
    height: 56,
    borderRadius: 18,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10,
  },
  actions: { flexDirection: 'row', gap: 10 },
  action: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 14,
    borderRadius: 16,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  actionLabel: { marginTop: 6 },
});
