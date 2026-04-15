import '../models/car_model.dart';
import '../models/inspection_form_model.dart';

/// Resolves uploaded media URLs from local paths using cloudinary data map.
List<String> _resolveMedia(
  List<String> localPaths,
  Map<String, Map<String, String>> cloudinaryData,
) {
  return localPaths
      .map((p) => cloudinaryData[p]?['url'] ?? p)
      .where((url) => url.startsWith('http'))
      .toList();
}

/// Gets a string value from the form data map.
String _s(InspectionFormModel d, String key) {
  final v = d.data[key];
  if (v == null) return '';
  if (v is List) {
    // If it's a list, join elements with a comma to avoid [val1, val2] string representation
    return v.map((e) => e.toString()).join(', ');
  }
  return v.toString();
}

/// Gets an int value from the form data map.
int _i(InspectionFormModel d, String key) {
  final v = d.data[key];
  if (v is int) return v;
  if (v is String) {
    return int.tryParse(v) ?? double.tryParse(v)?.round() ?? 0;
  }
  if (v is List && v.isNotEmpty) {
    final first = v.first;
    if (first is int) return first;
    if (first is String) return int.tryParse(first) ?? 0;
  }
  return 0;
}

/// Parses a DateTime from form data.
DateTime? _dt(InspectionFormModel d, String key) {
  final v = d.data[key];
  if (v == null) return null;
  if (v is DateTime) return v;

  String? vs;
  if (v is String) {
    vs = v;
  } else if (v is List && v.isNotEmpty) {
    final first = v.first;
    if (first is String) vs = first;
  }

  if (vs != null && vs.isNotEmpty) {
    // Try standard ISO parse first
    final iso = DateTime.tryParse(vs);
    if (iso != null) return iso;

    // Normalize separators: replace / with -
    final normalized = vs.replaceAll('/', '-');

    // Try DD-MM-YYYY format
    final parts = normalized.split('-');
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (p0 > 31) return DateTime(p0, p1, p2); // YYYY-MM-DD
        return DateTime(p2, p1, p0); // DD-MM-YYYY
      }
    }
    // Try MM-YYYY format
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final y = int.tryParse(parts[1]);
      if (m != null && y != null) return DateTime(y, m);
    }
  }

  if (v is num && v > 1000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  }

  return null;
}

/// Gets image list from imageFiles map, resolving URLs.
List<String> _imgs(
  String key,
  Map<String, List<String>> imageFiles,
  Map<String, Map<String, String>> cloudinaryData,
) {
  final paths = imageFiles[key] ?? [];
  return _resolveMedia(paths, cloudinaryData);
}

