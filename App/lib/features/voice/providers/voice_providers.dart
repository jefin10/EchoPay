import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/voice_repository.dart';

final voiceRepositoryProvider = Provider<VoiceRepository>(
  (ref) => VoiceRepository(ref.watch(apiClientProvider)),
);

/// Whether the intent server is reachable. Used by the voice screen's
/// online/offline chip; re-read to re-check.
final voiceServerHealthProvider = FutureProvider<bool>(
  (ref) => ref.watch(voiceRepositoryProvider).checkServerHealth(),
);
