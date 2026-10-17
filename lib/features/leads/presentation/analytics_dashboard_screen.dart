import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _loading = true;
  String _orgName = 'My Business';
  DateTime _lastUpdated = DateTime.now();

  List<Map<String, dynamic>> _leads = [];
  double _adSpend = 10000; 

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final member = await Supabase.instance.client
          .from('memberships')
          .select('organization_id, organizations(name)')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (member != null) {
        final orgId = member['organization_id'];
        _orgName = member['organizations']?['name'] ?? 'Business';

        // NOTE: created_at aur next_followup_at fetch kar rahe hain
        final res = await Supabase.instance.client
            .from('leads')
            .select('id, status_key, source, deal_value, lost_reason, created_at, next_followup_at')
            .eq('organization_id', orgId)
            .isFilter('deleted_at', null);

        if (mounted) {
          setState(() {
            _leads = List<Map<String, dynamic>>.from(res);
            _lastUpdated = DateTime.now();
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dashboard data load error: $e')),
        );
      }
    }
  }

  void _promptEditAdSpend() {
    final controller = TextEditingController(text: _adSpend.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Total Ad Spend'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Ad Spend (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null) {
                setState(() => _adSpend = val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final today = DateTime.now();

    // --- TODAY'S CALCULATIONS ---
    final leadsToday = _leads.where((l) {
      if (l['created_at'] == null) return false;
      final d = DateTime.parse(l['created_at']).toLocal();
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;

    final followupsToday = _leads.where((l) {
      if (l['next_followup_at'] == null) return false;
      final d = DateTime.parse(l['next_followup_at']).toLocal();
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;

    // --- OVERALL CALCULATIONS ---
    final totalLeads = _leads.length;
    final dealsWon = _leads.where((l) => l['status_key'] == 'won').length;
    final siteVisits = _leads.where((l) {
      final s = l['status_key']?.toString().toLowerCase() ?? '';
      return s == 'site_visit' || s == 'visit' || s == 'site visit';
    }).length;

    final leadToDealPercent = totalLeads > 0 ? (dealsWon / totalLeads * 100) : 0.0;

    final totalRevenue = _leads.where((l) => l['status_key'] == 'won').fold<double>(
      0.0,
      (sum, l) => sum + (double.tryParse(l['deal_value']?.toString() ?? '0') ?? 0.0),
    );

    final costPerLead = totalLeads > 0 ? (_adSpend / totalLeads) : 0.0;
    final roi = _adSpend > 0 ? (((totalRevenue - _adSpend) / _adSpend) * 100) : 0.0;

    // Status & Source & Lost Reasons Breakdowns
    final Map<String, int> statusCounts = {};
    final Map<String, int> sourceCounts = {};
    final Map<String, int> lostReasonsCounts = {};

    for (final l in _leads) {
      final key = (l['status_key'] ?? 'new').toString();
      statusCounts[key] = (statusCounts[key] ?? 0) + 1;
      
      final src = (l['source'] ?? 'Direct / Other').toString();
      sourceCounts[src] = (sourceCounts[src] ?? 0) + 1;

      if (l['status_key'] == 'lost' && l['lost_reason'] != null) {
        final r = l['lost_reason'].toString();
        lostReasonsCounts[r] = (lostReasonsCounts[r] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: CustomScrollView(
        slivers: [
          // 1. TOP GRADIENT HEADER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFFE94057)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$_orgName - Dashboard',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _fetchDashboardData,
                      ),
                      IconButton(
                        tooltip: 'Set Ad Spend',
                        icon: const Icon(Icons.currency_rupee, color: Colors.white),
                        onPressed: _promptEditAdSpend,
                      ),
                    ],
                  ),
                  Text(
                    'Updated: ${DateFormat('HH:mm:ss').format(_lastUpdated)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // 2. TODAY'S HIGHLIGHTS (Barabar size ke liye IntrinsicHeight use kiya hai)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TodayHighlightCard(
                        title: "New Leads (Today)",
                        value: '$leadsToday',
                        icon: Icons.fiber_new,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TodayHighlightCard(
                        title: "Follow-ups Today",
                        value: '$followupsToday',
                        icon: Icons.alarm,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. MAIN METRIC CARDS (8 KPIs)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _KpiCard(icon: Icons.people_alt, iconColor: Colors.deepPurple, title: 'Total Leads', value: '$totalLeads'),
                _KpiCard(icon: Icons.home_work, iconColor: Colors.orange, title: 'Site Visits / Conv', value: '$siteVisits'),
                _KpiCard(icon: Icons.emoji_events, iconColor: Colors.amber.shade700, title: 'Deals Won', value: '$dealsWon'),
                _KpiCard(icon: Icons.gps_fixed, iconColor: Colors.indigo, title: 'Lead to Deal', value: '${leadToDealPercent.toStringAsFixed(1)}%'),
                _KpiCard(icon: Icons.payments, iconColor: Colors.teal, title: 'Ad Spend', value: '₹${NumberFormat('#,##,###').format(_adSpend)}'),
                _KpiCard(icon: Icons.pin_drop, iconColor: Colors.pink, title: 'Cost per Lead', value: '₹${costPerLead.toStringAsFixed(2)}'),
                _KpiCard(icon: Icons.account_balance_wallet, iconColor: Colors.blue.shade700, title: 'Revenue', value: '₹${NumberFormat('#,##,###').format(totalRevenue)}'),
                _KpiCard(icon: Icons.trending_up, iconColor: Colors.green.shade700, title: 'ROI', value: '${roi.toStringAsFixed(0)}%', valueColor: Colors.green.shade700),
              ],
            ),
          ),

          // 4. LEAD FUNNEL & STATUS SPLIT
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _DashboardSectionCard(
                          title: 'Lead Funnel',
                          icon: Icons.filter_alt,
                          child: Column(
                            children: statusCounts.entries.map((e) {
                              final pct = totalLeads > 0 ? (e.value / totalLeads) : 0.0;
                              final color = _getStatusColor(e.key);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(width: 80, child: Text(e.key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(value: pct, minHeight: 14, backgroundColor: Colors.grey.shade200, color: color),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _DashboardSectionCard(
                          title: 'Status Split',
                          icon: Icons.donut_large,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 110,
                                width: 110,
                                child: CustomPaint(
                                  painter: _DonutChartPainter(data: statusCounts, total: totalLeads),
                                  child: Center(child: Text('$totalLeads', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: statusCounts.entries.map((e) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _getStatusColor(e.key), shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. LEAD SOURCES & LOST REASONS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DashboardSectionCard(
                          title: 'Lead Sources',
                          icon: Icons.bar_chart,
                          child: sourceCounts.isEmpty
                              ? const Text('Koi source nahi')
                              : Column(
                                  children: sourceCounts.entries.map((e) {
                                    final pct = totalLeads > 0 ? (e.value / totalLeads) : 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 95, child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: LinearProgressIndicator(value: pct, minHeight: 12, backgroundColor: Colors.purple.shade50, color: const Color(0xFF8E2DE2)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardSectionCard(
                          title: 'Lost Reasons',
                          icon: Icons.cancel_outlined,
                          titleColor: Colors.red.shade700,
                          child: lostReasonsCounts.isEmpty
                              ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No lost deals yet.', style: TextStyle(color: Colors.grey)))
                              : Column(
                                  children: lostReasonsCounts.entries.map((e) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                                            child: Text('${e.value}', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _getStatusColor(String key) {
    switch (key.toLowerCase()) {
      case 'new': return const Color(0xFF2F80ED);
      case 'hot': return Colors.orange;
      case 'site_visit': case 'site visit': case 'visit': return const Color(0xFFE91E63);
      case 'won': return const Color(0xFF27AE60);
      case 'lost': return const Color(0xFFEB5757);
      case 'contacted': return Colors.deepPurple;
      default: return Colors.blueGrey;
    }
  }
}

// UPDATE: Today's Highlights Card barabar size and single line text ke sath
class _TodayHighlightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _TodayHighlightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color? valueColor;

  const _KpiCard({required this.icon, required this.iconColor, required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF222B45))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? titleColor;

  const _DashboardSectionCard({required this.title, required this.icon, required this.child, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: titleColor ?? Colors.black87),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor ?? Colors.black87)),
            ],
          ),
          const Divider(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, int> data;
  final int total;

  _DonutChartPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    if (total == 0) {
      final paint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -math.pi / 2;
    data.forEach((key, count) {
      final sweepAngle = (count / total) * 2 * math.pi;
      final paint = Paint()..color = _AnalyticsDashboardScreenState._getStatusColor(key)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}