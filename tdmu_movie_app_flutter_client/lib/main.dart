import 'package:flutter/material.dart';

import 'models/auth_session.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MovieApp());
}

class MovieApp extends StatefulWidget {
  MovieApp({
    super.key,
    AuthService? authService,
    this.restoreSessionOnStart = true,
  }) : authService = authService ?? AuthService();

  final AuthService authService;
  final bool restoreSessionOnStart;

  @override
  State<MovieApp> createState() => _MovieAppState();
}

class _MovieAppState extends State<MovieApp> {
  late final AuthService _authService;
  AuthSession? _session;
  late bool _isBootstrapping;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _isBootstrapping = widget.restoreSessionOnStart;

    if (widget.restoreSessionOnStart) {
      _restoreSession();
    }
  }

  Future<void> _restoreSession() async {
    final session = await _authService.restoreSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _isBootstrapping = false;
    });
  }

  Future<void> _onLoggedOut() async {
    await _authService.clearSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TDMU Movie App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _isBootstrapping
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_session == null
                ? AuthScreen(
                    authService: _authService,
                    onAuthenticated: (session) {
                      setState(() {
                        _session = session;
                      });
                    },
                  )
                : HomeScreen(session: _session!, onLogout: _onLoggedOut)),
    );
  }
}
