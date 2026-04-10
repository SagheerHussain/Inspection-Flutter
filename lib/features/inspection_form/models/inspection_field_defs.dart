import 'package:flutter/material.dart';

/// Field type enum
enum FType {
  text,
  dropdown,
  image,
  number,
  video,
  date,
  multiSelect,
  searchable,
  dateTime,
}

/// Single form field definition
class F {
  final String key;
  final String label;
  final FType type;
  final List<String> options;
  final bool optional;
  final bool readonly;
  final int maxLines;
  final int minImages;
  final int maxImages;
  final int? maxDuration;

  const F.text(
    this.key,
    this.label, {
    this.optional = false,
    this.readonly = false,
    this.maxLines = 1,
  }) : type = FType.text,
       options = const [],
       minImages = 0,
       maxImages = 0,
       maxDuration = null;

  const F.drop(this.key, this.label, this.options, {this.optional = false})
    : type = FType.dropdown,
      readonly = false,
      maxLines = 1,
      minImages = 0,
      maxImages = 0,
      maxDuration = null;

  const F.dateTime(this.key, this.label, {this.optional = false})
    : type = FType.dateTime,
      options = const [],
      readonly = false,
      maxLines = 1,
      minImages = 0,
      maxImages = 0,
      maxDuration = null;

  const F.multi(this.key, this.label, this.options, {this.optional = false})
    : type = FType.multiSelect,
      readonly = false,
      maxLines = 1,
      minImages = 0,
      maxImages = 0,
      maxDuration = null;

  const F.searchable(this.key, this.label, {this.optional = false})
    : type = FType.searchable,
      options = const [],
      readonly = false,
      maxLines = 1,
      minImages = 0,
      maxImages = 0,
      maxDuration = null;

  const F.img(
    this.key,
    this.label, {
    this.optional = false,
    this.minImages = 1,
    this.maxImages = 3,
  }) : type = FType.image,
       options = const [],
       readonly = false,
       maxLines = 1,
       maxDuration = null;

  const F.num(this.key, this.label, {this.optional = false})
    : type = FType.number,
      options = const [],
      readonly = false,
      maxLines = 1,
      minImages = 0,
      maxImages = 0,
      maxDuration = null;

  const F.date(this.key, this.label, {this.optional = false})
    : type = FType.date,
      options = const [],
      readonly = false,
      maxLines = 1,
      minImages = 0,
      maxImages = 0,
      maxDuration = null;

  const F.video(
    this.key,
    this.label, {
    this.optional = false,
    this.minImages = 1,
    this.maxImages = 1,
    this.maxDuration,
  }) : type = FType.video,
       options = const [],
       readonly = false,
       maxLines = 1;
}

/// A section in the form
class FormSectionDef {
  final String title;
  final IconData icon;
  final List<F> fields;
  const FormSectionDef({
    required this.title,
    required this.icon,
    required this.fields,
  });
}

/// All 9 sections with exact fields from API payload
class InspectionFieldDefs {
  InspectionFieldDefs._();

