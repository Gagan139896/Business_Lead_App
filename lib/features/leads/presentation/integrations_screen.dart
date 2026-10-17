import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  String? _webhookKey;
  bool _loading = true;
  bool _isSimulating = false;

  final _testNameController = TextEditingController(text: 'Vikram Mehta');
  final _testPhoneController = TextEditingController(text: '9876543210');
  String _selectedPlatform = 'Meta Ads';

  @override
  void initState() {
    super.initState();
    _fetchOrgWebhookKey();
  }

  Future<void> _fetchOrgWebhookKey() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final member = await Supabase.instance.client
          .from('memberships')
          .select('organization_id, organizations(webhook_api_key)')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      if (member != null && mounted) {
        setState(() {
          _webhookKey = member['organizations']['webhook_api_key'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading webhook key: $e')),
        );
      }
    }
  }

  Future<void> _triggerSimulatedLead() async {
    if (_webhookKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Webhook Key nahi mili. Kripya reload karein.')),
      );
      return;
    }

    if (_testPhoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam 10-digit phone number enter karein')),
      );
      return;
    }

    setState(() => _isSimulating = true);

    try {
      final res = await Supabase.instance.client.rpc('ingest_external_lead', params: {
        'p_webhook_key': _webhookKey,
        'p_name': _testNameController.text.trim(),
        'p_phone': _testPhoneController.text.trim(),
        'p_source': _selectedPlatform,
        'p_custom_fields': {
          'campaign': 'Summer 2026 Campaign',
          'platform': _selectedPlatform,
          'simulated_at': DateTime.now().toIso8601String(),
        },
      });

      if (mounted) {
        final action = res['action'] == 'updated' ? 'Existing Lead Updated' : 'New Lead Created';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('Success: $action! ($_selectedPlatform)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Simulation Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final webhookUrl =
        'https://bpycutoucttomyjpeioa.supabase.co/functions/v1/lead-ingest?token=${_webhookKey ?? ""}';

    return Scaffold(
      appBar: AppBar(title: const Text('Integrations & Ingestion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Universal Webhook URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Is URL ko Google Ads, Meta Lead Gen, WhatsApp API ya landing page builders me paste karein:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      webhookUrl,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Webhook URL'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: webhookUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Webhook URL clipboard me copy ho gaya!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'In-App Lead Simulator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ads live kiye bina test karein ki alag-alag platform se leads kaise aati hain:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPlatform,
            decoration: const InputDecoration(labelText: 'Source Platform', border: OutlineInputBorder()),
            items: ['Meta Ads', 'Google Ads', 'Instagram Reel', 'WhatsApp Inbound', 'Website Form']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPlatform = v!),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _testNameController,
            decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _testPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixText: '+91 ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                foregroundColor: Colors.white,
              ),
              onPressed: _isSimulating ? null : _triggerSimulatedLead,
              child: _isSimulating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Simulate Inbound $_selectedPlatform Lead'),
            ),
          ),
        ],
      ),
    );
  }
}