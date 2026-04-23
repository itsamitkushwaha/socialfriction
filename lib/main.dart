import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/usage_provider.dart';
import 'providers/block_provider.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/auth_checker.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/block/block_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService.initialize();
  runApp(const SocialFrictionApp());
}

class SocialFrictionApp extends StatelessWidget {
  const SocialFrictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsageProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => BlockProvider()..loadData()),
      ],
      child: MaterialApp(
        title: 'Social Friction',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthChecker(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    StatsScreen(),
    BlockScreen(),
    FocusScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.block_rounded),
              label: 'Block',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_rounded),
              label: 'Focus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
