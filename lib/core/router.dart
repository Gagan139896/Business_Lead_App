import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/leads/leads_list_screen.dart';
import '../features/leads/add_lead_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      // 1. Onboarding Screen
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 2. Dashboard Screen (Pass organizationId and config as extra)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DashboardScreen(
            organizationId: extra['organizationId'] ?? '',
            orgConfig: extra['orgConfig'] ?? {},
          );
        },
      ),

      // 3. Leads List Screen
      GoRoute(
        path: '/leads',
        name: 'leads',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return LeadsListScreen(
            organizationId: extra['organizationId'] ?? '',
            orgConfig: extra['orgConfig'] ?? {},
          );
        },
      ),

      // 4. Add Lead Screen
      GoRoute(
        path: '/add-lead',
        name: 'add-lead',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AddLeadScreen(
            organizationId: extra['organizationId'] ?? '',
            orgConfig: extra['orgConfig'] ?? {},
          );
        },
      ),
    ],
  );
}