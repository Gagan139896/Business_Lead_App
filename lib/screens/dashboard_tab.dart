import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  final String clientName;
  final String businessType;
  final List<dynamic> leadsList;
  final bool isLoading;
  final VoidCallback onRefresh;

  const DashboardTab({
    super.key,
    required this.clientName,
    required this.businessType,
    required this.leadsList,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7b2cbf)));
    }

    int totalLeads = leadsList.length;
    int wonLeads = leadsList.where((l) => 
      (l['status_key'] ?? '') == 'won' || (l['status_key'] ?? '') == 'started'
    ).length;

    double conversionRate = totalLeads > 0 ? (wonLeads / totalLeads) * 100 : 0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome back, $clientName!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Business Type: ${businessType.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _kpiCard('Total Leads', '$totalLeads', Icons.people, Colors.purple),
              _kpiCard('Deals Won / Done', '$wonLeads', Icons.emoji_events, Colors.green),
              _kpiCard('Conversion Rate', '${conversionRate.toStringAsFixed(1)}%', Icons.trending_up, Colors.orange),
              _kpiCard('Active Pipeline', '$totalLeads', Icons.hourglass_top, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String val, IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: col, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: col, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: col)),
        ],
      ),
    );
  }
}