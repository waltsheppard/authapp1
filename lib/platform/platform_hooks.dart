import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PlatformHooks {
  const PlatformHooks();

  Future<void> onAppLaunch(Ref ref) async {}

  Future<void> onAppResume(Ref ref) async {}

  Future<void> onAppPaused(Ref ref) async {}

  Future<void> onDeepLink(Ref ref, Uri link) async {}

  Future<void> onSignOut(Ref ref) async {}
}

class DefaultPlatformHooks extends PlatformHooks {
  const DefaultPlatformHooks();
}

final platformHooksProvider = Provider<PlatformHooks>((ref) {
  return const DefaultPlatformHooks();
});
