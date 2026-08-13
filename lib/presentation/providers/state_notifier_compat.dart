/// Compatibility layer for StateNotifier + StateNotifierProvider
/// with Riverpod 3.x which removed these from the core package.
///
/// We re-export state_notifier and provide a StateNotifierProvider
/// implementation that wraps the state_notifier package with riverpod.
library presentation.providers.state_notifier_compat;

export 'package:state_notifier/state_notifier.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart' as sn;

/// A provider that creates a [StateNotifier] and exposes its [state].
///
/// This is a compatibility shim for code that was written for
/// flutter_riverpod 2.x. New code should prefer [NotifierProvider].
class StateNotifierProvider<Notifier extends sn.StateNotifier<State>, State>
    extends NotifierProvider<Notifier, State> {
  StateNotifierProvider(super._create, {super.name, super.dependencies});

  @override
  Notifier build() => _create();
}

/// A simple state provider compatibility shim.
/// Creates a notifier that holds a single value.
class StateProvider<State> extends NotifierProvider<StateNotifierShim<State>, State> {
  StateProvider(super._create, {super.name, super.dependencies});
}

/// A shim Notifier that mimics StateProvider behavior.
class StateNotifierShim<State> extends sn.StateNotifier<State> {
  StateNotifierShim(State initialState) : super(initialState);
}
