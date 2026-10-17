import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeadsTab extends StatelessWidget {
  final String orgId;
  final String businessType;
  final List<dynamic> leadsList;
  final bool isLoading;
  final VoidCallback onRefresh;

  const LeadsTab({
    super.key,
    required this.orgId,
    required this.businessType,
    required this.leadsList,
    required this.isLoading,
    required this.onRefresh,
  });

  void _showAddLeadDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final customFieldController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Lead'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
            const SizedBox(height: 10),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 10),
            TextField(
              controller: customFieldController, 
              decoration: InputDecoration(labelText: businessType == 'clinic' ? 'Health Concern' : 'Budget / Requirement'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7b2cbf), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;
              
              try {
                final client = Supabase.instance.client;
                await client.from('leads').insert({
                  'organization_id': orgId,
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'phone_normalized': phoneController.text.trim(),
                  'status_key': 'new',
                  'source': 'manual',
                  'custom_fields': {
                    businessType == 'clinic' ? 'concern' : 'requirement': customFieldController.text.trim()
                  }
                });

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                onRefresh();
              } catch (e) {
                debugPrint('Error adding lead: $e');
              }
            },
            child: const Text('Save Lead'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7b2cbf)));
    }

    return Scaffold(
      body: leadsList.isEmpty 
          ? const Center(child: Text('No leads added yet. Click + to add one!'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: leadsList.length,
              itemBuilder: (ctx, idx) {
                final lead = leadsList[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7b2cbf),
                      child: Text((lead['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(lead['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Ph: ${lead['phone'] ?? 'N/A'}\nStatus: ${lead['status_key']?.toUpperCase()}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7b2cbf),
        foregroundColor: Colors.white,
        onPressed: () => _showAddLeadDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}