import { Image, type ImageStyle, type StyleProp } from 'react-native';

const SOURCES = {
  full: require('../../../assets/images/full-logo.png'),
  text: require('../../../assets/images/text-logo.png'),
  icon: require('../../../assets/images/symbol-logo.png'),
} as const;

/** One of the three EchoPay logo assets. */
export function AppLogo({
  type = 'full',
  width,
  height,
  style,
}: {
  type?: keyof typeof SOURCES;
  width?: number;
  height?: number;
  style?: StyleProp<ImageStyle>;
}) {
  return (
    <Image
      source={SOURCES[type]}
      style={[{ width, height }, style]}
      resizeMode="contain"
      accessibilityLabel="EchoPay"
    />
  );
}