  static const List<FormSectionDef> sections = [
    // ═══════════════════════════════════════
    // 1. DOCUMENTS
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Document Details',
      icon: Icons.description,
      fields: [
        F.text('appointmentId', 'Appointment ID', readonly: true),
        F.text('city', 'City'),
        F.text('registrationNumber', 'Registration Number'),
        // F.text('registrationType', 'Registration Type', optional: true),
        F.drop('toBeScrapped', 'To Be Scrapped', ['Yes', 'No']),
        F.multi('chassisDetails', 'Chassis Details', []),
        F.img('chassisEmbossmentImages', 'Chassis Embossment Image'),
        F.multi('vinPlateDetails', 'Vin Plate Details', []),
        F.img('vinPlateImages', 'Vin Plate Image'),
        F.drop('rcBookAvailability', 'RC Book Availability', [
          'Original',
          'Duplicate',
          'Not Available',
        ]),
        F.drop('rcCondition', 'RC Condition', [
          'Good',
          'Fair',
          'Poor',
          'Damaged',
        ]),
        F.img('rcTokenImages', 'RC Image', minImages: 2),
        F.dateTime('inspectionDate', 'Inspection Date', optional: true),
        F.multi('mismatchInRc', 'Mismatch in RC', ['No', 'Yes']),
        F.date('registrationDate', 'Registration Date'),
        F.date('fitnessValidity', 'Fitness Validity'),
        F.text('engineNumber', 'Engine Number'),
        F.text('chassisNumber', 'Chassis Number'),
        F.searchable('make', 'Make'),
        F.searchable('model', 'Model'),
        F.searchable('variant', 'Variant'),
        F.date('yearMonthOfManufacture', 'Vehicle Manufacture'),
        F.drop('fuelType', 'Fuel Type', [
          'Petrol',
          'Diesel',
          'CNG',
          'Electric',
          'Hybrid',
          'LPG',
        ]),
        F.num('seatingCapacity', 'Seating Capacity'),
        F.text('color', 'Color'),
        F.num('cubicCapacity', 'Cubic Capacity'),
        F.text('norms', 'Norms'),
        F.text('registrationState', 'Registration State'),
        F.text('registeredRto', 'Registered RTO'),
        F.num('ownerSerialNumber', 'Ownership Serial No'),
        F.text('registeredOwner', 'Registered Owner'),
        F.text(
          'registeredAddressAsPerRc',
          'Registered Address as per RC',
          maxLines: 3,
        ),
        F.drop('roadTaxValidity', 'Road Tax Validity', [
          'Limited Period',
          'Valid',
          'Expired',
          'Lifetime',
          'LTT',
          'OTT',
        ]),
        F.date('taxValidTill', 'Tax Valid Till'),
        F.img('roadTaxImages', 'Road Tax Image', minImages: 1),
        F.text('hypothecationDetails', 'Hypothecation Details'),
        F.text('hypothecatedTo', 'Hypothecated To'),
        F.drop('insurance', 'Insurance Type', [
          'Comprehensive',
          'Third Party',
          'Expired',
          'Not Available',
          'Policy Not Available',
        ]),
        F.date('insuranceValidity', 'Insurance Validity'),
        F.text('insurer', 'Insured By'),
        F.text('insurancePolicyNumber', 'Policy Number'),
        F.img('insuranceImages', 'Insurance Image'),
        // F.text('noClaimBonus', 'No Claim Bonus', optional: true),
        // F.text('mismatchInInsurance', 'Mismatch In Insurance', optional: true),
        F.date('pucValidity', 'PUC Validity'),
        F.text('pucNumber', 'PUC Number'),
        F.img('pucImages', 'PUC Image', optional: true),
        F.drop('rcStatus', 'RC Status', ['Active', 'Inactive', 'Suspended']),
        F.text('blacklistStatus', 'Blacklist Status'),
        F.drop('rtoNoc', 'RTO NOC Details', [
          'Required',
          'Not Required',
          'Issued',
          'Not Applicable',
        ]),
        F.drop('rtoForm28', 'RTO Form 28 (2 Copies)', [
          'Required',
          'Not Required',
          'Available',
          'Missing',
        ]),
        F.drop('partyPeshi', 'Party Peshi', ['Yes', 'No']),
        F.drop('duplicateKey', 'Duplicate Key', [
          'Yes',
          'No',
          'Duplicate Key Available',
          'Available',
        ]),
        F.img('duplicateKeyImages', 'Duplicate Key Images'),
        F.multi('additionalDetails', 'Additional Details', [
          'Minor Dents',
          'Major Dents',
          'Minor Scratches',
          'Major Scratches',
          'Repainted',
          'Rusted',
        ], optional: true),
      ],
    ),

