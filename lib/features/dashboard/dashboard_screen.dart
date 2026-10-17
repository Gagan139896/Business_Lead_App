import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../leads/leads_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String organizationId;
  final Map<String, dynamic> orgConfig;

  const DashboardScreen({
    super.key,
    required this.organizationId,
    required this.orgConfig,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;
  int _totalLeads = 0;
  int _todayFollowups = 0;
  Map<String, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
  }

  // Supabase se real-time/aggregated metrics fetch karna
  Future<void> _fetchDashboardMetrics() async {
    setState(() => _isLoading = true);
    try {
      // 1. Total Leads count
      final totalResponse = await SupabaseConfig.client
          .from('leads')
          .select('id, status_key, next_followup_at')
          .eq('organization_id', widget.organizationId)
          .filter('deleted_at', 'is', null);

      final leads = List<Map<String, dynamic>>.from(totalResponse);
      
      int total = leads.length;
      Map<String, int> counts = {};
      int followupsToday = 0;

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      for (var lead in leads) {
        // Status count calculation
        String status = lead['status_key'] ?? 'new';
        counts[status] = (counts[status] ?? 0) + 1;

        // Today's follow-ups calculation
        String? followup = lead['next_followup_at'];
        if (followup != null && followup.startsWith(todayStr)) {
          followupsToday++;
        }
      }

      setState(() {
        _totalLeads = total;
        _todayFollowups = followupsToday;
        _statusCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.orgConfig['labels'] ?? {};
    final leadsNameLabel = labels['leads'] ?? 'Leads';
    final List statuses = widget.orgConfig['statuses'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.orgConfig['displayName'] ?? 'Business'} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardMetrics,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Summary Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total $leadsNameLabel',
                          value: '$_totalLeads',
                          icon: Icons.group,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Today Follow-ups',
                          value: '$_todayFollowups',
                          icon: Icons.alarm,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Status-wise Breakdown Section
                  const Text(
                    'Pipeline Status Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...statuses.map((status) {
                    final key = status['key'];
                    final label = status['label'];
                    final count = _statusCounts[key] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            '$count',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Leads list screen par navigate karna with status filter
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeadsListScreen(
                                organizationId: widget.organizationId,
                                orgConfig: widget.orgConfig,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 30),

                  // 3. Quick Action Button to open Full Leads View
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeadsListScreen(
                            organizationId: widget.organizationId,
                            orgConfig: widget.orgConfig,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: Text(
                      'Manage All $leadsNameLabel',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}