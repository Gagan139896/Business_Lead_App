import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TemplatePreviewScreen extends StatefulWidget {
  final String businessName;
  final String city;
  final String businessType;
  final Map<String, dynamic> templateConfig;

  const TemplatePreviewScreen({
    super.key,
    required this.businessName,
    required this.city,
    required this.businessType,
    required this.templateConfig,
  });

  @override
  State<TemplatePreviewScreen> createState() => _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends State<TemplatePreviewScreen> {
  bool _isSaving = false;

  Future<void> _createBusiness() async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.rpc(
        'register_business_with_template',
        params: {
          'p_business_name': widget.businessName,
          'p_business_type': widget.businessType,
          'p_city': widget.city,
        },
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = (widget.templateConfig['statuses'] as List? ?? []);
    final fields = (widget.templateConfig['fields'] as List? ?? []);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.templateConfig['display_name']} Format')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.businessName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (widget.city.isNotEmpty) Text('Location: ${widget.city}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pipeline Statuses:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((s) {
              final colorHex = (s['color'] as String? ?? '#2F80ED').replaceAll('#', '');
              return Chip(
                label: Text(s['label']),
                backgroundColor: Color(int.parse('0xFF$colorHex')).withOpacity(0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Form Fields for Leads:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...fields.map((f) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text(f['label']),
                  subtitle: Text('Type: ${f['type']} | ${f['required'] == true ? "Required" : "Optional"}'),
                ),
              )),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                foregroundColor: Colors.white,
              ),
              onPressed: _isSaving ? null : _createBusiness,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Apply Template & Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}