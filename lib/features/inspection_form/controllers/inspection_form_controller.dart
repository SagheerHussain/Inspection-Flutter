import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/services/api/api_service.dart';
import '../../../data/services/offline/offline_sync_service.dart';
import '../../../data/services/offline/inspection_offload_service.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/popups/exports.dart';
import '../models/inspection_field_defs.dart';
import '../models/inspection_form_model.dart';
import '../models/car_model.dart';
import '../helpers/car_model_mapper.dart';
import '../helpers/car_model_debug_printer.dart';
import '../../schedules/models/schedule_model.dart';
import '../../dashboard/course/screens/dashboard/coursesDashboard.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../schedules/controllers/schedule_controller.dart';
import '../../../data/repository/authentication_repository/authentication_repository.dart';
import '../screens/image_editor_screen.dart';

class InspectionFormController extends GetxController {
  final String appointmentId;
  final ScheduleModel? schedule;

  InspectionFormController({required this.appointmentId, this.schedule});

  final Rxn<InspectionFormModel> inspectionData = Rxn<InspectionFormModel>();
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final isSaving = false.obs;
  final isFetchingDetails = false.obs;

  /// Fields that were auto-filled from the fetch API and should be non-editable
  final RxSet<String> apiFetchedLockedFields = <String>{}.obs;

  // ── Re-Inspection state ──

  /// True specifically when the lead is a Re-Inspection report (not just a draft).
  /// This controls the "Re-Inspection Preview" dialog on submission.
  bool get isReInspection {
    final s =
        schedule?.inspectionStatus.toLowerCase().replaceAll('-', '') ?? '';
    final isReStatus = (s == 'reinspected' || s == 'reinspection');

    // Check source field for re-inspection keywords
    final source = schedule?.appointmentSource.toLowerCase() ?? '';
    final isReSource =
        source.contains('re-inspected') || source.contains('re-inspection');

    return isReStatus || isReSource;
  }

  /// Stores the original data snapshot fetched from the API for Re-Inspection
  /// (used for the preview dialog diff)
  Map<String, dynamic> _originalData = {};

  /// The carId (_id) from the car details API response for Re-Inspection update
  String? _reInspectionCarId;
  String _appVersion = 'Unknown';

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

  /// Shorthand for the global offline sync service
  OfflineSyncService get _syncService => OfflineSyncService.instance;

  // ── User-edited field tracking ──
  // Tracks which field keys the user has explicitly changed during this session.
  final Set<String> _userEditedKeys = {};

  /// Local snapshot storage key — full form data cached after first API call.
  /// Once this exists, the API is NEVER called again for this appointment.
  String get _snapshotKey => 'snapshot_$appointmentId';
  String get _snapshotImagesKey => 'snapshot_images_$appointmentId';
  String get _snapshotLockedFieldsKey => 'snapshot_locked_$appointmentId';
  String get _snapshotOriginalDataKey => 'snapshot_original_$appointmentId';
  String get _snapshotCarIdKey => 'snapshot_carid_$appointmentId';
  String get _snapshotCloudinaryKey => 'snapshot_cloudinary_$appointmentId';
  String get _snapshotDeletionsKey => 'snapshot_deletions_$appointmentId';
  String get _snapshotDropdownsKey => 'snapshot_dropdowns_$appointmentId';

  // Image storage: key → list of local file paths
  final RxMap<String, List<String>> imageFiles = <String, List<String>>{}.obs;

  // Cloudinary storage: localPath → {url, publicId}
  final RxMap<String, Map<String, String>> mediaCloudinaryData =
      <String, Map<String, String>>{}.obs;

  // ─── Internal Media Tracking ───
  // Tracks paths currently in flight to avoid redundant parallel uploads
  final Set<String> _currentlyUploading = {};
  // NEW: Offline Deletion Queue (PublicID + Metadata)
  final RxList<Map<String, dynamic>> pendingDeletions =
      <Map<String, dynamic>>[].obs;

  // Subscription to monitor connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
    'driverAirbagImages',
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
    // ── Sequential Initialization to prevent race conditions ──
    _initializeFlow();

