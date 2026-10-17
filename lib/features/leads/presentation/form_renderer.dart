import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicFormRenderer extends StatefulWidget {
  final List<dynamic> fields;
  final Map<String, dynamic> initialValues;
  final void Function(Map<String, dynamic> values) onChanged;

  const DynamicFormRenderer({
    super.key,
    required this.fields,
    this.initialValues = const {},
    required this.onChanged,
  });

  @override
  State<DynamicFormRenderer> createState() => _DynamicFormRendererState();
}

class _DynamicFormRendererState extends State<DynamicFormRenderer> {
  final Map<String, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    _formValues.addAll(widget.initialValues);
  }

  void _updateValue(String key, dynamic value) {
    setState(() {
      _formValues[key] = value;
    });
    widget.onChanged(_formValues);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.fields.map<Widget>((field) {
        final key = field['key'] as String;
        final label = field['label'] as String;
        final type = field['type'] as String? ?? 'text';
        final isRequired = field['required'] == true;
        final options = (field['options'] as List?)?.cast<String>() ?? [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildFieldWidget(key, label, type, isRequired, options),
        );
      }).toList(),
    );
  }

  Widget _buildFieldWidget(
    String key,
    String label,
    String type,
    bool isRequired,
    List<String> options,
  ) {
    switch (type) {
      case 'select':
        return DropdownButtonFormField<String>(
          value: _formValues[key] as String?,
          decoration: InputDecoration(
            labelText: '$label${isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: (val) => _updateValue(key, val),
          validator: (val) {
            if (isRequired && (val == null || val.isEmpty)) {
              return '$label select karna zaroori hai';
            }
            return null;
          },
        );

      case 'checkbox':
        final isChecked = _formValues[key] == true;
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: isChecked,
          onChanged: (val) => _updateValue(key, val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        );

      case 'number':
      case 'currency':
        return TextFormField(
          initialValue: _formValues[key]?.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '$label${isRequired ? ' *' : ''}',
            prefixText: type == 'currency' ? '₹ ' : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(key, val),
          validator: (val) {
            if (isRequired && (val == null || val.trim().isEmpty)) {
              return '$label bharna zaroori hai';
            }
            return null;
          },
        );

      case 'datetime':
      case 'date':
        final currentDate = _formValues[key] != null
            ? DateTime.tryParse(_formValues[key].toString())
            : null;
        return InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (pickedDate != null) {
              if (type == 'datetime' && context.mounted) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  final fullDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  _updateValue(key, fullDateTime.toIso8601String());
                  return;
                }
              }
              _updateValue(key, pickedDate.toIso8601String());
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '$label${isRequired ? ' *' : ''}',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              currentDate != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(currentDate)
                  : 'Date aur time chunein',
            ),
          ),
        );

      case 'text':
      default:
        return TextFormField(
          initialValue: _formValues[key]?.toString(),
          decoration: InputDecoration(
            labelText: '$label${isRequired ? ' *' : ''}',
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) => _updateValue(key, val),
          validator: (val) {
            if (isRequired && (val == null || val.trim().isEmpty)) {
              return '$label enter karein';
            }
            return null;
          },
        );
    }
  }
}