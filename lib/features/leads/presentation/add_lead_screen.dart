import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'form_renderer.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _orgId;
  String _leadLabel = 'Lead';
  List<dynamic> _customFields = [];
  List<String> _sources = ['Manual', 'Website', 'WhatsApp', 'Referral'];
  String _selectedSource = 'Manual';

  Map<String, dynamic> _customFieldsData = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOrgConfig();
  }

  Future<void> _loadOrgConfig() async {
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
          _leadLabel = config['labels']?['lead'] ?? 'Lead';
          _customFields = config['fields'] as List? ?? [];
          final configSources = (config['sources'] as List?)?.cast<String>();
          if (configSources != null && configSources.isNotEmpty) {
            _sources = configSources;
            _selectedSource = _sources.first;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Config load error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) return;
    if (_orgId == null) return;

    setState(() => _isSaving = true);

    try {
      final res = await Supabase.instance.client.rpc(
        'create_lead_with_activity',
        params: {
          'p_org_id': _orgId,
          'p_name': _nameController.text.trim(),
          'p_phone': _phoneController.text.trim(),
          'p_source': _selectedSource,
          'p_status_key': 'new',
          'p_custom_fields': _customFieldsData,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_leadLabel add ho gayi successfully!')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving lead: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('New $_leadLabel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Basic Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '$_leadLabel Name *',
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name bharna zaroori hai' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Valid 10-digit phone number enter karein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSource,
              decoration: const InputDecoration(
                labelText: 'Lead Source',
                border: OutlineInputBorder(),
              ),
              items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSource = val);
              },
            ),
            const SizedBox(height: 24),
            if (_customFields.isNotEmpty) ...[
              const Text(
                'Business Specific Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DynamicFormRenderer(
                fields: _customFields,
                onChanged: (values) {
                  _customFieldsData = values;
                },
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _saveLead,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save $_leadLabel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}