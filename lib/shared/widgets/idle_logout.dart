import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukaapp/app/router.dart';
import 'package:dukaapp/features/auth/presentation/controllers/auth_controller.dart';

/// Signs the user out after [timeout] without touching the screen, counting the
/// time the app spent in the background too, and opens the login page.
class IdleLogout extends ConsumerStatefulWidget {
  const IdleLogout({super.key, required this.child, this.timeout = const Duration(minutes: 30)});

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends ConsumerState<IdleLogout> with WidgetsBindingObserver {
  DateTime _lastActivity = DateTime.now();
  Timer? _timer;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background: the time away counts as idle time.
    if (state == AppLifecycleState.resumed) _check();
  }

  void _touch([_]) => _lastActivity = DateTime.now();

  Future<void> _check() async {
    if (_signingOut) return;
    if (ref.read(authProvider).status != AuthStatus.authenticated) {
      _lastActivity = DateTime.now(); // the clock starts at login
      return;
    }
    if (DateTime.now().difference(_lastActivity) < widget.timeout) return;

    _signingOut = true;
    try {
      await ref.read(authProvider.notifier).signOut();
      ref.read(appRouterProvider).go('/login');
    } finally {
      _signingOut = false;
      _lastActivity = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Any touch, scroll or mouse movement anywhere in the app is activity.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _touch,
      onPointerMove: _touch,
      onPointerSignal: _touch,
      child: widget.child,
    );
  }
}
