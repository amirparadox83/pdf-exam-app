/// Compatibility layer for StateNotifier + StateNotifierProvider
/// with Riverpod 3.x which removed these from the core package.
library presentation.providers.state_notifier_compat;

export 'package:state_notifier/state_notifier.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart' as sn;

/// Creates a StateNotifierProvider-like provider using NotifierProvider.
///
/// Usage: final myProvider = stateNotifierProvider<MyNotifier, MyState>(MyNotifier.new);
StateNotifierProvider<NotifierT extends sn.StateNotifier<StateT>, StateT>
    stateNotifierProvider<NotifierT extends sn.StateNotifier<StateT>, StateT>(
  NotifierT Function() create, {
  String? name,
  Iterable<ProviderFamily>? dependencies,
}) {
  return NotifierProvider<NotifierT, StateT>(
    create,
    name: name,
    dependencies: dependencies,
  );
}

/// Creates a StateProvider-like provider.
///
/// Usage: final myProvider = stateProvider<MyState>((ref) => initialValue);
Provider<StateT> stateProvider<StateT>(
  StateT Function(Ref ref) create, {
  String? name,
  Iterable<ProviderFamily>? dependencies,
}) {
  return Provider<StateT>(
    create,
    name: name,
    dependencies: dependencies,
  );
}
