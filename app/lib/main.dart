import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/catcher_screen.dart';
import 'screens/court_screen.dart';
import 'screens/waiting_screen.dart';
import 'providers/app_providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TaskLobApp(),
    ),
  );
}

class TaskLobApp extends StatelessWidget {
  const TaskLobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Lob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Mobile-first: larger touch targets
        visualDensity: VisualDensity.standard,
        // Accessible fonts
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
      ),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

/// Main app shell with bottom navigation
/// Provides the core navigation structure for Task Lob
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  // The three main screens
  final List<Widget> _screens = const [
    CatcherScreen(),
    CourtScreen(),
    WaitingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Get task counts for badges
    final myCourtCount = ref.watch(myCourtTasksProvider).length;
    final waitingCount = ref.watch(waitingTasksProvider).length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          // Catcher - The main action
          const NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Catch',
          ),

          // My Court - Tasks waiting on ME
          NavigationDestination(
            icon: Badge(
              isLabelVisible: myCourtCount > 0,
              label: Text('$myCourtCount'),
              child: const Icon(Icons.sports_tennis_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: myCourtCount > 0,
              label: Text('$myCourtCount'),
              child: const Icon(Icons.sports_tennis),
            ),
            label: 'My Court',
          ),

          // Waiting - Tasks waiting on OTHERS
          NavigationDestination(
            icon: Badge(
              isLabelVisible: waitingCount > 0,
              label: Text('$waitingCount'),
              child: const Icon(Icons.hourglass_empty_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: waitingCount > 0,
              label: Text('$waitingCount'),
              child: const Icon(Icons.hourglass_top),
            ),
            label: 'Waiting',
          ),
        ],
      ),
    );
  }
}
