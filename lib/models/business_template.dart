import 'dart:convert';

class BusinessTemplate {
  final String type;
  final int version;
  final String displayName;
  final Map<String, dynamic> config;

  BusinessTemplate({
    required this.type,
    required this.version,
    required this.displayName,
    required this.config,
  });

  factory BusinessTemplate.fromJson(Map<String, dynamic> json) {
    return BusinessTemplate(
      type: json['type'] ?? '',
      version: json['version'] ?? 1,
      displayName: json['display_name'] ?? '',
      config: json['config'] is String 
          ? jsonDecode(json['config']) 
          : json['config'] ?? {},
    );
  }
}