    // Listen for internet restoration to automatically retry pending uploads
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (hasInternet) {

        retryPendingDeletions(); // NEW: Also retry any offline deletions
      }
    });
  }

  Future<void> _initializeFlow() async {
    await _fetchVersion();
    await fetchDropdownList();
    await fetchInspectionData();
  }

  Future<void> _fetchVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('⚠️ Failed to fetch app version: $e');
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchInspectionData() async {
    debugPrint('🚀 Starting fetchInspectionData for $appointmentId');
    isLoading.value = true;
    try {
      // ── STEP 1: ALWAYS CHECK FOR LOCAL DRAFT FIRST (EXCEPT RE-INSPECTION) ──
      final snapshot = _storage.read(_snapshotKey);
      final user = UserController.instance.user.value;

      // Logic: Use draft only if NOT in Re-Inspection mode.
      // For Re-Inspection, we always want to fetch previous data from the API first.
      if (snapshot != null && snapshot is Map && !isReInspection) {
        debugPrint('📂 Found local draft for $appointmentId');
        final cachedId =
            snapshot['_id']?.toString() ?? snapshot['id']?.toString();
        if (cachedId != null && cachedId.isNotEmpty) {
          _reInspectionCarId = cachedId;
        }

        inspectionData.value = InspectionFormModel.fromJson(
          Map<String, dynamic>.from(snapshot),
        );

        final restoredKeys = inspectionData.value?.data.keys.toList() ?? [];
        debugPrint(
          '✅ [Draft] Restore complete: ${restoredKeys.length} keys found.',
        );
        debugPrint(
          '   📍 Restored Data snippet: ${inspectionData.value?.data.entries.take(10).map((e) => "${e.key}: ${e.value}")}',
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

        // Restore Cloudinary Metadata
        final savedCloudinaryData = _storage.read(_snapshotCloudinaryKey);
        if (savedCloudinaryData != null && savedCloudinaryData is Map) {
          _restoreCloudinaryData(savedCloudinaryData);
        }

        // Restore Pending Deletions
        final savedDeletions = _storage.read(_snapshotDeletionsKey);
        if (savedDeletions != null && savedDeletions is List) {
          pendingDeletions.assignAll(
            savedDeletions.cast<Map<String, dynamic>>(),
          );
        }

        // Restore Dropdown Options
        final savedDropdowns = _storage.read(_snapshotDropdownsKey);
        if (savedDropdowns != null && savedDropdowns is Map) {
          for (final entry in savedDropdowns.entries) {
            final list = entry.value;
            if (list is List) {
              dropdownOptions[entry.key.toString()] = list.cast<String>();
            }
          }
        }

        inspectionData.refresh();

        TLoaders.successSnackBar(
          title: 'Draft Loaded',
          message: 'Continuing from your saved progress.',
        );

        final savedLockedFields = _storage.read(_snapshotLockedFieldsKey);
        if (savedLockedFields != null && savedLockedFields is List) {
          apiFetchedLockedFields.assignAll(savedLockedFields.cast<String>());
        }

        // Wait a tiny bit for UI widgets to mount before syncing schedule
        Future.delayed(const Duration(milliseconds: 300), () {
          _syncScheduleWithChanges();
          _refreshSyncState(); // Update progress bar from restored snapshot
        });

        isLoading.value = false;
        return;
      }

      // ── STEP 2: NO DRAFT FOUND — PROCEED WITH DATA FETCHING ──

      // ── RE-INSPECTION & SUPERADMIN EDIT FLOW ──
      // API data takes priority ONLY if no local draft exists.
      if (isReInspection || user.id == 'superadmin') {
        try {
          final response = await ApiService.get(
            ApiConstants.carDetailsUrl(appointmentId),
          );

          final carData = response['carDetails'];
          if (carData != null && carData is Map<String, dynamic>) {
            _reInspectionCarId = carData['_id']?.toString();
            _originalData = Map<String, dynamic>.from(carData);
            _normalizeCarDataToFormKeys(carData);
            inspectionData.value = InspectionFormModel.fromJson(carData);
            _preFillMedia(carData);
            await _saveSnapshot();

            TLoaders.successSnackBar(
              title: 'Re-Inspection Data Loaded',
              message:
                  'Previous inspection data pre-filled. Update fields as needed.',
            );
            _syncScheduleWithChanges();
            isLoading.value = false;
            return;
          }
        } catch (e) {
          debugPrint('⚠️ API fetch failed: $e');
        }

        // No API data and no cache — start fresh
        _initializeNewInspection();
        isLoading.value = false;
        return;
      }

      // ── RUNNING LEADS & STANDARD FLOW ──
      // Logic for leads without Re-Inspection status:
      // Since we already checked for local drafts at Step 1, we only
      // initialize a new inspection here if no draft was found.

      _initializeNewInspection();

      /*
      // ── API FETCH DISABLED AS PER USER REQUEST ──
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

          TLoaders.successSnackBar(
            title: 'Data Loaded',
            message: 'Existing inspection data loaded from server.',
          );
          _syncScheduleWithChanges();
          isLoading.value = false;
          return;
        }
      } catch (e) {
        // debugPrint('⚠️ Car details fetch failed: $e — falling back to new form');
      }
      */

      // No car record found or API skipped — initialize empty form
      _initializeNewInspection();
    } catch (e) {
      // debugPrint('Fetch failed, initializing new: $e');
      _initializeNewInspection();
    } finally {
      isLoading.value = false;
    }
  }

  /// Reverse-maps API/CarModel JSON keys → Form field keys.
  /// The API response uses legacy keys (e.g. 'rcTaxToken', 'lhsFront45Degree')
  /// while the form uses renamed keys (e.g. 'rcTokenImages', 'lhsFullViewImages').
  /// This method copies values so InspectionFormModel.fromJson() can find them.
  void _normalizeCarDataToFormKeys(Map<String, dynamic> carData) {
    // ── Text/Dropdown field mappings: apiKey → formKey ──
    final Map<String, String> textMappings = {
      // Identity / RC
      'inspectionCity': 'city',
      'ieName': 'emailAddress',
      'fitnessValidity': 'fitnessTill',
      'yearAndMonthOfManufacture': 'yearMonthOfManufacture',
      'policyNumber': 'insurancePolicyNumber',
      // Exterior dropdowns
      'bonnetDropdownList': 'bonnet',
      'frontWindshieldDropdownList': 'frontWindshield',
      'roofDropdownList': 'roof',
      'frontBumperDropdownList': 'frontBumper',
      'lhsHeadlampDropdownList': 'lhsHeadlamp',
      'lhsFoglampDropdownList': 'lhsFoglamp',
      'rhsHeadlampDropdownList': 'rhsHeadlamp',
      'rhsFoglampDropdownList': 'rhsFoglamp',
      'lhsFenderDropdownList': 'lhsFender',
      'lhsOrvmDropdownList': 'lhsOrvm',
      'lhsAPillarDropdownList': 'lhsAPillar',
      'lhsBPillarDropdownList': 'lhsBPillar',
      'lhsCPillarDropdownList': 'lhsCPillar',
      'lhsFrontWheelDropdownList': 'lhsFrontAlloy',
      'lhsFrontTyreDropdownList': 'lhsFrontTyre',
      'lhsRearWheelDropdownList': 'lhsRearAlloy',
      'lhsRearTyreDropdownList': 'lhsRearTyre',
      'lhsFrontDoorDropdownList': 'lhsFrontDoor',
      'lhsRearDoorDropdownList': 'lhsRearDoor',
      'lhsRunningBorderDropdownList': 'lhsRunningBorder',
      'lhsQuarterPanelDropdownList': 'lhsQuarterPanel',
      'rearBumperDropdownList': 'rearBumper',
      'lhsTailLampDropdownList': 'lhsTailLamp',
      'rhsTailLampDropdownList': 'rhsTailLamp',
      'rearWindshieldDropdownList': 'rearWindshield',
      'bootDoorDropdownList': 'bootDoor',
      'spareTyreDropdownList': 'spareTyre',
      'bootFloorDropdownList': 'bootFloor',
      'rhsRearWheelDropdownList': 'rhsRearAlloy',
      'rhsRearTyreDropdownList': 'rhsRearTyre',
      'rhsFrontWheelDropdownList': 'rhsFrontAlloy',
      'rhsFrontTyreDropdownList': 'rhsFrontTyre',
      'rhsQuarterPanelDropdownList': 'rhsQuarterPanel',
      'rhsAPillarDropdownList': 'rhsAPillar',
      'rhsBPillarDropdownList': 'rhsBPillar',
      'rhsCPillarDropdownList': 'rhsCPillar',
      'rhsRunningBorderDropdownList': 'rhsRunningBorder',
      'rhsRearDoorDropdownList': 'rhsRearDoor',
      'rhsFrontDoorDropdownList': 'rhsFrontDoor',
      'rhsOrvmDropdownList': 'rhsOrvm',
      'rhsFenderDropdownList': 'rhsFender',
      'commentsOnExteriorDropdownList': 'comments',
      // Engine / Mechanical
      'upperCrossMemberDropdownList': 'upperCrossMember',
      'radiatorSupportDropdownList': 'radiatorSupport',
      'headlightSupportDropdownList': 'headlightSupport',
      'lowerCrossMemberDropdownList': 'lowerCrossMember',
      'lhsApronDropdownList': 'lhsApron',
      'rhsApronDropdownList': 'rhsApron',
      'firewallDropdownList': 'firewall',
      'cowlTopDropdownList': 'cowlTop',
      'engineDropdownList': 'engine',
      'batteryDropdownList': 'battery',
      'coolantDropdownList': 'coolant',
      'engineOilLevelDipstickDropdownList': 'engineOilLevelDipstick',
      'engineOilDropdownList': 'engineOil',
      'engineMountDropdownList': 'engineMount',
      'enginePermisableBlowByDropdownList': 'enginePermisableBlowBy',
      'exhaustSmokeDropdownList': 'exhaustSmoke',
      'clutchDropdownList': 'clutch',
      'gearShiftDropdownList': 'gearShift',
      'commentsOnEngineDropdownList': 'commentsOnEngine',
      'commentsOnEngineOilDropdownList': 'commentsOnEngineOil',
      'commentsOnTowingDropdownList': 'commentsOnTowing',
      'commentsOnTransmissionDropdownList': 'commentsOnTransmission',
      'commentsOnRadiatorDropdownList': 'commentsOnRadiator',
      'commentsOnOthersDropdownList': 'commentsOnOthers',
      // Interior / Electricals
      'steeringDropdownList': 'steering',
      'brakesDropdownList': 'brakes',
      'suspensionDropdownList': 'suspension',
      'odometerReadingBeforeTestDrive': 'odometerReadingInKms',
      'rearWiperWasherDropdownList': 'rearWiperWasher',
      'rearDefoggerDropdownList': 'rearDefogger',
      'infotainmentSystemDropdownList': 'infotainmentSystem',
      'rhsFrontDoorFeaturesDropdownList': 'powerWindowConditionRhsFront',
      'lhsFrontDoorFeaturesDropdownList': 'powerWindowConditionLhsFront',
      'rhsRearDoorFeaturesDropdownList': 'powerWindowConditionRhsRear',
      'lhsRearDoorFeaturesDropdownList': 'powerWindowConditionLhsRear',
      'commentOnInteriorDropdownList': 'commentOnInterior',
      'sunroofDropdownList': 'sunroof',
      'reverseCameraDropdownList': 'reverseCamera',
      'acTypeDropdownList': 'acType',
      'acCoolingDropdownList': 'acCooling',
      // Airbag renamed fields
      'driverAirbag': 'airbagFeaturesDriverSide',
      'coDriverAirbag': 'airbagFeaturesCoDriverSide',
      'coDriverSeatAirbag': 'airbagFeaturesLhsAPillarCurtain',
      'lhsCurtainAirbag': 'airbagFeaturesLhsBPillarCurtain',
      'lhsRearSideAirbag': 'airbagFeaturesLhsCPillarCurtain',
      'driverSeatAirbag': 'airbagFeaturesRhsAPillarCurtain',
      'rhsCurtainAirbag': 'airbagFeaturesRhsBPillarCurtain',
      'rhsRearSideAirbag': 'airbagFeaturesRhsCPillarCurtain',
      // Additional new fields
      'rcBookAvailabilityDropdownList': 'rcBookAvailability',
      'mismatchInRcDropdownList': 'mismatchInRc',
      'insuranceDropdownList': 'insurance',
      'mismatchInInsuranceDropdownList': 'mismatchInInsurance',
      'additionalDetailsDropdownList': 'additionalDetails',
      'frontWiperAndWasherDropdownList': 'frontWiperAndWasher',
      'lhsRearFogLampDropdownList': 'lhsRearFogLamp',
      'rhsRearFogLampDropdownList': 'rhsRearFogLamp',
      'spareWheelDropdownList': 'spareWheel',
      'lhsSideMemberDropdownList': 'lhsSideMember',
      'rhsSideMemberDropdownList': 'rhsSideMember',
      'transmissionTypeDropdownList': 'transmissionType',
      'driveTrainDropdownList': 'driveTrain',
      'commentsOnClusterMeterDropdownList': 'commentsOnClusterMeter',
      'dashboardDropdownList': 'dashboard',
      'driverSeatDropdownList': 'driverSeat',
      'coDriverSeatDropdownList': 'coDriverSeat',
      'frontCentreArmRestDropdownList': 'frontCentreArmRest',
      'rearSeatsDropdownList': 'rearSeats',
      'thirdRowSeatsDropdownList': 'thirdRowSeats',
      'noOfAirBags': 'noOfAirBags', // Ensure Airbag count pre-fills
    };

    // For each mapping: if the API key exists in carData but the form key
    // does NOT, copy the value over. If both exist, prefer what's already there
    // (the API key) but also set the form key so getFieldValue finds it.
    void copyIfPresent(String apiKey, String formKey) {
      final apiVal = carData[apiKey];
      if (apiVal == null) return;
      // For List values from DropdownList fields, join into comma-separated string
      if (apiVal is List && apiVal.isNotEmpty) {
        carData[formKey] = apiVal.join(', ');
      } else if (carData[formKey] == null ||
          carData[formKey].toString().isEmpty) {
        carData[formKey] = apiVal;
      }
    }

    // Apply all text/dropdown mappings (both directions)
    textMappings.forEach((apiKey, formKey) {
      copyIfPresent(apiKey, formKey);
      // Also reverse: if API response has the formKey value, ensure the
      // form can also find it under the apiKey (for DropdownList storage)
      if (carData[formKey] != null && carData[apiKey] == null) {
        carData[apiKey] = carData[formKey];
      }
    });

    // ── Merged/Split field handling ──
    // seatsUpholstery ← leatherSeats/fabricSeats
    if (carData['seatsUpholstery'] == null ||
        carData['seatsUpholstery'].toString().isEmpty) {
      if (carData['leatherSeats']?.toString().toLowerCase() == 'yes') {
        carData['seatsUpholstery'] = 'Leather';
      } else if (carData['fabricSeats']?.toString().toLowerCase() == 'yes') {
        carData['seatsUpholstery'] = 'Fabric';
      }
    }

    // steeringMountedMediaControls / steeringMountedSystemControls ← steeringMountedAudioControl
    if (carData['steeringMountedMediaControls'] == null ||
        carData['steeringMountedMediaControls'].toString().isEmpty) {
      carData['steeringMountedMediaControls'] =
          carData['steeringMountedAudioControl'] ?? '';
    }
    if (carData['steeringMountedSystemControls'] == null ||
        carData['steeringMountedSystemControls'].toString().isEmpty) {
      carData['steeringMountedSystemControls'] =
          carData['steeringMountedAudioControl'] ?? '';
    }

    // musicSystem → infotainmentSystem
    if (carData['infotainmentSystem'] == null ||
        carData['infotainmentSystem'].toString().isEmpty) {
      carData['infotainmentSystem'] = carData['musicSystem'] ?? '';
    }

    debugPrint('✅ _normalizeCarDataToFormKeys completed for Re-Inspection');
  }

  /// Pre-fills the imageFiles reactive map with remote URLs from the API response.
  /// This allows the form to display previously uploaded images for Re-Inspection.
  void _preFillMedia(Map<String, dynamic> carData) {
    // ── Image field mappings: API key → form key ──
    // The API stores images under legacy keys; the form expects new keys.
    // ── Image field mappings: API key → form key ──
    // The API stores images under legacy keys; the form expects new keys.
    final Map<String, String> imageMappings = {
      'rcTaxToken': 'rcTokenImages',
      'insuranceCopy': 'insuranceImages',
      'bothKeys': 'duplicateKeyImages',
      'form26GdCopyIfRcIsLost': 'form26AndGdCopyIfRcIsLostImages',
      'frontMain': 'frontMainImages',
      'lhsFront45Degree': 'lhsFullViewImages',
      'lhsFrontAlloyImages': 'lhsFrontWheelImages',
      'lhsRearAlloyImages': 'lhsRearWheelImages',
      'rearMain': 'rearMainImages',
      'rhsRear45Degree': 'rhsFullViewImages',
      'rhsRearAlloyImages': 'rhsRearWheelImages',
      'rhsFrontAlloyImages': 'rhsFrontWheelImages',
      'engineBay': 'engineBayImages',
      'additionalImages': 'additionalImages',
      'engineSound': 'engineVideo',
      'exhaustSmokeImages': 'exhaustSmokeVideo',
      'meterConsoleWithEngineOn': 'meterConsoleWithEngineOnImages', // Legacy mapping
      'frontSeatsFromDriverSideDoorOpen': 'frontSeatsFromDriverSideImages',
      'rearSeatsFromRightSideDoorOpen': 'rearSeatsFromRightSideImages',
      'dashboardFromRearSeat': 'dashboardImages',
      'additionalImages2': 'additionalInteriorImages',
      'bootdoorimages': 'bootDoorImages',
    };

    // ── Direct image keys (same key in API and form or newer API versions) ──
    final List<String> directImageKeys = [
      'rcTokenImages',
      'duplicateKeyImages',
      'frontMainImages',
      'frontBumperImages',
      'lhsFullViewImages',
      'lhsFrontWheelImages',
      'lhsRearWheelImages',
      'rearMainImages',
      'bootDoorOpenImages',
      'bootDoorClosedImages',
      'rhsFullViewImages',
      'rhsRearWheelImages',
      'rhsFrontWheelImages',
      'engineBayImages',
      'engineVideo',
      'exhaustSmokeVideo',
      'frontSeatsFromDriverSideImages',
      'rearSeatsFromRightSideImages',
      'dashboardImages',
      'frontWindshieldImages',
      'roofImages',
      'lhsHeadlampImages',
      'lhsFoglampImages',
      'rhsHeadlampImages',
      'rhsFoglampImages',
      'lhsFenderImages',
      'lhsFrontTyreImages',
      'lhsRunningBorderImages',
      'lhsOrvmImages',
      'lhsAPillarImages',
      'lhsFrontDoorImages',
      'lhsBPillarImages',
      'lhsRearDoorImages',
      'lhsCPillarImages',
      'lhsRearTyreImages',
      'spareTyreImages',
      'bootFloorImages',
      'rhsCPillarImages',
      'rhsRearDoorImages',
      'rhsBPillarImages',
      'rhsFrontDoorImages',
      'rhsAPillarImages',
      'rhsRunningBorderImages',
      'rhsFrontTyreImages',
      'rhsRearTyreImages',
      'rhsOrvmImages',
      'rhsFenderImages',
      'batteryImages',
      'sunroofImages',
      'lhsTailLampImages',
      'rhsTailLampImages',
      'rearWindshieldImages',
      'chassisEmbossmentImages',
      'vinPlateImages',
      'roadTaxImages',
      'pucImages',
      'rtoNocImages',
      'rtoForm28Images',
      'frontWiperAndWasherImages',
      'lhsRearFogLampImages',
      'rhsRearFogLampImages',
      'rearWiperAndWasherImages',
      'spareWheelImages',
      'cowlTopImages',
      'firewallImages',
      'acImages',
      'reverseCameraImages',
      'odometerReadingAfterTestDriveImages',
      'bootDoorImages',
      'meterConsoleWithEngineOnImages',
    ];

    // Helper to extract URL list from a value
    List<String> extractUrls(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value
            .map((e) => e.toString())
            .where((url) => url.startsWith('http'))
            .toList();
      }
      if (value is String && value.startsWith('http')) return [value];
      return [];
    }

    // 1. Process mapped image keys
    imageMappings.forEach((apiKey, formKey) {
      final urls = extractUrls(carData[apiKey]);
      if (urls.isNotEmpty) {
        imageFiles[formKey] = urls;
        carData[formKey] = urls; // also put in form data for consistency
      }
    });

    // 2. Process direct image keys
    for (final key in directImageKeys) {
      final urls = extractUrls(carData[key]);
      if (urls.isNotEmpty) {
        imageFiles[key] = urls;
      }
    }

    // 3. Handle split image fields
    // bonnetImages → bonnetClosedImages + bonnetOpenImages
    final bonnetImgs = extractUrls(carData['bonnetImages']);
    if (bonnetImgs.isNotEmpty) {
      // First half → bonnetClosedImages, second half → bonnetOpenImages
      final mid = (bonnetImgs.length / 2).ceil();
      imageFiles['bonnetClosedImages'] = bonnetImgs.sublist(0, mid);
      if (bonnetImgs.length > mid) {
        imageFiles['bonnetOpenImages'] = bonnetImgs.sublist(mid);
      }
    }
    // Also check direct new-API keys
    final bonnetClosed = extractUrls(carData['bonnetClosedImages']);
    if (bonnetClosed.isNotEmpty)
      imageFiles['bonnetClosedImages'] = bonnetClosed;
    final bonnetOpen = extractUrls(carData['bonnetOpenImages']);
    if (bonnetOpen.isNotEmpty) imageFiles['bonnetOpenImages'] = bonnetOpen;

    // frontBumperImages → frontBumperLhs45DegreeImages + frontBumperRhs45DegreeImages + frontBumperImages
    final fbLhs45 = extractUrls(carData['frontBumperLhs45DegreeImages']);
    if (fbLhs45.isNotEmpty)
      imageFiles['frontBumperLhs45DegreeImages'] = fbLhs45;
    final fbRhs45 = extractUrls(carData['frontBumperRhs45DegreeImages']);
    if (fbRhs45.isNotEmpty)
      imageFiles['frontBumperRhs45DegreeImages'] = fbRhs45;
    final fbMain = extractUrls(carData['frontBumperImages']);
    if (fbMain.isNotEmpty &&
        imageFiles['frontBumperLhs45DegreeImages'] == null) {
      imageFiles['frontBumperImages'] = fbMain;
    }

    // rearBumperImages → rearBumperLhs45DegreeImages + rearBumperRhs45DegreeImages + rearBumperImages
    final rbLhs45 = extractUrls(carData['rearBumperLhs45DegreeImages']);
    if (rbLhs45.isNotEmpty) imageFiles['rearBumperLhs45DegreeImages'] = rbLhs45;
    final rbRhs45 = extractUrls(carData['rearBumperRhs45DegreeImages']);
    if (rbRhs45.isNotEmpty) imageFiles['rearBumperRhs45DegreeImages'] = rbRhs45;
    // Always populate the main rearBumperImages from DB if available
    final rbMain = extractUrls(carData['rearBumperImages']);
    if (rbMain.isNotEmpty) {
      imageFiles['rearBumperImages'] = rbMain;
    }

    // lhsQuarterPanelImages → index 0: Open, index 1: Closed
    final rawLhsQP = carData['lhsQuarterPanelImages'];
    final List<String> lhsQPUrls = (rawLhsQP is List)
        ? rawLhsQP.map((e) => e?.toString() ?? '').toList()
        : [];
    if (lhsQPUrls.isNotEmpty && lhsQPUrls[0].isNotEmpty && lhsQPUrls[0].startsWith('http')) {
      imageFiles['lhsQuarterPanelWithRearDoorOpenImages'] = [lhsQPUrls[0]];
    }
    if (lhsQPUrls.length > 1 && lhsQPUrls[1].isNotEmpty && lhsQPUrls[1].startsWith('http')) {
      imageFiles['lhsQuarterPanelWithRearDoorClosedImages'] = [lhsQPUrls[1]];
    }
    // Fallback if backend returned explicit flat keys
    final fallBackLhsOpen = extractUrls(carData['lhsQuarterPanelWithRearDoorOpenImages']);
    if (fallBackLhsOpen.isNotEmpty) imageFiles['lhsQuarterPanelWithRearDoorOpenImages'] = fallBackLhsOpen;
    final fallBackLhsClosed = extractUrls(carData['lhsQuarterPanelWithRearDoorClosedImages']);
    if (fallBackLhsClosed.isNotEmpty) imageFiles['lhsQuarterPanelWithRearDoorClosedImages'] = fallBackLhsClosed;

    // rhsQuarterPanelImages → index 0: Open, index 1: Closed
    final rawRhsQP = carData['rhsQuarterPanelImages'];
    final List<String> rhsQPUrls = (rawRhsQP is List)
        ? rawRhsQP.map((e) => e?.toString() ?? '').toList()
        : [];
    if (rhsQPUrls.isNotEmpty && rhsQPUrls[0].isNotEmpty && rhsQPUrls[0].startsWith('http')) {
      imageFiles['rhsQuarterPanelWithRearDoorOpenImages'] = [rhsQPUrls[0]];
    }
    if (rhsQPUrls.length > 1 && rhsQPUrls[1].isNotEmpty && rhsQPUrls[1].startsWith('http')) {
      imageFiles['rhsQuarterPanelWithRearDoorClosedImages'] = [rhsQPUrls[1]];
    }
    // Fallback if backend returned explicit flat keys
    final fallBackRhsOpen = extractUrls(carData['rhsQuarterPanelWithRearDoorOpenImages']);
    if (fallBackRhsOpen.isNotEmpty) imageFiles['rhsQuarterPanelWithRearDoorOpenImages'] = fallBackRhsOpen;
    final fallBackRhsClosed = extractUrls(carData['rhsQuarterPanelWithRearDoorClosedImages']);
    if (fallBackRhsClosed.isNotEmpty) imageFiles['rhsQuarterPanelWithRearDoorClosedImages'] = fallBackRhsClosed;


    // apronLhsRhs → lhsApronImages + rhsApronImages
    final apronAll = extractUrls(carData['apronLhsRhs']);
    if (apronAll.isNotEmpty) {
      final mid = (apronAll.length / 2).ceil();
      imageFiles['lhsApronImages'] = apronAll.sublist(0, mid);
      if (apronAll.length > mid) {
        imageFiles['rhsApronImages'] = apronAll.sublist(mid);
      }
    }
    final lhsApron = extractUrls(carData['lhsApronImages']);
    if (lhsApron.isNotEmpty) imageFiles['lhsApronImages'] = lhsApron;
    final rhsApron = extractUrls(carData['rhsApronImages']);
    if (rhsApron.isNotEmpty) imageFiles['rhsApronImages'] = rhsApron;

    // Boot Door Open & Closed: check multiple possible DB keys
    final bootOpenList = extractUrls(carData['rearWithBootDoorOpenImages']);
    final bootOpenListAlt = extractUrls(carData['bootDoorOpenImages']);
    final bootClosedList = extractUrls(carData['bootDoorClosedImages']);

    if (bootOpenList.isNotEmpty) {
      imageFiles['bootDoorOpenImages'] = bootOpenList;
    } else if (bootOpenListAlt.isNotEmpty) {
      imageFiles['bootDoorOpenImages'] = bootOpenListAlt;
    }

    if (bootClosedList.isNotEmpty) {
      imageFiles['bootDoorClosedImages'] = bootClosedList;
    }

    // Fallback: use the single-string field rearWithBootDoorOpen which could be comma-separated
    final rearBoot = carData['rearWithBootDoorOpen'];
    if (rearBoot is String && rearBoot.isNotEmpty) {
      final parts = rearBoot.split(',').map((e) => e.trim()).where((url) => url.startsWith('http')).toList();
      if ((imageFiles['bootDoorOpenImages'] == null || imageFiles['bootDoorOpenImages']!.isEmpty) && parts.isNotEmpty) {
        imageFiles['bootDoorOpenImages'] = [parts[0]];
      }
      if ((imageFiles['bootDoorClosedImages'] == null || imageFiles['bootDoorClosedImages']!.isEmpty) && parts.length > 1) {
        imageFiles['bootDoorClosedImages'] = [parts[1]];
      }
    }

    // airbagimages array → individual airbag image fields
    final rawAirbagUrls = carData['airbagImages'] ?? carData['airbagimages'] ?? carData['airbags'];
    final List<String> airbagUrls = (rawAirbagUrls is List)
        ? rawAirbagUrls.map((e) => e?.toString() ?? '').toList()
        : [];
    
    final airbagKeys = [
      'driverAirbagImages',
      'coDriverAirbagImages',
      'driverSeatAirbagImages',
      'coDriverSeatAirbagImages',
      'rhsCurtainAirbagImages',
      'lhsCurtainAirbagImages',
      'driverKneeAirbagImages',
      'coDriverKneeAirbagImages',
      'rhsRearSideAirbagImages',
      'lhsRearSideAirbagImages',
    ];
    for (int i = 0; i < airbagUrls.length && i < airbagKeys.length; i++) {
      final url = airbagUrls[i];
      if (url.startsWith('http')) {
        imageFiles[airbagKeys[i]] = [url];
        carData[airbagKeys[i]] = [url];
      }
    }

    // Also check individual airbag image keys from new API format
    for (final key in airbagKeys) {
      final urls = extractUrls(carData[key]);
      if (urls.isNotEmpty) imageFiles[key] = urls;
    }

    imageFiles.refresh();
    debugPrint(
      '✅ _preFillMedia completed: ${imageFiles.keys.length} image fields populated',
    );
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
      data: {
        '_id': '',
        'appointmentId': appointmentId,
        'registrationNumber': schedule?.carRegistrationNumber ?? '',
        'yearMonthOfManufacture': schedule?.yearOfManufacture ?? '',
        'odometerReadingInKms': schedule?.odometerReadingInKms.toString() ?? '',
        'customerName': schedule?.ownerName ?? '',
        'customerPhone': schedule?.customerContactNumber ?? '',
        'city': schedule?.city ?? '',
        'make': '',
        'model': '',
        'variant': '',
        'status': 'Pending',
        'ownerSerialNumber': schedule?.ownershipSerialNumber.toString() ?? '',
      },
    );
    imageFiles.clear();
    mediaCloudinaryData.clear();
    _currentlyUploading.clear();
    pendingDeletions.clear();
    apiFetchedLockedFields.clear();
    _userEditedKeys.clear();
  }

  /// Persists the entire current form state (fields + images) to local storage.
  /// Call after first API load AND after every user save.
  Future<void> _saveSnapshot() async {
    final data = inspectionData.value;
    if (data == null) return;

    // Persist form fields (Standard form data)
    final snapMap = data.toJson();
    await _storage.write(_snapshotKey, snapMap);

    // Persist image paths in snapshot
    final imgMap = <String, dynamic>{};
    imageFiles.forEach((k, v) => imgMap[k] = v);
    await _storage.write(_snapshotImagesKey, imgMap);

    // Persist locked fields so they remain read-only upon re-open
    await _storage.write(
      _snapshotLockedFieldsKey,
      apiFetchedLockedFields.toList(),
    );

    // Persist Re-Inspection specific state
    await _storage.write(_snapshotOriginalDataKey, _originalData);
    if (_reInspectionCarId != null) {
      await _storage.write(_snapshotCarIdKey, _reInspectionCarId);
    }

    // Persist Cloudinary Metadata
    final cloudinaryMap = <String, dynamic>{};
    mediaCloudinaryData.forEach((k, v) => cloudinaryMap[k] = v);
    await _storage.write(_snapshotCloudinaryKey, cloudinaryMap);

    // Persist Deletion Queue
    await _storage.write(_snapshotDeletionsKey, pendingDeletions.toList());

    // Persist Dropdown Options (to ensure restored values are valid options)
    final dropdownMap = <String, dynamic>{};
    dropdownOptions.forEach((k, v) => dropdownMap[k] = v);
    await _storage.write(_snapshotDropdownsKey, dropdownMap);

    debugPrint(
      '💾 [Snapshot] Save Complete for $appointmentId. Fields: ${snapMap.length}, Images: ${imgMap.length}',
    );
  }

  /// Clears all snapshot data related to THIS appointmentId.
  /// Used after successful submission to ensure the next inspection starts fresh.
  Future<void> _clearSnapshot() async {
    await _storage.remove(_snapshotKey);
    await _storage.remove(_snapshotImagesKey);
    await _storage.remove(_snapshotCloudinaryKey);
    await _storage.remove(_snapshotDeletionsKey);
    await _storage.remove(_snapshotDropdownsKey);
    await _storage.remove(_snapshotLockedFieldsKey);
    await _storage.remove(_snapshotOriginalDataKey);
    await _storage.remove(_snapshotCarIdKey);

    // Clear sync tracker state for this appointment
    _syncService.clearState(appointmentId);
  }

  /// Recalculates and pushes the current total/uploaded counts to OfflineSyncService.
  /// Called after snapshot restore so the schedule card progress bar is accurate.
  void _refreshSyncState() {
    int total = 0;
    int uploaded = 0;

    imageFiles.forEach((key, paths) {
      for (final path in paths) {
        total++;
        if (isMediaUploaded(path)) uploaded++;
      }
    });

    if (total > 0) {
      _syncService.updateSyncState(
        appointmentId,
        total: total,
        uploaded: uploaded,
      );
    }
  }

  /// Helper to restore mediaCloudinaryData from JSON-compatible Map
  void _restoreCloudinaryData(Map data) {
    for (final entry in data.entries) {
      final val = entry.value;
      if (val is Map) {
        mediaCloudinaryData[entry.key.toString()] = Map<String, String>.from(
          val.map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    }
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

      // Sync changes to the list cards if important fields changed
      if (['make', 'model', 'variant', 'customerName'].contains(key)) {
        _syncScheduleWithChanges();
      }

      inspectionData.refresh();

      // NEW: Auto-save draft on every change (Text, Dropdown, Selections)
      _saveSnapshot();
    }
  }

  /// Syncs the current make/model/variant to any ScheduleController instances
  /// so the list cards reflect the updates immediately.
  void _syncScheduleWithChanges() {
    final data = inspectionData.value;
    if (data == null) return;

    // Safety check: ensure we don't sync empty identity fields over valid schedule data
    if (data.make.isEmpty && (schedule?.make.isNotEmpty ?? false)) {
      debugPrint(
        '⚠️ [Sync] Skipping schedule update: restored Make is empty while schedule has data.',
      );
      return;
    }

    ScheduleController.updateScheduleGlobally(
      appointmentId,
      make: data.data['make']?.toString(),
      model: data.data['model']?.toString(),
      variant: data.data['variant']?.toString(),
      ownerName: data.data['customerName']?.toString(),
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
        String finalPath = picked.path;

        // Navigation to ImageEditorScreen (Manual Blur & Watermarking) - ONLY for Primary Photos
        if (key == 'frontMainImages' ||
            key == 'rearMainImages' ||
            key == 'dashboardImages') {
          final String? editedPath = await Get.to(
            () => ImageEditorScreen(imagePath: picked.path),
          );
          
          if (editedPath == null || editedPath.isEmpty) {
            return; // User cancelled the editor
          }
          finalPath = editedPath;
        }

        final currentList = imageFiles[key] ?? [];
        currentList.add(finalPath);
        imageFiles[key] = List.from(currentList);
        imageFiles.refresh();

        // Save to Gallery if captured from Camera
        if (source == ImageSource.camera) {
          _saveToGallery(finalPath);
        }
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

  Future<void> _saveToGallery(String path, {bool isVideo = false}) async {
    try {
      if (isVideo) {
        await Gal.putVideo(path, album: 'Otobix Inspection');
      } else {
        await Gal.putImage(path, album: 'Otobix Inspection');
      }
      debugPrint('📸 Media saved to gallery: $path');
    } catch (e) {
      debugPrint('❌ Failed to save media to gallery: $e');
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
        // Uploading is now handled by the background queue upon submission.
        // We only save the path locally for the offline queue.

        // Save to Gallery if captured from Camera
        if (source == ImageSource.camera) {
          _saveToGallery(picked.path, isVideo: true);
        }
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
          // Uploading is now handled by the background queue upon submission.
          // We only save the path locally for the offline queue.
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
      // NOTE: We no longer delete from Cloudinary synchronously here because
      // uploading/deleting is now handled offline-first by the background queue.
      // If the media was never uploaded (since we don't upload on pick anymore),
      // there's nothing to delete remotely anyway.

      currentList.removeAt(index);
      mediaCloudinaryData.remove(path);

      imageFiles[key] = List.from(currentList);
      imageFiles.refresh();

      // NEW: Persist removal immediately
      _saveSnapshot();
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
    bool addToQueueOnFailure = true,
  }) async {
    try {
      // debugPrint(
      // ' API CALL: Deleting ${isVideo ? 'video' : 'image'} from Cloudinary',
      // );
      // debugPrint('📍 Target: $localInfo (PublicID: $publicId)');

      final url =
          isVideo ? ApiConstants.deleteVideoUrl : ApiConstants.deleteImageUrl;

      await ApiService.delete(url, {'publicId': publicId});

      // debugPrint('✅ SUCCESS: Remote file deleted.');
    } catch (e) {
      // debugPrint('❌ ERROR: Delete failed for $localInfo: $e');

      if (addToQueueOnFailure) {
        // Avoid duplicate entries in the queue
        bool alreadyQueued = pendingDeletions.any(
          (d) => d['publicId'] == publicId,
        );
        if (!alreadyQueued) {
          pendingDeletions.add({
            'publicId': publicId,
            'isVideo': isVideo,
            'localInfo': localInfo,
          });
          _saveSnapshot(); // Persist the queue state
        }
      }
    }
  }

  /// Retries all deletion requests that were previously queued due to lack of internet.
  void retryPendingDeletions() async {
    if (pendingDeletions.isEmpty) return;

    // debugPrint('📡 Connectivity restored. Retrying ${pendingDeletions.length} deletions...');

    // Take a snapshot of the current queue and clear it to avoid infinite loops if it fails again
    final List<Map<String, dynamic>> toRetry = List.from(pendingDeletions);
    pendingDeletions.clear();

    for (final item in toRetry) {
      await _deleteMedia(
        item['publicId'].toString(),
        isVideo: item['isVideo'] == true,
        localInfo: item['localInfo'].toString(),
        addToQueueOnFailure: true, // Re-queue if it fails AGAIN
      );
    }
  }

  // ─── Visibility & Requirements ───

  /// Returns whether a field should be visible based on current form state.
  bool isFieldVisible(String key) {
    final data = inspectionData.value;
    if (data == null) return true;

    // RC Condition visibility logic
    if (key == 'rcCondition') {
      final rcBookVal = getFieldValue('rcBookAvailability');
      return (rcBookVal == 'Original' || rcBookVal == 'Duplicate');
    }

    // RTO Form 28 visibility logic
    if (key == 'rtoForm28') {
      final rtoNocVal = getFieldValue('rtoNoc');
      return (rtoNocVal != 'Not Applicable');
    }

    // Tax Valid Till visibility logic
    if (key == 'taxValidTill') {
      final taxVal = getFieldValue('roadTaxValidity');
      return (taxVal == 'Limited Period');
    }

    // Hypothecated To visibility logic
    if (key == 'hypothecatedTo') {
      final hypVal = getFieldValue('hypothecationDetails').trim().toLowerCase();
      return (hypVal != 'no' &&
          hypVal != 'not hypothecated' &&
          hypVal.isNotEmpty);
    }

    // Duplicate Key Images visibility logic
    if (key == 'duplicateKeyImages') {
      final dupKeyVal = getFieldValue('duplicateKey');
      return (dupKeyVal == 'Duplicate Key Available' ||
          dupKeyVal == 'Available');
    }

    // Standard Visibility Mappings
    final visibilityRules = {
      'lhsFoglampImages': 'lhsFoglamp',
      'rhsFoglampImages': 'rhsFoglamp',
      'lhsRearFogLampImages': 'lhsRearFogLamp',
      'rhsRearFogLampImages': 'rhsRearFogLamp',
      'rearWiperAndWasherImages': 'rearWiperWasher',
      'reverseCameraImages': 'reverseCamera',
      'sunroofImages': 'sunroof',
      'lhsOrvmImages': 'lhsOrvm',
      'rhsOrvmImages': 'rhsOrvm',
      'spareWheelImages': 'spareWheel',
      'spareTyreImages': 'spareTyre',
      'driverAirbagImages': 'airbagFeaturesDriverSide',
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

    if (visibilityRules.containsKey(key)) {
      final parentKey = visibilityRules[key]!;
      final parentVal = getFieldValue(parentKey);

      // Rule: Not applicable or Not available
      if (parentVal == 'Not applicable' ||
          parentVal == 'Not Applicable' ||
          parentVal == 'Not available' ||
          parentVal == 'Not Available' ||
          parentVal == 'N/A' ||
          parentVal == 'Not Present' ||
          parentVal == 'Policy Not Available') {
        return false;
      }
    }

    // --- Master Airbag Rule ---
    final airbagRelatedFields = [
      'airbagFeaturesDriverSide',
      'driverAirbagImages',
      'airbagFeaturesCoDriverSide',
      'coDriverAirbagImages',
      'driverSeatAirbag',
      'driverSeatAirbagImages',
      'coDriverSeatAirbag',
      'coDriverSeatAirbagImages',
      'rhsCurtainAirbag',
      'rhsCurtainAirbagImages',
      'lhsCurtainAirbag',
      'lhsCurtainAirbagImages',
      'driverSideKneeAirbag',
      'driverKneeAirbagImages',
      'coDriverKneeSeatAirbag',
      'coDriverKneeAirbagImages',
      'rhsRearSideAirbag',
      'rhsRearSideAirbagImages',
      'lhsRearSideAirbag',
      'lhsRearSideAirbagImages',
    ];

    if (airbagRelatedFields.contains(key)) {
      final noOfAirbags = getFieldValue('noOfAirBags');
      if (noOfAirbags == 'Not applicable' || noOfAirbags == 'Not Applicable') {
        return false;
      }
    }

    // Default Superadmin override: if no specific rule hid the field, superadmin can see it
    final user = UserController.instance.user.value;
    if (user.id == 'superadmin') return true;

    return true;
  }

  /// Helper to convert a date to IST and format as UTC ISO string (ending in Z)
  /// as requested by backend for consistency.
  String _dateToIstUtcIso(DateTime date) {
    // Add 5:30 to UTC to represent IST moment as UTC string
    final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    // Remove milliseconds and append Z
    return istDate.toIso8601String().split('.').first + 'Z';
  }

  /// Returns whether a field is required (i.e. not hidden and not optional).
  bool isFieldRequired(String key) {
    // Superadmin bypass
    final user = UserController.instance.user.value;
    if (user.id == 'superadmin') return false;

    if (!isFieldVisible(key)) return false;

    // Find the field definition
    for (final section in InspectionFieldDefs.sections) {
      for (final field in section.fields) {
        if (field.key == key) {
          return !field.optional && !field.readonly;
        }
      }
    }
    return false;
  }

  List<String> getImages(String key) {
    return imageFiles[key] ?? [];
  }

  /// Checks if a media file (image/video) has been successfully uploaded to the server.
  bool isMediaUploaded(String path) {
    if (path.startsWith('http')) return true;
    final data = mediaCloudinaryData[path];
    if (data == null) return false;
    final url = data['url'];
    return url != null && url.startsWith('http');
  }

  // ─── Navigation ───
  /// Returns a list of labels for required fields that are not yet filled in the current section.
  List<String> getUnfilledRequiredFields(int sectionIndex) {
    // Superadmin bypass
    final user = UserController.instance.user.value;
    if (user.id == 'superadmin') return [];

    if (sectionIndex < 0 || sectionIndex >= InspectionFieldDefs.sections.length)
      return [];

    final unFilled = <String>[];
    final section = InspectionFieldDefs.sections[sectionIndex];

    for (final field in section.fields) {
      // Use localized requirement check
      if (!isFieldRequired(field.key)) continue;

      // Special check for image/video fields
      if (field.type == FType.image || field.type == FType.video) {
        final paths = imageFiles[field.key] ?? [];
        final count = paths.length;
        if (count < field.minImages) {
          unFilled.add(field.label);
        }
      } else {
        // Standard field check
        final val = getFieldValue(field.key);
        if (val.isEmpty || val == 'N/A') {
          unFilled.add(field.label);
        }
      }
    }
    return unFilled;
  }

  // ─── Navigation ───
  void nextSection() {
    if (currentSectionIndex.value < sectionCount - 1) {
      // ENFORCEMENT: Only move forward if current section is valid (starting from index 0)
      if (currentSectionIndex.value >= 0) {
        final missing = getUnfilledRequiredFields(currentSectionIndex.value);
        if (missing.isNotEmpty) {
          TLoaders.warningSnackBar(
            title: 'Incomplete Section',
            message:
                'Please complete: ${missing.take(3).join(", ")}${missing.length > 3 ? "..." : ""}',
          );
          return;
        }
      }

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
    // Superadmin bypass
    final user = UserController.instance.user.value;
    if (user.id == 'superadmin') {
      currentSectionIndex.value = index;
      pageController.jumpToPage(index);
      return;
    }

    // ENFORCEMENT: If moving forward, must pass validation of current and intermediary sections
    if (index > currentSectionIndex.value && currentSectionIndex.value >= 0) {
      // Loop through sections between current and target to ensure no skip
      for (int i = currentSectionIndex.value; i < index; i++) {
        final missing = getUnfilledRequiredFields(i);
        if (missing.isNotEmpty) {
          TLoaders.warningSnackBar(
            title: 'Section Incomplete',
            message:
                'Please complete ${InspectionFieldDefs.sections[i].title} first.',
          );
          // Jump to the first incomplete section to prompt the user
          currentSectionIndex.value = i;
          pageController.jumpToPage(i);
          return;
        }
      }
    }

    // Moving backward is always allowed
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

      TLoaders.successSnackBar(
        title: 'Data Saved',
        message: 'Your data has been saved as Draft',
      );
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

    final user = UserController.instance.user.value;

    // Validate ALL required fields across every section
    final missingBySection = <String, List<Map<String, String>>>{};
    for (final section in InspectionFieldDefs.sections) {
      for (final field in section.fields) {
        // Use localized requirement check
        if (!isFieldRequired(field.key)) continue;

        // 2. Perform Validation
        if (field.type == FType.image || field.type == FType.video) {
          final paths = getImages(field.key);
          final minReq = field.minImages > 0 ? field.minImages : 1;

          if (paths.length < minReq) {
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
    if (isReInspection && user.id != 'superadmin') {
      _showReInspectionPreviewDialog(data);
      return;
    }

    // OFFLOAD FLOW: Queue for background sync (upload media + submit API)
    // ══════════════════════════════════════════════════════════
    isSubmitting.value = true;
    try {
      // 1. Build CarModel payload (same as before)
      final carModel = _buildCarModelFromForm(data);
      final payload = carModel.toJson();

      // 2. Overlay any already-uploaded Cloudinary URLs into the payload
      //    (preserves work already done if user had uploaded before)
      imageFiles.forEach((key, paths) {
        if (const {
          'airbagImages', 'airbagimages', 'lhsQuarterPanelImages',
          'rhsQuarterPanelImages', 'bonnetImages', 'frontBumperImages',
          'rearBumperImages',
        }.contains(key)) return;

        if (paths.isNotEmpty) {
          final resolvedUrls = paths
              .map((p) {
                final url = mediaCloudinaryData[p]?['url'] ?? p;
                return url.startsWith('http') ? url : p; // keep local if not yet uploaded
              })
              .toList();
          payload[key] = resolvedUrls;
        }
      });

      // 3. Set final inspection status fields
      payload['status'] = 'Inspected';
      payload['inspectionStatus'] = 'Inspected';
      payload['auctionStatus'] = 'inspected';
      final nowUtcIso = DateTime.now().toUtc().toIso8601String();
      payload['timestamp'] = nowUtcIso;
      payload['inspectionDate'] = nowUtcIso;
      payload['sendToAuctionApk'] = nowUtcIso;

      // 4. Check for existing car record (UPDATE vs ADD) if online
      String? existingCarId;
      if (_syncService.isOnline) {
        try {
          final existingResponse = await ApiService.get(
            ApiConstants.carDetailsUrl(appointmentId),
          );
          final existingCar = existingResponse['carDetails'];
          if (existingCar != null && existingCar['_id'] != null) {
            existingCarId = existingCar['_id'].toString();
          }
        } catch (_) {}
      }

      // 5. Build telecalling status body (stored as query string so it serializes simply)
      String? telecallingBodyJson;
      if (schedule != null) {
        final storage = GetStorage();
        final userId = storage.read('USER_ID')?.toString() ??
            storage.read('user_id')?.toString() ?? '';
        final userRole =
            storage.read('USER_ROLE')?.toString() ?? 'Inspection Engineer';
        final statusBody = {
          'telecallingId': schedule!.id,
          'appointmentId': appointmentId,
          'changedBy': userId,
          'source': userRole,
          'inspectionStatus': 'Inspected',
          'status': 'Inspected',
          'remarks': schedule!.remarks ?? '',
          'version': _appVersion,
          'inspectionDateTime': nowUtcIso,
        };
        // Store as JSON via dart:convert
        telecallingBodyJson = statusBody.entries
            .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
            .join('&');
      }

      // 6. Build the queue item with LOCAL image file paths
      final offloadItem = OffloadQueueItem(
        appointmentId: appointmentId,
        ownerName: data.data['ownerName']?.toString() ??
            data.data['customerName']?.toString() ?? '',
        make: data.data['make']?.toString() ?? '',
        model: data.data['model']?.toString() ?? '',
        payload: payload,
        imageFiles: Map<String, List<String>>.from(
          imageFiles.map((k, v) => MapEntry(k, List<String>.from(v))),
        ),
        carId: existingCarId,
        telecallingId: schedule?.id,
        telecallingBody: telecallingBodyJson,
        // Pre-populate already-uploaded URLs so they don't get re-uploaded
        resolvedUrls: Map<String, String>.fromEntries(
          mediaCloudinaryData.entries
              .where((e) => e.value['url'] != null)
              .map((e) => MapEntry(e.key, e.value['url']!)),
        ),
      );

      // 7. Enqueue for background sync
      await InspectionOffloadService.instance.enqueue(offloadItem);

      // 8. Clear local draft immediately
      await _clearSnapshot();

      // 9. Trigger global refresh for main screens
      try {
        ScheduleController.refreshAllInstances();
      } catch (e) {
        debugPrint('⚠️ Failed to refresh schedules: $e');
      }

      // 10. Show success and navigate back
      try { TLoaders.hideSnackBar(); } catch (_) {}
      _showOffloadQueuedDialog();
    } catch (e) {
      try { TLoaders.hideSnackBar(); } catch (_) {}
      _showErrorDialog(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Success dialog shown after queueing — user knows it's syncing
  void _showOffloadQueuedDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Inspection Queued!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your inspection is saved locally and is now syncing in the background.\n\nTrack progress in the Off-Loading box on your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.until((route) => route.isFirst); // Go to dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
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
              paths
                  .map((p) {
                    final url = mediaCloudinaryData[p]?['url'] ?? p;
                    return url.startsWith('http') ? url : '';
                  })
                  .where((item) => item.isNotEmpty)
                  .toList();
          payload[key] = resolvedUrls;
        }
      });

      // Reconstruct composite arrays for backend schema compatibility
      List<String> getUrls(String key) {
        final urls = payload[key];
        if (urls is List) return urls.map((e) => e.toString()).where((u) => u.startsWith('http')).toList();
        return [];
      }
      String getFirstUrl(String key) => getUrls(key).firstOrNull ?? '';

      payload['airbagImages'] = [
        getFirstUrl('driverAirbagImages'),
        getFirstUrl('coDriverAirbagImages'),
        getFirstUrl('driverSeatAirbagImages'),
        getFirstUrl('coDriverSeatAirbagImages'),
        getFirstUrl('rhsCurtainAirbagImages'),
        getFirstUrl('lhsCurtainAirbagImages'),
        getFirstUrl('driverKneeAirbagImages'),
        getFirstUrl('coDriverKneeAirbagImages'),
        getFirstUrl('rhsRearSideAirbagImages'),
        getFirstUrl('lhsRearSideAirbagImages'),
      ];
      payload['bonnetImages'] = [...getUrls('bonnetClosedImages'), ...getUrls('bonnetOpenImages')];
      payload['frontBumperImages'] = [...getUrls('frontBumperLhs45DegreeImages'), ...getUrls('frontBumperRhs45DegreeImages'), ...getUrls('frontBumperImages')];
      payload['rearBumperImages'] = [...getUrls('rearBumperLhs45DegreeImages'), ...getUrls('rearBumperRhs45DegreeImages'), ...getUrls('rearBumperImages')];
      payload['lhsQuarterPanelImages'] = [getFirstUrl('lhsQuarterPanelWithRearDoorOpenImages'), getFirstUrl('lhsQuarterPanelWithRearDoorClosedImages')];
      payload['rhsQuarterPanelImages'] = [getFirstUrl('rhsQuarterPanelWithRearDoorOpenImages'), getFirstUrl('rhsQuarterPanelWithRearDoorClosedImages')];
      payload['apronLhsRhs'] = [...getUrls('lhsApronImages'), ...getUrls('rhsApronImages')];


      // Ensure timestamps represent IST moments converted to UTC
      final nowUtcIso = DateTime.now().toUtc().toIso8601String();
      payload['timestamp'] = nowUtcIso;
      payload['inspectionDate'] = nowUtcIso;
      payload['sendToAuctionApk'] = nowUtcIso;

      // For Re-Inspection: include carId and use PUT
      if (_reInspectionCarId != null) {
        payload['carId'] = _reInspectionCarId;
      }

      // Set status to Inspected on successful Re-Inspection submit
      payload['status'] = 'Inspected';
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
      await _clearSnapshot();

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
            'appointmentId': appointmentId,
            'changedBy': userId,
            'source': userRole,
            'inspectionStatus': 'Inspected',
            'status': 'Inspected',
            'remarks': schedule!.remarks ?? '',
            'version': _appVersion,
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

          // Refresh schedule list globally
          try {
            ScheduleController.refreshAllInstances();
          } catch (_) {}
        } else {
          // debugPrint('⚠️ schedule is null — cannot update telecalling status (Re-Inspection)');
        }
      } catch (e) {
        // debugPrint('⚠️ Failed to update telecalling status: $e');
        TLoaders.customToast(
          message: "Re-Inspection submitted, but lead status update failed: $e",
        );
      }

      // 7. Show success dialog
      try {
        try {
          TLoaders.hideSnackBar();
        } catch (e) {}
      } catch (_) {}
      _showSuccessDialog(
        response['message'] ?? 'Re-Inspection updated successfully!',
      );
    } catch (e) {
      // debugPrint('❌ Re-Inspection submit error: $e');
      try {
        try {
          TLoaders.hideSnackBar();
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

  // ─── Temporary Test Fill Feature ───

  /// Copies a Flutter bundled asset to a writable temp file and returns its path.
  /// This lets test-fill use offline bundled assets as real local file paths.
  Future<String?> _extractAssetToTemp(String assetPath, String filename) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (e) {
      debugPrint('⚠️ [TestFill] Failed to extract asset $assetPath: $e');
      return null;
    }
  }

  void tempTestFill() async {
    // ── Step 1: Extract bundled test assets to writable temp paths ──
    final testImagePath = await _extractAssetToTemp(
      'assets/images/profile/default.webp',
      'test_fill_image.webp',
    );
    final testVideoPath = await _extractAssetToTemp(
      'assets/images/profile/Default-video.mp4',
      'test_fill_video.mp4',
    );

    // ── Step 2: Fill all text / dropdown / date fields ──
    for (final section in InspectionFieldDefs.sections) {
      for (final field in section.fields) {
        if (field.readonly) continue;

        if (field.type == FType.text ||
            field.type == FType.number ||
            field.type == FType.dropdown ||
            field.type == FType.searchable ||
            field.type == FType.multiSelect) {
          
          dynamic value = "test";
          
          if (field.type == FType.number) {
            value = "10";
            if (field.key == 'ownerSerialNumber') value = "1";
            if (field.key == 'seatingCapacity') value = "5";
            if (field.key == 'cubicCapacity') value = "1200";
            if (field.key == 'odometerReadingInKms') value = "50000";
          }
          
          if (field.type == FType.dropdown || field.type == FType.searchable) {
            final dynamicOpts = dropdownOptions[field.key] ?? [];
            if (dynamicOpts.isNotEmpty) {
              value = dynamicOpts.first;
            } else if (field.options.isNotEmpty) {
              value = field.options.first;
            } else {
              value = "test";
            }
          }
          
          if (field.type == FType.multiSelect) {
            final dynamicOpts = dropdownOptions[field.key] ?? [];
            if (dynamicOpts.isNotEmpty) {
              value = [dynamicOpts.first];
            } else if (field.options.isNotEmpty) {
              value = [field.options.first];
            } else {
              value = ["test"];
            }
          }
          
          updateField(field.key, value);
        } else if (field.type == FType.date) {
          updateField(field.key, "2024-01-01");

        // ── Step 3: Fill image fields with matching assets from the dedicated folder ──
        } else if (field.type == FType.image) {
          final assetBase = 'assets/inspection-form-field-images';
          List<String> matchedPaths = [];

          // 1. Try to find assets matching the label
          String cleanLabel = field.label.trim();
          if (cleanLabel.endsWith(' Image')) cleanLabel = cleanLabel.substring(0, cleanLabel.length - 6);
          if (cleanLabel.endsWith(' Images')) cleanLabel = cleanLabel.substring(0, cleanLabel.length - 7);
          
          // Special case for RC Image which needs 2 images
          if (field.key == 'rcTokenImages') {
            final path1 = await _extractAssetToTemp('$assetBase/RC Token Image 1.png', 'rc_token_1.png');
            final path2 = await _extractAssetToTemp('$assetBase/RC Token Image 2.png', 'rc_token_2.png');
            if (path1 != null) matchedPaths.add(path1);
            if (path2 != null) matchedPaths.add(path2);
          } else {
            // General matching strategy
            // Try "CleanLabel Image.png" and "CleanLabel Images.png" and "CleanLabel.png"
            String? path = await _extractAssetToTemp('$assetBase/$cleanLabel Image.png', '${field.key}.png');
            if (path == null) {
               path = await _extractAssetToTemp('$assetBase/$cleanLabel Images.png', '${field.key}.png');
            }
            if (path == null) {
               path = await _extractAssetToTemp('$assetBase/${field.label}.png', '${field.key}.png');
            }
            
            // Try with some manual mapping for common discrepancies
            if (path == null) {
              if (field.label == 'Front Main') path = await _extractAssetToTemp('$assetBase/Front Main.png', '${field.key}.png');
              if (field.label == 'LHS Full View') path = await _extractAssetToTemp('$assetBase/LHS Full View.png', '${field.key}.png');
              if (field.label == 'Rear Main') path = await _extractAssetToTemp('$assetBase/Rear Main.png', '${field.key}.png');
              if (field.label == 'RHS Full View') path = await _extractAssetToTemp('$assetBase/RHS Full View.png', '${field.key}.png');
              if (field.label == 'Engine Bay') path = await _extractAssetToTemp('$assetBase/Engine Bay.png', '${field.key}.png');
              if (field.label == 'Cluster Meter (With Engine Running)') path = await _extractAssetToTemp('$assetBase/Cluster Meter (with engine Running).png', '${field.key}.png');
              if (field.label.contains('Boot Door Open Image')) {
                path = await _extractAssetToTemp('$assetBase/Boot Door Open image.png', '${field.key}.png');
                path ??= await _extractAssetToTemp('$assetBase/Rear With Boot Door Open Image.png', '${field.key}.png');
              }
              if (field.label.contains('Front Bumper LHS 45')) path = await _extractAssetToTemp('$assetBase/Front Bumper LHS 45.png', '${field.key}.png');
              if (field.label.contains('Front Bumper RHS 45')) path = await _extractAssetToTemp('$assetBase/Front Bumper RHS 45.png', '${field.key}.png');
              if (field.label.contains('Rear Bumper LHS 45')) path = await _extractAssetToTemp('$assetBase/Rear Bumper LHS 45.png', '${field.key}.png');
              if (field.label.contains('Rear Bumper RHS 45')) path = await _extractAssetToTemp('$assetBase/Rear Bumper RHS 45.png', '${field.key}.png');
              if (field.label == 'Bonnet Open') path = await _extractAssetToTemp('$assetBase/Bonnet open.png', '${field.key}.png');
              if (field.label == 'Bonnet Closed') path = await _extractAssetToTemp('$assetBase/Bonnet Close.png', '${field.key}.png');
              if (field.label == 'Front Seat from Driver Side (Door Open)') path = await _extractAssetToTemp('$assetBase/Front Seat From Driver Side (Door open).png', '${field.key}.png');
              if (field.label == 'Rear Seat from Right Side (Door Open)') path = await _extractAssetToTemp('$assetBase/Rear Seat From Right Side (Door open).png', '${field.key}.png');
              if (field.label == 'Dashboard from Rear Seat') path = await _extractAssetToTemp('$assetBase/Dashboard From Rear seat.png', '${field.key}.png');
              if (field.label == 'LHS Quarter Panel With Rear Door Open Image') path = await _extractAssetToTemp('$assetBase/LHS Quarter Panel With Rear Door Open Image.png', '${field.key}.png');
              if (field.label == 'LHS Quarter Panel With Rear Door Closed Image') path = await _extractAssetToTemp('$assetBase/LHS Quarter Panel with Rear door closed Image.png', '${field.key}.png');
              if (field.label == 'RHS Quarter Panel With Rear Door Open Image') path = await _extractAssetToTemp('$assetBase/RHS Quarter Panel with Rear door open Image.png', '${field.key}.png');
              if (field.label == 'RHS Quarter Panel With Rear Door Closed Image') path = await _extractAssetToTemp('$assetBase/RHS Quarter Panel with Rear door Close Image.png', '${field.key}.png');
            }

            if (path != null) {
              matchedPaths.add(path);
            } else if (testImagePath != null) {
              // Fallback to default if no match
              matchedPaths.add(testImagePath);
            }
          }

          if (matchedPaths.isNotEmpty) {
            // If field needs more images than we matched, duplicate the last one
            final needed = field.minImages > 0 ? field.minImages : 1;
            while (matchedPaths.length < needed && matchedPaths.length < field.maxImages) {
              matchedPaths.add(matchedPaths.last);
            }
            imageFiles[field.key] = matchedPaths;
            imageFiles.refresh();
          }

        // ── Step 4: Fill video fields with bundled test video ──
        } else if (field.type == FType.video && testVideoPath != null) {
          imageFiles[field.key] = [testVideoPath];
          imageFiles.refresh();
        }
      }
    }

    await _saveSnapshot();
    inspectionData.refresh();

    TLoaders.successSnackBar(
      title: 'Test Fill ✓',
      message:
          'Form filled with test data. Images & videos use bundled offline assets.',
    );
  }

  // ─── Temporary Clear Form Feature ───
  void tempClearForm() async {
    _initializeNewInspection();
    await _saveSnapshot();
    inspectionData.refresh();

    // Reset navigation to first section
    currentSectionIndex.value = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }

    TLoaders.successSnackBar(
      title: 'Form Cleared',
      message: 'The inspection form has been reset to an empty state.',
    );
  }

  // ─── CarModel Mapping Helpers ───
  CarModel _buildCarModelFromForm(InspectionFormModel data) {
    // Retrieve logged-in user info from local storage
    final storage = GetStorage();
    final userEmail = storage.read('USER_EMAIL')?.toString() ?? '';
    final userName = storage.read('USER_USERNAME')?.toString() ?? '';
    // Use the lead's inspectionAddress as the latlong value
    final address = schedule?.inspectionAddress ?? '';

    return buildCarModelFromForm(
      data,
      Map<String, List<String>>.from(imageFiles),
      Map<String, Map<String, String>>.from(mediaCloudinaryData),
      appointmentId,
      userEmail: userEmail,
      userName: userName,
      inspectionAddress: address,
      appVersion: _appVersion,
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

    // ── Check Cache First ──
    final cacheKey = 'attestr_cache_${regNo.toUpperCase()}';
    final cachedResponse = _storage.read(cacheKey);

    try {
      isFetchingDetails.value = true;

      Map<String, dynamic> response;

      if (cachedResponse != null && cachedResponse is Map<String, dynamic>) {
        response = cachedResponse;
      } else {
        // ── Step 1: Fetch vehicle registration details ──
        response = await ApiService.post(
          ApiConstants.fetchVehicleDetailsUrl,
          {"registrationNumber": regNo, "userId": userId},
        );

        // Cache the successful response
        await _storage.write(cacheKey, response);
      }

      // ── Step 1: Flatten the response for easier access (Avoid data.results nesting) ──
      final responseData = response['data'];
      if (responseData == null || responseData is! Map<String, dynamic>) {
        throw 'No details found for this registration number.';
      }

      final result = responseData['result'];
      final Map<String, dynamic> flattened = {};

      // Merge both high-level data and detailed result into one flat object
      if (responseData is Map<String, dynamic>) flattened.addAll(responseData);
      if (result is Map<String, dynamic>) flattened.addAll(result);

      // Remove the nested result key to keep it flat as requested
      flattened.remove('result');
      inspectionData.value?.data['attesterRawCarDetails'] = flattened;

      if (result != null && result is Map<String, dynamic>) {
        _applyFetchedData(result);
      }

      // ── Auto-fill Make, Model, Variant from response data ──
      _applyMakeModelVariantFromApi(responseData);

      // ── Step 2: Fetch Make/Model/Variant from telecalling API (fallback) ──
      // Only fetch from telecalling if make/model are not already filled by the API
      final currentMake = getFieldValue('make');
      final currentModel = getFieldValue('model');
      if (currentMake.isEmpty || currentModel.isEmpty) {
        await _fetchMakeModelVariantFromTelecalling();
      }

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
      final userEmail = UserController.instance.user.value.email;

      // Try all relevant statuses to find the matching appointment
      final statuses = [
        'Scheduled',
        'Running',
        'Re-Inspection',
        'Re-Scheduled',
      ];

      for (final status in statuses) {
        try {
          final Map<String, dynamic> body = {"inspectionStatus": status};

          final user = UserController.instance.user.value;
          if (user.id != 'superadmin') {
            body["allocatedTo"] = userEmail;
          }

          final response = await ApiService.post(
            ApiConstants.inspectionEngineerSchedulesPaginatedUrl(
              limit: 100,
              pageNumber: 1,
            ),
            body,
          );

          final List<dynamic> dataList = response['data'] ?? [];
          for (final record in dataList) {
            if (record is Map<String, dynamic> &&
                record['appointmentId']?.toString() == appointmentId) {
              // Found the matching record — extract make/model/variant
              final make =
                  (record['maker_name'] ?? record['make'] ?? '')
                      .toString()
                      .trim();
              final model =
                  (record['maker_model'] ?? record['model'] ?? '')
                      .toString()
                      .trim();
              final variant =
                  (record['variant_name'] ??
                          record['variant'] ??
                          record['series'] ??
                          '')
                      .toString()
                      .trim();

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

  /// Checks if a field is locked (either by definition or by API response)
  bool isFieldLocked(F field) {
    // Superadmin can edit anything
    final user = UserController.instance.user.value;
    if (user.id == 'superadmin') return false;

    return field.readonly || apiFetchedLockedFields.contains(field.key);
  }

  /// Checks if a field was locked by the API fetch response (non-editable)
  bool isFieldLockedByApi(String fieldKey) {
    // Superadmin bypass
    final user = UserController.instance.user.value;
    if (user.id == 'superadmin') return false;

    return apiFetchedLockedFields.contains(fieldKey);
  }

  /// Applies make, model, and variant from the new attestr API response.
  /// Uses a robust case-insensitive search for keys and looks in both
  /// responseData and result.
  void _applyMakeModelVariantFromApi(Map<String, dynamic> responseData) {
    final result = responseData['result'] as Map<String, dynamic>?;

    // findIn helper: respects the order of targetKeys to allow prioritization
    dynamic findIn(Map<String, dynamic> m, List<String> targetKeys) {
      for (final tk in targetKeys) {
        for (final entry in m.entries) {
          if (entry.key.toLowerCase() == tk.toLowerCase()) {
            final v = entry.value?.toString().trim() ?? '';
            if (v.isNotEmpty) return v;
          }
        }
      }
      return null;
    }

    // Try target keys in order of descriptive preference
    final makeVal =
        findIn(responseData, ['maker_name', 'make', 'maker']) ??
        (result != null
            ? findIn(result, ['maker_name', 'make', 'maker'])
            : null) ??
        '';

    final modelVal =
        findIn(responseData, ['maker_model', 'model', 'model_name']) ??
        (result != null
            ? findIn(result, ['maker_model', 'model', 'model_name'])
            : null) ??
        '';

    final variantVal =
        findIn(responseData, ['variant', 'series', 'variant_name']) ??
        (result != null
            ? findIn(result, ['variant', 'series', 'variant_name'])
            : null) ??
        '';

    final data = inspectionData.value;
    if (data == null) return;

    // Clear any previously locked fields from a prior fetch
    apiFetchedLockedFields.remove('make');
    apiFetchedLockedFields.remove('model');
    apiFetchedLockedFields.remove('variant');

    if (makeVal.isNotEmpty) {
      data.data['make'] = makeVal;
      data.make = makeVal;
      _userEditedKeys.add('make');
    }

    if (modelVal.isNotEmpty) {
      data.data['model'] = modelVal;
      data.model = modelVal;
      _userEditedKeys.add('model');
    }

    if (variantVal.isNotEmpty) {
      data.data['variant'] = variantVal;
      data.variant = variantVal;
      _userEditedKeys.add('variant');
    }
    // If variant is not available, it remains editable (not locked)

    _syncScheduleWithChanges();
    inspectionData.refresh();
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
      'seatingCapacity': [
        'seatingCapacity',
        'seating_capacity',
        'seat_cap',
        'seats',
        'capacity',
        'seat_count',
      ],
      'color': ['colorType', 'color', 'colour'],
      'cubicCapacity': [
        'cubicCapacity',
        'cubic_capacity',
        'cc',
        'cubic_cap',
        'displacement',
        'engine_capacity',
        'engine_size',
        'cc_rating',
        'cubic_capacity_cc',
        'displacement_cc',
        'capacity_cc',
      ],
      'norms': [
        'normsType',
        'norms',
        'pollution_norms',
        'norms_type',
        'emission_norms',
      ],
      'registeredRto': ['rto', 'registered_rto', 'rto_name', 'rto_code'],
      'ownerSerialNumber': [
        'ownerNumber',
        'owner_serial_number',
        'owner_count',
        'owner_number',
        'ownership_count',
      ],
      'registeredOwner': [
        'owner',
        'owner_name',
        'registered_owner',
        'registered_owner_name',
      ],
      'registeredAddressAsPerRc': [
        'currentAddress',
        'permanent_address',
        'address',
        'owner_address',
      ],
      'insuranceValidity': [
        'insuranceUpto',
        'insurance_valid_upto',
        'insurance_expiry',
      ],
      'insurer': [
        'insuranceProvider',
        'insurance_company',
        'insurer_name',
        'insurance_name',
      ],
      'insurancePolicyNumber': [
        'insurancePolicyNumber',
        'policy_no',
        'policyNumber',
      ],
      'pucValidity': [
        'pollutionCertificateUpto',
        'puc_upto',
        'puc_validity',
        'pollution_expiry',
      ],
      'pucNumber': ['pollutionCertificateNumber', 'puc_number', 'pucNo'],
      'city': ['city', 'city_name'],
      'taxValidTill': [
        'taxUpto',
        'tax_validity',
        'tax_paid_upto',
        'tax_upto',
        'tax_expiry',
      ],
    };

    bool updatedAny = false;
    mapping.forEach((targetKey, sourceKeys) {
      final value = find(sourceKeys);
      if (value != null) {
        String finalValue = value.toString();

        // 📝 Sanitize numeric strings (e.g., "1497.00" -> "1497")
        if (targetKey == 'cubicCapacity' || targetKey == 'seatingCapacity') {
          final parsed = double.tryParse(finalValue);
          if (parsed != null) {
            finalValue = parsed.round().toString();
          }
        }

        updateField(targetKey, finalValue);
        updatedAny = true;
      }
    });

    // ── Blacklist Status: Boolean/String → "Yes"/"No" ──
    final blacklistValue = find([
      'blacklistStatus',
      'is_blacklisted',
      'blacklist_details',
    ]);
    if (blacklistValue != null) {
      final isBlacklisted =
          (blacklistValue == true ||
              blacklistValue.toString().toLowerCase() == 'true' ||
              blacklistValue.toString() == '1' ||
              blacklistValue.toString().toLowerCase() == 'yes');

      updateField('blacklistStatus', isBlacklisted ? 'Yes' : 'No');
      updatedAny = true;
    } else {
      // Default to No if return null
      updateField('blacklistStatus', 'No');
      updatedAny = true;
    }

    // ── 0. Hypothecation Details: boolean 'financed' → "Yes"/"No" ──
    final financedValue = find(['financed', 'is_financed', 'hypothecated']);
    if (financedValue != null) {
      final isFinanced =
          (financedValue == true ||
              financedValue.toString().toLowerCase() == 'true' ||
              financedValue.toString() == '1' ||
              financedValue.toString().toLowerCase() == 'yes');

      final hypothecationValue = isFinanced ? 'Yes' : 'No';
      updateField('hypothecationDetails', hypothecationValue);
      updatedAny = true;

      // If "Yes", fill 'hypothecatedTo' from 'lender'
      if (isFinanced) {
        final lenderValue = find(['lender', 'financed_to', 'hypothecated_to']);
        if (lenderValue != null) {
          updateField('hypothecatedTo', lenderValue.toString());
        }
      } else {
        updateField('hypothecatedTo', ''); // Clear if No
      }
    }

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
        final existingOptions =
            dropdownOptions['fuelType'] ??
            ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid', 'LPG'];
        if (!existingOptions.any(
          (o) => o.toLowerCase() == formattedFuel.toLowerCase(),
        )) {
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
        final existingOptions =
            dropdownOptions['rcStatus'] ?? ['Active', 'Inactive', 'Suspended'];
        if (!existingOptions.any(
          (o) => o.toLowerCase() == formattedStatus.toLowerCase(),
        )) {
          dropdownOptions['rcStatus'] = [...existingOptions, formattedStatus];
        }
        updateField('rcStatus', formattedStatus);
      }
      updatedAny = true;
    }

    // Note: Make / Model / Variant are now handled by _applyMakeModelVariantFromApi()

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
