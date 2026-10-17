import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../models/template_model.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _businessTypeController = TextEditingController();

  String? _selectedBusinessType;
  List<BusinessTemplate> _templates = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTemplatesSafely();
  }

  // 100% Safe Template Loader with Guaranteed Fallbacks
  Future<void> _loadTemplatesSafely() async {
    final defaultTemplates = [
      BusinessTemplate(type: 'real_estate', displayName: 'Real Estate', version: 1, config: {}),
      BusinessTemplate(type: 'salon', displayName: 'Salon & Spa', version: 1, config: {}),
      BusinessTemplate(type: 'clinic', displayName: 'Clinic & Healthcare', version: 1, config: {}),
      BusinessTemplate(type: 'retail', displayName: 'Retail Store', version: 1, config: {}),
    ];

    try {
      final response = await SupabaseConfig.client
          .from('business_templates')
          .select()
          .eq('status', 'published');

      if (response != null && (response as List).isNotEmpty) {
        final fetched = (response as List)
            .map((e) => BusinessTemplate.fromJson(e))
            .toList();
        
        setState(() {
          _templates = fetched.isNotEmpty ? fetched : defaultTemplates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _templates = defaultTemplates;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Supabase fetch error, using fallbacks: $e');
      setState(() {
        _templates = defaultTemplates;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  // Guaranteed BottomSheet Picker
  void _showBusinessTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Business Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Divider(),
              ..._templates.map((template) {
                return ListTile(
                  leading: const Icon(Icons.store, color: Colors.blue),
                  title: Text(template.displayName, style: const TextStyle(fontSize: 16)),
                  onTap: () {
                    setState(() {
                      _selectedBusinessType = template.type;
                      _businessTypeController.text = template.displayName;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Register Business & Save to Supabase
  Future<void> _registerBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBusinessType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business type')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await SupabaseConfig.client.from('organizations').insert({
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'business_type': _selectedBusinessType,
      }).select().single();

      final orgId = response['id'];

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business Registered Successfully! 🚀')),
      );

      // Redirect to Dashboard via GoRouter with valid orgId
      context.go('/dashboard', extra: {'orgId': orgId});;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Business'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Apna business setup karein aur 1 click mein custom CRM paayein!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    
                    // Business Name Input
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Please enter business name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // City Input
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Business Type Selector Field
                    TextFormField(
                      controller: _businessTypeController,
                      readOnly: true,
                      onTap: _showBusinessTypePicker,
                      decoration: const InputDecoration(
                        labelText: 'Business Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a business type'
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSaving ? null : _registerBusiness,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Continue to Dashboard',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}