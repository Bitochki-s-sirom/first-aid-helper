import 'package:flutter/material.dart';
import 'colors/colors.dart';
import 'colors/themes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monochrome Dashboard',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: DashboardPage(onToggleTheme: _toggleTheme),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DashboardPage({super.key, required this.onToggleTheme});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.person, 'label': 'Profile'},
    {'icon': Icons.medical_information_outlined, 'label': 'Medical records'},
    {'icon': Icons.chat_rounded, 'label': 'Chat helper'},
    {'icon': Icons.calendar_month, 'label': 'Medications runout'},
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
              CircleAvatar(
                radius: 28,
                backgroundColor: kSidebarActiveColor,
                child: Center(
                    child: Text('C',
                        style: Theme.of(context).textTheme.bodyMedium)),
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
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Выбран пункт: ${menuItems[selectedIndex]['label']}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
