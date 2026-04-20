import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Label of a main-screen tab that widgets want to switch to.
/// Set this to navigate within the current [ResponsiveScaffold] instead of
/// pushing a new route (which would lose the sidebar/bottom-nav).
/// The main screen listens to changes, applies them, and resets back to null.
final requestedMainTabProvider = StateProvider<String?>((ref) => null);
