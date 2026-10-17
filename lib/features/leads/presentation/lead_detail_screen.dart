import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lead;
  final List<dynamic> statuses;
  final List<String> lostReasons;

  const LeadDetailScreen({
    super.key,
    required this.lead,
    required this.statuses,
    required this.lostReasons,
  });

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late Map<String, dynamic> _lead;
  List<Map<String, dynamic>> _activities = [];
  bool _loadingActivities = true;

  @override
  void initState() {
    super.initState();
    _lead = Map<String, dynamic>.from(widget.lead);
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final res = await Supabase.instance.client
          .from('lead_activities')
          .select('*')
          .eq('lead_id', _lead['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(res);
          _loadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  Future<void> _logActivity(String type, Map<String, dynamic> data) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('lead_activities').insert({
      'lead_id': _lead['id'],
      'organization_id': _lead['organization_id'],
      'user_id': user.id,
      'type': type,
      'data': data,
    });

    _fetchActivities();
  }

  // Action 1: Direct Phone Call
  Future<void> _makePhoneCall() async {
    final phone = _lead['phone']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await _logActivity('call_initiated', {'phone': phone, 'timestamp': DateTime.now().toIso8601String()});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone dialer open nahi ho saka')));
      }
    }
  }

  // Action 2: WhatsApp Message
  Future<void> _openWhatsApp() async {
    var phone = _lead['phone']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (phone.isEmpty) return;
    if (phone.length == 10) phone = '91$phone';

    final leadName = _lead['name'] ?? 'Sir/Ma\'am';
    final message = Uri.encodeComponent('Namaste $leadName ji! Humne aapka inquiry receive kiya hai. Kaise madad kar sakte hain?');
    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _logActivity('whatsapp_opened', {'phone': phone, 'timestamp': DateTime.now().toIso8601String()});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp launch nahi ho saka')));
      }
    }
  }

  // Action 3: Add Note Dialog
  void _promptAddNote() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Internal Note'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Customer se kya baat hui? (e.g. Price high bol rahe hain, kal call karein)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = noteController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                await _logActivity('note_added', {'note': text});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note add ho gaya!')));
                }
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  // Action 4: Schedule Follow-up
  Future<void> _scheduleFollowUp() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 11, minute: 0),
      );

      if (pickedTime != null) {
        final followUpDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await Supabase.instance.client.from('leads').update({
          'next_followup_at': followUpDateTime.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _lead['id']);

        setState(() {
          _lead['next_followup_at'] = followUpDateTime.toIso8601String();
        });

        await _logActivity('followup_scheduled', {
          'scheduled_for': followUpDateTime.toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Follow-up scheduled for: ${DateFormat('dd MMM, hh:mm a').format(followUpDateTime)}')),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(String newStatusKey, {num? dealValue, String? lostReason}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final updates = <String, dynamic>{
        'status_key': newStatusKey,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (dealValue != null) updates['deal_value'] = dealValue;
      if (lostReason != null) updates['lost_reason'] = lostReason;

      await Supabase.instance.client.from('leads').update(updates).eq('id', _lead['id']);

      await _logActivity('status_changed', {
        'from': _lead['status_key'],
        'to': newStatusKey,
        if (dealValue != null) 'deal_value': dealValue,
        if (lostReason != null) 'lost_reason': lostReason,
      });

      setState(() {
        _lead['status_key'] = newStatusKey;
        if (dealValue != null) _lead['deal_value'] = dealValue;
        if (lostReason != null) _lead['lost_reason'] = lostReason;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status update ho gaya!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update fail: $e')));
      }
    }
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Stage / Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...widget.statuses.map((s) {
                final key = s['key'] as String;
                final label = s['label'] as String;
                final kind = s['kind'] as String? ?? 'open';
                final isCurrent = _lead['status_key'] == key;

                return ListTile(
                  title: Text(label, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                  trailing: isCurrent ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (kind == 'won') {
                      _promptDealValue(key);
                    } else if (kind == 'lost') {
                      _promptLostReason(key);
                    } else {
                      _updateStatus(key);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _promptDealValue(String statusKey) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deal Closed (Won)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Deal Value (₹) *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = num.tryParse(controller.text.trim());
              if (val != null) {
                Navigator.pop(ctx);
                _updateStatus(statusKey, dealValue: val);
              }
            },
            child: const Text('Confirm Won'),
          ),
        ],
      ),
    );
  }

  void _promptLostReason(String statusKey) {
    String? selected = widget.lostReasons.isNotEmpty ? widget.lostReasons.first : 'Not interested';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark as Lost'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Lost Reason *', border: OutlineInputBorder()),
            items: widget.lostReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setDialogState(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selected != null) {
                  Navigator.pop(ctx);
                  _updateStatus(statusKey, lostReason: selected);
                }
              },
              child: const Text('Confirm Lost'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customFields = (_lead['custom_fields'] as Map<String, dynamic>?) ?? {};
    final nextFollowUp = _lead['next_followup_at'] != null
        ? DateTime.tryParse(_lead['next_followup_at'].toString())
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lead['name'] ?? 'Lead Detail'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Stage'),
            onPressed: _showStatusBottomSheet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_lead['name'] ?? 'Unnamed', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Phone: ${_lead['phone'] ?? 'N/A'}'),
                  Text('Source: ${_lead['source'] ?? 'Manual'}'),
                  Text('Current Status: ${_lead['status_key']}'),
                  if (_lead['deal_value'] != null) Text('Deal Value: ₹${_lead['deal_value']}'),
                  if (_lead['lost_reason'] != null) Text('Lost Reason: ${_lead['lost_reason']}'),
                  if (nextFollowUp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'Next Follow-up: ${DateFormat('dd MMM yyyy, hh:mm a').format(nextFollowUp)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // QUICK ACTIONS BAR
          Card(
            color: Colors.blue.shade50,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActionButton(
                    icon: Icons.phone,
                    label: 'Call',
                    color: Colors.green.shade700,
                    onTap: _makePhoneCall,
                  ),
                  _ActionButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: _openWhatsApp,
                  ),
                  _ActionButton(
                    icon: Icons.note_add_outlined,
                    label: 'Add Note',
                    color: Colors.blue.shade700,
                    onTap: _promptAddNote,
                  ),
                  _ActionButton(
                    icon: Icons.alarm_add,
                    label: 'Follow-up',
                    color: Colors.deepOrange,
                    onTap: _scheduleFollowUp,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Custom Business Details
          if (customFields.isNotEmpty) ...[
            const Text('Custom Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: customFields.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(e.value.toString()),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // History and Activities
          const Text('Timeline & History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_loadingActivities)
            const Center(child: CircularProgressIndicator())
          else if (_activities.isEmpty)
            const Text('Koi activity record nahi mila.')
          else
            ..._activities.map((a) {
              final type = a['type'] as String;
              final data = a['data'] as Map<String, dynamic>? ?? {};
              final time = a['created_at'] != null
                  ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(a['created_at']))
                  : '';

              IconData icon = Icons.history;
              Color iconColor = Colors.blue;
              String title = 'Activity';
              String detail = '';

              switch (type) {
                case 'created':
                  icon = Icons.fiber_new;
                  iconColor = Colors.green;
                  title = 'Lead Created';
                  detail = 'Source: ${data['source'] ?? 'Unknown'}';
                  break;
                case 'status_changed':
                  icon = Icons.sync_alt;
                  iconColor = Colors.indigo;
                  title = 'Stage Changed to "${data['to']}"';
                  if (data['deal_value'] != null) detail = 'Deal Value: ₹${data['deal_value']}';
                  if (data['lost_reason'] != null) detail = 'Reason: ${data['lost_reason']}';
                  break;
                case 'call_initiated':
                  icon = Icons.call_made;
                  iconColor = Colors.teal;
                  title = 'Phone Call Initiated';
                  detail = 'Dialed: ${data['phone']}';
                  break;
                case 'whatsapp_opened':
                  icon = Icons.chat_bubble_outline;
                  iconColor = const Color(0xFF25D366);
                  title = 'WhatsApp Chat Opened';
                  detail = 'Sent to: ${data['phone']}';
                  break;
                case 'note_added':
                  icon = Icons.sticky_note_2_outlined;
                  iconColor = Colors.amber.shade800;
                  title = 'Note Added';
                  detail = data['note'] ?? '';
                  break;
                case 'followup_scheduled':
                  icon = Icons.alarm;
                  iconColor = Colors.deepOrange;
                  title = 'Follow-up Scheduled';
                  detail = data['scheduled_for'] != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(data['scheduled_for']))
                      : '';
                  break;
                default:
                  title = type;
                  detail = data.toString();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0.5,
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.12),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: detail.isNotEmpty ? Text(detail) : null,
                  trailing: Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}