    // ═══════════════════════════════════════
    // 2. FRONT
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Front',
      icon: Icons.directions_car,
      fields: [
        F.img('frontMainImages', 'Front Main'),
        F.multi('bonnet', 'Bonnet', [
          'OK',
          'Repaint',
          'Dent',
          'Scratch',
          'Rust',
          'Replaced',
        ]),
        F.img('bonnetOpenImages', 'Bonnet Open'),
        F.img('bonnetClosedImages', 'Bonnet Closed'),
        F.multi('frontWindshield', 'Front Windshield', [
          'OK',
          'Crack',
          'Chip',
          'Replaced',
        ]),
        F.img('frontWindshieldImages', 'Front Windshield Image'),
        F.multi('frontWiperAndWasher', 'Front Wiper & Washer', [
          'Working',
          'Not Working',
        ]),
        F.img('frontWiperAndWasherImages', 'Front Wiper & Washer Image'),
        F.multi('roof', 'Roof', ['OK', 'Repaint', 'Dent', 'Scratch', 'Rust']),
        F.img('roofImages', 'Roof Image'),
        F.multi('frontBumper', 'Front Bumper', [
          'OK',
          'Scratch',
          'Crack',
          'Dent',
          'Replaced',
        ]),
        F.img('frontBumperLhs45DegreeImages', 'Front Bumper LHS 45'),
        F.img('frontBumperRhs45DegreeImages', 'Front Bumper RHS 45'),
        F.img('frontBumperImages', 'Front Bumper Image', optional: true),
        F.multi('lhsHeadlamp', 'LHS Headlamp', [
          'OK',
          'Broken',
          'Fogged',
          'Replaced',
        ]),
        F.img('lhsHeadlampImages', 'LHS Headlamp Image'),
        F.multi('lhsFoglamp', 'LHS Foglamp', [
          'OK',
          'Broken',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('lhsFoglampImages', 'LHS Foglamp Image'),
        F.multi('rhsHeadlamp', 'RHS Headlamp', [
          'OK',
          'Broken',
          'Fogged',
          'Replaced',
        ]),
        F.img('rhsHeadlampImages', 'RHS Headlamp Image'),
        F.multi('rhsFoglamp', 'RHS Foglamp', [
          'OK',
          'Broken',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('rhsFoglampImages', 'RHS Foglamp Image'),
      ],
    ),

    // ═══════════════════════════════════════
    // 3. LEFT
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Left',
      icon: Icons.arrow_back,
      fields: [
        F.img('lhsFullViewImages', 'LHS Full View'),
        F.multi('lhsFender', 'LHS Fender', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Rust',
          'Replaced',
        ]),
        F.img('lhsFenderImages', 'LHS Fender Image'),
        F.multi('lhsFrontAlloy', 'LHS Front Wheel', [
          'OK',
          'Bent',
          'Cracked',
          'Replaced',
        ]),
        F.img('lhsFrontWheelImages', 'LHS Front Wheel Image'),
        F.multi('lhsFrontTyre', 'LHS Front Tyre', [
          'OK',
          'Worn',
          'Bald',
          'Mismatched',
        ]),
        F.img('lhsFrontTyreImages', 'LHS Front Tyre Image'),
        F.multi('lhsOrvm', 'LHS ORVM', [
          'OK',
          'Broken',
          'Missing',
          'Scratched',
        ]),
        F.img('lhsOrvmImages', 'LHS ORVM Image'),
        F.multi('lhsAPillar', 'LHS A Pillar', [
          'OK',
          'Repaired',
          'Dented',
          'Repainted',
        ]),
        F.img('lhsAPillarImages', 'LHS A Pillar Image'),
        F.multi('lhsFrontDoor', 'LHS Front Door', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Replaced',
        ]),
        F.img('lhsFrontDoorImages', 'LHS Front Door Image'),
        F.multi('lhsBPillar', 'LHS B Pillar', [
          'OK',
          'Repaired',
          'Dented',
          'Repainted',
        ]),
        F.img('lhsBPillarImages', 'LHS B Pillar Image'),
        F.multi('lhsRearDoor', 'LHS Rear Door', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Replaced',
        ]),
        F.img('lhsRearDoorImages', 'LHS Rear Door Image'),
        F.multi('lhsCPillar', 'LHS C Pillar', [
          'OK',
          'Repaired',
          'Dented',
          'Repainted',
        ]),
        F.img('lhsCPillarImages', 'LHS C Pillar Image'),
        F.multi('lhsRunningBorder', 'LHS Running Border', [
          'OK',
          'Dent',
          'Rust',
          'Damaged',
        ]),
        F.img('lhsRunningBorderImages', 'LHS Running Border Image'),
        F.multi('lhsRearAlloy', 'LHS Rear Wheel', [
          'OK',
          'Bent',
          'Cracked',
          'Replaced',
        ]),
        F.img('lhsRearWheelImages', 'LHS Rear Wheel Image'),
        F.multi('lhsRearTyre', 'LHS Rear Tyre', [
          'OK',
          'Worn',
          'Bald',
          'Mismatched',
        ]),
        F.img('lhsRearTyreImages', 'LHS Rear Tyre Image'),
        F.multi('lhsQuarterPanel', 'LHS Quarter Panel', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Replaced',
        ]),
        F.img(
          'lhsQuarterPanelWithRearDoorOpenImages',
          'LHS Quarter Panel With Boot Door Open Image',
        ),
        F.img('lhsQuarterPanelImages', 'LHS Quarter Panel Image'),
      ],
    ),

    // ═══════════════════════════════════════
    // 4. REAR
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Rear',
      icon: Icons.arrow_downward,
      fields: [
        F.img('rearMainImages', 'Rear Main'),
        F.multi('rearBumper', 'Rear Bumper', [
          'OK',
          'Scratch',
          'Crack',
          'Dent',
          'Replaced',
        ]),
        F.img('rearBumperLhs45DegreeImages', 'Rear Bumper LHS 45'),
        F.img('rearBumperRhs45DegreeImages', 'Rear Bumper RHS 45'),
        F.img('rearBumperImages', 'Rear Bumper Image'),
        F.multi('lhsTailLamp', 'LHS Tail Lamp', ['OK', 'Broken', 'Fogged']),
        F.img('lhsTailLampImages', 'LHS Tail Lamp Image'),
        F.multi('lhsRearFogLamp', 'LHS Rear Fog Lamp', [
          'Present',
          'Not Present',
          'Broken',
          'Not Applicable',
        ]),
        F.img('lhsRearFogLampImages', 'LHS Rear Fog Lamp Image'),
        F.multi('rhsTailLamp', 'RHS Tail Lamp', ['OK', 'Broken', 'Fogged']),
        F.img('rhsTailLampImages', 'RHS Tail Lamp Image'),
        F.multi('rhsRearFogLamp', 'RHS Rear Fog Lamp', [
          'Present',
          'Not Present',
          'Broken',
          'Not Applicable',
        ]),
        F.img('rhsRearFogLampImages', 'RHS Rear Fog Lamp Image'),
        F.multi('rearWindshield', 'Rear Windshield', [
          'OK',
          'Crack',
          'Chip',
          'Replaced',
        ]),
        F.img('rearWindshieldImages', 'Rear Windshield Image'),
        /* F.multi('bootDoor', 'Boot Door', [
          'OK',
          'Dent',
          'Scratch',
          'Repaint',
          'Replaced',
        ]),
        F.img('bootDoorImages', 'Boot Door Image'), */
        F.img('rearWithBootDoorOpenImages', 'Boot Door Open Image'),
        F.multi('spareWheel', 'Spare Wheel', ['Available', 'Not Available']),
        F.img('spareWheelImages', 'Spare Wheel Image'),
        F.multi('spareTyre', 'Spare Tyre', [
          'Available',
          'Not Available',
          'Worn',
        ]),
        F.img('spareTyreImages', 'Spare Tyre Image'),
        F.multi('bootFloor', 'Boot Floor', ['OK', 'Rust', 'Damaged']),
        F.img('bootFloorImages', 'Boot Floor Image'),
      ],
    ),

    // ═══════════════════════════════════════
    // 5. RIGHT
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Right',
      icon: Icons.arrow_forward,
      fields: [
        F.img('rhsFullViewImages', 'RHS Full View'),
        F.multi('rhsQuarterPanel', 'RHS Quarter Panel', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Replaced',
        ]),
        F.img(
          'rhsQuarterPanelWithRearDoorOpenImages',
          'RHS Quarter Panel With Boot Door Open',
        ),
        F.img('rhsQuarterPanelImages', 'RHS Quarter Panel Image'),
        F.multi('rhsRearAlloy', 'RHS Rear Wheel', [
          'OK',
          'Bent',
          'Cracked',
          'Replaced',
        ]),
        F.img('rhsRearWheelImages', 'RHS Rear Wheel Image'),
        F.multi('rhsRearTyre', 'RHS Rear Tyre', [
          'OK',
          'Worn',
          'Bald',
          'Mismatched',
        ]),
        F.img('rhsRearTyreImages', 'RHS Rear Tyre Image'),
        F.multi('rhsRunningBorder', 'RHS Running Border', [
          'OK',
          'Dent',
          'Rust',
          'Damaged',
        ]),
        F.img('rhsRunningBorderImages', 'RHS Running Border Image'),
        F.multi('rhsCPillar', 'RHS C Pillar', [
          'OK',
          'Repaired',
          'Dented',
          'Repainted',
        ]),
        F.img('rhsCPillarImages', 'RHS C Pillar Image'),
        F.multi('rhsRearDoor', 'RHS Rear Door', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Replaced',
        ]),
        F.img('rhsRearDoorImages', 'RHS Rear Door Image'),
        F.multi('rhsBPillar', 'RHS B Pillar', [
          'OK',
          'Repaired',
          'Dented',
          'Repainted',
        ]),
        F.img('rhsBPillarImages', 'RHS B Pillar Image'),
        F.multi('rhsFrontDoor', 'RHS Front Door', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Replaced',
        ]),
        F.img('rhsFrontDoorImages', 'RHS Front Door Image'),
        F.multi('rhsAPillar', 'RHS A Pillar', [
          'OK',
          'Repaired',
          'Dented',
          'Repainted',
        ]),
        F.img('rhsAPillarImages', 'RHS A Pillar Image'),
        F.multi('rhsOrvm', 'RHS ORVM', [
          'OK',
          'Broken',
          'Missing',
          'Scratched',
        ]),
        F.img('rhsOrvmImages', 'RHS ORVM Image'),
        F.multi('rhsFrontAlloy', 'RHS Front Wheel', [
          'OK',
          'Bent',
          'Cracked',
          'Replaced',
        ]),
        F.img('rhsFrontWheelImages', 'RHS Front Wheel Image'),
        F.multi('rhsFrontTyre', 'RHS Front Tyre', [
          'OK',
          'Worn',
          'Bald',
          'Mismatched',
        ]),
        F.img('rhsFrontTyreImages', 'RHS Front Tyre Image'),
        F.multi('rhsFender', 'RHS Fender', [
          'OK',
          'Scratch',
          'Dent',
          'Repaint',
          'Rust',
          'Replaced',
        ]),
        F.img('rhsFenderImages', 'RHS Fender Image'),
      ],
    ),

    // ═══════════════════════════════════════
    // 6. ENGINE BAY
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Engine Bay',
      icon: Icons.engineering,
      fields: [
        F.img('engineBayImages', 'Engine Bay'),
        F.video('engineVideo', 'Engine Sound Video', maxDuration: 15),
        F.multi('engine', 'Engine', [
          'OK',
          'Noise',
          'Leak',
          'Misfire',
          'Seized',
        ]),
        F.multi('commentsOnEngine', 'Comment on Engine', [
          'OK',
          'Exhaust Smoke',
          'Oil Leakage',
          'Coolant Leakage',
          'Abnormal Noise',
        ], optional: true),
        F.multi('engineOilLevelDipstick', 'Engine Oil Level Dipstick', [
          'OK',
          'Low',
          'High',
          'Empty',
        ]),
        F.multi('engineOil', 'Engine Oil', [
          'OK',
          'Low',
          'Dirty',
          'Sludge',
          'Leakage',
        ]),
        F.multi('commentsOnEngineOil', 'Comment on Engine Oil', [
          'OK',
          'Dirty',
          'Leaking',
          'Sludge',
          'Level Low',
        ], optional: true),
        F.drop('enginePermisableBlowBy', 'Engine Permisable Blowby', [
          'No',
          'Yes',
        ]),
        F.multi('coolant', 'Coolant', [
          'OK',
          'Low',
          'Dirty',
          'Leakage',
          'Empty',
        ]),
        F.multi('cowlTop', 'Cowl Top', ['OK', 'Repaired', 'Damaged']),
        F.img('cowlTopImages', 'Cowl Top Image'),
        F.multi('firewall', 'Firewall', ['OK', 'Repaired', 'Damaged']),
        F.img('firewallImages', 'Firewall Image'),
        F.drop('abs', 'ABS', ['Working', 'Not Working', 'Not Available']),
        F.multi('lhsApron', 'LHS Apron', ['OK', 'Repaired', 'Damaged']),
        F.img('lhsApronImages', 'LHS Apron Image'),
        F.multi('rhsApron', 'RHS Apron', ['OK', 'Repaired', 'Damaged']),
        F.img('rhsApronImages', 'RHS Apron Image'),
        F.multi('battery', 'Battery', ['OK', 'Weak', 'Replace', 'Dead']),
        F.img('batteryImages', 'Battery Image'),
        F.multi('upperCrossMember', 'Upper Cross Member', [
          'OK',
          'Repaired',
          'Damaged',
        ]),
        F.multi('lhsSideMember', 'LHS Side Member', [
          'OK',
          'Repaired',
          'Damaged',
        ]),
        F.multi('rhsSideMember', 'RHS Side Member', [
          'OK',
          'Repaired',
          'Damaged',
        ]),
        F.multi('engineMount', 'Engine Mount', ['OK', 'Worn', 'Damaged']),
        F.multi('headlightSupport', 'Headlamp Support', [
          'OK',
          'Repaired',
          'Damaged',
        ]),
        F.multi('radiatorSupport', 'Radiator Support', [
          'OK',
          'Repaired',
          'Damaged',
        ]),
        F.multi('commentsOnRadiator', 'Comment on Radiator', [
          'OK',
          'Leaking',
          'Damaged',
          'Fins Bent',
        ], optional: true),
        F.multi('lowerCrossMember', 'Lower Cross Member', [
          'OK',
          'Repaired',
          'Damaged',
        ]),
        F.img('additionalImages', 'Optional Images', optional: true),
        F.multi('exhaustSmoke', 'Exhaust Smoke', [
          'Normal',
          'White',
          'Black',
          'Blue',
        ]),
        F.video('exhaustSmokeVideo', 'Exhaust Smoke Video', maxDuration: 10),
        F.multi('commentsOnTowing', 'Comment on Towing', [
          'N/A',
          'Towing Mandatory',
          'Front Towing',
          'Rear Towing',
        ], optional: true),
        F.multi('commentsOnOthers', 'Comment on Others', [
          'N/A',
          'Other Issues',
          'See Notes',
        ], optional: true),
      ],
    ),

    // ═══════════════════════════════════════
    // 7. ELECTRICALS
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Electricals',
      icon: Icons.electric_bolt,
      fields: [
        F.img(
          'meterConsoleWithEngineOnImages',
          'Cluster Meter (With Engine Running)',
        ),
        F.num('odometerReadingInKms', 'Odometer Reading'),
        F.drop('fuelLevel', 'Fuel Level', []),
        F.multi('commentsOnClusterMeter', 'Comment on Cluster Meter', [
          'OK',
          'Light On',
          'Display Issue',
          'Broken Glass',
        ], optional: true),
        F.multi('irvm', 'IRVM', ['OK', 'Broken', 'Missing']),
        F.multi('dashboard', 'Dashboard', [
          'OK',
          'Scratch',
          'Crack',
          'Damaged',
        ]),
        F.text('electricals', 'Electricals', optional: true),
        F.text('commentsOnElectricals', 'Comments on Electricals', optional: true),
        F.multi('musicSystem', 'Music System', [
          'Working',
          'Not Working',
          'Not Available',
          'N/A',
        ]),
        F.drop('inbuiltSpeaker', 'Inbuilt Speaker', [
          'OK',
          'Not Working',
          'Not Available',
        ]),
        F.multi('externalSpeaker', 'External Speaker', [
          'OK',
          'Not Working',
          'N/A',
        ]),
        F.multi(
          'steeringMountedAudioControl',
          'Steering Mounted Audio Controls',
          ['Working', 'Not Working', 'Not Available'],
        ),
        F.multi(
          'steeringMountedSystemControls',
          'Steering Mounted System Controls',
          ['Working', 'Not Working', 'Not Available'],
        ),
        F.drop('acType', 'AC Type', ['Manual', 'Climate Control', 'Dual Zone']),
        F.drop('acCooling', 'AC Cooling', [
          'Good',
          'Average',
          'Poor',
          'Not Working',
        ]),
        F.multi('commentsOnAC', 'Comment on AC', [
          'OK',
          'Low Cooling',
          'Noise',
          'Heating Issue',
        ], optional: true),
        F.img('acImages', 'AC Image'),
        F.drop('rearDefogger', 'Rear Defogger', [
          'Working',
          'Not Working',
          'Not Available',
        ]),
        F.multi('rearWiperWasher', 'Rear Wiper & Washer', [
          'Working',
          'Not Working',
          'Not Available',
          'Not Applicable',
        ]),
        F.img('rearWiperAndWasherImages', 'Rear Wiper & Washer Image'),
        F.multi('reverseCamera', 'Reverse Camera', [
          'Working',
          'Not Working',
          'Not Available',
          'Not Applicable',
        ]),
        F.img('reverseCameraImages', 'Reverse Camera Image'),
        F.multi('sunroof', 'Sunroof', [
          'Yes',
          'No',
          'Jammed',
          'Not Applicable',
        ]),
        F.img('sunroofImages', 'Sunroof Image'),
        F.drop('noOfPowerWindows', 'Number of Power Windows', [
          'Not Applicable',
          '1',
          '2',
          '4',
          '6',
          '7',
          '8',
          '9',
          '10',
          '12',
        ]),
        F.multi('powerWindowConditionRhsFront', 'Driver Door Features', [
          'Power Window',
          'Central Lock',
          'Manual',
        ]),
        F.multi('powerWindowConditionLhsFront', 'Co-Driver Door Features', [
          'Power Window',
          'Central Lock',
          'Manual',
        ]),
        F.multi('powerWindowConditionRhsRear', 'RHS Rear Door Features', [
          'Power Window',
          'Central Lock',
          'Manual',
        ]),
        F.multi('powerWindowConditionLhsRear', 'LHS Rear Door Features', [
          'Power Window',
          'Central Lock',
          'Manual',
        ]),
      ],
    ),

    // ═══════════════════════════════════════
    // 8. INTERIOR
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Interior',
      icon: Icons.airline_seat_recline_extra,
      fields: [
        F.drop('noOfAirBags', 'Number of Airbags', [
          'Not Applicable',
          '1',
          '2',
          '4',
          '6',
          '7',
          '8',
          '9',
          '10',
          '12',
        ]),
        F.drop('airbagFeaturesDriverSide', 'Driver Airbag', [
          'Present',
          'Not Present',
          'Deployed',
          'Not Applicable',
        ]),
        F.img('airbagImages', 'Driver Airbag Image'),
        F.drop('airbagFeaturesCoDriverSide', 'Co-Driver Airbag', [
          'Present',
          'Not Present',
          'Deployed',
          'Not Applicable',
        ]),
        F.img('coDriverAirbagImages', 'Co-Driver Airbag Image'),
        F.drop('driverSeatAirbag', 'Driver Seat Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('driverSeatAirbagImages', 'Driver Seat Airbag Image'),
        F.drop('coDriverSeatAirbag', 'Co-Driver Seat Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('coDriverSeatAirbagImages', 'Co-Driver Seat Airbag Image'),
        F.drop('rhsCurtainAirbag', 'RHS Curtain Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('rhsCurtainAirbagImages', 'RHS Curtain Airbag Image'),
        F.drop('lhsCurtainAirbag', 'LHS Curtain Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('lhsCurtainAirbagImages', 'LHS Curtain Airbag Image'),
        F.drop('driverSideKneeAirbag', 'Driver Knee Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('driverKneeAirbagImages', 'Driver Knee Airbag Image'),
        F.drop('coDriverKneeSeatAirbag', 'Co-Driver Knee Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('coDriverKneeAirbagImages', 'Co-Driver Knee Airbag Image'),
        F.drop('rhsRearSideAirbag', 'RHS Rear Side Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('rhsRearSideAirbagImages', 'RHS Rear Side Airbag Image'),
        F.drop('lhsRearSideAirbag', 'LHS Rear Side Airbag', [
          'Present',
          'Not Present',
          'Not Applicable',
        ]),
        F.img('lhsRearSideAirbagImages', 'LHS Rear Side Airbag Image'),
        F.drop('seatsUpholstery', 'Seat Upholstery', [
          'Fabric',
          'Leather',
          'Synthetic',
          'Mixed',
        ]),
        F.text('leatherSeats', 'Leather Seats', optional: true),
        F.text('fabricSeats', 'Fabric Seats', optional: true),
        F.multi('driverSeat', 'Driver Seat', ['OK', 'Torn', 'Stained', 'Worn']),
        F.multi('coDriverSeat', 'Co-Driver Seat', [
          'OK',
          'Torn',
          'Stained',
          'Worn',
        ]),
        F.drop('frontCentreArmRest', 'Front Centre Arm Rest', [
          'Present',
          'Not Present',
          'Damaged',
        ]),
        F.multi('rearSeats', 'Rear Seats', ['OK', 'Stained', 'Torn', 'Worn']),
        F.multi('thirdRowSeats', 'Third Row Seats', [
          'Present',
          'Not Applicable',
          'Damaged',
        ]),
        F.img(
          'frontSeatsFromDriverSideImages',
          'Front Seat from Driver Side (Door Open)',
        ),
        F.img(
          'rearSeatsFromRightSideImages',
          'Rear Seat from Right Side (Door Open)',
        ),
        F.img('dashboardImages', 'Dashboard from Rear Seat'),
        F.multi('commentOnInterior', 'Comment on Interior', [
          'OK',
          'Dirty',
          'Leaking',
          'Damaged',
          'Smelly',
        ], optional: true),
      ],
    ),

    // ═══════════════════════════════════════
    // 9. STEERING, SUSPENSION & BRAKES
    // ═══════════════════════════════════════
    FormSectionDef(
      title: 'Steering, Suspension & Brakes',
      icon: Icons.settings,
      fields: [
        F.multi('steering', 'Steering', [
          'OK',
          'Hard',
          'Noise',
          'Vibration',
          'Play',
        ]),
        F.multi('clutch', 'Clutch', [
          'OK',
          'Hard',
          'Slipping',
          'Deep',
          'Noise',
        ]),
        F.multi('gearShift', 'Gear Shift', ['OK', 'Hard', 'Noise', 'Jumping']),
        F.drop('transmissionType', 'Transmission Type', [
          'Manual',
          'Automatic',
          'AMT',
          'CVT',
          'DCT',
        ]),
        F.drop('driveTrain', 'Drive Train', ['FWD', 'RWD', 'AWD', '4WD']),
        F.multi('commentsOnTransmission', 'Comment on Transmission', [
          'OK',
          'Hard Shift',
          'Noise',
          'Slipping',
        ], optional: true),
        F.multi('brakes', 'Brakes', [
          'OK',
          'Spongy',
          'Noise',
          'Weak',
          'Pulling',
        ]),
        F.multi('suspension', 'Suspension', ['OK', 'Noise', 'Weak', 'Leaking']),
        F.num(
          'odometerReadingAfterTestDriveInKms',
          'Odometer Reading after Test Drive',
        ),
        F.img(
          'odometerReadingAfterTestDriveImages',
          'Odometer Reading after Test Drive Image',
        ),
      ],
    ),
  ];
}
