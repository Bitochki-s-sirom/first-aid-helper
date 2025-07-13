import 'package:flutter/material.dart';
import 'colors/colors.dart';
import 'colors/themes.dart';
import 'pages/chathelper.dart';
import 'pages/medications.dart';
import 'pages/profile.dart';
import 'pages/records.dart';
import 'widgets/squareavatar.dart';
import 'services/api_service.dart';
import 'services/local_storage.dart';
import 'utils/validators.dart';
import 'pages/loginpage.dart';
import 'pages/signuppage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoggedIn = false;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _login(String email, String password) async {
    try {
      final response = await ApiService.login(email: email, password: password);
      final personalInfo = await ApiService.getInfo(token: response['data']);
      await LocalStorage.saveAuthData(response['data'], personalInfo);

      setState(() => _isLoggedIn = true);
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка входа: ${e.toString()}')),
      );
    }
  }

  Future<void> _register(Map<String, String> userData) async {
    try {
      final response = await ApiService.register(
        email: userData['email']!,
        password: userData['password']!,
        firstName: userData['firstName']!,
      );
      final personalInfo = await ApiService.getInfo(token: response['data']);
      await LocalStorage.saveAuthData(response['data'], personalInfo);
      setState(() => _isLoggedIn = true);

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Регистрация успешна!'),
        ),
      );
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: ${e.toString()}')),
      );
      rethrow;
    }
  }

  Future<void> _checkAuthStatus() async {
    final authData = await LocalStorage.getAuthData();
    if (authData != null) {
      setState(() => _isLoggedIn = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _logout() {
    LocalStorage.clearAuthData();
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Monochrome Dashboard',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: _isLoggedIn
          ? DashboardPage(onToggleTheme: _toggleTheme, onLogout: _logout)
          : LoginPage(onLogin: _login),
      routes: {
        '/register': (context) => RegisterPage(onRegister: _register),
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const DashboardPage({
    super.key,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;
  late String firstName = 'Гость';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authData = await LocalStorage.getAuthData();
      if (mounted) {
        setState(() {
          firstName = authData?['name'] ?? 'Гость';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          firstName = 'Ошибка загрузки';
        });
      }
    }
  }

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.person, 'label': 'Profile'},
    {'icon': Icons.medical_information_outlined, 'label': 'Medical records'},
    {'icon': Icons.chat_rounded, 'label': 'Chat helper'},
    {'icon': Icons.medication_outlined, 'label': 'Medications'},
  ];

  final List<Widget> pages = const [
    ProfilePage(),
    MedicalRecordsPage(),
    ChatHelperPage(),
    MedicationsRunoutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: kSidebarColor,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              SquareAvatarWithFallback(
                imageUrl: 'https://example.com/avatar.jpg',
                name: firstName,
                size: 70,
              ),
              const SizedBox(height: 30),
              ...List.generate(menuItems.length, (index) {
                final item = menuItems[index];
                final bool isActive = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 12.0),
                  child: Material(
                    color: isActive ? kSidebarActiveColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: Icon(item['icon'],
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? kSidebarIconColor
                                  : kDarkSidebarIconColor),
                      title: Text(
                        item['label'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: () {
                        setState(() => selectedIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              }),
              const Spacer(),
              ListTile(
                leading: Icon(Icons.logout,
                    color: Theme.of(context).brightness == Brightness.light
                        ? kSidebarIconColor
                        : kDarkSidebarIconColor),
                title: Text(
                  'Выйти',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: widget.onLogout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: kSidebarColor,
        elevation: 0,
        title: Text(menuItems[selectedIndex]['label'],
            style: Theme.of(context).textTheme.bodyMedium),
        iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.light
                ? kBackgroundColor
                : kDarkBackgroundColor),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Theme.of(context).brightness == Brightness.light
                  ? kBackgroundColor
                  : kDarkBackgroundColor,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Change Theme',
          ),
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
