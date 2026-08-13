/// Compatibility layer for StateNotifier + StateNotifierProvider
/// with Riverpod 3.x which removed these from the core package.
library presentation.providers.state_notifier_compat;

export 'package:state_notifier/state_notifier.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart' as sn;

/// Creates a [NotifierProvider] that wraps a [StateNotifier].
/// This replaces StateNotifierProvider from riverpod 2.x.
///
/// Usage:
///   final myProvider = stateNotifierProvider<MyNotifier, MyState>(MyNotifier.new);
NotifierProvider<NotifierT, StateT>
    stateNotifierProvider<NotifierT extends sn.StateNotifier<StateT>, StateT>(
  NotifierT Function() create, {
  String? name,
}) {
  return NotifierProvider<NotifierT, StateT>(
    create,
    name: name,
  );
}

/// A simple state holder provider, replacing StateProvider.
/// Returns a [NotifierProvider] backed by a simple [StateNotifier].
///
/// Usage:
///   final themeProvider = stateProvider<ThemeMode>((ref) => ThemeMode.system);
NotifierProvider<sn.StateNotifier<StateT>, StateT>
    stateProvider<StateT>(
  StateT Function() initialValue, {
  String? name,
}) {
  return NotifierProvider<sn.StateNotifier<StateT>, StateT>(
    () => sn.StateNotifier(initialValue()),
    name: name,
  );
}
