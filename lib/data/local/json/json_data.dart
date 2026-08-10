class JsonData {
  final String key;
  final String value;

  const JsonData({required this.key, required this.value});

  factory JsonData.fromJson(Map<String, dynamic> json) {
    return JsonData(key: json['key'] as String, value: json['value'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value};
  }
}
