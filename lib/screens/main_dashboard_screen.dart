import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'dashboard_tab.dart';
import 'leads_tab.dart';

class MainDashboardScreen extends StatefulWidget {
  final String orgId;
  const MainDashboardScreen({super.key, required this.orgId});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String _clientName = 'My Business';
  String _businessType = 'real_estate';
  List<dynamic> _leadsList = [];

  @override
  void initState() {
    super.initState();
    _fetchCRMData();
  }

  Future<void> _fetchCRMData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      // 1. Fetch Organization Details
      final org = await client.from('organizations').select('name, business_type').eq('id', widget.orgId).maybeSingle();
      if (org != null) {
        _clientName = org['name'] ?? 'My Business';
        _businessType = org['business_type'] ?? 'real_estate';
      }

      // 2. Fetch Leads for this Organization
      debugPrint('===> Fetching for orgId: "${widget.orgId}"');

      final leads = await client
          .from('leads')
          .select()
          .eq('organization_id', widget.orgId)
          .order('created_at', ascending: false);

      debugPrint('===> Total leads found: ${leads.length}');
      if (leads.isNotEmpty) {
        debugPrint('===> First lead name: ${leads.first['name']} | org: ${leads.first['organization_id']}');
      }

      _leadsList = leads;
    } catch (e) {
      debugPrint('===> ERROR fetching CRM data: $e');
      _leadsList = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardTab(clientName: _clientName, businessType: _businessType, leadsList: _leadsList, isLoading: _isLoading, onRefresh: _fetchCRMData),
      LeadsTab(orgId: widget.orgId, businessType: _businessType, leadsList: _leadsList, isLoading: _isLoading, onRefresh: _fetchCRMData),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7b2cbf),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCRMData, tooltip: 'Refresh'),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context), tooltip: 'Logout'),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF7b2cbf),
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Leads & Pipeline'),
        ],
      ),
    );
  }
}