import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth & Onboarding Screens
import 'package:business_lead_app/features/auth/presentation/login_screen.dart';
import 'package:business_lead_app/features/auth/presentation/otp_screen.dart';
import 'package:business_lead_app/features/onboarding/presentation/register_business_screen.dart';
import 'package:business_lead_app/features/onboarding/presentation/template_preview_screen.dart';

// Home & Leads Screens
import 'package:business_lead_app/features/home/presentation/main_navigation_screen.dart';
import 'package:business_lead_app/features/leads/presentation/add_lead_screen.dart';
import 'package:business_lead_app/features/leads/presentation/leads_list_screen.dart';
import 'package:business_lead_app/features/leads/presentation/lead_detail_screen.dart';
import 'package:business_lead_app/features/leads/presentation/integrations_screen.dart';
import 'package:business_lead_app/features/leads/presentation/analytics_dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;

    final isAuthFlow = state.matchedLocation == '/login' ||
        state.matchedLocation == '/verify-otp' ||
        state.matchedLocation == '/register-business' ||
        state.matchedLocation == '/template-preview';

    if (session == null && !isAuthFlow) {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/register-business',
      builder: (context, state) => RegisterBusinessScreen(),
    ),
    // Template Preview route with all 4 required parameters handled safely
    GoRoute(
      path: '/template-preview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};

        final businessName = extra['businessName'] as String? ?? 
                             extra['name'] as String? ?? 
                             '';
        final city = extra['city'] as String? ?? '';
        final businessType = extra['businessType'] as String? ?? 'other';

        final templateConfig = (extra['templateConfig'] is Map<String, dynamic>)
            ? extra['templateConfig'] as Map<String, dynamic>
            : <String, dynamic>{
                'display_name': businessType,
                'statuses': <dynamic>[],
                'fields': <dynamic>[],
              };

        return TemplatePreviewScreen(
          businessName: businessName,
          city: city,
          businessType: businessType,
          templateConfig: templateConfig,
        );
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/leads',
      builder: (context, state) => const LeadsListScreen(),
    ),
    GoRoute(
      path: '/add-lead',
      builder: (context, state) => const AddLeadScreen(),
    ),
    GoRoute(
      path: '/integrations',
      builder: (context, state) => const IntegrationsScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsDashboardScreen(),
    ),
    GoRoute(
      path: '/lead-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return LeadDetailScreen(
          lead: extra['lead'],
          statuses: extra['statuses'],
          lostReasons: List<String>.from(extra['lostReasons']),
        );
      },
    ),
  ],
);