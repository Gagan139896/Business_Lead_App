import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lead_detail_screen.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  String? _orgId;
  String _leadPluralLabel = 'Leads';
  List<dynamic> _statuses = [];
  List<String> _lostReasons = ['Price too high', 'Location mismatch', 'Not interested'];
  String _selectedStatusFilter = 'all';
  List<Map<String, dynamic>> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrgAndLeads();
  }

  Future<void> _loadOrgAndLeads() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final member = await Supabase.instance.client
          .from('memberships')
          .select('organization_id')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (member != null) {
        _orgId = member['organization_id'];

        final configRow = await Supabase.instance.client
            .from('org_config')
            .select('config')
            .eq('organization_id', _orgId!)
            .maybeSingle();

        if (configRow != null) {
          final config = configRow['config'] as Map<String, dynamic>;
          _leadPluralLabel = config['labels']?['leads'] ?? 'Leads';
          _statuses = config['statuses'] as List? ?? [];
          final configLost = (config['lost_reasons'] as List?)?.cast<String>();
          if (configLost != null && configLost.isNotEmpty) {
            _lostReasons = configLost;
          }
        }

        await _fetchLeads();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLeads() async {
    if (_orgId == null) return;

    // Filter builder: order() ko filtering ke baad lagayein
    var query = Supabase.instance.client
        .from('leads')
        .select('*')
        .eq('organization_id', _orgId!)
        .isFilter('deleted_at', null);

    if (_selectedStatusFilter != 'all') {
      query = query.eq('status_key', _selectedStatusFilter);
    }

    final data = await query.order('created_at', ascending: false);
    setState(() {
      _leads = List<Map<String, dynamic>>.from(data);
    });
  }

  Color _getStatusColor(String statusKey) {
    final statusObj = _statuses.firstWhere(
      (s) => s['key'] == statusKey,
      orElse: () => null,
    );
    if (statusObj != null && statusObj['color'] != null) {
      final hex = (statusObj['color'] as String).replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    }
    return Colors.grey;
  }

  String _getStatusLabel(String statusKey) {
    final statusObj = _statuses.firstWhere(
      (s) => s['key'] == statusKey,
      orElse: () => null,
    );
    return statusObj != null ? statusObj['label'] : statusKey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_leadPluralLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _fetchLeads();
              setState(() => _isLoading = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedStatusFilter == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatusFilter = 'all');
                      _fetchLeads();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ..._statuses.map((s) {
                  final key = s['key'] as String;
                  final label = s['label'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _selectedStatusFilter == key,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatusFilter = selected ? key : 'all';
                        });
                        _fetchLeads();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _leads.isEmpty
                ? Center(
                    child: Text('Abhi koi $_leadPluralLabel nahi hain.'),
                  )
                : ListView.builder(
                    itemCount: _leads.length,
                    itemBuilder: (context, index) {
                      final lead = _leads[index];
                      final statusKey = lead['status_key'] ?? 'new';
                      final color = _getStatusColor(statusKey);
                      final custom = (lead['custom_fields'] as Map<String, dynamic>?) ?? {};

                      final extraDetail = custom.values.isNotEmpty
                          ? custom.values.firstWhere(
                              (v) => v != null && v.toString().isNotEmpty,
                              orElse: () => '',
                            )
                          : '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LeadDetailScreen(
                                  lead: lead,
                                  statuses: _statuses,
                                  lostReasons: _lostReasons,
                                ),
                              ),
                            );
                            _fetchLeads();
                          },
                          title: Text(
                            lead['name'] ?? 'Unnamed',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone: ${lead['phone'] ?? 'N/A'} | Source: ${lead['source'] ?? 'Manual'}'),
                              if (extraDetail.toString().isNotEmpty)
                                Text('Detail: $extraDetail', style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              _getStatusLabel(statusKey),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            backgroundColor: color.withOpacity(0.12),
                            side: BorderSide(color: color.withOpacity(0.4)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Lead'),
        onPressed: () async {
          final res = await context.push('/add-lead');
          if (res == true) {
            _fetchLeads();
          }
        },
      ),
    );
  }
}