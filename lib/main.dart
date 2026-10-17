import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bpycutoucttomyjpeioa.supabase.co', // Aapka Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJweWN1dG91Y3R0b215anBlaW9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4NjUyMTQsImV4cCI6MjEwNzQ0MTIxNH0.zG28Pe4vsY7pmjj9GK8MvyRnris3FHioROlOalgZXnQ',            // Aapki anon key
  );

  runApp(
    const ProviderScope(
      child: BusinessLeadApp(),
    ),
  );
}

class BusinessLeadApp extends StatelessWidget {
  const BusinessLeadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Business Lead App',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
        useMaterial3: true,
      ),
    );
  }
}