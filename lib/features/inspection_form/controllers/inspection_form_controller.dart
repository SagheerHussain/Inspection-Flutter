import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';
import '../../../data/services/api/api_service.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/popups/exports.dart';
import '../models/inspection_field_defs.dart';
import '../models/inspection_form_model.dart';
import '../models/car_model.dart';
import '../helpers/car_model_mapper.dart';
import '../helpers/car_model_debug_printer.dart';
import '../../schedules/models/schedule_model.dart';
import '../../dashboard/course/screens/dashboard/coursesDashboard.dart';
import '../../schedules/controllers/schedule_controller.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';

class InspectionFormController extends GetxController {
  final String appointmentId;
  final ScheduleModel? schedule;

  InspectionFormController({required this.appointmentId, this.schedule});

  final Rxn<InspectionFormModel> inspectionData = Rxn<InspectionFormModel>();
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final isSaving = false.obs;
  final isFetchingDetails = false.obs;

  // ── Re-Inspection state ──
  /// Tracks whether this lead originated from a Re-Inspection
  /// (set during data fetch — covers both direct Re-Inspection and Running leads that were Re-Inspected)
  bool _isReInspectionOrigin = false;

  /// True when the inspection should use the Re-Inspection update flow
  bool get isReInspection {
    if (_isReInspectionOrigin) return true;
    final s =
        schedule?.inspectionStatus.toLowerCase().replaceAll('-', '') ?? '';
    return s == 'reinspected' || s == 'reinspection';
  }

  /// Stores the original data snapshot fetched from the API for Re-Inspection
  /// (used for the preview dialog diff)
  Map<String, dynamic> _originalData = {};

  /// The carId (_id) from the car details API response for Re-Inspection update
  String? _reInspectionCarId;

  // Helper to find field definition by key
  F? _findFieldByKey(String key) {
    for (final section in InspectionFieldDefs.sections) {
      for (final field in section.fields) {
        if (field.key == key) return field;
      }
    }
    return null;
  }

  // Tabs / Sections
  final currentSectionIndex = 0.obs;
  final pageController = PageController();

  // Field navigation: when set, the UI will scroll to this field key
  final targetFieldKey = RxnString();
  final _storage = GetStorage();
  final _picker = ImagePicker();

  // ── User-edited field tracking ──
  // Tracks which field keys the user has explicitly changed during this session.
  final Set<String> _userEditedKeys = {};

  /// Local snapshot storage key — full form data cached after first API call.
  /// Once this exists, the API is NEVER called again for this appointment.
  String get _snapshotKey => 'snapshot_$appointmentId';
  String get _snapshotImagesKey => 'snapshot_images_$appointmentId';

  // Image storage: key → list of local file paths
  final RxMap<String, List<String>> imageFiles = <String, List<String>>{}.obs;

  // Cloudinary storage: localPath → {url, publicId}
  final RxMap<String, Map<String, String>> mediaCloudinaryData =
      <String, Map<String, String>>{}.obs;

  // Dynamic Dropdown Options: key → list of string options
  final RxMap<String, List<String>> dropdownOptions =
      <String, List<String>>{}.obs;

  List<String> get sectionTitles =>
      InspectionFieldDefs.sections.map((s) => s.title).toList();

  int get sectionCount => InspectionFieldDefs.sections.length;

  // ─── Non-mandatory field keys (can be empty on submit) ───
  static const Set<String> nonMandatoryKeys = {
    'additionalDetails',
    'bonnetImages',
    'frontBumperImages',
    'commentsOnEngine',
    'commentsOnEngineOil',
    'commentsOnRadiator',
    'additionalImages',
    'commentsOnTowing',
    'commentsOnOthers',
    'commentsOnClusterMeter',
    'commentsOnAC',
    'airbagImages',
    'coDriverAirbagImages',
    'driverSeatAirbagImages',
    'coDriverSeatAirbagImages',
    'rhsCurtainAirbagImages',
    'lhsCurtainAirbagImages',
    'driverKneeAirbagImages',
    'coDriverKneeAirbagImages',
    'rhsRearSideAirbagImages',
    'lhsRearSideAirbagImages',
    'commentOnInterior',
    'commentsOnTransmission',
  };

  @override
  void onInit() {
    super.onInit();
    fetchDropdownList();
    fetchInspectionData();
  }

