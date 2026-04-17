import 'package:get_storage/get_storage.dart';

/// API Configuration with Dev/Prod switching
class ApiConstants {
  ApiConstants._();

  static const String _prodBaseUrl =
      'https://ob-dealerapp-kong.onrender.com/api/';

  static final _storage = GetStorage();
  static const String _envKey = 'API_ENVIRONMENT';

  /// Get current environment: always returns 'production' as requested
  static String get environment => 'production';

  /// Check if using production
  static bool get isProduction => true;

  /// Get the active base URL — permanently set to Production
  static String get baseUrl => _prodBaseUrl;

  /// Switch to production (Now redundant but kept for compatibility)
  static Future<void> switchToProduction() async {
    await _storage.write(_envKey, 'production');
  }

  /// Switch to development (Disabled)
  static Future<void> switchToDevelopment() async {
    // await _storage.write(_envKey, 'development');
  }

  /// Toggle environment (Disabled)
  static Future<void> toggleEnvironment() async {
    /* 
    if (isProduction) {
      await switchToDevelopment();
    } else {
      await switchToProduction();
    }
    */
  }

  // ──────────────────────────────────────────
  // AUTH ENDPOINTS
  // ──────────────────────────────────────────
  // static String get loginUrl => 'https://otobixcrm.vercel.app/api/users/login';
  static String get loginUrl =>
      'https://otobixcrm-alpha.vercel.app/api/users/login';

  // ──────────────────────────────────────────
  // SCHEDULE / TELECALLING ENDPOINTS
  // ──────────────────────────────────────────
  static String get inspectionEngineerSchedulesUrl =>
      '${baseUrl}inspection/telecallings/get-list-by-inspection-engineer';

  /// Paginated telecalling endpoint with limit & pageNumber query params.
  /// Pass [search] to add a server-side search query param.
  static String inspectionEngineerSchedulesPaginatedUrl({
    int limit = 20,
    int pageNumber = 1,
    String? search,
  }) {
    final base =
        '${baseUrl}inspection/telecallings/get-list-by-inspection-engineer?limit=$limit&pageNumber=$pageNumber';
    if (search != null && search.isNotEmpty) {
      return '$base&search=${Uri.encodeQueryComponent(search)}';
    }
    return base;
  }

  static String get updateTelecallingUrl =>
      '${baseUrl}inspection/telecallings/update';

  static String schedulesUrl({int page = 1, int limit = 5}) =>
      '${baseUrl}admin/telecallings/get-list?page=$page&limit=$limit';

  /// Aggregation URL — fetches all records for totals computation
  static String get schedulesAggregationUrl =>
      '${baseUrl}admin/telecallings/get-list?page=1&limit=1000';

  // ──────────────────────────────────────────
  // CAR DETAILS ENDPOINT
  // ──────────────────────────────────────────
  static String carDetailsUrl(String appointmentId) =>
      '${baseUrl}car/details/carId?appointmentId=$appointmentId';

  /// Re-Inspection: Fetch car details by carId with empty appointmentId
  static String carDetailsForReInspectionUrl(String carId) =>
      '${baseUrl}car/details/$carId?appointmentId=';

  /// Re-Inspection: Update existing car record
  static String get carUpdateUrl => '${baseUrl}car/update';

  // ──────────────────────────────────────────
  // INSPECTION SUBMISSION ENDPOINTS
  // ──────────────────────────────────────────
  static String get inspectionSubmitUrl =>
      '${baseUrl}inspection/car/add-car-through-inspection';

  static String get fetchVehicleDetailsUrl =>
      '${baseUrl}inspection/fetch-vehicle-details-via-attestr';

  static String get getAllDropdownsUrl =>
      '${baseUrl}inspection/dropdowns/get-all-dropdowns-list';

  static String get searchCarMakesUrl =>
      '${baseUrl}customer/sell-my-car/search-car-makes';
  static String get searchCarModelsUrl =>
      '${baseUrl}customer/sell-my-car/search-car-models-by-make';
  static String get searchCarVariantsUrl =>
      '${baseUrl}customer/sell-my-car/search-car-variants-by-make-model';

  // Cloudinary Upload/Delete
  static String get uploadImagesUrl =>
      '${baseUrl}inspection/car/upload-car-images-to-cloudinary';
  static String get deleteImageUrl =>
      '${baseUrl}inspection/car/delete-image-from-cloudinary';
  static String get uploadVideoUrl =>
      '${baseUrl}inspection/car/upload-car-video-to-cloudinary';
  static String get deleteVideoUrl =>
      '${baseUrl}inspection/car/delete-video-from-cloudinary';
}
