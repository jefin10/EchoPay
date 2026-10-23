import { Text, type TextProps } from 'react-native';

import { Type } from '@/core/theme';

/** `Text` with the app's body font and ink colour as defaults. */
export function AppText({ style, ...rest }: TextProps) {
  return <Text {...rest} style={[Type.body(), style]} />;
}
