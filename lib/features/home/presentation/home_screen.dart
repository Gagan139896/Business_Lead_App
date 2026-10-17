import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _orgConfig;
  String _orgName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final member = await Supabase.instance.client
        .from('memberships')
        .select('organization_id, organizations(name)')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (member != null) {
      final orgId = member['organization_id'];
      _orgName = member['organizations']['name'] ?? '';

      final configRow = await Supabase.instance.client
          .from('org_config')
          .select('config')
          .eq('organization_id', orgId)
          .maybeSingle();

      if (configRow != null) {
        _orgConfig = configRow['config'];
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final leadLabel = _orgConfig?['labels']?['lead'] ?? 'Lead';
    final leadPlural = _orgConfig?['labels']?['leads'] ?? 'Leads';

    return Scaffold(
      appBar: AppBar(
        title: Text(_orgName.isEmpty ? 'Dashboard' : _orgName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _orgConfig?['display_name'] ?? 'Business',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Format: $leadLabel management active'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Button 1: View Leads
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.list_alt),
              label: Text('View $leadPlural List', style: const TextStyle(fontSize: 16)),
              onPressed: () => context.push('/leads'),
            ),
            const SizedBox(height: 16),
            // Button 2: Add Lead Manually
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.person_add),
              label: Text('Add New $leadLabel', style: const TextStyle(fontSize: 16)),
              onPressed: () => context.push('/add-lead'),
            ),
            const SizedBox(height: 16),
            // Button 3: Integrations & Simulator (Naya Button Yahan Hai)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF2F80ED)),
                foregroundColor: const Color(0xFF2F80ED),
              ),
              icon: const Icon(Icons.hub_outlined),
              label: const Text('Integrations & Lead Simulator', style: TextStyle(fontSize: 16)),
              onPressed: () => context.push('/integrations'),
            ),
          ],
        ),
      ),
    );
  }
}