  Future<void> fetchInspectionData() async {
    isLoading.value = true;
    try {
      // ── RE-INSPECTION FLOW ──
      if (isReInspection) {
        // Check snapshot first — API called only once
        final snapshot = _storage.read(_snapshotKey);
        if (snapshot != null && snapshot is Map) {
          _isReInspectionOrigin = true;
          _reInspectionCarId = snapshot['_id']?.toString();
          inspectionData.value = InspectionFormModel.fromJson(
            Map<String, dynamic>.from(snapshot),
          );
          final savedImages = _storage.read(_snapshotImagesKey);
          if (savedImages != null && savedImages is Map) {
            for (final entry in savedImages.entries) {
              final list = entry.value;
              if (list is List) {
                imageFiles[entry.key.toString()] =
                    list.map((e) => e.toString()).toList();
              }
            }
          }
          Get.snackbar(
            'Draft Loaded',
            'Continuing from your saved progress.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
          );
          _syncScheduleWithChanges();
          isLoading.value = false;
          return;
        }

        // First open — hit the API and cache
        final response = await ApiService.get(
          ApiConstants.carDetailsUrl(appointmentId),
        );

        final carData = response['carDetails'];
        if (carData != null) {
          _isReInspectionOrigin = true;
          _reInspectionCarId = carData['_id']?.toString();
          _originalData = Map<String, dynamic>.from(carData);
          _normalizeCarDataToFormKeys(carData);
          inspectionData.value = InspectionFormModel.fromJson(carData);
          _preFillMedia(carData);
          await _saveSnapshot(); // cache so next open skips API

          Get.snackbar(
            'Re-Inspection Data Loaded',
            'Previous inspection data pre-filled. Update fields as needed.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
            duration: const Duration(seconds: 3),
          );
        } else {
          _initializeNewInspection();
        }

        isLoading.value = false;
        return;
      }

      // ── RUNNING LEADS: Check for Re-Inspection Origin FIRST ──
      // Uses snapshot if available (API called only once).
      final normalizedStatus =
          schedule?.inspectionStatus.toLowerCase().replaceAll('-', '') ?? '';

      if (normalizedStatus == 'running') {
        // Check snapshot first
        final snapshot = _storage.read(_snapshotKey);
        if (snapshot != null && snapshot is Map) {
          final cachedId = snapshot['_id']?.toString();
          if (cachedId != null && cachedId.isNotEmpty) {
            _isReInspectionOrigin = true;
            _reInspectionCarId = cachedId;
            inspectionData.value = InspectionFormModel.fromJson(
              Map<String, dynamic>.from(snapshot),
            );
            final savedImages = _storage.read(_snapshotImagesKey);
            if (savedImages != null && savedImages is Map) {
              for (final entry in savedImages.entries) {
                final list = entry.value;
                if (list is List) {
                  imageFiles[entry.key.toString()] =
                      list.map((e) => e.toString()).toList();
                }
              }
            }
            Get.snackbar(
              'Draft Loaded',
              'Continuing from your saved progress.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade700,
              colorText: Colors.white,
              margin: const EdgeInsets.all(12),
              borderRadius: 12,
              duration: const Duration(seconds: 2),
            );
            _syncScheduleWithChanges();
            isLoading.value = false;
            return;
          }
        }

        // First open — call API to detect Re-Inspection origin
        try {
          final response = await ApiService.get(
            ApiConstants.carDetailsUrl(appointmentId),
          );
          final carData = response['carDetails'];
          if (carData != null && carData['_id'] != null) {
            _isReInspectionOrigin = true;
            _reInspectionCarId = carData['_id']?.toString();
            _originalData = Map<String, dynamic>.from(carData);
            _normalizeCarDataToFormKeys(carData);
            inspectionData.value = InspectionFormModel.fromJson(carData);
            _preFillMedia(carData);
            await _saveSnapshot(); // cache for all future opens

            Get.snackbar(
              'Re-Inspection Data Loaded',
              'Previous inspection data pre-filled. Update fields as needed.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade700,
              colorText: Colors.white,
              margin: const EdgeInsets.all(12),
              borderRadius: 12,
              duration: const Duration(seconds: 3),
            );

            _syncScheduleWithChanges();
            isLoading.value = false;
            return;
          }
        } catch (e) {
          // Fall through to standard flow
        }
      }

      // ── STANDARD FLOW (Scheduled / Running without Re-Inspection) ──
      // Strategy: Call the API exactly ONCE per appointment.
      //   • First open  → hit API, normalise, cache as local snapshot, display.
      //   • Later opens → skip API, load directly from local snapshot.
      // On "Save" the snapshot is fully overwritten with current form state,
      // so all user edits survive across sessions without touching the API.

      final snapshot = _storage.read(_snapshotKey);

      if (snapshot != null && snapshot is Map) {
        // ── SUBSEQUENT OPEN: load from snapshot (no API call) ──
        inspectionData.value = InspectionFormModel.fromJson(
          Map<String, dynamic>.from(snapshot),
        );

        // Restore image paths saved in the snapshot
        final savedImages = _storage.read(_snapshotImagesKey);
        if (savedImages != null && savedImages is Map) {
          for (final entry in savedImages.entries) {
            final list = entry.value;
            if (list is List) {
              imageFiles[entry.key.toString()] =
                  list.map((e) => e.toString()).toList();
            }
          }
        }

        Get.snackbar(
          'Draft Loaded',
          'Continuing from your saved progress.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
        _syncScheduleWithChanges();
        isLoading.value = false;
        return;
      }

      // ── FIRST OPEN: call the API, then cache the result ──
      try {
        final response = await ApiService.get(
          ApiConstants.carDetailsUrl(appointmentId),
        );

        final carData = response['carDetails'];
        if (carData != null && carData['_id'] != null) {
          // Reverse-map API keys → form keys
          _normalizeCarDataToFormKeys(carData);

          inspectionData.value = InspectionFormModel.fromJson(carData);

          // Pre-fill media from the API response
          _preFillMedia(carData);

          // ── Cache the normalised data so subsequent opens skip the API ──
          await _saveSnapshot();

          Get.snackbar(
            'Data Loaded',
            'Inspection data loaded from server.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
          );
          _syncScheduleWithChanges();
          isLoading.value = false;
          return;
        }
      } catch (e) {
        // debugPrint('⚠️ Car details fetch failed: $e — falling back to new form');
      }

      // No car record found — initialize empty form
      _initializeNewInspection();
    } catch (e) {
      // debugPrint('Fetch failed, initializing new: $e');
      _initializeNewInspection();
    } finally {
      isLoading.value = false;
    }
  }

  /// Reverse-maps API/CarModel JSON keys → Form field keys.
  /// The CarModel.toJson() outputs keys that differ from the form field keys.
  /// This method copies values from API keys to the form keys so
  /// InspectionFormModel.fromJson() + getFieldValue() can find them.
  void _normalizeCarDataToFormKeys(Map<String, dynamic> carData) {
    int mapped = 0;

    // Helper: parse a date value from various formats (ISO string, MongoDB $date, etc.)
    // and return a human-readable string
    String? _formatDate(dynamic val, {bool monthYearOnly = false}) {
      if (val == null) return null;
      DateTime? dt;

      if (val is String && val.isNotEmpty && val != 'N/A') {
        dt = DateTime.tryParse(val);
      } else if (val is Map) {
        // MongoDB $date format: {"$date": "2024-03-15T00:00:00.000Z"} or {"$date": {"$numberLong": "..."}}
        final dateVal = val['\$date'];
        if (dateVal is String) {
          dt = DateTime.tryParse(dateVal);
        } else if (dateVal is Map && dateVal['\$numberLong'] != null) {
          final ms = int.tryParse(dateVal['\$numberLong'].toString());
          if (ms != null) dt = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }

      if (dt == null) return null;

      if (monthYearOnly) {
        return '${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      }
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    }

    // Helper: normalize a date field in carData to DD-MM-YYYY format
    void normDate(String key, {bool monthYearOnly = false}) {
      final val = carData[key];
      if (val == null || val.toString().isEmpty || val.toString() == 'N/A')
        return;

      // Skip if already in DD-MM-YYYY format
      final str = val.toString();
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(str)) return;
      if (monthYearOnly && RegExp(r'^\d{2}-\d{4}$').hasMatch(str)) return;

      final formatted = _formatDate(val, monthYearOnly: monthYearOnly);
      if (formatted != null) {
        carData[key] = formatted;
        mapped++;
        // debugPrint('📅 Formatted date [$key]: $str → $formatted');
      }
    }

    // Helper: copy value from apiKey to formKey if formKey doesn't already have a value
    void map(String apiKey, String formKey, {bool isList = false}) {
      final apiVal = carData[apiKey];
      final formVal = carData[formKey];

      // Skip if form key already has a value
      if (formVal != null &&
          formVal.toString().isNotEmpty &&
          formVal.toString() != '0' &&
          formVal.toString() != 'N/A') {
        return;
      }

      if (apiVal == null ||
          apiVal.toString().isEmpty ||
          apiVal.toString() == 'N/A')
        return;

      if (isList && apiVal is List && apiVal.isNotEmpty) {
        // If the field is a multi-select field, keep it as a list.
        // Otherwise, take the first element for single-value dropdowns.
        final field = _findFieldByKey(formKey);
        if (field?.type == FType.multiSelect) {
          carData[formKey] = apiVal.map((e) => e.toString()).toList();
        } else {
          carData[formKey] = apiVal.first.toString();
        }
        mapped++;
      } else if (!isList) {
        carData[formKey] = apiVal;
        mapped++;
      }
    }

    // ═════════════════════════════════════════════
    // DATE FIELD RENAMES (API key → Form key)
    // ═════════════════════════════════════════════
    map('fitnessTill', 'fitnessValidity');
    map('yearAndMonthOfManufacture', 'yearMonthOfManufacture');
    map('yearMonthOfManufacture', 'yearMonthOfManufacture');

    // Date fields are now FType.date with a date picker.
    // The _BoundDateField widget handles ISO → DD-MM-YYYY display.
    // No need to pre-format date strings.

    // ═════════════════════════════════════════════
    // STRING FIELD RENAMES
    // ═════════════════════════════════════════════
    map('ieName', 'emailAddress');
    map('inspectionCity', 'city');
    map('policyNumber', 'insurancePolicyNumber');
    map('airConditioningManual', 'acType');
    map('airConditioningClimateControl', 'acCooling');
    map('commentsOnAC', 'commentsOnAC');
    map('odometerReadingBeforeTestDrive', 'odometerReadingInKms');
    map('driverAirbag', 'airbagFeaturesDriverSide');
    map('coDriverAirbag', 'airbagFeaturesCoDriverSide');

    // ═════════════════════════════════════════════
    // DROPDOWN LIST → SINGLE VALUE CONVERSIONS
    // The API stores these as arrays (XDropdownList),
    // but the form expects a single string value.
    // ═════════════════════════════════════════════
    map('rcBookAvailabilityDropdownList', 'rcBookAvailability', isList: true);
    map('mismatchInRcDropdownList', 'mismatchInRc', isList: true);
    map('insuranceDropdownList', 'insurance', isList: true);
    map('mismatchInInsuranceDropdownList', 'mismatchInInsurance', isList: true);
    map('additionalDetailsDropdownList', 'additionalDetails', isList: true);
    map('bonnetDropdownList', 'bonnet', isList: true);
    map('frontWindshieldDropdownList', 'frontWindshield', isList: true);
    map('roofDropdownList', 'roof', isList: true);
    map('frontBumperDropdownList', 'frontBumper', isList: true);
    map('lhsHeadlampDropdownList', 'lhsHeadlamp', isList: true);
    map('lhsFoglampDropdownList', 'lhsFoglamp', isList: true);
    map('rhsHeadlampDropdownList', 'rhsHeadlamp', isList: true);
    map('rhsFoglampDropdownList', 'rhsFoglamp', isList: true);
    map('lhsFenderDropdownList', 'lhsFender', isList: true);
    map('lhsOrvmDropdownList', 'lhsOrvm', isList: true);
    map('lhsAPillarDropdownList', 'lhsAPillar', isList: true);
    map('lhsBPillarDropdownList', 'lhsBPillar', isList: true);
    map('lhsCPillarDropdownList', 'lhsCPillar', isList: true);
    map('lhsFrontWheelDropdownList', 'lhsFrontAlloy', isList: true);
    map('lhsFrontTyreDropdownList', 'lhsFrontTyre', isList: true);
    map('lhsRearWheelDropdownList', 'lhsRearAlloy', isList: true);
    map('lhsRearTyreDropdownList', 'lhsRearTyre', isList: true);
    map('lhsFrontDoorDropdownList', 'lhsFrontDoor', isList: true);
    map('lhsRearDoorDropdownList', 'lhsRearDoor', isList: true);
    map('lhsRunningBorderDropdownList', 'lhsRunningBorder', isList: true);
    map('lhsQuarterPanelDropdownList', 'lhsQuarterPanel', isList: true);
    map('rearBumperDropdownList', 'rearBumper', isList: true);
    map('lhsTailLampDropdownList', 'lhsTailLamp', isList: true);
    map('rhsTailLampDropdownList', 'rhsTailLamp', isList: true);
    map('rearWindshieldDropdownList', 'rearWindshield', isList: true);
    map('bootDoorDropdownList', 'bootDoor', isList: true);
    map('spareTyreDropdownList', 'spareTyre', isList: true);
    map('bootFloorDropdownList', 'bootFloor', isList: true);
    map('rhsRearWheelDropdownList', 'rhsRearAlloy', isList: true);
    map('rhsRearTyreDropdownList', 'rhsRearTyre', isList: true);
    map('rhsFrontWheelDropdownList', 'rhsFrontAlloy', isList: true);
    map('rhsFrontTyreDropdownList', 'rhsFrontTyre', isList: true);
    map('rhsQuarterPanelDropdownList', 'rhsQuarterPanel', isList: true);
    map('rhsAPillarDropdownList', 'rhsAPillar', isList: true);
    map('rhsBPillarDropdownList', 'rhsBPillar', isList: true);
    map('rhsCPillarDropdownList', 'rhsCPillar', isList: true);
    map('rhsRunningBorderDropdownList', 'rhsRunningBorder', isList: true);
    map('rhsRearDoorDropdownList', 'rhsRearDoor', isList: true);
    map('rhsFrontDoorDropdownList', 'rhsFrontDoor', isList: true);
    map('rhsOrvmDropdownList', 'rhsOrvm', isList: true);
    map('rhsFenderDropdownList', 'rhsFender', isList: true);
    map('commentsOnExteriorDropdownList', 'comments', isList: true);
    map('upperCrossMemberDropdownList', 'upperCrossMember', isList: true);
    map('radiatorSupportDropdownList', 'radiatorSupport', isList: true);
    map('headlightSupportDropdownList', 'headlightSupport', isList: true);
    map('lowerCrossMemberDropdownList', 'lowerCrossMember', isList: true);
    map('lhsApronDropdownList', 'lhsApron', isList: true);
    map('rhsApronDropdownList', 'rhsApron', isList: true);
    map('firewallDropdownList', 'firewall', isList: true);
    map('cowlTopDropdownList', 'cowlTop', isList: true);
    map('engineDropdownList', 'engine', isList: true);
    map('batteryDropdownList', 'battery', isList: true);
    map('coolantDropdownList', 'coolant', isList: true);
    map(
      'engineOilLevelDipstickDropdownList',
      'engineOilLevelDipstick',
      isList: true,
    );
    map('engineOilDropdownList', 'engineOil', isList: true);
    map('engineMountDropdownList', 'engineMount', isList: true);
    map(
      'enginePermisableBlowByDropdownList',
      'enginePermisableBlowBy',
      isList: true,
    );
    map('exhaustSmokeDropdownList', 'exhaustSmoke', isList: true);
    map('clutchDropdownList', 'clutch', isList: true);
    map('gearShiftDropdownList', 'gearShift', isList: true);
    map('commentsOnEngineDropdownList', 'commentsOnEngine', isList: true);
    map('commentsOnEngineOilDropdownList', 'commentsOnEngineOil', isList: true);
    map('commentsOnTowingDropdownList', 'commentsOnTowing', isList: true);
    map(
      'commentsOnTransmissionDropdownList',
      'commentsOnTransmission',
      isList: true,
    );
    map('commentsOnRadiatorDropdownList', 'commentsOnRadiator', isList: true);
    map('commentsOnOthersDropdownList', 'commentsOnOthers', isList: true);
    map('steeringDropdownList', 'steering', isList: true);
    map('brakesDropdownList', 'brakes', isList: true);
    map('suspensionDropdownList', 'suspension', isList: true);
    map('rearWiperWasherDropdownList', 'rearWiperWasher', isList: true);
    map('rearDefoggerDropdownList', 'rearDefogger', isList: true);
    map('infotainmentSystemDropdownList', 'infotainmentSystem', isList: true);
    map(
      'rhsFrontDoorFeaturesDropdownList',
      'powerWindowConditionRhsFront',
      isList: true,
    );
    map(
      'lhsFrontDoorFeaturesDropdownList',
      'powerWindowConditionLhsFront',
      isList: true,
    );
    map(
      'rhsRearDoorFeaturesDropdownList',
      'powerWindowConditionRhsRear',
      isList: true,
    );
    map(
      'lhsRearDoorFeaturesDropdownList',
      'powerWindowConditionLhsRear',
      isList: true,
    );
    map('commentOnInteriorDropdownList', 'commentOnInterior', isList: true);
    map('sunroofDropdownList', 'sunroof', isList: true);
    map('reverseCameraDropdownList', 'reverseCamera', isList: true);
    map('acTypeDropdownList', 'acType');
    map('acCoolingDropdownList', 'acCooling');
    map('frontWiperAndWasherDropdownList', 'frontWiperAndWasher', isList: true);
    map('lhsRearFogLampDropdownList', 'lhsRearFogLamp', isList: true);
    map('rhsRearFogLampDropdownList', 'rhsRearFogLamp', isList: true);
    map('spareWheelDropdownList', 'spareWheel', isList: true);
    map('lhsSideMemberDropdownList', 'lhsSideMember', isList: true);
    map('rhsSideMemberDropdownList', 'rhsSideMember', isList: true);
    map('transmissionTypeDropdownList', 'transmissionType', isList: true);
    map('driveTrainDropdownList', 'driveTrain', isList: true);
    map(
      'commentsOnClusterMeterDropdownList',
      'commentsOnClusterMeter',
      isList: true,
    );
    map('dashboardDropdownList', 'dashboard', isList: true);
    map('driverSeatDropdownList', 'driverSeat', isList: true);
    map('coDriverSeatDropdownList', 'coDriverSeat', isList: true);
    map('frontCentreArmRestDropdownList', 'frontCentreArmRest', isList: true);
    map('rearSeatsDropdownList', 'rearSeats', isList: true);
    map('thirdRowSeatsDropdownList', 'thirdRowSeats', isList: true);

    // Seats Upholstery reverse logic (leatherSeats/fabricSeats → seatsUpholstery)
    if ((carData['seatsUpholstery'] == null ||
        carData['seatsUpholstery'].toString().isEmpty ||
        carData['seatsUpholstery'] == 'N/A')) {
      if (carData['leatherSeats'] == 'Yes') {
        carData['seatsUpholstery'] = 'Leather';
        mapped++;
      } else if (carData['fabricSeats'] == 'Yes') {
        carData['seatsUpholstery'] = 'Fabric';
        mapped++;
      }
    }

    // debugPrint('🔄 Reverse-mapping complete: $mapped fields normalized from API → form keys');
  }

  /// Extracts image/video URLs from API response and populates imageFiles
  void _preFillMedia(Map<String, dynamic> carData) {
    // 1. Explicit mappings where API keys and Form keys differ significantly
    final mediaMap = {
      'rcTaxToken': 'rcTokenImages',
      'insuranceCopy': 'insuranceImages',
      'bothKeys': 'duplicateKeyImages',
      'frontMain': 'frontMainImages',
      'lhsFront45Degree': 'lhsFullViewImages',
      'lhsFrontAlloyImages': 'lhsFrontWheelImages',
      'rhsRear45Degree': 'rhsFullViewImages',
      'rhsRearWheelImages': 'rhsRearWheelImages',
      'rhsFrontAlloyImages': 'rhsFrontWheelImages',
      'engineBay': 'engineBayImages',
      'engineSound': 'engineVideo',
      'apronLhsRhs': 'lhsApronImages',
      'meterConsoleWithEngineOn': 'meterConsoleWithEngineOnImages',
      'frontSeatsFromDriverSideDoorOpen': 'interiorImage1',
      'rearSeatsFromRightSideDoorOpen': 'interiorImage2',
      'dashboardFromRearSeat': 'interiorImage3',
      'additionalImages2': 'interiorImage4',
    };

    // 2. Iterate through all API data and try to find matching form fields
    carData.forEach((apiKey, val) {
      if (val == null) return;

      String? targetFormKey;

      if (mediaMap.containsKey(apiKey)) {
        targetFormKey = mediaMap[apiKey];
      } else {
        // Try exact match or appending 'Images'
        if (_findFieldByKey(apiKey) != null) {
          targetFormKey = apiKey;
        } else if (_findFieldByKey('${apiKey}Images') != null) {
          targetFormKey = '${apiKey}Images';
        }
      }

      if (targetFormKey != null) {
        final field = _findFieldByKey(targetFormKey);
        if (field != null &&
            (field.type == FType.image || field.type == FType.video)) {
          if (val is List) {
            imageFiles[targetFormKey] = val.map((e) => e.toString()).toList();
          } else if (val is String && val.isNotEmpty) {
            imageFiles[targetFormKey] = [val];
          }
        }
      }
    });

    imageFiles.refresh();
    // debugPrint(
    // '📸 Media pre-fill complete. Fields populated: ${imageFiles.keys.length}',
    // );
  }

  Future<void> fetchDropdownList() async {
    try {
      final response = await ApiService.get(ApiConstants.getAllDropdownsUrl);
      if (response['data'] is List) {
        final List<dynamic> data = response['data'];
        final Map<String, List<String>> apiDropdowns = {};

        // 1. Build the API dropdown map (isActive only)
        for (var item in data) {
          if (item is Map &&
              item['dropdownName'] != null &&
              item['dropdownValues'] is List &&
              item['isActive'] == true) {
            final String name = item['dropdownName'];
            final List<dynamic> vals = item['dropdownValues'];
            apiDropdowns[name] = vals.map((v) => v.toString()).toList();
          }
        }

        if (apiDropdowns.isEmpty) return;

        debugPrint('📋 [Dropdowns] Available API dropdown names:');
        for (final name in apiDropdowns.keys) {
          debugPrint('   → "$name"');
        }

        // 2. Map API dropdowns to form fields using Priority Rules
        final Map<String, List<String>> mappedOptions = {};

        // Internal helper for normalization
        String normalize(String s) =>
            s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

        // Internal helper for Levenshtein Distance (Similarity)
        double calculateSimilarity(String s1, String s2) {
          if (s1 == s2) return 1.0;
          if (s1.isEmpty || s2.isEmpty) return 0.0;

          List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
          List<int> v1 = List<int>.filled(s2.length + 1, 0);

          for (int i = 0; i < s1.length; i++) {
            v1[0] = i + 1;
            for (int j = 0; j < s2.length; j++) {
              int cost = (s1[i] == s2[j]) ? 0 : 1;
              v1[j + 1] = [
                v1[j] + 1,
                v0[j + 1] + 1,
                v0[j] + cost,
              ].reduce((a, b) => a < b ? a : b);
            }
            v0 = List.from(v1);
          }
          int distance = v0[s2.length];
          return 1.0 -
              (distance /
                  [s1.length, s2.length].reduce((a, b) => a > b ? a : b));
        }

        // ─── Priority 0: Explicit manual overrides ────────────────────────
        // Use these when fuzzy matching fails because the API name doesn't
        // resemble either the field key or the label closely enough.
        // Keys: form field key → exact API dropdownName (case must match).
        const Map<String, String> manualOverrides = {
          'lhsFrontAlloy': 'LHS Front Wheel',
          'lhsRearAlloy': 'LHS Rear Wheel',
          'rhsFrontAlloy': 'RHS Front Wheel',
          'rhsRearAlloy': 'RHS Rear Wheel',
          'lhsFrontTyre': 'LHS Front Tyre',
          'lhsRearTyre': 'LHS Rear Tyre',
          'rhsFrontTyre': 'RHS Front Tyre',
          'rhsRearTyre': 'RHS Rear Tyre',
          'commentsOnEngineOil': 'Comment On Engine Oil',
          'rearWiperWasher': 'Rear Wiper & Washer',
          'powerWindowConditionRhsFront': 'RHS Front Door Features',
          'powerWindowConditionLhsFront': 'LHS Front Door Features',
          'powerWindowConditionRhsRear': 'RHS Rear Door Features',
          'powerWindowConditionLhsRear': 'LHS Rear Door Features',
          'commentsOnRadiator': 'Comment On Radiator',
          'commentOnInterior': 'Comment On Interior',
          'commentsOnTransmission': 'Comments On Transmission',
          'commentsOnTowing': 'Comments On Towing',
          'commentsOnOthers': 'Comments On Others',
          'commentsOnAC': 'Comments On AC',
          'commentsOnClusterMeter': 'Comments On Cluster Meter',
          'chassisDetails': 'Chassis Details',
          'vinPlateDetails': 'Vin Plate Details',
          'additionalDetails': 'Additional Details',
          'fuelLevel': 'Fuel Level',
          'duplicateKey': 'Duplicate Key',
          'rtoForm28': 'RTO Form 28 (2 copies)',
          'rtoNoc': 'RTO NOC',
        };

        debugPrint(
          '🔍 [Dropdowns] Starting mapping for ${InspectionFieldDefs.sections.length} sections...',
        );

        for (final section in InspectionFieldDefs.sections) {
          for (final field in section.fields) {
            if (field.type != FType.dropdown && field.type != FType.multiSelect)
              continue;

            final fieldKey = field.key;
            final fieldLabel = field.label;
            final normKey = normalize(fieldKey);
            final normLabel = normalize(fieldLabel);

            // ── Priority 0: Manual Override ──────────────────────────────
            if (manualOverrides.containsKey(fieldKey)) {
              final apiName = manualOverrides[fieldKey]!;
              // Try exact, then case-insensitive lookup in apiDropdowns
              final foundKey = apiDropdowns.keys.firstWhere(
                (k) => normalize(k) == normalize(apiName),
                orElse: () => '',
              );
              if (foundKey.isNotEmpty) {
                debugPrint(
                  '🎯 [Dropdowns] Manual Override: "$fieldKey" → "$foundKey"',
                );
                mappedOptions[fieldKey] = apiDropdowns[foundKey]!;
                continue; // skip fuzzy matching for this field
              } else {
                debugPrint(
                  '⚠️ [Dropdowns] Override failed for "$fieldKey" ("$apiName" not found in API list)',
                );
              }
            }

            String? bestMatchName;
            double bestScore = 0.0;

            for (final dropdownName in apiDropdowns.keys) {
              final normApiName = normalize(dropdownName);

              // Priority 1 & 2: Exact/Normalized Match
              if (normKey == normApiName || normLabel == normApiName) {
                bestMatchName = dropdownName;
                bestScore = 1.0;
                break;
              }

              // Priority 3: Fuzzy Match (Confidence Check)
              final keyScore = calculateSimilarity(normKey, normApiName);
              final labelScore = calculateSimilarity(normLabel, normApiName);
              final currentBest = keyScore > labelScore ? keyScore : labelScore;

              if (currentBest > bestScore) {
                bestScore = currentBest;
                bestMatchName = dropdownName;
              }
            }

            // High confidence threshold (0.75) for fuzzy matching
            if (bestMatchName != null && bestScore >= 0.75) {
              debugPrint(
                '🔗 [Dropdowns] Auto-mapped "$fieldKey" ("$fieldLabel") → "$bestMatchName" (Score: $bestScore)',
              );
              mappedOptions[fieldKey] = apiDropdowns[bestMatchName]!;
            }
          }
        }

        if (mappedOptions.isNotEmpty) {
          debugPrint(
            '✅ [Dropdowns] Successfully mapped ${mappedOptions.length} fields.',
          );
          for (final entry in mappedOptions.entries) {
            debugPrint('   📍 ${entry.key} → ${entry.value.length} items');
          }
          dropdownOptions.addAll(mappedOptions);
        }
      }
    } catch (e) {
      // debugPrint('❌ Error mapping dropdowns: $e');
    }
  }

  void _initializeNewInspection() {
    inspectionData.value = InspectionFormModel(
      id: '',
      appointmentId: appointmentId,
      make: '',
      model: '',
      variant: '',
      status: 'Pending',
      data: {
        'appointmentId': appointmentId,
        'registrationNumber': schedule?.carRegistrationNumber ?? '',
        'yearMonthOfManufacture': schedule?.yearOfManufacture ?? '',
        'odometerReadingInKms': schedule?.odometerReadingInKms ?? 0,
        'customerName': schedule?.ownerName ?? '',
        'customerPhone': schedule?.customerContactNumber ?? '',
        'city': schedule?.city ?? '',
        'make': '',
        'model': '',
        'variant': '',
        'ownerSerialNumber': schedule?.ownershipSerialNumber ?? 1,
      },
    );
  }

  /// Persists the entire current form state (fields + images) to local storage.
  /// Call after first API load AND after every user save.
  Future<void> _saveSnapshot() async {
    final data = inspectionData.value;
    if (data == null) return;

    final snapMap = <String, dynamic>{};
    data.data.forEach((key, value) {
      if (value is String || value is num || value is bool || value == null) {
        snapMap[key] = value;
      } else if (value is List) {
        snapMap[key] = value.map((e) => e.toString()).toList();
      } else {
        snapMap[key] = value.toString();
      }
    });

    // Always write identity fields from data.data (source of truth set by updateField)
    snapMap['_id'] = data.data['_id'] ?? data.id;
    snapMap['appointmentId'] = data.data['appointmentId'] ?? data.appointmentId;
    snapMap['make'] = data.data['make'] ?? data.make;
    snapMap['model'] = data.data['model'] ?? data.model;
    snapMap['variant'] = data.data['variant'] ?? data.variant;
    snapMap['status'] = data.data['status'] ?? data.status;
    await _storage.write(_snapshotKey, snapMap);

    // Persist image paths in snapshot
    final imgMap = <String, dynamic>{};
    imageFiles.forEach((k, v) => imgMap[k] = v);
    await _storage.write(_snapshotImagesKey, imgMap);
  }

  // ─── Field Operations ───
  void updateField(String key, dynamic value) {
    final data = inspectionData.value;
    if (data != null) {
      if (data.data[key] == value) return;
      data.data[key] = value;

      // Keep the typed model fields in sync so _saveSnapshot reads correctly
      if (key == 'make') {
        data.make = value?.toString() ?? '';
        data.data['model'] = '';
        data.data['variant'] = '';
        data.model = '';
        data.variant = '';
        _userEditedKeys.add('model');
        _userEditedKeys.add('variant');
      } else if (key == 'model') {
        data.model = value?.toString() ?? '';
        data.data['variant'] = '';
        data.variant = '';
        _userEditedKeys.add('variant');
      } else if (key == 'variant') {
        data.variant = value?.toString() ?? '';
      }

      // Mark this key as user-edited
      _userEditedKeys.add(key);

      // Sync changes to the list cards if make/model/variant changed
      if (['make', 'model', 'variant'].contains(key)) {
        _syncScheduleWithChanges();
      }

      inspectionData.refresh();
    }
  }

  /// Syncs the current make/model/variant to any ScheduleController instances
  /// so the list cards reflect the updates immediately.
  void _syncScheduleWithChanges() {
    final data = inspectionData.value;
    if (data == null) return;

    ScheduleController.updateScheduleGlobally(
      appointmentId,
      make: data.data['make']?.toString(),
      model: data.data['model']?.toString(),
      variant: data.data['variant']?.toString(),
    );
  }

  String getFieldValue(String key) {
    final val = inspectionData.value?.data[key];
    if (val is List) {
      return val.join(', ');
    }
    return val?.toString() ?? '';
  }

  List<String> getFieldList(String key) {
    final val = inspectionData.value?.data[key];
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    if (val != null && val.toString().isNotEmpty) {
      return [val.toString()];
    }
    return [];
  }

  // ─── Image Operations ───
  Future<void> pickImage(String key, ImageSource source) async {
    try {
      final field = _findFieldByKey(key);
      final max = field?.maxImages ?? 3;
      final current = imageFiles[key]?.length ?? 0;

      if (current >= max) {
        Get.snackbar(
          'Limit Reached',
          'You can only upload up to $max images for this field.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked != null) {
        final currentList = imageFiles[key] ?? [];
        currentList.add(picked.path);
        imageFiles[key] = List.from(currentList);
        imageFiles.refresh();

        // Trigger Upload
        _uploadMedia(key, picked.path, isVideo: false);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> pickVideo(String key, ImageSource source) async {
    try {
      final field = _findFieldByKey(key);
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration:
            field?.maxDuration != null
                ? Duration(seconds: field!.maxDuration!)
                : null,
      );

      if (picked != null) {
        // --- Gallery Duration Validation ---
        if (field?.maxDuration != null) {
          final info = await VideoCompress.getMediaInfo(picked.path);
          final durationSec = (info.duration ?? 0) / 1000;

          // Add a tiny 0.5s buffer for metadata inconsistencies
          if (durationSec > (field!.maxDuration! + 0.5)) {
            TLoaders.errorSnackBar(
              title: 'Video Too Long',
              message:
                  'The selected video is ${durationSec.toStringAsFixed(1)}s. '
                  'Maximum allowed for ${field.label} is ${field.maxDuration}s.',
            );
            return;
          }
        }

        // Video always limited (maxImages is 1 for video by default now)
        imageFiles[key] = [picked.path];
        imageFiles.refresh();

        // Trigger Upload (Compression starts inside _uploadMedia)
        _uploadMedia(key, picked.path, isVideo: true);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not pick video: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> pickMultipleImages(String key) async {
    try {
      final field = _findFieldByKey(key);
      final max = field?.maxImages ?? 3;
      final currentPaths = imageFiles[key] ?? [];

      if (currentPaths.length >= max) {
        Get.snackbar(
          'Limit Reached',
          'You can already have $max images for this field.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (picked.isNotEmpty) {
        final currentList = List<String>.from(imageFiles[key] ?? []);
        // Take only up to what fits
        final remaining = max - currentList.length;
        final toAdd = picked.take(remaining).map((x) => x.path);

        currentList.addAll(toAdd);
        imageFiles[key] = currentList;
        imageFiles.refresh();

        // Trigger Uploads
        for (final path in toAdd) {
          _uploadMedia(key, path, isVideo: false);
        }

        if (picked.length > remaining) {
          Get.snackbar(
            'Limit Restricted',
            'Only $remaining images were added to respect the $max image limit.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blueAccent,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not pick images: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  void removeImage(String key, int index) {
    final currentList = imageFiles[key] ?? [];
    if (index >= 0 && index < currentList.length) {
      final path = currentList[index];
      final field = _findFieldByKey(key);
      final label = field?.label ?? key;
      final fileName = path.split('/').last;

      // debugPrint(
      // '🗑️ USER ACTION: Removing image "$fileName" from field "$label"',
      // );

      // Trigger Delete from Cloudinary
      final data = mediaCloudinaryData[path];
      if (data != null && data['publicId'] != null) {
        final isVideo = field?.type == FType.video;
        _deleteMedia(
          data['publicId']!,
          isVideo: isVideo,
          localInfo: '[$label] $fileName',
        );
      } else {
        // debugPrint(
        // 'ℹ️ Note: No remote delete called. This image was likely not uploaded yet or failed upload.',
        // );
      }

      currentList.removeAt(index);
      mediaCloudinaryData.remove(path);

      imageFiles[key] = List.from(currentList);
      imageFiles.refresh();
    }
  }

  // ─── Cloudinary API Helpers ───
  Future<void> _uploadMedia(
    String fieldKey,
    String localPath, {
    required bool isVideo,
  }) async {
    try {
      // debugPrint(
      // '⬆️ [START] Uploading ${isVideo ? 'video' : 'image'} to Cloudinary...',
      // );
      // debugPrint('📍 Local Path: $localPath');

      String finalPath = localPath;

      if (isVideo) {
        TLoaders.customToast(message: 'Compressing video...');
        final compressedPath = await _compressVideo(localPath);
        if (compressedPath == null) {
          // debugPrint('❌ Video compression failed or was cancelled.');
          return;
        }

        // Check size limit: 10MB = 10 * 1024 * 1024 bytes
        final file = File(compressedPath);
        final size = await file.length();
        if (size > 10 * 1024 * 1024) {
          TLoaders.errorSnackBar(
            title: 'Video Too Large',
            message: 'Compressed video exceeds 10MB limit.',
          );
          return;
        }
        finalPath = compressedPath;
      }

      final url =
          isVideo ? ApiConstants.uploadVideoUrl : ApiConstants.uploadImagesUrl;
      final fileKey = isVideo ? 'video' : 'imagesList';

      final file = await http.MultipartFile.fromPath(fileKey, finalPath);

      final response = await ApiService.multipartPost(
        url: url,
        fields: {'appointmentId': appointmentId},
        files: [file],
      );

      // Print full API response for transparency
      // debugPrint('📦 API RESPONSE (Upload - $fieldKey): $response');

      final resultData = response['data'] ?? response;
      String? returnedUrl;
      String? publicId;

      // Check if files list exists (for image uploads)
      if (resultData['files'] is List &&
          (resultData['files'] as List).isNotEmpty) {
        final firstFile = resultData['files'][0];
        returnedUrl = firstFile['url']?.toString();
        publicId =
            (firstFile['publicId'] ?? firstFile['public_id'])?.toString();
      } else {
        // Fallback for direct fields (common in video uploads)
        // Check multiple possible URL keys: originalUrl, optimizedUrl, url
        returnedUrl =
            (resultData['originalUrl'] ??
                    resultData['optimizedUrl'] ??
                    resultData['url'])
                ?.toString();
        publicId =
            (resultData['publicId'] ?? resultData['public_id'])?.toString();
      }

      if (returnedUrl != null) {
        // debugPrint('🌐 SUCCESS: File available at: $returnedUrl');
        if (publicId != null) {
          // debugPrint('🔑 PublicID stored for deletion: $publicId');
          mediaCloudinaryData[localPath] = {
            'url': returnedUrl,
            'publicId': publicId,
          };
        } else {
          // debugPrint(
          // '⚠️ WARNING: No publicId found in response. Remote deletion will not work for this file.',
          // );
        }
      } else {
        // debugPrint(
        // '❌ ERROR: Upload response did not contain a URL or files list.',
        // );
      }
    } catch (e) {
      // debugPrint('❌ FATAL: Upload failed for $localPath: $e');
    }
  }

  Future<String?> _compressVideo(String videoPath) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Keep the original just in case
        includeAudio: true,
      );
      return mediaInfo?.path;
    } catch (e) {
      // debugPrint('❌ Video compress error: $e');
      return null;
    }
  }

  Future<void> _deleteMedia(
    String publicId, {
    required bool isVideo,
    required String localInfo,
  }) async {
    try {
      // debugPrint(
      // '� API CALL: Deleting ${isVideo ? 'video' : 'image'} from Cloudinary',
      // );
      // debugPrint('📍 Target: $localInfo (PublicID: $publicId)');

      final url =
          isVideo ? ApiConstants.deleteVideoUrl : ApiConstants.deleteImageUrl;

      final response = await ApiService.delete(url, {'publicId': publicId});

      // Print full API response
      // debugPrint('� API RESPONSE (Delete $localInfo): $response');

      // debugPrint('✅ SUCCESS: Remote file deleted.');
    } catch (e) {
      // debugPrint('❌ ERROR: Delete failed for $localInfo: $e');
    }
  }

  List<String> getImages(String key) {
    return imageFiles[key] ?? [];
  }

  // ─── Navigation ───
  void nextSection() {
    if (currentSectionIndex.value < sectionCount - 1) {
      currentSectionIndex.value++;
      pageController.animateToPage(
        currentSectionIndex.value,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void previousSection() {
    if (currentSectionIndex.value > 0) {
      currentSectionIndex.value--;
      pageController.animateToPage(
        currentSectionIndex.value,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void jumpToSection(int index) {
    currentSectionIndex.value = index;
    pageController.jumpToPage(index);
  }

  /// Navigate to a specific field by its key.
  /// Finds which section it belongs to, jumps to that section,
  /// and broadcasts the field key so the UI can scroll to it.
  void navigateToField(String fieldKey) {
    for (int i = 0; i < InspectionFieldDefs.sections.length; i++) {
      final section = InspectionFieldDefs.sections[i];
      for (final field in section.fields) {
        if (field.key == fieldKey) {
          // Jump to the section
          jumpToSection(i);
          // Broadcast the target field key after a short delay
          // so the page has time to build
          Future.delayed(const Duration(milliseconds: 350), () {
            targetFieldKey.value = fieldKey;
            // Clear after another delay so it doesn't retrigger
            Future.delayed(const Duration(milliseconds: 500), () {
              targetFieldKey.value = null;
            });
          });
          return;
        }
      }
    }
  }

  // ─── Save Draft (Local) ───
  Future<void> saveInspection() async {
    final data = inspectionData.value;
    if (data == null) return;

    isSaving.value = true;
    try {
      // Write full current form state to the local snapshot.
      // This is the single source-of-truth for all future re-opens.
      await _saveSnapshot();

      // Legacy full-draft write kept for backward compatibility
      final draftKey = 'draft_$appointmentId';
      final saveMap = <String, dynamic>{};
      data.data.forEach((key, value) {
        if (value is String || value is num || value is bool || value == null) {
          saveMap[key] = value;
        } else if (value is List) {
          saveMap[key] = value.map((e) => e.toString()).toList();
        } else {
          saveMap[key] = value.toString();
        }
      });
      saveMap['_id'] = data.id;
      saveMap['appointmentId'] = data.appointmentId;
      saveMap['make'] = data.make;
      saveMap['model'] = data.model;
      saveMap['variant'] = data.variant;
      saveMap['status'] = data.status;
      await _storage.write(draftKey, saveMap);
      final imgKey = 'draft_images_$appointmentId';
      final imgMap = <String, dynamic>{};
      imageFiles.forEach((k, v) => imgMap[k] = v);
      await _storage.write(imgKey, imgMap);

      // debugPrint('💾 Draft saved successfully to local storage');

      // Always clear existing snackbars
      try {
        Get.closeAllSnackbars();
      } catch (e) {
        // Ignore errors from GetX snackbar system
      }

      // Simple delay to ensure GetX clears the overlay before showing new one
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          'Data Saved',
          'Your data has been saved as Draft',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          shouldIconPulse: false,
        );
      });
    } catch (e) {
      // debugPrint('Save draft error: $e');
      Get.snackbar(
        'Save Failed',
        'Could not save draft. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Submit to API ───
  Future<void> submitInspection() async {
    final data = inspectionData.value;
    if (data == null) return;

    // Validate ALL required fields across every section
    final missingBySection = <String, List<Map<String, String>>>{};
    for (final section in InspectionFieldDefs.sections) {
      for (final field in section.fields) {
        // 1. Skip if field should technically be hidden (Optional/Dynamic logic)
        if (field.optional) continue;

        // RC Condition visibility logic
        if (field.key == 'rcCondition') {
          final rcBookVal = getFieldValue('rcBookAvailability');
          if (rcBookVal != 'Original' && rcBookVal != 'Duplicate') continue;
        }

        // RTO Form 28 visibility logic
        if (field.key == 'rtoForm28') {
          final rtoNocVal = getFieldValue('rtoNoc');
          if (rtoNocVal == 'Not Applicable') continue;
        }

        // Tax Valid Till visibility logic
        if (field.key == 'taxValidTill') {
          final taxVal = getFieldValue('roadTaxValidity');
          if (taxVal != 'Limited Period') continue;
        }

        // Conditional requirements for images based on Not Applicable/Not Present selection
        final parentFields = {
          'lhsFoglampImages': 'lhsFoglamp',
          'rhsFoglampImages': 'rhsFoglamp',
          'lhsRearFogLampImages': 'lhsRearFogLamp',
          'rhsRearFogLampImages': 'rhsRearFogLamp',
          'rearWiperAndWasherImages': 'rearWiperWasher',
          'reverseCameraImages': 'reverseCamera',
          'sunroofImages': 'sunroof',
          'airbagImages': 'airbagFeaturesDriverSide',
          'coDriverAirbagImages': 'airbagFeaturesCoDriverSide',
          'driverSeatAirbagImages': 'driverSeatAirbag',
          'coDriverSeatAirbagImages': 'coDriverSeatAirbag',
          'rhsCurtainAirbagImages': 'rhsCurtainAirbag',
          'lhsCurtainAirbagImages': 'lhsCurtainAirbag',
          'driverKneeAirbagImages': 'driverSideKneeAirbag',
          'coDriverKneeAirbagImages': 'coDriverKneeSeatAirbag',
          'rhsRearSideAirbagImages': 'rhsRearSideAirbag',
          'lhsRearSideAirbagImages': 'lhsRearSideAirbag',
          'insuranceImages': 'insurance',
        };

        if (parentFields.containsKey(field.key)) {
          final parentVal = getFieldValue(parentFields[field.key]!);
          if (parentVal == 'Not Applicable' ||
              parentVal == 'Not Available' ||
              parentVal == 'Not Present' ||
              parentVal == 'Policy Not Available' ||
              parentVal == 'No' ||
              parentVal == 'N/A') {
            continue;
          }
        }

        // Duplicate Key Images requirement
        if (field.key == 'duplicateKeyImages') {
          final dupKeyVal = getFieldValue('duplicateKey');
          if (dupKeyVal != 'Duplicate Key Available' &&
              dupKeyVal != 'Available') {
            continue;
          }
        }

        // 2. Perform Validation
        if (field.type == FType.image || field.type == FType.video) {
          final imgs = getImages(field.key);
          final minReq = field.minImages > 0 ? field.minImages : 1;
          if (imgs.length < minReq) {
            String label = field.label;
            if (minReq > 1) label += ' (At least $minReq photos)';
            missingBySection.putIfAbsent(section.title, () => []).add({
              'key': field.key,
              'label': label,
            });
          }
        } else {
          final val = getFieldValue(field.key);
          if (val.isEmpty || val == '0') {
            if (field.type == FType.number && val == '0') continue;
            missingBySection.putIfAbsent(section.title, () => []).add({
              'key': field.key,
              'label': field.label,
            });
          }
        }
      }
    }

    if (missingBySection.isNotEmpty) {
      final totalMissing = missingBySection.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Missing Required Fields',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '$totalMissing field(s) need to be completed',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      missingBySection.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D6EFD,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${entry.key} (${entry.value.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D6EFD),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Field list — tappable to navigate
                              ...entry.value
                                  .take(5)
                                  .map(
                                    (f) => Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(Get.context!).pop();
                                          navigateToField(f['key']!);
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 5,
                                                color: Colors.red.shade300,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  f['label']!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 10,
                                                color: const Color(
                                                  0xFF0D6EFD,
                                                ).withValues(alpha: 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              if (entry.value.length > 5)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 2,
                                  ),
                                  child: Text(
                                    '+ ${entry.value.length - 5} more...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(Get.context!).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "OK, I'll fix them",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: true,
      );
      return;
    }

    // ══════════════════════════════════════════════════════════
    // RE-INSPECTION FLOW: Show Preview Dialog first
    // ══════════════════════════════════════════════════════════
    if (isReInspection) {
      _showReInspectionPreviewDialog(data);
      return;
    }

    // ══════════════════════════════════════════════════════════
    // STANDARD FLOW: Build CarModel, print debug, then submit to API
    // Check if record already exists — UPDATE instead of ADD
    // ══════════════════════════════════════════════════════════
    isSubmitting.value = true;
    try {
      // 1. Dump date field values for debugging
      final dateKeys = [
        'registrationDate',
        'fitnessValidity',
        'yearMonthOfManufacture',
        'taxValidTill',
        'insuranceValidity',
        'pucValidity',
      ];
      // debugPrint('═══════════════════════════════════════════════');
      // debugPrint('📅 DATE FIELD VALUES BEFORE BUILD:');
      for (final k in dateKeys) {
        final v = data.data[k];
        // debugPrint('  $k = ${v == null ? "NULL" : "\"$v\" (${v.runtimeType})"}');
      }
      // debugPrint('═══════════════════════════════════════════════');

      // 2. Build the CarModel from form data
      final carModel = _buildCarModelFromForm(data);

      // 2. Print all fields to debug console for verification
      _printCarModelDebug(carModel);

      // 3. Convert CarModel to JSON payload
      final payload = carModel.toJson();

      // 🔍 DEBUG: Trace bootDoorImages through the pipeline
      // debugPrint('═══════════════════════════════════════════════');
      // debugPrint('🔍 BOOT DOOR IMAGES DEBUG:');
      // debugPrint('  imageFiles[bootDoorImages] = ${imageFiles['bootDoorImages']}');
      // debugPrint('  carModel.bootDoorImages = ${carModel.bootDoorImages}');
      // debugPrint('  payload[bootDoorImages] (from toJson) = ${payload['bootDoorImages']}');
      // debugPrint('═══════════════════════════════════════════════');

      // Add image URLs from Cloudinary uploads
      imageFiles.forEach((key, paths) {
        if (paths.isNotEmpty) {
          final resolvedUrls =
              paths.map((p) {
                final cloudData = mediaCloudinaryData[p];
                return cloudData?['url'] ?? p;
              }).toList();
          payload[key] = resolvedUrls;
        }
      });

      // 🔍 DEBUG: bootDoorImages after imageFiles overlay
      // debugPrint('🔍 payload[bootDoorImages] (after overlay) = ${payload['bootDoorImages']}');

      // Ensure timestamp is set
      payload['timestamp'] = DateTime.now().toUtc().toIso8601String();

      // Debug: dump date values in payload
      // debugPrint('📅 DATE VALUES IN PAYLOAD:');
      for (final k in [
        'registrationDate',
        'fitnessTill',
        'yearMonthOfManufacture',
        'taxValidTill',
        'insuranceValidity',
        'pucValidity',
        'fitnessValidity',
        'yearAndMonthOfManufacture',
      ]) {
        // debugPrint('  payload[$k] = ${payload[k]}');
      }

      // ── Check if a car record already exists for this appointmentId ──
      String? existingCarId;
      try {
        // debugPrint('🔍 Checking if car record already exists for appointmentId: $appointmentId');
        final existingResponse = await ApiService.get(
          ApiConstants.carDetailsUrl(appointmentId),
        );
        final existingCar = existingResponse['carDetails'];
        if (existingCar != null && existingCar['_id'] != null) {
          existingCarId = existingCar['_id'].toString();
          // debugPrint('✅ Existing car record found: $existingCarId — will UPDATE instead of ADD');
        }
      } catch (e) {
        // debugPrint('ℹ️ No existing car record found (or check failed): $e — will ADD new record');
      }

      Map<String, dynamic> response;

      if (existingCarId != null) {
        // ── UPDATE existing record ──
        payload['carId'] = existingCarId;
        // Keep _id for the update API
        payload.remove('objectId');

        // debugPrint('📡 Updating existing car record via PUT...');
        // debugPrint('📦 Payload keys: ${payload.keys.toList()}');
        // debugPrint('🌐 URL: ${ApiConstants.carUpdateUrl}');
        // debugPrint('🔑 carId: $existingCarId');

        response = await ApiService.put(ApiConstants.carUpdateUrl, payload);
      } else {
        // ── ADD new record ──
        payload.remove('_id');
        payload.remove('id');
        payload.remove('objectId');
        // debugPrint(
        // '🔑 Payload after ID removal — _id: ${payload.containsKey('_id')}, id: ${payload.containsKey('id')}, objectId: ${payload.containsKey('objectId')}',
        // );

        // debugPrint('📡 Submitting new inspection to API...');
        // debugPrint('📦 Payload keys: ${payload.keys.toList()}');
        // debugPrint('🌐 URL: ${ApiConstants.inspectionSubmitUrl}');

        response = await ApiService.post(
          ApiConstants.inspectionSubmitUrl,
          payload,
        );
      }

      // debugPrint('✅ API Response: $response');

      // 5. Clear local draft on success
      await _storage.remove('draft_$appointmentId');
      await _storage.remove('draft_images_$appointmentId');

      // 6. Update telecalling status to 'Inspected'
      try {
        if (schedule != null) {
          // debugPrint('🔄 Updating telecalling status to Inspected...');
          // debugPrint('🔑 telecallingId: ${schedule!.id}');
          // debugPrint('📋 appointmentId: $appointmentId');

          final storage = GetStorage();
          final userId =
              storage.read('USER_ID')?.toString() ??
              storage.read('user_id')?.toString() ??
              '';
          final userRole =
              storage.read('USER_ROLE')?.toString() ?? 'Inspection Engineer';

          final statusBody = {
            'telecallingId': schedule!.id,
            'changedBy': userId,
            'source': userRole,
            'inspectionStatus': 'Inspected',
            'remarks': schedule!.remarks ?? '',
          };

          if (schedule!.inspectionDateTime != null) {
            statusBody['inspectionDateTime'] =
                schedule!.inspectionDateTime!.toIso8601String();
          }

          // debugPrint('📡 PUT ${ApiConstants.updateTelecallingUrl}');
          // debugPrint('📦 Body: $statusBody');

          final statusResponse = await ApiService.put(
            ApiConstants.updateTelecallingUrl,
            statusBody,
          );
          // debugPrint('✅ Telecalling status updated to Inspected: $statusResponse');

          // Refresh schedule list in background (non-blocking)
          try {
            if (Get.isRegistered<ScheduleController>()) {
              Get.find<ScheduleController>().refreshSchedules();
            }
          } catch (_) {}
        } else {
          // debugPrint('⚠️ schedule is null — cannot update telecalling status');
        }
      } catch (e) {
        // debugPrint('⚠️ Failed to update telecalling status: $e');
        // Don't block success if this fails — the car submission already succeeded
      }

      // 7. Show stunning success dialog
      try {
        Get.closeAllSnackbars();
      } catch (_) {}
      _showSuccessDialog(
        response['message'] ??
            (existingCarId != null
                ? 'Inspection updated successfully!'
                : 'Inspection submitted successfully!'),
      );
    } catch (e) {
      // debugPrint('❌ Submit error: $e');
      try {
        Get.closeAllSnackbars();
      } catch (_) {}
      _showErrorDialog(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Re-Inspection Preview Dialog ───
  void _showReInspectionPreviewDialog(InspectionFormModel data) {
    // Build the current data map from form
    final currentData = Map<String, dynamic>.from(data.data);

    // Resolve image URLs
    imageFiles.forEach((key, paths) {
      if (paths.isNotEmpty) {
        final resolvedUrls =
            paths.map((p) {
              final cloudData = mediaCloudinaryData[p];
              return cloudData?['url'] ?? p;
            }).toList();
        currentData[key] = resolvedUrls;
      }
    });

    // Build changed fields list for display
    final List<Map<String, dynamic>> changedFields = [];

    // Compare currentData with _originalData
    final allKeys = <String>{..._originalData.keys, ...currentData.keys};

    // Skip internal/system keys
    const skipKeys = {
      '_id',
      'id',
      '__v',
      'createdAt',
      'updatedAt',
      'timestamp',
      'objectId',
    };

    for (final key in allKeys) {
      if (skipKeys.contains(key)) continue;

      final oldVal = _originalData[key];
      final newVal = currentData[key];

      // Normalize for comparison
      final oldStr = _normalizeValue(oldVal);
      final newStr = _normalizeValue(newVal);

      if (oldStr != newStr) {
        // Try to find a human-readable label
        String label = key;
        final field = _findFieldByKey(key);
        if (field != null) label = field.label;

        // Detect if this is an image/media field
        final bool isImage = _isImageField(key, oldVal, newVal);

        if (isImage) {
          changedFields.add({
            'key': key,
            'label': label,
            'old': oldStr.isEmpty ? '(empty)' : oldStr,
            'new': newStr.isEmpty ? '(empty)' : newStr,
            'isImage': true,
            'oldImages': _extractImageUrls(oldVal),
            'newImages': _extractImageUrls(newVal),
          });
        } else {
          changedFields.add({
            'key': key,
            'label': label,
            'old': oldStr.isEmpty ? '(empty)' : oldStr,
            'new': newStr.isEmpty ? '(empty)' : newStr,
            'isImage': false,
          });
        }
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D6EFD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.preview_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Re-Inspection Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    changedFields.isEmpty
                        ? 'No changes detected'
                        : '${changedFields.length} field(s) changed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Body (scrollable list of changes)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child:
                  changedFields.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'All fields match the previous inspection. You can still submit to confirm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: changedFields.length,
                        separatorBuilder:
                            (_, __) =>
                                Divider(color: Colors.grey.shade200, height: 1),
                        itemBuilder: (context, index) {
                          final change = changedFields[index];
                          final bool isImageField = change['isImage'] == true;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  change['label'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                if (isImageField) ...[
                                  // ── Image thumbnails row ──
                                  _buildImageComparisonRow(
                                    'Before',
                                    Colors.red,
                                    change['oldImages'] as List<String>,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildImageComparisonRow(
                                    'After',
                                    Colors.green,
                                    change['newImages'] as List<String>,
                                  ),
                                ] else ...[
                                  // ── Text values ──
                                  // Previous value
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Before',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _truncate(
                                            change['old'].toString(),
                                            100,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // New value
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'After',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _truncate(
                                            change['new'].toString(),
                                            100,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1B5E20),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  // Back button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(Get.context!).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(Get.context!).pop();
                        _submitReInspection(data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Normalize any value to a comparable string
  String _normalizeValue(dynamic val) {
    if (val == null) return '';
    if (val is List) {
      if (val.isEmpty) return '';
      return val.map((e) => e.toString()).join(', ');
    }
    final str = val.toString().trim();
    if (str == '0' || str == 'null' || str == '[]') return '';
    return str;
  }

  /// Truncate long strings for display
  String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}...';
  }

  /// Check if a field contains image data
  bool _isImageField(String key, dynamic oldVal, dynamic newVal) {
    // Check by key naming convention
    if (key.toLowerCase().endsWith('images') ||
        key.toLowerCase().endsWith('image') ||
        key.toLowerCase().endsWith('video') ||
        key.toLowerCase().contains('photo')) {
      return true;
    }

    // Check by value content
    bool hasUrl(dynamic val) {
      if (val == null) return false;
      if (val is String)
        return val.startsWith('http') || val.startsWith('/data/');
      if (val is List) {
        return val.any(
          (e) =>
              e.toString().startsWith('http') ||
              e.toString().startsWith('/data/'),
        );
      }
      return false;
    }

    return hasUrl(oldVal) || hasUrl(newVal);
  }

  /// Extract image URLs from a dynamic value into a flat list
  List<String> _extractImageUrls(dynamic val) {
    if (val == null) return [];
    if (val is String) {
      if (val.isEmpty) return [];
      if (val.startsWith('http') || val.startsWith('/data/')) return [val];
      return [];
    }
    if (val is List) {
      return val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  /// Build a row showing label + thumbnail images
  Widget _buildImageComparisonRow(
    String label,
    Color color,
    List<String> imageUrls,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              imageUrls.isEmpty
                  ? Text(
                    '(no images)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                  : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        imageUrls.map((url) {
                          return GestureDetector(
                            onTap: () => _showImagePreview(url),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildThumbnail(url),
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }

  /// Build a thumbnail widget from a URL or local path
  Widget _buildThumbnail(String url) {
    if (url.startsWith('http')) {
      // Network image
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        errorBuilder:
            (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: Icon(
                Icons.broken_image_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.grey.shade400),
              ),
            ),
          );
        },
      );
    } else {
      // Local file path
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: 48, height: 48);
      }
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_rounded, size: 20, color: Colors.grey.shade400),
      );
    }
  }

  /// Show full-screen image preview with Close button
  void _showImagePreview(String url) {
    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Image viewer
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child:
                    url.startsWith('http')
                        ? Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    size: 64,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            );
                          },
                        )
                        : File(url).existsSync()
                        ? Image.file(File(url), fit: BoxFit.contain)
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'File not found',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            // Close button at top
            Positioned(
              top: MediaQuery.of(Get.context!).padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(Get.context!).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: Colors.transparent,
    );
  }

  /// Submit the Re-Inspection via PUT car/update
  Future<void> _submitReInspection(InspectionFormModel data) async {
    isSubmitting.value = true;
    try {
      // 1. Build the CarModel from form data
      final carModel = _buildCarModelFromForm(data);

      // 2. Print all fields to debug console for verification
      _printCarModelDebug(carModel);

      // 3. Convert CarModel to JSON payload
      final payload = carModel.toJson();

      // Add image URLs from Cloudinary uploads
      imageFiles.forEach((key, paths) {
        if (paths.isNotEmpty) {
          final resolvedUrls =
              paths.map((p) {
                final cloudData = mediaCloudinaryData[p];
                return cloudData?['url'] ?? p;
              }).toList();
          payload[key] = resolvedUrls;
        }
      });

      // Ensure timestamp is set
      payload['timestamp'] = DateTime.now().toUtc().toIso8601String();

      // For Re-Inspection: include carId and use PUT
      if (_reInspectionCarId != null) {
        payload['carId'] = _reInspectionCarId;
      }

      // Set status to Inspected on successful Re-Inspection submit
      payload['inspectionStatus'] = 'Inspected';

      // Keep the _id for the update API
      // Remove objectId only
      payload.remove('objectId');

      // debugPrint('📡 Submitting Re-Inspection update via PUT...');
      // debugPrint('📦 Payload keys: ${payload.keys.toList()}');
      // debugPrint('🌐 URL: ${ApiConstants.carUpdateUrl}');
      // debugPrint('🔑 carId: ${payload['carId']}');

      // 4. PUT to the update API
      final response = await ApiService.put(ApiConstants.carUpdateUrl, payload);

      // debugPrint('✅ API Response: $response');

      // 5. Clear local draft on success
      await _storage.remove('draft_$appointmentId');
      await _storage.remove('draft_images_$appointmentId');

      // 6. Update telecalling status to 'Inspected'
      try {
        if (schedule != null) {
          // debugPrint('🔄 Updating telecalling status to Inspected (Re-Inspection)...');
          // debugPrint('🔑 telecallingId: ${schedule!.id}');

          final storage = GetStorage();
          final userId =
              storage.read('USER_ID')?.toString() ??
              storage.read('user_id')?.toString() ??
              '';
          final userRole =
              storage.read('USER_ROLE')?.toString() ?? 'Inspection Engineer';

          final statusBody = {
            'telecallingId': schedule!.id,
            'changedBy': userId,
            'source': userRole,
            'inspectionStatus': 'Inspected',
            'remarks': schedule!.remarks ?? '',
          };

          if (schedule!.inspectionDateTime != null) {
            statusBody['inspectionDateTime'] =
                schedule!.inspectionDateTime!.toIso8601String();
          }

          // debugPrint('📡 PUT ${ApiConstants.updateTelecallingUrl}');
          // debugPrint('📦 Body: $statusBody');

          final statusResponse = await ApiService.put(
            ApiConstants.updateTelecallingUrl,
            statusBody,
          );
          // debugPrint('✅ Telecalling status updated to Inspected: $statusResponse');

          // Refresh schedule list in background (non-blocking)
          try {
            if (Get.isRegistered<ScheduleController>()) {
              Get.find<ScheduleController>().refreshSchedules();
            }
          } catch (_) {}
        } else {
          // debugPrint('⚠️ schedule is null — cannot update telecalling status (Re-Inspection)');
        }
      } catch (e) {
        // debugPrint('⚠️ Failed to update telecalling status: $e');
        // Don't block success if this fails — the car update already succeeded
      }

      // 7. Show success dialog
      try {
        try {
          Get.closeAllSnackbars();
        } catch (e) {}
      } catch (_) {}
      _showSuccessDialog(
        response['message'] ?? 'Re-Inspection updated successfully!',
      );
    } catch (e) {
      // debugPrint('❌ Re-Inspection submit error: $e');
      try {
        try {
          Get.closeAllSnackbars();
        } catch (e) {}
      } catch (_) {}
      _showErrorDialog(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Premium Success Dialog ───
  void _showSuccessDialog(String message) {
    Get.dialog(
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 24,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated success icon ──
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00C853),
                        const Color(0xFF00E676),
                        const Color(0xFF69F0AE),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Decorative sparkles ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSparkle(8, const Color(0xFFFFD54F)),
                    const SizedBox(width: 6),
                    _buildSparkle(5, const Color(0xFF69F0AE)),
                    const SizedBox(width: 6),
                    _buildSparkle(10, const Color(0xFF42A5F5)),
                    const SizedBox(width: 6),
                    _buildSparkle(6, const Color(0xFFFF7043)),
                    const SizedBox(width: 6),
                    _buildSparkle(8, const Color(0xFFAB47BC)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Title ──
                const Text(
                  'Form Submitted\nSuccessfully! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A237E),
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Message ──
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Appointment reference ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6EFD).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0D6EFD).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 16,
                        color: const Color(0xFF0D6EFD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: $appointmentId',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D6EFD),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Gradient "Done" Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF0D6EFD)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0D6EFD,
                          ).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close dialog
                        Get.back(); // Navigate back to schedules
                        // Navigate completely back to dashboard
                        Get.offAll(() => const CoursesDashboard());

                        // Refresh schedule controller if it exists
                        try {
                          if (Get.isRegistered<ScheduleController>()) {
                            Get.find<ScheduleController>().fetchSchedules();
                          }
                        } catch (_) {}
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  // ─── Premium Error Dialog ───
  void _showErrorDialog(String message) {
    Get.dialog(
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 24,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Animated error icon ──
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFD32F2F),
                              Color(0xFFF44336),
                              Color(0xFFFF5252),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD32F2F,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Title ──
                      const Text(
                        'Submission Error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A237E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Error Message Box ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Error Details:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD32F2F),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _humanizeError(message),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Action Buttons ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A237E), Color(0xFF0D6EFD)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  /// Converts technical error messages into something more readable
  String _humanizeError(String error) {
    String clean = error;

    // Remove common technical prefixes
    final prefixes = [
      'Exception: ',
      'HttpException: ',
      'SocketException: ',
      'LateInitializationError: ',
      'TypeError: ',
      'HandshakeException: ',
      'ClientException: ',
    ];

    for (var prefix in prefixes) {
      if (clean.contains(prefix)) {
        clean = clean.replaceFirst(prefix, '');
      }
    }

    // Handle specific common scenarios
    if (clean.contains('is not a subtype of type')) {
      return 'Data processing error. Please contact support.';
    }
    if (clean.contains('Failed host lookup') ||
        clean.contains('Connection refused')) {
      return 'Network error. Please check your internet connection.';
    }
    if (clean.contains('404')) {
      return 'Server endpoint not found. Please update the app.';
    }
    if (clean.contains('401') || clean.contains('403')) {
      return 'Session expired. Please log in again.';
    }
    if (clean.contains('500')) {
      return 'Server error. Our team has been notified.';
    }
    if (clean.contains('Field \'_controller@')) {
      return 'UI Synchronization error. Please try again.';
    }

    return clean.trim();
  }

  /// Small decorative sparkle dot
  Widget _buildSparkle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    );
  }

  // ─── CarModel Mapping Helpers ───
  CarModel _buildCarModelFromForm(InspectionFormModel data) {
    return buildCarModelFromForm(
      data,
      Map<String, List<String>>.from(imageFiles),
      Map<String, Map<String, String>>.from(mediaCloudinaryData),
      appointmentId,
    );
  }

  void _printCarModelDebug(CarModel model) {
    printCarModelDebug(model);
  }

  // ─── Auto Fetch Vehicle Details ───
  Future<void> autoFetchVehicleDetails() async {
    final regNo = getFieldValue('registrationNumber').trim();
    if (regNo.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'Registration Missing',
        message: 'Please enter a vehicle registration number first.',
      );
      return;
    }

    // ── Simple & Direct UserId Retrieval ──
    final String userId = AuthenticationRepository.instance.userId;

    try {
      isFetchingDetails.value = true;

      // ── Step 1: Fetch vehicle registration details ──
      final response = await ApiService.post(
        ApiConstants.fetchVehicleDetailsUrl,
        {"vehicleRegistrationNumber": regNo, "userId": userId},
      );

      // Access data.result as specified
      final result = response['data']?['result'];
      if (result != null && result is Map<String, dynamic>) {
        _applyFetchedData(result);
      } else {
        throw 'No details found for this registration number.';
      }

      // ── Step 2: Fetch Make/Model/Variant from telecalling API ──
      await _fetchMakeModelVariantFromTelecalling();

      TLoaders.successSnackBar(
        title: 'Details Fetched',
        message: 'Vehicle information has been auto-filled.',
      );
    } catch (e) {
      // debugPrint('❌ AutoFetch Error: $e');
      TLoaders.customToast(message: e.toString());
    } finally {
      isFetchingDetails.value = false;
    }
  }

  /// Calls the telecalling API to find the record matching this appointmentId
  /// and autofills Make, Model, and Variant from that record.
  Future<void> _fetchMakeModelVariantFromTelecalling() async {
    try {
      final engineerNumber =
          GetStorage().read('INSPECTION_ENGINEER_NUMBER') ?? '9090909090';

      // Try all relevant statuses to find the matching appointment
      final statuses = ['Scheduled', 'Running', 'Re-Inspection', 'Re-Scheduled'];

      for (final status in statuses) {
        try {
          final response = await ApiService.post(
            ApiConstants.inspectionEngineerSchedulesUrl,
            {
              "inspectionStatus": status,
              "inspectionEngineerNumber": engineerNumber,
            },
          );

          final List<dynamic> dataList = response['data'] ?? [];
          for (final record in dataList) {
            if (record is Map<String, dynamic> &&
                record['appointmentId']?.toString() == appointmentId) {
              // Found the matching record — extract make/model/variant
              final make = record['make']?.toString().trim() ?? '';
              final model = record['model']?.toString().trim() ?? '';
              final variant = record['variant']?.toString().trim() ?? '';

              final data = inspectionData.value;
              if (data != null) {
                if (make.isNotEmpty) {
                  data.data['make'] = make;
                  data.make = make;
                  _userEditedKeys.add('make');
                }
                if (model.isNotEmpty) {
                  data.data['model'] = model;
                  data.model = model;
                  _userEditedKeys.add('model');
                }
                if (variant.isNotEmpty) {
                  data.data['variant'] = variant;
                  data.variant = variant;
                  _userEditedKeys.add('variant');
                }
                _syncScheduleWithChanges();
                inspectionData.refresh();
              }
              return; // Found and applied — stop searching
            }
          }
        } catch (_) {
          // Continue to next status if this one fails
        }
      }
    } catch (e) {
      // debugPrint('⚠️ Telecalling fetch for Make/Model/Variant failed: $e');
      // Non-critical: don't block the main flow
    }
  }

  void _applyFetchedData(Map<String, dynamic> result) {
    // Helper to find a value by checking multiple potential keys case-insensitively
    dynamic find(List<String> keys) {
      final searchKeys =
          keys
              .map(
                (k) => k.toLowerCase().replaceAll('_', '').replaceAll(' ', ''),
              )
              .toSet();

      for (final entry in result.entries) {
        final entryKey = entry.key
            .toLowerCase()
            .replaceAll('_', '')
            .replaceAll(' ', '');
        if (searchKeys.contains(entryKey) &&
            entry.value != null &&
            entry.value.toString().isNotEmpty) {
          return entry.value;
        }
      }
      return null;
    }

    /// Title-case helper: "ACTIVE" → "Active", "PETROL" → "Petrol"
    String titleCase(String s) {
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }

    /// Finds the best existing dropdown match for [value].
    /// Returns the matched option string if found, otherwise null.
    String? matchDropdownOption(String fieldKey, String value) {
      // 1. Check static field definition options
      for (final section in InspectionFieldDefs.sections) {
        for (final field in section.fields) {
          if (field.key == fieldKey && field.options.isNotEmpty) {
            // Try exact match first
            for (final opt in field.options) {
              if (opt.toLowerCase() == value.toLowerCase()) return opt;
            }
            return null;
          }
        }
      }
      return null;
    }

    final mapping = {
      'registrationDate': ['registered', 'registration_date', 'reg_date'],
      'fitnessValidity': ['fitnessUpto', 'fitness_upto', 'fitness_valid_upto'],
      'engineNumber': ['engineNumber', 'engine_number', 'engineNo'],
      'chassisNumber': ['chassisNumber', 'chassis_number', 'chassisNo'],
      'yearMonthOfManufacture': [
        'manufactured',
        'manufacturing_date',
        'mfgDate',
      ],
      'seatingCapacity': ['seatingCapacity', 'seating_capacity', 'seat_cap'],
      'color': ['colorType', 'color', 'colour'],
      'cubicCapacity': ['cubicCapacity', 'cubic_capacity', 'cc'],
      'norms': ['normsType', 'norms', 'pollution_norms'],
      'registeredRto': ['rto', 'registered_rto', 'rto_name'],
      'ownerSerialNumber': [
        'ownerNumber',
        'owner_serial_number',
        'owner_count',
      ],
      'registeredOwner': ['owner', 'owner_name', 'registered_owner'],
      'registeredAddressAsPerRc': [
        'currentAddress',
        'permanent_address',
        'address',
      ],
      'insuranceValidity': ['insuranceUpto', 'insurance_valid_upto'],
      'insurer': ['insuranceProvider', 'insurance_company', 'insurer_name'],
      'insurancePolicyNumber': [
        'insurancePolicyNumber',
        'policy_no',
        'policyNumber',
      ],
      'pucValidity': ['pollutionCertificateUpto', 'puc_upto', 'puc_validity'],
      'pucNumber': ['pollutionCertificateNumber', 'puc_number', 'pucNo'],
      'blacklistStatus': [
        'blacklistStatus',
        'is_blacklisted',
        'blacklist_details',
      ],
      'city': ['city', 'city_name'],
      'taxValidTill': ['taxUpto', 'tax_validity', 'tax_paid_upto', 'tax_upto'],
    };

    bool updatedAny = false;
    mapping.forEach((targetKey, sourceKeys) {
      final value = find(sourceKeys);
      if (value != null) {
        updateField(targetKey, value.toString());
        updatedAny = true;
      }
    });

    // ── 1. Registration State: Extract from rto value ──
    // e.g. "PVD KOLKATA, West Bengal" → "West Bengal"
    final rtoValue = find(['rto', 'registered_rto', 'rto_name']);
    if (rtoValue != null) {
      final rtoStr = rtoValue.toString();
      // Set full RTO value
      updateField('registeredRto', rtoStr);
      updatedAny = true;

      // Extract state: everything after the last comma
      if (rtoStr.contains(',')) {
        final state = rtoStr.split(',').last.trim();
        if (state.isNotEmpty) {
          updateField('registrationState', state);
        }
      }
    }

    // ── 2. Fuel Type: Convert to Title Case and match dropdown option ──
    final rawFuel = find(['fuelType', 'fuel_type', 'fuel']);
    if (rawFuel != null) {
      final fuelStr = rawFuel.toString().trim();
      final formattedFuel = titleCase(fuelStr);

      // Check if an exact match exists in the dropdown options
      final matched = matchDropdownOption('fuelType', formattedFuel);
      if (matched != null) {
        updateField('fuelType', matched);
      } else {
        // If no match, add it temporarily to the dropdown options
        final existingOptions = dropdownOptions['fuelType'] ?? [
          'Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid', 'LPG',
        ];
        if (!existingOptions.any((o) => o.toLowerCase() == formattedFuel.toLowerCase())) {
          dropdownOptions['fuelType'] = [...existingOptions, formattedFuel];
        }
        updateField('fuelType', formattedFuel);
      }
      updatedAny = true;
    }

    // ── 3. RC Status: Convert to Title Case and match dropdown ──
    final rawStatus = find(['status', 'rc_status', 'status_as_on']);
    if (rawStatus != null) {
      final statusStr = rawStatus.toString().trim();
      final formattedStatus = titleCase(statusStr);

      // Check if an exact match exists in the dropdown options
      final matched = matchDropdownOption('rcStatus', formattedStatus);
      if (matched != null) {
        updateField('rcStatus', matched);
      } else {
        // If no match, add it temporarily to the dropdown options
        final existingOptions = dropdownOptions['rcStatus'] ?? [
          'Active', 'Inactive', 'Suspended',
        ];
        if (!existingOptions.any((o) => o.toLowerCase() == formattedStatus.toLowerCase())) {
          dropdownOptions['rcStatus'] = [...existingOptions, formattedStatus];
        }
        updateField('rcStatus', formattedStatus);
      }
      updatedAny = true;
    }

    // ── 4. Make / Model / Variant: Use API values first, then schedule as fallback ──
    final rawMake = find(['make', 'maker', 'maker_name']);
    final rawModel = find(['model', 'maker_model']);
    final rawVariant = find(['variant', 'series']);

    final makeVal = rawMake?.toString().trim() ?? '';
    final modelVal = rawModel?.toString().trim() ?? '';
    final variantVal = rawVariant?.toString().trim() ?? '';

    // Use API values; if empty, fall back to schedule data
    final finalMake = makeVal.isNotEmpty ? makeVal : (schedule?.make ?? '');
    final finalModel = modelVal.isNotEmpty ? modelVal : (schedule?.model ?? '');
    final finalVariant = variantVal.isNotEmpty ? variantVal : (schedule?.variant ?? '');

    if (finalMake.isNotEmpty) {
      // Set make first (without clearing model/variant via updateField),
      // then model, then variant — in order.
      final data = inspectionData.value;
      if (data != null) {
        data.data['make'] = finalMake;
        data.make = finalMake;
        _userEditedKeys.add('make');

        if (finalModel.isNotEmpty) {
          data.data['model'] = finalModel;
          data.model = finalModel;
          _userEditedKeys.add('model');
        }

        if (finalVariant.isNotEmpty) {
          data.data['variant'] = finalVariant;
          data.variant = finalVariant;
          _userEditedKeys.add('variant');
        }

        _syncScheduleWithChanges();
        updatedAny = true;
      }
    }

    if (updatedAny) {
      inspectionData.refresh();
    }
  }

  // ─── Searchable Dropdowns (Make, Model, Variant) ───
  Future<List<String>> searchMakes(String query) async {
    try {
      final response = await ApiService.post(ApiConstants.searchCarMakesUrl, {
        "q": query,
        "limit": "30",
      });
      if (response['data'] is List) {
        return (response['data'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Search Makes Error: $e');
      return [];
    }
  }

  Future<List<String>> searchModels(String query) async {
    final make = getFieldValue('make');
    if (make.isEmpty) return [];
    try {
      final response = await ApiService.post(ApiConstants.searchCarModelsUrl, {
        "make": make,
        "q": query,
        "limit": "30",
      });
      if (response['data'] is List) {
        return (response['data'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Search Models Error: $e');
      return [];
    }
  }

  Future<List<String>> searchVariants(String query) async {
    final make = getFieldValue('make');
    final model = getFieldValue('model');
    if (make.isEmpty || model.isEmpty) return [];
    try {
      final response = await ApiService.post(
        ApiConstants.searchCarVariantsUrl,
        {"make": make, "model": model, "q": query, "limit": "30"},
      );
      if (response['data'] is List) {
        return (response['data'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Search Variants Error: $e');
      return [];
    }
  }
}
