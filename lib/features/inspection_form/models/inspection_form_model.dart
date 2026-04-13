class InspectionFormModel {
  // Single source of truth for all form data
  final Map<String, dynamic> data;

  InspectionFormModel({required this.data});

  factory InspectionFormModel.fromJson(Map<String, dynamic> json) {
    return InspectionFormModel(data: json);
  }

  Map<String, dynamic> toJson() => data;

  // Key identity fields backed by the underlying data map
  String get id => data['_id']?.toString() ?? '';
  set id(String val) => data['_id'] = val;

  String get appointmentId => data['appointmentId']?.toString() ?? '';
  set appointmentId(String val) => data['appointmentId'] = val;

  String get make => data['make']?.toString() ?? '';
  set make(String val) => data['make'] = val;

  String get model => data['model']?.toString() ?? '';
  set model(String val) => data['model'] = val;

  String get variant => data['variant']?.toString() ?? '';
  set variant(String val) => data['variant'] = val;

  String get status => data['status']?.toString() ?? '';
  set status(String val) => data['status'] = val;

  // Helpers to get/set values safely from the data map
  String getString(String key) => data[key]?.toString() ?? '';
  void setString(String key, String value) => data[key] = value;

  List<String> getList(String key) {
    var list = data[key];
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }
}
