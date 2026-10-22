// Reanimated ships its own Jest helpers; this makes animations resolve
// synchronously and exposes the full API (Easing, layout animations, …).
require('react-native-reanimated').setUpTests();

// Icon fonts load through the asset registry, which Jest doesn't have.
jest.mock('@expo/vector-icons/MaterialIcons', () => {
  const { Text } = require('react-native');
  const Icon = ({ name }) => <Text>{name}</Text>;
  Icon.font = {};
  Icon.glyphMap = {};
  return { __esModule: true, default: Icon };
});
