import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/wellq_theme.dart';
import 'models/session.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient_portal_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WellQApp());
}

class WellQApp extends StatefulWidget {
  const WellQApp({super.key});
  @override
  State<WellQApp> createState() => _WellQAppState();
}

class _WellQAppState extends State<WellQApp> {
  final ApiClient _api = ApiClient();
  Session? _session;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final name = prefs.getString('user_name');
    var roles = prefs.getStringList('user_roles') ?? const <String>[];
    var userId = prefs.getString('user_id');

    if (token != null && name != null) {
      try {
        final response = await _api.getJson('/auth/me', token);
        final user = Map<String, dynamic>.from(response['user'] as Map);
        roles = List<String>.from(user['roles'] as List? ?? const []);
        userId = user['userId'] as String? ?? userId;
        await prefs.setStringList('user_roles', roles);
        if (userId != null) await prefs.setString('user_id', userId);
        _session = Session(
          accessToken: token,
          userName: name,
          roles: roles,
          userId: userId,
        );
      } catch (_) {
        _session = Session(
          accessToken: token,
          userName: name,
          roles: roles,
          userId: userId,
        );
      }
    }
    if (mounted) setState(() => _restoring = false);
  }

  Future<void> _onAuthenticated(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', session.accessToken);
    await prefs.setString('user_name', session.userName);
    await prefs.setStringList('user_roles', session.roles);
    if (session.userId != null)
      await prefs.setString('user_id', session.userId!);
    if (mounted) setState(() => _session = session);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_roles');
    await prefs.remove('user_id');
    if (mounted) setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WellQ',
    debugShowCheckedModeBanner: false,
    theme: WellQTheme.light,
    darkTheme: WellQTheme.dark,
    themeMode: ThemeMode.system,
    home: _restoring
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _session == null
        ? LoginScreen(api: _api, onAuthenticated: _onAuthenticated)
        : _session!.isPatient
        ? PatientPortalScreen(api: _api, session: _session!, onLogout: _logout)
        : HomeScreen(api: _api, session: _session!, onLogout: _logout),
  );
}
