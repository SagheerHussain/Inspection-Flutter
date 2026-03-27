class InspectionStatuses {
  InspectionStatuses._();

  static const String running = 'Running';
  static const String reScheduled = 'Re-Scheduled';
  static const String scheduled = 'Scheduled';
  static const String cancel = 'Cancelled';
  static const String inspected = 'Inspected';
  static const String reInspection = 'Re-Inspection';

  static const List<String> all = [
    running,
    reScheduled,
    scheduled,
    cancel,
    inspected,
    reInspection,
  ];
}
