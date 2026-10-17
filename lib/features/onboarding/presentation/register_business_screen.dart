import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedBusinessType = 'real_estate';

  // Default Template Configurations for instant preview
  final Map<String, Map<String, dynamic>> _templates = {
    'real_estate': {
      'display_name': 'Real Estate',
      'statuses': [
        {'key': 'new', 'label': 'New', 'color': '#2F80ED'},
        {'key': 'contacted', 'label': 'Contacted', 'color': '#F2994A'},
        {'key': 'site_visit', 'label': 'Site Visit', 'color': '#9B51E0'},
        {'key': 'won', 'label': 'Won', 'color': '#27AE60'},
        {'key': 'lost', 'label': 'Lost', 'color': '#EB5757'},
      ],
      'fields': [
        {'key': 'budget', 'label': 'Budget', 'type': 'currency', 'required': true},
        {'key': 'property_type', 'label': 'Property Type', 'type': 'select', 'required': true},
        {'key': 'bhk', 'label': 'BHK Requirement', 'type': 'text', 'required': false},
        {'key': 'location', 'label': 'Preferred Location', 'type': 'text', 'required': false},
      ],
    },
    'clinic': {
      'display_name': 'Clinic',
      'statuses': [
        {'key': 'new', 'label': 'New Enquiry', 'color': '#2F80ED'},
        {'key': 'called', 'label': 'Called', 'color': '#F2994A'},
        {'key': 'booked', 'label': 'Appointment Booked', 'color': '#E0359B'},
        {'key': 'started', 'label': 'Treatment Started', 'color': '#27AE60'},
        {'key': 'lost', 'label': 'Lost', 'color': '#EB5757'},
      ],
      'fields': [
        {'key': 'concern', 'label': 'Health Concern', 'type': 'text', 'required': true},
        {'key': 'age', 'label': 'Patient Age', 'type': 'number', 'required': false},
        {'key': 'preferred_time', 'label': 'Preferred Date & Time', 'type': 'datetime', 'required': false},
      ],
    },
    'salon': {
      'display_name': 'Salon & Beauty Parlour',
      'statuses': [
        {'key': 'new', 'label': 'New Enquiry', 'color': '#2F80ED'},
        {'key': 'contacted', 'label': 'Contacted', 'color': '#F2994A'},
        {'key': 'booked', 'label': 'Slot Booked', 'color': '#E0359B'},
        {'key': 'visited', 'label': 'Visited', 'color': '#27AE60'},
        {'key': 'lost', 'label': 'Lost', 'color': '#EB5757'},
      ],
      'fields': [
        {'key': 'service', 'label': 'Service Requested', 'type': 'text', 'required': true},
        {'key': 'preferred_stylist', 'label': 'Preferred Stylist', 'type': 'text', 'required': false},
      ],
    },
    'coaching': {
      'display_name': 'Coaching Institute',
      'statuses': [
        {'key': 'new', 'label': 'New Enquiry', 'color': '#2F80ED'},
        {'key': 'counselled', 'label': 'Counselled', 'color': '#F2994A'},
        {'key': 'demo', 'label': 'Demo Class', 'color': '#9B51E0'},
        {'key': 'admitted', 'label': 'Admitted', 'color': '#27AE60'},
        {'key': 'lost', 'label': 'Lost', 'color': '#EB5757'},
      ],
      'fields': [
        {'key': 'course', 'label': 'Course / Exam', 'type': 'text', 'required': true},
        {'key': 'class', 'label': 'Current Class', 'type': 'text', 'required': false},
      ],
    },
    'gym': {
      'display_name': 'Gym & Fitness',
      'statuses': [
        {'key': 'new', 'label': 'New Enquiry', 'color': '#2F80ED'},
        {'key': 'trial', 'label': 'Trial Booked', 'color': '#9B51E0'},
        {'key': 'joined', 'label': 'Joined', 'color': '#27AE60'},
        {'key': 'lost', 'label': 'Lost', 'color': '#EB5757'},
      ],
      'fields': [
        {'key': 'fitness_goal', 'label': 'Fitness Goal', 'type': 'text', 'required': true},
        {'key': 'plan_interest', 'label': 'Plan Duration', 'type': 'text', 'required': false},
      ],
    },
    'other': {
      'display_name': 'General Business',
      'statuses': [
        {'key': 'new', 'label': 'New', 'color': '#2F80ED'},
        {'key': 'contacted', 'label': 'Contacted', 'color': '#F2994A'},
        {'key': 'interested', 'label': 'Interested', 'color': '#9B51E0'},
        {'key': 'won', 'label': 'Deal Won', 'color': '#27AE60'},
        {'key': 'lost', 'label': 'Lost', 'color': '#EB5757'},
      ],
      'fields': [
        {'key': 'requirement', 'label': 'Requirement Details', 'type': 'text', 'required': true},
      ],
    },
  };

  @override
  void dispose() {
    _businessNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onProceedToPreview() {
    if (!_formKey.currentState!.validate()) return;

    final config = _templates[_selectedBusinessType] ?? _templates['other']!;

    context.push(
      '/template-preview',
      extra: {
        'businessName': _businessNameController.text.trim(),
        'city': _cityController.text.trim(),
        'businessType': _selectedBusinessType,
        'templateConfig': config,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Register Business'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Setup Your Business',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apne business ki category chuniye taaki app uske hisaab se pipeline aur custom fields set kar sake.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name *',
                    hintText: 'e.g. Apex Estates / City Dental',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Business name enter karein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    labelText: 'Business Category *',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'real_estate', child: Text('Real Estate')),
                    DropdownMenuItem(value: 'clinic', child: Text('Clinic & Healthcare')),
                    DropdownMenuItem(value: 'salon', child: Text('Salon & Beauty Parlour')),
                    DropdownMenuItem(value: 'coaching', child: Text('Coaching Institute')),
                    DropdownMenuItem(value: 'gym', child: Text('Gym & Fitness')),
                    DropdownMenuItem(value: 'other', child: Text('Other Business')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedBusinessType = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City / Location (Optional)',
                    hintText: 'e.g. Chandigarh, Mohali',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onProceedToPreview,
                    child: const Text(
                      'Preview Template & Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}