/// Builds a CarModel from inspection form data applying all comment rules.
CarModel buildCarModelFromForm(
  InspectionFormModel data,
  Map<String, List<String>> imageFiles,
  Map<String, Map<String, String>> cloudinaryData,
  String appointmentId, {
  String userEmail = '',
  String userName = '',
  String inspectionAddress = '',
  String appVersion = 'Unknown',
}) {
  // ── Helper shortcuts ──
  String s(String k) => _s(data, k);
  int i(String k) => _i(data, k);
  DateTime? dt(String k) => _dt(data, k);
  List<String> img(String k) => _imgs(k, imageFiles, cloudinaryData);

  // ── Pre-compute values for "changed to" fields ──
  List<String> asList(String k) {
    final raw = data.data[k];
    if (raw is List) return raw.map((e) => e.toString()).toList();

    final v = s(k);
    if (v.isEmpty) return [];
    if (v.contains(',')) return v.split(',').map((e) => e.trim()).toList();
    return [v];
  }

  // ── Pre-compute merged fields ──
  // musicSystem + stereo → infotainmentSystemDropdownList
  final musicVal = s('infotainmentSystem');
  final musicSystemOld = musicVal; // form uses 'infotainmentSystem' key
  final stereoOld = s('stereo'); // not in form, send empty

  // leatherSeats + fabricSeats → seatsUpholstery
  final seatsUpholsteryVal = s('seatsUpholstery');

  // steeringMountedAudioControl → divided into steeringMountedMediaControls + steeringMountedSystemControls
  final steeringAudioVal = s('steeringMountedAudioControl');
  final steeringMediaVal =
      s('steeringMountedSystemControls').isNotEmpty
          ? s('steeringMountedSystemControls')
          : steeringAudioVal;
  final steeringMediaControlsVal =
      s('steeringMountedMediaControls').isNotEmpty
          ? s('steeringMountedMediaControls')
          : steeringAudioVal;

  final airbagsList = [
    img('driverAirbagImages').firstOrNull ?? '',
    img('coDriverAirbagImages').firstOrNull ?? '',
    img('driverSeatAirbagImages').firstOrNull ?? '',
    img('coDriverSeatAirbagImages').firstOrNull ?? '',
    img('rhsCurtainAirbagImages').firstOrNull ?? '',
    img('lhsCurtainAirbagImages').firstOrNull ?? '',
    img('driverKneeAirbagImages').firstOrNull ?? '',
    img('coDriverKneeAirbagImages').firstOrNull ?? '',
    img('rhsRearSideAirbagImages').firstOrNull ?? '',
    img('lhsRearSideAirbagImages').firstOrNull ?? '',
  ];

  // apronLhsRhs → divided into lhsApronImages and rhsApronImages
  // The form has separate lhsApronImages and rhsApronImages
  final lhsApronImgs = img('lhsApronImages');
  final rhsApronImgs = img('rhsApronImages');

  // bonnetImages → divided into bonnetClosedImages, bonnetOpenImages and bonnetImages
  final bonnetOpenImgs = img('bonnetOpenImages');
  final bonnetClosedImgs = img('bonnetClosedImages');

  // frontBumperImages → divided into frontBumperLhs45DegreeImages, frontBumperRhs45DegreeImages and frontBumperImages
  final fbLhs45 = img('frontBumperLhs45DegreeImages');
  final fbRhs45 = img('frontBumperRhs45DegreeImages');
  final fbImgs = img('frontBumperImages');

  // rearBumperImages → divided
  final rbLhs45 = img('rearBumperLhs45DegreeImages');
  final rbRhs45 = img('rearBumperRhs45DegreeImages');
  final rbImgs = img('rearBumperImages');

  // lhsQuarterPanelImages → divided into Open and Closed
  final lhsQPWithDoorOpen = img('lhsQuarterPanelWithRearDoorOpenImages');
  final lhsQPWithDoorClosed = img('lhsQuarterPanelWithRearDoorClosedImages');

  // rhsQuarterPanelImages → divided into Open and Closed
  final rhsQPWithDoorOpen = img('rhsQuarterPanelWithRearDoorOpenImages');
  final rhsQPWithDoorClosed = img('rhsQuarterPanelWithRearDoorClosedImages');

  return CarModel(
    id: data.id,
    timestamp: DateTime.now(),
    // Use logged-in user's email; fall back to form data
    emailAddress: userEmail.isNotEmpty ? userEmail : s('emailAddress'),
    appointmentId:
        s('appointmentId').isNotEmpty ? s('appointmentId') : appointmentId,
    // renamed to inspectionCity
    city: s('city'),
    inspectionDate: dt('inspectionDate'),
    // removed
    registrationType: s('registrationType'),
    // changed to rcBookAvailabilityDropdownList
    rcBookAvailability: s('rcBookAvailability'),
    rcCondition: s('rcCondition'),
    registrationNumber: s('registrationNumber').toUpperCase(),
    registrationDate: dt('registrationDate'),
    // renamed to fitnessValidity
    fitnessTill: dt('fitnessValidity'),
    toBeScrapped: s('toBeScrapped'),
    registrationState: s('registrationState'),
    registeredRto: s('registeredRto'),
    ownerSerialNumber: i('ownerSerialNumber'),
    make: s('make'),
    model: s('model'),
    variant: s('variant'),
    engineNumber: s('engineNumber'),
    chassisNumber: s('chassisNumber'),
    registeredOwner: s('registeredOwner'),
    registeredAddressAsPerRc: s('registeredAddressAsPerRc'),
    // renamed to yearAndMonthOfManufacture
    yearMonthOfManufacture: dt('yearMonthOfManufacture'),
    fuelType: s('fuelType'),
    cubicCapacity: i('cubicCapacity'),
    hypothecationDetails: s('hypothecationDetails'),
    // changed to mismatchInRcDropdownList
    mismatchInRc: s('mismatchInRc'),
    roadTaxValidity: s('roadTaxValidity'),
    taxValidTill: dt('taxValidTill'),
    // changed to insuranceDropdownList
    insurance: s('insurance'),
    // renamed to policyNumber
    insurancePolicyNumber: s('insurancePolicyNumber'),
    insuranceValidity: dt('insuranceValidity'),
    // removed
    noClaimBonus: s('noClaimBonus'),
    // changed to mismatchInInsuranceDropdownList
    mismatchInInsurance: s('mismatchInInsurance'),
    duplicateKey: s('duplicateKey'),
    rtoNoc: s('rtoNoc'),
    rtoForm28: s('rtoForm28'),
    partyPeshi: s('partyPeshi'),
    // changed to additionalDetailsDropdownList
    additionalDetails: s('additionalDetails'),
    // renamed to rcTokenImages
    rcTaxToken: img('rcTokenImages'),
    // renamed to insuranceImages
    insuranceCopy: img('insuranceImages'),
    // renamed to duplicateKeyImages
    bothKeys: img('duplicateKeyImages'),
    // renamed to form26AndGdCopyIfRcIsLostImages
    form26GdCopyIfRcIsLost: img('form26AndGdCopyIfRcIsLostImages'),
    // changed to bonnetDropdownList
    bonnet: s('bonnet'),
    // changed to frontWindshieldDropdownList
    frontWindshield: s('frontWindshield'),
    // changed to roofDropdownList
    roof: s('roof'),
    // changed to frontBumperDropdownList
    frontBumper: s('frontBumper'),
    // changed to lhsHeadlampDropdownList
    lhsHeadlamp: s('lhsHeadlamp'),
    lhsFoglamp: s('lhsFoglamp'),
    rhsHeadlamp: s('rhsHeadlamp'),
    rhsFoglamp: s('rhsFoglamp'),
    lhsFender: s('lhsFender'),
    lhsOrvm: s('lhsOrvm'),
    lhsAPillar: s('lhsAPillar'),
    lhsBPillar: s('lhsBPillar'),
    lhsCPillar: s('lhsCPillar'),
    // renamed to lhsFrontWheelDropdownList
    lhsFrontAlloy: s('lhsFrontAlloy'),
    lhsFrontTyre: s('lhsFrontTyre'),
    // renamed to lhsRearWheelDropdownList
    lhsRearAlloy: s('lhsRearAlloy'),
    lhsRearTyre: s('lhsRearTyre'),
    lhsFrontDoor: s('lhsFrontDoor'),
    lhsRearDoor: s('lhsRearDoor'),
    lhsRunningBorder: s('lhsRunningBorder'),
    lhsQuarterPanel: s('lhsQuarterPanel'),
    rearBumper: s('rearBumper'),
    lhsTailLamp: s('lhsTailLamp'),
    rhsTailLamp: s('rhsTailLamp'),
    rearWindshield: s('rearWindshield'),
    bootDoor: s('bootDoor'),
    spareTyre: s('spareTyre'),
    bootFloor: s('bootFloor'),
    // renamed to rhsRearWheelDropdownList
    rhsRearAlloy: s('rhsRearAlloy'),
    rhsRearTyre: s('rhsRearTyre'),
    // renamed to rhsFrontWheelDropdownList
    rhsFrontAlloy: s('rhsFrontAlloy'),
    rhsFrontTyre: s('rhsFrontTyre'),
    rhsQuarterPanel: s('rhsQuarterPanel'),
    rhsAPillar: s('rhsAPillar'),
    rhsBPillar: s('rhsBPillar'),
    rhsCPillar: s('rhsCPillar'),
    rhsRunningBorder: s('rhsRunningBorder'),
    rhsRearDoor: s('rhsRearDoor'),
    rhsFrontDoor: s('rhsFrontDoor'),
    rhsOrvm: s('rhsOrvm'),
    rhsFender: s('rhsFender'),
    // renamed to commentsOnExteriorDropdownList
    comments: s('comments'),
    // changed to frontMainImages
    frontMain: img('frontMainImages'),
    // divided into bonnetClosedImages, bonnetOpenImages and bonnetImages
    bonnetImages: [...bonnetClosedImgs, ...bonnetOpenImgs],
    frontWindshieldImages: img('frontWindshieldImages'),
    roofImages: img('roofImages'),
    // divided
    frontBumperImages: [...fbLhs45, ...fbRhs45, ...fbImgs],
    lhsHeadlampImages: img('lhsHeadlampImages'),
    lhsFoglampImages: img('lhsFoglampImages'),
    rhsHeadlampImages: img('rhsHeadlampImages'),
    rhsFoglampImages: img('rhsFoglampImages'),
    // renamed to lhsFullViewImages
    lhsFront45Degree: img('lhsFullViewImages'),
    lhsFenderImages: img('lhsFenderImages'),
    // renamed to lhsFrontWheelImages
    lhsFrontAlloyImages: img('lhsFrontWheelImages'),
    lhsFrontTyreImages: img('lhsFrontTyreImages'),
    lhsRunningBorderImages: img('lhsRunningBorderImages'),
    lhsOrvmImages: img('lhsOrvmImages'),
    lhsAPillarImages: img('lhsAPillarImages'),
    lhsFrontDoorImages: img('lhsFrontDoorImages'),
    lhsBPillarImages: img('lhsBPillarImages'),
    lhsRearDoorImages: img('lhsRearDoorImages'),
    lhsCPillarImages: img('lhsCPillarImages'),
    lhsRearTyreImages: img('lhsRearTyreImages'),
    // renamed to lhsRearWheelImages
    lhsRearAlloyImages: img('lhsRearWheelImages'),
    // divided into lhsQuarterPanelWithRearDoorOpenImages and lhsQuarterPanelWithRearDoorClosedImages
    lhsQuarterPanelImages: [
      lhsQPWithDoorOpen.firstOrNull ?? '',
      lhsQPWithDoorClosed.firstOrNull ?? '',
    ],
    // renamed to rearMainImages
    rearMain: img('rearMainImages'),
    // renamed to rearWithBootDoorOpenImages
    rearWithBootDoorOpen:
        img('rearWithBootDoorOpenImages').isNotEmpty
            ? img('rearWithBootDoorOpenImages').first
            : '',
    // divided
    rearBumperImages: [...rbLhs45, ...rbRhs45, ...rbImgs],
    lhsTailLampImages: img('lhsTailLampImages'),
    rhsTailLampImages: img('rhsTailLampImages'),
    rearWindshieldImages: img('rearWindshieldImages'),
    spareTyreImages: img('spareTyreImages'),
    bootFloorImages: img('bootFloorImages'),
    // renamed to rhsFullViewImages
    rhsRear45Degree: img('rhsFullViewImages'),
    // divided into rhsQuarterPanelWithRearDoorOpenImages and rhsQuarterPanelWithRearDoorClosedImages
    rhsQuarterPanelImages: [
      rhsQPWithDoorOpen.firstOrNull ?? '',
      rhsQPWithDoorClosed.firstOrNull ?? '',
    ],
    // renamed to rhsRearWheelImages
    rhsRearAlloyImages: img('rhsRearWheelImages'),
    rhsRearTyreImages: img('rhsRearTyreImages'),
    rhsCPillarImages: img('rhsCPillarImages'),
    rhsRearDoorImages: img('rhsRearDoorImages'),
    rhsBPillarImages: img('rhsBPillarImages'),
    rhsFrontDoorImages: img('rhsFrontDoorImages'),
    rhsAPillarImages: img('rhsAPillarImages'),
    rhsRunningBorderImages: img('rhsRunningBorderImages'),
    // renamed to rhsFrontWheelImages
    rhsFrontAlloyImages: img('rhsFrontWheelImages'),
    rhsFrontTyreImages: img('rhsFrontTyreImages'),
    rhsOrvmImages: img('rhsOrvmImages'),
    rhsFenderImages: img('rhsFenderImages'),
    // changed
    upperCrossMember: s('upperCrossMember'),
    radiatorSupport: s('radiatorSupport'),
    headlightSupport: s('headlightSupport'),
    lowerCrossMember: s('lowerCrossMember'),
    lhsApron: s('lhsApron'),
    rhsApron: s('rhsApron'),
    firewall: s('firewall'),
    cowlTop: s('cowlTop'),
    engine: s('engine'),
    battery: s('battery'),
    coolant: s('coolant'),
    engineOilLevelDipstick: s('engineOilLevelDipstick'),
    engineOil: s('engineOil'),
    engineMount: s('engineMount'),
    enginePermisableBlowBy: s('enginePermisableBlowBy'),
    exhaustSmoke: s('exhaustSmoke'),
    clutch: s('clutch'),
    gearShift: s('gearShift'),
    commentsOnEngine: s('commentsOnEngine'),
    commentsOnEngineOil: s('commentsOnEngineOil'),
    commentsOnTowing: s('commentsOnTowing'),
    commentsOnTransmission: s('commentsOnTransmission'),
    commentsOnRadiator: s('commentsOnRadiator'),
    commentsOnOthers: s('commentsOnOthers'),
    // renamed to engineBayImages
    engineBay: img('engineBayImages'),
    // removed and divided into lhsApronImages and rhsApronImages
    apronLhsRhs: [...lhsApronImgs, ...rhsApronImgs],
    batteryImages: img('batteryImages'),
    // renamed to additionalEngineImages
    additionalImages: img('additionalImages'),
    // renamed to engineVideo
    engineSound: img('engineVideo'),
    // renamed to exhaustSmokeVideo
    exhaustSmokeImages: img('exhaustSmokeVideo'),
    // changed
    steering: s('steering'),
    brakes: s('brakes'),
    suspension: s('suspension'),
    // renamed to odometerReadingBeforeTestDrive
    odometerReadingInKms: i('odometerReadingInKms'),
    fuelLevel: s('fuelLevel'),
    abs: s('abs'),
    // removed
    electricals: s('electricals'),
    rearWiperWasher: s('rearWiperWasher'),
    rearDefogger: s('rearDefogger'),
    // removed and merged into infotainmentSystemDropdownList
    musicSystem: musicSystemOld,
    stereo: stereoOld,
    inbuiltSpeaker: s('inbuiltSpeaker'),
    externalSpeaker: s('externalSpeaker'),
    // removed and divided
    steeringMountedAudioControl: steeringAudioVal,
    noOfPowerWindows: s('noOfPowerWindows'),
    // renamed
    powerWindowConditionRhsFront: s('powerWindowConditionRhsFront'),
    powerWindowConditionLhsFront: s('powerWindowConditionLhsFront'),
    powerWindowConditionRhsRear: s('powerWindowConditionRhsRear'),
    powerWindowConditionLhsRear: s('powerWindowConditionLhsRear'),
    // changed
    commentOnInterior: s('commentOnInterior'),
    noOfAirBags: i('noOfAirBags'),
    // renamed
    airbagFeaturesDriverSide: s('airbagFeaturesDriverSide'),
    airbagFeaturesCoDriverSide: s('airbagFeaturesCoDriverSide'),
    airbagFeaturesLhsAPillarCurtain:
        s('airbagFeaturesLhsAPillarCurtain').isNotEmpty
            ? s('airbagFeaturesLhsAPillarCurtain')
            : s('coDriverSeatAirbag'),
    airbagFeaturesLhsBPillarCurtain:
        s('airbagFeaturesLhsBPillarCurtain').isNotEmpty
            ? s('airbagFeaturesLhsBPillarCurtain')
            : s('lhsCurtainAirbag'),
    airbagFeaturesLhsCPillarCurtain:
        s('airbagFeaturesLhsCPillarCurtain').isNotEmpty
            ? s('airbagFeaturesLhsCPillarCurtain')
            : s('lhsRearSideAirbag'),
    airbagFeaturesRhsAPillarCurtain:
        s('airbagFeaturesRhsAPillarCurtain').isNotEmpty
            ? s('airbagFeaturesRhsAPillarCurtain')
            : s('driverSeatAirbag'),
    airbagFeaturesRhsBPillarCurtain:
        s('airbagFeaturesRhsBPillarCurtain').isNotEmpty
            ? s('airbagFeaturesRhsBPillarCurtain')
            : s('rhsCurtainAirbag'),
    airbagFeaturesRhsCPillarCurtain:
        s('airbagFeaturesRhsCPillarCurtain').isNotEmpty
            ? s('airbagFeaturesRhsCPillarCurtain')
            : s('rhsRearSideAirbag'),
    // changed
    sunroof: s('sunroof'),
    // removed and merged to seatsUpholstery
    leatherSeats: seatsUpholsteryVal == 'Leather' ? 'Yes' : '',
    fabricSeats: seatsUpholsteryVal == 'Fabric' ? 'Yes' : '',
    // removed
    commentsOnElectricals: s('commentsOnElectricals'),
    // renamed
    meterConsoleWithEngineOn: img('meterConsoleWithEngineOnImages'),
    sunroofImages: img('sunroofImages'),
    frontSeatsFromDriverSideDoorOpen: img('frontSeatsFromDriverSideImages'),
    rearSeatsFromRightSideDoorOpen: img('rearSeatsFromRightSideImages'),
    dashboardFromRearSeat: img('dashboardImages'),
    reverseCamera: s('reverseCamera'),
    additionalImages2: img('additionalInteriorImages'),
    // renamed
    airConditioningManual: s('acType'),
    airConditioningClimateControl: s('acCooling'),
    commentsOnAc: s('commentsOnAC'),
    approvedBy: s('approvedBy'),
    approvalDate: dt('approvalDate'),
    approvalTime: dt('approvalTime'),
    approvalStatus: s('approvalStatus'),
    contactNumber: s('contactNumber'),
    newArrivalMessage: dt('newArrivalMessage'),
    budgetCar: s('budgetCar'),
    status: s('status'),
    priceDiscovery: i('priceDiscovery'),
    priceDiscoveryBy: s('priceDiscoveryBy'),
    latlong: inspectionAddress.isNotEmpty ? inspectionAddress : s('latlong'),
    retailAssociate: s('retailAssociate'),
    kmRangeLevel: i('kmRangeLevel'),
    highestBidder: s('highestBidder'),
    v: i('__v'),
    version: appVersion,

    // ✅ New fields (all nullable) — below the comment line
    ieName:
        userName.isNotEmpty
            ? userName
            : s('emailAddress'), // logged-in user's username
    inspectionCity: s('city'), // renamed from city
    rcBookAvailabilityDropdownList: asList('rcBookAvailability'),
    fitnessValidity: dt('fitnessValidity'),
    yearAndMonthOfManufacture: dt('yearMonthOfManufacture'),
    mismatchInRcDropdownList: asList('mismatchInRc'),
    insuranceDropdownList: asList('insurance'),
    policyNumber: s('insurancePolicyNumber'),
    mismatchInInsuranceDropdownList: asList('mismatchInInsurance'),
    additionalDetailsDropdownList: asList('additionalDetails'),
    rcTokenImages: img('rcTokenImages'),
    insuranceImages: img('insuranceImages'),
    duplicateKeyImages: img('duplicateKeyImages'),
    form26AndGdCopyIfRcIsLostImages: img('form26AndGdCopyIfRcIsLostImages'),
    bonnetDropdownList: asList('bonnet'),
    frontWindshieldDropdownList: asList('frontWindshield'),
    roofDropdownList: asList('roof'),
    frontBumperDropdownList: asList('frontBumper'),
    lhsHeadlampDropdownList: asList('lhsHeadlamp'),
    lhsFoglampDropdownList: asList('lhsFoglamp'),
    rhsHeadlampDropdownList: asList('rhsHeadlamp'),
    rhsFoglampDropdownList: asList('rhsFoglamp'),
    lhsFenderDropdownList: asList('lhsFender'),
    lhsOrvmDropdownList: asList('lhsOrvm'),
    lhsAPillarDropdownList: asList('lhsAPillar'),
    lhsBPillarDropdownList: asList('lhsBPillar'),
    lhsCPillarDropdownList: asList('lhsCPillar'),
    lhsFrontWheelDropdownList: asList('lhsFrontAlloy'),
    lhsFrontTyreDropdownList: asList('lhsFrontTyre'),
    lhsRearWheelDropdownList: asList('lhsRearAlloy'),
    lhsRearTyreDropdownList: asList('lhsRearTyre'),
    lhsFrontDoorDropdownList: asList('lhsFrontDoor'),
    lhsRearDoorDropdownList: asList('lhsRearDoor'),
    lhsRunningBorderDropdownList: asList('lhsRunningBorder'),
    lhsQuarterPanelDropdownList: asList('lhsQuarterPanel'),
    rearBumperDropdownList: asList('rearBumper'),
    lhsTailLampDropdownList: asList('lhsTailLamp'),
    rhsTailLampDropdownList: asList('rhsTailLamp'),
    rearWindshieldDropdownList: asList('rearWindshield'),
    bootDoorDropdownList: asList('bootDoor'),
    spareTyreDropdownList: asList('spareTyre'),
    bootFloorDropdownList: asList('bootFloor'),
    rhsRearWheelDropdownList: asList('rhsRearAlloy'),
    rhsRearTyreDropdownList: asList('rhsRearTyre'),
    rhsFrontWheelDropdownList: asList('rhsFrontAlloy'),
    rhsFrontTyreDropdownList: asList('rhsFrontTyre'),
    rhsQuarterPanelDropdownList: asList('rhsQuarterPanel'),
    rhsAPillarDropdownList: asList('rhsAPillar'),
    rhsBPillarDropdownList: asList('rhsBPillar'),
    rhsCPillarDropdownList: asList('rhsCPillar'),
    rhsRunningBorderDropdownList: asList('rhsRunningBorder'),
    rhsRearDoorDropdownList: asList('rhsRearDoor'),
    rhsFrontDoorDropdownList: asList('rhsFrontDoor'),
    rhsOrvmDropdownList: asList('rhsOrvm'),
    rhsFenderDropdownList: asList('rhsFender'),
    commentsOnExteriorDropdownList: asList('comments'),
    frontMainImages: img('frontMainImages'),
    bonnetClosedImages: bonnetClosedImgs,
    bonnetOpenImages: bonnetOpenImgs,
    frontBumperLhs45DegreeImages: fbLhs45,
    frontBumperRhs45DegreeImages: fbRhs45,
    lhsFullViewImages: img('lhsFullViewImages'),
    lhsFrontWheelImages: img('lhsFrontWheelImages'),
    lhsRearWheelImages: img('lhsRearWheelImages'),
    lhsQuarterPanelWithRearDoorOpenImages: lhsQPWithDoorOpen,
    lhsQuarterPanelWithRearDoorClosedImages: lhsQPWithDoorClosed,
    rearMainImages: img('rearMainImages'),
    rearWithBootDoorOpenImages: img('rearWithBootDoorOpenImages'),
    bootDoorImages: img('bootDoorImages'),
    rearBumperLhs45DegreeImages: rbLhs45,
    rearBumperRhs45DegreeImages: rbRhs45,
    rhsFullViewImages: img('rhsFullViewImages'),
    rhsQuarterPanelWithRearDoorOpenImages: rhsQPWithDoorOpen,
    rhsQuarterPanelWithRearDoorClosedImages: rhsQPWithDoorClosed,
    rhsRearWheelImages: img('rhsRearWheelImages'),
    rhsFrontWheelImages: img('rhsFrontWheelImages'),
    upperCrossMemberDropdownList: asList('upperCrossMember'),
    radiatorSupportDropdownList: asList('radiatorSupport'),
    headlightSupportDropdownList: asList('headlightSupport'),
    lowerCrossMemberDropdownList: asList('lowerCrossMember'),
    lhsApronDropdownList: asList('lhsApron'),
    rhsApronDropdownList: asList('rhsApron'),
    firewallDropdownList: asList('firewall'),
    cowlTopDropdownList: asList('cowlTop'),
    engineDropdownList: asList('engine'),
    batteryDropdownList: asList('battery'),
    coolantDropdownList: asList('coolant'),
    engineOilLevelDipstickDropdownList: asList('engineOilLevelDipstick'),
    engineOilDropdownList: asList('engineOil'),
    engineMountDropdownList: asList('engineMount'),
    enginePermisableBlowByDropdownList: asList('enginePermisableBlowBy'),
    exhaustSmokeDropdownList: asList('exhaustSmoke'),
    clutchDropdownList: asList('clutch'),
    gearShiftDropdownList: asList('gearShift'),
    commentsOnEngineDropdownList: asList('commentsOnEngine'),
    commentsOnEngineOilDropdownList: asList('commentsOnEngineOil'),
    commentsOnTowingDropdownList: asList('commentsOnTowing'),
    commentsOnTransmissionDropdownList: asList('commentsOnTransmission'),
    commentsOnRadiatorDropdownList: asList('commentsOnRadiator'),
    commentsOnOthersDropdownList: asList('commentsOnOthers'),
    engineBayImages: img('engineBayImages'),
    lhsApronImages: lhsApronImgs,
    rhsApronImages: rhsApronImgs,
    additionalEngineImages: img('additionalImages'),
    engineVideo: img('engineVideo'),
    exhaustSmokeVideo: img('exhaustSmokeVideo'),
    steeringDropdownList: asList('steering'),
    brakesDropdownList: asList('brakes'),
    suspensionDropdownList: asList('suspension'),
    odometerReadingBeforeTestDrive: i('odometerReadingInKms'),
    rearWiperWasherDropdownList: asList('rearWiperWasher'),
    rearDefoggerDropdownList: asList('rearDefogger'),
    infotainmentSystemDropdownList: asList('infotainmentSystem'),
    steeringMountedMediaControls: steeringMediaControlsVal,
    steeringMountedSystemControls: steeringMediaVal,
    rhsFrontDoorFeaturesDropdownList: asList('powerWindowConditionRhsFront'),
    lhsFrontDoorFeaturesDropdownList: asList('powerWindowConditionLhsFront'),
    rhsRearDoorFeaturesDropdownList: asList('powerWindowConditionRhsRear'),
    lhsRearDoorFeaturesDropdownList: asList('powerWindowConditionLhsRear'),
    commentOnInteriorDropdownList: asList('commentOnInterior'),
    driverAirbag: s('airbagFeaturesDriverSide'),
    coDriverAirbag: s('airbagFeaturesCoDriverSide'),
    coDriverSeatAirbag: s('coDriverSeatAirbag'),
    lhsCurtainAirbag: s('lhsCurtainAirbag'),
    lhsRearSideAirbag: s('lhsRearSideAirbag'),
    driverSeatAirbag: s('driverSeatAirbag'),
    rhsCurtainAirbag: s('rhsCurtainAirbag'),
    rhsRearSideAirbag: s('rhsRearSideAirbag'),
    sunroofDropdownList: asList('sunroof'),
    seatsUpholstery: seatsUpholsteryVal,
    meterConsoleWithEngineOnImages: img('meterConsoleWithEngineOnImages'),
    airbagImages: airbagsList,
    frontSeatsFromDriverSideImages: img('frontSeatsFromDriverSideImages'),
    rearSeatsFromRightSideImages: img('rearSeatsFromRightSideImages'),
    dashboardImages: img('dashboardImages'),
    reverseCameraDropdownList: asList('reverseCamera'),
    additionalInteriorImages: img('additionalInteriorImages'),
    acTypeDropdownList: s('acType'),
    acCoolingDropdownList: s('acCooling'),
    // Fresh new-only fields
    chassisEmbossmentImages: img('chassisEmbossmentImages'),
    chassisDetails: s('chassisDetails'),
    vinPlateImages: img('vinPlateImages'),
    vinPlateDetails: s('vinPlateDetails'),
    roadTaxImages: img('roadTaxImages'),
    seatingCapacity: i('seatingCapacity'),
    color: s('color'),
    numberOfCylinders: i('numberOfCylinders'),
    norms: s('norms'),
    hypothecatedTo: s('hypothecatedTo'),
    insurer: s('insurer'),
    pucImages: img('pucImages'),
    pucValidity: dt('pucValidity'),
    pucNumber: s('pucNumber'),
    rcStatus: s('rcStatus'),
    blacklistStatus: s('blacklistStatus'),
    rtoNocImages: img('rtoNocImages'),
    rtoForm28Images: img('rtoForm28Images'),
    frontWiperAndWasherDropdownList: asList('frontWiperAndWasher'),
    frontWiperAndWasherImages: img('frontWiperAndWasherImages'),
    lhsRearFogLampDropdownList: asList('lhsRearFogLamp'),
    lhsRearFogLampImages: img('lhsRearFogLampImages'),
    rhsRearFogLampDropdownList: asList('rhsRearFogLamp'),
    rhsRearFogLampImages: img('rhsRearFogLampImages'),
    rearWiperAndWasherImages: img('rearWiperAndWasherImages'),
    spareWheelDropdownList: asList('spareWheel'),
    spareWheelImages: img('spareWheelImages'),
    cowlTopImages: img('cowlTopImages'),
    firewallImages: img('firewallImages'),
    lhsSideMemberDropdownList: asList('lhsSideMember'),
    rhsSideMemberDropdownList: asList('rhsSideMember'),
    transmissionTypeDropdownList: asList('transmissionType'),
    driveTrainDropdownList: asList('driveTrain'),
    commentsOnClusterMeterDropdownList: asList('commentsOnClusterMeter'),
    irvm: s('irvm'),
    dashboardDropdownList: asList('dashboard'),
    acImages: img('acImages'),
    reverseCameraImages: img('reverseCameraImages'),
    driverSideKneeAirbag: s('driverSideKneeAirbag'),
    coDriverKneeSeatAirbag: s('coDriverKneeSeatAirbag'),
    driverSeatDropdownList: asList('driverSeat'),
    coDriverSeatDropdownList: asList('coDriverSeat'),
    frontCentreArmRestDropdownList: asList('frontCentreArmRest'),
    rearSeatsDropdownList: asList('rearSeats'),
    thirdRowSeatsDropdownList: asList('thirdRowSeats'),
    odometerReadingAfterTestDriveImages: img(
      'odometerReadingAfterTestDriveImages',
    ),
    odometerReadingAfterTestDriveInKms: i('odometerReadingAfterTestDriveInKms'),
    attesterRawCarDetails: data.data['attesterRawCarDetails'],
  );
}
