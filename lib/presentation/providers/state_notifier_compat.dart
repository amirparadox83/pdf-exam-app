/// Compatibility layer for Riverpod 3.x.
///
/// Riverpod 3.x removed `StateNotifier`, `StateNotifierProvider`, and
/// `StateProvider` from the core package.  This file re-exports the
/// `state_notifier` package (for any external consumers) and provides
/// migration helpers so existing code can switch to Riverpod 3.x
/// `Notifier` + `NotifierProvider` with minimal diffs.
library presentation.providers.state_notifier_compat;

// Keep the export so that files that imported this for StateNotifier
// still compile.  The actual StateNotifier class is still available
// from this package — we just don't use it with NotifierProvider anymore.
export 'package:state_notifier/state_notifier.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
