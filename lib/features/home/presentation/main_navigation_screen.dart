import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../leads/presentation/analytics_dashboard_screen.dart';
import '../../leads/presentation/leads_list_screen.dart';
import '../../leads/presentation/integrations_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Bottom Tabs ki Screens
  final List<Widget> _screens = const [
    AnalyticsDashboardScreen(),
    LeadsListScreen(),
    IntegrationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack se screens ka state refresh nahi hota switch karte waqt
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Center Quick Add Lead Floating Button
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: const Color(0xFF8E2DE2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
        onPressed: () => context.push('/add-lead'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Material 3 Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFF8E2DE2).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF8E2DE2)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted, color: Color(0xFF8E2DE2)),
            label: 'Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub, color: Color(0xFF8E2DE2)),
            label: 'Integrations',
          ),
        ],
      ),
    );
  }
}